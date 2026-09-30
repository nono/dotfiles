package main

import (
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

// probe is a report whose verdicts are known, for testing the judge.
type probe struct {
	kind   string
	report string
	found  bool // whether every expectation must be found, or none
}

// probesOf returns the probes of a case: a report that states every expectation, one that lists each as checked and
// fine, and an empty one.
func probesOf(c evalCase) []probe {
	var oracle, negative strings.Builder
	oracle.WriteString("Findings:\n\n")
	negative.WriteString("I checked each of these points and found no defect: the code handles each one.\n\n")
	for i, e := range c.Expect {
		fmt.Fprintf(&oracle, "%d. %s\n", i+1, e.Finding)
		fmt.Fprintf(&negative, "- Checked, and it does not hold: %s\n", e.Finding)
	}
	negative.WriteString("\nFindings: none.\n")
	return []probe{{"oracle", oracle.String(), true}, {"negative", negative.String(), false}, {"empty", "", false}}
}

// checkJudge runs the judge twice on each probe of the selected cases, and writes judge-check.md under cfg.out.
func checkJudge(ctx context.Context, cfg config, cf caseFile, progress io.Writer) error {
	type run struct {
		c     evalCase
		p     probe
		try   int
		jd    judgement
		cost  float64
		err   error
		wrong []string
	}
	var runs []*run
	for _, c := range selected(cfg, cf) {
		if c.Split == splitClean {
			continue
		}
		for _, p := range probesOf(c) {
			for try := 1; try <= 2; try++ {
				runs = append(runs, &run{c: c, p: p, try: try})
			}
		}
	}
	if len(runs) == 0 {
		return fmt.Errorf("no selected case holds expectations")
	}
	sem := make(chan struct{}, max(cfg.parallel, 1)*2)
	var wg sync.WaitGroup
	for _, r := range runs {
		wg.Go(func() {
			sem <- struct{}{}
			defer func() { <-sem }()
			path := filepath.Join(cfg.out, fmt.Sprintf("judge-%d-%s-%d.md", r.c.PR, r.p.kind, r.try))
			r.jd, r.cost, r.err = judge(ctx, r.c.Expect, r.p.report, path)
			if r.err != nil {
				return
			}
			for _, v := range r.jd.verdictsFor(r.c.Expect) {
				if v.Found != r.p.found {
					r.wrong = append(r.wrong, v.ID)
				}
			}
			fmt.Fprintf(progress, "revieweval: judge #%d %s try %d: %d wrong\n", r.c.PR, r.p.kind, r.try, len(r.wrong))
		})
	}
	wg.Wait()
	var b strings.Builder
	b.WriteString("# Judge check\n\nEach probe is judged twice. An oracle states every expected finding; a negative " +
		"lists each as checked and fine; an empty report says nothing.\n\n")
	b.WriteString("| PR | Probe | Try | Wrong verdicts | Findings counted | Cost |\n| --- | --- | --- | --- | --- | --- |\n")
	wrong, total, errs := 0, 0, 0
	var cost float64
	for _, r := range runs {
		cost += r.cost
		if r.err != nil {
			errs++
			fmt.Fprintf(&b, "| #%d | %s | %d | error: %s | | $%.2f |\n", r.c.PR, r.p.kind, r.try,
				strings.ReplaceAll(r.err.Error(), "|", `\|`), r.cost)
			continue
		}
		wrong += len(r.wrong)
		total += len(r.c.Expect)
		fmt.Fprintf(&b, "| #%d | %s | %d | %s | %d | $%.2f |\n", r.c.PR, r.p.kind, r.try, strings.Join(r.wrong, " "),
			r.jd.Findings, r.cost)
	}
	fmt.Fprintf(&b, "\n%d wrong verdicts of %d, %d failed calls. Total cost: $%.2f\n", wrong, total, errs, cost)
	if err := os.WriteFile(filepath.Join(cfg.out, "judge-check.md"), []byte(b.String()), 0o644); err != nil {
		return err
	}
	fmt.Fprintf(progress, "revieweval: %d wrong verdicts of %d, %d failed calls\n", wrong, total, errs)
	return nil
}

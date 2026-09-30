package main

import (
	"fmt"
	"regexp"
	"slices"
	"strings"
)

// The kinds of mutant.
const (
	kindRevert = "revert" // put a hunk back to its base lines
	kindDrop   = "drop"   // delete one statement the change adds
	kindNegate = "negate" // negate the condition of an if the change adds
)

// mutant is one edit of a head file, and the tests that failed under it.
type mutant struct {
	path    string
	kind    string
	line    int    // head line it edits; for a revert, the line of its hunk
	h       hunk   // the hunk, for a revert
	text    string // the head line, for a drop or a negate
	killers []string
}

func (m mutant) apply(lines []string) ([]string, error) {
	if m.kind == kindRevert {
		return revertHunk(lines, m.h)
	}
	if m.line < 1 || m.line > len(lines) || lines[m.line-1] != m.text {
		return nil, fmt.Errorf("line %d does not match the head file", m.line)
	}
	out := slices.Clone(lines)
	if m.kind == kindDrop {
		return slices.Delete(out, m.line-1, m.line), nil
	}
	negated, ok := negateIf(m.text)
	if !ok {
		return nil, fmt.Errorf("line %d holds no if to negate", m.line)
	}
	out[m.line-1] = negated
	return out, nil
}

// mutantsOf returns the mutants of the hunks of f that change code, and the number of comment-only hunks.
func mutantsOf(f fileDiff, kinds map[string]bool) ([]mutant, int) {
	var ms []mutant
	comments := 0
	for _, h := range f.hunks {
		if commentOnly(h) {
			comments++
			continue
		}
		oneAddedLine := len(h.oldLines) == 0 && len(h.newLines) == 1 // its revert is its drop
		if kinds[kindRevert] && !f.added {
			ms = append(ms, mutant{path: f.path, kind: kindRevert, line: h.newStart, h: h})
		}
		for i, l := range h.newLines {
			line := h.newStart + i
			if kinds[kindDrop] && droppable(l) && !(oneAddedLine && kinds[kindRevert] && !f.added) {
				ms = append(ms, mutant{path: f.path, kind: kindDrop, line: line, text: l})
			}
			if _, ok := negateIf(l); ok && kinds[kindNegate] {
				ms = append(ms, mutant{path: f.path, kind: kindNegate, line: line, text: l})
			}
		}
	}
	return ms, comments
}

var (
	logCall  = regexp.MustCompile(`(?i)^(\w*log\w*|l)\.|\.(Debug|Info|Warn|Warning|Trace|Print)(f|ln)?\(`)
	errRet   = regexp.MustCompile(`^return\b.*(\berr\b|Errorf\(|errors\.New\()`)
	hangRisk = regexp.MustCompile(`\b(Unlock|RUnlock|Done|cancel|Close)\(\)|^close\(`)
	ifLine   = regexp.MustCompile(`^(\s*(?:\} else )?if )(.+) \{$`)
	errCond  = regexp.MustCompile(`^\w+ [!=]= nil$`)
)

// droppable reports whether line is one whole statement whose deletion can compile and change behaviour. It leaves
// out declarations, lines of a multi-line construct, logging, error returns, and the calls whose deletion hangs a test.
func droppable(line string) bool {
	t := strings.TrimSpace(line)
	if t == "" || strings.Contains(t, ":=") || logCall.MatchString(t) || errRet.MatchString(t) ||
		hangRisk.MatchString(t) {
		return false
	}
	for _, p := range []string{"//", "}", ")", "]", ".", "case ", "default:", "else", "func ", "type ", "var ",
		"const ", "package ", "import", "if ", "for ", "switch ", "select ", "go func", "defer func"} {
		if strings.HasPrefix(t, p) {
			return false
		}
	}
	for _, s := range []string{"{", "(", "[", ",", ":", "+", "-", "*", "/", "&&", "||", "=", "`"} {
		if strings.HasSuffix(t, s) {
			return false
		}
	}
	return true
}

// negateIf returns line with the condition of its if negated. It leaves out an error check, whose negation mostly
// tests an error path.
func negateIf(line string) (string, bool) {
	m := ifLine.FindStringSubmatch(line)
	if m == nil {
		return "", false
	}
	prefix, cond := m[1], m[2]
	if i := strings.LastIndex(cond, "; "); i >= 0 {
		prefix, cond = prefix+cond[:i+2], cond[i+2:]
	}
	if errCond.MatchString(cond) {
		return "", false
	}
	return prefix + "!(" + cond + ") {", true
}

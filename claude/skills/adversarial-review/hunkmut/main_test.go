package main

import (
	"bytes"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
	"testing"
	"time"
)

const sampleDiff = `diff --git a/a.go b/a.go
index 1111111..2222222 100644
--- a/a.go
+++ b/a.go
@@ -2 +2 @@ package a
-// old comment
+// new comment
@@ -5,0 +6,3 @@ func F() {
+	if x {
+		return
+	}
@@ -9,2 +11,0 @@ func G() {
-	a()
-	b()
diff --git a/new.go b/new.go
new file mode 100644
index 0000000..3333333
--- /dev/null
+++ b/new.go
@@ -0,0 +1,2 @@
+package a
+func H() {}
diff --git a/gone.go b/gone.go
deleted file mode 100644
index 4444444..0000000
--- a/gone.go
+++ /dev/null
@@ -1 +0,0 @@
-package a
`

func TestParseDiffRejectsAPathWithoutPrefix(t *testing.T) {
	if _, err := parseDiff("diff --git a.go a.go\n--- a.go\n+++ a.go\n@@ -1 +1 @@\n-x\n+y\n"); err == nil {
		t.Error("a diff without a/ and b/ prefixes gave no error")
	}
}

func TestParseDiff(t *testing.T) {
	files, err := parseDiff(sampleDiff)
	if err != nil {
		t.Fatal(err)
	}
	if len(files) != 3 {
		t.Fatalf("got %d files, want 3", len(files))
	}
	a := files[0]
	if a.path != "a.go" || a.added || a.deleted || len(a.hunks) != 3 {
		t.Fatalf("a.go parsed as %+v", a)
	}
	want := []hunk{
		{newStart: 2, newCount: 1, oldLines: []string{"// old comment"}, newLines: []string{"// new comment"}},
		{newStart: 6, newCount: 3, newLines: []string{"\tif x {", "\t\treturn", "\t}"}},
		{newStart: 11, newCount: 0, oldLines: []string{"\ta()", "\tb()"}},
	}
	for i, h := range a.hunks {
		if h.newStart != want[i].newStart || h.newCount != want[i].newCount ||
			!slices.Equal(h.oldLines, want[i].oldLines) || !slices.Equal(h.newLines, want[i].newLines) {
			t.Errorf("hunk %d = %+v, want %+v", i, h, want[i])
		}
	}
	if f := files[1]; f.path != "new.go" || !f.added {
		t.Errorf("new.go parsed as %+v", f)
	}
	if f := files[2]; f.path != "gone.go" || !f.deleted {
		t.Errorf("gone.go parsed as %+v", f)
	}
}

func TestRevertHunk(t *testing.T) {
	head := []string{"l1", "l2", "l3", "l4"}
	tests := []struct {
		name string
		h    hunk
		want []string
	}{
		{"replace", hunk{newStart: 2, newCount: 2, oldLines: []string{"o"}, newLines: []string{"l2", "l3"}},
			[]string{"l1", "o", "l4"}},
		{"added lines", hunk{newStart: 1, newCount: 1, newLines: []string{"l1"}}, []string{"l2", "l3", "l4"}},
		{"deleted lines", hunk{newStart: 2, newCount: 0, oldLines: []string{"x", "y"}},
			[]string{"l1", "l2", "x", "y", "l3", "l4"}},
		{"deleted at the top", hunk{newStart: 0, newCount: 0, oldLines: []string{"x"}},
			[]string{"x", "l1", "l2", "l3", "l4"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := revertHunk(head, tt.h)
			if err != nil {
				t.Fatal(err)
			}
			if !slices.Equal(got, tt.want) {
				t.Errorf("got %q, want %q", got, tt.want)
			}
			if !slices.Equal(head, []string{"l1", "l2", "l3", "l4"}) {
				t.Errorf("revertHunk changed its input: %q", head)
			}
		})
	}
	if _, err := revertHunk(head, hunk{newStart: 2, newCount: 1, newLines: []string{"nope"}}); err == nil {
		t.Error("a hunk that does not match the file gave no error")
	}
}

func TestCommentOnly(t *testing.T) {
	if !commentOnly(hunk{oldLines: []string{"\t// a", ""}, newLines: []string{"  // b"}}) {
		t.Error("comment and blank lines not seen as comment-only")
	}
	if commentOnly(hunk{oldLines: []string{"// a"}, newLines: []string{"x := 1 // b"}}) {
		t.Error("a code line with a trailing comment seen as comment-only")
	}
}

func TestParseTestEvents(t *testing.T) {
	stream := `{"Action":"run","Package":"m/a","Test":"TestA"}
{"Action":"fail","Package":"m/a","Test":"TestA"}
{"Action":"fail","Package":"m/a"}
{"Action":"fail","Package":"m/b"}
{"ImportPath":"m/c [m/c.test]","Action":"build-fail"}
{"Action":"fail","Package":"m/c","FailedBuild":"m/c [m/c.test]"}
{"Action":"pass","Package":"m/d"}
`
	res, err := parseTestEvents(strings.NewReader(stream))
	if err != nil {
		t.Fatal(err)
	}
	if want := []string{"m/a TestA", "m/b (outside a test)"}; !slices.Equal(res.failed, want) {
		t.Errorf("failed = %q, want %q", res.failed, want)
	}
	if want := []string{"m/c [m/c.test]"}; !slices.Equal(res.buildFailed, want) {
		t.Errorf("buildFailed = %q, want %q", res.buildFailed, want)
	}
}

const baseAbs = `package m

// Abs returns x.
func Abs(x int) int {
	return x
}

func Clamp(x int) int {
	return x
}

func Keep() int {
	return 1
}
`

const headAbs = `package m

// Abs returns the absolute value of x.
func Abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

func Clamp(x int) int {
	return min(x, limit())
}

func Keep() int {
	return 1
}

func limit() int {
	return 10
}
`

const absTest = `package m

import "testing"

func TestAbs(t *testing.T) {
	if Abs(-2) != 2 || Abs(3) != 3 {
		t.Fatal("wrong")
	}
}
`

// useTest is a second package whose test also fails when Abs is wrong.
const useTest = `package use

import (
	"testing"

	"example.com/m"
)

func TestUsesAbs(t *testing.T) {
	if m.Abs(-1) != 1 {
		t.Fatal("wrong")
	}
}
`

// newRepo makes a git repository with a base commit and a head commit, and returns its path.
func newRepo(t *testing.T) string {
	t.Helper()
	for _, bin := range []string{"git", "go"} {
		if _, err := exec.LookPath(bin); err != nil {
			t.Skipf("%s not found", bin)
		}
	}
	t.Setenv("GIT_CONFIG_GLOBAL", os.DevNull)
	t.Setenv("GIT_CONFIG_NOSYSTEM", "1")
	t.Setenv("GOWORK", "off")
	t.Setenv("GOTOOLCHAIN", "local")
	dir := t.TempDir()
	run := func(args ...string) {
		t.Helper()
		cmd := exec.Command("git", append([]string{"-C", dir, "-c", "user.name=t", "-c", "user.email=t@t"}, args...)...)
		if out, err := cmd.CombinedOutput(); err != nil {
			t.Fatalf("git %v: %v\n%s", args, err, out)
		}
	}
	write := func(name, data string) {
		t.Helper()
		if err := os.WriteFile(filepath.Join(dir, name), []byte(data), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	run("init", "-q", "-b", "main")
	write("go.mod", "module example.com/m\n\ngo 1.25\n")
	write("abs.go", baseAbs)
	run("add", ".")
	run("commit", "-q", "-m", "base")
	run("tag", "base")
	write("abs.go", headAbs)
	write("abs_test.go", absTest)
	if err := os.Mkdir(filepath.Join(dir, "use"), 0o755); err != nil {
		t.Fatal(err)
	}
	write("use/use_test.go", useTest)
	run("add", ".")
	run("commit", "-q", "-m", "head")
	return dir
}

func TestMutate(t *testing.T) {
	dir := newRepo(t)
	// a user setting that drops the a/ and b/ prefixes of the diff
	t.Setenv("GIT_CONFIG_COUNT", "1")
	t.Setenv("GIT_CONFIG_KEY_0", "diff.noprefix")
	t.Setenv("GIT_CONFIG_VALUE_0", "true")
	kinds := map[string]bool{kindRevert: true, kindDrop: true, kindNegate: true}
	cfg := config{tester: tester{dir: dir, timeout: time.Minute}, base: "base", kinds: kinds}
	rep, err := mutate(t.Context(), cfg, io.Discard)
	if err != nil {
		t.Fatal(err)
	}
	has := func(ms []mutant, kind, line string) bool {
		return slices.ContainsFunc(ms, func(m mutant) bool {
			return m.kind == kind && (strings.Contains(m.text, line) ||
				slices.ContainsFunc(m.h.newLines, func(l string) bool { return strings.Contains(l, line) }))
		})
	}
	if !has(rep.killed, kindRevert, "return -x") {
		t.Errorf("the revert of the Abs fix is not killed: %+v", rep)
	}
	if !has(rep.killed, kindNegate, "if x < 0") {
		t.Errorf("the negation of the Abs fix is not killed: %+v", rep)
	}
	if !has(rep.killed, kindDrop, "return -x") {
		t.Errorf("the drop of the Abs fix is not killed: %+v", rep)
	}
	if !has(rep.survived, kindRevert, "min(x, limit())") {
		t.Errorf("the untested Clamp change did not survive: %+v", rep)
	}
	if !has(rep.broke, kindRevert, "return 10") {
		t.Errorf("reverting limit did not break the build: %+v", rep)
	}
	for _, m := range rep.killed {
		for _, k := range m.killers {
			if strings.HasPrefix(k, "example.com/m/use ") {
				t.Errorf("%s %s ran the other package although its own killed it: %q", m.kind, location(m), m.killers)
			}
		}
	}
	if rep.commentOnly != 1 {
		t.Errorf("commentOnly = %d, want 1", rep.commentOnly)
	}
	if !slices.Contains(rep.onBase.failed, "example.com/m TestAbs") {
		t.Errorf("TestAbs does not fail on the base code: %+v", rep.onBase)
	}
	if out, err := git(t.Context(), dir, "status", "--porcelain"); err != nil || out != "" {
		t.Errorf("the worktree is not restored: %q %v", out, err)
	}
	var b bytes.Buffer
	rep.write(&b)
	for _, want := range []string{"## Mutants no test kills (", "`abs.go:12` revert", "by example.com/m TestAbs"} {
		if !strings.Contains(b.String(), want) {
			t.Errorf("report lacks %q:\n%s", want, b.String())
		}
	}
}

func TestMutateStopsAtTheBudget(t *testing.T) {
	dir := newRepo(t)
	kinds := map[string]bool{kindRevert: true, kindDrop: true, kindNegate: true}
	cfg := config{tester: tester{dir: dir, timeout: time.Minute}, base: "base", kinds: kinds, budget: time.Nanosecond}
	rep, err := mutate(t.Context(), cfg, io.Discard)
	if err != nil {
		t.Fatal(err)
	}
	if n := len(rep.survived) + len(rep.killed) + len(rep.broke); n != 0 || len(rep.notRun) == 0 {
		t.Errorf("ran %d mutants and left %d past a spent budget", n, len(rep.notRun))
	}
	var b bytes.Buffer
	rep.write(&b)
	if want := "mutants not run: the budget of 1ns was spent"; !strings.Contains(b.String(), want) {
		t.Errorf("report lacks %q:\n%s", want, b.String())
	}
}

func TestMutateRefusesADirtyTree(t *testing.T) {
	dir := newRepo(t)
	if err := os.WriteFile(filepath.Join(dir, "abs.go"), []byte(baseAbs), 0o644); err != nil {
		t.Fatal(err)
	}
	cfg := config{tester: tester{dir: dir, timeout: time.Minute}, base: "base", kinds: map[string]bool{kindRevert: true}}
	if _, err := mutate(t.Context(), cfg, io.Discard); err == nil || !strings.Contains(err.Error(), "uncommitted") {
		t.Fatalf("got %v, want an error on the uncommitted change", err)
	}
}

func TestDroppable(t *testing.T) {
	for line, want := range map[string]bool{
		"\tqueue = append(queue, coord)":  true,
		"\t\treturn queue":                true,
		"\tx := f()":                      false,
		"\treturn err":                    false,
		"\treturn nil, fmt.Errorf(\"x\")": false,
		"\tlog.Warnf(\"x\")":              false,
		"\ts.logger.Info(\"x\")":          false,
		"\tmu.Unlock()":                   false,
		"\tdefer mu.Unlock()":             false,
		"\tclose(ch)":                     false,
		"\tfoo(a,":                        false,
		"\t}":                             false,
		"\tcase d == 0:":                  false,
		"\tif x {":                        false,
		"\t// note":                       false,
		"\tX: 1,":                         false,
	} {
		if got := droppable(line); got != want {
			t.Errorf("droppable(%q) = %v, want %v", line, got, want)
		}
	}
}

func TestNegateIf(t *testing.T) {
	for line, want := range map[string]string{
		"\tif x < 0 {":                      "\tif !(x < 0) {",
		"\t} else if a && b {":              "\t} else if !(a && b) {",
		"\tif v, ok := m[k]; ok && v > 1 {": "\tif v, ok := m[k]; !(ok && v > 1) {",
		"\tif err != nil {":                 "",
		"\tif err := f(); err != nil {":     "",
		"\tfor x {":                         "",
	} {
		got, ok := negateIf(line)
		if ok != (want != "") || got != want {
			t.Errorf("negateIf(%q) = %q, %v, want %q", line, got, ok, want)
		}
	}
}

func TestTestCapsMemory(t *testing.T) {
	if _, err := exec.LookPath("systemd-run"); err != nil {
		t.Skip("systemd-run not found")
	}
	t.Setenv("GOWORK", "off")
	t.Setenv("GOTOOLCHAIN", "local")
	dir := t.TempDir()
	for name, data := range map[string]string{
		"go.mod": "module example.com/m\n\ngo 1.25\n",
		"m_test.go": `package m

import "testing"

var sink [][]byte

func TestGrows(t *testing.T) {
	for range 1 << 16 {
		b := make([]byte, 1<<20)
		for i := range b {
			b[i] = 1
		}
		sink = append(sink, b)
	}
}
`,
	} {
		if err := os.WriteFile(filepath.Join(dir, name), []byte(data), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	tr := tester{dir: dir, pkgs: []string{"."}, timeout: time.Minute, memMax: "300M"}
	res, err := tr.test(t.Context())
	if err != nil {
		t.Fatal(err)
	}
	if len(res.failed) == 0 {
		t.Errorf("a test past the memory cap did not fail: %+v", res)
	}
}

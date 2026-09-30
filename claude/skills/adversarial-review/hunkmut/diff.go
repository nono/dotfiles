package main

import (
	"bufio"
	"errors"
	"fmt"
	"regexp"
	"slices"
	"strconv"
	"strings"
)

// hunk is one change of a zero-context diff.
type hunk struct {
	newStart int      // first line in the head file; with newCount 0, the line after which oldLines go
	newCount int      // lines the hunk holds in the head file
	oldLines []string // lines at the base
	newLines []string // lines at the head
}

// fileDiff is the change of one file.
type fileDiff struct {
	path    string // path at the head; the base path of a deleted file
	added   bool
	deleted bool
	hunks   []hunk
}

var hunkHeader = regexp.MustCompile(`^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@`)

// parseDiff reads the output of git diff -U0 --no-renames.
func parseDiff(text string) ([]fileDiff, error) {
	var files []fileDiff
	var cur *fileDiff
	var h *hunk
	flush := func() {
		if h != nil {
			cur.hunks = append(cur.hunks, *h)
			h = nil
		}
	}
	sc := bufio.NewScanner(strings.NewReader(text))
	sc.Buffer(make([]byte, 1024*1024), 64*1024*1024)
	for sc.Scan() {
		line := sc.Text()
		switch {
		case strings.HasPrefix(line, "diff --git "):
			if cur != nil {
				flush()
			}
			files = append(files, fileDiff{})
			cur = &files[len(files)-1]
		case cur == nil:
			return nil, fmt.Errorf("diff line before any file header: %q", line)
		case h == nil && strings.HasPrefix(line, "new file mode"):
			cur.added = true
		case h == nil && strings.HasPrefix(line, "deleted file mode"):
			cur.deleted = true
		case h == nil && strings.HasPrefix(line, "--- a/"):
			cur.path = strings.TrimRight(strings.TrimPrefix(line, "--- a/"), "\t")
		case h == nil && strings.HasPrefix(line, "+++ b/"):
			cur.path = strings.TrimRight(strings.TrimPrefix(line, "+++ b/"), "\t")
		case strings.HasPrefix(line, "@@ "):
			flush()
			m := hunkHeader.FindStringSubmatch(line)
			if m == nil {
				return nil, fmt.Errorf("malformed hunk header: %q", line)
			}
			start, _ := strconv.Atoi(m[1])
			count := 1
			if m[2] != "" {
				count, _ = strconv.Atoi(m[2])
			}
			h = &hunk{newStart: start, newCount: count}
		case h != nil && strings.HasPrefix(line, "+"):
			h.newLines = append(h.newLines, line[1:])
		case h != nil && strings.HasPrefix(line, "-"):
			h.oldLines = append(h.oldLines, line[1:])
		}
	}
	if err := sc.Err(); err != nil {
		return nil, err
	}
	if cur != nil {
		flush()
	}
	for _, f := range files {
		if f.path == "" {
			return nil, errors.New("a file of the diff has no a/ or b/ path")
		}
	}
	return files, nil
}

// revertHunk returns the head lines with h put back to its base lines.
func revertHunk(lines []string, h hunk) ([]string, error) {
	at := h.newStart - 1
	if h.newCount == 0 {
		at = h.newStart
	}
	if at < 0 || at+h.newCount > len(lines) || !slices.Equal(lines[at:at+h.newCount], h.newLines) {
		return nil, fmt.Errorf("hunk at line %d does not match the head file", h.newStart)
	}
	return slices.Concat(lines[:at], h.oldLines, lines[at+h.newCount:]), nil
}

// commentOnly reports whether every line h changes is blank or a line comment.
func commentOnly(h hunk) bool {
	for _, l := range slices.Concat(h.oldLines, h.newLines) {
		if t := strings.TrimSpace(l); t != "" && !strings.HasPrefix(t, "//") {
			return false
		}
	}
	return true
}

// splitLines splits a file into lines and says whether it ends with a newline.
func splitLines(data string) ([]string, bool) {
	trailing := strings.HasSuffix(data, "\n")
	data = strings.TrimSuffix(data, "\n")
	if data == "" {
		return nil, trailing
	}
	return strings.Split(data, "\n"), trailing
}

func joinLines(lines []string, trailing bool) string {
	s := strings.Join(lines, "\n")
	if trailing {
		s += "\n"
	}
	return s
}

#!/usr/bin/env bash
# Lists the open PRs of the current user, with the commits of the base that each PR lacks and the files that
# conflict when the base is merged. Run it inside a clone of the repository.
set -Eeuo pipefail

git fetch -q origin

printf '%-5s %-7s %-9s %-40s %s\n' PR BEHIND CONFLICTS BASE TITLE
gh pr list --author @me --state open --limit 100 --json number,title,baseRefName,headRefName \
	--jq '.[] | [.number, .baseRefName, .headRefName, .title] | @tsv' |
	while IFS=$'\t' read -r number base head title; do
		if ! git rev-parse -q --verify "origin/$head^{commit}" >/dev/null; then
			printf '%-5s %-7s %-9s %-40s %s\n' "$number" '?' '?' "$base" "$title (no origin/$head)"
			continue
		fi
		behind=$(git rev-list --count "origin/$head..origin/$base")
		# Exit 1 means conflicts: the lines after the tree id, up to the first blank line, name the conflicted files.
		status=0
		out=$(git merge-tree --write-tree --name-only "origin/$head" "origin/$base" 2>&1) || status=$?
		case $status in
		0) conflicts=0 ;;
		1) conflicts=$(printf '%s\n' "$out" | sed -n '2,/^$/p' | grep -c . || true) ;;
		*) conflicts='?' ;;
		esac
		printf '%-5s %-7s %-9s %-40s %s\n' "$number" "$behind" "$conflicts" "${base:0:40}" "$title"
	done

---
name: file-story
description: Use when asked to file, create, open or write a Shortcut story, ticket or bug report.
allowed-tools: "Bash(scut story create:*), Bash(scut field values:*)"
---

# File a story

Create one Shortcut story with the command of step 3. Do not ask for its fields. A
follow-up story gets the same fields: it goes in To Do, never in Backlog.

## Steps

1. Pick the Technical Area. `Back end` is the default. Use another value only when
   the story is about that area (for example `UI` for a UI change). The values are in
   `scut field values "Technical Area"`.
2. Write the story:
   - Name: a short description with a capital first letter and no final period.
     No `sc-NNNN` in it: the branch name comes from the name, and Shortcut links
     the PR to each story ID in the branch name.
   - Type: feature, bug or chore, from the request.
   - Description, in a file in your scratchpad: the problem, then what done means.
     Use ASD-STE100 Simplified Technical English and few words. A cause names the
     file and line that show it; else write "Cause: not known" and give the evidence.
3. Create the story with this one command:

   ```sh
   scut story create --name "<name>" --type <type> --description-file <file> \
     --team "Software Dev" --workflow Standard --state "To Do" \
     --requester @me --owner @me --field "Technical Area=<value>"
   ```

   - Exit 3: a name does not match, and `valid` lists the names. Stop and tell the
     user. Do not pick a near match.
   - Exit 5: the story can exist. Read `suggestion` before you create it again.

   Reply with its `sc-NNNN` ID, URL and the Technical Area you picked, with the reason
   if it is not `Back end`.

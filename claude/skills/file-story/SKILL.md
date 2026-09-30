---
name: file-story
description: Use when asked to file, create, open or write a Shortcut story, ticket or bug report.
---

# File a story

Create one Shortcut story with the fields below. Do not ask for them. A follow-up
story gets the same fields: it goes in To Do, never in Backlog.

| Field | Value |
|-------|-------|
| Team | Software Dev |
| Workflow | Standard |
| State | To Do |
| Requester | Bruno Michel |
| Owner | Bruno Michel |
| Technical Area | Back End, unless another value fits better |

## Steps

1. Load the Shortcut tools with `ToolSearch` (query `shortcut`). Absent: stop with
   "open a session in ~/ts/main; the Shortcut tools exist only there".
2. Find the IDs by name: the team, the Standard workflow and its To Do state, the
   current user (Bruno Michel), and the Technical Area custom field and its values.
   A name that does not match: stop and tell the user. Do not pick a near match.
   In the Standard workflow (500000005), To Do is 500000007. Always pass
   `workflow_state_id` to `stories-create`: the default state is Backlog.
3. Pick the Technical Area. Back End is the default. Use another value only when
   the story is about that area (for example Front End for a UI change).
4. Write the story:
   - Name: a short description with a capital first letter and no final period.
   - Type: feature, bug or chore, from the request.
   - Description: the problem, then what done means. Use ASD-STE100 Simplified
     Technical English and few words.
5. Create the story. Reply with its `sc-NNNN` ID, URL and the Technical Area you
   picked, with the reason if it is not Back End.

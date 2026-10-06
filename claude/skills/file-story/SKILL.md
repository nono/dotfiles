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
2. Use the IDs of the "Known IDs" table below. When a call fails on one, or the
   Technical Area you need is not in the table, find it by name: the team, the
   Standard workflow and its To Do state, the current user (Bruno Michel), or the
   Technical Area custom field and its values. A name that does not match: stop and
   tell the user. Do not pick a near match.
   In the Standard workflow (500000005), To Do is 500000007. Always pass
   `workflow_state_id` to `stories-create`: the default state is Backlog.
3. Pick the Technical Area. Back End is the default. Use another value only when
   the story is about that area (for example Front End for a UI change).
4. Write the story:
   - Name: a short description with a capital first letter and no final period.
   - Type: feature, bug or chore, from the request.
   - Description: the problem, then what done means. Use ASD-STE100 Simplified
     Technical English and few words.
5. Create the story with `stories-create`. It takes no custom field and no requester,
   so then call `stories-update` on the new story with `requested_by_id`, `owner_ids`
   and `custom_fields: [{field_id: <Technical Area>, value_id: <value>}]`. Reply with
   its `sc-NNNN` ID, URL and the Technical Area you picked, with the reason if it is not
   Back End.

## Known IDs

| Name | ID |
|------|----|
| Team Software Dev | `659d5a5b-8dfb-475d-b664-5068e9d1d778` |
| Bruno Michel | `6a8c3277-6d3f-46ad-8e2b-614269613f8f` |
| Technical Area field | `659d5a5b-08b2-4eb1-b29f-703a73481c90` |
| Technical Area "Back end" | `659d5a5b-08aa-4af3-b3d0-d03dc9e0846c` |
| Technical Area "Testing" | `66713d55-4e6f-47b6-a605-55688b30450a` |

# Smart List Entries and Preview

## Core idea
The Entries tab defines the choices a user can select; Preview lets an administrator inspect the configured list before using it.

## Entry fields

| Field | Purpose |
|---|---|
| ID | Unique numeric identifier and ordering value; customizable when automatic ID generation is disabled |
| Name | Unique programmatic identifier using alphanumeric characters and underscores |
| Label | Text shown in the drop-down |

Oracle documents adding, editing, and deleting entries, and using Preview to inspect the list. See [Defining Smart List Entries](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/adding_or_changing_smart_list_entries.html) and [Previewing Smart Lists](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/previewing_smart_lists.html).

## Manage changes carefully

1. Review dependencies before changing an entry: member formulas, rules, integrations, data mappings, reporting, and historical comparisons.
2. Decide whether an ID/name/label change affects a consumer. These fields serve different purposes; do not assume that changing one is equivalent to changing another.
3. Record the before/after definition and test the affected forms and calculations in a nonproduction environment.
4. Use Preview to check labels and order, then test a saved value with an appropriate user.
5. For deletion or ID changes, plan recovery and historical-data checks. Oracle permits entry deletion; the impact on this project's consumers is not known until tested.

A raw number displayed after an entry change may have several causes. Do not call it an “orphan ID” or prescribe recreating an entry until the value, definition history, and target behavior have been verified.

## Illustrative example

A hypothetical list contains ID 1 / Name Prior_Year / Label Prior Year and ID 2 / Name Manual / Label Manual. If users request a clearer label, test a label-only change separately from changes to IDs or names. This is **illustrative**, not a production rule.

## Troubleshooting

| Symptom | Check |
|---|---|
| Duplicate or missing choices | Entry uniqueness, saved changes, member association, and access filter |
| Unexpected order | Display Order property: ID, Name, or Label |
| Entry is present in Preview but absent for one user | Minimum Access Required and the user's member permissions if list is hierarchy-based |
| Historical value renders unexpectedly after a list change | Compare prior entry definitions, member/data context, and target rendering; reproduce in a safe environment |

## Recall

**Question:** Which property is shown to a planner? Which one is the programmatic name? What should be checked before deleting an entry?

**Answer:** Label is user-facing; Name is the programmatic identifier. Check all rule, formula, integration, reporting, and historical uses, then test and retain a recovery path.

**Teach-back:** Describe how you would make a requested wording change without accidentally changing the choice identity used by a calculation.

## Oracle sources checked 2026-10-30

- [Defining Smart List Entries](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/adding_or_changing_smart_list_entries.html)
- [Previewing Smart Lists](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/previewing_smart_lists.html)
- [Smart List Properties](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/adding_or_changing_smart_list_properties.html)

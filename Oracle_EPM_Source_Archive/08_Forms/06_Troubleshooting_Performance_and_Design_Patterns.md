# 06 — Form troubleshooting and design patterns

## Core idea

Troubleshoot a form by reproducing the user’s exact context, changing one factor at a time, and comparing expected versus actual behavior. Avoid universal performance thresholds or fixes that are not supported by evidence.

## Repeatable diagnostic path

~~~mermaid
flowchart TD
 A[Record form version, client, user, POV, and time] --> B[Reproduce the same symptom]
 B --> C{Which area—}
 C -->|Layout or missing data| D[Check axes, members, filters, and suppression]
 C -->|Cannot edit| E[Check cell reason, security, approvals, validity, and form settings]
 C -->|Save or rule| F[Check validation, prompts, rule event, and job outcome]
 C -->|Slow response| G[Measure grid size, rules, formulas, and data retrieval separately]
 D --> H[Change one setting and retest]
 E --> H
 F --> H
 G --> H
 H --> I[Record expected and actual results]
~~~

## Diagnose by symptom

| Symptom | Checks |
|---|---|
| Empty or unexpectedly small grid | POV/page choices, member selections, access, scenario date range, valid intersections, row/column suppression |
| Missing zero or formula result | Missing/zero suppression, formula columns, Database Suppression caveat, form version |
| Cell is read-only | Read-only form/segment, cell-level security, invalid intersection, approval status, member storage/type, user access |
| Save appears incomplete | Validation messages, form version, Autosave behavior, rule prompts, job status, Smart View submit behavior |
| Form is slow | Compare same POV and user; inspect grid size, selected members, suppression, formulas, validation rules, associated rules, Smart Push, and client/network conditions |
| Behavior differs between browser and Excel | Compare form version, Smart View options, client release, suppression settings, flex configuration, and current Oracle limits |

Do not assume “slow” means one specific setting is wrong. Record repeatable timing only as evidence for the same user, context, and client; Oracle Cloud services and data volumes vary. Do not claim a fixed load-time target or speed-up factor without a project requirement and measured baseline.

## Suppression trade-offs

Oracle documents that suppress missing blocks may improve efficiency when many rows are suppressed, but can degrade performance if few or no rows are suppressed. It also documents cases where Dynamic Calc members may be ignored and row indentation may differ. Database Suppression can reduce data on the business-process side, but formula columns returning #MISSING may be suppressed before the business-process formula evaluation. These are reasons to test, not blanket recommendations.

For a controlled before/after comparison:
1. Select a representative form, POV, user, and client.
2. Capture current row/column results and response behavior.
3. Change one suppression option.
4. Test populated, sparse, empty, zero, formula, and invalid-intersection cases.
5. Compare both the grid result and user task.
6. Keep or revert based on the expected behavior and evidence.

## Safe design habits

- Keep a clear purpose for every form and minimize unnecessary members on its axes.
- Make prompts and instructions explicit about the required POV.
- Use suppression only when users can still reach all intended data-entry intersections.
- Test rules, form security, and valid intersections using representative roles.
- Use background Smart Push only where job monitoring and reconciliation are defined.
- Re-test after switching form version or changing Smart View/flex options.
- Record the baseline, change, test cases, outcome, and owner.

## Recall check

1. Why record the user and POV during troubleshooting— Access, selected members, and data availability change the result.
2. Is Database Suppression always faster— No. Oracle documents benefits and caveats; test on the specific form.
3. What is a useful performance claim— A repeatable measurement with the context and test method stated.

**Teach-back:** Walk a reviewer through diagnosing a form that appears to have missing rows without immediately changing suppression.

## Oracle references

- [Setting Form Grid Properties](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/setting_form_grid_properties.html)
- [Why Cells May Be Read-Only](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/why_cells_may_be_read_only_100x91541c8b.html)
- [Suppressing Invalid Data in Forms](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/suppressing_invalid_data_in_forms.html)
- [About Business Rules](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/about_business_rules.html)

Checked 2026-10-30. Troubleshooting steps are diagnostic recommendations; adapt to the service and project’s actual requirements.

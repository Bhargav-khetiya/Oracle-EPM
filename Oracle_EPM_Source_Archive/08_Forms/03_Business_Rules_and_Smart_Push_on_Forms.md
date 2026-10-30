# 03 — Form business rules and Smart Push

## Core idea

A form can provide context for a business rule and can initiate a data map push. The form association does not make the rule or data movement safe by itself; prompts, access, selections, and save behavior must be tested.

## Form rule associations

Planning forms can associate rules with form events such as before/after load or before/after save. Rule properties can include prompts and whether members on the form are used as prompt values. The exact event choices and behavior depend on the form and rule configuration.

| Event | What to investigate | Test evidence |
|---|---|---|
| Before Load | Whether rule logic should run before the grid is presented | Correct values/context and understandable errors |
| After Load | Whether a rule should run once the form is loaded | No unintended writes or repeated work |
| Before Save | Whether validation or a veto should prevent a save | Invalid input is blocked with a clear message |
| After Save | Whether follow-up logic should run after data submission | Confirm saved values, prompts, and rule outcome for the form version |

Do not assume every “after save” rule has identical commit/prompt behavior in Forms 1.0 and Forms 2.0. Reproduce the exact prompt, cancel, save, and error path in the target version before documenting the sequence as a project fact. A long-running rule may be unsuitable for an interactive form; Oracle’s Planning guidance recommends keeping form-triggered rules responsive and monitoring rule execution.

**Use Members on Form** can use form members as runtime prompt values where the rule is configured for it. This does not automatically prove that the rule is limited to the intended department, entity, or selection. Inspect the rule’s prompt design and test boundary cases.

## Smart Push and data maps

Smart Push moves selected data between cubes using a configured data map. Its scope comes from the data map, form context, selection settings, and any configured override. It is not the same as saving data to the source cube.

~~~mermaid
flowchart LR
 E[User edits source form] --> S[Save source data]
 S --> R[Configured rule or Smart Push action]
 R --> D[Data map selection and mappings]
 D --> T[Target cube]
 T --> V[Reconcile expected target intersections]
~~~

This diagram is a logical sequence, not a guarantee of transaction timing or atomicity.

For a form with multiple segments, Oracle documents an Overwrite Selection pattern with an appropriate selection as a recommended way to control the data pushed. A background push can let the user continue while the push runs; this does not mean the target is immediately refreshed or that failure can be ignored. Check job status and target data.

## Safe implementation sequence

1. Define the business outcome and source/target cube.
2. Confirm the source form, form version, data map, mappings, and user access.
3. Specify the intended POV and selection in writing.
4. Decide which rules run on load/save and whether prompts use form members.
5. Test as a planner with valid, invalid, empty, and boundary selections.
6. For Smart Push, compare source and target at the exact intended intersections and inspect the job result.
7. Document exceptions, retry behavior, ownership, and reconciliation.

## Troubleshooting

| Symptom | First checks |
|---|---|
| Rule sees unexpected members | Inspect runtime prompts, “Use Members on Form,” page/POV, and rule variables |
| Save occurs but a prompt or follow-up is confusing | Reproduce on the same form version and record save/cancel/error outcomes |
| Target values are missing or too broad | Check data map mapping, selection, form context, and job result |
| User can run the rule but it fails | Check application role, form access, rule permissions, and prompt values |
| Results differ after changing form version | Re-test event order, prompt handling, Smart View, and suppression behavior |

## Recall check

1. What does a data map define? The member mappings and data selection used to move data between supported cubes.
2. Does “Use Members on Form” guarantee the correct business scope? No; verify prompt configuration and the final selection.
3. What must be checked after a background Smart Push? Its completion/result and the target intersections.

**Teach-back:** Explain the difference between saving a source form and pushing data to a target cube.

## Oracle references

- [Form Properties Panel and rule options](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/properties_panel.html)
- [Form Design Considerations](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/form_design_considerations.html)
- [About Business Rules](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/about_business_rules.html)
- [Configure Smart Push for a Form](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/diepm/configuring_smart_push_for_a_form.html)
- [Oracle Groovy and Smart Push tutorial](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/groovy-tutorial-moving-modified-data-using-groovy-and-smartpush/index.html)

Checked 2026-10-30. Rule behavior and Smart Push configuration are release- and application-dependent; verify in the target environment.

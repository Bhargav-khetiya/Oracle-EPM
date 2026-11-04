# Smart Lists: Concept and Data Model

## Core idea
A Smart List is a configured drop-down list that lets a user choose a value in supported Planning form cells instead of typing it.

**Plain language:** it is a controlled choice field attached to a Planning member. The user sees a label, while the Smart List definition also has an entry ID and a programmatic name.

> **Important boundary:** Oracle's user/admin documentation describes the logical Smart List behavior and entry properties. It does not establish that a customer can inspect a specific physical Essbase file or Cloud storage implementation. This guide makes no claims about .PAG files, block bytes, or Cloud internals.

## Why use one—

Use a Smart List when users need a small governed set of choices for a supported data-entry cell, such as a hypothetical forecast method. Use a dimension when the values must participate as independent dimensional members for slicing, security, hierarchy, or aggregation. A Smart List is not a replacement for a dimension.

Oracle describes Smart Lists as custom drop-downs in Planning form cells. Users select an item rather than type into a Smart List cell. See [Administering Smart Lists](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/sm_lists.html).

## Logical flow

~~~mermaid
flowchart LR
 A[Admin defines list entries] --> B[Associate list with supported member]
 B --> C[User opens form cell]
 C --> D[Selects a list item]
 D --> E[Planning displays configured label]
 D --> F[Rule/formula may reference supported Smart List value]
~~~

This is the documented user-facing model. It does not describe physical SaaS storage.

## Entry properties

| Property | Meaning | Design note |
|---|---|---|
| ID | Unique numeric entry identifier and sort value | Can be customized when automatic ID generation is disabled; plan changes carefully when data or integrations depend on values. |
| Name | Unique programmatic name using supported characters | Oracle formula expressions can reference Smart Lists; keep names stable and meaningful. |
| Label | Text displayed to users in the drop-down | Optimize for clarity; label changes and ID changes are different changes. |

See [Defining Smart List Entries](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/adding_or_changing_smart_list_entries.html). Do not infer physical persistence or claim that an ID change is harmless/damaging without testing the use cases and data involved.

## Evaluation order

For a Smart List to be viewable in forms, Oracle says the dimension to which the Smart List-type member belongs must be first in the evaluation order. The correct dimension is not universally Account. Check the relevant cube and member; see [Managing Dimensions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/managing_dimensions.html) and [Smart List Properties](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/adding_or_changing_smart_list_properties.html).

## Illustrative example

A hypothetical account member called Forecast Method could be associated with entries such as “Prior Year,” “Three-Year Average,” and “Manual.” A user selects one in a form; a rule may use the selected Smart List through supported Calculation Manager syntax. This is an **illustrative** teaching example, not a project configuration.

## Configure and validate

1. Confirm the cell is intended for a controlled choice and that a Smart List is appropriate instead of a dimension.
2. Create the list and define unique IDs, names, and clear labels.
3. Associate it with the intended member and configure the relevant cube/evaluation order.
4. Set missing-value display behavior to fit the form.
5. Preview entries, then test with users who have different access levels.
6. Test save, retrieval, rule/formula use, Smart View if in scope, and any cross-cube/data-map behavior.
7. Before changing IDs, deleting entries, or synchronizing lists, identify dependencies and historical reporting impacts; test a controlled change.

## Troubleshooting

| Symptom | Check |
|---|---|
| Cell shows a number or no drop-down | Member data type/list association, form configuration, and evaluation order |
| Item is absent from drop-down | List entries, member association, access settings when based on members, and filters |
| Blank value displays unexpectedly | Smart List missing-label options and form missing-value display setting |
| Rule gives unexpected result | Insert/use supported Smart List expression; verify entry identity and tested value in the correct cube |
| Cross-cube values render differently | Confirm target metadata/list mapping and test actual supported data-map behavior; do not assume IDs transfer safely |

## Remember and explain

**Recall:** What is a Smart List— What are ID, Name, and Label— Which dimension belongs first in evaluation order— When is a dimension a better design choice—

**Answer key:** A Smart List is a controlled drop-down for supported form cells. ID is the unique numeric entry, Name is the programmatic key, and Label is user-facing. The dimension associated with the Smart List-type member must be first in evaluation order. Use a dimension when values must behave as independent members for analysis/security/hierarchy.

**Teach-back:** Explain a Smart List to a new planner without describing unsupported storage internals, then describe how you would validate its display and calculation use.

## Oracle sources checked 2026-10-30

- [Administering Smart Lists](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/sm_lists.html)
- [Smart List Properties](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/adding_or_changing_smart_list_properties.html)
- [Smart List Entries](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/adding_or_changing_smart_list_entries.html)
- [Managing Dimensions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/managing_dimensions.html)

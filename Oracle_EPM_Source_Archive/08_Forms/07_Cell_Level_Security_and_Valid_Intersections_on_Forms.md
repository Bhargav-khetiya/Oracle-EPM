# 07 — Cell-level security and valid intersections on forms

## Core idea

Cell-level security controls who may read or write data at member intersections; valid intersections control which combinations of members are allowed for data entry. They solve different problems and must not be used as substitutes.

## Compare the controls

| Control | Question it answers | Scope and effect |
|---|---|---|
| Member security | Which dimension members can this user access— | Baseline data access throughout the application |
| Cell-level security (CLS) | At which intersections should this user/group have read or write access denied— | An exception to regular member security, applying where cells are shown, including forms and Smart View |
| Valid intersections (VI) | Which combinations of dimension members are valid for data entry— | Marks combinations valid or invalid; invalid cells are read-only and may be suppressed on forms |
| Form/segment read-only | Can users edit through this form layout— | Form interaction only; it is not general data security |
| Artifact access | Can a user open a form or folder— | Access to the artifact itself, separate from cell data rights |

Oracle describes cell-level security restrictions as Deny Read or Deny Write. A user with read access can view data but cannot edit it; a user denied read access sees #NoAccess. Service Administrators are not affected by cell-level security. Test rules with the actual user/group and the test facility or an equivalent non-admin account.

## Valid intersections mental model

A valid intersection rule restricts combinations, such as allowing a certain account only for a certain department. In each rule group, an anchor dimension is required. Nonanchor dimensions can be required or optional according to the design. Groups may overlap; inspect the documented group evaluation and overlap behavior before assuming one rule overrides another.

A valid intersection is a data-entry filter, not a confidentiality control. If users must not see a value, design security accordingly.

~~~mermaid
flowchart LR
 U[User identity and member security] --> C[Cell-level security exception]
 C --> R[Read or write access at an intersection]
 V[Dimension combination] --> I[Valid intersection rule]
 I --> E[Entry allowed or cell read-only]
~~~

## Worked illustrative example

Suppose a planning application has Department and Account dimensions. The business says that only Research departments may enter a specific R&D account. A valid intersection rule can constrain permitted combinations. If the value must also be hidden from certain users, member security or cell-level security must separately address visibility. This is illustrative; it is not a known project requirement.

## Design and test procedure

1. Identify the business requirement: visibility, editability, or allowed combinations.
2. Map the relevant dimensions, cubes, users/groups, and existing member security.
3. Choose the appropriate control; document why.
4. For CLS, confirm deny-read versus deny-write, target groups/users, anchor and nonanchor dimensions, and cube applicability.
5. For valid intersections, confirm anchor settings, required nonanchor dimensions, member selections/exclusions, and overlapping groups.
6. Test as representative users, including a Service Administrator only as a comparison.
7. Verify the result in the web form and Smart View or other clients used by the team.
8. Record expected and actual access, including invalid cells and suppression.

Do not infer an internal security engine, storage schema, or evaluation sequence from the UI. Use Oracle’s documented functional behavior and the project’s tested configuration.

## Troubleshooting read-only cells

A read-only cell can result from several controls. Review the user-facing reason where available, then check: form and segment settings, member security, cell-level security, valid intersections, approval status, member properties, and user access. A missing member or invalid member can also explain unexpected behavior.

## Recall check

1. Which control governs allowed member combinations— Valid intersections.
2. Which control can deny reading a value at a specific intersection— Cell-level security.
3. Does valid intersection make a value confidential— No.
4. Does a form read-only setting replace data security— No.

**Teach-back:** Explain to a reviewer why “this combination is not valid” and “this user must not see this value” need different controls.

## Oracle references

- [Valid Intersections and Cell-Level Security overview](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/defining_valid_intersections_and_cell_level_security_chapter_intro.html)
- [Creating Valid Intersections](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/creating_valid_intersections.html)
- [Valid Intersection Rules](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/valid_intersection_rules.html)
- [Defining Cell-Level Security](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/defining_cell_level_security.html)
- [Why Cells May Be Read-Only](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/why_cells_may_be_read_only_100x91541c8b.html)
- [Suppressing Invalid Data in Forms](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/suppressing_invalid_data_in_forms.html)

See also the [Security and Access guide](../01_Security_and_Access/Oracle_EPM_Access_Control_Master_Guide.md) and [Valid Intersections guide](../01_Security_and_Access/Oracle_EPM_Valid_Intersections_Master_Guide.md).

Checked 2026-10-30. Rule interactions and availability depend on application configuration; confirm against current Oracle documentation and test data.

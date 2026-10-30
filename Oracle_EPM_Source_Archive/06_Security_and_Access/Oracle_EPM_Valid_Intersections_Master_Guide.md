# Planning Valid Intersections: Beginner-to-Consultant Guide

## Core idea
A valid intersection group filters which dimensional combinations are offered or accepted in relevant Planning data-entry and member-selection contexts.

**Plain language:** a planning cube may contain combinations that do not make business sense. A rule can guide users toward allowed combinations. This feature is not a user permission and does not replace security.

> **Scope:** This guide describes Oracle Planning behavior. Confirm cube, form, and release applicability in the current documentation.

## Why it matters and where it applies

Oracle documents valid-intersection rules for filtering data entry, member selection, and runtime prompts. On a form, invalid cells may be read-only or suppressed depending on form configuration. A rule is not a guarantee that all existing stored data has been removed, nor a substitute for access control. See [Creating Valid Intersections](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/creating_valid_intersections.html) and [Dimension Design Considerations](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/dimension_design_considerations.html).

~~~mermaid
flowchart LR
 U[User selects or enters members] --> C{Combination evaluated}
 C -->|Allowed by configuration| A[Member/data-entry action can proceed]
 C -->|Invalid for context| R[Filtered, read-only, or suppressed per interface]
 S[User permissions] -. independently determine access .-> C
~~~

The diagram separates intersection filtering from permissions; exact interface behavior depends on setup.

## The group model

A group contains a **definition type** (Valid Intersection or Invalid Intersection), an **anchor dimension**, optional **nonanchor dimensions**, and one or more rules.

- The anchor dimension is required for evaluation in the cube.
- Nonanchor dimensions can be marked required or not required. If a required dimension is absent from the cube, the group is ignored for that cube. A nonrequired missing dimension can leave other dimensions in the group still evaluated.
- Unselected anchor members are valid by default. Clearing **Unselected Members are Valid** makes unselected anchor members invalid under the documented rules.
- Rules use the dimensions defined by the group and can include or exclude members, substitution variables, and attributes as supported.

These are consequential design settings. See Oracle's [Anchor and Nonanchor Dimensions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/approval_group_anchor_and_nonanchor_dimensions.html) only if that page applies to the feature being discussed; for valid intersections specifically use [Valid Intersection Examples](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/valid_intersection_examples.html).

## Choosing valid or invalid

| Definition | Use when | Design question |
|---|---|---|
| Valid Intersection | The rule describes combinations to allow. | What happens to anchor members not listed? |
| Invalid Intersection | The rule describes combinations to reject. | Which other combinations remain valid? |

Choose based on the real rule and tested outcomes, not an unverified claim that one type is always faster. Oracle documents both types and their precedence behavior. Start with the [rule examples](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/valid_intersection_examples.html).

## How overlaps are evaluated

Oracle documents these important cases:

- Overlapping rules within the **same group** mark an intersection valid if either rule condition is met.
- Rules across **different groups** must satisfy the requirements of all applicable groups.
- If any applicable group marks an intersection invalid, that invalid result overrides another group's valid result.

Therefore, group order should not be described as a simple “first match wins” evaluation. Test overlaps with actual members and cube dimensionality. See [Valid Intersection Rules](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/valid_intersection_rules.html) and [Valid Intersection Examples](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/valid_intersection_examples.html).

## Illustrative example

Suppose a hypothetical company allows products in the Computer Equipment branch only for manufacturing entities. Define a group using Entity as anchor and Product as nonanchor, then specify the member sets. The anchor choice and unselected-member setting affect what happens outside the stated member sets. This example is **illustrative** and is not a project requirement.

Before implementation, make a truth table of expected valid/invalid cases, including:
- listed Entity + listed Product;
- listed Entity + unlisted Product;
- unlisted Entity + listed Product;
- a cube missing the nonanchor dimension;
- overlapping rules and shared members if present.

## Configure and validate

1. Confirm the Planning service, cube, dimensions, and interface where the rule is needed.
2. Translate the business rule into explicit expected valid/invalid member combinations.
3. Choose the anchor dimension deliberately; document required/nonrequired dimensions and the unselected-member setting.
4. Select Valid or Invalid definition type based on the actual rule.
5. Add rules and member selections; review exclusions and overlaps.
6. Test representative combinations in forms and runtime prompts where applicable.
7. Check form behavior: invalid intersections may be read-only; suppression can hide invalid rows/columns where configured.
8. Check users with different permissions separately. The feature does not grant access.
9. Record test cases, expected/actual results, cube, form, and release.

## Troubleshooting

| Symptom | Likely area to inspect |
|---|---|
| Too many combinations disappear | Anchor dimension, unselected members setting, required dimensions, overlapping groups |
| Invalid cells remain visible | Form suppression/display settings; visibility does not imply the combination is valid |
| Member selector shows unexpected choices | Which dimensions are on the page/selector and whether the group applies in that cube |
| Rule behaves differently in another cube | Cube dimensionality and required/nonrequired nonanchor settings |
| User cannot enter an otherwise valid combination | Member permissions, cell-level security, workflow state, form design, and valid intersections are separate checks |
| Existing data appears in newly invalid cells | Determine whether data is stored and what approved cleanup process applies; never clear data without impact review and backup/approval |

## Remember and explain

**Recall:** What does the feature filter? What does the anchor dimension control? What is the difference between same-group and cross-group overlap? Does a valid intersection authorize a user?

**Answer key:** It filters dimensional combinations in relevant entry/selection contexts. The anchor is required and controls how unselected members are treated. Same-group overlaps use the documented either-rule behavior; groups combine requirements, with invalid results overriding valid. Authorization remains a separate security concern.

**Teach-back:** Explain one allowed and one blocked case, then explain how you would distinguish a valid-intersection issue from a permission issue.

## Oracle sources checked 2026-10-30

- [Creating Valid Intersections](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/creating_valid_intersections.html)
- [Valid Intersection Rules](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/valid_intersection_rules.html)
- [Valid Intersection Examples](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/valid_intersection_examples.html)
- [Dimension Design Considerations](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/dimension_design_considerations.html)
- [Types of Access Permissions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/types_of_access_permissions.html)

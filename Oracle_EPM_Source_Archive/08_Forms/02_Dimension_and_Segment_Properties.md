# 02 — Dimension axes, member display, and segments

## Core idea

The form layout places dimensions on axes and selects members for the user’s working context. Axis placement controls the shape of the grid; dimension and segment properties control how those selections appear and behave.

## The four layout areas

| Area | Beginner explanation | Typical use |
|---|---|---|
| Point of View (POV) | Context applied to the grid, often selected above it | Scenario, Version, Year, Currency |
| Page | A selector that changes a dimension’s members for the displayed grid | Entity or Department |
| Rows | Members listed vertically | Account or Product |
| Columns | Members listed horizontally | Period or Scenario |

This is a conceptual example, not a statement about this project’s application design. A dimension’s placement and available members depend on the application, cube, and form definition.

~~~mermaid
flowchart TB
 C[Application cube and dimensions] --> L[Form layout: POV, page, rows, columns]
 L --> M[Member selections and user access]
 M --> G[Grid presented to the user]
~~~

## Dimension display properties

Oracle documents form dimension properties for the POV, page, row, and column areas. Common choices include displaying the member name, alias, or member formula; hiding a dimension; showing consolidation operators; expanding row/column members at open; and drilling on shared members in applicable hierarchy cases.

| Property | What a user sees or does | Care point |
|---|---|---|
| Member Name / Alias | Shows the technical member name, friendly alias, or configured combination | Confirm the alias table and user terminology |
| Member Formula | Permits viewing member formulas where supported | This displays a formula; it does not create an outline formula |
| Hide dimension | Hides the dimension in the visible layout | Hiding is not the same as removing its POV/member context |
| Show consolidation operators | Shows operators such as + where applicable | User preferences may affect display; verify the form setting |
| Start expanded | Opens row/column members expanded | Test usability and grid size with the actual hierarchy |
| Drill on shared members | Allows drilling on shared members in the documented hierarchy case | Do not assume it applies to every shared-member layout |
| Flex beyond form definition | In flex forms, can allow Smart View users to add row/column members beyond the form definition | Available only for flex forms and row/column dimensions; respect documented limitations |
| Row width | Sets row header width, including standard and custom sizing choices | Check long aliases and Smart View presentation |

Use “Apply to all” carefully. It propagates selected properties to dimensions in the relevant area; set the intended values first and inspect each affected dimension afterward.

## Segments

A segment is a row or column portion of the layout. Segment controls can affect display, editability, hierarchy presentation, suppression, and width. The exact current controls depend on form version and designer interface, so confirm each option’s description in the live designer rather than inferring from a screenshot.

The original notes include a historical extraction for “Column B” with values such as a 100-pixel width, missing-data suppression, and invalid Scenario/Time Period suppression. Treat those values as an unverified example, not a project requirement. Confirm the form, date, cube, and current setting before reusing them.

When changing a segment:
1. Select the row or column segment in the form designer.
2. Review its current properties and affected dimensions.
3. Change one behavior at a time.
4. Save, reopen, and test with representative data and user access.
5. Check the web form and Smart View separately if both are used.

A segment marked read-only does not override the user’s broader security grants; it constrains that form’s interaction. Likewise, hiding a segment does not make its data secure.

## Worked illustrative layout

A budget form might put Entity on Page, Account on Rows, Period on Columns, and Scenario/Version in the POV. A planner selects one Entity and enters monthly Budget values for the chosen Account members. If the business needs cross-entity comparison, a page selector may be a poor fit; the design decision should follow the business task, security, and usability requirements.

## Validation checklist

- Every dimension appears in the intended layout area.
- The POV and page selections produce the expected intersections.
- Names and aliases are understandable and unambiguous.
- Expanded hierarchies do not produce an unmanageable grid.
- Shared-member drilling works only where intended.
- Segment hide/read-only/suppression settings match the task.
- The same layout behaves as expected in the supported web and Smart View clients.

## Recall check

1. What does Page do compared with POV— Both constrain context, but Page is presented as a user-facing selector for the form grid.
2. Does hiding a dimension remove its context— No.
3. Does a read-only segment secure the data everywhere— No; it only affects form interaction.

**Teach-back:** Sketch a four-axis form for a simple monthly budget and explain why each dimension belongs on its chosen axis.

## Oracle references

- [Setting Dimension Properties](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/setting_dimension_properties_330.html)
- [Setting Form Grid Properties](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/setting_form_grid_properties.html)
- [Form Design Considerations](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/form_design_considerations.html)
- [Designing Flex Forms](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/designing_flex_forms_100xe1ae74d7.html)

Checked 2026-10-30. The Oracle documentation describes Planning Cloud behavior; verify exact options in the target service release and form version.

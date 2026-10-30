# Planning Forms: Design, Validation, and Smart View

This folder covers form layout, data entry, suppression, validation, attached business rules, Smart View options, and Groovy. It also contains notes about internal implementation; treat those claims as unverified unless Oracle publishes them for the applicable Cloud service.

## Learning order

1. [Grid and display properties](01_Grid_and_Display_Properties.md)
2. [Dimension and segment properties](02_Dimension_and_Segment_Properties.md)
3. [Business rules and Smart Push](03_Business_Rules_and_Smart_Push_on_Forms.md)
4. [Smart View and flex forms](04_Smart_View_Prediction_and_Printing_Options.md)
5. [Format and validation rules](05_Format_and_Validation_Rules_Engine.md)
6. [Troubleshooting and design](06_Troubleshooting_Performance_and_Design_Patterns.md)
7. [Cell security and valid intersections](07_Cell_Level_Security_and_Valid_Intersections_on_Forms.md)
8. [Groovy and form context](08_Groovy_Rules_and_Form_Context_API.md)
9. [Artifact lifecycle and technical boundaries](09_Form_Layout_Internals_and_XML_Repository.md)

## Safe mental model

A form defines a user-facing data grid: POV/page/row/column member selections, display settings, suppression, validation, and optional rule associations. The exact behavior depends on form version, cube, application, user access, client interface, and release.

~~~mermaid
flowchart LR
 D[Form definition and dimensions] --> Q[Data retrieval and suppression]
 Q --> U[User entry and validation]
 U --> S[Save and associated rule]
 S --> P[Optional configured data map/Smart Push]
~~~

This is a conceptual flow, not an assertion about private server internals or timing.

## Review boundaries

- Suppression settings have different purposes and caveats; test the intended form and Smart View behavior.
- “Run on load/save” and “Use Members on Form” affect rule launch/prompt behavior; they do not guarantee that a rule is scoped safely.
- Valid intersections, cell-level security, artifact permission, workflow, and form read-only settings are distinct.
- Flex Forms are a Smart View feature with documented limits; edits to row members affect submit workflow.
- Do not cite HSP_* table names, XML shapes, kernel classes, physical files, thresholds, or benchmark values as Cloud facts unless an Oracle source establishes them.
- Every example must be labeled project-specific or illustrative and tested in its intended product/version.

## Official Oracle starting points

- [Form grid properties](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/setting_form_grid_properties.html)
- [Display properties](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/setting_display_properties.html)
- [Form design considerations](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/form_design_considerations.html)
- [Validation rules in forms](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/including_data_validation_rules_in_forms.html)
- [Smart View form options](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/setting_smart_view_form_options_100x672ac700.html)
- [Groovy API reference](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/groov/index.html)

See [review coverage](../_review/coverage.csv) and [Oracle source register](../_review/oracle_sources.md).

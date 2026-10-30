# Oracle Planning Smart Lists

This folder explains the Smart List feature, configuration, entries, rule usage, and safe design review. It does not describe Cloud physical storage internals.

## Reading order

1. [Concept and data model](01_Smart_Lists_Architecture_and_Storage_Physics.md)
2. [Properties](02_Properties_Tab_Exhaustive_Guide.md)
3. [Entries and preview](03_Entries_Tab_and_Preview_Tab.md)
4. [Calculation Manager](04_Calculation_Manager_and_Business_Rules_Integration.md)
5. [Illustrative scenarios and review questions](05_Real_World_Scenarios_Troubleshooting_and_Interview_Mastery.md)

## Key distinctions

- ID identifies/orders an entry; Name is programmatic; Label is user-facing.
- The dimension associated with a Smart List-type member must be first in evaluation order for the list to appear in forms. It is not always Account.
- Hierarchy-based lists can honor member security; filtering options does not grant access.
- Use a dimension when choices need independent hierarchy, slicing, security, or aggregation.
- Before changing IDs/entries, check formulas, integrations, history, and reporting; test in context.
- Do not infer SaaS file layout from the logical Smart List model.

## Oracle sources

[Administering Smart Lists](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/sm_lists.html) · [Smart List Properties](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/adding_or_changing_smart_list_properties.html) · [Smart List Entries](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/adding_or_changing_smart_list_entries.html) · [Evaluation Order](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/managing_dimensions.html) · [Calculation Manager insertion](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/ecalc/inserting_smart_lists.html)

See [coverage tracker](../_review/coverage.csv) and [Oracle source register](../_review/oracle_sources.md).

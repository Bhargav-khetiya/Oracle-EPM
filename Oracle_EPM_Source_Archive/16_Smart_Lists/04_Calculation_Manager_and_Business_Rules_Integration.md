# Smart Lists in Calculation Manager and Rules

## Core idea
Calculation Manager can reference Smart List choices in supported Planning formulas and scripts.

Oracle documents inserting Smart Lists into variables and formula, script, condition, and member-range components. Use the insertion controls and confirm generated syntax in the target application. See [About Smart Lists](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/ecalc/about_smart_lists.html) and [Inserting Smart Lists](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/ecalc/inserting_smart_lists.html).

Documented syntax includes:

~~~text
[[SLName.entryname]]
~~~

Illustrative formula:

~~~text
IF ("Forecast Method" == [[Forecast_Method.Manual]])
  "Forecast Result" = "Manual Input";
ENDIF
~~~

Oracle documents that the entry expression resolves to its configured numeric ID in the formula. This example is not a tested project rule.

## Safe rule workflow
1. Confirm application, cube, member type/list association, and target scope.
2. Define expected outcomes for each entry, including missing values.
3. Insert the Smart List using Calculation Manager's supported UI.
4. Check generated syntax and dimensional scope.
5. Test each choice in a safe environment and compare expected/actual results.
6. Record release, test members, result, and owner.

## Groovy and data movement boundary
Groovy has a separate API/context. Do not use copied methods such as getSmartListText or setSmartList unless the current Oracle API reference documents them for that context. Likewise, do not assume Smart List IDs transfer unchanged between cubes through a data map. Verify target metadata, mappings, and actual results. See [Creating a Groovy Rule](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/epbca/creating_a_groovy_rule_about.html) and [Defining Data Maps](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/defining_data_maps.html).

## Troubleshooting
| Symptom | Check |
|---|---|
| Wrong value/branch | Entry name, configured ID, member association, generated script |
| Formula rejected | Component type and current syntax |
| Groovy method fails | Current API reference and object context |
| Push displays unexpectedly | Target member/list configuration and supported mappings |

**Recall:** How do you reference an entry? What do you verify before a Groovy method or cross-cube push?
**Answer:** Use supported Calculation Manager insertion/syntax. Verify API support and target configuration; do not infer undocumented behavior.
**Teach-back:** Explain how to test a choice from form entry through rule result.

## Oracle sources checked 2026-10-30
- [About Smart Lists](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/ecalc/about_smart_lists.html)
- [Inserting Smart Lists](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/ecalc/inserting_smart_lists.html)
- [Creating a Groovy Rule](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/epbca/creating_a_groovy_rule_about.html)
- [Defining Data Maps](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/defining_data_maps.html)

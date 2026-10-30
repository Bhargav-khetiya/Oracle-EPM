# 08 — Groovy rules and form context

## Core idea

Groovy rules let an administrator use supported EPM APIs to inspect form context, validate input, and run configured actions. Use Oracle’s documented API reference and examples for the application release; do not rely on guessed method names or private server details.

## Beginner mental model

A form has a point of view, row and column members, and cells. A Groovy rule can receive a form-related grid context when configured for the appropriate form event. The rule may inspect or respond to data using supported interfaces. It does not grant permission to bypass application security or expose undocumented internals.

Common scenarios include:
- validating changed cells and returning a clear message;
- vetoing an action when a documented business condition fails;
- reading grid context to select data for a configured process;
- invoking a configured Smart Push or data map pattern.

The exact grid and operation objects available depend on rule type, event, and release.

## Supported API landmarks

Oracle’s Groovy API documents a DataGrid interface for POV/row/column header cells and cell iterators, plus DataGrid.DataCell for individual data cells. The documented DataCell API includes methods such as isEdited, isReadOnly, isValid, isValidIntersection, and setData. EpmScript documents throwVetoException. Verify signatures, null handling, supported application, and event context in the current API before implementation.

Use these as API discovery terms, not as an exhaustive list or an assumption that every method is valid in every context. Do not use undocumented names such as crossesInvalidIntersection, getSmartListText, setSmartList, or isHasAccess as if they were supported.

## Safe rule-development sequence

1. Write the business requirement, input scope, expected result, and failure message.
2. Select the correct rule type and form event.
3. Read the Oracle API for each required object and method.
4. Check that the rule uses only the current operation’s intended context and changed cells where required.
5. Avoid hard-coded member names, thresholds, or assumptions about the entire grid.
6. Test valid, invalid, missing, read-only, and boundary inputs with a representative planner.
7. Review the job/rule result and confirm saved data or veto behavior.
8. Check performance and error handling with realistic grid size.
9. Keep source, rule name, deployment version, test evidence, and rollback path together.

## Pseudocode example (not executable)

~~~text
For each data cell available in the rule's documented grid context:
    If the cell is changed and violates an approved business rule:
        stop the operation with a user-friendly message
~~~

The threshold and business condition must come from an approved requirement. This example intentionally contains no fabricated code or project rule.

## Smart Push

Oracle provides a tutorial for moving modified form data with Groovy and Smart Push. Follow that tutorial and its exact API pattern for the configured application. Do not assume that arbitrary override maps, Smart List conversion, or cross-cube member mapping are available without checking the API and data map configuration.

## Troubleshooting

| Symptom | Check |
|---|---|
| Grid or operation object unavailable | Rule type, form association, event, and supported execution context |
| Rule sees unexpected cells | POV, prompts, form members, and whether logic filters edited/read-only cells |
| A method fails to compile | Current Oracle API signature and service release |
| Validation does not stop the intended action | Rule event, exception API, form prompt behavior, and test scenario |
| Smart Push does not match source form | Data map selection, mappings, form context, override, and job details |
| Rule is slow | Grid scope, repeated lookups, rule logic, and Oracle execution guidance |

## Recall check

1. Where should method names be verified? The Oracle Groovy API for the applicable product and release.
2. Does a form-context rule bypass security? No.
3. What must be approved before encoding a validation threshold? The business requirement and exception behavior.

**Teach-back:** Describe a safe process for checking whether a Groovy method is supported before putting it into a production rule.

## Oracle references

- [Oracle EPM Groovy API: DataGrid](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/groov/oracle/epm/api/grid/DataGrid.html)
- [Oracle EPM Groovy API: DataCell](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/groov/oracle/epm/api/grid/DataGrid.DataCell.html)
- [Oracle EPM Groovy API: EpmScript](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/groov/oracle/epm/api/script/EpmScript.html)
- [Groovy examples](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/groov/groovy-examples.html)
- [Running Groovy Rules](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svurr/run_groovy_rules.html)
- [Moving modified data using Groovy and Smart Push](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/groovy-tutorial-moving-modified-data-using-groovy-and-smartpush/index.html)

Checked 2026-10-30. The API reference is authoritative for signatures; use the current version for any executable implementation.

# 03 — Smart View options

## Core idea

Smart View options control how members, data, and formatting appear and how the client behaves. Some settings are specific to a worksheet; others are global. Provider support varies, so use Oracle’s support matrix for the connected data source.

## Option areas

| Area | Typical controls | Scope and caution |
|---|---|---|
| Member Options | Zoom level, member name display, indentation, ancestor position, member retention | Usually sheet-specific; options vary by provider and behavior mode |
| Data Options | Missing/zero suppression, replacement labels, other display or submit choices | Suppression settings may have provider-specific and global behavior |
| Formatting | Cell styles, Excel formatting, number formats, retained formatting | Not all providers support each option; form definitions can override some client settings |
| Advanced | Shared connection settings, diagnostics, and other client-level options | Often global; change environment settings only with IT/admin guidance |

The Smart View interface changes between desktop releases and clients. Do not treat the option areas as one universal four-tab dialog or assume a setting is available on every provider.

## Suppression and replacement labels

Suppressing missing data or zero values changes what is shown in the grid. It does not make a value confidential or delete it. Clearing suppression may reveal rows that were previously hidden. A replacement label changes presentation; displaying “restricted” in place of a cell label does not grant or deny access.

Before using suppression:
1. Confirm the provider and whether the operation is a form or ad hoc grid.
2. Check row, column, and block suppression separately.
3. Test a grid with missing values, zero values, and mixed values.
4. Confirm users can open the grid when suppression is enabled.
5. Document the expected row/column output.

Do not claim that submitting zero always writes a physical zero or deletes a block. Submit behavior is provider-, application-, and setting-dependent.

## Formatting

Smart View can use cell styles or Excel formatting. These choices are not interchangeable in all operations. Excel formatting behavior depends on grid type, provider, and settings; a form definition can disable formatting. Compare the results after refresh, zoom, pivot, submit, and undo before adopting a workbook standard.

## Global versus sheet-level

Oracle’s options documentation distinguishes global settings from sheet-level settings. Advanced options are global; data suppression also includes global settings. For others, inspect the relevant option’s scope before changing it. “Apply to all worksheets” can update more than the active grid.

## Recall check

1. Do replacement labels secure data? No.
2. Why can a setting change behavior across an entire workbook? Some options are global or applied to all sheets.
3. Why test formatting after zoom and refresh? Grid operations can affect retained formatting.

**Teach-back:** Describe how you would test a suppression option without confusing hidden values with deleted data.

## Oracle references

- [Setting Smart View options](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svumb/smart_view_options_setting.html)
- [Member options](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svufc/opt_memb.html)
- [Data options](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svpbc/opt_data.html)
- [Formatting options](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svuuc/opt_format.html)
- [Formatting options supported for Planning forms and ad hoc](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svuuc/formatting_options_supported_for_planning_forms_and_ad_hoc.html)
- [Smart View behavior options in Cloud EPM](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svurc/smart_view_behavior_options_epm_cloud_100x3bdf3ac9.html)

Checked 2026-10-30 against the Smart View 26.100 documentation set.

# 05 — Smart View worksheet functions and VBA

## Core idea

Smart View worksheet functions retrieve or submit data for a defined point of view. VBA functions automate supported client actions. Both must use the current function syntax, provider support, and user permissions.

## Worksheet functions

| Function | Purpose | Important care point |
|---|---|---|
| HsGetValue | Retrieves a value for selected dimension members | Specify a complete, intended POV; a missing dimension can default to its top-level member |
| HsSetValue | Sends a value to a data source for selected members | Requires write access; avoid cells with Supporting Details |
| HsGetSheetInfo | Retrieves information about the current worksheet | Use the documented property names and provider support |
| HsAlias / HsDescription | Returns an alias or description in supported contexts | Function names and provider availability differ |

Oracle function syntax uses dimension/member pairs, commonly Dimension#Member. The connection parameter comes first. For example, an illustrative read-only pattern is:

~~~excel
=HsGetValue("ConnectionName","Account#Sales","Period#Jan","Scenario#Budget")
~~~

Use the Function Builder or current Oracle syntax guide to construct a valid formula. Do not copy a sample member, connection, or cube name into production.

HsGetValue is evaluated through Smart View refresh operations. HsSetValue sends values to the source; use the documented submit/refresh process for the function and provider. Validate the result in the application after submission.

## VBA and Cloud EPM

The earlier version of this guide included a macro that embedded a username/password and called HypConnect for Planning Cloud. That is not a safe or correct Cloud pattern: Oracle documents HypConnect as unsupported for Cloud data sources and identifies HypUIConnect for Cloud authentication through an existing private connection.

For VBA:
1. Use the current Smart View Developer’s Guide and its provider applicability table.
2. Use the installed smartview.bas declarations rather than hand-writing declarations from an old sample.
3. Use the documented authentication method and do not store credentials in code.
4. Handle return codes, failures, and cleanup; do not silently submit data.
5. Test with a nonproduction connection and least-privilege account.
6. Have the organization review macro signing, distribution, workbook storage, and secrets handling.

This guide intentionally does not provide a runnable production macro. VBA code can submit data and requires environment-specific connection and security design.

## Recall check

1. What is the delimiter in the POV syntax— A hash between dimension and member, such as Account#Sales.
2. Which API should be consulted for Cloud connection through VBA— Oracle documents HypUIConnect for Cloud; check the current Developer’s Guide.
3. Why avoid embedding credentials— Workbooks and macros can be shared or inspected.

**Teach-back:** Describe what you would verify before distributing an HsSetValue workbook or a VBA macro.

## Oracle references

- [Smart View 26.100 User’s Guide](https://docs.oracle.com/en/applications/enterprise-performance-management/smart-view/26.100/uugsv/launch.html)
- [Smart View functions overview](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svpbc/using_functions.html)
- [HsGetValue](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svufc/hsgetvalue_483.html)
- [Function syntax guidelines](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svumb/functions_syntax_guidelines_100x489d6978.html)
- [Submit Data options](https://docs.oracle.com/en/applications/enterprise-performance-management/smart-view/26.100/uugsv/about_the_submit_data_options.html)
- [HypUIConnect](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svdvg/hypuiconnect.html)
- [HypConnect limitations](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svdvg/hypconnect.html)
- [Smart View Developer’s Guide, Release 26.100](https://docs.oracle.com/en/applications/enterprise-performance-management/smart-view/26.100/dvesv/index.html)
- [VBA declarations in 64-bit Office](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svdvg/vba_functions_in_64-bit_versions.html)

Oracle’s 26.100 Developer’s Guide is dated October 2026; related User’s Guide material is release 26.100. Checked 2026-10-30.

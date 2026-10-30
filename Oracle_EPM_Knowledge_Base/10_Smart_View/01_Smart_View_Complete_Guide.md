# Smart View Complete Guide

> **Prerequisites:** [What Is EPM](../00_Foundation/01_What_Is_EPM.md), [Dimensions and Metadata](../08_Dimensions_and_Metadata/01_Dimension_Fundamentals.md)  
> **Sources merged:** ChatGPT Smart_View_and_Ad_Hoc (6 files), Claude 10_Smart_View, Gemini Smart_View_and_Ad_Hoc (6 files)  
> **Evidence Labels:** `[Oracle Documented]` · `[Illustrative]` · `[Recommendation]`

---

## What Is Smart View?

**Oracle Smart View for Office** is an Excel add-in that connects Microsoft Office to Oracle EPM Cloud (and other Oracle data sources). It lets users retrieve, analyze, and submit planning data directly from Excel — combining the familiarity of spreadsheets with the power of multidimensional EPM databases.

```
┌─────────────────┐     HTTPS/REST     ┌──────────────────────┐
│  Microsoft      │ ◄──────────────────►│  Oracle EPM Cloud    │
│  Excel + Smart  │                     │  (Planning, FCCS,    │
│  View Add-In    │  Retrieve / Submit  │   TRCS, Essbase)     │
└─────────────────┘                     └──────────────────────┘
         │
         ▼
  ┌─────────────────────────────────────┐
  │  User can:                          │
  │  • Open Forms (same layout as web)  │
  │  • Run Ad Hoc analysis (flexible)   │
  │  • Submit data back to EPM          │
  │  • Use Excel formulas alongside     │
  │  • Automate with VBA (limited)      │
  └─────────────────────────────────────┘
```

`[Oracle Documented]`

---

## Connections: Shared vs Private

| Connection Type | Description | URL Pattern |
|:---|:---|:---|
| **Shared** | Centrally managed by administrator; available to all users | Typically ends with `/workspace/SmartViewProviders` |
| **Private** | Saved or entered by individual user | Typically ends with `/HyperionPlanning/SmartView` |

A shared URL points to administrator-managed connection data. A private connection is user-managed.

### Connection Setup

1. Obtain the connection URL from your EPM administrator
2. Confirm Smart View release compatibility with your Office version
3. In Excel: Smart View Panel → Shared or Private Connections
4. Sign in using your organization's authentication flow
5. Navigate to the target application and form/ad hoc grid
6. Verify provider, application, cube, and user before reading or submitting data

> [!WARNING]
> Never place passwords in workbooks, VBA macros, screenshots, or support tickets. Use the organization's approved authentication method.

`[Oracle Documented]`

---

## Ad Hoc Analysis

An ad hoc grid lets you explore members and dimensions freely without being locked to a fixed form layout. Each operation changes the visible grid.

### Common Operations

| Operation | What It Does | Key Consideration |
|:---|:---|:---|
| **Zoom In** | Retrieves children, descendants, or another level | Choose the right zoom level for your provider |
| **Zoom Out** | Collapses view to a higher level | Check which parent levels remain visible |
| **Keep Only** | Keeps only selected members | May invalidate grid layout if required members removed |
| **Remove Only** | Removes selected members | Confirm you didn't remove required POV context |
| **Pivot** | Moves dimension between rows, columns, and POV | Review resulting intersections before submitting |
| **Refresh** | Retrieves current values from the server | **Overwrites** unsaved workbook changes |
| **Submit Data** | Sends eligible changes to EPM | Requires write access; check POV first |

### Zoom Options

| Option | Returns |
|:---|:---|
| **Next Level** | Direct children only |
| **All Levels** | All descendants at every level |
| **Bottom Level** | Only Level 0 (leaf) members |
| **Sibling Level** | Members at the same level under the same parent |

> [!NOTE]
> Not every provider supports every zoom mode. Sibling Level and Same Generation require Standard-mode applications. Check your provider and client release.

### Safe Ad Hoc Analysis Sequence

1. Connect to the application and open an ad hoc grid
2. Confirm the POV and row/column dimensions
3. Filter or zoom gradually, especially on large hierarchies
4. Review the resulting member list and totals
5. Refresh if the POV changed or you need current values
6. Before submitting: verify every edited cell, the active POV, and your write access
7. Submit and review the provider response

`[Oracle Documented]`

---

## Smart View Options

Key options that affect ad hoc behavior and data display:

### Data Options

| Option | Settings | Impact |
|:---|:---|:---|
| **#NoData / Missing Label** | Custom text or blank | How `#MISSING` cells display |
| **Suppress Rows** | No Data, Zero, Missing | Hides rows with no data (presentation only, not security) |
| **Member Name Display** | Name Only, Alias Only, Name and Alias | Controls how members appear in grid |
| **Preserve Formulas on Retrieve** | On / Off | Whether Excel formulas survive a Refresh |

### Cell Styles

Smart View can apply formatting to distinguish:
- **Data cells** vs **member cells**
- **Read-only** vs **writable** cells
- **Dirty** (changed, not yet submitted) cells

`[Oracle Documented]`

---

## Working with Forms in Smart View

When you open a Planning form in Smart View, you see the **same layout** as the web form — same rows, columns, POV, and business rules. Key differences:

| Feature | Web Form | Smart View Form |
|:---|:---|:---|
| **Layout** | Rendered in browser | Rendered in Excel |
| **Excel formulas** | Not available | ✅ Can add Excel formulas alongside |
| **Conditional formatting** | EPM conditional formatting | Excel conditional formatting |
| **Save/Submit** | Submits dirty cells | Same behavior |
| **Business rules** | Run on save (if configured) | Run on save (if configured) |
| **Multiple forms** | One per browser tab | Multiple sheets in one workbook |

`[Oracle Documented]`

---

## Flex Forms

Flex forms provide **flexible row or column management** while retaining form behavior. Users can rearrange, sort, move, and filter members within the flexible axis.

Key points:
- A flex form is **not** an unrestricted Excel workbook — form definition, metadata validity, and access rules still apply
- Removing a row from a worksheet is **not** a data-clear operation
- Flex forms require specific minimum EPM Cloud and Smart View versions
- Suppression and Groovy combinations have documented limits

`[Oracle Documented]`

---

## Supporting Detail, Comments, and Attachments

| Feature | Purpose | Important Note |
|:---|:---|:---|
| **Supporting Detail** | Structured calculation hierarchy (text + values + operators) to develop a cell value | Not the same as an Excel formula |
| **Comments** | Explain data assumptions or background | Permissions control who can add/view/remove |
| **Attachments** | Supporting files or URLs linked to cells | Check permitted file types and size limits |
| **Change History** | Shows who changed what and when | Only available when data auditing is enabled by admin |

`[Oracle Documented]`

---

## Worksheet Functions

Smart View provides worksheet functions that retrieve or submit data for specific dimension intersections:

| Function | Purpose | Example |
|:---|:---|:---|
| **HsGetValue** | Retrieves a value for selected members | `=HsGetValue("Conn","Account#Sales","Period#Jan","Scenario#Budget")` |
| **HsSetValue** | Sends a value to the data source | Requires write access; use documented submit process |
| **HsGetSheetInfo** | Returns info about the current worksheet | Provider-specific |
| **HsAlias / HsDescription** | Returns alias or description | Provider-specific |

### POV Syntax

Functions use the **Dimension#Member** pattern:

```excel
=HsGetValue("ConnectionName","Account#Revenue","Period#Jan","Entity#US_East","Scenario#Budget","Version#Working","Year#FY26")
```

> [!IMPORTANT]
> Use the **Function Builder** or current Oracle syntax guide to construct valid formulas. A missing dimension can default to its top-level member, potentially returning unexpected values.

`[Oracle Documented]`

---

## VBA Automation

Smart View provides a VBA API for automating operations. Key guidance:

- **Cloud Authentication:** Use `HypUIConnect` for Cloud EPM connections (not `HypConnect`, which is unsupported for Cloud)
- **Declarations:** Use the installed `smartview.bas` declarations rather than hand-writing from old samples
- **Credentials:** Never embed passwords in VBA code
- **Error Handling:** Always handle return codes and failures; don't silently submit data
- **Testing:** Test with a non-production connection and least-privilege account
- **Review:** Have the organization review macro signing, distribution, and workbook storage

`[Oracle Documented]`

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "Cannot connect to provider" | Wrong URL, network issue, or SSO problem | Verify URL with admin; check proxy settings |
| Slow ad hoc retrieval | Too many members retrieved (zoomed to bottom on large hierarchy) | Zoom gradually; use Keep Only to narrow scope |
| Data doesn't refresh | Cached sheet | Close and reopen connection; clear Smart View cache |
| Submit fails silently | Read-only cells or insufficient access | Check cell styles (read-only highlight); verify security |
| HsGetValue returns 0 or #MISSING | Incomplete POV (missing dimension defaults to top member) | Specify all dimensions explicitly |
| "Smart View has encountered a problem" | Version mismatch or conflicting add-ins | Run Smart View Health Check; check Office version compatibility |
| Excel formulas overwritten on Refresh | "Preserve Formulas" option not enabled | Enable "Preserve Formulas on Retrieve" in Smart View Options |
| Flex form members not saving | Client version too old | Check minimum EPM Cloud and Smart View version requirements |

---

## Smart View Health Check

Smart View includes a built-in diagnostic tool:
1. In Excel: Smart View ribbon → Help → Health Check
2. Collects environment information (versions, add-ins, connection details)
3. Use this output when raising support tickets — it provides Oracle Support with the details they need

---

## Quick Recall

1. **What is the difference between Refresh and Submit Data?**
   → Refresh retrieves current values from the server (overwrites local changes). Submit sends eligible changes from Excel to EPM.

2. **Why must you check the POV before submitting?**
   → The POV determines which dimension members your data targets. Wrong POV = data written to wrong intersections.

3. **Can you use Excel formulas alongside Smart View data?**
   → Yes, but enable "Preserve Formulas on Retrieve" to prevent Refresh from overwriting them.

4. **Teach-back:** Explain what you would verify before distributing an HsSetValue workbook or VBA macro to production users.

---

## Oracle Documentation References

- [Smart View 26.100 User's Guide](https://docs.oracle.com/en/applications/enterprise-performance-management/smart-view/26.100/uugsv/launch.html)
- [Smart View Developer's Guide](https://docs.oracle.com/en/applications/enterprise-performance-management/smart-view/26.100/dvesv/index.html)
- [URL Syntax for Connections](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/cgsad/2_working_with_epm_clients_connect_url_syntax.html)
- [Smart View Functions Overview](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svpbc/using_functions.html)
- [Smart View Diagnostics and Health Check](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svuuc/about_smart_view_diagnostics.html)

`[Oracle Documented]` — Checked 2026-10-30. Confirm supported release with your administrator.


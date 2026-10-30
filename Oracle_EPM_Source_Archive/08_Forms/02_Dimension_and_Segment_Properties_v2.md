# 02 — Dimension and Segment Properties: Layout Architecture

---

## 2.1 The 4 Dimension Axes in Form Design

In Oracle EPM Planning, every form organizes dimensions across four functional axes:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FORM AXES ARCHITECTURE                          │
├─────────────┬──────────────────────────────────────────────────────────┤
│ 1. Page     │ Dropdown selector allowing users to flip between pages   │
│             │ (e.g., Department: D10010, D10020, D10030)               │
├─────────────┼──────────────────────────────────────────────────────────┤
│ 2. POV      │ Static or selectable global context filter               │
│             │ (e.g., Scenario: Budget, Version: Working)               │
├─────────────┼──────────────────────────────────────────────────────────┤
│ 3. Row      │ Horizontal lines running down the grid (e.g., Accounts)  │
├─────────────┼──────────────────────────────────────────────────────────┤
│ 4. Column   │ Vertical columns running across the grid (e.g., Periods) │
└─────────────┴──────────────────────────────────────────────────────────┘
```

---

## 2.2 Dimension Properties Breakdown

From your supplied production extraction (`forms property.txt`), here is every dimension property analyzed across its respective axis:

| Property | Axis Availability | Technical Function & Best Practice |
| :--- | :--- | :--- |
| **`Apply to all page/POV/row/column dimensions`** | All Axes | Copies the display properties configured on this dimension to all other dimensions sharing the same axis. |
| **`Member name`** | All Axes | Displays the raw programmatic Essbase member name (e.g., `D10010`). |
| **`Alias`** | All Axes | Displays the human-readable description from the active alias table (e.g., `D10010:Catering`). |
| **`Member Formula`** | All Axes | Allows adding a dynamic calculation formula directly inside the form layout without modifying the Essbase outline metadata. |
| **`Hide dimension`** | All Axes | Keeps the dimension in the POV/Page context for data filtering, but hides it visually from the user interface. |
| **`Show consolidation operators`** | All Axes | Renders the Essbase consolidation operator (`+`, `-`, `~`, `^`) next to the member name in the row or column header. |
| **`Start expanded`** | Rows & Columns | When users open the form, automatically expands parent members to display their children without requiring manual clicks. |
| **`Drill on shared members`** | Rows & Columns | Allows users to expand and drill down into **Shared Members** just like base members. *(Note: Must be enabled if alternate reporting hierarchies are used on the form).* |
| **`Row Width` / `Column Width`** | Rows & Columns | Specifies custom pixel widths for row headers or data columns. |

---

## 2.3 Segment Properties Deep Dive

A **Segment** is an individual column or row slice within the form grid. In your extraction, **Column B** exhibits the following segment properties:

```
┌─────────────────────────────────────────────────────────────┐
│                    SEGMENT PROPERTIES (COLUMN B)            │
├─────────────────────────────────────────────────────────────┤
│ Apply to all columns:                  [ ] Unchecked        │
│ Hide:                                  [ ] Unchecked        │
│ Read-only:                             [ ] Unchecked        │
│ Show separator:                        [ ] Unchecked        │
│ Suppress hierarchy:                    [ ] Unchecked        │
│ Suppress missing data:                 [X] Checked          │
│ Suppress invalid Scenario/Time Periods:[X] Checked          │
│ Column width:                          [100px              ]│
└─────────────────────────────────────────────────────────────┘
```

### Segment Property Details:
1. **`Hide`**: Completely hides this specific column/row segment (e.g., used to hide an intermediate calculation column while displaying the final ratio).
2. **`Read-only`**: Overrides user security to lock an individual column (e.g., making prior-year Actuals column read-only while keeping Budget columns editable).
3. **`Show separator`**: Draws a thick visual separator line before this segment to differentiate financial statement sections.
4. **`Suppress hierarchy`**: Flattens hierarchical indentation, rendering child members at the same left-aligned margin as parent members.

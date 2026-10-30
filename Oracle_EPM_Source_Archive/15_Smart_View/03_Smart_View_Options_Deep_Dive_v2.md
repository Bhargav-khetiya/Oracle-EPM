# 03 — Smart View Options: Configuration & Formatting Bible

---

## 3.1 Overview of the 4 Smart View Options Tabs

The **Options** dialog in Smart View (**Smart View Ribbon $\rightarrow$ Options**) governs every aspect of grid rendering, member labeling, data suppression, cell formatting, and network timeouts across four primary tabs:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        THE 4 SMART VIEW OPTIONS TABS                   │
├────────────────────┬───────────────────────────────────────────────────┤
│ 1. Member Options  │ Zoom levels, indentation, alias displays,         │
│                    │ ancestor positioning (Top vs. Bottom)             │
├────────────────────┼───────────────────────────────────────────────────┤
│ 2. Data Options    │ #MISSING suppression, zero suppression,           │
│                    │ replacement labels, Submit Zero behavior          │
├────────────────────┼───────────────────────────────────────────────────┤
│ 3. Formatting      │ Cell Styles (Read-Only vs Editable),              │
│                    │ Use Excel Formatting, Move Formatting on Refresh  │
├────────────────────┼───────────────────────────────────────────────────┤
│ 4. Advanced        │ Shared connection URLs, logging levels,           │
│                    │ proxy routing, multi-grid worksheet enabling      │
└────────────────────┴───────────────────────────────────────────────────┘
```

---

## 3.2 Tab 1: Member Options

| Setting | Options Available | Architectural Mechanics & Best Practice |
| :--- | :--- | :--- |
| **`Zoom In Level`** | Next Level, All Levels, Bottom Level, Sibling Level, Same Level, Same Gen | Sets the default behavior when double-clicking a member in the grid. |
| **`Member Name Display`** | • Member Name Only<br>• Distinct Member Name<br>• Member Name and Alias<br>• Description Only | **Crucial for Financial Reporting**:<br>• `Member Name`: Displays technical code (e.g., `D10010`).<br>• `Description Only`: Displays alias (e.g., `Catering`).<br>• `Member Name and Alias`: Displays `D10010: Catering`. |
| **`Indentation`** | • None<br>• Subitems<br>• Totals | • `Subitems`: Indents child members to the right (classic tree view).<br>• `None`: Left-aligns all members (essential when building Excel PivotTables). |
| **`Ancestor Position`** | • Top<br>• Bottom | • `Top`: Parent appears above children (standard P&L layout).<br>• `Bottom`: Children appear first, followed by the Parent total at the bottom (traditional accounting subtotal format). |
| **`Include Selection`** | Checked / Unchecked | When zooming in on a parent, retains the parent row in the grid. If unchecked, the parent is replaced by its children. |

---

## 3.3 Tab 2: Data Options & Suppression

```
┌─────────────────────────────────────────────────────────────┐
│                    DATA OPTIONS PANEL                       │
├─────────────────────────────────────────────────────────────┤
│ Suppress Rows:      [X] No Data / Missing  [X] Zero         │
│ Suppress Columns:   [ ] No Data / Missing  [ ] Zero         │
│                                                             │
│ Replacement Labels:                                         │
│   #Missing Label:   [0.00                                  ]│
│   #NoAccess Label:  [RESTRICTED                            ]│
│   #Invalid Label:   [INVALID                               ]│
│                                                             │
│ Submit Zero:        [ ] Unchecked                           │
└─────────────────────────────────────────────────────────────┘
```

### Critical Data Option Behaviors:
1. **`Suppress Rows: No Data / Missing`**: Instructs Essbase to prune empty blocks, skipping rows with no data.
2. **`Submit Zero` (The Storage Trap)**:
   * *When Unchecked*: Entering `0` in a cell and submitting clears the cell, storing `#MISSING` and allowing Essbase to reclaim block space.
   * *When Checked*: Entering `0` forces Essbase to allocate a physical 8-byte floating point `0.00000000`, creating physical blocks on disk. **Leave unchecked unless zero balances must be explicitly preserved**.
3. **`Replacement Labels`**:
   * Replaces technical `#MISSING` text with custom strings (e.g., `0.00`, `-`, or blank) for executive presentation.
   * Replaces `#NoAccess` with `CONFIDENTIAL` for unauthorized security intersections.

---

## 3.4 Tab 3: Formatting Options: Cell Styles vs. Excel Formatting

Smart View provides two mutually exclusive formatting models:

```
┌──────────────────────────────────────┬──────────────────────────────────────┐
│             CELL STYLES              │        USE EXCEL FORMATTING          │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ • Smart View dynamically color-codes │ • Planners apply custom fonts, fills,│
│   cells based on their state:        │   and borders using Excel's ribbon.  │
│   - Read-Only cells -> Light Gray    │ • Smart View preserves Excel styling │
│   - Editable cells  -> Light Green   │   across refreshes.                  │
│   - Supporting Detail -> Light Yellow│ • "Move Formatting on Refresh" moves │
│   - Drill-Through -> Light Orange    │   styles when new rows are expanded. │
│ • Best for data-entry forms.         │ • Best for polished board packages.  │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

---

## 3.5 Tab 4: Advanced Options

* **`Shared Connections URL`**: The central XML server address connecting your enterprise users to EPM Cloud.
* **`Logging Level`**: Set to `Error` for standard production; set to `Debug` when capturing trace logs for Oracle Support tickets.
* **`Route all requests through proxy`**: Enforces routing through corporate internet firewalls.
* **`Enable multiple-grid support on worksheet`**: Allows multiple independent cubes to live on the same tab.

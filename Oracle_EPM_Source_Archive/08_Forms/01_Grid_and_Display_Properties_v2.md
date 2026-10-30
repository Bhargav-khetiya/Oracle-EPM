# 01 — Form Properties, Instructions, Precision, & Grid Engine

> **Source**: Directly derived from the production UI extraction `forms property.txt` for `Data Entry Form For FY 25,26,27-1` on cube `FinPlan`.

---

## 1.1 The Properties Tab: Form Identity & Data Formatting

The **Properties Tab** establishes the fundamental metadata, instructions, precision formatting, contextual menus, and dynamic variables for an Oracle EPM Cloud Planning form.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FORM PROPERTIES OVERVIEW                        │
├──────────────────────────┬─────────────────────────────────────────────┤
│ Form Name                │ Data Entry Form For FY 25,26,27-1           │
│ Description              │ this form is use for enter data             │
│ Cube                     │ FinPlan                                     │
│ Use Metric               │ [ ] Unchecked                               │
└──────────────────────────┴─────────────────────────────────────────────┘
```

### 1.1.1 Enter Instructions: Rich Text vs. Source Code Editing

The form designer provides an integrated WYSIWYG rich text editor with full HTML source code toggle:

| Toolbar Group | Tools Available | Runtime & Business Function |
| :--- | :--- | :--- |
| **History & Cleanup** | `Undo`, `Redo`, `Clear Styling` | Allows rapid editing rollback and strips dirty pasted styles from Word/Excel. |
| **Editor Modes** | `Rich Text Editing Mode`, `Source Code Editing Mode` | Switches between visual formatting and raw HTML (`<p>`, `<span>`, `style`). |
| **Colors & Fonts** | `No Color` (Foreground/Background), `Bold`, `Italic`, `Underline` | Highlights critical budget deadlines, policies, or warnings. |
| **Typography Details**| `Subscript`, `Superscript`, `Strikethrough` | Formatting metric notations (e.g., $CO_2$, $m^2$) or deprecated budget items. |
| **Alignment** | `Justify Left`, `Justify Center`, `Justify Right`, `Justify Full` | Formats instructions across wide browser windows. |
| **Lists & Structure** | `Bulleted List`, `Numbered List`, `Indent`, `Outdent` | Provides numbered step-by-step submission workflows for planners. |
| **Hyperlinks** | `Add Link`, `Remove Link` | Directs planners to external SharePoint policies, ERP portals, or training videos. |

---

### 1.1.2 Precision Matrix: Currency, Non-Currency, & Percentage

Oracle EPM Cloud allows granular decimal display control per metric class:

```
┌────────────────────────────────────────────────────────────────────────┐
│                           PRECISION SETTINGS                           │
├────────────────────────────────────────────────────────────────────────┤
│ [ ] Use Currency member precision setting                              │
│                                                                        │
│ Metric Class               Minimum Decimal       Maximum Decimal       │
│ ─────────────────────────  ───────────────────   ───────────────────   │
│ Currency values            [2                ]   [2                ]   │
│ Non-currency values        [0                ]   [2                ]   │
│ Percentage values          [1                ]   [2                ]   │
└────────────────────────────────────────────────────────────────────────┘
```

1. **`Use Currency member precision setting`**:
   * If **Checked**: The form defers decimal precision to the currency dimension member properties (e.g., `USD` = 2 decimals, `JPY` = 0 decimals).
   * If **Unchecked**: The form enforces the custom Minimum and Maximum values specified in the table below.
2. **`Minimum` vs. `Maximum` Decimals**:
   * **Minimum**: Pads zeros to maintain alignment (e.g., `Minimum = 2` renders `5` as `5.00`).
   * **Maximum**: Rounds the visual display (e.g., `Maximum = 2` renders `5.6789` as `5.68`).
   * *Critical Engine Rule*: Precision formatting affects **visual display only**. Essbase continues storing the full 8-byte IEEE 754 floating-point value (`5.67890123`) in `.PAG` blocks.

---

### 1.1.3 Context Menus (Action Menus Attachment)

Forms bind Action Menus to give planners right-click capabilities on the grid:

* **Available Menus in Production Extraction**:
  1. `Add_new_employee_Row`
  2. `Calculate Revenue`
  3. `Calculate using @PRIOR`
  4. `Clear_All_New_Employees_R`
  5. `Copy FY26 Actual Catering`
  6. `Enter/Modify Opening Balances For Current year December`
  7. `Menu`
  8. `New Menu`
  9. `TestMenu`
  10. `Visit Google`
* **Selected Menus**: Administrators move menus from Available to Selected. The order in Selected Menus determines the top-to-bottom sequence in the user's right-click dropdown.

---

### 1.1.4 Dynamic User Variables

* **`Enable dynamic user variables`** *(Checkbox)*:
  * When checked, allows planners to change user variables (e.g., `&Department_Var`, `&Entity_Var`) directly on the form header without navigating to **User Preferences**.
  * The form dynamically re-renders and queries Essbase based on the newly selected variable member.

---

## 1.2 Grid Properties: Suppression & Performance Architecture

The **Other Options $\rightarrow$ Grid Properties** tab governs how the EPM application server queries Essbase and handles empty space:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        DATA SUPPRESSION ARCHITECTURE                   │
├──────────────────────────────────┬─────────────────────────────────────┤
│   WITHOUT DATABASE SUPPRESSION   │     WITH DATABASE SUPPRESSION       │
├──────────────────────────────────┼─────────────────────────────────────┤
│ 1. Essbase returns ALL 50,000    │ 1. Essbase C++ kernel (ESSSVR)      │
│    theoretical cell intersections│    scans index .IND B-tree.         │
│    over network to Planning Java.│ 2. Discards empty blocks in RAM.    │
│ 2. Java application server parses│ 3. Returns ONLY rows with valid data│
│    50,000 cells in memory.       │    (e.g., 200 rows) over network.   │
│ 3. Suppresses empty rows.        │                                     │
│ Network Payload: 45 MB           │ Network Payload: 120 KB             │
│ Render Time: 18 - 25 seconds     │ Render Time: 0.6 seconds            │
└──────────────────────────────────┴─────────────────────────────────────┘
```

### 1.2.1 Row & Column Suppression Matrix

| Property | Default | Technical Mechanics | Performance Impact |
| :--- | :---: | :--- | :--- |
| **`Suppress missing blocks`** | Unchecked | Instructs Essbase to evaluate the **Index (`.IND`) file B-tree** before retrieving data. If no block exists for a sparse row combination, Essbase skips the row entirely. | **Massive (10x-50x speedup)**. Critical for forms with sparse dimensions (Entity, Dept, Project) on rows. |
| **`Suppress missing data - Rows`** | Unchecked | Evaluates data cells across the row. If all cells evaluate to `#MISSING`, the row is omitted from the grid. | Eliminates blank visual rows; improves rendering speed. |
| **`Suppress invalid data - Rows`** | Unchecked | Suppresses rows where cells are invalid due to **Valid Intersections** or cell security restrictions. | Prevents users from seeing read-only, grayed-out invalid rows. |
| **`Use Database Suppression`** | Unchecked | Pushes suppression logic down into the native **Essbase C++ query processor (`ESSSVR`)** rather than filtering in Java memory. | **Critical for large forms**. Reduces network traffic between Essbase and the Planning application tier by up to 98%. |
| **`Suppress missing data - Columns`** | Unchecked | Suppresses vertical columns where all row intersections are empty. | Useful in multi-year rolling forecasts where future periods have no data. |
| **`Suppress invalid data - Columns`** | Unchecked | Suppresses columns made invalid by security or period locks. | Cleans up column headers. |

---

### 1.2.2 Other Grid Properties

| Property | Production Meaning & Architecture |
| :--- | :--- |
| **`Suppress invalid Scenario/Time Periods`** | When checked, if a column falls outside the Scenario's active date range (`Start Yr/Period` to `End Yr/Period`), Planning suppresses the column automatically. |
| **`Global Assumptions Form`** | Marks the form as a centralized driver table. Assumptions entered here apply globally across other forms. |
| **`Enable Autosave`** | Enables instant cell commitment. As soon as a user tabs out of a cell, Planning submits the change to Essbase without requiring the user to click "Save." |
| **`Suppress Missing also Suppresses Zero`**| When enabled, rows containing only zeros (`0.00`) are treated as `#MISSING` and suppressed from the display. |
| **`Remove Form Suppressions in Ad Hoc`** | If a user launches ad-hoc analysis from this form, clears suppression settings to allow full multidimensional exploration. |
| **`Enable Calc On the Fly`** | Calculates simple member formulas in browser memory via JavaScript before saving to Essbase, giving instant feedback. |
| **`Pivot Rows and Columns after load`** | Swaps horizontal and vertical axes after initial data retrieval. |
| **`Disable formatting`** | Strips custom font colors and borders, rendering plain HTML cells for maximum rendering speed on 10,000+ cell grids. |

---

## 1.3 Display Properties: User Interaction Settings

| Display Property | Function & Business Purpose |
| :--- | :--- |
| **`Make form read-only`** | Locks all cells in the form. Planners can view numbers but cannot enter data. Used for executive reporting forms. |
| **`Hide Form`** | Hides the form from standard navigation lists (accessible only via Action Menus or Task Lists). |
| **`Display missing values as blank`**| Renders empty cells as clean blanks instead of cluttering the screen with `#MISSING` text. |
| **`Enable Mass Allocate`** | Enables the native EPM Mass Allocation engine, allowing users to enter a lump sum at a parent and spread it using spread profiles. |
| **`Enable Grid Spread`** | Allows users to right-click a cell and spread values proportionally or evenly across rows/columns. |
| **`Enable cell-level document`** | Enables planners to attach supporting PDF, Excel, or Word documents directly to specific financial cells. |
| **`Message for forms with no data`** | Custom text displayed (e.g., *"No budget data exists for the selected department"*) if all intersections are empty. |
| **`Hide Save Confirmation Message`** | Suppresses the popup toast *"Data has been saved successfully"*, streamlining rapid data entry. |
| **`Display grid lines for empty cells`** | Renders HTML table cell borders even when cells contain no values. |

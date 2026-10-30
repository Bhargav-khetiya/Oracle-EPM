# 02 — Ad Hoc Analysis: Grid Operations & Dimensional Slicing

---

## 2.1 What is Ad Hoc Analysis?

**Ad Hoc Analysis** is the free-form, multidimensional exploration canvas of Oracle EPM. Instead of being locked into a rigid form layout, analysts can slice, dice, pivot, drill down, filter, and expand any dimension hierarchy in real time directly within Microsoft Excel.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        THE AD HOC CANVAS ANATOMY                       │
├────────────────────────────────────────────────────────────────────────┤
│ Floating POV Bar:  [Scenario: Budget] [Version: Working] [Years: FY26] │
│                                                                        │
│                      [Period: Jan]    [Period: Feb]    [Period: Mar]   │
│ [Account: Revenue]     $1,200,000       $1,450,000       $1,600,000    │
│ [Account: COGS]          $450,000         $520,000         $580,000    │
│ [Account: Gross Margin]  $750,000         $930,000       $1,020,000    │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2.2 Core Ad Hoc Operations: Master Reference

Every ad-hoc action corresponds to an optimized Essbase kernel query:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        AD HOC OPERATIONS REFERENCE                          │
├────────────────────┬────────────────────────────────────────────────────────┤
│ Zoom In            │ Expands parent hierarchies to reveal child members     │
│ Zoom Out           │ Collapses child members back into summary parent       │
│ Keep Only          │ Filters the grid strictly to the selected member slice │
│ Remove Only        │ Strips unneeded members out of the active view         │
│ Pivot              │ Swaps dimensions across Rows, Columns, and the POV     │
│ Submit Data        │ Commits edited numeric cells back to Essbase .PAG files│
│ Refresh            │ Discards unsaved edits & pulls fresh cube values       │
└────────────────────┴────────────────────────────────────────────────────────┘
```

---

### 2.2.1 The 6 Zoom In Modes: Deep Breakdown

When you double-click a member or click **Zoom In**, Smart View executes one of six distinct traversal algorithms:

| Zoom In Mode | Essbase Hierarchy Action | When to Use in Practice |
| :--- | :--- | :--- |
| **`Next Level`** *(Default)* | Expands only the **immediate children** of the selected parent. | Step-by-step hierarchical exploration (e.g., Total Operating Expense $\rightarrow$ Personnel, Facilities, Travel). |
| **`All Levels`** | Recursively expands **every descendant** all the way down to leaf Level 0. | Building full hierarchical reporting trees. |
| **`Bottom Level`** | Expands **only Level 0 leaf members**, completely skipping intermediate summary parents. | **The Auditor's Choice**: Essential for extracting pure transactional input data for reconciliations. |
| **`Sibling Level`** | Retains the selected member and retrieves all other members that share the same immediate parent. | Peer comparison (e.g., compare `Dept 101` with `Dept 102`, `Dept 103`). |
| **`Same Level`** | Retrieves all members across the entire dimension that share the same level distance from leaf Level 0. | Cross-hierarchy statutory reporting. |
| **`Same Generation`**| Retrieves all members that share the same distance from the root top member (Generation 1). | Comparing top-level divisions across business units. |

---

### 2.2.2 Keep Only vs. Remove Only

* **`Keep Only`**:
  * Select a row (e.g., `Travel Expense`) or column (e.g., `Jan`) $\rightarrow$ Click **Keep Only**.
  * Smart View discards all other rows and columns, isolating your analysis to that single intersection.
* **`Remove Only`**:
  * Select an unneeded row (e.g., `Intercompany Eliminations`) $\rightarrow$ Click **Remove Only**.
  * Strips that specific slice out of the worksheet without disturbing the rest of the grid.

---

### 2.2.3 Pivoting: Slicing Multidimensional Space

Pivoting allows analysts to alter their dimensional perspective in seconds:
1. **Row to Column**: Drag a dimension header from a row to a column (e.g., moving `Department` from vertical rows to horizontal columns to compare departments side-by-side).
2. **Grid to POV**: Drag an unneeded dimension from the grid into the floating **POV bar** to lock it as a constant background coordinate.
3. **POV to Grid**: Drag a dimension from the POV bar directly into row or column headers to begin expanding its hierarchy.

---

## 2.3 Free-Form Ad Hoc: The Power User Technique

You do not even need to open a pre-built form to analyze data:
1. Open a completely blank Excel worksheet.
2. In cell **A1**, type: `Year` (e.g., `FY26`).
3. In cell **B1**, type: `Period` (e.g., `Jan`).
4. In cell **A2**, type: `Account` (e.g., `Gross_Sales`).
5. Connect your active sheet to `FinPlan`.
6. Click **Refresh**.
7. **Smart View instantly recognizes the grid layout**, establishes the active POV, and pulls the live number from Essbase!

---

## 2.4 Multi-Grid Ad Hoc: Multiple Cubes on One Sheet

Smart View allows placing **multiple independent grids on the same Excel worksheet**:
* **Top Grid**: Connected to `FinPlan` BSO cube (P&L Income Statement).
* **Bottom Grid**: Connected to `Manpower` Workforce cube (Headcount and Salaries).
* **Enabling Multi-Grid**:
  * Navigate to **Smart View Options $\rightarrow$ Advanced**.
  * Check **`Enable multiple-grid support on worksheet`**.
  * Planners can now build consolidated management report packages sourcing from multiple cubes on a single tab!

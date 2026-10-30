# 04 — Smart View, Prediction, & Printing Options

---

## 4.1 Smart View Options: Deep Dive

Because finance professionals spend much of their day in Microsoft Excel, Oracle EPM provides dedicated **Smart View Options** configured directly on the data form:

```
┌─────────────────────────────────────────────────────────────┐
│                    SMART VIEW OPTIONS                       │
├─────────────────────────────────────────────────────────────┤
│ Disable spreading:                  [ ] Unchecked           │
│ Repeat member labels:               [X] Checked             │
│ Disable sheet protection:           [X] Checked             │
│ Enable flex form for rows:          [X] Checked             │
│ Enable flex form for columns:       [ ] Unchecked           │
│ Show invalid members for flex form: [X] Checked             │
└─────────────────────────────────────────────────────────────┘
```

### Detailed Feature Breakdown:
1. **`Repeat member labels`**:
   * *Standard Form*: Merges parent cells visually (e.g., "Total Department" spans 10 rows).
   * *When Checked*: Repeats the text "Total Department" on **every single row**.
   * *Why Critical*: Allows planners to build native Excel **Pivot Tables, VLOOKUPs, INDEX/MATCH, and Power Query pipelines** directly on the Smart View sheet without missing data gaps.
2. **`Disable sheet protection`**:
   * Leaves the Excel worksheet unlocked so users can write native Excel formulas (`=SUM(A1:B1)`), apply conditional formatting, and add scratch notes in adjacent cells.
3. **`Enable flex form for rows` (The Flex Form Revolution)**:
   * Traditional Smart View forms lock row structures.
   * **Flex Forms** allow users to type new members directly into rows, reorder rows, delete unneeded rows, and use Excel sort/filter tools.
   * Upon clicking **Submit Data**, Smart View validates the modified rows and saves the data seamlessly.
4. **`Show invalid members for flex form`**:
   * If a user types an invalid or misspelled member name (e.g., `Dept_9999`) on a flex form row, highlights the cell in yellow/red rather than failing silently.

---

## 4.2 Prediction Options (Predictive Planning)

Oracle EPM Cloud features an embedded machine learning and statistical time-series forecasting engine (**Predictive Planning**):

```
┌─────────────────────────────────────────────────────────────┐
│                    PREDICTION OPTIONS                       │
├─────────────────────────────────────────────────────────────┤
│ Include Events:             [X] Checked                     │
│ Select Calendar:            [Standard 12-Month Calendar    ]│
│ Prediction for Dynamic Calc:[X] Checked                     │
└─────────────────────────────────────────────────────────────┘
```

1. **`Include Events`**:
   * Incorporates discrete historical events (e.g., a 2-month factory shutdown, an acquisition, or an advertising campaign spike) as exogenous dummy variables, preventing historical anomalies from distorting forward trend projections.
2. **`Prediction for Dynamic Calc`**:
   * Enables the statistical engine to forecast dynamically calculated lines (e.g., Gross Profit Margin % or Operating Ratio) in addition to base stored accounts.

---

## 4.3 Printing Options

* **`Include Supporting Detail`**: When exporting or printing forms to PDF/Excel, includes the underlying line-item supporting detail schedules attached to individual numeric cells.
* **`Show Comments`**: Prints cell annotations and audit notes.
* **`Show attribute members`**: Displays linked attribute dimension values (e.g., Brand, Package Type) as additional columns.
* **`Apply Precision`**: Enforces strict decimal rounding rules configured in the form definition (e.g., rounding headcount to 0 decimals, currency to 2 decimals).
* **`Show Currency Codes`**: Prepends ISO currency codes (USD, EUR, GBP) to financial values.

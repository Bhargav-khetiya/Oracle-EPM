# Designing with Financial Reporting (FR) Web Studio — Complete Markdown Edition

> **Original PDF:** `Designing_with_Financial_Reporting_Web_Studio.pdf` | **Folder:** Level 3 (Build & Design)  
> **Purpose:** Complete Markdown extraction of legacy Financial Reporting Web Studio (`FR Studio`), covering grid layout, functions, suppression rules, and bursting definitions.

---

## Table of Contents
1. [FR Web Studio Grid Architecture & POV](#grid-architecture)
2. [Report Functions (`GridPoint`, `CellText`, `Variance`)](#functions)
3. [Conditional Formatting & Row/Column Suppression](#formatting)
4. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. FR Web Studio Grid Architecture & POV <a name="grid-architecture"></a>

- Planners open `Reports -> Financial Reporting -> New Report`.
- Drag grids, text boxes, and charts onto the report design canvas.

---

## 2. Report Functions (`GridPoint`, `CellText`, `Variance`) <a name="functions"></a>

- **`<<CellText(Grid1, Row, Col)>>`:** Extracts text commentary (`Cell Notes`) from Essbase and renders it in a formatted footnote box below the grid.
- **`<<Variance(ColA, ColB)>>`:** Calculates mathematical difference directly in the reporting engine without hitting Essbase.

---

## 3. Conditional Formatting & Row/Column Suppression <a name="formatting"></a>

- **Suppress Zero / Missing:** Always enable `Suppress Zero` and `Suppress Missing` on data rows to prevent 500-page blank report printouts.

---

## 4. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`16_Administration/02_Reports_Complete_Guide.md`** — Legacy FR migration.

# Working with Oracle Smart View for Google Workspace — Complete Markdown Edition

> **Original PDF:** `Working_with_Oracle_Smart_View_for_Google_Workspace.pdf` | **Folder:** Level 2 (Daily Usage)  
> **Purpose:** Definitive Markdown guide on daily financial modeling, ad-hoc analysis, cell commenting, and grid operations inside Google Sheets.

---

## Table of Contents
1. [Ad-Hoc Analysis in Google Sheets](#ad-hoc-analysis)
2. [Member Selection & Zoom Commands](#zoom-commands)
3. [Cell Comments, Supporting Detail & Cell History](#cell-features)
4. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Ad-Hoc Analysis in Google Sheets <a name="ad-hoc-analysis"></a>

Users connect to an Essbase BSO/ASO cube via the Google sidebar $\rightarrow$ click `Ad-Hoc Analysis`. The initial top-level dimension slice renders in cells `A1:F15`.

---

## 2. Member Selection & Zoom Commands <a name="zoom-commands"></a>

- **Zoom In (`Next Level / Bottom Level / All Levels`):** Double-clicking a parent member (`Total_Opex`) expands its immediate children across the sheet rows.
- **Keep Only / Remove Only:** Highlights specific columns (`Jan, Feb, Mar`) and discards the remaining periods from the sheet view.
- **Pivot:** Moves a dimension (`Scenario`) from the POV sidebar onto the grid column headers.

---

## 3. Cell Comments, Supporting Detail & Cell History <a name="cell-features"></a>

- **Supporting Detail:** Allows planners to build local mathematical breakdown lines (`e.g., Flight ($500) + Hotel ($800) = $1,300`) inside a single Essbase cell without creating database metadata.
- **Cell History:** Audits exact timestamp, user ID, and previous values for every cell modification directly in the Google sidebar (`Smart View -> Cell Actions -> Cell History`).

---

## 4. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`09_Smart_View/01_Smart_View_Overview.md`** — Core Smart View features.
- **`09_Smart_View/03_Smart_View_Specialized_Deep_Reference.md`** — Google Sheets detailed matrix.

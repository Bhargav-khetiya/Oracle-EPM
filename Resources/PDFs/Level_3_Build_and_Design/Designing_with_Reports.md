# Designing with Reports (EPM Reports) — Complete Markdown Edition

> **Original PDF:** `Designing_with_Reports.pdf` | **Folder:** Level 3 (Build & Design)  
> **Purpose:** Definitive, massive Markdown reference of modern EPM Reports Studio (`Redwood Reports`), covering grid building, formula rows, bursting definitions, and cross-cube reporting.

---

## Table of Contents
1. [Modern EPM Reports Studio Architecture](#architecture)
2. [Multi-Grid & Cross-Cube Reporting (`FinPlan + FCCS in One Report`)](#cross-cube)
3. [Formula Rows, Conditional Formatting & Dynamic Text](#formulas)
4. [Bursting Definition Setup & Automated Emailing](#bursting)
5. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Modern EPM Reports Studio Architecture <a name="architecture"></a>

Modern **EPM Reports (`Reports -> Reports -> Create Report`)** replaces legacy FR with a clean, drag-and-drop web designer.
- **Shared Objects:** Grids, logos, and headers can be saved as **Shared Objects** and linked across 50 different reports. Updating the shared header once updates all 50 reports instantly!

---

## 2. Multi-Grid & Cross-Cube Reporting (`FinPlan + FCCS in One Report`) <a name="cross-cube"></a>

Unlike FR which restricted grids to a single connection, EPM Reports allows inserting **Grid 1 (`EPBCS Planning Cube`)** and **Grid 2 (`FCCS Consolidation Cube`)** on the exact same page canvas with synchronized POV prompts!

---

## 3. Formula Rows, Conditional Formatting & Dynamic Text <a name="formulas"></a>

- Supports standard Excel-style syntax inside grid formulas: `=[Gross_Margin] / [Total_Revenue]`.
- **Text Functions:** `Textual POV description`, `Current date/time stamps`, and `Audited cell notes`.

---

## 4. Bursting Definition Setup & Automated Emailing <a name="bursting"></a>

Inside `Reports -> Bursting -> New Bursting Definition`:
- Define **Bursting Slice Dimension** (`Cost Center`).
- Map target email addresses using an **External CSV distribution list** or an **Essbase attribute table**. EPM Cloud generates individual PDF slices and emails them securely overnight.

---

## 5. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`16_Administration/02_Reports_Complete_Guide.md`** — Complete EPM Reports design and bursting setup.

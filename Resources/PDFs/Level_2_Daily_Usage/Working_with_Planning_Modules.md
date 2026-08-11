# Working with Planning Modules — Complete Markdown Edition

> **Original PDF:** `Working_with_Planning_Modules.pdf` | **Folder:** Level 2 (Daily Usage)  
> **Purpose:** Comprehensive Markdown extraction covering end-user workflows across the 4 OOTB Oracle Planning Modules: Financials, Workforce, Capital, and Projects.

---

## Table of Contents
1. [Financials Module Workflows: Revenue, Opex & Balance Sheet](#financials-workflows)
2. [Workforce Module Workflows: Compensation & Employee Lifecycle](#workforce-workflows)
3. [Capital Module Workflows: Asset Acquisition & Depreciation](#capital-workflows)
4. [Projects Module Workflows: Project Billing & Financial Intersect](#projects-workflows)
5. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Financials Module Workflows: Revenue, Opex & Balance Sheet <a name="financials-workflows"></a>

- **Driver-Based Revenue:** Planners enter expected `Unit Sales Volume` and `Average Selling Price (ASP)`. The system auto-calculates Gross Revenue.
- **Balance Sheet & Cash Flow:** Planners define Days Sales Outstanding (`DSO`) and Days Payable Outstanding (`DPO`). Driver rules calculate accounts receivable/payable and generate indirect cash flow statements.

---

## 2. Workforce Module Workflows: Compensation & Employee Lifecycle <a name="workforce-workflows"></a>

- **Existing Employees vs. To Be Hired (TBH):** Planners manage named employees loaded from HR (`Workday/HCM`) and add generic TBH requisitions (`TBH_Analyst_1`) with targeted start dates and salary grades.
- **Automated Tax Calculation:** Running `Calculate Compensation` applies state/country tax tables (`FICA, FUTA, SUTA, 401k match`) across all active months.

---

## 3. Capital Module Workflows: Asset Acquisition & Depreciation <a name="capital-workflows"></a>

- **New Asset Requisitions:** Planners select asset class (`IT Hardware - 3 Yr Depreciation`), purchase price (`$150,000`), and in-service date.
- **Depreciation Rollup:** Rule automatically calculates straight-line or double-declining depreciation and pushes monthly expense charges directly into the Financials `Opex` cube!

---

## 4. Projects Module Workflows: Project Billing & Financial Intersect <a name="projects-workflows"></a>

- **Capital vs. Contract Projects:** Models internal IT rollouts (`Capitalizable asset conversion`) vs billable customer implementations (`Time & Materials / Fixed Fee billing schedules`).

---

## 5. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`03_Planning_Modules/01_OOTB_Modules_Deep_Reference.md`** — Exhaustive configuration and calculation driver tables across all 4 modules.

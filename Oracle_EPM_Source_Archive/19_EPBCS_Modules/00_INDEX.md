# EPBCS Modules & Business Processes: Master Engineering Guide

## 1. Executive Architectural Overview

In Oracle Enterprise Performance Management Cloud (EPM Cloud), **Enterprise Planning and Budgeting Cloud Service (EPBCS)** elevates traditional custom planning by providing five pre-configured, best-practice business processes (commonly referred to as **Modules**):

1. **Financials (`OEP_FS`)**: Core Income Statement (Revenue & Expense), Balance Sheet, and Cash Flow modeling with driver-based calculations.
2. **Workforce (`OEP_WFP`)**: Headcount, salary, compensation, taxes, and benefits modeling at the Employee and/or Job level.
3. **Capital (`OEP_CPX`)**: New capital asset requests, existing asset management, depreciation schedules, and IFRS 16 / ASC 842 lease accounting.
4. **Projects (`OEP_PFP`)**: Internal, capital, and contract project planning with time, resource, and direct billing recognition.
5. **Strategic Modeling**: Long-range 5-to-10 year strategic forecasting, balance sheet optimization, debt restructuring, and M&A modeling.

```
+===================================================================================================+
|                                    EPBCS MULTI-MODULE ECOSYSTEM                                    |
+===================================================================================================+
|                                                                                                   |
|                               +-------------------------------+                                   |
|                               |       STRATEGIC MODELING      |                                   |
|                               |   (Long-Range 5-10 Year Plan) |                                   |
|                               +-------------------------------+                                   |
|                                               |                                                   |
|                               Target Targets  | Strategic Boundary Alignments                     |
|                                               v                                                   |
|  +-----------------------------+             +-----------------------------+                      |
|  |      WORKFORCE (OEP_WFP)    |             |       CAPITAL (OEP_CPX)     |                      |
|  | - Compensation & Salaries   |             | - New Capex & Tangibles     |                      |
|  | - Headcount & FTE Tracking  |             | - Depreciation & Leases     |                      |
|  +-----------------------------+             +-----------------------------+                      |
|                 \                                           /                                     |
|                  \ Payroll & Benefits Expense              / Capitalized Assets,                  |
|                   \ Pushed via Smart Push / Data Maps     /  Depreciation Expense                 |
|                    v                                     v                                        |
|  +---------------------------------------------------------------------------------------------+  |
|  |                                  FINANCIALS CORE (OEP_FS)                                   |  |
|  | - Revenue Modeling (Driver, Trend, Direct)                                                  |  |
|  | - Operating Expenses (Aggregated from Workforce & Capital)                                 |  |
|  | - Balance Sheet & Working Capital                                                           |  |
|  | - Direct & Indirect Cash Flow Statements                                                    |  |
|  +---------------------------------------------------------------------------------------------+  |
|                 ^                                                                                 |
|                 |                                                                                 |
|                 | Project Labor, Asset Transfers, & Billing Revenue                               |
|  +-----------------------------+                                                                  |
|  |      PROJECTS (OEP_PFP)     |                                                                  |
|  | - Capital Projects (Assets) | -----------------------------------------------------------------+
|  | - Contract Projects (Billing)|                                                                  |
|  +-----------------------------+                                                                  |
|                                                                                                   |
+===================================================================================================+
```

---

## 2. Cubes Created by Modules

When an administrator enables modules in EPBCS, the system automatically instantiates dedicated Essbase cubes (BSO and ASO) tailored for that module's calculation mechanics:

| Module Name | Calculation Cube (BSO) | Reporting Cube (ASO) | Dedicated Dimensions Added | Primary Architectural Role |
| :--- | :--- | :--- | :--- | :--- |
| **Financials** | `OEP_FS` | `OEP_REP` | `Plan Element`, `Account`, `Entity` | Central financial aggregation, driver calculations, P&L. |
| **Workforce** | `OEP_WFP` | `OEP_WFREP` | `Property`, `Employee`, `Job`, `Union Code`, `Gender` | Granular roster planning, tax tier limits, benefits. |
| **Capital** | `OEP_CPX` | `OEP_CPXREP` (or shared `OEP_REP`) | `Asset Class`, `Asset Detail`, `Lease Asset` | Depreciation waterfall, lease present value, salvage. |
| **Projects** | `OEP_PFP` | `OEP_PFPREP` (or shared `OEP_REP`) | `Project`, `Project Element`, `Resource`, `Task` | Resource timesheets, milestone billing, capital asset push. |
| **Strategic Modeling** | Native In-Memory Engine | Relational Bridge | Financial Model Files (`.alc`) | Non-dimensional, freeform financial statement modeling. |

---

## 3. Directory Structure & Chapter Navigation

| Chapter / File | Focus Area | Key Techno-Functional Mastery |
| :--- | :--- | :--- |
| [01_Financials_Module_OEP_FS.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/EPBCS_Modules_and_Business_Processes/01_Financials_Module_OEP_FS.md) | **Financials Deep Dive** | Revenue & Expense drivers, Balance sheet working capital, Cash flow indirect methods, rolling forecasts, seeded rules. |
| [02_Workforce_Module_OEP_WFP.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/EPBCS_Modules_and_Business_Processes/02_Workforce_Module_OEP_WFP.md) | **Workforce Deep Dive** | Granularity choices (Employee, Job, Employee+Job), salary bands, merit increases, tax caps, partial FTEs, transfers. |
| [03_Capital_Module_OEP_CPX.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/EPBCS_Modules_and_Business_Processes/03_Capital_Module_OEP_CPX.md) | **Capital Deep Dive** | Tangible vs Intangible assets, IFRS 16 lease calculations, depreciation methods, impairments, asset disposal. |
| [04_Projects_Module_OEP_PFP.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/EPBCS_Modules_and_Business_Processes/04_Projects_Module_OEP_PFP.md) | **Projects Deep Dive** | Project types (Internal, Capital, Contract), labor rate cards, time & material billing, asset capitalization flow. |
| [05_Strategic_Modeling_HSF.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/EPBCS_Modules_and_Business_Processes/05_Strategic_Modeling_HSF.md) | **Strategic Modeling** | Long-range forecasting, debt scheduling, capital structure optimization, funding options, Monte Carlo simulation. |
| [06_Cross_Module_Integration_and_Data_Flow.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/EPBCS_Modules_and_Business_Processes/06_Cross_Module_Integration_and_Data_Flow.md) | **Cross-Module Sync** | Automated data movement from Workforce, Capital, and Projects into Financials (`Rollup`, Data Maps, Smart Push). |

---

## 4. Beginner Metaphor: The Corporation as a Machine

To understand EPBCS modules as a fresher, picture a large manufacturing company:
* **Financials** is the **Executive Dashboard & Bank Account**: It does not care which individual employee got a $\$2,000$ bonus or which laptop was purchased; it only cares about the total salary expense and total equipment depreciation hitting the P&L.
* **Workforce** is the **Human Resources Department**: It tracks every individual person, their hire date, salary grade, 401(k) match, medical insurance, and payroll taxes. It calculates these complex details and sends one summarized monthly number to Financials.
* **Capital** is the **Facilities & Equipment Fleet**: It tracks physical buildings, delivery trucks, manufacturing machines, and server racks, calculating monthly depreciation and sending it to Financials.
* **Projects** is the **Engineering & Client Services Team**: It tracks billable hours, project budgets, and development costs. When a software project finishes, it turns into an intangible asset in Capital, and billings flow into Financials.


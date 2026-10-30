# Interview Preparation — Complete Guide

> **Section:** 15 — Professional Development  
> **File:** 01 — Interview Guide  
> **Difficulty:** All Levels  
> **Prerequisites:** Familiarity with core EPM concepts (this entire knowledge base)

---

## How to Use This Guide

This guide collects the most common Oracle EPM interview questions organized by topic and difficulty. For each question, we provide:
- The question as an interviewer would ask it
- A concise, confident answer
- Key terms to include in your response

---

## Foundation Questions

### Q: What is Oracle EPM Cloud?
> Oracle Enterprise Performance Management (EPM) Cloud is a suite of cloud-based applications for planning, budgeting, forecasting, financial consolidation, reporting, and analysis. It replaces the on-premises Hyperion suite. The core component for planning is EPBCS (Enterprise Planning and Budgeting Cloud Service), which includes the Planning module and an embedded Essbase calculation engine.

### Q: What is the difference between PBCS and EPBCS?
> **PBCS** (Planning and Budgeting Cloud Service) is the standard cloud planning application — you define dimensions and build everything manually. **EPBCS** (Enterprise PBCS) extends PBCS with pre-built planning modules: Financials, Workforce, Capital, Projects, and Strategic Modeling. EPBCS includes everything in PBCS plus ready-to-use business process content. [Illustrative — Oracle has consolidated these into a single Planning offering in recent releases]

### Q: What is Essbase?
> Essbase (Extended Spread Sheet dataBASE) is the multidimensional calculation engine underneath EPM Cloud Planning. It stores data in cubes organized by dimensions. In EPM Cloud, Essbase is embedded and managed by Oracle — you don't install or maintain it separately.

---

## Dimensions and Metadata Questions

### Q: What are sparse and dense dimensions?
> **Dense** dimensions define what's inside a data block (e.g., Account, Period). **Sparse** dimensions define how many blocks exist (e.g., Entity, Scenario, Version). The key performance insight: fixing a calculation on sparse dimensions reduces how many blocks Essbase loads from disk, which is the biggest performance lever.

### Q: What are the mandatory dimensions in Planning?
> Account, Period, Year, Scenario, Version, Entity, and Currency. These cannot be deleted. Custom (user-defined) dimensions can be added for additional analysis axes like Product, Department, or Project.

### Q: Explain Dynamic Calc vs Store in member properties.
> **Store** means the value is saved to disk when calculated. **Dynamic Calc** means the value is calculated on the fly during retrieval — never stored. Dynamic Calc saves disk space and avoids stale data but adds retrieval time. Use Store for frequently accessed values; use Dynamic Calc for ratios, percentages, and upper-level aggregations in Hybrid BSO.

### Q: What is a UDA?
> User-Defined Attribute — a text tag assigned to members for filtering and calculation logic. Example: Tag entities with UDA "Hotel" or "Restaurant" to run different calculations per entity type using `@ISUDA("Entity", "Hotel")`.

---

## Calculation Questions

### Q: What does a FIX statement do?
> FIX defines the calculation scope — which data blocks Essbase loads from disk. It dramatically improves performance by limiting calculations to specific members. Always FIX on sparse dimensions (Scenario, Version, Year, Entity) to reduce the number of blocks processed.

### Q: When should you use Groovy vs Calc Script?
> **Calc Script** for: pure math, AGG, DATACOPY, SET commands, performance-critical calculations. **Groovy** for: email notifications, REST API calls, data validation with user messages (throwVetoException), Smart List text comparisons, cross-cube data access. **Hybrid** approach: use Groovy for logic and validation, then call an embedded calc script for heavy math.

### Q: What is throwVetoException?
> A Groovy method that stops a form save and displays an error message to the user. Used for data validation — if revenue is negative or headcount isn't a whole number, the Groovy rule vetoes the save and tells the user what to fix.

### Q: Explain SET CREATEBLOCKONEQ.
> When set to ON, Essbase creates new sparse blocks whenever a formula assigns a non-missing value to an intersection where no block exists. Critical for data seeding (e.g., copying Actuals to Budget for a new year). Must be turned OFF after use, or it can cause block explosion.

---

## Data Integration Questions

### Q: What is Data Management (FDMEE)?
> Data Management (also called FDMEE — Financial Data Management Enterprise Edition) is the built-in data integration tool in EPM Cloud. It handles loading data from flat files, ERP systems, and other sources into the Essbase cube, with mapping, transformation, and validation capabilities.

### Q: What is a Smart Push?
> Smart Push automatically copies data from one plan type (cube) to another after a form save. For example, when a user saves headcount in the Workforce cube, Smart Push can automatically push the salary total to the Financials cube. Configured per form in Form Properties.

### Q: What is a Data Map?
> A Data Map defines the member mapping between two plan types (cubes). It specifies which source members map to which target members when moving data between cubes using Smart Push or the data exchange interface.

---

## Smart View Questions

### Q: What is Smart View?
> Oracle Smart View for Office is an Excel add-in that connects to EPM Cloud. Users can retrieve data into Excel, edit it, submit changes back to the cube, and run business rules — all from within Excel.

### Q: What is the difference between forms mode and ad hoc in Smart View?
> **Forms mode** opens a pre-built form designed by the administrator — fixed layout, specific members, consistent formatting. **Ad hoc** mode gives the user free-form access to the cube — they can zoom in/out, pivot dimensions, and explore data freely. Forms are faster and more controlled; ad hoc is more flexible.

---

## Administration Questions

### Q: What is EPM Automate?
> EPM Automate is a command-line utility for automating EPM Cloud administration tasks: running rules, importing/exporting data, managing snapshots, cloning environments, and running maintenance operations. It's the primary automation tool for EPM Cloud.

### Q: What is a Database Refresh?
> After importing metadata changes (new members, changed properties), you must refresh the database to deploy changes to the Essbase outline. It has three phases: validate metadata, create outline, restructure data blocks. Schedule during maintenance windows for large changes.

### Q: What are substitution variables?
> Server-side named values (e.g., `CurrYear = FY26`) set by administrators and referenced in rules, forms, and reports using `&VarName`. When the year rolls, the admin updates the variable — every artifact using it automatically picks up the change.

---

## Architecture Questions

### Q: Explain BSO vs ASO vs Hybrid.
> **BSO** (Block Storage Option): Traditional write-back storage. Data stored in blocks. Good for planning and input. **ASO** (Aggregate Storage Option): Optimized for large-volume aggregation and reporting. Dynamic aggregation, no write-back. **Hybrid BSO**: Combines BSO write-back with ASO-style dynamic queries. Dense dimensions can be Dynamic Calc for fast retrieval. Best of both worlds for planning applications.

### Q: What happens during the daily maintenance window?
> Oracle runs an automatic daily process that creates a cold Essbase backup, performs database optimization, and applies patches. The environment is briefly unavailable. The window time is configurable but cannot be skipped.

---

## Scenario-Based Questions

### Q: Design a budget approval workflow for a multi-entity organization.

> **Step 1:** Define the Planning Unit Hierarchy (PUH) with Entity as the base dimension. Each entity owner (Hotel GM) starts their budget.
> **Step 2:** Configure approval paths: Entity Owner → Regional VP → CFO. Use Promote, Approve, Reject, Sign Off actions.
> **Step 3:** Set up validation rules (Groovy) to check for negative revenues, mandatory fields, and variance thresholds.
> **Step 4:** Auto-approve entities where variance to prior year is ≤ 5%.
> **Step 5:** Send email notifications at each approval stage using Groovy email integration.
> **Step 6:** Lock data after Sign Off using Version (Working → Final copy).

### Q: How would you handle a production-to-test sync?

> Use `cloneEnvironment` for a complete one-step copy. For more control, use `exportsnapshot` → `copySnapshotFromInstance` → `importsnapshot` → `refreshcube`. Automate with a nightly PowerShell script scheduled via Windows Task Scheduler or a job orchestrator.

---

## Tips for Interview Success

1. **Use Oracle terminology**: Say "plan type" not "cube," "Database Refresh" not "rebuild"
2. **Mention performance implications**: Always tie answers to performance impact
3. **Reference the hybrid approach**: For Groovy/calc script questions, always mention the hybrid pattern
4. **Know the numbers**: Block size 10-100 KB optimal, 50 MB Groovy memory limit, 500K cell DataGridBuilder limit
5. **Name specific functions**: @ISMBR, @LEVMBRS, @CHILDREN, throwVetoException
6. **Mention EPM Automate**: For any automation question, EPM Automate is usually part of the answer

---

## Source Provenance

| Source | Files |
|--------|-------|
| ChatGPT | `Techno_Functional_Consultant_Review_Bible/` (8 files) |
| Claude | `21_Interview/`, `24_Architect_Masterclass/` |
| Gemini | `Techno_Functional_Consultant_Review_Bible/` (mirrors ChatGPT) |


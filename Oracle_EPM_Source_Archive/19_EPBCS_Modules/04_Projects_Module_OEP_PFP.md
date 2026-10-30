# 04 Projects Module (`OEP_PFP`): Complete Techno-Functional Engineering Guide

## 1. What is the Projects Module?

Enterprises across technology, consulting, construction, engineering, aerospace, and energy organize major business initiatives into distinct, multi-period projects. 

The **Projects Module** (`OEP_PFP`) is a pre-built business process in Oracle Enterprise Planning and Budgeting Cloud Service (EPBCS) designed to model multi-year project financial lifecycles:
* **Project Typologies**: Supports **Internal Projects** (corporate IT, marketing campaigns), **Capital Projects** (construction, capitalized software development), and **Contract Projects** (client-billable professional services, construction delivery).
* **Granular Costing**: Models labor hours $\times$ standard billing/cost rate cards, external contractors, raw materials, software licenses, travel, and project contingencies.
* **Contract Revenue Recognition**: Implements **ASC 606 / IFRS 15** revenue models including **Time & Materials (T&M)**, **Fixed Price (Milestone & Percentage of Completion / POC)**, and **Cost Plus** margin billing.
* **Cross-Module Highways**: Seamlessly bridges capital project expenses into the **Capital (`OEP_CPX`)** module and streams project P&L balances directly into **Financials (`OEP_FS`)**.

```
+===================================================================================================+
|                                    PROJECTS MODULE ENGINE OVERVIEW                                |
+===================================================================================================+
|                                                                                                   |
|  [PROJECT INPUTS]                         [CALCULATION ENGINE]            [FINANCIAL TARGETS]     |
|  - Project Catalog (WBS Tasks)            - Labor Hours x Rate Cards      - Financials (OEP_FS)   |
|  - Internal Resources & Contractors       - ASC 606 Revenue Recognition   - Service Revenue (P&L) |
|  - Material & Equipment Costs             - POC Cost-to-Cost Equations    - Direct Project Costs  |
|  - Billing Terms & Milestone Schedules    - Overhead Burden Multipliers   - Capital (OEP_CPX)     |
|  - Contract Prices & EAC Estimates        - Capitalize Project Costs      - Fixed Asset Additions |
|                                                                                                   |
+===================================================================================================+
```

### Fresher Metaphor: The Project Manager's Timesheet & Billing Engine
Think of Projects as the specialized ERP subsystem used by Delivery Partners and Engineering Directors. A Lead Architect creates *"Project 204: Global Cloud Migration"*. They budget 4 Senior Developers for 500 hours each at a $\$150/\text{hour}$ rate card, add $\$60,000$ for cloud database compute, and compute a total project budget of $\$360,000$. The Projects module manages this project schedule and feeds the financial totals to executive reporting.

---

## 2. Cube Topology & Dimension Storage Architecture

Projects operations calculate within a dedicated Block Storage cube: **`OEP_PFP`** (BSO / Hybrid BSO).

### 2.1 The 4 Core Dedicated Project Dimensions

| Dimension Name | Type | Dense/Sparse | Technical Purpose & Storage Behavior |
| :--- | :--- | :--- | :--- |
| **`Account`** | System | **Dense** | Financial lines (`Labor Cost`, `Contractor Expense`, `Billable Revenue`, `Gross Margin`, `Margin %`). |
| **`Period`** | System | **Dense** | Monthly time periods (`Jan`, `Feb`, ... `Dec`, `BegBalance`). |
| **`Project`** | Module | **Sparse** | The master project catalog (`Internal_IT_Upgrade`, `Client_Bank_Advisory`, `CIP_Warehouse_Robotics`). |
| **`Project Element`** | Module | **Sparse** | Segregates inputs, calculations, and financial drivers (`Labor Hours`, `Labor Rate`, `Direct Cost`, `Revenue Recognized`). |
| **`Resource`** | Module | **Sparse** | Labor roles, employee placeholders, equipment, and materials (`Senior_Architect`, `Project_Manager`, `Subcontractor_Tier1`, `Cloud_Servers`). |
| **`Task`** | Optional | **Sparse** | Work Breakdown Structure (WBS) phases (`Phase_1_Discovery`, `Phase_2_Build`, `Phase_3_Testing`, `Phase_4_GoLive`). |
| **`Entity`** | Core | **Sparse** | Corporate entities and delivery business units (`1001_Corporate_HQ`, `4100_Consulting_Services`). |
| **`Version`** | Core | **Sparse** | Scenarios and versions (`Working`, `Approved_Project`, `EAC_Review`). |
| **`Scenario`** | Core | **Sparse** | Data streams (`Plan`, `Forecast`, `Actual`). |
| **`Years`** | Core | **Sparse** | Multi-year planning years (`FY24`, `FY25`, `FY26`...). |

---

## 3. The Three Distinct Project Typologies

During project initiation, every project must be designated under one of three distinct architectural project types:

```
+---------------------------------------------------------------------------------------------------+
|                                     PROJECT TYPOLOGY MATRIX                                       |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  1. INTERNAL PROJECTS                                                                             |
|     - Business Purpose: Operational initiatives without customer billing (cybersecurity overhaul).|
|     - Accounting Flow: All expenses flow directly into the Financials Income Statement as        |
|       Operating Expenses (SG&A / R&D). Zero revenue is recognized.                                |
|                                                                                                   |
|  2. CAPITAL PROJECTS                                                                              |
|     - Business Purpose: Long-term asset creation (factory construction, software development).    |
|     - Accounting Flow: Costs accumulate inside OEP_PFP under Construction in Progress (CIP).      |
|       Upon completion, the "Push to Capital" rule moves the total cost to OEP_CPX as a fixed asset|
|       initiating depreciation! Zero P&L expense occurs during the construction phase.             |
|                                                                                                   |
|  3. CONTRACT PROJECTS (CLIENT BILLABLE)                                                           |
|     - Business Purpose: Client-facing professional services generating gross customer revenue.    |
|     - Accounting Flow: Computes billable revenue, direct costs, and gross profit margins. Pushes  |
|       both revenue and direct costs into Financials (OEP_FS) under Cost of Goods Sold (COGS).     |
|                                                                                                   |
+---------------------------------------------------------------------------------------------------+
```

---

## 4. Percentage of Completion (POC) Revenue Recognition: Full Mathematical Proof

Under international accounting standards (**ASC 606 / IFRS 15 - Revenue from Contracts with Customers**), fixed-price service contracts must recognize revenue over time in proportion to performance completed.

### 4.1 The Cost-to-Cost POC Equations
1. **Percentage of Completion (POC %)**:
   $$\text{POC \%}_t = \frac{\text{Cumulative Costs Incurred to Date}_t}{\text{Estimated Total Costs at Completion (EAC)}_t}$$

2. **Cumulative Revenue Recognized to Date**:
   $$\text{Cumulative Revenue}_t = \text{Total Contract Price} \times \text{POC \%}_t$$

3. **Current Period Revenue Recognized**:
   $$\text{Period Revenue}_t = \text{Cumulative Revenue}_t - \text{Cumulative Revenue Previously Recognized}_{t-1}$$

---

### 4.2 Comprehensive 4-Quarter Worked Financial Schedule (With Cost Overrun)

#### Contract Parameters:
* **Agreed Fixed Contract Price**: **$\$1,000,000.00$**
* **Initial Estimated Cost at Completion (EAC)**: **$\$600,000.00$** (Target Profit = $\$400,000$, or $40\%$).
* **Event in Q2**: Project scope expansion and technical complexity increase Estimated Total Costs from $\$600,000$ to **$\$750,000$**!

| Period | Period Costs Incurred | Cumulative Incurred Costs | Estimated Total Costs (EAC) | POC % (Cumul / EAC) | Cumulative Revenue Recognized | Period Revenue Recognized | Period Gross Profit | Period Profit Margin % |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Q1** | $\$150,000.00$ | $\$150,000.00$ | $\$600,000.00$ | $\frac{\$150\text{k}}{\$600\text{k}} = \mathbf{25.0\%}$ | $\$250,000.00$ | **$\$250,000.00$** | $\$100,000.00$ | $40.0\%$ |
| **Q2** | $\$150,000.00$ | $\$300,000.00$ | **$\$750,000.00$** *(Overrun!)*| $\frac{\$300\text{k}}{\$750\text{k}} = \mathbf{40.0\%}$ | $\$400,000.00$ | **$\$150,000.00$** | **$\$0.00$** | **$0.0\%$** *(Catch-up)*|
| **Q3** | $\$225,000.00$ | $\$525,000.00$ | $\$750,000.00$ | $\frac{\$525\text{k}}{\$750\text{k}} = \mathbf{70.0\%}$ | $\$700,000.00$ | **$\$300,000.00$** | $\$75,000.00$ | $25.0\%$ |
| **Q4** | $\$225,000.00$ | $\$750,000.00$ | $\$750,000.00$ | $\frac{\$750\text{k}}{\$750\text{k}} = \mathbf{100.0\%}$| $\$1,000,000.00$ | **$\$300,000.00$** | $\$75,000.00$ | $25.0\%$ |
| **Total**| **$\$750,000.00$** | — | — | — | — | **$\$1,000,000.00$** | **$\$250,000.00$** | **$25.0\%$** |

#### Crucial Architectural Insights from the Table:
1. **The Q2 Margin Compression Catch-Up**:
   * In Q1, the project recognized $\$250,000$ revenue assuming a $40\%$ margin.
   * In Q2, estimated total costs jumped to $\$750,000$, lowering overall project margin to $25\%$.
   * Because cumulative revenue at $40\%$ completion is:
     $$\$1,000,000 \times 40\% = \$400,000.00$$
     and Q1 already recognized $\$250,000$, Q2 period revenue is strictly:
     $$\$400,000 - \$250,000 = \mathbf{\$150,000.00}$$
   * Against $\$150,000$ of actual Q2 costs incurred, **Q2 recognized $\$0.00$ profit**! The algorithm automatically absorbed the cumulative margin dilution in Q2.
2. **Cumulative True-Up**: By the end of Q4, total revenue is exactly $\$1,000,000.00$, total costs are $\$750,000.00$, and total contract gross profit is $\$250,000.00$ ($25\%$).

---

## 5. Labor Costing & Rate Cards Engine

Projects eliminates the risk of exposing sensitive employee payroll figures to project managers by utilizing **Labor Rate Matrices**:

```
+---------------------------------------------------------------------------------------------------+
|                                  LABOR RATE MATRIX STRUCTURE                                      |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  COORDINATE INTERSECTION:                                                                         |
|  [Standard_Rates] x [No_Project] x [Entity: Global]                                               |
|                                                                                                   |
|  RESOURCE ROLE          | STANDARD BILLING RATE ($/HR) | INTERNAL COST RATE ($/HR) | OVERTIME MULT|
|  -----------------------+------------------------------+---------------------------+------------- |
|  Managing Director      | $450.00 / hr                 | $220.00 / hr              | 1.0x         |
|  Senior Cloud Architect | $250.00 / hr                 | $120.00 / hr              | 1.5x         |
|  Software Engineer      | $150.00 / hr                 | $65.00 / hr               | 1.5x         |
|  QA Test Specialist     | $95.00 / hr                  | $40.00 / hr               | 1.5x         |
|  Offshore Developer     | $55.00 / hr                  | $22.00 / hr               | 1.0x         |
|                                                                                                   |
+---------------------------------------------------------------------------------------------------+
```

### 5.1 Groovy Dynamic Calculation Script for Project Labor
When a project manager logs 160 hours for a `Senior Cloud Architect`:

```groovy
/* Groovy Rule: Calculate Project Labor Costs & Billed Revenue */
operation.grid.dataCellIterator({ DataCell cell -> cell.isEdited() }).each { cell ->
    def project = cell.getMemberName("Project")
    def resource = cell.getMemberName("Resource")
    def hours = cell.data
    
    // Fetch rate card values dynamically from Assumptions coordinate
    def costRate = getRateFromMatrix(resource, "Internal_Cost_Rate")
    def billRate = getRateFromMatrix(resource, "Standard_Billing_Rate")
    
    def directCost = hours * costRate
    def billableRevenue = hours * billRate
    
    // Write back to specific Project Element members
    cell.getCrossDimCell("Project_Cost", "Labor").setEditedValue(directCost)
    cell.getCrossDimCell("Project_Revenue", "Labor").setEditedValue(billableRevenue)
}
```

---

## 6. Integration Highways: Capital & Financials Flow

### 6.1 Pushing Capital Projects to Capital (`OEP_CPX`)
When a capital project finishes (e.g., building a automated fulfillment center):
1. Project Manager marks status = **Completed**.
2. Executes Action Menu: **"Push to Capital"**.
3. **Seeded Business Rule**:
   * Evaluates cumulative project costs in `OEP_PFP` ($2,400,000).
   * Spawns a new Asset Detail in `OEP_CPX` under Asset Class: `Buildings & Improvements`.
   * Sets the asset cost = $\$2,400,000$, and sets the in-service date.
   * Depreciation initiates automatically in `OEP_CPX`.

### 6.2 The Project Payroll Offset Contra-Account (Preventing Double Counting)
If an internal employee's annual salary is budgeted inside **Workforce (`OEP_WFP`)** and they spend 500 hours working on a project in **Projects (`OEP_PFP`)**:
* Pushing Workforce to Financials records: **$\$120,000$ Salary Expense**.
* Pushing Projects to Financials records: **$\$50,000$ Project Labor Expense**.
* If left unadjusted, total financial expense = $\$170,000$ (**$\$50,000$ double counted!**).
* **Architectural Solution**: The seeded data map writes a credit of $\$50,000$ to **`Project Payroll Offset`** (contra-expense) in Financials, ensuring net SG&A remains exactly $\$120,000$!

---

## 7. Top 10 Twisted Review & Interview Questions on Projects

### Q1: What is the fundamental difference between an Internal Project and a Contract Project?
**Answer**: 
* **Internal Project**: Budgeted for corporate internal initiatives (e.g., HR intranet portal). All costs are categorized as Operating Expenses (SG&A). It generates zero billable revenue.
* **Contract Project**: Executed for third-party clients (e.g., client construction or consulting). It models billable revenue streams (T&M, Fixed Price, Cost Plus), direct project costs, and gross profit margins, flowing both revenue and Cost of Goods Sold (COGS) into Financials.

### Q2: How does the Percentage-of-Completion (POC) method prevent revenue distortion during project cost overruns?
**Answer**: Under POC cost-to-cost formula, POC % is calculated as $\frac{\text{Cumulative Incurred Costs}}{\text{EAC}}$. If EAC increases due to an overrun, the denominator expands, reducing the calculated completion percentage. When multiplied by the contract price, the new cumulative revenue target drops, forcing current period revenue to absorb the dilution and immediately lowering recognized profit margin.

### Q3: Why does EPBCS utilize a `Project Element` dimension in `OEP_PFP`?
**Answer**: To segregate operational drivers, calculations, and accounting results cleanly without creating hundreds of redundant accounts. For instance, hours worked, hourly rates, direct labor costs, contractor expenses, and revenue all intersect with the same `Resource` and `Project` coordinate by varying the `Project Element` member (`Element_Hours`, `Element_Rate`, `Element_Cost`, `Element_Revenue`).

### Q4: How do you prevent double-counting of employee labor when both Workforce and Projects modules are enabled?
**Answer**: Through the seeded **`Project Payroll Offset`** contra-account. When employee hours are expensed inside Projects, the system pushes direct labor cost to Financials COGS or project expense accounts, while simultaneously posting an equal credit to `Project Payroll Offset` in the operational cost center. This cancels out the redundant salary expense pushed from Workforce.

### Q5: Can an end user add new WBS Tasks dynamically to a project in a web form?
**Answer**: Yes, if dynamic member creation is configured or if the application utilizes Groovy rules with the `addMember` API. In standard BSO configurations without Groovy, administrators pre-seed placeholder task members (`Task_01`, `Task_02`, `Task_03`...) or users create them via the **Add Project Task** Action Menu.

### Q6: What happens when a Capital Project in `OEP_PFP` is completed and pushed to Capital (`OEP_CPX`)?
**Answer**: The seeded `Push to Capital` business rule copies the total accumulated capital project expenditure from `OEP_PFP` into `OEP_CPX` as a newly initialized `Asset Detail`. The rule assigns the target `Asset Class`, sets the asset purchase cost equal to the project total, establishes the in-service date, and triggers monthly depreciation calculations.

### Q7: What are the three contract revenue recognition methods supported in Projects?
**Answer**:
1. **Time and Materials (T&M)**: $\text{Revenue} = \text{Logged Labor Hours} \times \text{Billing Rate Card}$.
2. **Fixed Price**: Revenue recognized across project milestones or via continuous **Percentage of Completion (POC)**.
3. **Cost Plus**: $\text{Revenue} = \text{Actual Incurred Costs} \times (1 + \text{Agreed Markup \%})$.

### Q8: How does the Projects module handle currency conversion if a project is executed in multiple international entities?
**Answer**: Projects leverages the multi-currency framework. Rate cards can be defined in local currencies (`EUR`, `GBP`) or corporate currency (`USD`). When costs and revenues are calculated, standard currency conversion rules translate local currency figures into parent reporting currencies using monthly exchange rate tables maintained in the platform.

### Q9: What is the purpose of the `Resource` dimension?
**Answer**: The `Resource` dimension stores the operational components that drive project costs and billing. It contains hierarchical rollups for internal labor roles (`Senior Architect`, `Analyst`), named employees, external vendor contractors, equipment rentals, hardware/software materials, and travel line items.

### Q10: How does Smart Push improve project forecasting cycles?
**Answer**: During project review meetings, project managers update EAC cost estimates or log hours on a form. When they click **Save**, Smart Push instantly transfers updated revenue and margin lines to `OEP_FS` within 1 second using "Form Context", giving executive leadership immediate visibility into project P&L impacts without waiting for overnight batch processing.

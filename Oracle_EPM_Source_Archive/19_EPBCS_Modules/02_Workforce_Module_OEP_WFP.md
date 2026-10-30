# 02 Workforce Module (`OEP_WFP`): Complete Techno-Functional Engineering Guide

## 1. What is the Workforce Module?

Payroll, bonuses, and employee benefits represent the single largest operating expense line for most global enterprises, typically accounting for **$50\% \text{ to } 70\%$ of total corporate operating expenditures (SG&A)**. 

The **Workforce Module** (`OEP_WFP`) is a pre-built, highly specialized business process inside Oracle Enterprise Planning and Budgeting Cloud Service (EPBCS). It bridges the operational world of human resources (HRIS systems like Oracle HCM Cloud, Workday, and SAP SuccessFactors) with the strategic financial ledger.

```
+===================================================================================================+
|                                    WORKFORCE FUNCTIONAL ENGINE                                    |
+===================================================================================================+
|                                                                                                   |
|  [HR OPERATIONAL INPUTS]                  [CALCULATION ENGINE]            [GENERAL LEDGER TARGET] |
|  - Named Employees & Requisitions         - Multi-tier Base Salary        - Financials (OEP_FS)   |
|  - Headcount & Partial FTE                - Merit Increase Timing         - Base Salaries (P&L)   |
|  - Job Roles & Standard Pay Grades        - Statutory Tax Caps (FICA/SUTA)- Bonus Expense         |
|  - Departmental Allocations               - Benefit Matching (401k/Health)- Medical Benefits      |
|  - Mid-Year Hires, Transfers, Departures  - Non-Cash Accruals             - Payroll Taxes         |
|                                                                                                   |
+===================================================================================================+
```

### Fresher Metaphor: The Granular Corporate Roster
Think of Workforce as an automated corporate payroll department operating within your planning model. Instead of an FP&A analyst manually guessing:
$$\text{"Marketing salary will be approximately } \$1,200,000 \text{ next year"}$$
Workforce lists every single employee:
> *"John Doe, Senior Cloud Architect, Base \$160,000, receives a 4.5% merit raise on July 1st, participates in the PPO Family medical plan at \$14,400/yr employer cost, matches 401(k) at 5%, and his Social Security tax caps out in August at \$168,600."*

It computes every single line item down to the exact dollar across every month and automatically pushes the summarized totals to the financial P&L.

---

## 2. The Irrevocable Granularity Decision

During initial application configuration (**Application -> Configure -> Workforce**), the system architect must choose the **Workforce Planning Granularity**.

> [!WARNING]
> **Irrevocable Configuration Alert**: Once chosen during initial enablement, the workforce granularity **CANNOT BE CHANGED**. You cannot convert a "Job Only" application to "Employee and Job" later without blowing away the entire application or building custom workarounds.

```
+---------------------------------------------------------------------------------------------------+
|                                  WORKFORCE GRANULARITY MATRIX                                     |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  1. EMPLOYEE ONLY                                                                                 |
|     - Tracks named individuals (e.g., E00123_Alice, E00124_Bob).                                  |
|     - Best for: Small corporate headquarters, boutique firms, executive rosters.                  |
|     - Limitation: Cannot easily model open requisitions by standardized job grade.                |
|                                                                                                   |
|  2. JOB ONLY                                                                                      |
|     - Tracks positions and headcount counts (e.g., Senior_Dev $\times 12$ FTE).                   |
|     - Best for: High-turnover environments (retail store associates, call centers, factory lines).|
|     - Benefit: Compact cube size; minimal block expansion.                                       |
|                                                                                                   |
|  3. EMPLOYEE AND JOB (ENTERPRISE STANDARD - RECOMMENDED)                                          |
|     - Intersects named individuals with specific job titles: "E00123_Alice -> Architect".        |
|     - Supports To-Be-Hired (TBH) requisitions, promotions, job grade changes, and transfers.       |
|     - Requirement: Essential for >90% of mid-to-large enterprise implementations.                 |
|                                                                                                   |
+---------------------------------------------------------------------------------------------------+
```

---

## 3. Cube Topology & Dimension Storage Architecture

Workforce operates within a dedicated Block Storage cube: **`OEP_WFP`** (BSO / Hybrid BSO).

### 3.1 Dimension Roles & Dense/Sparse Classification

| Dimension Name | Type | Dense/Sparse | Technical Purpose & Storage Behavior |
| :--- | :--- | :--- | :--- |
| **`Account`** | System | **Dense** | Stores financial calculations (`Basic Salary`, `Total Compensation`, `FICA Tax`, `Health Care`). |
| **`Period`** | System | **Dense** | Stores time buckets (`BegBalance`, `Jan`, `Feb`, ... `Dec`). |
| **`Property`** | Custom | **Dense / Sparse** | Holds non-financial employee metadata (`Start Date`, `End Date`, `FTE`, `Pay Type`, `Status`). Set to Dense in standard implementations for high-speed register math. |
| **`Employee`** | Module | **Sparse** | Member list of all existing personnel and TBH placeholder slots (`TBH_001`, `TBH_002`). |
| **`Job`** | Module | **Sparse** | Job titles and functional grade levels (`Senior Manager`, `Analyst 1`). |
| **`Entity`** | Core | **Sparse** | Cost centers and organizational business units (`1001_Corporate_HQ`, `2100_Sales_East`). |
| **`Version`** | Core | **Sparse** | Modeling versions (`Working`, `Final_Budget`, `WhatIf_Salary_Freeze`). |
| **`Scenario`** | Core | **Sparse** | Data streams (`Plan`, `Forecast`, `Actual`). |
| **`Years`** | Core | **Sparse** | Calendar years (`FY24`, `FY25`, `FY26`). |
| **`Union Code`** | Optional | **Sparse** | Collective bargaining agreements and union pay scales (if enabled). |
| **`Gender`** | Optional | **Sparse** | Equal employment and demographic reporting (if enabled). |

### 3.2 The Low-Level Byte Layout of the Dense Block

In Essbase, a data block is an uncompressed, contiguous memory array of 8-byte IEEE 754 double-precision floating point numbers. 

When `Account`, `Period`, and `Property` are Dense, an individual block represents the Cartesian product:
$$\text{Block Size (Bytes)} = (\text{Members in Account}) \times (\text{Members in Period}) \times (\text{Members in Property}) \times 8 \text{ Bytes}$$

For example, with 120 Accounts, 18 Periods, and 30 Properties:
$$\text{Block Cells} = 120 \times 18 \times 30 = 64,800 \text{ cells}$$
$$\text{Block Size} = 64,800 \times 8 \text{ bytes} = 518,400 \text{ bytes} \approx 506.25 \text{ KB}$$

```
+---------------------------------------------------------------------------------------------------+
|                        WORKFORCE DENSE BLOCK MEMORY ARRAY (BSO KERNEL)                            |
+---------------------------------------------------------------------------------------------------+
| Coordinate Key: [Entity: Sales_East] x [Employee: E109_John] x [Job: Senior_AE] x [FY25] x [Plan] |
|                                                                                                   |
| OFFSET   | DENSE MEMBER COORDINATE                           | IEEE 754 FLOAT VALUE | MEANING     |
| ---------+---------------------------------------------------+----------------------+------------ |
| 0x000000 | [Jan] -> [FTE] -> [Property_Value]               | 1.0000000000000000   | Active FTE  |
| 0x000008 | [Jan] -> [Start_Date] -> [Property_Value]         | 20240115.0000000000  | Jan 15 2024 |
| 0x000010 | [Jan] -> [Salary_Basis] -> [Property_Value]       | 1.0000000000000000   | Annual (1)  |
| 0x000018 | [Jan] -> [Base_Salary] -> [Account_Value]         | 10000.000000000000   | $10,000/mo  |
| 0x000020 | [Jan] -> [Merit_Pct] -> [Property_Value]          | 0.0400000000000000   | 4.0% Merit  |
| 0x000028 | [Jan] -> [FICA_Tax] -> [Account_Value]            | 620.00000000000000   | 6.2% FICA   |
| 0x000030 | [Jan] -> [Medicare_Tax] -> [Account_Value]        | 145.00000000000000   | 1.45% Med   |
| 0x000038 | [Jan] -> [401k_Employer_Match] -> [Account_Value] | 400.00000000000000   | 4% Match    |
| ...      | ...                                               | ...                  | ...         |
+---------------------------------------------------------------------------------------------------+
```

> [!TIP]
> **Why Dense Property Delivers Blazing Speed**:
> Because `Base_Salary`, `Merit_Pct`, `FICA_Tax`, and `Start_Date` reside in the **same physical memory block**, the Essbase calculation engine evaluates the entire compensation package in CPU L1/L2 cache without issuing a single secondary block lookup or disk I/O request.

---

## 4. Complex Compensation Mechanics & Mathematical Formulas

### 4.1 Base Salary, Merit Timing, and Partial Periods

Workforce calculates base salary dynamically based on employee status, hire date, departure date, and merit raise effective dates:

1. **Monthly Base Salary Formula**:
   $$\text{Monthly Base} = \frac{\text{Annual Salary}}{12} \times \text{Active Days Ratio} \times (1 + \text{Merit \%})$$

2. **Partial Period Calculation (Mid-Month Hire)**:
   If an employee starts on **April 16th** in a 30-day month with a $\$120,000$ annual salary:
   $$\text{Active Days Ratio} = \frac{30 - 16 + 1}{30} = \frac{15}{30} = 0.50$$
   $$\text{April Salary} = \left(\frac{\$120,000}{12}\right) \times 0.50 = \$5,000.00$$

3. **Merit Increase Effective Month**:
   If the employee receives a $5\%$ merit raise effective **July 1st**:
   * January – June: Monthly Salary = $\$10,000.00$
   * July – December: Monthly Salary = $\$10,000.00 \times (1 + 0.05) = \$10,500.00$

---

### 4.2 The Statutory Tax Cap Dilemma: Exhaustive Worked Example

In global and US payroll planning, statutory taxes do not apply indefinitely. Certain taxes are strictly capped when cumulative earnings reach statutory annual limits:
* **US Social Security (FICA)**: $6.2\%$ tax rate, capped at **$\$168,600$** of annual earnings.
* **US Medicare**: $1.45\%$ tax rate (uncapped), plus **$0.9\%$ Additional Medicare Tax** on earnings above $\$200,000$.
* **Federal Unemployment (FUTA)**: $0.6\%$ net effective rate, capped at **$\$7,000$** of annual earnings.
* **State Unemployment (SUTA)**: e.g., $3.5\%$ average rate, capped at **$\$9,000$** of annual earnings.

#### 12-Month Mathematical Proof for an Executive Earning $240,000/Year:
* **Monthly Base Pay**: $\$20,000.00$ per month.
* **Annual Salary**: $\$240,000.00$.

| Month | Monthly Gross Pay | Cumulative YTD Gross | FICA Subject Wages | FICA Tax (6.2%) | Medicare Tax (1.45%) | Addl Medicare (0.9% >$200k) | FUTA Tax (0.6% Cap $7k) | Total Monthly Tax |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Jan** | $\$20,000$ | $\$20,000$ | $\$20,000.00$ | $\$1,240.00$ | $\$290.00$ | $\$0.00$ | $\$42.00$ *(Cap Hit)* | **$\$1,572.00$** |
| **Feb** | $\$20,000$ | $\$40,000$ | $\$20,000.00$ | $\$1,240.00$ | $\$290.00$ | $\$0.00$ | $\$0.00$ | **$\$1,530.00$** |
| **Mar** | $\$20,000$ | $\$60,000$ | $\$20,000.00$ | $\$1,240.00$ | $\$290.00$ | $\$0.00$ | $\$0.00$ | **$\$1,530.00$** |
| **Apr** | $\$20,000$ | $\$80,000$ | $\$20,000.00$ | $\$1,240.00$ | $\$290.00$ | $\$0.00$ | $\$0.00$ | **$\$1,530.00$** |
| **May** | $\$20,000$ | $\$100,000$ | $\$20,000.00$ | $\$1,240.00$ | $\$290.00$ | $\$0.00$ | $\$0.00$ | **$\$1,530.00$** |
| **Jun** | $\$20,000$ | $\$120,000$ | $\$20,000.00$ | $\$1,240.00$ | $\$290.00$ | $\$0.00$ | $\$0.00$ | **$\$1,530.00$** |
| **Jul** | $\$20,000$ | $\$140,000$ | $\$20,000.00$ | $\$1,240.00$ | $\$290.00$ | $\$0.00$ | $\$0.00$ | **$\$1,530.00$** |
| **Aug** | $\$20,000$ | $\$160,000$ | $\$20,000.00$ | $\$1,240.00$ | $\$290.00$ | $\$0.00$ | $\$0.00$ | **$\$1,530.00$** |
| **Sep** | $\$20,000$ | $\$180,000$ | **$\$8,600.00$** *(Partial)*| **$\$533.20$** *(Cap Hit)*| $\$290.00$ | $\$0.00$ | $\$0.00$ | **$\$823.20$** |
| **Oct** | $\$20,000$ | $\$200,000$ | **$\$0.00$** *(Exceeded)* | **$\$0.00$** | $\$290.00$ | $\$0.00$ | $\$0.00$ | **$\$290.00$** |
| **Nov** | $\$20,000$ | $\$220,000$ | **$\$0.00$** *(Exceeded)* | **$\$0.00$** | $\$290.00$ | **$\$180.00$** | $\$0.00$ | **$\$470.00$** |
| **Dec** | $\$20,000$ | $\$240,000$ | **$\$0.00$** *(Exceeded)* | **$\$0.00$** | $\$290.00$ | **$\$180.00$** | $\$0.00$ | **$\$470.00$** |
| **Total**| **$\$240,000$** | — | **$\$168,600.00$** | **$\$10,453.20$** | **$\$3,480.00$** | **$\$360.00$** | **$\$42.00$** | **$\$14,335.20$** |

#### Crucial Insights from the Table:
1. **The Month 9 Cliff**: In September, cumulative earnings hit $\$180,000$. The FICA cap is $\$168,600$. Previous cumulative was $\$160,000$. Therefore, only:
   $$\$168,600 - \$160,000 = \$8,600.00$$
   is taxable. FICA tax drops from $\$1,240.00$ to **$\$533.20$**.
2. **Months 10–12 Zero Tax**: In October, November, and December, taxable FICA earnings are **$\$0.00$**, and FICA tax is strictly **$\$0.00$**.
3. **The Additional Medicare Tax Inversion**: In November, cumulative earnings surpass $\$200,000$, triggering the extra $0.9\%$ tax ($\$20,000 \times 0.9\% = \$180.00$).

---

### 4.3 Low-Level Calculation Script Implementation

The Essbase calculation rule behind `Calculate Compensation` implements this cumulative logic using `@ACCUM`, `@PRIOR`, and conditional branching:

```sql
/* Workforce Tax Calculation Kernel Logic */
FIX(&Year, &Scenario, &Version, @RELATIVE("Total Department", 0))
  FIX(@RELATIVE("Total Employee", 0), @RELATIVE("Total Jobs", 0))

    "Cumulative_Gross_Pay" = @ACCUM("Gross_Salary");

    "FICA_Taxable_Wages" = 
      @MAX(0, 
        @MIN("Gross_Salary", 
          168600 - @PRIOR("Cumulative_Gross_Pay", 1, @RELATIVE("Period", 0))
        )
      );

    "FICA_Tax" = "FICA_Taxable_Wages" * 0.062;

    "Medicare_Tax" = "Gross_Salary" * 0.0145;

    "Addl_Medicare_Tax" = 
      @IF("Cumulative_Gross_Pay" > 200000,
        @IF(@PRIOR("Cumulative_Gross_Pay", 1, @RELATIVE("Period", 0)) >= 200000,
          "Gross_Salary" * 0.009,
          ("Cumulative_Gross_Pay" - 200000) * 0.009
        ),
        0
      );

  ENDFIX
ENDFIX
```

---

## 5. Employee Inter-Departmental Transfers: Behind-the-Scenes Architecture

When an employee transfers from `Department 1001 (Sales East)` to `Department 2002 (Marketing West)` on **September 1st**:

```
+===================================================================================================+
|                              EMPLOYEE TRANSFER EXECUTION ENGINE                                   |
+===================================================================================================+
|                                                                                                   |
|  STEP 1: USER INITIATES ACTION MENU IN WEB FORM                                                   |
|  - Right-clicks employee: E00452_Sarah_Connor                                                     |
|  - Action Menu: "Transfer Employee"                                                               |
|  - Dialog prompts: Target Entity = Dept_2002, Target Job = Marketing_Mgr, Date = 01-Sep-2025       |
|                                                                                                   |
|  STEP 2: GROOVY SCRIPT CAPTURES RUNTIME PROMPTS (RTP)                                             |
|  - Reads grid row: Salary = $120,000, FTE = 1.0, Benefits = Medical_PPO                           |
|  - Validates transfer date against fiscal year boundaries.                                        |
|                                                                                                   |
|  STEP 3: ESSBASE SOURCE BLOCK UPDATE (DEPT 1001)                                                  |
|  - Modifies Property: [End_Date] = 31-Aug-2025.                                                   |
|  - Months Sep - Dec: FTE set to 0.0; Salary set to $0.00.                                         |
|  - Retains Jan - Aug actual expenses in Dept 1001 intact!                                         |
|                                                                                                   |
|  STEP 4: ESSBASE TARGET BLOCK INITIALIZATION (DEPT 2002)                                          |
|  - Instantiates NEW block: [Dept_2002] x [E00452] x [Marketing_Mgr] x [FY25].                     |
|  - Sets Property: [Start_Date] = 01-Sep-2025; [End_Date] = 31-Dec-2025.                          |
|  - Sets [Transfer_In_Flag] = 1.0; Copies salary rate card and benefit options.                   |
|  - Months Jan - Aug: FTE set to 0.0; Months Sep - Dec: FTE set to 1.0.                            |
|                                                                                                   |
|  STEP 5: CROSS-BLOCK RE-INDEXING & RECALCULATION                                                  |
|  - Recalculates both source and target blocks.                                                    |
|  - B-Tree index registers new block in Dept_2002; page files update.                             |
|  - Zero double-counting across the enterprise!                                                    |
|                                                                                                   |
+===================================================================================================+
```

### Technical Detail: Avoiding "Ghost Blocks" During Transfers
If an administrator or custom script creates the target employee block without setting the `Start_Date` property correctly, Essbase calculates a full 12 months of salary in **both** departments, causing corporate headcount and payroll expenses to double-count. Workforce's seeded Groovy logic strictly writes the boundary dates before triggering the calculation.

---

## 6. Relational Repository Schema Behind Workforce

Behind the Essbase cube, the Oracle EPM Cloud relational repository stores employee and job configuration tables:

```
+---------------------------------------------------------------------------------------------------+
|                            WORKFORCE RELATIONAL SCHEMA ARCHITECTURE                               |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  HSP_OBJECT                                                                                       |
|  (Central Object Registry)                                                                        |
|  +--------------------+----------------------+--------------------+                               |
|  | OBJECT_ID (PK)     | OBJECT_NAME          | OBJECT_TYPE        |                               |
|  +--------------------+----------------------+--------------------+                               |
|  | 50012              | E00452_Sarah_Connor  | 32 (Employee)      |                               |
|  | 50013              | Software_Architect   | 33 (Job)           |                               |
|  | 50014              | Medical_PPO_Family   | 34 (Benefit)       |                               |
|  +--------------------+----------------------+--------------------+                               |
|             |                                                                                     |
|             | Links to Member Attributes                                                          |
|             v                                                                                     |
|  HSP_MEMBER_TO_ATTRIBUTE                                                                          |
|  +--------------------+----------------------+--------------------+                               |
|  | MEMBER_ID (FK)     | ATTRIBUTE_ID (FK)    | VALUE_TEXT         |                               |
|  +--------------------+----------------------+--------------------+                               |
|  | 50012              | 801 (Salary_Grade)   | Grade_8            |                               |
|  | 50012              | 802 (Hire_Date)      | 2021-03-15         |                               |
|  | 50012              | 803 (Exempt_Status)  | Exempt             |                               |
|  +--------------------+----------------------+--------------------+                               |
+---------------------------------------------------------------------------------------------------+
```

When metadata is refreshed (**Application -> Overview -> Actions -> Refresh Database**), the platform reads `HSP_OBJECT` and constructs the outline files (`.otm`, `.oti`) for `OEP_WFP`.

---

## 7. Top 10 Twisted Review & Interview Questions on Workforce

### Q1: Why is the `Property` dimension frequently configured as Dense, and what is the trade-off?
**Answer**: In Workforce, calculations require simultaneous evaluation of multiple non-financial attributes (`Start Date`, `End Date`, `FTE`, `Pay Basis`, `Salary`, `Bonus %`, `Medical Plan`). Configuring `Property` as **Dense** places all these attributes into the same contiguous 64KB–512KB memory block. The CPU computes compensation, taxes, and benefits entirely in register cache without issuing secondary block lookups. 
**Trade-off**: It increases the size of every physical data block. If hundreds of unnecessary properties are added, block size can exceed the optimal 256KB threshold, increasing memory consumption.

### Q2: A client selects "Job Only" planning, but 6 months later demands named employee tracking. Can you change this in Application Settings?
**Answer**: **NO**. Workforce granularity is an **irrevocable configuration**. Once enabled, you cannot convert "Job Only" to "Employee and Job". You must either:
1. Rebuild the application from scratch (export all data, delete application, recreate, re-import).
2. Or, build an ugly, high-maintenance custom dimension structure that circumvents seeded module logic.
*Consultant Rule*: Always recommend **Employee and Job** during initial workshops unless the client strictly enforces anonymous retail/manufacturing shift budgeting.

### Q3: How does Workforce calculate Partial FTE, and why is the annual total an average rather than a sum?
**Answer**: If an employee is hired on **October 1st** in a calendar year (Q4):
* Jan – Sep (9 months): $\text{FTE} = 0.0$
* Oct – Dec (3 months): $\text{FTE} = 1.0$
* **Annual Summary FTE**: $\frac{0 + 0 + ... + 1.0 + 1.0 + 1.0}{12} = \frac{3.0}{12} = \mathbf{0.25 \text{ FTE}}$.
The `FTE` account has a Time Balance property of **Average** (or custom formula), preventing corporate rollup reports from showing $3.0$ FTEs for a single person who worked for 3 months!

### Q4: An HR analyst inputs a merit increase of 5% in July, but the annual salary report shows an unexpected dollar amount. What happened?
**Answer**: Common culprits:
1. **Proration Setting**: The module may be configured to evaluate merit timing based on exact hire dates rather than the first day of the merit month.
2. **Salary Basis Mismatch**: If the employee is tagged as "Hourly" instead of "Annual", the merit % is applied to the hourly rate and multiplied by monthly working hours (which vary between 160, 168, and 176 hours depending on the calendar month).
3. **Double Application**: If a user runs `Synchronize Defaults` after manually overriding an employee's salary on a form, the default grade table may overwrite their manual entry.

### Q5: What happens behind the scenes during a mid-year Employee Transfer between two entities?
**Answer**: 
1. The source department block (`Entity_A`) has its `End Date` property updated to the day prior to transfer, zeroing out salary/FTE in subsequent months. Historical expenses remain untouched.
2. A new block is instantiated in the target department (`Entity_B`) with `Start Date` set to the transfer date.
3. Groovy script copies the employee's salary rate, job code, and benefit selections to the new block.
4. Both blocks are calculated, ensuring zero gap and zero double-counting in corporate totals.

### Q6: How does Workforce synchronize with the Financials core cube (`OEP_FS`) without crashing performance?
**Answer**: Workforce does **not** push individual named employees to Financials! Detailed employee records stay inside `OEP_WFP`. The pre-built Data Map (`Compensation to Financials`) aggregates data across Level 0 employees and jobs, drops those dimensions, and maps the summarized dollar totals to Financials Level 0 SG&A accounts (`Base Salaries`, `Fringe Benefits`, `Payroll Taxes`) by Department. Only summary financial numbers cross into `OEP_FS`.

### Q7: If an employee earns $250,000, why does the FICA tax line become zero in the final months of the year?
**Answer**: Statutory payroll tax ceilings. The US federal government caps Social Security taxation at $\$168,600$ of annual gross earnings. Workforce tracks cumulative year-to-date wages in memory. Once cumulative wages exceed $\$168,600$, the calculation rule evaluates taxable wages as $\$0.00$, resulting in zero tax for the remaining periods.

### Q8: Can an end user edit salary amounts directly on a read-only Workforce form?
**Answer**: No. However, on writable forms, if salary is governed by **Job Salary Defaults**, the cell may be dynamically locked by a validation rule. To override the standard grade rate, the user must check the **"Override Salary"** property flag, which triggers cell-level security or dynamic form logic to unlock the `Salary` input cell.

### Q9: What is the difference between `TBH` members and existing employees?
**Answer**:
* **Existing Employees**: Named individuals mapped from HRIS systems with fixed employee IDs and historical tenure.
* **`TBH` (To Be Hired)**: Seeded placeholder members (`TBH1`, `TBH2`, `TBH3`...) used to model open requisitions and future headcount growth. They inherit salary and benefit assumptions directly from their assigned `Job` and `Salary Grade`.

### Q10: How do you handle non-standard compensation like Commissions, Relocation Allowances, and Severance?
**Answer**: Through **Additional Earnings** properties configured in the Workforce setup wizard:
1. **Commission**: Driven by an entered percentage multiplied by projected sales revenue pulled from Financials or Sales planning.
2. **One-Time Lump Sums**: Relocation bonuses or signing bonuses entered in specific individual calendar periods (`BegBalance` or specific month) with calculation type set to **Flat Amount**.
3. **Severance Packages**: Modeled using custom benefit/earning logic tied to an employee's years of service upon departure.

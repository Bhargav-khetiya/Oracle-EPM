# 03 Capital Module (`OEP_CPX`): Complete Techno-Functional Engineering Guide

## 1. What is the Capital Module?

Corporate capital expenditures (Capex)—investments in machinery, IT server infrastructure, facilities, commercial real estate, corporate aircraft, and intangible software licenses—represent massive multi-year financial commitments that dictate a firm's long-term balance sheet health.

The **Capital Module** (`OEP_CPX`) is a pre-built business process in Oracle Enterprise Planning and Budgeting Cloud Service (EPBCS) designed to manage the entire lifecycle of physical and intangible capital investments:
* **New Asset Planning**: Models requests, approvals, purchase timing, and cash disbursements for new property, plant, and equipment (PP&E).
* **Depreciation & Amortization Engines**: Automatically computes monthly non-cash depreciation based on asset class useful lives, salvage values, and statutory accounting depreciation methods.
* **Lease Accounting (IFRS 16 & ASC 842)**: Capitalizes operating leases onto the balance sheet as Right-of-Use (ROU) assets and lease liabilities, calculates present values of discounted lease payment streams, and splits monthly cash lease payments into effective interest expense and liability principal amortization.
* **Construction in Progress (CIP)**: Accumulates labor, contractor, and material costs during construction phases without depreciating, then capitalizes the full asset cost upon the in-service date.
* **Existing Asset Maintenance**: Tracks historical assets, useful life revisions, write-downs (impairments under IAS 36), inter-entity transfers, and asset retirements (computing gain/loss on disposal).

```
+===================================================================================================+
|                                    CAPITAL MODULE ENGINE OVERVIEW                                 |
+===================================================================================================+
|                                                                                                   |
|  [CAPITAL INPUTS]                         [CALCULATION ENGINE]            [FINANCIAL STATEMENTS]  |
|  - Asset Class & Asset Detail             - Straight-Line / DDB / SYD     - Balance Sheet (PP&E)  |
|  - Purchase Cost & In-Service Date        - IFRS 16 Present Value Engine  - Income Statement (Depr|
|  - Lease Terms & Discount Rates           - Amortization Schedules        - Cash Flow (Capex Cash)|
|  - Useful Life & Salvage Values           - CIP Capitalization Logic      - ROU Assets & Leases   |
|  - Retirements & Selling Prices           - Gain / Loss on Disposal       - Debt & Interest Lines |
|                                                                                                   |
+===================================================================================================+
```

### Fresher Metaphor: The Fleet & Property Manager
Imagine an enterprise purchasing a specialized manufacturing machine for $\$120,000$ cash. 
Under corporate accounting rules, a firm **cannot** immediately record a $\$120,000$ expense on Month 1's Income Statement—doing so would falsely imply catastrophic monthly losses. 
Instead:
1. The $\$120,000$ machine is capitalized as a **Fixed Asset** on the Balance Sheet.
2. The cash outflow is recorded under **Cash Flow from Investing Activities**.
3. Over its 5-year operating life, its cost is expensed gradually as **Depreciation** ($\$2,000$ per month) on the Income Statement.

The Capital module automates all of this multi-year mathematical tracking across thousands of assets automatically.

---

## 2. Cube Topology & Dimension Storage Architecture

Capital operations reside in a dedicated Block Storage cube: **`OEP_CPX`** (BSO / Hybrid BSO).

### 2.1 Dimensional Roles & Dense/Sparse Classification

| Dimension Name | Type | Dense/Sparse | Technical Storage & Purpose |
| :--- | :--- | :--- | :--- |
| **`Account`** | System | **Dense** | Financial and driver accounts (`Asset Cost`, `Accumulated Depreciation`, `Depreciation Expense`, `Salvage Value`, `Useful Life Months`). |
| **`Period`** | System | **Dense** | Monthly time periods (`Jan`, `Feb`, ... `Dec`, `BegBalance`). |
| **`Asset Class`** | Module | **Sparse** | Parent asset categories that establish default depreciation rules (`Buildings`, `Machinery & Equipment`, `IT Hardware`, `Vehicles`, `Intangibles`). |
| **`Asset Detail`** | Module | **Sparse** | Specific physical or requested asset instances (`Server_Rack_001`, `CNC_Machine_02`, `CIP_Warehouse_Phase1`). |
| **`Entity`** | Core | **Sparse** | Corporate entities and cost centers owning the assets (`1001_Corporate_HQ`, `3001_Factory_Berlin`). |
| **`Version`** | Core | **Sparse** | Scenarios and versions (`Working`, `Approved_Capex`, `WhatIf_Lease`). |
| **`Scenario`** | Core | **Sparse** | Data streams (`Plan`, `Forecast`, `Actual`). |
| **`Years`** | Core | **Sparse** | Projection years (`FY24`, `FY25`, `FY26`...). |

---

## 3. Depreciation Methods Waterfall: Mathematical Comparison

Capital natively provides standard global accounting depreciation algorithms. 

### Comparative Scenario Parameters:
* **Asset Cost**: $\$60,000.00$
* **Salvage Value**: $\$6,000.00$
* **Depreciable Base**: $\text{Cost} - \text{Salvage} = \$60,000 - \$6,000 = \$54,000.00$
* **Useful Life**: 5 Years ($60$ Months)
* **Straight-Line Rate**: $\frac{1}{5} = 20\%$ per year ($1.667\%$ per month)
* **Double-Declining Rate**: $2 \times 20\% = 40\%$ per year

### 3.1 Mathematical Formulas
1. **Straight-Line (SL)**:
   $$\text{Annual Depr} = \frac{\text{Cost} - \text{Salvage Value}}{\text{Useful Life in Years}} = \frac{\$54,000}{5} = \$10,800.00 / \text{year}$$
   $$\text{Monthly Depr} = \frac{\$10,800}{12} = \$900.00 / \text{month}$$

2. **Double-Declining Balance (DDB)**:
   $$\text{Depr}_t = \text{Beginning Book Value}_t \times \left(\frac{2}{\text{Useful Life}}\right)$$
   *(Note: Depreciates until Net Book Value hits Salvage Value; switches to Straight-Line when SL yields higher depreciation).*

3. **Sum-of-the-Years'-Digits (SYD)**:
   $$\text{Denominator} = \frac{n(n + 1)}{2} = \frac{5(6)}{2} = 15$$
   $$\text{Annual Depr}_t = (\text{Cost} - \text{Salvage}) \times \frac{\text{Remaining Useful Life}_t}{15}$$

### 3.2 5-Year Comparative Waterfall Table

| Year | Straight-Line (SL) Expense | SL Ending Book Value | Double-Declining (DDB) Expense | DDB Ending Book Value | Sum-of-Years' Digits (SYD) Expense | SYD Ending Book Value |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Yr 0** | — | $\$60,000.00$ | — | $\$60,000.00$ | — | $\$60,000.00$ |
| **Yr 1** | $\$10,800.00$ | $\$49,200.00$ | $\$24,000.00$ ($40\% \times \$60\text{k}$) | $\$36,000.00$ | $\$18,000.00$ ($\frac{5}{15} \times \$54\text{k}$) | $\$42,000.00$ |
| **Yr 2** | $\$10,800.00$ | $\$38,400.00$ | $\$14,400.00$ ($40\% \times \$36\text{k}$) | $\$21,600.00$ | $\$14,400.00$ ($\frac{4}{15} \times \$54\text{k}$) | $\$27,600.00$ |
| **Yr 3** | $\$10,800.00$ | $\$27,600.00$ | $\$8,640.00$ ($40\% \times \$21.6\text{k}$) | $\$12,960.00$ | $\$10,800.00$ ($\frac{3}{15} \times \$54\text{k}$) | $\$16,800.00$ |
| **Yr 4** | $\$10,800.00$ | $\$16,800.00$ | $\$5,184.00$ *(or switch to SL)* | $\$7,776.00$ | $\$7,200.00$ ($\frac{2}{15} \times \$54\text{k}$) | $\$9,600.00$ |
| **Yr 5** | $\$10,800.00$ | **$\$6,000.00$** | **$\$1,776.00$** *(Capped at Salvage)*| **$\$6,000.00$** | $\$3,600.00$ ($\frac{1}{15} \times \$54\text{k}$) | **$\$6,000.00$** |
| **Total**| **$\$54,000.00$** | — | **$\$54,000.00$** | — | **$\$54,000.00$** | — |

> [!IMPORTANT]
> **Key Architectural Insight**: Across all methods, total cumulative depreciation over 5 years is **identically $\$54,000.00$**, and the ending net book value is strictly equal to the **$\$6,000.00$ Salvage Value**. The difference lies entirely in **timing**: DDB front-loads $71.1\%$ of total depreciation into the first 2 years, whereas Straight-Line spreads it evenly at $20\%$ per year.

---

## 4. Lease Accounting: IFRS 16 & ASC 842 Compliance

Under international accounting standards (IFRS 16 and ASC 842), operating leases can no longer be hidden off-balance sheet as ordinary monthly rent expense. All leases over 12 months must be capitalized onto the balance sheet!

### 4.1 The Discounted Cash Flow Present Value (PV) Formula

When an enterprise enters into a lease agreement:
* **Monthly Lease Payment ($PMT$)**: $\$5,000.00$
* **Lease Term ($n$)**: 36 Months (3 Years)
* **Discount Rate / Incremental Borrowing Rate ($r$)**: $6.0\%$ annual ($\frac{6.0\%}{12} = 0.5\%$ per month, or $r = 0.005$)

$$\text{PV of Lease Obligations} = \sum_{t=1}^{n} \frac{PMT}{(1 + r)^t} = PMT \times \left[ \frac{1 - (1 + r)^{-n}}{r} \right]$$

Plugging in the parameters:
$$\text{Annuity Factor} = \frac{1 - (1.005)^{-36}}{0.005} = \frac{1 - 0.835644}{0.005} = \frac{0.164356}{0.005} = 32.871016$$
$$\mathbf{\text{Present Value (Initial Asset \& Liability)}} = \$5,000.00 \times 32.871016 = \mathbf{\$164,355.08}$$

---

### 4.2 Complete 36-Month Lease Amortization Schedule (Sample Progression)

Upon lease inception:
* **Balance Sheet Asset**: Right-of-Use (ROU) Asset = **$\$164,355.08$**
* **Balance Sheet Liability**: Lease Obligation = **$\$164,355.08$**
* **Monthly ROU Depreciation (Straight-Line)**: $\frac{\$164,355.08}{36} = \mathbf{\$4,565.42} / \text{month}$

| Month | Beginning Liability | Total Cash Payment | Effective Interest (0.5%) | Principal Amortization | Ending Lease Liability | ROU Asset Depreciation | Ending ROU Net Asset | Total P&L Expense |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **M01** | $\$164,355.08$ | $\$5,000.00$ | $\$821.78$ | $\$4,178.22$ | $\$160,176.86$ | $\$4,565.42$ | $\$159,789.66$ | **$\$5,387.20$** |
| **M02** | $\$160,176.86$ | $\$5,000.00$ | $\$800.88$ | $\$4,199.12$ | $\$155,977.74$ | $\$4,565.42$ | $\$155,224.24$ | **$\$5,366.30$** |
| **M03** | $\$155,977.74$ | $\$5,000.00$ | $\$779.89$ | $\$4,220.11$ | $\$151,757.63$ | $\$4,565.42$ | $\$150,658.82$ | **$\$5,345.31$** |
| **M04** | $\$151,757.63$ | $\$5,000.00$ | $\$758.79$ | $\$4,241.21$ | $\$147,516.42$ | $\$4,565.42$ | $\$146,093.40$ | **$\$5,324.21$** |
| **M05** | $\$147,516.42$ | $\$5,000.00$ | $\$737.58$ | $\$4,262.42$ | $\$143,254.00$ | $\$4,565.42$ | $\$141,527.98$ | **$\$5,303.00$** |
| **M06** | $\$143,254.00$ | $\$5,000.00$ | $\$716.27$ | $\$4,283.73$ | $\$138,970.27$ | $\$4,565.42$ | $\$136,962.56$ | **$\$5,281.69$** |
| ... | ... | ... | ... | ... | ... | ... | ... | ... |
| **M18** | $\$89,321.45$ | $\$5,000.00$ | $\$446.61$ | $\$4,553.39$ | $\$84,768.06$ | $\$4,565.42$ | $\$82,177.54$ | **$\$5,012.03$** |
| ... | ... | ... | ... | ... | ... | ... | ... | ... |
| **M35** | $\$9,925.62$ | $\$5,000.00$ | $\$49.63$ | $\$4,950.37$ | $\$4,975.25$ | $\$4,565.42$ | $\$4,565.42$ | **$\$4,615.05$** |
| **M36** | $\$4,975.25$ | $\$5,000.00$ | $\$24.88$ | $\$4,975.12$ | **$\$0.00$** | $\$4,565.42$ | **$\$0.00$** | **$\$4,590.30$** |
| **Total**| — | **$\$180,000.00$**| **$\$15,644.92$** | **$\$164,355.08$**| — | **$\$164,355.08$**| — | **$\$180,000.00$**|

---

### 4.3 The Critical P&L Front-Loading & EBITDA Distortion (Must-Know Interview Concept)

Notice two profound financial realities illuminated in this schedule:

1. **The P&L Expense Front-Loading Trap**:
   * Under legacy accounting, rent was a flat $\$5,000/\text{month}$ on the P&L ($12 \times \$5,000 = \$60,000/\text{yr}$).
   * Under IFRS 16:
     * In **Month 1**, total P&L expense = $\$4,565.42 \text{ (ROU Depr)} + \$821.78 \text{ (Interest)} = \mathbf{\$5,387.20}$!
     * In **Month 36**, total P&L expense = $\$4,565.42 + \$24.88 = \mathbf{\$4,590.30}$.
   * **Result**: IFRS 16 **front-loads total expenses into early years**, temporarily depressing Net Income in Year 1!

2. **The Artificial EBITDA Boost**:
   * Under legacy rules, $\$5,000$ rent sat in Operating Expenses, **reducing EBITDA**.
   * Under IFRS 16, that $\$5,000$ cash outflow is eliminated from Operating Expenses! It is split into **Depreciation** (D in EBITDA) and **Interest** (I in EBITDA).
   * **Result**: **EBITDA increases significantly** under IFRS 16, even though not a single extra dollar of cash entered the business!

---

## 5. Construction in Progress (CIP) Capitalization Engine

Enterprises constructing corporate campuses, data centers, or custom software accumulate expenses across multi-month construction phases.

```
+===================================================================================================+
|                                CIP CAPITALIZATION LIFECYCLE                                       |
+===================================================================================================+
|                                                                                                   |
|  PHASE 1: CONSTRUCTION ACCUMULATION (MONTHS 1 - 12)                                               |
|  - Invoices for raw materials, architecture design, and contractor labor arrive.                  |
|  - Stored in CIP Asset Detail: "CIP_DataCenter_Bldg" under Asset Class: CIP.                      |
|  - Depreciation Rule Evaluation: DEPRECIATION = $0.00 (CIP is non-depreciable).                   |
|  - Balance Sheet: CIP Asset balance grows: $500,000 -> $1,200,000 -> $3,500,000.                  |
|                                                                                                   |
|  PHASE 2: IN-SERVICE DATE EVENT (MONTH 13)                                                        |
|  - Building passes municipal inspection; facility opens for operation.                           |
|  - User selects Action Menu: "Capitalize Asset / Put In Service".                                 |
|  - Inputs: In-Service Date = 01-Jan-2026, Target Class = Buildings, Useful Life = 360 Months.       |
|                                                                                                   |
|  PHASE 3: ESSBASE KERNEL EXECUTION                                                                |
|  - Business Rule: Moves total accumulated cost ($3,500,000) from CIP to Buildings.                |
|  - Zeroes out CIP balance: [CIP_DataCenter_Bldg] = $0.00.                                         |
|  - Instantiates Fixed Asset: [DataCenter_Operational] = $3,500,000.                               |
|  - Triggers Straight-Line Depreciation: $3,500,000 / 360 = $9,722.22 / month.                     |
|                                                                                                   |
+===================================================================================================+
```

---

## 6. Existing Asset Management: Impairments, Transfers, and Retirements

### 6.1 Asset Retirement & Gain/Loss on Disposal
When an enterprise sells or retires an asset prior to full depreciation:
1. User enters: **Retirement Date** and **Cash Proceeds (Selling Price)**.
2. The `Retire Asset` rule calculates:
   $$\text{Net Book Value (NBV)} = \text{Original Cost} - \text{Accumulated Depreciation}$$
   $$\text{Gain / Loss on Disposal} = \text{Selling Price} - \text{NBV}$$
3. **Accounting Balance Sheet Flush**:
   * Fixed Asset Gross Cost is credited to $\$0.00$.
   * Accumulated Depreciation is debited to $\$0.00$.
   * Gain/Loss is written to the P&L (Non-Operating Income/Expense).
   * Cash proceeds flow to Cash Flow from Investing Activities.

### 6.2 Asset Impairment (IAS 36 / US GAAP)
If an asset's market value collapses (e.g., specialized manufacturing hardware made obsolete by new technology):
* Planners enter the **Recoverable Amount**.
* If $\text{Recoverable Amount} < \text{Net Book Value}$:
  $$\text{Impairment Loss} = \text{NBV} - \text{Recoverable Amount}$$
* The rule writes an immediate non-cash impairment expense to the P&L and writes down the asset book value.

---

## 7. Tri-Statement Financial Statement Integration

A single Capex action in `OEP_CPX` synchronously ripples through all three primary financial statements in Financials (`OEP_FS`):

```
                                [NEW ASSET PURCHASE]
                       $120,000 Production Server Fleet
                                         |
         +-------------------------------+-------------------------------+
         |                               |                               |
         v                               v                               v
  [BALANCE SHEET]               [INCOME STATEMENT]              [CASH FLOW STATEMENT]
  Fixed Assets (PP&E)           Depreciation Expense            Cash Flow from Investing:
  increases by $120,000.        increases by $2,000/mo.         Capital Expenditure (Capex)
  Accumulated Depr              (Reduces Operating Income       Outflow = -$120,000 in Month 1.
  increases by $2,000/mo.       and Net Income).                Depreciation added back to
                                                                Operating Cash Flow (+ $2,000).
```

---

## 8. Top 10 Twisted Review & Interview Questions on Capital

### Q1: What is the fundamental difference between an Asset Class and an Asset Detail?
**Answer**: 
* **`Asset Class`**: Parent dimension member governing global corporate accounting assumptions (e.g., `Machinery`, `Buildings`, `Vehicles`, `Intangibles`). Standard useful lives (e.g., 60 months) and depreciation conventions (e.g., Straight-Line, half-month convention) are maintained at the Asset Class level.
* **`Asset Detail`**: Specific physical or requested asset instance (`Forklift_01`, `Dell_PowerEdge_Cluster`). Individual assets inherit defaults from their parent Asset Class, but users with proper security permissions can override useful life or depreciation method for specific assets.

### Q2: Why does EBITDA increase under IFRS 16 / ASC 842 lease accounting compared to legacy operating lease accounting?
**Answer**: Under legacy lease accounting, monthly lease payments were treated as **Operating Rent Expense** within SG&A, directly reducing EBITDA. Under IFRS 16, the operating lease is capitalized onto the balance sheet. The cash payment is decomposed into **ROU Asset Depreciation** and **Lease Liability Interest Expense**. Because EBITDA stands for Earnings *Before* Interest, Taxes, Depreciation, and Amortization, removing rent from operating expenses and reclassifying it as Interest and Depreciation automatically inflates reported EBITDA!

### Q3: Why does IFRS 16 lease accounting front-load total P&L expenses in Year 1?
**Answer**: ROU Asset depreciation is straight-line (constant every month), but lease liability interest is computed using the **effective interest method** on the remaining unpaid liability balance. Because the principal liability is highest in Month 1, the monthly interest expense is also highest in Month 1 ($\$821.78$ vs $\$24.88$ in Month 36). Adding flat depreciation plus declining interest produces a downward-sloping total monthly expense curve, front-loading P&L costs in early periods.

### Q4: How does Capital handle Construction in Progress (CIP) assets from a depreciation perspective?
**Answer**: CIP assets have their depreciation method set to **No Depreciation / None**. Costs accumulate across periods in CIP accounts without affecting P&L depreciation. When the asset is placed in service, the user triggers the seeded `Capitalize Asset` rule, which credits CIP, debits the target depreciable Asset Class, and activates the depreciation calculation beginning in the in-service month.

### Q5: What happens in Essbase when an asset is retired before its useful life is complete?
**Answer**: The `Retire Asset` rule executes an atomic accounting write-off:
1. Calculates ending Net Book Value ($\text{Cost} - \text{Accumulated Depreciation}$).
2. Calculates $\text{Gain / Loss} = \text{Cash Proceeds} - \text{NBV}$.
3. Sets the asset's active status flag to 0.
4. Flushes the asset's gross cost and accumulated depreciation from the balance sheet in all subsequent periods, stopping future depreciation calculations immediately.

### Q6: Can you plan Intangible Assets in the Capital module, and how does the accounting differ?
**Answer**: **Yes**. In the Capital feature enablement wizard, the administrator enables **Intangibles**. Intangible assets (capitalized software, patents, copyrights) calculate **Amortization** rather than depreciation, following IAS 38 / ASC 350. They are segregated on the Balance Sheet under Intangible Assets rather than Tangible PP&E.

### Q7: If a company buys a $50,000 asset with a $5,000 salvage value over 5 years, why does DDB depreciation in Year 5 calculate as $1,776 instead of 40% of remaining book value?
**Answer**: The **Salvage Value Floor Rule**. In Year 4, ending book value was $\$7,776.00$. If DDB applied its normal $40\%$ rate in Year 5:
$$\$7,776.00 \times 40\% = \$3,110.40$$
Subtracting $\$3,110.40$ from $\$7,776.00$ would leave an ending book value of:
$$\$7,776.00 - \$3,110.40 = \$4,665.60$$
which violates the accounting law that an asset cannot be depreciated below its salvage value ($\$6,000.00$)! Therefore, the Capital engine caps Year 5 depreciation strictly at:
$$\$7,776.00 - \$6,000.00 = \mathbf{\$1,776.00}$$.

### Q8: How does Capital integrate with the Projects module (`OEP_PFP`)?
**Answer**: In organizations executing capital projects (e.g., developing proprietary software or constructing manufacturing plants), labor hours and contractor materials are budgeted inside Projects (`OEP_PFP`) under a Capital Project. Once the project finishes, the **"Push to Capital"** business rule capitalizes the project's total cumulative cost into a new Asset Detail inside `OEP_CPX`, initiating monthly depreciation.

### Q9: What is the Half-Month / Mid-Quarter Convention in Capital?
**Answer**: Tax and corporate accounting policies often stipulate that assets purchased mid-period do not receive a full month of depreciation:
* **Half-Month**: Assets placed in service on or before the 15th receive a full month of depreciation; assets placed after the 15th receive a half-month or begin next month.
* **Full Month**: Full month depreciation regardless of purchase day.
Capital provides configurable depreciation convention settings during module setup.

### Q10: How does Capital data flow into Financials (`OEP_FS`) without manual re-keying?
**Answer**: Through the seeded **`Capital to Financials`** Data Map and Smart Push. When an asset is created or updated, Smart Push transfers:
1. New asset additions to Financials Balance Sheet account: `Property, Plant and Equipment - Additions`.
2. Calculated monthly depreciation to Financials P&L account: `Depreciation Expense`.
3. Cash outflows to Financials Cash Flow account: `Capital Expenditures`.
All dimensional intersections align automatically via pre-built module mappings.

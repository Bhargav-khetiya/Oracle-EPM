# 02 Oracle EPM Application Types: PBCS, EPBCS, Custom, FreeForm, and FCCS

## 1. The Oracle EPM Cloud Application Landscape

Oracle Enterprise Performance Management Cloud is not a monolithic tool; it is a unified suite offering specialized application types tailored for specific enterprise finance functions. As a techno-functional consultant, you must know the technical capabilities, cube limits, and business use cases for every application type:

```
+===================================================================================================+
|                                  ORACLE EPM CLOUD APPLICATION TYPES                               |
+===================================================================================================+
|                                                                                                   |
|  [PLANNING BUSINESS PROCESSES]                                                                    |
|  +------------------------------+  +------------------------------+  +-------------------------+  |
|  | CUSTOM PLANNING              |  | MODULE-BASED (EPBCS)         |  | FREEFORM PLANNING       |  |
|  | - Complete blank canvas      |  | - Out-of-the-box modules:    |  | - Pure Essbase in Cloud |  |
|  | - Design own dimensions     |  |   Fin, WFP, CPX, PFP, HSF    |  | - Zero required dims    |  |
|  | - Max 12 Cubes (6 BSO/6 ASO) |  | - Pre-built forms & rules    |  | - Up to 12 Cubes        |  |
|  +------------------------------+  +------------------------------+  +-------------------------+  |
|                                                                                                   |
|  [FINANCIAL CLOSE & CONSOLIDATION]                                                                |
|  +---------------------------------------------------------------------------------------------+  |
|  | FINANCIAL CONSOLIDATION AND CLOSE (FCCS)                                                    |  |
|  | - Statutory financial close, balance sheet balance, CTA, intercompany eliminations           |  |
|  | - Mandatory 11-13 core dimensions (Consolidation, View, Intercompany, Movement, Multi-GAAP)  |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                                                                   |
|  [SPECIALIZED BUSINESS PROCESSES]                                                                 |
|  +--------------------+  +--------------------+  +--------------------+  +---------------------+  |
|  | TAX REPORTING      |  | PROFITABILITY (PCM)|  | NARRATIVE REPORTING|  | ENTERPRISE DATA MGT |  |
|  | - Tax provisions   |  | - Activity-based   |  | - Collaborative    |  | - Centralized master|  |
|  | - CbCR regulatory  |  |   cost allocations |  |   board report pack|  |   metadata (EDMCS)  |  |
|  +--------------------+  +--------------------+  +--------------------+  +---------------------+  |
+===================================================================================================+
```

---

## 2. Exhaustive Comparison Matrix

| Application Type | Mandatory Dimensions | Max Cubes Permitted | Groovy Engine— | Primary Business Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Custom Planning** | Account, Entity, Scenario, Version, Period, Years | Up to 12 (6 BSO + 6 ASO) | **Yes** (Enterprise SKU) | Tailored corporate budgeting where pre-built modules do not fit business model. |
| **Module-Based (EPBCS)**| Seeded module dims (`Plan Element`, `Property`, `Asset Class`, `Project`) | Dedicated module cubes (`OEP_FS`, `OEP_WFP`, `OEP_CPX`, `OEP_PFP`, `OEP_REP`) | **Yes** (Enterprise SKU) | Best-practice corporate planning with rapid time-to-value. |
| **FreeForm Planning** | **NONE** (Zero required dimensions) | Up to 12 Cubes (BSO, ASO, Hybrid) | **Yes** | Direct lift-and-shift of on-premises standalone Essbase applications without Planning overhead. |
| **FCCS** | Mandatory 11-13 dimensions (`Consolidation`, `Movement`, `Intercompany`, `Data Source`) | Pre-configured consolidation cubes | Supported with restrictions | Statutory month-end legal financial close, IFRS/GAAP consolidations, intercompany eliminations. |
| **Tax Reporting (TRCS)**| National, Regional, Tax Account, Movement | Pre-configured Tax cubes | Supported | Calculating corporate effective tax rates, tax provisions, and country-by-country reporting. |
| **PCMCS** | Rule, Allocation, Cost Center, Activity | High-volume ASO/BSO allocation engine | Pre-configured engine | Heavy multi-tier allocations, product/customer profitability, cost-to-serve analysis. |

---

## 3. Deep Dive: Custom Planning vs. EPBCS (Modules)

This is one of the most frequently asked review questions:

### When to Recommend Custom Planning:
* The client has highly unique industry mechanics that do not conform to standard SG&A (e.g., Oil & Gas upstream exploration, Commercial Airline seat-mile yield planning, High-frequency hedge fund trading).
* The client wants complete freedom over dimensional naming and outline hierarchies without unused seeded accounts.

### When to Recommend Module-Based (EPBCS):
* The client wants accelerated deployment (weeks instead of months).
* The client requires pre-built, best-practice financial statements, employee roster compensation modeling, or lease accounting (IFRS 16 / ASC 842).
* The client wants pre-configured integration data maps between Workforce, Capital, and Financials.

---

## 4. Deep Dive: What Makes FreeForm Planning Revolutionary—

In legacy on-premises Essbase, companies had hundreds of standalone cubes that did NOT have traditional Planning dimensions (e.g., a supply chain cube with dimensions: `Warehouse`, `Pallet_Type`, `Truck_Route`, `Metric`, `Day`).
* Traditional Planning rejected this because Planning **strictly mandated** `Account`, `Entity`, `Scenario`, `Version`, `Period`, and `Years`.
* **FreeForm Planning** removes all restrictions! You can create a cube with **any dimensions you want**, or migrate an on-premises Essbase `.otl` file directly into Oracle EPM Cloud with a single click.

---

## 5. Deep Dive: FCCS Consolidation Mechanics vs. Planning Aggregation

A common interview trap is confusing an **EPBCS Rollup** with an **FCCS Consolidation**:

| Dimension | Planning Rollup (`OEP_FS`) | FCCS Statutory Consolidation |
| :--- | :--- | :--- |
| **Engine Mechanism** | Mathematical Hierarchical Rollup (`+`, `-`, `~`) in Essbase. | Multi-stage statutory accounting consolidation engine. |
| **Intercompany** | Requires custom elimination rules or custom dimensions. | **Automated Elimination**: Reads `Intercompany` dimension; eliminates balances at the first common parent. |
| **Currency Translation** | Simple multiplication by exchange rate table. | **GAAP / IFRS Compliance**: Translates P&L at Average, Balance Sheet at Ending, Equity at Historical, computing CTA. |
| **Ownership Structure** | Assumes 100% consolidation rollup. | Supports **Ownership Management**: Legal entities consolidated at 60%, 40% (Equity Method), or minority interests. |
| **Movement Dimension** | Typically not used unless custom built. | **Mandatory**: Tracks opening balance, additions, disposals, currency translation impact, and closing balance. |


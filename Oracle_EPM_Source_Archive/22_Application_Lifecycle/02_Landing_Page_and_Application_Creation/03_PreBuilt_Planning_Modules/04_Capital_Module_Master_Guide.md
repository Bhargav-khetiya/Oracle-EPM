﻿# 🏗️ Capital Module — Complete Master Setup Guide
## Capital Asset Planning, Depreciation, Lease Accounting (ASC 842 / IFRS 16) & Lifecycle Governance

> **Module:** Capital  
> **Target Cubes:** `OEP_CAP` (BSO Hybrid) + `OEP_REP` (ASO Reporting)  
> **Subscriptions Supported:** Enterprise & Standard Cloud EPM  
> **Integration Ecosystem:** Automatically feeds Depreciation & Amortization to Financials P&L (`OEP_FS`), Capital Expenditures (CapEx) to Cash Flow, and Asset/Liability balances to Balance Sheet

---

## 🎯 Architecture Overview & Value Proposition

The **Capital** module automates the entire planning lifecycle for fixed assets, intangible assets, and leased equipment. Rather than managing cumbersome, error-prone offline Excel depreciation schedules, Capital integrates physical asset planning directly into financial statements:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       CAPITAL MODULE ARCHITECTURE                           │
├──────────────────────────────────────┬──────────────────────────────────────┤
│ 📐 ASSET PLANNING WORKBENCH          │ 🔗 FINANCIAL INTEGRATION (SMART PUSH)│
├──────────────────────────────────────┼──────────────────────────────────────┤
│ • New Asset Requests & Business Cases│ ➔ Depreciation Expense ➔ P&L (OEP_FS)│
│ • Existing Asset Depreciation Schedules│ ➔ CapEx Cash Outflow ➔ Cash Flow    │
│ • IFRS 16 / ASC 842 Lease Schedules  │ ➔ Net Book Value ➔ Balance Sheet     │
│ • Asset Transfers, Impairments, Sales│ ➔ Lease Liabilities ➔ Balance Sheet  │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

---

## 📋 Enable Features: Complete Configuration Screen

To unlock the Capital module, navigate to **Application → Configure → Capital → Enable Features**:

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Enable Features: Capital                                                [ Enable ]  [ Cancel ]   │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                  │
│ 🏢 Tangible Assets:                                                                              │
│   ☑ Enable Tangible Assets Planning                                                              │
│       ☑ Land                                                                                     │
│       ☑ Buildings & Improvements                                                                 │
│       ☑ Machinery & Manufacturing Equipment                                                      │
│       ☑ Furniture & Fixtures                                                                     │
│       ☑ Office & IT Equipment                                                                    │
│       ☑ Vehicles & Transportation                                                                │
│                                                                                                  │
│ 💡 Intangible Assets:                                                                            │
│   ☑ Enable Intangible Assets Planning                                                            │
│       ☑ Software & Intellectual Property                                                         │
│       ☑ Patents & Trademarks                                                                     │
│       ☑ Goodwill & Licenses                                                                      │
│                                                                                                  │
│ 📜 Lease Assets (IFRS 16 / ASC 842 Compliance):                                                  │
│   ☑ Enable Lease Asset Planning                                                                  │
│       🔘 Low-Value Asset Exemption Tracking                                                      │
│       🔘 Short-Term Lease Exemption Tracking                                                     │
│                                                                                                  │
│ 🔄 Asset Lifecycle Operations:                                                                   │
│   ☑ Existing Assets (Import & Manage Active Asset Register)                                     │
│   ☑ New Asset Investment Requests (Capital Approval Unit Hierarchy)                              │
│   ☑ Asset Transfers (Inter-Department & Inter-Entity Transfers)                                  │
│   ☑ Asset Impairments & Write-Offs                                                               │
│   ☑ Asset Retirements & Disposals                                                                │
│                                                                                                  │
│ 📊 Driver & Calculation Modes:                                                                   │
│   ☑ Driver-Based Depreciation Planning                                                           │
│   ☑ Direct Input / Override Planning                                                             │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

> [!CAUTION]
> **Irreversible Feature Enablement:**  
> Once an asset class or feature is enabled, its account hierarchies and dimension members **cannot be removed** from `OEP_CAP`. Always validate the asset classes needed by your enterprise before clicking **[ Enable ]**.

---

## 📉 Depreciation Methods Dictionary & Calculation Mechanics

Capital supports all global GAAP and IFRS statutory depreciation methods:

| Method Name | Mathematical Formula | Accounting Application |
|:---|:---|:---|
| **Straight Line (SL)** | $\frac{\text{Cost} - \text{Salvage Value}}{\text{Useful Life (Months)}}$ | Buildings, IT equipment, furniture; equal charge over useful life. |
| **Declining Balance (DB)** | $\text{Book Value} \times \left(\frac{1}{\text{Useful Life}}\right) \times \text{Factor}$ | Accelerated depreciation for machinery that loses value rapidly early on. |
| **Double Declining (DDB)** | $\text{Book Value} \times \left(\frac{2}{\text{Useful Life}}\right)$ | Highly aggressive acceleration; switches to Straight Line when optimal. |
| **Sum of the Years' Digits (SYD)**| $(\text{Cost} - \text{Salvage}) \times \frac{\text{Remaining Life}}{\sum \text{Years}}$ | Accelerated depreciation with smooth tapering over asset life. |
| **Units of Production** | $(\text{Cost} - \text{Salvage}) \times \frac{\text{Units Current Period}}{\text{Total Estimated Units}}$ | Mining, heavy equipment, commercial vehicles based on mileage or run hours. |
| **No Depreciation** | N/A | Land, works of art, assets held for sale. |

---

## 📜 ASC 842 & IFRS 16 Lease Accounting Deep Dive

Under modern lease accounting standards (ASC 842 / IFRS 16), operating leases can no longer remain off-balance-sheet:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      LEASE ACCOUNTING SCHEDULE ENGINE                       │
├──────────────────────────────────────┬──────────────────────────────────────┤
│ 📥 LEASE CONTRACT INPUT DRIVERS      │ 📤 SYSTEM-CALCULATED FINANCIAL LINES │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ • Lease Start Date & Lease Term      │ • **Right-of-Use (ROU) Asset**       │
│ • Monthly / Quarterly Lease Payment  │ • **Lease Liability (Short/Long)**   │
│ • Incremental Borrowing Rate (IBR %) │ • **Interest Expense** (Amortization)│
│ • Payment Timing (In Advance/Arrears)│ • **Depreciation / Rent Expense**    │
│ • Classification (Finance vs Operating)│ • **Periodic Principal Payment**   │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

### Lease Calculation Phases:
1. **Present Value Calculation:** Capital computes the Present Value (PV) of future lease payments discounted at the tenant's Incremental Borrowing Rate (IBR).
2. **Day 1 Capitalization:** Records initial Right-of-Use (ROU) Asset and equal Lease Liability.
3. **Monthly Amortization Schedule:**  
   - Interest is calculated on the remaining liability balance.  
   - The lease payment reduces the principal liability.  
   - The ROU asset is amortized straight-line over the shorter of lease term or asset life.

---

## 🏗️ Pre-Built Capital Dimensions

When Capital is enabled, the `OEP_CAP` cube is instantiated with specialized dimensions:

| Dimension | Role in Cube | Seeded Members & Structure |
|:---|:---|:---|
| **Asset Class** | Categorizes capital types | `Tangible Assets`, `Intangible Assets`, `Leased Assets` |
| **Asset Detail** | Line-item asset tracking | `Existing Assets`, `New Asset Requests`, `Asset_001`, `Asset_002` |
| **Cap Account** | Financial lines & drivers | `Asset Cost`, `Accumulated Depreciation`, `Net Book Value`, `Depreciation Expense`, `Salvage Value`, `Useful Life in Months` |
| **Property Type** | Physical location/class | `Owned`, `Leased`, `Capitalized Project Asset` |
| **Plan Element** | Calculation staging | `Input`, `Calculated`, `Overrides`, `Smart Push` |

---

## 📝 Pre-Built Data Forms & User Workflows

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│ Capital User Navigation Flow                                                            │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  ┌─────────────────────────┐   ┌─────────────────────────┐   ┌────────────────────────┐ │
│  │ 📑 Manage Assets        │   │ ➕ New Asset Requests   │   │ 📜 Lease Assets        │ │
│  │ View active register,   │   │ Submit business cases,  │   │ Enter lease terms,     │ │
│  │ run depreciation rules  │   │ CapEx justification     │   │ generate ROU schedules │ │
│  └─────────────────────────┘   └─────────────────────────┘   └────────────────────────┘ │
│                                                                                         │
│  ┌─────────────────────────┐   ┌─────────────────────────┐   ┌────────────────────────┐ │
│  │ 🔄 Asset Actions        │   │ 📊 Financial Impact     │   │ 🚀 Push to Financials  │ │
│  │ Transfers, impairments, │   │ Audit P&L, Balance Sheet│   │ Smart Push data map to │ │
│  │ disposals & salvage     │   │ and Cash Flow impacts   │   │ update OEP_FS cube     │ │
│  └─────────────────────────┘   └─────────────────────────┘   └────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### Essential Capital Forms:
- **`Existing Asset Schedule`:** Grid for updating useful life adjustments, salvage estimates, and running mid-year deprecation updates.
- **`New Asset Input Form`:** Allows department heads to enter anticipated CapEx purchases (Purchase Date, Cost, Category) and select justification codes.
- **`Lease Schedule Input Grid`:** Form where contract managers enter lease payments, interest rates, and commencement dates.
- **`Asset Transfer Dialog`:** Wizard for shifting capital cost and accumulated depreciation from Cost Center A to Cost Center B.

---

## 🔄 Smart Push Integration: Pushing Capital to Financials

Capital calculates at the physical asset level. To reflect these figures in the company's financial statements:

1. Navigate to **Application → Data Maps**.
2. Select **`Capital to Financials`** Data Map:
   - Source Cube: `OEP_CAP`
   - Target Cube: `OEP_FS`
3. Mappings:
   - `OEP_CAP.Depreciation Expense` ➔ `OEP_FS.Depreciation Expense (P&L)`
   - `OEP_CAP.Capital Expenditure` ➔ `OEP_FS.Capital Outflow (Cash Flow)`
   - `OEP_CAP.Net Book Value` ➔ `OEP_FS.Property Plant and Equipment (Balance Sheet)`
4. Click **[ Push Data ]** or associate the Smart Push with the form **Save** action for real-time synchronization.

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: How does the Capital module support ASC 842 and IFRS 16 Right-of-Use (ROU) lease accounting—
**Answer:** When **Lease Assets** is enabled in Capital features, the module provisions lease calculation logic:
1. It calculates the initial **Lease Liability** and **Right-of-Use (ROU) Asset** as the present value of future lease payments using the contract discount rate.
2. It generates monthly amortization schedules separating **Interest Expense** from **Principal Payment**.
3. It calculates straight-line ROU Asset amortization and synchronizes these entries directly into the Financials P&L and Balance Sheet cubes.

### Q2: What happens to depreciation expense when an asset is retired or transferred between departments mid-year—
**Answer:** When an asset transfer action is executed via the Capital action menu, the system sets the transfer date, clears future depreciation from the source entity, and initializes asset valuation and remaining useful life in the target entity. If retired, the system calculates the **Gain/Loss on Disposal** based on salvage value minus Net Book Value (NBV).

### Q3: Can an enterprise configure custom depreciation methods beyond Straight Line and Declining Balance—
**Answer:** Yes. Capital supports **Named Depreciation Methods** and custom monthly schedules. You can configure custom percentage tables (e.g. MACRS 5-year, 7-year accelerated schedules) where specific percentages are applied across each year of the asset's useful life.

---

## 🔗 Navigation

| Direction | Document |
|:---|:---|
| **← Previous** | [03_Workforce_Module.md](./03_Workforce_Module_Master_Guide.md) |
| **Next →** | [05_Projects_Module.md](./05_Projects_Module_Master_Guide.md) |
| **Modules Overview** | [01_Modules_Overview.md](./01_Modules_Architecture_Overview.md) |
| **Master Index** | [00_MASTER_INDEX.md](../../00_MASTER_INDEX.md) |

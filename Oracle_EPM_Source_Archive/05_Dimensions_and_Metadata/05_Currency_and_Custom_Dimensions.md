# 05 — Currency and Custom Dimensions: Multi-Cube Modeling

---

## 5.1 Overview: Dimensionality Across Multi-Cube Applications

In Enterprise Planning (EPBCS), an application frequently consists of multiple interconnected cubes:
* **`FinPlan`**: The primary financial general ledger cube (P&L, Balance Sheet, Cash Flow).
* **`EPBCS`**: The central ASO reporting repository.
* **`Manpower`**: The Workforce planning cube (Employee, Job, Salary details).
* **`Capital`**: The Fixed Assets planning cube (Asset Class, Depreciation schedules).

Because different business processes require different dimensional detail, Oracle EPM uses specialized dimensions and design patterns to ensure cross-cube data integrity.

---

## 5.2 Currency Dimension: The `USD_Reporting` Extraction

From your supplied production screen extraction:

```
Member: USD_Reporting
├── Code:                 USD_Reporting (Disabled)
├── Description:          Blank (Disabled)
├── Alias Table:          Default
├── Alias:                Blank
├── Data Storage:         Store (Disabled)
├── Two Pass Calculation: Unchecked (Disabled)
├── Data Type:            Unspecified (Disabled)
└── Additional Tab:       Create Currency (Visible)
```

```
┌─────────────────────────────────────────────────────────────┐
│                 CURRENCY CONVERSION FLOW                    │
├─────────────────────────────────────────────────────────────┤
│ 1. Local Currency Input (e.g. Entity London enters in GBP)  │
│    -> Stored at [Currency: Local]                           │
│                                                             │
│ 2. Administrator defines Exchange Rate Table (Hsp_Rates):   │
│    -> GBP to USD Monthly Average Rate = 1.28                │
│                                                             │
│ 3. Currency Conversion Rule Executes:                       │
│    -> [USD_Reporting] = [Local] * 1.28                      │
│                                                             │
│ 4. Global Consolidation:                                    │
│    -> All entities roll up cleanly into Global Parent       │
│       using the common USD_Reporting currency denomination. │
└─────────────────────────────────────────────────────────────┘
```

### Why Properties Are Disabled on `USD_Reporting`
* In your extract, almost all property fields on `USD_Reporting` are **grayed out / read-only**.
* **Reason**: `USD_Reporting` is a **system-generated reporting currency member**. It was created via the **Create Currency** wizard. Planning locks reporting currency properties to ensure that the relational translation engine (`Hsp_Rates`) and underlying Essbase conversion scripts maintain synchronized mathematical bindings.

---

## 5.3 Custom Dimensions: The "No Member" Architecture Pattern (`No Custom1`)

From your supplied production screen extraction:

```
Member: No Custom1
├── Data Storage:       Store (Enabled)
├── Data Type:          Unspecified (Enabled)
└── Plan Type Settings:
    ├── FinPlan:        Enabled (Yes), Operator = Addition
    ├── EPBCS:          Disabled (No), Operator = Addition (Disabled)
    ├── Manpower:       Enabled (Yes), Operator = Addition
    └── Capital:        Disabled (No), Operator = Addition (Disabled)
```

### Why Every Custom Dimension Needs a "No <Dimension>" Member
Consider an application where the `FinPlan` cube tracks revenue by `Project` (Custom1). However, administrative travel expenses or general corporate revenues do not belong to any specific project.
* In a multidimensional database, **a cell cannot exist without specifying a member for every single dimension**. You cannot leave a dimension blank.
* If there were no `No Project` member, planners would be forced to assign overhead costs to a real customer project, skewing operational metrics.
* `No Custom1` acts as the standard **neutral clearinghouse intersection** for non-project data.

### The Multi-Cube Enablement Matrix Explained
In your screen:
* **`FinPlan`**: **Enabled** (Tracks financial project granularity).
* **`EPBCS`**: **Disabled** (ASO reporting cube aggregates project details or omits the dimension).
* **`Manpower`**: **Enabled** (Assigns employees to project teams).
* **`Capital`**: **Disabled** (Assets are capitalized at the entity/cost center level, not per project).

> [!TIP]
> Disabling unneeded dimensions in specific cubes keeps Essbase block sizes lean and index files compact, preventing block explosion in sub-cubes.

---

## 5.4 Generic Cost Center Dimensions: The `D10010:Catering` Extraction

From your supplied production screen extraction:

```
Member: D10010 (Alias: D10010:Catering)
├── Data Storage:       Store (Enabled)
├── Data Type:          Unspecified (Enabled)
└── Plan Type Settings: Enabled across ALL 4 CUBES (FinPlan, EPBCS, Manpower, Capital)
                        Consolidation Operator = Addition across all cubes
```

### Analysis of the Universal Department Member
Unlike project-specific dimensions, the **Department / Cost Center** dimension represents organizational ownership:
1. `D10010` is an operational catering cost center.
2. It incurs salary costs in **`Manpower`**.
3. It owns kitchen equipment depreciated in **`Capital`**.
4. Its operating P&L aggregates into **`FinPlan`**.
5. Its final statutory reports roll up into **`EPBCS`**.
6. Because it exists in all four business domains, it is **Enabled in all 4 plan types**, with consolidation operator `Addition` (`+`) ensuring uniform rollups across cubes.

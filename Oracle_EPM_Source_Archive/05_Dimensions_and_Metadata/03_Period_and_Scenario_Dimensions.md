# 03 — Period and Scenario Dimensions: Time Bounding & Lifecycles

---

## 3.1 Overview: Controlling the Time Continuum

In Oracle EPM Planning, the **Period**, **Years**, and **Scenario** dimensions work together to create the time horizon of the enterprise.
* **Period Dimension**: Governs intra-year periodicity (Months, Quarters, Half-Years, Full Year).
* **Years Dimension**: Multi-year timeline (e.g., FY24 to FY40).
* **Scenario Dimension**: Business context (Actual, Budget, Forecast, Plan) and binds the active time horizon during which data entry and calculations are permitted.

---

## 3.2 Period Dimension Deep Dive: The `Q1` Extraction

From your supplied production screen extraction:

```
Member: Q1
├── Data Storage:         Dynamic Calc
├── Two Pass Calculation: Unchecked (Enabled)
├── Start Period:         Jan
├── End Period:           Mar
└── Plan Type Operators:  Addition across all 4 cubes
```

```
┌────────────────────────────────────────────────────────────────────────┐
│                   PERIOD RANGE BINDING: Q1 (JAN - MAR)                 │
├────────────────────────────────────────────────────────────────────────┤
│ • Start Period = Jan                                                   │
│ • End Period   = Mar                                                   │
│ • Essbase outlines evaluate Q1 exclusively across the months           │
│   spanning January through March.                                      │
│ • Forms with dynamic column expansion restrict Q1 rollups strictly     │
│   within this bounded calendar interval.                               │
│ • Prevents out-of-boundary member rollups when customized fiscal       │
│   calendars (4-4-5, 5-4-4, 13-period) are implemented.                 │
└────────────────────────────────────────────────────────────────────────┘
```

### Why Oracle Provides Start Period & End Period
In standard corporate calendars, Q1 maps to Jan–Mar. However, in retail, manufacturing, or healthcare:
* Fiscal year may begin in April (Q1 = Apr, May, Jun).
* Fiscal calendars may follow **4-4-5 weeks** (where Period 1, 2, and 3 have specific calendar day cutoffs).
* By binding `Start Period` and `End Period` in the metadata, Planning ensures that dynamic time series calculations (`@YTD`, `@QTD`, `@PRIOR`) and dynamic quarter aggregations calculate across the exact intended calendar window.

---

## 3.3 Scenario Dimension Deep Dive: The `Actual` Extraction

From your supplied production screen extraction:

```
Member: Actual
├── Start Yr:                     FY24
├── Start Period:                 Jan
├── End Yr:                       FY40
├── End Period:                   Jul
├── Include BegBal as Time Period: Checked
├── Enabled for Approvals:        Checked
├── Hierarchy Type:               Not Set
├── Data Storage:                 Never Share
└── Plan Type Settings:           FinPlan = Addition, EPBCS = Addition,
                                  Manpower = Ignore, Capital = Ignore
```

---

### 3.3.1 Active Range Bounding (`FY24 Jan` to `FY40 Jul`)

```
   [Past / Archived]   [ACTIVE RANGE: FY24 Jan to FY40 Jul]   [Future Closed]
   ◄─── Prior FY23 ────┼─────────────────────────────────────┼──── Post FY40 ──►
     Read-Only / Lock    Open for Data Load & Forms Entry       Data Block Rejection
```

1. **Security & Form Locking**:
   * Users cannot enter data into periods prior to `FY24 Jan` or after `FY40 Jul`.
   * Web forms dynamically gray out or hide columns outside this active window.
2. **Essbase Block Prevention**:
   * If a data load script attempts to load numbers into `FY22` for Scenario `Actual`, Planning rejects the records, preventing accidental block explosion.

---

### 3.3.2 Include BegBal as Time Period

* **`BegBal` (Beginning Balance)**: A specialized, non-calendar time period member created automatically by Planning.
* Positioned in the outline **before January** in the Period dimension.
* **Why it matters**:
  * Balance sheet accounts (Fixed Assets, Opening Inventory) and Workforce headcounts require an opening balance carried forward from previous years.
  * Storing opening balance in January would distort January cash flow activity.
  * When `Include BegBal as Time Period` is **Checked**, forms, Smart View, and business rules treat `BegBal` as an accessible time coordinate for that scenario.

---

### 3.3.3 Hierarchy Type: Not Set vs. Stored vs. Dynamic

* **`Not Set`**: Default standard behavior; adheres to the member's individual `Data Storage` property (`Never Share`).
* **`Stored`**: Enforces strict physical block rollup in hybrid/ASO environments.
* **`Dynamic`**: Forces the entire scenario rollup to evaluate dynamically in RAM.

---

### 3.3.4 Plan Type Operators: Why Manpower and Capital are Set to `Ignore` (`~`)

In your screen extract:
* `FinPlan`: **Addition** (`+`)
* `EPBCS`: **Addition** (`+`)
* `Manpower`: **Ignore** (`~`)
* `Capital`: **Ignore** (`~`)

#### The Multi-Cube Architectural Reason:
* In `FinPlan` and `EPBCS` (Financial reporting cubes), `Actual` is a core comparative scenario that rolls up into variance calculations (`Actual vs Budget`).
* In `Manpower` (Workforce) and `Capital` (Fixed Assets), planning is forward-looking. Actual historical payrolls and existing capital assets are typically held as reference drivers or baselines, but do not aggregate directly into active planning parents. Setting the operator to **`Ignore` (`~`)** ensures that baseline actuals in the sub-cubes do not inflate operational budget rollups.

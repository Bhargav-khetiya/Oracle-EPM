# Period, Scenario, Version, and Year Dimensions

> **Prerequisites:** [Account Dimension](03_Account_Dimension.md)  
> **Sources merged:** ChatGPT 03/04, Claude 05.30 §4-7, Gemini 03/04  
> **Evidence Labels:** `[Oracle Documented]` · `[Illustrative]` · `[Recommendation]`

---

## Period Dimension

### Purpose

The Period dimension governs **intra-year time granularity** — months, quarters, half-years, and full year. Combined with the Year dimension, it defines the complete time horizon.

### Standard Hierarchy

```
YearTotal (Root — Dynamic Calc)
  ├── Q1 (Dynamic Calc)
  │   ├── Jan (Store, Level 0)
  │   ├── Feb (Store, Level 0)
  │   └── Mar (Store, Level 0)
  ├── Q2 (Dynamic Calc)
  │   ├── Apr ─ May ─ Jun
  ├── Q3 (Dynamic Calc)
  │   ├── Jul ─ Aug ─ Sep
  └── Q4 (Dynamic Calc)
      ├── Oct ─ Nov ─ Dec
```

For **Indian Fiscal Year** (April–March):
```
FY Total
  ├── Q1: Apr, May, Jun
  ├── Q2: Jul, Aug, Sep
  ├── Q3: Oct, Nov, Dec
  └── Q4: Jan, Feb, Mar
```

### Start Period and End Period Properties

Each quarter member carries **Start Period** and **End Period** properties (e.g., Q1: Start = Jan, End = Mar). This matters because:

- Fiscal calendars vary: retail may use 4-4-5 weeks, manufacturing may start in April
- These bindings ensure dynamic time series functions (`@YTD`, `@QTD`, `@PRIOR`) calculate across the exact intended calendar window
- Forms with dynamic column expansion restrict rollups within the bounded interval

`[Oracle Documented]`

### BegBalance (Beginning Balance)

`BegBalance` is a specialized non-calendar period member positioned **before January** in the outline:

- Balance sheet accounts need opening balances carried from prior years
- Storing opening balance in January would distort January cash flow activity
- When a Scenario has "Include BegBal as Time Period" checked, forms and business rules can access BegBalance as a time coordinate

`[Oracle Documented]`

---

## Year Dimension

### Purpose

The Year dimension holds fiscal years as separate members. Each year is a simple member — no special properties beyond the standard.

```
Year Dimension:
  ├── FY24 (Historical — loaded from ERP)
  ├── FY25 (Historical)
  ├── FY26 (Current Budget Year — open for input)
  ├── FY27 (Forecast)
  ├── FY28 (Long-Range Plan)
  └── FY29 (Long-Range Plan)
```

### Adding and Removing Years

```
Adding a new year:
  Application → Dimensions → Year → Add Member "FY30"
  → Requires Refresh Database (Sparse restructure — fast)

Removing a historical year:
  ⚠️ Data for that year is PERMANENTLY DELETED
  → Must carefully archive data before removal
```

`[Oracle Documented]`

---

## Scenario Dimension

### Purpose

The Scenario dimension separates **different versions of reality** — what actually happened vs what was planned:

```
Scenario Dimension:
  ├── Actual     ← Loaded from ERP (what happened)
  ├── Budget     ← Annual budget (what we planned)
  ├── Forecast   ← Updated expectations (re-forecast)
  └── Plan       ← Long-range strategic plan (3–5 years)
```

### Key Scenario Properties

| Property | Description | Example |
|----------|-------------|---------|
| **Start Year / End Year** | Active date range for data entry | FY24 → FY40 |
| **Start Period / End Period** | First/last period open for data | Jan → Jul |
| **Exchange Rate Table** | Which FX rate table to use | Hsp_Rates |
| **Enabled for Process Management** | Whether approval workflow applies | Yes for Budget |
| **Include BegBal** | Whether BegBalance is accessible | Checked for Actual |

### Active Range Bounding

```
[Past / Archived]   [ACTIVE RANGE: FY24 Jan to FY40 Jul]   [Future Closed]
◄── Prior FY23 ────┼─────────────────────────────────────┼──── Post FY40 ──►
  Read-Only / Lock    Open for Data Load & Forms Entry       Block Rejection
```

- Users **cannot** enter data into periods outside the active range
- Web forms dynamically gray out or hide columns outside this window
- Data loads targeting periods outside the range are **rejected**, preventing accidental block explosion

`[Oracle Documented]`

### Scenario Plan Type Operators

A scenario can have different consolidation operators per cube:

```
Scenario: Actual
  FinPlan:  Addition (+)    ← Core financial comparison
  EPBCS:    Addition (+)    ← Statutory reporting
  Manpower: Ignore (~)      ← Baseline reference, not aggregated
  Capital:  Ignore (~)      ← Reference only
```

**Why?** In financial cubes, Actual is a core comparative scenario for variance calculations. In Workforce and Capital cubes, historical actuals serve as reference drivers but shouldn't inflate active planning rollups.

`[Recommendation]`

---

## Version Dimension

### Purpose

The Version dimension represents **iterative stages** of a plan within a scenario. While Scenario answers *"What business case?"* (Budget, Forecast), Version answers *"Which revision?"* (Working, Draft, Final).

### Version Types

This is one of the most critical structural decisions in Planning:

```
┌──────────────────────────────────────┬──────────────────────────────────────┐
│      STANDARD BOTTOM UP              │         STANDARD TARGET              │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ Planners enter data at LEVEL 0       │ Executives enter targets at          │
│ (cost centers, products, details)    │ PARENT levels (e.g., Total US)       │
│                                      │                                      │
│ Data aggregates UPWARD into          │ Data is spread DOWNWARD to           │
│ parent nodes                         │ children via allocation rules        │
│                                      │                                      │
│ Level 0 = Read/Write                 │ Parent = Read/Write                  │
│ Parents = Read-Only (calculated)     │ Level 0 = reflects allocated target  │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

### Worked Examples

**Bottom-Up (Working):**
```
Total Engineering
  ├── Dept 101 (Software): User enters $150,000 ← Editable
  └── Dept 102 (QA):       User enters $50,000  ← Editable
  
Total Engineering = $200,000 (Read-Only, auto-aggregated)
VP cannot change Total directly — it's derived.
```

**Top-Down (Target):**
```
CFO enters Total Engineering = $300,000 ← Editable
  ├── Dept 101: $225,000 (allocated 75% based on prior year)
  └── Dept 102: $75,000  (allocated 25% based on prior year)
```

`[Oracle Documented]`

### Enabled for Approvals

When checked, the version becomes eligible for **Planning Unit Hierarchy (PUH)** workflow:

```
[Planner] ──Promote──► [Reviewer] ──Approve──► [Signed Off]
    ▲                       │
    └───────Reject──────────┘
```

- When promoted, write permissions transfer to the reviewer
- The planner's grid becomes read-only
- Best Practice: Enable approvals for Working; disable for archived Final versions

`[Oracle Documented]`

### Sandboxes

Sandboxes provide **private "What-If" workspaces** without requiring new Version members:

```
Base Data (permanent in .PAG):
  [Entity: US_East, Version: Working] = $100K

Planner 1 Sandbox (virtual overlay):
  [Sandbox: Best_Case] = $130K  (Only visible to Planner 1)

Planner 2 Sandbox (virtual overlay):
  [Sandbox: Worst_Case] = $80K  (Only visible to Planner 2)

When approved → "Publish Sandbox" → overwrites base data with $130K
```

- Changes are held in a private memory layer — they do not corrupt shared production data
- No admin intervention needed to create or destroy sandboxes

`[Oracle Documented]`

### Version Lifecycle Matrix

| Version | Type | Data Storage | Approvals? | Sandboxes? | Use Case |
|:---|:---|:---|:---:|:---:|:---|
| **Working** | Bottom Up | Never Share | ✅ Yes | Optional | Daily collaborative budget entry |
| **Target** | Standard Target | Never Share | No | No | Executive top-down corporate targets |
| **Final** | Bottom Up | Never Share | No | No | Locked, approved board-level budget |
| **What_If** | Bottom Up | Never Share | No | ✅ Yes | Ad-hoc modeling and simulation |

`[Illustrative]`

---

## Currency Dimension

### Purpose

Exists **only** in multi-currency applications. Enables data entry in local currency and reporting in group currency.

```
Currency Dimension:
  ├── Local        ← Data entered in entity's base currency
  ├── INR          ← Reporting in Indian Rupees
  ├── USD          ← Reporting in US Dollars
  └── GBP          ← Reporting in British Pounds
```

### Currency Translation Flow

```
1. Local Currency Input (Hotel UK enters in GBP):
   Revenue [Hotel UK, Jan, Budget, Local] = £350,000

2. Exchange Rate Table (Hsp_Rates):
   GBP → USD Average Rate for Jan = 1.28

3. Currency Conversion Rule executes:
   Revenue [Hotel UK, Jan, Budget, USD] = £350,000 × 1.28 = $448,000

4. Global Consolidation:
   All entities roll up in USD_Reporting currency
```

The **Exchange Rate Type** on each Account determines which rate applies:
- Revenue → Average Rate (earned evenly throughout period)
- Cash → Ending Rate (point-in-time balance)
- Equity → Historical Rate (original investment rate)

### System-Generated Currency Members

Reporting currency members (like `USD_Reporting`) are created via the **Create Currency** wizard. Their properties are **locked/grayed out** because Planning must maintain synchronized bindings between the relational translation engine and Essbase conversion scripts.

`[Oracle Documented]`

---

## Custom Dimensions

### Design Best Practices

```
✅ DO:
  - Keep custom dimensions small (< 50 members if possible)
  - Make them Sparse (unless very small and fully populated)
  - Use meaningful names with prefixes: D10010 Catering
  - Design complete hierarchies before building
  - Consider: "Can I pivot on this dimension?"

❌ DON'T:
  - Create custom dimensions for attributes (use UDA or Attribute Dimensions)
  - Create too many custom dimensions (each adds sparse complexity)
  - Make custom dimensions Dense (inflates block size)
  - Use custom dimensions for one-time categorization (use UDA)
```

### "No" Members

Every custom dimension has a system-generated **"No"** member:

```
Department Dimension:
  Department (Root)
    ├── No Department    ← System member, always exists
    ├── D10010: Catering
    ├── D10020: Front Office
    └── D10030: Finance
```

Since every cell requires a member from every dimension, `No Department` serves as the neutral intersection for data that isn't department-specific (e.g., company-wide revenue).

### Multi-Cube Enablement

A custom dimension member can be enabled in some cubes and disabled in others:

```
Member: D10010 (Catering)
  FinPlan:  ✅ Enabled (financial reporting)
  EPBCS:    ✅ Enabled (statutory reporting)
  Manpower: ✅ Enabled (salary costs)
  Capital:  ✅ Enabled (kitchen equipment)

Member: No Custom1 (No Project)
  FinPlan:  ✅ Enabled (project-level tracking)
  EPBCS:    ❌ Disabled (ASO aggregates differently)
  Manpower: ✅ Enabled (employee-project assignment)
  Capital:  ❌ Disabled (assets at entity level, not project)
```

`[Oracle Documented]`

---

## Quick Recall

1. **What's the difference between Scenario and Version?**
   → Scenario = business context (Actual, Budget, Forecast). Version = revision stage within that context (Working, Final, Target).

2. **Why does BegBalance exist as a separate period?**
   → To hold opening balances (prior year carryforward) without distorting the first month's activity data.

3. **When would you use a Target version vs a Bottom-Up version?**
   → Target for executive top-down budget envelopes that allocate downward. Bottom-Up for planner-driven detailed budgeting that aggregates upward.

4. **Teach-back prompt:** Explain to a colleague how Sandboxes let multiple planners model what-if scenarios without interfering with each other's data.

---

**Next:** [Advanced Topics](05_Advanced_Topics.md) — HSP tables, solve order, implied sharing, and shared members


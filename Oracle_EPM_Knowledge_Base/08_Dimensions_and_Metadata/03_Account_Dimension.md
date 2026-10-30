# Account Dimension Deep Dive

> **Prerequisites:** [Universal Member Properties](02_Universal_Member_Properties.md), [Financial Concepts](../02_Finance_Concepts/01_Financial_Concepts.md)  
> **Sources merged:** ChatGPT 02, Claude 05.08/05.21/05.30 §2/§13/§14, Gemini 02  
> **Evidence Labels:** `[Oracle Documented]` · `[Illustrative]` · `[Recommendation]`

---

## Purpose

The **Account** dimension is the mathematical backbone of any Planning application. Unlike generic dimensions, it incorporates native accounting intelligence:

1. **Normal debit/credit signs** (Assets vs Liabilities, Revenue vs Expense)
2. **Time-series aggregation behaviors** (Flow vs Balance accounts)
3. **Variance calculation intelligence** (Favorable vs Unfavorable)
4. **Currency translation rules** (Historical, Average, or Ending FX rates)

`[Oracle Documented]`

---

## Standard Account Hierarchy Pattern

```
Account (Dimension Root)
  ├── Income Statement
  │   ├── Revenue
  │   │   ├── Operating Revenue
  │   │   │   ├── 100110: Rooms Revenue (Store, +)
  │   │   │   ├── 100120: Banquet Revenue (Store, +)
  │   │   │   └── 100130: F&B Revenue (Store, +)
  │   │   └── Non-Operating Revenue
  │   │       └── 110000: Interest Income (Store, +)
  │   │
  │   ├── COGS (Cost of Goods Sold)
  │   │   ├── 200000: Raw Materials (Store, +)
  │   │   └── 200010: Direct Labor (Store, +)
  │   │
  │   ├── Gross Margin (Dynamic Calc, formula: Revenue - COGS)
  │   │
  │   ├── Operating Expense
  │   │   ├── 300000: Salaries (Store, +)
  │   │   ├── 300010: Benefits (Store, +)
  │   │   ├── 300020: Rent (Store, +)
  │   │   └── 300030: Travel (Store, +)
  │   │
  │   └── Net Income (Dynamic Calc, formula: Gross Margin - OpEx)
  │
  ├── Balance Sheet
  │   ├── Assets
  │   │   ├── Current Assets
  │   │   │   ├── 400000: Cash (Store, Time Balance: Balance)
  │   │   │   └── 400010: Accounts Receivable (Store, Time Balance: Balance)
  │   │   └── Fixed Assets
  │   │       └── 410000: Property (Store, Time Balance: Balance)
  │   └── Liabilities & Equity
  │       ├── 500000: Accounts Payable (Store, Time Balance: Balance)
  │       └── 600000: Retained Earnings (Store, Time Balance: Balance)
  │
  └── Statistical / Driver Accounts
      ├── Rooms Available (Store, ~, Saved Assumption)
      ├── Occupancy Rate (Dynamic Calc, ~, formula: Sold / Available)
      └── RevPAR (Dynamic Calc, ~, formula: Revenue / Available)
```

`[Illustrative]` — Actual hierarchies vary by organization

---

## The 6 Account Types

Every Account member must be assigned one of these types. The choice controls sign behavior, variance direction, and time aggregation defaults.

| Account Type | Normal Sign | Financial Statement | Default Time Balance | Typical Members |
|:---|:---:|:---|:---:|:---|
| **Revenue** | Credit | Income Statement | Flow | Sales, service revenue, interest income |
| **Expense** | Debit | Income Statement | Flow | Salaries, rent, utilities, travel |
| **Asset** | Debit | Balance Sheet | Balance | Cash, AR, inventory, property |
| **Liability** | Credit | Balance Sheet | Balance | AP, loans, bonds |
| **Equity** | Credit | Balance Sheet | Balance | Retained earnings, common stock |
| **Saved Assumption** | Neutral | Non-financial | Flow | Tax rates, headcount, occupancy %, price/unit |

### Saved Assumption Details

Saved Assumptions are for **driver accounts** — non-financial values that power calculations but don't appear directly on financial statements:
- Consolidation operator is typically set to `~` (Ignore) so drivers don't add into currency rollups
- Time Balance is Flow by default but can be overridden
- Variance Reporting is Non-Expense (more is usually neutral/good)

`[Oracle Documented]`

---

## Variance Reporting: Expense vs Non-Expense

This property ensures that **good performance shows as positive variance** and **poor performance shows as negative variance** on reports.

| Setting | Formula Applied |
|---------|----------------|
| **Non-Expense** (Revenue, Asset, Equity) | Variance = Actual − Budget |
| **Expense** (Expense, Liability) | Variance = Budget − Actual |

### Numerical Proof

| Scenario | Account Type | Setting | Budget | Actual | Formula | Variance | Status |
|:---|:---|:---|:---:|:---:|:---|:---:|:---:|
| Sales growth | Revenue | Non-Expense | \$100K | \$120K | 120K − 100K | **+\$20K** | ✅ Favorable |
| Sales drop | Revenue | Non-Expense | \$100K | \$80K | 80K − 100K | **−\$20K** | ❌ Unfavorable |
| Cost overrun | Expense | Expense | \$50K | \$65K | 50K − 65K | **−\$15K** | ❌ Unfavorable |
| Cost savings | Expense | Expense | \$50K | \$40K | 50K − 40K | **+\$10K** | ✅ Favorable |

> [!CAUTION]
> If you accidentally set an Expense account to Non-Expense, a \$15K overspend calculates as 65K − 50K = +\$15K — showing as **favorable** on board reports. This is a catastrophic reporting defect that may go unnoticed for weeks.

`[Oracle Documented]`

---

## Time Balance Properties

The **Time Balance** property defines how account values aggregate across the Period dimension (months → quarters → years):

```
Period:        Jan     Feb     Mar      Q1 Rollup
────────────────────────────────────────────────────
FLOW (Revenue): 100  +  150  +  200  =   450  (Sum of months)
BALANCE (Cash):  50      75      90  →    90  (Ending month)
FIRST (Opening): 30      40      45  →    30  (First month)
AVERAGE (Count): 500    510     520  →   510  (Mean of months)
```

### Complete Time Balance Reference

| Setting | Q1 Calculation | Use For |
|:---|:---|:---|
| **Flow** | Jan + Feb + Mar | P&L accounts: Revenue, COGS, expenses (activity during period) |
| **Balance** | = Mar (last period) | Balance Sheet: Cash, AR, Fixed Assets (point-in-time snapshot) |
| **First** | = Jan (first period) | Opening balances: Beginning Inventory, Opening Headcount |
| **Average** | (Jan + Feb + Mar) ÷ 3 | KPI averages: Average Daily Headcount |
| **Fill** | Propagates entered value to empty future months | Fixed assumptions: Monthly rent entered once and filled forward |
| **Weighted Avg (Actual_Actual)** | Weighted by calendar days per month (31, 28, 31) | Treasury yields, bond interest |
| **Weighted Avg (Actual_365)** | Weighted by 365-day annual basis | Commercial paper interest |

`[Oracle Documented]`

### The Skip Setting

When calculating Balance or Average across periods, some months may contain `#MISSING` or zero:

| Skip Setting | Behavior |
|:---|:---|
| **None** | Strict — if March is `#MISSING`, Q1 = `#MISSING` |
| **Missing** | Skips `#MISSING` months — takes last real value |
| **Zeros** | Skips zero months |
| **Missing and Zeros** | Skips both to find the last real operational value |

> [!NOTE]
> Skip is only meaningful when Time Balance is Balance, First, or Average. For Flow accounts (where values are simply summed), Skip is locked to None and appears disabled in the UI.

---

## Exchange Rate Types

| Type | Description | Use For |
|:---|:---|:---|
| **No Rate** | Exempt from currency translation | Ratios, percentages, statistical counts |
| **Average** | Multiplies by periodic average exchange rate | Income Statement accounts (revenue earned evenly) |
| **Ending** | Multiplies by period-end spot rate | Balance Sheet accounts (point-in-time balance) |
| **Historical** | Uses original investment exchange rate | Equity items (original investment value) |

The exchange rate tables are stored in Planning's `Hsp_Rates` system, and the currency conversion business rule applies these rates to translate local currency values into reporting currency.

`[Oracle Documented]`

---

## Account Properties Summary

Every Account member carries these properties:

| Property | Values | What It Controls |
|----------|--------|-----------------|
| **Account Type** | Revenue, Expense, Asset, Liability, Equity, Saved Assumption | Financial sign and variance direction |
| **Variance Reporting** | Expense, Non-Expense | Favorable/unfavorable interpretation |
| **Time Balance** | Flow, First, Balance, Average, Fill, Weighted Average | Period-to-quarter aggregation method |
| **Skip Value** | None, Missing, Zeros, Missing and Zeros | Skip behavior during time aggregation |
| **Exchange Rate Type** | None, Average, Ending, Historical | Currency translation rate selection |
| **Data Storage** | Store, Dynamic Calc, etc. | Storage behavior (see [Universal Properties](02_Universal_Member_Properties.md)) |
| **Source Plan Type** | Plan1, Plan2, etc. | Which cube is the "source of truth" for this account |
| **Smart List** | (linked Smart List name) | Associates a dropdown list for data entry |
| **Data Type** | Currency, Non-Currency, Percentage, Date, Text, Smart List | Formatting and conversion behavior |
| **UDA** | Free text tags | User-defined attribute tags (e.g., HSP_NOLINK) |
| **Member Formula** | Essbase formula | Calculation expression for Dynamic Calc members |

---

## Quick Recall

1. **Why does Cash use Time Balance: Balance instead of Flow?**
   → Cash is a point-in-time snapshot. The Q1 cash balance IS the March balance, not the sum of three monthly balances.

2. **When should you set Variance Reporting to "Expense"?**
   → For any account where spending MORE than budget is unfavorable (Expense and Liability accounts). This reverses the variance formula to Budget − Actual.

3. **What is a Saved Assumption and why use Ignore (~)?**
   → A non-financial driver account (headcount, tax rate, price). Using ~ prevents driver values from adding into financial currency rollups.

4. **Teach-back prompt:** Explain to a colleague why setting the wrong Account Type can cause incorrect financial reports.

---

**Next:** [Period, Scenario, and Version Dimensions](04_Period_Scenario_Version.md) — time bounding, active ranges, and workflow stages


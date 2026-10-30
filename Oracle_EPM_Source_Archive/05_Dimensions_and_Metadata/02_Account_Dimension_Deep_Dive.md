# 02 — Account Dimension Deep Dive: Financial Logic & Storage

---

## 2.1 The Account Dimension in Oracle EPM

The **Account** dimension is the mathematical backbone of any Planning application. Unlike generic dimensions (Entity, Product, Department), the Account dimension incorporates native accounting intelligence:
1. **Normal Debit/Credit signs** (Assets vs Liabilities, Revenues vs Expenses).
2. **Time-series aggregation behaviors** (Flowing vs Ending Balances).
3. **Variance calculation intelligence** (Favorable vs Unfavorable variances).
4. **Currency translation rules** (Historical, Average, or Ending FX rates).

---

## 2.2 Deep Dive: The `Net Profit` UI Extraction

From your supplied production screen extraction:

```
Member: Net Profit
├── Account Type:        Revenue
├── Variance Reporting:  Non-Expense
├── Time Balance:        Flow
├── Skip:                None (disabled)
├── Exchange Rate Type:  Average
├── Source Cube:         FinPlan
├── Data Storage:        Dynamic Calc
├── Two Pass Calc:       Unchecked
├── Data Type:           Currency
├── UDAs:                HSP_NOLINK, Hsp_Currency
└── Solve Order:         Configured in Member Formula tab
```

---

## 2.3 The 6 Account Types: Mechanics & Accounting Signs

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            ACCOUNT TYPES TAXONOMY                           │
├────────────────────┬───────────────┬─────────────────┬──────────────────────┤
│ Account Type       │ Normal Sign   │ Parent Rollup   │ Financial Statement  │
├────────────────────┼───────────────┼─────────────────┼──────────────────────┤
│ Revenue            │ Credit        │ + (Positive)    │ Income Statement     │
│ Expense            │ Debit         │ + (Positive)    │ Income Statement     │
│ Asset              │ Debit         │ + (Positive)    │ Balance Sheet        │
│ Liability          │ Credit        │ + (Positive)    │ Balance Sheet        │
│ Equity             │ Credit        │ + (Positive)    │ Balance Sheet        │
│ Saved Assumption   │ Neutral       │ ~ (Ignore)      │ Driver / KPI Memo    │
└────────────────────┴───────────────┴─────────────────┴──────────────────────┘
```

### Detailed Behavioral Rules
1. **`Revenue`**:
   * Stored as positive numbers for positive sales.
   * Contributes positively to Operating Income and Gross Margin.
2. **`Expense`**:
   * Entered and displayed as positive numbers by planners (e.g., Rent = \$5,000).
   * Contributes positively to Total Operating Expenses.
   * When subtracted from Revenue in a dynamic Net Income formula (`[Revenue] - [Expense]`), the formula subtracts the positive expense amount.
3. **`Asset`**:
   * Represents economic resources owned.
   * Rolls up into Total Current Assets and Total Non-Current Assets.
4. **`Liability`**:
   * Represents debts and financial obligations.
   * Rolls up into Total Liabilities.
5. **`Equity`**:
   * Represents retained earnings, common stock, and reserves.
   * Satisfies the accounting equation: $\text{Assets} = \text{Liabilities} + \text{Equity}$.
6. **`Saved Assumption`**:
   * Non-financial drivers: Tax Rates (21%), Inflation (3.5%), Headcount (45), Price per Unit (\$12.50).
   * Usually set to Consolidation Operator `~` (Ignore) so drivers don't add into financial currency rollups.

---

## 2.4 Variance Reporting: Expense vs. Non-Expense

Standard financial reporting requires that **good performance results in positive variances**, while **poor performance results in negative variances**:

$$\text{Variance for Non-Expense (Revenue)} = \text{Actual} - \text{Budget}$$
$$\text{Variance for Expense} = \text{Budget} - \text{Actual}$$

### Comparison Table with Numerical Proof

| Scenario | Account Type | Setting | Budget | Actual | Formula Applied | Variance | Display Status |
| :--- | :--- | :--- | :---: | :---: | :--- | :---: | :---: |
| **Sales Growth** | Revenue | `Non-Expense` | \$100,000 | \$120,000 | $120\text{k} - 100\text{k}$ | **+\$20,000** | ✅ Favorable (Green) |
| **Sales Drop** | Revenue | `Non-Expense` | \$100,000 | \$80,000 | $80\text{k} - 100\text{k}$ | **-\$20,000** | ❌ Unfavorable (Red) |
| **Cost Overrun** | Expense | `Expense` | \$50,000 | \$65,000 | $50\text{k} - 65\text{k}$ | **-\$15,000** | ❌ Unfavorable (Red) |
| **Cost Savings** | Expense | `Expense` | \$50,000 | \$40,000 | $50\text{k} - 40\text{k}$ | **+\$10,000** | ✅ Favorable (Green) |

> [!IMPORTANT]
> If you accidentally set an Expense account to `Non-Expense`, an overspend of \$15,000 will calculate as $65\text{k} - 50\text{k} = +\$15,000$, showing up on board reports as a **positive favorable variance**, which is a catastrophic reporting defect.

---

## 2.5 Time Balance & Skip Options

The **Time Balance** property defines how account values aggregate across the **Time / Period** dimension (from months into quarters and years):

```
       TIME BALANCE: FLOW vs. BALANCE vs. FIRST
       
       Period:        Jan     Feb     Mar      Q1 Rollup
       ──────────────────────────────────────────────────
       FLOW (Rev):    100  +  150  +  200  =   450  (Sum of months)
       BALANCE (Cash): 50      75      90  =    90  (Ending month)
       FIRST (Inv):    30      40      45  =    30  (Opening month)
```

### Complete Time Balance Options Reference

| Time Balance Setting | Mathematical Evaluation for Q1 | Financial Statement Fit |
| :--- | :--- | :--- |
| **`Flow`** | $\text{Q1} = \text{Jan} + \text{Feb} + \text{Mar}$ | **P&L Accounts**: Revenue, COGS, Travel, Utilities. (Activity during the period). |
| **`Balance`** | $\text{Q1} = \text{Mar}$ (Ending period) | **Balance Sheet**: Cash, Accounts Receivable, Fixed Assets, Accounts Payable. |
| **`First`** | $\text{Q1} = \text{Jan}$ (Beginning period) | **Beginning Balances**: Opening Inventory, Beginning Headcount. |
| **`Average`** | $\text{Q1} = (\text{Jan} + \text{Feb} + \text{Mar}) / 3$ | **KPI Averages**: Average Daily Headcount, Average Inventory Level. |
| **`Fill`** | Propagates the entered value to all empty future months | **Fixed Assumptions**: Monthly Rent budget entered once in Jan and filled forward. |
| **`Weighted Average - Actual_Actual`** | Weighted by exact calendar days in each month | **Treasury Yields**: Bond yields weighted by 31, 28, 31 calendar days. |
| **`Weighted Average - Actual_365`** | Weighted by standard 365-day annual basis | **Daily Interest**: Commercial paper interest accruals. |
| **`Custom`** | Defined by procedural calculation script | Specialized statutory actuarial calculations. |
| **`Disable`** | Turns off time balance aggregation | Raw staging accounts. |

---

### The "Skip" Setting & Why It Was Disabled in `Net Profit`

When calculating ending balances or averages, some months might contain `#MISSING` or `0`:

| Skip Setting | Behavior When Month is Empty / Zero |
| :--- | :--- |
| **`None`** | Evaluates strictly. If March is `#MISSING`, Q1 evaluates to `#MISSING`. |
| **`Missing`** | Skips `#MISSING`. If March is missing, takes **February's** ending balance. |
| **`Zeros`** | Skips zeros. If March is `0`, takes **February's** balance. |
| **`Missing And Zeros`**| Skips both `#MISSING` and `0` to locate the last real operational value. |

#### Why Disabled on `Net Profit`:
* `Skip` is mathematically relevant **only when Time Balance is set to Balance, First, or Average**.
* Because `Net Profit` has `Time Balance = Flow`, monthly values are simply summed ($100 + 150 + \text{\#MISSING} = 250$). Skip is inapplicable and locked to `None`.

---

## 2.6 Exchange Rate Types & Currency Conversion

* **`No Rate`**: Exempt from currency translation (ratios, percentages, statistical counts).
* **`Average`**: Multiplies or divides by the periodic Average Exchange Rate table (`Hsp_Rates`). Standard for all **Income Statement** accounts.
* **`Ending`**: Multiplies or divides by the period-end spot rate. Standard for all **Balance Sheet** accounts.
* **Source Cube**: Designates which cube (`FinPlan`, `EPBCS`, `Manpower`, `Capital`) acts as the authoritative metadata master for this account in multi-cube deployments.

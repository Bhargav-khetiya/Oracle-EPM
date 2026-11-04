# 10 — Advanced Solve Order & Formula Collision Mathematics

---

## 10.1 The Cell Collision Problem Explained

In a multidimensional database containing multiple dynamic calculation dimensions, a critical mathematical conflict arises whenever an intersection contains **two or more members with competing formulas**:

```
                              THE CELL COLLISION
                                      │
              Account Dimension:                Period / Scenario Dimension:
           [ Gross Margin % ]                             [ Variance % ]
       Formula: (Gross Margin / Sales)              Formula: (Actual - Budget) / Budget
                                      │
                                      ▼
                        INTERSECTION CELL (X)
                 Which formula executes first in RAM—
```

Without an explicit **Solve Order**, the Essbase kernel resolves collisions arbitrarily based on dimension outline order, frequently producing **mathematically invalid financial metrics** on executive reports.

---

## 10.2 Mathematical Proof: The Variance vs. Ratio Divergence

Consider a real corporate reporting example with the following baseline numbers:

```
Baseline Figures:
  • Actual Sales  = $1,000,000  | Actual Gross Margin  = $400,000  -> Actual GM % = 40.0%
  • Budget Sales  = $800,000    | Budget Gross Margin  = $200,000  -> Budget GM % = 25.0%
```

Now we query the cell: `[Account: Gross Margin %, Scenario: Variance %]`.

### Case A: Account Evaluates First $\rightarrow$ Variance % Evaluates Last (CORRECT)
* Solve Order: `Account = 10`, `Scenario / Variance % = 20`.
1. **Step 1 (Account Evaluates)**:
   * $\text{Actual GM \%} = 400\text{k} / 1000\text{k} = \mathbf{40.0\%}$
   * $\text{Budget GM \%} = 200\text{k} / 800\text{k} = \mathbf{25.0\%}$
2. **Step 2 (Variance % Evaluates Last)**:
   * Takes the two pre-calculated margins:
   $$\text{Variance \%} = \frac{40.0\% - 25.0\%}{25.0\%} = \frac{15.0\%}{25.0\%} = \mathbf{+60.0\% \text{ Variance! (MATHEMATICALLY ACCURATE)}}$$

---

### Case B: Variance % Evaluates First $\rightarrow$ Account Evaluates Last (DISASTROUS ERROR)
* Solve Order: `Account = 20`, `Scenario / Variance % = 10`.
1. **Step 1 (Variance % Evaluates Base Lines)**:
   * $\text{Variance Sales} = 1000\text{k} - 800\text{k} = \mathbf{\$200,000}$
   * $\text{Variance Gross Margin} = 400\text{k} - 200\text{k} = \mathbf{\$200,000}$
2. **Step 2 (Account Gross Margin % Formula Divides the Variances)**:
   * Evaluates: $\text{Variance GM} / \text{Variance Sales}$:
   $$\text{Result} = \frac{\$200,000}{\$200,000} = \mathbf{100.0\% \text{ (ABSURD NONSENSE!) } ❌}$$

> [!CRITICAL]
> An error in Solve Order turned a **+60.0% variance** into an absurd **100.0%**, which would completely mislead financial leadership.

---

## 10.3 The Universal Enterprise Solve Order Hierarchy

To guarantee mathematical integrity across BSO, Hybrid BSO, and ASO cubes, follow this standard hierarchy:

```
┌─────────────────────────────────────────────────────────────┐
│             UNIVERSAL ENTERPRISE SOLVE ORDER HIERARCHY       │
├────────────────────┬─────────────┬──────────────────────────┤
│ Dimensional Tier   │ Solve Order │ Typical Members          │
├────────────────────┼─────────────┼──────────────────────────┤
│ Tier 1: Base Data  │      0      │ Stored leaf members,     │
│                    │             │ simple aggregations (+/-)│
├────────────────────┼─────────────┼──────────────────────────┤
│ Tier 2: Time Series│     10      │ Q1, Q2, YTD, MTD, Rolling│
├────────────────────┼─────────────┼──────────────────────────┤
│ Tier 3: P&L Sums   │     20      │ Gross Margin, EBITDA,    │
│                    │             │ Operating Income         │
├────────────────────┼─────────────┼──────────────────────────┤
│ Tier 4: Ratios     │     30      │ Gross Margin %, Markup %,│
│                    │             │ Tax Rate %, Headcount Avg│
├────────────────────┼─────────────┼──────────────────────────┤
│ Tier 5: Reporting  │     40      │ Constant Currency,       │
│         Views      │             │ Local to USD translation │
├────────────────────┼─────────────┼──────────────────────────┤
│ Tier 6: Variances  │     50      │ Actual vs Budget,        │
│                    │             │ Variance, Variance %     │
└────────────────────┴─────────────┴──────────────────────────┘
```

---

## 10.4 Configuring Solve Order in Oracle Planning

1. In the Web Studio, open **Dimensions $\rightarrow$ Account** (or target dimension).
2. Edit the dynamic member (e.g., `Net Profit Margin %`).
3. Click the **Member Formula** tab.
4. Enter the calculation formula in the editor.
5. In the **Solve Order** numeric field, enter the appropriate precedence integer (e.g., `30`).
6. Click **Save** and perform an **Application Database Refresh**.

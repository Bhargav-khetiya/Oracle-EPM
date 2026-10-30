# Finance Concepts for EPM — Financial Statements and Planning

> **Folder:** 02_Finance_Concepts | **Audience:** Beginner → Consultant
>
> **Provenance:** Merged from Claude `02_Finance/02.01_Financial_Statements_and_Accounting.md`, `02.02_Driver_Based_Planning_and_KPIs.md`, `02.03_Rolling_Forecast_Architecture.md`; Claude `01_Foundation/01.02_Business_Concepts.md`

---

## Why Finance Matters for EPM Consultants

EPM software exists to serve the **CFO's office**. If you don't understand financial statements, you can't design a meaningful planning application. Every dimension, form, rule, and report connects back to financial concepts.

---

## The Three Financial Statements

### 1. Income Statement (P&L — Profit and Loss)

Shows how much money a company **made and spent** over a period.

```
Revenue                    ₹100 Cr
 - Cost of Goods Sold       ₹40 Cr
 = Gross Profit              ₹60 Cr
 - Operating Expenses        ₹30 Cr
   (Salaries, Rent, Marketing)
 = EBITDA                     ₹30 Cr
 - Depreciation & Amortization ₹5 Cr
 = EBIT (Operating Income)    ₹25 Cr
 - Interest Expense            ₹3 Cr
 = EBT (Earnings Before Tax)  ₹22 Cr
 - Income Tax                  ₹7 Cr
 = Net Income                 ₹15 Cr
```

**EPM Relevance:** P&L accounts are **Flow** type — values accumulate over time (Jan + Feb + Mar = Q1).

### 2. Balance Sheet

Shows what a company **owns and owes** at a point in time.

```
ASSETS                          LIABILITIES + EQUITY
Cash               ₹20 Cr     Accounts Payable    ₹10 Cr
Accounts Receivable ₹15 Cr     Bank Loans          ₹30 Cr
Inventory           ₹10 Cr     Total Liabilities   ₹40 Cr
Fixed Assets        ₹55 Cr     
                                Shareholder Equity  ₹60 Cr
Total Assets       ₹100 Cr     Total L + E        ₹100 Cr
```

**EPM Relevance:** Balance Sheet accounts are **Balance** type — the value at any point is the current position, not a sum of periods.

### 3. Cash Flow Statement

Shows how cash **moves in and out** of the company.

| Section | What It Covers |
|---------|---------------|
| **Operating** | Cash from business operations (collections, payments) |
| **Investing** | Cash from buying/selling assets |
| **Financing** | Cash from loans, equity, dividends |

---

## Key Financial Concepts for EPM

### Time Balance Types

| Type | Meaning | EPM Aggregation | Example |
|------|---------|-----------------|---------|
| **Flow** | Accumulates over time | Jan + Feb + Mar = Q1 | Revenue, Expense |
| **Balance** | Point-in-time snapshot | Q1 = Mar value (last period) | Cash, Receivables |
| **First** | Uses first period value | Q1 = Jan value | Opening balance |
| **Average** | Average across periods | Q1 = (Jan + Feb + Mar) / 3 | Average headcount |

### Driver-Based Planning

Instead of entering every number manually, define **drivers** and let the system calculate:

```
Revenue = Rooms Available × Occupancy Rate × Average Room Rate

Driver Inputs:
  Rooms Available    = 100
  Occupancy Rate     = 75%
  Average Room Rate  = ₹5,000

Calculated:
  Room Nights Sold = 100 × 75% = 75
  Revenue = 75 × ₹5,000 = ₹3,75,000 per day
```

### Rolling Forecasts

Instead of a fixed annual budget, continuously update predictions:

| Pattern | What It Means |
|---------|--------------|
| **3+9** | 3 months actual + 9 months forecast = 12 months |
| **6+6** | 6 months actual + 6 months forecast = 12 months |
| **Rolling 18** | Always forecast the next 18 months |

---

## 🧠 Self-Check Questions

1. **What is the difference between a P&L and a Balance Sheet?**
2. **What Time Balance type would you use for Revenue? For Cash?**
3. **What is driver-based planning and why is it better than direct entry?**
4. **Explain a 3+9 rolling forecast.**

> **Teach-back prompt:** Explain to a new EPM developer why they need to understand the difference between Flow and Balance accounts before designing an application's Account dimension.


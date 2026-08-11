# Administering Predictive Cash Forecasting — Complete Markdown Edition

> **Original PDF:** `Administering_Predictive_Cash_Forecasting.pdf` | **Folder:** Level 5 (Advanced & Specialized)  
> **Purpose:** Definitive Markdown guide for configuring Oracle Predictive Cash Forecasting (`PCF`), mapping ERP cash transactions, setting up AI liquidity models, and defining daily bank rolling horizons.

---

## Table of Contents
1. [Predictive Cash Forecasting (`PCF`) Architecture](#pcf-architecture)
2. [Mapping ERP Bank Transactions & Daily Cash Flow Drivers](#cash-drivers)
3. [AI Liquidity Forecasting & Rolling Daily Horizons](#liquidity)
4. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Predictive Cash Forecasting (`PCF`) Architecture <a name="pcf-architecture"></a>

**Predictive Cash Forecasting (`PCF`)** is an advanced EPM Enterprise Cloud application tailored for corporate treasurers. Unlike standard monthly balance sheet cash flow (`Indirect Method`), PCF models **Daily Operational Cash Flow (`Direct Method`)** across bank accounts.

---

## 2. Mapping ERP Bank Transactions & Daily Cash Flow Drivers <a name="cash-drivers"></a>

- Connects via Data Integration to `Oracle Cloud ERP Cash Management` to pull daily bank statement closing balances and open accounts receivable invoices.
- **Driver Rules:** Maps historical customer invoice payment behavior (`e.g., Customer A typically pays 4 days after net 30 due date`) to predict exact physical daily cash inflows.

---

## 3. AI Liquidity Forecasting & Rolling Daily Horizons <a name="liquidity"></a>

- Enables **Daily Rolling Forecasts** (`14-day, 30-day, and 90-day daily cash projections`).
- Uses native Auto-Predict ML models (`ARIMA/ETS`) to identify cyclical end-of-month payroll cash drains automatically.

---

## 4. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`17_Advanced_Planning/01_Advanced_Planning_Deep_Reference.md`** — Detailed PCF setup and treasury configuration.

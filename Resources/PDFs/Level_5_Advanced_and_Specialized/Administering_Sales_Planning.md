# Administering Sales Planning — Complete Markdown Edition

> **Original PDF:** `Administering_Sales_Planning.pdf` | **Folder:** Level 5 (Advanced & Specialized)  
> **Purpose:** Comprehensive Markdown reference covering Oracle Sales Planning (`OSP`), Quota Planning, Advanced Sales Forecasting, Key Account Planning, and Salesforce CRM integration.

---

## Table of Contents
1. [Sales Planning Architecture: Quota, Key Account & Advanced Forecasting](#architecture)
2. [Configuring Quota Planning & Top-Down / Bottom-Up Allocation](#quota-planning)
3. [Salesforce CRM Data Integration & Pipeline Driver Rules](#crm-integration)
4. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Sales Planning Architecture: Quota, Key Account & Advanced Forecasting <a name="architecture"></a>

**Oracle Sales Planning (`OSP`)** bridges corporate financial targets (`VP of Sales`) with operational field execution (`Sales Reps`).

---

## 2. Configuring Quota Planning & Top-Down / Bottom-Up Allocation <a name="quota-planning"></a>

- **Top-Down Quota Allocation:** VP of Sales sets a $\$100\text{M}$ global target. Driver rules allocate quota to regional directors (`North America = $60M`) based on historical market potential or territory account density.
- **Bottom-Up Quota Negotiation:** Field reps submit proposed accounts and adjustments; controllers reconcile top-down vs bottom-up gaps.

---

## 3. Salesforce CRM Data Integration & Pipeline Driver Rules <a name="crm-integration"></a>

- Uses pre-built Data Integration adapters to pull daily open opportunities, sales stages (`Stage 1 = 10%, Stage 4 = 80%`), and historical win rates directly from **Salesforce CRM**.

---

## 4. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`17_Advanced_Planning/01_Advanced_Planning_Deep_Reference.md`** — Quota calculation tables and CRM mappings.

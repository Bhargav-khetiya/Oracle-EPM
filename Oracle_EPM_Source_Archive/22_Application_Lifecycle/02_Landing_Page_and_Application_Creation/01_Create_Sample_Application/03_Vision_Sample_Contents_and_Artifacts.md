# 📦 Vision Sample Application — Complete Contents Reference
## Everything Included in the Vision Sample

> **Application Name:** Vision  
> **Type:** Planning (with Modules)  
> **Purpose:** Learning, demonstration, and exploration

---

## 📐 Dimension Structure

### 1. Account Dimension
| Level | Member | Alias | Data Storage | Account Type |
|-------|--------|-------|-------------|--------------|
| 0 | Account | Total Account | Dynamic Calc | - |
| 1 | ├── Gross Revenue | Gross Revenue | Dynamic Calc | Revenue |
| 2 | │   ├── Product Revenue | Product Revenue | Store | Revenue |
| 2 | │   ├── Service Revenue | Service Revenue | Store | Revenue |
| 2 | │   └── Other Revenue | Other Revenue | Store | Revenue |
| 1 | ├── Discounts | Discounts | Store | Revenue |
| 1 | ├── Net Revenue | Net Revenue | Dynamic Calc | Revenue |
| 1 | ├── COGS | Cost of Goods Sold | Dynamic Calc | Expense |
| 2 | │   ├── Material Costs | Material Costs | Store | Expense |
| 2 | │   ├── Labor Costs | Labor Costs | Store | Expense |
| 2 | │   └── Overhead | Manufacturing Overhead | Store | Expense |
| 1 | ├── Gross Margin | Gross Margin | Dynamic Calc | Expense |
| 1 | ├── Operating Expenses | Operating Expenses | Dynamic Calc | Expense |
| 2 | │   ├── Salary | Salaries | Store | Expense |
| 2 | │   ├── Benefits | Employee Benefits | Store | Expense |
| 2 | │   ├── Travel | Travel & Entertainment | Store | Expense |
| 2 | │   ├── Marketing | Marketing Expense | Store | Expense |
| 2 | │   ├── Depreciation | Depreciation | Store | Expense |
| 2 | │   └── Other OpEx | Other Operating Expenses | Store | Expense |
| 1 | ├── Operating Income | Operating Income | Dynamic Calc | Expense |
| 1 | ├── Interest | Interest Expense | Store | Expense |
| 1 | ├── Tax | Income Tax | Store | Expense |
| 1 | └── Net Income | Net Income | Dynamic Calc | Saved Assumption |

### 2. Entity Dimension
| Level | Member | Alias | Currency | Description |
|-------|--------|-------|----------|-------------|
| 0 | Total Entity | Total Entity | USD | Top-level rollup |
| 1 | ├── United States | US Operations | USD | US operations |
| 2 | │   ├── East | East Region | USD | Eastern US |
| 2 | │   ├── West | West Region | USD | Western US |
| 2 | │   └── Central | Central Region | USD | Central US |
| 1 | ├── Europe | European Operations | EUR | European operations |
| 2 | │   ├── UK | United Kingdom | GBP | UK operations |
| 2 | │   ├── Germany | Germany | EUR | German operations |
| 2 | │   └── France | France | EUR | French operations |
| 1 | └── Asia Pacific | APAC Operations | USD | Asia Pacific |
| 2 |     ├── Japan | Japan | USD | Japanese operations |
| 2 |     ├── China | China | USD | Chinese operations |
| 2 |     └── Australia | Australia | USD | Australian operations |

### 3. Scenario Dimension
| Member | Alias | Start Year | Start Period | End Year | End Period |
|--------|-------|------------|-------------|----------|-----------|
| Actual | Actual | FY20 | Jan | FY27 | Dec |
| Budget | Budget | FY24 | Jan | FY27 | Dec |
| Forecast | Forecast | FY24 | Jan | FY27 | Dec |
| Plan | Strategic Plan | FY24 | Jan | FY27 | Dec |

### 4. Version Dimension
| Member | Alias | Type | Description |
|--------|-------|------|-------------|
| Working | Working | Bottom Up | Active editing version |
| Final | Final Version | Bottom Up | Approved/locked version |
| BU Version 1 | BU Submission | Bottom Up | Business unit submission |
| Target | Target Version | Target | Top-down target setting |

### 5. Year Dimension
| Member | Description |
|--------|-------------|
| FY20 | Fiscal Year 2020 |
| FY21 | Fiscal Year 2021 |
| FY22 | Fiscal Year 2022 |
| FY23 | Fiscal Year 2023 |
| FY24 | Fiscal Year 2024 |
| FY25 | Fiscal Year 2025 |
| FY26 | Fiscal Year 2026 |
| FY27 | Fiscal Year 2027 |

### 6. Period Dimension
| Member | Alias | Quarter |
|--------|-------|---------|
| Jan | January | Q1 |
| Feb | February | Q1 |
| Mar | March | Q1 |
| Apr | April | Q2 |
| May | May | Q2 |
| Jun | June | Q2 |
| Jul | July | Q3 |
| Aug | August | Q3 |
| Sep | September | Q3 |
| Oct | October | Q4 |
| Nov | November | Q4 |
| Dec | December | Q4 |
| Q1 | Quarter 1 | - |
| Q2 | Quarter 2 | - |
| Q3 | Quarter 3 | - |
| Q4 | Quarter 4 | - |
| YearTotal | Year Total | - |
| BegBalance | Beginning Balance | - |

### 7. Currency Dimension (if multi-currency enabled)
| Member | Alias | Symbol | Triangulation Currency |
|--------|-------|--------|----------------------|
| USD | US Dollar | $ | - |
| EUR | Euro | € | - |
| GBP | British Pound | £ | - |
| Local | Local Currency | - | - |
| HSP_InputValue | Input Value | - | System |

---

## 📝 Pre-Built Forms

### Income Statement Forms
| Form Name | Description | Row Dimension | Column Dimension |
|-----------|-------------|---------------|-----------------|
| Revenue Input | Revenue line item data entry | Account (Revenue accounts) | Period (Months) |
| Expense Input | Operating expense data entry | Account (Expense accounts) | Period (Months) |
| Income Statement | Full P&L view | Account (All P&L) | Period (Months) |
| Revenue by Product | Revenue broken by product line | Product | Period (Months) |

### Planning Forms
| Form Name | Description | POV Settings |
|-----------|-------------|-------------|
| Annual Budget | Annual budget entry form | Scenario=Budget, Version=Working |
| Quarterly Forecast | Quarterly forecast updates | Scenario=Forecast, Version=Working |
| Headcount Planning | Employee headcount planning | Module-specific |
| Capital Request | Capital expenditure requests | Module-specific |

---

## 🧮 Pre-Built Business Rules

| Rule Name | Type | Description | Launch From |
|-----------|------|-------------|-------------|
| Calculate Revenue | Calc Manager | Calculates revenue rollups | Revenue forms |
| Roll Up Expenses | Calc Manager | Aggregates expense categories | Expense forms |
| Currency Translation | Calc Manager | Translates local currency to reporting | System |
| Copy Actual to Forecast | Calc Manager | Seeds forecast with actual data | Forecast forms |
| Spread Evenly | Calc Manager | Distributes annual values evenly across months | Budget forms |
| Calculate Ratios | Calc Manager | Calculates financial KPIs and ratios | Dashboards |

---

## 📊 Pre-Built Dashboards & Reports

| Name | Type | Description |
|------|------|-------------|
| Executive Summary | Dashboard | High-level KPIs and financial overview |
| Revenue Dashboard | Dashboard | Revenue trends and analysis |
| Expense Dashboard | Dashboard | Expense tracking and variance |
| Variance Report | Financial Report | Budget vs Actual variance analysis |
| Income Statement | Financial Report | Full P&L financial report |
| Balance Sheet | Financial Report | Balance sheet report |

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: What cubes are provisioned in the Vision application, and what are their respective storage types?
**Answer:** Vision provisions two primary Essbase cubes:
1. Plan1: Block Storage (BSO) Hybrid cube used for financial data entry, driver-based revenue planning, and business rule calculations.
2. VisnASO / VisnRep: Aggregate Storage (ASO) cube used for high-speed executive multidimensional reporting and fast aggregations.

### Q2: Which dimensions in Vision are configured as Dense versus Sparse?
**Answer:** By default in Vision BSO:
- **Dense Dimensions:** Account and Period (defines the internal contiguous block cell matrix).
- **Sparse Dimensions:** Entity, Year, Scenario, Version, Currency, and custom dimensions (Product, Market).

### Q3: Can you extract specific business rules or forms from the Vision application to reuse in a custom production app?
**Answer:** Yes. Navigate to Tools â†’ Migration, expand Planning â†’ Artifacts â†’ Forms or Business Rules, select the desired items, and click **Export**. Download the resulting snapshot and import it into your custom application. *Caution: Ensure that any referenced dimension members in the Vision rules/forms also exist in the target application!*

---

## 🔗 Navigation

| Document | Description |
|----------|-------------|
| [Post-Creation Walkthrough](./04_Post_Sample_Creation_Walkthrough.md) | How to explore the Vision application |
| ← [Creation Steps](./02_Vision_Sample_Creation_Walkthrough.md) | Return to creation steps |
| ← [Back to Overview](./01_Sample_Application_Overview.md) | Return to Sample Application overview |

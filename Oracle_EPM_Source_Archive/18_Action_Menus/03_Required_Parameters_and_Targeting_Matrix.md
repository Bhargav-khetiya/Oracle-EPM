# 03 — Required Parameters & Targeting Matrix

---

## 3.1 What are Required Parameters—

The **Required Parameters** dropdown controls the **spatial and dimensional visibility** of an Action Menu item. Without targeting, every menu item would appear whenever a user right-clicks anywhere on the form, cluttering the UI with irrelevant actions.

```
┌────────────────────────────────────────────────────────────────────────┐
│                     THE 3 TARGETING CATEGORIES                         │
├────────────────────┬───────────────────────────────────────────────────┤
│ 1. Universal       │ Appears anywhere on the form (None)               │
│ 2. Spatial Grid    │ Appears only on specific grid zones (POV, Page,   │
│                    │ Row Header, Column Header, Cell Only, Members)    │
│ 3. Dimensional     │ Appears only when right-clicking a specific       │
│                    │ dimension (e.g. Account, Entity, Department)      │
└────────────────────┴───────────────────────────────────────────────────┘
```

---

## 3.2 The 23 Required Parameters Master Reference

From your supplied production HTML extraction, here are all 23 options in source order:

| # | Parameter Option | Category | Where Menu Appears | Practical Real-World Example |
| :-: | :--- | :--- | :--- | :--- |
| **1** | **`None`** | Universal | Anywhere the user right-clicks on the form or grid. | "Return to Navigation Flow" or "Open Help". |
| **2** | **`Account`** | Dimensional | Only on Account member cells or headers. | "Show Account Formula" or "Account Trend". |
| **3** | **`AssetClass`** | Dimensional | Only on Capital Asset Class members. | "Add New Capital Asset" (Buildings, IT). |
| **4** | **`AssetDetail`** | Dimensional | Only on individual capital asset lines. | "Calculate Asset Depreciation". |
| **5** | **`Currency`** | Dimensional | Only on Currency members or headers. | "Run Currency Conversion". |
| **6** | **`Custom1`** | Dimensional | Only on Custom1 (e.g., Project) members. | "Project Variance Analysis". |
| **7** | **`Department`** | Dimensional | Only on Department / Cost Center members. | "Clear_Dept" or "Department Aggregation". |
| **8** | **`Employee`** | Dimensional | Only on Workforce Employee members. | "Transfer Employee" or "Change Job Grade". |
| **9** | **`Entity`** | Dimensional | Only on Entity dimension coordinates. | "Promote Approval Unit" or "Entity Rollup". |
| **10**| **`Future`** | Dimensional | Only on Future planning horizon members. | "Strategic Long-Range Forecast". |
| **11**| **`Grade`** | Dimensional | Only on Workforce Job Grade members. | "Update Salary Grade Band". |
| **12**| **`HSP_View`** | Dimensional | Only on Periodic/YTD View members. | "Switch between Periodic and YTD View". |
| **13**| **`Period`** | Dimensional | Only on Period members (Jan, Feb, Q1). | "Calculate using @PRIOR". |
| **14**| **`PlanElement`**| Dimensional | Only on PlanElement (Workforce driver) members. | "FY26_Actual_Account_Cleanup_By_PlanElement". |
| **15**| **`Scenario`** | Dimensional | Only on Scenario coordinates (Actual, Budget). | "Copy Budget to Forecast". |
| **16**| **`Version`** | Dimensional | Only on Version coordinates (Working, Final). | "Copy Version" or "Publish Sandbox". |
| **17**| **`Years`** | Dimensional | Only on Years members (FY25, FY26). | "Roll Forward Fiscal Year". |
| **18**| **`Point of View`**| Spatial | Only on POV dropdown bars in web forms. | "Change Application Context". |
| **19**| **`Page`** | Spatial | Only on Page dropdown bars in web forms. | "Bulk Process All Pages". |
| **20**| **`Row`** | Spatial | Only on row headers on the left side of the grid. | "Insert New Row" or "Sort Rows". |
| **21**| **`Column`** | Spatial | Only on column headers along the top of the grid. | "Hide Column" or "Calculate Column Balance". |
| **22**| **`Members only`**| Spatial | Only on dimension member labels (not data cells). | "Drill Down" or "Show Member Properties". |
| **23**| **`Cell Only`** | Spatial | Only on editable or read-only numeric data cells. | "Launch Calculation" or "Grid Spread". |

---

## 3.3 The `Members` Selector Control

When you select a dimensional parameter (e.g., `Department` or `Account`), the **`Members`** field becomes active:
* If left blank: The menu item appears for **any member** in that dimension.
* If specific members are selected (e.g., `D10010:Catering` or `Revenue`):
  * The menu item appears **only when right-clicking those specific members**.
  * Right-clicking `D10020:Finance` will **not** display the menu item.
* *Consultant Use Case*: Used for department-specific calculation rules like `Catering Revenue calculation`, ensuring other departments do not run catering logic.

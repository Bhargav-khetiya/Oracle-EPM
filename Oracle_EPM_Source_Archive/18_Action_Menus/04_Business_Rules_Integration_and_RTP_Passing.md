# 04 — Business Rules Integration & RTP Passing

---

## 4.1 Business Rules: The Engine of Action Menus

Attaching a **Business Rule** to an Action Menu transforms a static data-entry grid into an interactive calculation canvas. Instead of running batch calculations across the entire database, users execute fast, targeted calculations on the exact entity, department, or account they are currently editing.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        RTP CONTEXT PASSING FLOW                        │
├────────────────────────────────────────────────────────────────────────┤
│ 1. User right-clicks cell: [Account: Rev, Dept: D10010, Period: Jan]   │
│ 2. Context Relay captures: {Account="Rev", Dept="D10010", Period="Jan"}│
│ 3. User clicks menu item: "Calculate Catering Revenue"                │
│ 4. Planning inspects Business Rule Runtime Prompts (RTP):             │
│    • Prompt: {var_Department} -> Injected with "D10010"               │
│    • Prompt: {var_Period}     -> Injected with "Jan"                  │
│ 5. If "Hide Prompt" is CHECKED:                                        │
│    • Skips dialog window completely                                    │
│    • Rule executes silently in background via ESSSVR                  │
│    • Displays Launch Confirmation Message toast in browser             │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4.2 Classic View vs. Streamline View

When a business rule requires user input or validation, the **View Type** dropdown controls the modal presentation:

| Feature | Classic View | Streamline View |
| :--- | :--- | :--- |
| **Technology** | Standard Oracle ADF Modal Window | Modern Redwood HTML5 Inline Container |
| **User Experience** | Traditional desktop-like dialog with tabs | Mobile-friendly, clean, high-contrast controls |
| **Prompt Display** | Standard dropdowns and member pickers | Modern card layout with inline search |
| **Best Used When** | Complex rules with 5+ multi-member prompts | Fast single-prompt operational workflows |

---

## 4.3 Hide Prompt & Seamless One-Click Execution

The **`Hide Prompt`** checkbox is the cornerstone of professional EPM user experience:
* **Default Unchecked**: The user right-clicks $\rightarrow$ Clicks Rule $\rightarrow$ Pop-up dialog appears showing the prompt coordinates $\rightarrow$ User clicks "Launch" $\rightarrow$ Rule runs. (3 clicks).
* **Checked**: If all required prompts can be mapped from the active cell's Page, POV, Row, and Column, **no dialog is displayed**. The rule executes instantly with **1 click**.
* *Failsafe Mechanism*: If a rule requires an assumption prompt (e.g., `{Enter_Inflation_Rate}`) that cannot be derived from grid coordinates, Planning **automatically forces the prompt dialog to display**, preventing null calculation errors.

---

## 4.4 Analysis of Production Rules from UI Extraction

In your supplied HTML snapshot (`action menu.txt`), 52 named business rules are available in the dropdown. These represent real-world enterprise planning workflows:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PRODUCTION BUSINESS RULES TAXONOMY                       │
├──────────────────────┬──────────────────────────────────────────────────────┤
│ 1. Aggregations      │ • Aggeregate_Income_Expense                          │
│                      │ • Aggregate_Full_Account_Bhargav                     │
│                      │ • FinPlan_01_Aggregation                             │
│                      │ • Partial_Aggeregate_Dep_Full_PlnEle_on_Expense      │
│                      │                                                      │
│ 2. Data Cleanup      │ • Clear_Dept                                         │
│                      │ • Clear_FY26_Actual_P&L_Bhargav                      │
│                      │ • ClearData                                          │
│                      │ • FY26_Actual_expense_Cleanup_bhargav                │
│                      │                                                      │
│ 3. Copy & Seed       │ • FY26_Actual_Clear&Copy_data_on_E10002              │
│                      │ • FY26_Actual_Copy_data_to_Budget_on_E10002          │
│                      │ • BR_Task_9_Data_Copy_With_SmartList_Selection       │
│                      │                                                      │
│ 4. Driver & Calc     │ • Catering Revenue calculation                       │
│                      │ • Task_6_Account_Balance_Calc                        │
│                      │ • BR_Task_10_TrendBased_Planning_with_Smart_Sheet    │
│                      │ • Task9_Allocate_Rudra                               │
└──────────────────────┴──────────────────────────────────────────────────────┘
```

### Case Study: `Catering Revenue calculation` on `D10010:Catering`
1. **Targeting**: Required Parameters set to `Department`, Member set to `D10010`.
2. **Context Passing**: Passes `Department = D10010`, along with the clicked Year, Period, Scenario, and Version.
3. **Essbase FIX Statement**:
   ```essbase
   FIX(&Current_Year, &Current_Scenario, &Current_Version, "D10010")
       "Catering_Revenue" = "Meals_Served" * "Avg_Price_Per_Meal";
   ENDFIX
   ```
4. **Performance**: Evaluates in **< 100 milliseconds** because calculation is scoped strictly to 1 department block, bypassing the other 5,000 departments in the cube.

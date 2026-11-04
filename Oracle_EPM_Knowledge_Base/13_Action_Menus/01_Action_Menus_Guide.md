# 13.1 Action Menus: Context-Sensitive Navigation & Dynamic Parameter Passing

## Table of Contents
1. [Core Consultant Mental Model](#1-core-consultant-mental-model)
2. [Action Menu Architecture: Right-Click Interception](#2-action-menu-architecture-right-click-interception)
3. [Menu Item Types: Forms, Business Rules & URL Redirection](#3-menu-item-types-forms-business-rules--url-redirection)
4. [Context Passing Mechanics (Passing Current POV to Targets)](#4-context-passing-mechanics-passing-current-pov-to-targets)
5. [Tough & Twisted Review Questions with Consultant Model Answers](#5-tough--twisted-review-questions-with-consultant-model-answers)

---

<!-- ===================================================================== -->
<!-- 🎯 LIVE INTERACTIVE VISUAL CARD: ACTION MENUS ARCHITECTURE -->
<!-- ===================================================================== -->
<details open>
<summary><b>🎯 Live Interactive Architecture Card: Action Menus & Context-Passing Pipeline (Click to Collapse / Expand)</b></summary>

<br/>

> [!TIP]
> **Consultant High-Yield Summary:** An Action Menu is a right-click context menu bound to data forms. It intercepts the user's active coordinate (Entity, Account, Period, Year) and dynamically injects those coordinates as **Runtime Prompts (RTP)** into targeted business rules or secondary forms, eliminating manual navigation.

| Target Action Type | Parameter Passing Mechanism | User Experience Outcome |
| :--- | :--- | :--- |
| **Data Form** | Passes active Page/POV/Row/Column members | Opens detailed breakdown form filtered to the clicked entity |
| **Business Rule** | Binds clicked coordinate into Rule RTPs | Executes calculation strictly on the clicked cell intersection |
| **URL Link** | Appends query string parameters (`?entity=US`) | Opens external ERP invoice viewer or operational dashboard |
| **Manage Approvals** | Evaluates active Scenario/Version/Entity | Jumps directly to the Approval Unit promotion screen |

```mermaid
sequenceDiagram
    autonumber
    actor User as Financial Planner
    participant Form as Web Form / Smart View Grid
    participant MenuEngine as Action Menu Context Router
    participant Target as Target Form / Business Rule

    User->>Form: Right-clicks cell [Entity: US_East, Account: Travel_Opex, Period: Oct]
    Form->>MenuEngine: Intercepts coordinate tuple: {US_East, Travel_Opex, Oct, FY26}
    MenuEngine->>User: Displays context menu: "Calculate Department Travel"
    User->>MenuEngine: Clicks "Calculate Department Travel"
    MenuEngine->>Target: Launches Business Rule passing RTPs:<br/>Entity="US_East", Account="Travel_Opex"
    Target-->>User: Rule executes in 150 ms; targeted cell updated
```

</details>

---

## 1. Core Consultant Mental Model

Action Menus represent the difference between an amateur EPM design and an enterprise-grade consultant design:
* **The Amateur Design:** A planner looking at corporate expenses sees an anomaly in Travel for the East Region. They must write down the numbers, close the form, open the navigation menu, search for the Personnel Travel form, manually select East Region, select October, and find the account.
* **The Consultant Design:** The planner right-clicks the cell, selects **"Drill to Travel Detail"**, and the system instantly opens the detailed breakdown form pre-filtered to East Region and October.

---

## 2. Action Menu Architecture: Right-Click Interception

When an Action Menu is attached to a web data form:
1. The user right-clicks any data cell or row/column header.
2. The Planning JavaScript engine extracts the active cell's **coordinate vector**:
   $$\text{Tuple} = \{\text{Scenario}, \text{Version}, \text{Year}, \text{Period}, \text{Entity}, \text{Account}, \dots\}$$
3. The menu engine evaluates menu conditions:
   * If a menu item is configured to appear only on `Account: Travel`, it hides the menu item on salary cells.
4. The user selects an action, and the router passes the coordinate vector to the target destination.

---

## 3. Menu Item Types: Forms, Business Rules & URL Redirection

| Item Type | Configuration Property | Execution Behavior |
| :--- | :--- | :--- |
| **Form** | Target Form, Target Cube | Opens the secondary form, filtering its Page/POV to match the clicked cell. |
| **Business Rule** | Target Rule, Prompt Mappings | Passes clicked cell members into rule variables, bypassing user prompt popups. |
| **Dashboard** | Target Dashboard 2.0 | Launches an interactive dashboard filtered to the clicked division. |
| **URL** | External URL with tokens | Resolves tokens like `https://erp.company.com/invoice?id={cell.value}`. |

---

## 4. Context Passing Mechanics (Passing Current POV to Targets)

When configuring an Action Menu item in Calculation Manager or Form Designer:
* **Use Form Context:** Automatically maps dimensions from the source form to matching dimensions in the target form.
* **Runtime Prompt (RTP) Binding:** In business rules, assign the prompt default value to **"Current Member"** from the active grid:
  * Variable `var_Entity` is bound to the clicked Row Entity.
  * Variable `var_Period` is bound to the clicked Column Period.
* When launched from the Action Menu, the business rule runs silently in the background without prompting the user for input.

---

## 5. Tough & Twisted Review Questions with Consultant Model Answers

### Question 1: "An administrator builds an Action Menu item to launch a business rule from a form. When users right-click, the rule prompt dialog still pops up asking for Entity and Year. How do you make the rule execute silently using the clicked cell's context?"
**Consultant Model Answer:**
> "To execute silently without user prompts:
> 1. In the Action Menu Designer, edit the rule menu item.
> 2. Locate the **Prompt Mappings** section.
> 3. For each Runtime Prompt (e.g., `rtp_Entity`, `rtp_Year`), set the mapping source to **'Grid Context'** (or select the specific dimension from the form grid).
> 4. Ensure the **'Hide Prompts'** checkbox is checked.
> When configured, the menu router automatically binds the clicked cell's Entity and Year into the prompt variables and dispatches the execution immediately, bypassing the interactive prompt window."

### Question 2: "Can an Action Menu item be attached to Smart View ad-hoc grids, or does it only work on predefined web data forms?"
**Consultant Model Answer:**
> "Action Menus are configured at the **Data Form definition level**. 
> * **On Web Forms and Smart View Forms:** When a user opens a data form inside Excel via Smart View, right-clicking any cell exposes the Action Menu directly inside the Excel right-click context menu.
> * **On Free-Form Smart View Ad-Hoc Grids:** Action Menus do not appear because free-form grids do not have an underlying form definition to bind the menu. However, users can execute business rules on ad-hoc grids via the Smart View ribbon rule launcher."

### Question 3: "A user right-clicks a cell on row 10 and selects an Action Menu linking to a secondary form. The secondary form opens, but displays data for the entire company instead of the clicked entity. What was misconfigured?"
**Consultant Model Answer:**
> "In the Action Menu item definition, the administrator failed to enable **'Pass Context'** (or 'Use Form Context') for the Entity dimension. 
> Without context passing enabled, the target form opens with its own default Page/POV selections (which defaulted to 'Total_Company'). Enabling 'Pass Context' ensures that the target form's POV is dynamically overwritten with the clicked cell's specific leaf entity coordinate."

---
*Proceed to [Module 14: Application Lifecycle Management & Cloning](../14_Application_Lifecycle/00_INDEX.md).*

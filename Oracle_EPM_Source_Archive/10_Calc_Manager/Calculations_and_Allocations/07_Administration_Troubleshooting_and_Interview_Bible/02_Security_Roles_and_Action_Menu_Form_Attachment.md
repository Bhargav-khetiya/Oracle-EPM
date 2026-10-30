# 02 Security Roles, Form Attachments, and Action Menu Integration

## 1. Calculation Manager Security Architecture

Security governance in Calculation Manager operates across two distinct operational boundaries:
1. **Design-Time Privileges**: Who can create, edit, validate, deploy, and unlock calculation artifacts.
2. **Runtime Launch Privileges**: Which end users and business roles can execute deployed rules.

```
+---------------------------------------------------------------------------------------------------+
|                                  SECURITY & EXECUTION PRIVILEGES                                  |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  DESIGN-TIME SECURITY (Calculation Manager UI)                                                    |
|  +---------------------------------------------------------------------------------------------+  |
|  | - Service Administrator: Full unconstrained access (Author, Deploy, Delete, Unlock).        |  |
|  | - Power User: Author and edit rules within assigned application domains (cannot break locks).|  |
|  | - Planner / User: ZERO access to Calculation Manager design canvas.                          |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                  |                                                |
|                                                  | Rule Deployed to Planning                      |
|                                                  v                                                |
|  RUNTIME ACCESS SECURITY (Planning Access Permissions)                                            |
|  +---------------------------------------------------------------------------------------------+  |
|  | - Business Rule Permissions assigned under Tools -> Access Permissions -> Rules.           |  |
|  | - Grant "Launch" privilege to specific Native / IDCS User Groups (e.g., "Finance Planners").   |  |
|  | - If Launch privilege is denied: Rule is completely hidden from user form menus & Smart View. |  |
|  +---------------------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Attaching Business Rules to Web Data Forms

To execute calculations automatically during end-user planning workflows, rules are attached to Web Data Forms under the **Business Rules** tab in the Form Designer:

| Form Attachment Setting | Execution Event | Operational Use Case |
| :--- | :--- | :--- |
| **Run Before Load** | Fires before data cells are fetched from Essbase into the web browser. | **Data Seeding**: Copying prior year actuals or initializing blank forecast blocks before user views grid. |
| **Run After Save** | Fires immediately after the user commits dirty cells to the database. | **Dynamic Recalculation**: Recomputing tax, fringe benefits, or net profit based on newly entered numbers. |
| **Use Form Context** | Overrides RTP variables with active form coordinates. | Restricts rule execution to the user's active Page and POV members without prompt popups. |
| **Hide Prompt** | Suppresses RTP modal dialog if all variables resolve from form. | Provides seamless, zero-click calculation experience for end users. |

---

## 3. Action Menu Integration: Context-Sensitive Execution

Rather than running a rule on save, users often need to trigger calculations on-demand for specific rows or columns. This is achieved by attaching the Business Rule to an **Action Menu**:

```
+---------------------------------------------------------------------------------------------------+
|                                   ACTION MENU RIGHT-CLICK LAUNCH                                  |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  USER RIGHT-CLICKS CELL ON FORM: [Entity: "E101_East", Account: "Bonus_Pool"]                     |
|                                                                                                   |
|  CONTEXT MENU OPENS:                                                                              |
|  |-- Edit Supporting Details                                                                      |
|  |-- Add Cell Comment                                                                             |
|  `-- [Business Rules]                                                                             |
|        `-- Calculate Department Bonus Pool  <-- Action Menu Item                                  |
|                                                                                                   |
|  MECHANISM:                                                                                       |
|  - Action Menu automatically captures:                                                            |
|    - Selected Row Member:    Account = "Bonus_Pool"                                               |
|    - Selected Column Member: Period = "Q1"                                                        |
|    - Selected Page Member:   Entity = "E101_East"                                                 |
|  - Injects captured coordinates directly into Rule Runtime Prompts ({RTP_Entity}, {RTP_Account})  |
|  - Launches calculation instantly without manual user parameter typing!                           |
+---------------------------------------------------------------------------------------------------+
```

### Configuration Steps:
1. Navigate to **Tools -> Action Menus**.
2. Create New Item $\rightarrow$ Type = **Business Rule**.
3. Select Deployed Rule.
4. Enable **Context Sensitive**: Maps grid selection to RTP variables.
5. Associate Action Menu with the target Web Form under **Form Properties -> Other Options**.


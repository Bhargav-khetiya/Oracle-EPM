# Action Menus — Complete Guide

> **Section:** 13 — Action Menus  
> **File:** 01 — Action Menus Guide  
> **Difficulty:** Beginner → Advanced  
> **Prerequisites:** [01_Forms_and_Navigation](../02_User_Interface_and_Navigation/01_Forms_and_Navigation.md)

---

## What Are Action Menus?

An **Action Menu** is a right-click context menu attached to cells on a data form (or Smart View grid). When a user right-clicks a cell, they see options like "Drill to Detail," "Calculate Revenue," or "Open Dashboard" — all pre-configured by the administrator.

### Why They Matter

Without action menus, a user reviewing sales data who notices a variance in the East Region must close the current form, navigate to a different form, manually select East Region, and re-select the scenario and period. With action menus, they right-click → select "Drill to Personnel" → the target form opens instantly, pre-filtered to the exact context.

```
Without Action Menus:           With Action Menus:
6 steps, 60-90 seconds          1 right-click, 2 seconds
```

---

## How Action Menus Work

When a user right-clicks a cell:

1. The EPM engine **intercepts** the click coordinates
2. It **scans the active grid context**: page dimensions, POV, row headers, column headers
3. It **evaluates required parameters** to determine which menu items are valid for this intersection
4. It displays the **filtered menu** showing only relevant actions
5. When the user selects an action, the engine **relays context** (Entity, Period, Account, etc.) to the target

---

## The 9 Menu Item Types

| Type | Purpose | Common Use |
|------|---------|------------|
| **URL** | Open an external website or dashboard | Drill to ERP, BI report, or CRM |
| **Form** | Navigate to another Planning form | Drill from summary to detail form |
| **Business Rule** | Execute a calc script or Groovy rule | On-demand calculations |
| **Manage Approvals** | Open the approval workflow screen | Review/manage budget approvals |
| **Dashboard** | Open a Planning dashboard | Context-filtered visualizations |
| **Change Status** | Execute approval actions (Promote, Approve, Reject) | Inline workflow actions |
| **Menu Header** | Visual separator/folder | Organize menu items |
| **Previous Form** | Return to the previously opened form | Breadcrumb navigation |
| **Copy Version** | Copy data between versions | Working → Final copy |

### Type 1: URL — External Drill-Through

```
URL: https://erp.company.com/ledger?entity=$Entity$&period=$Period$&account=$Account$
Use Form Context: ✓ Checked
```

Planning replaces `$Entity$`, `$Period$`, `$Account$` with the actual member names from the clicked cell.

### Type 2: Form — Cross-Form Navigation

Navigates to another form, automatically passing the current context (Entity, Scenario, Version, Period) to set the target form's POV. The user sees the detail form pre-filtered to their context.

### Type 3: Business Rule — The Most Powerful Type

Triggers a calculation directly from the grid. Key configuration options:

| Field | Purpose |
|-------|---------|
| **Cube** | Which plan type the rule belongs to |
| **Business Rules** | The deployed rule to execute |
| **View Type** | Classic (popup) or Streamline (inline modal) |
| **Hide Prompt** | If all RTPs can be satisfied from cell context, skip the prompt dialog |
| **Window Title** | Custom title for the dialog |

When **Hide Prompt** is checked and all RTPs match the cell context, the rule executes immediately on right-click — no dialog at all.

### Type 6: Change Status — Inline Approval Actions

Allows users to Promote, Approve, Reject, or Sign Off budgets directly from the grid without opening the approval dashboard. Supports 20 approval actions including Start, Exclude, Delegate, Freeze/Unfreeze, and Submit to Top.

---

## Creating an Action Menu

### Step 1: Create the Menu

```
Navigator → Action Menus → Create
Name: Revenue_Analysis_Menu
```

### Step 2: Add Menu Items

For each item, configure:

| Field | Description | Limits |
|-------|-------------|--------|
| **Menu Item** | Programmatic name (unique key) | 80 chars, alphanumeric + underscore only |
| **Label** | Display text the user sees | 80 chars, free-form text |
| **Icon** | Optional icon | Text/path input |
| **Type** | One of the 9 types | Required |
| **Required Parameters** | Dimensional targeting criteria | 23 options, default: None |
| **Members** | Restrict to specific members | Optional |

### Step 3: Assign to Forms

```
Form Properties → Action Menu dropdown → Select the menu
```

### Step 4: Test

Open the form, right-click a cell, verify the menu appears with correct items filtered by context.

---

## Required Parameters — Controlling When Menu Items Appear

Required Parameters determine which right-click locations show a specific menu item:

| Parameter | Menu Appears When Clicking On |
|-----------|------------------------------|
| **None** | Anywhere on the grid |
| **Row** | Any row header |
| **Column** | Any column header |
| **Page** | Any page/POV dropdown |
| **Cell** | Any data cell |
| **Account (Row/Column/Page)** | Specific Account dimension member |
| **Entity (Row/Column/Page)** | Specific Entity dimension member |
| **Period (Row/Column/Page)** | Specific Period dimension member |
| **Scenario (Row/Column/Page)** | Specific Scenario dimension member |

When you specify "Account" as the required parameter, you can further restrict to specific members (e.g., only show "Calculate Catering" when right-clicking on "Catering_Revenue").

---

## Web Forms vs Smart View Differences

| Feature | Web Data Forms | Smart View (Excel) |
|---------|---------------|-------------------|
| Menu access | Direct right-click | Right-click → Smart View flyout |
| POV targeting | Supported | **Not supported** |
| Launch window | Browser popup/tab | External browser window |
| Flex Forms | N/A | Fully supported |

---

## Best Practices

1. **Group related items** under Menu Header separators
2. **Use Hide Prompt** for business rules that only need the cell context
3. **Limit menu items** to 10–15 per menu (too many overwhelms users)
4. **Name consistently**: `Drill_to_[TargetForm]`, `Calc_[Operation]`
5. **Test in both** web forms and Smart View
6. **Use required parameters** to show only relevant items per context

---

## Quick Recall

1. **What is an Action Menu?** → A right-click context menu on form cells that provides drill-through, calculations, and navigation.
2. **How many menu item types exist?** → 9: URL, Form, Business Rule, Manage Approvals, Dashboard, Change Status, Menu Header, Previous Form, Copy Version.
3. **What does Hide Prompt do?** → Executes the rule immediately without showing a prompt dialog if all RTPs are satisfied by the cell context.
4. **What are Required Parameters?** → Rules that control when a menu item appears based on what the user right-clicked.

**Teach-back prompt:** Explain to a colleague how an Action Menu business rule item can execute a calculation on the exact entity and period the user right-clicked, without showing any prompts.

---

## Source Provenance

| Source | Files |
|--------|-------|
| ChatGPT | `Action_Menus/01-05` (5 files, ~45KB total) |
| Gemini | `Action_Menus/` (mirrors ChatGPT structure) |
| Oracle | [Action Menus in Planning](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/) |


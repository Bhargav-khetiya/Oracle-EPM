# User Interface, Forms, and Navigation

> **Prerequisites:** [What Is EPM](../00_Foundation/01_What_Is_EPM.md)  
> **Sources merged:** ChatGPT 02_User_Interface_and_Navigation + Form_Properties (14 files), Claude 06_Forms + 28_Screen_Encyclopedia + 33_Navigation_Encyclopedia, Gemini equivalents  
> **Evidence Labels:** `[Oracle Documented]` · `[Illustrative]` · `[Recommendation]`

---

## Navigation Flows

Navigation Flows control the user interface experience — what icons, cards, and tabs a user sees on the EPM Cloud home page.

### Structural Hierarchy

```
HOME PAGE
  └── Clusters (large folders: "Financials", "Workforce")
        └── Cards (clickable tiles: "Expense Planning", "Revenue")
              └── Tabs (organize content within cards)
                    ├── Vertical tabs (left side)
                    └── Horizontal tabs (top within a vertical tab)
```

### Attachable Objects

Cards and tabs can point to: Dashboards (1.0/2.0), Data Forms, Business Rules, Task Lists, Financial Reports, URLs, Approvals, and Job Console.

### Role-Based Flows

| Flow | Audience | Shows |
|:---|:---|:---|
| **Executive Flow** | Senior leaders | Dashboards and reports only |
| **Planner Flow** | Budget analysts | Forms, task lists, business rules |
| **Admin Flow (Default)** | Administrators | All features based on role |

> [!IMPORTANT]
> **Hiding ≠ Securing.** Removing a card from a Navigation Flow hides it from the home page but does NOT remove underlying security access. Users can still access rules via Smart View or direct URL. Navigation Flows are for UI simplicity, not security.

> [!TIP]
> You cannot edit the Default flow. Duplicate it, edit the duplicate, and activate the new one. If a user belongs to multiple groups with different flows, the flow highest in the list order takes priority.

`[Oracle Documented]`

---

## Web Data Forms

A Planning form is the primary data entry interface. It combines a grid layout with display, validation, and save behavior.

### Form Design Essentials

| Component | Purpose |
|:---|:---|
| **Rows** | Usually Account dimension members |
| **Columns** | Usually Period dimension members |
| **POV (Point of View)** | Fixed context: Entity, Scenario, Version, Year |
| **Page** | Selectable dimension member (user can switch) |
| **Business Rules** | Rules attached to run on save or on demand |
| **Smart Push** | Data Map to push data to another cube on save |

### Form Properties

#### Precision and Display

| Setting | What It Does | Example |
|:---|:---|:---|
| **Minimum Decimals** | Pads trailing zeros | Min 2: `100` → `100.00` |
| **Maximum Decimals** | Rounds displayed decimal places | Max 3: `100.12345` → `100.123` |
| **Currency Member Precision** | Uses precision defined for the currency member | Varies by currency |

#### Suppression Settings

| Setting | Practical Meaning | Caution |
|:---|:---|:---|
| **Suppress Missing Data** | Hides rows/columns with no data | May hide intersections users need to populate |
| **Suppress Missing Blocks** | Skips missing blocks at query level | Can help with many missing rows; can hurt with few |
| **Database Suppression** | Applies suppression closer to the database | Test with formula columns (may suppress before formula evaluates) |
| **Suppress Invalid Data** | Hides invalid intersection rows/columns | Users may not understand why data is unavailable |
| **Suppress Missing + Zero** | Combines missing and zero suppression | Behavior varies by form version; test zero-valued data |

#### Grid and Save Options

| Setting | Purpose |
|:---|:---|
| **Autosave** | Saves as users navigate between cells |
| **Calc On the Fly** | Evaluates formulas without submitting (Forms 2.0) |
| **Enable Mass Allocate** | Allows mass data spreading across intersections |
| **Enable Grid Spread** | Allows spreading values across periods |
| **Make Form Read-Only** | Prevents data entry (does not revoke data access) |
| **Cell-Level Documents** | Enables attachments on individual cells |

### Grid Spread and Mass Allocate

**Grid Spread** lets users distribute a value across time periods:

```
User enters Q1 Revenue = $300,000
Grid Spread options:
  • Evenly:    Jan=$100K, Feb=$100K, Mar=$100K
  • Based on existing data ratios
  • Based on prior year pattern
  • Fill: $300K in each month
```

**Mass Allocate** distributes data across dimensional intersections (entities, departments, products) based on rules.

`[Oracle Documented]`

---

## Dashboards

EPM Cloud offers two dashboard types:

| Type | Description |
|:---|:---|
| **Dashboards 1.0** | Legacy — component-based layout with forms, charts, and tiles |
| **Dashboards 2.0 (Infolets)** | Modern — responsive, configurable tiles showing KPIs and trends |

Dashboards are read-only views that pull data from forms and cubes. They're typically attached to Navigation Flow cards for executive consumption.

`[Oracle Documented]`

---

## Form Design Best Practices

```
✅ DO:
  - Keep forms focused on a single planning task
  - Use clear form instructions telling users what to enter
  - Test suppression with populated, empty, and zero-valued data
  - Attach business rules to run on save only when needed
  - Test Smart Push with "Use Form Context" enabled

❌ DON'T:
  - Create forms with hundreds of rows (use filtering/paging)
  - Enable Grid Spread without confirming the required role
  - Assume hiding a form removes data access (use security)
  - Enable Autosave + complex rules without testing performance
```

`[Recommendation]`

---

## Quick Recall

1. **What are Navigation Flows and what can't they do?**
   → They control the home page UI (clusters, cards, tabs). They CANNOT enforce security — hiding a card doesn't prevent access via Smart View or URL.

2. **What is the difference between Grid Spread and Mass Allocate?**
   → Grid Spread distributes across time periods (one dimension). Mass Allocate distributes across multiple dimensional intersections.

3. **Why must you test suppression before enabling it?**
   → Aggressive suppression can hide intersections that users need for data entry, and formula columns may be suppressed before formulas evaluate.

---

## Oracle References

- [Setting Form Grid Properties](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/setting_form_grid_properties.html)
- [Setting Form Precision](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/setting_form_precision_and_other_options.html)
- [Form Design Considerations](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/form_design_considerations.html)
- [About Navigation Flows](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/about_navigation_flows.html)


# 🚀 Step 1: General Properties
## Application Name, Description & Type Selection

> **Wizard Step:** 1 of 5  
> **Screen Title:** "Create Application" or "General Properties"  
> **Navigation:** `Planning Landing Page → START → Step 1`  
> **Previous:** Planning Landing Page  
> **Next:** Step 2 — Application Type / Module Selection

---

## 📸 Screen Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  Create Application                                    Step 1/5  │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  General Properties                                               │
│  ─────────────────                                                │
│                                                                   │
│  Application Name *     [________________________]                │
│                                                                   │
│  Description            [________________________]                │
│                         [________________________]                │
│                         [________________________]                │
│                                                                   │
│  Application Type *     [▼ Select Application Type    ]           │
│                                                                   │
│                                                                   │
│                                                                   │
│                                                                   │
│  ┌────────┐  ┌────────┐                                          │
│  │ Cancel │  │  Next  │                                          │
│  └────────┘  └────────┘                                          │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📝 Field-by-Field Reference

### Field 1: Application Name *(Required)*

| Property | Details |
|----------|---------|
| **Label** | "Application Name" |
| **Type** | Text input field |
| **Required** | ✅ Yes (marked with asterisk *) |
| **Max Length** | 30 characters |
| **Allowed Characters** | Letters (A-Z, a-z), Numbers (0-9), Underscores (_) |
| **Prohibited Characters** | Spaces, hyphens, special characters (@, #, $, %, etc.) |
| **Case Sensitive** | No (stored as entered but treated case-insensitively) |
| **Must Start With** | A letter (cannot start with a number or underscore) |
| **Uniqueness** | Must be unique within the environment |

#### ✅ Valid Application Names
| Name | Valid? | Notes |
|------|--------|-------|
| `FinancialPlan` | ✅ | Good — descriptive, no special chars |
| `Budget_2025` | ✅ | Good — underscore allowed |
| `Vision` | ✅ | Good — simple and clear |
| `MyApp` | ✅ | Valid but not descriptive |
| `CORP_PLANNING` | ✅ | Good — uppercase with underscore |

#### ❌ Invalid Application Names
| Name | Valid? | Reason |
|------|--------|--------|
| `Financial Plan` | ❌ | Contains space |
| `2025_Budget` | ❌ | Starts with number |
| `My-App` | ❌ | Contains hyphen |
| `App@Corp` | ❌ | Contains special character |
| `ThisIsAVeryLongApplicationNameThatExceedsTheLimit` | ❌ | Exceeds 30 characters |
| ` ` (empty) | ❌ | Required field |

> [!CAUTION]
> **The Application Name CANNOT be changed after creation.** Choose carefully. This name becomes the internal database identifier and appears in all migration snapshots, API calls, and system references.

> [!TIP]
> **Naming Convention Best Practice:**
> - Use a consistent naming convention across environments
> - Include purpose: `Corp_Planning`, `Fin_Forecast`, `WF_Plan`
> - Consider environment prefix for non-production: `DEV_FinPlan`, `TEST_FinPlan`

---

### Field 2: Description *(Optional)*

| Property | Details |
|----------|---------|
| **Label** | "Description" |
| **Type** | Multi-line text area |
| **Required** | ❌ No |
| **Max Length** | 255 characters |
| **Allowed Characters** | Any characters including spaces, punctuation |
| **Default Value** | Empty |
| **Editable Later** | ✅ Yes — can be changed after creation |

#### Best Practice Examples:
```
"Corporate financial planning application for FY2024-FY2028. 
Includes revenue forecasting, expense budgeting, and capital planning."

"HR workforce planning - headcount, compensation, and benefits 
for all business units across North America and Europe."

"FreeForm custom application for supply chain cost modeling 
and allocation analysis."
```

---

### Field 3: Application Type *(Required)*

| Property | Details |
|----------|---------|
| **Label** | "Application Type" |
| **Type** | Dropdown/Select list |
| **Required** | ✅ Yes |
| **Default Value** | None (must select) |
| **Editable Later** | ❌ No — CANNOT be changed after creation |

#### Available Options in Dropdown:

| Option | Description | Subscription | When to Choose |
|--------|-------------|-------------|----------------|
| **Planning** | Standard Planning application with optional module framework | Standard + Enterprise | Most common choice for financial planning |
| **FreeForm** | Blank canvas — custom cubes and dimensions | Standard + Enterprise | Maximum flexibility, custom modeling |

> [!IMPORTANT]
> **Planning vs FreeForm — Key Architectural Differences:**
> 
> | Aspect | Planning | FreeForm |
> |--------|----------|----------|
> | Required Dimensions | Account, Entity, Period, Year, Scenario, Version | None required |
> | Pre-built Modules | Financials, Workforce, Capital, Projects, SM | None |
> | Maximum Cubes | Depends on subscription (4-12) | Up to 12 |
> | Maximum Dimensions | Up to 20-29 | Up to 29 |
> | Module Enable Features | ✅ Yes | ❌ No |
> | Essbase OTL Import | ❌ No | ✅ Yes |
> | Dimension Flexibility | Constrained by module structure | Fully flexible |

---

## 🔘 Buttons on This Screen

| Button | Location | Action | Enabled When |
|--------|----------|--------|-------------|
| **Cancel** | Bottom-left | Returns to Planning Landing Page without creating anything | Always |
| **Next** | Bottom-right | Proceeds to Step 2 of the wizard | All required fields filled |

### Button Behaviors:
- **Cancel:** Clicking Cancel returns to the original Planning Landing Page. No data is saved. You can click START again to restart.
- **Next:** Validates all required fields. If validation fails, error messages appear next to the invalid fields. If validation passes, proceeds to the next wizard step.

---

## ❌ Validation Errors

| Error Message | Cause | Resolution |
|---------------|-------|------------|
| "Application name is required" | Name field is empty | Enter a valid application name |
| "Application name contains invalid characters" | Special chars or spaces used | Remove invalid characters |
| "Application name must start with a letter" | Starts with number/underscore | Start with a letter |
| "Application name exceeds maximum length" | More than 30 characters | Shorten the name |
| "Application type must be selected" | No type chosen from dropdown | Select Planning or FreeForm |
| "An application with this name already exists" | Duplicate name (rare in fresh env) | Choose a different name |

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: Can the Application Name ever be renamed after completing Step 1?
**Answer:** No. The Application Name is permanently bound to the internal relational schema, Essbase directory trees, security groups, and REST API endpoints. There is no rename command or setting. Changing an application name requires exporting all metadata and data, wiping the environment via ecreate -f, and creating a new application with the desired name.

### Q2: Why does the wizard reject application names containing underscores or hyphens like PLAN_CORP or FIN-2026?
**Answer:** Oracle Cloud EPM enforces strict naming syntax: maximum **8 characters**, must start with a letter (Aâ€“Z), and allow only alphanumeric characters (Aâ€“Z, â€“z,  â€“9). Hyphens (-), underscores (_), spaces, and special symbols are strictly prohibited because they interfere with internal Unix/Essbase path resolution and SQL table prefix generation.

### Q3: Can the Description field be modified after the application has been created?
**Answer:** Yes. Unlike the Application Name, the **Description** field is fully editable post-creation. Service Administrators can update it at any time by navigating to Application â†’ Settings â†’ General Properties â†’ Description.

---

## 🔗 Navigation

| Direction | Document |
|-----------|----------|
| **Next →** | [Step 2: Application Type Selection](./03_Step2_Application_Type_Selection.md) |
| **← Previous** | [Wizard Overview](./01_Wizard_Overview_and_Prerequisites.md) |
| **← Back to Index** | [Master Index](../../00_MASTER_INDEX.md) |

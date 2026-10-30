# ⚙️ Application Settings Overview — Post-Creation Master Guide
## Navigating the Application Workbench, System Properties & Configuration Governance

> **Navigation:** `Home → Application → Overview` AND `Home → Application → Settings`  
> **Applicability:** All Planning, FreeForm, and Module-based applications  
> **Role Requirement:** Service Administrator  
> **Purpose:** Central command center for monitoring application health, adjusting runtime parameters, and governing lifecycle changes

---

## 🧭 Entry Point: Application Overview Screen

Once an application is created (via Sample, Wizard, or Migration), the original Landing Page disappears, and the **Application Home Page** becomes active. Navigating to **Application → Overview** presents the central management dashboard:

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Application: PlanCorp                                                                        [ Actions ▼ ]  [ Help ❓ ] │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐  ┌────────────────────────────────────┐  │
│  │ Cubes: 3             │  │ Dimensions: 12       │  │ Total Members: 8,420 │  │ Last Database Refresh:             │  │
│  │ 2 BSO, 1 ASO         │  │ 7 Standard, 5 Custom │  │ Outline Status: Clean│  │ 12-Oct-2026 12:54 PM (Succeeded)   │  │
│  └──────────────────────┘  └──────────────────────┘  └──────────────────────┘  └────────────────────────────────────┘  │
│                                                                                                                        │
│  Tabs: [ Cubes ]   [ Dimensions ]   [ Activity ]                                                                       │
│ ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                                                                                                                        │
│  Cubes Listing:                                                                                                        │
│  ┌──────────────┬───────────────┬──────────────────────┬─────────────┬─────────────────┬─────────────────────────────┐ │
│  │ Cube Name    │ Type          │ Storage Engine       │ Dimensions  │ Size / Blocks   │ Status                      │ │
│  ├──────────────┼───────────────┼──────────────────────┼─────────────┼─────────────────┼─────────────────────────────┤ │
│  │ Plan1        │ Planning      │ Block Storage (BSO)  │ 12          │ 45.2 MB         │ Active                      │ │
│  │ OEP_FS       │ Financials    │ Hybrid (BSO + ASO)   │ 11          │ 118.4 MB        │ Active                      │ │
│  │ OEP_REP      │ Reporting     │ Aggregate (ASO)      │ 12          │ 310.0 MB        │ Active                      │ │
│  └──────────────┴───────────────┴──────────────────────┴─────────────┴─────────────────┴─────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🎯 The Actions Menu Breakdown

In the upper-right corner of the Application Overview screen, the **[ Actions ▼ ]** menu provides critical operational controls:

```
[ Actions ▼ ]
  ├── 🔄 Refresh Database ................. Restructures cubes, syncs outline, deploys security filters
  ├── ⚙️ Enable Features .................. Launches module enablement wizard (Financials, Workforce, etc.)
  ├── 🔀 Convert to Hybrid BSO ............ Converts classic BSO cubes to Hybrid calculation engine
  ├── 🧩 Manage Approvals ................. Configures approval units, promotional paths, and reviewers
  ├── 🧹 Compact Outline .................. Defragments Essbase outline files to optimize memory
  ├── 📊 Performance Settings ............. Configures grid limits, compression, and query caches
  └── 🗑️ Remove Application .............. Permanently deletes the application and drops all databases
```

### Key Actions Summary

| Action Item | Operational Impact | Risk Level |
|:---|:---|:---:|
| **Refresh Database** | Pushes all metadata modifications, formulas, and security assignments into the physical Essbase cubes. | 🟢 Low (Routine) |
| **Enable Features** | Unlocks pre-built modules (Financials, Workforce, Capital, Projects, Strategic Modeling). | 🟡 Moderate (Irreversible) |
| **Convert to Hybrid BSO** | Migrates dense/sparse calculation models to Hybrid Essbase for ultra-fast aggregations. | 🟡 Moderate (Test in Sandbox) |
| **Manage Approvals** | Sets up budget approval hierarchies and validation rules. | 🟢 Low |
| **Compact Outline** | Purges deleted member markers and defragments outline structures. | 🟢 Low |
| **Remove Application** | **Drops the application completely.** Environment reverts to the Landing Page. | 🔴 **Critical (Irreversible)** |

---

## ⚖️ The Immutability Matrix: What CAN vs CANNOT Be Changed

A foundational responsibility of the EPM Architect is knowing which parameters are locked forever at creation time versus which parameters remain adaptable.

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                                APPLICATION GOVERNANCE MATRIX                             │
├──────────────────────────────────────────────────────────┬───────────────────────────────┤
│ 🔒 PERMANENTLY LOCKED AT CREATION                        │ 🔓 CAN BE MODIFIED / EXPANDED │
├──────────────────────────────────────────────────────────┼───────────────────────────────┤
│ ❌ Application Name (e.g., PlanCorp)                      │ ✅ Application Description     │
│ ❌ Application Type (Planning vs FreeForm)               │ ✅ Fiscal Years (can add future)│
│ ❌ Start Year (cannot be pushed backwards)               │ ✅ Custom Dimensions (add new)│
│ ❌ Fiscal Year First Month (e.g., January)               │ ✅ Enable Pre-built Modules   │
│ ❌ Multi-Currency Core Architecture (Enabled vs Disabled)│ ✅ Default Currency Symbol     │
│ ❌ Calendar Period Granularity (12 vs 13 periods)         │ ✅ Hybrid BSO Conversion      │
│ ❌ Distribution Type (Even, 4-4-5, 5-4-4, 4-5-4)         │ ✅ User Variables / Sub Vars  │
│ ❌ Sandboxing (if not enabled during cube setup)         │ ✅ Substitution Variables     │
└──────────────────────────────────────────────────────────┴───────────────────────────────┘
```

### Detailed Evaluation of Locked Parameters

1. **Application Name:**
   - Once specified, the internal schema, database tables, and object references are bound to this identifier.
   - **Remedy if incorrect:** Delete application or recreate instance and import snapshot under desired name.
2. **Application Type (Planning vs FreeForm):**
   - FreeForm applications have no mandatory standard dimensions (Period, Year, Scenario, Version, Entity, Account). Standard Planning enforces this structure. You cannot cross this architectural boundary post-creation.
3. **Start Year & Calendar Distribution:**
   - You can add additional **future years** anytime (`Application → Overview → Dimensions → Years → Add Years`).
   - You **cannot** change the Start Year backwards or alter the fundamental weekly/monthly calendar distribution pattern.
4. **Multi-Currency:**
   - If created as Single Currency, you cannot flip a switch to turn on the standard Currency dimension later. You would have to model currencies manually as custom dimensions or recreate the application.

---

## 🛠️ Navigating `Application → Settings`

While `Application → Overview` focuses on data structures and cubes, **`Application → Settings`** governs system-wide behaviors, formatting, and performance defaults:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Application Settings                                                                       [ Save ]     │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                         │
│  General Properties:                                                                                    │
│    Application Name: PlanCorp (Read-Only)                                                               │
│    Description:      [ Corporate Enterprise Planning Model                                            ] │
│    Application Type: Enterprise Planning (Read-Only)                                                    │
│                                                                                                         │
│  Display & Localization:                                                                                │
│    Default Currency:           [ USD - US Dollar                                                     ▼ ] │
│    Date Format:                [ MM/DD/YYYY                                                          ▼ ] │
│    Number Formatting:          [ 1,234,567.89                                                        ▼ ] │
│                                                                                                         │
│  Grid & Form Performance Controls:                                                                      │
│    Maximum Number of Rows:     [ 50,000  ] (Range: 1,000 - 100,000)                                     │
│    Maximum Number of Columns:  [ 250     ] (Range: 50 - 500)                                            │
│    Cell Comment Character Limit[ 1,000   ]                                                              │
│                                                                                                         │
│  Approvals & Process Control:                                                                           │
│    Enable Email Notifications: ☑ Yes                                                                    │
│    Allow Out-of-Office Action: ☑ Yes                                                                    │
│                                                                                                         │
│  System Maintenance & Logging:                                                                          │
│    Artifact Audit Tracking:    ☑ Enable Audit for Metadata and Data Changes                             │
│    Daily Maintenance Window:   [ 01:00 AM UTC                                                        ▼ ] │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🧰 Key Post-Creation Administration Artifacts

Beyond basic settings, the Application navigation group provides access to core operational components:

| Feature / Artifact | Navigation Path | Purpose |
|:---|:---|:---|
| **Data Maps** | `Application → Data Maps` | Pushes and synchronizes data slices between BSO calculation cubes and ASO reporting cubes (e.g., `OEP_FS` → `OEP_REP`). |
| **Valid Intersections** | `Application → Valid Intersections` | Defines rules that restrict user data entry to valid combinations of dimensions (e.g., prohibiting IT expenses on HR cost centers). |
| **Substitution Variables** | `Application → Variables → Substitution Variables` | Global variables (e.g., `&CurYr = FY26`, `&CurMo = Oct`) referenced throughout forms, rules, and reports. |
| **User Variables** | `Application → Variables → User Variables` | Dynamic context filters that individual users configure in their preferences (e.g., `Selected_Entity`). |
| **Action Menus** | `Application → Action Menus` | Right-click contextual menus on forms that execute business rules, jump to URLs, or open sub-forms. |
| **Navigation Flows** | `Tools → Navigation Flows` | Custom role-tailored dashboards and cluster card arrangements for end users. |

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: Which core application parameters are permanently locked at creation time?
**Answer:** The following parameters can NEVER be modified post-creation:
1. **Application Name** (e.g. `PlanCorp`)
2. **Application Type** (Planning vs FreeForm)
3. **Fiscal Year First Month** (e.g. January vs July)
4. **Calendar Granularity** (12 vs 13 periods)
5. **Multi-Currency Architecture** (Single Currency vs Multi-Currency)
6. **Application Start Year** (cannot add historical past years)

### Q2: What is the performance risk of increasing Grid Display Limits to maximum (100,000 rows Ã— 500 columns)?
**Answer:** Large grid limits dramatically increase memory usage and server-side query processing times. If a user opens a wide-open suppression grid across 500,000 cells, the browser may freeze, and Essbase thread pools can become saturated, degrading response times for all concurrent users. Keep limits to operational defaults (e.g. 50,000 rows Ã— 250 columns).

### Q3: How do you enable audit tracking for metadata additions and transactional data edits?
**Answer:** Navigate to `Application â†’ Settings â†’ System Maintenance & Logging` and enable **Artifact Audit Tracking**. For transactional data changes, enable **Data Audit** under `Application â†’ Overview â†’ Dimensions â†’ [Dimension]` for specific accounts or scenarios.

---

## 🔗 Navigation

| Direction | Document |
|:---|:---|
| **← Previous Directory** | [03_Migrate_Application/05_Post_Migration_Validation.md](../03_Migrate_Application_from_Snapshot/05_Post_Migration_Validation_and_Diagnostics.md) |
| **Next →** | [02_Enable_Features_Post_Creation.md](./02_Progressive_Feature_Enablement.md) |
| **Master Index** | [00_MASTER_INDEX.md](../00_MASTER_INDEX.md) |

﻿# 🚀 Step 5: Review & Create
## Final Review Screen and Application Creation

> **Wizard Step:** 5 of 5 (Final Step)  
> **Screen Title:** "Review" or "Create Application"  
> **Navigation:** `START → Step 1 → Step 2 → Step 3 → Step 4 → Step 5 (Review)`  
> **Previous:** Step 4 — Currency Configuration  
> **Next:** Application Home Page (after creation)

---

## 📸 Screen Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  Create Application                                    Step 5/5  │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Review                                                           │
│  ──────                                                           │
│                                                                   │
│  Please review your application settings before creating:         │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │  General Properties                                      │     │
│  │  ────────────────                                        │     │
│  │  Application Name:    Corp_Planning                      │     │
│  │  Description:         Corporate financial planning app   │     │
│  │  Application Type:    Planning                           │     │
│  │                                                          │     │
│  │  Enabled Features                                        │     │
│  │  ────────────────                                        │     │
│  │  Financials:          ✅ Enabled                         │     │
│  │  Workforce:           ✅ Enabled                         │     │
│  │  Capital:             ❌ Not Enabled                     │     │
│  │  Projects:            ❌ Not Enabled                     │     │
│  │  Strategic Modeling:  ❌ Not Enabled                     │     │
│  │  Sales Planning:      ❌ Not Enabled                     │     │
│  │                                                          │     │
│  │  Calendar                                                │     │
│  │  ────────                                                │     │
│  │  Start Year:          FY24                               │     │
│  │  End Year:            FY28                               │     │
│  │  Start Month:         January                            │     │
│  │  Period Type:         12 Months                          │     │
│  │  Weekly Distribution: Even                               │     │
│  │                                                          │     │
│  │  Currency                                                │     │
│  │  ────────                                                │     │
│  │  Main Currency:       USD - US Dollar                    │     │
│  │  Multi-Currency:      ✅ Enabled                         │     │
│  │  Add'l Currencies:    EUR, GBP, INR                      │     │
│  └─────────────────────────────────────────────────────────┘     │
│                                                                   │
│  ⚠️ These settings cannot be changed after creation:             │
│     Application Name, Start Year, Start Month,                    │
│     Multi-Currency, Application Type                              │
│                                                                   │
│  ┌────────┐  ┌────────┐  ┌────────────┐                         │
│  │ Cancel │  │  Back  │  │  Create ✓  │                         │
│  └────────┘  └────────┘  └────────────┘                         │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📋 Review Checklist

Before clicking **Create**, verify each section:

### ✅ General Properties Verification
| Check | Question | If Wrong... |
|-------|----------|-------------|
| ☐ | Is the Application Name correct and following naming conventions— | Click **Back** to Step 1 |
| ☐ | Is the Description accurate— | Click **Back** to Step 1 (or edit later) |
| ☐ | Is the Application Type correct (Planning vs FreeForm)— | Click **Back** to Step 1 |

### ✅ Enabled Features Verification
| Check | Question | If Wrong... |
|-------|----------|-------------|
| ☐ | Are the correct modules enabled— | Click **Back** to Step 2 |
| ☐ | Are unnecessary modules disabled— | Click **Back** to Step 2 |
| ☐ | Remember: you can enable more modules later, but cannot disable | N/A |

### ✅ Calendar Verification
| Check | Question | If Wrong... |
|-------|----------|-------------|
| ☐ | Is the Start Year early enough for historical data— | Click **Back** to Step 3 |
| ☐ | Is the End Year far enough for your planning horizon— | Click **Back** (or extend later) |
| ☐ | Is the Fiscal Year Start Month correct— | Click **Back** to Step 3 |
| ☐ | Is the Period Type correct (12/13/Custom)— | Click **Back** to Step 3 |

### ✅ Currency Verification
| Check | Question | If Wrong... |
|-------|----------|-------------|
| ☐ | Is the Main Currency your primary reporting currency— | Click **Back** to Step 4 |
| ☐ | Is Multi-Currency enabled if needed— | Click **Back** to Step 4 |
| ☐ | Are all required currencies added— | Click **Back** (or add later) |

---

## 🔘 Buttons on This Screen

| Button | Label | Location | Action | Style |
|--------|-------|----------|--------|-------|
| **Cancel** | Cancel | Bottom-left | Cancels entire wizard, returns to Landing Page | Gray/outlined |
| **Back** | Back | Bottom-center | Returns to Step 4 (Currency) | Gray/outlined |
| **Create** | Create ✓ | Bottom-right | **CREATES THE APPLICATION** | Blue/primary, prominent |

### Create Button Behavior:
1. Click **Create**
2. Confirmation dialog may appear: *"Are you sure you want to create this application—*
3. Click **OK/Yes** to confirm
4. Progress indicator appears showing creation stages
5. Application creation takes **5-20 minutes** depending on:
   - Number of enabled modules
   - Calendar range (number of years)
   - Multi-currency settings
   - System load

---

## ⏳ Creation Progress

```
┌────────────────────────────────────────────┐
│       Creating Application...              │
│                                             │
│  ████████████████████░░░░░░░  70%          │
│                                             │
│  ✅ Application container created           │
│  ✅ Cubes initialized                       │
│  ✅ Dimensions created                      │
│  ✅ Module metadata loaded                  │
│  🔄 Building forms and rules...            │
│  ○  Deploying reports                       │
│  ○  Database refresh                        │
│                                             │
│  Please wait...                             │
└────────────────────────────────────────────┘
```

### Creation Process Steps:
| # | Process | Duration | Description |
|---|---------|----------|-------------|
| 1 | Application Container | ~30 sec | Creates app structure in the cloud |
| 2 | Cube Creation | ~1 min | Initializes BSO and ASO cubes |
| 3 | Dimension Build | ~2 min | Creates all dimensions and system members |
| 4 | Module Metadata | ~3 min | Loads module-specific accounts, forms, rules |
| 5 | Forms & Rules | ~3 min | Deploys all pre-built artifacts |
| 6 | Reports & Dashboards | ~2 min | Creates reporting artifacts |
| 7 | Database Refresh | ~3 min | Final outline build and index creation |
| 8 | Validation | ~1 min | Verifies application integrity |

---

## ✅ After Creation — What Happens Next

### Automatic Redirect
Upon successful creation, you are automatically redirected to the **EPM Application Home Page**.

### First-Time Home Page
```
┌──────────────────────────────────────────────┐
│  Welcome to Corp_Planning!                    │
│                                               │
│  Your application has been created.           │
│                                               │
│  Recommended Next Steps:                      │
│  1. Configure module settings                 │
│  2. Set up dimension members                  │
│  3. Create/modify data forms                  │
│  4. Configure security                        │
│  5. Load data                                 │
└──────────────────────────────────────────────┘
```

### Recommended Post-Creation Actions:
| Priority | Action | Navigation |
|----------|--------|------------|
| 1 | Enable remaining features | Application → Configure → Enable Features |
| 2 | Configure modules | Application → Configure → [Module Name] |
| 3 | Add dimension members | Application → Overview → Dimensions |
| 4 | Set up custom forms | Navigator → Forms |
| 5 | Configure business rules | Navigator → Rules (Calc Manager) |
| 6 | Assign security | Tools → Access Control |
| 7 | Load data | Data Integration or Data Management |
| 8 | Refresh database | Application → Configure → Actions → Refresh |

---

## ❌ Creation Failure Scenarios

| Error | Cause | Resolution |
|-------|-------|------------|
| "Application creation failed" | System error | Check Jobs console for details; may need to retry |
| "Insufficient resources" | Environment resource limits | Contact Oracle Support |
| "Timeout during creation" | Long-running process | Check Jobs console — may have completed |
| Browser closes during creation | Network/browser issue | Log back in — creation continues server-side |
| "Invalid application name" | Name validation failed | Should not occur at this step (validated in Step 1) |

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: What exact technical operations occur in the background when you click "Create"—
**Answer:** The server executes a 5-phase provisioning pipeline:
1. Provisions the relational schema tables for forms, security, and task lists.
2. Initializes the physical Essbase cubes (Plan1, etc.) and outlines on disk.
3. Builds core dimension hierarchies (Account, Entity, Period, Year, Scenario, Version).
4. Generates system rate tables and default currency exchange rules.
5. Performs the initial full Database Restructure and deploys security access control.

### Q2: What should an administrator do if application creation fails with an internal timeout error—
**Answer:** Wait 15 minutes. Check the application URL. If the Landing Page is still displayed or the environment is unresponsive, log in via EPM Automate and check status:
`cmd
epmautomate login admin@company.com "C:\EPM\pass.epw" "https://epm.oraclecloud.com"
epmautomate recreate -f
`
Wipe the instance clean and retry. Timeouts typically occur if underlying cloud storage is undergoing maintenance or if an invalid reserved keyword was used in naming.

### Q3: Can the configuration choices displayed on the Review screen be exported for documentation—
**Answer:** The web wizard does not offer a "Print to PDF" button. Best practice is to take a screenshot of the Step 5 Review screen and archive it in your project repository as part of the formal System Architecture Document (SAD) sign-off.

---

## 🔗 Navigation

| Direction | Document |
|-----------|----------|
| **After Creation →** | [Post-Creation Settings](../../04_Post_Creation_Governance_and_Administration/01_Application_Settings_and_Immutability_Matrix.md) |
| **← Previous** | [Step 4: Currency Configuration](./05_Step4_Currency_Configuration.md) |
| **← Back to Index** | [Master Index](../../00_MASTER_INDEX.md) |

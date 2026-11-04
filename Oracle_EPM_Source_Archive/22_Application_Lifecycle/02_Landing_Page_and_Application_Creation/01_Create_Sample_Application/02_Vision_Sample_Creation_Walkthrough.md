﻿# 📦 Vision Sample Application — Step-by-Step Creation
## Every Screen, Every Click, Every Button

> **Navigation:** `Planning Landing Page → CREATE button`  
> **Total Steps:** 2–3 (mostly automated)  
> **Time Required:** 5–15 minutes  

---

## Step 1: Click the CREATE Button

### Screen: Planning Landing Page
**Location of Button:** Left column, below "Create a sample application" heading

| Element | Details |
|---------|---------|
| **Button Label** | CREATE |
| **Button Style** | Black background, white text, rectangular |
| **Button Size** | ~120px wide × 35px tall |
| **Hover Effect** | Slight color change to dark gray |
| **Cursor** | Changes to pointer (hand) on hover |

**Action:** Click the **[CREATE]** button

---

## Step 2: Confirmation Dialog (if applicable)

### Screen: Confirmation Popup
In some Oracle Cloud EPM versions, a confirmation dialog appears:

```
┌────────────────────────────────────────────┐
│          Create Sample Application          │
│                                             │
│  Are you sure you want to create the        │
│  Vision sample application—                 │
│                                             │
│  This will create a fully configured        │
│  Planning application with sample data      │
│  and artifacts.                             │
│                                             │
│  ⚠️ This action cannot be undone.           │
│                                             │
│         [Cancel]        [OK / Create]       │
└────────────────────────────────────────────┘
```

| Button | Action |
|--------|--------|
| **Cancel** | Returns to the Planning Landing Page, no changes made |
| **OK / Create** | Begins the sample application creation process |

**Action:** Click **[OK]** or **[Create]** to proceed

---

## Step 3: Application Creation Progress

### Screen: Processing / Progress Indicator
After confirming, the system displays a progress indicator:

```
┌────────────────────────────────────────────┐
│          Creating Application...            │
│                                             │
│  ████████████░░░░░░░░░░░░░  45%            │
│                                             │
│  Creating dimensions...                     │
│  Loading metadata...                        │
│  Importing sample data...                   │
│  Building forms and rules...                │
│                                             │
│  Please wait. This may take several minutes │
└────────────────────────────────────────────┘
```

### What the System Does During Creation:
| # | Process | Duration | Description |
|---|---------|----------|-------------|
| 1 | Initialize Application | ~30 sec | Creates the application container and database |
| 2 | Create Dimensions | ~1 min | Builds all dimension hierarchies (Account, Entity, etc.) |
| 3 | Load Metadata | ~2 min | Imports member properties, aliases, formulas |
| 4 | Import Data | ~3 min | Loads sample financial data across all intersections |
| 5 | Build Forms | ~1 min | Creates all pre-configured data entry forms |
| 6 | Deploy Rules | ~1 min | Imports and deploys Calc Manager business rules |
| 7 | Create Reports | ~1 min | Sets up dashboards and Financial Reports |
| 8 | Configure Security | ~30 sec | Applies default security and access permissions |
| 9 | Build Task Lists | ~30 sec | Creates workflow task lists |
| 10 | Database Refresh | ~2 min | Final database refresh and index rebuild |

> [!NOTE]
> During this process, do **NOT** close the browser, navigate away, or refresh the page. The process runs server-side but the UI needs to remain active to receive the completion notification.

---

## Step 4: Completion — Redirect to Home Page

### Screen: Application Home Page
Once creation completes, you are automatically redirected to the **EPM Application Home Page**:

```
┌──────────────────────────────────────────────────────────────┐
│  ORACLE  EPM Cloud                          👤 Demo Adams ▼  │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Welcome, Demo Adams                                          │
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ 📊       │  │ 📋       │  │ 📈       │  │ ⚙️       │     │
│  │ Data     │  │ Forms    │  │ Reports  │  │ Settings │     │
│  │          │  │          │  │          │  │          │     │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘     │
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ 📁       │  │ 🔧       │  │ 📊       │  │ 📋       │     │
│  │ Rules    │  │ Tools    │  │ Dashbrd  │  │ Tasks    │     │
│  │          │  │          │  │          │  │          │     │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘     │
│                                                               │
│  Recent Activity:                                             │
│  • Application "Vision" created successfully                  │
│  • Database refresh completed                                 │
└──────────────────────────────────────────────────────────────┘
```

---

## ✅ Verification Checklist

After the Vision sample application is created, verify the following:

| # | Check | How to Verify | Expected Result |
|---|-------|---------------|-----------------|
| 1 | Application exists | Navigate → Application → Overview | "Vision" application listed |
| 2 | Dimensions populated | Navigate → Application → Overview → Dimensions | All dimensions visible with members |
| 3 | Forms created | Navigate → Navigator → Forms | Multiple pre-built forms listed |
| 4 | Rules deployed | Navigate → Navigator → Rules | Business rules visible in Calc Manager |
| 5 | Data loaded | Open any form → check cells | Sample data values present |
| 6 | Reports available | Navigate → Reports | Financial Reports and dashboards exist |
| 7 | Task Lists created | Navigate → Task Lists | Pre-configured task lists visible |

---

## ❌ Common Issues During Creation

| Issue | Cause | Resolution |
|-------|-------|------------|
| Creation hangs at 0% | Network timeout | Refresh browser, check Jobs console |
| Error: "Insufficient privileges" | Wrong role assigned | Ensure Service Administrator role |
| Creation fails midway | System resource issue | Wait 30 min, try Remove & Recreate |
| Page shows blank after creation | Browser cache issue | Clear cache and re-login |
| "Application already exists" | Previous attempt succeeded | Navigate to Home page directly |

---

## 🔗 Next Steps

| Document | Description |
|----------|-------------|
| [Vision Sample Contents](./03_Vision_Sample_Contents_and_Artifacts.md) | Detailed list of everything in the Vision sample |
| [Post-Creation Walkthrough](./04_Post_Sample_Creation_Walkthrough.md) | Exploring and using the Vision application |
| ← [Back to Overview](./01_Sample_Application_Overview.md) | Return to Sample Application overview |

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: What happens if the network connection drops while the creation progress bar displays 45%—
**Answer:** The creation process continues uninterrupted on Oracle Cloud's backend Kubernetes cluster. The browser progress bar is merely a client-side listener polling a server-side status API. If your network disconnects, simply wait 10 minutes, reconnect, and navigate to the application URL. You will be redirected to the fully provisioned Vision Home Page.

### Q2: Why does Vision sample creation take 10"15 minutes while a clean wizard application takes under 3 minutes—
**Answer:** A clean wizard application provisions an empty Essbase outline and metadata container. The Vision sample application, by contrast, loads thousands of historical transactional data records, compiles dozens of Calc Manager business rules, deploys dashboards, imports financial reports, and restructures database indexes across multiple cubes.

### Q3: Can you automate the creation of the Vision sample application via EPM Automate CLI without opening a browser—
**Answer:** No. EPM Automate does not offer a standalone createSampleApplication command. To automate environment setup without the UI, export a baseline snapshot of Vision once (Vision_Baseline.zip), and use epmautomate importSnapshot "Vision_Baseline" in automated test pipelines.

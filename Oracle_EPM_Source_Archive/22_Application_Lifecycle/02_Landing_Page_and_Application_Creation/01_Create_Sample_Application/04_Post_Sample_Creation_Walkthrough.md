# 📦 Vision Sample Application — Post-Creation Walkthrough
## Exploring Your New Vision Application

> **Prerequisite:** Vision sample application has been successfully created  
> **Starting Point:** EPM Application Home Page  
> **Goal:** Explore every area of the newly created application

---

## 🏠 Home Page — First Screen After Creation

After the Vision application is created, you land on the **EPM Home Page**. This is your central hub.

### Home Page Cards (Navigation Tiles)

| # | Card | Icon | Description | Click To... |
|---|------|------|-------------|-------------|
| 1 | **Home** | 🏠 | Return to this page | Return to main navigation |
| 2 | **Data** | 📊 | Data entry and forms | Open data forms for input |
| 3 | **Dashboards** | 📈 | Visual dashboards | View pre-built dashboards |
| 4 | **Infolets** | ℹ️ | Quick information panels | View summary KPI panels |
| 5 | **Reports** | 📋 | Financial Reports | Run and view reports |
| 6 | **Rules** | 🧮 | Business Rules | View/run calculation rules |
| 7 | **Approvals** | ✅ | Approval workflows | Manage planning unit approvals |
| 8 | **Academy** | 🎓 | Help and tutorials | Access learning resources |
| 9 | **Application** | ⚙️ | Application settings | Configure application (Admin) |
| 10 | **Tools** | 🔧 | System tools | Access Migration, Jobs, etc. |

---

## 📊 Exploring Data / Forms

### Navigation: `Home → Data`

1. Click the **Data** card on the Home page
2. The Forms panel opens on the left side
3. Expand the form folders to see all available forms
4. Click on any form to open it for data entry

### Key Actions Available on Forms:
| Action | Location | Description |
|--------|----------|-------------|
| **Save** | Toolbar | Save entered data |
| **Refresh** | Toolbar | Refresh form data from database |
| **Business Rules** | Toolbar menu | Launch associated business rules |
| **Supporting Detail** | Right-click cell | Add line-item detail |
| **Cell Comments** | Right-click cell | Add notes/comments to cells |
| **Lock/Unlock** | Right-click cell | Lock cells from editing |
| **Adjust** | Right-click cell | Adjust values by amount or % |
| **Grid Spread** | Right-click cell | Spread values across periods |
| **Mass Allocate** | Right-click cell | Allocate values using patterns |

---

## 📈 Exploring Dashboards

### Navigation: `Home → Dashboards`

1. Click the **Dashboards** card
2. Select a dashboard from the list
3. Interactive charts and graphs display financial data

### Dashboard Interactivity:
| Feature | Description |
|---------|-------------|
| **Drill-down** | Click on chart elements to drill into details |
| **POV Selection** | Change Point-of-View (Entity, Scenario, Year) |
| **Export** | Export dashboard to PDF or image |
| **Refresh** | Refresh underlying data |

---

## ⚙️ Exploring Application Settings

### Navigation: `Home → Application`

This opens the Application administration area:

| Tab | Description | Key Contents |
|-----|-------------|-------------|
| **Overview** | Application summary | App name, type, cubes, dimensions |
| **Dimensions** | Dimension editor | View/edit all dimensions and members |
| **Configure** | Module configuration | Enable features, configure modules |
| **Settings** | Application settings | System preferences, defaults |
| **Variables** | Substitution variables | User and system variables |

---

## 🔧 Exploring Tools

### Navigation: `Home → Tools`

| Tool | Description |
|------|-------------|
| **Migration** | Export/Import snapshots |
| **Jobs** | View running and completed jobs |
| **Audit** | View audit trail |
| **Access Control** | Manage users, roles, permissions |
| **Daily Maintenance** | Schedule maintenance windows |
| **Cloud Scheduler** | Schedule automated jobs |

---

## ✅ Recommended Exploration Path

| Step | Action | Purpose |
|------|--------|---------|
| 1 | Open a Revenue form | See how data entry works |
| 2 | Enter some test values | Practice data input |
| 3 | Run a business rule | See calculations in action |
| 4 | View a dashboard | See data visualization |
| 5 | Open Application → Dimensions | Understand dimension structure |
| 6 | Check Tools → Jobs | See job history |
| 7 | Run a Financial Report | See formatted reporting |

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: What is the first diagnostic step an administrator should execute immediately after Vision creation finishes?
**Answer:** Navigate to Application â†’ Jobs (Job Console). Verify that the Create Database, Cube Refresh, and Metadata Load background jobs all display a status of **Completed** with zero fatal exceptions. If any job shows errors, the database outline may require a manual Refresh Database.

### Q2: How can an administrator quickly verify that sample data loaded properly across all scenarios?
**Answer:** Open Smart View or navigate to Data â†’ Revenue Planning â†’ Revenue Overview. Change the POV to Scenario: Actual, Year: FY24, Version: Working. Cells should populate with formatted financial numbers. If cells display #MISSING, run the pre-built Calculate Revenue business rule from the Actions menu.

### Q3: If a tester modifies formulas or data in Vision and breaks the calculation engine, what is the fastest way to reset?
**Answer:** Execute a reset and recreation:
`cmd
epmautomate login admin@company.com "C:\EPM\pass.epw" "https://epm.oraclecloud.com"
epmautomate recreate -f
`
Once reset to the Landing Page, click **CREATE** again. Within 10 minutes, a factory-fresh Vision instance is restored.

---

## 🔗 Navigation

| Document | Description |
|----------|-------------|
| ← [Vision Contents](./03_Vision_Sample_Contents_and_Artifacts.md) | What's included in Vision |
| ← [Creation Steps](./02_Vision_Sample_Creation_Walkthrough.md) | How Vision was created |
| ← [Back to Master Index](../../00_MASTER_INDEX.md) | Return to main index |

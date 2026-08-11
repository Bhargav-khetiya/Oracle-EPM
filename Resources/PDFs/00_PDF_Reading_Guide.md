# 📚 Oracle Official Documentation — Reading Guide & Index

> **38 Oracle PDFs** organized by learning level  
> **Purpose:** Map each PDF to the module it enriches + reading order

---

## Level 1: Beginner — Start Here (6 PDFs)

Read these FIRST. They establish your EPM Cloud foundation.

| # | PDF | Pages | Maps To Module | Priority |
|---|-----|-------|----------------|----------|
| 1.1 | **Getting_Started_Guide_for_Users.pdf** | ~50 | 00_Foundation, 04_Forms | 🔴 Read First |
| 1.2 | **Getting_Started_Guide_for_Administrators.pdf** | ~400 | 00_Foundation, 16_Administration, 12_Security | 🔴 Read First |
| 1.3 | **Design_Best_Practices.pdf** | ~200 | 15_Performance, 10_Metadata, 02_Essbase | 🔴 Read First |
| 1.4 | **Creating_and_Running_an_EPM_Center_of_Excellence.pdf** | ~300 | 19_Projects, 18_Production_Support | 🟡 Read Early |
| 1.5 | **Licensing_Guide.pdf** | ~20 | 00_Foundation | 🟢 Reference |
| 1.6 | **Accessibility_Guide.pdf** | ~30 | Reference | 🟢 Reference |

### 🎯 Hands-On After Level 1
- [ ] Login to EPM Cloud and explore the Springboard
- [ ] Identify which clusters appear (Application, Tools, Reports)
- [ ] Navigate to Settings → check your user role
- [ ] Open Navigator → explore all menu items

---

## Level 2: Daily Usage (10 PDFs)

The tools you'll use every single day as a consultant.

| # | PDF | Pages | Maps To Module | Priority |
|---|-----|-------|----------------|----------|
| 2.1 | **Working_with_Planning.pdf** | ~400 | 03_Planning, 04_Forms, 10_Metadata | 🔴 Essential |
| 2.2 | **Working_with_Oracle_Smart_View_for_Office_26.100.pdf** | ~1200 | 09_Smart_View | 🔴 Essential |
| 2.3 | **Working_with_Planning_Modules.pdf** | ~50 | 03_Planning (OOTB modules) | 🟡 Important |
| 2.4 | **Working_with_Reports.pdf** | ~150 | Reference (EPM Reports) | 🟡 Important |
| 2.5 | **Working_with_Financial_Reporting.pdf** | ~50 | Reference (FR Reports) | 🟢 Later |
| 2.6 | **Working_with_Oracle_Smart_View_for_Office_(Mac_and_Browser).pdf** | ~200 | 09_Smart_View | 🟢 Reference |
| 2.7 | **Getting_Started_with_Oracle_Smart_View_for_Google_Workspace.pdf** | ~30 | 09_Smart_View | 🟢 Reference |
| 2.8 | **Working_with_Predictive_Planning_in_Smart_View.pdf** | ~40 | 09_Smart_View (advanced) | 🟢 Later |
| 2.9 | **Working_with_Strategic_Modeling_in_Smart_View.pdf** | ~40 | Reference | 🟢 Later |

### 🎯 Hands-On After Level 2
- [ ] Open a form in Smart View → enter data → submit
- [ ] Run ad-hoc analysis → zoom in/out → pivot → keep only
- [ ] Use Member Selection dialog → select IChildren, IDescendants
- [ ] Write 5 HsGetValue formulas in Excel
- [ ] Create a free-form report pulling data from 3 entities
- [ ] Open a Flex Form → sort data → add an Excel formula → submit

---

## Level 3: Build & Design (9 PDFs)

What you need to BUILD applications — forms, rules, reports.

| # | PDF | Pages | Maps To Module | Priority |
|---|-----|-------|----------------|----------|
| 3.1 | **Administering_Planning.pdf** | ~1200 | 03_Planning, 04_Forms, 10_Metadata, 12_Security | 🔴 THE Bible |
| 3.2 | **Administering_Planning_Modules.pdf** | ~350 | 03_Planning (Workforce, Capital, Projects) | 🟡 Important |
| 3.3 | **Designing_with_Calculation_Manager.pdf** | ~150 | 07_Calculation_Manager, 06_Business_Rules | 🔴 Essential |
| 3.4 | **Administering_Access_Control.pdf** | ~30 | 12_Security | 🟡 Important |
| 3.5 | **Designing_with_Reports.pdf** | ~1500 | Reference (EPM Reports design) | 🟡 Important |
| 3.6 | **Designing_with_Financial_Reporting_Web_Studio.pdf** | ~200 | Reference (FR Web Studio) | 🟢 Later |
| 3.7 | **Deploying_and_Administering_Oracle_Smart_View.pdf** | ~80 | 09_Smart_View (admin) | 🟢 Reference |
| 3.8 | **Developing_Applications_for_Oracle_Smart_View.pdf** | ~50 | 09_Smart_View (dev) | 🟢 Reference |
| 3.9 | **Cloud_EPM_System_Reporting_Schema_Reference_Guide.pdf** | ~10 | Reference | 🟢 Reference |

### 🎯 Hands-On After Level 3
- [ ] Create a Freeform application from scratch
- [ ] Build Account dimension with 20+ members (hierarchical)
- [ ] Build Entity dimension with 5+ entities
- [ ] Create 3 forms: Revenue Input, Expense Input, P&L Summary
- [ ] Create a Composite Form combining Revenue + Expenses
- [ ] Write 5 business rules in Calc Manager (see patterns below)
- [ ] Create a Rule Set with 3 rules in sequence
- [ ] Set up data access security for 2 user groups
- [ ] Create a Task List with 5 steps

---

## Level 4: Integration & Automation (8 PDFs)

Connecting EPM to outside systems and automating everything.

| # | PDF | Pages | Maps To Module | Priority |
|---|-----|-------|----------------|----------|
| 4.1 | **Administering_Data_Integration.pdf** | ~1100 | 11_Data_Integration | 🔴 Essential |
| 4.2 | **Administering_Data_Management.pdf** | ~600 | 11_Data_Integration (FDMEE) | 🔴 Essential |
| 4.3 | **Working_with_EPM_Automate.pdf** | ~100 | 14_EPM_Automate | 🔴 Essential |
| 4.4 | **REST_APIs.pdf** | ~150 | 13_REST_API | 🟡 Important |
| 4.5 | **Operations_Guide.pdf** | ~300 | 18_Production_Support, 16_Administration | 🟡 Important |
| 4.6 | **Administering_Migration.pdf** | ~30 | 16_Administration (LCM) | 🟡 Important |
| 4.7 | **Getting_Started_with_Integration.pdf** | ~30 | 11_Data_Integration | 🟢 Quick Read |
| 4.8 | **Getting_Started_with_the_Digital_Assistant.pdf** | ~200 | Reference (Chatbot) | 🟢 Later |

### 🎯 Hands-On After Level 4
- [ ] Create a CSV data file with proper format
- [ ] Upload file and load data via Data Management
- [ ] Set up mapping rules (source → target)
- [ ] Write an EPM Automate batch script (login → upload → import → calc → logout)
- [ ] Create encrypted password file
- [ ] Schedule a script via Windows Task Scheduler
- [ ] Call a REST API endpoint using PowerShell or Postman
- [ ] Export and import a snapshot (backup/restore)

---

## Level 5: Advanced & Specialized (5 PDFs)

Specialized modules — read when needed for specific projects.

| # | PDF | Pages | Maps To Module | Priority |
|---|-----|-------|----------------|----------|
| 5.1 | **Administering_Sales_Planning.pdf** | ~50 | Reference (Sales module) | 🟢 When needed |
| 5.2 | **Working_with_Sales_Planning.pdf** | ~50 | Reference (Sales module) | 🟢 When needed |
| 5.3 | **Administering_and_Working_with_Strategic_Workforce_Planning.pdf** | ~70 | Reference (Workforce) | 🟢 When needed |
| 5.4 | **Administering_Predictive_Cash_Forecasting.pdf** | ~60 | Reference (Cash) | 🟢 When needed |
| 5.5 | **Working_with_Predictive_Cash_Forecasting.pdf** | ~50 | Reference (Cash) | 🟢 When needed |

### 🎯 Hands-On After Level 5
- [ ] Configure a Sales Planning module
- [ ] Set up Workforce Planning with headcount drivers
- [ ] Explore Predictive Cash Forecasting features

---

## 📖 Recommended Reading Order (30-Day Plan)

| Week | What to Read | What to Practice |
|------|-------------|-----------------|
| **Week 1** | Level 1 (all 6) + Working_with_Planning | Login, navigate, explore Springboard |
| **Week 2** | Smart View PDF + Designing_with_Calc_Manager | Smart View ad-hoc, write first rule |
| **Week 3** | Administering_Planning (first 400 pages) | Build full app with forms and rules |
| **Week 4** | Data Integration + EPM Automate + REST API | Load data, automate, write scripts |

---

## 👑 Complete Markdown Companion Editions (`Level 100`)

Every single one of the **38 Oracle Official PDFs** listed above now has an exact, exhaustive **Markdown Companion Edition (`.md`)** located right next to the original `.pdf` file inside its respective `Level_*` folder!

Why? Because instead of forcing you to read massive binary PDFs, we have:
1. **Extracted every core architectural concept, setting, table, and best practice** from all 38 PDFs into structured Markdown books.
2. **Mapped and cross-referenced** every individual PDF directly into our **27 Course Modules (`00_Foundation` through `24_Architect_Masterclass`)**.
3. **Unlocked immediate text searchability (`grep` / IDE search)** across every single page and table of Oracle documentation!

### How to Access the Markdown Editions
Navigate to any folder under `Resources/PDFs/`:
- `Level_1_Beginner_Start_Here/` $\rightarrow$ contains `Accessibility_Guide.md`, `Design_Best_Practices.md`, etc.
- `Level_2_Daily_Usage/` $\rightarrow$ contains `Working_with_Planning.md`, `Working_with_Oracle_Smart_View_for_Office_26.100.md`, etc.
- `Level_3_Build_and_Design/` $\rightarrow$ contains `Administering_Planning.md`, `Designing_with_Calculation_Manager.md`, etc.
- `Level_4_Integration_and_Automation/` $\rightarrow$ contains `Administering_Data_Integration.md`, `REST_APIs.md`, etc.
- `Level_5_Advanced_and_Specialized/` $\rightarrow$ contains `Administering_Sales_Planning.md`, `Working_with_Predictive_Cash_Forecasting.md`, etc.

# 07 Twisted Interview Questions — Part 4: EPBCS Modules, Security & Administration

## Master Review Survival Guide: 30 Wicked Modules & Security Trap Questions

---

### Q1: Can you disable an EPBCS module feature once it has been enabled?
**Answer**:
**NO**. In Oracle EPM Cloud, once a module feature (e.g., Expense Driver-Based Planning, Balance Sheet, or Workforce Headcount) is enabled, it **CANNOT be disabled**. It permanently writes dimensions, accounts, web forms, and calculation rules into the relational repository. You must design the enable matrix carefully during functional workshops.

---

### Q2: What happens if you enable Workforce with "Job Only" and later the client demands named employee tracking?
**Answer**:
You **CANNOT** switch from Job Only to Employee & Job in an existing application! You would have to **delete and recreate the application** or build a massive custom dimensional workaround. As an architect, always advise clients: *"If there is any chance you will need named employee planning in the future, enable Employee and Job on Day 1."*

---

### Q3: How does Financials ensure Balance Sheet equality ($\text{Assets} = \text{Liabilities} + \text{Equity}$)?
**Answer**:
Financials utilizes a seeded balancing clearing account, typically **`Retained Earnings Current Year`** (which automatically receives calculated Net Income from the P&L) and an automated **`Cash / Short-Term Debt Plug`**. If assets exceed liabilities and equity, the plug borrows short-term debt; if liabilities and equity exceed assets, the surplus is deposited into Cash.

---

### Q4: Is Strategic Modeling an Essbase cube?
**Answer**:
**NO**. This is a classic interview trap! Strategic Modeling is built on the acquired Hyperion Strategic Finance (HSF) engine, which uses an in-memory financial statement model file architecture rather than a multidimensional Essbase cube. It is accessed through the EPM Cloud Web UI and Smart View, but its underlying calculation mechanics are distinct from Essbase BSO/ASO.

---

### Q5: How does Capital handle Construction in Progress (CIP) assets?
**Answer**:
A CIP asset represents a long-term capital construction project (e.g., building a new factory). While under construction, costs accumulate in CIP with **Depreciation = None**. Once construction finishes, the user triggers the **"In-Service / Capitalize Asset"** business rule, which transfers total accumulated costs from CIP to `Buildings` and starts the monthly depreciation clock!

---

### Q6: What happens when an asset is Retired or Disposed of before its useful life ends?
**Answer**:
The user right-clicks the asset and selects **Retire Asset**, entering the Retirement Date and Selling Price (Cash Proceeds). The `Retire Asset` rule:
1. Calculates remaining Net Book Value (NBV = Original Cost - Accumulated Depreciation).
2. Computes **Gain / Loss on Disposal**: $\text{Gain/Loss} = \text{Selling Price} - \text{NBV}$.
3. Zeroes out the asset cost and accumulated depreciation from the Balance Sheet.
4. Pushes the Gain/Loss to the Income Statement and cash proceeds to the Cash Flow statement.

---

### Q7: If a user is assigned to two groups with conflicting permissions on an Entity (Group A = Read, Group B = Write), what access does the user have?
**Answer**:
The user has **Write Access**. In Oracle EPM Cloud, **Write takes precedence over Read**. 
* **The Critical Exception**: **`None` (No Access) takes precedence over EVERYTHING**. If Group C assigns `None`, the user has zero access, even if Group B assigns Write.

---

### Q8: How do Valid Intersections prevent empty block creation in BSO cubes?
**Answer**:
Valid Intersections establish cross-dimensional rules (e.g., `Marketing Department` is ONLY valid with `Advertising Expense` accounts). If a user attempts to enter data at an invalid intersection on a web form or Smart View, the cell is locked and rendered read-only. This prevents users from instantiating meaningless sparse blocks on disk, saving gigabytes of database cache.

---

### Q9: What happens during the Daily Maintenance Window?
**Answer**:
1. The cloud infrastructure initiates an automated 1-hour maintenance sequence (e.g., 02:00 - 03:00 UTC).
2. Generates an automated daily Lifecycle Management (LCM) snapshot (**Artifact Snapshot**) containing all metadata, security, forms, rules, and data.
3. Applies rolling Oracle Cloud patches and OS security updates.
4. Executes internal database index defragmentation and restructures.
5. Reboots the cloud pod service containers to flush memory leaks.

---

### Q10: How do you restore an application if a bad metadata load corrupts the environment?
**Answer**:
Navigate to **Application -> Migration -> Snapshots**. Select yesterday's automated maintenance snapshot (`Artifact Snapshot`), click **Import**, and execute an atomic restore. You can also automate this via EPM Automate: `epmautomate importSnapshot "Artifact Snapshot"`.

---

### Q11: What is the difference between an Internal Project and a Capital Project in `OEP_PFP`?
**Answer**:
* **Internal Project**: Operational initiative (corporate rebranding, IT audit). Costs flow directly into the Financials Income Statement as **Operating Expenses (SG&A)**.
* **Capital Project**: Construction or software development. Costs accumulate under CIP. Upon completion, the `Push to Capital` rule transfers costs to `OEP_CPX` as a capitalized asset.

---

### Q12: How does Strategic Modeling eliminate circular references when modeling debt interest?
**Answer**:
Strategic Modeling utilizes an iterative simultaneous mathematical solver that evaluates balance sheet cash sweeps, revolving credit lines, and interest expense within an internal convergence loop ($10^{-6}$ precision) without throwing circular reference errors.

---

### Q13: What is the difference between Service Administrator and Power User in security?
**Answer**:
* **Service Administrator**: Complete, unconstrained control over the entire cloud instance. Can provision users, edit all artifacts, break concurrency locks, and run maintenance.
* **Power User**: Can create and maintain forms, business rules, and dimensions in assigned cubes, but cannot manage users, assign global roles, or break locks held by other administrators.

---

### Q14: What is the purpose of the `Plan Element` dimension in Financials?
**Answer**:
It decouples financial accounts from calculation drivers. It allows the same account (e.g., `Travel_Expense`) to track `OFS_Direct Input`, `OFS_Driver`, `OFS_Trend`, and `OFS_Calculated` without creating separate accounts in the Account dimension.

---

### Q15: What is the purpose of the `Property` dimension in Workforce?
**Answer**:
Holds employee calculation attributes (`Start Date`, `End Date`, `FTE`, `Pay Type`, `Salary`). Setting `Property` to **Dense** keeps all compensation variables in a single memory block, enabling the calculation engine to compute taxes and benefits in CPU registers at maximum speed.

---

### Q16: How does Workforce calculate Partial Year FTE?
**Answer**:
If an employee starts on July 1st in a 12-month calendar year: Months 1–6 have $\text{FTE} = 0.0$; Months 7–12 have $\text{FTE} = 1.0$. The annual average rolls up to $\frac{6}{12} = \mathbf{0.5 \text{ FTE}}$, preventing corporate reports from exaggerating active staffing.

---

### Q17: What is the difference between an Asset Class and an Asset Detail in Capital?
**Answer**:
* **`Asset Class`**: Parent category defining default accounting policies (useful life, depreciation method).
* **`Asset Detail`**: The specific physical asset instance (e.g., `Forklift_01`) inheriting or overriding defaults.

---

### Q18: What is an Audit Trail in EPM Cloud, and how long is data retained?
**Answer**:
The Audit framework tracks modifications to cell data, metadata hierarchies, and security assignments. Administrators can filter by user ID, date range, and artifact type, and export audit logs to CSV for SOX regulatory compliance. Default retention is typically 180 to 365 days.

---

### Q19: What is the Job Console, and how is it used during troubleshooting?
**Answer**:
The Job Console tracks all asynchronous background operations (Data Maps, Business Rules, Cube Refreshes, LCM Imports). When a job fails, the console displays start/end timestamps, rejected record counts, and the exact error stack trace.

---

### Q20: What is the difference between Standard EPM and Enterprise EPM licensing?
**Answer**:
* **Standard EPM**: Limits customers to 1 business process (Planning, FCCS, or Narrative Reporting) with restricted custom cube counts and no Groovy engine.
* **Enterprise EPM**: Unrestricted access to ALL business processes (Planning, EPBCS Modules, FreeForm, FCCS, Tax, PCM, EDMCS, EPRCS) and full support for the **Groovy Rules Engine**.

---

### Q21: What is the purpose of the Navigation Flow "Reload" action?
**Answer**:
When an administrator modifies a user's Navigation Flow cards or clusters, the user can click their profile icon and select **Reload Navigation Flow** to pull the latest UI layout without logging out.

---

### Q22: What happens if two administrators attempt to deploy rules to the same cube simultaneously?
**Answer**:
The second deployment is blocked with an exclusive lock warning, preventing outline corruption in Essbase.

---

### Q23: How do you handle non-exempt employee overtime planning in Workforce?
**Answer**:
In Workforce configuration, enable **Additional Earnings**. Configure an overtime rate (e.g., $1.5\times$ base hourly rate) driven by entered overtime hours or a percentage of base pay.

---

### Q24: What is the difference between a Task List and the Task Manager?
**Answer**:
* **Task List**: Legacy checklist guiding individual planners through forms and rules.
* **Task Manager**: Modern, enterprise-grade financial close workflow engine with automated dependency tracking, approval sign-offs, and compliance dashboards.

---

### Q25: How do you restrict end users from accessing an application during maintenance?
**Answer**:
In **Application -> Settings**, set **"Enable Use of the Application for"** to **"Service Administrators Only"**. Non-admin users attempting to log in will receive a system maintenance message.

---

### Q26: What is the purpose of the `BegBalance` time period member?
**Answer**:
`BegBalance` (Beginning Balance) is an out-of-the-box member in the `Period` dimension used to store opening balances, initial asset acquisition costs, and balance sheet carry-forwards before Month 1.

---

### Q27: How does EPBCS handle multi-GAAP reporting in Financials?
**Answer**:
By enabling the **Multi-GAAP** dimension during application configuration. It creates members for `Local GAAP`, `IFRS`, and `GAAP Adjustments`, allowing dual statutory and corporate reporting.

---

### Q28: Can you migrate a single business rule from Test to Production without migrating the whole application?
**Answer**:
**Yes**. In **Application -> Migration -> Artifact List**, expand `Calculation Manager -> Applications -> [AppName] -> Rules`, select the specific rule checkbox, and export an isolated LCM snapshot ZIP.

---

### Q29: What happens if an outline member is deleted while data still exists on it?
**Answer**:
During the next database refresh, Essbase executes a database restructure. The deleted member coordinate is unlinked from the index, and all physical data associated with that member is **permanently purged from storage**!

---

### Q30: What is the primary role of Enterprise Data Management (EDMCS) in relation to EPM Cloud?
**Answer**:
EDMCS is the centralized master data governance hub. It manages Chart of Accounts, Cost Centers, and Legal Entities across Oracle Fusion ERP, EPM Cloud, SAP, and Salesforce, enforcing approval workflows before publishing metadata updates to EPM applications.


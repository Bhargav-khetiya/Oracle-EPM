# 04 — Business Rules, Calculations, & Governance

---

## 4.1 Automating Business Rules and Calculations

Calculations in Oracle EPM Planning (Essbase BSO and Calc Manager rules) are executed via EPM Automate to perform night-end aggregations, driver-based allocations, currency translations, and balance sheet rollovers.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        CALCULATION COMMAND MATRIX                      │
├────────────────────┬───────────────────────────────────────────────────┤
│ runBusinessRule    │ Executes a single Calc Manager / Essbase rule     │
│ runRuleSet         │ Executes an ordered sequence of business rules    │
│ runJob             │ Universal job executor (Rules, Refreshes, Exports)│
└────────────────────┴───────────────────────────────────────────────────┘
```

---

## 4.2 Passing Runtime Prompts (RTP) in `runBusinessRule`

Most enterprise calculation rules require input coordinates (e.g., Scenario, Version, Entity, Years). EPM Automate allows passing these as command-line arguments:

```cmd
epmautomate runBusinessRule <Rule_Name> [Prompt_Name=Prompt_Value] ...
```

### 4.2.1 Single-Member Prompts:
```cmd
epmautomate runBusinessRule "Catering Revenue calculation" "Entity=E10002" "Scenario=Budget" "Version=Working" "Years=FY26"
```

### 4.2.2 Multi-Member Prompts (Quoting Syntax):
When an RTP accepts multiple members, wrap the members in escaped quotes:
```cmd
epmautomate runBusinessRule "Aggregate_Full_Account_Bhargav" "Entity=\"E10001\",\"E10002\"" "Years=FY26"
```

### 4.2.3 Executing Rule Sets:
To execute a sequential calculation chain (e.g., Clear $\rightarrow$ Calculate Revenues $\rightarrow$ Calculate Expenses $\rightarrow$ Aggregate):
```cmd
epmautomate runRuleSet "Nightly_Financial_Calc_RuleSet" "Scenario=Budget" "Version=Working"
```

---

## 4.3 Universal Job Management: `runJob`

The **`runJob`** command provides a unified framework to launch any job defined in the Planning Job Console:

```cmd
epmautomate runJob <Job_Type> <Job_Name> [Parameters]
```

### Supported Job Types:
* **`RULES`**: Launches a single business rule.
* **`RULESET`**: Launches a rule set.
* **`CUBE_REFRESH`**: Executes an Essbase database refresh.
* **`CLEAR_CUBE`**: Executes a physical data clear.
* **`IMPORT_DATA`** / **`EXPORT_DATA`**: Data file loading and extraction.
* **`IMPORT_METADATA`** / **`EXPORT_METADATA`**: Hierarchy builds.

---

## 4.4 User Governance & Security Auditing

EPM Automate includes native security automation commands to satisfy Sarbanes-Oxley (SOX) compliance and automated employee onboarding:

```cmd
:: 1. Export user directory with security roles to CSV
epmautomate exportUsers "Active_Users_Audit_2026.csv"

:: 2. Generate detailed dimension-level access control report
epmautomate userAccessReport "User_Dimensional_Security_Report.csv"

:: 3. Generate system audit trail of all logins and data modifications
epmautomate userAuditReport "2026-10-01" "2026-10-27" "Audit_Report_Oct2026.csv"

:: 4. Programmatically assign roles to a newly hired analyst
epmautomate assignRole "jsmith@orbrick.com" "Planner"
```

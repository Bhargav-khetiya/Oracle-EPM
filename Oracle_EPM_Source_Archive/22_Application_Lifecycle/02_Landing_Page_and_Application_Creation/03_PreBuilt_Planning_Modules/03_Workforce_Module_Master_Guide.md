﻿# 👥 Workforce Module — Complete Setup Guide
## Headcount, Compensation, Benefits & Labor Cost Planning

> **Module:** Workforce  
> **Cube:** OEP_WFP (BSO Hybrid) + OEP_REP (ASO Shared)  
> **Subscription:** Standard + Enterprise  
> **Integration:** Financials (labor expense), Projects (resource allocation)

---

## 🎯 What Workforce Module Provides

| Area | Description |
|------|-------------|
| **Headcount Planning** | Plan current and future employee/position counts by department |
| **Compensation Planning** | Salary, merit increases, bonus, incentive planning |
| **Benefits Planning** | Health insurance, retirement, PTO, other benefits |
| **Tax Planning** | Employer-side payroll taxes by jurisdiction |
| **New Hire Planning** | Planning for new positions and recruitment |
| **Transfer & Termination** | Employee movement, attrition, transfers |
| **Workforce Analytics** | Headcount trends, cost per employee, turnover KPIs |

---

## 🔧 Planning Approach Selection

When enabling Workforce, you choose a planning approach:

### Available Approaches:

| Approach | Description | Best For | Granularity |
|----------|-------------|----------|-------------|
| **Employee-based** | Plan by individual named employee | Small-medium orgs (< 5,000 employees) | Highest — individual level |
| **Position-based** | Plan by position/role code | Medium-large orgs | Medium — position level |
| **Job-based** | Plan by job code with headcount | Large orgs (10,000+ employees) | Lower — aggregate level |
| **Hybrid** | Combination of approaches | Complex organizations | Mixed |

```
┌──────────────────────────────────────────────────────────────────┐
│  Workforce Configuration — Planning Approach                      │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Select your workforce planning approach:                         │
│                                                                   │
│  ○ Employee-based                                                 │
│    Plan by individual named employee. Best for smaller            │
│    organizations that need detailed employee-level planning.      │
│                                                                   │
│  ○ Position-based                                                 │
│    Plan by organizational position. Positions can be filled       │
│    or vacant. Best for medium to large organizations.             │
│                                                                   │
│  ○ Job-based                                                      │
│    Plan by job code with aggregate headcount. Best for very       │
│    large organizations or high-level workforce planning.          │
│                                                                   │
│  ⚠️ This selection cannot be changed after enabling.             │
│                                                                   │
│  [Cancel]  [Next]                                                 │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📋 Enable Features — Workforce

**Navigation:** `Application → Configure → Workforce → Enable Features`

| Feature | Description | Dependencies |
|---------|-------------|-------------|
| **Basic Compensation** | Salary, hourly rate planning | None (core) |
| **Merit & Promotion** | Merit increase, promotion planning | Basic Compensation |
| **Bonus & Incentive** | Bonus, commission, incentive comp | Basic Compensation |
| **Benefits** | Health, dental, vision, life insurance | None |
| **Retirement** | 401k, pension, retirement plans | None |
| **Employer Taxes** | FICA, FUTA, SUI, local taxes | Basic Compensation |
| **Strategic Workforce Planning** | Long-range workforce modeling | Enterprise only |

---

## 🏗️ Dimensions Created by Workforce

| Dimension | Type | Key Members | Description |
|-----------|------|-------------|-------------|
| **Employee** | Custom | (User-defined) | Individual employees or positions |
| **Job** | Custom | (User-defined) | Job codes / role titles |
| **Position** | Custom | (User-defined) | Organizational positions |
| **Component** | Custom | OWP_Salary, OWP_Bonus, OWP_Benefits, OWP_Tax | Compensation components |
| **Property** | Custom | Status, Start Date, End Date, FTE, Grade | Employee properties |

---

## ⚙️ Configuration Tasks

### Task 1: Compensation Defaults

**Navigation:** `Configure → Workforce → Compensation Defaults`

| Setting | Description | Example Values |
|---------|-------------|----------------|
| Default Salary | Base salary for new hires | $50,000 |
| Default FTE | Full-time equivalent | 1.0 |
| Merit Increase % | Default annual merit | 3% |
| Bonus Target % | Default bonus percentage | 10% |
| Benefits Rate % | Benefits as % of salary | 25% |
| Tax Rate % | Employer tax rate | 7.65% (FICA) |

### Task 2: Grade/Step Configuration

| Grade | Min Salary | Mid Salary | Max Salary | Bonus Target |
|-------|-----------|-----------|-----------|-------------|
| Grade 1 | $30,000 | $40,000 | $50,000 | 5% |
| Grade 2 | $45,000 | $55,000 | $65,000 | 8% |
| Grade 3 | $60,000 | $75,000 | $90,000 | 10% |
| Grade 4 | $85,000 | $100,000 | $120,000 | 15% |
| Grade 5 | $110,000 | $140,000 | $175,000 | 20% |

### Task 3: Benefit Plans

| Plan | Type | Employer Cost | Employee Cost | Eligibility |
|------|------|-------------|---------------|-------------|
| Medical — Basic | Health | $500/mo | $150/mo | All FTE ≥ 0.5 |
| Medical — Premium | Health | $800/mo | $250/mo | All FTE ≥ 0.5 |
| Dental | Dental | $50/mo | $20/mo | All FTE ≥ 0.5 |
| Vision | Vision | $25/mo | $10/mo | All FTE ≥ 0.5 |
| 401k Match | Retirement | 4% of salary | N/A | After 1 year |
| Life Insurance | Life | 1x salary | N/A | All employees |

---

## 📝 Pre-Built Forms (Workforce)

| Form | Purpose | Key Inputs |
|------|---------|------------|
| Existing Headcount | View/edit current employees | Name, Grade, Salary, FTE |
| New Hire Planning | Plan new positions | Role, Start Date, Grade, Salary |
| Compensation Review | Merit and promotion planning | Merit %, Promotion, New Salary |
| Transfer & Termination | Employee movement | Transfer Date, Term Date, Reason |
| Benefits Enrollment | Benefits by employee | Plan selections, coverage |
| Workforce Dashboard | KPIs and analytics | Headcount, Cost, Turnover |
| Workforce Expense | Total labor cost by period | Auto-calculated from comp data |

---

## 🧮 Pre-Built Business Rules (Workforce)

| Rule | Description |
|------|-------------|
| OWP_Calculate_Compensation | Calculates total compensation from components |
| OWP_Apply_Merit | Applies merit increases to salaries |
| OWP_Calculate_Benefits | Calculates benefit costs based on enrollment |
| OWP_Calculate_Taxes | Calculates employer payroll taxes |
| OWP_Sync_To_Financials | Pushes labor costs to Financials cube |
| OWP_Headcount_Calc | Calculates headcount aggregations |
| OWP_Annualize | Annualizes partial-year compensation |

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: Why is selecting "Employee-based" versus "Job-based" planning strictly irreversible—
**Answer:** Employee-based planning provisions the Employee dimension and compiles calculation scripts to iterate over individual human records (managing FTE, hire dates, and merit months). Job-based planning omits the Employee dimension entirely, modeling labor at aggregate job code averages. Switching between these structures requires rebuilding the underlying Essbase block matrix and rewriting all compensation calculation rules.

### Q2: How does Workforce calculate compensation for mid-year new hires and terminations—
**Answer:** Workforce utilizes the Property dimension members: Start Date, End Date, and Status (Active, Departed, New Hire). The calculation rule OWP_Calculate_Compensation evaluates the employee's start and end dates against the fiscal calendar. For periods prior to Start Date or following End Date, compensation and tax components evaluate to $0. For the partial start month, the rule applies day-count proration if configured.

### Q3: What happens if a merit increase is applied to an employee whose compensation is set to Grade/Step rather than individual salary—
**Answer:** In Grade/Step modeling, base pay is derived from the centralized Grade/Step matrix table. If an administrator applies a general merit increase rule, the system updates the salary matrix rates across grades rather than altering the individual employee's override property, ensuring pay equity governance across all employees assigned to that grade.

---

## 🔗 Navigation

| Direction | Document |
|-----------|----------|
| **Next →** | [Capital Module](./04_Capital_Module_Master_Guide.md) |
| **← Previous** | [Financials Module](./02_Financials_Module_Master_Guide.md) |
| **← Modules Overview** | [Modules Overview](./01_Modules_Architecture_Overview.md) |

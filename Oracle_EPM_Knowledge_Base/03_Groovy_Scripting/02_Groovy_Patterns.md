# Groovy Advanced Patterns — Complete Guide

> **Section:** 03 — Groovy Scripting  
> **File:** 02 — Advanced Patterns  
> **Difficulty:** Intermediate → Architect  
> **Prerequisites:** [01_Groovy_Overview](./01_Groovy_Overview.md), [01_Calc_Manager_Overview](../05_Calc_Manager_and_Business_Rules/01_Calc_Manager_Overview.md)

---

## Why Advanced Patterns?

Basic Groovy iterates cells on a form. Advanced Groovy does much more:
- Reads from **other cubes** (DataMaps and Grid Builder)
- **Writes data** programmatically (DataGridBuilder)
- Generates and executes **dynamic calc scripts**
- Calls **REST APIs** and sends **emails**
- Orchestrates **multi-step workflows** (validate → calculate → approve → notify)

The key insight: **Groovy for logic, Essbase for math.** Use Groovy to read context, make decisions, and build perfectly scoped calc scripts. Let Essbase execute the heavy computation.

---

## Pattern 1: Reading Form Data

### Read What the User Sees

```groovy
/* Read the POV (Point of View) — what the user selected */
def grid = operation.grid

grid.pov.each { dimName, memberName ->
    println "POV: ${dimName} = ${memberName}"
}

/* Loop through edited cells only */
grid.dataCellIterator().each { cell ->
    if (cell.edited) {
        println "EDITED: ${cell.memberNames} = ${cell.data}"
    }
}
```

### Read Specific Intersections from the Cube

```groovy
/* DataGridDefinitionBuilder = READ from cube */
DataGridDefinitionBuilder builder = new DataGridDefinitionBuilder()
builder.addPov(["Scenario": "Budget", "Version": "Working",
                "Year": "FY26", "Entity": "Hotel India"])
builder.addColumn(["Period": ["Jan", "Feb", "Mar"]])
builder.addRow(["Account": ["Revenue", "Expense", "Net_Income"]])

DataGridDefinition dgd = builder.build()
DataGrid dataGrid = operation.application.getDataGrid(dgd, "Plan1")

dataGrid.dataCellIterator().each { cell ->
    println "${cell.getMemberName("Account")} / ${cell.getMemberName("Period")} = ${cell.data}"
}
```

> [!IMPORTANT]
> `DataGridDefinitionBuilder` is for **reading**. `DataGridBuilder` is for **writing**. Mixing them up is the most common Groovy mistake.

---

## Pattern 2: Writing Data with DataGridBuilder

```groovy
/* DataGridBuilder = WRITE to cube */
DataGridBuilder grid = new DataGridBuilder("Plan1")

grid.addPov("Scenario", "Forecast")
grid.addPov("Version", "Working")
grid.addPov("Year", "FY26")
grid.addPov("Entity", "Hotel India")
grid.addPov("Currency", "INR")

grid.addColumn("Period", "Jan")
grid.addColumn("Period", "Feb")
grid.addColumn("Period", "Mar")

grid.addRow(["Account": "Revenue"], [15000000, 16000000, 17000000])
grid.addRow(["Account": "Expense"], [9000000, 9500000, 10000000])

grid.build(true)  // true = suppress missing values
```

---

## Pattern 3: Dynamic Calc Script Generation

This is the **most powerful Groovy pattern**. Instead of writing one generic calc script that processes all entities, Groovy reads the user's form context and generates a perfectly scoped script.

```groovy
/* Read user selections */
def entity = rtps.RTP_Entity.getEssbaseMemberName()
def scenario = rtps.RTP_Scenario.getEssbaseMemberName()
def currYear = operation.application.getSubstitutionVariable("CurrYear", "Plan1")

/* Build a targeted calc script */
String calcScript = """
SET UPDATECALC OFF;
SET CREATEBLOCKONEQ ON;

FIX("${entity}", "${scenario}", "Working", "${currYear}", @LEVMBRS("Department", 0))
    @CHILDREN("YearTotal")(
        "Revenue" = "Revenue" * (1 + ${rtps.RTP_GrowthRate} / 100);
        "Net_Income" = "Revenue" - "Expense";
    )
ENDFIX

SET CREATEBLOCKONEQ OFF;
"""

/* Execute on Essbase */
operation.planType.essCalcScript = calcScript
operation.planType.execute()
```

**Performance comparison:**

| Approach | Scope | Time |
|----------|-------|------|
| Generic calc script (no FIX on Entity) | All entities | 45 seconds |
| Groovy-generated script (FIX on specific entity) | One entity | 0.5 seconds |

---

## Pattern 4: Data Validation and Vetoing Saves

Groovy rules set as **Before Save** on a form can validate data and prevent bad data from reaching the cube:

```groovy
def hasErrors = false

operation.grid.dataCellIterator().each { cell ->
    if (cell.edited) {
        def account = cell.getMemberName("Account")
        def value = cell.data

        // Revenue must be positive
        if (account == "Revenue" && value < 0) {
            cell.addValidationError(0xFF0000,
                "Revenue cannot be negative! You entered: ${value}")
            hasErrors = true
        }

        // Occupancy Rate must be 0-100
        if (account == "Occupancy_Rate" && (value < 0 || value > 100)) {
            cell.addValidationError(0xFF0000,
                "Occupancy Rate must be between 0 and 100.")
            hasErrors = true
        }

        // Headcount must be whole number
        if (account == "Headcount" && value != Math.floor(value)) {
            cell.addValidationError(0xFFA500,
                "Headcount must be a whole number.")
            hasErrors = true
        }
    }
}

if (hasErrors) {
    throwVetoException("Validation failed. Please fix the highlighted cells.")
}
```

The user sees the cell highlighted in red with the error message. Data is **not** saved to the cube.

---

## Pattern 5: Cross-Cube Data Access (DataMaps)

DataMaps let a Groovy rule read data from a **different cube** than the current form's plan type.

```groovy
/* Reference a pre-configured Data Map */
DataMap wfpMap = operation.dataMap("WFP_to_FinPlan")

/* Use it in cell iteration */
operation.grid.dataCellIterator("Account#Labor_Cost").each { cell ->
    double salary = cell.crossDimCell(wfpMap, "Account#Basic_Salary").data
    double benefits = cell.crossDimCell(wfpMap, "Account#Benefits").data
    cell.data = salary + benefits
}
```

The DataMap must be pre-configured in Navigator → Data Exchange → Data Maps.

---

## Pattern 6: REST API Calls

Groovy rules can call external APIs — fetching exchange rates, posting to Slack, updating dashboards.

```groovy
/* GET request */
def url = new URL("https://api.exchangerate-api.com/v4/latest/USD")
HttpURLConnection conn = (HttpURLConnection) url.openConnection()
conn.setRequestMethod("GET")
conn.setConnectTimeout(5000)   // Always set timeouts
conn.setReadTimeout(10000)

try {
    if (conn.responseCode == 200) {
        def jsonSlurper = new groovy.json.JsonSlurper()
        def rates = jsonSlurper.parseText(conn.inputStream.text)
        double inrRate = rates.rates.INR
        println "USD to INR: ${inrRate}"

        // Write rate to cube
        DataGridBuilder grid = new DataGridBuilder("Plan1")
        grid.addPov("Scenario", "Actual")
        grid.addPov("Version", "Working")
        grid.addPov("Year", "FY26")
        grid.addPov("Entity", "HSP_Rates")
        grid.addColumn("Period", "Jan")
        grid.addRow(["Account": "USD_Rate"], [inrRate])
        grid.build(true)
    }
} catch (Exception e) {
    println "API call failed: ${e.message}"
    // Don't block the rule for non-critical API failures
} finally {
    conn.disconnect()
}
```

### POST Request (Slack Notification)

```groovy
def url = new URL("https://hooks.slack.com/services/YOUR/WEBHOOK/URL")
HttpURLConnection conn = url.openConnection()
conn.setRequestMethod("POST")
conn.setRequestProperty("Content-Type", "application/json")
conn.setDoOutput(true)

def payload = """{"text": "Budget approved for Mumbai Hotel - FY2026"}"""
conn.outputStream.write(payload.getBytes("UTF-8"))
conn.outputStream.flush()

println "Slack notification sent: ${conn.getResponseCode()}"
conn.disconnect()
```

---

## Pattern 7: Email Notifications

```groovy
def emailService = operation.application.getEmailService()

emailService.sendMail(
    "cfo@company.com",
    "Budget Approved: ${entity}",
    "The FY2026 Budget has been approved.\nApproved by: ${operation.user.name}"
)
```

> [!WARNING]
> Always wrap email calls in `try-catch`. If the email service is unavailable, the entire rule fails otherwise.

---

## Pattern 8: Multi-Step Workflow

The most powerful real-world pattern combines validation, calculation, status updates, and notification in a single rule:

```groovy
/* ===== Monthly Close Workflow ===== */

// STEP 1: VALIDATE
def errors = []
operation.grid.dataCellIterator("Account#Room_Revenue").each { cell ->
    if (cell.data < 0) {
        errors << "Negative: ${cell.getMemberName('Entity')}/${cell.getMemberName('Period')}"
    }
}
if (errors.size() > 0) {
    throwVetoException("Validation Failed:\n${errors.join('\n')}")
}

// STEP 2: CALCULATE (embedded calc script for performance)
def calcScript = """
SET LOCKBLOCK ON;
SET CALCPARALLEL 4;
FIX("Budget", "Working", "FY2026", @RELATIVE("All_Hotels", 0))
  "Total_Revenue" = "Room_Revenue" + "FB_Revenue" + "Spa_Revenue";
  "Net_Income" = "Total_Revenue" - "Total_Expenses";
ENDFIX
FIX("Budget", "Working", "FY2026")
  AGG("Entity");
ENDFIX
SET LOCKBLOCK OFF;
"""
operation.application.getEssbaseServer()
    .getApplication(operation.application.getName())
    .getCube("OEP_FS")
    .executeCalcScript(calcScript)

// STEP 3: AUTO-APPROVE (Smart List update)
int approvedCount = 0
operation.grid.dataCellIterator("Account#Budget_Status").each { cell ->
    if (cell.getSmartListValue() == "In Review") {
        double variance = cell.crossDimCell("Account#Variance_Pct").data
        if (Math.abs(variance) <= 5.0) {
            cell.data = 3  // 3 = "Approved" in Smart List
            approvedCount++
        }
    }
}

// STEP 4: NOTIFY
try {
    operation.application.getEmailService().sendMail(
        "cfo@company.com",
        "Budget Processing Report",
        "Auto-approved: ${approvedCount} entities\nTimestamp: ${new Date()}"
    )
} catch (Exception e) {
    println "Email failed: ${e.message}"
}
```

---

## Groovy vs Calc Script — Decision Guide

| Requirement | Best Choice | Why |
|-------------|------------|-----|
| Simple math (A + B = C) | **Calc Script** | Native, 2–4× faster |
| Aggregation (AGG) | **Calc Script** | Not available in Groovy |
| DATACOPY | **Calc Script** | Native command |
| SET commands (LOCKBLOCK, PARALLEL) | **Calc Script** | Not available in Groovy |
| Complex validation with user messages | **Groovy** | `throwVetoException()` |
| Send email | **Groovy** | Only way |
| REST API calls | **Groovy** | Only way |
| Smart List text comparison | **Groovy** | `getSmartListValue()` returns text |
| Cross-cube data access | **Groovy** | DataMap + `crossDimCell()` |
| Math + integration | **Both** | Groovy for logic + embedded calc for math |

**Rule of thumb:** Start with a Calc Script. If you hit a limitation, switch to Groovy (or use the hybrid approach).

---

## Performance Guidelines

| Guideline | Reason |
|-----------|--------|
| Use Groovy to BUILD calc scripts, not DO math | Essbase is 100× faster at math |
| Minimize DataGrid reads | Each read = network round trip |
| Use targeted FIX in generated scripts | Narrow scope = fast execution |
| Batch DataGridBuilder writes to ≤10,000 cells | Larger writes may timeout |
| Always set `connectTimeout` on HTTP calls | Prevents rule hangs |
| Close connections in `try/finally` | Prevents memory leaks |

**Memory limits:** Each Groovy rule runs in the Planning JVM with approximately 50 MB per execution. DataGridBuilder can handle ~500,000 cells before memory issues. [Recommendation]

| Cell Count | Approach |
|-----------|----------|
| < 10,000 | Groovy can handle directly |
| 10,000 – 100,000 | Use Groovy to generate calc scripts |
| > 100,000 | Must use calc scripts (not Groovy) |

---

## Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| Using Groovy to loop through 1M cells | JVM memory crash | Generate a calc script instead |
| Not checking for null | `NullPointerException` | Use `?.` (safe navigation operator) |
| Forgetting `getEssbaseMemberName()` on RTP | Returns object, not string | Always call `.getEssbaseMemberName()` |
| Hard-coding member names | Breaks when members change | Use RTPs and substitution variables |
| Not using `throwVetoException()` for validation | Bad data saves to cube | Always veto on validation failure |
| Writing AGG in Groovy | Impossible | Embed calc script inside Groovy |
| No timeout on HTTP connections | Rule hangs if API is down | Set `connectTimeout` and `readTimeout` |
| Sending email in a loop | 100 emails instead of 1 | Collect data, send 1 summary email |

---

## Quick Recall

1. **What's the difference between DataGridDefinitionBuilder and DataGridBuilder?** → DefinitionBuilder is for READING, GridBuilder is for WRITING.
2. **What does `throwVetoException()` do?** → Prevents the form save and shows an error message to the user.
3. **When should you use embedded calc scripts in Groovy?** → For AGG, DATACOPY, SET commands, and any math-heavy operations.
4. **Why generate dynamic calc scripts instead of hard-coding them?** → Dynamic scripts FIX on exactly the user's context, making them 10–100× faster.
5. **Can Groovy call external APIs?** → Yes, via `HttpURLConnection` with GET/POST requests.

**Teach-back prompt:** Walk a colleague through the hybrid Groovy/calc script pattern: when does Groovy take control, when does it hand off to Essbase, and why?

---

## Source Provenance

| Source | Files |
|--------|-------|
| Claude | `09_Groovy/09.01_Groovy_Basics_and_Architecture.md` (839 lines), `09.06_Groovy_Advanced_Patterns.md`, `09.04_Groovy_REST_API_and_Email.md`, `09.07_Groovy_vs_Calc_Script_Decision.md` |
| ChatGPT | `Calc Manager/Calculations_and_Allocations/06_Groovy_Business_Rules/` (3 files) |
| Gemini | `Calc Manager/Calculations_and_Allocations/06_Groovy_Business_Rules/` (mirrors ChatGPT) |
| Oracle | [EPM Cloud Groovy Rules](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/groov/) |


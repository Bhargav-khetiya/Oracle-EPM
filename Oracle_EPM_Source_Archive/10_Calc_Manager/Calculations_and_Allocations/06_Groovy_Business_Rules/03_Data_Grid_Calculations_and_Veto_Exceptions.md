# 03 In-Memory Grid Calculations, Data Validation, and Veto Exceptions

## 1. The Pre-Save Validation Paradigm

In financial budgeting systems, allowing users to submit mathematically invalid, out-of-policy, or logically corrupt numbers creates downstream chaos (e.g., entering negative capital expenditures, requesting headcount increases exceeding departmental budget caps, or projecting gross margins below zero).

Traditionally, data was saved first, a calculation script ran, and an administrator audited exceptions days later. **Groovy In-Memory Validations** shift this paradigm to the point of entry: **Pre-Save Interception**.

```
+---------------------------------------------------------------------------------------------------+
|                                  GROOVY PRE-SAVE VETO INTERCEPT                                   |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [USER ENTERS DATA ON FORM & CLICKS SAVE]                                                         |
|  - Enters Capex Request = $2,500,000                                                              |
|         |                                                                                         |
|         v                                                                                         |
|  [GROOVY "RUN BEFORE SAVE" INTERCEPT]                                                             |
|  - Inspects operation.grid data cells                                                             |
|  - Evaluates business rule policy:                                                                |
|    "No department may submit a single Capex request > $1,000,000 without Executive Board Approval"|
|         |                                                                                         |
|         +-----------------------+-----------------------+                                         |
|         | Validation Passes                             | Validation Fails                        |
|         v                                               v                                         |
|  [PROCEED TO DATABASE COMMIT]                    [THROW VETO EXCEPTION]                           |
|  - Data written to BSO blocks                    - Transaction ATOMICALLY ROLLED BACK!            |
|  - User sees "Save Successful"                   - Zero dirty cells written to database!          |
|                                                  - Form displays custom modal error message:      |
|                                                    "Policy Violation: Capex exceeds $1M cap!"     |
|                                                                                                   |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. The `throwVetoException()` Mechanism

The `throwVetoException()` API method immediately halts the form save pipeline:
* **Atomic Rollback**: Any pending database updates are immediately aborted. The database remains in its pre-save state.
* **Modal Alert Dialog**: Displays the string passed to the method inside an Oracle EPM Cloud error modal.
* **HTML Formatting**: Supports standard HTML styling (`<b>`, `<font color="red">`, `<ul>`, `<li>`) for rich, executive-grade error presentation.

---

## 3. Production Validation Script: Multi-Policy Budget Guard

```groovy
/*
 * Script Name: Groovy_Budget_Policy_Validator.groovy
 * Event: Form "Run Before Save"
 * Purpose: Enforces financial policies; blocks invalid saves with rich HTML alerts.
 */

if (!operation.hasGrid() || !operation.grid.hasData()) return

List<String> policyViolations = []

// Iterate over user-modified cells
operation.grid.dataCellIterator { DataCell cell -> cell.isEdited() }.each { DataCell cell ->
    String account = cell.getMemberName("Account")
    String entity  = cell.getMemberName("Entity")
    Double value   = cell.data

    // Policy Rule 1: No negative values permitted on Operating Expenses
    if (account.contains("Expense") && value < 0) {
        policyViolations.add("<b>${entity} - ${account}</b>: Negative expense values are prohibited (Entered: ${value}).")
    }

    // Policy Rule 2: Single Capex line item cannot exceed $1,000,000
    if (account == "Capex_Machinery" && value > 1000000) {
        policyViolations.add("<b>${entity}</b>: Machinery Capex request (\$${value}) exceeds standard \$1,000,000 authorization cap.")
    }

    // Policy Rule 3: Headcount additions must be integer values
    if (account == "New_Hire_Headcount" && value % 1 != 0) {
        policyViolations.add("<b>${entity}</b>: Headcount requests must be whole numbers (Entered: ${value}).")
    }
}

// If any violations were detected, block the save immediately!
if (!policyViolations.isEmpty()) {
    String errorMessage = """
    <div style="font-family: Arial; font-size: 13px;">
      <h3 style="color: #D9534F; margin-top: 0;">Budget Submission Blocked: Policy Violations</h3>
      <p>The following inputs breach corporate budgeting policies and cannot be saved:</p>
      <ul>
        ${policyViolations.collect { "<li>${it}</li>" }.join("")}
      </ul>
      <p><i>Please correct these values and click Save again, or contact Finance for an exemption.</i></p>
    </div>
    """
    throwVetoException(errorMessage)
}

println("All budget policy validations passed successfully. Proceeding with commit.")
```

---

## 4. Pure In-Memory Cell Calculations (Skipping Essbase Scripts)

Groovy can also perform mathematical calculations directly on the client grid cells before saving, completely eliminating the need for an Essbase calculation script:

```groovy
/*
 * Example: In-Memory Gross Margin Calculation
 * Calculates Gross Margin directly in grid memory before commit.
 */

operation.grid.dataCellIterator { DataCell cell -> cell.isEdited() }.each { DataCell cell ->
    if (cell.getMemberName("Account") == "Units_Sold") {
        // Fetch adjacent Price cell in same row
        DataCell priceCell = cell.crossDimCell("Price")
        DataCell revCell   = cell.crossDimCell("Gross_Revenue")

        if (priceCell != null && revCell != null) {
            Double revenue = cell.data * priceCell.data
            // Write directly into grid cell memory
            revCell.setEdited(true)
            revCell.data = revenue
        }
    }
}
// When script terminates, Planning commits both Units_Sold AND Gross_Revenue in 1 pass!
```


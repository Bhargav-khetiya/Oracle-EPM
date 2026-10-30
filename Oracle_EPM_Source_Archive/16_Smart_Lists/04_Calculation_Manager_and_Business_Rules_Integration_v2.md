# 04 — Calc Manager & Business Rules Integration

---

## 4.1 How Calculations Interact with Smart Lists

Because Essbase stores Smart List selections as standard 8-byte floating-point numbers, calculation scripts and Groovy rules can read, evaluate, and write Smart List values directly.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        CALCULATION SYNTAX OPTIONS                      │
├──────────────────────────────────┬─────────────────────────────────────┤
│         NUMERIC ID SYNTAX        │       PROGRAMMATIC BRACKET SYNTAX   │
├──────────────────────────────────┼─────────────────────────────────────┤
│ IF ("Employee_Type" == 1)        │ IF ("Employee_Type" ==              │
│     "Bonus" = "Salary" * 0.15;   │     [[Employee_Type.Full_Time]])    │
│ ENDIF                            │     "Bonus" = "Salary" * 0.15;      │
│                                  │ ENDIF                               │
│ Disadvantage: Hardcodes numbers. │ Advantage: Self-documenting and     │
│ Fragile across environments.     │ stable across LCM migrations.       │
└──────────────────────────────────┴─────────────────────────────────────┘
```

---

## 4.2 Writing Smart List Values in Calc Scripts

Business rules can set Smart List values automatically based on financial thresholds:

```essbase
FIX("FY26", "Budget", "Working", @RELATIVE("Total_Entity", 0))
    "Approval_Flag"(
        IF ("EBITDA" > 1000000)
            "Approval_Flag" = [[Approval_Status.Auto_Approved]];
        ELSE
            "Approval_Flag" = [[Approval_Status.Requires_VP_Review]];
        ENDIF
    )
ENDFIX
```

---

## 4.3 Groovy Rules and Smart Lists

In modern EPM Cloud, **EPM Groovy Business Rules** provide powerful native Smart List methods:

```groovy
// Iterate over edited cells in a form
operation.grid.dataCellIterator({ DataCell cell -> cell.isEdited() }).each { cell ->
    
    // Check if the account has a Smart List
    if (cell.getAccountName() == "Project_Status") {
        
        // Read the human-readable text string
        String statusText = cell.getSmartListText()
        
        // Read the underlying Essbase numeric ID
        Double statusId = cell.getData()
        
        println "User selected: ${statusText} (Internal ID: ${statusId})"
        
        // Conditionally update another cell
        if (statusText == "Approved") {
            // Set another Smart List cell
            cell.setSmartList("Ready_for_Billing")
        }
    }
}
```

---

## 4.4 Data Maps and Smart Push with Smart Lists

When pushing data between cubes (e.g., from `Manpower` into `FinPlan`):
* If both cubes share the identical Smart List definition, Smart Push transfers the underlying numeric ID seamlessly.
* If the target cube does not have the Smart List assigned to the target account, Smart Push pushes the raw numeric ID (e.g., `1.0`), which will display as a number until the Smart List is assigned in the target cube's metadata.

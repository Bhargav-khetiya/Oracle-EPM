# Groovy Scripting in Oracle EPM Cloud — Overview

> **Folder:** 03_Groovy_Scripting | **Audience:** Intermediate → Architect
>
> **Provenance:** Merged from Claude `09_Groovy/`; ChatGPT `Calc Manager/Calculations_and_Allocations/06_Groovy_Business_Rules/`; Gemini `Calc Manager/Calculations_and_Allocations/06_Groovy_Business_Rules/`

---

## What Is Groovy in EPM Cloud?

**Groovy** is a Java-based scripting language available within Calculation Manager for writing advanced business rules. While standard calc scripts handle mathematical formulas, Groovy adds programming capabilities: conditional logic, loops, REST API calls, custom error messages, and data grid operations.

**Plain language:** If calc scripts are a hammer (good for hitting nails), Groovy is a Swiss Army knife (can do almost anything).

---

## When to Use Groovy vs Calc Scripts

| Feature | Calc Script | Groovy |
|---------|------------|--------|
| **Simple calculations** | ✅ Best choice | Overkill |
| **Complex conditional logic** | Limited | ✅ Full programming |
| **REST API calls** | Not possible | ✅ Supported |
| **Custom validation/veto** | Not possible | ✅ `throwVetoException()` |
| **Dynamic FIX generation** | Static only | ✅ Based on edited cells |
| **Data Grid read/write** | Native Essbase | ✅ `DataGridBuilder` |
| **Performance** | Faster for pure calc | Overhead for JVM startup |
| **Learning curve** | Lower | Higher (Java knowledge helps) |

---

## Key Groovy Capabilities

### 1. Dynamic FIX Generation (Micro-FIX)

The most powerful Groovy technique: instead of calculating across all blocks, Groovy builds a FIX statement targeting **only the cells the user actually edited**.

```groovy
// Pseudo-code: Build FIX from edited cells only
def editedCells = operation.grid.getEditedCells()
def members = editedCells.collect { it.getMemberName("Entity") }.unique()
String fix = "FIX(${members.collect{'"'+it+'"'}.join(',')})"
// Execute targeted calc — 147x faster than full-scope calc
```

**Result:** Form save latency drops from 45 seconds to 200 milliseconds.

### 2. Pre-Save Validation with throwVetoException

Stop a form save with a custom error message if business rules are violated:

```groovy
// Block negative revenue entries
operation.grid.dataCellIterator().each { cell ->
    if (cell.getMemberName("Account") == "Revenue" && cell.data < 0) {
        throwVetoException("Revenue cannot be negative. Please check your entry.")
    }
}
```

### 3. DataGridBuilder — Programmatic Data Access

Read from and write to any cube programmatically:

```groovy
// Read data from one cube, process, write to another
DataGridBuilder builder = new DataGridBuilder()
builder.addPov(["Scenario": "Actual", "Year": "FY26"])
builder.addColumn(["Period": ["Jan", "Feb", "Mar"]])
builder.addRow(["Account": "Revenue", "Entity": "US_East"])
DataGrid grid = builder.build(cube)
// Process grid values...
```

### 4. REST API Calls from Groovy

Call external services or EPM REST endpoints:

```groovy
// Call EPM REST API to run another job
HttpResponse response = operation.application.getConnection("EPM_REST")
    .post("/interop/rest/11.1.2.3.600/applicationsnapshots/exportSnapshot")
```

---

## Groovy Rule Architecture

```
Groovy Rule in Calc Manager
├── Runs in a sandboxed JVM (Java Virtual Machine)
├── Has access to the Planning Object Model:
│   ├── operation.grid — the form data grid
│   ├── operation.application — application context
│   ├── cube — Essbase cube reference
│   └── rtps — runtime prompt values
├── Can generate and execute Essbase calc scripts dynamically
├── Can read/write data via DataGridBuilder
└── Can call REST APIs via HTTP connections
```

---

## Common Groovy Patterns

| Pattern | Use Case |
|---------|----------|
| **Micro-FIX** | Dynamic calc scope based on edited cells |
| **Veto validation** | Block invalid data before save |
| **Data copy** | Cross-cube data movement via DataGridBuilder |
| **Dynamic member lists** | Build member lists based on runtime conditions |
| **REST integration** | Call external services or trigger EPM operations |
| **Custom alerts** | Rich HTML error messages to users |

---

## 🧠 Self-Check Questions

1. **When should you use Groovy instead of a calc script?**
2. **What does throwVetoException do?**
3. **How does dynamic FIX generation improve performance?**
4. **What is DataGridBuilder used for?**

> **Teach-back prompt:** Explain to a senior consultant why Groovy micro-FIX can reduce form save time from 45 seconds to 200ms. Then describe the architecture of how a Groovy rule executes within Calc Manager.

---

## Oracle Sources

- [Groovy Rules Java API Reference](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/groov/) (Online only)
- [Designing with Calculation Manager](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfcsr/)


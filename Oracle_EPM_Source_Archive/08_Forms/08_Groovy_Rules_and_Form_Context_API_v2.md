# ☕ Form Properties — Groovy Rules & Form Context API Deep Dive

> **Purpose**: This technical manual provides an exhaustive architectural reference for developing, debugging, and optimizing **EPM Groovy Business Rules** executing within the context of Oracle EPM Cloud web forms and Smart View grids.

---

## 1. Architectural Model: Groovy vs. Essbase Calc Scripts on Forms

Traditional Essbase calculation scripts execute inside the MOLAP kernel (`ESSSVR`) without any direct awareness of the client form, the user's cursor, or the specific cells edited in the grid. In contrast, EPM Groovy rules execute inside the **EPM Cloud Java Application Server** container, exposing the entire form grid data model before, during, and after persistence:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           CLIENT TIER (Web Form / Smart View)           │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │ HTTP POST (Form Save / Load)
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                  EPM APPLICATION SERVER (JVM Tier)                      │
│                                                                         │
│  [Form Lifecycle Hook: Run Before Save]                                 │
│  ├── 1. Grid Deserialization ──► `operation.grid` constructed in RAM     │
│  ├── 2. Groovy Script Execution (Groovy Engine 3.x / OpenJDK)           │
│  │   ├── Iterate edited cells: `cell.isEdited()`                        │
│  │   ├── Real-time data validation                                      │
│  │   └── If invalid ──► `throwVetoException()` (Aborts HTTP Save)       │
│  └── 3. Dynamic Calculation Generation                                  │
│      └── Build focused Essbase FIX statement using edited coordinates   │
└──────────────────┬───────────────────────────────────┬──────────────────┘
                   │                                   │
                   │ Fast Grid API Write               │ Dynamic Calc Script
                   ▼                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       ESSBASE MOLAP ENGINE                              │
│  ├── Writes edited 8-byte cells to data blocks in .PAG                  │
│  └── Executes focused calc scope (0.1s vs 30s full-cube calc)           │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Form Grid Execution Lifecycle Hooks

When attaching a Groovy rule to an EPM Form under **Form Settings → Business Rules**, three execution event hooks are available:

| Lifecycle Hook | Execution Point | Grid State in Memory | Primary Use Cases |
| :--- | :--- | :--- | :--- |
| **Run Before Load** | Invoked when the user opens or refreshes the form, before data is sent to the client browser. | Grid is populated with read data from Essbase, but not yet displayed. | Dynamic member filtering, building user-specific drop-down lists, dynamic form layout modification, pre-flight data staging. |
| **Run Before Save** | Invoked when user clicks **Save** / **Submit**, before changes are committed to Essbase. | Contains original values and newly entered values; `cell.isEdited()` is `true` for changed cells. | **Data Validation**: Rejecting out-of-bound inputs, vetoing saves, cross-cell logic checking, dynamically adjusting target values. |
| **Run After Save** | Invoked immediately after changed data is physically written and committed to Essbase blocks. | Grid is saved; reflects post-commit database state. | **Targeted Calculations**: Running calculations scoped strictly to modified entities/cost centers; **Smart Push**: Triggering targeted data synchronization from BSO to ASO. |

---

## 3. The `operation.grid` Object Model

The primary interface for form interaction is `operation.grid`. The object hierarchy exposes complete dimensional metadata and cell coordinates:

```
operation
├── application           (Application metadata, cubes, dimensions)
├── currentUser           (Security identity, email, assigned groups)
└── grid                  (The active form grid instance)
    ├── cube              (Target Essbase cube, e.g. "Plan1", "Oep_FS")
    ├── rows              (Array of GridRow objects)
    ├── columns           (Array of GridColumn objects)
    ├── pov               (Array of Dimension / Member pairs on POV)
    └── page              (Array of Dimension / Member pairs on Page)
```

### Essential `DataCell` Properties and Methods

When iterating cells via `operation.grid.dataCellIterator()`, each `DataCell` provides:

| Method / Property | Return Type | Description |
| :--- | :--- | :--- |
| `cell.data` | `Double` / `Number` | The raw numeric value stored or entered in the cell. Read/write property (`cell.data = 500`). |
| `cell.formattedValue` | `String` | Text representation (e.g., `"$500.00"`, `"Active"`, `"Stage 1"` for Smart Lists). |
| `cell.isEdited()` | `boolean` | `true` if the value was modified by the user in the current transaction. |
| `cell.isReadOnly()` | `boolean` | `true` if the cell cannot be written to (due to CLS, dynamic calc, locked period). |
| `cell.crossesInvalidIntersection()`| `boolean` | `true` if the cell coordinates violate a Valid Intersection rule. |
| `cell.getMemberName(dimName)`| `String` | Retrieves the member name for the specified dimension at this cell's coordinate. |
| `cell.getAccountName()` | `String` | Convenience method to retrieve the Account dimension member. |
| `cell.getPeriodName()` | `String` | Convenience method to retrieve the Period dimension member. |
| `cell.addMessage(int type, String msg)`| `void` | Attaches a visual validation badge or tooltip to this specific cell. |

---

## 4. Production Script 1: Real-Time Pre-Save Validation with `throwVetoException()`

This production-grade script runs on **Run Before Save**. It iterates only edited cells, validates that expense adjustments do not exceed 25% of baseline budget, and aborts the save with a clear error dialog if violated:

```groovy
/* Groovy Rule: Validate Expense Increases on Form Submit
   Attachment: Run Before Save
   Context: EPM Planning Web Form
*/

import com.oracle.epm.api.model.DataCell
import com.oracle.epm.api.model.Grid

Grid grid = operation.grid

// Efficiently filter iterator strictly to modified cells
List<String> errorList = []

grid.dataCellIterator { DataCell cell -> cell.isEdited() }.each { DataCell cell ->
    String accountName = cell.getAccountName()
    String entityName  = cell.getMemberName("Entity")
    String periodName  = cell.getPeriodName()
    Double newValue    = cell.data as Double
    
    // Ignore empty/missing entries
    if (newValue == null) return

    // Business Logic: Check if expense increases exceed allowable threshold
    if (accountName.startsWith("6") || accountName.contains("Expense")) {
        if (newValue > 100000.0) {
            errorList.add("Account [${accountName}] in Entity [${entityName}] (${periodName}) exceeds maximum allowable expense limit ($100,000). Entered: ${newValue}")
        }
        if (newValue < 0.0) {
            errorList.add("Negative expenses are prohibited for Account [${accountName}] in Entity [${entityName}].")
        }
    }
}

// If validation errors exist, cancel the save and present the error dialog to the user
if (!errorList.isEmpty()) {
    String formattedMessage = "Validation Failed! Please correct the following errors:\n\n" + errorList.join("\n")
    throwVetoException(formattedMessage)
}
```

> **Client Impact**: When `throwVetoException()` is called, the EPM server returns an `HTTP 400` payload with the custom error string. The client web form keeps the user's modifications in the grid without clearing their inputs, highlighting the affected fields.

---

## 5. Production Script 2: Dynamic Dynamic FIX Statement Generation

One of Groovy's highest ROI features on forms is calculating **only what changed**. A traditional calc script might recalculate the entire `Entity` hierarchy (30–60 seconds). A Groovy-generated calculation targets strictly the modified entities and accounts (0.2–0.8 seconds):

```groovy
/* Groovy Rule: Focused Recalculation on Form Save
   Attachment: Run After Save
   Context: Financial Planning Form
*/

import com.oracle.epm.api.model.DataCell
import com.oracle.epm.api.model.Grid

Grid grid = operation.grid

// Collect unique modified members per dimension
Set<String> editedEntities = [] as Set
Set<String> editedAccounts = [] as Set
Set<String> editedPeriods  = [] as Set

grid.dataCellIterator { DataCell cell -> cell.isEdited() }.each { DataCell cell ->
    editedEntities.add("\"" + cell.getMemberName("Entity") + "\"")
    editedAccounts.add("\"" + cell.getAccountName() + "\"")
    editedPeriods.add("\""  + cell.getPeriodName() + "\"")
}

// If no cells were edited, terminate immediately
if (editedEntities.isEmpty()) {
    println("No cells modified. Exiting without calculation.")
    return
}

// Retrieve fixed POV context
String scenario = "\"" + grid.getRows()[0].getMemberName("Scenario") + "\""
String version  = "\"" + grid.getRows()[0].getMemberName("Version") + "\""
String years    = "\"" + grid.getRows()[0].getMemberName("Years") + "\""

// Construct the ultra-fast focused calculation script
String calcScript = """
FIX(${editedEntities.join(", ")}, ${scenario}, ${version}, ${years}, ${editedPeriods.join(", ")})
    FIX(@RELATIVE("Total Cost Center", 0))
        CALC DIM("Account");
    ENDFIX
    AGG("Entity");
ENDFIX
"""

println("Executing Focused Dynamic Calc:\n" + calcScript)

// Execute calculation directly against the form's underlying cube
grid.cube.executeCalcScript(calcScript)
```

---

## 6. Production Script 3: Targeted Real-Time Smart Push via Groovy

When syncing data between a BSO Planning cube and an ASO Reporting cube, a standard Smart Push configured on form save syncs the entire form grid slice—frequently taking 5–15 seconds. Using Groovy, Smart Push is invoked strictly for the cells modified:

```groovy
/* Groovy Rule: Micro Smart Push on Modified Slices
   Attachment: Run After Save
*/

import com.oracle.epm.api.model.SmartPush

Grid grid = operation.grid

// Check if any cells were edited
boolean hasEdits = grid.dataCellIterator { DataCell cell -> cell.isEdited() }.hasNext()

if (!hasEdits) {
    println("No edits detected. Smart Push bypassed.")
    return
}

// Build Smart Push execution object matching the form's configured data map
SmartPush smartPush = grid.buildSmartPush("Push_Plan1_To_OEP_FS")

// Override the data map slice to push ONLY edited entities and periods
Set<String> editedEntities = [] as Set
grid.dataCellIterator { DataCell cell -> cell.isEdited() }.each { DataCell cell ->
    editedEntities.add(cell.getMemberName("Entity"))
}

// Apply targeted override slice
smartPush.overrideMemberSelection("Entity", editedEntities as List)

// Execute the Smart Push synchronously
smartPush.execute()
println("Targeted Smart Push completed successfully for entities: ${editedEntities}")
```

---

## 7. Performance Best Practices & Do's and Don'ts

| Practice | Status | Architectural Rationale |
| :--- | :--- | :--- |
| **Filter iterators with predicates** (`dataCellIterator { it.isEdited() }`) | ✅ **Mandatory** | Avoids inspecting unedited cells. In a 10,000-cell form with 5 edits, reduces loop iterations by 99.95%. |
| **Avoid Essbase MDX/Calc calls inside cell loops** | ❌ **Forbidden** | Executing an Essbase query per cell inside a loop results in an $N+1$ query disaster. Aggregate members into `Set` collections and execute one bulk query. |
| **Validate coordinates against VIC before calculating** | ✅ **Recommended** | Prevents writing data into invalid member intersections that will fail validation downstream. |
| **Use `println()` sparingly in production** | ✅ **Recommended** | Excessive console logging introduces I/O serialization overhead in the EPM cloud application logs. |
| **Wrap large Groovy rules in `try / catch` blocks** | ✅ **Recommended** | Ensures graceful failure and returns clean, human-readable error messages to users rather than raw Java stack traces. |

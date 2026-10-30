# 02 Dynamic Data Map Execution via Groovy and Context Overrides

## 1. Hybrid Architecture: Combining Data Maps with Groovy

While standard Smart Push requires hardcoded configuration on a web form, enterprise applications often demand **dynamic runtime routing**. For example, the user selects a scenario on the form, and the system must dynamically push data to different cubes or clear specific target slices based on runtime logic.

The Oracle EPM Groovy API bridges this requirement by exposing native Data Maps directly as programmable objects via:
`operation.application.getDataMap("DataMapName")`

```
+---------------------------------------------------------------------------------------------------+
|                            GROOVY-ORCHESTRATED DYNAMIC DATA MAP ENGINE                           |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [USER FORM SAVE]                                                                                 |
|         |                                                                                         |
|         v                                                                                         |
|  [GROOVY SCRIPT INTERCEPT]                                                                        |
|         |                                                                                         |
|         | 1. Read Current POV & User Edits:                                                       |
|         |    - Scenario: "Forecast"                                                               |
|         |    - Years:    "FY25"                                                                   |
|         |    - Entity:   "E105_EMEA"                                                              |
|         |                                                                                         |
|         | 2. Instantiate Dynamic Data Map Object:                                                 |
|         |    DataMap map = operation.application.getDataMap("OEP_FS to OEP_REP")                 |
|         |                                                                                         |
|         | 3. Inject Dynamic POV Slicing Overrides:                                                |
|         |    Map<String, String> povOverrides = [:]                                               |
|         |    povOverrides["Entity"] = "E105_EMEA"                                                 |
|         |    povOverrides["Scenario"] = "Forecast"                                                |
|         |                                                                                         |
|         | 4. Invoke Underlying C++ Load Buffer Engine:                                            |
|         |    map.execute(povOverrides, true)                                                      |
|         v                                                                                         |
|  [BULK C++ STREAMING COMMITTED IN < 500ms]                                                        |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Production Groovy Script: Dynamic POV Push

```groovy
/*
 * Script Name: Groovy_Dynamic_DataMap_Push.groovy
 * Purpose: Dynamically extracts form POV coordinates and passes them as
 *          runtime overrides to the underlying C++ Data Map engine.
 */

// 1. Capture Form Context
String currentScenario = operation.grid.getPovHeader("Scenario")
String currentYear     = operation.grid.getPovHeader("Years")
String currentVersion  = operation.grid.getPovHeader("Version")

// Extract unique entities edited by the user
Set<String> editedEntities = [] as Set
operation.grid.dataCellIterator { DataCell cell -> cell.isEdited() }.each { DataCell cell ->
    editedEntities.add(cell.getMemberName("Entity"))
}

// Exit early if user clicked save without modifying numeric data
if (editedEntities.isEmpty()) {
    println("No edited data cells detected. Skipping dynamic push.")
    return
}

String entityOverrideString = editedEntities.join(",")
println("Target Push Scope: Entities = [${entityOverrideString}], Year = [${currentYear}]")

// 2. Fetch the pre-configured Data Map
DataMap dataMap = operation.application.getDataMap("OEP_FS to OEP_REP")

// 3. Construct POV Override Map
Map<String, String> overrides = [
    "Scenario": currentScenario,
    "Years"   : currentYear,
    "Version" : currentVersion,
    "Entity"  : entityOverrideString
]

// 4. Execute Data Map with Dynamic Target Clear
// Parameters: (Map<String, String> overrides, boolean clearTargetData)
try {
    dataMap.execute(overrides, false)
    println("Dynamic Smart Push completed successfully via Groovy orchestrator.")
} catch (Exception ex) {
    throwVetoException("Data Map synchronization failed: " + ex.getMessage())
}
```

---

## 3. Dynamic Target Clearing Based on User POV

When an end-user needs to perform a scenario restatement, the target reporting cube must be cleared **only for that specific scenario and year** before pushing new numbers:

```groovy
/*
 * Target Slicing Clear via Groovy
 */
Cube repCube = operation.application.getCube("OEP_REP")

// Construct MDX Clear Region
String clearRegion = """
CrossJoin(
    CrossJoin({[${currentScenario}]}, {[${currentYear}]}),
    Descendants([Total_Expenses])
)
"""

// Execute MDX Clear on ASO Target
repCube.clearData(clearRegion, Cube.ClearOption.PHYSICAL)
println("Successfully executed targeted MDX physical clear on ASO reporting cube.")

// Now execute Data Map to repopulate fresh numbers
dataMap.execute(overrides, false)
```

---

## 4. Pure Groovy Grid Mover vs. Groovy-Wrapped Data Map

| Criterion | Pure Groovy DataGridBuilder | Groovy-Wrapped Data Map (`dataMap.execute`) |
| :--- | :--- | :--- |
| **Throughput** | $25,000 \text{ to } 75,000 \text{ cells/sec}$ | **$200,000 \text{ to } 500,000 \text{ cells/sec}$** |
| **Logic Capability** | Full Java/Groovy algorithmic flexibility | Fixed dimensional mappings & fixed members |
| **Target Execution** | Groovy constructs tuples cell-by-cell | Low-level C++ streaming directly between cubes |
| **Best Used For** | Real-time calculations with dynamic business logic | Mass bulk movements with dynamic POV filters |


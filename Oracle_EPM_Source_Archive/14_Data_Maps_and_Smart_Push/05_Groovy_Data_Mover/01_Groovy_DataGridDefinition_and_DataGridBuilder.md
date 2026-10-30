# 01 Groovy DataGridDefinition, DataGridBuilder, and In-Memory Data Mover

## 1. The Groovy In-Memory Data Movement Paradigm

In complex enterprise implementations, standard Data Maps and Smart Push may lack the algorithmic flexibility needed for advanced calculations (e.g., dynamically adjusting tax rates during the push, routing data conditionally based on user-entered percentages, or moving data across non-standard dimensional intersections).

The **Oracle EPM Groovy Rules Engine** enables developers to extract, transform, and load data completely in-memory using the Java/Groovy JVM without writing intermediate disk files or executing slow point-by-point calc scripts.

```
+---------------------------------------------------------------------------------------------------+
|                                 GROOVY IN-MEMORY DATA MOVER PIPELINE                              |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  1. USER FORM SAVE:                                                                               |
|     User modifies cells on Web Data Form (Source BSO Cube)                                        |
|                                                                                                   |
|  2. GROOVY INTERCEPT (operation.grid):                                                             |
|     +-------------------------------------------------------------------------+                   |
|     | Cell Iterator: grid.dataCellIterator { it.isEdited() }                  |                   |
|     | Captures: Account, Entity, Period, Years, OldValue, NewValue            |                   |
|     +-------------------------------------------------------------------------+                   |
|                                         |                                                         |
|                                         v                                                         |
|  3. IN-MEMORY TRANSFORMATION (Groovy Business Logic):                                             |
|     - Validates input thresholds                                                                  |
|     - Calculates dynamic markup or custom currency translation                                    |
|     - Formats target coordinate addresses                                                         |
|                                         |                                                         |
|                                         v                                                         |
|  4. TARGET GRID BUILDER (DataGridBuilder):                                                        |
|     +-------------------------------------------------------------------------+                   |
|     | Target Cube: cube.getDataGridBuilder(DataGrid.GridType.WRITE)           |                   |
|     | Appends Rows: [TargetAccount, TargetEntity, TargetPeriod] -> Value      |                   |
|     +-------------------------------------------------------------------------+                   |
|                                         |                                                         |
|                                         v                                                         |
|  5. DIRECT KERNEL COMMIT (builder.build()):                                                       |
|     - Ingests memory grid directly into Target ASO Load Buffer or BSO Cache   |                   |
|     - Total Latency: < 800 milliseconds                                       |                   |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Reading Source Data: `DataGridDefinitionBuilder`

When data must be extracted dynamically from a source cube based on runtime prompts or form context:

```groovy
/*
 * Example: Extracting source data dynamically using DataGridDefinitionBuilder
 */
Cube sourceCube = operation.application.getCube("OEP_FS")

// Define the extraction slice dynamically
DataGridDefinitionBuilder builder = sourceCube.getDataGridDefinitionBuilder()
builder.addPov(["Scenario", "Version", "Years"], [["Plan"], ["Working"], ["FY25"]])
builder.addColumn(["Period"], [["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]])
builder.addRow(["Account"], [["Sales_Revenue", "Cost_of_Goods_Sold"]])
builder.addRow(["Entity"], [["E101_East", "E102_West"]])

DataGridDefinition gridDef = builder.build()

// Execute extract into memory grid
DataGrid sourceGrid = sourceCube.loadGrid(gridDef, false)
println("Total Source Cells Extracted: ${sourceGrid.size()}")
```

---

## 3. Streaming Data into Target: `DataGridBuilder`

To write extracted and transformed data into the target cube, Groovy provides the high-speed `DataGridBuilder` API:

```groovy
/*
 * Production Pattern: Form-triggered Groovy Data Mover from BSO to ASO
 * Executes synchronously upon saving the web form.
 */

// 1. Identify Target Cube
Cube targetCube = operation.application.getCube("OEP_REP")

// 2. Initialize Target Data Grid Builder
DataGridBuilder targetGrid = targetCube.getDataGridBuilder(DataGrid.GridType.WRITE)

// 3. Define Target Grid Dimensional Architecture
// Target POV Dimensions
targetGrid.addPov("Plan", "Working", "FY25", "Periodic") // Scenario, Version, Years, View

// Target Column Dimensions
targetGrid.addColumn("Jan", "Feb", "Mar") // Period

// 4. Iterate over ONLY edited cells on the user's active web form
operation.grid.dataCellIterator { DataCell cell -> cell.isEdited() }.each { DataCell cell ->
    String account = cell.getMemberName("Account")
    String entity  = cell.getMemberName("Entity")
    Double value   = cell.data

    // Apply transformation logic (e.g., apply 10% management fee)
    Double transformedVal = value * 1.10

    // Append row to target in-memory grid
    targetGrid.addRow([account, entity], [transformedVal, transformedVal * 1.02, transformedVal * 1.05])
}

// 5. Build and Commit to Target Cube
DataGridBuilder.Status status = new DataGridBuilder.Status()
DataGrid gridToCommit = targetGrid.build(status)

targetCube.saveGrid(gridToCommit)

println("Successfully moved ${status.numAcceptedCells} cells to Target Cube.")
if (status.numRejectedCells > 0) {
    println("WARNING: ${status.numRejectedCells} cells rejected by target cube!")
}
```

---

## 4. Architectural Advantages of Groovy Data Mover

1. **Precision Micro-Push**: Standard Smart Push pushes all cells in the form intersection; Groovy can evaluate `cell.isEdited()` to push **strictly the 2 or 3 cells that the user actually touched**.
2. **Dynamic In-Flight Calculations**: Allows mathematical logic, rounding, currency cross-triangulation, and conditional splits that static Data Maps cannot express.
3. **Instant Validation**: Groovy can evaluate target constraints before saving and issue a `throwVetoException()` to block invalid entries and roll back both source and target updates atomically.


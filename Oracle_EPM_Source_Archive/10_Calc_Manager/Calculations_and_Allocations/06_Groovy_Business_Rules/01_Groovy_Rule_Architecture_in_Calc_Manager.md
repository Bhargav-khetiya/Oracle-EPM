# 01 Groovy Business Rule Architecture, Java Virtual Machine Sandbox, and Planning Object Model

## 1. The Architectural Shift: Groovy in Calculation Manager

In Oracle Enterprise Performance Management Cloud (Enterprise Planning and Budgeting Cloud Service - EPBCS and Financial Consolidation and Close - FCCS), the integration of the **Apache Groovy Scripting Engine** represents the most significant architectural evolution since the invention of Calculation Manager.

Traditional Essbase calculation scripts (`.csc`) are declarative, static domain-specific languages (DSL) executed strictly inside the Essbase kernel. **Groovy Rules**, by contrast, execute inside the **Planning Application Server Java Virtual Machine (JVM)**, providing full object-oriented programming capabilities, real-time access to the user interface data grid, REST web service calls, and dynamic calc script generation.

```
+---------------------------------------------------------------------------------------------------+
|                                  GROOVY CALCULATION ARCHITECTURE                                  |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [USER WEB FORM SAVE / ACTION MENU]                                                               |
|         |                                                                                         |
|         v                                                                                         |
|  +---------------------------------------------------------------------------------------------+  |
|  | PLANNING APPLICATION SERVER (JAVA / GROOVY JVM SANDBOX)                                     |  |
|  |                                                                                             |  |
|  |  +-------------------------------+      +------------------------------------------------+  |  |
|  |  | THE PLANNING OBJECT MODEL     |      | GROOVY EXECUTION LIFECYCLE                     |  |  |
|  |  | - operation.application       |      | 1. Intercepts Form Context (Rows, Cols, POV)   |  |  |
|  |  | - operation.grid              | ===> | 2. Filters Edited / Dirty Cells                |  |  |
|  |  | - cube                        |      | 3. Enforces Business Logic & Validations       |  |  |
|  |  | - dimension / member          |      | 4. Throws Veto Exceptions to block invalid saves|  |  |
|  |  +-------------------------------+      +------------------------------------------------+  |  |
|  +---------------------------------------------------------------------------------------------+  |
|         |                                                                                         |
|         | Generates Dynamic, Micro-Scoped Calc Script String                                      |
|         v                                                                                         |
|  +---------------------------------------------------------------------------------------------+  |
|  | ESSBASE CALCULATION ENGINE (C++ KERNEL)                                                      |  |
|  | - Executes targeted FIX statement on ONLY the edited coordinates                             |  |
|  | - Finishes in 200ms instead of 45 seconds!                                                   |  |
|  +---------------------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Groovy vs. Essbase Calc Script: Architectural Comparison

| Dimension | Essbase Calculation Script | Groovy Business Rule |
| :--- | :--- | :--- |
| **Execution Environment** | Essbase Server C++ Kernel (`ESSSVR`). | Planning Application Server JVM (Java 11+). |
| **Data Grid Awareness** | Completely blind to UI grid; knows only cube blocks. | Full awareness of active form POV, edited cells, and layout. |
| **Dynamic Code Generation**| Static; member tokens can only be injected via RTPs. | Can dynamically construct and assemble calc scripts at runtime. |
| **Error Handling / Veto** | Cannot easily abort a form save with a custom message. | Supports `throwVetoException()` with rich custom HTML alerts. |
| **External Integrations** | Limited to location aliases / CDFs. | Full support for HTTP/REST API calls and JSON processing. |
| **Execution Scope** | Typically macro-slice across multiple blocks. | Micro-slice focused strictly on dirty / touched cells. |

---

## 3. The Core Planning Object Model

Within a Groovy Business Rule in Calculation Manager, developers interact with predefined contextual objects injected by the runtime environment:

### 3.1 `operation.grid`
Represents the client-side data grid that triggered the rule (available when attached to a Web Form or Ad-Hoc Grid).
* `grid.dataCellIterator()`: Iterates over cells matching specific predicates.
* `grid.getRows()`, `grid.getColumns()`, `grid.getPov()`: Returns structural coordinate arrays.
* `grid.hasData()`: Verifies if the form contains active records.

### 3.2 `operation.application`
Exposes application-wide metadata and services:
* `application.getCube("OEP_FS")`: Returns the cube descriptor.
* `application.getDataMap("MapName")`: Accesses native Data Maps.
* `application.getConnection("LinkedService")`: Connects to external REST endpoints.

### 3.3 `cube`
Exposes the Essbase storage engine:
* `cube.executeCalcScript(scriptString)`: Transmits a dynamically generated calc script string to the Essbase kernel.
* `cube.loadGrid(gridDef)`: Extracts multidimensional data directly into JVM memory.
* `cube.saveGrid(dataGrid)`: Flushes in-memory calculations directly to cube blocks.

---

## 4. The JVM Security Sandbox

To maintain enterprise cloud stability and multi-tenant security, Oracle EPM Cloud enforces strict sandbox constraints on Groovy scripts:
* **No Arbitrary File System Access**: Cannot write to local disk paths (`java.io.File` access is restricted).
* **Memory and Execution Limits**: Groovy scripts exceeding memory limits or looping beyond thread timeout thresholds (typically 3–5 minutes) are terminated by the JVM watch-dog thread.
* **Whitelisted Java Classes**: Developers can only instantiate classes within approved packages (`java.util`, `java.text`, `com.hyperion.planning.hyperionscripttool.epbcs.*`).


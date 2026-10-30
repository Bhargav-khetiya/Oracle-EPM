# 01 Calculation Manager Architecture, System Views, and Repository Schema

## 1. High-Level Architectural Foundations

Oracle Hyperion / EPM Cloud **Calculation Manager** is the enterprise graphical rule design, lifecycle management, and validation environment that bridges financial business logic with the underlying multidimensional Essbase calculation kernel. 

Before Calculation Manager, rules were authored as flat ASCII text `.csc` calculation script files directly on the Essbase file system. Calculation Manager abstracts and enhances this by introducing:
* A centralized relational metadata repository storing graphical business logic artifacts.
* Multi-tiered variable scoping and Design-Time Prompts (DTP).
* A validation compiler that parses visual flowcharts, validates syntax against outline metadata, and generates optimized Essbase calc scripts.
* Deployment and security synchronization with the Planning relational application framework.

```
+---------------------------------------------------------------------------------------------------+
|                              CALCULATION MANAGER ENTERPRISE ARCHITECTURE                          |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  +---------------------------------------------------------------------------------------------+  |
|  | CALCULATION MANAGER WEB UI / CANVAS DESIGNER                                                |  |
|  | [Visual Flowchart Palette] <============== Auto-Sync ==============> [Script / Code Editor]  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                  |                                                |
|                                1. Save Artifact  | 2. Compile & Validate                          |
|                                                  v                                                |
|  +---------------------------------------------------------------------------------------------+  |
|  | PLANNING RELATIONAL APPLICATION REPOSITORY (HSP_CALCMGR_* / HSP_OBJECT Tables)              |  |
|  | - Stores Rule XML definitions, Variable scopes, Template definitions, and Locks.              |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                  |                                                |
|                                                  | 3. Deploy Rule Action                          |
|                                                  v                                                |
|  +---------------------------------------------------------------------------------------------+  |
|  | CALC COMPILER & DEPLOYMENT ENGINE                                                            |  |
|  | - Converts Visual Flowchart / DTP into raw Essbase Calculation Language (.csc)                |  |
|  | - Replaces Variable tokens with Essbase Member names                                        |  |
|  | - Validates member existence against Essbase outline (.otl)                                  |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                  |                                                |
|                                                  | 4. Write & Register Rule                       |
|                                                  v                                                |
|  +---------------------------------------------------------------------------------------------+  |
|  | ESSBASE CALCULATION ENGINE & STORAGE                                                         |  |
|  | - Cube ASO / BSO Kernel                                                                      |  |
|  | - Deployed Rule registered in Planning Form Menus & Job Scheduler                            |  |
|  +---------------------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. The Four System Views in Calculation Manager

Calculation Manager organizes its navigation hierarchy into four distinct architectural views, selectable via the top navigation dropdown or left sidebar tabs:

### 2.1 System View (The Application Hierarchy View)
The primary administrative view displaying the complete enterprise topology:
```
System View
  `-- Oracle EPM Cloud Pod
        `-- Planning Applications
              `-- Vision
                    |-- Plan Types (Cubes: OEP_FS, OEP_WFP, OEP_REP)
                    |     |-- Rules
                    |     |-- Rule Sets
                    |     |-- Components (Formulas, Scripts)
                    |     `-- Templates
                    |-- Variables (Application & Plan Type Scopes)
                    `-- Database Properties
```
* **Use Case**: Developing rules for specific cubes, deploying rulesets, and managing cube-specific variables.

### 2.2 Database View
Organizes artifacts strictly by their physical storage database and application connection type (Essbase Block Storage, Aggregate Storage, or Planning Application).
* **Use Case**: Database administrators performing outline inspections, cache tuning, index defragmentation, and database property adjustments.

### 2.3 Custom View
Allows rule designers to organize artifacts into custom user-defined hierarchical folders regardless of application, cube, or artifact type.
* **Use Case**: Grouping all revenue-related components across cubes (Rules, Formulas, Scripts, Variables) into a single logical "Revenue Management" workspace folder.

### 2.4 Deployment View
Displays the deployment lifecycle and synchronization status of all rules across environments:
* **To Be Deployed**: Rules modified or saved in design mode that have not yet been compiled into the production application.
* **Deployed**: Rules currently active and accessible to end users in data forms and action menus.
* **Deployment Status Flags**:
  * *Green Checkmark*: Rule is successfully deployed and outline-synchronized.
  * *Yellow Triangle*: Rule has been edited since last deployment (desynchronized).
  * *Red Exclamation Mark*: Compilation error; deployment failed.

---

## 3. Relational Repository Schema & Lifecycle States

Calculation Manager artifacts do not exist as independent files on the operating system during development. They are persisted inside the Planning relational database schema (or Calculation Manager repository database in legacy on-prem) across specialized tables:

| Relational Table | Purpose | Stored Attributes |
| :--- | :--- | :--- |
| `HSP_CALCMGR_RULES` | Master record of Business Rules | `RULE_ID`, `APP_ID`, `PLAN_TYPE_ID`, `RULE_NAME`, `IS_ACTIVE`, `DEPLOYED_DATE`, `XML_PAYLOAD` |
| `HSP_CALCMGR_RULESETS`| Master record of Rule Sets | `RULESET_ID`, `APP_ID`, `RULESET_NAME`, `STOP_ON_ERROR`, `EXECUTION_ORDER` |
| `HSP_CALCMGR_VARIABLES`| Variable definitions & scopes | `VAR_ID`, `SCOPE_TYPE` (Global/App/Plan/Rule), `VAR_TYPE` (Member/String/Numeric), `DEFAULT_VALUE` |
| `HSP_CALCMGR_TEMPLATES`| Reusable system & custom templates | `TEMPLATE_ID`, `TEMPLATE_NAME`, `DTP_SCHEMA`, `LOGIC_XML` |
| `HSP_CALCMGR_LOCKS` | Active design session concurrency locks | `OBJECT_ID`, `USER_ID`, `LOCK_TIMESTAMP`, `MACHINE_IP` |

### The Three Operational Lifecycle States
1. **Draft / Inactive State**:
   * The rule is stored only in `HSP_CALCMGR_RULES`.
   * It cannot be viewed or triggered by end users.
   * Compiles only in-memory during validation.
2. **Active / Validated State**:
   * The visual flowchart passes all syntax, dimension, and type validation checks.
   * Ready for deployment.
3. **Deployed State**:
   * The compiler translates the XML flowchart into an Essbase calculation script string.
   * Registers the rule with Planning's `HSP_ACTION` and form security tables.
   * End users can now see and run the rule in Data Forms, Task Lists, and Smart View.


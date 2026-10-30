# 01 Rule Deployment Lifecycle, Validation Compiler, and LCM Migration

## 1. The Rule Compilation and Deployment Lifecycle

In Calculation Manager, business rules do not run directly as visual flowchart diagrams. They undergo a multi-phase compilation and deployment pipeline that converts visual XML descriptors into optimized Essbase calculation scripts (`.csc`) and registers them within Planning application security and navigation structures.

```
+---------------------------------------------------------------------------------------------------+
|                                  RULE DEPLOYMENT & LIFECYCLE PIPELINE                             |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [PHASE 1: DESIGN & SAVE (DRAFT)]                                                                 |
|  - Developer designs rule on Visual Canvas or Script Editor.                                      |
|  - Clicks [ SAVE ].                                                                               |
|  - Stored in Planning relational repository (HSP_CALCMGR_RULES).                                  |
|  - Status: "To Be Deployed" (End-users CANNOT see or run this version).                          |
|                                                                                                   |
|  [PHASE 2: VALIDATION]                                                                            |
|  - Clicks [ VALIDATE ] (or triggered automatically during Deploy).                                |
|  - Compiles Abstract Syntax Tree (AST) into temporary in-memory script.                           |
|  - Performs lexical analysis, syntax parsing, and outline member verification.                   |
|  - Reports errors or warnings in the Log & Message Pane.                                          |
|                                                                                                   |
|  [PHASE 3: COMPILATION & DEPLOYMENT]                                                              |
|  - Clicks [ DEPLOY ].                                                                             |
|  - Generates finalized Essbase Calculation Script string.                                         |
|  - Registers Rule in Planning Relational Catalog (HSP_ACTION, HSP_OBJECT).                        |
|  - Status: "Deployed" (Green Checkmark). Rule is live in Forms, Menus, and Job Scheduler!         |
|                                                                                                   |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. The Validation Engine Checks

The Calculation Manager compiler executes rigorous static code analysis during the validation phase:

| Validation Category | Specific Checks Executed | Common Compiler Error Messages |
| :--- | :--- | :--- |
| **Member Verification** | Cross-references every member name and function root against the active cube outline (`.otl`). | `Unknown member [MbrName] in formula.` |
| **Data Storage Integrity** | Verifies that target members on LHS are not tagged as **Dynamic Calc** or **Label Only**. | `Target member cannot be calculated or dynamic.` |
| **Syntax & Lexical Analysis** | Verifies matching parentheses `()`, quotes `""`, and terminating semicolons `;`. | `Syntax error: unexpected token or missing semicolon.` |
| **Variable Token Binding** | Validates that all `{VarName}` tokens exist in active scopes and have default values. | `Variable [VarName] cannot be resolved.` |
| **Cross-Dimension Validity** | Checks that member combinations in `->` syntax span distinct dimensions. | `Cannot reference multiple members from the same dimension in cross-dim operator.` |

---

## 3. Migration via Lifecycle Management (LCM)

Business rules, rule sets, variables, and templates are fully portable across Dev, Test, and Production environments using **Lifecycle Management (LCM)**.

### 3.1 LCM Artifact Paths in Snapshot ZIP
```
/resource/Calculation Manager/
  |-- Applications/
  |     `-- Vision/
  |           |-- Rules/
  |           |     |-- Calculate_Revenue.xml
  |           |     `-- Alloc_Corporate_Overhead.xml
  |           |-- RuleSets/
  |           |     `-- Monthly_Close.xml
  |           `-- Variables/
  |                 `-- Vision_Variables.xml
  |-- Global_Variables/
  `-- Templates/
        `-- Custom_Overhead_Allocation.xml
```

### 3.2 LCM Export / Import XML Schema
An inspection of the exported rule XML reveals how visual canvas coordinates and compiled calculation syntax are stored concurrently:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CalculationRule xmlns="http://xmlns.oracle.com/calcmgr" version="24.08.65">
    <Name>Calculate_Gross_Margin</Name>
    <Application>Vision</Application>
    <PlanType>OEP_FS</PlanType>
    <Description>Computes Gross Margin from Revenue and COGS</Description>
    <ExecutionType>Script</ExecutionType>
    <ScriptBody><![CDATA[
        FIX("Forecast", "Working", {RTP_Year})
          "Gross_Margin" = "Total_Revenue" - "Total_COGS";
        ENDFIX
    ]]></ScriptBody>
    <CanvasCoordinates>
        <Node id="1" type="FIX" x="120" y="50" width="300" height="200"/>
        <Node id="2" type="Formula" x="140" y="100" width="250" height="80"/>
    </CanvasCoordinates>
</CalculationRule>
```

---

## 4. Headless Deployment via EPM Automate

In continuous integration and delivery (CI/CD) pipelines, rules can be deployed headlessly:
```powershell
epmautomate deployFormulas "AppName" "CubeName" ruleNames="Calculate_Revenue,Alloc_Overhead"
```
This enables enterprise teams to deploy rules automatically across staging and production pods during release windows without manual UI clicks.


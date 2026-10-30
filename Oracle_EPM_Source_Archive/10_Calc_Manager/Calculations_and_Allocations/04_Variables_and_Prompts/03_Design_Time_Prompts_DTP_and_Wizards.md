# 03 Design-Time Prompts (DTP) vs. Runtime Prompts (RTP): Wizard Compilation

## 1. Architectural Distinction: DTP vs. RTP

Developers frequently confuse **Design-Time Prompts (DTP)** with **Runtime Prompts (RTP)**. While both present interactive dialogs to gather parameters, they operate at completely different phases of the software lifecycle and target different user audiences.

```
+---------------------------------------------------------------------------------------------------+
|                                      DTP vs. RTP LIFECYCLE PHASES                                 |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  DESIGN-TIME PROMPT (DTP) LIFECYCLE:                                                              |
|  [Rule Developer / Admin]                                                                         |
|            |                                                                                      |
|            | 1. Drags Template onto Canvas in Calculation Manager                                 |
|            v                                                                                      |
|  [DTP WIZARD DIALOG OPENS]                                                                        |
|  - Developer selects Cost Center, Target Account, Allocation Driver                               |
|            |                                                                                      |
|            | 2. Developer clicks [ Finish ]                                                       |
|            v                                                                                      |
|  [DTP COMPILER GENERATES STATIC CALC SCRIPT]                                                      |
|  - Logic is permanently compiled into the rule definition                                         |
|  - Occurs ONCE during development!                                                                |
|                                                                                                   |
|  -----------------------------------------------------------------------------------------------  |
|                                                                                                   |
|  RUNTIME PROMPT (RTP) LIFECYCLE:                                                                  |
|  [End-User / Financial Planner]                                                                   |
|            |                                                                                      |
|            | 1. Clicks "Save" on Web Form or launches Rule in Smart View                          |
|            v                                                                                      |
|  [RTP DIALOG OPENS]                                                                               |
|  - Planner selects "Working" and "FY25"                                                           |
|            |                                                                                      |
|            | 2. Planner clicks [ Launch ]                                                         |
|            v                                                                                      |
|  [ENGINE INJECTS VALUES INTO COMPILED SCRIPT & EXECUTES]                                          |
|  - Occurs EVERY SINGLE TIME the user runs the rule!                                               |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Comprehensive Comparison Matrix

| Architectural Dimension | Design-Time Prompt (DTP) | Runtime Prompt (RTP) |
| :--- | :--- | :--- |
| **Execution Phase** | **Design-Time** (During rule authoring in Calc Manager). | **Runtime** (When rule is executed by end-user or batch). |
| **Target Audience** | Rule Developer / EPM Administrator. | Financial Planner / End-User / Automated Script. |
| **Location** | Defined exclusively inside **Templates**. | Defined in Global, Application, Plan, or Rule variables. |
| **Script Generation** | Dynamically constructs code structures (`IF`, `FIX`, equations). | Injects member names or numbers into pre-existing code tokens. |
| **User Prompt Frequency** | Once per template insertion. | Every time the business rule is launched. |
| **Batch Automation Impact**| Zero impact on batch execution (already compiled into script).| Must pass parameters via CLI or REST payload (`RTP_Name=val`). |
| **Performance Overhead** | Zero runtime overhead. | Small parsing overhead ($< 10\text{ms}$) to bind runtime tokens. |

---

## 3. Dynamic Script Generation Using DTP Logic

DTPs allow templates to generate completely different calculation script blocks based on developer selections:

### Template DTP Logic (Architect Definition):
```xml
<TemplateLogic>
    <Condition test="[dtp_CalcMethod] == 'Straight-Line'">
        "Depr_Expense" = ("Asset_Cost" - "Salvage_Value") / [dtp_LifeMonths];
    </Condition>
    <Condition test="[dtp_CalcMethod] == 'Double-Declining'">
        "Depr_Expense" = ("Asset_Cost" - "Accum_Depr") * (2 / [dtp_LifeMonths]);
    </Condition>
</TemplateLogic>
```

### Resulting Compiled Script:
* If the developer selected `Straight-Line`, the compiled rule contains **only the Straight-Line equation**.
* The alternate Double-Declining code is omitted entirely, producing a clean, lean, and high-performance calc script.


# 01 Variable Architecture, Ten Data Types, and Scoping Hierarchy

## 1. Multi-Tiered Scoping Architecture

Variables in Calculation Manager are parameterized memory tokens that decouple business logic from hardcoded member names, dates, or numeric constants. Calculation Manager enforces a strict **4-Tier Scoping Hierarchy** that dictates where a variable is defined, where it can be referenced, and how name collisions are resolved.

```
+---------------------------------------------------------------------------------------------------+
|                                     VARIABLE SCOPING HIERARCHY                                    |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [LEVEL 1: GLOBAL SCOPE]                                                                          |
|  Available across ALL Applications in the entire EPM Cloud environment.                           |
|  (e.g., Global_Current_Year = "FY25", Global_Cutoff_Date = "2026-10-31")                          |
|             |                                                                                     |
|             v                                                                                     |
|  [LEVEL 2: APPLICATION SCOPE]                                                                     |
|  Available across ALL Cubes/Plan Types within a specific Application (e.g., Vision).              |
|  (e.g., App_Scenario = "Forecast", App_Currency = "USD")                                          |
|             |                                                                                     |
|             v                                                                                     |
|  [LEVEL 3: PLAN TYPE / DATABASE SCOPE]                                                            |
|  Available strictly within a specific Cube (e.g., OEP_FS or OEP_WFP).                             |
|  (e.g., Fin_Default_Account = "Net_Income", WFP_Max_Headcount = 500)                              |
|             |                                                                                     |
|             v                                                                                     |
|  [LEVEL 4: RULE SCOPE]                                                                            |
|  Private to a single Business Rule. Cannot be viewed or referenced by any other rule.             |
|  (e.g., Rule_Local_Driver = "Alloc_Basis")                                                        |
|                                                                                                   |
|  RESOLUTION PRECEDENCE:                                                                           |
|  Rule Scope > Plan Type Scope > Application Scope > Global Scope                                  |
|  (A Rule-level variable overrides an Application-level variable of the same name).                |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. The Ten Variable Data Types

Calculation Manager supports ten distinct variable types, each enforcing specific input validation and engine compilation formatting:

| Variable Type | Allowed Input | Essbase Script Format | Production Use Case |
| :--- | :--- | :--- | :--- |
| **1. Member** | Single outline member | `"MemberName"` | Slicing a specific department or entity in a FIX statement. |
| **2. Members** | Multiple comma-delimited members | `"Mbr1", "Mbr2", "Mbr3"` | Selecting multiple cost centers or accounts. |
| **3. String / Text** | Freeform character sequence | `"TextValue"` | Defining dynamic log prefixes or UDA string tags. |
| **4. Number** | Decimal floating-point number | `125000.50` | Currency conversion threshold or financial rate. |
| **5. Integer** | Whole integer number | `12` | Number of projection periods or loop limit counters. |
| **6. Date** | Formatted calendar date | `YYYYMMDD` integer | Start date for employee payroll calculations. |
| **7. Boolean** | Logical flag (`True` / `False`) | `1` / `0` | Branching flag to include or bypass Capex offsets. |
| **8. Cross Dimension** | Multi-member intersection tuple | `"USD"->"Local_Entity"` | Central driver rate location. |
| **9. Dimension** | Outline dimension name | `Account`, `Entity` | Dynamic dimension iteration in templates. |
| **10. Percent** | Decimal percentage ratio | `0.15` (for 15%) | Inflation markup factor or tax rate multiplier. |

---

## 3. Variable Designer Interface

Variables are configured through the **Variable Designer** dialog accessible via the toolbar or **Tools -> Variable Designer**:

```
+---------------------------------------------------------------------------------------------------+
|                                     VARIABLE DESIGNER DIALOG                                      |
+---------------------------------------------------------------------------------------------------+
| Scope: [Application: Vision               ]   Variable Type: [Member                     ]       |
| Name:  [var_CurrentYear                   ]   Dimension:     [Years                      ]       |
+---------------------------------------------------------------------------------------------------+
| Default Value: ["FY25"                    ]   Is Runtime Prompt (RTP): [X] Enabled                |
| Prompt Text:   [Select Current Fiscal Year]                                                       |
| Member Limits: [@DESCENDANTS("All_Years") ]                                                       |
+---------------------------------------------------------------------------------------------------+
```

---

## 4. Substitution Variables vs. Calculation Manager Variables

Developers often confuse Essbase **Substitution Variables** with Calculation Manager Variables:

| Feature | Essbase Substitution Variable (`&SubVar`) | Calculation Manager Variable (`{CalcVar}`) |
| :--- | :--- | :--- |
| **Storage Layer** | Essbase Server/App/DB configuration file | Planning Relational Metadata Repository (`HSP_CALCMGR_VARIABLES`) |
| **Syntax** | `&CurYear` | `{CurYear}` |
| **Runtime Prompting** | Cannot prompt end-users during form save | Fully supports interactive end-user prompts (RTP) |
| **Scope Flexibility** | Server, App, Database | Global, Application, Plan Type, Rule |
| **Maintenance** | Updated via EPM Automate / MaxL / UI | Managed via Variable Designer in Calc Manager |
| **Best Practice** | Use for enterprise-wide static boundaries (`&CurYear`, `&CurPeriod`). | Use when rules require dynamic user inputs or modular scoping. |


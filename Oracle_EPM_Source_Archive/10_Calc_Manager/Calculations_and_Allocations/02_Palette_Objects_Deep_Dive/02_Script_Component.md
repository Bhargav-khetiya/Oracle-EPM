# 02 Script Component: Embedding Native Essbase Code and Variable Tokens

## 1. Role and Architecture of the Script Component

The **Script Component** acts as an unrestricted raw code container within the visual Calculation Manager canvas. While visual Formula and Condition components provide structured declarative modeling, real-world enterprise calculations often require specialized Essbase commands, multidimensional macros, temporary variables, and low-level tuning switches that cannot be represented by simple formula cards.

```
+---------------------------------------------------------------------------------------------------+
|                                     SCRIPT COMPONENT IN CANVAS                                    |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  VISUAL CANVAS WORKSPACE                                                                          |
|  +---------------------------------------------------------------------------------------------+  |
|  | FIX ("FY25", "Plan", "Working")                                                             |  |
|  |   |                                                                                         |  |
|  |   v                                                                                         |  |
|  |  +---------------------------------------------------------------------------------------+  |  |
|  |  | SCRIPT COMPONENT: [Script_Calculate_Depreciation]                                     |  |  |
|  |  |                                                                                       |  |  |
|  |  | /* Direct Essbase Script Code Block */                                                |  |  |
|  |  | VAR AssetLife = 60;                                                                   |  |  |
|  |  | "Depr_Expense" = @SLN("Capex_Cost"->"BegBalance", "Salvage_Val", AssetLife);          |  |  |
|  |  |                                                                                       |  |  |
|  |  | IF (@ISMBR("Jan"))                                                                    |  |  |
|  |  |   "Accum_Depr" = "Depr_Expense";                                                      |  |  |
|  |  | ELSE                                                                                  |  |  |
|  |  |   "Accum_Depr" = @PRIOR("Accum_Depr") + "Depr_Expense";                              |  |  |
|  |  | ENDIF                                                                                 |  |  |
|  |  +---------------------------------------------------------------------------------------+  |  |
|  |   |                                                                                         |  |
|  |   v                                                                                         |  |
|  | ENDFIX                                                                                      |  |
|  +---------------------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. When to Use Script Components vs. Visual Components

| Requirement / Scenario | Use Visual Components (Formula/Condition) | Use Script Component |
| :--- | :--- | :--- |
| Simple $A = B \times C$ calculations | **Yes** (Clear visual audit trail) | Unnecessary overhead |
| Temporary script variables (`VAR TempVal;`) | Not supported | **Mandatory** |
| Low-level tuning switches (`SET CACHE`, `SET UPDATECALC`) | Not supported | **Mandatory** |
| Deeply nested recursive looping with `@CURRMBR` | Clutters canvas with 20+ boxes | **Yes** (Clean 10-line script) |
| Complex IF-ELSE with 10+ conditions | Creates massive visual diagram | **Yes** (Concise code) |
| Novice developer maintenance | **Yes** (Intuitive UI) | Requires calc script coding skills |

---

## 3. Variable Interpolation Syntax (`{VariableName}`)

Script Components seamlessly integrate with Calculation Manager's variable engine. To inject a variable into raw script code:
* Wrap the variable name in curly braces: `{VariableName}`.
* At compilation and runtime, Calculation Manager's preprocessor replaces the token with the evaluated member string, numeric value, or runtime prompt selection.

### Production Example with Runtime Prompts (RTP)
```sql
/*
 * Script Component: Custom Overhead Allocation
 * Variables: {RTP_Scenario}, {RTP_Year}, {RTP_Cost_Center}
 */

SET UPDATECALC OFF;
SET AGGSPARSESEL ON;

FIX({RTP_Scenario}, {RTP_Year}, "Working", {RTP_Cost_Center})
  "Corporate_Overhead" (
    IF (@ISMBR("Sales_Division"))
      "Corporate_Overhead" = "Total_Cost" * 0.15;
    ELSEIF (@ISMBR("Marketing_Division"))
      "Corporate_Overhead" = "Total_Cost" * 0.10;
    ELSE
      "Corporate_Overhead" = "Total_Cost" * 0.05;
    ENDIF
  )
ENDFIX
```

---

## 4. Best Practices for Script Components

1. **Keep Blocks Modular**: Do not place a 2,000-line monolithic script inside a single Script Component. Break the rule into logical stages on the canvas (e.g., *Phase 1: Clear Target*, *Phase 2: Calculate Drivers*, *Phase 3: Rollup*).
2. **Comment Every Block**: Always include header comment blocks documenting inputs, outputs, author, and revision history.
3. **Declare Semicolons Reliably**: Every statement inside a Script Component must terminate with a semicolon `;`. Missing semicolons will fail validation with cryptic syntax errors.


# @ISACCTYPE

## Overview

`@ISACCTYPE` is a **native Essbase boolean function** in Oracle EPM Cloud (PBCS/EPBCS). It evaluates the currently calculating member (usually an Account) and returns `TRUE` or `FALSE` based on whether that member is structurally tagged with a specific **Account Type** property in the dimension outline.

### Why Does This Function Exist?

In EPM Cloud, the `Account` dimension is fundamentally different from other dimensions because its members have special mathematical behaviors based on their "Account Type" (e.g., Expense, Revenue, Asset, Liability, or Saved Assumption). 
When an Essbase aggregation runs, it inherently knows to subtract Expenses from Revenue. However, when writing custom allocation scripts or driver-based models, you often need to branch your logic based on these properties. For example, if you are inflating next year's budget, you might want to increase all "Revenue" accounts by 10%, but decrease all "Expense" accounts by 2%. 
You *could* manually list all 500 expense accounts in an `IF` statement, or create a custom UDA. But that is redundant and error-prone. `@ISACCTYPE` allows the script to directly read the native Account Type property that is already maintained in the outline, making the script highly dynamic and maintenance-free.

### When to Use It

- **Dynamic Forecasting**: Applying different inflation or deflation growth rates dynamically based on whether the calculating account is a Revenue or Expense line item.
- **Cash Flow Modeling**: Reversing the mathematical sign of an account (multiplying by `-1`) specifically if it is an Asset or Liability type before pushing it to a Cash Flow reporting hierarchy.
- **Targeted Zero-Outs**: Clearing out all "Saved Assumption" input metrics prior to a data load, while leaving the financial "Expense" actuals completely untouched.

---

## Category

**Boolean & Conditional / Outline Properties / Essbase Native Functions**

---

## Syntax

```essbase
@ISACCTYPE(Account_Type_Keyword)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Account_Type_Keyword` | Keyword | ✅ Yes | The explicit system keyword defining the account type you are checking for. Valid keywords are:<br>- `FIRST` or `EXPENSE`<br>- `LAST` or `REVENUE`<br>- `AVERAGE`<br>- `ASSET`<br>- `LIABILITY`<br>- `EQUITY`<br>- `NONCURRENCY` or `SAVED_ASSUMPTION` |

*(Note: While `FIRST`, `LAST`, and `AVERAGE` technically refer to Time Balance properties rather than pure Account Types, this function historically evaluates both property sets).*

---

## Return Value

**Return Type**: Boolean (`TRUE` or `FALSE`)

Returns `TRUE` (1) if the currently calculating member matches the requested type. Returns `FALSE` (0) if it does not.
- **Evaluation Target**: This function inherently evaluates the member currently being processed in the `Account` dimension. You do not pass a specific member name into the function (e.g., you write `@ISACCTYPE(EXPENSE)`, not `@ISACCTYPE("Salaries", EXPENSE)`).

---

## How It Works (Behind the Scenes)

1. **Trigger**: The Essbase engine encounters the `IF(@ISACCTYPE(...))` block during a calculation pass.
2. **Context Query**: It looks at the specific member it is currently calculating (e.g., `"Travel_Expense"`).
3. **Property Lookup**: It queries the active `.otl` outline properties for that member, specifically checking the "Account Type" or "Time Balance" flags.
4. **Comparison**: It compares the outline property to the `Account_Type_Keyword` provided in the script.
5. **Return**: It returns `TRUE` or `FALSE` to resolve the `IF` statement.

---

## Syntax Variants & Scenarios

### Variant 1: Checking for Expense Types

```essbase
/* 
   If the current account is an Expense type, returns TRUE.
*/
IF(@ISACCTYPE(EXPENSE))
```

### Variant 2: Checking for Saved Assumptions (Drivers)

```essbase
/* 
   If the current account is a statistical driver (Non-Currency), returns TRUE.
*/
IF(@ISACCTYPE(NONCURRENCY))
```

---

## Practical Examples

### Example 1: Global Inflation Adjustments

**Scenario**: The CFO dictates a top-down mandate: Next year's plan (`"FY25"`) must assume a 10% increase in all Revenue, but mandate a 3% cut to all Operating Expenses. Instead of managing complex UDAs, the administrator writes a single rule that iterates through every account and dynamically branches the math based on the native account type.

```essbase
FIX("FY25", "Working", "Total_Company")
    
    /* 
       1. This calculation runs on every single Account in the P&L.
       We use a massive FIX, but control the logic with IF statements.
    */
    FIX(@IDESCENDANTS("Net_Income"))
        
        /* 
           2. Check if the active account is a Revenue Account.
           If TRUE, increase by 10%.
        */
        IF(@ISACCTYPE(REVENUE))
            
            "Plan" = "Prior_Year_Actuals" * 1.10;
            
        /* 
           3. If it wasn't Revenue, check if it's an Expense.
           If TRUE, cut by 3%.
        */
        ELSEIF(@ISACCTYPE(EXPENSE))
            
            "Plan" = "Prior_Year_Actuals" * 0.97;
            
        /* 
           4. If it is neither (e.g., a margin percentage or saved assumption),
           simply carry the value forward flat.
        */
        ELSE
            
            "Plan" = "Prior_Year_Actuals";
            
        ENDIF
        
    ENDFIX
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Not Fixing on the Account Dimension | Running on Entities | `@ISACCTYPE` is completely useless if the script is iterating through the `Entity` dimension and only calculating a single hardcoded account (like `"Revenue" = ...`). The function only works when Essbase is actively sweeping *across* the Account dimension members. Ensure your `FIX` statement is explicitly iterating across the accounts you want to evaluate |
| Relying on Strings | `IF(@ISACCTYPE("EXPENSE"))` | The parameter is a **Keyword**, not a string. Do NOT enclose `EXPENSE` or `REVENUE` in quotes. If you use quotes, the compiler will treat it as a member name or string and throw a severe syntax error. Use bare keywords |
| Confusing `SAVED_ASSUMPTION` | EPM Cloud Terminology | In the Web UI for EPM Cloud (PBCS), the account type is often labeled "Saved Assumption" (used for headcounts, rates, drivers). Under the hood, in the Essbase `.otl`, this is technically the `NONCURRENCY` flag. While modern Calc Manager sometimes supports `@ISACCTYPE(SAVED_ASSUMPTION)`, it is safer and more universally compliant to use `@ISACCTYPE(NONCURRENCY)` for statistical accounts |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@ISUDA`](./@ISUDA.md) | The alternative approach. If you cannot rely on native Account Types (e.g., you need to differentiate between "Fixed Expenses" and "Variable Expenses"), you must create UDAs in the outline and check for them using `@ISUDA` |
| [`@ISMBR`](./@ISMBR.md) | The direct structural check. Used when you want to execute logic on a specific, explicitly named account, rather than a broad property category |
| [`@ISATTRIBUTE`](./@ISATTRIBUTE.md) | Similar to `ISACCTYPE`, but checks user-defined dimensional attributes rather than the hardcoded, native financial property flags |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — ISACCTYPE](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/isacctype.html)

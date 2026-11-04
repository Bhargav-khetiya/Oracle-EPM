# SET EMPTYMEMBERSETS

## Overview

`SET EMPTYMEMBERSETS` is a **native Essbase system directive** in Oracle EPM Cloud (PBCS/EPBCS). It controls how the calculation compiler handles `FIX` statements that evaluate to an empty list (zero members). 

### Why Does This Function Exist—

In highly dynamic, automated calculation scripts, the `FIX` statement is often populated by variable queries, attributes, or UDAs rather than hardcoded member names. 
For example, you might write a script that runs every night and fixes on `@UDA("Entity", "Requires_Calculation")`. 
What happens on a night where *zero* entities have that UDA— 
By default, the Essbase compiler sees that the `@UDA` function returned an empty set. Because the `FIX` is technically invalid (you can't fix on nothing), Essbase throws a severe syntax error, halts the entire script, and flags a failure in the Job Console.
If you have a massive batch process, this failure crashes the entire overnight chain. 
`SET EMPTYMEMBERSETS ON` solves this. It overrides the compiler's strict validation. It tells the engine: "If a FIX statement returns zero members, do NOT crash. Simply skip the enclosed code, log a warning, and proceed to the next line of the script." It is a vital safety net for dynamic automation.

### When to Use It

- **UDA / Attribute Driven Logic**: Wrapping `FIX` statements that rely on dynamically shifting metadata tags (e.g., `"Active_Projects"`, `"Open_Stores"`) that may occasionally return zero results.
- **Substitution Variable Fallbacks**: Protecting a script that uses a variable like `&Target_Region`. If an admin temporarily clears the variable, the script will safely bypass the logic rather than crashing.
- **Lights-Out Automation**: Ensuring that overnight batch jobs never throw fatal exceptions due to temporary data anomalies or empty hierarchical branches.

---

## Category

**System & Optimization / Calculation Directives / Essbase Native Functions**

---

## Syntax

```essbase
SET EMPTYMEMBERSETS ON | OFF;
```

*(Note: Because this is a `SET` command, it does NOT use the `@` prefix, and it must end with a semicolon `;`).*

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ON | OFF` | Keyword | ✅ Yes | The explicit toggle switch. <br>- `ON`: Instructs the compiler to safely ignore empty `FIX` statements and continue execution. <br>- `OFF`: Default behavior. An empty `FIX` statement will trigger a fatal calculation error and halt the script. |

---

## Return Value

**Return Type**: Passthrough (Engine State Modification)

This command does not return a value. It alters the internal strictness of the Essbase script compiler.
- **Scope**: The `SET` command affects the entire calculation script from the line it is declared downward.
- **Job Console Output**: When set to `ON`, an empty `FIX` will still generate a message in the Job Console (usually a Warning stating that the member set is empty), but the script status will return as **Successful** rather than **Error**.

---

## How It Works (Behind the Scenes)

1. **Directive Read**: The compiler hits `SET EMPTYMEMBERSETS ON;`. It toggles the internal `IGNORE_EMPTY_FIX` flag to TRUE.
2. **Compilation Scan**: The compiler reaches `FIX(@UDA("Project", "Flagged"))`.
3. **Array Resolution**: It scans the outline for the UDA. It finds zero matches. The array is empty `[]`.
4. **Validation Check**: Normally, the compiler would abort here. Because the flag is `ON`, the compiler suppresses the abort command.
5. **Bypass**: The engine completely skips all code inside that specific `FIX`...`ENDFIX` block and immediately resumes execution on the line directly following the `ENDFIX`.

---

## Syntax Variants & Scenarios

### Variant 1: Activating the Safety Net

```essbase
/* 
   Placed at the top of the script to protect against dynamic FIX failures.
*/
SET EMPTYMEMBERSETS ON;
```

---

## Practical Examples

### Example 1: Protecting a Targeted Bonus Calculation

**Scenario**: A company calculates a `"Special_Bonus"` for employees. However, this bonus only applies to employees tagged with the `"Bonus_Eligible"` UDA. The HR team updates this UDA monthly. In January, zero employees are eligible. If the script runs natively, it will crash and take down the entire payroll batch. The admin adds `EMPTYMEMBERSETS ON`.

```essbase
/* 
   1. We enable the safety net to prevent crashes.
*/
SET EMPTYMEMBERSETS ON;

/* 
   2. The FIX relies on a dynamic UDA.
   In January, this returns zero members.
*/
FIX(@UDA("Employee", "Bonus_Eligible"), "Working", "FY25")
    
    /* 
       3. Because EMPTYMEMBERSETS is ON, Essbase sees the empty array 
       and simply skips this math entirely. It does not crash.
    */
    "Special_Bonus" = "Base_Salary" * 0.15;
    
ENDFIX

/* 
   4. The script successfully continues down here, executing the 
   rest of the payroll logic.
*/
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Masking Real Errors | "Why didn't my script do anything— | While this command is a great safety net, it can also mask genuine, catastrophic mistakes. If you accidentally misspell the UDA (`@UDA("Employee", "Bnus_Eligible")`), the array will be empty. If `EMPTYMEMBERSETS` is `ON`, the script will skip the math and report "Success". You will have no idea that the bonus failed to calculate until users complain. Always review your Job Console warnings, even on successful scripts |
| Using it for Hardcoded Missing Members | Syntax Errors | This command protects against *functions* returning empty arrays (like `@UDA` or `@CHILDREN`). It does NOT protect against hardcoding a member name that doesn't exist. If you write `FIX("Store_999")` and Store 999 does not exist in the outline, the compiler will still crash with an "Unknown Member" error before it even evaluates the `SET` command |
| Using `@` Prefix | `@SET EMPTYMEMBERSETS` | This is a calculation macro. It is not a function. If you put an `@` symbol in front of it, the compiler will crash immediately |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@UDA`](../09_Boolean_Conditional/@UDA.md) | One of the primary dynamic array functions that necessitates the use of `EMPTYMEMBERSETS` to prevent crashes when the tag is missing |
| [`@ATTRIBUTE`](../04_Member_Navigation/@ATTRIBUTE.md) | Another dynamic array query function frequently protected by this directive |
| `FIX` | The foundational scoping block that this directive explicitly governs |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Directives — SET EMPTYMEMBERSETS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/set_emptymembersets.html)

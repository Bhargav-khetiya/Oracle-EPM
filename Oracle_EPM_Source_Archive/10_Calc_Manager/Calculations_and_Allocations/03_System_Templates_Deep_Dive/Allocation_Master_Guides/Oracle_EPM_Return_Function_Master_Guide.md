# Oracle EPM: The Ultimate Master Guide to the @RETURN Function (Essbase)


---

## 1. Introduction to @RETURN
Imagine you are building a house (running a calculation). Before you pour the concrete, you notice the wooden frame is crooked. What do you do? You stop working immediately and tell the site manager there is a problem. 

In Oracle EPM (Essbase), `@RETURN` is that **Emergency Stop Button**. It is a command you put inside a Calculation Script. If it detects a problem—like a user entering a negative number where it shouldn't be—it immediately halts the entire calculation and sends a custom text message to the user explaining exactly what went wrong.

---

## 2. Architectural Deep Dive: How @RETURN Actually Works

### The Mechanism
The `@RETURN` function works as a **hard exit**. When Essbase executes a calculation script, it reads top to bottom, processing blocks of data. The moment it hits `@RETURN` within an `IF` statement, it terminates the process.

1. **The Trigger**: The condition in the `IF` statement is met (e.g., `Profit < 0`).
2. **The Halt**: Essbase aborts the rest of the script. It does not calculate the next block. It does not finish the current fix statement.
3. **The Payload**: It generates a string (your error message).
4. **The Delivery**: The message is passed from the Essbase engine back to the Planning Web UI (Job Console) and the application log. The user running the business rule sees this message pop up on their screen.

### The Limitations (Crucial!)
- **Calc Scripts Only**: You **cannot** use `@RETURN` inside a Member Formula (Dynamic Calc or Store). It is strictly for Business Rules / Calculation Scripts.
- **No Transactional Rollback**: If your script calculates and saves data for Entity A, and then hits an `@RETURN` while processing Entity B, the data for Entity A **remains changed in the database**. It does not "undo" the work it did before the error occurred.

---

## 3. Every Parameter Explained (Syntax Breakdown)

**Syntax:** `@RETURN ("ErrorMessage", [,INFO|ERROR|WARNING])`

### Parameter 1: `ErrorMessage`
This is the text string that will be displayed to the user.
- **Static String**: You can hardcode a message in quotes: `"Data is invalid."`
- **Dynamic String**: You can use string functions like `@CONCATENATE` and `@NAME` to build a dynamic message that tells the user exactly *where* the error happened.

### Parameter 2: `Priority Level` (INFO | ERROR | WARNING)
This dictates how the message is flagged in the Job Console and application logs.
- **INFO**: Flags it as an informational message. **(Note: It STILL stops the calculation script!)**
- **WARNING**: Flags it as a warning (yellow triangle). Use this for non-critical logic failures.
- **ERROR**: Flags it as a hard failure (red X). Use this for severe data integrity violations.

*(If you omit this parameter, it defaults to `INFO`.)*

---

## 4. Comprehensive Hands-On Scenarios (Mastering Every Use Case)

### Hands-On 1: Basic Input Validation (Preventing Negative Expenses)
**Goal:** Stop the rule if a user enters negative expenses.
**Code:**
```essbase
FIX ("Actual", "FY24", "Working")
    "Total_Expenses" (
        IF ("Total_Expenses" < 0)
            @RETURN("Error: Expenses cannot be negative. Please correct your input.", ERROR);
        ENDIF
    )
ENDFIX
```

### Hands-On 2: Data Integrity Checks (Balance Sheet Balancing)
**Goal:** Ensure Assets = Liabilities + Equity before running a heavy consolidation.
**Code:**
```essbase
FIX ("Actual", "FY24")
    "Check_Account" (
        IF ("Total_Assets" <> ("Total_Liabilities" + "Total_Equity"))
            @RETURN("Data Integrity Violation: The Balance Sheet does not balance. Consolidations aborted.", ERROR);
        ENDIF
    )
ENDFIX
```

### Hands-On 3: Dynamic Messages (Telling the User Exactly Who Failed)
**Goal:** If a specific Market has negative profit, tell the user *which* Market it is.
**Code:**
```essbase
FIX(@DESCENDANTS("Market"))
    "Profit" (
        IF ("Profit" < 0)
            @RETURN(@CONCATENATE("Calculation aborted. Negative profit found in Market: ", @NAME(@CURRMBR("Market"))), ERROR);
        ENDIF
    )
ENDFIX
```
*(Pro Tip: `@CURRMBR` grabs the current member being calculated, `@NAME` turns it into a string, and `@CONCATENATE` glues it to your text.)*

### Hands-On 4: Advanced Dynamic Messages (Multiple Concatenations)
**Goal:** Essbase's `@CONCATENATE` only takes two strings at a time. To build a long sentence, you must nest them.
**Code:**
```essbase
FIX(@DESCENDANTS("Entity"))
    "Budget" (
        IF ("Budget" > "Target")
            @RETURN(
                @CONCATENATE(
                    @CONCATENATE("Warning: Entity [", @NAME(@CURRMBR("Entity"))),
                    "] has exceeded the Corporate Target. Rule stopped."
                ), 
                WARNING
            );
        ENDIF
    )
ENDFIX
```

### Hands-On 5: Fail-Fast Architecture (Checking #MISSING)
**Goal:** Don't waste time running a 30-minute allocation script if the driver data is missing.
**Code:**
```essbase
FIX("No_Entity")
    "Allocation_Driver" (
        IF (@ISMBRMISSING("Allocation_Driver"))
            @RETURN("Allocation aborted: The driver data has not been loaded for this period.", INFO);
        ENDIF
    )
ENDFIX
/* Heavy allocation logic goes down here, but won't run if the driver is missing */
```

### Hands-On 6: Using INFO to Confirm a State
**Goal:** Sometimes you just want to stop a rule gracefully because there's no work to do, without making the user think there is an "Error".
**Code:**
```essbase
FIX("Current_Month")
    "Data_Flag" (
        IF ("Data_Flag" == 1)
            @RETURN("Data has already been locked for this month. No calculations were necessary.", INFO);
        ENDIF
    )
ENDFIX
```

---

## 5. Edge Cases & Bizarre Behaviors

1. **The "INFO" Trap:** Many developers assume `INFO` means "Log this message and keep calculating." **This is false.** `@RETURN` *always* immediately halts the script, regardless of the priority level. If you just want to log a message without stopping, you cannot use `@RETURN`. (You would need Groovy or a custom logging mechanism).
2. **Member Formulas Will Crash:** If you try to save a Member Formula in the Outline that contains `@RETURN`, Essbase will throw a syntax error. It is exclusively for Calc Scripts.
3. **Block Processing Order Matters:** Essbase calculates in blocks based on your sparse dimensions. If you have an `@RETURN` in a `FIX` on 100 Entities, and the error condition is met on the 50th Entity, the calculations for the first 49 Entities are already written to the database! Be very careful using `@RETURN` in the middle of data-altering scripts. Best practice is to put all `@RETURN` validation checks at the very top of your script *before* any data modification happens.
4. **Quotation Mark Errors:** When using `@CONCATENATE`, balancing your double quotes `"` is notoriously difficult and causes validation errors. Always construct your strings carefully.

---

## 6. Advanced Technical Questions

**Q1: Does @RETURN rollback data?**
> **A:** **No.** Essbase does not have transactional rollback for calc scripts. If the script modified data blocks before hitting the `@RETURN` statement, those modifications remain saved in the database. This is why validation checks should occur at the beginning of the script.

**Q2: I want to send a warning message to the Job Console, but I want the script to finish calculating. Can I use `@RETURN("Message", WARNING)`?**
> **A:** **No.** Any use of `@RETURN`, regardless of whether it is INFO, WARNING, or ERROR, will immediately stop the calculation. To log without stopping, you would need to use Groovy scripting (e.g., `println`) instead of standard Essbase calc scripts.

**Q3: How do I tell the user the exact intersection that caused the error?**
> **A:** You must nest `@CONCATENATE` and `@NAME(@CURRMBR("Dimension"))` functions. Since `@CONCATENATE` only accepts two arguments, building a string with 3 or 4 dimensions requires deep nesting: 
> `@CONCATENATE(@CONCATENATE("Error at ", @NAME(@CURRMBR("Entity"))), @NAME(@CURRMBR("Account")))`.

**Q4: Can I use `@RETURN` inside an `@IF` in a member formula?**
> **A:** **No.** The documentation specifically states `@RETURN` can only be used in calculation scripts, not member formulas.

**Q5: What happens if an `@RETURN` condition is met inside a Business Rule that is triggered by a Data Form "Save" action?**
> **A:** The rule fails, the message is displayed directly on the user's screen in the web UI as a pop-up, and (depending on form configuration) the data save itself may be aborted if the rule is set to "Run Before Save".

**Q6: Can I return the actual numerical value that caused the error in my message?**
> **A:** Standard Essbase calc scripts struggle to convert numbers to strings inside `@RETURN`. You generally use Groovy for this. However, in pure Essbase, you can use `@HspNumToString` (if available in your EPM version) to convert the number, then `@CONCATENATE` it into the message.

**Q7: I wrote `@RETURN("Failed", ERROR)` but the syntax check failed. Why?**
> **A:** Ensure it is inside a valid block. `@RETURN` must be tied to a member block or inside an `IF` statement that is tied to a member. For example: `"Account" ( IF(condition) @RETURN(...) ENDIF )`

**Q8: If I have a parent script that uses `RUNSQL` or calls another script, and the child script hits `@RETURN`, does the parent script keep running?**
> **A:** Generally, the entire job terminates. An `@RETURN` throws a termination signal to the Essbase calculation engine, which bubbles up and stops the parent process.

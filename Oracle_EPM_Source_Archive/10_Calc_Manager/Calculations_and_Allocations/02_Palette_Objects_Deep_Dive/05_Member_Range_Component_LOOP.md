# 05 Member Range Component: Dimensional Looping, `@CURRMBR`, and Recurrence

## 1. Dimensional Iteration Architecture

In financial and operational planning models, certain calculations cannot be evaluated in a single vector operation because the current period or step depends directly on the calculated result of the preceding period (recurrence / forward dependency). Examples include:
* Beginning Cash Balance = Prior Period Ending Cash Balance.
* Asset Depreciation & Amortization schedules.
* Cumulative multi-period headcounts.

The **Member Range Component** (often paired with looping constructs) provides the visual mechanism in Calculation Manager to iterate sequentially across an ordered range of members in a specific dimension.

```
+---------------------------------------------------------------------------------------------------+
|                                 MEMBER RANGE SEQUENTIAL ITERATION                                 |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  DIMENSION: Period (Ordered Range: Jan -> Feb -> Mar -> ... -> Dec)                               |
|                                                                                                   |
|  [Jan]                                                                                            |
|   |-- Beg_Cash = Initial_Input                                                                    |
|   |-- Ending_Cash = Beg_Cash + Jan_Inflow - Jan_Outflow = $10,000                                 |
|   |                                                                                               |
|   v (Passes calculated Ending_Cash to next iteration)                                             |
|  [Feb]                                                                                            |
|   |-- Beg_Cash = @PRIOR(Ending_Cash) = $10,000                                                    |
|   |-- Ending_Cash = Beg_Cash + Feb_Inflow - Feb_Outflow = $14,000                                 |
|   |                                                                                               |
|   v                                                                                               |
|  [Mar ... Dec]                                                                                    |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Properties Pane Configuration

When configuring a Member Range Component on the visual canvas:

| Property Field | Setting / Value | Description |
| :--- | :--- | :--- |
| **Dimension** | Period / Years / Custom Dim | The dimension whose members will be traversed sequentially. |
| **Member Range Specification** | Range or Member Set | Comma-delimited list or range operator: `"Jan":"Dec"`, `@LEVMBRS("Period", 0)`. |
| **Direction** | Forward / Backward | Traversal order (Forward = Jan to Dec; Backward = Dec to Jan). |
| **Condition / Break** | Optional Expression | Halts loop execution if condition is met early (e.g., Cash balance drops below 0). |

---

## 3. Dynamic Member Navigation: `@CURRMBR`, `@PRIOR`, and `@NEXT`

Inside a Member Range Component, calculations leverage Essbase time-series and navigation functions to dynamically reference surrounding coordinates:

### 3.1 `@CURRMBR(Dimension)`
Returns the member name of the current coordinate being processed in the loop:
```sql
/* Dynamically retrieves inflation rate tagged to the active month */
"Inflation_Factor" = "Base_Rate" * @XREF(RefApp, @CURRMBR("Period"));
```

### 3.2 `@PRIOR(Member [, n, RangeList])`
Fetches the value of `Member` from $n$ steps prior within the defined member range:
```sql
/* Standard Beginning Balance Roll-forward */
"Beg_Inventory" = 
  @IF(@ISMBR("Jan"), 
      "Initial_Stock", 
      @PRIOR("Ending_Inventory", 1, "Jan":"Dec"));
```

### 3.3 `@NEXT(Member [, n, RangeList])`
Fetches values from future periods in the range (e.g., looking ahead to forecast requirements).

---

## 4. Production Looping Pattern: Multi-Year Debt Amortization

```sql
/*
 * Compiled Calculation Manager Rule: Debt Amortization
 * Iterates across Years FY24:FY28 and Periods Jan:Dec
 */

FIX("Plan", "Working", "Corp_Treasury", "USD")
  FIX("FY24":"FY28")
    FIX("Jan":"Dec")
      "Principal_Balance" (
        IF (@ISMBR("FY24") AND @ISMBR("Jan"))
          "Beg_Balance" = "Initial_Loan_Amount";
        ELSE
          "Beg_Balance" = @PRIOR("End_Balance", 1, "Jan":"Dec");
        ENDIF;

        "Monthly_Interest" = "Beg_Balance" * ("Annual_Interest_Rate" / 12);
        "Principal_Payment" = "Total_Monthly_Payment" - "Monthly_Interest";
        "End_Balance" = "Beg_Balance" - "Principal_Payment";
      )
    ENDFIX
  ENDFIX
ENDFIX
```

---

## 5. Performance Traps in Member Range Traversal

1. **Unbounded Ranges**: Specifying `"All Periods"` instead of Level 0 leaf periods (`@LEVMBRS("Period", 0)`) causes the loop to process quarter summary members (`Q1`, `Q2`), corrupting the roll-forward.
2. **Dense vs. Sparse Looping**: Looping across a **Dense** dimension (Period) is in-memory and blazingly fast. Looping across a **Sparse** dimension (e.g., sequentially traversing 1,000 Entities) forces Essbase to swap blocks constantly in and out of the data cache, causing severe disk thrashing.


# Calculation Functions Reference — Complete Guide

> **Section:** 05 — Calc Manager and Business Rules  
> **File:** 03 — Calculation Functions Reference  
> **Difficulty:** Intermediate → Advanced  
> **Prerequisites:** [01_Calc_Manager_Overview](./01_Calc_Manager_Overview.md), [02_Business_Rules_Design](./02_Business_Rules_Design.md)

---

## What Are Calculation Functions?

Calculation functions (often called "@functions") are built-in operations available in Essbase calc scripts and Calculation Manager. They perform member navigation, data retrieval, mathematical operations, string manipulation, and more.

EPM Cloud provides **450+ functions** across 20 categories. This reference covers the most important ones organized by purpose.

---

## Function Categories at a Glance

| Category | Count | Key Functions | Use Case |
|----------|-------|---------------|----------|
| Flow Control | ~10 | FIX, IF, LOOP, ENDFIX | Structure calculations |
| SET Commands | ~15 | SET CALCPARALLEL, SET CREATEBLOCKONEQ | Configure engine behavior |
| Calc Commands | ~10 | AGG, CALC DIM, DATACOPY, CLEARDATA | Bulk operations |
| Member Navigation | ~30 | @CHILDREN, @DESCENDANTS, @PARENT, @SIBLINGS | Traverse hierarchies |
| Data Access | ~15 | @PARENTVAL, @ANCESTVAL, @PRIOR, @NEXT | Read related values |
| Mathematical | ~15 | @SUM, @AVG, @MAX, @MIN, @ROUND | Standard math |
| Statistical | ~10 | @STDEV, @CORRELATION, @RANK, @MEDIAN | Statistical analysis |
| Financial | ~10 | @IRR, @NPV, @SLN, @SYD, @INTEREST | Financial calculations |
| Boolean/Conditional | ~20 | @ISMBR, @ISANCEST, @ISDESC, @ISLEV, @ISGEN | Test member properties |
| String | ~10 | @CONCATENATE, @SUBSTRING, @NAME, @LIKE | Text operations |
| Date/Time | ~20 | @DATEDIFF, @DATEROLL, @TODATE, @TODAY | Date calculations |
| CalcMgr Extended | ~100+ | @CalcMgrExcel*, @CalcMgrDate*, @CalcMgrStr* | Excel-equivalent functions |
| HSP Functions | ~20 | @HspConcat, @HspMbrList, @HspMessage | Planning-specific |
| Time Series | ~10 | @MOVAVG, @MOVSUM, @TREND, @SPLINE | Forecasting |
| Range/Set | ~15 | @RANGE, @XRANGE, @INTERSECT, @MERGE | Member set operations |
| Cross-Dimensional | ~10 | @XREF, @XWRITE, @MDSHIFT, @MDALLOCATE | Multi-cube operations |
| Allocation | ~3 | @ALLOCATE, @MDALLOCATE | Top-down distribution |
| Debugging | ~5 | @JDebug, @CalcMgrLogValues | Development/troubleshooting |

---

## Flow Control

### FIX / ENDFIX

Defines the calculation scope (which blocks Essbase loads).

```
FIX("Budget", "Working", &CurrYear, @LEVMBRS("Entity", 0))
    /* calculations here */
ENDFIX
```

### IF / ELSEIF / ELSE / ENDIF

Conditional execution within a calculation.

```
IF("Revenue" <> 0)
    "Profit_Margin" = "Net_Income" / "Revenue" * 100;
ELSEIF("Revenue" == #MISSING)
    "Profit_Margin" = #MISSING;
ELSE
    "Profit_Margin" = 0;
ENDIF
```

### LOOP / ENDLOOP

Repeats a calculation block a fixed number of times.

```
LOOP(12)       /* Repeat 12 times */
    "Cumulative" = "Cumulative" + "Monthly_Value";
ENDLOOP
```

---

## Member Navigation Functions

These functions traverse the dimension hierarchy to select members dynamically.

| Function | Returns | Example |
|----------|---------|---------|
| `@CHILDREN("Total")` | Immediate children | Revenue, Expense, Net_Income |
| `@DESCENDANTS("Total")` | All descendants (all levels) | Every member below Total |
| `@ICHILDREN("Total")` | Children including the parent | Total, Revenue, Expense, Net_Income |
| `@IDESCENDANTS("Total")` | Descendants including the parent | Total + every member below |
| `@PARENT("Revenue")` | Immediate parent | Total |
| `@ANCESTORS("Revenue")` | All ancestors | Total, root member |
| `@SIBLINGS("Revenue")` | Members at same level under same parent | Expense, Net_Income |
| `@LEVMBRS("Entity", 0)` | All members at level 0 (leaf) | Individual entities |
| `@GENMBRS("Entity", 3)` | All members at generation 3 | Region-level entities |
| `@RELATIVE("Total", 0)` | Leaf descendants of a member | All level-0 below Total |
| `@UDA("Entity", "Hotel")` | Members with a specific UDA | Entities tagged "Hotel" |
| `@WITHATTR("Product", "Color", "Red")` | Members with a specific attribute value | Red products |

### Navigation diagram

```
          Total_Entity (Gen 1, Lev 3)
          /                  \
    Americas (Gen 2, Lev 2)    EMEA (Gen 2, Lev 2)
     /        \                  /        \
  US (Gen3)  Canada (Gen3)   UK (Gen3)  France (Gen3)
  /    \
NYC   LA     ← Level 0 (leaf members)

@CHILDREN("Americas")     → US, Canada
@DESCENDANTS("Americas")  → US, Canada, NYC, LA
@PARENT("US")             → Americas
@SIBLINGS("US")           → Canada
@LEVMBRS("Entity", 0)    → NYC, LA, Canada, UK, France
@RELATIVE("Americas", 0) → NYC, LA, Canada
```

---

## Data Access Functions

| Function | Purpose | Example |
|----------|---------|---------|
| `@PARENTVAL("Account")` | Value from the parent in Account dimension | Parent's stored value |
| `@ANCESTVAL("Entity", 2)` | Value from ancestor at generation 2 | Region-level value |
| `@PRIOR("Period")` | Previous member in the dimension | Feb → Jan |
| `@NEXT("Period")` | Next member in the dimension | Jan → Feb |
| `@SHIFT("Period", -3)` | Member N positions away | Apr shifted by -3 → Jan |
| `@CURRMBR("Entity")` | Current member being processed | Dynamic member reference |

### Cross-Dimensional Reference (`->`)

The `->` operator reads a value from a different intersection:

```
/* Read Budget Revenue and write to Variance */
"Variance" = "Revenue" -> "Actual" - "Revenue" -> "Budget";

/* Read prior year */
"YoY_Growth" = ("Revenue" - "Revenue" -> @PRIOR("Year")) / "Revenue" -> @PRIOR("Year") * 100;
```

---

## Boolean / Conditional Functions

These return TRUE or FALSE and are used inside IF statements:

| Function | Tests | Example |
|----------|-------|---------|
| `@ISMBR("Revenue")` | Is current member "Revenue"? | `IF(@ISMBR("Revenue"))` |
| `@ISANCEST("Total")` | Is current member an ancestor of Total? | Parent/grandparent test |
| `@ISDESC("Total")` | Is current member a descendant of Total? | Child/grandchild test |
| `@ISLEV("Entity", 0)` | Is current member at level 0? | Leaf member test |
| `@ISGEN("Entity", 2)` | Is current member at generation 2? | Hierarchy level test |
| `@ISUDA("Entity", "Hotel")` | Does current member have UDA "Hotel"? | UDA-based branching |
| `@ISACCTYPE("Revenue", "Expense")` | Is account type Expense? | Account type check |
| `@ISCHILD("Americas")` | Is current member a child of Americas? | Direct parent test |
| `@ISSIBLING("US")` | Is current member a sibling of US? | Same-parent test |

### Practical Example: Different Logic by Account Type

```
FIX("Budget", "Working", &CurrYear, @LEVMBRS("Entity", 0))
    @LEVMBRS("Account", 0)(
        IF(@ISUDA("Account", "Revenue"))
            "Account" = "Account" -> "Actual" -> @PRIOR("Year") * 1.05;
        ELSEIF(@ISUDA("Account", "Expense"))
            "Account" = "Account" -> "Actual" -> @PRIOR("Year") * 1.03;
        ENDIF
    )
ENDFIX
```

---

## Calculation Commands

| Command | Purpose | Syntax |
|---------|---------|--------|
| `AGG("Dimension")` | Aggregate (roll up) a dimension | `AGG("Entity");` |
| `CALC DIM` | Calculate a dimension's formulas | `CALC DIM("Account");` |
| `DATACOPY` | Copy data between members | `DATACOPY "Source" TO "Target";` |
| `CLEARDATA` | Remove all data from a slice | `CLEARDATA "Budget";` |
| `CLEARBLOCK` | Remove empty blocks | `CLEARBLOCK ALL;` |

---

## Financial Functions

| Function | Purpose | Formula Equivalent |
|----------|---------|-------------------|
| `@IRR(memberRange)` | Internal Rate of Return | Discount rate where NPV = 0 |
| `@NPV(rate, memberRange)` | Net Present Value | Discounted cash flows |
| `@SLN(cost, salvage, life)` | Straight-line depreciation | (Cost - Salvage) / Life |
| `@SYD(cost, salvage, life, period)` | Sum-of-years depreciation | Accelerated depreciation |
| `@INTEREST(principal, rate, periods)` | Interest calculation | Standard interest |
| `@GROWTH(rate)` | Apply growth rate | Previous × (1 + rate) |
| `@DECLINE(rate)` | Apply decline rate | Previous × (1 - rate) |
| `@COMPOUND(rate, periods)` | Compound growth | Value × (1 + rate)^periods |

---

## CalcMgr Extended Functions

Calculation Manager adds 100+ extended functions. The most useful categories:

### Date/Time (@CalcMgrDate*)

| Function | Purpose |
|----------|---------|
| `@CalcMgrGetCurrentDate()` | Today's date |
| `@CalcMgrDaysBetween(date1, date2)` | Days between two dates |
| `@CalcMgrAddMonths(date, n)` | Add months to a date |
| `@CalcMgrGetDay(date)` | Extract day from date |
| `@CalcMgrGetMonth(date)` | Extract month from date |
| `@CalcMgrDateToString(date, format)` | Format date as text |

### Excel-Equivalent Financial (@CalcMgrExcel*)

| Function | Excel Equivalent | Purpose |
|----------|-----------------|---------|
| `@CalcMgrExcelPMT` | PMT() | Loan payment calculation |
| `@CalcMgrExcelFV` | FV() | Future value |
| `@CalcMgrExcelPV` | PV() | Present value |
| `@CalcMgrExcelNPV` | NPV() | Net present value |
| `@CalcMgrExcelIRR` | IRR() | Internal rate of return |
| `@CalcMgrExcelRATE` | RATE() | Interest rate |
| `@CalcMgrExcelNPER` | NPER() | Number of periods |
| `@CalcMgrExcelSLN` | SLN() | Straight-line depreciation |

### String Functions (@CalcMgr*)

| Function | Purpose |
|----------|---------|
| `@CalcMgrConcat(str1, str2)` | Concatenate strings |
| `@CalcMgrSubstring(str, start, len)` | Extract substring |
| `@CalcMgrUppercase(str)` | Convert to uppercase |
| `@CalcMgrLowercase(str)` | Convert to lowercase |
| `@CalcMgrTrim(str)` | Remove whitespace |
| `@CalcMgrReplaceAll(str, find, replace)` | Find and replace |
| `@CalcMgrMatches(str, regex)` | Regex pattern match |

### Utility Functions

| Function | Purpose |
|----------|---------|
| `@CalcMgrSortAndReturn(list, order)` | Sort a list |
| `@CalcMgrIsValidMember(name)` | Check if member exists |
| `@CalcMgrLogValues(message, vars)` | Write to calc log |

---

## HSP Functions (Planning-Specific)

| Function | Purpose |
|----------|---------|
| `@HspConcat(str1, str2)` | Concatenate for Planning |
| `@HspMbrList(dimension, function)` | Get a member list |
| `@HspMbrIndex(dimension, member)` | Get member's index |
| `@HspNthMbr(dimension, n)` | Get nth member |
| `@HspMessage(message)` | Display message to user |
| `@HspGetMbrCount(dimension)` | Count members in dimension |

---

## Time Series Functions

| Function | Purpose | Use Case |
|----------|---------|----------|
| `@MOVAVG(n)` | Moving average over n periods | Smooth trends |
| `@MOVSUM(n)` | Moving sum over n periods | Rolling totals |
| `@MOVMAX(n)` | Moving maximum over n periods | Peak detection |
| `@MOVMIN(n)` | Moving minimum over n periods | Floor detection |
| `@TREND(method, periods)` | Linear or exponential trend | Forecasting |
| `@SPLINE` | Cubic spline interpolation | Smooth curve fitting |
| `@PTD` | Period-to-date | Cumulative totals |
| `@TODATE` | Year/quarter-to-date | Cumulative with reset |

---

## Allocation Functions

### @ALLOCATE

Distributes a parent value to children based on a driver:

```
@ALLOCATE("Corporate_Overhead" -> "Total_Entity",
    ACROSS @LEVMBRS("Entity", 0),
    BASIS "Revenue",
    SPREAD PROPORTIONAL,
    ROUNDMETHOD NOROUND,
    ERRORMETHOD NOOP);
```

| Parameter | Purpose | Options |
|-----------|---------|---------|
| First argument | Source value to distribute | Member intersection |
| `ACROSS` | Target members to receive allocation | Member function |
| `BASIS` | Driver for proportional split | Account member |
| `SPREAD` | Distribution method | PROPORTIONAL, EQUAL, REPLICATE |
| `ROUNDMETHOD` | How to handle rounding | NOROUND, ROUND, ROUNDALIASED |
| `ERRORMETHOD` | What to do if basis is zero | NOOP, DIVIDEBYZERO |

---

## Complete Function List (458 Functions)

The full list of all 458 functions available in EPM Cloud Calc Manager is organized into these categories in the source files:

| Category | Count | Examples |
|----------|-------|---------|
| Core @ functions | ~120 | @ABS, @SUM, @CHILDREN, @ISMBR |
| @CalcMgr functions | ~120 | @CalcMgrExcel*, @CalcMgrDate* |
| @CalcMgrExcel functions | ~100 | Financial, Math, Statistical, Lookup |
| @Hsp functions | ~20 | Planning-specific |
| Commands | ~30 | FIX, IF, AGG, DATACOPY, SET |
| Debug functions | ~5 | @JDebug, @JSendDebug |

For the complete alphabetical listing, refer to the [Oracle Calculation Manager Function Reference](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/).

---

## Quick Recall

1. **What does @CHILDREN("Total") return?** → Immediate children of Total (one level down).
2. **What's the difference between @DESCENDANTS and @RELATIVE?** → @DESCENDANTS returns all levels below; @RELATIVE with level 0 returns only leaf members.
3. **How do you read a value from a different intersection?** → Cross-dimensional reference with `->`: `"Revenue" -> "Actual"`.
4. **What does @ALLOCATE do?** → Distributes a parent value to children based on a proportional driver.
5. **When do you use @ISMBR vs @ISUDA?** → @ISMBR checks for a specific member; @ISUDA checks for a user-defined attribute tag.

**Teach-back prompt:** Explain how you would use @LEVMBRS, @ISUDA, and FIX together to calculate a 5% revenue growth only for entities tagged as "Hotel" at the leaf level.

---

## Source Provenance

| Source | Files |
|--------|-------|
| ChatGPT | `Calc Manager/Calc Managers all business Rule Functions/` (20 subdirectories, 458 functions listed), function category files 01-20 |
| Claude | `30_Function_Reference/` |
| Gemini | `Calc Manager/Calc Managers all business Rule Functions/` (mirrors ChatGPT) |
| Oracle | [Essbase Technical Reference — Calculation Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/esscs/) |


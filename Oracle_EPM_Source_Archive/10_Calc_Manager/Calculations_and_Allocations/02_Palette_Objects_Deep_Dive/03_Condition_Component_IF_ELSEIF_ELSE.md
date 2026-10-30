# 03 Condition Component: IF, ELSEIF, ELSE Branching and Sparse Traps

## 1. Visual Condition Architecture

The **Condition Component** introduces branching logic into a Calculation Manager visual flowchart. It allows rule designers to evaluate boolean expressions dynamically and route the calculation execution down separate paths:
* **True Branch (Green Port)**: Executes child components when the condition evaluates to `TRUE`.
* **False / Else Branch (Red Port)**: Executes child components when the condition evaluates to `FALSE`.

```
+---------------------------------------------------------------------------------------------------+
|                                   VISUAL CONDITION FLOWCHART                                      |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|                            +-------------------------------------+                                |
|                            |         CONDITION COMPONENT         |                                |
|                            |  IF (@ISMBR("Sales_Division"))      |                                |
|                            +-------------------------------------+                                |
|                                       /                       \                                   |
|                         [TRUE BRANCH]                           [FALSE BRANCH]                    |
|                        /                                         \                                |
|                       v                                           v                               |
|        +-----------------------------+             +-----------------------------+                |
|        | Formula Component:          |             | Formula Component:          |                |
|        | Bonus = Revenue * 0.10;     |             | Bonus = Revenue * 0.05;     |                |
|        +-----------------------------+             +-----------------------------+                |
|                       \                                           /                               |
|                        \                                         /                                |
|                         +-------------------> + <---------------+                                 |
|                                               |                                                   |
|                                               v                                                   |
|                                     [NEXT FLOWCHART STEP]                                         |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Supported Boolean Operators & Functions

The Condition Component evaluates standard Essbase boolean functions and relational operators:

### 2.1 Relational & Logical Operators
* `==` (Equality), `!=` (Inequality)
* `>`, `<`, `>=`, `<=` (Numeric comparisons)
* `AND`, `OR`, `NOT` (Compound logical gates)

### 2.2 Native Essbase Metadata Boolean Functions
* `@ISMBR("MemberName")`: Evaluates whether the current coordinate matches the specified member.
* `@ISDESC("ParentMember")`: True if coordinate is an inclusive descendant of parent.
* `@ISUDA(Dimension, "UDAName")`: True if coordinate possesses the User Defined Attribute.
* `@ISLEV(Dimension, LevelNumber)`: True if coordinate resides on the specified level (e.g., Level 0).
* `@ISIPAR("ParentMember")`: True if coordinate is an immediate parent of specified member.

---

## 3. The Golden Architectural Rule: FIX vs. Sparse IF

One of the most catastrophic performance errors in Essbase rule design is using a **Sparse IF statement inside a calculation** instead of a **FIX statement**.

```
+---------------------------------------------------------------------------------------------------+
|                                   FIX vs. SPARSE IF COMPARISON                                    |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  CUBE DIMENSIONS:                                                                                 |
|  - Entity: Sparse (5,000 members, but only 200 members have data)                                 |
|  - Account: Dense                                                                                 |
|                                                                                                   |
|  SCENARIO A: SPARSE IF STATEMENT (DISASTROUS)                                                     |
|  +---------------------------------------------------------------------------------------------+  |
|  | "Sales_Tax" (                                                                               |  |
|  |   IF (@ISMBR("E101_East"))       /* Essbase loads ALL 5,000 blocks into memory! */          |  |
|  |     "Sales_Tax" = "Sales" * 0.08; /* Evaluates IF condition 5,000 times! */                 |  |
|  |   ENDIF                                                                                     |  |
|  | )                                                                                           |  |
|  +---------------------------------------------------------------------------------------------+  |
|  Execution Time: 45.0 SECONDS (Forces Top-Down evaluation across all blocks).                     |
|                                                                                                   |
|  SCENARIO B: FIX STATEMENT (OPTIMAL)                                                              |
|  +---------------------------------------------------------------------------------------------+  |
|  | FIX ("E101_East")                /* Essbase loads EXACTLY 1 block into memory! */           |  |
|  |   "Sales_Tax" = "Sales" * 0.08;  /* Evaluates formula once in Bottom-Up mode! */             |  |
|  | ENDFIX                                                                                      |  |
|  +---------------------------------------------------------------------------------------------+  |
|  Execution Time: 0.05 SECONDS (1000x Performance Gain!).                                         |
+---------------------------------------------------------------------------------------------------+
```

### The Rule of Thumb:
* **Sparse Dimensions**: **ALWAYS FIX**. Never write `IF (@ISMBR(sparse_member))`.
* **Dense Dimensions**: Safe to use `IF (@ISMBR(dense_member))` because dense evaluation occurs within an already-loaded memory block.

---

## 4. Complex Condition Groupings and Nested IFs

Condition Components allow multiple criteria linked by logical operators:

```sql
/* Compiled Script Output of Nested Condition Component */
IF (@ISMBR("Budget") AND @ISDESC("Operating_Expenses") AND NOT @ISMBR("Depreciation"))
  "Approved_Amount" = "Requested_Amount" * "Cap_Ratio";
ELSEIF (@ISMBR("Forecast") AND @ISMBR("Jan":"Jun"))
  "Approved_Amount" = "Actual_Amount";
ELSE
  "Approved_Amount" = "Requested_Amount";
ENDIF
```

### Best Practice for Deeply Nested Logic:
Limit visual Condition nesting to no more than 3 levels on the canvas. If the business logic requires 5+ branching paths, transition that specific logic block into a **Script Component** using a clean `IF / ELSEIF / ELSE / ENDIF` text structure to maintain readability.


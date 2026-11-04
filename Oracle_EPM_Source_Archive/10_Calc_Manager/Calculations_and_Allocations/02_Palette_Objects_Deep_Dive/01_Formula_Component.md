# 01 Formula Component: Properties, Assignment Logics, and Block Generation

## 1. Architectural Essence of the Formula Component

The **Formula Component** is the primary mathematical workhorse of Calculation Manager. It encapsulates a single assignment equation or a sequence of mathematical operations where a target member on the left-hand side (LHS) is populated with the evaluated result of an expression on the right-hand side (RHS).

```
+---------------------------------------------------------------------------------------------------+
|                                     FORMULA COMPONENT ANATOMY                                     |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  LEFT-HAND SIDE (LHS): Target Member           RIGHT-HAND SIDE (RHS): Mathematical Expression    |
|  +--------------------------------+           +-------------------------------------------------+ |
|  | "Net_Operating_Income"         |    =      | "Gross_Profit" - "Total_Operating_Expenses"     | |
|  +--------------------------------+           +-------------------------------------------------+ |
|                 |                                                      |                          |
|                 v                                                      v                          |
|  [Storage Type Evaluation]                    [Execution Mode & Calculation Engine]              |
|  - Is target Dense or Sparse—                 - Evaluates RHS expression using Essbase FPU       |
|  - Does target block exist—                   - Bottom-Up vs. Top-Down resolution                |
|  - Triggers Block Creation if Sparse—         - Handles #MISSING and Division by Zero            |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Properties Pane Configuration

When a Formula Component is dropped onto the canvas, the Properties Pane provides the following configuration controls:

| Property Field | Allowed Values | Operational Behavior |
| :--- | :--- | :--- |
| **Component Name** | Alphanumeric string | Identifier displayed on the visual canvas card (e.g., `Calc_Gross_Margin`). |
| **Target Member (LHS)** | Valid outline member or variable | The dimension coordinate that receives the calculated value. |
| **Expression (RHS)** | Mathematical formula, Essbase functions, cross-dim pointers | The computational logic evaluated by Essbase. |
| **Comments** | Freeform text | Injected into the compiled script as `/* comment */` for audit compliance. |
| **Create Blocks** | Default / Yes / No | Overrides engine block creation behavior (`@SET CREATEBLOCKONEQ`). |

---

## 3. Assignment Mechanics: Dense vs. Sparse Targets

The architectural impact of a Formula Component depends fundamentally on whether the target member belongs to a **Dense** or **Sparse** dimension.

### 3.1 Assigning to a Dense Member (e.g., Account / Period)
* **Execution Mode**: **Bottom-Up** by default.
* **Mechanism**: Essbase iterates over existing sparse blocks in the memory cache. Within each existing block, it directly writes the result into the dense array cell.
* **Block Creation**: **Does NOT create new blocks**. If a sparse block does not exist, the formula is skipped for that intersection, ensuring optimal execution speed.

### 3.2 Assigning to a Sparse Member (e.g., Entity / Department / Cost Center)
* **Execution Mode**: **Top-Down** by default (unless forced Bottom-Up).
* **The Block Creation Hazard**: If the target sparse member combination does not exist, Essbase cannot write the value unless a new block is physically created.
* **Syntax**:
  ```sql
  /* Sparse assignment creates blocks if SET CREATEBLOCKONEQ is ON */
  SET CREATEBLOCKONEQ ON;
  "E105_New_Branch" = "E101_East" * 0.50;
  ```
* **Performance Impact**: Creating sparse blocks via formula assignment is computationally expensive. If looped across large sparse dimensions, it triggers massive index reallocation and disk fragmentation.

---

## 4. Handling Division by Zero and `#MISSING`

In financial models, unhandled division by zero or missing driver values can corrupt downstream aggregations or produce `#INVALID` errors:

### Safe Division Pattern
Always wrap division operations with `@ISMISSING` or comparison checks:
```sql
/* Calculation Manager Formula Expression */
"Expense_Ratio" = 
  @IF("Total_Revenue" != 0 AND "Total_Revenue" != #MISSING, 
      "Operating_Expense" / "Total_Revenue", 
      #MISSING);
```

---

## 5. Production Formula Patterns and Anti-Patterns

### 5.1 Pattern: Cross-Dimensional Assignment
```sql
/* Cross-dimensional pointer on RHS */
"Target_Allocation" = "Source_Cost"-> "Total_Cost_Center" * "Driver_Percent";
```

### 5.2 Anti-Pattern: Assigning to a Dynamic Calc Member
* **The Failure**: Placing a Dynamic Calc member on the LHS of a Formula Component:
  `"Gross_Margin_Dynamic" = "Revenue" - "COGS";`
* **Result**: Compilation or runtime failure with: `Essbase Error: Target member is dynamic calc. Assignment not permitted.` Dynamic members must be calculated via Member Formulas, not Business Rule assignments.


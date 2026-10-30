# 01 Allocation Template: Architecture, 6-Part Equation, and Wizard Screens

## 1. The Mathematical Foundation of Allocations

The Calculation Manager **Allocation Template** provides a wizard-driven interface to generate mathematically rigorous, zero-sum cost and revenue allocations. At the engine level, all enterprise allocations follow the canonical 6-part allocation formula:

$$\text{Target} = \text{Source Pool} \times \left( \frac{\text{Basis Driver}}{\text{Total Basis Pool}} \right) \times \text{Factor} \pm \text{Offset}$$

```
+---------------------------------------------------------------------------------------------------+
|                                     ALLOCATION TEMPLATE TOPOLOGY                                  |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [SOURCE POOL]                                                                                    |
|  Corp Overhead = $1,000,000                                                                       |
|  (Dept: Corporate_Admin)                                                                          |
|         |                                                                                         |
|         | 1. Evaluates Allocation Drivers (BASIS)                                                 |
|         v                                                                                         |
|  +---------------------------------------------------------------------------------------------+  |
|  | BASIS / DRIVER POOL: Active Full-Time Employees (Headcount)                                 |  |
|  | - Dept East:  100 Headcount (25%)  ===> Target Allocation: $250,000                         |  |
|  | - Dept West:  200 Headcount (50%)  ===> Target Allocation: $500,000                         |  |
|  | - Dept North: 100 Headcount (25%)  ===> Target Allocation: $250,000                         |  |
|  | Total Driver Pool = 400 Headcount (100%)                                                     |  |
|  +---------------------------------------------------------------------------------------------+  |
|         |                                                                                         |
|         | 2. Post Offsetting Entry (OFFSET)                                                       |
|         v                                                                                         |
|  +---------------------------------------------------------------------------------------------+  |
|  | OFFSET POSTING: Dept: Corporate_Admin | Account: Overhead_Offset = -$1,000,000              |  |
|  | NET CORPORATE IMPACT = $1,000,000 (Source) - $1,000,000 (Offset) = $0.00 (Zero-Sum!)         |  |
|  +---------------------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Wizard Screens and UI Walkthrough

When dropping the **Allocation** template onto the canvas, Calculation Manager launches a multi-step design wizard:

### Step 1: Source (The Cost Pool)
* Specifies the coordinate intersection containing the funds or quantities to be redistributed.
* **Member Filter**: E.g., `Account: "Corporate_Rent"`, `Department: "No_Department"`, `Entity: "Corp_HQ"`.

### Step 2: Allocation Method
* **Ratio to Total (Pro-Rata)**: Allocates based on each target's proportion of a driver metric.
* **Even Split**: Divides source evenly among all qualifying target members ($1 / N$).
* **Fixed Percentage**: Applies explicit percentage multipliers declared per target.

### Step 3: Basis (The Allocation Driver)
* Defines the driver metric used to calculate the allocation ratio.
* Can reference a completely different cube, scenario, or time period (e.g., allocating FY25 Budget based on FY24 Actual Headcount).

### Step 4: Target (Destination Coordinates)
* Specifies the dimensions and member sets where the calculated allocations will be written.
* Target members are typically base leaf departments: `@LEVMBRS("Department", 0)`.

### Step 5: Offset (The Balancing Entry)
* Specifies where the negative credit entry is written to maintain balance sheet and P&L integrity.
* **Best Practice**: Post the offset to a dedicated contra-account (e.g., `"Overhead_Alloc_Contra"`) rather than subtracting directly from the source account, preserving audit visibility.

### Step 6: Rounding Adjustments
* Controls precision and assigns rounding differences (penny imbalances) to a specific target entity or the largest recipient.

---

## 3. Generated Essbase Calculation Script

Behind the scenes, Calculation Manager compiles the wizard selections into optimized MDX/Essbase script:

```sql
/*
 * Compiled Allocation Template Output
 * Source: Corp_Overhead ($1,000,000)
 * Basis: Headcount across Level 0 Departments
 * Target: Dept_East, Dept_West, Dept_North
 * Offset: Corp_Overhead_Offset on Corporate_Admin
 */

FIX("Actual", "FY25", "Working")
  /* Calculate and store Total Driver in temporary variable */
  VAR TotalDriver = 0;
  
  "Corporate_Admin" (
    TotalDriver = @SUMRANGE("Headcount", @LEVMBRS("Department", 0));
  )

  /* Loop over target departments and allocate */
  FIX(@LEVMBRS("Department", 0))
    "Allocated_Expense" (
      IF (TotalDriver != 0 AND TotalDriver != #MISSING)
        "Allocated_Expense" = 
          ("Corp_Overhead"->"Corporate_Admin" * ("Headcount" / TotalDriver));
      ENDIF
    )
  ENDFIX

  /* Post Zero-Sum Offset */
  "Corporate_Admin" (
    "Overhead_Offset" = -1 * "Corp_Overhead"->"Corporate_Admin";
  )
ENDFIX
```

---

## 4. Allocation Traps and Performance Tuning

1. **Zero / Missing Driver Handling**: If total headcount across all departments is 0 or `#MISSING`, division by zero will cause calculation errors. The generated script wraps division with `IF (TotalDriver != 0)`.
2. **Dynamic Calc Pool Error**: The Source Pool cannot reside on a dynamic calculation member that has not yet been computed. Ensure source data is stored or computed prior to triggering the allocation.
3. **Cross-Cube Allocations**: If the driver resides in a different cube (e.g., Headcount in Workforce BSO, Costs in Financials BSO), use **Data Maps** to move Headcount into Financials first, then allocate locally for maximum speed.


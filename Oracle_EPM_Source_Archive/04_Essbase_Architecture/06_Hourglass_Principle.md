# 06 — The Hourglass Principle: Optimal Outline Design

---

## 6.1 What Is the Hourglass Principle—

The **Hourglass Principle** (also called the **Hourglass Design** or **Hourglass Shape**) is a best-practice guideline for designing Essbase BSO database outlines. It states:

> **The dimensions in the outline should be ordered so that DENSE dimensions are in the middle, with SPARSE dimensions on the outside (top and bottom), creating an hourglass shape when you visualize the relative sizes.**

```
OUTLINE ORDER (top to bottom):        SIZE VISUALIZATION:

  1. Largest Sparse dimension      █████████████████████████
  2. 2nd largest Sparse dim        ██████████████████
  3. 3rd largest Sparse dim        ████████████
  ─────── Sparse/Dense border ──── ─────────────
  4. Largest Dense dimension       ████████
  5. 2nd largest Dense dim         ██████
  6. Smallest Dense dimension      ████
  ─────── Dense/Sparse border ──── ─────────────
  7. Smaller Sparse dimension      █████████
  8. Smallest Sparse dimension     ██████████████

       ↕ Forms the HOURGLASS shape ↕
```

### Why Is It Called "Hourglass"—

When you list dimensions by their stored member count, and arrange them with the largest sparse dimensions at top, dense dimensions in the middle, and remaining sparse dimensions at the bottom, the profile looks like an **hourglass** — wide at top, narrow in the middle, wide at bottom.

---

## 6.2 Why the Hourglass Principle Matters

### The Core Reason: Calculation Performance

In BSO, calculations follow the **outline order**. Essbase processes dimensions **from bottom to top** during default calculation (`CALC ALL`).

```
Calculation Order (default CALC ALL):

  Processes BOTTOM dimension first, then moves UP:

  Step 1: Calculate Dimension 8 (bottom sparse)     ← Sparse aggregation
  Step 2: Calculate Dimension 7 (next sparse)        ← Sparse aggregation
  Step 3: Calculate Dimension 6 (dense)              ← Intra-block calc ★ FAST
  Step 4: Calculate Dimension 5 (dense)              ← Intra-block calc ★ FAST
  Step 5: Calculate Dimension 4 (dense)              ← Intra-block calc ★ FAST
  Step 6: Calculate Dimension 3 (sparse)             ← Sparse aggregation
  Step 7: Calculate Dimension 2 (sparse)             ← Sparse aggregation
  Step 8: Calculate Dimension 1 (top sparse)         ← Sparse aggregation
```

### Why Dense Dimensions Should Be Together

When dense dimensions are consecutive and in the middle:

1. **Intra-block calculations** (within a single block) are processed in sequence
2. The block is loaded ONCE and all dense dimension calculations happen in memory
3. No disk I/O between dense dimension calculations
4. Extremely fast — just arithmetic on arrays in RAM

### Why the Largest Sparse Should Be First (Top)

1. Essbase calculates from bottom to top
2. The FIRST (top) dimension is calculated LAST
3. By putting the largest sparse dimension first:
   - All smaller aggregations happen first (creating fewer intermediate blocks)
   - The final, largest aggregation is the most efficient (only one pass)
4. This minimizes the total number of **block reads and writes** during calculation

---

## 6.3 The Hourglass Rule — Detailed Ordering

### Within Sparse Dimensions: Order by DECREASING member count

```
SPARSE dimensions ordered from LARGEST to SMALLEST:

  Entity:    1,000 members → Position 1 (top)
  Product:     500 members → Position 2
  Project:     200 members → Position 3
  
  (Dense dimensions in middle)
  
  Scenario:      5 members → Position N-1
  Version:       3 members → Position N (bottom)
```

### Within Dense Dimensions: Order by DECREASING member count

```
DENSE dimensions ordered from LARGEST to SMALLEST:

  Account:   200 stored members → First dense position
  Period:     17 stored members → Second dense position
  Year:        5 stored members → Third dense position
```

### The Complete Hourglass

```
Position  Dimension     Members   Type      Why This Position
────────────────────────────────────────────────────────────────
   1      Entity        1,000     SPARSE    Largest sparse → top
   2      Product         500     SPARSE    2nd largest sparse
   3      Project         200     SPARSE    3rd largest sparse
   ────── TRANSITION ──────────────────────────────────────────
   4      Account         200     DENSE     Largest dense
   5      Period           17     DENSE     2nd largest dense
   6      Year              5     DENSE     Smallest dense
   ────── TRANSITION ──────────────────────────────────────────
   7      Scenario          5     SPARSE    Smaller sparse
   8      Version           3     SPARSE    Smallest sparse

Hourglass shape:
  Entity     ████████████████████████████████████████
  Product    ████████████████████████████
  Project    ████████████████
  ──────────────────────────
  Account    ████████████████
  Period     █████████
  Year       ████
  ──────────────────────────
  Scenario   ████
  Version    ███
```

---

## 6.4 Why NOT Following the Hourglass Hurts Performance

### Anti-Pattern 1: Dense Dimensions at the Top

```
BAD ORDER:
  1. Account (DENSE) ← WRONG POSITION
  2. Period  (DENSE) ← WRONG POSITION
  3. Entity  (SPARSE)
  4. Product (SPARSE)
  5. Scenario (SPARSE)

Problem:
  - Calc processes from bottom up
  - Scenario (sparse) calculated first
  - Then Product (sparse)
  - Then Entity (sparse)
  - Then Period (dense) ← Dense calc NOT grouped with Account
  - Then Account (dense)
  
  The sparse dimensions are sandwiched between dense dimensions.
  Each sparse calculation may need to load/unload blocks,
  then dense calcs happen with blocks possibly evicted from cache.
  
  Result: 20-40% slower calculations
```

### Anti-Pattern 2: Random Dimension Ordering

```
BAD ORDER:
  1. Account (DENSE)
  2. Entity  (SPARSE)
  3. Period  (DENSE)
  4. Product (SPARSE)
  5. Scenario (SPARSE)

Problem:
  - Dense and sparse are interleaved
  - Essbase alternates between intra-block and inter-block operations
  - Cache thrashing (blocks loaded, evicted, reloaded)
  - I/O pattern becomes random instead of sequential
  
  Result: 2-5× slower calculations
```

### Anti-Pattern 3: Smallest Sparse at Top

```
BAD ORDER:
  1. Version   (SPARSE, 3 members) ← Smallest sparse at top!
  2. Scenario  (SPARSE, 5 members)
  3. Account   (DENSE)
  4. Period    (DENSE)
  5. Entity    (SPARSE, 1000 members) ← Largest sparse at bottom!
  6. Product   (SPARSE, 500 members)

Problem:
  - Entity (1000 members) is calculated early (near bottom)
  - This creates 1000 upper-level blocks EARLY in the process
  - Subsequent sparse calculations must process these extra blocks
  - More blocks in memory = more cache pressure
  - Processing 1000-member aggregation early means all later
    calcs process 1000× more blocks than necessary
    
  Result: Exponentially more blocks to process → much slower
```

---

## 6.5 When to Deviate from the Hourglass

The Hourglass is a **guideline**, not an absolute rule. You may deviate when:

### Case 1: Attribute Dimensions
- Attribute dimensions are always sparse
- They are typically placed after their associated base dimension
- This is fine even if it breaks the perfect hourglass shape

### Case 2: Very Small Sparse Dimensions (2-3 members)
- Dimensions like Version (Working, Final) or Currency (Local, USD)
- These are so small that their position has minimal performance impact
- They can be placed anywhere without significant effect

### Case 3: Application-Specific Calc Requirements
- If your business rules calculate specific dimensions in a required order
- Custom calc scripts override the default CALC ALL order
- In this case, optimize for YOUR specific calc scripts, not just CALC ALL

### Case 4: EPM Planning Dimensions
- Planning applications have required dimension types
- Some dimensions must be in specific positions for Planning to work
- Follow Planning's requirements, then optimize within those constraints

---

## 6.6 The Mathematics of Dimension Ordering

### How Aggregation Works in Practice

Consider a simple 2-sparse-dimension database:

```
Dimensions:
  Entity (sparse): E1, E2, E3 → Total_Entity
  Product (sparse): P1, P2, P3, P4 → Total_Product
  Account (dense): Revenue, COGS

Scenario A: Entity first (top), Product second (bottom)
  Calc order (bottom-up): Product first, then Entity
  
  Step 1: Aggregate Product for each Entity
    E1: P1+P2+P3+P4 → Total_Product    (4 blocks read, 1 block write)
    E2: P1+P2+P3+P4 → Total_Product    (4 blocks read, 1 block write)
    E3: P1+P2+P3+P4 → Total_Product    (4 blocks read, 1 block write)
    Total: 12 reads + 3 writes = 15 I/O ops
    
  Step 2: Aggregate Entity for each Product (including Total_Product)
    P1: E1+E2+E3 → Total_Entity    (3 blocks read, 1 block write)
    P2: E1+E2+E3 → Total_Entity    (3 blocks read, 1 block write)
    P3: E1+E2+E3 → Total_Entity    (3 blocks read, 1 block write)
    P4: E1+E2+E3 → Total_Entity    (3 blocks read, 1 block write)
    Total_Product: E1+E2+E3 → Total  (3 blocks read, 1 block write)
    Total: 15 reads + 5 writes = 20 I/O ops
    
  GRAND TOTAL: 35 I/O operations

Scenario B: Product first (top), Entity second (bottom)
  Calc order (bottom-up): Entity first, then Product
  
  Step 1: Aggregate Entity for each Product
    P1: E1+E2+E3 → Total_Entity    (3 reads, 1 write)
    P2: E1+E2+E3 → Total_Entity    (3 reads, 1 write)
    P3: E1+E2+E3 → Total_Entity    (3 reads, 1 write)
    P4: E1+E2+E3 → Total_Entity    (3 reads, 1 write)
    Total: 12 reads + 4 writes = 16 I/O ops
    
  Step 2: Aggregate Product for each Entity (including Total_Entity)
    E1: P1+P2+P3+P4 → Total_Product    (4 reads, 1 write)
    E2: P1+P2+P3+P4 → Total_Product    (4 reads, 1 write)
    E3: P1+P2+P3+P4 → Total_Product    (4 reads, 1 write)
    Total_Entity: P1+P2+P3+P4 → Total  (4 reads, 1 write)
    Total: 16 reads + 4 writes = 20 I/O ops
    
  GRAND TOTAL: 36 I/O operations

Difference: Minimal in this small example.
But with Entity=1000, Product=5:
  Entity first → 5×1000 + 1001×5 = 10,005 I/O  (better)
  Product first → 1000×5 + 6×1000 = 11,000 I/O  (worse)
```

**Key insight**: Putting the larger sparse dimension first (top) = calculated LAST = fewer total intermediate operations.

---

## 6.7 Practical Hourglass Design — Step by Step

### Step 1: List All Dimensions with Properties

```
Dimension       Type      Stored Members    Data Density
─────────────────────────────────────────────────────────
Entity          Sparse    800               Low (5%)
Product         Sparse    350               Very Low (2%)
Project         Sparse    150               Low (8%)
Account         Dense     180               High (80%)
Period          Dense     17                Very High (95%)
Year            Dense     5                 Very High (100%)
Scenario        Sparse    4                 Medium (60%)
Version         Sparse    2                 Medium (70%)
Currency        Sparse    3                 Medium (50%)
```

### Step 2: Separate into Sparse and Dense Groups

```
SPARSE: Entity(800), Product(350), Project(150), Scenario(4), Version(2), Currency(3)
DENSE:  Account(180), Period(17), Year(5)
```

### Step 3: Sort Each Group by Member Count (Descending)

```
SPARSE (descending): Entity(800), Product(350), Project(150), Scenario(4), Currency(3), Version(2)
DENSE (descending):  Account(180), Period(17), Year(5)
```

### Step 4: Arrange in Hourglass Pattern

```
Position   Dimension     Members   Type
────────────────────────────────────────
   1       Entity        800       SPARSE  ← Top
   2       Product       350       SPARSE
   3       Project       150       SPARSE
   ──────  ────────      ───       ─────
   4       Account       180       DENSE   ← Middle
   5       Period        17        DENSE
   6       Year          5         DENSE
   ──────  ────────      ───       ─────
   7       Scenario      4         SPARSE  ← Bottom
   8       Currency      3         SPARSE
   9       Version       2         SPARSE
```

### Step 5: Verify Block Size

```
Block Size = 180 × 17 × 5 × 8 = 122,400 bytes ≈ 119.5 KB

✅ Within the 8-200 KB sweet spot
```

### Step 6: Verify Total Database Size Estimate

```
Potential blocks = 800 × 350 × 150 × 4 × 3 × 2 = 1,008,000,000

Wait — that's 1 BILLION potential blocks! ❌

Expected density = 5% × 2% × 8% × 60% × 50% × 70% ≈ 0.00017%

Actual blocks ≈ 1,008,000,000 × 0.00017% ≈ 1,714 blocks

Total data ≈ 1,714 × 119.5 KB ≈ 200 MB ✅ (very manageable)
```

---

## 6.8 Hourglass and EPM Planning Applications

In Oracle Planning (PBCS/EPBCS/On-Premises), some dimension ordering rules are imposed by the application:

```
Planning Application Requirements:
  - Account MUST be a specific dimension type
  - Period MUST be a specific dimension type  
  - Year MUST be a specific dimension type
  - Scenario and Version have specific roles

Recommended Planning Outline Order (Hourglass-compatible):

  1. Entity          (Sparse, usually largest)
  2. Custom dims     (Sparse, by descending size)
  3. Product         (Sparse)
  4. ──── Dense ────
  5. Account         (Dense, usually largest dense)
  6. Period          (Dense)
  7. Year            (Dense or Sparse depending on size)
  8. ──── Sparse ────
  9. Scenario        (Sparse, small)
  10. Version        (Sparse, small)
  11. Currency       (Sparse, small)
```

---

## 6.9 Common Hourglass Mistakes

| Mistake | Impact | Fix |
|---------|--------|-----|
| All sparse at top, all dense at bottom | Moderate slowdown | Move dense to middle |
| Dense-Sparse-Dense-Sparse alternating | Severe slowdown | Group dense together |
| Smallest sparse at top, largest at bottom | Moderate slowdown | Reverse sparse order |
| Too many dense dimensions (block too large) | Memory issues | Move some to sparse |
| Ignoring the principle entirely | Unpredictable performance | Redesign outline |

---

## 6.10 Measuring the Impact of Dimension Order

### Before/After Comparison

```
Test: Full CALC ALL on same database, same data, different dimension orders.

Scenario A: Hourglass (correct)
  CALC ALL time: 12 minutes
  Blocks read:   450,000
  Blocks written: 180,000
  Peak memory:   2.1 GB

Scenario B: Random order
  CALC ALL time: 28 minutes ← 2.3× slower
  Blocks read:   890,000   ← 2× more reads
  Blocks written: 350,000   ← 2× more writes
  Peak memory:   3.8 GB     ← 80% more memory

Scenario C: Reversed (worst case)
  CALC ALL time: 45 minutes ← 3.75× slower
  Blocks read:   1,200,000  ← 2.7× more reads
  Blocks written: 500,000    ← 2.8× more writes
  Peak memory:   5.2 GB     ← 2.5× more memory
```

---

## Summary

> **The Hourglass Principle states: order dimensions with the largest sparse at the top, dense in the middle (largest to smallest), and smallest sparse at the bottom. This optimizes calculation performance by grouping intra-block operations together and minimizing the total number of block I/O operations during aggregation. Dense dimensions in the middle = one block load, all dense calcs in memory. Largest sparse at top = calculated last = fewest total intermediate blocks. Following this principle can improve calculation performance by 2-4×.**

---

**← Previous:** [05 — Index and Page Files](./05_Index_and_Page_Files.md)  
**Next →** [07 — Data Operations and Performance](./07_Data_Operations_and_Performance.md)

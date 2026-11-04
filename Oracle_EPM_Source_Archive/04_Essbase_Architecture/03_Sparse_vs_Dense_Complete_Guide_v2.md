# 03 — Sparse vs Dense Dimensions: The Complete Guide

---

## 3.1 The Most Important Decision in Essbase Design

The **sparse vs. dense** assignment of dimensions is the **single most impactful design decision** in Essbase. Get it wrong, and your database will:
- Consume 10× to 1000× more disk space than necessary
- Run calculations 10× slower
- Take hours to load data that should take minutes
- Crash from memory exhaustion

Get it right, and Essbase delivers sub-second query performance on billions of data points.

---

## 3.2 What "Sparse" and "Dense" Actually Mean

### Dense Dimension
> A dimension where **most combinations with other dense dimensions will have data**.

Dense dimensions define the **internal structure (shape) of every block**. Every block has cells for ALL dense member combinations, whether or not data exists there.

### Sparse Dimension  
> A dimension where **most combinations with other sparse dimensions will NOT have data**.

Sparse dimensions determine **which blocks exist**. A block is created only when at least one cell in that sparse combination has data.

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│   DENSE = "Always reserve space" → Defines block interior        │
│   SPARSE = "Only create if needed" → Defines block existence     │
│                                                                  │
│   Think of it like a hotel:                                       │
│   DENSE = The rooms in each floor (every floor has all rooms)    │
│   SPARSE = The floors that actually have guests                  │
│          (empty floors don't exist in Essbase)                   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 3.3 The Math Behind Sparse and Dense

### Block Size Formula

```
Block Size (bytes) = Product of all dense dimension member counts × 8

Example:
  Dense dimensions:
    Account:  150 members (stored, including upper-level)
    Period:   17 members (Jan-Dec + Q1-Q4 + Year Total)
    
  Block Size = 150 × 17 × 8 = 20,400 bytes ≈ 20 KB per block
```

### Maximum Number of Blocks (Potential Blocks)

```
Potential Blocks = Product of all sparse dimension member counts

Example:
  Sparse dimensions:
    Entity:    500 members (stored)
    Product:   200 members (stored)
    Scenario:  5 members
    Version:   3 members
    Year:      5 members
    
  Potential Blocks = 500 × 200 × 5 × 3 × 5 = 7,500,000 blocks
```

### Maximum Database Size (Theoretical)

```
Max DB Size = Block Size × Potential Blocks
            = 20 KB × 7,500,000
            = 150,000,000 KB
            = 150 GB

But in reality, only blocks WITH DATA are created.
If only 2% of sparse combinations have data:

Actual DB Size = 20 KB × 150,000 blocks = 3 GB
```

### The Density Ratio

```
Database Density = (Actual blocks with data) / (Potential blocks) × 100%

In our example: 150,000 / 7,500,000 × 100% = 2%

This is typical! Most Essbase databases have 1-10% density.
Not every entity sells every product in every scenario.
```

---

## 3.4 Why Certain Dimensions Should Be Dense

A dimension should be **dense** when:

### Rule 1: Small member count
- Fewer members = smaller block size
- Dense dimensions multiply together to form block size
- You want blocks to be **8 KB to 200 KB** (sweet spot for performance)

### Rule 2: Most combinations will have data
- If Account has Revenue, COGS, and Headcount, and nearly every entity/product will have all three — Account is dense
- Period is dense because every entity with data will have data in most months

### Rule 3: The dimension is frequently calculated across
- Calculations within a single block are **MUCH faster** than across blocks
- Account aggregations (Revenue - COGS = Gross Profit) happen within a single block
- Period aggregations (Jan + Feb + Mar = Q1) happen within a single block
- This is called **"intra-block calculation"** — it's almost instant

### Classic Dense Dimensions:

| Dimension | Why Dense— |
|-----------|-----------|
| **Account** | Small (50-500 members), nearly all intersections populated, heavy calculation target |
| **Period** | Small (12-17 members), all entities have monthly data, time aggregation |
| **Year** | Very small (3-5 members), usually all populated |

---

## 3.5 Why Certain Dimensions Should Be Sparse

A dimension should be **sparse** when:

### Rule 1: Large member count
- Many members = many possible combinations
- If dense, each additional member adds to EVERY block's size
- Making Entity (500 members) dense would multiply every block size by 500

### Rule 2: Most combinations will NOT have data  
- Not every entity sells every product
- Not every product exists in every scenario/version
- Sparse means "only create blocks where data exists"

### Rule 3: The dimension represents independent analytical perspectives
- Entity=US_East and Entity=UK have completely independent data
- Making them sparse means separate blocks, separate calculations

### Classic Sparse Dimensions:

| Dimension | Why Sparse— |
|-----------|-------------|
| **Entity** | Large (100-10000 members), entities are independent, not all combos exist |
| **Product** | Large (50-5000 members), not sold everywhere |
| **Scenario** | Small but very few intersections (Budget doesn't exist for historical years) |
| **Version** | Small, but not all versions have data for all intersections |
| **Custom dims** | Usually large, represents unique analytical cuts |

---

## 3.6 The Decision Framework: How to Decide Sparse vs Dense

```
                    START
                      │
                      ▼
              ┌───────────────┐
              │ How many       │
              │ stored members │
              │ (incl. upper)— │
              └───────┬───────┘
                      │
              ┌───────┴───────┐
              │               │
        ≤ 20-30         > 30 members
        members               │
              │               ▼
              │       ┌───────────────┐
              │       │ What % of      │
              │       │ intersections  │
              │       │ will have data—│
              │       └───────┬───────┘
              │               │
              │       ┌───────┴───────┐
              │       │               │
              │     > 50%          < 50%
              │       │               │
              ▼       ▼               ▼
         ┌────────┐ ┌────────┐  ┌─────────┐
         │ Likely │ │ DENSE  │  │ SPARSE  │
         │ DENSE  │ │        │  │         │
         └────────┘ └────────┘  └─────────┘
              │
              ▼
      ┌───────────────┐
      │ Will it cause  │
      │ block size     │
      │ > 200 KB—      │
      └───────┬───────┘
              │
        ┌─────┴─────┐
        │           │
       Yes          No
        │           │
        ▼           ▼
   ┌─────────┐ ┌────────┐
   │ SPARSE  │ │ DENSE  │
   └─────────┘ └────────┘
```

### Quick Rules of Thumb

| Criterion | Dense | Sparse |
|-----------|-------|--------|
| Member count | < 50 ideal, < 100 acceptable | > 50 typical |
| Data density | > 30-50% of intersections populated | < 30% of intersections populated |
| Calculation direction | Aggregates WITHIN the dimension heavily | Aggregates ACROSS the dimension |
| Independence | Members are interdependent (Revenue - COGS) | Members are independent (US vs UK) |

---

## 3.7 Visualizing Sparse vs Dense — The Hotel Analogy

```
Imagine an Essbase database as a HOTEL:

SPARSE dimensions = HOTEL FLOORS (Entity, Product)
DENSE dimensions  = ROOMS ON EACH FLOOR (Account, Period)

┌─────────────────────────────────────────────┐
│ Floor 3: Entity=Europe, Product=Gadget      │
│ ┌────┬────┬────┬────┬────┬────┬────┐        │
│ │R101│R102│R103│R104│R105│... │R117│        │
│ │Rev │Rev │Rev │COGS│COGS│    │NI  │        │
│ │Jan │Feb │Mar │Jan │Feb │    │Year│        │
│ │ 50 │ 60 │ #M │ 25 │ 30 │    │ 90 │        │
│ └────┴────┴────┴────┴────┴────┴────┘        │
├─────────────────────────────────────────────┤
│ Floor 2: Entity=US_West, Product=Widget     │
│ ┌────┬────┬────┬────┬────┬────┬────┐        │
│ │R101│R102│R103│R104│R105│... │R117│        │
│ │Rev │Rev │Rev │COGS│COGS│    │NI  │        │
│ │Jan │Feb │Mar │Jan │Feb │    │Year│        │
│ │200 │180 │210 │100 │ 90 │    │250 │        │
│ └────┴────┴────┴────┴────┴────┴────┘        │
├─────────────────────────────────────────────┤
│ Floor 1: Entity=US_East, Product=Widget     │
│ ┌────┬────┬────┬────┬────┬────┬────┐        │
│ │R101│R102│R103│R104│R105│... │R117│        │
│ │Rev │Rev │Rev │COGS│COGS│    │NI  │        │
│ │Jan │Feb │Mar │Jan │Feb │    │Year│        │
│ │100 │120 │130 │ 50 │ 60 │    │150 │        │
│ └────┴────┴────┴────┴────┴────┴────┘        │
├─────────────────────────────────────────────┤
│ ❌ No Floor for: Entity=Europe, Product=Widget │
│    (No data → No block → No floor created)     │
└─────────────────────────────────────────────┘

Key insight:
- Every FLOOR has the SAME rooms (same block structure)
- Floors only exist where there are guests (data)
- Missing guests in a room → #Missing value
- Room layout is IDENTICAL on every floor
```

---

## 3.8 The Combinatorics: Why This Matters So Much

### Scenario A: CORRECT Sparse/Dense Assignment

```
Dimensions:
  Entity:   1,000 members  → SPARSE
  Product:    500 members   → SPARSE  
  Account:    100 members   → DENSE
  Period:      17 members   → DENSE

Block size = 100 × 17 × 8 = 13,600 bytes ≈ 13.3 KB  ✅ (excellent)
Potential blocks = 1,000 × 500 = 500,000
Actual blocks (5% density) = 25,000
Total data = 25,000 × 13.3 KB = 332 MB  ✅ (manageable)
Index size ≈ 25,000 × ~200 bytes = 5 MB  ✅
```

### Scenario B: WRONG — Making Entity Dense

```
Dimensions:
  Product:    500 members   → SPARSE
  Account:    100 members   → DENSE
  Period:      17 members   → DENSE
  Entity:   1,000 members  → DENSE  ← WRONG!

Block size = 100 × 17 × 1,000 × 8 = 13,600,000 bytes ≈ 13 MB per block! ❌
Potential blocks = 500 (only Product is sparse)
Actual blocks (90% density) = 450
Total data = 450 × 13 MB = 5.85 GB

BUT:
- Each block is 13 MB → massive memory consumption
- Only a few MB of each 13 MB block has real data
- Block density is < 1% → 99% of each block is #Missing
- Loading a SINGLE block into cache uses 13 MB of RAM
- Calculations within blocks are slow (huge arrays to traverse)

Result: 5.85 GB stored, but PERFORMANCE IS TERRIBLE ❌
```

### Scenario C: WRONG — Making Account Sparse

```
Dimensions:
  Entity:   1,000 members   → SPARSE
  Product:    500 members    → SPARSE
  Account:    100 members    → SPARSE  ← WRONG!
  Period:      17 members    → DENSE

Block size = 17 × 8 = 136 bytes ≈ 0.13 KB  ← Tiny blocks!

Potential blocks = 1,000 × 500 × 100 = 50,000,000 (50 million!)
Actual blocks (5% density) = 2,500,000

Total data = 2,500,000 × 0.13 KB = 325 MB (similar raw data)

BUT:
- 2.5 MILLION index entries → index file is enormous
- Index search is slow with millions of entries
- Each block is only 136 bytes → massive overhead per block
- Block header overhead (~48 bytes) per block → 36% wasted on headers
- Account calculations (Revenue - COGS) now cross BLOCKS → extremely slow
- Aggregation requires reading thousands of blocks instead of one

Result: Calculations are 100× slower ❌
        Index file is 100× larger ❌
        Retrieval requires reading 100× more blocks ❌
```

---

## 3.9 The Golden Rule: Block Size Sweet Spot

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   OPTIMAL BLOCK SIZE: 8 KB — 200 KB                        │
│                                                             │
│   < 8 KB:   Too many tiny blocks, index overhead,           │
│             cross-block calculations, poor I/O              │
│                                                             │
│   8-100 KB: ★ IDEAL ★ Good I/O, reasonable cache usage,     │
│             efficient calculations                           │
│                                                             │
│   100-200 KB: Acceptable, monitor cache usage                │
│                                                             │
│   > 200 KB: Blocks too large, excessive memory per block,   │
│             poor cache utilization, slow I/O                 │
│                                                             │
│   > 1 MB:   DANGER ZONE — redesign your outline immediately │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Block Size = (Dense_Dim1_Members × Dense_Dim2_Members × ... × Dense_DimN_Members) × 8
```

---

## 3.10 Calculating Block Size — Step by Step

### Step 1: Identify Dense Dimensions and Their Stored Member Counts

> **IMPORTANT**: Count ALL stored members, not just Level 0 members. Upper-level members that store data (Dynamic Calc members are NOT stored) also count.

```
Account dimension:
  Total members:     150
  Dynamic Calc:       30 (not stored, calculated on-the-fly)
  Stored members:    120

Period dimension:
  Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec = 12
  Q1, Q2, Q3, Q4 = 4 (stored if Account is "Store Data")
  Year Total = 1
  Stored members: 17

Year dimension (if dense):
  FY2022, FY2023, FY2024, FY2025, FY2026 = 5
  Stored members: 5
```

### Step 2: Calculate Block Size

```
Block Size = 120 × 17 × 5 × 8 = 81,600 bytes ≈ 79.7 KB

✅ Within the sweet spot (8 - 200 KB)
```

### Step 3: Check Against Guidelines

| Block Size | Assessment | Action |
|------------|-----------|--------|
| 79.7 KB | ✅ Good | No changes needed |

---

## 3.11 Real-World Examples of Sparse/Dense Design

### Example 1: Financial Planning Application

```
Dimension         Members    Density    →  Assignment
─────────────────────────────────────────────────────
Account           200        High       →  DENSE ✅
Period            17         High       →  DENSE ✅
Year              5          High       →  DENSE ✅
Scenario          5          Medium     →  SPARSE (not all combos exist)
Version           3          Medium     →  SPARSE
Entity            300        Low        →  SPARSE ✅
Department        50         Low        →  SPARSE
Product           100        Very Low   →  SPARSE ✅

Block size: 200 × 17 × 5 × 8 = 136,000 bytes ≈ 133 KB ✅
```

### Example 2: Workforce Planning Application

```
Dimension         Members    Density    →  Assignment
─────────────────────────────────────────────────────
Account (HR)      50         High       →  DENSE ✅
Period            17         High       →  DENSE ✅
Year              5          High       →  DENSE ✅
Scenario          4          Medium     →  SPARSE
Entity            200        Low        →  SPARSE ✅
Employee          5,000      Very Low   →  SPARSE ✅
Position          500        Very Low   →  SPARSE
Job Code          100        Very Low   →  SPARSE

Block size: 50 × 17 × 5 × 8 = 34,000 bytes ≈ 33 KB ✅
```

### Example 3: WRONG Design — Too Many Dense Dimensions

```
Dimension         Members    Assignment (WRONG!)
────────────────────────────────────────────────
Account           200        DENSE
Period            17         DENSE
Year              5          DENSE
Scenario          5          DENSE ← WRONG
Entity            300        SPARSE
Department        50         DENSE ← WRONG
Product           100        SPARSE

Block size: 200 × 17 × 5 × 5 × 50 × 8 = 34,000,000 bytes = 34 MB ❌
DISASTER! Each block is 34 MB!
```

---

## 3.12 The "Population Pattern" Analysis

The best way to decide sparse vs. dense is to analyze your **data population pattern**:

### Question: "For this dimension, what percentage of its members will have data for a typical combination of other dimensions—

```
For Account:
  Q: "For a given Entity + Product + Period + Year, how many Accounts have data—
  A: "Almost all — Revenue, COGS, Headcount, etc. all exist"
  → 80%+ coverage → DENSE ✅

For Period:
  Q: "For a given Entity + Product + Account + Year, how many Periods have data—
  A: "All months — Jan through Dec"
  → 100% coverage → DENSE ✅

For Entity:
  Q: "For a given Account + Period + Product + Year, how many Entities have data—
  A: "Only 30% of entities sell this specific product"
  → 30% coverage → SPARSE ✅

For Product:
  Q: "For a given Entity + Account + Period + Year, how many Products have data—
  A: "Only 5-10% of products are sold in each entity"
  → 5-10% coverage → SPARSE ✅
```

---

## 3.13 Impact of Member Properties on Storage

### Stored vs. Dynamic Calc Members

```
Member Property          Stored in Block—    Impacts Block Size—
───────────────────────────────────────────────────────────────
Store Data               ✅ Yes              ✅ Yes
Dynamic Calc             ❌ No               ❌ No (calculated on retrieval)
Dynamic Calc and Store   ✅ Yes              ✅ Yes
Label Only               ❌ No               ❌ No
Shared Member            ❌ No (points to    ❌ No
                            original)
```

### Why This Matters

If Account has 200 total members but 50 are Dynamic Calc:
```
WRONG: Block includes 200 members → Block too large
RIGHT: Block includes 150 members → Block is 25% smaller

Always count STORED members when calculating block size.
```

---

## 3.14 Attribute Dimensions and Sparse/Dense

**Attribute dimensions are ALWAYS sparse** and cannot be changed. They are virtual dimensions that tag base dimension members with characteristics:

```
Product (base dimension, sparse):
  ├── Widget_A    [Color=Red, Size=Large]
  ├── Widget_B    [Color=Blue, Size=Small]
  └── Gadget_A    [Color=Red, Size=Medium]

Color (attribute dimension, always sparse):
  ├── Red
  ├── Blue
  └── Green

Size (attribute dimension, always sparse):
  ├── Small
  ├── Medium
  └── Large
```

Attribute dimensions don't create blocks — they create **virtual aggregations** across their associated base dimension.

---

## 3.15 Master Pedagogical Reference & Recall Guide (The 12 Pillars)

### 1. Core Idea
**Dense dimensions determine the internal array structure and physical size of every 64KB data block, while Sparse dimensions determine which blocks actually get created on disk and where they reside in the B-Tree index.**

### 2. Simple Explanation & Analogy
* **Everyday Analogy**: Think of an Essbase database as an apartment complex:
  * **Sparse Dimensions** are the *Building Number* and *Floor Number*. You only construct a physical building if people actually buy apartments in that city block.
  * **Dense Dimensions** are the *Rooms within each Apartment* (Kitchen, Living Room, Bedroom). Every apartment built has the exact same floor plan and room structure, even if one room sits temporarily empty.

### 3. Purpose: Why It Matters
Configuring Dense vs. Sparse settings is the single most critical architectural decision in Essbase design. If you make too many dimensions Dense, block sizes explode beyond 1MB, exhausting RAM and crashing the server. If you make too many dimensions Sparse, Essbase creates millions of tiny 100-byte blocks, degrading performance due to index traversal overhead.

### 4. Connections to Other Concepts
* **Hourglass Principle ([06_Hourglass_Principle.md](./06_Hourglass_Principle.md))**: Dense dimensions must be sorted from largest to smallest, followed by Sparse dimensions from smallest to largest.
* **Calculation Engine ([Calc Manager](../Calc%20Manager/Calculations_and_Allocations/05_Calculation_Engine_and_Performance/01_Execution_Modes_BottomUp_vs_TopDown.md))**: Formulas across dense dimensions calculate quickly within memory; formulas referencing sparse dimensions require cross-block pointer navigation and risk triggering slow Top-Down execution.

### 5. Prerequisites & Assumptions
* Understanding of Level 0 vs. Upper-level summary members.
* Outline access in Calculation Manager or Smart View Admin Mode.

### 6. How It Works: Block Sizing Formula
$$\text{Block Size (Bytes)} = (\text{Stored Dense Member Count}_1 \times \text{Stored Dense Member Count}_2 \times \dots) \times 8 \text{ bytes}$$

```
                SPARSE DIMENSIONS (Determine Block Address)
        Entity: NY | Scenario: Actual | Version: Working | Year: FY25
                                    │
                                    ▼
       ┌────────────────────────────────────────────────────────┐
       │                PHYSICAL ESSBASE BLOCK                  │
       │                                                        │
       │           DENSE DIMENSION: PERIOD (Jan..Dec)           │
       │              Jan     Feb     Mar     ...   Dec         │
       │  Rev      [ 8 B ] [ 8 B ] [ 8 B ]        [ 8 B ]       │
       │  COGS     [ 8 B ] [ 8 B ] [ 8 B ]        [ 8 B ]       │
       │  OPEX     [ 8 B ] [ 8 B ] [ 8 B ]        [ 8 B ]       │
       │  ...                                                   │
       │  NetInc   [ 8 B ] [ 8 B ] [ 8 B ]        [ 8 B ]       │
       │                                                        │
       │          DENSE DIMENSION: ACCOUNT (100 members)        │
       └────────────────────────────────────────────────────────┘
```

### 7. How to Do It: Sizing & Assignment Procedure
1. Identify dimensions where data is present for almost every combination (typically **Account** and **Period**); designate these as **Dense**.
2. Identify dimensions where combinations are sparsely populated (e.g., **Entity**, **Product**, **Project**, **Customer**); designate these as **Sparse**.
3. Count only **Stored** members in each dense dimension (exclude `Dynamic Calc` and `Label Only`).
4. Multiply stored dense member counts together and multiply by 8 bytes.
5. Verify the resulting block size is strictly between **50 KB and 250 KB**.

### 8. Worked Example (Illustrative)
> *(Note: The following configuration is illustrative for learning purposes)*
* **Dimension Structure**:
  * `Account`: 120 stored members (Dense)
  * `Period`: 17 stored members: 12 months + 4 quarters + Full Year (Dense)
  * `Entity`: 500 members (Sparse)
  * `Product`: 2,000 members (Sparse)
  * `Scenario`: 3 members (Sparse)
* **Calculation**:
  $$\text{Block Size} = 120 \times 17 \times 8 \text{ bytes} = 16,320 \text{ bytes} \approx 16 \text{ KB}$$
* **Evaluation**: A 16 KB block size is slightly light but acceptable. If we make `Scenario` Dense:
  $$\text{Block Size} = 120 \times 17 \times 3 \times 8 \text{ bytes} = 48,960 \text{ bytes} \approx 48 \text{ KB}$$
  This brings the block into the ideal performance zone (~50 KB)!

### 9. Compare Choices: Dense vs. Sparse Decision Matrix

| Dimension Characteristic | Designate as Dense | Designate as Sparse |
| :--- | :--- | :--- |
| **Data Population** | High (>70% populated coordinates) | Low (<10% populated coordinates) |
| **Typical Dimensions** | Account, Period | Entity, Product, Customer, Market |
| **Physical Storage** | Contiguous 8-byte cells in `.PAG` | Addresses in `.IND` B-Tree index |
| **Calculation Speed** | Ultra-fast in-memory array pointer | Cross-block navigation overhead |
| **Risk if Misconfigured** | Massive block size (>1MB) $\to$ Out of Memory | Millions of blocks $\to$ Index thrashing |

### 10. How to Validate Success
1. In the Essbase Job Console or Database Statistics, inspect **Block Size**.
2. Confirm **Block Size is between 50,000 bytes (50KB) and 250,000 bytes (250KB)**.
3. Review **Block Density %**; ideal average density should be **>60%**.

### 11. Troubleshooting Common Issues
* **Symptom: Essbase server crashes with out-of-memory error during data load.**
  * *Cause*: Too many dimensions set to Dense, producing blocks >5MB. Each worker thread attempting to load blocks exhausts system RAM.
  * *Remedy*: Change the largest dense dimensions (except Account and Period) to Sparse; restructure the outline.
* **Symptom: Database size is 50GB despite only having 100,000 actual data numbers.**
  * *Cause*: Dimensions with low population were marked Dense, creating massive blocks full of empty `#MISSING` zeros.
  * *Remedy*: Switch low-population dimensions to Sparse.

### 12. Remember and Explain It (Active Recall & Teach-Back)
* **Quick Recap**: Dense dimensions create the internal cells of each block; Sparse dimensions create the address coordinates. Keep block size between 50KB and 250KB.
* **Recall Question 1**: How many bytes does a single Essbase numeric cell consume in a data block—
  * *Answer*: Exactly 8 bytes (double-precision floating point number).
* **Recall Question 2**: Do Dynamic Calc members contribute to the physical block size of a dense dimension—
  * *Answer*: No! Only stored members consume physical space in the block array.
* **Teach-Back Prompt**: *Explain to a colleague why setting all 8 dimensions in an EPM application to "Dense" would destroy system performance rather than make it faster.*

---

## Summary

> **Dense dimensions define the shape (size) of every block — make them small and highly populated. Sparse dimensions define which blocks exist — make them large and sparsely populated. The single most critical metric is BLOCK SIZE: keep it between 8 KB and 200 KB. Analyze your data population patterns to determine which dimensions should be sparse vs. dense. Getting this wrong can make your database 100× slower and larger.**

---

**← Previous:** [02 — Data Storage Architecture](./02_Essbase_Data_Storage_Architecture.md)  
**Next →** [04 — Block Storage Deep Dive](./04_Block_Storage_Deep_Dive.md)

# What Is Essbase — The Complete Foundation

> **Folder:** 07_Essbase_Architecture | **Audience:** Beginner → Architect
>
> **Provenance:** Merged from ChatGPT `Essbase_Internal_Architecture/01_What_Is_Essbase.md`; Claude `03_Essbase/03.20_Essbase_Architecture_Deep_Dive.md`; Gemini `Essbase_Internal_Architecture/01_What_Is_Essbase.md`

---

## What Is Essbase?

**Essbase** (Extended Spread Sheet dataBASE) is a **multidimensional database** (MDDB) server. Originally developed by Arbor Software in 1992, later acquired by Hyperion Solutions, and then by Oracle Corporation in 2007.

**Plain language:** If EPM is a car, Essbase is the engine. Every number you see in an EPM form, every calculation that runs, every report that's generated — all of it is powered by Essbase.

---

## Essbase Is NOT a Relational Database

This is the **single most important concept** to understand:

| Feature | Relational Database (Oracle DB, SQL Server) | Essbase |
|---------|------------------------------------------|---------:|
| **Data Model** | Tables with rows and columns | Multidimensional cubes |
| **Query Language** | SQL | MDX, Calc Scripts, Report Scripts |
| **Data Storage** | Tablespaces, data pages | .PAG files (page files) + .IND files (index files) |
| **How data is located** | B-tree/hash indexes | Index files pointing to block locations |
| **Primary use** | Transaction processing (OLTP) | Analytical processing (OLAP) |
| **Aggregation** | Computed at query time (slow) | Pre-aggregated and stored (fast) |
| **Dimensionality** | 2D (row × column) | N-dimensional (up to 256 dimensions) |
| **Schema** | Normalized/denormalized tables | Hierarchical dimension outlines |

### Why Essbase Exists

In the relational world, to answer *"What were the sales of Product X in Region Y for Month Z in Scenario Budget?"* you need complex SQL JOINs, GROUP BY, and aggregation across millions of rows.

In Essbase, this answer is **pre-computed and stored at a specific cell intersection** — it's a single lookup, effectively O(1) retrieval time.

---

## The Multidimensional Concept

### What Is a Dimension?

A **dimension** is a category of analysis — one axis of a multidimensional space.

| Dimension | Purpose | Example Members |
|-----------|---------|-----------------:|
| **Account** | What is being measured | Revenue, COGS, Net Income, Headcount |
| **Period** | When | Jan, Feb, Q1, FY2024 |
| **Year** | Which fiscal year | FY2023, FY2024, FY2025 |
| **Scenario** | Which version of reality | Actual, Budget, Forecast |
| **Version** | Draft or approved | Working, Final |
| **Entity** | Who/Where | Corp, US_East, UK_London |
| **Product** | What is being sold | Product_A, Product_B |
| **Currency** | In what currency | USD, EUR, GBP, LC |

### What Is a Cube?

A **cube** is a multidimensional data space defined by its dimensions. 5 dimensions = a 5-dimensional hypercube.

```
Imagine a 3D cube:
                    ┌─────────────────────┐
                   /│                     /│
                  / │    Jan  Feb  Mar   / │
                 /  │   ┌────┬────┬───┐/  │
                /   │   │ 100│ 200│150││   │  ← Account axis
     Product A /    │   ├────┼────┼───┤│   │
              /     │   │ 50 │ 75 │ 80││   │
             /      │   └────┴────┴───┘│   │
            /       └──────────────────/
           └──────────────────────────┘
                  ↑ Period axis
```

Now extend this to 8+ dimensions — that's Essbase.

### What Is a Cell?

A **cell** is a single intersection of all dimensions:

```
Cell = (Revenue, Jan, FY2024, Actual, Working, US_East, Product_A, USD)
Value = $150,000
```

Every data point in Essbase lives at a specific cell address defined by one member from each dimension.

---

## Storage Types: BSO, ASO, and Hybrid

### BSO — Block Storage Option (MOLAP)

- **The classic Essbase architecture** and primary storage for Planning
- Data stored in **multidimensional blocks** in proprietary binary files (.PAG)
- Supports both data input AND calculations
- Each block contains all Dense dimension intersections

**Use BSO when:** Users enter data (planning, budgeting, forecasting)

### ASO — Aggregate Storage Option

- Optimized for **read-heavy, aggregate-heavy** queries
- Data loaded (not entered), then dynamically aggregated
- Faster queries on large datasets; limited calculation capability
- Uses different internal storage (not blocks in the BSO sense)

**Use ASO when:** Reporting, consolidation, large-scale read-only analysis

### Hybrid BSO

- BSO storage with ASO-style **dynamic aggregation** for upper-level members
- Enabled by setting `ASODYNAMICAGGINBSO` on the database
- Combines BSO input capability with ASO query performance
- Some BSO functions not supported in Hybrid mode

**Use Hybrid when:** You need BSO input with better query performance at upper levels

---

## Sparse vs Dense — The Most Critical Design Decision

This is where Essbase performance is won or lost.

| Aspect | Dense Dimension | Sparse Dimension |
|--------|----------------|------------------|
| **Role** | Defines the SHAPE of each block | Defines WHICH blocks exist |
| **Typical examples** | Account, Period | Entity, Product, Scenario |
| **Why?** | Almost every entity has every account for every period | Not every entity sells every product in every scenario |
| **Impact** | More dense members = larger blocks | More sparse members = more blocks |

### The Hourglass Principle

The optimal outline design follows an **hourglass shape**:
- **Sparse dimensions:** Can be large (many members) — they create more blocks, but blocks are small
- **Dense dimensions:** Should be small (fewer members) — they define block size

```
OPTIMAL: The Hourglass
         ┌───────────────┐
         │ Sparse: Large │  ← Many members OK
         │ (Entity: 500) │
         └───────┬───────┘
                 │
         ┌───────┴───────┐
         │ Dense: Small  │  ← Keep members small
         │ (Account: 50) │
         │ (Period: 12)  │
         └───────┬───────┘
                 │
         ┌───────┴───────┐
         │ Sparse: Large │  ← Many members OK
         │ (Product: 200)│
         └───────────────┘

Block Size = Account members × Period members × (other Dense)
           = 50 × 12 = 600 cells per block (small, efficient)

Number of Blocks = Entity × Product × Scenario × (other Sparse)
                 = 500 × 200 × 3 = 300,000 blocks
```

> **Warning:** Making too many dimensions Dense creates enormous blocks. 15 Dense dimensions can crash an Essbase server because each block would contain billions of cells, most of which are empty (#Missing).

---

## Data Retrieval: How Essbase Finds Your Number

```
User opens a form showing Revenue for Jan, Budget, US_East:

Step 1: Essbase identifies the block address
        → Sparse coordinates: (Budget, US_East)
        
Step 2: Essbase looks up the block in the INDEX file (.IND)
        → Index says: "Block at offset 45,678 in PAGE file"
        
Step 3: Essbase reads the block from the PAGE file (.PAG)
        → Block is decompressed into memory
        
Step 4: Essbase locates the cell WITHIN the block
        → Dense coordinates: (Revenue, Jan)
        → Direct array offset calculation (O(1) lookup)
        
Step 5: Value returned to the form
        → $150,000
```

---

## Plan Types in EPM Cloud

In Oracle EPM Cloud, Essbase cubes are called **Plan Types**:

| Plan Type | Storage | Purpose |
|-----------|---------|---------|
| **Plan1** | BSO | Primary planning cube (data entry) |
| **Plan2** | BSO | Secondary planning cube |
| **Plan3** | BSO | Tertiary planning cube |
| **Reporting** | ASO | Read-only reporting/consolidation |
| **OEP_FS** | BSO | Pre-built Financials module cube |
| **OEP_WFP** | BSO | Pre-built Workforce Planning cube |
| **OEP_CPX** | BSO | Pre-built Capital Planning cube |

---

## 🧠 Self-Check Questions

1. **How is Essbase different from a relational database?**
2. **What is a cell in Essbase? Give an example with 5 dimensions.**
3. **What is the difference between BSO and ASO?**
4. **What do Dense dimensions define? What do Sparse dimensions define?**
5. **Why is the Hourglass Principle important?**
6. **What happens if you make 15 dimensions Dense?**
7. **How does Essbase physically locate a data value?**

> **Teach-back prompt:** Explain to a new EPM developer why they can't treat Essbase like an Oracle SQL database. Then draw the sparse/dense concept on a whiteboard and explain what happens when a user saves data in a form.

---

## What's Next?

→ [02_Essbase_Storage.md](02_Essbase_Storage.md) — Deep dive into blocks, .PAG/.IND files, compression


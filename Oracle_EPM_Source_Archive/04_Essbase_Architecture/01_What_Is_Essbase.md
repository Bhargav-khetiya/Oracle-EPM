# 01 — What Is Essbase: The Complete Foundation

---

## 1.1 What Is Essbase—

**Essbase** (Extended Spread Sheet dataBASE) is a **multi-dimensional database** (MDDB) server developed originally by Arbor Software in 1992, later acquired by Hyperion Solutions, and then by Oracle Corporation in 2007.

### Essbase Is NOT a Relational Database

This is the single most important concept to understand:

| Feature | Relational Database (Oracle, SQL Server) | Essbase |
|---------|------------------------------------------|---------|
| Data Model | Tables with rows and columns | Multi-dimensional cubes |
| Query Language | SQL | MDX, Report Scripts, Calc Scripts |
| Data Storage | .DBF files, tablespaces, data pages | .PAG files (page files) + .IND files (index files) |
| How data is located | B-tree indexes, hash indexes | Index files pointing to block locations in page files |
| Primary use | Transaction processing (OLTP) | Analytical processing (OLAP) |
| Aggregation | Computed at query time (slow) | Pre-aggregated and stored (fast) |
| Dimensionality | 2-dimensional (row × column) | N-dimensional (up to 256 dimensions) |
| Schema | Normalized/denormalized tables | Hierarchical dimension outlines |

### Why Essbase Exists

In the relational world, if you want to answer: *"What were the sales of Product X in Region Y for Month Z in Scenario Budget—* — you need to:

1. Write a complex SQL JOIN across multiple tables
2. GROUP BY and aggregate on the fly
3. Wait for the query to process millions of rows

In Essbase, this answer is **pre-computed and stored at a specific cell intersection** — it's a single lookup, effectively O(1) retrieval time.

---

## 1.2 The Multi-Dimensional Concept

### What Is a "Dimension"—

A dimension is a **category of analysis**. Think of it as one axis of a multi-dimensional space.

**Common dimensions in EPM/Planning:**

| Dimension | Purpose | Example Members |
|-----------|---------|-----------------|
| Account | What is being measured | Revenue, COGS, Net Income, Headcount |
| Period | When | Jan, Feb, Q1, FY2024 |
| Year | Which fiscal year | FY2023, FY2024, FY2025 |
| Scenario | Which version of reality | Actual, Budget, Forecast |
| Version | Draft or approved | Working, Final |
| Entity | Who/Where | Corp, US_East, UK_London |
| Product | What is being sold | Product_A, Product_B, All_Products |
| Currency | In what currency | USD, EUR, GBP, LC (Local Currency) |

### What Is a "Cube"—

A cube is a **multi-dimensional data space** defined by its dimensions. If you have 5 dimensions, you have a 5-dimensional cube (a "hypercube").

```
Imagine a 3D cube:
                    ┌─────────────────────┐
                   /│                     /│
                  / │    Jan  Feb  Mar   / │
                 /  │   ┌────┬────┬───┐/  │
                /   │   │ 100│ 200│150││   │
     Product A /    │   ├────┼────┼───┤│   │  ← Account axis
              /     │   │ 50 │ 75 │ 80││   │
             /      │   ├────┼────┼───┤│   │
            /       │   │ 50 │125 │ 70││   │
           /        └───┴────┴────┴───┘/
          /         Revenue            /
         /          COGS              /
        /           Net Income       /
       └─────────────────────────────┘
              ↑ Period axis
```

Now extend this to 8+ dimensions — that's Essbase.

### What Is a "Cell"—

A cell is a **single intersection** of all dimensions. For example:

```
Cell = (Revenue, Jan, FY2024, Actual, Working, US_East, Product_A, USD)
Value = $150,000
```

Every data point in Essbase lives at a specific cell address defined by one member from each dimension.

---

## 1.3 OLAP Types: MOLAP vs ROLAP vs HOLAP

Essbase supports multiple storage architectures:

### BSO (Block Storage Option) — MOLAP

- **This is the classic Essbase architecture** and the primary focus of this documentation
- Data is stored in **multi-dimensional blocks** in proprietary binary files (.PAG)
- Data is **pre-aggregated** — upper-level members store calculated values
- Supports **write-back** — users can input data directly
- Supports **complex calculations** via Calc Scripts and Business Rules
- Best for: Planning, Budgeting, Forecasting (where data input is needed)

### ASO (Aggregate Storage Option) — MOLAP variant

- Data is stored differently — **only leaf-level (Level 0) data is stored**
- Aggregations are computed **on-the-fly** at query time (or via aggregate views)
- **Read-only** by design (no direct data input through forms)
- Supports **very large dimensions** (millions of members)
- Best for: Reporting, Analysis, Large Historical datasets

### Comparison: BSO vs ASO

| Feature | BSO (Block Storage) | ASO (Aggregate Storage) |
|---------|--------------------|-----------------------|
| Storage Model | Pre-aggregated blocks | Leaf-level only + aggregate views |
| Write-back | ✅ Yes | ❌ No (read-only) |
| Calc Scripts | ✅ Full support | ❌ Not supported |
| Business Rules | ✅ Full support | ⚠️ Limited (MDX only) |
| Max Dimensions | ~20 practical | 100+ practical |
| Max Members/Dim | Thousands | Millions |
| Data Input Forms | ✅ Yes | ❌ No |
| Aggregation Speed | Instant (pre-calculated) | Fast (on-the-fly with views) |
| Sparse/Dense concept | ✅ Yes (core concept) | ❌ No (different model) |
| Use Case | Planning, Budgeting | Reporting, Large Analysis |

---

## 1.4 Where Essbase Fits in Oracle EPM

```
┌─────────────────────────────────────────────────────────────┐
│                    USER INTERFACE LAYER                       │
│  ┌──────────┐  ┌──────────────┐  ┌───────────────────────┐  │
│  │ Smart View│  │ Planning Web │  │ Financial Reporting   │  │
│  │ (Excel)   │  │ Forms        │  │ (FR Studio/Web)       │  │
│  └─────┬─────┘  └──────┬───────┘  └───────────┬───────────┘  │
│        │               │                      │              │
├────────┼───────────────┼──────────────────────┼──────────────┤
│        │    APPLICATION/MIDDLEWARE LAYER       │              │
│        │               │                      │              │
│  ┌─────▼───────────────▼──────────────────────▼───────────┐  │
│  │              Oracle Planning (Java App)                  │  │
│  │   - Form definitions (stored in relational DB)          │  │
│  │   - Business Rules (stored in relational DB)            │  │
│  │   - Task Lists, Approvals, Workflows                    │  │
│  │   - Calc Manager scripts                                │  │
│  └──────────────────────┬──────────────────────────────────┘  │
│                         │                                     │
├─────────────────────────┼─────────────────────────────────────┤
│                         │    DATA STORAGE LAYER               │
│   ┌─────────────────────▼─────────────────────────────┐      │
│   │              ESSBASE SERVER                         │      │
│   │                                                     │      │
│   │   ┌─────────────┐  ┌──────────────┐                │      │
│   │   │ Application  │  │ Application  │                │      │
│   │   │  ┌─────────┐ │  │  ┌─────────┐ │                │      │
│   │   │  │Database 1│ │  │  │Database 3│ │                │      │
│   │   │  │ .PAG     │ │  │  │ .PAG     │ │                │      │
│   │   │  │ .IND     │ │  │  │ .IND     │ │                │      │
│   │   │  │ .OTL     │ │  │  │ .OTL     │ │                │      │
│   │   │  └─────────┘ │  │  └─────────┘ │                │      │
│   │   │  ┌─────────┐ │  │              │                │      │
│   │   │  │Database 2│ │  │              │                │      │
│   │   │  └─────────┘ │  │              │                │      │
│   │   └─────────────┘  └──────────────┘                │      │
│   │                                                     │      │
│   │   Physical Files on Disk:                           │      │
│   │   ARBORPATH/app/<AppName>/<DbName>/                 │      │
│   │     ├── <DbName>.otl    (Outline)                   │      │
│   │     ├── <DbName>.ind    (Index)                     │      │
│   │     ├── <DbName>.pag    (Data/Page)                 │      │
│   │     ├── ess00001.ind    (Index overflow)            │      │
│   │     ├── ess00001.pag    (Data overflow)             │      │
│   │     ├── <DbName>.esm    (Metadata)                  │      │
│   │     ├── <DbName>.tct    (Transaction control)       │      │
│   │     └── <DbName>.otl.keep (Outline backup)          │      │
│   └─────────────────────────────────────────────────────┘      │
│                                                                │
│   ┌─────────────────────────────────────────────────────┐      │
│   │         RELATIONAL DATABASE (Oracle RDBMS)           │      │
│   │                                                     │      │
│   │   - Planning Repository tables                      │      │
│   │   - Form definitions                                │      │
│   │   - Business Rule definitions                       │      │
│   │   - Security/provisioning                           │      │
│   │   - Task lists and workflows                        │      │
│   │   - Smart List definitions                          │      │
│   │   - Member metadata (for Planning dimensions)       │      │
│   └─────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1.5 Essbase Application and Database Hierarchy

```
Essbase Server
├── Application 1 (e.g., "HrPlan")
│   ├── Database 1 (e.g., "HrPlan")     ← This is the cube
│   └── Database 2 (e.g., "HrRpt")      ← Another cube
├── Application 2 (e.g., "FinPlan")
│   ├── Database 1 (e.g., "FinPlan")
│   └── Database 2 (e.g., "FinRpt")
└── Application 3 (e.g., "WFPlan")
    └── Database 1 (e.g., "WFPlan")
```

### Key Terms

| Term | Definition |
|------|-----------|
| **Application** | A logical container that holds one or more databases. Maps to a folder on disk. |
| **Database** | A single cube/hypercube. Has its own outline, data, and configuration. |
| **Outline** | The metadata definition of the cube — dimensions, members, hierarchies, formulas. Stored in `.OTL` file. |
| **Member** | A single element within a dimension (e.g., "January" in Period dimension). |
| **Generation** | The level of a member counting from the TOP of the hierarchy (Gen 1 = top). |
| **Level** | The level of a member counting from the BOTTOM (Level 0 = leaf/input level). |

---

## 1.6 Key File Types in Essbase

| File Extension | Name | Purpose |
|----------------|------|---------|
| `.OTL` | Outline file | Stores the complete dimension/member hierarchy, properties, formulas |
| `.IND` | Index file | Maps sparse dimension intersections to physical data block locations |
| `.PAG` | Page file (Data file) | Stores the actual data blocks containing cell values |
| `.ESM` | Essbase metadata | Stores database configuration and metadata |
| `.TCT` | Transaction control | Manages concurrent access and transaction logging |
| `.OTL.KEEP` | Outline backup | Backup of outline before last restructure |
| `.CSC` | Calc script | Business rule / calculation script source |
| `.REP` | Report script | Report definition |
| `.RUL` | Rules file | Data load / dimension build rules |
| `.TXT` / `.CSV` | Data files | Source data for loading |

---

## 1.7 How Essbase Differs from a Spreadsheet

People often think of Essbase as "a big spreadsheet." This is dangerously misleading.

| Feature | Spreadsheet | Essbase |
|---------|------------|---------|
| Dimensions | 2 (rows × columns) | Up to 256 |
| Users | Single user | Multi-user concurrent |
| Data volume | ~1 million rows | Billions of cells |
| Aggregation | Manual formulas | Automatic hierarchical roll-up |
| Security | File-level | Cell-level (dimensional security) |
| Audit trail | None | Transaction logging |
| Data integrity | Fragile (broken formulas) | Structural (outline-driven) |

---

## 1.8 The Essbase Lifecycle in EPM

```
1. DESIGN PHASE
   └── Define dimensions, hierarchies, sparse/dense settings
       └── Create outline (.OTL)

2. BUILD PHASE
   └── Build dimension members (from flat files or relational sources)
       └── Using rules files (.RUL)

3. LOAD PHASE
   └── Load data into the cube
       └── From flat files, SQL, or EPM integrations

4. CALCULATE PHASE
   └── Run calc scripts or business rules
       └── Aggregate data, apply business logic

5. REPORT PHASE
   └── Users retrieve data via Smart View, Forms, Reports
       └── Essbase retrieves from blocks in .PAG files

6. MAINTAIN PHASE
   └── Backup, restructure, optimize, export
       └── Manage .IND and .PAG files, cache settings
```

---

## Summary

> **Essbase is a multi-dimensional database engine that stores data in blocks (not tables). It is NOT a relational database. Data lives in proprietary .PAG and .IND files on the Essbase server's filesystem. Everything you see in Planning forms, Smart View, and reports — the actual numbers — come from Essbase blocks. But the form definitions, rules, security, and metadata are stored separately in a relational database (Oracle RDBMS).**

---

**Next →** [02 — Essbase Data Storage Architecture](./02_Essbase_Data_Storage_Architecture.md)

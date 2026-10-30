# 02 — Essbase Data Storage Architecture: How Data Is Physically Stored

---

## 2.1 The Fundamental Truth: Essbase Is NOT Relational

Before diving into architecture, burn this into your mind:

```
┌──────────────────────────────────────────────────────────┐
│                                                          │
│   Relational DB:  Data → Tables → Rows → Columns        │
│                   Located via: SQL queries + B-tree      │
│                                                          │
│   Essbase BSO:    Data → BLOCKS → Cells                  │
│                   Located via: INDEX files                │
│                   Stored in:   PAGE files                 │
│                                                          │
│   Essbase does NOT use tables, rows, or SQL.             │
│   It uses a proprietary binary storage format.           │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## 2.2 The Three Pillars of Essbase Storage

Essbase data storage rests on three foundational concepts:

### Pillar 1: The Outline (.OTL)
- Defines the **structure** of the cube
- Contains all dimensions, members, hierarchies, properties, formulas
- Determines which dimensions are **sparse** and which are **dense**
- The outline is the **blueprint** — changing it triggers a **restructure**

### Pillar 2: The Index (.IND files)
- Maps **sparse dimension combinations** to physical block locations
- Think of it as a **table of contents** for a book
- Tells Essbase: *"The block for Entity=US_East, Product=Widget_A, Scenario=Actual is located at offset X in page file Y"*

### Pillar 3: The Data/Page Files (.PAG files)
- Contains the actual **data blocks** with cell values
- Think of it as the **pages of the book**
- Each block is a fixed-size array of dense dimension cells

```
Analogy:

    OUTLINE = The library catalog system (defines what books exist)
    INDEX   = The card catalog (tells you which shelf/page)
    PAGE    = The actual book pages (contains the content)
    
    To find data:
    1. Essbase looks at the OUTLINE to understand the structure
    2. Searches the INDEX for the sparse combination
    3. Reads the BLOCK from the PAGE file at the indexed location
    4. Returns the specific cell from within the block
```

---

## 2.3 Physical File Layout on Disk

When you create an Essbase database, the following files are created on the server:

```
$ARBORPATH/app/
└── <ApplicationName>/
    └── <DatabaseName>/
        ├── <DatabaseName>.otl          ← Outline (structure definition)
        ├── <DatabaseName>.ind          ← Primary index file
        ├── <DatabaseName>.pag          ← Primary page/data file
        ├── ess00001.ind                ← Index overflow file 1
        ├── ess00001.pag                ← Page overflow file 1  
        ├── ess00002.ind                ← Index overflow file 2
        ├── ess00002.pag                ← Page overflow file 2
        ├── ...                         ← More overflow files as needed
        ├── <DatabaseName>.esm          ← Security/metadata
        ├── <DatabaseName>.tct          ← Transaction control table
        ├── <DatabaseName>.otl.keep     ← Outline backup (pre-restructure)
        ├── <DatabaseName>.ddb          ← Database definition
        └── temp/                       ← Temporary files during operations
```

### Why Multiple .IND and .PAG Files?

Each `.IND` and `.PAG` file has a **maximum size limit** (configurable, default ~2GB per file). When a file reaches its limit, Essbase creates overflow files:

```
<DbName>.ind    → ess00001.ind → ess00002.ind → ...
<DbName>.pag    → ess00001.pag → ess00002.pag → ...
```

The `DATAFILECACHESIZE` configuration setting controls how many of these files can be open simultaneously.

---

## 2.4 The Block — The Fundamental Unit of Storage

### What Is a Block?

A **block** is the smallest unit of data storage in Essbase BSO. It is a **fixed-size, multi-dimensional array** formed by all **dense dimensions**.

```
If your dense dimensions are:
  - Account: 100 members (at Level 0 + upper levels)
  - Period:  17 members (Jan-Dec + Q1-Q4 + Year)

Then each block = 100 × 17 = 1,700 cells
Each cell = 8 bytes (double-precision floating point)
Block size = 1,700 × 8 = 13,600 bytes ≈ 13.3 KB
```

### How Blocks Are Created

A block is created (or exists) for each **unique combination of sparse dimension members** that has data.

```
If your sparse dimensions are:
  - Entity:   500 members
  - Product:  200 members  
  - Scenario: 3 members (Actual, Budget, Forecast)
  - Version:  2 members (Working, Final)
  - Year:     5 members (FY2020-FY2024)

Maximum possible blocks = 500 × 200 × 3 × 2 × 5 = 3,000,000 blocks
```

But NOT all combinations have data! If only 10% have data:
```
Actual blocks = 300,000 blocks
Total data = 300,000 × 13.3 KB ≈ 3.9 GB
```

### The Key Insight: Sparse Dimensions Determine WHICH Blocks Exist

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  Dense dimensions → Define the SHAPE (size) of each     │
│                     block (same for ALL blocks)          │
│                                                         │
│  Sparse dimensions → Define WHICH blocks exist          │
│                      (only combinations with data)       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

Visual:

```
Sparse combo: Entity=US_East, Product=Widget, Scenario=Actual, Year=FY24

Creates ONE block:
┌──────────────────────────────────────────────┐
│            Jan  Feb  Mar ... Dec  Q1  Q2 ... │
│ Revenue    100  120  130     200  350 ...     │
│ COGS        50   60   65     100  175 ...     │
│ Gross Pft   50   60   65     100  175 ...     │
│ ...                                          │
│ Net Income  30   35   40      60  105 ...     │
└──────────────────────────────────────────────┘
     ↑ Dense: Account (rows) × Period (columns)

Another sparse combo: Entity=UK, Product=Gadget, Scenario=Budget, Year=FY24

Creates ANOTHER block with the SAME SHAPE:
┌──────────────────────────────────────────────┐
│            Jan  Feb  Mar ... Dec  Q1  Q2 ... │
│ Revenue    200  180  190     220  570 ...     │
│ COGS       100   90   95     110  285 ...     │
│ ...                                          │
└──────────────────────────────────────────────┘
```

---

## 2.5 How Essbase Locates Data — The Retrieval Process

When a user requests data (e.g., through a form or Smart View), here's what happens internally:

```
Step 1: PARSE THE REQUEST
   User requests: Revenue, Jan, FY2024, Actual, Working, US_East, Product_A
   
Step 2: SPLIT INTO SPARSE AND DENSE COMPONENTS
   Sparse key:  (FY2024, Actual, Working, US_East, Product_A)
   Dense cell:  (Revenue, Jan)
   
Step 3: SEARCH THE INDEX
   Essbase searches the .IND file for the sparse key
   Index entry found: Block #47832, Page file ess00003.pag, Offset 0x4F200
   
Step 4: READ THE BLOCK FROM DISK
   Read 13,600 bytes from ess00003.pag at offset 0x4F200
   Decompress if necessary (blocks can be compressed)
   
Step 5: LOCATE THE CELL WITHIN THE BLOCK
   Within the 1,700-cell block, find cell at position:
   Position = (Revenue_offset × Period_count) + Jan_offset
   Position = (0 × 17) + 0 = 0
   
Step 6: RETURN THE VALUE
   Cell value = 150000.00
```

```
Diagram:

  User Request                     Index (.IND)                    Page (.PAG)
  ───────────                     ────────────                    ────────────
  Revenue, Jan, FY24,     ──►    Sparse Key Lookup:       ──►    Read Block:
  Actual, Working,               (FY24,Act,Wrk,           ┌──────────────────┐
  US_East, Product_A              US_E,Prod_A)             │ Block #47832     │
                                  → File: ess00003.pag     │ ┌──────────────┐ │
                                  → Offset: 0x4F200        │ │Rev,Jan=150K  │ │
                                                           │ │Rev,Feb=120K  │ │
                                                           │ │...           │ │
                                                           │ └──────────────┘ │
                                                           └──────────────────┘
```

---

## 2.6 Data Storage at the Bit Level

Each cell in a block is stored as an **IEEE 754 double-precision floating-point number** (8 bytes / 64 bits):

```
Bit layout of a single cell:
┌───┬──────────────┬─────────────────────────────────────────────┐
│ S │  Exponent    │              Mantissa (Fraction)             │
│1b │  11 bits     │              52 bits                         │
└───┴──────────────┴─────────────────────────────────────────────┘

S = Sign bit (0 = positive, 1 = negative)
Exponent = Power of 2
Mantissa = Significant digits

Range: ±5.0 × 10^−324 to ±1.7976931348623157 × 10^308
Precision: ~15-17 significant decimal digits
```

### Block Memory Layout

A block is stored as a **contiguous array** of cells in memory:

```
Block for (FY24, Actual, Working, US_East, Product_A):

Memory offset:  0x000  0x008  0x010  0x018  0x020  ...
                ┌──────┬──────┬──────┬──────┬──────┬─────
                │Cell 0│Cell 1│Cell 2│Cell 3│Cell 4│ ...
                │ 8 B  │ 8 B  │ 8 B  │ 8 B  │ 8 B  │
                └──────┴──────┴──────┴──────┴──────┴─────

Cell addressing within block:
  Cell_Position = Σ(member_offset_i × product_of_subsequent_dimension_sizes)
  
  For 2 dense dims (Account=100, Period=17):
    Cell_Position = Account_offset × 17 + Period_offset
    
  Example: COGS (offset=1), March (offset=2)
    Cell_Position = 1 × 17 + 2 = 19
    Memory offset = 19 × 8 = 152 bytes from block start
```

---

## 2.7 Block Density and #Missing Values

Not every cell in a block contains a real value. Cells without data are marked as **#Missing** (represented internally as a special NaN value or zero, depending on configuration).

```
A typical block might look like:
┌────────────────────────────────────────────────┐
│ Revenue:    100  120  130  #M   #M   #M   350  │
│ COGS:        50   60   65  #M   #M   #M   175  │
│ Headcount:   10   10   11  #M   #M   #M    11  │
│ Deprec:      #M   #M   #M  #M   #M   #M    #M  │
│ Tax Rate:    #M   #M   #M  #M   #M   #M    #M  │
│ ...                                             │
└────────────────────────────────────────────────┘

Block Density = (Cells with data) / (Total cells in block)
             = 21 / 1,700 = 1.2%
```

### Why Block Density Matters

- **Low density** = wasted storage space (storing lots of #Missing values)
- **Very low density** = sign that outline design might be wrong
- **Compression** helps mitigate low density (Essbase compresses blocks)
- Typical healthy block density: **10% - 50%**
- Below 5%: Consider redesigning the outline

---

## 2.8 Compression

Essbase compresses blocks before writing them to .PAG files to save disk space.

### Compression Methods

| Method | Description | Best For |
|--------|-------------|----------|
| **Bitmap** (default) | Uses bitmap encoding to skip #Missing values | Blocks with many #Missing cells |
| **RLE** (Run-Length Encoding) | Compresses sequences of repeated values | Blocks with repeated values |
| **ZLIB** | Standard compression algorithm | Maximum compression |
| **None** | No compression | Maximum read speed (if disk space isn't an issue) |

```
Example of Bitmap compression:

Uncompressed block (8 cells × 8 bytes = 64 bytes):
[100.0] [#Missing] [#Missing] [200.0] [#Missing] [150.0] [#Missing] [#Missing]

Bitmap: 10010100 (1 = has data, 0 = missing)
Data:   [100.0] [200.0] [150.0]

Compressed size: 1 byte (bitmap) + 24 bytes (3 values) = 25 bytes
Compression ratio: 25/64 = 39% of original size
```

---

## 2.9 Storage Types: Input, Calculated, and #Missing

Within each block, cells can be in three states:

```
┌──────────────────────────────────────────────────────┐
│ State          │ Description                          │
├──────────────────────────────────────────────────────┤
│ INPUT DATA     │ Data loaded or entered by user       │
│                │ Stored on disk in .PAG files          │
│                │ Survives database restart              │
├──────────────────────────────────────────────────────┤
│ CALCULATED     │ Values computed by calc scripts       │
│                │ Stored on disk after calculation       │
│                │ Can be cleared and recalculated        │
├──────────────────────────────────────────────────────┤
│ #MISSING       │ No data exists for this intersection  │
│                │ Compressed away in storage             │
│                │ Returns "empty" to users               │
└──────────────────────────────────────────────────────┘
```

---

## 2.10 Full Data Flow — From User to Disk

```
USER ENTERS DATA IN FORM
        │
        ▼
PLANNING SERVER (Java Application)
        │ Validates data
        │ Checks security
        │ Applies smart list mappings
        ▼
ESSBASE PROVIDER SERVICES
        │ Translates to Essbase API calls
        ▼
ESSBASE SERVER (ESSSVR process)
        │
        ├── 1. Parse cell address into sparse+dense components
        │
        ├── 2. Lock the relevant block (concurrency control)
        │
        ├── 3. Search INDEX for block location
        │      └── If block doesn't exist → CREATE new block
        │          └── Allocate space in .PAG file
        │          └── Add entry to .IND file  
        │
        ├── 4. Load block into DATA CACHE (memory)
        │      └── If not already cached
        │      └── Decompress block
        │
        ├── 5. Update cell value within the block
        │      └── Calculate cell position from dense member offsets
        │      └── Write new value (8 bytes)
        │
        ├── 6. Mark block as DIRTY (modified, needs write-back)
        │
        ├── 7. Eventually FLUSH dirty blocks to disk
        │      └── Compress block
        │      └── Write to .PAG file
        │      └── Update .IND if block location changed
        │      └── Update .TCT (transaction control)
        │
        └── 8. Release block lock
                └── Other users can now access this block
```

---

## 2.11 Essbase vs Relational — A Side-by-Side Data Storage Example

### Scenario: Storing sales data for 3 entities, 2 products, 12 months, 5 accounts

**In a Relational Database (e.g., Oracle RDBMS):**

```sql
CREATE TABLE SALES_DATA (
    entity_id   VARCHAR2(20),
    product_id  VARCHAR2(20),
    month       VARCHAR2(10),
    account     VARCHAR2(20),
    value       NUMBER
);

-- 3 × 2 × 12 × 5 = 360 rows
INSERT INTO SALES_DATA VALUES ('US_East', 'Widget', 'Jan', 'Revenue', 100);
INSERT INTO SALES_DATA VALUES ('US_East', 'Widget', 'Jan', 'COGS', 50);
-- ... 358 more rows
```

Storage: 360 rows × ~100 bytes/row ≈ 36 KB + indexes

**In Essbase:**

```
Outline:
  Entity (sparse):   US_East, US_West, Europe
  Product (sparse):  Widget, Gadget
  Account (dense):   Revenue, COGS, Gross_Profit, OpEx, Net_Income
  Period (dense):    Jan, Feb, Mar, ..., Dec

Block size: 5 accounts × 12 months = 60 cells × 8 bytes = 480 bytes per block
Max blocks: 3 entities × 2 products = 6 blocks

Total storage: 6 × 480 = 2,880 bytes + index overhead ≈ 3 KB
```

Essbase is **12× more efficient** in this example because:
1. No redundant dimension values stored per row
2. No varchar overhead
3. Fixed-size blocks with direct addressing
4. No B-tree index overhead

---

## Summary

> **Essbase stores data in BLOCKS, not tables. Each block is a fixed-size array of cells defined by dense dimensions. The INDEX (.IND) maps sparse combinations to block locations. The PAGE files (.PAG) contain the actual block data. This architecture enables instant cell lookups and efficient multi-dimensional analysis that would require expensive JOINs and GROUP BYs in a relational database.**

---

**← Previous:** [01 — What Is Essbase](./01_What_Is_Essbase.md)  
**Next →** [03 — Sparse vs Dense — Complete Guide](./03_Sparse_vs_Dense_Complete_Guide.md)

# 10 — Behind the Scenes: Complete End-to-End Walkthroughs

---

## 10.1 Walkthrough 1: User Enters Data in a Form and Saves

This is the most common operation in Planning. Let's trace **every single step** from the moment a user clicks a form to when the data is permanently stored on disk.

```
ACTORS:
  👤 User (in browser)
  🌐 Web Server (Planning/Workspace)
  ☕ Planning Java Application
  📊 Essbase Server (ESSSVR process)
  💾 Disk (.PAG, .IND files)
  🗄️ Relational DB (Oracle RDBMS)
```

### Phase 1: Opening the Form

```
Step 1: 👤 User clicks "Revenue Input" form in Planning
        │
Step 2: 🌐 Web Server receives HTTP request
        │   POST /HyperionPlanning/servlet/HspLinkServlet
        │   Session authenticated (SSO token validated)
        │
Step 3: ☕ Planning App processes form request
        │   a. Query 🗄️ relational DB:
        │      SELECT * FROM HSP_FORM_DEF WHERE FORM_ID = 456
        │      → Gets form name, type, plan type
        │
        │   b. Query 🗄️ for form layout:
        │      SELECT * FROM HSP_FORM_LAYOUT WHERE FORM_ID = 456
        │      → Rows: Period (Jan, Feb, Mar, Q1)
        │      → Columns: Account (Revenue, COGS, Gross Profit)
        │      → POV: FY2024, Actual, Working
        │      → Page: Entity (User selects), Product (User selects)
        │
        │   c. Query 🗄️ for security:
        │      SELECT * FROM HSP_ACCESS_CTRL WHERE USER_ID = 789
        │      → User can read US_East, US_West
        │      → User can write US_East
        │      → User cannot see Europe (filtered out)
        │
        │   d. Build cell intersection list:
        │      All combinations of: 
        │        Rows × Columns × POV values × Page selections
        │      = (Jan,Feb,Mar,Q1) × (Revenue,COGS,GP) × 
        │        (FY24,Actual,Working,US_East,Widget)
        │      = 12 cell addresses
        │
Step 4: ☕ Planning sends data request to 📊 Essbase
        │   Via Essbase JAPI (Java API):
        │   "Retrieve cells at these 12 intersections"
        │
Step 5: 📊 Essbase processes retrieval
        │
        │   a. Group cells by block:
        │      All 12 cells belong to same sparse combination:
        │      (FY24, Actual, Working, US_East, Widget)
        │      → Need only 1 block
        │
        │   b. Compute block key from sparse members
        │      key = hash(FY24, Actual, Working, US_East, Widget) = 47832
        │
        │   c. Search INDEX CACHE for key 47832
        │      ├── CACHE HIT: Index page in memory → skip disk read
        │      └── CACHE MISS: Read .IND file → load index page → search
        │
        │   d. Index says: Block 47832 → ess00002.pag, offset 0x1A3400, size 1890
        │
        │   e. Check DATA CACHE for block 47832
        │      ├── CACHE HIT: Block in memory → skip disk read
        │      └── CACHE MISS: Read 💾 ess00002.pag at offset 0x1A3400
        │           → Read 1890 compressed bytes
        │           → Decompress → 13,600 bytes (100 accounts × 17 periods × 8)
        │           → Load into Data Cache
        │
        │   f. Extract requested cells from block:
        │      Revenue,Jan = block[offset(Revenue) × 17 + offset(Jan)] = 100
        │      Revenue,Feb = block[offset(Revenue) × 17 + offset(Feb)] = 120
        │      Revenue,Mar = block[offset(Revenue) × 17 + offset(Mar)] = 130
        │      COGS,Jan = block[offset(COGS) × 17 + offset(Jan)] = 50
        │      ... (12 cells extracted)
        │
        │   g. For Dynamic Calc members (e.g., Gross Profit):
        │      Gross_Profit = Revenue - COGS (calculated on-the-fly)
        │      GP,Jan = Revenue,Jan - COGS,Jan = 100 - 50 = 50
        │      GP,Feb = Revenue,Feb - COGS,Feb = 120 - 60 = 60
        │      GP,Mar = Revenue,Mar - COGS,Mar = 130 - 65 = 65
        │      Q1 values (if Dynamic Calc): Jan + Feb + Mar
        │
        │   h. Return 12 values to Planning
        │
Step 6: ☕ Planning formats the grid
        │   a. Apply member aliases (Jan → "January", Revenue → "Net Revenue")
        │   b. Apply number formatting (100 → $100, precision=0)
        │   c. Apply cell colors (red for negative, green for positive)
        │   d. Mark read-only cells (Gross Profit = formula, can't edit)
        │   e. Mark writable cells (Revenue, COGS for US_East)
        │   f. Apply Smart List formatting (if applicable)
        │
Step 7: 🌐 Web Server sends HTML/JSON response to browser
        │
Step 8: 👤 User sees the form with data:
        │
        │   Revenue Input - US_East, Widget
        │   POV: FY2024 | Actual | Working
        │   ┌─────────────┬──────────┬──────────┬──────────┬──────────┐
        │   │             │ January  │ February │  March   │    Q1    │
        │   ├─────────────┼──────────┼──────────┼──────────┼──────────┤
        │   │ Net Revenue │   $100   │   $120   │   $130   │   $350   │
        │   │ COGS        │    $50   │    $60   │    $65   │   $175   │
        │   │ Gross Profit│    $50   │    $60   │    $65   │   $175   │
        │   └─────────────┴──────────┴──────────┴──────────┴──────────┘
        │   (Gross Profit and Q1 are calculated, shown as read-only)
        
TIME ELAPSED: 200ms - 2 seconds (depending on cache hits/misses)
```

### Phase 2: User Modifies Data and Saves

```
Step 9: 👤 User changes Revenue, January from $100 to $160
        │   User changes Revenue, February from $120 to $150
        │   User clicks SAVE
        │
Step 10: 🌐 Web Server receives POST request
         │   Body: [{cell: "Rev,Jan,FY24,Act,Wrk,USE,Wdg", value: 160},
         │          {cell: "Rev,Feb,FY24,Act,Wrk,USE,Wdg", value: 150}]
         │
Step 11: ☕ Planning validates
         │   a. Check user write access: ✅ User can write US_East
         │   b. Check cell is writable: ✅ Revenue is not read-only
         │   c. Check value is valid: ✅ Numeric value
         │   d. Check planning unit status: ✅ Not locked/approved
         │
Step 12: ☕ Planning sends update to 📊 Essbase
         │   "Write value 160 to (Revenue,Jan,FY24,Actual,Working,US_East,Widget)"
         │   "Write value 150 to (Revenue,Feb,FY24,Actual,Working,US_East,Widget)"
         │
Step 13: 📊 Essbase processes the write
         │
         │   a. Group updates by block:
         │      Both cells → same block (US_East, Widget, FY24, Actual, Working)
         │
         │   b. ACQUIRE WRITE LOCK on block 47832
         │      └── If another user has it → WAIT (up to LOCKTIMEOUT)
         │      └── Lock acquired ✅
         │
         │   c. Block should already be in Data Cache (from the retrieval)
         │      If evicted → reload from .PAG (same process as retrieval)
         │
         │   d. UPDATE cells in memory:
         │      block[offset(Revenue) × 17 + offset(Jan)] = 160.0
         │      block[offset(Revenue) × 17 + offset(Feb)] = 150.0
         │
         │   e. MARK block as DIRTY
         │      Set dirty flag in block header
         │
         │   f. RELEASE WRITE LOCK
         │
         │   g. LOG transaction in .TCT file:
         │      "Block 47832 modified at 14:32:05.123 by user BhargavK"
         │
         │   h. Return SUCCESS to Planning
         │
Step 14: ☕ Planning checks for "On Save" business rule
         │   a. Query 🗄️: Is there a rule configured to run on save for this form—
         │   b. YES → Rule "CalcRevenueForm" is configured
         │
Step 15: ☕ Planning tells 📊 Essbase to run "CalcRevenueForm"
         │   The rule might be:
         │   FIX("Actual", "Working", "FY2024", "US_East", "Widget")
         │     CALC DIM("Account", "Period");
         │   ENDFIX
         │
Step 16: 📊 Essbase executes the calc script
         │
         │   a. FIX narrows scope to 1 block (US_East, Widget, FY24, Act, Wrk)
         │
         │   b. Block already in Data Cache (just modified)
         │
         │   c. CALC DIM("Account"):
         │      Gross_Profit = Revenue - COGS
         │      Jan: GP = 160 - 50 = 110  (was 50, now 110)
         │      Feb: GP = 150 - 60 = 90   (was 60, now 90)
         │      Mar: GP = 130 - 65 = 65   (unchanged)
         │      ... (all account formulas recalculated)
         │
         │   d. CALC DIM("Period"):
         │      Q1 = Jan + Feb + Mar
         │      Revenue Q1 = 160 + 150 + 130 = 440  (was 350)
         │      COGS Q1 = 50 + 60 + 65 = 175       (unchanged)
         │      GP Q1 = 110 + 90 + 65 = 265         (was 175)
         │      ... (all period aggregations)
         │
         │   e. Block still DIRTY (more changes)
         │
         │   f. Return calc complete to Planning
         │
Step 17: ☕ Planning retrieves updated values from 📊 Essbase
         │   (Same as retrieval in Step 4-5, but block is in cache)
         │
Step 18: 🌐 Send updated grid to 👤 User:
         │
         │   ┌─────────────┬──────────┬──────────┬──────────┬──────────┐
         │   │             │ January  │ February │  March   │    Q1    │
         │   ├─────────────┼──────────┼──────────┼──────────┼──────────┤
         │   │ Net Revenue │   $160 ▲ │   $150 ▲ │   $130   │   $440 ▲ │
         │   │ COGS        │    $50   │    $60   │    $65   │   $175   │
         │   │ Gross Profit│   $110 ▲ │    $90 ▲ │    $65   │   $265 ▲ │
         │   └─────────────┴──────────┴──────────┴──────────┴──────────┘
         │   (▲ = changed values)

Step 19: 📊 EVENTUALLY (async): Flush dirty block to 💾 disk
         │
         │   a. Compress block 47832 (bitmap compression)
         │      13,600 bytes → ~1,890 bytes
         │
         │   b. Write to ess00002.pag:
         │      └── If block fits in same location → overwrite
         │      └── If block size changed → relocate, update .IND
         │
         │   c. Clear dirty flag
         │
         │   d. Data is now PERMANENTLY STORED on disk 💾
         │
TIME ELAPSED: Save + Calc = 500ms - 5 seconds
```

---

## 10.2 Walkthrough 2: Running a Full CALC ALL

```
TRIGGER: Admin runs CALC ALL via MaxL or EAS

Step 1: 📊 Essbase receives CALC ALL command
        │
Step 2: 📊 Parse outline, determine calculation order (bottom-up)
        │   Order: Version → Scenario → Year → Period → Account → Product → Entity
        │
Step 3: ████████████████████████████████████████
        │ PHASE 1: Calculate Version (Sparse, bottom)
        │
        │ For each unique (Entity, Product, Year, Scenario):
        │   For each Version parent (e.g., "All_Versions"):
        │     Read child blocks: Working, Final
        │     If parent block doesn't exist → CREATE
        │     Aggregate: All_Versions = Working + Final
        │     Mark parent block dirty
        │
        │ I/O: Read N child blocks, Write N/2 parent blocks
        │ Time: ~2% of total calc time (small dimension)
        │
Step 4: ████████████████████████████████████████
        │ PHASE 2: Calculate Scenario (Sparse)
        │ 
        │ For each unique (Entity, Product, Year, Version):
        │   For each Scenario parent (e.g., "All_Scenarios"):
        │     Read child blocks: Actual, Budget, Forecast
        │     Aggregate into parent
        │     Mark dirty
        │
        │ Time: ~5% of total calc time
        │
Step 5: ████████████████████████████████████████
        │ PHASE 3: Calculate Year (Dense — INTRA-BLOCK!)
        │
        │ For EACH existing block:
        │   Load block into Data Cache
        │   Within the block:
        │     Year_Total = FY20 + FY21 + FY22 + FY23 + FY24
        │     (Just array addition — blazing fast!)
        │   Mark block dirty
        │
        │ Time: ~5% of total calc time (fast — in-memory)
        │
Step 6: ████████████████████████████████████████
        │ PHASE 4: Calculate Period (Dense — INTRA-BLOCK!)
        │
        │ For EACH existing block:
        │   Block should already be in cache (from Step 5)
        │   Within the block:
        │     Q1 = Jan + Feb + Mar
        │     Q2 = Apr + May + Jun
        │     Q3 = Jul + Aug + Sep
        │     Q4 = Oct + Nov + Dec
        │     Year = Q1 + Q2 + Q3 + Q4
        │   Mark dirty
        │
        │ Time: ~5% of total calc time
        │
Step 7: ████████████████████████████████████████
        │ PHASE 5: Calculate Account (Dense — INTRA-BLOCK!)
        │
        │ For EACH existing block:
        │   Block should be in cache
        │   Within the block:
        │     Gross_Profit = Revenue - COGS
        │     Operating_Income = Gross_Profit - OpEx
        │     Net_Income = Operating_Income - Tax
        │     Margin% = Net_Income / Revenue
        │     ... (all account formulas)
        │   Mark dirty
        │
        │ Time: ~8% of total calc time
        │   (More formulas than simple aggregation)
        │
Step 8: ████████████████████████████████████████
        │ PHASE 6: Calculate Product (Sparse)
        │
        │ For each unique (Entity, Scenario, Version, Year):
        │   For each Product parent in hierarchy:
        │     "All Products"
        │       ├── "Category A"
        │       │     ├── Widget   (read block)
        │       │     └── Gadget   (read block)
        │       │     → Write Category A block
        │       └── "Category B"
        │             ├── Gizmo    (read block)
        │             → Write Category B block
        │     → All Products = Category A + Category B
        │     → Write All Products block
        │
        │ BLOCKS CREATED: One for each upper-level Product member
        │                 × each Entity × Scenario × Version × Year
        │
        │ Time: ~25% of total calc time
        │
Step 9: ████████████████████████████████████████
        │ PHASE 7: Calculate Entity (Sparse — LARGEST, LAST)
        │
        │ For each unique (Product, Scenario, Version, Year):
        │   For each Entity parent in hierarchy:
        │     "Total Company"
        │       ├── "Americas"
        │       │     ├── US_East  (read block)
        │       │     ├── US_West  (read block)
        │       │     ├── Canada   (read block)
        │       │     → Write Americas block
        │       └── "Europe"
        │             ├── UK       (read block)
        │             ├── Germany  (read block)
        │             ├── France   (read block)
        │             → Write Europe block
        │     → Total Company = Americas + Europe
        │     → Write Total Company block
        │
        │ BLOCKS CREATED: One for each upper-level Entity member
        │                 × each Product × Scenario × Version × Year
        │
        │ Time: ~50% of total calc time (LARGEST — most blocks!)
        │
Step 10: 📊 Flush ALL dirty blocks to 💾 disk
         │   Compress each block
         │   Write to .PAG files
         │   Update .IND with new/moved entries
         │
Step 11: 📊 Log statistics
         │   "Total Calc Time: 720.5 seconds"
         │   "Blocks Created: 125,000"
         │   "Blocks Read: 450,000"
         │   "Blocks Written: 230,000"
         │
Step 12: 📊 Return completion status

TOTAL TIME: 12 minutes for this example database
```

---

## 10.3 Walkthrough 3: Data Load from Flat File

```
Data file: revenue_data.csv
US_East,Widget,Revenue,Jan,FY24,Actual,Working,100
US_East,Widget,Revenue,Feb,FY24,Actual,Working,120
US_East,Widget,COGS,Jan,FY24,Actual,Working,50
US_East,Widget,COGS,Feb,FY24,Actual,Working,60
US_West,Gadget,Revenue,Jan,FY24,Actual,Working,200
US_West,Gadget,Revenue,Feb,FY24,Actual,Working,180
... (100,000 records)

Step 1: 📊 Essbase receives load command
        │   "IMPORT DATA ... USING RULES_FILE 'RevenueLoad' ..."
        │
Step 2: 📊 Open rules file (.RUL)
        │   - Column mapping: Col1=Entity, Col2=Product, etc.
        │   - Data field: Col8
        │   - Skip/select criteria
        │   - Header record handling
        │
Step 3: 📊 Parse record 1:
        │   "US_East,Widget,Revenue,Jan,FY24,Actual,Working,100"
        │   
        │   a. Map columns to dimensions:
        │      Entity=US_East, Product=Widget, Account=Revenue,
        │      Period=Jan, Year=FY24, Scenario=Actual, Version=Working
        │   
        │   b. Validate all members exist in outline ✅
        │   
        │   c. Identify sparse key: (US_East, Widget, FY24, Actual, Working)
        │      Identify dense cell: (Revenue, Jan)
        │      Data value: 100
        │   
        │   d. Search INDEX for block:
        │      ├── Block exists → load into Data Cache
        │      └── Block doesn't exist → create new block
        │   
        │   e. Write value 100 at cell (Revenue, Jan) in block
        │   
Step 4: 📊 Parse record 2:
        │   "US_East,Widget,Revenue,Feb,FY24,Actual,Working,120"
        │   
        │   Same sparse key! Block already in Data Cache ★
        │   Just update cell (Revenue, Feb) = 120
        │   No disk I/O needed!
        │
Step 5: 📊 Continue for records 3, 4 (same block) ...
        │
Step 6: 📊 Parse record 5:
        │   "US_West,Gadget,Revenue,Jan,FY24,Actual,Working,200"
        │   
        │   DIFFERENT sparse key: (US_West, Gadget, FY24, Actual, Working)
        │   Previous block → mark dirty, may flush
        │   New block → search index, load or create
        │
        │   THIS IS WHY PRE-SORTING DATA IS CRITICAL:
        │   If data is sorted by sparse keys, each block is loaded ONCE
        │   If data is random, the same block may be loaded/unloaded hundreds of times
        │
Step 7: 📊 Continue for all 100,000 records...
        │   Periodically flush dirty blocks to disk
        │   Monitor Data Cache usage
        │
Step 8: 📊 COMMIT: Flush all remaining dirty blocks
        │   Write compressed blocks to .PAG
        │   Update .IND
        │   Update .TCT
        │
Step 9: 📊 Report statistics:
        │   "Records loaded: 98,500"
        │   "Records rejected: 1,500 (invalid members)"
        │   "Blocks created: 5,000"
        │   "Blocks updated: 12,000"
        │   "Elapsed time: 45 seconds"

PERFORMANCE COMPARISON:
  Sorted data:     45 seconds (each block loaded once)
  Unsorted data:   8 minutes (blocks loaded/unloaded multiple times)
  Improvement: 10× faster with sorted data!
```

---

## 10.4 Walkthrough 4: What Happens During a Database Restructure

```
TRIGGER: Admin changes Account dim from 150 to 160 stored members
         (added 10 new account members)

Step 1: 📊 Essbase detects outline change
        │   Dense dimension modified → FULL RESTRUCTURE required
        │
Step 2: 📊 LOCK DATABASE
        │   Disconnect all users
        │   Set database to exclusive mode
        │   
        │   ⚠️ DATABASE IS NOW OFFLINE
        │
Step 3: 📊 Calculate new block parameters
        │   Old block size: 150 × 17 × 8 = 20,400 bytes
        │   New block size: 160 × 17 × 8 = 21,760 bytes
        │   Each block grows by 1,360 bytes (10 members × 17 periods × 8)
        │
Step 4: 📊 Read ALL blocks from existing .PAG files
        │   200,000 blocks × 20,400 bytes = ~4 GB to read
        │   Each block: read, decompress, hold in memory
        │   (May need to process in batches if memory is limited)
        │
Step 5: 📊 TRANSFORM each block
        │   For each of 200,000 blocks:
        │     Old: [150 accounts × 17 periods] = 2,550 cells
        │     New: [160 accounts × 17 periods] = 2,720 cells
        │     
        │     Insert 10 new cell slots (170 cells × 8 bytes = 1,360 bytes)
        │     New cells initialized with #Missing
        │     Existing data preserved in correct positions
        │     
        │     ┌─────────────────────────────────────────────────┐
        │     │ Old block:                                       │
        │     │ [Rev,Jan][Rev,Feb]...[COGS,Jan]...[Acct150,Dec] │
        │     │                                                  │
        │     │ New block:                                       │
        │     │ [Rev,Jan][Rev,Feb]...[COGS,Jan]...[Acct150,Dec] │
        │     │ [Acct151,Jan]...[Acct160,Dec]  ← NEW cells (#M) │
        │     └─────────────────────────────────────────────────┘
        │
Step 6: 📊 Write NEW .PAG files (temporary)
        │   Compress each transformed block
        │   Write sequentially to new .PAG files
        │   200,000 blocks × ~2,200 bytes (avg compressed) = ~440 MB
        │
Step 7: 📊 Write NEW .IND files (temporary)
        │   Rebuild B-tree index with new block locations
        │   Same number of entries, but all offsets changed
        │
Step 8: 📊 SWAP files
        │   Rename old .PAG → .PAG.keep (backup)
        │   Rename new .PAG → .PAG (primary)
        │   Same for .IND
        │   
Step 9: 📊 UNLOCK DATABASE
        │   Database back online
        │   Users can reconnect
        │
Step 10: 📊 Log completion
         │   "Restructure completed in 12 minutes 34 seconds"
         │   "200,000 blocks processed"
         │   "Block size changed from 20,400 to 21,760 bytes"

⏱️ TOTAL DOWNTIME: 12 minutes 34 seconds
💾 DISK SPACE NEEDED: ~880 MB temporarily (old + new files)
```

---

## 10.5 Walkthrough 5: Smart View Retrieve

```
Step 1: 👤 User opens Excel with Smart View
        │   Connects to Planning datasource
        │   Selects Ad Hoc analysis
        │
Step 2: 👤 Places members on sheet:
        │   Rows: All children of "Americas" (US_East, US_West, Canada)
        │   Columns: Revenue, COGS for Jan, Feb, Mar
        │   POV: FY2024, Actual, Working, All Products
        │
Step 3: 👤 Clicks "Refresh" (⟳)
        │
Step 4: Smart View sends MDX-like query to 📊 Essbase:
        │   SELECT {Revenue.Jan, Revenue.Feb, Revenue.Mar,
        │           COGS.Jan, COGS.Feb, COGS.Mar}
        │   ON COLUMNS
        │   FROM FinPlan
        │   WHERE (FY2024, Actual, Working, All_Products)
        │   WITH {US_East, US_West, Canada} ON ROWS
        │
Step 5: 📊 Essbase determines blocks needed:
        │   Block 1: (US_East, All_Products, FY24, Actual, Working)
        │   Block 2: (US_West, All_Products, FY24, Actual, Working)
        │   Block 3: (Canada, All_Products, FY24, Actual, Working)
        │   
        │   NOTE: "All_Products" is an upper-level member
        │   These blocks only exist if aggregation has been run!
        │   If not → values may be #Missing (need to run calc first)
        │
Step 6: 📊 For each block:
        │   Index lookup → Page file read → Decompress → Extract cells
        │   3 blocks × 6 cells each = 18 values
        │
Step 7: 📊 Return values to Smart View
        │
Step 8: Smart View populates Excel cells:
        │   ┌──────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
        │   │          │ Rev/Jan  │ Rev/Feb  │ Rev/Mar  │COGS/Jan  │COGS/Feb  │...
        │   ├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
        │   │ US_East  │   160    │   150    │   130    │    50    │    60    │
        │   │ US_West  │   200    │   180    │   210    │   100    │    90    │
        │   │ Canada   │    80    │    75    │    90    │    40    │    35    │
        │   └──────────┴──────────┴──────────┴──────────┴──────────┴──────────┘
```

---

## Summary

> **Every user interaction with EPM — opening a form, saving data, running a calc, loading data, restructuring — involves a precise choreography between the Planning server (relational DB for metadata), Essbase server (blocks for data), and the file system (.PAG and .IND for persistence). Understanding these end-to-end flows is essential for troubleshooting performance issues, designing efficient applications, and knowing where to look when things go wrong.**

---

**← Previous:** [09 — EPM Forms, Rules, and Data Storage](./09_EPM_Forms_Rules_Data_Storage.md)  
**Next →** [11 — Kernel and Memory Architecture](./11_Kernel_and_Memory_Architecture.md)

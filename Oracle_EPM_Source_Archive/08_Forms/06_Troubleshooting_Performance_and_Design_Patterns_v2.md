# 06 — Form Properties: Performance Tuning & Interview Bible

---

## 6.1 The 5 Deadly Form Performance Killers

If an Oracle EPM Planning data entry form takes **more than 2 seconds to load**, it is almost always suffering from one of the following architectural defects:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   THE 5 FORM PERFORMANCE KILLERS                       │
├──────────────────────────────────┬─────────────────────────────────────┤
│ 1. Unchecked "Suppress missing   │ Essbase reads entire .PAG space     │
│    blocks"                       │ instead of scanning the .IND B-tree.│
├──────────────────────────────────┼─────────────────────────────────────┤
│ 2. Unchecked "Use Database       │ Transmits 50,000 empty cells over   │
│    Suppression"                  │ network for Java to filter in RAM.  │
├──────────────────────────────────┼─────────────────────────────────────┤
│ 3. Unchecked "Validate only for  │ Validation processor loops through  │
│    pages with existing blocks"   │ hundreds of non-existent pages.     │
├──────────────────────────────────┼─────────────────────────────────────┤
│ 4. Heavy Synchronous Smart Push  │ User waits for cross-cube sync      │
│    on Save                       │ instead of running in background.   │
├──────────────────────────────────┼─────────────────────────────────────┤
│ 5. Dynamic Calc Formulas on both │ Solves double dynamic intersections │
│    Rows AND Columns              │ repeatedly in RAM on every cell.    │
└──────────────────────────────────┴─────────────────────────────────────┘
```

---

## 6.2 Sub-Second Form Performance Tuning Checklist

To optimize any slow form to sub-second load times:
1. **Enable Database Suppression**:
   * Check **`Suppress missing blocks`**.
   * Check **`Suppress missing data - Rows`**.
   * Check **`Use Database Suppression`**.
2. **Optimize Validation Rules**:
   * Check **`Validate only for pages with existing blocks`**.
3. **Tune Smart Push**:
   * Check **`Run Smart Push In Background`** so users receive instant save confirmation.
4. **Scope Business Rules**:
   * Check **`Use Members on Form`** so save rules calculate only the current department rather than executing `CALC ALL`.
5. **Clean Layout**:
   * Move large sparse dimensions (Entity, Department, Project) to the **Page** or **POV** axis, keeping Rows and Columns focused on Dense dimensions (Account, Period).

---

## 6.3 Production Troubleshooting Matrix

| Symptom / Defect | Root Cause | Diagnostic Step | Resolution Step |
| :--- | :--- | :--- | :--- |
| **Form takes 30 seconds to open** | Suppression is executing in Java memory; empty blocks are not pruned via index. | Open Form Designer $\rightarrow$ Grid Properties. | Check **`Suppress missing blocks`** and **`Use Database Suppression`**. |
| **All cells display grayed-out / read-only** | Form is marked read-only, Version is Standard Target, or member is Dynamic Calc. | Check Display Properties (`Make form read-only`) and Version Type. | Uncheck `Make form read-only`. Ensure Version is `Bottom Up` and accounts are `Store`. |
| **Form displays "No data to display"** | All cells are `#MISSING` and suppression is enabled, or user has no access. | Check user security on Entity/Account. Uncheck suppression to test. | Verify user read/write access. Ensure historical data exists for POV. |
| **Saving takes 45 seconds** | Smart Push or Business Rule is running synchronously across the full database. | Inspect Business Rules and Smart Push tabs on form. | Enable **`Run Smart Push In Background`**. Add `FIX` statement to business rule. |
| **Excel users cannot build PivotTables from form** | Parent member labels are merged visually, leaving blank rows in Excel. | Check Smart View Options on form. | Check **`Repeat member labels`**. |

---

## 6.4 Golden Do's and Don'ts of Form Design

### ✅ The DO's:
1. **DO always check `Suppress missing blocks` and `Use Database Suppression`** on every planning form.
2. **DO enable `Repeat member labels`** so finance teams can analyze data in Excel via PivotTables and VLOOKUP.
3. **DO run Smart Push in the background** to ensure sub-second save times for end users.
4. **DO check `Validate only for pages with existing blocks`** to prevent validation rules from scanning empty space.
5. **DO use `Hide Prompt` with `Use Members on Form`** for automated, one-click save calculations.

### ❌ The DON'Ts:
1. **DON'T put two large sparse dimensions on rows** (e.g., Entity $\times$ Product) without database suppression; it can freeze the web server.
2. **DON'T execute full database calculations (`CALC ALL`) on form save**; scope calculations strictly to the form's active Page and POV.
3. **DON'T use `Dynamic Calc and Store` accounts on forms**; they cause severe page file fragmentation.
4. **DON'T create forms with more than 50 columns**; use user variables to restrict the visible time horizon to 12–24 rolling months.

---

## 6.5 Top 10 Consultant Interview Questions & Answers

### Q1: What is the physical difference between `Suppress missing data` and `Suppress missing blocks`—
> **Answer**: `Suppress missing data` retrieves all rows into application memory and filters out rows where all cells equal `#MISSING`. `Suppress missing blocks` queries the **Essbase Index (`.IND`) file B-tree** *before* retrieving data; if no physical block exists for that sparse combination, Essbase bypasses the row entirely, resulting in up to 50x faster query execution.

### Q2: What does `Use Database Suppression` do behind the scenes—
> **Answer**: By default, suppression filtering occurs in the Java web application server tier. Enabling `Use Database Suppression` pushes the suppression algorithm directly into the native **Essbase C++ engine (`ESSSVR`)**, filtering empty records in RAM before transmitting them across the network. This eliminates up to 98% of network payload between Essbase and Planning.

### Q3: Why is `Validate only for pages with existing blocks` critical for form performance—
> **Answer**: If a form has 500 departments on the Page axis but only 50 have data, unchecking this option forces Planning to evaluate validation rules against all 500 pages, wasting CPU on empty space. Checking it instructs Planning to consult the `.IND` index and execute validation strictly on the 50 pages with physical `.PAG` blocks.

### Q4: What is the difference between `Run Before Save` and `Run After Save` business rules—
> **Answer**: `Run Before Save` executes before modified cells are committed to Essbase; if an error or validation failure occurs, the save is rolled back. `Run After Save` executes immediately after data is safely written to `.PAG` disk blocks, making it ideal for aggregations, driver allocations, and cross-cube sync.

### Q5: What are Flex Forms in Smart View—
> **Answer**: Flex Forms allow Excel users to dynamically insert new rows, delete rows, sort, filter, and rearrange dimensional hierarchies in Smart View without breaking form definitions. When data is submitted, Planning validates the modified row structure and writes back to the correct Essbase blocks.

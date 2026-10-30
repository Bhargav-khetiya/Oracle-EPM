# 📐 Dimension Management Post-Creation — Master Guide
## Architecture, Custom Dimension Creation, Member Properties & Outline Governance

> **Navigation:** `Home → Application → Overview → Dimensions`  
> **Role Requirement:** Service Administrator or user with `Application - Administer` granular role  
> **Core Concept:** Dimensions define the multidimensional coordinate system of your Essbase cubes. Proper dimension governance ensures optimal calculation speed, report rendering performance, and data model flexibility.

---

## 🧭 Entry Point: The Dimensions Workspace

Navigating to **Application → Overview → Dimensions** provides the centralized interface for managing all dimensions across all application cubes:

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Dimensions: PlanCorp                                                               [ Actions ▼ ]  [ Save ]  [ Help ❓ ] │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Cube: [ All Cubes                  ▼ ]                                                                                 │
│                                                                                                                        │
│ ┌──────────────────────┬──────────────────────┬──────────────┬──────────────┬───────────────┬────────────────────────┐ │
│ │ Dimension            │ Type                 │ Density      │ Data Storage │ Total Members │ Cube Assignments       │ │
│ ├──────────────────────┼──────────────────────┼──────────────┼──────────────┼───────────────┼────────────────────────┤ │
│ │ Period               │ Base (Standard)      │ Dense        │ Stored       │ 18            │ Plan1, OEP_FS, OEP_REP │ │
│ │ Account              │ Base (Standard)      │ Dense        │ Stored       │ 1,240         │ Plan1, OEP_FS, OEP_REP │ │
│ │ Year                 │ Base (Standard)      │ Sparse       │ Stored       │ 15            │ Plan1, OEP_FS, OEP_REP │ │
│ │ Scenario             │ Base (Standard)      │ Sparse       │ Stored       │ 8             │ Plan1, OEP_FS, OEP_REP │ │
│ │ Version              │ Base (Standard)      │ Sparse       │ Stored       │ 12            │ Plan1, OEP_FS, OEP_REP │ │
│ │ Entity               │ Base (Standard)      │ Sparse       │ Stored       │ 450           │ Plan1, OEP_FS, OEP_REP │ │
│ │ Currency             │ Currency (Standard)  │ Sparse       │ Dynamic Calc │ 35            │ Plan1, OEP_FS, OEP_REP │ │
│ │ Department           │ Custom (Generic)     │ Sparse       │ Stored       │ 180           │ Plan1, OEP_FS          │ │
│ │ Product              │ Custom (Generic)     │ Sparse       │ Stored       │ 3,200         │ Plan1, OEP_FS, OEP_REP │ │
│ │ Channel              │ Custom (Generic)     │ Sparse       │ Stored       │ 14            │ Plan1, OEP_REP         │ │
│ └──────────────────────┴──────────────────────┴──────────────┴──────────────┴───────────────┴────────────────────────┘ │
│                                                                                                                        │
│ [ ➕ Add Custom Dimension ]   [ 📥 Import Metadata ]   [ 📤 Export Metadata ]   [ 🔀 Evaluation Order ]                │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## ➕ Creating a New Custom Dimension Post-Creation

When business requirements demand tracking a new analytical facet (e.g., `Market`, `Project`, `Channel`):

1. Click **[ ➕ Add Custom Dimension ]** in the Dimensions toolbar.
2. The **Create Dimension** dialog opens:

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Create Dimension                                                      ✖ │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│ Dimension Name: [ Channel                                             ] │
│ Description:    [ Sales Distribution Channels                         ] │
│ Dimension Type: [ Custom (Generic)                                  ▼ ] │
│                                                                         │
│ Cube Participation:                                                     │
│   ☑ Plan1 (Planning Cube)                                               │
│   ☑ OEP_FS (Financials Cube)                                            │
│   ☑ OEP_REP (Reporting Cube)                                            │
│                                                                         │
│ Density in BSO Cubes:                                                   │
│   🔘 Sparse (Recommended for custom dimensions)                         │
│   ⚪ Dense                                                               │
│                                                                         │
│ Hierarchy Creation:                                                     │
│   Root Member Name: [ Total_Channel                                   ] │
│   Default Member:   [ No_Channel                                      ] │
│                                                                         │
│                                           [ Save ]         [ Cancel ]   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Essential Creation Rules:
- **No Spaces or Illegal Characters:** Member and dimension names must not contain spaces, brackets `[]`, braces `{}`, commas, colons, or tabs.
- **No Reserved Words:** Avoid Oracle Essbase keywords (e.g., `Date`, `Year`, `Time`, `Level`, `Gen`, `Children`, `Descendants`, `Parents`, `CrossDim`).
- **Unique Across Application:** Member names must be strictly unique across the entire application unless Duplicate Member Names is enabled during initial cube architecture setup.

---

## 🧬 Dense vs Sparse: The Architectural Rulebook

In Essbase Block Storage (BSO) and Hybrid cubes, dimensions are categorized as either **Dense** or **Sparse**:

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                  DENSE vs SPARSE ARCHITECTURE COMPARISON                     │
├──────────────────────────────────────┬───────────────────────────────────────┤
│ DENSE DIMENSIONS                     │ SPARSE DIMENSIONS                     │
├──────────────────────────────────────┼───────────────────────────────────────┤
│ • Define the internal data cell grid │ • Determine the physical storage block│
│   inside each Essbase data block.    │   address (index).                    │
│ • Typically: **Period** and          │ • Typically: **Entity**, **Year**,    │
│   **Account**.                       │   **Scenario**, **Version**, Custom.  │
│ • Memory footprint is allocated for  │ • Blocks are created **only when data │
│   all member intersections in block. │   actually exists** (prevents bloat). │
│ • Best practice: Keep dense block    │ • In Hybrid BSO, sparse aggregations  │
│   size between **50 KB to 2 MB**.    │   calculate dynamically in RAM!       │
└──────────────────────────────────────┴───────────────────────────────────────┘
```

> [!WARNING]
> **Dense Dimension Threshold:**  
> Never mark custom dimensions (e.g., `Customer`, `Product`) as **Dense** unless they have very few members (less than 15) and data exists at nearly 100% of intersections. Making a high-cardinality dimension Dense causes catastrophic index explosion and block bloat!

---

## 🏷️ Dimension Member Properties Dictionary

When inspecting or editing individual members in the Dimension Editor (`Application → Overview → Dimensions → [Click Dimension Name]`):

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Edit Member: Net_Income                                                                       [ Save ] │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                        │
│ Member Name:      [ Net_Income                                        ]                                │
│ Default Alias:    [ Net Income After Taxes                            ]                                │
│ Parent:           [ Total_Income                                      ]                                │
│ Data Storage:     [ Dynamic Calc                                    ▼ ]                                │
│ Data Type:        [ Currency                                        ▼ ]                                │
│ Two-Pass Calc:    ☑ Yes                                                                                │
│ Consolidation (+):[ + (Addition)                                        ▼ ]                                │
│ Plan Type / Cube: ☑ Plan1   ☑ OEP_FS   ☑ OEP_REP                                                       │
│ Time Balance:     [ None                                            ▼ ]                                │
│ Skip:             [ None                                            ▼ ]                                │
│ Variance Report:  [ Non-Expense                                     ▼ ]                                │
│ Member Formula:   [ "Operating_Income" - "Income_Taxes";              ]                                │
│                                                                                                        │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Property Reference Table

| Property Name | Allowed Values | Behavioral Impact |
|:---|:---|:---|
| **Data Storage** | `Store`, `Dynamic Calc`, `Never Share`, `Shared`, `Label Only` | Determines if values are written to disk blocks (`Store`) or computed in memory on-the-fly (`Dynamic Calc`). |
| **Two-Pass Calculation** | `True` / `False` | Forces Essbase to calculate this member after all other dimension calculations complete. Essential for ratios, percentages, and profit margins. |
| **Consolidation Operator** | `+`, `-`, `*`, `/`, `%`, `~` (Ignore), `^` (Never) | Defines how the member rolls up into its parent. `~` ignores the child during parent summation. |
| **Data Type** | `Currency`, `Non-Currency`, `Percentage`, `Date`, `Text`, `Smart List` | Enforces display format and mathematical validation rules. |
| **Time Balance** | `None`, `First`, `Last`, `Average` | Governs how values aggregate over the Period dimension. Crucial for Balance Sheet and Headcount (e.g., Ending Inventory uses `Last`). |
| **Skip** | `None`, `Missing`, `Zeros`, `Missing and Zeros` | Controls how missing or zero values are skipped during Time Balance aggregation. |
| **Variance Reporting** | `Expense`, `Non-Expense` | Flips variance math for variance reporting (`Actual - Budget` vs `Budget - Actual`). |

---

## 🔀 Evaluation Order Governance

When multiple Dynamic Calc dimensions contain member formulas, their execution order can change calculation results (especially when Account formulas intersect with Period or Custom dimension formulas).

**Navigation:** `Application → Overview → Dimensions → Evaluation Order (🔀)`

```
┌─────────────────────────────────────────────────────────┐
│ Evaluation Order                                      ✖ │
├─────────────────────────────────────────────────────────┤
│ Select Cube: [ OEP_FS                               ▼ ] │
│                                                         │
│ Drag dimensions to arrange evaluation precedence:       │
│                                                         │
│   1. 🔢 Account         (Highest Precedence)            │
│   2. 📅 Period                                          │
│   3. 🏷️ Scenario                                        │
│   4. 👥 Entity                                          │
│   5. 📦 Product         (Lowest Precedence)             │
│                                                         │
│                                  [ Save ]    [ Cancel ] │
└─────────────────────────────────────────────────────────┘
```

- **Rule of Thumb:** Place dimensions with complex percentage and ratio formulas (typically `Account`) at the top of the evaluation order so their formulas override simple aggregations.

---

## 📋 Bulk Metadata Management: Import & Export

For enterprise applications containing tens of thousands of members, maintaining members via the web GUI is inefficient. Use bulk CSV imports:

### Exporting Dimension Metadata
1. Navigate to `Application → Overview → Dimensions`.
2. Click **[ 📤 Export Metadata ]**.
3. Select dimensions to export (e.g., `Entity`, `Account`).
4. Click **Export** to download CSV files with all column properties.

### Importing Dimension Metadata
1. Format your update file matching Oracle's dimension template:
   ```csv
   Dimension,Parent,Data Storage,Consolidation,Alias: Default
   Corporate_Sales,Total_Revenue,Store,+,Gross Commercial Sales
   Online_Sales,Total_Revenue,Store,+,Direct E-Commerce Sales
   ```
2. Click **[ 📥 Import Metadata ]**.
3. Select the target dimension and browse to your CSV file.
4. Click **Import**.
5. Check `Application → Jobs` to verify zero validation errors.
6. Execute a **Database Refresh** to push changes into Essbase.

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: What is the fundamental architectural difference between Dense and Sparse dimensions in Essbase BSO?
**Answer:**
- **Dense Dimensions:** Define the internal cell matrix inside a physical data block on disk (typically `Account` and `Period`).
- **Sparse Dimensions:** Define the multidimensional index pointers that identify where blocks live on disk (e.g. `Entity`, `CostCenter`, `Product`).
A block only exists on disk if at least one data point exists for that sparse intersection.

### Q2: What happens to historical data if a member's Data Storage is changed from `Store` to `Dynamic Calc`?
**Answer:** Historical data is **permanently destroyed**. When you change a member to Dynamic Calc and refresh the database, Essbase purges the physical data cells from disk. If you later revert the member back to Store, the data returns as `#MISSING`. Always export Level 0 data before changing storage properties!

### Q3: How do you perform bulk dimension updates without clicking through the web UI?
**Answer:** Export the dimension to CSV (`Application â†’ Overview â†’ Dimensions â†’ Export`), edit member properties in Excel or via script, and re-import via `Application â†’ Overview â†’ Dimensions â†’ Import` or EPM Automate:
```cmd
epmautomate importMetadata "Account.csv"
```
Follow with a Database Refresh to compile outline changes.

---

## 🔗 Navigation

| Direction | Document |
|:---|:---|
| **← Previous** | [02_Enable_Features_Post_Creation.md](./02_Progressive_Feature_Enablement.md) |
| **Next →** | [04_Database_Refresh.md](./04_Database_Refresh_Master_Operations.md) |
| **Master Index** | [00_MASTER_INDEX.md](../00_MASTER_INDEX.md) |

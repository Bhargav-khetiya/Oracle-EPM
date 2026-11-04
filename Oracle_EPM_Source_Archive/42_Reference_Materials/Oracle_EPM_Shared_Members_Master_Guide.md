# Shared Members — Oracle EPM Cloud / Essbase

## Overview

A **Shared Member** is one of the most fundamental concepts in Oracle Essbase and EPM Cloud outline design. It is a **pointer** to a "base" (original) member that allows the same member to appear under **multiple parents** without duplicating data. Shared members are the mechanism behind **alternate hierarchies** — different ways to slice, group, and roll up the same underlying data.

Think of it this way: a base member is the **original document**. A shared member is a **shortcut** to that document. No matter which shortcut you click, you always open the same file. Edit through the shortcut, and the original changes. Edit the original, and all shortcuts reflect it.

### Why Do Shared Members Exist—

Business reporting almost always requires viewing the same data from multiple angles:

| Business Need | Primary Hierarchy | Alternate Hierarchy (Shared Members) |
|---------------|-------------------|--------------------------------------|
| View products by category AND by brand | Products by Category | Products by Brand |
| View entities by geography AND by business unit | Entities by Region | Entities by Line of Business |
| View accounts by financial statement AND by cost center type | Accounts by P&L Line | Accounts by Cost Type |
| View employees by department AND by grade | Employees by Department | Employees by Grade Level |

Without shared members, you'd need to duplicate data for each hierarchy — leading to storage waste, inconsistencies, and maintenance nightmares.

### When to Use Shared Members

- When you need the **same member** to appear under **different parents**
- When building **alternate rollup hierarchies** for reporting
- When you need multiple "views" of the same data without duplication
- When different departments need different organizational views of the same underlying data
- When building management vs. statutory reporting hierarchies

---

## Category

**Outline Design / Dimension Management / Data Storage**

---

## ⚡ Deep Dive: How Shared Members Work Internally

### The Pointer Mechanism

```
┌──────────────────────────────────────────────────────────┐
│                   OUTLINE (Entity Dimension)              │
│                                                          │
│  Total Entity (Store Data)                               │
│  ├── By_Region                        ← PRIMARY          │
│  │   ├── North  (Store Data)   ◄══ BASE MEMBER          │
│  │   ├── South  (Store Data)   ◄══ BASE MEMBER          │
│  │   ├── East   (Store Data)   ◄══ BASE MEMBER          │
│  │   └── West   (Store Data)   ◄══ BASE MEMBER          │
│  │                                                       │
│  └── By_BusinessUnit                  ← ALTERNATE        │
│      ├── Retail                                          │
│      │   ├── North  (Shared)   ══► points to North base │
│      │   └── East   (Shared)   ══► points to East base  │
│      └── Wholesale                                       │
│          ├── South  (Shared)   ══► points to South base │
│          └── West   (Shared)   ══► points to West base  │
└──────────────────────────────────────────────────────────┘
```

### What Happens at the Data Level

```
DATA BLOCKS (Sparse dimension = Entity):

Block for "North" ─── stores actual data ─── value = 500
                        ▲           ▲
                        │           │
                   read/write   read/write
                        │           │
          By_Region → North    Retail → North (Shared)
          
Both paths access the SAME physical data block.
There is only ONE copy of the data.
```

**Key facts:**
1. A shared member **does NOT create its own data block** — it points to the base member's block
2. Data entered through a shared member is **stored in the base member's block**
3. Any change to the base member's data is **instantly visible** through all shared members
4. The database size stays the same whether you have 0 or 100 shared members pointing to a base

---

## 🔗 Deep Dive: Base Member vs. Shared Member — What's Different

### Property Comparison

| Property | Base Member | Shared Member |
|----------|-------------|---------------|
| **Data Storage** | `Store Data` (or `Dynamic Calc`, `Never Share`) | `Shared` (always) |
| **Stores data—** | ✅ Yes — owns its data block | ❌ No — points to base member's block |
| **Member name** | The original name | **Must be identical** to the base member name |
| **Can have children—** | ✅ Yes | ❌ No — shared members are always leaf nodes |
| **Can have a formula—** | ✅ Yes | ❌ No — formulas only on base members |
| **Can have UDAs—** | ✅ Yes | ❌ No — UDAs only on base members |
| **Can have attributes—** | ✅ Yes | ❌ No — attributes only on base members |
| **Can have aliases—** | ✅ Yes (sets alias for all shared) | Inherits alias from base member |
| **Consolidation operator** | Has its own (`+`, `-`, `~`, etc.) | Has its **own** (can differ from base!) |
| **Outline position** | Must appear **BEFORE** any shared members | Must appear **AFTER** the base member |
| **Can be renamed—** | ✅ Yes — all shared members auto-update | N/A — name always mirrors base |
| **Can be deleted—** | ⚠️ Deleting base removes ALL shared instances | ✅ Can be deleted independently |

### What Shared Members CAN Have (Different from Base)

Despite being "pointers," shared members have a few independent properties:

| Property | Can Differ from Base— | Why— |
|----------|-----------------------|------|
| **Parent** | ✅ Yes — that's the whole point | Different parent = different hierarchy |
| **Consolidation operator** | ✅ Yes | May aggregate differently in the alternate hierarchy |
| **Sibling order** | ✅ Yes | Can be positioned differently under the alternate parent |

### What Shared Members CANNOT Have

| Property | Allowed— | Why Not— |
|----------|----------|----------|
| Own formula | ❌ No | Would create data conflicts — which formula runs— |
| Own children | ❌ No | Would create an independent sub-hierarchy under a pointer |
| Own UDAs | ❌ No | UDAs belong to the base member |
| Own attributes | ❌ No | Attributes belong to the base member |
| Own aliases | ❌ No | Aliases are inherited from the base |
| Data storage other than "Shared" | ❌ No | By definition, data storage = Shared |

---

## 🏗️ Deep Dive: Creating Shared Members

### Method 1: Dimension Editor (EPM Cloud UI)

**Navigation**: Application → Overview → Dimensions → Select Dimension → Edit

**Steps**:
1. Navigate to the **parent** where you want the shared member to appear (the alternate hierarchy parent)
2. Click **Add Child** (or Add Sibling)
3. Enter the **exact same name** as the existing base member
4. Set **Data Storage** to `Shared`
5. Save
6. **Refresh Database** to apply the outline change

> ⚠️ **Important**: You MUST enter the exact same member name as the base. If the name doesn't match an existing base member, it will be created as a new independent member, not a shared member.

### Method 2: Flat File Metadata Load

**File format** (CSV):

```csv
Member,Parent,Data Storage,Alias: Default
North,By_Region,Store Data,North Region
South,By_Region,Store Data,South Region
East,By_Region,Store Data,East Region
West,By_Region,Store Data,West Region
North,Retail,Shared,
South,Wholesale,Shared,
East,Retail,Shared,
West,Wholesale,Shared,
```

**Key rules for the load file**:
- Base member rows **must come before** shared member rows (or base members must already exist)
- The **Data Storage** column must be explicitly set to `Shared`
- The **Parent** column determines where the shared member is placed
- Member name must be **identical** to the base member

### Method 3: Data Management / Integration (FDMEE/DM)

For automated metadata management:
1. Create an **Import Format** mapping file columns to dimension properties
2. Create a **Data Load Rule** pointing to your metadata file
3. Execute the load
4. Refresh Database

---

## 🔍 Deep Dive: How to Identify Shared Members (Finding Base vs. Shared)

This is one of the most common questions: "I'm looking at a member — how do I know if it's a base or shared—

### Method 1: Dimension Editor

In the EPM Cloud Dimension Editor:
- Navigate to the member in question
- Check the **Data Storage** property:
  - `Store Data` / `Dynamic Calc` / `Never Share` → **Base member**
  - `Shared` → **Shared member** (pointer to base)

### Method 2: Look at the Parent

The same member name appearing under **different parents** tells you:
- The **first occurrence** (in outline order) is the **base member**
- All subsequent occurrences are **shared members**

```
Entity Dimension:
├── By_Region
│   └── North  ← appears first = BASE MEMBER
└── By_BusinessUnit
    └── Retail
        └── North  ← appears second = SHARED MEMBER
```

### Method 3: Smart View / Ad Hoc Grid

1. Open Smart View
2. Create an ad-hoc grid on the dimension
3. Zoom in on the hierarchy
4. Observe which parent the member appears under
5. The member under the **primary hierarchy** is typically the base

### Method 4: Outline XML / Flat File Export

Export the dimension metadata to a flat file:
- Members with `Data Storage = Store Data` → Base
- Members with `Data Storage = Shared` → Shared

### Method 5: Essbase Outline Viewer (On-Premise)

In EAS (Essbase Administration Services):
- Right-click the member → Properties
- **Data Storage** property shows `Shared` for shared members
- Shared members also display with a **different icon** (typically a linked/arrow icon)

---

## 🎯 Deep Dive: How Shared Members Affect Calculations, Forms, and Reports

### In Calculations (Business Rules)

```essbase
/* When you calculate a parent with shared children... */
FIX("FY25", "Actual")
    AGG("Entity");
ENDFIX
```

**What happens during aggregation—**

```
By_Region:                          By_BusinessUnit:
├── North = 500 (base)              ├── Retail
├── South = 300 (base)              │   ├── North = 500 (shared → same 500)
├── East  = 400 (base)              │   └── East  = 400 (shared → same 400)
└── West  = 200 (base)              │   Retail TOTAL = 900 ✅
By_Region TOTAL = 1400 ✅           └── Wholesale
                                        ├── South = 300 (shared → same 300)
                                        └── West  = 200 (shared → same 200)
                                        Wholesale TOTAL = 500 ✅
```

- `By_Region` aggregates its base members: 500 + 300 + 400 + 200 = **1400**
- `Retail` aggregates its shared members: 500 + 400 = **900** (reads from same data blocks as North and East base)
- `Wholesale` aggregates its shared members: 300 + 200 = **500**
- `By_BusinessUnit` = 900 + 500 = **1400** ✅ — Same total, different breakdowns!

> **Key insight**: Aggregation works the same for shared members as for base members. The parent reads the value from the underlying data block (whether accessed via base or shared), and rolls up normally.

### In FIX Statements

```essbase
/* FIXing on a shared member... */
FIX("FY25", "Actual")
    FIX("North")
        "Revenue" = 500;
    ENDFIX
ENDFIX
```

- If `"North"` resolves to the **base member**, the value is written to North's data block
- If the calc engine encounters `"North"` under a shared context, it still writes to the **same data block** — there's only one block for "North"

> **Important**: In FIX, Essbase typically resolves to the **base member** unless you specifically navigate through the alternate hierarchy. The behavior depends on dense/sparse configuration and which member appears first in the outline.

### In Data Forms (Web Forms)

| Scenario | Behavior |
|----------|----------|
| Editing a cell at a shared member | Value is written to the **base member's data block** — same as editing the base directly |
| Drill-down on a shared member | By default, drill-down may be **disabled** on shared members. Must be explicitly enabled. |
| Enabling drill on shared members | Form Designer → Dimension Properties → check **"Drill on shared members"** |
| Smart View ad hoc drill | Admin must enable: **"Allow drill down on shared members in ad hoc"** in application settings |

### In Reports / Dashboards

- Shared members display the **same data** as their base members
- Parent of shared members shows the **alternate rollup** (the whole point of the alternate hierarchy)
- Some reporting tools may show the hierarchy path, revealing whether you're viewing through the primary or alternate hierarchy

---

## 📊 Deep Dive: Data Storage Properties — The Complete Picture

Shared members are one of several data storage properties. Understanding them all helps clarify where shared members fit:

### All Data Storage Types

| Storage Type | Stores Data— | Creates Block— | Use Case |
|-------------|-------------|----------------|----------|
| **Store Data** (default) | ✅ Yes | ✅ Yes (for sparse dims) | Standard data storage — level-0 input members, stored parents |
| **Dynamic Calc** | ❌ No (calculated on-the-fly) | ❌ No | Parents that should always show current aggregation. Saves storage but costs CPU. |
| **Dynamic Calc and Store** | ✅ First calc, then stores | ✅ Yes (after first calc) | Rarely used. Calculates once, then stores the result. |
| **Shared** | ❌ No (pointer) | ❌ No | Alternate hierarchies — points to base member's data |
| **Never Share** | ✅ Yes (forced independent) | ✅ Yes | Prevents implicit sharing — forces data to be stored independently |
| **Label Only** | ❌ No | ❌ No | Navigation/grouping only — no data, no aggregation |

### Implicit Sharing vs. Explicit Sharing

This is one of the most confusing concepts. There are **two types** of sharing in Essbase:

#### Explicit Sharing (You Create It)

This is what we've been discussing — you manually create a shared member in the outline to place a member under an alternate parent.

```
Entity:
├── By_Region
│   └── North (Store Data)   ← BASE
└── By_BU
    └── Retail
        └── North (Shared)   ← You created this explicitly
```

#### Implicit (Implied) Sharing (Essbase Does It Automatically)

Essbase automatically "shares" data between a parent and child in specific situations to save storage. **You don't create these** — Essbase does it behind the scenes:

| Condition | What Happens | Example |
|-----------|-------------|---------|
| **Parent has exactly ONE child** | Parent and child share the same data cell | `Total_Dept` → `Only_Dept` (single child). Both show same value. |
| **Parent has multiple children, only ONE consolidates** | Parent shares data with the only consolidating child | `Total` has `Active (+)` and `Inactive (~)`. Parent shares with `Active`. |
| **Parent is Label Only** | Parent inherits the value of its first child | `Group_Label` (Label Only) → `First_Child` shows same value. |

**Why does implicit sharing matter—**

Normally you don't notice it. But it can cause unexpected behavior:
- Entering data in a parent form cell might actually write to the child (because they share data)
- You expect the parent to be independent, but it mirrors the child

**Fix**: Set the member to **Never Share** to prevent implicit sharing:

```
Entity:
└── Total_Dept (Never Share)   ← forces independent storage
    └── Only_Dept (Store Data)  ← has its own value now
```

---

## 🔥 Complete Scenario: Building an Alternate Entity Hierarchy

### Business Requirement

The organization needs to view financial data two ways:
1. **By Geography** (primary): Americas → US, Canada, Mexico, Brazil
2. **By Business Line** (alternate): Enterprise, SMB, Consumer — each with a mix of geographic entities

### Step 1: Design the Outline

```
Entity Dimension:
├── Total_Geography (Store Data)              ← PRIMARY HIERARCHY
│   ├── Americas (Store Data)
│   │   ├── US        (Store Data)   ◄── BASE
│   │   ├── Canada    (Store Data)   ◄── BASE
│   │   ├── Mexico    (Store Data)   ◄── BASE
│   │   └── Brazil    (Store Data)   ◄── BASE
│   ├── EMEA (Store Data)
│   │   ├── UK        (Store Data)   ◄── BASE
│   │   ├── Germany   (Store Data)   ◄── BASE
│   │   └── France    (Store Data)   ◄── BASE
│   └── APAC (Store Data)
│       ├── Japan     (Store Data)   ◄── BASE
│       ├── Australia (Store Data)   ◄── BASE
│       └── India     (Store Data)   ◄── BASE
│
└── Total_BusinessLine (Store Data)           ← ALTERNATE HIERARCHY
    ├── Enterprise (Store Data)
    │   ├── US        (Shared)    ══► points to US base
    │   ├── UK        (Shared)    ══► points to UK base
    │   ├── Germany   (Shared)    ══► points to Germany base
    │   └── Japan     (Shared)    ══► points to Japan base
    ├── SMB (Store Data)
    │   ├── Canada    (Shared)    ══► points to Canada base
    │   ├── France    (Shared)    ══► points to France base
    │   ├── Australia (Shared)    ══► points to Australia base
    │   └── India     (Shared)    ══► points to India base
    └── Consumer (Store Data)
        ├── Mexico    (Shared)    ══► points to Mexico base
        └── Brazil    (Shared)    ══► points to Brazil base
```

### Step 2: Load File (CSV)

```csv
Member,Parent,Data Storage
Total_Geography,,Store Data
Americas,Total_Geography,Store Data
US,Americas,Store Data
Canada,Americas,Store Data
Mexico,Americas,Store Data
Brazil,Americas,Store Data
EMEA,Total_Geography,Store Data
UK,EMEA,Store Data
Germany,EMEA,Store Data
France,EMEA,Store Data
APAC,Total_Geography,Store Data
Japan,APAC,Store Data
Australia,APAC,Store Data
India,APAC,Store Data
Total_BusinessLine,,Store Data
Enterprise,Total_BusinessLine,Store Data
US,Enterprise,Shared
UK,Enterprise,Shared
Germany,Enterprise,Shared
Japan,Enterprise,Shared
SMB,Total_BusinessLine,Store Data
Canada,SMB,Shared
France,SMB,Shared
Australia,SMB,Shared
India,SMB,Shared
Consumer,Total_BusinessLine,Store Data
Mexico,Consumer,Shared
Brazil,Consumer,Shared
```

### Step 3: How Data Flows

Assume this data exists (all at base level):

| Entity | Revenue |
|--------|---------|
| US | 1000 |
| Canada | 400 |
| Mexico | 200 |
| Brazil | 300 |
| UK | 600 |
| Germany | 500 |
| France | 350 |
| Japan | 800 |
| Australia | 450 |
| India | 550 |

**After aggregation:**

```
By Geography:                          By Business Line:
Americas  = 1900                       Enterprise = 2900
  US      = 1000                         US       = 1000 (shared)
  Canada  = 400                          UK       = 600  (shared)
  Mexico  = 200                          Germany  = 500  (shared)
  Brazil  = 300                          Japan    = 800  (shared)
EMEA      = 1450                       SMB        = 1750
  UK      = 600                          Canada   = 400  (shared)
  Germany = 500                          France   = 350  (shared)
  France  = 350                          Australia= 450  (shared)
APAC      = 1800                         India    = 550  (shared)
  Japan   = 800                        Consumer   = 500
  Australia= 450                         Mexico   = 200  (shared)
  India   = 550                          Brazil   = 300  (shared)
                                       
Total_Geography = 5150                 Total_BusinessLine = 5150  ✅ Same total!
```

**Both hierarchies add up to the same total (5150)** because they're looking at the same underlying data — just grouped differently.

### Step 4: What Happens When a User Edits Data

A user opens a form showing the **Business Line** view and changes `US` revenue from 1000 to 1200:

```
Enterprise (form view):
  US = 1200  ← user changed this
```

**What actually happens—**
1. `US` under `Enterprise` is a **shared member** → it points to the base `US` under `Americas`
2. The value **1200 is written to the base member's data block**
3. Now `US` everywhere shows **1200** — under `Americas` AND under `Enterprise`
4. After aggregation: `Americas` = 2100, `Enterprise` = 3100, both totals = 5350

> The user edited through the alternate hierarchy, but the data was stored at the base. Both views instantly reflect the change.

---

## 🔧 Drill-Down Configuration for Shared Members

### Problem: Drill-Down Is Disabled by Default

By default, EPM Cloud **does not allow drill-down on shared members** in forms and ad-hoc grids. This prevents confusion but also limits reporting flexibility.

### Enabling Drill-Down in Forms

1. Open the form in **Form Designer** (edit mode)
2. Select the **dimension** on the row or column that contains shared members
3. Expand **Dimension Properties**
4. Check ☑️ **"Drill on shared members"**
5. Save the form

### Enabling Drill-Down in Smart View Ad Hoc

This is an **application-level** setting:
1. Navigate to **Application → Settings**
2. Find **"Allow drill down on shared members in ad hoc"**
3. Set to **Enabled**

### Drill Behavior Options

| Option | Behavior |
|--------|----------|
| **Drill on shared members (disabled)** | Zooming in on a shared member does nothing — it stays at that level |
| **Drill on shared members (enabled)** | Zooming in shows the shared member's context (its children in the alternate hierarchy, if any) |
| **Drill to All Levels in Base** | When drilling on a shared member, shows ALL descendants of the BASE member — effectively jumps to the primary hierarchy |

---

## ⚠️ Shared Members in Calculations — Key Behaviors

### @XREF and @XWRITE with Shared Members

When @XREF or @XWRITE references a shared member:
- It reads/writes to the **base member's data** — there's only one physical value
- The result is the same regardless of whether you reference the base or shared member name

### FIX and Shared Members

```essbase
/* FIXing on a shared member's parent in the alternate hierarchy */
FIX("FY25", "Actual", @DESCENDANTS("Enterprise"))
    "Revenue" = "Revenue" * 1.1;
ENDFIX
```

`@DESCENDANTS("Enterprise")` returns: `US, UK, Germany, Japan` (the shared members under Enterprise).

**What happens—**: Essbase resolves these to their **base member data blocks** and modifies them. This means:
- US's revenue under Americas is also changed (same block!)
- Any other shared reference to US also reflects the change

> ⚠️ **Gotcha**: If you calculate through the alternate hierarchy, you're modifying the SAME data that the primary hierarchy sees. There's no isolation — changes propagate everywhere instantly.

### DATACOPY and Shared Members

```essbase
DATACOPY "North" TO "South";
```

If `North` is a base member, this copies North's data to South's data block — straightforward.

If `North` is a shared member, DATACOPY reads from the base member's block that North points to. The result is the same — shared members are transparent in calculations.

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| **Creating a "shared" member with wrong name** | Member name doesn't exactly match the base → creates a NEW independent member, not a shared member | Ensure the name is **identical** (case-sensitive in Essbase) |
| **Placing shared before base in outline** | Base member must appear BEFORE any shared members in the outline order | Reorder: base first, shared after |
| **Adding children to a shared member** | Shared members cannot have children — will cause an error | Only add children to base members |
| **Adding formulas to a shared member** | Formulas are not allowed on shared members | Place formulas on the base member only |
| **Editing shared member and expecting isolation** | Data entered at a shared member goes to the base → visible everywhere | By design — shared members always point to the same data |
| **Forgetting to set Data Storage to "Shared"** in load file | Member gets created as a new independent "Store Data" member | Always explicitly set `Data Storage = Shared` in metadata loads |
| **Double-counting in calculations** | If your calc iterates both primary AND alternate hierarchy, the same data is processed twice | Use FIX on either primary OR alternate members, not both |
| **Deleting a base member** | All shared instances are also deleted | Delete shared members first, then the base (or intentionally delete all) |
| **Expecting different data per hierarchy** | Shared members always show base member's value — you can't have US=1000 in one hierarchy and US=1200 in another | Use separate members (not shared) if you need independent values per hierarchy |
| **Implicit sharing surprises** | Parent with one child auto-shares data — form entry at parent writes to child | Set parent to `Never Share` if you need independent storage |
| **Drill-down not working** | Drill on shared members is disabled by default | Enable in Form Designer → Dimension Properties |

---

## 🆚 Shared Members vs. Other Approaches

| Approach | Same Data— | Independent Values— | Use Case |
|----------|-----------|--------------------|---------| 
| **Shared Members** | ✅ Single copy of data | ❌ Always same value | Alternate hierarchies for reporting |
| **Duplicate Members (different names)** | ❌ Independent data | ✅ Each has own value | When hierarchies need different values |
| **Attribute Dimensions** | ✅ Reads from base | ❌ No independent data | Tagging members for analysis (no rollup) |
| **@XREF** | ✅ Reads from source | ❌ Read-only reference | Cross-cube data access |
| **UDAs + Member Formulas** | Mixed | Mixed | Conditional rollups |

---

## Performance Considerations

| Consideration | Impact |
|---------------|--------|
| **Shared members don't create blocks** | ✅ No storage overhead — alternate hierarchies are "free" in terms of block count |
| **Aggregation through alternate hierarchy** | Same performance as primary — reads the same blocks |
| **Large number of shared members** | Outline size increases (metadata), but data storage stays the same |
| **Outline ordering** | Base member must be before shared — affects outline load order |
| **Implicit sharing** | Can save storage but may cause unexpected form behavior |

---

## Quick Reference: Shared Member Rules

```
┌────────────────────────────────────────────────────────────┐
│              SHARED MEMBER RULES — QUICK REFERENCE          │
│                                                            │
│  ✅ MUST:                                                  │
│  • Name must be IDENTICAL to the base member               │
│  • Base member must exist BEFORE shared member             │
│  • Base and shared must be in the SAME dimension           │
│  • Data Storage must be set to "Shared"                    │
│                                                            │
│  ❌ CANNOT:                                                │
│  • Cannot have children                                    │
│  • Cannot have formulas                                    │
│  • Cannot have UDAs                                        │
│  • Cannot have attributes                                  │
│  • Cannot have aliases (inherits from base)                │
│  • Cannot have Data Storage other than "Shared"            │
│                                                            │
│  ✅ CAN:                                                   │
│  • Have a different parent (the whole point!)               │
│  • Have a different consolidation operator                  │
│  • Be deleted independently (without affecting base)       │
│  • Be referenced in FIX, @XREF, @XWRITE, etc.             │
│  • Appear in forms, reports, Smart View                    │
└────────────────────────────────────────────────────────────┘
```

---

## Related Concepts

| Concept | Relationship |
|---------|-------------|
| **Alternate Hierarchies** | Built using shared members — the primary use case |
| **Data Storage Properties** | Shared is one of several storage types (Store Data, Dynamic Calc, Never Share, Label Only) |
| **Implicit Sharing** | Automatic sharing by Essbase — different from explicit shared members |
| **Never Share** | Prevents implicit sharing — forces independent data storage |
| **Attribute Dimensions** | Alternative to shared members for analysis — uses tags instead of hierarchy |
| **Dense/Sparse** | Affects block creation — shared members don't create additional blocks |

---

## Official Oracle Reference

- [Understanding Shared Members (Essbase)](https://docs.oracle.com/en/database/other-databases/essbase/21/essoa/shared-members.html)
- [Setting Data Storage Properties](https://docs.oracle.com/en/database/other-databases/essbase/21/essoa/setting-data-storage-properties.html)
- [Implied Sharing](https://docs.oracle.com/en/database/other-databases/essbase/21/essoa/implied-sharing.html)
- [Designing Alternate Hierarchies](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/managing_dimensions.html)

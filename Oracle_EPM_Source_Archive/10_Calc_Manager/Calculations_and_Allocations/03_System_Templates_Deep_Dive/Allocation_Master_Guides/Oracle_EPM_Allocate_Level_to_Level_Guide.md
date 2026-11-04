# Oracle EPM: Complete Guide to the Allocate - Level to Level Template (EPBCS / PBCS)

---

## 1. What Is the Allocate - Level to Level Template—

The **Allocate - Level to Level** template is a specialized system template in Oracle EPM Cloud's **Calculation Manager** designed for a specific use case: **allocating data from one hierarchy level to another within the same dimension**. Unlike the standard Allocation template (which allocates from a source member to all level 0 descendants of a parent), this template lets you define a **start level** and an **end level**, distributing data from members at the start level down to members at the end level.

### How It Differs from the Standard Allocation Template

| Feature | Standard Allocation Template | Allocate - Level to Level Template |
|---|---|---|
| **Allocation Target** | Always level 0 (leaf) members | Any level you specify (level 3 → level 4, etc.) |
| **Start/End Levels** | Not configurable — always goes to bottom | Explicitly defined — you choose both |
| **Use Case** | Spread a single source to all leaves | Spread data from parents at one level to their children at the next level |
| **Hierarchy Awareness** | Basic — just finds level 0 under a parent | Advanced — respects level/generation numbers |
| **Script Optimization** | Not available | Built-in optimization for single-member dimensions |
| **Offset** | Optional, with opposite sign and clear options | Optional, simpler — define dimensionality and member |

### When to Use This Template

| Situation | Use Level to Level— |
|---|---|
| Data is loaded at parent level and needs to be pushed to children (one level down) | ✅ Yes |
| Multi-level cascade: allocate from level 3 parents to level 0 in one pass | ✅ Yes |
| Data exists at level 0 and needs to go to other level 0 members (same level) | ❌ No — use standard Allocation template |
| Single parent → level 0 spread with percentage of source | ❌ No — use standard Allocation template |
| Complex conditional allocation logic | ❌ No — use `@ALLOCATE` in a script |

---

## 2. Understanding Levels and Generations in the Context of This Template

Before using this template, you **must** understand how Oracle EPM defines levels and generations:

### Levels (Bottom-Up Numbering)

```
              T_TP  ─────────────────── Level 3 (Generation 1)
             /    \
          T_TP1   T_TP2  ──────────── Level 2 (Generation 2)
         /    \      |
      P_100  P_110  P_200  ────────── Level 1 (Generation 3)
      /   \
   P_101  P_102  ─────────────────── Level 0 (Generation 4)
```

| Concept | Direction | Level 0 Is | Higher Numbers Are |
|---|---|---|---|
| **Level** | Bottom-up | The leaf (no children) | Closer to the root |
| **Generation** | Top-down | The farthest from root | Closer to the leaves |

### Key Rule for This Template

When the wizard asks for **Start Level** and **End Level**:
- **Start Level** = The level where the SOURCE data currently sits (higher number = closer to root).
- **End Level** = The level where you want data to be allocated TO (lower number = closer to leaves).
- **Start Level must be > End Level** (you're moving data DOWN the hierarchy).

### Example

```
Hierarchy:
  T_TP         (Level 3)
    ├── T_TP1  (Level 2)  ← Start Level = 2
    │     ├── P_100  (Level 1)
    │     │     ├── P_101 (Level 0)  ← End Level = 0
    │     │     └── P_102 (Level 0)  ← End Level = 0
    │     └── P_110  (Level 1)
    ├── T_TP2  (Level 2)  ← Start Level = 2
    │     ├── P_200  (Level 1)
    │     └── P_210  (Level 1)
    └── T_TP3  (Level 2)  ← Start Level = 2
          ├── P_291  (Level 1)
          └── P_292  (Level 1)

Start Level: 2 (T_TP1, T_TP2, T_TP3 — the parents with data)
End Level:   0 (P_101, P_102, etc. — the leaf members)

What happens: Data at T_TP1, T_TP2, T_TP3 is allocated down to their
              respective level 0 descendants.
```

---

## 3. How to Add the Template to a Rule

### Method A: Graphical Rule or Template

1. Open or create a Business Rule or Template in **Calculation Manager → Rule Designer**.
2. In the **New Objects** palette, locate **Allocate - Level to Level**.
3. **Drag** and **drop** it into the flowchart between **Begin** and **End**.
4. The **Allocate - Level to Level Wizard** opens.

### Method B: Script Rule or Template

1. Open or create a Business Rule or Template in script mode.
2. Expand **System Templates** in the left panel.
3. Select **Allocate - Level to Level** and **drop** it into the desired area.
4. The wizard opens.

---

## 4. The Allocate - Level to Level Wizard — Every Step in Detail

---

### Step 1: Point of View (POV)

**Purpose:** Define the dimensions and members that **do NOT vary** during the allocation.

#### What You See

A table listing all dimensions in your application:

| Dimension | Selection |
|---|---|
| Account | *(select member)* |
| Period | *(select member)* |
| HSP_View | *(select member)* |
| Years | *(select member)* |
| Scenario | *(select member)* |
| Version | *(select member)* |
| Currency | *(select member)* |
| Entity | *(select member)* |
| PlanElement | *(select member)* |
| Department | *(select member)* |
| Future | *(select member)* |
| Custom1 | *(select member)* |

#### How to Select Members

| Method | How | When to Use |
|---|---|---|
| **Use Predefined Selection** | Click Variable Selector → select a saved variable set | Reusable member sets |
| **Member Selector** | Click Member Selector → browse tree and pick | One-off specific picks |
| **Actions** | Select dimension → click Select → choose member, variable, or function | Runtime prompts, substitution variables, functions |

#### Rules

| Rule | Detail |
|---|---|
| Select one or more members | At least one dimension must have a member |
| **Ensure all members have the Store property** | Members must NOT be Dynamic Calc — they must be stored members |
| Dimensions left empty | Will be addressed in subsequent steps (Source, Target, etc.) |
| Functions are allowed | You CAN use `@CHILDREN`, `@RELATIVE`, etc. in POV |

#### ⚠️ Critical Warning: Store Property

The wizard explicitly states: **"Ensure all members you select have the Store property."** This means:
- ✅ **Stored members** (data is physically saved in Essbase) — allowed
- ❌ **Dynamic Calc members** (calculated on-the-fly) — NOT allowed
- ❌ **Label Only members** (no data storage) — NOT allowed

**Why:** The allocation writes data to intersections. If a member is Dynamic Calc, Essbase cannot store a value there — the write is silently ignored.

**How to Check:** In the dimension editor, look at the member's **Data Storage** property. It should say "Store" (not "Dynamic Calc" or "Never Share" or "Label Only").

#### Effect

Every allocated result includes these POV members. Example:
```
POV: Scenario=Budget, Version=Working, Years=FY2025, Period=Jan
→ All allocated values are written at Budget → Working → FY2025 → Jan
```

---

### Step 2: Source

**Purpose:** Define **where the data comes from** — the member(s) whose values will be distributed.

#### What You See

A table listing all dimensions not fully specified in POV, plus a percentage field:

| Field | Description |
|---|---|
| Dimension rows | One row per dimension — enter the source member |
| **Percentage to allocate** | Default: `100`. Enter the % of source value to allocate. |

#### Rules

| Rule | Detail |
|---|---|
| Enter one member per dimension | Every listed dimension needs a value |
| **Leave the allocation dimension EMPTY** | The dimension you'll use in Allocation Range (the one with the hierarchy) should be left blank here |
| Source members CAN be parent/aggregate | You can source from summary members |
| Functions are NOT allowed | Only explicit members or variables |
| Percentage = 100 means full amount | Enter 50 for half, 25 for a quarter, etc. |

#### ⚠️ Critical: Leave the Allocation Dimension Empty

This is the most important rule in this step. The dimension you plan to allocate across (where the level-to-level logic will apply) must be **left empty** here. You'll define it in the next step (Allocation Range).

**Example:**
If your hierarchy is in the **Product** dimension (T_TP → T_TP1 → P_100 → P_101), leave `Product` empty in Source.

#### Effect

The system reads the value at `(POV members) + (Source members)` and multiplies by the percentage:
```
Amount = Source Value × (Percentage ÷ 100)
```

---

### Step 3: Allocation Range

**Purpose:** This is the **core step** of the Level to Level template. Define:
1. Which **dimension** to allocate across
2. Which **parent member** serves as the top of the allocation scope
3. Which **level to start** from (where data exists)
4. Which **level to end** at (where data should be written)

#### What You See

| Field | Description |
|---|---|
| **Dimension** | Select the dimension with the hierarchy (e.g., Product, Entity, Department) |
| **Parent member** | The top-level parent member that scopes the allocation |
| **Start level/generation** | The level or generation number where data currently exists |
| **End level/generation** | The level or generation number where data should be allocated to |

#### How to Configure

**Example Hierarchy:**
```
T_TP  (Level 3, Generation 1)
  ├── P_000         (Level 2, Generation 2)
  ├── T_TP1         (Level 2, Generation 2)
  │     ├── P_100   (Level 1, Generation 3)
  │     │     ├── P_101 (Level 0, Generation 4)
  │     │     └── P_102 (Level 0, Generation 4)
  │     └── P_110   (Level 1, Generation 3)
  ├── T_TP2         (Level 2, Generation 2)
  │     ├── P_200   (Level 0, Generation 3)
  │     └── P_210   (Level 0, Generation 3)
  └── T_TP3         (Level 2, Generation 2)
        ├── P_291   (Level 0, Generation 3)
        └── P_292   (Level 0, Generation 3)
```

**Configuration for allocating from level 2 parents to their level 0 children:**

| Field | Value | Explanation |
|---|---|---|
| Dimension | Product | The dimension with the hierarchy |
| Parent member | T_TP | The top-most scope — all members below this are in scope |
| Start level | 2 | T_TP1, T_TP2, T_TP3 (where data currently lives) |
| End level | 0 | P_101, P_102, P_200, P_210, P_291, P_292 (where data goes) |

#### How the Allocation Cascades

The template allocates **level by level**, not in one jump:

```
Step 1: Level 2 → Level 1
  T_TP1's value → split to P_100, P_110
  T_TP2's value → split to P_200, P_210
  T_TP3's value → split to P_291, P_292

Step 2: Level 1 → Level 0
  P_100's value (from Step 1) → split to P_101, P_102
  P_110 (if has children at level 0) → split to children
  (P_200, P_210, P_291, P_292 are already level 0 — no further split)
```

**Key Insight:** The template automatically cascades through each intermediate level. You don't need to create separate allocation rules for each level.

#### Rules

| Rule | Detail |
|---|---|
| Start level must be HIGHER than end level | Data flows downward (from parents to children) |
| The parent member scopes the allocation | Only members under this parent are in scope |
| All data below the start level is allocated | Every member at the start level that has children is processed |
| End level members receive the final values | These are the ultimate targets |

#### ⚠️ Common Mistakes

| Mistake | Consequence | Fix |
|---|---|---|
| Start level = End level | Nothing happens — no levels to traverse | Ensure Start > End |
| Start level < End level | Invalid — can't allocate upward | Reverse the values |
| Parent member too high | More members are in scope than intended | Narrow the parent |
| Parent member too low | Some intended members are out of scope | Widen the parent |
| Unbalanced hierarchy | Some branches don't reach the end level | Members at intermediate levels may be skipped or treated as level 0 |

---

### Step 4: Target (Script Option)

**Purpose:** Define target members for dimensions specified in Source that aren't used for allocation, **plus** select a performance optimization dimension.

#### What You See

| Section | Description |
|---|---|
| **Target members** | For dimensions defined in Source but not in Allocation Range, specify the target |
| **Optimization dimension** | "For optimization, select a dimension that has only one member from the table" |
| **Main member dimension** | "Select the dimension from which you selected a single member above" |

#### Optimization Explained

This is a **performance feature** unique to the Level to Level template:

**How it works:**
1. If any dimension in your POV or Target has only **one member selected** (e.g., `Currency = USD`), select that dimension here.
2. The template uses this single-member dimension to optimize the generated calc script by reducing unnecessary dimension loops.

**Example:**
```
If Currency dimension only has "USD" selected:
  Optimization dimension: Currency
  Main member dimension: Currency

The calc script can be simplified because it doesn't need to loop
through multiple currency members.
```

#### Rules

| Rule | Detail |
|---|---|
| Target members default to Source members | You can override them |
| Target members should be level 0 (stored) | Same as other templates |
| Optimization is optional but recommended | Improves performance on large cubes |

---

### Step 5: Offset (Optional)

**Purpose:** Write a balancing (offsetting) entry so the allocation doesn't double-count.

#### What You See

| Field | Description |
|---|---|
| **Offset dimensionality** | Define which dimensions are part of the offset intersection |
| **Offset member on the allocation dimension** | The member in the allocation dimension where the offset is written |

#### How to Configure

1. **Define the offset's dimensionality:** Specify members for each dimension in the offset intersection.
2. **Define the offset member on the allocation dimension:** This is typically the parent member from the Allocation Range, or a specific "offset" member.

The placeholder `[allocationRange1]` in the wizard refers to the allocation dimension — you enter the offset member for that dimension here.

#### Rules

| Rule | Detail |
|---|---|
| **This step is OPTIONAL** | Leave blank to skip offset entirely |
| Offset member should be in the allocation dimension | It writes the balancing entry at this specific member |
| Offset value is the negative of total allocated amount | Balances the books |

#### Example

```
Allocation Range: Product dimension, Parent = T_TP
Data allocated from T_TP1, T_TP2, T_TP3 → down to level 0 children

Offset member on allocation dimension: T_TP (the grand-parent)
→ The total of all allocated values is written as a NEGATIVE to T_TP
→ Net effect: balanced
```

#### ⚠️ Common Mistake

Setting the offset member to a **level 0 member** when it should be the parent. If your offset is at a level 0 member, the offset only affects that one member, not the aggregate total.

---

### Step 6: Driver

**Purpose:** Define the basis for how data is distributed at each level.

#### What You See

| Field | Description |
|---|---|
| **Driver members** | Select one member per dimension for dimensions that vary from the POV |
| **Update driver's aggregations—** | Yes / No |

#### How to Select Driver Members

Same three methods as POV:
- Use Predefined Selection
- Member Selector
- Actions (per dimension)

#### Rules

| Rule | Detail |
|---|---|
| Select members for varying dimensions only | Dimensions that are the same as POV can be left empty |
| One member per dimension | Each dimension gets exactly one driver member |
| Empty dimensions inherit from POV | The POV and upper member ranges fill in missing dimensions |

#### "Update Driver's Aggregations" Option

| Setting | Effect | When to Use |
|---|---|---|
| **Yes** | Before calculating the allocation, the system aggregates (recalculates) the driver values in the allocation dimension | When driver data may have changed at level 0 and parent-level driver values are stale |
| **No** | Uses driver values as-is, without re-aggregation | When driver data is already current (more performant) |

#### ⚠️ Important

Setting this to **Yes** adds processing time because Essbase must first aggregate the driver dimension before performing the allocation. Only use **Yes** when you know driver data has been recently updated at lower levels and parents haven't been recalculated yet.

---

### Step 7: Other Options

**Purpose:** Final configuration for clearing, re-aggregation, rounding, and block creation.

#### What You See

| Question | Default | Options |
|---|---|---|
| **Clear the Allocation Range before allocation—** | No | Yes / No |
| **Reaggregate the allocation range after allocation—** | No | Yes / No |
| **Number of decimal places** | 0 | Any integer (0, 2, 4, etc.) |
| **Create missing blocks automatically—** | No | Yes / No |

#### Each Option Explained

**Clear the Allocation Range:**
| Setting | Effect | When to Use |
|---|---|---|
| **Yes** | Clears ALL data in the allocation range (between start and end levels) to `#MISSING` before running | When re-running the allocation — prevents accumulation of stale values |
| **No** | New values are written on top of existing data | When multiple allocations feed the same range (additive) |

**Reaggregate the allocation range:**
| Setting | Effect | When to Use |
|---|---|---|
| **Yes** | After the allocation, parent members in the allocation range are recalculated | When downstream rules or reports need up-to-date parent totals immediately |
| **No** | Parent members retain their old values until the next aggregation | Better performance — aggregate separately later |

**Number of decimal places:**
| Value | Effect |
|---|---|
| `0` | Values are rounded to whole numbers |
| `2` | Values are rounded to 2 decimal places (standard for currency) |
| `4` | Values are rounded to 4 decimal places (for unit costs, rates) |

**Create missing blocks automatically:**
| Setting | Effect | When to Use |
|---|---|---|
| **Yes** | If a target intersection doesn't have a data block in Essbase, one is created automatically | When target members are new or have never had data |
| **No** | Only existing blocks receive data — new blocks are NOT created | Performance optimization — use when blocks already exist |

---

## 5. Complete Configuration Example

### Business Scenario

**Hierarchy (Product Dimension):**
```
T_TP  (Level 3)
  ├── P_000        (Level 2) — standalone, no children
  ├── T_TP1        (Level 2)
  │     ├── P_100  (Level 1)
  │     │     ├── P_101  (Level 0)
  │     │     └── P_102  (Level 0)
  │     └── P_110  (Level 0)
  ├── T_TP2        (Level 2)
  │     ├── P_200  (Level 0)
  │     └── P_210  (Level 0)
  └── T_TP3        (Level 2)
        ├── P_291  (Level 0)
        └── P_292  (Level 0)
```

**Requirement:** Budget data is loaded at level 2 (T_TP1 = $100,000, T_TP2 = $60,000, T_TP3 = $40,000). Allocate to level 0 using Revenue as the driver.

### Wizard Configuration

| Step | Field | Value | Notes |
|---|---|---|---|
| **POV** | Scenario | Budget | Fixed |
| | Version | Working | Fixed |
| | Years | FY2025 | Fixed |
| | Period | Jan | Fixed |
| | Currency | USD | Fixed — also used for optimization |
| | HSP_View | BaseData | Fixed |
| **Source** | Account | Operating_Expenses | Where data lives |
| | Entity | Corporate | Specific entity |
| | Department | All_Depts | Parent for departments |
| | Product | *(leave empty)* | This is the allocation dimension |
| | Percentage | 100 | Full allocation |
| **Allocation Range** | Dimension | Product | The hierarchy dimension |
| | Parent member | T_TP | Scope of allocation |
| | Start level | 2 | T_TP1, T_TP2, T_TP3 |
| | End level | 0 | P_101, P_102, P_110, P_200, P_210, P_291, P_292 |
| **Target/Script Option** | Account | Operating_Expenses_Allocated | Different target account |
| | Entity | Corporate | Same entity |
| | Optimization dimension | Currency | Only one member (USD) |
| | Main member dimension | Currency | Same as above |
| **Offset** | Dimensionality | Account = Operating_Expenses, Entity = Corporate | Where offset is written |
| | Offset member (alloc dim) | T_TP | Grand-parent — receives total offset |
| **Driver** | Account | Revenue | Revenue-based driver |
| | Update aggregations | No | Revenue data is already current |
| **Other Options** | Clear range | Yes | Clean slate |
| | Reaggregate | Yes | Update parents after |
| | Decimal places | 0 | Whole numbers |
| | Create blocks | Yes | Ensure all targets exist |

### Data & Calculation

```
BEFORE ALLOCATION:

Level 2 Data (Source — loaded values):
  T_TP1: $100,000
  T_TP2:  $60,000
  T_TP3:  $40,000

Revenue Driver (at level 0):
  P_101:  $500,000  (50% of T_TP1's scope)
  P_102:  $300,000  (30%)
  P_110:  $200,000  (20%)
  P_200:  $400,000  (67% of T_TP2's scope)
  P_210:  $200,000  (33%)
  P_291:  $250,000  (62.5% of T_TP3's scope)
  P_292:  $150,000  (37.5%)

ALLOCATION CASCADE:

Pass 1: Level 2 → Level 1 (where applicable)
  T_TP1 ($100,000):
    → P_100: $100,000 × (800,000/1,000,000) = $80,000
        (P_100's revenue = P_101 + P_102 = $500K + $300K = $800K)
    → P_110: $100,000 × (200,000/1,000,000) = $20,000
        (P_110 is level 0 — keeps $20,000)

  T_TP2 ($60,000):
    → P_200 and P_210 are already level 0
    → P_200: $60,000 × (400,000/600,000) = $40,000
    → P_210: $60,000 × (200,000/600,000) = $20,000

  T_TP3 ($40,000):
    → P_291 and P_292 are already level 0
    → P_291: $40,000 × (250,000/400,000) = $25,000
    → P_292: $40,000 × (150,000/400,000) = $15,000

Pass 2: Level 1 → Level 0
  P_100 ($80,000 from Pass 1):
    → P_101: $80,000 × (500,000/800,000) = $50,000
    → P_102: $80,000 × (300,000/800,000) = $30,000

FINAL RESULTS (Level 0):

  P_101:  $50,000  ✓
  P_102:  $30,000  ✓
  P_110:  $20,000  ✓ (was level 0 in T_TP1's scope)
  P_200:  $40,000  ✓
  P_210:  $20,000  ✓
  P_291:  $25,000  ✓
  P_292:  $15,000  ✓
  ────────────────
  Total: $200,000  ✓ (= $100K + $60K + $40K)

OFFSET:
  T_TP → -$200,000 (balances the total)
```

---

## 6. Key Differences from the Standard Allocation Template

| Feature | Standard Allocation | Allocate - Level to Level |
|---|---|---|
| **Target levels** | Always level 0 (leaf) | Configurable start and end levels |
| **Cascade behavior** | Single pass: parent → level 0 | Multi-pass: level N → level N-1 → ... → level M |
| **Script optimization** | Not available | Select single-member dimension for optimization |
| **Source percentage** | ✅ Available | ✅ Available |
| **Spread method step** | ✅ Separate step (Skip None/Missing/Zero/Both) | Handled internally by driver |
| **Offset complexity** | Full: opposite sign, clear options | Simpler: dimensionality + offset member |
| **Exclude step** | ✅ Available | ❌ Not available — all members in range are included |
| **Unbalanced hierarchies** | Targets are always level 0 — unbalanced hierarchies don't matter | Can cause issues — branches that don't reach the end level may have incomplete allocations |
| **Driver aggregation update** | Not available | ✅ Option to update driver aggregations before allocation |

---

## 7. Handling Unbalanced Hierarchies

### The Problem

In an unbalanced hierarchy, some branches go deeper than others:

```
T_TP  (Level 3)
  ├── T_TP1        (Level 2)
  │     ├── P_100  (Level 1)
  │     │     ├── P_101  (Level 0)  ← 4 levels deep
  │     │     └── P_102  (Level 0)
  │     └── P_110  (Level 0)        ← 3 levels deep (stops at level 0)
  ├── P_000        (Level 0)        ← 2 levels deep (directly under root!)
  └── T_TP2        (Level 2)
        ├── P_200  (Level 0)        ← 3 levels deep
        └── P_210  (Level 0)
```

If you set Start Level = 2 and End Level = 0:
- **T_TP1** (Level 2): Has children → allocation proceeds ✓
- **T_TP2** (Level 2): Has children → allocation proceeds ✓
- **P_000** (Level 0): Is NOT at level 2 — it's already at level 0. It's **skipped** by the start level filter.

### The Solution

| Approach | How |
|---|---|
| **Balanced hierarchies** | Restructure your dimension so all branches have the same depth — best practice |
| **Multiple passes** | Create separate allocation rules for different branches |
| **Use @ALLOCATE directly** | Write custom calc scripts that handle each branch independently |
| **Shared members** | Place shared members at the appropriate level to balance the hierarchy |

---

## 8. Do's & Don'ts for Level to Level Template

### ✅ DO's

| # | Do | Why |
|---|---|---|
| 1 | **Verify your hierarchy levels** before configuring | Wrong start/end levels cause silent failures |
| 2 | **Leave the allocation dimension empty in Source** | It's defined in Allocation Range |
| 3 | **Ensure all POV members have Store property** | Dynamic Calc members can't store allocated values |
| 4 | **Use the optimization dimension** for performance | Select the dimension with only one member |
| 5 | **Set "Update driver aggregations = Yes"** if driver data changed recently | Ensures proportional shares are accurate |
| 6 | **Enable Clear Range = Yes when re-running** | Prevents double-counting from prior runs |
| 7 | **Verify the hierarchy is balanced** | Unbalanced branches may be partially skipped |
| 8 | **Test with a small hierarchy first** | Complex multi-level allocations can write to many cells |
| 9 | **Set Create Missing Blocks = Yes** for new hierarchies | Without blocks, data cannot be written |
| 10 | **Save the rule after completing the wizard** | Unsaved configurations are lost |

### ❌ DON'TS

| # | Don't | Why |
|---|---|---|
| 1 | **Don't set Start Level = End Level** | No levels to traverse — nothing happens |
| 2 | **Don't set Start Level < End Level** | Can't allocate upward — rule errors or produces no results |
| 3 | **Don't use functions in the Source step** | Only explicit members and variables are allowed |
| 4 | **Don't forget to check level numbers** | Level numbers are bottom-up (level 0 = leaf) — easy to confuse with generations (top-down) |
| 5 | **Don't use Dynamic Calc members in POV** | Allocation can't write to Dynamic Calc intersections |
| 6 | **Don't skip the driver step** for proportional allocation | Without a driver, the allocation has no basis for distribution |
| 7 | **Don't use this template for same-level redistribution** | It's designed for top-down allocation between different levels |
| 8 | **Don't set Create Blocks = Yes on very large cubes** without testing | Can create millions of blocks and exhaust memory |
| 9 | **Don't ignore unbalanced hierarchies** | Members on short branches may be skipped |
| 10 | **Don't set Reaggregate = Yes on large cubes** in production | Aggregation is expensive — do it separately for better control |

---

## 9. Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| No data allocated at all | Start Level = End Level, or source is `#MISSING` | Verify levels are different and source has data |
| Some branches get data, others don't | Unbalanced hierarchy — short branches don't reach start level | Balance the hierarchy or create separate rules |
| "Member not found" error | Typo in parent member or offset member | Verify exact member names in the outline |
| Allocated values don't sum correctly | Driver values not aggregated, or rounding without error handling | Set "Update driver aggregations = Yes" and add rounding |
| Double-counting after re-run | Clear Range = No | Set Clear Range = Yes |
| Performance is very slow | Create Blocks = Yes on a large cube, or Reaggregate = Yes | Set both to No and handle separately |
| Dynamic Calc error | POV or Target includes Dynamic Calc members | Change to stored members |
| Offset not written | Offset step left blank | Define offset dimensionality and member |
| Data written to wrong levels | Start and End levels swapped or miscounted | Double-check level numbers (bottom-up) |
| "Cannot allocate to member" error | Target member is Label Only or Dynamic Calc | Change member's Data Storage to "Store" |

---

## 10. Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│     ALLOCATE - LEVEL TO LEVEL QUICK REFERENCE                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ACCESS:                                                     │
│  Graphical: New Objects → Allocate - Level to Level          │
│  Script:    System Templates → Allocate - Level to Level     │
│                                                              │
│  WIZARD STEPS:                                               │
│  POV → Source (%) → Allocation Range (start/end levels) →    │
│  Target (+ script optimization) → Offset (optional) →       │
│  Driver (+ aggregation option) → Other Options → Finish     │
│                                                              │
│  LEVELS (Bottom-Up):                                         │
│  Level 0 = Leaf (no children)                                │
│  Level 1 = Parent of leaves                                  │
│  Level 2 = Grandparent of leaves                             │
│  Level N = N levels above leaves                             │
│                                                              │
│  GENERATIONS (Top-Down):                                     │
│  Gen 1 = Root                                                │
│  Gen 2 = Children of root                                    │
│  Gen N = N levels below root                                 │
│                                                              │
│  KEY RULES:                                                  │
│  ✓ Start Level > End Level (data flows down)                 │
│  ✓ Leave allocation dimension empty in Source                │
│  ✓ All POV members must have Store property                  │
│  ✓ Use optimization dimension for performance                │
│  ✓ Cascades automatically through each level                 │
│  ✗ Cannot allocate upward (End > Start)                      │
│  ✗ Cannot use functions in Source step                        │
│  ✗ No Exclude step available                                 │
│                                                              │
│  UNIQUE FEATURES vs. STANDARD ALLOCATION:                    │
│  • Configurable start/end levels                             │
│  • Script optimization option                                │
│  • Driver aggregation update option                          │
│  • Multi-pass cascade through levels                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

> **Document Version:** 1.0  
> **Applies To:** Oracle EPM Cloud — Enterprise Planning and Budgeting Cloud Service (EPBCS / PBCS)  
> **Last Updated:** August 2026  
> **Source:** [Oracle EPM Calculation Manager — Using the Allocate Level to Level Template](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/ecalc/)

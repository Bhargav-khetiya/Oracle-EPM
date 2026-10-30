# 05 — Format & Validation Rules Engine

---

## 5.1 Overview: The Data Governance Engine

The **Format / Validation Rules Engine** allows form designers to enforce corporate financial policies directly within data-entry forms. It serves two distinct purposes:
1. **Dynamic Formatting**: Changes cell background colors, borders, and fonts based on cell values (e.g., highlighting negative variances in red).
2. **Data Validation & Save Blocking**: Intercepts cell inputs and blocks the user from saving if financial rules are violated (e.g., blocking submission if travel expense exceeds budget by > 15%).

```
┌────────────────────────────────────────────────────────────────────────┐
│                        VALIDATION RULE STRUCTURE                       │
├────────────────────────────────────────────────────────────────────────┤
│ RULE: [Check_Capex_Limit]                                              │
│ LOCATION: [Column B: FY26 Budget]                                      │
│                                                                        │
│ CONDITION BLOCK 1:                                                     │
│   Source: [Cell Value] > Target: [Value: $500,000]                     │
│                                                                        │
│ ACTIONS:                                                               │
│   • Action 1: Set Background Color = Light Coral (Red)                 │
│   • Action 2: Display Tooltip = "Requires CFO Special Approval"        │
│   • Action 3: BLOCK SAVE (Process = Stop Save)                         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 5.2 Anatomy of the Rule Editor & Condition Block Toolbar

From your supplied production extraction (`forms property.txt`), the Format/Validation Rule Properties editor provides an enterprise-grade condition builder:

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                FORMAT / VALIDATION RULE PROPERTIES                                     │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ [Add Rule]  [Delete]  [Duplicate]  [View Rule]                                                         │
│ Location:    [Column B                     ]   Name:        [Capex_Variance_Threshold]                │
│ Description: [Flags variances > 15% and stops save]                                                    │
│ [X] Enable format/validation rule               [ ] Format Only     [ ] Custom grouping                │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ CONDITION BLOCK TOOLBAR:                                                                               │
│ [Add Condition Block]  [Delete Condition Block]  [Cut]  [Copy]  [Paste]  [Group]  [Un-Group]  [Detach] │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ TABLE OF CONDITIONS:                                                                                   │
│ Condition │ Source Type  │ Source Value │ Operator │ Target Type  │ Target Value │ Process │ Actions │
│ ───────── │ ──────────── │ ──────────── │ ──────── │ ──────────── │ ──────────── │ ─────── │ ─────── │
│ 1         │ Current Cell │ [Value]      │ >        │ Value        │ 100000.00    │ Stop    │ Red,    │
│           │              │              │          │              │              │ Save    │ Tooltip │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ [Add Condition]  [Delete Condition]                    [Help]  [Validate]  [OK]  [Cancel]              │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 5.2.1 Core Field Specifications

| Component | UI State / Options in Extract | Function & Business Purpose |
| :--- | :--- | :--- |
| **`Location`** | Grid Segment (e.g. `Column B`, `Row 1`) | Dictates the boundary of evaluation on the form. |
| **`Enable format/validation rule`** | Checkbox | Activates or disables the rule without deleting its definition. |
| **`Format Only`** | Checkbox | When checked, applies visual styling (colors/fonts) only; does **not** block data saving regardless of condition outcomes. |
| **`Custom grouping`** | Checkbox | Unlocks boolean grouping logic (`AND`, `OR`, parentheses `( )`) across multiple condition blocks. |
| **`Source Type`** | `Current Cell Value`, `Cross-Dimension Cell Value`, `Account Type`, `Member Name` | The left-hand operand evaluated by the validation processor. |
| **`Operator`** | `=`, `!=`, `>`, `<`, `>=`, `<=`, `Between`, `Contains` | Relational comparison operator. |
| **`Target Type`** | `Value`, `Cell Intersection`, `Smart List Entry`, `User Variable` | The right-hand operand compared against the source. |
| **`Process`** | `Continue`, `Warning`, `Stop Save` | Dictates runtime execution flow: `Stop Save` throws an error dialog and cancels the Essbase commit. |
| **`Actions`** | Background color, font weight, border, custom validation tooltips | Visual formatting injected into the client browser DOM. |

---

## 5.3 The Two Essential Essbase Optimization Checkboxes

At the bottom of the validation rules editor in your extract, two critical performance checkboxes reside:

```
┌─────────────────────────────────────────────────────────────┐
│                 CRITICAL PERFORMANCE CHECKBOXES             │
├─────────────────────────────────────────────────────────────┤
│ [X] Validate only for users with access to this form        │
│ [X] Validate only for pages with existing blocks            │
└─────────────────────────────────────────────────────────────┘
```

### 1. `Validate only for users with access to this form`
* *Why it matters*: In large enterprise deployments, background validation processes or batch refreshes evaluate rules across security groups. If a user has no access to the underlying form, skipping rule execution saves CPU cycles.

---

### 2. `Validate only for pages with existing blocks` (The Block Physics Secret)

This is one of the most important performance toggles in Oracle EPM Planning:

```
THE SCENARIO:
  • Page Dimension: Department (500 Cost Centers)
  • Active Cost Centers with Data: 50
  • Empty Cost Centers (No Blocks in .PAG): 450
```

#### What Happens When UNCHECKED:
1. When a user opens or saves a form, Planning's validation processor loops through **all 500 pages**.
2. For the 450 empty pages, it attempts to query Essbase for cell intersections.
3. Because the blocks do not exist, Essbase may create temporary in-memory structures or scan the index repeatedly.
4. **Result**: Validation takes **15 to 30 seconds**, and forms become frustratingly slow.

#### What Happens When CHECKED:
1. Planning first queries the **Essbase Index (`.IND`) file B-tree**.
2. It detects that **only 50 blocks physically exist** for this department hierarchy.
3. It **completely skips the 450 empty pages**.
4. Validation executes strictly across the 50 existing pages.
5. **Result**: Execution time drops from 30 seconds to **< 0.5 seconds (60x speedup)**.

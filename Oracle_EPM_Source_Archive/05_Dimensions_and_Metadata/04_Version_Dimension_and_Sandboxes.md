# 04 — Version Dimension and Sandboxes: Workflow & Target Modeling

---

## 4.1 Overview: Modeling Scenarios Across Iterations

The **Version** dimension represents iterative stages of a plan or forecast within a given Scenario. While `Scenario` answers *"What business case are we modeling?"* (Budget, Forecast), `Version` answers *"Which revision or iteration of this plan is this?"* (Working, Draft 1, Review, Final).

---

## 4.2 Deep Dive: The `Working` UI Extraction

From your supplied production screen extraction:

```
Member: Working
├── Version Type:          Standard Bottom Up
├── Enabled for Approvals: Checked
├── Enable Sandboxes:      Unchecked
├── Hierarchy Type:        Not Set
├── Data Storage:          Never Share
├── Two Pass Calculation:  Unchecked (Disabled)
└── Plan Type Settings:    All 4 cubes checked (disabled checkboxes);
                           Addition operator selected across all cubes
```

---

## 4.3 Version Type: Standard Bottom Up vs. Standard Target

This is one of the most critical structural decisions in Oracle Planning:

```
┌──────────────────────────────────────┬──────────────────────────────────────┐
│        STANDARD BOTTOM UP            │           STANDARD TARGET            │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ • Planners enter data at LEVEL 0     │ • Executives/Managers enter targets  │
│   (Cost Centers, Products, Details). │   at PARENT levels (e.g. Total US).  │
│ • Data aggregates UPWARD into        │ • Data is spread DOWNWARD to child   │
│   parent nodes.                      │   members using allocation rules.    │
│ • Level 0 is Read/Write;             │ • Parent nodes are Read/Write;       │
│   Parents are Read-Only (calculated).│   Level 0 reflects allocated target. │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

### Detailed Numerical Comparison

#### Scenario 1: Standard Bottom Up (`Working`)
* **Hierarchy**: `Total Engineering` $\rightarrow$ `Dept 101 (Software)`, `Dept 102 (QA)`.
* **User Action**: The software manager types **\$150,000** in Dept 101; QA manager types **\$50,000** in Dept 102.
* **Result**:
  * `Dept 101` = \$150,000 (Editable)
  * `Dept 102` = \$50,000 (Editable)
  * `Total Engineering` = **\$200,000** (Read-Only dynamically aggregated summary).
* If the VP of Engineering tries to change `Total Engineering` directly to \$250,000 on a Bottom-Up form, Planning **blocks the input** because parent blocks are derived.

#### Scenario 2: Standard Target (`Target_Version`)
* **Hierarchy**: `Total Engineering` $\rightarrow$ `Dept 101`, `Dept 102`.
* **User Action**: The CFO issues a top-down budget envelope by typing **\$300,000** directly into `Total Engineering`.
* **Result**:
  * `Total Engineering` accepts direct data entry (\$300,000).
  * Planning triggers Grid Spreading or an Allocation Rule to distribute the \$300,000 down to `Dept 101` and `Dept 102` based on prior-year ratios (e.g., 75% / 25% $\rightarrow$ \$225,000 and \$75,000).

---

## 4.4 Enabled for Approvals

When `Enabled for Approvals` is **Checked**:
1. The version becomes an eligible dimension coordinate in **Planning Unit Hierarchies (PUH)**.
2. A formal workflow is established:
   ```
   [Planner] ────Promote────► [Reviewer] ────Approve────► [Signed Off]
       ▲                           │
       └──────────Reject───────────┘
   ```
3. When a planner promotes their budget, write permissions are dynamically transferred to the reviewer, and the planner's grid becomes read-only.
4. *Best Practice*: `Working` versions are enabled for approvals; archived versions (`Final`, `Historical Actuals`) have approvals disabled.

---

## 4.5 Enable Sandboxes

```
┌─────────────────────────────────────────────────────────────┐
│                 SANDBOX MEMORY ARCHITECTURE                 │
├─────────────────────────────────────────────────────────────┤
│ Base Data Blocks (Permanent in .PAG disk files):            │
│ [Entity: US_East | Dept: Sales | Version: Working] = $100K  │
│                                                             │
│ Planner 1 Sandbox Overlay (Virtual Private RAM layer):      │
│ [Sandbox: Best_Case] = $130K  (Only visible to Planner 1)   │
│                                                             │
│ Planner 2 Sandbox Overlay:                                  │
│ [Sandbox: Worst_Case] = $80K  (Only visible to Planner 2)   │
│                                                             │
│ When approved: User clicks "Publish Sandbox"                │
│ -> Overwrites Base Data Block in .PAG with $130K            │
└─────────────────────────────────────────────────────────────┘
```

* **What is a Sandbox?**: A private "What-If" workspace created dynamically for each user without requiring administrators to add new members to the Version dimension.
* **Storage Mechanics**: Sandboxes use virtual cell overlays. Changes are held in a private memory layer and do not dirty or corrupt shared production data.
* **Publishing**: When satisfied with a scenario, the user selects **Publish Sandbox**, which writes the numbers back into the base `Working` version.

---

## 4.6 Version Lifecycle Comparison Matrix

| Version Name | Version Type | Data Storage | Approvals Enabled? | Sandboxes Enabled? | Typical Consultant Use Case |
| :--- | :--- | :--- | :---: | :---: | :--- |
| **`Working`** | Standard Bottom Up | `Never Share` | **Yes** | Optional | Daily collaborative budget and forecast entry. |
| **`Target`** | Standard Target | `Never Share` | No | No | Executive top-down corporate targets. |
| **`Final`** | Standard Bottom Up | `Never Share` | No | No | Locked, approved board-level budget (Read-Only). |
| **`What_If`** | Standard Bottom Up | `Never Share` | No | **Yes** | Ad-hoc modeling and simulation. |

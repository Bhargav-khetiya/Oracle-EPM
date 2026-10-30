# 06 — System Approval Dimensions & The 17 Metric Types

---

## 6.1 The Architecture of `HSP_` System Members

In your supplied production screen extractions:
* **`HSP_Approval Unit Hierarchy`** (Metric Type = `Approval Unit Hierarchy`)
* **`HSP_Approval Unit Submission Group`** (Metric Type = `Approval Unit Submission Group`)

The `HSP_` prefix designates **internal system members generated and maintained exclusively by Oracle Hyperion/EPM Planning's kernel**.

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              THE HSP_ SYSTEM GUARANTEE                                 │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ • Created automatically when Planning applications are provisioned.                    │
│ • Binds the relational workflow engine (PUH) to Essbase storage blocks.                │
│ • Administrators must NEVER rename, delete, add custom children to, or repurpose       │
│   any member beginning with HSP_. Doing so corrupts the relational-Essbase mapping.    │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 6.2 The 17 Metric Types: Comprehensive Master Reference

The **Metric Type** dropdown defines how a system member interacts with Planning Unit Hierarchies (PUH), workflow states, promotional history, and dynamic cell-level security.

| # | Metric Type | Plain-English Definition | Internal Technical Data Stored | Practical Real-World Example |
| :-: | :--- | :--- | :--- | :--- |
| **1** | **`None`** | Standard operational member | Normal numeric or Smart List data; no workflow binding. | Base sales accounts, employee headcounts. |
| **2** | **`Data Value`** | Financial data submission point | The actual budget dollars submitted as part of the approval unit. | Total departmental budget balance submitted for review. |
| **3** | **`Process State`** | Workflow progression status code | Numeric status flag: `0 = Under Review`, `1 = Submitted`, `2 = Approved`. | Status badge on the Planning approvals dashboard. |
| **4** | **`Approval Unit PM Member`** | Primary Member tracking | Identifies the base operational member bound to this approval unit. | Cost Center `E10002` bound as the unit root. |
| **5** | **`Approval Unit Primary Member`** | Primary hierarchy binding | Resolves secondary approval trees back to the primary Entity outline. | Alternate rollup of regional entities into statutory approval paths. |
| **6** | **`Approval Unit Secondary Member`**| Secondary dimension filter | Tracks secondary dimensional coordinates (e.g., Scenario or Version). | Approval units partitioned by `Scenario: Budget` and `Version: Working`. |
| **7** | **`Approval Unit Owner`** | Current user ownership lock | User ID of the individual or group who currently has write access. | Shows `jsmith` as the current owner holding the budget edit lock. |
| **8** | **`Approval Unit Previous Owner`**| Preceding reviewer audit | User ID of the person who promoted, delegated, or rejected the unit. | Shows that `mchen` promoted the budget to `jsmith` for second-round sign-off. |
| **9** | **`Approval Unit Last Action`** | Audit trail action code | String/code recording the last action: `Promote`, `Reject`, `Sign Off`. | Audit report displays "Rejected with Comment: Revise travel budget." |
| **10**| **`Approval Unit Substate`** | Granular workflow condition | Specialized internal workflow state (e.g., `Validation Failed`). | Indicates a budget cannot be promoted because a data rule failed. |
| **11**| **`Approval Unit Submission Group`**| Sub-entity submission group | **Selected in Extract**: Group ID allowing split submission of an entity. | Finance submits Operating Expenses in Week 1 and CapEx in Week 2. |
| **12**| **`Approval Unit Hierarchy`** | Approval tree root reference | **Selected in Extract**: Binds the member to the Planning Unit Hierarchy. | Links the member to the North America Commercial Approval Unit Tree. |
| **13**| **`Entity Process State`** | Rollup entity workflow status | Identifies whether all child entities are approved before parent signs off. | Prevents Total US from signing off while California is still "Under Review." |
| **14**| **`Approval Unit Total`** | Stored financial check total | Checksum dollar value recorded at the moment of promotion. | Check total of \$1,500,000 recorded when promoted to VP. |
| **15**| **`Approval Unit Total (Dynamic)`**| On-the-fly threshold check | Dynamically evaluated threshold for promotional routing rules. | Routes approval to CFO if total exceeds \$5,000,000; to Director if under. |
| **16**| **`Approval Unit Last Modified`** | Epoch timestamp | Numeric timestamp of the exact date/time the unit was promoted. | System audit log displaying `2026-10-27 14:30:00 UTC`. |
| **17**| **`Cell Level Security Access`** | Dynamic security overlay | Toggles read/write access based on workflow approval status. | Locks all data cells in an entity the moment the planner hits "Submit." |

---

## 6.3 Deep Dive: Submission Groups (`Metric Type = 11`)

In your extracted screen for `HSP_Approval Unit Submission Group`:
* **The Business Problem**: In traditional budgeting, an entire Entity (e.g., `E10002`) had to be submitted at once. If Human Resources was finished with salaries but IT was waiting for software quotes, the entire departmental budget was blocked from approval.
* **The Solution (Submission Groups)**: Planning allows partitioning budget forms into **Submission Groups**:
  * `Group 1`: Personnel Costs (Promoted by HR on Day 5).
  * `Group 2`: Operating Expenses (Promoted by Cost Center Manager on Day 10).
  * `Group 3`: Capital Outlays (Promoted by Facilities on Day 15).
* The member `HSP_Approval Unit Submission Group` stores the group assignment metadata, allowing independent promotion, rejection, and approval cycles for the same entity.

---

## 6.4 The Approval-Unit Lifecycle

```
[PLANNER: jsmith]
  │
  ▼ (Planner completes data entry in web form)
[PROMOTE ACTION]
  │  1. Planning checks Validation Rules
  │  2. Updates Metric Type: Process State = 1 (Submitted)
  │  3. Updates Metric Type: Approval Unit Owner = mchen (Reviewer)
  │  4. Updates Metric Type: Approval Unit Previous Owner = jsmith
  │  5. Cell Level Security flips jsmith's permissions to READ-ONLY
  ▼
[REVIEWER: mchen]
  │
  ├───[REJECT]───► Returns to jsmith (Owner reverts to jsmith; write restored)
  │
  └───[APPROVE]──► Final Sign-off (Locked permanently; Process State = 2)
```

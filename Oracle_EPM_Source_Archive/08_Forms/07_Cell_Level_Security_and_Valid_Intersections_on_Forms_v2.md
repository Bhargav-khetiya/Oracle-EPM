# 🛡️ Form Properties — Cell-Level Security (CLS) & Valid Intersections (VIC)

> **Purpose**: This technical manual details the internal architecture, database evaluation pipeline, grid rendering mechanics, suppression interactions, and performance impacts of **Cell-Level Security (CLS)** and **Valid Intersections (VIC)** within Oracle EPM Cloud Planning web forms and Smart View grids.

---

## 1. Architectural Distinction: CLS vs. Valid Intersections

While both features restrict interactions at specific multi-dimensional coordinates on forms, their architectural layers, execution engines, and functional objectives are fundamentally different:

| Dimension / Characteristic | Cell-Level Security (CLS) | Valid Intersections (VIC) |
| :--- | :--- | :--- |
| **Primary Purpose** | **Authorization & Data Privacy**: Restricting read/write access based on user role, group, or identity. | **Business Logic & Data Integrity**: Restricting invalid business combinations (e.g., Marketing expense in an IT department). |
| **Governing Engine** | EPM Planning Application Server Security Kernel (Intersects with Essbase security tokens). | EPM Planning Metadata Validation Engine (Applied at Form Grid / Data Entry layer). |
| **Applicability** | Evaluated per user identity or group assignment. | Universal across all users (including Service Administrators, unless explicitly bypassed). |
| **Permission Modes** | `READ`, `WRITE`, `DENY` (Deny takes absolute precedence). | `VALID`, `INVALID` (Binary valid or not valid). |
| **Cell Display (Smart View / Web)** | `#NoAccess` (if Denied), Gray Read-Only (if Read-Only), White/Yellow (if Write). | Light Gray / Hatched pattern with tooltip: *"This intersection is not valid"*. Read-Only. |
| **Form Data Suppression** | Form property: *Suppress Missing Blocks* / *Data*. Denied cells evaluate as `#NoAccess`. | Form property: *Suppress Invalid Data* (Hides the entire row/column if all cells are invalid). |
| **Essbase Level Impact** | Affects data retrieval queries via generated security filters (`MDX sub-queries`). | Purely relational/application layer; Essbase block structure is agnostic to VIC. |

---

## 2. Relational Schema & Storage Internals

In the Oracle EPM Cloud relational repository (underlying PostgreSQL/Oracle relational instance), CLS and Valid Intersections are maintained in dedicated schema tables:

```
                          RELATIONAL PERSISTENCE MODEL
                          
   [HSP_OBJECT] ──────────────┐ (Member / User / Group ID)
         │                    │
         ▼                    ▼
   [HSP_CLS_RULE]       [HSP_VALID_INTERSECTION]
   ├── RULE_ID          ├── VI_GROUP_ID
   ├── RULE_NAME        ├── RULE_NAME
   ├── APP_ID           ├── ANCHOR_DIM_ID
   └── ACCESS_TYPE      └── ENABLE_FLAG
         │                    │
         ▼                    ▼
   [HSP_CLS_DEF]        [HSP_VI_RULE_DEF]
   ├── DIM_ID           ├── DIM_ID
   ├── MEMBER_SELECTION ├── MEMBER_SET (e.g. Descendants)
   └── EXCLUDE_FLAG     └── IS_EXCLUSION
```

### Relational Table Descriptions

1. **`HSP_CLS_RULE`**:
   - `RULE_ID` (Integer Primary Key)
   - `ACCESS_TYPE`: Bitmask integer representing `1 = READ`, `2 = WRITE`, `0 = DENY`.
   - `PRIORITY`: Evaluation precedence order.
2. **`HSP_CLS_MEMBER_SET`**:
   - Stores the multi-dimensional tuples defining the security boundary. Each row maps a `RULE_ID` to a `DIM_ID` and a `MEMBER_FUNCTION` (e.g., `@IDESC(Total_Entity)`).
3. **`HSP_VALID_INTERSECTION` & `HSP_VI_RULE_DEF`**:
   - Stores the rule group definition.
   - `ANCHOR_DIM_ID`: Identifies the driving dimension (Anchor Dimension). When an anchor member is present, the EPM engine checks dependent dimension rules.

---

## 3. The 6-Stage Cell Access Evaluation Pipeline

When an EPM Form renders or a user attempts to submit data, the application processes cell coordinates through a strict 6-stage pipeline:

```
[User Requests Form Render / Submit]
               │
               ▼
   [Stage 1: Essbase Member Security]
   ├── Does user have Essbase Read/Write to Entity, Account, Version?
   └── If Essbase = NONE ──► Result: #NoAccess (Terminated immediately)
               │ (Pass)
               ▼
   [Stage 2: Scenario / Version Time Restrictions]
   ├── Is Scenario/Version locked for the period? (Start/End period checks)
   └── If Locked ──► Result: Read-Only (Cell grayed out)
               │ (Pass)
               ▼
   [Stage 3: Planning Unit Approval Hierarchy (PUH)]
   ├── Is the Approval Unit in 'Promoted' or 'Approved' state?
   └── If Not Owner ──► Result: Read-Only
               │ (Pass)
               ▼
   [Stage 4: Valid Intersections (VIC) Engine]
   ├── Does coordinate match an Invalid Intersection rule?
   └── If INVALID ──► Result: Read-Only / Tooltip 'Invalid' (Write blocked)
               │ (Valid)
               ▼
   [Stage 5: Cell-Level Security (CLS) Engine]
   ├── Check CLS Rules:
   │   ├── Match DENY rule? ──► Result: #NoAccess (Data hidden/masked)
   │   ├── Match WRITE rule? ──► Result: WRITE (Yellow/Editable)
   │   └── Match READ rule? ──► Result: READ (Gray/Read-Only)
               │ (Write Permitted)
               ▼
   [Stage 6: Form Segment & Dynamic Calc Status]
   ├── Is member Dynamic Calc or Form Column set to Read-Only?
   └── Final State: EDITABLE or READ-ONLY
```

---

## 4. Grid Rendering & Visual States on Forms

The EPM Web Grid renderer assigns specific CSS classes and HTML attributes to each cell based on the resolved coordinate status:

| Coordinate State | Rendered Color | Cell Value Displayed | User Action Allowed | Underlying Form Grid Attribute |
| :--- | :--- | :--- | :--- | :--- |
| **Valid + Write Permitted** | White (Web) / Yellow (Smart View) | Numeric value (e.g., `45,000.00`) | Direct input, Spread, Mass Allocate | `data-editable="true"` |
| **Valid + Read-Only (CLS)** | Light Gray (`#F4F4F4`) | Numeric value (e.g., `45,000.00`) | View only. Double-click does not open input. | `data-editable="false"` |
| **Valid + Denied (CLS)** | Gray / Pattern | `#NoAccess` or Blank | Hidden / Unselectable | `data-access="denied"` |
| **Invalid Intersection (VIC)** | Light Gray with red hatch / Warning icon | Numeric value (or blank if missing) | Read-Only. Hover displays: *"Invalid Intersection"*. | `data-invalid-intersection="true"` |
| **Dynamic Calc Member** | Soft Gray | Calculated value (e.g., `120,000.00`) | Read-Only. Double-click recalculates parent. | `data-storage="dynamic_calc"` |

---

## 5. Interaction with Data Suppression Settings

Forms have critical toggle options in the **Grid Properties** tab that dictate how CLS and VIC interact with row and column suppression:

### 1. `Suppress Invalid Data`
- **When Checked (`True`)**:
  - The Form Layout Engine intercepts the retrieved data grid before sending it to the browser.
  - If an entire row or column consists solely of coordinates flagged as **Invalid Intersections**, that row or column is stripped from the DOM.
  - *Internal Mechanism*: Unlike Essbase suppression (which happens in the MOLAP engine via MDX `NON EMPTY`), VIC suppression happens in the **EPM Web Application Server tier**. It cross-references the retrieved Essbase slice against the in-memory VIC bitmask.
- **When Unchecked (`False`)**:
  - The invalid rows/columns are rendered. Cells are marked read-only with an invalid intersection icon, allowing users to see that the intersection exists but cannot be populated.

### 2. `Suppress Missing Blocks` vs. `Cell-Level Security`
- When a user has `DENY` permission via CLS on a sparse intersection:
  - Essbase treats the cell as protected.
  - If **Suppress Missing Blocks** or **Suppress #Missing Data** is active, and all accessible cells in the row are `#Missing`, but a denied cell contains physical data:
    - **Security Rule**: The row **WILL BE SUPPRESSED** if the user has no read permission to the underlying data.
    - EPM Cloud prevents information leakage: A user cannot infer the presence of hidden numbers by seeing an un-suppressed row with `#NoAccess`.

---

## 6. Groovy Rules Interaction with CLS and VIC

When leveraging Groovy Business Rules on forms (`operation.grid`), script authors must handle CLS and VIC flags explicitly to prevent runtime calculation errors or security bypass attempts:

```groovy
/* Check Cell-Level Security and Valid Intersection status in Groovy */
operation.grid.dataCellIterator { DataCell cell ->
    // Check if the cell is an invalid business intersection
    if (cell.crossesInvalidIntersection()) {
        println("Skipping cell at: ${cell.getMemberNames()} - Invalid Intersection")
        return // Skip calculation logic
    }

    // Check if the cell is locked by Cell-Level Security
    if (cell.isReadOnly()) {
        println("Cell at: ${cell.getMemberNames()} is Read-Only due to CLS or Form Property")
        return
    }

    // Process valid, editable data cell
    if (cell.isEdited()) {
        Double currentVal = cell.data as Double
        if (currentVal < 0) {
            // Throw user-friendly validation error back to the Form UI
            throwVetoException("Negative values are not permitted for ${cell.getAccountName()}.")
        }
    }
}
```

### Groovy Methods Reference

- `cell.crossesInvalidIntersection()`: Returns `boolean`. `true` if the cell coordinate violates any active Valid Intersection rule.
- `cell.isReadOnly()`: Returns `boolean`. Evaluates all 6 stages of the security pipeline; returns `true` if write-access is blocked by CLS, Scenario locking, or member properties.
- `cell.isHasAccess()`: Returns `false` if CLS `DENY` rule obscures the cell.

---

## 7. Performance Architecture: The Cartesian Rule Danger

### The Risk of Cartesian Explosion in CLS
Unlike native Essbase security filters that compile directly into index boundary trees, CLS rules are evaluated dynamically by the EPM application server:

$$\text{Evaluation Overhead} = \prod_{i=1}^{N} \text{Members in CLS Rule Definition}_i \times \text{Rows on Form} \times \text{Columns on Form}$$

If a CLS rule defines:
- Entity: `@IDESC(Total_Entity)` (1,000 members)
- Account: `@IDESC(Gross_Margin)` (500 members)
- Cost Center: `@IDESC(Total_CC)` (200 members)

The application server must maintain an in-memory resolution set of:

$$1,000 \times 500 \times 200 = 100,000,000 \text{ coordinate checks}$$

### Best-Practice Architecture Guidelines

1. **Use Anchor Dimensions in Valid Intersections**:
   - Always choose the dimension with the fewest active members as the **Anchor Dimension** (e.g., `Scenario` or `Version` rather than `Account` or `Entity`).
   - The validation engine only checks sub-rules when the anchor member is encountered in the grid.
2. **Prefer Member-Level Security over CLS where possible**:
   - If an entire Cost Center or Entity should be read-only for a group, assign Read access in **Access Control** (Essbase filter level).
   - Reserve CLS strictly for **matrix intersections** (e.g., User can write to Entity A for OpEx accounts, but read-only for CapEx accounts).
3. **Limit Overlapping CLS Rules**:
   - Keep CLS rule sets per application under 50 rules. Excessive rules generate massive memory caches during user session initialization, causing form load latency to spike from 1.2s to 18s+.

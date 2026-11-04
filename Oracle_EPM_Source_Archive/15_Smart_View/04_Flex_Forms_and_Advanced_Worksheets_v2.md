# 04 — Flex Forms, Supporting Detail, & Advanced Worksheets

---

## 4.1 The Flex Form Revolution

For years, the biggest complaint from corporate finance teams about Oracle Hyperion Planning was: *"When I open a data form in Excel, Smart View locks the sheet. I cannot insert rows, sort columns, or delete lines I don't care about!"*

**Flex Forms** solve this problem by combining the structured metadata validation of a web form with the complete free-form flexibility of Microsoft Excel.

```
┌──────────────────────────────────────┬──────────────────────────────────────┐
│        TRADITIONAL SMART VIEW FORM   │               FLEX FORM              │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ • Sheet is locked and protected.     │ • Full native Excel freedom.         │
│ • Cannot insert new rows or members. │ • Insert, copy, paste new members.   │
│ • Excel Sort and Filter are disabled.│ • Use Excel AutoFilter and Sorting.  │
│ • Deleting a row corrupts the form.  │ • Delete unneeded rows freely.       │
│ • Rigid, static presentation.        │ • Submit Data validates & saves all. │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

---

## 4.2 How Flex Forms Work Behind the Scenes

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FLEX FORM SUBMISSION PIPELINE                   │
├────────────────────────────────────────────────────────────────────────┤
│ 1. USER OPENS FLEX FORM IN SMART VIEW                                  │
│    └── Form retrieves default members: [Dept 101, Dept 102]            │
│                                                                        │
│ 2. USER MODIFIES EXCEL SHEET                                           │
│    ├── Inserts new row: Types "Dept 103"                               │
│    ├── Deletes row: Deletes "Dept 102"                                 │
│    └── Uses Excel Filter: Filters only accounts > $50,000              │
│                                                                        │
│ 3. USER CLICKS "SUBMIT DATA"                                           │
│    ├── Smart View scans modified grid coordinates                      │
│    ├── Validates that "Dept 103" is a valid member in the cube         │
│    ├── Ignores the deleted row (does not delete data in Essbase)       │
│    └── Submits modified numbers directly into Essbase .PAG blocks      │
└────────────────────────────────────────────────────────────────────────┘
```

### Enabling Flex Forms:
* In the Form Designer (**Form Properties $\rightarrow$ Smart View Options**):
  * Check **`Enable flex form for rows`**.
  * Check **`Enable flex form for columns`**.
  * Check **`Show invalid members for flex form`** (flags misspelled typed members in red/yellow).

---

## 4.3 Supporting Detail Schedules

When a planner enters **\$120,000** for Travel Expense, an auditor or CFO will ask: *"What makes up this \$120,000—*
* **Supporting Detail** allows planners to attach a hierarchical micro-calculation schedule directly to a single cell:

```
[CELL: Travel Expense = $120,000]
  │
  └── Supporting Detail Schedule:
      ├── [+] Flights: 10 trips * $1,200      = $12,000
      ├── [+] Hotels: 50 nights * $200        = $10,000
      ├── [+] Trade Show Booth in Las Vegas   = $80,000
      └── [+] Client Dinners & Catering       = $18,000
      ─────────────────────────────────────────────────
      TOTAL ACCUMULATED CELL VALUE            = $120,000
```

### Operations in Smart View:
* Right-click cell $\rightarrow$ **Smart View $\rightarrow$ Supporting Detail**.
* Add sibling or child rows.
* Select operators: `+` (Add), `-` (Subtract), `*` (Multiply), `/` (Divide).
* The parent cell automatically recalculates and becomes **Read-Only** (derived from the schedule).

---

## 4.4 Cell Comments, History, & Document Attachments

1. **Cell Comments**:
   * Right-click cell $\rightarrow$ **Smart View $\rightarrow$ Cell Comments**.
   * Enter textual audit explanations (e.g., *"Approved per Q3 executive committee memo"*).
   * Stored in the Planning relational database, flagged by a visual red triangle in Excel.
2. **Cell History (Audit Trail)**:
   * Right-click cell $\rightarrow$ **Smart View $\rightarrow$ Cell History**.
   * Displays the complete audit log: Date, Timestamp, User Name, Previous Value, New Value.
3. **Document Attachments**:
   * Attach contracts, vendor invoices, or Excel scratchpads (.PDF, .XLSX, .DOCX) directly to a cell intersection.

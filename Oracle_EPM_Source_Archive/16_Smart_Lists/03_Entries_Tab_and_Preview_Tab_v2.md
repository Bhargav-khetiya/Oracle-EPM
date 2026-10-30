# 03 — Entries Tab, Life-Cycle, & The Preview Tab

---

## 3.1 The Entries Tab

While the **Properties Tab** defines the structural rules of the Smart List, the **Entries Tab** is where the actual values are defined.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        ENTRIES TAB GRID STRUCTURE                      │
├───────┬──────────────────────────────┬─────────────────────────────────┤
│  ID   │ Name (Programmatic Key)      │ Label (User Display)            │
├───────┼──────────────────────────────┼─────────────────────────────────┤
│   1   │ Draft                        │ Draft (Under Preparation)       │
│   2   │ In_Review                    │ In Review (Submitted to VP)     │
│   3   │ Approved                     │ Approved (Board Level)          │
│   4   │ Rejected                     │ Rejected (Needs Revision)       │
└───────┴──────────────────────────────┴─────────────────────────────────┘
```

---

## 3.2 Managing Entries: Actions & Rules

1. **Add Entry**:
   * Creates a new row. If `Automatically generate ID` is enabled, Planning assigns the next highest integer.
2. **Move Up / Move Down**:
   * Changes the physical visual order in the Entries editor.
   * *Note*: If `Display Order` on the Properties tab is set to `By Label` or `By Name`, the user dropdown will ignore this physical order and sort alphabetically.
3. **Editing Labels**:
   * Modifying an entry's **Label** (e.g., changing `"Draft"` to `"Initial Draft"`) is **completely safe** and takes effect immediately. The underlying Essbase number (`1.0`) does not change.

---

## 3.3 The "Orphan ID" Risk: Why You Must Never Delete Entries

```
The Deletion Disaster:
1. FY24: User selects "Contractor" (ID = 4).
   Essbase stores 4.00000000 in .PAG.
2. FY25: Admin deletes entry "Contractor" (ID = 4) from the Smart List.
3. FY26: Auditor opens FY24 historical form.
   -> Planning reads 4.00000000 from Essbase.
   -> Scans Smart List dictionary: ID 4 NOT FOUND.
   -> Result: Cell displays the raw unmapped number "4.00" ❌.
```

> [!CAUTION]
> **Never delete a Smart List entry** if data has ever been saved against it.
> **Consultant Best Practice**: Instead of deleting, edit the label to add an inactive prefix: `[INACTIVE] Contractor`. Then use form validation rules to prevent users from selecting inactive entries in future years.

---

## 3.4 The Preview Tab

The **Preview Tab** provides an administrative sandbox to test the user experience before saving:
1. **Dropdown Behavior**: Verifies that the dropdown renders properly with the expected sort order (`ID`, `Name`, `Label`).
2. **Missing Label Verification**: Confirms that `#Missing Drop Down Label` (`"No Data"`) appears at the top of the list.
3. **Width and Truncation**: Validates that long entry labels do not truncate in standard form cell widths.

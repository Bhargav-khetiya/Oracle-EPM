# 02 — Properties Tab Exhaustive Reference

---

## 2.1 The Properties Tab: Field-by-Field Breakdown

From your supplied production HTML extraction (`smartlist.txt`):

```
┌─────────────────────────────────────────────────────────────┐
│                    SMART LIST PROPERTIES                    │
├─────────────────────────────────────────────────────────────┤
│ Smart List:                 [Demo_List                    *]│
│ Label:                      [Demo List 1                  *]│
│ Display Order:              [ID                           ▼]│
│ #Missing Drop Down Label:   [No Data                       ]│
│ #Missing Form Label:        [Drop Down Setting            ▼]│
│ Automatically generate ID:  [X] Checked                     │
│ Create From Members:        [ ] Unchecked                   │
│ Cube:                       [FinPlan (Hidden/Disabled)    ▼]│
│ Member Selection:           [Blank (Disabled)              ]│
│ Minimum Access Required:    [Read (Disabled)              ▼]│
└─────────────────────────────────────────────────────────────┘
```

### 2.1.1 Visible Tabs & Keyboard Access Keys

| Tab Name | Access Key | Status in Snapshot | Architectural Function |
| :--- | :---: | :---: | :--- |
| **Properties** | **P** (`accesskey="P"`) | **Selected** | Master configuration panel governing list identity, sorting, missing labels, and source mode. |
| **Entries** | **R** (`accesskey="R"`) | Available | Registry of numeric IDs, programmatic names, and localized display labels. |
| **Preview** | **W** (`accesskey="W"`) | Available | Administrative testing sandbox to preview rendered dropdown order and labels. |

---

### 2.1.2 Internal ADF HTML Element Registry

For automated testing and technical diagnostics, the exact underlying ADF client element IDs captured in the production HTML are:

| Field Label | ADF HTML Element ID | Control Type | Observed State in Source |
| :--- | :--- | :--- | :--- |
| **Smart List** | `zhr16500:1:slName::content` | `input type="text"` | `Demo_List` (Max 80 chars, Required `*`) |
| **Label** | `zhr16500:1:slLabel::content` | `input type="text"` | `Demo List 1` (Max 80 chars, Required `*`) |
| **Display Order** | `zhr16500:1:displayOrderId::content`| `select` | `ID` (Options: ID, Name, Label, Hierarchy) |
| **#Missing Drop Down Label** | `zhr16500:1:slMissingLabel::content`| `input type="text"` | `No Data` |
| **#Missing Form Label** | `zhr16500:1:slMissingFormLabel::content` | `select` | `Drop Down Setting` (Options: Drop Down Setting, Form Setting) |
| **Automatically generate ID**| `zhr16500:1:slAutoGenId::content` | `input type="checkbox"` | Checked (`value="t"`) |
| **Create From Members** | `zhr16500:1:slFromMbrCb::content` | `input type="checkbox"` | Unchecked (`value="t"`) |
| **Cube** | `zhr16500:1:slPlanType::content` | `select` | Disabled, row hidden (`display:none`, `p_AFDisabled`), value: `FinPlan` |
| **Member Selection** | `zhr16500:1:slMember::content` | `input type="text"` | Blank, Disabled; Link: `zhr16500:1:msLink` (Disabled) |
| **Minimum Access Required** | `zhr16500:1:slMinimumAccessReqd::content`| `select` | Disabled, value: `Read` (Options: None, Display, Read, Write) |
| **Help Icon** | `zhr16500:1:infoLink` | `a` link | Disabled |

---

## 2.2 Core Identifier Properties

| Property | Required— | Field Constraints | Consultant Best Practice |
| :--- | :---: | :--- | :--- |
| **`Smart List`** | **Yes** (`*`) | Max 80 characters. Alphanumeric characters and underscores (`_`) **only**. No spaces or punctuation. | The programmatic name referenced in Calc Manager scripts: `IF ("Employee_Type" == [[Employee_Type.Full_Time]])`. |
| **`Label`** | **Yes** (`*`) | Max 80 characters. Free-form text. Spaces and special characters **allowed**. | Descriptive title displayed in administrative menus and form designer panels. |

---

## 2.3 Display Order: Deep Sorting Comparison

The **Display Order** dropdown dictates how entries are sorted when a user clicks the dropdown in a web form or Smart View:

```
Sample Entries:
  • ID: 3  | Name: Contract   | Label: C - Independent Contractor
  • ID: 1  | Name: FullTime   | Label: A - Full-Time Employee
  • ID: 2  | Name: PartTime   | Label: B - Part-Time Employee
```

| Display Order Setting | Dropdown Sequence Presented to Planner | Why Use This Option— |
| :--- | :--- | :--- |
| **`By ID`** *(Selected in extract)* | 1. A - Full-Time Employee (ID 1)<br>2. B - Part-Time Employee (ID 2)<br>3. C - Independent Contractor (ID 3) | **Sequential / Process Workflows**: Ideal when IDs represent a progression (e.g., Draft $\rightarrow$ Review $\rightarrow$ Approved). |
| **`By Name`** | 1. Contract (Name)<br>2. FullTime (Name)<br>3. PartTime (Name) | Alphabetical sorting by back-end programmatic name. |
| **`By Label`** | 1. A - Full-Time Employee (Label)<br>2. B - Part-Time Employee (Label)<br>3. C - Independent Contractor (Label) | **User Usability**: Standard alphabetical sorting based on what the user sees. |
| **`Hierarchy`** | Arranged in parent-child indentation | Used exclusively when Smart List is built using **Create From Members**. |

---

## 2.4 Missing Value Labels: Dropdown vs. Form Setting

A critical user-experience configuration governing blank cells:

```
┌──────────────────────────────────────┬──────────────────────────────────────┐
│       #MISSING DROP DOWN LABEL       │        #MISSING FORM LABEL           │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ Text that appears INSIDE the active  │ How the cell appears BEFORE the user │
│ dropdown list to clear the cell.     │ clicks it, when the cell is blank.   │
│ Example in extract: "No Data"        │ Options:                             │
│ When clicked: Sets Essbase to #MISSING│ • Drop Down Setting: Shows "No Data" │
│                                      │ • Form Setting: Defers to form blank │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

1. **`#Missing Drop Down Label`** (Set to `"No Data"` in extract):
   * When a user wants to un-assign or clear an existing selection, they click the dropdown and choose `"No Data"`.
   * Planning clears the cell and writes `#MISSING` back to the Essbase data block.
2. **`#Missing Form Label`**:
   * **`Drop Down Setting`**: The cell displays `"No Data"` in gray text before the user even clicks it. This signals to planners that a selection is required.
   * **`Form Setting`**: Defers to the form's global missing setting (typically rendering the cell as completely empty/blank).

---

## 2.5 Automatically Generate ID: Dev vs. Prod Best Practice

* **Checked (`t` in extract)**:
  * When an administrator adds new entries, Planning automatically assigns IDs sequentially: `1, 2, 3, 4, 5...`
  * *Best for*: Rapid initial development and simple static lists.
* **Unchecked**:
  * The administrator must manually type the numeric ID for every entry.
  * *Consultant Best Practice for Production*: **Uncheck this box in multi-environment architectures**. If Dev has `Full-Time = 1` and `Part-Time = 2`, but an administrator in Test adds `Part-Time` first (`ID = 1`) and `Full-Time` second (`ID = 2`), migrating data between environments via LCM or Data Management will completely scramble employee classifications.

---

## 2.6 Create From Members: Dynamic Outline Synchronization

When `Create From Members` is **Checked**:
1. Planning dynamically populates the Smart List directly from the members of an existing dimension.
2. **`Cube`** (`FinPlan`, `EPBCS`, `Manpower`, `Capital`) and **`Member Selection`** become enabled.
3. *Example*: A Smart List named `SL_Department` dynamically inherits all children of `Total Department`.
4. *Benefit*: Eliminates double-maintenance. Adding a new department automatically updates the Smart List dropdown.
5. *Why Disabled in Extract*: In your HTML extraction, `Create From Members` is **Unchecked**, which naturally disables the `Cube` and `Member Selection` fields.

---

## 2.7 Minimum Access Required

* **Options**: `None`, `Display`, `Read`, `Write`.
* Dictates the minimum Planning security role required to view and select entries from this Smart List.
* *Why Disabled in Extract*: When `Create From Members` is unchecked, security is governed at the form and cell level, locking this setting to `Read`.

# 01 — Smart Lists Architecture & Storage Physics

---

## 1.1 The Underlying Problem: Text in a Multidimensional Engine

Oracle EPM's underlying storage and calculation engine is **Oracle Essbase**, an OLAP database optimized strictly for high-speed multi-dimensional floating-point calculations.
* In an Essbase Block Storage (BSO) or Aggregate Storage (ASO) cube, every data cell inside a `.PAG` data file is a **64-bit IEEE 754 double-precision floating-point number (8 bytes)**.
* Essbase has **no native text string storage engine** for data cells.
* If a business process requires a user to select an operational status (e.g., `Draft`, `In Review`, `Approved`) or an employee type (e.g., `Full-Time`, `Contractor`), Essbase cannot write the string `"Approved"` into the data block.

---

## 1.2 The Solution: The Smart List Translation Layer

A **Smart List** is a metadata bridge that translates between user-facing text strings and underlying database numbers:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        SMART LIST TRANSLATION FLOW                     │
├────────────────────────────────────────────────────────────────────────┤
│ 1. ADMINISTRATOR DEFINITION:                                           │
│    Creates Smart List "Project_Status":                                │
│      • Entry ID 1 = "Draft"                                            │
│      • Entry ID 2 = "In Review"                                        │
│      • Entry ID 3 = "Approved"                                         │
│                                                                        │
│ 2. USER INTERFACE (Web Form / Smart View):                             │
│    User clicks cell -> Planning intercepts the cell ->                 │
│    Renders dropdown: ["Draft", "In Review", "Approved"]                │
│    User selects "Approved".                                            │
│                                                                        │
│ 3. PERSISTENCE IN ESSBASE (.PAG File on Disk):                         │
│    Planning writes the double-precision float:                         │
│    [Account: Status, Entity: East, Period: Jan] = 3.00000000           │
│                                                                        │
│ 4. SUBSEQUENT RETRIEVAL:                                               │
│    Planning reads 3.00000000 from Essbase -> Looks up dictionary ->    │
│    Renders "Approved" in the user's browser.                           │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 1.3 The 3 Internal Identifiers of a Smart List Entry

Every Smart List entry contains three distinct properties:

| Identifier | Technical Nature | Where Used | Can It Change? |
| :--- | :--- | :--- | :--- |
| **`ID`** | Integer (stored as 8-byte float in Essbase) | Physical `.PAG` disk storage, calculation comparisons | **NEVER change an ID** once historical data exists! |
| **`Name`** | Programmatic string (alphanumeric, no spaces) | Calc Manager business rules, Groovy scripts, Data Maps | Stable programmatic reference. |
| **`Label`** | User-friendly display text (spaces allowed) | Web forms, Financial Reports, Smart View dropdowns | Can be modified freely without corrupting stored data. |

---

## 1.4 The Golden Rule: Dimension Evaluation Order

In a multidimensional database, a cell is the intersection of all dimensions:
* **Account Dimension** says: *"I am a Smart List."*
* **Currency Dimension** says: *"I am USD currency."*
* **Scenario Dimension** says: *"I am Unspecified numeric."*

```
       WITHOUT EVALUATION ORDER:
       Currency (Rank 1) Overrides Account -> Cell renders: "$3.00" ❌

       WITH EVALUATION ORDER (CORRECT):
       Account (Rank 1) Evaluates First   -> Cell renders: "Approved" ✅
```

> [!CRITICAL]
> If a Smart List displays as a raw number (e.g., `1.00`, `2.00`) or currency formatted number (`$1.00`) instead of a dropdown, **Evaluation Order is misconfigured**.
> **Resolution**: Navigate to **Application $\rightarrow$ Overview $\rightarrow$ Dimensions $\rightarrow$ Evaluation Order**. Set the dimension containing the Smart List (typically **Account**) to **Rank 1**.

# Administering Data Management (FDMEE) — Complete Markdown Edition

> **Original PDF:** `Administering_Data_Management.pdf` | **Folder:** Level 4 (Integration & Automation)  
> **Purpose:** Complete Markdown extraction of legacy Data Management (`FDMEE Web UI`), covering import formats, logic accounts, check rules, and batch processing.

---

## Table of Contents
1. [Legacy Data Management Architecture](#architecture)
2. [Import Formats, Locations & Data Load Rules](#load-rules)
3. [Logic Accounts & Validation Check Rules](#logic-accounts)
4. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Legacy Data Management Architecture <a name="architecture"></a>

Accessed via `Navigator -> Data Management`. Stores data in an internal staging repository (`TDATASEG_T`).

---

## 2. Import Formats, Locations & Data Load Rules <a name="load-rules"></a>

- **Import Formats:** Defines column positions (`Column 1 = Account, Column 2 = Amount`) for delimited text files.
- **Locations:** Ties Import Formats to Target Applications and specifies functional data load owners.

---

## 3. Logic Accounts & Validation Check Rules <a name="logic-accounts"></a>

- **Logic Accounts:** Generates derived data lines inside the staging table prior to cube upload (`e.g., creating an automated Debit/Credit balancing row`).
- **Check Rules (`Validation Engine`):** Verifies accounting integrity (`e.g., Total Assets must equal Total Liabilities + Equity`). If check fails, export to cube is blocked with a red flag.

---

## 4. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`11_Data_Integration/01_Data_Integration_Complete_Guide.md`** — FDMEE to Data Integration transition table.

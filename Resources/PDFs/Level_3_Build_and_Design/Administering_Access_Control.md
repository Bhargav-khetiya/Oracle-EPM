# Administering Access Control — Complete Markdown Edition

> **Original PDF:** `Administering_Access_Control.pdf` | **Folder:** Level 3 (Build & Design)  
> **Purpose:** Comprehensive Markdown reference covering EPM Cloud security architecture, IDCS groups, application roles, Cell-Level Security (`Valid Intersections`), and access auditing.

---

## Table of Contents
1. [IDCS / OCI IAM Integration & Synchronization](#idcs-sync)
2. [Managing Users, Groups & Application Roles](#manage-roles)
3. [Cell-Level Security: Assign Security vs. Valid Intersections](#cell-security)
4. [Security Migration via LCM & CSV Import](#security-migration)
5. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. IDCS / OCI IAM Integration & Synchronization <a name="idcs-sync"></a>

Oracle EPM Cloud authenticates natively against **Oracle Cloud Infrastructure Identity and Access Management (`OCI IAM` / formerly `IDCS`)**.
- **Best Practice:** Never assign individual human users directly to EPM application roles. Always create **AD / IDCS Groups** (`e.g., EPM_FPNA_Analyst_Group`) and assign the EPM role to the group!

---

## 2. Managing Users, Groups & Application Roles <a name="manage-roles"></a>

Inside `Tools -> Access Control`:
- **Manage Users:** Displays user email, status (`Active vs. Inactive`), and assigned groups.
- **Role Assignment Hierarchy:** If a user belongs to two groups where one has `Power User` and one has `User`, EPM Cloud applies **Role Super-Set Rules** (the user receives `Power User` privileges).

---

## 3. Cell-Level Security: Assign Security vs. Valid Intersections <a name="cell-security"></a>

| Security Mechanism | Where Configured | What It Controls |
| :--- | :--- | :--- |
| **Dimension Member Security (`Assign Security`)** | `Create and Manage -> Dimensions -> Assign Security` | Grants `Read`, `Write`, or `None` access to specific branches of a dimension (`e.g., Group A gets Write access to Cost Center 100-199`). |
| **Valid Intersections** | `Application -> Valid Intersections` | Defines valid structural combinations (`e.g., Entity US_01 can ONLY select US Dollar currency`). Prevents invalid data entry across the entire app. |

---

## 4. Security Migration via LCM & CSV Import <a name="security-migration"></a>

- Administrators can export security assignments (`secfile.csv`) via EPM Automate (`exportSecurity / importSecurity`) to synchronize cell security across Test and Prod pods in seconds.

---

## 5. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`12_Security/01_Security_Complete_Guide.md`** — Comprehensive security matrix and step-by-step group setup.
- **`24_Architect_Masterclass/08_The_Complete_Error_Code_Encyclopedia.md`** — `#NoAccess` (`HSP-10115`) troubleshooting.

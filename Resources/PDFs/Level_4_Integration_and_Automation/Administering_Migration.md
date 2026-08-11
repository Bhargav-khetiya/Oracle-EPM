# Administering Migration (LCM) — Complete Markdown Edition

> **Original PDF:** `Administering_Migration.pdf` | **Folder:** Level 4 (Integration & Automation)  
> **Purpose:** Definitive Markdown companion covering Lifecycle Management (`LCM`), snapshot export/import, artifact granularity, and automated backup governance.

---

## Table of Contents
1. [Lifecycle Management (`LCM`) Architecture & Artifact Categories](#lcm-architecture)
2. [Snapshot Exports, Imports & Selective Restoration](#snapshot-operations)
3. [Automated Nightly Backups & EPM Automate Scripts](#automated-backups)
4. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Lifecycle Management (`LCM`) Architecture & Artifact Categories <a name="lcm-architecture"></a>

Inside `Tools -> Migration`:
- **Artifact Categories:** `Global Artifacts (`Security, Variables, Substitution Variables`)` and `Application Artifacts (`Calculation Manager Rules, Forms, Dimensions, Data Maps`)`.

---

## 2. Snapshot Exports, Imports & Selective Restoration <a name="snapshot-operations"></a>

- **Selective Restoration:** If an administrator accidentally deletes a single web form, they can open yesterday's snapshot (`Artifact Snapshot`), drill down into `Forms -> Department Expense Form`, select just that single item, and restore it in 10 seconds without resetting the rest of the application!

---

## 3. Automated Nightly Backups & EPM Automate Scripts <a name="automated-backups"></a>

```bash
# EPM Automate Automated Nightly Snapshot Download Script
epmautomate login svc_admin@company.com key.epw https://epbcs.oraclecloud.com
epmautomate downloadFile "Artifact Snapshot" C:/Backups/EPBCS_Snapshot_%DATE%.zip
epmautomate logout
```

---

## 4. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`16_Administration/01_Administration_Complete_Guide.md`** — Complete migration checklists.

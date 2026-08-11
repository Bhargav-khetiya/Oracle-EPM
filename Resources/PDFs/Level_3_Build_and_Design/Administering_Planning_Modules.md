# Administering Planning Modules — Complete Markdown Edition

> **Original PDF:** `Administering_Planning_Modules.pdf` | **Folder:** Level 3 (Build & Design)  
> **Purpose:** Definitive Markdown guide for configuring, enabling features, mapping drivers, and customizing business logic across the 4 OOTB Oracle Planning Modules (`Financials, Workforce, Capital, Projects`).

---

## Table of Contents
1. [Incremental Enablement & Feature Configuration](#incremental-enablement)
2. [Financials Module Administration: Driver Framework & Accounts](#financials-admin)
3. [Workforce Module Administration: Benefits, Taxes & Merit Matrix](#workforce-admin)
4. [Capital & Projects Module Configuration Rules](#capital-projects-admin)
5. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Incremental Enablement & Feature Configuration <a name="incremental-enablement"></a>

Inside `Application -> Configure -> [Module Name] -> Enable Features`:
- **Architect Golden Rule:** Feature enablement is **Incremental and Permanent**. Once you enable a feature (`e.g., Employee-Level Compensation` or `Multi-Currency Projects`), you **CANNOT disable it or delete the generated metadata dimensions** without wiping and rebuilding the entire EPM application! Always enable minimal features during initial setup.

---

## 2. Financials Module Administration: Driver Framework & Accounts <a name="financials-admin"></a>

- **Configuring Drivers:** Administrators map standard account names (`OFS_Revenue_Driver`) to target P&L lines.
- **Rolling Forecast Setup:** Enable 12, 18, or 24-month continuous rolling horizons that cross fiscal year boundaries (`e.g., FY26 Q4 -> FY27 Q3`).

---

## 3. Workforce Module Administration: Benefits, Taxes & Merit Matrix <a name="workforce-admin"></a>

- **Benefits & Taxes Wizard:** Configure tiered tax limits (`FICA Social Security cap at $168,600`) and monthly medical benefit rates (`Single vs. Family coverage`).
- **Merit Matrix:** Map performance rating tiers (`Exceeds Expectations = 5% increase`, `Meets = 3%`) tied directly to merit effective months.

---

## 4. Capital & Projects Module Configuration Rules <a name="capital-projects-admin"></a>

- **Capital:** Set asset class useful life (`Depreciation years`) and salvage value thresholds.
- **Projects:** Configure project types (`Capital, Contract, Indirect`) and revenue recognition rules (`Percentage of Completion vs. Milestone`).

---

## 5. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`03_Planning_Modules/01_OOTB_Modules_Deep_Reference.md`** — Complete technical driver tables for all 4 modules.
- **`24_Architect_Masterclass/01_The_Springboard_and_Settings_Map.md`** — Module configuration properties.

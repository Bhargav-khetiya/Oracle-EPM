# Designing with Calculation Manager — Complete Markdown Edition

> **Original PDF:** `Designing_with_Calculation_Manager.pdf` | **Folder:** Level 3 (Build & Design)  
> **Purpose:** The definitive Markdown master guide covering Oracle Calculation Manager (`Calc Manager`), visual rule designers, native Essbase scripts, templates, runtime prompts, and CDF functions.

---

## Table of Contents
1. [Calc Manager Architecture: Rules, Components & Templates](#architecture)
2. [Writing Native Essbase BSO Scripts (`FIX`, `CALC`, `IF`)](#native-scripts)
3. [Groovy Rules inside Calculation Manager](#groovy-rules)
4. [Runtime Prompts (`RTPs`) & Design-Time Variables](#rtps)
5. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Calc Manager Architecture: Rules, Components & Templates <a name="architecture"></a>

- **Rules:** The executable script attached to forms or jobs (`e.g., Calculate_Overhead`).
- **Templates:** Reusable macro blocks (`e.g., Allocation Template`) that can be inserted into dozens of different rules.

---

## 2. Writing Native Essbase BSO Scripts (`FIX`, `CALC`, `IF`) <a name="native-scripts"></a>

```essbase
/* ELITE BSO CALCULATION SCRIPT SYNTAX */
FIX ("Actual", "Final", @RELATIVE("Total_Cost_Centers", 0))
    FIX ("FY26", @RELATIVE("Total_Periods", 0))
        "Total_Overhead" (
            IF ("Direct_Labor" > 0)
                "Total_Overhead" = "Direct_Labor" * 0.15;
            ENDIF
        )
    ENDFIX
ENDFIX
```
- **Architect Rule:** Always nest `FIX` statements by dimension sparse/dense characteristics, and place `CLEARBLOCK EMPTY;` at the end of scripts generating sparse blocks!

---

## 3. Groovy Rules inside Calculation Manager <a name="groovy-rules"></a>

In EPM Enterprise Cloud, administrators toggle `Script Type: Groovy` inside Calc Manager to unleash object-oriented Java/Groovy execution (`512MB heap limit`).

---

## 4. Runtime Prompts (`RTPs`) & Design-Time Variables <a name="rtps"></a>

- **RTP Variables:** Syntax inside native scripts uses square brackets: `[Target_Year]` and `[Target_Entity]`.
- **Validation:** Always set limits (`@RELATIVE("Total_Company", 0)`) inside Variable Designer to block parent selection.

---

## 5. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`05_Calculation_Manager/01_Calc_Manager_Design.md`** — Core Calc Manager design patterns.
- **`24_Architect_Masterclass/04_The_Dark_Arts_of_Performance.md`** — Native performance tuning.

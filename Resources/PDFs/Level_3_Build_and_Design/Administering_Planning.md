# Administering Planning — Complete Markdown Edition

> **Original PDF:** `Administering_Planning.pdf` | **Folder:** Level 3 (Build & Design)  
> **Purpose:** The definitive 800+ page master administration reference extracted into structured Markdown. Covers cube creation, dimension management, forms design, variables, data maps, and database restructuring.

---

## Table of Contents
1. [Application Creation & Cube Properties](#app-creation)
2. [Dimension Management & Hierarchy Properties](#dimensions)
3. [User Variables vs. Substitution Variables](#variables)
4. [Smart Push & Data Map Architecture](#data-maps)
5. [Database Restructuring (`Cube Refresh`) Mechanics](#restructuring)
6. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Application Creation & Cube Properties <a name="app-creation"></a>

When creating an application, administrators choose currency options (`Single vs. Multi-Currency`) and storage rules (`Hybrid BSO`).
- **Cube Properties Table:** Set `Dynamic Calc Cache Size` and `Index Cache Size` under `Application -> Overview -> Actions -> Performance Settings`.

---

## 2. Dimension Management & Hierarchy Properties <a name="dimensions"></a>

- **Data Storage Operators:** `Store` (Physical block), `Dynamic Calc` (RAM calculation), `Dynamic Calc and Store` (Calculate on first read and cache—**Architect Warning: Avoid in cloud grids**), `Never Share`, `Label Only`.
- **Two Pass Calculation:** Must be checked on dynamic account formulas (`Gross Margin %`) to ensure they evaluate *after* the initial dense block consolidation pass.

---

## 3. User Variables vs. Substitution Variables <a name="variables"></a>

| Variable Type | Scope & Persistence | Example Use Case |
| :--- | :--- | :--- |
| **Substitution Variable** | Global (`App/Cube level`). Set by administrator (`Tools -> Variables`). Applies uniformly across all users. | `CurrYear = FY26`, `CurrMonth = Mar` |
| **User Variable** | Individual (`User level`). Each planner selects their own personal value in `User Preferences`. | `MyDepartment = CC_109`, `MyEntity = US_Retail` |

---

## 4. Smart Push & Data Map Architecture <a name="data-maps"></a>

- **Data Maps (`Application -> Data Exchange -> Data Maps`):** Maps dimensions between source BSO (`FinPlan`) and target ASO (`Reporting`).
- **Smart Push:** Attaches the Data Map directly to a web form (`Form Properties -> Smart Push -> Run After Save`), pushing *only the modified POV intersections* in `< 0.3s`.

---

## 5. Database Restructuring (`Cube Refresh`) Mechanics <a name="restructuring"></a>

When administrators click **Refresh Database**, EPM Cloud compares relational dimension tables against Essbase `.otl` outlines:
- **Fast Refresh (No Restructure):** Adding a `Store` child member at the bottom of a sparse hierarchy (`Takes 5 seconds`).
- **Dense Restructure (Full Block Rewrite):** Adding, deleting, or renaming a `Store` member in a **Dense dimension** (`Account` or `Period`). Essbase physically recreates every single `.pag` data block on the hard drive (`Can take 1-4 hours on large cubes!`).

---

## 6. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`01_Essbase_Core/01_BSO_vs_ASO_Deep_Dive.md`** — Storage operators and block math.
- **`05_Calculation_Manager/01_Calc_Manager_Design.md`** — Two pass rules.
- **`24_Architect_Masterclass/02_Essbase_Under_The_Hood.md`** — Physical restructuring mechanics.

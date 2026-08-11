# Design Best Practices for Oracle EPM Cloud — Complete Markdown Edition

> **Original PDF:** `Design_Best_Practices.pdf` | **Folder:** Level 1 (Beginner & Foundations)  
> **Purpose:** Complete Markdown extraction of official Oracle design standards for cube sizing, dimension order, form optimization, and calculation performance.

---

## Table of Contents
1. [Cube Architecture: BSO vs. ASO vs. Hybrid BSO](#cube-architecture)
2. [Dimension Order & Sparse/Dense Optimization](#dimension-order)
3. [Web Form & Smart View Design Standards](#form-design)
4. [Calculation & Business Rule Optimization Rules](#calc-optimization)
5. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Cube Architecture: BSO vs. ASO vs. Hybrid BSO <a name="cube-architecture"></a>

Oracle strictly mandates **Hybrid BSO** for all modern financial planning cubes (`FinPlan`, `Workforce`, `Capex`).

### Storage Rules
- **Dense Dimensions:** Always set `Account` and `Period` as **Dense** (`Block Size range: 50 KB - 200 KB`).
- **Sparse Dimensions:** All organizational and transactional dimensions (`Entity`, `Cost Center`, `Product`, `Project`) must be **Sparse**.
- **Reporting Optimization:** Always push completed BSO data into an **ASO Reporting Cube** using `Smart Push` / `Data Maps` for instantaneous high-concurrency reporting.

---

## 2. Dimension Order & Sparse/Dense Optimization <a name="dimension-order"></a>

The physical order of dimensions inside `Create and Manage -> Dimensions` dictates index efficiency and calculation speed.

### Recommended BSO Dimension Order (Top to Bottom)
1. **Time / Year (Sparse - Smallest count)** (`FY23, FY24...`)
2. **Scenario / Version (Sparse - Small count)** (`Actual, Budget...`)
3. **Entity / Cost Center (Sparse - Medium/Large count)** (`CC_100, CC_200...`)
4. **Product / Project / Custom (Sparse - Largest count)** (`SKU_10001...`)
5. **Account (Dense)** (`Revenue, Opex...`)
6. **Period (Dense)** (`Jan, Feb, Mar...`)

---

## 3. Web Form & Smart View Design Standards <a name="form-design"></a>

- **Suppress Missing Blocks:** **ALWAYS check this box** on forms and grid properties (`Suppress Missing Blocks`). It forces Essbase to ignore non-existent physical blocks, dropping query times from 30+ seconds to sub-second.
- **POV vs. Page vs. Rows:** Keep rows to `< 100 leaf members` per page. Move static dimensions (`Year`, `Scenario`, `Version`, `Currency`) to the **POV Bar** or **Page Dropdown**.

---

## 4. Calculation & Business Rule Optimization Rules <a name="calc-optimization"></a>

- **Never `CALC ALL` on Hybrid Cubes:** Do not run `AGG` across upper-level sparse members in Hybrid BSO; let dynamic calculation handle rollups in RAM.
- **Right-Side Cross-Dimensionals:** Never put `->` (`Cross-Dimensional pointer`) on the left side of an equation inside `FIX`. Always put `->` on the right side.

---

## 5. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`00_Foundation/05_Design_Best_Practices_Oracle_Reference.md`** — Core architectural rules.
- **`15_Performance/01_Performance_Complete_Guide.md`** — BSO/ASO tuning algorithms.
- **`24_Architect_Masterclass/02_Essbase_Under_The_Hood.md`** — $2^{32}$ block limits and indexing math.

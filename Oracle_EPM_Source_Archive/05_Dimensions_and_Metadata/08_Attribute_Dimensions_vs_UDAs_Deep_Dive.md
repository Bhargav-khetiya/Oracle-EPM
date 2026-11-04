# 08 — Attribute Dimensions vs. UDAs: Deep Architecture

---

## 8.1 The Multidimensional Slicing Challenge

In financial and operational planning, reporting requires analyzing data along descriptive member characteristics (e.g., slicing Products by *Color*, *Package Type*, or *Size*; slicing Employees by *Exempt/Non-Exempt* or *Union Status*).

Architects have two primary tools to achieve this:
1. **User-Defined Attributes (UDAs)**: Lightweight text tags attached to outline members.
2. **Attribute Dimensions**: Dynamic, secondary multidimensional hierarchies linked to base sparse dimensions.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        UDA vs. ATTRIBUTE DIMENSION                     │
├──────────────────────────────────┬─────────────────────────────────────┤
│   USER-DEFINED ATTRIBUTES (UDA)  │         ATTRIBUTE DIMENSIONS        │
├──────────────────────────────────┼─────────────────────────────────────┤
│ • Flat text string tag.          │ • True multidimensional hierarchy.  │
│ • No parent-child rollup tree.   │ • Aggregates data dynamically       │
│ • Cannot be placed on form axes  │   (e.g., Total Red = $1,500,000).   │
│   (cannot pivot or slice).       │ • Can be dragged to Row, Column,    │
│ • Exclusively used in Calc       │   POV, or Page in forms/Smart View. │
│   Manager rules: @ISUDA.         │ • Supports Type: Text, Numeric,     │
│ • 0 bytes disk overhead.         │   Date, and Boolean.                │
└──────────────────────────────────┴─────────────────────────────────────┘
```

---

## 8.2 Attribute Dimensions: The Storage Physics

Unlike standard dimensions, **Attribute Dimensions do NOT create physical blocks in `.PAG` files**:
* They are linked exclusively to **Sparse Dimensions** (e.g., linking `Product_Size` to `Product`).
* When an ad-hoc query places `Product_Size: Small` on rows, Essbase dynamically scans the base `Product` sparse index (`.IND`), identifies all products mapped to `Small`, and dynamically sums their values in the **Dynamic Calc Cache**.
* **Zero disk bloat**: Slicing across 10 attribute dimensions does not increase database size by a single byte!

---

## 8.3 Attribute Data Types

Oracle EPM supports 4 distinct Attribute data types:

| Attribute Type | Description | Practical Use Case | Query Capability |
| :--- | :--- | :--- | :--- |
| **`Text`** | Categorical strings | `Product_Color: Red, Blue, Green` | Exact match filtering |
| **`Numeric`** | Numeric values | `Square_Footage: 2500, 5000` | Range queries (`> 5000 AND < 10000`) |
| **`Date`** | Calendar dates | `Contract_End_Date: 2026-12-31` | Date range queries (`BEFORE`, `AFTER`) |
| **`Boolean`** | True/False binary flags | `Tax_Exempt: True, False` | Binary inclusion filtering |

---

## 8.4 Calculation Functions: Calc Manager & Essbase

### 1. Attribute Functions in Calc Scripts:
```essbase
/* Calculate only products with attribute "Premium_Brand" */
FIX(@ATTRIBUTE(Premium_Brand), "Budget", "FY26")
    "Marketing_Allocation" = "Sales" * 0.08;
ENDFIX
```

### 2. Range Queries with `@WITHATTR`:
```essbase
/* Query assets where square footage is greater than 10,000 */
FIX(@WITHATTR("Square_Footage", ">", 10000), "Actual", "FY26")
    "Maintenance_Expense" = "Base_Cost" * 1.25;
ENDFIX
```

---

## 8.5 Decision Framework: UDA vs. Attribute Dimension

```
Do users need to slice, pivot, or display this property as a column in Web Forms or Smart View—
├── YES ──► ✅ ATTRIBUTE DIMENSION (Allows dynamic ad-hoc slicing & aggregation)
└── NO  ──► Is it needed ONLY inside calculation scripts (e.g. @ISUDA in business rules)—
            ├── YES ──► ✅ USER-DEFINED ATTRIBUTE (UDA) (Lightweight, zero cache overhead)
            └── NO  ──► Use a standard Member Alias or Member Description.
```

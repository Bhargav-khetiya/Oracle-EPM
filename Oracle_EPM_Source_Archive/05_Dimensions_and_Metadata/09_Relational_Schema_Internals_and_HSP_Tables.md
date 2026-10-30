# 09 — Relational Schema Internals & The `HSP_` Database Tables

---

## 9.1 Overview: The Relational Backbone of Planning

When an administrator manages dimensions in Oracle EPM Planning, changes are **not made directly to the Essbase `.OTL` file in real time**. Instead, all dimensions, members, aliases, properties, and formulas are stored as normalized relational rows in the **Planning Relational Repository (Oracle RDBMS Schema)**.

```
┌────────────────────────────────────────────────────────────────────────┐
│                      METADATA PERSISTENCE ARCHITECTURE                 │
├────────────────────────────────────────────────────────────────────────┤
│ 1. ADMIN SAVES MEMBER IN WEB UI:                                       │
│    -> Executes SQL INSERT/UPDATE into HSP_ relational tables           │
│                                                                        │
│ 2. APPLICATION REFRESH (CUBE REFRESH):                                 │
│    -> Planning Java engine queries relational tables via JDBC          │
│    -> Constructs multidimensional tree structure in memory             │
│    -> Uses Essbase JAPI / C API to compile binary outline (.OTL)       │
│    -> Triggers Essbase restructure (.PAG / .IND)                       │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 9.2 The Core `HSP_` Relational Tables

Below is the database catalog mapping how member properties are physically stored in the relational schema:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       PLANNING RELATIONAL SCHEMA MAP                        │
├──────────────────────┬──────────────────────────────────────────────────────┤
│ HSP_OBJECT           │ Global catalog: Assigns unique OBJECT_ID to every    │
│                      │ dimension, member, form, menu, user, and folder      │
├──────────────────────┼──────────────────────────────────────────────────────┤
│ HSP_MEMBER           │ Hierarchy structure: Maps MEMBER_ID to PARENT_ID,    │
│                      │ DIM_ID, and sibling sort position                    │
├──────────────────────┼──────────────────────────────────────────────────────┤
│ HSP_ACCOUNT          │ Financial accounting properties: ACCOUNT_TYPE,       │
│                      │ TIME_BALANCE, SKIP, VARIANCE_REPORTING, RATE_TYPE    │
├──────────────────────┼──────────────────────────────────────────────────────┤
│ HSP_MEMBER_TO_       │ Multi-cube deployment: Cube enablement flags and     │
│ PLAN_TYPE            │ consolidation operators per plan type                │
├──────────────────────┼──────────────────────────────────────────────────────┤
│ HSP_ALIAS            │ Member display labels mapped to ALIAS_TABLE_ID       │
├──────────────────────┼──────────────────────────────────────────────────────┤
│ HSP_MEMBER_FORMULA   │ Calc formulas stored as text strings per cube        │
├──────────────────────┼──────────────────────────────────────────────────────┤
│ HSP_UDA_ASSIGNMENT   │ Many-to-many mapping between MEMBER_ID and UDA_ID    │
└──────────────────────┴──────────────────────────────────────────────────────┘
```

---

## 9.3 Detailed Table Schemas & Foreign Keys

### 1. `HSP_OBJECT` (The Root Catalog)
Every entity in Planning receives an immutable numeric `OBJECT_ID`:
* `OBJECT_ID`: Primary Key (e.g., `10542`).
* `OBJECT_NAME`: Internal string (e.g., `"Net Profit"`).
* `OBJECT_TYPE`: Integer code (`1 = Dimension`, `2 = Member`, `5 = Form`, `8 = Business Rule`).

### 2. `HSP_MEMBER` (Hierarchy Relationships)
* `MEMBER_ID`: Foreign Key $\rightarrow$ `HSP_OBJECT.OBJECT_ID`.
* `DIM_ID`: Foreign Key $\rightarrow$ `HSP_OBJECT.OBJECT_ID` (The parent dimension).
* `PARENT_ID`: Foreign Key $\rightarrow$ `HSP_OBJECT.OBJECT_ID` (The immediate parent member).
* `POSITION`: Integer sort order among siblings.
* `DATA_STORAGE`: Integer code (`0 = Store`, `1 = Never Share`, `2 = Label Only`, `3 = Shared`, `4 = Dynamic Calc`).

### 3. `HSP_ACCOUNT` (Account Accounting Intelligence)
* `MEMBER_ID`: Primary Key $\rightarrow$ `HSP_OBJECT.OBJECT_ID`.
* `ACCOUNT_TYPE`: Integer code (`1 = Expense`, `2 = Revenue`, `3 = Asset`, `4 = Liability`, `5 = Equity`, `6 = Saved Assumption`).
* `TIME_BALANCE`: Integer code (`0 = Flow`, `1 = First`, `2 = Balance`, `3 = Average`).
* `SKIP`: Integer code (`0 = None`, `1 = Missing`, `2 = Zeros`, `3 = Missing & Zeros`).
* `VARIANCE_REPORTING`: Integer code (`0 = Non-Expense`, `1 = Expense`).

### 4. `HSP_MEMBER_TO_PLAN_TYPE` (Multi-Cube Enablement)
* `MEMBER_ID`: Compound Primary Key.
* `PLAN_TYPE`: Cube ID (`1 = FinPlan`, `2 = EPBCS`, `3 = Manpower`, `4 = Capital`).
* `CONSOLIDATION_TYPE`: Operator code (`0 = Addition`, `1 = Subtraction`, `2 = Multiplication`, `3 = Division`, `4 = Percent`, `5 = Ignore`, `6 = Never`).
* `USED_IN_PLAN_TYPE`: Binary flag (`1 = Enabled/Checked`, `0 = Disabled/Unchecked`).

---

## 9.4 What Happens at the SQL Level During Maintenance

### Case A: Renaming a Member (`D10010` to `Dept_Catering`)
```sql
UPDATE HSP_OBJECT 
SET OBJECT_NAME = 'Dept_Catering' 
WHERE OBJECT_ID = 10542;
```
* **Why Planning Never Breaks Internal Links**: Because forms, task lists, and security groups store `OBJECT_ID = 10542`, **renaming a member never breaks forms or permissions**! The internal ID remains constant.

### Case B: Moving a Member to a New Parent
```sql
UPDATE HSP_MEMBER 
SET PARENT_ID = 20881, POSITION = 3 
WHERE MEMBER_ID = 10542;
```
* The member's hierarchical lineage is updated in SQL. During the next Cube Refresh, Essbase restructures the `.OTL` outline accordingly.

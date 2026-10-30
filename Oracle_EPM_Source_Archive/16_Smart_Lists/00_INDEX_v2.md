# 📖 Oracle EPM Cloud — Smart Lists: Master Architecture Bible

> **Purpose**: This directory provides an exhaustive, consultant-grade reference for Oracle EPM Cloud Planning Smart Lists. Every property, dropdown option, physical Essbase storage mechanic (8-byte IEEE floats), evaluation order rule, business rule integration, and troubleshooting diagnostic is covered in depth based on production source extractions.

---

## 📂 Document Index

| # | File | Topic & Focus Area | Technical Level |
|---|------|--------------------|-----------------|
| 00 | [00_INDEX.md](./00_INDEX.md) | Master directory index, architecture summary, and navigation guide | Overview |
| 01 | [01_Smart_Lists_Architecture_and_Storage_Physics.md](./01_Smart_Lists_Architecture_and_Storage_Physics.md) | The translation bridge, Essbase 8-byte float physics, relational metadata mapping, Evaluation Order rules | Foundation & Core |
| 02 | [02_Properties_Tab_Exhaustive_Guide.md](./02_Properties_Tab_Exhaustive_Guide.md) | Field-by-field breakdown: Display Order (ID, Name, Label, Hierarchy), #Missing Labels, Auto Generate ID, Create From Members, Minimum Access Required | Core Engineering |
| 03 | [03_Entries_Tab_and_Preview_Tab.md](./03_Entries_Tab_and_Preview_Tab.md) | Managing entries, ID stability, orphan numeric values, preview verification | Administration |
| 04 | [04_Calculation_Manager_and_Business_Rules_Integration.md](./04_Calculation_Manager_and_Business_Rules_Integration.md) | Reading and writing Smart Lists in Calc Scripts, Groovy rules, Smart Push, and Data Maps | Advanced Engineering |
| 05 | [05_Real_World_Scenarios_Troubleshooting_and_Interview_Mastery.md](./05_Real_World_Scenarios_Troubleshooting_and_Interview_Mastery.md) | 8 production scenarios, troubleshooting matrix, LCM migration, 15 consultant interview questions & answers | Best Practices & Reference |

---

## 🎯 How to Use This Guide

1. **For Fundamentals & Storage Physics**: Read `01`.
2. **For Configuration & Properties Setup**: Read `02` → `03`.
3. **For Calc Manager, Groovy & Business Rules**: Read `04`.
4. **For Implementation Scenarios & Interview Preparation**: Read `05`.

---

## 🔑 Key Architecture at a Glance

```
Essbase Data Block (.PAG file on disk)
  └── Can ONLY store 64-bit double-precision floating-point numbers.
      It has NO native text string storage engine.

The Smart List Translation Layer:
  ┌─────────────────────────────────────────────────────────────┐
  │ 1. Database Level (Essbase): Stores float 1.00000000        │
  │ 2. Relational Level (Planning): Maps ID 1 -> "Full-Time"   │
  │ 3. User Level (Web Form): Displays dropdown: "Full-Time"    │
  └─────────────────────────────────────────────────────────────┘

The Golden Evaluation Order Rule:
  └── Account dimension MUST be Rank 1 in Evaluation Order, or the
      cell will evaluate as Currency (USD) and ignore the Smart List.
```

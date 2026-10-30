# 📖 Oracle EPM Cloud — Form Properties: Master Architecture Bible

> **Purpose**: This directory serves as the exhaustive, deep-dive reference for Oracle EPM Cloud Planning Data Form Properties. Every grid property, display setting, dimension & segment rule, business rule execution hook, Smart Push setting, Smart View option, and validation rule engine mechanic is analyzed at consultant depth based on production source extractions.

---

## 📂 Document Index

| # | File | Topic & Focus Area | Technical Level |
|---|------|--------------------|-----------------|
| 00 | [00_INDEX.md](./00_INDEX.md) | Master directory index, architecture summary, and navigation guide | Overview |
| 01 | [01_Grid_and_Display_Properties.md](./01_Grid_and_Display_Properties.md) | Form Properties & Grid Engine: Properties tab (Instructions toolbar, Precision matrix, Context Menus, Dynamic User Variables), Grid Suppression, Database Suppression, Autosave, Display options | Core Performance & UI |
| 02 | [02_Dimension_and_Segment_Properties.md](./02_Dimension_and_Segment_Properties.md) | Dimension & Segment Properties: Page/POV/Row/Column properties, Consolidation operators, Start expanded, Drill on shared members, Segment formatting | Form Layout Engineering |
| 03 | [03_Business_Rules_and_Smart_Push_on_Forms.md](./03_Business_Rules_and_Smart_Push_on_Forms.md) | Business Rules & Smart Push: Run Before/After Load, Run Before/After Save, Use Members on Form, Smart Push background sync, Database Suppression | Automation & Data Movement |
| 04 | [04_Smart_View_Prediction_and_Printing_Options.md](./04_Smart_View_Prediction_and_Printing_Options.md) | Smart View, Prediction & Printing: Flex Forms (Rows/Columns), Spreading, Sheet protection, Predictive Planning, Supporting Detail | Advanced Client Features |
| 05 | [05_Format_and_Validation_Rules_Engine.md](./05_Format_and_Validation_Rules_Engine.md) | Format & Validation Rules: Condition blocks, Source/Target evaluation, Validate only for pages with existing blocks, Format Only rules | Business Logic Governance |
| 06 | [06_Troubleshooting_Performance_and_Design_Patterns.md](./06_Troubleshooting_Performance_and_Design_Patterns.md) | Form performance optimization matrix, sub-second load tuning, troubleshooting guide, 15 consultant interview questions & answers | Best Practices & Reference |
| 07 | [07_Cell_Level_Security_and_Valid_Intersections_on_Forms.md](./07_Cell_Level_Security_and_Valid_Intersections_on_Forms.md) | Cell-Level Security (CLS) vs Valid Intersections (VIC): Relational schema, 6-stage pipeline, visual indicators, suppression interplay, Cartesian dangers | Security & Data Integrity |
| 08 | [08_Groovy_Rules_and_Form_Context_API.md](./08_Groovy_Rules_and_Form_Context_API.md) | Groovy Rules & Form Context API: `operation.grid` model, lifecycle hooks, pre-save validation with `throwVetoException()`, focused dynamic FIX calcs, targeted Smart Push | Advanced Form Automation |
| 09 | [09_Form_Layout_Internals_and_XML_Repository.md](./09_Form_Layout_Internals_and_XML_Repository.md) | Form Layout Internals, XML Repository & LCM Structure: `HSP_FORM_*` relational tables, annotated LCM XML schema, MDX query compilation, Python mass maintenance | Enterprise Metadata Engineering |

---

## 🎯 How to Use This Guide

1. **For Form Performance & Retrieval Speed**: Read `01` → `06`.
2. **For Layout & Visual Design**: Read `01` → `02`.
3. **For Calculations & Cross-Cube Sync**: Read `03`.
4. **For Excel / Smart View Optimization**: Read `04`.
5. **For Data Quality & Validation Rules**: Read `05` → `07`.
6. **For Groovy Form Rules & In-Flight Control**: Read `08`.
7. **For Form Relational Storage & LCM XML Automation**: Read `09`.

---

## 🔑 Key Architecture at a Glance

```
Form Execution Lifecycle:
  1. USER CLICKS FORM
     ├── Relational DB loads layout definition (HSP_FORM_LAYOUT)
     └── Security validates user read permissions
  2. RUN BEFORE LOAD RULES EXECUTE
  3. DATA RETRIEVAL (ESSSVR Kernel Query)
     ├── "Suppress Missing Blocks" -> reads .IND B-tree to skip empty sparse keys
     ├── "Use Database Suppression" -> C++ kernel filters empty rows in RAM
     └── Cell-level security masks unauthorized intersections
  4. RUN AFTER LOAD RULES EXECUTE
  5. FORM RENDERS IN BROWSER / SMART VIEW
  6. USER EDITS DATA & HITS SAVE
     ├── "Validate only for pages with existing blocks" runs validation checks
     ├── RUN BEFORE SAVE RULES EXECUTE
     ├── Data commits to Essbase .PAG blocks
     ├── RUN AFTER SAVE RULES EXECUTE
     └── SMART PUSH launches (syncs FinPlan -> ASO Reporting)
```

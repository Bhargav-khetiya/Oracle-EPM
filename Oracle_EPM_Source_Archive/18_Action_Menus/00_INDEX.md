# 📖 Oracle EPM Cloud — Action Menus: Master Architecture Bible

> **Purpose**: This directory provides an exhaustive, consultant-level reference for Oracle EPM Cloud Planning Action Menus (Right-Click Context Menus). Every property, menu item type, required parameter, context relay mechanism, business rule runtime prompt mapping, approval action, and troubleshooting diagnostic is covered in depth based on production HTML source extractions.

---

## 📂 Document Index

| # | File | Topic & Focus Area | Technical Level |
|---|------|--------------------|-----------------|
| 00 | [00_INDEX.md](./00_INDEX.md) | Master directory index, architecture summary, and navigation guide | Overview |
| 01 | [01_Action_Menu_Architecture_and_Context_Relay.md](./01_Action_Menu_Architecture_and_Context_Relay.md) | Architecture, front-end vs back-end, Web Forms vs Smart View, Context Relay physics (Page, POV, Row, Column coordinate harvesting), shared common fields | Foundation & Core |
| 02 | [02_The_9_Menu_Item_Types_Complete_Guide.md](./02_The_9_Menu_Item_Types_Complete_Guide.md) | Exhaustive breakdown of all 9 item types: URL, Form, Business Rule, Manage Approvals, Dashboard, Change Status (20 actions), Menu Header, Previous Form, Copy Version | Core Engineering |
| 03 | [03_Required_Parameters_and_Targeting_Matrix.md](./03_Required_Parameters_and_Targeting_Matrix.md) | The 23 Required Parameters: Point of View, Page, Row, Column, Cell Only, Members only, and all 16 dimension-specific targeting rules | UI Context Targeting |
| 04 | [04_Business_Rules_Integration_and_RTP_Passing.md](./04_Business_Rules_Integration_and_RTP_Passing.md) | Business Rule integration, Runtime Prompt (RTP) injection from grid coordinates, Classic vs Streamline View, Hide Prompt mechanics, 52 production rules analyzed | Advanced Integration |
| 05 | [05_Troubleshooting_Security_and_Best_Practices.md](./05_Troubleshooting_Security_and_Best_Practices.md) | Production troubleshooting matrix, security permissions, migration via LCM snapshot, consultant Do's & Don'ts, 15 interview questions and answers | Governance & Reference |

---

## 🎯 How to Use This Guide

1. **For Fundamentals & Context Mechanics**: Read `01` → `02`.
2. **For Menu Targeting & Grid Restraints**: Read `03`.
3. **For Business Rules & Approvals Automation**: Read `02` → `04`.
4. **For Production Troubleshooting & Consultant Interviews**: Read `05`.

---

## 🔑 Key Architecture at a Glance

```
User Right-Clicks a Data Cell in Planning / Smart View
  │
  ▼
[Context Relay Engine]
  ├── Harvests Page Dimension Members (e.g., Entity: US_East)
  ├── Harvests POV Dimension Members (e.g., Scenario: Budget, Version: Working)
  ├── Harvests Row Dimension Members (e.g., Account: Gross_Sales)
  └── Harvests Column Dimension Members (e.g., Period: Jan, Years: FY25)
  │
  ▼
[Evaluates "Required Parameters"]
  ├── Does the clicked cell match targeting rules? (Cell Only, Row, Dimension)
  └── Filters visible menu options in the right-click dropdown
  │
  ▼
[Executes Target Action]
  ├── URL: Injects context tokens into target web URL
  ├── Form / Dashboard: Opens target object filtered by clicked POV
  ├── Business Rule: Injects clicked coordinates into Runtime Prompts (RTP)
  ├── Change Status: Executes approval promotion/rejection on clicked Entity
  └── Copy Version: Copies data slice from Source Version to Target Version
```

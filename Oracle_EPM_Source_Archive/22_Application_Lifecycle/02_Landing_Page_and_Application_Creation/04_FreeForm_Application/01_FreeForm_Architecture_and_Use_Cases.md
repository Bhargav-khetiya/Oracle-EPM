# 🎨 FreeForm Application — Complete Overview
## Custom Cubes, Flexible Dimensions, Maximum Freedom

> **Application Type:** FreeForm  
> **Architecture:** Custom Essbase cubes (BSO/ASO/Hybrid)  
> **Subscription:** Standard + Enterprise  
> **Best For:** Custom modeling, unique use cases, Essbase-like flexibility

---

## 🎯 What FreeForm Is

FreeForm is a **"blank canvas"** application type that gives you maximum flexibility to design your own multidimensional model without the constraints of pre-built Planning modules.

### FreeForm vs Planning Comparison

| Aspect | Planning (Modules) | FreeForm |
|--------|-------------------|----------|
| **Required Dimensions** | Account, Entity, Period, Year, Scenario, Version | ❌ None required |
| **Pre-built Content** | ✅ Forms, rules, dashboards, KPIs | ❌ None — you build everything |
| **Module Framework** | ✅ Financials, Workforce, Capital, etc. | ❌ No modules |
| **Cube Flexibility** | Limited by module structure | ✅ Full control — up to 12 cubes |
| **Dimension Flexibility** | Constrained by required dimensions | ✅ Up to 29 dimensions per cube |
| **Essbase OTL Import** | ❌ Not supported | ✅ Supported |
| **Smart View Compatibility** | ✅ Yes | ✅ Yes |
| **Data Maps** | ✅ Module-to-module | ✅ Cube-to-cube (need ≥ 2 cubes) |
| **Best For** | Standard financial planning | Custom/specialized modeling |

---

## 🤔 When to Choose FreeForm

### ✅ Choose FreeForm When:
| Scenario | Reason |
|----------|--------|
| Migrating from on-premise Essbase | OTL import support, similar architecture |
| Custom allocation models | No dimension constraints |
| Supply chain modeling | Non-standard dimension structure |
| Custom P&L that doesn't fit modules | Full control over account structure |
| Data warehousing / reporting | ASO cube support for large aggregations |
| Statistical modeling | Non-financial dimension structures |
| Custom KPI tracking | Flexible metric definitions |

### ❌ Do NOT Choose FreeForm When:
| Scenario | Better Alternative |
|----------|-------------------|
| Standard financial planning | Planning with Financials module |
| Need pre-built content quickly | Planning modules |
| Workforce/compensation planning | Planning with Workforce module |
| You're new to EPM | Start with Planning modules or Vision sample |

---

## 📋 FreeForm Creation Wizard Steps

The FreeForm wizard is shorter than the Planning wizard:

```
┌─────────────────────────────────────────────────────────┐
│                FREEFORM WIZARD FLOW                       │
│                                                          │
│   Step 1: General Properties                             │
│   ├── Application Name                                   │
│   ├── Description                                        │
│   └── Application Type = FreeForm                        │
│          │                                                │
│          ▼                                                │
│   Step 2: Cube Setup                                     │
│   ├── Number of Cubes (1-12)                             │
│   ├── Cube Names (max 8 chars each)                      │
│   └── Cube Types (BSO / ASO for each)                    │
│          │                                                │
│          ▼                                                │
│   Step 3: Dimension Setup                                │
│   ├── Account dimension (optional — enable/name)         │
│   ├── Entity dimension (optional — enable/name)          │
│   └── Period dimension (optional — enable/name)          │
│          │                                                │
│          ▼                                                │
│   Step 4: Review & Create                                │
│   ├── Summary of all settings                            │
│   └── [Create] button                                    │
└─────────────────────────────────────────────────────────┘
```

---

## 🔗 Detailed FreeForm Guides

| Step | Document | Description |
|------|----------|-------------|
| Cubes | [Cube Setup](./02_FreeForm_Cube_Setup.md) | Cube creation and BSO/ASO configuration |
| Dimensions | [Dimension Setup](./03_FreeForm_Dimension_Setup.md) | Dimension mapping and setup |
| Review | [Review & Create](./04_FreeForm_Review_and_Create.md) | Final review and creation |
| ← Back | [Wizard Overview](../02_Create_New_Application_Wizard/01_Wizard_Overview_and_Prerequisites.md) | Return to wizard overview |

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: How does Cloud EPM FreeForm differ from standalone on-premises Essbase 11.1.2.4 or Essbase 21c?
**Answer:** FreeForm runs modern Essbase in the Oracle Cloud SaaS tier, wrapped inside the EPM Cloud platform. Unlike standalone Essbase, FreeForm provides native web forms, dashboards, Calc Manager rules, Data Integration, EPM Automate CLI, and Task Lists out of the boxâ€”while granting complete freedom to design outlines without the 6 mandatory Planning dimensions.

### Q2: Can a FreeForm application be created with NO dimensions at all?
**Answer:** No. An Essbase cube requires at least one dimensional coordinate structure to exist. In Step 3 of the FreeForm wizard, you can accept default dimension suggestions (Account, Entity, Period) or disable them, but you must provision at least one dimension (or load an outline file) so Essbase can compile block storage structures.

### Q3: Can planners connect Excel Smart View directly to FreeForm cubes without Account and Entity dimensions?
**Answer:** Yes. Smart View connects to FreeForm cubes exactly like standard Essbase connections. Users perform ad-hoc multi-dimensional slicing across whatever custom dimensions you created (e.g. Measures, Geography, Product, Time).

﻿# 🎨 FreeForm — Cube Setup
## Creating and Configuring Cubes (BSO, ASO, Hybrid)

> **Wizard Step:** 2 (FreeForm path)  
> **Screen Title:** "Cubes" or "Cube Setup"  
> **Previous:** Step 1 — General Properties (Application Type = FreeForm)  
> **Next:** Step 3 — Dimension Setup

---

## 📸 Screen Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  Create Application — FreeForm                         Step 2/4  │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Cube Setup                                                       │
│  ──────────                                                       │
│                                                                   │
│  Number of Cubes *      [▼ 1                 ]                    │
│                                                                   │
│  ┌──────────────────────────────────────────────────────┐        │
│  │  Cube 1                                               │        │
│  │  ─────                                                │        │
│  │  Cube Name *     [Plan1    ]  (max 8 characters)      │        │
│  │  Is ASO          ☐                                    │        │
│  │  (Leave unchecked for BSO Hybrid)                     │        │
│  └──────────────────────────────────────────────────────┘        │
│                                                                   │
│  ── If Number of Cubes > 1 ──                                     │
│                                                                   │
│  ┌──────────────────────────────────────────────────────┐        │
│  │  Cube 2                                               │        │
│  │  ─────                                                │        │
│  │  Cube Name *     [Report1  ]  (max 8 characters)      │        │
│  │  Is ASO          ☑                                    │        │
│  └──────────────────────────────────────────────────────┘        │
│                                                                   │
│  ┌────────┐  ┌────────┐  ┌────────┐                             │
│  │ Cancel │  │  Back  │  │  Next  │                             │
│  └────────┘  └────────┘  └────────┘                             │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📝 Field-by-Field Reference

### Field 1: Number of Cubes

| Property | Details |
|----------|---------|
| **Label** | "Number of Cubes" |
| **Type** | Dropdown (1–12) |
| **Required** | ✅ Yes |
| **Default** | 1 |
| **Range** | 1 to 12 |
| **Can Add Later** | ✅ Yes — cubes can be added post-creation |

**Recommendations:**
| Cubes | Use Case |
|-------|----------|
| 1 | Simple planning model, single-purpose application |
| 2 | Planning (BSO) + Reporting (ASO) — most common |
| 3-4 | Multiple planning areas with shared reporting |
| 5+ | Complex multi-area models (rare at creation) |

> [!TIP]
> Start with fewer cubes. You can add more later via Application → Overview → Cubes. Data Maps require at least 2 cubes to function.

---

### Field 2: Cube Name (per cube)

| Property | Details |
|----------|---------|
| **Label** | "Cube Name" |
| **Type** | Text input |
| **Required** | ✅ Yes |
| **Max Length** | 8 characters |
| **Allowed Characters** | Letters (A-Z, a-z), Numbers (0-9) |
| **Prohibited** | Spaces, special characters, underscores |
| **Must Start With** | A letter |
| **Uniqueness** | Must be unique within the application |
| **Editable Later** | ❌ No — cannot rename cubes after creation |

#### Valid Cube Names:
| Name | Valid— | Notes |
|------|--------|-------|
| `Plan1` | ✅ | Good — short, descriptive |
| `Rpt` | ✅ | Good — abbreviation for Reporting |
| `BSO1` | ✅ | Valid |
| `Alloc` | ✅ | Good — indicates allocation purpose |
| `FinPlan` | ✅ | Good — Financial Planning |

#### Invalid Cube Names:
| Name | Valid— | Reason |
|------|--------|--------|
| `Financial` | ❌ | Exceeds 8 characters |
| `Plan 1` | ❌ | Contains space |
| `Plan_1` | ❌ | Contains underscore |
| `1Plan` | ❌ | Starts with number |

---

### Field 3: Is ASO (per cube)

| Property | Details |
|----------|---------|
| **Label** | "Is ASO" |
| **Type** | Checkbox |
| **Default** | ☐ Unchecked (BSO Hybrid) |
| **Editable Later** | ❌ No — cannot change cube type |

#### BSO vs ASO Comparison:

| Feature | BSO (Hybrid) | ASO |
|---------|-------------|-----|
| **Full Name** | Block Storage Option | Aggregate Storage Option |
| **Data Input** | ✅ Yes — users can enter data | ❌ No direct input (load only) |
| **Calculations** | ✅ Complex calculations, Calc Scripts | Limited — aggregation only |
| **Write-back** | ✅ Yes | ❌ No |
| **Aggregation Speed** | Slower for large datasets | ✅ Very fast — dynamic aggregation |
| **Dimension Limit** | ~20-25 dense/sparse | ✅ Higher — up to 29 |
| **Best For** | Planning, data entry, calculations | Reporting, analysis, large datasets |
| **Hybrid Enabled** | ✅ Auto-enabled in Cloud | N/A |
| **Data Maps Source** | ✅ Can be source | ❌ Cannot be source |
| **Smart Push** | ✅ Supported | ❌ Not supported |

#### When to Choose BSO:
- ✅ Data entry forms
- ✅ Complex business rules
- ✅ What-if analysis
- ✅ Budgeting and forecasting

#### When to Choose ASO:
- ✅ Large data volumes (100M+ cells)
- ✅ Reporting and analysis only
- ✅ Many dimensions (high dimensionality)
- ✅ Real-time aggregation needs
- ✅ Data loaded from external sources only

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: What is the maximum number of cubes in FreeForm, and what are their naming constraints—
**Answer:** FreeForm supports up to **12 cubes** per application. Cube names must be **1 to 8 characters**, alphanumeric only, starting with a letter. Spaces and special characters are prohibited. Once created, cube names cannot be renamed.

### Q2: When should a FreeForm cube be configured as BSO Hybrid versus Aggregate Storage (ASO)—
**Answer:**
- **BSO Hybrid:** Best for planning, what-if modeling, write-back forms, complex business rules, and financial calculations.
- **ASO (Aggregate Storage):** Best for massive analytical reporting cubes, large dimension rollups (millions of members), and multi-year data marts where calculation logic is simple summation.

### Q3: Can an administrator convert a BSO cube to an ASO cube post-creation in FreeForm—
**Answer:** No. Cube storage engine architecture (BSO vs ASO) is locked at creation. To change a cube from BSO to ASO, you must delete the cube (if permitted) or recreate the application and define the new cube as ASO.

---

## 🔗 Navigation

| Direction | Document |
|-----------|----------|
| **Next →** | [Dimension Setup](./03_FreeForm_Dimension_Setup.md) |
| **← Previous** | [FreeForm Overview](./01_FreeForm_Architecture_and_Use_Cases.md) |
| **← Back to Index** | [Master Index](../../00_MASTER_INDEX.md) |

﻿# 🎨 FreeForm — Dimension Setup
## Mapping and Configuring Dimensions

> **Wizard Step:** 3 (FreeForm path)  
> **Screen Title:** "Dimensions"  
> **Previous:** Step 2 — Cube Setup  
> **Next:** Step 4 — Review & Create

---

## 📸 Screen Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  Create Application — FreeForm                         Step 3/4  │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Dimension Setup                                                  │
│  ───────────────                                                  │
│                                                                   │
│  Configure the default dimensions for your application.           │
│  You can add more dimensions after creation.                      │
│                                                                   │
│  ┌──────────────────────────────────────────────────────┐        │
│  │ Dimension Type │ Enabled │ Name           │ Cube     │        │
│  ├────────────────┼─────────┼────────────────┼──────────┤        │
│  │ Account        │  ☐      │ [Account    ]  │ [All  ▼] │        │
│  │ Entity         │  ☐      │ [Entity     ]  │ [All  ▼] │        │
│  │ Period         │  ☐      │ [Period     ]  │ [All  ▼] │        │
│  └──────────────────────────────────────────────────────┘        │
│                                                                   │
│  ℹ️ All dimensions are optional in FreeForm.                     │
│  You can create a shell application with no dimensions            │
│  and add all dimensions manually after creation.                  │
│                                                                   │
│  ⚠️ Dimension names cannot be changed after creation.            │
│                                                                   │
│  ┌────────┐  ┌────────┐  ┌────────┐                             │
│  │ Cancel │  │  Back  │  │  Next  │                             │
│  └────────┘  └────────┘  └────────┘                             │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📝 Field-by-Field Reference

### Dimension Table Columns

#### Column 1: Dimension Type
| Type | Description | Essbase Equivalent |
|------|-------------|-------------------|
| **Account** | Financial account structure | Account dimension tag |
| **Entity** | Organizational units | None (custom) |
| **Period** | Time periods | Time dimension tag |

> [!NOTE]
> In FreeForm, these are **optional suggestions**. Unlike standard Planning, you are NOT required to have Account, Entity, or Period dimensions. You can skip all three and add entirely custom dimensions later.

#### Column 2: Enabled ☐
| Property | Details |
|----------|---------|
| **Type** | Checkbox |
| **Default** | ☐ Unchecked |
| **Required** | ❌ No — all optional |
| **Effect when checked** | Creates this dimension with the specified name |
| **Effect when unchecked** | Dimension is NOT created |

#### Column 3: Name
| Property | Details |
|----------|---------|
| **Type** | Text input |
| **Visible** | Only when Enabled is checked |
| **Default** | "Account", "Entity", "Period" |
| **Max Length** | 80 characters |
| **Allowed Characters** | Letters, numbers, underscores, spaces |
| **Editable Later** | ❌ No — cannot rename dimensions after creation |
| **Customizable** | ✅ Yes — rename to match your model (e.g., "Measures", "Department", "Month") |

#### Column 4: Cube
| Property | Details |
|----------|---------|
| **Type** | Dropdown |
| **Options** | "All" (assigned to all cubes) or specific cube name |
| **Default** | "All" |
| **Purpose** | Which cube(s) this dimension belongs to |

---

## 📊 Dimension Design Strategies

### Strategy 1: Start with Defaults
Enable Account, Entity, and Period with default names:
| Enabled | Name | Use Case |
|---------|------|----------|
| ☑ Account | Account | Standard financial model |
| ☑ Entity | Entity | Multi-entity organization |
| ☑ Period | Period | Monthly/quarterly time periods |

### Strategy 2: Custom Names
Enable defaults but rename to your model's terminology:
| Enabled | Name | Use Case |
|---------|------|----------|
| ☑ Account | Measures | KPI/metric-based model |
| ☑ Entity | Department | Departmental planning |
| ☑ Period | Month | Monthly-only model |

### Strategy 3: Shell Application
Skip all defaults and build from scratch:
| Enabled | Name | Result |
|---------|------|--------|
| ☐ | - | No Account dimension |
| ☐ | - | No Entity dimension |
| ☐ | - | No Period dimension |

Then add custom dimensions post-creation via Application → Overview → Dimensions.

---

## 📐 Post-Creation Dimension Management

After the FreeForm application is created, you manage dimensions via:

**Navigation:** `Application → Overview → Dimensions`

### Available Dimension Types (Post-Creation):
| Type | Description | Max per App | Dense/Sparse |
|------|-------------|------------|-------------|
| **Account** | Financial measures — ONE per app | 1 | Dense |
| **Period** | Time periods — ONE per app | 1 | Dense |
| **Entity** | Organizational units | 1 | Sparse |
| **Year** | Fiscal years | 1 | Sparse |
| **Scenario** | Planning scenarios | 1 | Sparse |
| **Version** | Data versions | 1 | Sparse |
| **Currency** | Currency codes | 1 | Sparse |
| **Custom/Generic** | Any custom dimension | Up to 20+ | User-defined |
| **Attribute** | Attribute dimensions | Multiple | N/A |

### Dimension Properties You Set:
| Property | Description | Options |
|----------|-------------|---------|
| **Name** | Dimension name | Any text (max 80 chars) |
| **Type** | Dimension type | Account, Entity, Period, Year, Custom, etc. |
| **Cube** | Assigned cube(s) | Specific cube or all cubes |
| **Dense/Sparse** | Storage classification | Dense or Sparse |
| **Alias Table** | Alternate name table | Default alias table |
| **Sort Order** | Member sort order | None, Ascending, Descending |
| **Data Storage** | Default data storage | Store, Dynamic Calc, Never Share, Label Only, Shared |
| **Two-Pass Calc** | Two-pass calculation | Yes/No |

---

## ⚠️ Limits and Constraints

| Constraint | Standard | Enterprise |
|-----------|----------|------------|
| Maximum Cubes | 4 (BSO) + 1 (ASO) | 12 (mixed BSO/ASO) |
| Max Dimensions per Cube | ~20 | ~29 |
| Max Dense Dimensions | ~8 | ~8 |
| Max Sparse Dimensions | ~12 | ~21 |
| Max Members per Dimension | No hard limit | No hard limit |
| Max Total Application Size | Service-dependent | Service-dependent |

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: What are the 3 optional default dimensions offered during FreeForm wizard setup—
**Answer:** The wizard offers Account, Entity, and Period as optional checkboxes. Unlike standard Planning where these are mandatory, in FreeForm you can uncheck any or all of them. You can rename them (e.g. renaming Account to Measures or Period to Time).

### Q2: What is the maximum number of dimensions allowed per cube in FreeForm—
**Answer:** A FreeForm cube supports up to **29 dimensions**. However, best practice for performance in BSO Hybrid is to keep dimension counts between 8 and 14 to avoid excessive sparse block header overhead.

### Q3: Can you import an Essbase outline (.otl) directly into FreeForm during application creation—
**Answer:** Yes. If you select "Create from Essbase Outline (.otl)" in the creation flow, the wizard allows you to upload an existing on-premises Essbase outline file. FreeForm parses the outline, creates the cubes, and builds all dimensions, member formulas, and alias tables automatically.

---

## 🔗 Navigation

| Direction | Document |
|-----------|----------|
| **Next →** | [Review & Create](./04_FreeForm_Review_and_Create.md) |
| **← Previous** | [Cube Setup](./02_FreeForm_Cube_Setup.md) |
| **← FreeForm Overview** | [FreeForm Overview](./01_FreeForm_Architecture_and_Use_Cases.md) |

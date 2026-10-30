# Dimensions and Metadata

> Every data cell in an Essbase cube sits at the intersection of one member from each dimension. Understanding dimension architecture — what each dimension controls, how members are stored, and how they aggregate — is the foundation of every Planning task.

---

## Reading Order

| # | File | What You'll Learn |
|---|------|-------------------|
| 1 | [Dimension Fundamentals](01_Dimension_Fundamentals.md) | What dimensions are, standard vs custom, dense vs sparse, the two architectural layers |
| 2 | [Universal Member Properties](02_Universal_Member_Properties.md) | Data storage types, consolidation operators, two-pass, UDAs vs attributes, dynamic children |
| 3 | [Account Dimension](03_Account_Dimension.md) | Account types, variance reporting, time balance, skip settings, exchange rate types |
| 4 | [Period, Scenario, Version, Year](04_Period_Scenario_Version.md) | Time bounding, active ranges, bottom-up vs target, sandboxes, currency dimension |
| 5 | [Advanced Topics](05_Advanced_Topics.md) | HSP_ tables, 17 metric types, implied sharing, shared members, solve order, design patterns |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           DIMENSION ARCHITECTURE                                │
├────────────────────┬───────────────────────────┬────────────────────────────────┤
│  STANDARD DIMS     │  CUSTOM DIMS              │  SYSTEM DIMS                   │
│  (Cannot delete)   │  (Admin-created)          │  (Internal HSP_ members)       │
├────────────────────┼───────────────────────────┼────────────────────────────────┤
│  Account           │  Department               │  HSP_Approval Unit Hierarchy   │
│  Entity            │  Product                  │  HSP_Submission Group          │
│  Period            │  Channel                  │  Metric Type members           │
│  Year              │  Project                  │                                │
│  Scenario          │  Driver                   │                                │
│  Version           │  (Up to 7 in PBCS,        │                                │
│  Currency (if MC)  │   20 in Free Form)        │                                │
└────────────────────┴───────────────────────────┴────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │ Every member has:  │
                    │ • Name / Alias     │
                    │ • Data Storage     │
                    │ • Consolidation Op │
                    │ • Plan Type flags  │
                    │ • Data Type        │
                    │ • UDAs             │
                    └───────────────────┘
```

## Data Storage Quick Reference

| Type | Disk? | Input? | Use For |
|:---|:---:|:---:|:---|
| **Store** | ✅ | ✅ | Base input members, loaded data |
| **Dynamic Calc** | ❌ | ❌ | Parents, ratios, KPIs — calculated on demand |
| **Never Share** | ✅ | ✅ | Single-child parents needing isolated data |
| **Shared** | ❌ | Via base | Alternate hierarchies (zero storage cost) |
| **Label Only** | ❌ | ❌ | Organizational grouping headers |

## Required Dimensions by Application Type

| Dimension | Standard (PBCS) | Enterprise (EPBCS) | Free Form |
|-----------|:---:|:---:|:---:|
| Account | ✅ | ✅ | Optional |
| Entity | ✅ | ✅ | Optional |
| Period | ✅ | ✅ | ✅ |
| Year | ✅ | ✅ | ✅ |
| Scenario | ✅ | ✅ | Optional |
| Version | ✅ | ✅ | Optional |
| Currency | If multi-currency | If multi-currency | No |

---

**Provenance:** Content merged from ChatGPT `Dimension_Properties/` (12 files), Claude `05_Metadata/` (8 files) + `29_Property_Encyclopedia/` (11 files), Gemini `Dimension_Properties/` (12 files). See [MERGE_MAP.md](../MERGE_MAP.md) for full source tracing.

# Smart View

> Smart View brings EPM data into the familiar Excel environment — letting planners, analysts, and administrators retrieve, analyze, and submit data without leaving their spreadsheets.

---

## Reading Order

| # | File | What You'll Learn |
|---|------|-------------------|
| 1 | [Smart View Complete Guide](01_Smart_View_Complete_Guide.md) | Connections, ad hoc analysis, forms, flex forms, functions, VBA, troubleshooting |

---

## Architecture

```
┌──────────────────┐         HTTPS          ┌──────────────────────┐
│ Excel + Smart    │ ◄─────────────────────► │ Oracle EPM Cloud     │
│ View Add-In      │  Retrieve / Submit      │ (Planning, FCCS,     │
│                  │                          │  Essbase, TRCS)      │
└──────────────────┘                          └──────────────────────┘
```

## Key Concepts at a Glance

| Concept | One-Line Summary |
|:---|:---|
| **Shared Connection** | Administrator-managed connection URL available to all users |
| **Private Connection** | User-entered/saved connection URL |
| **Ad Hoc Analysis** | Free-form exploration of dimensions without a fixed form layout |
| **Refresh** | Retrieves current data from server (overwrites local changes) |
| **Submit** | Sends edited data from Excel to EPM |
| **HsGetValue** | Worksheet function that retrieves a specific cell value |
| **Flex Forms** | Forms with flexible row/column management |

---

**Provenance:** Merged from ChatGPT `Smart_View_and_Ad_Hoc/` (6 files), Claude `10_Smart_View/`, Gemini equivalents. See [MERGE_MAP.md](../MERGE_MAP.md).

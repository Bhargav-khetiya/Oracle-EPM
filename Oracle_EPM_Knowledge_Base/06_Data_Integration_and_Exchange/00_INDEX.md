# Data Integration and Exchange

> Data doesn't live in EPM alone. This section covers every way data moves into, out of, and between EPM cubes — from external ERP loads to real-time form-level Smart Push.

---

## Reading Order

| # | File | What You'll Learn |
|---|------|-------------------|
| 1 | [Data Integration Overview](01_Data_Integration_Overview.md) | External data loading (Data Management vs Data Integration), the 5-component ETL chain, member mappings, EPM Agent |
| 2 | [Data Maps and Smart Push](02_Data_Maps_and_Smart_Push.md) | Inter-cube data movement, Smart Push real-time sync, @XREF/@XWRITE, context-aware micro-slicing |

---

## Architecture Overview

```
EXTERNAL SOURCES                     EPM CLOUD CUBES                    REPORTING
                                                                        
┌──────────────┐                    ┌──────────────────┐               
│ ERP Systems  │──┐  Data          │ BSO Planning     │──┐ Data Maps  
│ Flat Files   │  │  Integration   │ (FinPlan, WFP,   │  │ Smart Push 
│ On-Prem DB   │──┤ ──────────────►│  CapPlan)        │  │            
│ REST APIs    │  │                │                  │  │            
└──────────────┘  │                └──────────────────┘  │            
                  │                                      ▼            
                  │                ┌──────────────────┐               
                  └───────────────►│ ASO Reporting    │               
                                   │ (OEP_REP, FCCS)  │               
                                   └──────────────────┘               
```

## Cross-Cube Data Movement Patterns

| Pattern | Tool | Direction | Speed |
|:---|:---|:---|:---|
| **ERP → BSO** | Data Integration | External → EPM | Medium |
| **File → BSO** | Data Integration | External → EPM | Fast |
| **BSO → ASO** | Data Maps / Smart Push | EPM → EPM | Very Fast |
| **BSO → BSO** | Data Maps | EPM → EPM | Fast |
| **Formula lookup** | @XREF | Pull (per-cell) | Slow |
| **Calc script push** | @XWRITE | Push (per-cell) | Slow |
| **Groovy push** | DataGridBuilder | Push (batch) | Fast |

---

**Provenance:** Content merged from ChatGPT `Data_Integration/` (2 files), ChatGPT `Data_Maps_and_Exchange/` (17 files across 6 subdirectories), Claude `11_Data_Integration/` (5 files), Gemini equivalents. See [MERGE_MAP.md](../MERGE_MAP.md).

# Administering Data Integration — Complete Markdown Edition

> **Original PDF:** `Administering_Data_Integration.pdf` | **Folder:** Level 4 (Integration & Automation)  
> **Purpose:** Definitive Markdown guide on modern Redwood Data Integration (`Pipeline`), applications, import/export mappings, EPM Integration Agent, and multi-stage orchestration.

---

## Table of Contents
1. [Redwood Data Integration vs. Data Management](#architecture)
2. [Configuring Applications, Locations & Category Mappings](#config)
3. [Member Mapping Rules (`Explicit`, `Between`, `In`, `Multi-Dim`, `SQL`)](#mappings)
4. [EPM Integration Agent Setup & Local JDBC Extraction](#agent-setup)
5. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Redwood Data Integration vs. Data Management <a name="architecture"></a>

Modern **Data Integration (`Data Exchange -> Data Integration`)** replaces legacy FDMEE frames with intuitive pipeline flows.
- Supports multi-stage execution pipelines (`Extract -> Map -> Validate -> Load -> Calculate`).

---

## 2. Configuring Applications, Locations & Category Mappings <a name="config"></a>

- **Source Applications:** Flat file (`CSV`), Cloud ERP (`Fusion`), or On-Prem Database via Agent.
- **Target Applications:** EPM Planning cubes (`FinPlan`, `Workforce`), ASO cubes, or FreeForm apps.

---

## 3. Member Mapping Rules (`Explicit`, `Between`, `In`, `Multi-Dim`, `SQL`) <a name="mappings"></a>

| Mapping Rule Type | Syntax / Behavior | Example |
| :--- | :--- | :--- |
| **Explicit** | Exact 1-to-1 string replacement. | Source `1001` $\rightarrow$ Target `Revenue_Hardware` |
| **Between** | Numeric or alphabetical range mapping. | Source `6000 TO 6999` $\rightarrow$ Target `Operating_Expenses` |
| **In (`Wildcard`)** | Match based on comma list or wildcard pattern (`*`). | Source `7*` $\rightarrow$ Target `Other_Income` |
| **Multi-Dimensional** | Maps based on multiple source dimensions simultaneously. | If `Account == 5000` AND `Entity == US_01` $\rightarrow$ Target `US_Payroll` |
| **SQL (`Script`)** | Executes dynamic SQL expressions or Groovy transformation scripts. | `CASE WHEN ACCOUNT LIKE '4%' THEN 'REV_' || ACCOUNT END` |

---

## 4. EPM Integration Agent Setup & Local JDBC Extraction <a name="agent-setup"></a>

- Download agent zip $\rightarrow$ configure `agentparams.ini` $\rightarrow$ install `mssql-jdbc.jar` $\rightarrow$ start polling loop (`HTTPS 443`).

---

## 5. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`11_Data_Integration/01_Data_Integration_Complete_Guide.md`** — Comprehensive Data Integration setup.
- **`24_Architect_Masterclass/09_EPM_Integration_Agent_and_Local_SQL_Tunneling.md`** — Local SQL extraction deep dive.

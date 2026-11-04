# 33. Cheat Sheets — Rapid-Fire Reference Tables, Syntax & CLI Quick Lookups

> **Consultant High-Yield Summary:**  
> Quick-reference cheat sheets for the active technical consultant. Instant syntax guides for Essbase calc commands, Groovy API calls, EPM Automate commands, REST API payloads, and dimension member storage formulas.

---

## ðŸŽ¯ Live Interactive Visual Architecture Card

<details open>
<summary><b>ðŸŽ¯ Live Interactive Architecture Card: Technical Quick-Reference Fast Index</b></summary>

| Technology Domain | Core Reference Topic | Rapid Lookup Syntax |
| :--- | :--- | :--- |
| **Essbase Calc Commands** | Scoping & Looping | `FIX (sparse_mbrs) ... ENDFIX`, `CLEARDATA`, `AGG (dim)` |
| **EPM Automate CLI** | Daily Automation Commands | `epmautomate login`, `refreshcube`, `runbusinessrule`, `copysnapshot` |
| **Groovy Scripting API** | Grid Interception & Exceptions | `operation.grid.dataCellIterator { it.edited }`, `throwVetoException()` |
| **Member Formulas** | Dynamic Ratios & Margin % | `IF("Denom" != 0) "Num" / "Denom"; ELSE #Missing; ENDIF` |

```mermaid
flowchart LR
    CalcCheat["Essbase Calc Syntax"] --- GroovyCheat["Groovy API Patterns"]
    GroovyCheat --- CLICheat["EPM Automate CLI"]
    CLICheat --- RESTCheat["REST API Endpoints"]
    RESTCheat --- FormulaCheat["Member Formulas"]
```

</details>

---

## ðŸ›ï¸ Architectural Comparison & Design Patterns

| Command / Function | Primary Purpose | Syntax Example |
| :--- | :--- | :--- |
| `@CALCPARALLEL` | Enables multithreaded calculation | `SET CALCPARALLEL 4;` |
| `@IDESCENDANTS` | Returns member and all its descendants | `FIX(@IDESCENDANTS("Total_Entity"))` |
| `throwVetoException` | Cancels form save with custom message | `throwVetoException(new ValidationMessage('Error!'))` |

---

## ðŸ’¼ Tough & Twisted Review Scenarios (Consultant Review Defense)

### Question 1: "What is the difference between `@DESCENDANTS` and `@IDESCENDANTS`?"
> **Consultant Model Answer:**  
> `@DESCENDANTS(member)` returns all children and descendants of the member, EXCLUDING the member itself. `@IDESCENDANTS(member)` (Inclusive Descendants) returns the member AND all of its children and descendants. Using `@DESCENDANTS` when you intended to include the parent causes calculation logic to miss the parent node.

---

## ðŸ“‘ Complete Document Catalog

| # | Document File | Topic Description |
|---|---------------|-------------------|
| 01 | [25.01_EPM_Ecosystem.md](./25.01_EPM_Ecosystem.md) | 25.01 â€” EPM Ecosystem Cheat Sheet |
| 02 | [25.02_Calc_Manager_Functions_CheatSheet.md](./25.02_Calc_Manager_Functions_CheatSheet.md) | 25.02 â€” Essbase Calc Script Syntax Cheat Sheet |
| 03 | [25.02_Essbase_Database.md](./25.02_Essbase_Database.md) | 25.02 — Essbase Database Cheat Sheet |
| 04 | [25.03_Account_Properties.md](./25.03_Account_Properties.md) | 25.03 â€” Account Properties Cheat Sheet |
| 05 | [25.04_Forms_and_Planning.md](./25.04_Forms_and_Planning.md) | 25.04 — Forms and Planning Cheat Sheet |
| 06 | [25.05_Roles.md](./25.05_Roles.md) | 25.05 — Roles and Security Cheat Sheet |
| 07 | [25.06_Business_Rules.md](./25.06_Business_Rules.md) | 25.06 — Business Rules Cheat Sheet |
| 08 | [25.07_Groovy.md](./25.07_Groovy.md) | 25.07 — Groovy in Calc Manager: Cheat Sheet |
| 09 | [25.08_Data_Integration.md](./25.08_Data_Integration.md) | 25.08 â€” Data Integration Cheat Sheet |
| 10 | [25.09_Security.md](./25.09_Security.md) | 25.09 — Security Cheat Sheet |
| 11 | [25.10_EPM_Automate.md](./25.10_EPM_Automate.md) | 25.10 â€” EPM Automate Cheat Sheet |

---

> **Consultant Implementation Note:** Master the architectural comparison and review defense questions in this module before presenting designs to client stakeholders or senior review panels.
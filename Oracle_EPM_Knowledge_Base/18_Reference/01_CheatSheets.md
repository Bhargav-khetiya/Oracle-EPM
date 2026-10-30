# Cheat Sheets — Quick Reference Cards

> **Section:** 18 — Reference  
> **File:** 01 — Cheat Sheets  
> **Difficulty:** All Levels

---

## EPM Navigation Cheat Sheet

| Task | Path |
|------|------|
| Open a form | Navigator → Data → Forms |
| Run a business rule | Navigator → Rules → Select rule → Launch |
| Open Calc Manager | Navigator → Calculation Manager |
| Manage dimensions | Navigator → Dimensions |
| Import metadata | Navigator → Application → Import Metadata |
| Export snapshot | Navigator → Application → Snapshot |
| Manage security | Navigator → Tools → Access Control |
| View jobs | Navigator → Tools → Jobs |
| Open Data Maps | Navigator → Data Exchange → Data Maps |
| Create an Action Menu | Navigator → Action Menus |

---

## Essbase @Functions Cheat Sheet

### Member Navigation

| Function | Returns |
|----------|---------|
| `@CHILDREN("P")` | Children of P |
| `@DESCENDANTS("P")` | All descendants of P |
| `@PARENT("M")` | Parent of M |
| `@SIBLINGS("M")` | Siblings of M |
| `@LEVMBRS("D", 0)` | All level-0 (leaf) members |
| `@GENMBRS("D", 2)` | All generation-2 members |
| `@RELATIVE("P", 0)` | Leaf descendants of P |
| `@UDA("D", "tag")` | Members with UDA "tag" |

### Boolean Tests

| Function | Tests |
|----------|-------|
| `@ISMBR("M")` | Is current member M? |
| `@ISANCEST("M")` | Is current member ancestor of M? |
| `@ISDESC("M")` | Is current member descendant of M? |
| `@ISLEV("D", N)` | Is current member at level N? |
| `@ISGEN("D", N)` | Is current member at generation N? |
| `@ISUDA("D", "tag")` | Does current member have UDA? |

### Data Access

| Function | Returns |
|----------|---------|
| `@PARENTVAL("D")` | Value from parent |
| `@PRIOR("D")` | Value from previous member |
| `@NEXT("D")` | Value from next member |
| `"M1" -> "M2"` | Cross-dimensional reference |

### Commands

| Command | Purpose |
|---------|---------|
| `FIX / ENDFIX` | Define calculation scope |
| `IF / ENDIF` | Conditional logic |
| `AGG("D")` | Aggregate dimension |
| `DATACOPY A TO B` | Copy data |
| `CLEARDATA "M"` | Clear data for member |

---

## SET Commands Cheat Sheet

| Command | Common Value | Purpose |
|---------|-------------|---------|
| `SET UPDATECALC` | OFF | Recalculate everything |
| `SET CREATEBLOCKONEQ` | ON/OFF | Create blocks on formula assignment |
| `SET CREATENONMISSINGBLK` | ON | Create blocks for DATACOPY |
| `SET CALCPARALLEL` | 4 | Enable parallel calculation |
| `SET CALCTASKDIMS` | 2 | Parallel task splitting |
| `SET LOCKBLOCK` | ON | Lock blocks during calculation |
| `SET AGGMISSG` | ON/OFF | Include missing in aggregation |
| `SET FRMLBOTTOMUP` | ON | Bottom-up formula calculation |

---

## Groovy Cheat Sheet

### Key Objects

| Object | Purpose |
|--------|---------|
| `operation.grid` | Current form data grid |
| `operation.application` | Application object |
| `operation.planType` | Current plan type |
| `operation.user` | Current user |
| `rtps.RTP_Name` | Runtime prompt value |

### Common Operations

```groovy
// Read edited cells
operation.grid.dataCellIterator().each { cell ->
    if (cell.edited) { /* process */ }
}

// Get RTP value
def entity = rtps.RTP_Entity.getEssbaseMemberName()

// Read from cube
DataGridDefinitionBuilder builder = new DataGridDefinitionBuilder()
// ... configure and build

// Write to cube
DataGridBuilder grid = new DataGridBuilder("Plan1")
// ... add POV, columns, rows, build(true)

// Execute calc script
operation.planType.essCalcScript = "FIX(...) ... ENDFIX"
operation.planType.execute()

// Validate and veto
throwVetoException("Error message")

// Send email
operation.application.getEmailService().sendMail(to, subject, body)
```

---

## EPM Automate Cheat Sheet

### Connection

| Command | Purpose |
|---------|---------|
| `epmautomate login user pass url` | Connect |
| `epmautomate logout` | Disconnect |

### Data Operations

| Command | Purpose |
|---------|---------|
| `epmautomate importdata "RuleName"` | Load data |
| `epmautomate exportdata "RuleName"` | Export data |
| `epmautomate runbusinessrule "Rule"` | Run rule |
| `epmautomate rundatarule "Rule" start end import export` | Run data integration rule |
| `epmautomate refreshcube` | Deploy metadata to Essbase |

### File Operations

| Command | Purpose |
|---------|---------|
| `epmautomate uploadfile "file"` | Upload to inbox |
| `epmautomate downloadfile "file"` | Download from outbox |
| `epmautomate listfiles` | List files |
| `epmautomate deletefile "file"` | Delete file |

### Lifecycle Operations

| Command | Purpose |
|---------|---------|
| `epmautomate exportsnapshot "name"` | Export snapshot |
| `epmautomate importsnapshot "name"` | Import snapshot |
| `epmautomate copySnapshotFromInstance url user pass "name"` | Cross-instance copy |
| `epmautomate cloneEnvironment ...` | Clone entire environment |
| `epmautomate recreate -f` | Factory reset |

---

## Dimension Properties Cheat Sheet

| Property | Values | Default |
|----------|--------|---------|
| Data Storage | Store, Dynamic Calc, Never Share, Label Only, Shared | Store |
| Data Type | Currency, Non-currency, Percentage, Date, Text, Unspecified | Unspecified |
| Two Pass Calculation | True/False | False |
| Skip Value | None, Missing, Zeros, Missing and Zeros | None |
| Time Balance | None, First, Last, Average | None |
| Variance Reporting | Non-Expense, Expense | Non-Expense |

---

## Source Provenance

| Source | Files |
|--------|-------|
| Claude | `25_CheatSheets/` |
| ChatGPT | Various topic files (consolidated) |
| Gemini | Various topic files (consolidated) |


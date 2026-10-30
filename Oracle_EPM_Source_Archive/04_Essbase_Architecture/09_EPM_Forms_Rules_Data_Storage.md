# 09 — EPM Forms, Rules, and Data Storage: Where Everything Lives

---

## 9.1 The Two-World Architecture of Oracle EPM

Oracle EPM (Enterprise Performance Management) uses a **dual storage architecture**:

```
┌─────────────────────────────────────────────────────────────────┐
│                    ORACLE EPM ARCHITECTURE                       │
│                                                                  │
│  ┌──────────────────────────┐  ┌───────────────────────────────┐│
│  │   RELATIONAL DATABASE     │  │     ESSBASE SERVER            ││
│  │   (Oracle RDBMS)          │  │     (OLAP Engine)              ││
│  │                           │  │                               ││
│  │  STORES:                  │  │  STORES:                      ││
│  │  ✦ Form definitions      │  │  ✦ The actual DATA            ││
│  │  ✦ Business Rule defs    │  │    (numbers, cell values)      ││
│  │  ✦ Calc Manager scripts  │  │                               ││
│  │  ✦ Task Lists            │  │  ✦ Dimension outlines         ││
│  │  ✦ Smart Lists           │  │    (member hierarchies)        ││
│  │  ✦ Menu definitions      │  │                               ││
│  │  ✦ User preferences      │  │  ✦ Calc scripts (.CSC)        ││
│  │  ✦ Approval status       │  │                               ││
│  │  ✦ Security (access)     │  │  ✦ Data blocks (.PAG)         ││
│  │  ✦ Currency rates        │  │                               ││
│  │  ✦ Exchange rate tables  │  │  ✦ Block index (.IND)         ││
│  │  ✦ Planning Unit status  │  │                               ││
│  │  ✦ Member metadata       │  │  Physical files on disk:      ││
│  │    (aliases, UDAs, props)│  │    .OTL, .PAG, .IND,          ││
│  │  ✦ Workflow state        │  │    .ESM, .TCT                  ││
│  │  ✦ Annotations           │  │                               ││
│  │  ✦ Cell-level documents  │  │                               ││
│  │  ✦ Substitution vars     │  │                               ││
│  │                           │  │                               ││
│  │  Physical: Oracle DB      │  │  Physical: File system        ││
│  │  tables, stored in        │  │  on Essbase server             ││
│  │  RDBMS tablespace         │  │                               ││
│  └──────────────────────────┘  └───────────────────────────────┘│
│                                                                  │
│  KEY INSIGHT:                                                    │
│  ─────────────                                                   │
│  When you see "100" in a form cell → that "100" is in Essbase    │
│  When you see the form layout/design → that's in the RDBMS       │
│  The form DEFINITION is relational; the DATA is Essbase          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 9.2 Where Forms Are Saved

### Form Definition Storage

Planning forms are **defined and stored in the relational database** (Oracle RDBMS), NOT in Essbase.

```
RELATIONAL DATABASE TABLES FOR FORMS:
────────────────────────────────────────

HSP_FORM_DEF
  - Form ID, Name, Description
  - Application ID
  - Plan Type (which Essbase cube)
  - Created by, Modified by
  - Form type (simple, composite, ad-hoc)

HSP_FORM_LAYOUT
  - Form ID (FK to HSP_FORM_DEF)
  - Row definitions (which dimensions/members on rows)
  - Column definitions (which dimensions/members on columns)
  - POV definitions (Point of View - fixed dimension members)
  - Page definitions (drop-down selectable members)

HSP_FORM_PROPERTIES
  - Display properties
  - Precision settings
  - Currency display options
  - Enable/disable data input
  - Suppress missing data option
  - Context menus
  - Business rules to launch (on load, on save)

HSP_FORM_ACCESS
  - Which users/groups can access this form
  - Read/write permissions per form
  - Composite form component access

HSP_FORM_VALIDATION_RULES
  - Data validation rules for the form
  - Range checks, cross-validation rules

Example query to see form definitions:
  SELECT * FROM HSP_FORM_DEF WHERE APP_ID = 123;
```

### What Happens When a Form Is Opened

```
USER CLICKS ON FORM "Revenue Input"
        │
        ▼
┌─────────────────────────────────────────────┐
│ 1. PLANNING reads from RELATIONAL DB:        │
│    SELECT * FROM HSP_FORM_DEF                 │
│      WHERE FORM_NAME = 'Revenue Input'        │
│    → Gets form layout definition              │
│                                              │
│ 2. PLANNING reads member selections:          │
│    SELECT * FROM HSP_FORM_LAYOUT              │
│      WHERE FORM_ID = 456                      │
│    → Gets row members: Jan, Feb, Mar, Q1      │
│    → Gets col members: Revenue, COGS, GP      │
│    → Gets POV: FY2024, Actual, Working        │
│                                              │
│ 3. PLANNING applies SECURITY:                 │
│    SELECT * FROM HSP_FORM_ACCESS              │
│      WHERE FORM_ID = 456 AND USER_ID = 789    │
│    → Confirms user has access                  │
│                                              │
│ 4. PLANNING sends DATA REQUEST to ESSBASE:    │
│    "Get me cells at these intersections"       │
│    → Essbase reads blocks, returns values      │
│                                              │
│ 5. PLANNING formats the grid:                 │
│    Apply precision, scaling, colors, etc.      │
│    → Sends HTML/JSON to user's browser         │
└─────────────────────────────────────────────┘
```

---

## 9.3 Where Business Rules Are Saved

### Business Rule / Calc Manager Script Storage

Business Rules (from Calc Manager) are stored in **BOTH** the relational database AND Essbase:

```
STORAGE LOCATIONS FOR BUSINESS RULES:
─────────────────────────────────────────

1. RELATIONAL DATABASE (Primary):
   ┌────────────────────────────────────────────────┐
   │ HSP_CALCRULE                                    │
   │   - Rule ID, Name, Description                  │
   │   - Rule Type (BSO, MDX, template)              │
   │   - Graphical design metadata (Calc Manager UI) │
   │   - Plan Type association                       │
   │   - Deployment status                           │
   │                                                 │
   │ HSP_CALCRULE_COMPONENTS                          │
   │   - Script components (conditions, formulas)     │
   │   - Template references                          │
   │   - Variable definitions                         │
   │   - Component order and nesting                  │
   │                                                 │
   │ HSP_CALCRULE_SCRIPT                              │
   │   - The actual generated calc script text        │
   │   - Compiled/validated status                    │
   │                                                 │
   │ HSP_CALCRULE_RTP                                 │
   │   - Runtime prompts (user input variables)       │
   │   - Default values                               │
   │   - Variable types                               │
   └────────────────────────────────────────────────┘

2. ESSBASE SERVER (Deployed copy):
   ┌────────────────────────────────────────────────┐
   │ $ARBORPATH/app/<AppName>/<DbName>/              │
   │   └── <RuleName>.csc                            │
   │       (The actual calc script file deployed      │
   │        to Essbase for execution)                 │
   └────────────────────────────────────────────────┘
```

### Business Rule Lifecycle

```
1. DESIGN (in Calc Manager UI)
   └── Stored in: RELATIONAL DB (HSP_CALCRULE tables)
   └── What's stored: Graphical design, components, conditions

2. VALIDATE
   └── Calc Manager generates script text from graphical design
   └── Validates against Essbase outline
   └── Script stored in: HSP_CALCRULE_SCRIPT

3. DEPLOY
   └── Script pushed to Essbase server as .CSC file
   └── Registered in Essbase as a calc script
   └── Now TWO copies: relational DB + Essbase filesystem

4. EXECUTE (via form or task list)
   └── Planning tells Essbase: "Run calc script <RuleName>"
   └── Essbase executes: reads/writes blocks per script logic
   └── Results stored in: Essbase .PAG files (data blocks)

5. RESULTS
   └── Modified data is in ESSBASE blocks
   └── User opens form → sees updated values from Essbase
```

---

## 9.4 Where Different Types of Data Are Saved

### Complete Data Location Map

```
╔══════════════════════════════════╤═══════════════════════════════════╗
║ DATA TYPE                        │ STORED IN                         ║
╠══════════════════════════════════╪═══════════════════════════════════╣
║                                  │                                   ║
║ NUMERIC DATA                     │                                   ║
║ ├── Cell values (Revenue=100)    │ Essbase .PAG files (blocks)       ║
║ ├── Aggregated values            │ Essbase .PAG files (blocks)       ║
║ ├── Calculated values            │ Essbase .PAG files (blocks)       ║
║ └── #Missing indicators          │ Essbase .PAG files (compression)  ║
║                                  │                                   ║
║ TEXT/STRING DATA                  │                                   ║
║ ├── Smart List selections         │ Essbase (as numeric IDs in blocks)║
║ │   └── Smart List definitions    │ Relational DB (HSP_SMARTLIST)     ║
║ ├── Cell text/notes               │ Relational DB (HSP_TEXT tables)   ║
║ ├── Cell-level documents          │ Relational DB (HSP_DOCUMENTS)     ║
║ └── Supporting Details            │ Relational DB (HSP_SUPPORT_DET)   ║
║                                  │                                   ║
║ METADATA                          │                                   ║
║ ├── Dimension hierarchies         │ BOTH: Relational + Essbase .OTL  ║
║ ├── Member properties             │ BOTH: Relational + Essbase .OTL  ║
║ ├── Member aliases                │ BOTH: Relational + Essbase .OTL  ║
║ ├── UDAs                          │ BOTH: Relational + Essbase .OTL  ║
║ ├── Member formulas               │ BOTH: Relational + Essbase .OTL  ║
║ └── Attribute associations        │ BOTH: Relational + Essbase .OTL  ║
║                                  │                                   ║
║ APPLICATION OBJECTS               │                                   ║
║ ├── Data forms                    │ Relational DB (HSP_FORM_*)        ║
║ ├── Business rules                │ Relational + Essbase (.CSC)       ║
║ ├── Task lists                    │ Relational DB (HSP_TASKLIST_*)    ║
║ ├── Menus                         │ Relational DB (HSP_MENU_*)        ║
║ ├── Currencies                    │ Relational DB (HSP_CURRENCY_*)    ║
║ ├── Exchange rates                │ Relational DB (HSP_EXCHRATE_*)    ║
║ └── Substitution variables        │ Essbase (in-memory + .ESM)        ║
║                                  │                                   ║
║ SECURITY & ACCESS                 │                                   ║
║ ├── Users and groups              │ Shared Services / LDAP            ║
║ ├── Role assignments              │ Relational DB (HSP_ACCESS_*)      ║
║ ├── Data access (member-level)    │ Relational DB (HSP_ACCESS_CTRL)   ║
║ └── Form access                   │ Relational DB (HSP_FORM_ACCESS)   ║
║                                  │                                   ║
║ WORKFLOW                          │                                   ║
║ ├── Planning unit status          │ Relational DB (HSP_PM_STATUS)     ║
║ ├── Approval status               │ Relational DB (HSP_APPROVAL_*)    ║
║ ├── Annotations                   │ Relational DB (HSP_ANNOTATION_*)  ║
║ └── Audit trail                   │ Relational DB (HSP_AUDIT_*)       ║
║                                  │                                   ║
║ CONFIGURATION                     │                                   ║
║ ├── Application settings          │ Relational DB (HSP_APP_SETTINGS)  ║
║ ├── Essbase configuration         │ Essbase (essbase.cfg file)        ║
║ ├── Database properties           │ Essbase (.ESM file)               ║
║ └── Cache settings                │ Essbase (.ESM + essbase.cfg)      ║
║                                  │                                   ║
╚══════════════════════════════════╧═══════════════════════════════════╝
```

---

## 9.5 The Relational Database Schema (Key Tables)

### EPM Planning Repository — Key Tables

```
MEMBER/DIMENSION TABLES:
────────────────────────
HSP_MEMBER
  - Member_ID, OBJECT_NAME, PARENT_ID
  - DIM_ID (which dimension)
  - DATA_STORAGE (store/dynamic calc/shared/label only)
  - CONSOLIDATION (+, -, ~, etc.)
  - TWO_PASS_CALC flag
  - PLAN_TYPE (which cube)

HSP_ALIAS
  - Member_ID, ALIAS_NAME
  - ALIAS_TABLE_ID

HSP_DIMENSION
  - DIM_ID, DIM_NAME
  - DIM_TYPE (Account, Entity, Period, etc.)
  - DENSE_SPARSE_FLAG (0=Dense, 1=Sparse)

HSP_MEMBER_FORMULA
  - Member_ID, FORMULA_TEXT
  - PLAN_TYPE

FORM TABLES:
────────────────
HSP_FORM_DEF
  - FORM_ID, FORM_NAME, FORM_TYPE
  - PLAN_TYPE
  - CREATED_BY, MODIFIED_DATE

HSP_FORM_DIMENSION
  - FORM_ID, DIM_ID
  - AXIS (ROW, COLUMN, POV, PAGE)
  - MEMBER_SELECTION (member expression)

HSP_FORM_PROPERTY
  - FORM_ID, PROPERTY_NAME, PROPERTY_VALUE
  - e.g., (456, "SuppressMissing", "true")

BUSINESS RULE TABLES:
────────────────────────
HSP_CALCRULE
  - RULE_ID, RULE_NAME, RULE_TYPE
  - PLAN_TYPE
  - DEPLOY_STATUS

HSP_CALCRULE_SCRIPT
  - RULE_ID, SCRIPT_TEXT (CLOB)
  
HSP_CALCRULE_RTP
  - RULE_ID, PROMPT_NAME, PROMPT_TYPE
  - DEFAULT_VALUE, MEMBER_SELECTION

WORKFLOW TABLES:
────────────────────
HSP_PM_STATUS
  - PLANNING_UNIT_ID
  - ENTITY_ID, SCENARIO_ID, VERSION_ID
  - STATUS (Not Started, First Pass, Under Review, Approved, etc.)
  - OWNER

HSP_TASKLIST
  - TASKLIST_ID, TASKLIST_NAME
  - OWNER, DUE_DATE

HSP_TASK
  - TASK_ID, TASKLIST_ID
  - TASK_TYPE (form, business rule, URL, etc.)
  - TASK_ORDER
  - ASSOCIATED_OBJECT_ID (which form/rule)
```

---

## 9.6 The Synchronization Problem: Relational ↔ Essbase

Because metadata exists in BOTH places, synchronization is critical:

```
SYNCHRONIZATION FLOW:

Planning Application                    Essbase
(Relational DB)                         (Cube)
──────────────────                     ─────────

Admin adds member          ──────►     Outline updated (.OTL)
in Planning UI                         Data restructured (if needed)
└── HSP_MEMBER table                   New member available for blocks
    updated                            

Admin modifies form        (no sync)   Nothing changes in Essbase
in Planning UI                         Forms are relational only
└── HSP_FORM_DEF 
    updated

Admin deploys              ──────►     .CSC file created/updated
Business Rule                          on Essbase file system
└── HSP_CALCRULE_SCRIPT
    → generates script

User inputs data           ──────►     Block updated in .PAG
via form                               Cell value written
└── Planning sends API 
    call to Essbase

User opens form            ◄──────     Essbase returns cell values
                                       from .PAG blocks
└── Planning reads form 
    def from relational,
    data from Essbase

REFRESH DATABASE           ──────►     Full outline sync
(Admin action)                         Planning → Essbase
                                       Ensures metadata in sync
```

### When Things Go Out of Sync

```
PROBLEM: Relational DB and Essbase outline are out of sync

Symptoms:
  - Members visible in Planning UI but not in Smart View
  - Forms show errors about missing members
  - Business rules fail with "member not found"
  - Data loads reject valid records

Fix:
  1. Refresh database (Planning → Essbase sync)
  2. If that fails → delete and recreate the Essbase cube
  3. Re-deploy all business rules
  4. Restart Planning application
```

---

## 9.7 Data Load Rules Files (.RUL) — Where They Live

```
RULES FILES STORAGE:

1. ON ESSBASE SERVER FILESYSTEM:
   $ARBORPATH/app/<AppName>/<DbName>/
   └── <RuleName>.rul         (binary format, created by EAS/MaxL)
   
2. REFERENCED IN ESSBASE METADATA:
   Registered in the Essbase application catalog
   Visible via EAS, MaxL, or Smart View
   
3. NOT IN THE RELATIONAL DATABASE:
   Rules files are Essbase-native objects
   They are NOT managed by Planning
   
4. FOR DATA MANAGEMENT (FDMEE/DM):
   Data integration rules are in the RELATIONAL DB
   └── FDMEE repository tables
   └── Data Management configuration
   └── These are DIFFERENT from Essbase rules files
```

---

## 9.8 Where Substitution Variables Live

```
SUBSTITUTION VARIABLES:

Scope         Location              Example
──────────────────────────────────────────────────
Server        Essbase server        &CurrMonth = "Jan"
              in-memory + .ESM      Available to ALL apps

Application   Essbase application   &CurrYear = "FY2024"
              in-memory + .ESM      Available to all DBs in app

Database      Essbase database      &CurrScenario = "Actual"
              in-memory + .ESM      Available to this DB only

Planning also maintains substitution variables in:
  HSP_SUBST_VAR table in relational DB
  These are synced to Essbase during refresh

How they're used:
  - In forms: POV can use &CurrMonth
  - In business rules: FIX(&CurrYear)
  - In Smart View: @HspSubVar("CurrMonth")
  - In data loads: Can reference in rules file
```

---

## 9.9 Backup and Migration — What to Back Up

### What Needs to Be Backed Up

```
FOR COMPLETE RECOVERY:

1. RELATIONAL DATABASE (Oracle RDBMS)
   └── Full database backup using RMAN or Data Pump
   └── Contains: forms, rules, security, metadata, workflows
   └── This is the MOST CRITICAL backup

2. ESSBASE FILES
   └── $ARBORPATH/app/<AppName>/<DbName>/
   └── Files: .OTL, .PAG, .IND, .ESM, .TCT, .CSC, .RUL
   └── Contains: data, outline, calc scripts, rules files

3. SHARED SERVICES (CSS)
   └── User/group definitions
   └── Provisioning (role assignments)

4. CONFIGURATION FILES
   └── essbase.cfg (Essbase server config)
   └── Planning application properties
   └── Web server configuration

FOR DATA-ONLY BACKUP:
   └── Export data from Essbase (flat file or LCM)
   └── This is the fastest way to restore data
   └── Does NOT include forms, rules, or security
```

### LCM (Lifecycle Management) — What It Exports

```
LCM Export Contents:
  ├── /HSP_Info/                  (from Relational DB)
  │   ├── Smart Lists
  │   ├── Exchange Rates
  │   ├── Planning Units
  │   └── Application Settings
  │
  ├── /resource/                  (from Relational DB)
  │   ├── Data Forms
  │   ├── Composite Forms
  │   ├── Task Lists
  │   ├── Menus
  │   └── Calc Manager Rules
  │
  ├── /Global Artifacts/          (from Shared Services)
  │   ├── User Groups
  │   └── Provisioning
  │
  └── /<AppName>/                 (from Essbase)
      ├── Outline (.OTL)
      ├── Calc Scripts (.CSC)
      ├── Rules Files (.RUL)
      ├── Data (optional - flat file export)
      ├── Security filters
      └── Substitution variables
```

---

## Summary

> **EPM Forms, Business Rules, Task Lists, and most application metadata are stored in the RELATIONAL DATABASE (Oracle RDBMS), not in Essbase. The actual DATA (cell values, numbers) is stored in Essbase .PAG files. Member metadata exists in BOTH locations and must be kept in sync. Business Rules exist in the relational DB (design) and as .CSC files on Essbase (execution). Understanding this dual-storage architecture is essential for backup, migration, troubleshooting, and understanding where to look when things go wrong.**

---

**← Previous:** [08 — Sparse-Dense Interchange Impact](./08_Sparse_Dense_Interchange_Impact.md)  
**Next →** [10 — Behind the Scenes Complete Walkthrough](./10_Behind_The_Scenes_Complete.md)

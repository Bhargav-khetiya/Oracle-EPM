# NotebookLM Prompt — Oracle EPM Cloud Data Integration: Complete Deep Dive Tutorial

---

## INSTRUCTIONS FOR NOTEBOOKLM

You are creating a complete, next-level, AI-based tutorial and reference guide for **Oracle EPM Cloud Data Integration** (also known as Data Management / FDMEE). This must be the most thorough, detailed, and practical guide ever created on this topic. Cover EVERY click, EVERY option, EVERY property, EVERY screen, EVERY scenario, EVERY error, and EVERY best practice.

The audience ranges from absolute beginners (who have never opened EPM Cloud) to advanced administrators who need edge-case details. Explain things so clearly that someone with zero EPM experience could follow along, but include enough depth that a 10-year veteran learns something new.

Use a conversational, engaging tone — like a brilliant mentor explaining to a colleague. Use tables, diagrams (described in text), flowcharts, decision trees, real-world analogies, and step-by-step walkthroughs for every concept.

---

## SECTION 1: THE BIG PICTURE — WHY DATA INTEGRATION EXISTS

### Cover these topics in extreme detail:

1. **What is Oracle EPM Cloud—**
   - Explain Planning, Budgeting, Financial Consolidation (FCCS), Tax Reporting, Account Reconciliation
   - Explain that EPM Cloud applications have multiple "plan types" (cubes) — BSO (Block Storage) and ASO (Aggregate Storage)
   - Explain that these cubes store financial data organized by dimensions (Account, Entity, Period, Year, Scenario, Version, etc.)

2. **The Fundamental Problem Data Integration Solves**
   - EPM Cloud is where financial planning, budgeting, and consolidation happen
   - But the actual transactional data lives in ERP systems (Oracle ERP Cloud, SAP, Oracle EBS, PeopleSoft, NetSuite, custom databases)
   - Someone needs to move data FROM the ERP INTO EPM Cloud — that's what Data Integration does
   - Analogy: EPM Cloud is the "kitchen" where recipes (budgets, forecasts) are prepared. Data Integration is the "delivery truck" that brings raw ingredients (actual GL data) from the warehouse (ERP)

3. **The Data Integration Ecosystem — All the Ways Data Moves in EPM Cloud**
   - Draw a complete map of every data movement method:
     - **Data Integration** (this guide): External systems → EPM Cloud
     - **Data Maps**: EPM Cube → EPM Cube (batch, full refresh)
     - **Smart Push**: EPM Cube → EPM Cube (delta, real-time, form save)
     - **@XWRITE**: Programmatic cube-to-cube write during calculations
     - **@XREF**: Programmatic cube-to-cube read during calculations
     - **DATACOPY**: Within same cube, same structure copy
     - **Groovy Scripts**: Programmatic automation of any of the above
     - **EPM Automate**: Command-line automation
     - **REST APIs**: External system automation
   - Explain when to use each one with a decision flowchart

4. **History and Evolution**
   - FDMEE (Financial Data Quality Management Enterprise Edition) — the on-premise predecessor
   - Data Management — the cloud version of FDMEE, embedded in EPM Cloud
   - Data Integration — the modern, next-gen UI built on top of Data Management
   - Both Data Management and Data Integration exist simultaneously — they are two views of the same engine
   - Changes in one are automatically reflected in the other

---

## SECTION 2: NAVIGATION — HOW TO GET THERE (EVERY CLICK)

### Cover every navigation path:

1. **Accessing Data Integration (Modern UI)**
   - Login to EPM Cloud
   - Click the **Navigator** (hamburger menu, top-left)
   - Under **Data Exchange**, click **Data Integration**
   - Describe the landing page: list of integrations, search bar, create button, actions menu
   - Every button on this screen: Create, Edit, Delete, Run, Schedule, Clone, Export, Import

2. **Accessing Data Management (Legacy UI)**
   - Login to EPM Cloud
   - Click the **Navigator**
   - Under **Data Exchange**, click **Data Management**
   - Describe the landing page: Setup tab, Workflow tab, Batch Processing tab
   - Every menu item: Setup → Define Integration, Target Application, Import Format, Location, Data Load Mapping, etc.

3. **Accessing from Data Exchange Card**
   - Home page → Data Exchange card
   - Inbox/Outbox, Data Maps, Smart Push, Data Integration — all accessible from here

4. **Required Security Roles**
   - Which roles can access Data Integration: Service Administrator, Power User, Data Manager
   - What each role can and cannot do
   - How to assign roles: Navigator → Tools → Access Control

---

## SECTION 3: THE FIVE CORE COMPONENTS — EXHAUSTIVE DETAIL

### COMPONENT 1: SOURCE SYSTEM

**Explain every source type with setup steps:**

#### A. File-Based Source
- What file formats are supported: CSV (comma-separated), TXT (tab/pipe/custom delimited), Fixed-width
- Where files are uploaded: the Inbox folder
- How to upload: UI upload, EPM Automate `uploadFile`, REST API
- File naming conventions
- Character encoding (UTF-8 recommended)
- Maximum file size limits
- How to handle files with special characters, line breaks in data, quoted fields

#### B. Oracle ERP Cloud Source (Direct Connect)
- How the direct connection works (no file transfer needed)
- How to register Oracle ERP Cloud as a source
- What data can be pulled: GL Balances, Subledger data, Journal entries
- Connection configuration: Service URL, credentials
- Pre-built extract rules vs. custom queries

#### C. On-Premise Database Source (via EPM Integration Agent)
- Full EPM Agent architecture (see Section 7 for deep dive)
- Supported databases: Oracle DB, SQL Server, MySQL, IBM DB2, PostgreSQL
- JDBC driver configuration for each database type
- Connection string format for each database type
- SQL query definition for data extraction
- How to test the connection

#### D. Other EPM Application Source
- Loading from one EPM business process to another
- Cross-application data movement

#### E. NetSuite Source
- Direct connection to Oracle NetSuite
- Pre-built integrations
- Saved search-based extraction

**Properties and settings for each source type:**

| Property | Description | Example |
|----------|-------------|---------|
| Source System Name | Unique identifier | `Oracle_ERP_Cloud_GL` |
| Source Type | File / ERP Cloud / On-Premise / etc. | `File` |
| Connection Details | URL, credentials, JDBC string | varies by type |
| Agent | Which EPM Agent to use (if on-premise) | `FINANCE_AGENT_01` |

---

### COMPONENT 2: IMPORT FORMAT

**Explain every property and option:**

#### What is an Import Format—
- Think of it as a "column mapping blueprint" — it tells the system how to read the source data
- It maps each column in your source file (or SQL query result) to a dimension in the target EPM application

#### Creating an Import Format (Every Click):
1. Navigate: Data Management → Setup → Import Format (or Data Integration → Actions → Import Format)
2. Click **Add** (+)
3. Enter properties:

| Property | Description | Options |
|----------|-------------|---------|
| Name | Unique name for this format | e.g., `GL_Monthly_Import` |
| Description | Free-text description | e.g., `Monthly GL data from ERP` |
| Source | Which source system this format reads from | Select from registered sources |
| Target | Which EPM application this format maps to | Select from registered applications |
| File Type | How the source file is structured | `Delimited`, `Fixed Width`, `Multi-Column` |
| Delimiter | Character separating columns (for delimited files) | `Comma`, `Tab`, `Pipe`, `Semicolon`, `Tilde`, `Custom` |
| Header Rows | Number of rows to skip at the top | `1` (most common — skip the header row) |

#### Column Mapping Detail:

For each column in your source, you define:

| Setting | Description | Example |
|---------|-------------|---------|
| Column Number | Which column in the source (1-based) | `1` |
| Mapped To | Which EPM dimension this column feeds | `Account`, `Entity`, `Period`, `Year`, `Scenario`, `Amount` |
| Expression | Optional transformation formula | `SUBSTR(source_value, 1, 5)` to take first 5 chars |

**Special columns:**
- **Amount**: The numeric data column (must have exactly one)
- **Attribute dimensions**: Optional UDA/attribute mapping
- **Account type**: If FCCS, maps to account type (Asset, Liability, etc.)

#### Import Format for Different File Types:

**Delimited file example:**
```
Account,Entity,Period,Year,Scenario,Amount
40100,CC-1001,JAN,2025,ACTUAL,50000
40200,CC-1001,JAN,2025,ACTUAL,25000
```
Mapping: Col1→Account, Col2→Entity, Col3→Period, Col4→Year, Col5→Scenario, Col6→Amount

**Fixed-width file example:**
```
40100CC-1001JAN 202550000
40200CC-1001JAN 202525000
```
Mapping: Position 1-5→Account, Position 6-12→Entity, Position 13-15→Period, Position 16-19→Year, Position 20-25→Amount

**Multi-column (matrix) file example:**
```
Account,Entity,Jan,Feb,Mar
40100,CC-1001,50000,52000,48000
40200,CC-1001,25000,26000,24000
```
Period is derived from the column header, not from a data column.

---

### COMPONENT 3: TARGET APPLICATION

**Explain every aspect of registering and configuring target applications:**

#### What is a Target Application—
- The destination EPM business process where data will land
- Could be: Planning (FinStmt BSO), Planning (Reporting ASO), FCCS, Tax Reporting, Freeform

#### Registration:
1. Navigate: Data Management → Setup → Target Application
2. Click **Add** (+)
3. Select the application type and specific plan type (cube)
4. Configure dimension mapping (which EPM dimensions are available for mapping)

#### Target Application Properties:

| Property | Description | Example |
|----------|-------------|---------|
| Application Name | The EPM business process | `Vision Planning` |
| Plan Type | Which cube within the application | `FinStmt`, `Workforce`, `Revenue` |
| Type | BSO or ASO | `BSO` |
| Dimensions | List of dimensions available for mapping | Account, Entity, Period, Year, Scenario, Version, etc. |
| Currency | Whether multi-currency is enabled | `Yes/No` |

#### Application Options (Critical Settings):

| Option | Description | Values |
|--------|-------------|--------|
| Enable Drill Through | Allow users to drill from forms back to source | `Yes / No` |
| Accumulate Data within Source | How duplicate rows in the source are handled | `Yes (sum them) / No (last wins)` |
| Allow Drill Down on Shared Members | Whether drill-through works on shared members | `Yes / No` |
| Support Entity Currency | Load data with currency tags | `Yes / No` |

---

### COMPONENT 4: LOCATION

**Explain every property and concept:**

#### What is a Location—
- A Location is a **container** that groups together: Source System + Import Format + Target Application + Mappings + Data Load Rules
- Think of it as a named "pipeline" — everything needed to execute a specific type of data load
- You can have multiple Locations for different load scenarios (e.g., `GL_Actuals_Load`, `Budget_Upload`, `Headcount_Load`)

#### Creating a Location (Every Click):
1. Navigate: Data Management → Setup → Define Integration → Location
2. Click **Add** (+)
3. Enter properties:

| Property | Description | Example |
|----------|-------------|---------|
| Name | Unique identifier | `GL_Monthly_Actuals` |
| Description | Free-text | `Monthly GL actuals from Oracle ERP` |
| Import Format | Which Import Format to use | `GL_Import_Format` |
| Location Type | Direction of data flow | `Import` (source → EPM) or `Export` (EPM → external) |
| Target Application | Which EPM application receives the data | `Planning - FinStmt` |
| Functional Currency | Default currency | `USD` |
| Data Exchange Method | How data is exchanged | `File`, `Direct`, `Agent` |

#### Location Context:
- A Location also stores the **period mapping** and **category mapping** context
- When you run a data load, you select a Location + Period + Category

---

### COMPONENT 5: MEMBER MAPPINGS (DATA LOAD MAPPINGS)

**This is the most critical section — explain every mapping type in extreme detail:**

#### What are Member Mappings—
- Translation rules that convert source system codes to EPM dimension member names
- Example: Your ERP uses account code `40100`, but EPM uses member name `Revenue_Product_Sales`
- Without mappings, the load would fail because EPM doesn't have a member called `40100`

#### Navigating to Mappings:
1. Data Management → Setup → Data Load Mapping
2. Select your Location
3. Select the Dimension to map (Account, Entity, etc.)
4. Click **Add** to create a new mapping rule

#### Mapping Types — EXHAUSTIVE Detail:

##### TYPE 1: EXPLICIT MAPPING
- **What it is**: A direct, 1-to-1 translation. Source value X always becomes target value Y.
- **Properties**:

| Field | Description | Example |
|-------|-------------|---------|
| Source Value | Exact source value to match | `40100` |
| Target Value | EPM member name to translate to | `Revenue_Product_Sales` |
| Processing Order | Evaluation priority (lower = evaluated first) | `1` |

- **When to use**: When you know every source code and its corresponding EPM member
- **Performance**: Best for small to medium member counts
- **Example**: Map 500 ERP account codes to 500 EPM account members

##### TYPE 2: LIKE MAPPING (WILDCARD)
- **What it is**: Pattern-based matching using wildcards
- **Wildcards**:
  - `*` — matches any number of characters
  - `—` — matches exactly one character
- **Properties**:

| Field | Description | Example |
|-------|-------------|---------|
| Source Value | Pattern with wildcards | `40*` |
| Target Value | EPM member (can include `*` to carry over matched text) | `Revenue_*` |
| Processing Order | Priority | `10` |

- **Examples**:
  - `40*` → `Revenue_*` : Source `40100` becomes `Revenue_100`
  - `*_ELIM` → `*_Elimination` : Source `US_ELIM` becomes `US_Elimination`
  - `6———0` → `Admin_————` : Source `60010` becomes `Admin_0010`

- **When to use**: When source and target follow naming conventions
- **Performance**: Excellent for large member counts (one rule handles thousands of members)

##### TYPE 3: BETWEEN MAPPING (RANGE)
- **What it is**: Maps a range of source values to a single target value
- **Properties**:

| Field | Description | Example |
|-------|-------------|---------|
| Source Start | Beginning of the range | `40100` |
| Source End | End of the range | `40199` |
| Target Value | EPM member | `Revenue_Summary` |

- **When to use**: When ERP chart of accounts follows numeric ranges
- **Example**: All accounts from 40100-40199 are revenue accounts → map to `Revenue_Summary`

##### TYPE 4: IN MAPPING (LIST)
- **What it is**: Maps a specific list of non-sequential source values to one target
- **Properties**:

| Field | Description | Example |
|-------|-------------|---------|
| Source Values | Comma-separated list | `40100, 40250, 40375` |
| Target Value | EPM member | `Revenue_All` |

- **When to use**: When you need to map scattered values that don't follow a pattern or range

##### TYPE 5: MULTI-DIMENSION MAPPING
- **What it is**: Maps based on COMBINATIONS of multiple source columns
- **Properties**:

| Source Account | Source Entity | → | Target Account |
|----------------|---------------|---|----------------|
| `40100` | `US` | → | `Revenue_US` |
| `40100` | `UK` | → | `Revenue_UK` |
| `50100` | `*` | → | `COGS_*` |

- **When to use**: When the target member depends on a combination of source fields

#### Mapping Processing Order (Precedence):
1. **Multi-Dimension** (most specific — wins first)
2. **Explicit** (exact match)
3. **Between** (range match)
4. **In** (list match)
5. **Like** (pattern match — least specific)

If multiple rules of the same type could match, the one with the lowest **Processing Order** number wins.

#### Special Target Values:

| Target Value | Meaning |
|-------------|---------|
| `#IGNORE` | Skip this row — do not load it |
| `#MULTIMATCH` | Flag for multi-dimension lookup |

#### Importing/Exporting Mappings in Bulk:
- You can export all mappings to CSV/Excel for backup
- You can import mappings from CSV for bulk setup
- EPM Automate command: `epmautomate importMapping "LocationName" DimensionName MappingFile.csv`
- Import modes: **Merge** (add to existing) or **Replace** (clear and reload)

---

## SECTION 4: THE FOUR-STAGE EXECUTION PIPELINE

### Explain each stage with extreme detail:

#### STAGE 1: IMPORT
- What happens technically: data is extracted from the source and loaded into an intermediate staging table inside EPM Cloud
- For file-based loads: the system reads the file from the Inbox, parses it according to the Import Format, and stages each row
- For agent-based loads: the EPM Agent executes the SQL query against the on-premise database, retrieves results, and sends them to EPM Cloud
- Import Modes (explain each with scenarios):
  - **Append**: Adds to existing staged data without clearing. Use when loading from multiple files before a single export.
  - **Replace**: Clears ALL staged data for this Location/Period/Category, then imports fresh. Use for standard monthly loads.
  - **Map and Validate**: Imports and immediately applies mappings. Combines Stage 1 and Stage 2.
  - **No Import**: Skips import entirely. Use when re-exporting previously imported data after fixing mappings.
  - **Direct**: Bypasses staging entirely — loads directly into the target. Use for pre-mapped, clean data for maximum performance.
- What the staging table looks like (describe the TDATASEG table structure)
- Row count limits and performance considerations

#### STAGE 2: VALIDATE (MAP)
- What happens technically: each row in the staging table is checked against the member mappings
- For each dimension, the system:
  1. Looks for a Multi-Dimension mapping match
  2. If not found, looks for an Explicit match
  3. If not found, looks for a Between match
  4. If not found, looks for an In match
  5. If not found, looks for a Like match
  6. If still not found → MAPPING ERROR
- Successfully mapped rows get status = "Valid"
- Failed rows get status = "Mapping Error" or "Validation Error"
- Describe every possible error type and how to fix each one

#### STAGE 3: EXPORT
- What happens technically: validated data is pushed into the target EPM application (the Essbase cube)
- Export Modes (explain each with scenarios and implications):
  - **Merge**: Loads data; existing data not in the load is preserved. Like an UPDATE + INSERT.
  - **Replace**: Clears the POV scope in the target cube first, then loads. Like a DELETE + INSERT.
  - **Accumulate**: Adds loaded values to existing values. Like SUM(existing + new).
  - **Subtract**: Subtracts loaded values from existing values. Like SUM(existing - new).
  - **No Export**: Data stays in staging. Use for dry runs.
  - **Check**: Exports and then runs a verification check.
- How "Replace" determines what to clear: it uses the Category (Scenario), Period, and other POV dimensions
- The difference between logical clear and physical clear in BSO vs. ASO targets
- How many rows can be exported in a single load
- What happens if the export partially fails

#### STAGE 4: CHECK (Optional)
- Post-export verification
- Custom validation scripts can be triggered
- How to set up check rules

---

## SECTION 5: THE WORKBENCH — TROUBLESHOOTING HEADQUARTERS

### Explain every screen, tab, button, and action:

#### Accessing the Workbench:
1. Data Management → Workflow → Data Load Workbench
2. Select the Location, Period, and Category
3. Click **Go** to load the workbench

#### Workbench Tabs:

**Tab 1: Source (Imported Data)**
- Shows raw imported data before mapping
- Columns: each source column as defined in the Import Format
- Row count
- Filter and search capabilities

**Tab 2: Target (Mapped Data)**
- Shows data after mapping has been applied
- Source values alongside their mapped target values
- Status column: Valid, Mapping Error, Validation Error
- Each mapped dimension shown

**Tab 3: Validation Errors**
- Shows only rows that failed mapping
- Error details: which dimension failed, what the source value was
- **Fix Maps** button: click to jump directly to the mapping screen for that dimension
- After fixing, click **Validate** to re-process

**Tab 4: Landing (Exported Data)**
- Shows what was actually loaded into the target cube
- Row counts: loaded vs. skipped vs. failed

#### Workbench Actions:
- **Import**: Re-run the import stage
- **Validate**: Re-run the mapping/validation stage
- **Export**: Push data to the target
- **Check**: Run verification
- **Drill Through**: Click a cell to see its source lineage

---

## SECTION 6: DATA INTEGRATION (MODERN UI) — COMPLETE WALKTHROUGH

### Explain the entire Data Integration modern UI:

#### The Integration List Page:
- Displays all defined integrations as cards or a list
- Search, filter, sort capabilities
- **Create** button to create a new integration
- **Actions** menu: Edit, Delete, Clone, Run, Schedule, Map Dimensions, Map Members, Options

#### Creating a New Integration (Every Click):

**Step 1: General Settings**

| Field | Description |
|-------|-------------|
| Name | Integration name |
| Description | Free-text description |
| Category | Group/tag for organization |

**Step 2: Source**

| Field | Description |
|-------|-------------|
| Source Application | Select from registered sources or "File" |
| File Name | If file-based, specify the filename pattern |
| Delimiter | For delimited files |

**Step 3: Target**

| Field | Description |
|-------|-------------|
| Target Application | Select the EPM application |
| Plan Type | Which cube |
| Data Load Method | Numeric data / File-based |

**Step 4: Map Dimensions**
- Auto-map same-named dimensions
- Manually map remaining dimensions
- For each dimension, select the source column

**Step 5: Map Members (Filters)**
- Define which members to include/exclude
- Set default members for dimensions not in the source
- Period mapping, year mapping

**Step 6: Options**
- Import Mode: Append, Replace, Map and Validate, No Import, Direct
- Export Mode: Merge, Replace, Accumulate, Subtract, No Export, Check
- Row/column header options
- Date format
- Drill-through settings

**Step 7: Schedule (Optional)**
- Immediate execution or scheduled
- Recurrence pattern: Daily, Weekly, Monthly

**Step 8: Run**
- Execute the integration
- Monitor in Jobs console

#### Quick Mode vs. Standard Mode:
- **Quick Mode**: Simplified 3-step setup for basic file loads. Source → Dimension Mapping → Run.
- **Standard Mode**: Full setup with all options. For complex scenarios.

---

## SECTION 7: EPM INTEGRATION AGENT — DEEP DIVE

### Cover every aspect of the agent:

#### What is it—
- A lightweight Java application that runs inside your corporate network
- Bridges EPM Cloud and on-premise databases
- Eliminates the need for manual CSV file creation and upload

#### Architecture Diagram (describe in detail):
- The agent sits on a server inside the firewall
- It connects to your database via JDBC
- It communicates with EPM Cloud via HTTPS (outbound only in async mode)
- Draw the complete data flow: Database → JDBC → Agent → HTTPS/SSL → EPM Cloud

#### Two Modes:
1. **Synchronous**: EPM Cloud initiates the connection (requires inbound firewall rule)
2. **Asynchronous** (Recommended): Agent polls EPM Cloud for jobs (outbound HTTPS only — more secure)

#### Installation Steps (Every Click):
1. Download agent: EPM Cloud → Data Exchange → Agent
2. Unzip to a directory on the target server
3. Install Java JRE 8+ (if not already installed)
4. Run `createAppFolder.bat` (Windows) or `createAppFolder.sh` (Linux)
5. Edit `agent.properties` file:
   - EPM Cloud URL
   - Agent name
   - Communication mode (sync/async)
   - Polling interval (for async mode)
6. Start the agent: `startAgent.bat` or `startAgent.sh`
7. Register in EPM Cloud: Data Integration → Agent → Register

#### Database-Specific JDBC Configuration:

**Oracle Database:**
```
Driver: oracle.jdbc.OracleDriver
URL: jdbc:oracle:thin:@//hostname:1521/servicename
```

**SQL Server:**
```
Driver: com.microsoft.sqlserver.jdbc.SQLServerDriver
URL: jdbc:sqlserver://hostname:1433;databaseName=FINANCE_DB
```

**MySQL:**
```
Driver: com.mysql.cj.jdbc.Driver
URL: jdbc:mysql://hostname:3306/database_name
```

#### Agent Clusters:
- Multiple agents can be deployed in a cluster
- Load balancing across agents
- Failover if one agent goes down
- Configuration steps for clustering

#### Agent Troubleshooting:
- Log files location and format
- Common errors: Java version mismatch, JDBC driver missing, connection timeout
- How to test the connection independently
- Monitoring agent health from EPM Cloud

---

## SECTION 8: PERIOD AND CATEGORY MAPPING

### Explain these often-overlooked but critical mappings:

#### Period Mapping:
- Maps source period codes to EPM period members
- Example: `JAN-2025` → `Jan`, `FEB-2025` → `Feb`
- Configuration: Data Management → Setup → Period Mapping
- Period key format: `Month Year` (e.g., `Jan 2025`)
- Fiscal year vs. Calendar year considerations
- How to handle custom fiscal periods (e.g., 4-4-5 calendar)
- Prior period mapping for comparative loads

#### Category Mapping:
- Maps source scenario/category codes to EPM Scenario and Version
- Example: `ACTUAL` → Scenario: `Actual`, Version: `Final`
- Example: `BUDGET_V1` → Scenario: `Budget`, Version: `Working`
- Configuration: Data Management → Setup → Category Mapping

---

## SECTION 9: DRILL-THROUGH CONFIGURATION

### Explain the complete drill-through setup:

#### What is Drill-Through—
- Users click on a cell in an EPM form/report and see the original source transactions
- Provides audit trail and data lineage

#### Setup Steps:
1. Enable drill-through in the Target Application options
2. Ensure the data was loaded through Data Integration (not manually entered)
3. Configure drill-through regions in the dimension mapping
4. Set up user permissions for drill access

#### Drill-Through Behavior:
- What the user sees when they click
- How the system traces back: Target member → Mapping → Staging table → Source data
- URL drill-through (linking to source ERP screens)
- Data drill-through (showing source transaction details in EPM)

---

## SECTION 10: EPM AUTOMATE COMMANDS — COMPLETE REFERENCE

### Cover every relevant command with syntax, parameters, and examples:

#### Login/Logout:
```
epmautomate login username password_file URL
epmautomate logout
```

#### File Management:
```
epmautomate uploadFile "localpath/file.csv" inbox
epmautomate downloadFile "outbox/report.csv" "localpath/"
epmautomate listFiles inbox
epmautomate deleteFile "inbox/old_file.csv"
```

#### Running Integrations:
```
epmautomate runIntegration "IntegrationName" importMode=Replace exportMode=Merge periodName=Jan inputFileName=file.csv
epmautomate runDataRule "RuleName" startPeriod endPeriod importMode exportMode [fileName]
```

#### Import/Export Modes (via EPM Automate):

| importMode | Meaning |
|-----------|---------|
| APPEND | Add to existing staged data |
| REPLACE | Clear and reload staged data |
| MAP_AND_VALIDATE | Import + map in one step |
| NONE | Skip import |

| exportMode | Meaning |
|-----------|---------|
| MERGE | Add/update without clearing target |
| REPLACE | Clear target scope, then load |
| ACCUMULATE | Add to existing target values |
| SUBTRACT | Subtract from existing target values |
| NONE | Skip export |
| CHECK | Export + verify |

#### Mapping Management:
```
epmautomate importMapping "LocationName" DimensionName MappingFile.csv REPLACE
epmautomate exportMapping "LocationName" DimensionName OutputFile.csv
```

#### Scheduling:
```
epmautomate runIntegration "GL_Load" importMode=Replace exportMode=Merge periodName=Jan
```
Schedule via Windows Task Scheduler or Linux Cron to run the above command at desired frequency.

#### Sample Complete Automation Script:
Provide a full Windows batch script and Linux shell script that:
1. Logs in to EPM Cloud
2. Uploads a file
3. Runs the integration
4. Checks for errors
5. Downloads error file if any
6. Sends email notification
7. Logs out

---

## SECTION 11: COMPLETE REAL-WORLD SCENARIOS

### Scenario 1: Monthly GL Actuals Load from CSV File
- End-to-end walkthrough from file creation to verified data in EPM
- Every click, every screen, every setting
- What the file looks like, what the mappings look like, what the result looks like

### Scenario 2: On-Premise Database Load via EPM Agent
- SQL Server GL data → EPM Agent → EPM Cloud Planning
- Complete SQL query, agent configuration, import format, location, mappings, execution

### Scenario 3: Oracle ERP Cloud Direct Integration
- Pre-built connector setup
- GL Balance extract
- Period-based incremental loads

### Scenario 4: Multi-Period Bulk Load
- Loading 12 months of data at once
- Period mapping configuration
- Replace vs. Merge considerations for bulk loads

### Scenario 5: Budget Upload from Excel Template
- User fills Excel template → saves as CSV → uploads to Inbox → Data Integration loads
- Template design, file format, validation, error handling

### Scenario 6: Intercompany Elimination Load
- Loading elimination entries
- Multi-dimension mapping for IC accounts
- Accumulate mode for adjustment entries

### Scenario 7: Metadata Load (Dimension Members)
- Loading new accounts, entities, or other dimension members
- Import Format for metadata
- Data Storage property mapping (Store Data, Dynamic Calc, Shared)
- Refresh Database after metadata load

---

## SECTION 12: ERROR HANDLING AND TROUBLESHOOTING GUIDE

### Cover every possible error with cause and resolution:

#### Mapping Errors:
- Unmapped member: source value not found in any mapping rule
- Invalid target member: mapped to a member that doesn't exist in EPM
- Ambiguous mapping: multiple rules match the same source value

#### Import Errors:
- File not found in Inbox
- Delimiter mismatch
- Wrong number of columns
- Non-numeric data in amount column
- Character encoding issues
- Header row not skipped

#### Export Errors:
- Target cube locked (maintenance running)
- Security violation (user lacks access)
- Invalid intersection in target (member combinations that don't exist)
- BSO block creation limits exceeded

#### Agent Errors:
- Agent offline or not responding
- JDBC connection failure
- SQL query syntax error
- Query timeout (data too large)
- Authentication failure

#### Log Files:
- Where to find them: Process Details → Download Logs
- How to read them: error codes, timestamps, row numbers
- Common error messages and their meanings

---

## SECTION 13: PERFORMANCE OPTIMIZATION

### Cover every optimization technique:

1. **File optimization**: Pre-sort, remove unnecessary columns, compress
2. **Mapping optimization**: Use Like mappings over Explicit for large member counts
3. **Import optimization**: Direct mode for pre-mapped data
4. **Export optimization**: Merge for delta loads, Replace for full refresh
5. **Agent optimization**: Place agent near database, use agent clusters
6. **SQL optimization**: Pre-aggregate in SQL, use indexes, limit row count
7. **Scheduling optimization**: Stagger loads, avoid peak hours
8. **Parallel execution**: Running multiple integrations simultaneously

---

## SECTION 14: COMPARISON TABLE — ALL DATA MOVEMENT METHODS

Create an exhaustive comparison table covering:
- Data Integration vs. Data Maps vs. Smart Push vs. @XWRITE vs. @XREF vs. DATACOPY vs. Groovy
- For each: direction, source types, target types, transformation capability, performance, automation, error handling, drill-through, comments/attachments support, BSO/ASO support, security model

---

## SECTION 15: BEST PRACTICES CHECKLIST

Provide a numbered, actionable checklist of best practices:
1. Always use Replace import mode for standard loads
2. Use Merge export for incremental loads, Replace for full refresh
3. Create Like mappings as fallback for new members
4. Set up drill-through for audit trail
5. Use EPM Automate for scheduled loads
6. Monitor the Jobs console after every load
7. Test in a non-production environment first
8. Document all mappings in an external spreadsheet
9. Use agent clusters for production
10. Keep file sizes under 500MB
11. Pre-aggregate in SQL for database-based loads
12. Set up email alerts for load failures
13. Refresh Database after metadata loads
14. Use Direct import mode for pre-mapped data
15. Archive source files after successful loads

---

## FORMAT REQUIREMENTS

- Use headers and subheaders for clear organization
- Include tables for every comparison and property list
- Use code blocks for SQL, scripts, file examples
- Include text-based diagrams/flowcharts for architecture and data flow
- Use numbered step-by-step lists for every walkthrough
- Include "Pro Tip" callouts for advanced insights
- Include "Common Mistake" callouts for pitfalls
- Include "Real-World Example" callouts for practical scenarios
- Use analogies and metaphors to explain complex concepts
- Keep the tone conversational but professional — like a senior consultant teaching a junior team member
- Make it comprehensive enough that someone could learn the ENTIRE Data Integration framework from this document alone

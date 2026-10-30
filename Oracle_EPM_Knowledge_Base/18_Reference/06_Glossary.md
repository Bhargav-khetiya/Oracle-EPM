# Oracle EPM Glossary — Complete Terminology Reference

> **Folder:** 18_Reference | **Audience:** All levels
>
> **Provenance:** Merged from ChatGPT `GLOSSARY.md`; Claude `26_Glossary/`, `GLOSSARY.md` (200+ terms); Gemini `GLOSSARY_AND_TERMINOLOGY.md`

---

## A

| Term | Definition |
|------|-----------|
| **Account** | A dimension that represents what is being measured (Revenue, Expense, Net Income, Headcount). Usually Dense. |
| **Account Type** | Property of Account members: Expense, Revenue, Asset, Liability, Equity, Saved Assumption. Controls variance reporting and time balance. |
| **AGG** | Essbase command to aggregate a sparse dimension. See also `CALC DIM`. |
| **Aggregate Storage (ASO)** | Essbase storage type optimized for read-heavy, aggregate-heavy queries. Data is loaded, not entered. Limited calculation capability. |
| **Allocation** | Distributing a total amount across target members using a driver or formula. |
| **Application** | A configured EPM workspace containing cubes, forms, rules, and other artifacts. |
| **Approval Unit** | A data unit that moves through a configured approval workflow (Not Started → Under Review → Approved). |
| **Artifact** | A managed application object: form, rule, report, task list, dashboard, etc. |
| **ASO** | See Aggregate Storage. |
| **Attribute Dimension** | A dimension that classifies base dimension members without consuming storage. Zero-byte footprint. |

## B

| Term | Definition |
|------|-----------|
| **Block** | The fundamental unit of data storage in BSO Essbase. Contains all Dense dimension intersections for a unique Sparse coordinate combination. |
| **Block Storage (BSO)** | The classic Essbase storage architecture. Data stored in multidimensional blocks in .PAG files. Supports both input and calculation. |
| **Bottom-Up Calculation** | Essbase calculation mode that processes Level-0 members first, then aggregates upward. ~300x faster than Top-Down for most use cases. |
| **BSO** | See Block Storage. |
| **Business Rule** | A calculation script created in Calc Manager that runs on Essbase data. |

## C

| Term | Definition |
|------|-----------|
| **Calc Manager** | Calculation Manager — the tool for creating, managing, and deploying business rules in EPM Cloud. |
| **Calc Script** | Essbase's native scripting language for calculations. |
| **Cell** | A single data value at the intersection of all dimensional members. |
| **Cell-Level Security** | Fine-grained access restriction for individual data cells. Separate from member permissions. |
| **CLEARBLOCK** | Physical clear — removes entire data blocks from storage. |
| **CLEARDATA** | Logical clear — sets cell values to #Missing without removing blocks. |
| **Consolidation Operator** | Determines how a child member rolls up to its parent: `+` (add), `-` (subtract), `*` (multiply), `/` (divide), `%` (percent), `~` (ignore), `^` (never consolidate). |
| **Cube** | A multidimensional database defined by its dimensions. In EPM Cloud, cubes are called "Plan Types." |
| **Currency** | A dimension representing reporting currencies (USD, EUR, Local Currency). |

## D

| Term | Definition |
|------|-----------|
| **Data Map** | A configuration for moving/mapping data between EPM cubes or between EPM and external sources. |
| **Data Storage Type** | Member property: Store, Dynamic Calc, Dynamic Calc and Store, Never Share, Label Only, Shared. |
| **DataGridBuilder** | Groovy API class for reading/writing Essbase data programmatically. |
| **Dense** | A dimension stored inside data blocks. Defines block shape. Typical: Account, Period. |
| **Dimension** | A category of analysis (Account, Period, Entity, Scenario) forming one axis of the multidimensional space. |
| **Dynamic Calc** | Member computed on demand when retrieved. Uses zero disk storage. |

## E

| Term | Definition |
|------|-----------|
| **Entity** | A dimension representing organizational units (business units, departments, locations). Usually Sparse. |
| **EPBCS** | Enterprise Planning and Budgeting Cloud Service — EPM Cloud with pre-built planning modules. |
| **EPM** | Enterprise Performance Management — software for planning, budgeting, forecasting, and reporting. |
| **EPM Automate** | Command-line utility for automating EPM Cloud operations via REST API. |
| **EPM Cloud** | Oracle's unified cloud platform for enterprise performance management. |
| **Essbase** | Extended Spread Sheet dataBASE — Oracle's multidimensional OLAP database engine. |
| **Evaluation Order** | The sequence in which dimensions are processed. Critical for Smart Lists. |

## F

| Term | Definition |
|------|-----------|
| **FCCS** | Financial Consolidation and Close Cloud Service. |
| **FDMEE** | Financial Data Management, Enterprise Edition — legacy name for Data Integration. |
| **FIX** | Calc script statement that limits calculation scope to specific members. The most critical performance tool. |
| **Flex Form** | Smart View form type combining ad hoc flexibility with form-like behavior. |
| **Form** | Web-based data entry and viewing interface in Planning. |
| **FreeForm** | EPM Cloud application type without pre-built modules — pure Essbase. |

## G–H

| Term | Definition |
|------|-----------|
| **Groovy** | Java-based scripting language used in EPM Cloud for advanced business rules. |
| **HFM / HFP** | Hyperion Financial Management / Hyperion Financial Planning — on-premises predecessors. |
| **Hourglass Principle** | Optimal outline design: sparse dimensions can be large, dense dimensions should be small. |
| **HSP_** | Prefix for Planning repository relational database tables. |
| **HsGetValue** | Smart View function to retrieve a single value from Essbase. |
| **Hybrid BSO** | BSO storage with ASO-style dynamic aggregation. Enabled by ASODYNAMICAGGINBSO. |
| **Hyperion** | Oracle's legacy on-premises EPM product suite, acquired in 2007. |

## I–L

| Term | Definition |
|------|-----------|
| **IDCS** | Oracle Identity Cloud Service — authentication and user management for EPM Cloud. |
| **Import Format** | Data Integration configuration that parses source file columns and expressions. |
| **Label Only** | Data storage type for category header members with no data. |
| **LCM** | Life Cycle Management — snapshot-based artifact migration between EPM environments. |
| **Level-0** | Leaf-level members with no children — where data is typically entered. |

## M–O

| Term | Definition |
|------|-----------|
| **MDX** | Multidimensional Expressions — query language for OLAP databases. |
| **Member** | An item in a dimension hierarchy (Revenue, Jan, US_East). |
| **Member Formula** | A calculation formula attached directly to a member — runs automatically on retrieval. |
| **#Missing** | Indicates no data in a cell (not zero — zero is a stored value). |
| **MOLAP** | Multidimensional OLAP — stores data in multidimensional arrays (what BSO does). |
| **OCI** | Oracle Cloud Infrastructure — the cloud platform hosting EPM Cloud. |

## P–R

| Term | Definition |
|------|-----------|
| **PBCS** | Planning and Budgeting Cloud Service — original cloud planning product. |
| **Period** | A dimension representing time (Jan, Feb, Q1, FY2024). Usually Dense. |
| **Plan Type** | An Essbase cube within an EPM application (Plan1, Plan2, Reporting, OEP_FS). |
| **POV** | Point of View — the dimensional context selected by the user when viewing data. |
| **REST API** | EPM Cloud's HTTP-based API for programmatic access. |
| **ROLAP** | Relational OLAP — stores data in relational tables (not what Essbase does). |
| **RTP** | Runtime Prompt — user input requested when a business rule launches. |
| **RuleSet** | A container for sequencing multiple business rules, optionally in parallel. |

## S

| Term | Definition |
|------|-----------|
| **Sandbox** | A private what-if area for planners to model scenarios without affecting official data. |
| **Scenario** | A dimension representing different versions of reality (Actual, Budget, Forecast). |
| **Shared Member** | A member that points to another member's stored data, enabling alternate hierarchies. |
| **Smart List** | A configured drop-down list for data entry cells, associated with a Planning member. |
| **Smart Push** | Automated data movement from a BSO cube to an ASO cube, typically for reporting. |
| **Smart View** | Oracle's Excel add-in for connecting to and interacting with EPM Cloud data. |
| **Solve Order** | Priority (0–127) that determines which member formula executes first at cell intersections. |
| **Sparse** | A dimension that defines which data blocks exist. Typical: Entity, Product, Scenario. |
| **Substitution Variable** | A global variable set by administrators, referenced in rules (e.g., &CurrYear = FY26). |

## T–Z

| Term | Definition |
|------|-----------|
| **Task List** | A checklist of planning process steps assigned to users with due dates. |
| **TDATASEG** | The relational staging table used by Data Integration/Data Management. |
| **throwVetoException** | Groovy method that rolls back a form save and displays a custom error message. |
| **Time Balance** | Account property controlling how periodic values aggregate to parent periods: Flow, Balance, First, Average. |
| **Top-Down Calculation** | Essbase calculation mode that processes parent members first. ~300x slower than Bottom-Up. |
| **Two-Pass** | Member property that forces a second calculation pass for correct ratio aggregation. |
| **UDA** | User-Defined Attribute — a text tag attached to members for grouping and filtering. |
| **Valid Intersection** | A rule filtering which dimensional combinations are offered in data entry. Not a security control. |
| **VBA** | Visual Basic for Applications — used with Smart View for Excel automation. |
| **Version** | A dimension representing draft status (Working, Final). |
| **XREF** | Cross-database reference function — reads data from another cube in a formula. |
| **XWRITE** | Cross-database write function — writes data to another cube from a formula. |


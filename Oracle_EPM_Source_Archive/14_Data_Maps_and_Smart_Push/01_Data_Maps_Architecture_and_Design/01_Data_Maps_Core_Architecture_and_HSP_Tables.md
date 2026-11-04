# 01 Data Maps Core Architecture and Relational Repository Schema

## 1. Executive Architectural Overview

Oracle Enterprise Performance Management (EPM) Cloud Data Maps serve as the high-speed, declarative data movement engine between cubes within an application or across interconnected applications. Unlike legacy calculation scripts utilizing `@XREF` or `@XWRITE` which execute cell-by-cell at runtime inside the Essbase kernel, Data Maps operate at the **platform metadata and storage buffer layer**, orchestrating bulk data extraction, in-memory structural transformation, and parallel load buffer streaming.

```
+---------------------------------------------------------------------------------------------------+
|                                  ORACLE EPM CLOUD DATA MAP ENGINE                                 |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  +--------------------------------+                  +--------------------------------+           |
|  |     SOURCE CUBE (BSO / ASO)    |                  |     TARGET CUBE (ASO / BSO)    |           |
|  |  +--------------------------+  |                  |  +--------------------------+  |           |
|  |  | Dense/Sparse Block Store |  |                  |  | ASO Data Slices (dbs/app)|  |           |
|  |  | (pag/ind files or temp)  |  |                  |  | or BSO Block Storage     |  |           |
|  +--+--------------------------+--+                  +--+--------------------------+--+           |
|                  |                                                  ^                             |
|                  | 1. MDX Slice Extract                             | 4. Load Buffer Stream       |
|                  v                                                  |    (C++ API Commit)         |
|  +--------------------------------+                  +--------------------------------+           |
|  |      SOURCE DATA STREAM        |                  |      TARGET LOAD BUFFER        |           |
|  |  [Tuple: Dim1..DimN | Value]   |                  |  [EssWriteLoadBuffer C-Call]   |           |
|  +--------------------------------+                  +--------------------------------+           |
|                  |                                                  ^                             |
|                  |               2. Transformation Pipeline         |                             |
|                  +----------------------> [TRANSFORM] --------------+                             |
|                                           |         ^                                             |
|                                           |         |                                             |
|                             +-------------v---------+-------------+                               |
|                             |    PLANNING RELATIONAL METADATA     |                               |
|                             |      HSP_MAP_* Repository Tables    |                               |
|                             +-------------------------------------+                               |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Planning Relational Repository Schema (`HSP_MAP_*`)

In Oracle EPM Cloud Planning (and Financial Consolidation and Close / FreeForm), Data Maps definitions are stored in the underlying relational application repository (Oracle Autonomous Database schema managed by the platform). When an administrator configures a Data Map via the UI, the platform persists the topology across several relational tables:

### 2.1 The Relational Table Hierarchy

| Table Name | Primary Key | Foreign Keys | Functional Purpose |
| :--- | :--- | :--- | :--- |
| `HSP_MAP` | `MAP_ID` | `APP_ID` | Master definition of the Data Map (Name, Description, Source Cube ID, Target Cube ID, Status, Clear Target Option). |
| `HSP_MAP_DIM_DEF` | `MAP_DIM_ID` | `MAP_ID`, `SRC_DIM_ID`, `TGT_DIM_ID` | Dimensional alignment rules linking Source Dimension to Target Dimension (including Unmapped Dimension definitions). |
| `HSP_MAP_SRC_MBR` | `SRC_MBR_MAP_ID` | `MAP_DIM_ID` | Member selection queries on the source cube (e.g., `ILvl0Descendants(Total_Entity)`, specific members, exclusions). |
| `HSP_MAP_TGT_MBR` | `TGT_MBR_MAP_ID` | `MAP_DIM_ID` | Target member placement, target fixed assignments, or mapping target member definitions. |
| `HSP_MAP_EXCLUSION`| `EXCLUSION_ID` | `SRC_MBR_MAP_ID` | Specific members or subtrees excluded from the extraction slice. |
| `HSP_MAP_PARAM` | `PARAM_ID` | `MAP_ID` | Configuration options such as Copy Comments, Copy Attachments, Overwrite, and Aggregation on Target settings. |

### 2.2 Relational Entity-Relationship Representation

```sql
-- Conceptual Schema of Oracle EPM Planning Data Map Repository

CREATE TABLE HSP_MAP (
    MAP_ID          NUMBER(10) PRIMARY KEY,
    APP_ID          NUMBER(10) NOT NULL,
    MAP_NAME        VARCHAR2(255) NOT NULL,
    SRC_CUBE_ID     NUMBER(10) NOT NULL,
    TGT_CUBE_ID     NUMBER(10) NOT NULL,
    CLEAR_TGT_DATA  NUMBER(1) DEFAULT 0, -- 0=No, 1=Physical Clear, 2=Logical Clear
    COPY_COMMENTS   NUMBER(1) DEFAULT 0,
    COPY_SUPPORTING NUMBER(1) DEFAULT 0,
    CREATED_BY      VARCHAR2(100),
    CREATED_DATE    TIMESTAMP,
    LAST_UPDATED    TIMESTAMP
);

CREATE TABLE HSP_MAP_DIM_DEF (
    MAP_DIM_ID     NUMBER(10) PRIMARY KEY,
    MAP_ID          NUMBER(10) REFERENCES HSP_MAP(MAP_ID) ON DELETE CASCADE,
    SRC_DIM_ID     NUMBER(10),           -- NULL if unmapped target dimension
    TGT_DIM_ID     NUMBER(10),           -- NULL if unmapped source dimension
    MAPPING_TYPE    VARCHAR2(50) NOT NULL -- 'IDENTITY', 'ONE_TO_MANY', 'MANY_TO_ONE', 'FIXED'
);

CREATE TABLE HSP_MAP_SRC_MBR (
    SRC_MBR_MAP_ID  NUMBER(10) PRIMARY KEY,
    MAP_DIM_ID     NUMBER(10) REFERENCES HSP_MAP_DIM_DEF(MAP_DIM_ID) ON DELETE CASCADE,
    MEMBER_SELECTION VARCHAR2(2000) NOT NULL, -- e.g., 'Descendants(Total_Geography)'
    IS_EXCLUSION    NUMBER(1) DEFAULT 0
);

CREATE TABLE HSP_MAP_TGT_MBR (
    TGT_MBR_MAP_ID  NUMBER(10) PRIMARY KEY,
    MAP_DIM_ID     NUMBER(10) REFERENCES HSP_MAP_DIM_DEF(MAP_DIM_ID) ON DELETE CASCADE,
    TARGET_MEMBER   VARCHAR2(255) NOT NULL    -- Specific target member or expression
);
```

---

## 3. Lifecycle of a Data Map Execution

When an administrator or user triggers a Data Map (either via Web UI, Job Console, Smart Push on Form Save, EPM Automate, or REST API), the platform executes the following phased process:

```
[Phase 1: Validation & Security Check]
   |--> Verifies user has access rights to source and target data slices.
   |--> Validates source and target dimension hierarchies.
   |
[Phase 2: Source Extraction Slice Generation]
   |--> Parses member selections and exclusions in HSP_MAP_SRC_MBR.
   |--> Translates configuration into an optimized MDX extraction query or Grid Slicer.
   |
[Phase 3: Target Cube Preparation & Clearing (Optional)]
   |--> If "Clear Target Data" is enabled:
   |      - If Target is ASO: Executes MDX Clear Slice or creates negative compensation slice.
   |      - If Target is BSO: Executes targeted CLEARBLOCK or CLEARDATA on target slice.
   |
[Phase 4: Stream Transformation & Memory Pipeline]
   |--> Source data tuples are streamed through the transformation engine in chunks (typically 10,000 to 50,000 cells).
   |--> Applies dimension mapping rules, fixed member assignments, and data conversion.
   |
[Phase 5: Target Ingestion]
   |--> If Target is ASO: Opens an ASO Load Buffer (EssBeginLoadBuffer), streams rows, and commits via EssUpdateFileASO.
   |--> If Target is BSO: Ingests via Essbase Block Writer buffer directly to pag/ind files.
   |
[Phase 6: Target Rollup (Optional)]
   |--> If "Rollup Target Cube" is selected:
   |      - ASO: Incremental aggregate view update or full rollup.
   |      - BSO: Runs internal CALC DIM aggregation on sparse dimensions.
```

---

## 4. LCM XML Schema Representation

During Migration (LCM snapshot export), Data Maps are serialized into XML files within the `resource/Data Maps` folder. An analysis of the LCM XML reveals the operational parameters passed to the engine:

```xml
<—xml version="1.0" encoding="UTF-8"—>
<DataMap xmlns="http://xmlns.oracle.com/epm/planning/datamap" version="24.08.65">
    <Name>OEP_FS to OEP_REP</Name>
    <Description>Data Push from Financials Core BSO to Reporting ASO Cube</Description>
    <SourceCube>OEP_FS</SourceCube>
    <TargetCube>OEP_REP</TargetCube>
    <Options>
        <ClearTargetData>true</ClearTargetData>
        <CopyComments>false</CopyComments>
        <CopySupportingDetails>false</CopySupportingDetails>
        <AggregateOnTarget>true</AggregateOnTarget>
    </Options>
    <DimensionMappings>
        <!-- 1:1 Identity Mapping -->
        <DimensionMapping sourceDim="Account" targetDim="Account" type="ExactMatch">
            <SourceMembers>
                <MemberSelection operator="Descendants">Total_Income</MemberSelection>
                <MemberSelection operator="Descendants">Total_Expenses</MemberSelection>
            </SourceMembers>
            <Exclusions>
                <MemberSelection operator="Member">Statistical_Accounts</MemberSelection>
            </Exclusions>
        </DimensionMapping>
        
        <!-- Dimension with fixed target member (Target has dim, Source does not) -->
        <DimensionMapping targetDim="View" type="Fixed">
            <TargetMember>Periodic</TargetMember>
        </DimensionMapping>

        <!-- Unmapped Source Dimension (Aggregated or Filtered to single member) -->
        <DimensionMapping sourceDim="Plan_Element" type="FixedSource">
            <SourceMember>Total_Plan_Element</SourceMember>
        </DimensionMapping>
    </DimensionMappings>
</DataMap>
```

---

## 5. Architectural Differences: Data Maps vs Calc Script (`@XREF` / `@XWRITE`)

| Parameter | Data Maps Engine | Calc Script `@XREF` / `@XWRITE` |
| :--- | :--- | :--- |
| **Execution Layer** | Application server orchestrator + bulk buffer API | Essbase C++ Calculation Kernel |
| **Extraction Protocol** | MDX bulk query / Essbase Data Slicer | Point-by-point network socket call |
| **Load Mechanism** | ASO Load Buffer (`EssWriteLoadBuffer`) / Bulk BSO writer | Individual cell injection via cross-cube pointer |
| **Throughput** | **100,000 – 500,000 cells/second** | **500 – 2,500 cells/second** |
| **Target Cube Impact** | Appends single clean slice to ASO; minimal lock contention | Serial block locks on BSO target; high locking overhead |
| **UI Integration** | Seamless visual configuration; attached to Forms as Smart Push | Requires custom calc script coding and form association |
| **Maintenance** | Metadata changes auto-update or highlight validation errors | Hardcoded member names require manual script audits |

---

## 6. Security and Access Permissions

Data Maps respect role-based and cell-level security according to how they are invoked:

1. **Job Console / Administrator Execution**: Runs under the context of the user triggering the job. If run by an Administrator, security filters can be bypassed or enforced depending on configuration.
2. **Smart Push on Web Form Save**: Executes under the context of the **end user saving the form**. If the user does not have write access to the target slice or read access to the source slice, data outside their security realm will not be moved.
3. **Run as Administrator Option (Groovy Override)**: When wrapped in Groovy script rules, the Data Map execution can be elevated to run with administrative credentials using `operation.application.getDataMap("MapName").execute(true)`.


# 🏛️ Form Properties — Form Layout Internals, XML Repository & LCM Structure

> **Purpose**: This technical document explores the internal physical persistence of Oracle EPM Cloud web forms in the relational repository, the structural schema of exported **Lifecycle Management (LCM) XML files**, the behind-the-scenes query compilation from form layouts into Essbase MDX/GridAPI queries, and programmatic mass-maintenance automation.

---

## 1. Relational Persistence Schema (`HSP_FORM_*` Tables)

In Oracle EPM Cloud Planning, web forms are not stored as static HTML files or Essbase objects. They exist as relational entity definitions in the application's underlying relational database catalog.

```
                      RELATIONAL FORM REPOSITORY MODEL
                      
    [HSP_OBJECT] (OBJECT_ID = 50201, OBJECT_NAME = "OEP_FS_Rev_Exp", TYPE_ID = 6)
          │
          ▼
    [HSP_FORM]
    ├── FORM_ID (50201)
    ├── PLAN_TYPE (Cube ID: 1 = Oep_FS)
    ├── FORM_TYPE (1 = Standard, 2 = Composite)
    ├── SUPPRESS_MISSING (0/1)
    ├── SUPPRESS_ZERO (0/1)
    └── ENABLE_PRECISION (0/1)
          │
          ├─────────────────────────────┬─────────────────────────────┐
          ▼                             ▼                             ▼
    [HSP_FORM_LAYOUT]           [HSP_FORM_SEGMENT]           [HSP_FORM_BR_ASSOC]
    ├── LAYOUT_ID               ├── SEGMENT_ID               ├── ASSOC_ID
    ├── FORM_ID                 ├── FORM_ID                  ├── FORM_ID
    ├── AXIS_TYPE (0=Col, 1=Row)├── AXIS (0/1)               ├── RULE_ID
    └── DIMENSION_ORDER         └── IS_DYNAMIC (0/1)         └── HOOK (1=Pre, 2=Post)
                                        │
                                        ▼
                                [HSP_FORM_CELL_PROP]
                                ├── SEGMENT_ID
                                ├── PROPERTY_TYPE (Format, Validation)
                                └── PROPERTY_VALUE
```

### Key Relational Tables

1. **`HSP_FORM`**: Core registry holding form metadata, default cube bindings, global grid toggles (suppression flags, auto-save settings, precision flags).
2. **`HSP_FORM_LAYOUT`**: Defines axis assignments (Row, Column, POV, Page) and the dimensional nesting order on each axis.
3. **`HSP_FORM_SEGMENT`**: Represents distinct row or column segments. Each segment has its own member selections, formula overrides, and display formatting rules.
4. **`HSP_FORM_BR_ASSOC`**: Maps business rules to form lifecycle events (`Run Before Load`, `Run Before Save`, `Run After Save`).

---

## 2. LCM XML Artifact Architecture

When an administrator exports a form using **Lifecycle Management (LCM)** or EPM Automate (`exportAppSecurity` / `exportMetadata`), the relational metadata is serialized into an XML file located under `/resource/Forms/<Folder_Name>/<Form_Name>.xml`.

### Annotated Real-World Form XML Definition

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form xmlns="http://xmlns.oracle.com/epm/planning/form">
    <name>OEP_FS_Revenue_and_Expense</name>
    <description>Driver-based Revenue and Operating Expense Plan</description>
    <cube>Oep_FS</cube>
    <type>DataForm</type>
    
    <!-- Global Grid Properties -->
    <gridProperties>
        <suppressMissingBlocks>true</suppressMissingBlocks>
        <suppressMissingData>true</suppressMissingData>
        <suppressZeroData>false</suppressZeroData>
        <suppressInvalidData>true</suppressInvalidData>
        <autoSave>true</autoSave>
        <enablePrecision>true</enablePrecision>
        <minimumPrecision>2</minimumPrecision>
        <maximumPrecision>2</maximumPrecision>
        <maxCellsLimit>500000</maxCellsLimit>
    </gridProperties>

    <!-- Point of View (POV) & Page Axes -->
    <layout>
        <pageAxis>
            <dimension name="Years">
                <selection type="UserSelection">FY24, FY25, FY26</selection>
            </dimension>
        </pageAxis>
        <povAxis>
            <dimension name="Scenario"><selection>OEP_Plan</selection></dimension>
            <dimension name="Version"><selection>OEP_Working</selection></dimension>
            <dimension name="Currency"><selection>USD</selection></dimension>
        </povAxis>

        <!-- Column Axis Definition (Segmented) -->
        <columnAxis>
            <segment id="1" type="Data">
                <dimension name="Period">
                    <selection type="Function">ILvl0Descendants("YearTotal")</selection>
                </dimension>
            </segment>
        </columnAxis>

        <!-- Row Axis Definition (Multi-Segmented) -->
        <rowAxis>
            <!-- Segment 1: Revenue Accounts -->
            <segment id="1" type="Data" readOnly="false">
                <dimension name="Account">
                    <selection type="Function">IDescendants("40000_Total_Revenue")</selection>
                </dimension>
                <dimension name="Entity">
                    <selection type="UserSelection">"E101_Sales_East"</selection>
                </dimension>
            </segment>

            <!-- Segment 2: Formula Separator Row (Gross Margin %) -->
            <segment id="2" type="Formula" readOnly="true">
                <dimension name="Account">
                    <label>Gross Margin Ratio</label>
                    <formula>[1] / [Total Revenue] * 100</formula>
                </dimension>
            </segment>
        </rowAxis>
    </layout>

    <!-- Attached Business Rules & Groovy Hooks -->
    <businessRules>
        <rule name="Calculate_Gross_Margin">
            <runOnSave>true</runOnSave>
            <useFormContext>true</useFormContext>
        </rule>
        <groovyRule name="PreSave_Budget_Validator">
            <runBeforeSave>true</runBeforeSave>
        </groovyRule>
    </businessRules>
</form>
```

---

## 3. Behind-the-Scenes: Query Compilation Pipeline

When a user opens a web form, the EPM Cloud Application Server executes a multi-step compilation process to transform the relational XML layout into an Essbase data retrieval query:

```
[Form Open Request Received]
              │
              ▼
  [Step 1: Parse Form Layout & Substitute User Variables]
  ├── Resolve user variables: &CurYear ──► "FY24"
  ├── Resolve dynamic member selections: ILvl0Descendants("YearTotal")
  └── Expand segment rows and columns into tuple cross-products
              │
              ▼
  [Step 2: Generate Essbase MDX Query / GridAPI Request]
  ├── Construct non-empty set queries for sparse intersections
  └── Generate MDX SELECT statement:
      SELECT
        Crossjoin({[FY24]}, {[Jan]:[Dec]}) ON COLUMNS,
        NON EMPTY Crossjoin({Descendants([40000_Total_Revenue])}, {[E101_Sales_East]}) ON ROWS
      FROM [Oep_FS].[Oep_FS]
      WHERE ([OEP_Plan], [OEP_Working], [USD])
              │
              ▼
  [Step 3: Essbase MOLAP Engine Execution]
  ├── Evaluates sparse index B-trees in .IND
  ├── Fetches dense blocks from .PAG into Data Block Buffer Cache
  └── Extracts requested dense cell offsets (8 bytes each)
              │
              ▼
  [Step 4: Application Server Post-Processing & Security Masking]
  ├── Applies Cell-Level Security (CLS) bitmasks (read/write/deny)
  ├── Evaluates Valid Intersections (VIC) rules
  ├── Evaluates Form Formula Rows (e.g. Row [1] / Row [2])
  └── Injects Formatting Rules (color codes, read-only badges)
              │
              ▼
  [Step 5: Serialize JSON Payload & Transmit to Browser Grid]
```

---

## 4. Programmatic Mass Maintenance: Automating Form Changes

In large enterprise implementations with hundreds of web forms, manual updates (e.g., updating a renamed member or changing suppression settings across 120 forms) via the web UI is prone to human error. Administrators can automate this using an LCM XML processing script:

### Python Script: Batch Updating Suppression Settings across 100+ Form XMLs

```python
"""
EPM Form LCM Batch Processor
Author: Enterprise Architecture Team
Purpose: Recursively scan exported LCM form XML files, enforce standard suppression 
         settings, update obsolete member references, and prepare for LCM re-import.
"""

import os
import xml.etree.ElementTree as ET

FORMS_DIR = r"D:\LCM_Exports\Artifacts\Forms"
OLD_MEMBER = "Old_Cost_Center_99"
NEW_MEMBER = "CC_Corporate_Universal"

modified_count = 0

for root_dir, _, files in os.walk(FORMS_DIR):
    for filename in files:
        if filename.endswith(".xml"):
            filepath = os.path.join(root_dir, filename)
            tree = ET.parse(filepath)
            root = tree.getroot()

            # Ensure XML belongs to EPM planning form schema
            if "form" not in root.tag:
                continue

            changed = False

            # 1. Enforce Enterprise Grid Suppression Standards
            grid_props = root.find("gridProperties")
            if grid_props is not None:
                suppress_missing = grid_props.find("suppressMissingBlocks")
                if suppress_missing is not None and suppress_missing.text != "true":
                    suppress_missing.text = "true"
                    changed = True

                suppress_invalid = grid_props.find("suppressInvalidData")
                if suppress_invalid is not None and suppress_invalid.text != "true":
                    suppress_invalid.text = "true"
                    changed = True

            # 2. Replace Deprecated Member Names in Selections
            for selection in root.iter("selection"):
                if OLD_MEMBER in (selection.text or ""):
                    selection.text = selection.text.replace(OLD_MEMBER, NEW_MEMBER)
                    changed = True

            # Save modified XML file
            if changed:
                tree.write(filepath, encoding="UTF-8", xml_declaration=True)
                modified_count += 1
                print(f"[UPDATED] {filename}")

print(f"\nProcessing Complete. Successfully updated {modified_count} form definition(s).")
```

---

## 5. Architectural Thresholds and Governance Limits

To prevent browser crashes and memory starvation in the EPM application server, Oracle enforces specific architectural thresholds on web forms:

| Form Metric / Threshold | Hard Limit | Recommended Best-Practice Limit | Failure Impact if Exceeded |
| :--- | :--- | :--- | :--- |
| **Max Cells per Grid (`maxCellsLimit`)** | 500,000 cells | $\le$ 25,000 cells | `HTTP 500` - *"Form exceeds the maximum cell limit. Please reduce member selections."* |
| **Segments per Axis** | 60 segments | $\le$ 15 segments | Severe rendering latency; browser JavaScript thread hangs during DOM construction. |
| **Formula Rows / Columns** | Unlimited | $\le$ 10 formula rows | Slow form loads; application server executes formula calculations row-by-row in single-threaded Java memory. |
| **Dynamic Member Expansion** | Unlimited | Use `@DESCENDANTS` cautiously | If a function expands to 2,000+ members on rows, Essbase query time spikes from 0.4s to 25s+. |

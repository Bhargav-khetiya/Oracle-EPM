# 📖 Oracle EPM Cloud & Essbase: Master Glossary & Terminology

This glossary defines essential terms, acronyms, calculation operators, and architectural concepts across Oracle Enterprise Performance Management (EPM) Cloud and the Essbase calculation engine. Each entry provides both a **plain-English analogy** for beginners and a **precise technical definition** for senior architects.

---

## A

### Aggregate Storage Option (ASO)
* **Simple Analogy**: Think of ASO as an ultra-fast digital calculator with a summary report view. It doesn't write complex recursive math line-by-line; it just instantly calculates subtotals on the fly when you ask for them.
* **Technical Definition**: An Essbase storage engine architecture optimized for high-dimensional aggregation and read-only analytical reporting. Unlike BSO, data cells are stored in compressed tabular tables rather than multi-dimensional arrays, and upper-level dimension rollups are computed dynamically in-memory without requiring batch calculation scripts.
* **Canonical Reference**: [`Essbase_Internal_Architecture/02_Essbase_Data_Storage_Architecture.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Essbase_Internal_Architecture/02_Essbase_Data_Storage_Architecture.md)

### Approval Unit Hierarchy (AUH)
* **Simple Analogy**: Think of AUH as an enterprise sign-off clipboard. When the department manager finishes their budget, they sign it and pass the clipboard up to the division VP; once signed, the department manager's pencil is taken away so they can't change the numbers behind the VP's back.
* **Technical Definition**: A hierarchical approval path constructed by combining the Entity dimension with specific Scenario and Version members. AUH governs the promotional workflow (Not Started $\to$ First Pass $\to$ Under Review $\to$ Approved), transferring data ownership and imposing write locks at the database block level.
* **Canonical Reference**: [`03_Workflow_and_Task_Management/Oracle_EPM_Approval_Flow_Master_Guide.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/03_Workflow_and_Task_Management/Oracle_EPM_Approval_Flow_Master_Guide.md)

---

## B

### Block Storage Option (BSO)
* **Simple Analogy**: Think of BSO as a warehouse full of filing cabinets. Each drawer is a specific room (sparse intersection), and inside each drawer is a perfectly structured grid of folders (dense intersection) where you can perform complex step-by-step arithmetic.
* **Technical Definition**: The traditional Essbase multidimensional storage engine. BSO partitions data into physical 64KB arrays (blocks) containing all dense dimension member intersections, indexed by multidimensional coordinates formed by sparse dimensions. BSO supports full procedural calculation scripting, recursive formulas, and allocations.
* **Canonical Reference**: [`Essbase_Internal_Architecture/04_Block_Storage_Deep_Dive.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Essbase_Internal_Architecture/04_Block_Storage_Deep_Dive.md)

### Bottom-Up Calculation Mode
* **Simple Analogy**: Bottom-Up is like a factory assembly line where workers only assemble products when physical raw parts actually arrive at their workstation. They never stand around staring at empty tables.
* **Technical Definition**: An Essbase calculation engine optimization mode (`@CALCMODE(BOTTOMUP)`) where formulas execute exclusively on existing, physically allocated data blocks. Bottom-Up calculation skips non-existent sparse intersections, running up to 300x faster than Top-Down mode.
* **Canonical Reference**: [`Calc Manager/Calculations_and_Allocations/05_Calculation_Engine_and_Performance/01_Execution_Modes_BottomUp_vs_TopDown.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/05_Calculation_Engine_and_Performance/01_Execution_Modes_BottomUp_vs_TopDown.md)

---

## C

### Cell-Level Security (CLS)
* **Simple Analogy**: Standard security gives someone a key to a room; Cell-Level Security allows them into the room but puts a locked glass display over specific items on the shelf.
* **Technical Definition**: A granular security mechanism that overrides standard dimension member security by evaluating multi-dimensional coordinate tuples. It allows administrators to grant Read, Write, or Deny access to specific cell intersections (e.g., allow a user to edit OPEX accounts for Department 100, but make Executive Salaries read-only).
* **Canonical Reference**: [`Form_Properties/07_Cell_Level_Security_and_Valid_Intersections_on_Forms.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Form_Properties/07_Cell_Level_Security_and_Valid_Intersections_on_Forms.md)

### Custom Defined Function (CDF)
* **Simple Analogy**: A specialized power tool plugged into an engine to perform a task the standard engine wasn't natively built to do (like translating Java dates or financial bond yields).
* **Technical Definition**: Java-based functions developed and compiled into JAR files registered with Calculation Manager and Essbase (e.g., `@CalcMgrDateDiff`, `@CalcMgrExcelIRR`).
* **Canonical Reference**: [`Calc Manager/Calc Managers all business Rule Functions/Calc Managers all business Rule Functions.txt`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calc%20Managers%20all%20business%20Rule%20Functions/Calc%20Managers%20all%20business%20Rule%20Functions.txt)

---

## D

### Data Maps
* **Simple Analogy**: An automated conveyor belt connecting two separate production rooms. What gets produced in Room 1 (BSO cube) is mapped, repacked, and placed onto the belt to appear in Room 2 (ASO cube).
* **Technical Definition**: Relational metadata definitions stored in `HSP_MAP` tables that define source-to-target dimensional mappings between EPM plan types. Data Maps handle missing dimensions, member renaming, and smart exclusions during inter-cube data movement.
* **Canonical Reference**: [`Data_Maps_and_Exchange/01_Data_Maps_Architecture_and_Design/01_Data_Maps_Core_Architecture_and_HSP_Tables.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Data_Maps_and_Exchange/01_Data_Maps_Architecture_and_Design/01_Data_Maps_Core_Architecture_and_HSP_Tables.md)

### Dense Dimension
* **Simple Analogy**: The numbered rows and columns on a physical piece of graph paper. Every intersection physically exists on the sheet, even if a square is left blank.
* **Technical Definition**: An Essbase dimension designated as Dense because the majority of its member intersections are expected to contain data (e.g., Accounts and Period). All dense dimension members are allocated together within a physical contiguous data block; each cell is located at a fixed numeric byte offset.
* **Canonical Reference**: [`Essbase_Internal_Architecture/03_Sparse_vs_Dense_Complete_Guide.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Essbase_Internal_Architecture/03_Sparse_vs_Dense_Complete_Guide.md)

### Dynamic Calc
* **Simple Analogy**: A calculator that performs an equation on your phone screen when you hit the equals button, but never saves the result to the phone's hard drive.
* **Technical Definition**: A member data storage property where numeric values are calculated in RAM at query retrieval time rather than being pre-calculated and stored in `.PAG` files on disk. Reduces database file size but consumes calculation CPU during user retrievals.
* **Canonical Reference**: [`Dimension_Properties/01_Universal_Member_Properties.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Dimension_Properties/01_Universal_Member_Properties.md)

---

## E

### EPM Automate
* **Simple Analogy**: A robotic virtual administrator with a command prompt that can perform repetitive nighttime system tasks while everyone is asleep.
* **Technical Definition**: Oracle's official cross-platform command-line utility (CLI) that enables administrators to automate operational tasks (file uploads, data imports, business rule execution, cube refreshes, snapshot backups, and environment cloning) via batch scripts.
* **Canonical Reference**: [`EPM_Automate/01_Architecture_Installation_and_Authentication.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/EPM_Automate/01_Architecture_Installation_and_Authentication.md)

### Enterprise Planning and Budgeting Cloud Service (EPBCS)
* **Simple Analogy**: Buying a brand-new house that already comes fully furnished with a state-of-the-art kitchen, living room, and plumbing system, instead of buying an empty plot of land and building every brick yourself.
* **Technical Definition**: Oracle EPM Cloud offering featuring pre-built, best-practice business processes: Financials (`OEP_FS`), Workforce (`OEP_WFP`), Capital (`OEP_CPX`), Projects (`OEP_PFP`), and Strategic Modeling (HSF).
* **Canonical Reference**: [`EPBCS_Modules_and_Business_Processes/00_INDEX.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/EPBCS_Modules_and_Business_Processes/00_INDEX.md)

---

## F

### FreeForm Planning
* **Simple Analogy**: An open artist's canvas without pre-drawn coloring outlines. You decide how many dimensions exist and what they are called.
* **Technical Definition**: An Oracle EPM Cloud application deployment model unconstrained by standard Planning dimensions (no mandatory Entity, Period, Scenario, or Version). Allows importing pure Essbase BSO/ASO outlines up to 26 dimensions.
* **Canonical Reference**: [`Techno_Functional_Consultant_Review_Bible/02_Application_Types_PBCS_EPBCS_Custom_FreeForm_FCCS.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Techno_Functional_Consultant_Review_Bible/02_Application_Types_PBCS_EPBCS_Custom_FreeForm_FCCS.md)

---

## G

### Groovy Rules Engine
* **Simple Analogy**: Giving your calculation script eyes and ears. Instead of blindly recalculating an entire 50,000-cell spreadsheet, the script watches where the user's cursor typed and recalculates only those 3 modified numbers.
* **Technical Definition**: A Java-virtual-machine-based scripting environment embedded within EPM Cloud Calculation Manager. Groovy rules interact with the Planning Java Object Model (`EpmScriptContext`, `DataGridDefinition`, `DataGridBuilder`), enabling dynamic micro-FIX generation and pre-save input validation (`throwVetoException`).
* **Canonical Reference**: [`Calc Manager/Calculations_and_Allocations/06_Groovy_Business_Rules/01_Groovy_Rule_Architecture_in_Calc_Manager.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/06_Groovy_Business_Rules/01_Groovy_Rule_Architecture_in_Calc_Manager.md)

---

## H

### Hourglass Principle
* **Simple Analogy**: Stacking stones in an hourglass shape: heaviest flat stones at the base, narrow stones in the middle, and large round boulders at the very top.
* **Technical Definition**: The outline design rule for optimal BSO performance:
  1. Dense dimensions arranged from largest member count to smallest member count.
  2. Sparse dimensions arranged from smallest member count to largest member count.
* **Canonical Reference**: [`Essbase_Internal_Architecture/06_Hourglass_Principle.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Essbase_Internal_Architecture/06_Hourglass_Principle.md)

### Hybrid BSO
* **Simple Analogy**: A sports car with an electric motor for instant city acceleration and a gasoline engine for heavy highway towing.
* **Technical Definition**: An Essbase storage mode combining BSO procedural calculations with in-memory ASO dynamic sparse aggregation. Upper-level sparse members are set to `Dynamic Calc` and calculated dynamically at query time via the ASO query engine, eliminating batch `CALC DIM` and `AGG` scripts.
* **Canonical Reference**: [`Essbase_Internal_Architecture/13_Hybrid_BSO_Engine_Internals.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Essbase_Internal_Architecture/13_Hybrid_BSO_Engine_Internals.md)

---

## L

### Lifecycle Management (LCM)
* **Simple Analogy**: Packing all personal belongings into a standardized shipping container, sealing it, and shipping it across town to unpack in an identical new house.
* **Technical Definition**: The underlying Oracle EPM migration framework used to export, package, and import application artifacts (metadata, forms, rules, dashboards, security) across development, test, and production pods.
* **Canonical Reference**: [`05_Application_Creation_and_Lifecycle_Management/01_Environment_Lifecycle_and_Maintenance/06_Snapshot_Lifecycle_Management.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/05_Application_Creation_and_Lifecycle_Management/01_Environment_Lifecycle_and_Maintenance/06_Snapshot_Lifecycle_Management.md)

---

## S

### Smart Push
* **Simple Analogy**: Instant messaging for financial cubes. The millisecond you click "Save" on your budget form, the data is pushed in the background to the reporting dashboard.
* **Technical Definition**: An EPM feature built on Data Maps that automatically moves data slices from a source BSO planning cube directly into an ASO reporting cube upon web form save or on-demand execution.
* **Canonical Reference**: [`Data_Maps_and_Exchange/02_Smart_Push_Internals/01_Smart_Push_Architecture_and_Form_Sync.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Data_Maps_and_Exchange/02_Smart_Push_Internals/01_Smart_Push_Architecture_and_Form_Sync.md)

### Solve Order
* **Simple Analogy**: Order of operations in high school algebra: multiplication and division happen before addition and subtraction ($2 + 3 \times 4 = 14$, not $20$).
* **Technical Definition**: An integer property ($0$ to $127$) assigned to dimension members determining calculation priority when two dynamic formulas intersect at the same coordinate (e.g., Net Margin % vs. Quarter 1 sum). Higher solve orders calculate after lower solve orders.
* **Canonical Reference**: [`Dimension_Properties/10_Advanced_Solve_Order_and_Formula_Execution.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Dimension_Properties/10_Advanced_Solve_Order_and_Formula_Execution.md)

### Sparse Dimension
* **Simple Analogy**: Houses on a rural country road. Most plots of land are completely empty; houses only exist at specific addresses.
* **Technical Definition**: An Essbase dimension designated as Sparse because data exists only for a small fraction of potential member combinations (e.g., Entity, Department, Product). Sparse combinations determine physical block creation in `.IND` and `.PAG` files.
* **Canonical Reference**: [`Essbase_Internal_Architecture/03_Sparse_vs_Dense_Complete_Guide.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Essbase_Internal_Architecture/03_Sparse_vs_Dense_Complete_Guide.md)

---

## V

### Valid Intersections (VI)
* **Simple Analogy**: A smart form that grays out the "Roof Sunroof" checkbox when you select "Motorcycle" as the vehicle type.
* **Technical Definition**: Business rules that prevent data entry, form navigation, and block creation at impossible dimensional coordinate combinations (e.g., preventing Capital Expenditure accounts from being selected under Human Resources).
* **Canonical Reference**: [`01_Security_and_Access/Oracle_EPM_Valid_Intersections_Master_Guide.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/01_Security_and_Access/Oracle_EPM_Valid_Intersections_Master_Guide.md)


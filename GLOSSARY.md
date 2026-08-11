# 📚 GLOSSARY — Oracle EPM A-Z Terminology Dictionary

> **Purpose:** Every term, abbreviation, and concept you will encounter in Oracle EPM work.  
> **Last Updated:** July 11, 2026

---

## A

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **Ad Hoc** | — | Creating a custom report on-the-fly, without a pre-built form | Smart View feature |
| **Allocation** | — | Distributing a cost across departments or entities | Cost allocation in P&L |
| **Alias** | — | A friendly display name for a member (e.g., "100110" → "Rooms Revenue") | Dimension member property |
| **Anchor Dimension** | — | The primary dimension on a row/column that controls layout | Form design |
| **ARCS** | Account Reconciliation Cloud Service | Oracle tool for comparing two financial records | EPM Pillar #3 |
| **ASO** | Aggregate Storage Option | Storage method optimized for fast reporting (read-only, no write-back) | Essbase storage |
| **Attribute** | — | A classification attached to a dimension member for analysis | Dimension property |

## B

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **BegBalance** | Beginning Balance | Starting balance at the beginning of a period | Period dimension member |
| **Block** | — | Multi-dimensional data container created by Dense dimension intersections | Essbase internals |
| **Block Set** | — | Group of blocks processed during a calculation | Calc performance |
| **BSO** | Block Storage Option | Storage method for complex calculations and data entry (write-back) | Essbase storage |
| **Budget** | — | A financial plan — how much you plan to spend/earn | Scenario type |
| **Business Rule** | — | An automated calculation or action (e.g., Revenue × Tax Rate = Tax) | Calculation Manager |

## C

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **Cell** | — | A single data point at the intersection of all dimensions | Essbase cube |
| **COGS** | Cost of Goods Sold | Direct cost of producing what you sell | Finance term |
| **Consolidation** | — | Combining multiple entities' data into one total | EPM core function |
| **Consolidation Operator** | — | Symbol (+, -, ~, ^) that controls how a child contributes to parent | Member property |
| **Cube** | — | A multi-dimensional data structure (also called database in Essbase) | Essbase core |
| **Currency Dimension** | — | Handles multi-currency applications (INR, USD, EUR) | Standard dimension |

## D

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **Dashboard** | — | A visual display showing charts, graphs, and key numbers | Reporting |
| **Data Block** | — | Container where Essbase stores data for one sparse combination | Essbase internals |
| **Data Storage** | — | Property controlling how member data is stored (Store, Dynamic Calc, etc.) | Member property |
| **Data Type** | — | Type of data stored: Currency, Non-Currency, Percentage, Text, Smart List, Date | Account property |
| **Dense Dimension** | — | Dimension where most combinations have data; forms the block interior | Essbase design |
| **Depreciation** | — | Reduction in value of an asset over time | Finance term |
| **Dimension** | — | A business category (Account, Entity, Period, etc.) | Essbase core |
| **Drill-back** | — | Clicking a number to go back to the original source system (EPM → ERP) | Navigation |
| **Drill-down** | — | Clicking a total to see its component details | Navigation |
| **Driver-Based Planning** | — | Using input assumptions (drivers) to calculate results automatically | Planning concept |
| **Dynamic Calc** | — | Data calculated on-the-fly when viewed, not stored in the cube | Data storage type |
| **Dynamic Calc and Store** | — | Calculated on first access, then stored for faster future retrieval | Data storage type |

## E

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **EDMCS** | Enterprise Data Management Cloud Service | Oracle tool for managing business master data | EPM Pillar #4 |
| **Entity** | — | A company, branch, or organizational unit | Standard dimension |
| **EPBCS** | Enterprise Planning and Budgeting Cloud Service | Oracle's enhanced cloud planning tool | EPM Pillar #1 |
| **EPM** | Enterprise Performance Management | System for planning, budgeting, forecasting, and reporting | The platform |
| **EPM Automate** | — | Command-line utility for automating EPM Cloud tasks | Administration |
| **ERP** | Enterprise Resource Planning | System managing day-to-day operations (accounting, payroll, etc.) | Source system |
| **Essbase** | Extended Spreadsheet Database | Oracle's multidimensional database powering EPM | Core engine |
| **Evaluation Order** | — | The sequence in which Essbase calculates members | Calculation |
| **Exchange Rate** | — | Rate for converting between currencies (Average, Ending, Historical) | Account property |

## F

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **FCCS** | Financial Consolidation and Close Cloud Service | Oracle tool for combining financial data | EPM Pillar #2 |
| **Fill** | — | Time Balance setting: carry last value forward until new value entered | Account property |
| **First** | — | Time Balance setting: take only the first period's value | Account property |
| **Flex Form** | — | Ad-hoc-like form allowing users to modify layout at runtime | Form type |
| **Flow** | — | Time Balance setting: add up all periods (most common) | Account property |
| **Forecast** | — | A prediction of future numbers based on current trends | Scenario type |
| **Form** | — | A data entry screen where users input budget/forecast numbers | Planning UI |
| **FSSAI** | Food Safety and Standards Authority of India | Indian food safety regulator | Industry term |
| **FY** | Financial Year | A 12-month accounting period (e.g., FY25 = Apr 2025 - Mar 2026) | Finance term |

## G

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **Generation** | — | Top-down position in hierarchy (1 = root, 2 = first children, etc.) | Essbase hierarchy |
| **GL** | General Ledger | The master record of ALL financial transactions | Finance term |
| **Groovy** | — | Scripting language (Java-based) used to write business rules in EPM | Calculation |

## H

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **Hierarchy** | — | Parent-child relationships between members in a dimension | Essbase structure |
| **Hybrid BSO** | — | Modern BSO combining block storage calculation power with ASO-like speed | Essbase storage |
| **Hyperion** | — | Oracle's original on-premises EPM system (predecessor to cloud) | Legacy system |

## I

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **Implied Sharing** | — | Automatic value sharing when a parent has only one child | Essbase behavior |
| **Instance** | — | One separate installation/setup of the application | Environment |

## L

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **Label Only** | — | Data storage type: used for grouping/headings, holds no data | Member property |
| **Level** | — | Bottom-up position in hierarchy (0 = leaf, 1 = one above, etc.) | Essbase hierarchy |

## M

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **MDX** | Multi-Dimensional eXpressions | Query language for Essbase cubes | Query language |
| **Member** | — | An individual item within a dimension (e.g., "Jan", "Revenue") | Essbase core |
| **Member Formula** | — | A calculation formula attached to a specific dimension member | Calculation |
| **Metadata** | — | "Data about data" — names, properties, structure (not the numbers) | EPM concept |
| **Migration** | — | Moving data/applications from one system to another | Administration |

## N

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **Net Profit** | — | Profit after ALL expenses including tax | Finance term |
| **Never Share** | — | Data storage: creates unique block, prevents aggregation of rates/prices | Member property |
| **NRCS** | Narrative Reporting Cloud Service | Oracle tool for report + explanation generation | EPM Pillar #5 |

## O

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **OOTB** | Out of the Box | Features/modules pre-built by Oracle | Application type |

## P

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **P&L** | Profit and Loss Statement | Report showing Revenue, Expenses, and Profit | Finance report |
| **PBCS** | Planning and Budgeting Cloud Service | Basic cloud planning tool (predecessor to EPBCS) | Legacy cloud |
| **PCMCS** | Profitability and Cost Management Cloud Service | Oracle tool for cost allocation analysis | EPM Pillar #6 |
| **Year** | — | The financial year dimension (FY25, FY26) | Standard dimension |

---

### 💡 Pro Tip: The Language of the Business
> **Misconception:** "If I know all the technical terms like 'ASO Incremental Slice' and 'L2 Cache', the client will respect me as a senior architect."
> **Reality:** The CFO does not care about Essbase blocks. A true Elite Architect uses technical terms when speaking to developers, but instantly translates them into business value when speaking to stakeholders. Don't say: "We need to clear the ASO slices." Say: "We need to run a maintenance job so your executive dashboards load in 2 seconds instead of 10 seconds." Master both dictionaries.

| **PlanElement** | — | Categorizes data: Load, Calculated, Adjustments | Custom dimension |
| **POV** | Point of View | Fixed dimension selections that filter what you see on a form | Form layout |

## Q-R

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **Q1-Q4** | Quarter 1-4 | Three-month periods within a year | Period members |
| **Rolling Forecast** | — | Continuously updated forecast looking 12-18 months ahead | Planning concept |
| **Runtime Prompt** | — | A pop-up asking user for input before running a rule or opening a form | Business Rules |

## S

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **Saved Assumption** | — | Account type for assumption values (Tax Rate, Growth Rate) | Account property |
| **Scenario** | — | Dimension tracking Actual vs Budget vs Forecast | Standard dimension |
| **Shared Member** | — | Member that shares data from another stored member | Data storage |
| **Skip Value** | — | Controls what to do with zeros/missing in calculations | Account property |
| **Smart List** | — | Dropdown selection values in data cells | Data type |
| **Smart Push** | — | Moving data between cubes within the same application | Data movement |
| **Smart View** | — | Oracle's Excel add-in for connecting to EPM | Reporting tool |
| **Sparse Dimension** | — | Dimension where many combinations have no data; creates separate blocks | Essbase design |
| **Store** | — | Data storage type: data physically saved in the cube | Member property |
| **Substitution Variable** | — | Global placeholder whose value can be changed without editing the app | Administration |

## T

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **Task List** | — | A list of tasks assigned to users in a defined sequence | Workflow |
| **Time Balance** | — | How monthly data rolls up to quarterly/yearly (Flow, First, Balance, etc.) | Account property |
| **TRCS** | Tax Reporting Cloud Service | Oracle tool for tax calculations and reports | EPM Pillar #7 |

## U-V

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **UDA** | User-Defined Attribute | Custom text label attached to members for filtering and grouping | Member property |
| **Valid Intersection** | — | Rules defining which dimension combinations are allowed | Data integrity |
| **Variance** | — | Difference between Budget/Forecast and Actual | Finance analysis |
| **Version** | — | Dimension tracking Working vs Approved vs What-If drafts | Standard dimension |

## W-Y

| Term | Full Form | Definition | Context |
|---|---|---|---|
| **What-If Analysis** | — | Testing hypothetical scenarios without changing official data | Planning concept |
| **Workflow** | — | A defined sequence of steps (submit → review → approve) | Process |
| **YTD** | Year-to-Date | Total from the start of the year until current date | Finance term |

---

> **Tip:** Use `Ctrl+F` to search for any term quickly.

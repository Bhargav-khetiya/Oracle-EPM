# 03 Application Creation: Screen-by-Screen Walkthrough, Every Property, and Behind-the-Scenes Mechanics

## 1. The Application Creation Lifecycle

Creating an Oracle EPM Cloud application is an irrevocable architectural event. Several settings chosen during this 5-minute wizard permanently dictate the physical database structure, relational repository schemas, and dimensional layout of the environment.

```
+===================================================================================================+
|                                APPLICATION CREATION WIZARD PIPELINE                               |
+===================================================================================================+
|                                                                                                   |
|  [STEP 1: LANDING PAGE & TYPE SELECTION]                                                          |
|  Select Application Type: Planning (Custom / Module-Based) or FreeForm                           |
|                                                  |                                                |
|                                                  v                                                |
|  [STEP 2: GENERAL INFORMATION]                                                                    |
|  Application Name (Max 8 characters) & Description                                                |
|                                                  |                                                |
|                                                  v                                                |
|  [STEP 3: CALENDAR & TIME FREQUENCY]                                                              |
|  Start Month, First Fiscal Year, Number of Years, 12 vs 13 Periods, Weekly Distribution (4-4-5)   |
|                                                  |                                                |
|                                                  v                                                |
|  [STEP 4: CURRENCY & MULTI-CURRENCY TOPOLOGY]                                                     |
|  Multi-Currency (Yes/No), Base Currency Code                                                      |
|                                                  |                                                |
|                                                  v                                                |
|  [STEP 5: ADVANCED ARCHITECTURAL TOGGLES]                                                         |
|  Sandboxes (HSP_View dimension), Strategic Modeling, Hybrid BSO Mode                              |
|                                                  |                                                |
|                                                  v                                                |
|  [STEP 6: SUMMARY & ATOMIC PROVISIONING]                                                           |
|  Initializes Relational Repository + Provisions Essbase Cubes on Cloud Disk                       |
|                                                                                                   |
+===================================================================================================+
```

---

## 2. Screen-by-Screen Exhaustive Property Analysis

### Screen 1: Landing Page & Application Type
* **Options**:
  * **Planning**: Standard enterprise planning. Can be initialized as a blank **Custom** application or configured with pre-built **Modules** (Financials, Workforce, Capital, Projects).
  * **FreeForm**: Unconstrained pure Essbase in the cloud with zero required dimensions.

### Screen 2: General Properties
* **Application Name**:
  * **Rule**: Maximum of **8 alphanumeric characters** (e.g., `Vision`, `CorpPlan`, `FinApp`).
  * **Why 8 characters?**: Legacy Essbase operating system directory limitations require 8-character folder names.
* **Description**: Freeform text explaining business ownership.

### Screen 3: Time & Calendar Architecture

| Property Field | Options | Architectural Meaning & Behind-the-Scenes Effect | Can it be Changed Later? |
| :--- | :--- | :--- | :--- |
| **First Fiscal Year** | Dropdown (e.g., `FY20`) | The earliest historical year stored in the `Years` dimension. | **NO**. Irrevocable. |
| **Number of Fiscal Years**| Integer (e.g., `10`) | Instantiates sequential members in the `Years` dimension (e.g., FY20 through FY29). Additional future years can be appended later. | Additional years can be added. |
| **Fiscal Year Start Month**| January, April, July, October | Dictates the calendar cutover for annual rollups. E.g., July start means Q1 = Jul, Aug, Sep. | **NO**. Irrevocable. |
| **Period Frequency** | **12 Month** vs. **13 Period** | *12 Month*: Standard calendar months (Jan–Dec). *13 Period*: Manufacturing / Retail calendar with 13 four-week periods (P01–P13). | **NO**. Irrevocable. |
| **Weekly Distribution** | **Even**, **4-4-5**, **4-5-4**, **5-4-4** | Dictates how weekly operational feeds distribute into monthly buckets. *4-4-5*: Month 1 has 4 weeks, Month 2 has 4 weeks, Month 3 has 5 weeks. | **NO**. Irrevocable. |

### Screen 4: Currency & Exchange Rate Architecture

| Property Field | Options | Architectural Meaning & Behind-the-Scenes Effect | Can it be Changed Later? |
| :--- | :--- | :--- | :--- |
| **Multi-Currency** | **Yes** / **No** | If **Yes**: Automatically instantiates the **`Currency`** dimension, creates the **`HSP_Rates`** exchange rate cube, and seeds rate accounts (`HSP_Rate_Average`, `HSP_Rate_Ending`). If **No**: Cube operates strictly in a single currency. | **NO**. Cannot enable or disable later! |
| **Base Currency** | Dropdown (USD, EUR, GBP, JPY, CAD) | The default corporate functional currency assigned to `Entity` members unless overridden. | **NO**. Irrevocable. |

### Screen 5: Advanced Features & Architectural Toggles

| Advanced Feature | Default | Detailed Technical Impact | Recommendation |
| :--- | :--- | :--- | :--- |
| **Sandboxes** | Disabled | If enabled: Automatically creates the system dimension **`HSP_View`** with members (`BaseData`, `Sandbox_Active`, `ConsolidatedData`). Allows private what-if modeling. **Drawback**: Increases block storage overhead by creating virtual sandbox slices. | Enable ONLY if client explicitly requires private user scenarios. |
| **Strategic Modeling** | Disabled | Enables the acquired Hyperion Strategic Finance (HSF) in-memory long-range engine. | Enable if 5–10 year strategic M&A is needed. |
| **Hybrid BSO Mode** | **Enabled** | Automatically configures the Essbase engine to support Dynamic Calc on sparse dimensions, eliminating batch aggregation scripts. | **Always keep Enabled**. |

---

## 3. What Happens Behind the Scenes During the 5-Minute Build?

When you click **Create Application**, Oracle EPM Cloud triggers an asynchronous infrastructure orchestrator:

```
[User Clicks 'Create']
         |
         v
[Step 1: Relational Metadata Schema Provisioning]
  - Initializes Autonomous Database schema.
  - Formats tables: HSP_OBJECT, HSP_MEMBER, HSP_DIMENSION, HSP_CUBE, HSP_ACCESS.
  - Seeds predefined system accounts: HSP_Rates, BegBalance, No Year, No Period.
         |
         v
[Step 2: Essbase Kernel Directory Formatting]
  - Spawns cloud container process.
  - Formats disk directory: /u01/data/essbase/app/<AppName>/
  - Creates initial BSO calculation cube (Plan1 or OEP_FS).
  - Formats default .pag and .ind storage structures.
         |
         v
[Step 3: Core Dimensions Seeded]
  - Account, Entity, Scenario, Version, Period, Years.
  - (Optional) Currency dimension + HSP_Rates cube.
  - (Optional) HSP_View dimension (if Sandboxes enabled).
         |
         v
[Step 4: Web Presentation Artifact Registration]
  - Seeds default Navigation Flow ("Default").
  - Formats default administrative security groups in OCI IAM / IDCS.
  - Writes completion flag (Status = Active). Application is live!
```

---

## 4. The 5 "Golden Traps" of Application Creation (Review Killers!)

These are the exact trap questions interviewers use to detect inexperienced consultants:

### Trap 1: "A client created an application with Multi-Currency = No. Two months into UAT, they acquired a UK subsidiary and need GBP. How do you enable Multi-Currency?"
* **The Trap**: Claiming you can go to Dimension Library or Application Settings to check a box.
* **The Truth**: **You CANNOT enable Multi-Currency post-creation!** It is an irrevocable binary switch at application initialization. The only solution is to **recreate the application** or build a custom currency dimension workaround.

### Trap 2: "Can you change the Fiscal Year Start Month from January to July after go-live?"
* **The Truth**: **NO**. The fiscal year start month permanently establishes the internal calendar token index in Essbase. Changing it requires an application rebuild.

### Trap 3: "What is the consequence of enabling Sandboxes 'just in case'?"
* **The Truth**: Enabling Sandboxes creates the `HSP_View` dimension permanently. Every query, form, and calculation script must now account for `HSP_View`. It creates dense/sparse block indexing overhead and **cannot be deleted**. Never enable it unless there is an approved business requirement.

### Trap 4: "What is the maximum number of characters permitted for an application name, and why?"
* **The Truth**: **8 alphanumeric characters**. Because under the hood, Essbase creates physical file system directory paths on Linux (`/app/<AppName>`) based on legacy 8.3 filename conventions.

### Trap 5: "When should you use 13-Period frequency instead of 12-Month?"
* **The Truth**: Use **13-Period** for **Retail and Hospitality clients** who operate on 4-week reporting cycles (52 weeks = $13 \times 4$-week periods). This eliminates the distortion caused by months having different numbers of weekends (e.g., February 28 days vs. March 31 days).


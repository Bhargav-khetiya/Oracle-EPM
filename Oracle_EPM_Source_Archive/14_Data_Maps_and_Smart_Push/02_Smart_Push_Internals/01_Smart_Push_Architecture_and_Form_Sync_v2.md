# 01 Smart Push Architecture, Form Integration, and Real-Time Sync

## 1. Architectural Essence of Smart Push

**Smart Push** is the presentation-layer operational manifestation of Oracle EPM Cloud Data Maps. While a Data Map defines the theoretical data routing rules between two cubes, Smart Push binds that definition directly to a Web Data Form or Ad-Hoc Grid, enabling instantaneous, bidirectional, or unidirectional data movement immediately upon user interaction (specifically upon clicking **Save**).

```
+---------------------------------------------------------------------------------------------------+
|                                     SMART PUSH EXECUTION PIPELINE                                 |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  +------------------------+                                                                       |
|  |     WEB DATA FORM      |  User edits cells (e.g., Q1 Travel Expense = $5,000)                  |
|  | [Page: Dept_100, USD]  |  User clicks [ SAVE ] button                                          |
|  +------------------------+                                                                       |
|              |                                                                                    |
|              | 1. Form Save Transaction Intercept                                                 |
|              v                                                                                    |
|  +------------------------+      2. Intersect Form Context with Map Slice                         |
|  | PLANNING FORM ENGINE   | -------------------------------------------------+                    |
|  | - Evaluates Dirty Grid |                                                  |                    |
|  | - Commits to Source BSO|                                                  |                    |
|  +------------------------+                                                  v                    |
|              |                                              +---------------------------------+   |
|              | 3. Invoke Smart Push Engine                  |      DYNAMIC POV SLICER         |   |
|              v                                              | [Page: Dept_100]                |   |
|  +-------------------------------------------------------+  | [POV:  FY24, Plan, Working]     |   |
|  | SMART PUSH ENGINE (Micro-Slice Extraction)            |  | [Rows: Travel_Exp]              |   |
|  | - Extracts ONLY dirty coordinates or visible grid slice |  | [Cols: Jan, Feb, Mar]           |   |
|  +-------------------------------------------------------+  +---------------------------------+   |
|              |                                                               |                    |
|              | 4. Parallel Stream Load Buffer                                |                    |
|              v                                                               v                    |
|  +---------------------------------------------------------------------------------------------+  |
|  | TARGET REPORTING CUBE (ASO / BSO)                                                           |  |
|  | - Ingests Micro-Slice into ASO In-Memory Load Buffer (Buffer ID: 101)                       |  |
|  | - Commits as a 1-second Micro-Slice file                                                    |  |
|  +---------------------------------------------------------------------------------------------+  |
|              |                                                                                    |
|              | 5. Return Control to User Interface (< 1.5 seconds)                                |
|              v                                                                                    |
|  +------------------------+                                                                       |
|  | FORM REFRESH COMPLETE  |  User sees saved values, target reports reflect changes immediately.  |
|  +------------------------+                                                                       |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Form-Level Smart Push Configuration

Administrators associate Data Maps with forms through the **Form Designer** under the **Smart Push** tab.

### 2.1 Configuration Attributes in Form Designer

| Configuration Setting | Options | Operational Meaning and Performance Impact |
| :--- | :--- | :--- |
| **Data Map Selection** | Dropdown of active maps | Selects the underlying dimensional translation and routing rules. |
| **Run On Save** | Checked / Unchecked | If **Checked**, Smart Push executes synchronously or asynchronously immediately when the user clicks Save. |
| **Use Form Context** | Checked / Unchecked | **Critical Setting**: If checked, limits the pushed data to the members present in the form's POV, Page, Rows, and Columns. If unchecked, pushes the entire global definition of the Data Map. |
| **Run in Background** | Checked / Unchecked | If checked, releases the user interface immediately while offloading the data push to the server's background task queue. |
| **Overwrite Data** | Checked / Unchecked | Dictates whether target values are overwritten by incoming source numbers. |

---

## 3. Context-Aware Micro-Slice vs. Global Macro-Slice

The defining architectural differentiator between a generic Data Map push and an optimized Smart Push is the **Context Intersection Engine**.

### 3.1 The Danger of Global Macro-Slices
If a form designer forgets to check **Use Form Context**, saving a form where a user modified a single $50 cell triggers a **Full Macro-Slice Push**. 
* The engine queries the entire Data Map definition (e.g., all 500 Entities, 1,200 Accounts, 5 Years, and 12 Periods).
* This extracts 1,000,000+ cells, creates massive ASO load buffers, and locks server threads for 30–60 seconds.
* The end user experiences severe browser freeze, often resulting in gateway timeout errors (HTTP 504).

### 3.2 The Micro-Slice Resolution Algorithm
When **Use Form Context** is enabled, the Planning server performs a mathematical set intersection between the form's active layout and the Data Map's inclusion criteria:

$$\text{Pushed Slice} = \text{Form Active Coordinates} \cap \text{Data Map Definition}$$

```
Form Context:
  - Page: Entity = "E101_Sales_East"
  - POV:  Scenario = "Plan", Version = "Working", Years = "FY24"
  - Rows: Accounts = "Advertising", "Travel", "Meals" (3 members)
  - Cols: Periods = "Jan", "Feb", "Mar" (3 members)
Total Form Coordinate Space: 1 * 1 * 1 * 1 * 3 * 3 = 9 cells.

Data Map Scope:
  - Entity: ILvl0Descendants("Total_Company") (500 entities)
  - Accounts: ILvl0Descendants("Operating_Expenses") (150 accounts)
  - Periods: Jan:Dec (12 periods)

Smart Push Resolution:
  Extracts and pushes ONLY the 9 cells intersecting the user's active grid!
  Execution Duration: < 400 milliseconds.
```

---

## 4. Run on Save Lifecycle and Execution Flow

When a user submits edits on a Web Data Form with Smart Push enabled, the platform executes a precise sequence of events:

```
[User Action: Click 'Save']
       |
       v
[Step 1: Client Validation] -> Verifies formula syntax, required cells, read-only locks.
       |
       v
[Step 2: Server Data Ingestion] -> Writes dirty cells to Source BSO cube blocks.
       |
       v
[Step 3: Run Before Save Business Rules] -> (If attached to form).
       |
       v
[Step 4: Commit Source Block Storage] -> Flushes BSO dirty blocks to disk cache.
       |
       v
[Step 5: Smart Push Context Evaluation] -> Builds micro-slice MDX specification.
       |
       v
[Step 6: Stream Micro-Slice to Target] -> Opens ASO buffer, writes rows, commits slice.
       |
       v
[Step 7: Run After Save Business Rules] -> (If attached to form).
       |
       v
[Step 8: UI Acknowledgement] -> "Data has been saved. Smart Push completed."
```

---

## 5. Synchronous vs. Asynchronous (Background) Execution

Choosing between synchronous and asynchronous Smart Push depends entirely on workflow requirements and data volume:

### 5.1 Synchronous Push (Run in Background = False)
* **Behavior**: The web browser displays a loading spinner until both the source save and the target Smart Push are 100% committed.
* **When to Use**:
  * Highly interactive planning where the user immediately navigates to a summary dashboard tab fed by the target cube.
  * Micro-slices involving fewer than 5,000 cells.
* **Risk**: If the slice takes longer than 15–20 seconds, user productivity drops and browser timeout thresholds may be breached.

### 5.2 Asynchronous Push (Run in Background = True)
* **Behavior**: The source form save completes immediately (1–2 seconds), unlocking the UI for the user. A notification banner informs the user that data is being synchronized in the background.
* **When to Use**:
  * Large forms where a user edits hundreds of rows across multiple pages (e.g., workforce roster grids or mass Capex entry).
  * Forms where target calculations or aggregations are intensive.
* **Job Tracking**: Background Smart Push creates an asynchronous job entry in the **Job Console**, allowing administrators to monitor status, duration, and error stacks.

---

## 6. Smart Push Tuning and Best Practices Matrix

| Problem Area | Architectural Root Cause | Corrective Architecture |
| :--- | :--- | :--- |
| **Save Latency > 15s** | "Use Form Context" is unchecked; entire cube is being pushed. | Check **Use Form Context** in Form Designer -> Smart Push tab. |
| **Dynamic Calc Target Error** | Target cube contains dynamic calculation members mapped from source. | Exclude dynamic members from Data Map or map to stored level 0 targets. |
| **Grid Too Large** | Form displays 10,000+ rows; micro-slice is effectively a macro-slice. | Apply suppression (Suppress Missing, Suppress Zero) or partition form across pages. |
| **ASO Target Degradation** | High-frequency Smart Push generates hundreds of tiny ASO slices daily. | Implement automated nightly ASO slice merge jobs via EPM Automate. |
| **Data Mismatch on Dashboard** | Smart Push runs in background and user refreshes dashboard before commit completes. | Educate users or switch critical summary forms to synchronous push. |

---

## 7. Master Pedagogical Reference & Recall Guide (The 12 Pillars)

### 1. Core Idea
**Smart Push is a real-time form event trigger that instantly extracts the edited dimensional slice from a BSO planning cube and streams it directly into an ASO reporting cube using in-memory load buffers upon clicking Save.**

### 2. Simple Explanation & Analogy
* **Everyday Analogy**: Think of Smart Push as real-time document synchronization in Google Docs or OneDrive. When you type in a shared document on your laptop, the changes are instantly synchronized to your colleague's tablet screen across the world without requiring you to manually export, email, and re-import a PDF file.

### 3. Purpose: Why It Matters
In enterprise planning, executives want to see real-time corporate dashboard updates the moment department managers submit their budgets. Without Smart Push, administrators have to run batch ETL scripts every night, leaving reporting dashboards 24 hours behind actual planning numbers. Smart Push eliminates this delay while keeping the main planning cube fast and lean.

### 4. Connections to Other Concepts
* **Data Maps ([Vol 08: Data_Maps_Core_Architecture](../01_Data_Maps_Architecture_and_Design/01_Data_Maps_Core_Architecture_and_HSP_Tables.md))**: Defines the static dictionary of how source dimensions map to target dimensions.
* **ASO Load Buffers ([02_ASO_Load_Buffers_and_Slice_Internals.md](./02_ASO_Load_Buffers_and_Slice_Internals.md))**: Smart Push streams numbers directly into Essbase `EssWriteLoadBuffer` memory structures rather than staging text files.
* **ASO Slice Merging ([03_ASO_Slice_Merge_and_Compaction_Strategies.md](./03_ASO_Slice_Merge_and_Compaction_Strategies.md))**: Every Smart Push save creates an incremental data slice; frequent saves require nightly slice compaction to prevent hitting the 256-slice limit.

### 5. Prerequisites & Assumptions
* Pre-existing source cube (BSO) and target reporting cube (ASO or BSO).
* An active, validated Data Map configured under `Application -> Data Exchange -> Data Maps`.
* Write access to the source form and target cube members.

### 6. How It Works: Micro-Slice Data Pipeline
```
[User Clicks Save on Web Form]
               │
               ▼
   [Planning Form Save Intercept]
   Evaluates dirty cells and commits to Source BSO Cube
               │
               ▼
     [Smart Push Slice Generator]
   Filters Data Map to exact POV, Page, Row, and Column members
               │
               ▼
      [In-Memory Buffer Stream]
   Streams coordinates into Target ASO Cube Load Buffer
               │
               ▼
      [Target Slice Commit]
   Creates small incremental ASO data slice (<1.5 seconds)
               │
               ▼
[Browser Unlocks: Real-Time Sync Complete]
```

### 7. How to Do It: Step-by-Step Form Association
1. Navigate to **Navigator $\to$ Forms $\to$ Edit Form**.
2. Click the **Smart Push** tab at the top of the Form Designer.
3. Click the **+ (Add)** button and select the desired Data Map from the dropdown.
4. Ensure **Run On Save** is checked.
5. Check **Use Form Context** (critical to ensure only current page/POV is pushed).
6. Decide whether to check **Run in Background**:
   * *Unchecked (Synchronous)*: For small forms (<5,000 cells) where users immediately view reports.
   * *Checked (Asynchronous)*: For massive input rosters with hundreds of rows.
7. Click **Save** and close the Form Designer.

### 8. Worked Example (Illustrative)
> *(Note: The following scenario is illustrative for learning purposes)*
* **Source Form**: `OEP_FS` (Financials BSO Cube)
* **Target Cube**: `OEP_REP` (Corporate Reporting ASO Cube)
* **Form POV**: `FY25`, `Plan`, `Working`, `USD`
* **Form Page**: `Dept_210` (Human Resources)
* **User Action**: Planner enters `$15,000` into `Airfare_Expense` for `Jan`, `Feb`, and `Mar`, and clicks **Save**.
* **Smart Push Action**:
  Instead of pushing all 500 departments and 1,000 accounts, Smart Push slices strictly:
  `POV: FY25, Plan, Working, USD | Page: Dept_210 | Account: Airfare_Expense | Periods: Jan, Feb, Mar`
  *(Execution: 3 cells streamed into ASO buffer; total elapsed time: 0.85 seconds!)*

### 9. Compare Choices: Cross-Cube Data Movement Methods

| Method | Trigger | Scope | Target Engine | User Wait Time |
| :--- | :--- | :--- | :--- | :--- |
| **Smart Push** | Web Form Save | Micro-slice (Current Form Context) | ASO or BSO | <1.5s (Synchronous) or 0s (Background) |
| **Scheduled Data Map** | Nightly / On-Demand | Full Dimension Slices | ASO or BSO | Several minutes (Batch Job) |
| **`@XWRITE` / `@XREF`** | Calculation Script | Explicit FIX coordinates | BSO to BSO/ASO | Depends on script size (5s–60s) |
| **Groovy Data Mover** | Custom Button / Event | Custom in-memory matrix | ASO or BSO | Sub-second programmatic push |

### 10. How to Validate Success
1. Open the source web form, edit a number, and click **Save**.
2. Open a separate Smart View sheet connected directly to the target reporting cube.
3. Refresh the exact same coordinates in Smart View; confirm the updated value appears immediately.
4. In the Planning UI, navigate to **Application $\to$ Jobs**; confirm the Smart Push job status displays **Completed** with green checkmark.

### 11. Troubleshooting Common Issues
* **Symptom: Form save takes 25 seconds after attaching Smart Push.**
  * *Cause*: **Use Form Context** was left unchecked in the Form Designer. The system is attempting to push all years, departments, and accounts defined in the Data Map.
  * *Remedy*: Open Form Designer $\to$ Smart Push tab; enable the **Use Form Context** checkbox.
* **Symptom: Smart Push fails with error: `Cannot write to dynamic calculation member`.**
  * *Cause*: The source contains stored accounts that map to a member in the target cube whose storage property is set to `Dynamic Calc`.
  * *Remedy*: Adjust the Data Map to map strictly to Level 0 stored target members, or change the target member property to `Store`.
* **Symptom: Smart Push aborts with error: `Maximum number of slices (256) reached`.**
  * *Cause*: Target ASO cube has accumulated 256 micro-slices from hundreds of form saves without running a slice merge.
  * *Remedy*: Execute an ASO Slice Merge job immediately with zero elimination via the Job Console or EPM Automate.

### 12. Remember and Explain It (Active Recall & Teach-Back)
* **Quick Recap**: Smart Push connects Data Maps to Web Forms, automatically streaming micro-slices into ASO reporting cubes upon clicking Save. Always check "Use Form Context."
* **Recall Question 1**: What happens if "Use Form Context" is disabled on a form's Smart Push configuration—
  * *Answer*: Smart Push will push the entire global scope of the Data Map rather than just the visible form members, causing severe save latency.
* **Recall Question 2**: Why is pushing data to an ASO reporting cube preferable to having all users report directly out of the BSO planning cube—
  * *Answer*: BSO cubes must lock blocks during calculations and input, causing user contention. ASO reporting cubes aggregate millions of cells dynamically in-memory without locks or batch calculation scripts.
* **Teach-Back Prompt**: *Explain the difference between a scheduled batch Data Map and a real-time Smart Push to a financial analyst who wants to know why their executive dashboard updates immediately after they hit Save.*


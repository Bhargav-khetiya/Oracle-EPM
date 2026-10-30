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


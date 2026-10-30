# Oracle EPM Cloud: The Ultimate Master Guide to Task Lists

## 1. Introduction: What are Task Lists?
**Task Lists** in Oracle EPM Cloud (EPBCS/PBCS) organize groups of tasks for users, providing a structured, step-by-step way to guide planners and administrators through business processes (like budgeting and forecasting). By providing a clear list of tasks, instructions, dependencies, and due dates, Service Administrators can ensure that users complete their workflows in the correct order.

### Task Lists vs. EPM Task Manager
When a new EPM application is created, administrators are presented with two task flow options:
1. **Task Lists (Classic):** The traditional planning task management system.
2. **EPM Task Manager:** The newer, default option for modern EPM applications, offering highly advanced workflow, orchestration, and dashboarding capabilities.

> [!WARNING] 
> **Migration to Task Manager:** If you are using Classic Task Lists, you *can* upgrade to EPM Task Manager (via Application > Overview > Actions > Enable Task Manager). However, you **cannot** migrate existing tasks. All classic Task Lists must be completely deleted before the upgrade, and you **cannot revert** the change once enabled.

---

## 2. Creating and Organizing Task Lists
*(Navigation: Navigator > Create and Manage > Task Lists)*

Before creating individual tasks, you must create a **Task List** container to hold them. 
* **Create / Rename / Remove:** Basic management of the folders holding your tasks.
* **Move / Reorder:** Move a Task List into a specific folder or move it up/down to dictate the order in which users see the lists.
* **Instructions:** Adding detailed rich-text instructions at the *Task List level* helps users understand the overall goal of the specific process.

---

## 3. Adding and Configuring Tasks (Objects That Can Be Attached)
Once the Task List exists, you add individual tasks as children. Tasks can be flat, or nested hierarchically (Parent Tasks with Child Tasks).

### Available Task Types
When defining a task, select its **Type** to determine what action happens:
* **Form:** Opens a specific Data Form. *Note: You can set Page Member Defaults here, which override the most recently used settings in a user's session.*
* **Business Rule:** Executes a specific calculation attached to a selected cube.
* **Manage Approvals:** Starts the review process for a specific scenario and version.
* **URL:** Opens an external website or system.
* **Dashboard:** Opens an EPM Dashboard. *(Note: Only available in the Simplified Interface).*
* **Copy Version:** Copies data, supporting detail, cell text, and documents for specified source/destination versions. *(Not available to Power Users and Users).*
* **Job Console:** Opens the job console to view jobs (like copy/push data) by type and completion status.
* **Dimension Editor:** Enables administrators to view/modify dimensions at runtime.
* **Refresh Application:** Captures recent changes by refreshing the application at runtime.
* **Import and Export:** Allows metadata/data import and export via flat files.
* **Descriptive:** A "dummy" task with no interactive properties. Used purely as a placeholder or text instruction.

> [!NOTE] 
> Legacy tasks like *Security Management, Process Management*, and *Form Management* are only available in the old Desktop interface and cannot be added/edited in the modern Simplified Interface.

### Scheduling, Alerts, and Durations
* **Duration:** Define how long the task should take (e.g., `2 d` for 2 days, `1 w` for 1 week).
* **Start & End Dates:** Enforce exact timestamps for when a task opens and when it is due.
* **Alerts & Reminders:** Configure automated emails. For example, if a task is due on Friday, configure an Alert to send emails on Wednesday, repeating every day until complete.

### Dependencies
You can force a chronological workflow by making a task dependent on another primary task.

> [!CAUTION]
> **Dependency Limitation:** Dependencies across task list hierarchies are **not supported when a task has children**. You cannot make a task completion dependent on a *child* task of another primary task. If a parent task is incomplete, its children are affected, but it is not recursive across different branches.

---

## 4. Security: Assigning Access
Just because a user can see a Data Form doesn't mean they can see the Task List containing it. Access must be explicitly granted, preferably via **Groups** rather than individual Users.

**Access Levels:**
* **Assigned:** The user can view the Task List and execute/complete the tasks within it. *(They cannot assign tasks to other people).*
* **Manage:** The user can modify the Task List structure.
* **Manage and Assign:** The user can modify the Task List and grant access to other users.
* **None:** The user cannot see the Task List.

---

## 5. Maintenance and Lifecycle

### Copying and Moving Tasks
* **Copying:** Highlight a task and click **Save As** to duplicate it.
* **Cut/Paste (Moving):** Move a task from one Task List to another, or convert a flat task into a child of another parent task.

### Clearing Task Lists (The Rollover Process)
At the end of a planning cycle, tasks are marked as "Complete". To reuse the exact same Task List for the next cycle, use the **Clear Task List** function to wipe:
1. **Completion Status:** Unchecks the tasks so they are fresh for new users.
2. **Due Dates and Alerts:** Clears out hardcoded dates and disables email alerts.
3. **Both:** Completely resets the Task List for immediate reuse.

---

## 6. Deep Dive: Administering Tasks with Task Manager
While Classic Task Lists are useful, **EPM Task Manager** provides centralized monitoring and a visible, automated system of record for running business processes.

### Core Task Manager Terms (The Hierarchy)
Task Manager relies on a robust hierarchy of structured components:
1. **Tasks:** Activities performed during a business process. Service Administrators define tasks (start/end dates, assignees). Users execute and submit them.
2. **Templates:** A repeatable set of tasks saved for future periods (e.g., monthly).
3. **Schedules:** An ordered set of tasks mapped to calendar dates, created from templates. When mapped and opened, tasks start automatically.
4. **Task Types:** Standardizes task details across all tasks of the same type.
   * **Basic Task:** Default, no specific details.
   * **Parent Task:** Creates task hierarchies (e.g., parent *Load Data*, children *Load EMEA* and *Load NA*).
   * **Integration Task:** Links to external applications (e.g., automatically triggering processes in *Account Reconciliation*).

### Managing Operational Dashboards
Task Manager includes powerful visual analytics to track task completion status globally.

**Example: Building a "Completion by Region" Chart**
Assuming a custom `Organizational Unit` attribute exists:
1. Click the **Object Type** icon and select **Tasks**.
2. Click the **View Selector** icon and select **Chart View**.
3. Click the **Settings** icon and specify:
   * **Properties tab:** Title: *Completion by Region*, Type: *Column*, Background: *No fill*, Label Position: *Inside Edge*, Orientation: *Horizontal*, Grid Lines: *Checked*, Period: *Selection*.
   * **Layout tab - X-Axis:** Type: *Attribute*, Attribute 1: *Organizational Unit*, Sort: *Organizational Unit (Descending)*.
   * **Layout tab - Legend (Series):** Value: *Task*, Aggregation: *Count*, Categories: *Status*.
   * **Axis tab - Y Axis:** *Checked*, all settings *Auto*.
   * **Legend tab:** Position: *Right*, Palette: *Redwood*, keep default labels (Closed, Error, Open, Pending).
4. Click **OK**. This results in a real-time column chart showing regions falling behind in tasks.

---

## 7. What Senior Consultants Expect You to Know
* **Migration Strategy:** The irreversible nature of upgrading to Task Manager and the requirement to delete classic Task Lists first.
* **State Overrides:** Understanding that setting Page Member Defaults in a Form task will overwrite a user's recent session selections.
* **Metadata Flow:** Task Lists are relational metadata in EPM, exportable via LCM (Migration) under "Relational Data" or "Planning".
* **Security Architecture:** Access control should be maintained cleanly via Groups with standard "Assigned" access for end-users.

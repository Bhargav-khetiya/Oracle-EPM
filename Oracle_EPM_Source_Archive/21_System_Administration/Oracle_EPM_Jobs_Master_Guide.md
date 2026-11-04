# Oracle EPM Cloud: The Ultimate Master Guide to Jobs

## 1. Introduction: What are Jobs—
In Oracle EPM Cloud, **Jobs** automate repetitive tasks and data operations. Instead of manually running rules or moving data, administrators can define jobs to execute complex processes either on-demand or on a predetermined schedule.

---

## 2. Job Types
The system supports a wide variety of job types. The most critical include:

* **Rules / Rulesets:** Executes Calculation Manager Business Rules or groupings of rules.
* **Clear Cube:** Wipes data from specific intersections before new data is loaded or calculated.
* **Copy Data:** Copies data from one intersection to another (e.g., Actuals to Forecast).
* **Export Data / Import Data:** Extracts or loads flat files of data to/from the application.
* **Export Metadata / Import Metadata:** Extracts or loads dimension hierarchies.
* **Restructure Cube:** Optimizes the underlying Essbase database to improve performance after significant metadata changes.
* **Map Data:** Pushes data from one cube to another using Data Maps.
* **Invalid Intersection Reports:** Generates reports showing where data exists in invalid intersections.

---

## 3. Scheduling Jobs
Jobs can be scheduled to run automatically, saving administrators significant time.
*(Navigation: Application > Jobs > Schedule)*

**Scheduling Options:**
* **Run Now:** Executes the job immediately in the background.
* **Run Later:** Schedules the job for a specific future date and time.
* **Hourly / Daily / Weekly / Monthly / Yearly:** You can configure precise recurring schedules. For example, scheduling an "Hourly" data push to a reporting cube during the month-end close.

**Job Console / Status:**
You can view the progress of running jobs and the historical logs of completed/failed jobs in the Job Console.

---

## 4. Front End vs. Back End Operations

### Front End
* **Navigation:** **Application > Jobs**.
* **Usage:** Administrators define the job parameters in the UI and save them as reusable templates.

### Back End
* **Migration:** Jobs are migrated via LCM (Migration) under the "Relational Data" -> "Jobs" artifact.
* **EPM Automate:** This is the most common back-end interaction. Jobs defined in the UI are triggered externally by integration scripts using the `epmautomate runJob "JobName"` command.

---

## 5. What Senior Consultants Expect You to Know

> [!CAUTION]
> **Concurrent Job Limitations**
> EPM Cloud places limits on concurrent jobs. If you schedule 10 heavy "Copy Data" jobs to run at the exact same time, the system will queue them or fail out due to resource contention. Seniors expect you to stagger job schedules.

> [!IMPORTANT]
> **EPM Automate vs. UI Scheduling**
> While the UI scheduler is great for simple tasks, Enterprise architectures **do not** use the UI scheduler for primary integrations. Seniors expect all critical jobs to be orchestrated externally via EPM Automate or REST API in a centralized scheduling tool (like Control-M, Autosys, or OCI Data Integration) to allow for error handling and dependency chaining.

> [!TIP]
> **Clear Cube Jobs**
> Never use a Business Rule (`CLEARDATA`) to clear an entire scenario/version. Seniors expect you to use the **Clear Cube** job type, which drops the physical data blocks in Essbase and is exponentially faster.

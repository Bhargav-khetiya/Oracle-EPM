# Oracle EPM Cloud: The Ultimate Master Guide to Daily Maintenance

## 1. Introduction: Automated Maintenance Window (AMW)
Every Oracle EPM Cloud environment requires a one-hour period each day to perform essential maintenance. This is known as the **Daily Maintenance Window**. During this time, the system automatically backs up the application, applies any necessary patches, and resets the services to ensure peak performance.

---

## 2. Setting the Maintenance Time
*(Navigation: Tools > Daily Maintenance)*

Administrators must set the maintenance start time. 
* **Best Practice:** The time should be scheduled during the absolute lowest period of user activity (e.g., 2:00 AM local time).
* **Duration:** While the window is scheduled for one hour, routine maintenance usually completes in 15-30 minutes unless Oracle is applying a major monthly patch.
* **User Impact:** During the maintenance window, the application is **completely unavailable** to users. Any running jobs, data loads, or calculations may be forcefully terminated.

---

## 3. The Artifact Snapshot (Backup)
The most critical output of the Daily Maintenance process is the **Artifact Snapshot**.
* Every day, the system takes a full backup of the entire environment (Metadata, Data, Forms, Rules, Security, etc.) and overwrites the previous day's snapshot file.
* The snapshot is named `Artifact Snapshot` and is stored in the migration inbox/outbox.

> [!WARNING]
> **Retention Policy**
> Oracle EPM Cloud only retains the **most recent** Artifact Snapshot. Yesterday's snapshot is permanently overwritten by today's snapshot. 

---

## 4. Front End vs. Back End Operations

### Front End
* **Setting the Time:** Administrators change the AMW time via the UI.
* **Manual Export:** Administrators can manually navigate to Migration, select the `Artifact Snapshot`, and download it to their local computer for safekeeping.

### Back End (EPM Automate)
* **Automated Backups:** Because Oracle only keeps one day of backups, it is an absolute requirement for administrators to use EPM Automate to download the snapshot daily.
  * Command: `epmautomate downloadfile "Artifact Snapshot"`
* **Forcing Maintenance:** You can force the maintenance window to run immediately using:
  * Command: `epmautomate runDailyMaintenance`

---

## 5. What Senior Consultants Expect You to Know

> [!IMPORTANT]
> **Disaster Recovery (DR) and Archiving**
> Senior architects expect a fully automated script to run daily (usually triggered by Windows Task Scheduler or a Linux Cron job) that executes `epmautomate login`, `downloadfile "Artifact Snapshot"`, renames the file with the current timestamp (e.g., `Snapshot_2024_03_15.zip`), and archives it to a secure corporate server. **Relying solely on Oracle's single-day retention is an unacceptable architectural risk.**

> [!TIP]
> **Cloning Environments**
> Senior administrators use the daily maintenance snapshot to keep environments in sync. You can use the "Clone Environment" feature (or `epmautomate cloneEnvironment`) to automatically overwrite your Test environment with the Production environment's daily snapshot, ensuring UAT is always performed on fresh data.

> [!CAUTION]
> **Patching Schedule**
> Oracle applies patches on the first Friday of the month for TEST environments, and the third Friday of the month for PROD environments, exactly during this daily maintenance window. Seniors expect you to align critical testing around this schedule.

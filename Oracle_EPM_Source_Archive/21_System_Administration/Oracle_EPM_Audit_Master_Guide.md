# Oracle EPM Cloud: The Ultimate Master Guide to Auditing

## 1. Introduction: What is Auditing?
Auditing in Oracle EPM Cloud allows administrators to track changes made to the application. It answers the critical questions of "Who changed what, and when?" This is essential for SOX compliance, internal controls, and troubleshooting unexpected application behavior.

---

## 2. Types of Auditing & Enabling Tracking
*(Navigation: Tools > Audit)*

Auditing is NOT enabled by default. Administrators must explicitly turn on audit tracking for specific categories.

**Key Audit Categories:**
* **Data:** Tracks every single data value change, including the old value, new value, intersection, and the user who changed it.
* **Metadata:** Tracks changes to dimension members (additions, deletions, property changes).
* **Security:** Tracks changes to users, groups, and access assignments.
* **Form / Rule Definitions:** Tracks structural changes to artifacts (e.g., if a user modifies a Data Form layout or edits a Business Rule).
* **Variables:** Tracks updates to User and Substitution variables.
* **Approvals:** Tracks promotional path changes (e.g., when a budget is Signed Off or Rejected).

---

## 3. Viewing and Filtering Audit Details
Once enabled, the system logs the activity. Administrators can view the logs in the Audit interface.

* **Filtering:** You can filter logs by Date Range, User, Category (e.g., just Data changes), or specific Artifacts.
* **Exporting:** For compliance reporting, administrators can export the filtered audit logs to an Excel file.

---

## 4. Front End vs. Back End Operations

### Front End
* **Usage:** Administrators configure the categories to track and export the reports manually via the UI. End users do not have access to the Audit logs.

### Back End
* **EPM Automate:** Audit records cannot be migrated via LCM. However, administrators can automate the extraction of audit logs for external SIEM (Security Information and Event Management) systems using EPM Automate.
* **Purging:** EPM Automate is commonly used to clear out old audit data (`epmautomate clearAudit`) to prevent the relational database from growing too large.

---

## 5. What Senior Consultants Expect You to Know (Architecture & Limitations)

> [!CAUTION]
> **The Performance Impact of Data Auditing**
> Senior architects will warn you: **Do not indiscriminately turn on Data Auditing for the entire application.** Writing an audit record for every single cell calculation can cripple system performance. Only enable Data Auditing during critical planning cycles, or rely on other methods (like isolated reporting cubes) if full data traceability is strictly required.

> [!IMPORTANT]
> **Database Bloat and Purging Strategy**
> The audit log is stored in the EPM relational database. If left unchecked for years, a massive audit table can slow down basic application operations (like LCM exports). Seniors expect you to establish a **retention policy** (e.g., keep 90 days of logs in EPM) and schedule a monthly automated job to export the logs to a secure archive and immediately purge them from the EPM system.

> [!TIP]
> **Retroactive Auditing is Impossible**
> If a user makes a change to a security group, and Audit Tracking for "Security" was turned off at that exact moment, the record is gone forever. You cannot turn on auditing today and expect to see changes made yesterday. Seniors ensure all critical audit categories (especially Security and Metadata) are enabled on Day 1 of Go-Live.

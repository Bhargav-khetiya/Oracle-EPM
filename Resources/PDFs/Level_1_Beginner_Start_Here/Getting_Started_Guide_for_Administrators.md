# Getting Started Guide for Administrators — Complete Markdown Edition

> **Original PDF:** `Getting_Started_Guide_for_Administrators.pdf` | **Folder:** Level 1 (Beginner & Foundations)  
> **Purpose:** Definitive Markdown companion covering initial cloud tenant setup, user provisioning, daily maintenance scheduling, environment cloning, and Service Administrator responsibilities.

---

## Table of Contents
1. [Initial Tenant Activation & EPM Cloud Architecture](#tenant-activation)
2. [Identity Domain Security & User Provisioning](#user-provisioning)
3. [Environment Cloning & Snapshot Management](#environment-cloning)
4. [Daily Maintenance & Patching Window Setup](#daily-maintenance)
5. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Initial Tenant Activation & EPM Cloud Architecture <a name="tenant-activation"></a>

When Oracle provisions a new EPM Enterprise Cloud subscription, administrators receive access to two primary environments per pod: **Test (Dev)** and **Production (Prod)**.

### Administrator Onboarding Workflow
1. Access Oracle Cloud Infrastructure (`OCI`) Identity and Access Management (`IAM` / `IDCS`) console.
2. Verify initial `Service Administrator` identity domain credentials.
3. Access the EPM Cloud URL (`https://your-tenant.epm.us-phoenix-1.ocs.oraclecloud.com`).
4. Select application creation template (`Planning`, `Financial Consolidation`, `Account Reconciliation`, or `FreeForm`).

---

## 2. Identity Domain Security & User Provisioning <a name="user-provisioning"></a>

Oracle EPM Cloud uses a **4-Tier Pre-Defined Role Architecture** managed inside `Access Control -> Manage Users/Groups`:

| Pre-Defined Application Role | Access Level & Capabilities |
| :--- | :--- |
| **Service Administrator** | Complete control. Can create/delete applications, manage security, execute all REST/CLI batch commands, and access hidden diagnostics. |
| **Power User** | Can design forms, build business rules, create data maps, and manage metadata for their assigned dimensions. Cannot modify global security or restore snapshots. |
| **User (Planner)** | Read/Write access to data entry forms, Smart View grids, and reports based on assigned Cell-Level Security (`Valid Intersections`). |
| **Viewer** | Read-only access to dashboards and reports. Cannot modify or submit data. |

---

## 3. Environment Cloning & Snapshot Management <a name="environment-cloning"></a>

Administrators must perform regular environment cloning between Production and Dev/Test using **Lifecycle Management (`LCM`)**.

### Automated Environment Cloning (`Application -> Clone Environment`)
Instead of downloading a 15GB zip file to your laptop and re-uploading, administrators use **Direct Cloud-to-Cloud Cloning**:
- Enter target URL, target username (`Service Administrator`), and encrypted password.
- Select `Users and Predefined Roles` (`Optional`) and `Data and Artifacts`.
- EPM Cloud creates an encrypted background stream, wiping the target pod and replacing it with the source environment in 30-45 minutes.

---

## 4. Daily Maintenance & Patching Window Setup <a name="daily-maintenance"></a>

- **Maintenance Window:** Set under `Tools -> Daily Maintenance`. Must be configured for a 1-hour window during off-peak hours (`e.g., 2:00 AM UTC`).
- **Snapshot Retention:** Configure **Number of Daily Maintenance Backups** to `3` (maximum allowed on EPM Cloud storage) so you can roll back up to 3 days of unexpected changes.

---

## 5. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`00_Foundation/01_EPM_Foundations.md`** — Tenant navigation and initial pod setup.
- **`12_Security/01_Security_Complete_Guide.md`** — IDCS security groups, application roles, and data access filters.
- **`16_Administration/01_Administration_Complete_Guide.md`** — LCM migration, cloning, and snapshot maintenance.

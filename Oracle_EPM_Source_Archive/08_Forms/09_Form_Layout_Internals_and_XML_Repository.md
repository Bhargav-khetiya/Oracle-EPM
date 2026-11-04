# 09 — Form artifact lifecycle and technical boundaries

## Core idea

Treat Planning forms as Cloud artifacts managed through supported Oracle interfaces and migration procedures. Do not edit presumed database tables or undocumented XML structures.

## What the source notes claim

The earlier version of this document described specific HSP_FORM_* relational tables, internal IDs, XML element structures, query compilation, physical database details, and a script for mass-changing form artifacts. This review did not find an official Oracle source establishing those details as a supported Cloud interface. They remain unverified and are retained in the dated original backup for traceability; do not use them to diagnose or modify a live environment.

Oracle Cloud is operated as a service. The absence of a public source in this review does not prove that a detail is false; it means it is not suitable as a verified instruction here.

## Supported change and migration approach

Use the current Oracle-supported application interface, artifact export/import, snapshot, clone, or migration process appropriate to the task. Confirm that the selected procedure supports the form artifact and dependencies you need. A form may rely on dimensions, member selections, rules, data maps, security, folders, and variables; verify each dependency in the target environment.

Recommended control sequence:
1. Identify the exact form and dependent artifacts.
2. Export or snapshot using a documented Oracle workflow.
3. Preserve a pre-change restore point and record environment/release.
4. Apply a controlled change in a nonproduction environment.
5. Import or deploy with the documented tool and inspect the job result.
6. Open the form as an administrator and representative user.
7. Validate layout, member choices, security, rules, suppression, and data.
8. Promote through the project’s approved release path and retain evidence.

Do not execute an old bulk-edit script merely because it is stored in the docs library. First establish that the inputs and interface are supported, make a backup, test on a disposable artifact, and obtain a successful comparison and rollback procedure.

## Review questions for an artifact change

- Is the proposed change available in the supported form designer or import workflow—
- Which dependencies are included and which must be moved separately—
- Does the import report warnings or errors—
- Does the form work in its intended web and Smart View clients—
- Can the original definition be restored using a tested Oracle-supported method—
- Who approved the production change—

## Recall check

1. Are internal table names and XML examples verified Cloud interfaces— Not by this review.
2. What is the safe migration path— Use the current Oracle-documented artifact and environment migration process.
3. What must be checked after import— Job outcome, dependencies, permissions, layout, rules, and representative user behavior.

**Teach-back:** Explain why an undocumented XML edit may seem to work but still be unsafe to use as a repeatable Cloud deployment method.

## Oracle references

- [Clone and migration overview](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/epmss/clone_migration_overview.html)
- [Import artifacts from a snapshot](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/epmss/lcm_import_artifact.html)
- [Editing Planning forms](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/editing_forms.html)
- [Oracle EPM Cloud lifecycle and artifact documentation](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/epmss/)

Checked 2026-10-30. Confirm current supported procedures and artifact dependencies for the target service.

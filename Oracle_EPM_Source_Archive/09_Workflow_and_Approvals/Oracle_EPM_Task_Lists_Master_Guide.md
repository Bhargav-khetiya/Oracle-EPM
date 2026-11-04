# Planning Task Lists and Task Manager: Learning Guide

## Core idea
Task Lists guide users through Planning work; Task Manager provides a broader system for defining, scheduling, assigning, tracking, and monitoring repeatable tasks.

**Plain language:** both help coordinate work, but their objects and lifecycle differ. A classic Task List is a guided checklist. Task Manager has task types, templates, tasks, schedules, and operational views.

## Choose the task flow deliberately

| Option | What it is | Key decision |
|---|---|---|
| Task List | Classic Planning feature listing tasks, instructions, and end dates | Keep it if the application is designed to use legacy lists |
| EPM Task Manager | Centralized monitoring and repeatable task orchestration | Use its templates/schedules and applicable task types |

Oracle says EPM Task Manager is the default task flow for new Planning applications. Existing applications can switch from Task Lists to Task Manager, but this is consequential: existing lists/tasks cannot be migrated; they must be deleted before enabling Task Manager; after enabling, switching back is not supported. Back up the application before deleting task lists and tasks. See [Setting Up the Calendar and Task Flow Type](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/setting_up_the_calendar.html) and [Enabling Task Manager](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/switching_from_task_lists_to_task_manager.html).

> **Do not treat conversion as a routine upgrade.** Inventory, export/backup, redesign, approvals, and test before making this change in any environment.

## Classic Task Lists

Oracle describes Task Lists as tasks, instructions, and end dates that guide users through a planning process. Service Administrators and Power Users create/manage them. Tasks can invoke supported actions such as opening a form, launching a rule, opening a URL, or starting an approval process; the available types depend on product and release. See [Administering Task Lists](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/administering_tasks.html).

A typical design sequence:

1. Identify the user goal and the order of work.
2. Create a list with concise instructions.
3. Add tasks that point to the relevant Planning artifact or action.
4. Set dates, alerts, and dependencies only where required by the design.
5. Assign list access and verify users can also access the underlying forms/rules/data.
6. Test completion, overdue behavior, and reuse/reset procedures.

Task-list access and the permissions on linked forms/rules are separate. Do not assume that visibility of a task grants permission to use its target artifact.

## Task Manager building blocks

Oracle's Task Manager guide includes:

- **Task Types:** reusable definitions of common task details, questions, or instructions.
- **Task Templates:** repeatable task structures.
- **Tasks:** individual activities, with properties, assignees/workflow, instructions, and possibly predecessors.
- **Schedules:** dated execution structures created from or managed using tasks/templates.
- **Integrations and views:** supported integration tasks, monitoring, filters, and operational dashboards.

Use the current [Administering Tasks with Task Manager](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/cm_administering_tasks_with_task_manager.html) guide for supported configuration and release-specific detail. Do not rely on copied chart settings or task-type lists without checking they match your service.

## Illustrative example

For a hypothetical monthly forecast, a template could organize “prepare inputs,” “review assumptions,” and “submit forecast.” A schedule would place dated instances for a chosen cycle, and task ownership would identify who performs each step. This is **illustrative**; it is not this project's actual workflow.

For each task, define: trigger/input, owner, due date, expected evidence, predecessor, success criteria, escalation path, and recovery action.

## Validate the design

- Confirm the application's selected task flow type.
- Test with a representative Service Administrator, Power User, User, and Viewer where applicable.
- Confirm list/schedule visibility and permissions on linked artifacts.
- Verify dependencies and dates with realistic calendar boundaries.
- Confirm notifications, completion status, and reporting in the target interface.
- For a task-flow conversion, prove backups are restorable and redesign/rebuild has been tested before deleting source lists.

## Troubleshooting

| Symptom | Check |
|---|---|
| User sees a task but cannot complete it | Task assignment/access and permission to the linked form, rule, or approval unit |
| List exists but Task Manager is unavailable | Current task-flow type, residual Task List artifacts, role, and whether re-login is required after enablement |
| Users expect old tasks to appear after switching | Oracle does not migrate existing Task Lists/tasks; redesign them in Task Manager |
| Dates or alerts behave unexpectedly | Task configuration, calendar/time zone, alert date, and current Oracle guidance |
| Dashboard/chart differs from an example | Example settings may be release- or configuration-specific; verify attributes, view, and aggregation in current documentation |

## Remember and explain

**Recall:** How does a classic Task List differ from Task Manager— What is irreversible about enabling Task Manager— Which objects should be checked when a task cannot be completed—

**Answer key:** Task Lists are classic guided lists; Task Manager provides centralized repeatable task monitoring and scheduling. Existing Task Lists/tasks must be deleted before enabling, cannot be migrated, and the switch back is unavailable. Check task flow, assignment/access, target artifact permissions, and workflow state.

**Teach-back:** Explain how you would choose a task flow for a new application and how you would safely assess a legacy conversion.

## Oracle sources checked 2026-10-30

- [Administering Task Lists](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/administering_tasks.html)
- [Setting Up the Calendar and Task Flow Type](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/setting_up_the_calendar.html)
- [Enabling Task Manager from within Planning](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/switching_from_task_lists_to_task_manager.html)
- [Administering Tasks with Task Manager](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/cm_administering_tasks_with_task_manager.html)

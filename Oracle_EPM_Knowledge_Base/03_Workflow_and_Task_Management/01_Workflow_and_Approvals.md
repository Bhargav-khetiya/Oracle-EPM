# Workflow: Task Lists, Task Manager, and Approvals

> **Prerequisites:** [Forms and Navigation](../02_User_Interface_and_Navigation/01_Forms_and_Navigation.md)  
> **Sources merged:** ChatGPT 03_Workflow_and_Task_Management (3 files), Claude workflow content, Gemini equivalents  
> **Evidence Labels:** `[Oracle Documented]` · `[Illustrative]` · `[Recommendation]`

---

## Task Lists vs Task Manager

Oracle provides two frameworks for coordinating planning work:

| Feature | Classic Task Lists | EPM Task Manager |
|:---|:---|:---|
| **Purpose** | Guided checklist | Centralized repeatable task orchestration |
| **Objects** | Tasks with instructions, dates, linked artifacts | Task types, templates, tasks, schedules, views |
| **Best for** | Simple sequential workflows | Complex recurring processes with monitoring |
| **Default for** | Legacy applications | New Planning applications |
| **Migration** | Cannot migrate lists to Task Manager | Must delete lists before enabling |

> [!CAUTION]
> Switching from Task Lists to Task Manager is **irreversible**. Existing Task Lists/tasks must be deleted before enabling Task Manager. Back up the application first and redesign tasks in Task Manager.

`[Oracle Documented]`

---

## Classic Task Lists

Task Lists guide users through a planning process with ordered tasks, instructions, and end dates.

### Typical Design

1. Identify user goal and order of work
2. Create a list with concise instructions
3. Add tasks pointing to relevant artifacts (forms, rules, URLs, approvals)
4. Set dates, alerts, and dependencies where needed
5. Assign list access and verify users can also access underlying forms/rules
6. Test completion, overdue behavior, and reuse/reset procedures

### Task Types (Attachable Actions)

| Type | Action |
|:---|:---|
| **Open Form** | Navigates user to a specific data entry form |
| **Launch Business Rule** | Executes a calculation rule |
| **Open URL** | Opens an external link or Oracle Cloud page |
| **Approval Process** | Starts or continues an approval workflow |

> [!NOTE]
> Task-list access and permissions on linked forms/rules are **separate**. Visibility of a task does not automatically grant permission to use its target artifact.

`[Oracle Documented]`

---

## Approval Workflows

The approval system enables formal budget review cycles using **Planning Unit Hierarchies (PUH)**.

### Approval Flow

```
[Planner: jsmith]
  │
  ▼ (completes data entry in web form)
[PROMOTE]
  │  1. Planning checks validation rules
  │  2. Updates Process State to "Submitted"
  │  3. Transfers ownership to reviewer (mchen)
  │  4. Cell-level security flips planner to READ-ONLY
  ▼
[Reviewer: mchen]
  │
  ├──[REJECT]──► Returns to jsmith (write access restored)
  │
  └──[APPROVE]──► Final Sign-off (locked permanently)
```

### Key Approval Concepts

| Concept | Description |
|:---|:---|
| **Planning Unit** | An entity or budget slice that flows through the approval process |
| **Promote** | Move the budget forward to the next reviewer |
| **Approve / Sign Off** | Mark as final — locks data |
| **Reject** | Send back to the previous owner for revision |
| **Delegate** | Transfer ownership to another reviewer |
| **Submission Group** | Partition an entity into independently promotable sections |

### Version and Scenario Interaction

- Only versions with **Enabled for Approvals** checked participate in PUH
- Approval workflows bind to specific Scenario/Version/Entity intersections
- When promoted, write permissions dynamically transfer and the promoter's grid becomes read-only

`[Oracle Documented]`

---

## EPM Task Manager Building Blocks

| Object | Purpose |
|:---|:---|
| **Task Types** | Reusable definitions of common task details, questions, instructions |
| **Task Templates** | Repeatable task structures that can be instantiated |
| **Tasks** | Individual activities with properties, assignees, predecessors |
| **Schedules** | Dated execution structures created from templates |
| **Integration Tasks** | Tasks that invoke system operations (data loads, rules) |

### Illustrative Monthly Forecast Template

```
Template: Monthly Forecast Close
  Task 1: "Prepare Inputs"     → Owner: Finance Analyst → Day 3
  Task 2: "Review Assumptions" → Owner: Finance Manager → Day 5 (predecessor: Task 1)
  Task 3: "Submit Forecast"    → Owner: Finance Director → Day 7 (predecessor: Task 2)
```

`[Illustrative]`

---

## Troubleshooting

| Symptom | Check |
|:---|:---|
| User sees task but cannot complete it | Task assignment AND permission to the linked form/rule/approval unit |
| Task Manager not available | Task flow type setting; residual Task List artifacts; re-login after enablement |
| Old tasks missing after conversion | Oracle does not migrate Task Lists → Task Manager; redesign required |
| Dates/alerts behaving unexpectedly | Task configuration, calendar/time zone, alert date settings |
| Approval button grayed out | User doesn't have the budget unit in their ownership; check PUH assignment |

---

## Quick Recall

1. **What is irreversible about enabling Task Manager?**
   → Existing Task Lists/tasks must be deleted before enabling, cannot be migrated, and switching back is unavailable.

2. **What happens to data access when a planner promotes their budget?**
   → Write access transfers to the reviewer. The planner's grid becomes read-only (cell-level security enforced by PUH).

3. **Can a task list grant permission to a form?**
   → No. Task list access and form permissions are separate. Visibility of a task doesn't grant access to its target artifact.


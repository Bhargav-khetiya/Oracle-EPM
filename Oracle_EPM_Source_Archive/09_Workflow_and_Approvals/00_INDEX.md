# Workflow, Task Management, and Planning Approvals

This folder covers two related but distinct ways to coordinate Planning work: Task Lists/Task Manager for activity tracking, and approval units for routing planning data through review.

## Read in this order

1. [Task Lists and Task Manager](Oracle_EPM_Task_Lists_Master_Guide.md) — understand the two task-flow options and the non-reversible conversion considerations.
2. [Planning approvals](Oracle_EPM_Approval_Flow_Master_Guide.md) — learn approval units, ownership, templates, actions, and validation.

## Mental model

~~~mermaid
flowchart LR
 T[Task coordination] -->|points user to work| A[Form, rule, report, or process]
 P[Approval unit] -->|routes plan data| O[Owner/reviewer action]
 A --> R[Result and evidence]
 O --> R
~~~

Tasks coordinate activities; approvals route a defined unit of planning data. One may link a person to an approval-related task, but the mechanisms do not replace each other.

## Terms and review cautions

- Use **approval unit** as the current term; older notes may say Planning Unit.
- Approval actions and statuses depend on the hierarchy template, current state, and permissions; they are not one universal linear sequence.
- Owner changes can affect who may edit, subject to data write permission.
- Task Lists are the classic task-flow feature. EPM Task Manager is a separate task flow; conversion is consequential and existing lists/tasks are not migrated.
- A visible task does not guarantee permission to use its linked artifact or data.
- Treat all examples as illustrative unless a project artifact confirms them.

## Oracle references

- [Administering Task Lists](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/administering_tasks.html)
- [Administering Tasks with Task Manager](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/cm_administering_tasks_with_task_manager.html)
- [Approval Unit Actions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/approval_unit_actions.html)
- [Approval Unit States](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/approval_unit_states.html)
- [Approvals Process](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/approvals_process.html)

Related study topic: [approval dimensions and metrics](../Dimension_Properties/06_System_Approval_Dimensions_and_17_Metric_Types.md). Check its claims against current Oracle guidance before relying on them. See [review coverage](../_review/coverage.csv).

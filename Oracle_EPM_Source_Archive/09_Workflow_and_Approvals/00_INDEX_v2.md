# Volume 12C: Workflow, Task Lists, and Approval Unit Hierarchies

## 1. Executive Architectural Overview

Workflow orchestration in Oracle EPM Cloud guarantees that enterprise budgets and forecasts follow formal review, submission, approval, and locking cycles across distributed departments and legal entities.

```
+---------------------------------------------------------------------------------------------------+
|                                  WORKFLOW & APPROVALS TOPOLOGY                                    |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [APPROVAL UNIT HIERARCHY (AUH)]                                                                  |
|  - Dimension combining Entity + Scenario + Version                                                |
|  - Assigns Owner and Reviewer paths to specific organizational nodes                              |
|                                                                                                   |
|  [PROMOTIONAL WORKFLOW STATES]                                                                    |
|  - Not Started ===> Under Review ===> Approved ===> Frozen / Locked                              |
|  - Restricts data write access at the database level when locked                                  |
|                                                                                                   |
|  [TASK LISTS & TASK MANAGER]                                                                      |
|  - Chronological checklists guiding planners through forms, rules, and reports                    |
|  - Milestone deadlines, completion dependencies, and automated email reminders                    |
|                                                                                                   |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Directory Contents and Chapter Navigation

| Document | Primary Focus | Key Architectural Concepts |
| :--- | :--- | :--- |
| [Oracle_EPM_Approval_Flow_Master_Guide.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/03_Workflow_and_Task_Management/Oracle_EPM_Approval_Flow_Master_Guide.md) | **Approval Management** | Approval Unit Hierarchies, Promotional Paths, Sign-off validation rules, and database cell write lockouts. |
| [Oracle_EPM_Task_Lists_Master_Guide.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/03_Workflow_and_Task_Management/Oracle_EPM_Task_Lists_Master_Guide.md) | **Task Lists & Manager** | Sequential task checklists, artifact linking, dependency precedence, and execution tracking. |

---

## 3. Related Cross-References
- **Approval Dimensions & Metrics**: See [Dimension_Properties/06_System_Approval_Dimensions_and_17_Metric_Types.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Dimension_Properties/06_System_Approval_Dimensions_and_17_Metric_Types.md)


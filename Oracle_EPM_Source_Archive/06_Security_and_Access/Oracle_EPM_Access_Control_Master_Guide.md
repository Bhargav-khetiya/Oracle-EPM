# Oracle EPM Planning Security: Beginner-to-Consultant Guide

## Core idea
Oracle EPM security is layered: an application role grants access to the service, while application permissions control which data and artifacts a person can use.

**Plain language:** getting into the building is different from getting a key to a particular room or file. A user may be able to open Planning but still lack permission to a form, rule, or dimension member.

> **Scope:** This guide uses Oracle Planning/Planning Modules terminology. Other EPM services can expose different behavior. Verify the exact service and release.

## Security layers

| Layer | Question it answers | Examples |
|---|---|---|
| Identity and sign-in | Can this identity authenticate to the environment— | SSO and identity-domain provisioning |
| Application role | Can the identity access the business process, and with what broad capabilities— | Service Administrator, Power User, User, Viewer |
| Application permissions | Which application elements can the identity see or use— | Member, form, rule, dashboard permissions |
| Workflow/process access | Can the identity act in a configured workflow— | Approval ownership/review actions; depends on setup |

Oracle describes global roles and application permissions separately. Do not treat “OCI IAM roles,” artifact permissions, and dimensional security as one interchangeable layer. See [About User and Role Management](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/about_user_and_role_management.html) and [Understanding Application Roles](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/cgsad/4_managing_epm_cloud_users_roles_predefined_roles.html).

## Predefined Planning roles

| Role | Beginner summary | Professional caution |
|---|---|---|
| Service Administrator | Administers the Planning business process, including application security. | Broad privilege; assign only to people who need it. |
| Power User | Performs expanded business-user and administration tasks, depending on Planning configuration. | Does not mean unrestricted access to every data member or artifact. |
| User | Enters/submits plans and uses permitted application features. | Access to forms, rules, and data still depends on permissions. |
| Viewer | Views/analyzes permitted data and artifacts. | Viewers cannot modify application data; rule launching has limitations depending on prompts and access. |

Roles are not a substitute for least-privilege design. Capabilities vary by service and task; use Oracle’s [role guide](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/cgsad/4_managing_epm_cloud_users_roles_predefined_roles.html).

## Groups and permissions

Oracle supports permissions for groups and individual users. Group-based assignments are a maintainable practice when people share access needs; direct user assignments are supported, so do not describe them as prohibited. Oracle recommends groups to reduce repeated administration in [Access Permissions Design](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/access_design_considerations.html).

Permission labels can include **Read**, **Write**, **None**, and **Display**; rule permissions also use **Launch** and **No Launch**. The available choices depend on the secured element. See [Types of Access Permissions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/types_of_access_permissions.html).

Oracle documents precedence for Planning permissions: role-level security, specific user assignments, group assignments, then parent-level assignments. Between conflicting groups, the least restrictive permission generally takes precedence, with a documented exception for None; user assignments take precedence over group assignments. Do not simplify this to “the most restrictive always wins.” Check the current permission page before designing an exception.

## Data access and artifact access

- **Member/data permission** affects access to dimension members and data.
- **Artifact permission** affects application objects such as forms, rules, dashboards, and reports.
- **Valid intersections** filter allowed member combinations for relevant data-entry contexts; they are not an access grant.
- **Cell-level security** has its own configuration and must be reviewed separately from member permissions and valid intersections.

A person’s effective result can depend on the application role, artifact permissions, member permissions, workflow state, and the specific interface. Test with representative users rather than inferring access from one setting.

## Illustrative example

A regional planner is assigned the User role and is placed in a group that has access to the regional Entity members and a planning form. This example is **illustrative**, not a statement about this project. Validate the full path: sign-in → assigned role → form permission → member/data permission → valid intersection and workflow rules → save/submit outcome.

## Implementation and review checklist

1. Confirm the service, environment, user identity, and assigned application role.
2. Identify the artifact and data members required for the user’s task.
3. Review direct and inherited permissions, group membership, and rule launch rights.
4. Define group-based access where it improves maintainability; document justified direct assignments.
5. Test permitted and denied cases with representative users in a non-production environment.
6. Record expected result, actual result, test date, role/group, and affected members/artifacts.
7. Recheck security after migration or configuration changes; do not assume a migration artifact includes every security layer.

## Troubleshooting

| Symptom | Check |
|---|---|
| User can sign in but cannot open a form | Application role, form artifact permission, group membership, and application status |
| Form opens but data is missing or read-only | Member/data permissions, form design, valid intersections, cell-level security, and workflow state |
| User can view but cannot launch a rule | Rule permission, role, launch permission, and runtime-prompt type |
| Two users in similar groups get different results | Direct user assignments, inherited parent permissions, group overlap, and role differences |

Do not “fix” a security issue by granting broad administrator access. Identify the missing permission layer and retest.

## Remember and explain

**Recall:** What does the application role control— What controls access to a particular form or member— Can permissions be assigned to individuals— Why can a valid intersection not replace security—

**Answer key:** The role grants broad business-process capabilities; application permissions further scope access. Oracle supports individual and group assignments, while groups are often easier to maintain. A valid intersection filters dimensional combinations, not identity authorization.

**Teach-back:** Explain the path from sign-in to a user saving one permitted planning cell, naming the evidence you would test at every layer.

## Sources checked 2026-10-30

- [About User and Role Management](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/about_user_and_role_management.html)
- [Types of Access Permissions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/types_of_access_permissions.html)
- [Access Permissions Design](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/access_design_considerations.html)
- [Understanding Application Roles](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/cgsad/4_managing_epm_cloud_users_roles_predefined_roles.html)

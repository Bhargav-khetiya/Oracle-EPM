# Oracle EPM Planning Security — Beginner-to-Professional Guide

> **Folder:** 01_Security_and_Access | **Audience:** Beginner → Architect
>
> **Provenance:** Merged from ChatGPT `Oracle_EPM_Access_Control_Master_Guide.md`; Claude `12_Security/*.md`; Gemini `01_Security_and_Access/Oracle_EPM_Access_Control_Master_Guide.md`

---

## Core Idea

Oracle EPM security is **layered**: an application role grants access to the service, while application permissions control which data and artifacts a person can use.

**Plain language:** Getting into the building is different from getting a key to a particular room. A user may be able to open Planning but still lack permission to a specific form, rule, or dimension member.

---

## Security Layers

| Layer | Question It Answers | Examples |
|---|---|---|
| **Identity and sign-in** | Can this identity authenticate to the environment? | SSO, IDCS/IAM provisioning |
| **Application role** | Can the identity access the business process, and with what broad capabilities? | Service Administrator, Power User, User, Viewer |
| **Artifact permissions** | Which application elements can the identity see or use? | Form, rule, dashboard, report permissions |
| **Member/data permissions** | Which data can the identity see or edit? | Member-level Read, Write, None |
| **Valid intersections** | Which dimensional combinations are offered? | Filtering invalid combos (not an access grant) |
| **Workflow/process access** | Can the identity act in a configured workflow? | Approval ownership, review actions |

> Oracle describes global roles and application permissions separately. Do not treat OCI IAM roles, artifact permissions, and dimensional security as one interchangeable layer. See [About User and Role Management](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/about_user_and_role_management.html).

---

## Predefined Planning Roles

| Role | What They Can Do | Cautions |
|---|---|---|
| **Service Administrator** | Full administration of the Planning business process, including security, metadata, rules, and application settings | Broad privilege — assign only to people who genuinely need it |
| **Power User** | Expanded business-user tasks and some admin capabilities depending on configuration | Does NOT mean unrestricted access to every data member or artifact |
| **User** | Enter/submit plans, use permitted application features | Access to forms, rules, and data depends on specific permissions |
| **Viewer** | View and analyze permitted data and artifacts | Cannot modify data; rule launching has limitations |

> **Oracle documented:** Roles are not a substitute for least-privilege design. Capabilities vary by service and task. See Oracle's [role guide](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/cgsad/4_managing_epm_cloud_users_roles_predefined_roles.html).

---

## How Roles Are Assigned

```
Step 1: User identity created in IDCS or OCI IAM Identity Domains
Step 2: Administrator assigns application role (Service Admin / Power User / User / Viewer)
Step 3: Administrator assigns user to Groups (recommended for maintainability)
Step 4: Permissions assigned to Groups (or individual users where justified)
Step 5: User logs in → system evaluates role + permissions + valid intersections
```

### Groups vs Individual Assignments

Oracle supports permissions for **both groups and individual users**. Group-based assignments are recommended when people share access needs. Direct user assignments are supported — do not describe them as prohibited. Oracle recommends groups to reduce repeated administration.

---

## Permission Types

| Permission | Applies To | Effect |
|---|---|---|
| **Read** | Members, forms, rules | Can view but not modify |
| **Write** | Members, forms | Can view AND modify data |
| **None** | Members, forms, rules | Cannot see the secured element |
| **Launch** | Business rules | Can execute the rule |
| **No Launch** | Business rules | Cannot execute the rule |

### Permission Precedence

Oracle documents the following precedence for Planning permissions:

1. **Role-level security** (broadest)
2. **Specific user assignments** (override group assignments)
3. **Group assignments**
4. **Parent-level assignments** (inherited)

> **Important:** Between conflicting groups, the **least restrictive** permission generally takes precedence, with a documented exception for `None`. User assignments take precedence over group assignments. Do NOT simplify this to "the most restrictive always wins."

---

## Data Access vs Artifact Access

| Type | What It Controls | Examples |
|---|---|---|
| **Member/data permission** | Access to dimension members and data values | "User can see Revenue but not EBITDA" |
| **Artifact permission** | Access to application objects | "User can open Form_A but not Form_B" |
| **Valid intersections** | Filter allowed member combinations | "Product X not valid for Manufacturing entities" — NOT an access grant |
| **Cell-level security** | Granular cell-by-cell control | Separate from member permissions |

> A person's effective access depends on the application role, artifact permissions, member permissions, workflow state, AND the specific interface. **Test with representative users** rather than inferring access from one setting.

---

## Implementation Checklist

1. ☐ Confirm the service, environment, user identity, and assigned application role
2. ☐ Identify the artifacts and data members required for the user's task
3. ☐ Review direct and inherited permissions, group membership, and rule launch rights
4. ☐ Define group-based access where it improves maintainability; document justified direct assignments
5. ☐ Test permitted AND denied cases with representative users in a non-production environment
6. ☐ Record expected result, actual result, test date, role/group, and affected members/artifacts
7. ☐ Recheck security after migration or configuration changes

---

## Troubleshooting

| Symptom | What to Check |
|---|---|
| User can sign in but cannot open a form | Application role, form artifact permission, group membership, application status |
| Form opens but data is missing or read-only | Member/data permissions, form design, valid intersections, cell-level security, workflow state |
| User can view but cannot launch a rule | Rule permission, role, launch permission, runtime-prompt type |
| Two users in similar groups get different results | Direct user assignments, inherited parent permissions, group overlap, role differences |
| Security issue after migration | Migration artifacts may not include every security layer — revalidate |

> **Never "fix" a security issue by granting broad administrator access.** Identify the missing permission layer and retest.

---

## 🧠 Self-Check Questions

1. **What are the four predefined Planning roles?**
2. **What is the difference between artifact permissions and member/data permissions?**
3. **Can permissions be assigned to individual users? Is it recommended?**
4. **Between conflicting groups, which permission wins?**
5. **Why can't valid intersections replace security?**

> **Teach-back prompt:** Explain the complete path from a user signing in to successfully saving one permitted planning cell. Name the evidence you would test at every security layer.

---

## Oracle Sources

- [About User and Role Management](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/about_user_and_role_management.html)
- [Understanding Application Roles](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/cgsad/4_managing_epm_cloud_users_roles_predefined_roles.html)
- [Access Permissions Design](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/access_design_considerations.html)
- [Types of Access Permissions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/types_of_access_permissions.html)


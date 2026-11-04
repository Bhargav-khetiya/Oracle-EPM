# Volume 12A: Security Governance and Access Control

## 1. Executive Architectural Overview

Security in Oracle Enterprise Performance Management (EPM) Cloud operates on a defense-in-depth model that combines cloud identity management (OCI IAM / IDCS), role-based access control (RBAC), dimension-level member security, cell-level security rules, and dimensional valid intersection definitions.

```
+---------------------------------------------------------------------------------------------------+
|                                  ORACLE EPM SECURITY LAYER STACK                                  |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [LAYER 1: IDENTITY & AUTHENTICATION]                                                             |
|  - Oracle Cloud Infrastructure Identity and Access Management (OCI IAM) / IDCS                   |
|  - Single Sign-On (SSO), Multi-Factor Authentication (MFA), SAML 2.0 / OAuth 2.0 Token Bearers    |
|                                                                                                   |
|  [LAYER 2: PREDEFINED FUNCTIONAL ROLES]                                                           |
|  - Service Administrator, Power User, User, Viewer                                                |
|                                                                                                   |
|  [LAYER 3: DIMENSION MEMBER SECURITY (HSP_ACCESS)]                                                |
|  - Read, Write, None assigned to User/Group on Dimension Hierarchies (Entity, Account, Scenario)  |
|                                                                                                   |
|  [LAYER 4: CELL-LEVEL SECURITY (CLS)]                                                             |
|  - Multi-dimensional matrix restrictions (e.g., Read-Only for Dept_100 on Budget)                  |
|                                                                                                   |
|  [LAYER 5: VALID INTERSECTIONS (VI)]                                                              |
|  - Prevents data entry and block creation at un-permitted dimensional coordinate intersections     |
|                                                                                                   |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Directory Contents and Chapter Navigation

| Document | Primary Focus | Key Architectural Concepts |
| :--- | :--- | :--- |
| [Oracle_EPM_Access_Control_Master_Guide.md](01_Security_and_Access/Oracle_EPM_Access_Control_Master_Guide.md) | **Access Control & RBAC** | Predefined functional roles (Service Admin vs Power User), native groups, IDCS synchronization, artifact permissions. |
| [Oracle_EPM_Valid_Intersections_Master_Guide.md](01_Security_and_Access/Oracle_EPM_Valid_Intersections_Master_Guide.md) | **Valid Intersections (VI)** | Restricting coordinate combinations in Web Forms, Smart View, and calculations. Preventing empty block creation. |

---

## 3. Related Cross-References
- **Cell-Level Security in Forms**: See [Form_Properties/07_Cell_Level_Security_and_Valid_Intersections_on_Forms.md](Form_Properties/07_Cell_Level_Security_and_Valid_Intersections_on_Forms.md)
- **Calculation Manager Security Roles**: See [Calc Manager/Calculations_and_Allocations/07_Administration_Troubleshooting_and_Interview_Bible/02_Security_Roles_and_Action_Menu_Form_Attachment.md](Calc%20Manager/Calculations_and_Allocations/07_Administration_Troubleshooting_and_Interview_Bible/02_Security_Roles_and_Action_Menu_Form_Attachment.md)


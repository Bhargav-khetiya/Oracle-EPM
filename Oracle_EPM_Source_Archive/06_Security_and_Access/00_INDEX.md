# Security and Access

## Start with the layers

Oracle Planning security has separate questions: can the user authenticate, which application role is assigned, which application elements can the user access, and what process actions are available? A visible form does not by itself prove the user can access every data cell.

~~~mermaid
flowchart TD
 I[Identity and sign-in] --> R[Planning application role]
 R --> P[Artifact and member permissions]
 P --> V[Valid intersection and workflow context]
 V --> O[Observed action/result]
~~~

Use this as a learning map, not an exhaustive Oracle security architecture.

## Guides in this folder

| Guide | Focus |
|---|---|
| [Access control](Oracle_EPM_Access_Control_Master_Guide.md) | Application roles, groups, artifact/member permissions, precedence, and testing |
| [Valid intersections](Oracle_EPM_Valid_Intersections_Master_Guide.md) | Anchor/nonanchor dimensions, valid/invalid combinations, overlap behavior, and form validation |

## Read next

- [Form behavior and cell-level security](../Form_Properties/07_Cell_Level_Security_and_Valid_Intersections_on_Forms.md) — detailed form context; not yet reviewed.
- [Calculation Manager security topic](../Calc%20Manager/Calculations_and_Allocations/07_Administration_Troubleshooting_and_Interview_Bible/02_Security_Roles_and_Action_Menu_Form_Attachment.md) — verify against Oracle source before relying on it.

## Important distinctions

- Application role is not the same as a form permission.
- Artifact access is not the same as data-member access.
- Valid intersections filter dimensional combinations; they do not authorize a person.
- Cell-level security is distinct and must be assessed using the feature's own documentation.
- Group-based grants are a maintainable practice; Oracle also supports direct assignments. Follow the actual access design.

## Oracle references

- [About User and Role Management](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/about_user_and_role_management.html)
- [Types of Access Permissions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/types_of_access_permissions.html)
- [Creating Valid Intersections](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/creating_valid_intersections.html)
- [Valid Intersection Examples](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/valid_intersection_examples.html)

Current coverage and source status are in the [review tracker](../_review/coverage.csv) and [Oracle source register](../_review/oracle_sources.md).

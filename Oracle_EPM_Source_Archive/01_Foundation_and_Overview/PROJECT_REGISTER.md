# Project Evidence, Assumptions, and Open Questions

## Evidence boundary
Inspected material is a learning library with collections for security, UI, workflow, administration, lifecycle, calculations, integration/data maps, dimensions, Planning modules, EPM Automate, Essbase concepts, forms, Smart Lists, Smart View, and review. This establishes documentation coverage only. Reviewed entry points did not identify an approved architecture, environment inventory, requirements, or client configuration; no solution decision is asserted.

| ID | Type | Statement | Status |
|---|---|---|---|
| E-01 | Observed | Root contains 18 principal subject folders plus README and master index. | Observed |
| E-02 | Observed | Reference materials include Oracle extracts, including a large Planning administration manual. | Partly reviewed |
| A-01 | Boundary | Folder names do not prove a feature is configured for a client. | Apply throughout |
| A-02 | Boundary | Examples are not client facts unless linked to approved project evidence. | Apply throughout |

## Questions for an implementation review
1. Which EPM services are licensed and actually used?
2. Which environments, releases, cubes, modules, dimensions, integrations, and external systems are in scope?
3. Which approved artifacts define architecture, requirements, security, data flows, and ownership?
4. How are integrations reconciled, and who owns failure/restart decisions?
5. What change-control, snapshot, migration, rollback, and support procedures are approved?
6. Which notes are project decisions, generic training, or historical/on-premises context?

Resolve these from approved designs, requirements, integration inventory, security matrix, environment evidence, runbooks, and the responsible project owner/admin.

## Decision log
Record decisions only when approved evidence supports them. Capture ID, date, owner, rationale, alternatives, impact, and source.

# Oracle EPM Cloud Learning and Working Index

This index navigates a study library. It does not describe a confirmed customer architecture. Start at [README](README.md), follow the [roadmap](LEARNING_ROADMAP.md), and read a topic index before its detail files.

## Evidence order

1. Current Oracle documentation for behavior and stated release.
2. Approved project artifacts for actual configuration, requirements, roles, integrations, and decisions.
3. Dated environment tests for observed behavior.
4. Labeled recommendations and illustrative examples.
5. Unverified claims, which stay open until checked.

## Learning sequence

~~~mermaid
flowchart TD
 A[Business purpose and vocabulary] --> B[Applications, cubes, dimensions, members]
 B --> C[Forms, Smart Lists, user experience]
 C --> D[Workflow, approvals, security]
 B --> E[Calculations and rules]
 B --> F[Data integration and data maps]
 C --> G[Validation and reconciliation]
 D --> G
 E --> G
 F --> G
 G --> H[Migration, operations, support]
 H --> I[Explain evidence, risks, tradeoffs]
~~~

Study progression only; not a confirmed solution diagram.

## Topic index

**Foundation:** [Security](01_Security_and_Access/00_INDEX.md) · [UI](02_User_Interface_and_Navigation/00_INDEX.md) · [Dimensions](Dimension_Properties/00_INDEX.md) · [Forms](Form_Properties/00_INDEX.md) · [Smart Lists](Smart_Lists/00_INDEX.md)

**Process and calculation:** [Workflow](03_Workflow_and_Task_Management/00_INDEX.md) · [Calculation Manager](Calc%20Manager/Calculations_and_Allocations/00_INDEX.md) · [Planning modules](EPBCS_Modules_and_Business_Processes/00_INDEX.md) · [Action menus](Action_Menus/00_INDEX.md)

**Data and automation:** [Data Integration](Data_Integration/00_INDEX.md) · [Data maps](Data_Maps_and_Exchange/00_INDEX.md) · [Smart View](Smart_View_and_Ad_Hoc/00_INDEX.md) · [EPM Automate](EPM_Automate/00_INDEX.md)

**Operations and review:** [Administration](04_System_Administration/00_INDEX.md) · [Lifecycle](05_Application_Creation_and_Lifecycle_Management/00_MASTER_INDEX.md) · [Essbase concepts](Essbase_Internal_Architecture/00_INDEX.md) · [Review bible](Techno_Functional_Consultant_Review_Bible/00_INDEX.md) · [References](Reference_Materials/00_INDEX.md)

## Reviewer lens

Trace **business need → source/target → dimensional mapping → transformation/calculation → security/workflow → user action → validation/reconciliation → migration/operations**. At each step ask for the input, owner, expected output, success evidence, safe retry behavior, and authoritative source. Record missing project answers in the [register](PROJECT_REGISTER.md).

## Cloud boundary

EPM Cloud exposes Essbase-based capabilities; this does not prove customers can inspect server files, database schemas, network topology, kernel routines, or physical storage internals. Treat these as historical/on-premises context or hypotheses unless Oracle documents them for the specific service. Function catalogs do not guarantee support in every context. Performance values need environment, release, method, and evidence.

See [glossary](GLOSSARY.md), [source register](_review/oracle_sources.md), [coverage tracker](_review/coverage.csv), and [checkpoint](_review/findings.md).

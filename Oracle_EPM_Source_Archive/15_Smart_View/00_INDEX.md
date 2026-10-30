# Oracle Smart View and Ad Hoc Analysis

This collection explains how Smart View connects to Cloud EPM, how to work with ad hoc grids and forms, and how to troubleshoot or automate common tasks. It is a learning library, not evidence of a configured customer connection or approved workbook.

## Reading path

1. [Connections and architecture](01_Smart_View_Architecture_and_Connection_Management.md)
2. [Ad hoc grid operations](02_Ad_Hoc_Analysis_Grid_Operations_and_Physics.md)
3. [Options and formatting](03_Smart_View_Options_Deep_Dive.md)
4. [Flex forms, supporting detail, comments, and attachments](04_Flex_Forms_and_Advanced_Worksheets.md)
5. [Worksheet functions and VBA](05_Formulas_Functions_and_VBA_Automation.md)
6. [Troubleshooting and recall questions](06_Troubleshooting_Performance_and_Interview_Guide.md)

## Safe mental model

Smart View is an Office client that connects to configured EPM data providers. The provider controls which operations are supported. A worksheet grid is a client view of selected dimensions and members; do not treat it as evidence of private server internals or physical database storage.

~~~mermaid
flowchart LR
 C[Configured connection] --> P[Provider and application]
 P --> G[Form or ad hoc grid]
 G --> U[Refresh, analyze, or edit]
 U --> S[Submit changed data when permitted]
~~~

## Review boundaries

- Shared and private connection URLs follow Oracle patterns; use the URL supplied by the administrator.
- Ad hoc zoom options depend on provider and Smart View Ad Hoc Behavior mode.
- Data suppression and replacement labels affect presentation; they are not security controls or proof that data was deleted.
- Smart View functions and VBA calls have provider and release requirements. Use the current Oracle User’s and Developer’s Guides.
- Excel version, add-ins, operating system, SSO, proxy, and network setup are environment-specific. No such configuration is confirmed for this project.

The source register is in [review/oracle_sources.md](../_review/oracle_sources.md); reviewed files and remaining work are tracked in [review/coverage.csv](../_review/coverage.csv).

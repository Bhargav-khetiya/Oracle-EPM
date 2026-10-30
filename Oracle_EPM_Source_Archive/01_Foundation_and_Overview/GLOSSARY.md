# Oracle EPM Learning Glossary

These are starting definitions. Meaning varies by service, application type, feature, and release. Verify with the linked topic and Oracle sources.

| Term | Working definition | Read next |
|---|---|---|
| Application | Configured EPM workspace containing artifacts and, depending on product, cubes or processes. | [Lifecycle](05_Application_Creation_and_Lifecycle_Management/00_MASTER_INDEX.md) |
| Approval unit | Planning data unit that may move through a configured approval process; states and permissions depend on setup. | [Workflow](03_Workflow_and_Task_Management/00_INDEX.md) |
| Artifact | Managed application object such as a form, rule, or report; types vary. | [Lifecycle](05_Application_Creation_and_Lifecycle_Management/00_MASTER_INDEX.md) |
| Calculation Manager | Oracle environment for designing and managing supported business rules and calculation artifacts. | [Rules](Calc%20Manager/Calculations_and_Allocations/00_INDEX.md) |
| Cell | Value at the intersection of dimensional members in a cube. | [Dimensions](Dimension_Properties/00_INDEX.md) |
| Cell-level security | Supported access restriction for individual data cells; differs from valid-intersection filtering. | [Security](01_Security_and_Access/00_INDEX.md) |
| Cube | Multidimensional structure for organizing/calculating business values; capabilities vary by type. | [Essbase](Essbase_Internal_Architecture/00_INDEX.md) |
| Data map | Configured mechanism for moving/mapping data between supported EPM sources and targets. | [Data maps](Data_Maps_and_Exchange/00_INDEX.md) |
| Dimension | Data category such as Account, Period, Scenario, Entity, or a business-specific category. | [Dimensions](Dimension_Properties/00_INDEX.md) |
| EPM Automate | Oracle command-line utility for supported repeatable EPM Cloud operations; check current command syntax. | [EPM Automate](EPM_Automate/00_INDEX.md) |
| Evaluation order | Configured precedence where data types/features require resolution; use is context dependent. | [Smart Lists](Smart_Lists/00_INDEX.md) |
| Essbase | Oracle multidimensional analytics technology used by EPM products; Cloud internals differ from on-premises files. | [Essbase](Essbase_Internal_Architecture/00_INDEX.md) |
| Form | User-facing grid/interface for viewing or entering planning data, subject to layout, access, and validation. | [Forms](Form_Properties/00_INDEX.md) |
| FreeForm | EPM Cloud application type with its own supported design and limits; do not assume Planning behavior. | [Oracle sources](_review/oracle_sources.md) |
| Groovy rule | Rule using Groovy in applicable Planning contexts; check supported APIs and restrictions. | [Calculation Manager](Calc%20Manager/Calculations_and_Allocations/00_INDEX.md) |
| Member | Item in a dimension hierarchy, such as an account or period. | [Dimensions](Dimension_Properties/00_INDEX.md) |
| Planning | Oracle EPM Cloud planning service; confirm Planning versus Planning Modules scope. | [Planning modules](EPBCS_Modules_and_Business_Processes/00_INDEX.md) |
| Smart List | Configured choices in supported data-entry contexts; verify storage/display behavior. | [Smart Lists](Smart_Lists/00_INDEX.md) |
| Smart View | Oracle Office interface to supported EPM data/artifacts; providers and operations vary. | [Smart View](Smart_View_and_Ad_Hoc/00_INDEX.md) |
| Sparse/dense | Essbase dimension classifications affecting storage modeling; source Cloud applicability. | [Essbase](Essbase_Internal_Architecture/00_INDEX.md) |
| Task Manager | Task-management feature in applicable services; distinct from legacy Task Lists. | [Workflow](03_Workflow_and_Task_Management/00_INDEX.md) |
| Valid intersection | Rule limiting valid member combinations in relevant entry contexts; does not grant permission. | [Forms](Form_Properties/00_INDEX.md) |
| POV | Point of View: selected dimensional context for data being viewed or edited. | [UI](02_User_Interface_and_Navigation/00_INDEX.md) |
| Runtime prompt | Value requested at rule launch to parameterize supported execution. | [Calculation Manager](Calc%20Manager/Calculations_and_Allocations/00_INDEX.md) |

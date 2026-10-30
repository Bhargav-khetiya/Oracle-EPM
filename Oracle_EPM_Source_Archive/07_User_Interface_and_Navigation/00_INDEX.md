# Volume 12B: User Interface, Navigation Flows, and Grid Operations

## 1. Executive Architectural Overview

The Oracle EPM Cloud presentation tier encompasses role-tailored Navigation Flows, real-time interactive Dashboards and Infolets, dynamic Web Data Grids, and specialized grid spreading/mass allocation tools.

```
+---------------------------------------------------------------------------------------------------+
|                                  USER INTERFACE ARCHITECTURE                                      |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [ROLE-BASED NAVIGATION FLOWS]                                                                    |
|  - Custom cluster icons, card tabs, and sub-tabs assigned to user groups                          |
|  - Hides administrative complexity from frontline business planners                              |
|                                                                                                   |
|  [DASHBOARDS 2.0 & INFOLETS]                                                                      |
|  - Real-time visualization widgets (bar, line, waterfall, radar, donut)                          |
|  - Direct interactive grid components linked via global POV bars                                 |
|                                                                                                   |
|  [WEB DATA GRID OPERATIONS]                                                                       |
|  - Grid Spread: Proportional, Even, and Fill spreading of totals down time periods                |
|  - Mass Allocation: On-demand distribution of values across sparse dimensions                     |
|                                                                                                   |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Directory Contents and Chapter Navigation

| Document | Primary Focus | Key Architectural Concepts |
| :--- | :--- | :--- |
| [Oracle_EPM_Navigation_Flows_Master_Guide.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/02_User_Interface_and_Navigation/Oracle_EPM_Navigation_Flows_Master_Guide.md) | **Navigation Flows** | Designing role-based home page clusters, cards, and tabs. Custom branding, dynamic permissions, and multi-tab workflows. |
| [Oracle_EPM_Dashboards_Master_Guide.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/02_User_Interface_and_Navigation/Oracle_EPM_Dashboards_Master_Guide.md) | **Dashboards & Infolets** | Dashboard 2.0 architecture, component linking, global POV synchronization, and high-speed ASO reporting feeds. |
| [Oracle_EPM_Grid_Spread_Master_Guide.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/02_User_Interface_and_Navigation/Oracle_EPM_Grid_Spread_Master_Guide.md) | **Grid Spread Operations** | Deep architectural guide (50KB) on Proportional, Even, and Fill spreading algorithms, cell locks, and historical proportions. |
| [Oracle_EPM_Mass_Allocate_Master_Guide.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/02_User_Interface_and_Navigation/Oracle_EPM_Mass_Allocate_Master_Guide.md) | **Mass Allocation in Forms** | Exhaustive guide (69KB) on client-side mass allocation wizards, basis drivers, spread ratios, and server-side calculation commits. |

---

## 3. Related Cross-References
- **Web Data Form Properties**: See [Form_Properties/00_INDEX.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Form_Properties/00_INDEX.md)
- **Action Menus**: See [Action_Menus/00_INDEX.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Action_Menus/00_INDEX.md)
- **Calculation Allocations**: See [Calc Manager/Calculations_and_Allocations/03_System_Templates_Deep_Dive/01_Allocation_Template.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/03_System_Templates_Deep_Dive/01_Allocation_Template.md)


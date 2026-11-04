# 01 — Action Menu Architecture & Context Relay

---

## 1.1 What is an Action Menu—

In Oracle EPM Cloud Planning, an **Action Menu** (commonly referred to as a **Right-Click Context Menu**) allows administrators to attach contextual actions directly to cells, rows, columns, and POV drop-downs in Web Data Forms, Web Ad Hoc grids, and Smart View (Excel).

```
┌────────────────────────────────────────────────────────────────────────┐
│                        THE ACTION MENU PARADIGM                        │
├──────────────────────────────────┬─────────────────────────────────────┤
│       WITHOUT ACTION MENUS       │          WITH ACTION MENUS          │
├──────────────────────────────────┼─────────────────────────────────────┤
│ 1. User reviews Sales in Form A. │ 1. User right-clicks Sales cell     │
│ 2. Notices variance in East Reg. │    for East Region.                 │
│ 3. Closes Form A.                │ 2. Selects "Drill to Personnel" or  │
│ 4. Navigates to Navigation Flow. │    "Calculate Catering Revenue".    │
│ 5. Opens Workforce Form B.       │ 3. Target form or business rule     │
│ 6. Manually selects East Region. │    opens instantly pre-filtered to  │
│ 7. Manually selects FY25 & Jan.  │    East Region, FY25, and Jan.      │
│ Total Time: 60 - 90 seconds      │ Total Time: 2 seconds               │
└──────────────────────────────────┴─────────────────────────────────────┘
```

---

## 1.2 Front-End vs. Back-End Architecture

```
[FRONT-END USER INTERACTION]
  │
  ├── Web Data Form Grid (Browser ADF Interface)
  ├── Web Ad Hoc Grid (Dynamic analysis canvas)
  └── Smart View for Office (Excel Right-Click -> Smart View context flyout)
  │
[EPM CONTEXT RELAY ENGINE (HyperionPlanning / ADF Kernel)]
  │
  ├── 1. Intercepts Mouse Event: (x, y) cell coordinates
  ├── 2. Scans Active Grid Context:
  │      • Page Dimensions   -> (e.g., Entity: E10002)
  │      • POV Dimensions    -> (e.g., Scenario: Budget, Version: Working)
  │      • Row Header        -> (e.g., Account: Gross_Sales, Dept: D10010)
  │      • Column Header     -> (e.g., Period: Jan, Years: FY26)
  ├── 3. Evaluates "Required Parameters" Filter:
  │      • Displays only menu items valid for this intersection
  │
[TARGET EXECUTION SUBSYSTEM]
  │
  ├── Business Rule Engine: Maps harvested coordinates to Runtime Prompts (RTP)
  ├── Planning Navigation: Opens target Form or Dashboard with filtered POV
  ├── Approval Engine: Submits/Promotes approval unit for clicked Entity
  └── Web Gateway: Injects dynamic URL tokens for external system drill-through
```

---

## 1.3 Common Fields: Technical Reference

In the supplied production UI extraction (`action menu.txt`), every menu item possesses a common header panel:

| Field Name | UI Label | Required— | Technical Limits & Rules | Internal Mechanics |
| :--- | :--- | :---: | :--- | :--- |
| **`Menu Item`** | `Menu Item` | **Yes** (`*`) | Max 80 characters. Alphanumeric characters and underscores (`_`) **only**. No spaces or punctuation. | The programmatic unique key in the Planning relational database (`HSP_ACTION_MENU_ITEM`). |
| **`Label`** | `Label` | **Yes** (`*`) | Max 80 characters. Free-form text. Spaces, numbers, and special characters **allowed**. | The human-readable string displayed to planners in the right-click menu. Supports localization keys. |
| **`Icon`** | `Icon` | No | Text / path input. | Optional UI icon path displayed adjacent to the menu text. |
| **`Type`** | `Type` | **Yes** | Dropdown with **9 supported choices**. | Dictates which type-specific property panel renders below the header. |
| **`Required Parameters`** | `Required Parameters` | **Yes** | Dropdown with **23 supported choices**. Default is `None`. | Determines the spatial and dimensional targeting criteria required for the menu item to appear. |
| **`Members`** | `Members` | No | Member string / selector dialog. | Restricts menu display to specific members within the targeted dimension (hidden when Required Parameters = `None`). |

---

## 1.4 Web Forms vs. Smart View Runtime Differences

While Action Menus function in both the web browser and Microsoft Excel via Smart View, critical behavioral differences exist:

| Feature / Behavior | Web Data Forms | Smart View (Excel) |
| :--- | :---: | :---: |
| **Menu Access** | Direct right-click anywhere on grid cell. | Right-click $\rightarrow$ Expand **Smart View** flyout menu. |
| **`Page` & `Point of View` Targeting** | Supported (can right-click directly on POV dropdowns). | **Not Supported** (right-click on Excel POV cells does not invoke menu). |
| **Launch in Separate Window** | Opens browser pop-up modal or tab. | Spawns external web browser window or Excel sub-dialog. |
| **Classic vs Streamline Rule View** | Renders ADF dialog for RTP inputs. | Renders Smart View RTP input form. |
| **Flex Forms Support** | N/A | Fully supported on Flex Forms; preserves context during row/column reordering. |

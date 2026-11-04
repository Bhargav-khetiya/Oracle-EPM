# 02 Toolbar Buttons, Screen Anatomy, and Canvas Visual Designer

## 1. Calculation Manager Screen Anatomy

The Calculation Manager rule designer interface is partitioned into four primary functional zones designed for visual flowchart composition, metadata browsing, and real-time script compilation:

```
+---------------------------------------------------------------------------------------------------+
| CALCULATION MANAGER TOOLBAR (Save, Validate, Deploy, View Toggles, Zoom, Designer Utilities)     |
+-------------------+-------------------------------------------------------+-----------------------+
| COMPONENT PALETTE | VISUAL DESIGN CANVAS                                  | PROPERTIES PANE       |
|                   |                                                       |                       |
| [New Formula    ] |  +-------------------------------------------------+  | Properties for the    |
| [New Script     ] |  | [START]                                         |  | selected component on |
| [New Condition  ] |  |    |                                            |  | the canvas:           |
| [Member Block   ] |  |    v                                            |  |                       |
| [Member Range   ] |  | +---------------------------------------------+ |  | Component Name:       |
| [FIX Object     ] |  | | FIX ("FY25", "Plan", "Working")             | |  | [Fix_Revenue_Slice  ] |
| [Rule Component ] |  | |   |                                         | |  |                       |
| [Rule Set       ] |  | |   v                                         | |  | Dimension Fixes:      |
|                   |  | | [Formula: Sales = Units * Price;]           | |  | Years: FY25           |
| TEMPLATES:        |  | +---------------------------------------------+ |  | Scenario: Plan        |
| [Allocation     ] |  |    |                                            |  | Version: Working      |
| [Clear Data     ] |  |    v                                            |  |                       |
| [Copy Data      ] |  | [END]                                           |  | Comments / Notes      |
| [Level to Level ] |  +-------------------------------------------------+  |                       |
+-------------------+-------------------------------------------------------+-----------------------+
| LOG & MESSAGE PANE (Validation Errors, Compiler Warnings, Script Preview Output)                 |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Complete Toolbar Buttons Specification

The Calculation Manager top toolbar contains specialized action triggers. Understanding each button's exact operational role is vital for efficient rule development:

| Toolbar Icon / Button | Command Label | Exact Operational Function |
| :--- | :--- | :--- |
| 💾 **Save** | **Save** | Serializes the visual canvas into the relational database (`HSP_CALCMGR_RULES`). Saves draft state without deploying. |
| 📋 **Save As** | **Save As** | Clones the current rule, formula, or template under a new artifact name. |
| ✅ **Validate** | **Validate** | Compiles the visual canvas into memory, checking member names against the Essbase outline and syntax rules. Reports errors in the Log Pane. |
| 🚀 **Deploy** | **Deploy** | Performs validation, compiles the rule into raw Essbase script language (`.csc`), registers it with Planning, and makes it available to end users. |
| 📝 **Edit Script** | **Edit Script / Designer Toggle** | Switches between the graphical visual flowchart canvas and the low-level text/code editor. |
| ⚙️ **Variable Designer** | **Variable Designer** | Launches the variable management modal to create, edit, or delete Global, Application, Plan Type, and Rule-scoped variables. |
| 🗄️ **Database Properties** | **Database Properties** | Opens physical Essbase database settings: cache sizing (Index, Data, Calc), storage limits, and location aliases. |
| 📏 **Show Grid** | **Show / Hide Grid** | Toggles alignment grid lines on the visual canvas. |
| 📐 **Snap to Grid** | **Snap to Grid** | Enforces mathematical alignment of dragged palette components to the canvas coordinate grid. |
| 🔍 **Zoom In** | **Zoom In / Out** | Adjusts canvas magnification from 25% to 200% for navigating complex rule flowcharts. |
| 🖼️ **Fit to Window** | **Fit to Window** | Auto-scales large, multi-branching rule diagrams to fit completely within the visible screen dimensions. |
| 🔲 **Format** | **Format Flowchart** | Auto-aligns all visual components, straightening connector arrows and organizing branching logic into clean vertical swimlanes. |
| 🔎 **Find/Replace** | **Find and Replace** | Searches across formulas, scripts, and component member selections for specific member strings. |

---

## 3. Visual Canvas Mechanics: Drag, Drop, and Linking

### 3.1 Component Nesting and Scope Inheritance
The visual canvas enforces strict hierarchical nesting:
* **Container Components** (such as **FIX**, **Member Range / LOOP**, and **Condition**):
  * When dragged onto the canvas, they create a bounded rectangular container.
  * Sub-components (Formulas, Scripts) dropped *inside* the container automatically inherit the surrounding multidimensional context.
  * Dragging a Formula outside the FIX box immediately strips the multidimensional boundary from that calculation.

### 3.2 Branching Flowlines in Condition Components
When a **Condition Component** (IF / ELSEIF / ELSE) is added to the canvas:
* The canvas generates two directional output ports:
  * **True Branch (Green Line)**: Executed when the conditional expression evaluates to true.
  * **False / Else Branch (Red Line)**: Executed when the condition evaluates to false.
* Components dropped onto the green line are nested inside the generated `IF (...)` block; components dropped onto the red line are placed inside the `ELSE` block.

---

## 4. Keyboard Shortcuts & Productivity Accelerators

| Shortcut Key | Action Performed |
| :--- | :--- |
| `Ctrl + S` | Save active rule draft. |
| `Ctrl + Shift + V` | Trigger in-memory rule validation. |
| `Ctrl + Shift + D` | Trigger full rule compilation and deployment. |
| `Ctrl + F` | Open Find and Replace dialog. |
| `Ctrl + Z` / `Ctrl + Y` | Undo / Redo canvas operations. |
| `Ctrl + Space` | Trigger Intellisense member / function auto-complete inside Formula and Script editors. |
| `Delete` | Remove selected component from canvas (with confirmation). |


# Oracle EPM: The Ultimate Master Guide to Action Menus (Right-Click Menus)

---

## 1. Introduction: What is an Action Menu?
An **Action Menu** (also known as a Right-Click Context Menu) allows Service Administrators to create custom options that appear when a user right-clicks on a cell, row, or column in a Web Form or an Ad Hoc Grid. 

Instead of forcing users to navigate through the home screen, Action Menus allow them to seamlessly:
*   Launch a Business Rule (with or without Runtime Prompts).
*   Jump to another Data Form.
*   Open a related Dashboard.
*   Open an external URL.
*   Navigate to Manage Approvals.

### The Power of "Context"
The most powerful feature of Action Menus is **Context Relay**. When a user right-clicks a cell, EPM captures exactly *where* they clicked. The Page, POV, the row members to the left, and the column members above are automatically passed to the target action. This means a Business Rule or Target Form automatically knows exactly which Entity, Account, and Period to run for, without the user having to re-select them.

---

## 2. Front-End vs Back-End Architecture
To fully grasp Action Menus, you must understand how they bridge the front-end interface with the back-end database.

**The Front End (Where users see it):**
*   **Web Data Forms:** Attached manually by form designers. They appear when right-clicking cells, rows, or columns.
*   **Web Ad Hoc Grids:** Attached automatically if designated as a "Global Ad Hoc Menu."
*   **Smart View (Excel):** Appear nested under the default Excel right-click menu > Smart View flyout.

**The Back End (How it links internally):**
*   **Cube Context:** Most menu items (especially Business Rules and Ad Hoc menus) must be tied to a specific back-end Cube (e.g., `Plan1`). 
*   **Parameter Passing:** The back-end EPM engine listens to the intersection the user clicked (the Required Parameters) and injects those members into the target object (e.g., pushing the "Sales" account into the Business Rule's runtime prompt).
*   **Attached Objects:** You can attach 5 types of objects to an Action Menu: Forms, Business Rules, Dashboards, Manage Approvals, and external URLs.

---

## 3. Managing Action Menus & Constraints
*(Navigation: Home > Navigator > Create and Manage > Action Menus)*

### Naming Conventions & Limitations (Text / Alphabets)
When defining a menu item, strict naming conventions apply:
*   **Menu Item Name (Back-End ID):** Must contain *only* alphanumeric characters and underscores (`_`). **No spaces or special characters allowed.** This is the unique programmatic identifier.
*   **Label (Front-End Display):** The text displayed to the user. **Spaces and special characters ARE allowed.** You can also reference a localization resource variable (e.g., `LABEL_FILE`) to support multiple languages.
*   **Icon:** Although the UI has an "Icon" field, Oracle documentation explicitly states that assigning icons is **not currently supported**.

### Structuring a Menu
Menus are built hierarchically. 
*   **Create Menu:** Creates the main container.
*   **Add Child:** Creates a menu item *inside* a Menu Header.
*   **Add Sibling:** Creates a menu item at the same level as the currently selected item.
*   **Separator Bars:** To create a visual line separating menu items, create a Menu Header and set its Label to a single hyphen (`-`). 

### Required Parameters (Where the Menu Appears)
You can restrict a menu item so it only appears when a user clicks on specific things:
*   **Point of View / Page:** Menu only appears if clicking on the POV or Page dropdowns. *(Note: Not supported in Smart View).*
*   **Row / Column:** Menu appears when clicking row/column headers.
*   **Members Only:** Menu only appears on dimension members.
*   **Cell Only:** Menu only appears on data cells.
*   **Dimension/Member Selection:** E.g., Select the `Account` dimension. The menu will *only* appear when the user right-clicks an Account member.
*   **None:** The menu appears anywhere the user right-clicks in the form.

---

## 4. Types of Menu Items & Use Cases

### 1. Business Rule
Launches a specific Business Rule for the selected Cube.
*   **View Type:** Choose how Runtime Prompts (RTPs) display.
    *   *Classic View:* Default window block.
    *   *Streamline View:* Each prompt on a different line for cleaner UI.
*   **Customization:** You can customize the Window Title, OK Button text, and Cancel Button text.
*   **Launch Confirmation Message:** You can provide a custom warning message (e.g., *"Are you sure you want to run this heavy allocation? It may take 5 minutes."*) before the rule executes.

### 2. Form
Jumps the user to a target Data Form.
*   **Context Passing:** The context (POV, Page, selected members) of the source form is retained. If the target form contains those dimensions on its Page, it will automatically update to match the source context.
*   **Flex Forms:** If the target form is a Flex Form, Action Menus will automatically open it as a Flex Form in Smart View, and a Simple Form on the web.

### 3. URL
Opens an external webpage in a new tab.
*   **Use Form Context:** A highly powerful feature. If checked, you can pass EPM dimension members as parameters into the external URL. 
*   *Example:* If you want to link to an external HR system for the selected Employee:
    *   `https://hr-system.company.com/profile?EmployeeID=<Employee>`
    *   When the user right-clicks employee "E1045", it dynamically opens `https://hr-system.company.com/profile?EmployeeID=E1045`.

### 4. Dashboard
Opens a selected Dashboard in a new dynamic tab. The cell context from the form is retained and applied to the dashboard filters.

### 5. Manage Approvals
Directs the user to the Manage Approvals screen for a specific Scenario and Version.

---

## 5. Ad Hoc Action Menus (Global Menus)

By default, Action Menus must be manually attached to specific Forms (via the Form Designer > Other Options tab). However, you can create **Global Ad Hoc Menus**.

**What is an Ad Hoc Menu?**
It is a menu that is automatically enabled for *all* Ad Hoc grids across the system, without needing to attach it manually.

**How to Configure:**
1. In Action Menus, create a new menu or edit an existing one.
2. Check the **Enable for Ad Hoc** checkbox.
3. Select the **Cubes** this menu applies to (or leave it as 'All Cubes').
4. *Result:* Whenever a user builds an Ad Hoc grid using that cube (on the web or in Smart View), right-clicking a data cell will display this menu. 

*Use Case:* Create a global "Run Consolidation" or "Calculate Current Entity" Business Rule menu that users can trigger anytime they are doing Ad Hoc analysis.

---

## 6. Smart View Integration

Action Menus are fully supported in Oracle Smart View for Office (for both Forms and Ad Hoc grids). 

**How Users Find Them in Excel:**
1. The user selects a member or data cell in their Excel sheet.
2. They right-click the cell.
3. At the very bottom of the standard Excel right-click menu, they select the **Smart View** flyout menu.
4. The custom Action Menu commands (e.g., *Allocate Plan Targets*) will appear near the bottom of this list, below standard Smart View commands like *Cell Comments* and *Adjust*.

**Important Smart View Limitations:**
*   For Action Menus attached to forms in Smart View, setting the Required Parameter to **Page** or **POV** is *not supported*. Always anchor Smart View menus to Rows, Columns, Cells, or specific Dimensions.

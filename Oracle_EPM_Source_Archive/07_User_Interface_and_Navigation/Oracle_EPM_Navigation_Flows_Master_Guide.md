# Oracle EPM Cloud: The Ultimate Master Guide to Navigation Flows

## 1. Introduction: What are Navigation Flows?
Navigation Flows control the user interface (UI) experience in Oracle EPM Cloud. They dictate exactly what icons, cards, clusters, and tabs a user sees when they log into the application. By customizing Navigation Flows, administrators can hide irrelevant technical menus and provide a clean, role-based, hyper-focused UI tailored specifically to a user's daily tasks.

---

## 2. Structural Components
*(Navigation: Tools > Navigation Flows)*

The Home Page is organized using a strict hierarchical structure:
1. **Clusters:** The large, high-level folders on the home screen (e.g., "Financials", "Workforce").
2. **Cards:** The clickable squares inside a cluster (e.g., "Expense Planning", "Revenue").
3. **Tabs (Vertical and Horizontal):** Once a card is clicked, tabs organize the content on the screen. 
   * *Vertical tabs* appear on the left side of the screen.
   * *Horizontal tabs* appear across the top of the screen within a vertical tab.

---

## 3. Objects That Can Be Attached
When you define a Card or a Tab, you must attach an artifact to it so the user can interact with the system. The following objects can be attached:
* **Dashboards (1.0 or 2.0)**
* **Data Forms**
* **Business Rules**
* **Task Lists**
* **Financial Reporting / Reports**
* **URLs** (External links or links to other Oracle Cloud applications)
* **Approvals / Job Console**

---

## 4. Role-Based Navigation Flows (Front End)
A massive advantage of Navigation Flows is that you can create different UI experiences for different sets of users.

* **The Executive Flow:** You can build a flow assigned to the "Executive_Group" that *only* displays Dashboards and Reports. All data entry forms and backend tools are completely hidden from their home screen.
* **The Planner Flow:** You can build a flow assigned to the "Planners_Group" that shows Data Forms, Task Lists, and Business Rules, but hides security and dimension management.
* **The Admin Flow (Default):** The system provides a "Default" navigation flow that shows all features available based on the user's base identity role.

**Customization Options:**
* You can rename standard labels (e.g., changing "Data" to "Budget Entry").
* You can assign custom icons to Clusters and Cards.
* You can activate, deactivate, and duplicate flows. *(Note: You cannot edit the out-of-the-box Default flow. You must duplicate it, edit the duplicate, and activate the new one).*

---

## 5. What Senior Consultants Expect You to Know (Architecture & Limitations)

> [!IMPORTANT]
> **Priority and Assignment**
> If a user belongs to multiple groups, and those groups are assigned to *different* active Navigation Flows, the system looks at the **order of the flows** on the Navigation Flow page. The flow that is highest in the list is the one the user will see. Seniors expect you to order flows carefully (most specific groups at the top, generic groups at the bottom).

> [!CAUTION]
> **Hiding is NOT Securing**
> Removing the "Rules" card from a user's Navigation Flow stops them from clicking it on the home page, but it **does not** remove their underlying security access to run rules. If they have the URL, or if they access the system via Smart View (Excel), they can still run the rule. Seniors expect you to understand that Navigation Flows are for UI simplicity, not for true security.

> [!TIP]
> **Back-End Migration**
> Navigation Flows are migrated via LCM under the "Navigation Flow" artifact. However, migrating a flow that points to a specific custom Dashboard will result in an error if that Dashboard hasn't been migrated first. Always migrate Forms/Dashboards/Reports before migrating the Navigation Flow that references them.

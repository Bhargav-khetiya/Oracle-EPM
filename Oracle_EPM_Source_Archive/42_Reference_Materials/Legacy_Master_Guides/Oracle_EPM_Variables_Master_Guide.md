# Oracle EPM Cloud: The Ultimate Master Guide to Variables

## 1. Introduction: What are Variables—
Variables in Oracle EPM Cloud act as dynamic placeholders for members, numbers, or text. Instead of hardcoding specific members (like "FY24" or "January") into hundreds of Forms, Business Rules, and Reports, administrators use variables. When the month changes, you update the variable in one central location, and the entire application updates instantly.

---

## 2. Types of Variables
There are two primary types of variables in Oracle EPM, each serving a distinctly different purpose.

### 1. Substitution Variables
Substitution variables act as global placeholders for specific dimension members. 
* **Scope:** They can be defined at the **Global** (All Applications), **Application** (Specific Application), or **Cube** (Specific Database) level. If the same variable exists at multiple levels, the system evaluates them in this order: Cube > Application > Global.
* **Usage:** They are prefixed with an ampersand (`&`) in calculations and forms (e.g., `&CurYr`, `&CurMo`).
* **Control:** They are maintained strictly by Service Administrators. End-users cannot change substitution variables.

### 2. User Variables
User variables act as dynamic filters that change based on the individual user logged into the system.
* **Scope:** They are defined at the application level, but their actual *value* is selected by each individual user in their **Preferences**.
* **Usage:** In forms, user variables allow a single generic form (e.g., "Departmental Expense") to open to "Sales" for the Sales VP, and "Marketing" for the Marketing VP, based on what they set their variable to.
* **Control:** Administrators create the variable and define a list of valid members (Limits). End-users select their specific value from that limited list.

---

## 3. Front End vs. Back End Operations

### Front End
* **Navigation:** **Tools > Variables**.
* **Usage:** Administrators add, edit, and delete both Substitution and User variables here. 
* **Limits:** For User Variables, administrators must define the "Member Limit" (e.g., `ILvl0Descendants(Department)`) to restrict what users can select.

### Back End
* **Migration:** Variables are migrated via LCM under "Relational Data".
* **EPM Automate:** Substitution variables are frequently updated via automated scripts at month-end using the `epmautomate setsubstvars` command. (e.g., `epmautomate setsubstvars CubeName CurMo=Feb`).

---

## 4. What Senior Consultants Expect You to Know

> [!IMPORTANT]
> **Performance Impact of Substitution Variables in Rules**
> Senior architects expect you to know that Essbase processes substitution variables differently than hardcoded text. In highly complex FIX statements in Calculation Manager, using a substitution variable can sometimes prevent the calculation engine from taking the most optimal query path. Use them wisely, primarily for time/period dimensions.

> [!CAUTION]
> **User Variable Context Errors**
> If a user attempts to open a form that relies on a User Variable, but the user has not yet set a value for that variable in their Preferences, the form will throw an error and refuse to open. Seniors expect you to provide clear instructions or use "Smart Lists" as an alternative if the user base is not technically savvy enough to manage their preferences.

> [!TIP]
> **Valid Intersections Support**
> **Substitution variables** are fully supported inside Valid Intersection rules (e.g., `&CurYr`). However, **User variables** are completely unsupported in Valid Intersections. 

> [!NOTE]
> **Cross-Dimensional Limits**
> A User Variable is strictly tied to a single dimension. You cannot create a user variable that spans multiple dimensions.

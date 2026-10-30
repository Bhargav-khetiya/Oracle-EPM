# Oracle EPM Cloud: The Ultimate Master Guide to Valid Intersections

## 1. Introduction: What are Valid Intersections?
**Valid Intersections** in Oracle EPM Cloud define rules that restrict who can enter or view data in specific combinations of dimensions. By default, EPM assumes all members in all dimensions are valid with one another. Valid Intersections allow you to filter certain cell intersections so users can only enter data, select members, or select runtime prompts in combinations that make business sense (e.g., specific products are only valid for specific departments).

This feature:
- Optimizes the information available to users.
- Speeds up the planning process.
- Prevents invalid data entry, making invalid cells read-only in forms.

### Valid vs. Invalid Intersections
You can define these rules in two ways:
* **Valid Intersection:** Explicitly defines which combinations *are* allowed. 
* **Invalid Intersection:** Explicitly defines which combinations *are not* allowed. Use this when data entry is allowed in most cell combinations, and you only need to prevent data entry in a select few.

---

## 2. Core Components of a Valid Intersection Rule
*(Navigation: Application > Valid Intersections)*

A Valid Intersection consists of **Groups** and **Rules**.

### Valid Intersection Groups
A group is the container for the rules and defines:
* The dimensions to be included.
* The **Anchor Dimension** (Required).
* The **Nonanchor Dimensions** (Can be marked as required or not required).
* The **Unselected Members are Valid/Invalid** setting for the anchor dimension.

### Valid Intersection Rules
Rules exist within a Group and define the specific member intersections.
* Rules must use the same dimensions defined in their parent Group.
* You can use specific members, functions (e.g., Descendants, Inclusive Descendants), or Substitution Variables. *(Note: User variables are NOT supported).*
* You can explicitly **Exclude** or **Exclude All** (shared members included) specific members from a rule.

---

## 3. Anchor vs. Nonanchor Dimensions

Understanding the difference between Anchor and Nonanchor dimensions is critical to avoiding broken forms and missing data.

> [!IMPORTANT]
> **Anchor Dimension**
> The choice of the anchor dimension is the most significant decision. It is always a **required dimension** in the cube used for evaluation.
> * If you select **Unselected Members are Valid** (Default): Any member of the anchor dimension not explicitly mentioned in a rule remains open and valid with all other dimension members.
> * If you select **Unselected Members are Invalid**: Any member of the anchor dimension not explicitly mentioned in a rule is completely locked out (invalid) across the entire application for the dimensions in this group.

> [!TIP]
> **Nonanchor Dimensions (Required vs. Not Required)**
> * If **Required**: A cube that does *not* contain this dimension will completely ignore the Valid Intersection group.
> * If **Not Required**: A cube that does *not* contain this dimension will still evaluate the anchor dimension's rules, potentially locking out data entry unexpectedly based on the anchor settings alone.

---

## 4. Evaluation Order and Overlaps

Valid Intersections evaluate based on a strict order of precedence. Understanding how rules overlap is essential for Senior Consultants troubleshooting locked forms.

### Evaluation Order (Performance)
The system evaluates the groups from top to bottom based on their order on the Valid Intersections page. Once an intersection is defined as **Invalid** by *any* group, it stops evaluating for that intersection. Invalid groups override valid group results.

### Redundancy within the SAME Group
If two rules within the *same* group overlap, the system marks the intersection as valid if **either** rule's conditions are met. (e.g., Rule 1 says Sales + Phones is valid. Rule 2 says All Departments + Phones is valid. The overlap doesn't break anything; the broader rule wins).

### Redundancy across DIFFERENT Groups
If two rules in *different* groups overlap, the system marks an intersection valid **only if it satisfies the requirements of ALL groups**. If Group 1 says "Gross Profit must use Sales Entities" and Group 2 says "Net Income can use Total Department," the restriction from Group 1 strictly applies to Gross Profit, overriding the broader allowance of Group 2.

---

## 5. Front-End Operations and Validations

### In Data Forms
* Invalid intersections appear as read-only (typically greyed out) cells.
* **Suppress Invalid Data:** In Form Design, administrators can choose to suppress invalid data. Entire rows or columns consisting solely of invalid intersections will be hidden from the user, drastically improving form performance and readability.

### In Runtime Prompts (Calculation Manager)
When a user launches a Business Rule, the member selector for the runtime prompts will automatically filter out members that result in an invalid intersection based on the user's previous selections.

### Clearing Invalid Data
If data was loaded *before* a valid intersection rule was created, that data now sits in an invalid cell. 
* You can run an **Invalid Intersection Report**.
* You can execute the **Clear Invalid Data** job to systematically wipe data that no longer conforms to the active intersection rules.

---

## 6. What Senior Consultants Expect You to Know (Architecture & Limitations)

> [!CAUTION]
> **Performance Impact**
> Over-engineering Valid Intersections can slow down form rendering and Business Rule prompt generation. Seniors expect you to use **Invalid Intersections** instead of Valid Intersections when 90% of the cube is open, to save processing time.

> [!WARNING]
> **Shared Members**
> Shared members *are* supported. If a base member is selected for a rule, any shared members are automatically included. Conversely, if a shared member is selected, the base member is included. You must be careful when using "Exclude" vs "Exclude All" if you want to target only specific shared rollups.

> [!IMPORTANT]
> **Migration and LCM**
> Intersections can be migrated via standard LCM, but they can also be imported/exported directly from the Valid Intersections page to Excel (XLSX). 
> *The Excel file must have exactly two sheets: `ValidIntersectionGroups` and `ValidIntersectionRules`.*
> **Note:** Locked rules (system-generated rules starting with FCCS_, OEP_, etc.) will not be exported or imported.

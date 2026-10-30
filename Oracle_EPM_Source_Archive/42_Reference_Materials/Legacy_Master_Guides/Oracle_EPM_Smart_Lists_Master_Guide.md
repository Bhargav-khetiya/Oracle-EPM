# Oracle EPM: The Ultimate Master Guide to Smart Lists (EPBCS / PBCS)


---

## 1. Architectural Deep Dive: How Smart Lists Actually Work

### The Problem: Text in a Numbers Game
Oracle EPM's underlying engine is **Essbase**, a multi-dimensional database optimized purely for numeric calculations. It natively hates text. If you want a user to enter "Approved" as a project status, Essbase cannot store the string "Approved" in a standard numeric data cell.

### The Solution: The Smart List Bridge
A Smart List is a metadata translation layer. 
1. **The Administrator** creates a Smart List (e.g., `Project_Status`).
2. **Entries** are defined: `1 = Draft`, `2 = Pending`, `3 = Approved`.
3. **The User** opens a web form. The Planning UI intercepts the cell, sees it's tagged with a Smart List, and replaces the numeric input box with a drop-down showing "Draft, Pending, Approved".
4. **The Database** receives the user's selection. If the user picks "Approved", Planning translates this back and stores the number `3` in Essbase.

**Internal Working:**
- Every Smart List entry has an `ID`, a `Name`, and a `Label`.
- `ID` = The integer stored in Essbase.
- `Name` = The programmatic name (no spaces) used in Business Rules and Data Management.
- `Label` = The UI-friendly text the user sees.
- The `HSP_ID` property in the relational repository maps the dimension member to the Smart List definition.

### The Golden Rule: Evaluation Order (Crucial Concept)
Data cells are intersections of multiple dimensions.
- Account says: "I am a Smart List."
- Scenario says: "I am unspecified."
- Period says: "I am unspecified."
- Currency says: "I am USD."

If `Account` is not evaluated first, the cell might look at the `Currency` dimension, decide the cell must hold "USD Data," and ignore the Smart List entirely. **Always set the dimension containing the Smart List (usually Account) to rank 1 in your Evaluation Order.** *(Navigate: Application > Overview > Dimensions > Evaluation Order)*.

---

## 2. Every Property & Button Explained (UI Breakdown)

When you navigate to **Navigator > Create and Manage > Smart Lists**, you are presented with several tabs and buttons. Here is a definitive guide to exactly what every single property does.

### The "Properties" Tab
This tab defines the global behavior of the Smart List.

- **Smart List Name**: The programmatic identifier. 
  - *Rule*: Alphanumeric and underscores only. No spaces.
  - *Example*: `Project_Status` (This is what you type into Business Rules).
- **Label**: The user-friendly name displayed in the UI.
  - *Rule*: Spaces and special characters are allowed.
  - *Example*: `Project Status (Active/Inactive)`.
- **Display Order**: Controls how the drop-down is sorted when a user clicks the cell.
  - *By ID*: Sorts by the underlying number (1, 2, 3). Useful for logical progression (e.g., Draft -> In Review -> Approved).
  - *By Name*: Sorts alphabetically by the programmatic name.
  - *By Label*: Sorts alphabetically by what the user sees.
- **#MISSING Drop-Down Label**: What text appears in the drop-down list to represent a blank/null value.
  - *Example*: If you enter `"No Selection"`, users will see "No Selection" at the top of the drop-down. If they click it, the cell is cleared and saved as `#MISSING` in Essbase.
- **#MISSING Form Label**: How the cell looks *before* the user clicks on it, if it contains no data.
  - *Drop-Down Setting*: It will show the text you entered above (e.g., "No Selection"). This makes it obvious to users that a selection is required.
  - *Form Setting*: It defers to the Data Form's settings (usually meaning the cell just looks completely blank).
- **Automatically Generate ID**: A checkbox.
  - *Checked*: As you add new entries, Planning automatically assigns ID 1, 2, 3, 4 sequentially.
  - *Unchecked*: You must manually type the ID for every entry. (Best practice for strict environments migrating via LCM or FDMEE).
- **Create from Members**: A checkbox that changes the Smart List from "manual" to "dynamic".
  - *Checked*: The "Entries" tab disappears. You are prompted to select a Dimension hierarchy (e.g., `Entity`). The Smart List automatically populates with all members under that hierarchy.
- **Minimum Access Required**: Only visible if "Create from Members" is checked.
  - *None*: Everyone sees all members in the drop-down, regardless of security.
  - *Display*: Users see members they have at least "Display" access to.
  - *Read*: Users see members they have at least "Read" access to.
  - *Write*: Users see members they have "Write" access to.

### The "Entries" Tab
This is where you manually build the list (if not using "Create from Members").

- **Add (+ Button)**: Adds a new blank row for a new entry.
- **Delete (X Button)**: Deletes the selected row. *(Warning: Deleting entries causes orphaned data!)*
- **ID**: The integer that will be physically stored in the Essbase database. (e.g., `1`).
- **Name**: The programmatic string (e.g., `In_Progress`). Used in mappings.
- **Label**: The text the user actually sees in the web form (e.g., `In Progress`).

### The "Preview" Tab
Shows exactly how your configuration looks in a live form cell. It renders the drop-down list exactly as a user will see it, allowing you to verify sorting and `#MISSING` labels.

---

## 3. Comprehensive Scenarios

### Hands-On 1: Basic Drop-Downs (Justifications)
**Goal:** Require users to explain high travel expenses.
- **Setup:** Create Smart List `SL_TravelJustif`. Entries: `1=Client_Visit`, `2=Conference`, `3=Training`.
- **Application:** Assign this to a new Account member `Travel_Justification` (Data Type: Smart List). Add to a data entry form next to `Travel_Expenses`.
- **Edge Case:** If the user leaves it blank, what happens? Configure `#MISSING Drop-Down Label` to "Select Reason" and `#MISSING Form Label` to `Drop-Down Setting` so it forces a visual prompt instead of an empty cell.

### Hands-On 2: The Boolean Calculation Driver (Yes/No)
**Goal:** A flag to determine if an employee gets a bonus.
- **Setup:** Smart List `SL_YesNo`. Entries: `0=No`, `1=Yes`. (Notice we use 0 and 1).
- **Application:** Account member `Calc_Bonus_Flag`.
- **Business Rule Integration:** Because we used 1 and 0, we can use it in math directly!
  ```essbase
  /* No IF statement needed! */
  "Bonus_Amount" = "Base_Salary" * "Bonus_Pct" * "Calc_Bonus_Flag"; 
  /* If Flag is 0, Bonus is 0. If 1, Bonus is calculated. */
  ```

### Hands-On 3: Dynamic Smart Lists from Dimension Members
**Goal:** Allow users to pick a specific "Vendor" from the Entity dimension.
- **Setup:** Create Smart List `SL_Vendors`. Select **Create from Members** and pick the `Entity` dimension (under a specific parent, e.g., `All_Vendors`).
- **Understanding:** EPM automatically uses the Member Name as the Name and the Member Alias as the Label. The ID is internally assigned based on the dimension member's unique ID.
- **Security Implication:** Set **Minimum Access Required** to `Read`. If user John does not have Read access to `Vendor_X`, it disappears from his drop-down list!

### Hands-On 4: Rate Multipliers (Risk Scoring)
**Goal:** Calculate project contingency based on Risk Level.
- **Setup:** Smart List `SL_Risk`. `1=Low` (Label: Low Risk), `2=Med` (Label: Medium Risk), `3=High` (Label: High Risk).
- **Business Rule:**
  ```essbase
  IF ("Project_Risk" == 1)
      "Contingency" = "Budget" * 0.05;
  ELSEIF ("Project_Risk" == 2)
      "Contingency" = "Budget" * 0.10;
  ELSEIF ("Project_Risk" == 3)
      "Contingency" = "Budget" * 0.20;
  ENDIF
  ```

### Hands-On 5: Using Smart Lists in Data Maps / Smart Push (ASO Syncing)
**Goal:** Push Smart List text to a Reporting (ASO) cube.
- **Concept:** ASO cubes can store Smart List text for reporting.
- **Action:** Go to Smart Lists > Synchronize. This creates dimension members in your ASO cube matching your Smart List names.
- **Edge Case:** If your Smart List names have spaces, the Sync will fail because Essbase member names cannot contain invalid characters. Always use underscores in Names (Labels can have spaces).

### Hands-On 6: Loading Smart List Data via Data Management (FDMEE)
**Goal:** Load a flat file where the source system provides text (e.g., "Active", "Terminated").
- **Concept:** You cannot load the word "Active" directly into Essbase.
- **Action:** In Data Management, create a **Mapping** for the Account/Data column. You must map the source string ("Active") to the numeric ID of the Smart List entry (e.g., "1").

### Hands-On 7: Extracting Smart List Labels in Groovy Rules
**Goal:** A Groovy rule needs to send an email with the selected Project Status.
- **Concept:** Standard Essbase rules only see the number (1). Groovy can retrieve the string!
- **Code Snippet:**
  ```groovy
  DataCell cell = grid.getCell("Project_Status")
  String statusLabel = cell.getSmartListLabel() // Returns "Approved"
  double statusID = cell.getData() // Returns 3
  ```

### Hands-On 8: Smart Lists in Financial Reporting (FR)
**Goal:** Show the text "Approved" on a PDF report, not the number 3.
- **Action:** In the FR grid, you use the `SmartList` text function. If the cell contains a 3, FR queries the relational database, finds the Label for ID 3, and renders "Approved" on the PDF.

### Hands-On 9: Smart List Member Formulas
**Goal:** A dynamic account that returns a Smart List value based on numeric thresholds.
- **Setup:** Account `Health_Score` (Data Type: Smart List `SL_Health` where 1=Poor, 2=Good, 3=Excellent).
- **Member Formula:** 
  ```essbase
  IF ("Profit_Margin" < 0.10)
      "Health_Score" = 1;
  ELSEIF ("Profit_Margin" < 0.20)
      "Health_Score" = 2;
  ELSE
      "Health_Score" = 3;
  ENDIF
  ```
  *Result:* The form automatically shows "Excellent" if profit is high.

### Hands-On 10: The "Orphaned Data" Trap (Deleting Entries)
**Goal:** Understand what happens when you modify Smart Lists.
- **Scenario:** You have a Smart List `1=Open`, `2=Closed`. You have 1,000 projects saved as `1` (Open). You delete the entry "Open". You realize the mistake and recreate "Open".
- **The Catastrophe:** EPM assigns a *new* ID to the newly created "Open" (e.g., `ID = 3`).
- **The Result:** All your 1,000 projects now show as empty or invalid drop-downs in the form, because the database still stores `1`, but ID `1` no longer exists in the Smart List definition. 
- **The Fix:** You must write a Business Rule or Data Management load to change all `1`s to `3`s in the database. *Never delete entries in production unless you are purging data.*

---

## 4. Edge Cases and System Behaviors

1. **Changing Data Types Midway:** If you change an Account from `Currency` to `Smart List`, the existing numeric data doesn't disappear from Essbase. If the existing data is `500.5`, the form will look broken or show an invalid ID error. You must clear the data before changing data types.
2. **Aggregations:** Smart List Accounts MUST have a consolidation property of `~` (Ignore). You cannot add "Approved" + "Approved". If set to `+`, Essbase will add `3 + 3 = 6`, which might correspond to "Terminated" in your list!
3. **Smart Lists on Dense vs Sparse Dimensions:** It is highly recommended to attach Smart Lists only to Dense dimensions (like Account) to avoid block explosion and calculation anomalies when executing IF statements against them.

---

## 5. Advanced Technical Questions

**Q1: A user claims they selected "High Risk" on a form and saved it. Another user opens a report and sees "Low Risk". Assuming both users have correct security, what happened?**
> **A:** There are a few possibilities.
> 1. Form intersection conflicts: The users might be looking at different intersections (e.g., different Scenarios/Versions).
> 2. Data Push: If the report is pointing to the ASO cube, the Smart Push or Data Map might not have run, so the ASO cube is showing stale data.
> 3. Smart List ID changes: The Smart List IDs might have been altered.

**Q2: How do you migrate a Smart List from Test to Prod without changing the internal IDs?**
> **A:** You must use **Migration (LCM)**. Do not manually recreate Smart Lists in Prod. LCM preserves the internal IDs. If you manually create them, the IDs will mismatch, and moving Essbase data between environments will result in incorrect drop-down selections.

**Q3: Can a single cell have multiple Smart Lists?**
> **A:** No. If multiple dimensions in a cell intersection have different Smart Lists assigned, the Evaluation Order dictates which one wins. Only one drop-down will appear.

**Q4: I set my Evaluation Order perfectly, but my cell is still Read-Only and won't show the Smart List. Why?**
> **A:** Check standard Essbase properties:
> - Is the intersection at Level-0 for all sparse dimensions?
> - Is the Scenario/Version open for input?
> - Does the Account have a Member Formula? (Members with formulas are read-only).
> - Is the Account consolidation operator set to dynamic calc?

**Q5: What is the maximum number of entries a Smart List can have?**
> **A:** Technically, thousands, but practically, performance degrades on web forms if you exceed a few hundred. If you need 1,000+ entries, you should use a Dimension (Create from Members) or re-evaluate the architecture, as drop-downs become unmanageable for users.

**Q6: We use "Create from Members" for our Employee Smart List. An employee left the company, so we deleted the member from the dimension. What happens to the historical data?**
> **A:** The historical Essbase data (the ID) remains, but it loses its textual translation. It will show up as a raw number or an invalid selection on historical forms. To handle this, instead of deleting the member, move it to an "Inactive Employees" hierarchy and restrict security to "Display" so history is maintained.

**Q7: Can I use Smart Lists in a Data Validation Rule within a Web Form?**
> **A:** Yes! You can write a validation rule: `If Current Cell Value == 3 (Approved)`, turn the cell background green. You reference the integer ID or the Smart List name depending on the validation builder context.

**Q8: If I have a Smart List with Automatically Generate IDs, and I import entries via a metadata flat file, what IDs get assigned?**
> **A:** EPM will assign the next available sequential IDs. It is best practice for highly controlled environments to *uncheck* "Automatically Generate IDs" and explicitly define the IDs in your metadata load file to ensure consistency across environments.

**Q9: How do Smart Lists impact Essbase cache and performance?**
> **A:** Smart Lists themselves have almost zero impact on Essbase calculation performance because Essbase only processes the integers. However, excessive use of IF statements checking those integers across massive sparse combinations can cause performance overhead.

**Q10: Why do Smart Lists cause issues in multi-currency applications when attached to Currency data types?**
> **A:** They shouldn't be! If an Account is meant to hold a Smart List, its Data Type should be set to `Smart List`, not `Currency`. If it is `Currency`, currency conversion scripts (HSP_Rates) will attempt to multiply the Smart List ID (e.g., `3`) by the FX rate (e.g., `1.5`), altering the ID to `4.5` and destroying the Smart List selection.

---

## 6. Smart List Functions & Programmatic Methods

Because Smart Lists act as a bridge between the numeric database (Essbase) and the user interface (Text), the way you interact with them changes entirely depending on **where** you are writing the function (e.g., Business Rules, Groovy, Financial Reporting). Here is a breakdown of the programmatic ways to interact with Smart Lists.

### 1. Essbase Calc Scripts: Direct Numeric Evaluation
Standard Essbase Calculation Scripts and Member Formulas cannot natively read text. There is no specific `@SMARTLIST` text function in standard Essbase. Instead, you evaluate the Smart List's **ID** numerically.

*   **Use Case:** You need to calculate values based on a Smart List selection (e.g., assigning a risk multiplier based on a selected Risk Level).
*   **Example (Calc Script / Member Formula):**
    ```essbase
    /* Assuming Smart List "SL_Risk": 1=Low, 2=Medium, 3=High */
    IF ("Project_Risk" == 1)
        "Contingency" = "Budget" * 0.05;
    ELSEIF ("Project_Risk" == 2)
        "Contingency" = "Budget" * 0.10;
    ELSEIF ("Project_Risk" == 3)
        "Contingency" = "Budget" * 0.20;
    ENDIF
    ```
*   **Result:** Essbase calculates the contingency purely based on the numeric value stored in the database.
*   **Difference:** This is the fastest method, but it is entirely "blind" to the textual labels.

### 2. Groovy API: `getSmartListLabel()`
Unlike standard Essbase scripts, Groovy Business Rules have access to the Planning relational database, meaning they can actively translate the number back into the user-facing text string.

*   **Use Case:** You need to extract the actual text of the Smart List to send in an email notification, build a dynamic string, or export to a text file.
*   **Example (Groovy Script):**
    ```groovy
    // Get the intersection cell containing the Smart List
    DataCell cell = grid.getCell("Project_Status")
    
    // Function to extract the text label
    String statusLabel = cell.getSmartListLabel() 
    
    // Function to extract the numeric ID
    double statusID = cell.getData() 
    
    println("The Project is currently in status: " + statusLabel)
    ```
*   **Result:** `statusLabel` returns the string `"Approved"`, while `statusID` returns the number `3`.
*   **Difference:** This is the only programmatic way to dynamically extract the user-facing text inside a Business Rule process.

### 3. Financial Reporting (FR): `SmartList` Text Function
When building PDF or HTML reports in Financial Reporting Web Studio, you want users to see the actual text, not the underlying numbers (e.g., a column of `1`s and `2`s).

*   **Use Case:** Displaying Smart List text on an external report.
*   **Example (Financial Reporting Grid):**
    You insert this text function directly into the FR grid cell properties:
    ```text
    <<SmartList("Grid1", Current, "Project_Status")>>
    ```
*   **Result:** When the report runs, FR queries the underlying ID from Essbase, looks up the Smart List definition, and renders the word `"Approved"` on the PDF.
*   **Difference:** This function only exists in the Reporting layer. It does not calculate data; it only masks the presentation of data.

### 4. Essbase Calc Scripts: `@HspNumToString` (String Conversion)
If you want to trigger a custom `@RETURN` error message that includes the user's Smart List value, you can't easily concatenate a number into a string in pure Essbase. You must use `@HspNumToString`.

*   **Use Case:** Failing a calculation script and displaying the numeric ID of the Smart List to the user in the error log.
*   **Example (Calc Script):**
    ```essbase
    FIX("Working")
        "Project_Expenses" (
            /* If the Smart List ID is 99 (Invalid Status) */
            IF ("Project_Status" == 99)
                @RETURN(@CONCATENATE("Calculation Failed. Invalid Status ID entered: ", @HspNumToString("Project_Status")), ERROR);
            ENDIF
        )
    ENDFIX
    ```
*   **Result:** The rule stops and the user sees a pop-up: *"Calculation Failed. Invalid Status ID entered: 99"*.
*   **Difference:** It converts the ID to a string, but it **does not** fetch the label. It just turns the integer `99` into the string `"99"`.

### 5. Web Form Data Validation Rules
Administrators can build visual rules (e.g., turn a cell red) based on what a user selects in a Smart List without writing any code.

*   **Use Case:** Highlighting a cell dynamically based on the dropdown selection (e.g., turning a cell Green if "Approved" is selected).
*   **Example (Form UI Logic):**
    ```text
    If Current Cell Value == 3 (Approved) 
    Then Background Color = Green
    ```
*   **Result:** The UI immediately colors the cell green as soon as the user selects "Approved" from the dropdown.
*   **Difference:** This is evaluated in the browser/UI instantly. It does not require a database save or a business rule execution.

### Summary of Differences

| Function / Method | Environment | Returns/Evaluates | Primary Purpose |
| :--- | :--- | :--- | :--- |
| **Direct Logic (`== 1`)** | Essbase Calc Script | Integer ID | Core mathematical/conditional logic in the database. |
| **`getSmartListLabel()`** | Groovy Rules | String Label | Fetching the actual text for advanced automation/emails. |
| **`SmartList` Function** | Financial Reporting | String Label | Displaying the text beautifully on a printable report. |
| **Data Validation** | Web Form UI | Condition State | Immediate visual feedback to the end-user. |
| **`@HspNumToString`** | Essbase Calc Script | Stringified ID | Converting the number to text for error messaging. |

---

## 7. Deep Dive: "Create from Members" (Dimension-Driven Smart Lists)

The **Create from Members** feature fundamentally changes how a Smart List operates. Instead of an Administrator manually typing out static entries (1=Draft, 2=Approved), the Smart List dynamically binds itself to a live dimension hierarchy (e.g., the `Entity` or `Vendor` dimension).

### 7.1. Architectural Working Principle
When you create a standard Smart List, EPM generates arbitrary integer IDs (1, 2, 3) stored in a relational table. 
When you check **Create from Members**:
1. EPM points the Smart List directly to the selected Dimension (e.g., `Vendor`).
2. EPM automatically uses the **Member Name** as the Smart List Name, and the **Alias** as the Smart List Label.
3. The internal ID assigned to the Smart List entry is mapped natively to the underlying dimension member.
4. If a new Vendor is added to the dimension, the Smart List updates automatically. No manual maintenance is required.

### 7.2. Creation & Member Access (Security Filtering)
During creation, you are required to set **Minimum Access Required**. This is a powerful feature that dynamically filters the drop-down list based on the logged-in user's dimension security.

*   **None:** The user sees all members in the drop-down, regardless of whether they have security access to that member in the actual dimension.
*   **Display:** The user only sees members in the drop-down if they have at least "Display" access to them in the dimension security.
*   **Read:** The user only sees members they have "Read" access to.
*   **Write:** The user only sees members they have "Write" access to.

**Deep Example:**
You have a Smart List driving an "Assign Project To" field, linked to the `Department` dimension. User Alice has Write access to `Dept_IT` and `Dept_HR`, but no access to `Dept_Finance`.
*   If Minimum Access = **None**: Alice sees IT, HR, and Finance in the drop-down.
*   If Minimum Access = **Write**: Alice only sees IT and HR in the drop-down. Finance is invisible.

### 7.3. Retrieval in Code & Related Functions
When a Smart List is linked to a dimension, you often need to perform logic based on the *actual dimension member* selected. 

#### Groovy Implementation (The Most Powerful Method)
Groovy provides dedicated functions to retrieve not just the text, but the actual Dimension Member object tied to the Smart List selection. This allows you to read properties, UDAs, or aliases of the selected member!

**Example: Read a UDA from the dynamically selected member**
```groovy
// 1. Get the cell containing the Smart List
DataCell cell = grid.getCell("Selected_Vendor")

// 2. Extract the actual Member Name from the Smart List
// Note: We use getSmartListMemberName(), not getSmartListLabel()
String selectedVendorName = cell.getSmartListMemberName()

// 3. Fetch the actual Dimension Member object from the application
Member vendorMember = operation.application.getDimension("Vendor").getMember(selectedVendorName)

// 4. Now we can access ANYTHING about that member!
if (vendorMember.hasUda("Preferred_Vendor")) {
    println("User selected a Preferred Vendor: " + vendorMember.getAlias("Default"))
} else {
    println("Warning: Non-preferred vendor selected.")
}
```

#### Essbase Calc Script Implementation
In standard Calc Scripts, reading a member-driven Smart List to use as a dynamic cross-dimensional pointer is notoriously difficult. You must extract the name using `@NAME` and `@HspNumToString`, or use Groovy to write the member name into a runtime prompt.
**Note:** It is highly recommended to use Groovy for this exact use case, as standard Essbase calculation blocks cannot easily use a Smart List integer to pivot to a sparse dimension member dynamically.

### 7.4. Synchronizing & Reporting (Data Maps / Smart Push)
When you push data to an ASO reporting cube, ASO does not natively understand "Smart List ID 405". It only understands text or dimension members.

**The Synchronization Process:**
1. Navigate to **Navigator > Smart Lists > Synchronize**.
2. EPM scans the Smart List and automatically creates matching dimension members in the designated ASO reporting dimension.
3. When you run a **Smart Push** or **Data Map**, you map the dense account containing the Smart List to the target ASO dimension.

**Deep Example:**
*   **BSO Cube (Input):** User selects "IT_Department" from a Smart List in the `Transfer_To` account.
*   **Synchronization:** EPM created a member named "IT_Department" in the ASO `Target_Department` dimension.
*   **Smart Push Execution:** The Data Map reads the Smart List ID from the `Transfer_To` account, translates it to the string "IT_Department", and pushes the numeric data block to the `IT_Department` member in the ASO target dimension.
*   **Result:** You can now run a report in ASO explicitly slicing by `Target_Department`.

### 7.5. The "Detach" Option
In the Smart Lists management screen (**Navigator > Smart Lists**), there is an explicit **"Detach"** button located on the top right toolbar. When you select a Smart List that was originally created dynamically from a dimension, clicking this button permanently separates the Smart List from its source dimension.

**What happens when you Detach?**
1. The Smart List breaks its dynamic link to the dimension hierarchy.
2. The "Entries" tab (which is hidden while dynamic) reappears.
3. The current list of dynamically generated members is frozen and converted into standard, static, manually-managed entries.
4. Future dimension updates (adding/removing members) will no longer sync to this Smart List.

**Why would you use the Detach technique?**
*   **Bulk Loading Hack:** If you need to create a Smart List with 500 entries (e.g., US States and Counties), typing them manually is tedious. Instead, you check "Create from Members", point it to a dimension containing those 500 members, hit save, and then immediately uncheck it (detach). You just auto-generated 500 entries in seconds!
*   **Custom Labels:** When a Smart List is dynamic, its Label *must* match the member Alias. If you detach it, you can edit the labels on the Entries tab to say anything you want, completely independent of the dimension aliases.
*   **Selective Deletion:** If you linked to the `Vendor` dimension, but you want to hide 3 specific vendors from the drop-down (and security filtering is too broad), you can detach the list and manually delete those 3 entries.


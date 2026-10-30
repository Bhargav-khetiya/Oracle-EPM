# 05 — Smart Lists: Scenarios, Troubleshooting, & Interview Bible

> **Source Reference**: Extracted from production planning extractions (`smartlist.txt`) and enterprise implementation standards.

---

## 5.1 8 Production Implementation Scenarios

The following 8 scenarios represent the most common enterprise use cases for Smart Lists in Oracle EPM Planning:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       8 PRODUCTION SMART LIST SCENARIOS                     │
├──────────────────────┬──────────────────────────────────────────────────────┤
│ 1. Project Status    │ [Draft=1, In Review=2, Approved=3, Rejected=4]       │
│ 2. Employee Grade    │ [SL_Employee_Grade: Analyst=1, Senior=2, VP=3]       │
│ 3. Nationality       │ [SL_Employee_Nationality: US=1, UK=2, UAE=3, IND=4]  │
│ 4. Trend Forecasting │ [Forecast_Trend_List: Prior Year=1, 3-Yr Avg=2]      │
│ 5. Confidence Meter  │ [ConfidenceMeter: High=100, Med=50, Low=25]          │
│ 6. Binary Toggles    │ [Yes_No: Yes=1, No=0]                                │
│ 7. Dynamic Depts     │ [Select_Dept: Synchronized via Create From Members]  │
│ 8. Depr Method       │ [Straight Line=1, Double Declining=2, MACRS=3]       │
└──────────────────────┴──────────────────────────────────────────────────────┘
```

### Detailed Scenario Breakdown Table

| # | Smart List Name | Business Requirement | Configured Entries (ID / Name / Label) | Essbase Value Stored | Calc Rule / Groovy Consumption |
| :-: | :--- | :--- | :--- | :---: | :--- |
| **1** | **`Status_List`** | Approval workflow milestone tracking. | `1: Draft`<br>`2: In_Review`<br>`3: Approved`<br>`4: Rejected` | `1.0` to `4.0` | `IF ("Project_Status" == [[Status_List.Approved]]) ... ENDIF` |
| **2** | **`SL_Employee_Grade`** | Workforce salary band lookup by job level. | `1: Grade_1 (Analyst)`<br>`2: Grade_2 (Senior)`<br>`3: Grade_3 (Director)` | `1.0` to `3.0` | Driver table lookup: Pulls base salary from assumptions cube based on selected grade. |
| **3** | **`SL_Employee_Nationality`** | Regional visa, tax, and social security calculations. | `1: US`<br>`2: UK`<br>`3: UAE`<br>`4: India` | `1.0` to `4.0` | Applies country-specific tax rate percentages: `IF ("Nationality" == [[SL_Employee_Nationality.UAE]]) Tax = 0;` |
| **4** | **`Forecast_Trend_List`** | Revenue forecasting driver selection. | `1: Prior_Yr (PY Actual)`<br>`2: Three_Yr_Avg (3-Yr Average)`<br>`3: Manual (Manual Input)` | `1.0` to `3.0` | Dynamic calculation switch: Executes `@PRIOR`, `@AVGRANGE`, or accepts direct user input. |
| **5** | **`ConfidenceMeter`** | Pipeline deal weighting for revenue recognition. | `25: Low (25%)`<br>`50: Med (50%)`<br>`75: High (75%)`<br>`100: Closed (100%)` | `25.0` to `100.0` | Multiplies gross pipeline opportunity by confidence float: `"Net_Revenue" = "Gross_Deal" * ("Confidence" / 100);` |
| **6** | **`Yes_No`** | Boolean capital expenditure approval toggle. | `1: Yes (Eligible)`<br>`0: No (Ineligible)` | `1.0` or `0.0` | Simple logical gate: `"Bonus_Amount" = "Base_Salary" * 0.15 * "Yes_No";` |
| **7** | **`Select_Dept`** | Cross-department cost allocation target. | Built via **Create From Members** pointing to `Total Department`. | Dynamic Member IDs | Dynamically identifies target cost center without maintaining static list entries. |
| **8** | **`Depr_Method`** | Fixed asset depreciation calculation engine. | `1: SL (Straight Line)`<br>`2: DDB (200% Double Declining)`<br>`3: MACRS (Tax Accelerated)` | `1.0` to `3.0` | Branches into specific financial depreciation functions inside Capital planning business rules. |

---

## 5.2 Production Troubleshooting Matrix

| Symptom / Defect | Root Cause | Diagnostic Step | Permanent Fix |
| :--- | :--- | :--- | :--- |
| **Cell displays `$1.00` instead of text label** | Dimension Evaluation Order misconfigured; Currency dimension evaluated before Account. | Check **Application $\rightarrow$ Overview $\rightarrow$ Dimensions $\rightarrow$ Evaluation Order**. | Move the dimension containing the Smart List (Account) to **Rank 1**. |
| **Dropdown displays raw numbers in Smart View** | Smart View option "Display Member Name / Alias" overriding form formatting. | Check Smart View Data Options $\rightarrow$ Cell Display. | Set Smart View display to **Use Form Formatting**. |
| **Dropdown sorted randomly instead of 1, 2, 3** | `Display Order` is set to `By Label` or `By Name` instead of `By ID`. | Open Smart List Properties tab $\rightarrow$ Inspect Display Order. | Change Display Order to **`By ID`** and save. |
| **Historical data displays raw numbers like `4.00`** | An entry was deleted from the Smart List after historical data was saved (Orphan ID). | Compare historical number with historical LCM backup. | Re-create the deleted entry with the identical integer ID (`4`). |
| **Empty cells look blank instead of saying "No Data"** | `#Missing Form Label` is set to `Form Setting` instead of `Drop Down Setting`. | Check `#Missing Form Label` on Properties tab. | Change to **`Drop Down Setting`**. |
| **Smart List dropdown does not appear in web form** | Member data type set to `Currency` or `Non-Currency` instead of `SmartList`. | Open Dimension Library $\rightarrow$ Inspect Account member `Data Type`. | Set `Data Type` = `SmartList` and select the target list in `Smart Lists` dropdown. |
| **Data Map / Smart Push fails to sync Smart List data** | Smart List IDs differ between source BSO cube and target ASO cube. | Export Smart Lists from both environments via LCM. | Synchronize entry IDs across both cubes using identical manual IDs. |

---

## 5.3 Golden Do's and Don'ts of Smart Lists

### ✅ The DO's:
1. **DO set Evaluation Order Rank 1** on the dimension containing Smart Lists (typically Account).
2. **DO use programmatic bracket syntax in business rules** (`[[SmartList.Entry]]`) rather than hardcoding numeric IDs (`1`, `2`).
3. **DO uncheck `Automatically generate ID` in multi-environment deployments** to guarantee identical ID mapping across Dev, Test, and Prod.
4. **DO mark obsolete entries as `[INACTIVE]`** instead of deleting them to protect historical reporting.
5. **DO use `Create From Members`** when the list of choices represents an active dimension hierarchy.

### ❌ The DON'Ts:
1. **DON'T delete Smart List entries** if data has ever been committed against them in any historical period.
2. **DON'T change the integer ID of an existing entry**; it silently corrupts all historical data blocks.
3. **DON'T use Smart Lists when a dimension member is required for slicing**; Smart Lists cannot be placed on form Row or Column axes.
4. **DON'T create Smart Lists with more than 5,000 entries**; large lists cause browser rendering lag during dropdown construction.

---

## 5.4 20 Consultant Interview Questions & Answers

### Beginner Level (Fundamentals)

#### Q1: What is an Oracle EPM Planning Smart List?
> **Answer**: A Smart List is a predefined dropdown list of text choices assigned to an Account or custom dimension member. While the user selects and views a descriptive text label in forms or Smart View, Essbase physically stores a corresponding numeric integer in the underlying multi-dimensional data block.

#### Q2: How does Essbase store a Smart List value on disk?
> **Answer**: Essbase stores Smart List values as standard 64-bit IEEE double-precision floating-point numbers (e.g., `1.00000000`, `2.00000000`) inside the 8-byte cells of `.PAG` data files. Essbase has no native text engine; Planning acts as an application-tier translation dictionary between the number and the text label.

#### Q3: Which dimension member data type is required to display a Smart List?
> **Answer**: The member's **Data Type** property must be set to **`SmartList`**, and the specific list must be selected in the **`Smart Lists`** dropdown property in the Dimension Editor.

#### Q4: What is the difference between the Smart List Name and its Label on the Properties tab?
> **Answer**: The **Smart List Name** (e.g., `SL_Status`) is the internal programmatic identifier referenced in Calc Manager rules and REST APIs (max 80 chars, alphanumeric and underscores only). The **Label** (e.g., `Project Approval Status`) is the human-readable display name shown in administration screens and form builders.

#### Q5: What are the two available tabs other than Properties observed on the Smart List configuration screen?
> **Answer**: The **Entries** tab (used to define entry IDs, names, and labels) and the **Preview** tab (used by administrators to test dropdown sorting and missing label rendering).

---

### Intermediate Level (UI Configuration & Architecture)

#### Q6: Explain the difference between `Drop Down Setting` and `Form Setting` in `#Missing Form Label`.
> **Answer**: `Drop Down Setting` causes an empty cell to display the text specified in `#Missing Drop Down Label` (e.g., `"No Data"`) before the user clicks it. `Form Setting` defers to the web form's global missing setting, typically rendering the empty cell as completely blank.

#### Q7: What are the 4 available options in the `Display Order` dropdown?
> **Answer**: **`ID`** (sorts numerically by entry ID), **`Name`** (sorts alphabetically by programmatic entry name), **`Label`** (sorts alphabetically by user-facing label), and **`Hierarchy`** (arranges entries in parent-child indented tree format when built using `Create From Members`).

#### Q8: Why is Dimension Evaluation Order critical when working with Smart Lists?
> **Answer**: Because cells are multidimensional intersections, multiple dimensions dictate formatting. If the Currency dimension is evaluated before the Account dimension, Planning formats the cell as currency (e.g., `$1.00`). Setting Account to **Evaluation Order Rank 1** ensures the Smart List formatting takes precedence.

#### Q9: What happens when `Automatically generate ID` is checked versus unchecked?
> **Answer**: When checked, Planning automatically assigns sequential IDs (`1, 2, 3...`) as new entries are added. When unchecked, administrators must manually specify the integer ID for each entry. Unchecking is the production best practice in multi-environment deployments to prevent ID mismatches between Dev, Test, and Prod.

#### Q10: What is an "Orphan ID" and how does it occur?
> **Answer**: An Orphan ID occurs when an administrator deletes an entry from a Smart List after historical data was saved against it. Essbase retains the numeric float (e.g., `4.0`), but because ID `4` no longer exists in the Planning relational dictionary, forms render the raw number `"4.00"` instead of a text label.

---

### Advanced Level (Calculations & Multi-Cube Integration)

#### Q11: How do you reference a Smart List entry inside an Essbase calculation script?
> **Answer**: Using double-bracket notation: `IF ("Employee_Type" == [[Employee_Type.Full_Time]])`. Planning pre-compiles this into the numeric integer before sending the script to the Essbase kernel (`IF ("Employee_Type" == 1)`).

#### Q12: How do you extract the text string of a Smart List entry in Calculation Manager for export?
> **Answer**: Using the CDF (Custom Defined Function) `@HspNumToString("AccountName")` or `@HspGetSmartListLabel("SmartListName", "AccountName")`.

#### Q13: How do you read and write Smart List values in EPM Groovy rules?
> **Answer**: Use `cell.getSmartList()` or `cell.getFormattedValue()` to read the text label, and `cell.setSmartList("Full_Time")` or `cell.data = 1` to write values back to the grid.

#### Q14: What happens if a calculation script writes a number that does not correspond to any Smart List entry (e.g., `999.0`)?
> **Answer**: Essbase successfully commits the float `999.0` to the data block. However, when viewed on a form, Planning will display the raw number `"999.00"` because no corresponding text label exists in the dictionary.

#### Q15: How does `Create From Members` work architecturally?
> **Answer**: Planning links the Smart List directly to an Essbase dimension hierarchy within a selected cube. Whenever members are added, renamed, or moved in that dimension, Planning automatically synchronizes the Smart List entries without requiring manual maintenance.

---

### Scenario-Based & Production Debugging

#### Q16: A finance user complains that a Smart List dropdown shows "$1.00", "$2.00" instead of "Draft", "Approved". How do you resolve this?
> **Answer**: Navigate to **Application $\rightarrow$ Overview $\rightarrow$ Dimensions $\rightarrow$ Evaluation Order**. Verify the rank order. Move the **Account** dimension to **Rank 1** above Currency and Entity. Perform a database refresh.

#### Q17: You are migrating a Workforce planning application from Dev to Prod via LCM. Planners in Prod report that all "Full-Time" employees are now showing as "Contractors". What caused this?
> **Answer**: `Automatically generate ID` was checked, and entries were created in a different order in Dev versus Prod (e.g., Full-Time was ID 1 in Dev, but Contractor was ID 1 in Prod). The data was loaded with ID 1, leading to swapped classifications. Fix: Align Prod entry IDs to Dev via LCM snapshot import.

#### Q18: Can a Smart List be assigned to a Dense dimension member other than Account?
> **Answer**: Yes, Smart Lists can be assigned to custom Dense dimensions or Period/Version in specialized modules, provided the dimension evaluation order prioritizes the Smart List dimension over conflicting currency or numeric formats.

#### Q19: How do Smart Lists behave in Smart View when copying and pasting data?
> **Answer**: Users can copy and paste the text label (e.g., "Approved") across cells. Upon submitting data, Smart View translates the text into the corresponding numeric ID before transmitting the payload to Essbase. If an invalid string is typed, Smart View rejects the submission.

#### Q20: What is the recommended deployment checklist before releasing a Smart List to production?
> **Answer**:
> 1. Uncheck `Automatically generate ID` and verify manual integer IDs across Dev, Test, and Prod.
> 2. Confirm Account dimension is Evaluation Order Rank 1.
> 3. Verify `#Missing Drop Down Label` is set to `"No Data"` and `#Missing Form Label` is configured as desired.
> 4. Test dropdown rendering in both Web Forms and Smart View.
> 5. Validate business rules utilizing `[[SmartList.Entry]]` syntax execute correctly against target cells.

# 07 — Dimension Properties: Troubleshooting, Do's & Don'ts, and Interview Bible

> **Source Reference**: Extracted from production member extractions (`Dimension property.txt`) and enterprise implementation standards.

---

## 7.1 Production Troubleshooting Matrix

| Symptom / Error | Root Cause in Member Properties | Verification Steps | Definite Resolution |
| :--- | :--- | :--- | :--- |
| **Parent ratio shows sum of children** (e.g. 40% + 60% = 100%) | `Two Pass Calculation` is unchecked or member is `Store` instead of `Dynamic Calc`. | Open Account properties. Check Data Storage and Two Pass state. | Set Storage to `Dynamic Calc` and check `Two Pass Calculation`. |
| **Cannot enter data into Level 0 cell** | Member is `Dynamic Calc`, `Label Only`, or Version is `Standard Target`. | Inspect Data Storage and Version Type in Dimension Editor. | Change Storage to `Store` (or `Never Share`). Ensure Version is `Bottom Up`. |
| **Smart List dropdown does not appear in form cell** | Account Data Type is set to `Currency` or `Unspecified` instead of `SmartList`. | Open Account properties; verify Data Type and Smart List assignment. | Set Data Type to `SmartList`, select the Smart List, and run Application Refresh. |
| **Positive variance for overspent expenses** | `Variance Reporting` is configured as `Non-Expense` instead of `Expense`. | Check Account properties $\rightarrow$ Variance Reporting dropdown. | Change Variance Reporting to `Expense`. |
| **Balance Sheet cash at Q1 shows 3x actual ending balance** | `Time Balance` is set to `Flow` instead of `Balance`. | View Time Balance property on Asset account. | Set Time Balance to `Balance` and Skip to `Missing`. |
| **Cube refresh fails after adding a parent member** | Parent with single child auto-shared, causing block collision. | Check if parent has only one child and is set to `Store`. | Set the single child (or parent) to `Never Share`. |
| **Data disappears from forms outside FY24-FY40** | Scenario active date range (`Start Yr` / `End Yr`) does not cover the period. | Check Scenario properties: `Start Yr`, `End Yr`. | Expand the active year and period window on the Scenario member. |
| **Dynamic Children cannot be added by planners** | `Enable for Dynamic Children` unchecked on parent member. | Inspect parent member dynamic children settings. | Check `Enable for Dynamic Children` and set limit (e.g., 10). |
| **Member is checked for FinPlan but disabled for EPBCS** | The member belongs to a dimension excluded from that specific cube's dimensionality. | Check Plan Type Enablement matrix in the Dimension Editor. | Enable dimension in target plan type or assign standard "No Member" pattern. |
| **Approval workflow stuck / unable to promote entity** | Version or Scenario has `Enabled for Approvals` unchecked. | Check Scenario and Version member properties. | Check `Enabled for Approvals` and assign to Planning Unit Hierarchy (PUH). |

---

## 7.2 Golden Do's and Don'ts of Dimension Properties

### ✅ The DO's:
1. **DO use `Never Share` on single-child stored parents** to prevent Essbase from auto-sharing blocks and creating locking conflicts.
2. **DO set Time Balance to `Balance` and Skip to `Missing`** for all Balance Sheet and Headcount accounts.
3. **DO set Variance Reporting to `Expense`** for all expense accounts so that overspending correctly displays as negative/red variance.
4. **DO keep Dynamic Calc member formulas simple** (addition, subtraction, simple ratios) to ensure sub-second form retrieval.
5. **DO create a "No Member" (e.g., `No Custom1`)** in every custom dimension to provide a clearinghouse coordinate for non-project data.
6. **DO disable unneeded custom dimensions in sub-cubes** to keep block sizes small and calculations fast.
7. **DO enable sandboxes only on working, active modeling versions** to prevent virtual block memory bloat.

### ❌ The DON'Ts:
1. **DON'T use `Dynamic Calc and Store`** in modern EPM Cloud applications; it causes severe `.PAG` disk fragmentation and cache synchronization overhead.
2. **DON'T rename or delete any `HSP_` member** (e.g., `HSP_Approval Unit Hierarchy`); doing so breaks the Planning relational database schema.
3. **DON'T assign complex procedural formulas to stored members in the outline**; execute them via Calc Manager business rules or Groovy instead.
4. **DON'T leave Time Balance as `Flow` on Balance Sheet accounts**; it will sum January, February, and March cash together, presenting inflated balance sheet totals.
5. **DON'T enable sandboxes on every version**; reserve sandboxes for iterative forecasting.

---

## 7.3 20 Consultant Technical Interview Questions & Answers

### Fundamentals & Universal Properties

#### Q1: What is the exact difference between `Store` and `Dynamic Calc` in Essbase—
> **Answer**: A `Store` member allocates an 8-byte IEEE double-precision floating-point slot within each dense data block stored in physical `.PAG` files on disk (and creates an entry in `.IND` if sparse). A `Dynamic Calc` member consumes **0 bytes of disk space**; its value is evaluated dynamically in RAM during query execution using the Dynamic Calc Cache and discarded after the query completes.

#### Q2: Why is the Two Pass Calculation checkbox disabled on stored members—
> **Answer**: Essbase executes Two-Pass calculations exclusively in RAM during runtime query evaluation. Stored members are calculated during pre-compiled batch calculation runs (`CALC ALL`, `AGG`). Therefore, Oracle EPM Cloud restricts Two-Pass calculations to dense `Dynamic Calc` members.

#### Q3: When MUST an architect configure `Never Share`—
> **Answer**: `Never Share` is required when a parent member has only one child. Under default Essbase optimization, Essbase marks single-child parents as "Auto-Shared" with the child to save space. In Planning, this shared pointer causes security evaluation errors, data input locks, and unexpected formula overwrites. Setting `Never Share` forces Essbase to generate distinct blocks.

#### Q4: What does the `Label Only` storage type do—
> **Answer**: `Label Only` members store no data and cannot accept calculations or user inputs. They serve purely as navigation headings or organizational labels in hierarchies (e.g., `Gross Margin Ratios`).

---

### Account Dimension Architecture

#### Q5: Explain the 6 Account Types and their consolidation default behavior.
> **Answer**:
> 1. `Expense`: Aggregates as positive expense; variance is inverted.
> 2. `Revenue`: Normal income rollup.
> 3. `Asset`: Balance sheet debit balances.
> 4. `Liability`: Balance sheet credit balances.
> 5. `Equity`: Ownership and retained earnings.
> 6. `Saved Assumption`: Drivers and statistical factors that do not consolidate into financial parents.

#### Q6: What is the difference between `Flow` and `Balance` in Time Balance—
> **Answer**: `Flow` sums all periods across time (e.g., Q1 = Jan + Feb + Mar), essential for Income Statement accounts. `Balance` takes the ending period's value (e.g., Q1 Cash = March ending balance), essential for Balance Sheet accounts.

#### Q7: What are the 4 Skip options for Time Balance accounts—
> **Answer**:
> - `None`: Evaluates all periods including zeros and missing.
> - `Missing`: Ignores `#MISSING` periods and takes the last populated period.
> - `Zeros`: Ignores periods containing `0.00`.
> - `Missing And Zeros`: Ignores both `#MISSING` and `0.00` values when evaluating balance.

#### Q8: What does `Variance Reporting` control—
> **Answer**: It dictates whether an increase in an account is treated as favorable or unfavorable. For `Expense` accounts, Actual > Budget is an overspend (negative variance). For `Non-Expense` accounts (Revenue), Actual > Budget is favorable (positive variance).

---

### Period, Scenario & Version Dimensions

#### Q9: What is the purpose of `Start Yr / Period` and `End Yr / Period` on Scenario members—
> **Answer**: It defines the active data entry and reporting window for that scenario (e.g., FY24 Jan to FY40 Jul on `Actual`). Planners cannot enter data, run calculations, or open forms outside this active window.

#### Q10: What does `Include BegBal as Time Period` do—
> **Answer**: It attaches the `BegBal` (Beginning Balance) non-calendar member to the scenario. It stores opening balance sheet positions and opening headcount without distorting monthly cash flows.

#### Q11: Explain the difference between `Standard Bottom Up` and `Standard Target` versions.
> **Answer**: In `Standard Bottom Up`, planners enter data at Level 0 leaf members, and values aggregate upward into read-only parent nodes. In `Standard Target`, executives enter top-down target envelopes directly at parent nodes, and Planning spreads the data downward to child members using grid spreading or allocation rules.

#### Q12: How do Sandboxes work on the Version dimension—
> **Answer**: When `Enable Sandboxes` is checked on a Version member, Planning generates private virtual data blocks for individual planners. Planners can test "what-if" forecasts without affecting the base plan until they click **Publish**.

---

### Multi-Cube Architecture & Consolidation Operators

#### Q13: What is the multi-cube "No Member" pattern (e.g., `No Custom1`)—
> **Answer**: When custom dimensions (e.g., Project, Product) exist in some cubes but not others, or when entering enterprise-level assumptions not attributable to a project, the "No Member" pattern provides a valid clearinghouse Level 0 coordinate (`No Custom1`) to avoid data rejection.

#### Q14: Explain the 7 BSO Consolidation Operators.
> **Answer**:
> 1. `+` (Addition): Child adds to parent.
> 2. `-` (Subtraction): Child subtracts from parent.
> 3. `*` (Multiplication): Multiplies parent balance.
> 4. `/` (Division): Divides parent balance.
> 5. `%` (Percent): Calculates child percentage of parent.
> 6. `~` (Ignore): Member is bypassed during consolidation.
> 7. `^` (Never): Member never consolidates under any calculation script.

#### Q15: Why does the EPBCS plan type only show `Addition` and `Ignore` consolidation operators—
> **Answer**: ASO (Aggregate Storage) reporting cubes rely on MDX set rollups and solve orders rather than sequential procedural consolidation. Consequently, ASO outlines support only Addition and Ignore.

---

### System & Approval Dimensions (`HSP_` Members)

#### Q16: What does the `HSP_` prefix indicate on dimension members—
> **Answer**: `HSP_` designates internal Planning system members managed by the application repository (e.g., `HSP_Approval Unit Hierarchy`, `HSP_Rates`). Administrators must never delete or rename these members, as they maintain relational integrity with approval workflows and exchange rate tables.

#### Q17: What are the 17 Metric Types associated with system members—
> **Answer**:
> 1. `None`
> 2. `Data Value`
> 3. `Process State`
> 4. `Approval Unit PM Member`
> 5. `Approval Unit Primary Member`
> 6. `Approval Unit Secondary Member`
> 7. `Approval Unit Owner`
> 8. `Approval Unit Previous Owner`
> 9. `Approval Unit Last Action`
> 10. `Approval Unit Substate`
> 11. `Approval Unit Submission Group`
> 12. `Approval Unit Hierarchy`
> 13. `Entity Process State`
> 14. `Approval Unit Total`
> 15. `Approval Unit Total (Dynamic)`
> 16. `Approval Unit Last Modified`
> 17. `Cell Level Security Access`

#### Q18: What is a Submission Group in Planning Unit Hierarchies—
> **Answer**: Submission Groups partition an entity's data into independent approval streams (e.g., HR submits headcount in Group 1; Cost Center manager submits OpEx in Group 2), preventing dependencies where one department blocks another's workflow.

---

### Dynamic Children & Outline Restructuring

#### Q19: How do Dynamic Children work in Oracle EPM Planning—
> **Answer**: When `Enable for Dynamic Children` is checked, administrators specify a maximum limit (e.g., 10). Planners can add ad-hoc members (e.g., new projects or employees) on the fly directly from web forms without requiring an administrator to perform a full database outline restructuring.

#### Q20: What is the consultant deployment checklist for dimension properties—
> **Answer**:
> 1. Verify all parent members with a single child are set to `Never Share`.
> 2. Confirm all Balance Sheet and Headcount accounts are `Time Balance = Balance` and `Skip = Missing`.
> 3. Verify all Expense accounts have `Variance Reporting = Expense`.
> 4. Ensure ratios and margins are set to `Dynamic Calc` with `Two Pass Calculation` checked.
> 5. Validate that all Scenario members have active date windows spanning all planning years.
> 6. Run Application Refresh to compile the outline into Essbase.

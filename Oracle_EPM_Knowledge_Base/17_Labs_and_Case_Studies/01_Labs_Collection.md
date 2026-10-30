# Labs and Case Studies — Hands-On Exercises

> **Section:** 17 — Labs and Case Studies  
> **File:** 01 — Labs Collection  
> **Difficulty:** Beginner → Advanced  
> **Prerequisites:** [04_Study_Path_and_Learning_Roadmap](../00_Foundation/04_Study_Path_and_Learning_Roadmap.md)

---

## How to Use These Labs

Each lab is a self-contained exercise designed to reinforce a specific concept. Work through them in order for the best learning progression. Labs assume you have access to an EPM Cloud instance (use the Vision sample application for practice).

---

## Lab 1: Explore the EPM Cloud Interface (Beginner — 20 min)

**Objective:** Navigate the EPM Cloud home page and identify key areas.

**Steps:**
1. Log in to your EPM Cloud instance
2. Identify the Navigator menu — list all available cards
3. Open a data form — identify the POV bar, row headers, column headers, and data cells
4. Right-click a cell — observe available options
5. Open the Job Console — identify recent jobs and their statuses

**Expected outcome:** You can confidently navigate the EPM Cloud interface and locate key areas.

---

## Lab 2: Create and Modify Dimensions (Beginner — 30 min)

**Objective:** Add a custom dimension member and set its properties.

**Steps:**
1. Navigator → Dimensions → Entity
2. Click on an existing parent member
3. Add a child member: Name = "Test_Entity_001", Alias = "Test Entity"
4. Set properties: Data Storage = Store, Data Type = Currency
5. Save the dimension
6. Run Database Refresh to deploy the change
7. Open a form and verify the new member appears

**Validation:** The new member appears in the Entity dimension selector.

---

## Lab 3: Build a Simple Business Rule (Intermediate — 45 min)

**Objective:** Create a calc script that calculates Net Income.

**Steps:**
1. Navigator → Calculation Manager → New Rule
2. Name: `Lab_Calculate_Net_Income`, Plan Type: Plan1
3. Write the script:
```
FIX("Budget", "Working", &CurrYear, @LEVMBRS("Entity", 0))
    "Net_Income" = "Revenue" - "Expense";
ENDFIX
```
4. Validate → Save → Deploy
5. Navigate to Rules → Launch the rule
6. Open a form showing Net Income — verify the values are correct

**Expected outcome:** Net Income cells show Revenue minus Expense for all leaf entities.

---

## Lab 4: Create a Data Entry Form (Intermediate — 45 min)

**Objective:** Design a form for budget input.

**Steps:**
1. Navigator → Forms → Create
2. Set up the form:
   - Name: "Lab_Budget_Input"
   - POV: Scenario = Budget, Version = Working, Year = FY26
   - Rows: Account (Revenue, Expense, Net_Income)
   - Columns: Period (Jan through Dec)
   - Page: Entity (selectable)
3. Set form properties:
   - Enable "Suppress missing rows"
   - Add a "Run on Save" business rule: Lab_Calculate_Net_Income
4. Save and test by entering data and saving

**Expected outcome:** Users can enter Revenue and Expense; Net Income calculates automatically on save.

---

## Lab 5: Write Your First Groovy Rule (Intermediate — 60 min)

**Objective:** Create a Groovy validation rule that prevents negative revenue.

**Steps:**
1. Create a new Groovy rule: `GR_Lab_Validate_Revenue`
2. Write the code:
```groovy
def hasErrors = false

operation.grid.dataCellIterator().each { cell ->
    if (cell.edited) {
        def account = cell.getMemberName("Account")
        if (account == "Revenue" && cell.data < 0) {
            cell.addValidationError(0xFF0000,
                "Revenue cannot be negative! You entered: ${cell.data}")
            hasErrors = true
        }
    }
}

if (hasErrors) {
    throwVetoException("Please fix validation errors before saving.")
}
```
3. Validate → Save → Deploy
4. Associate as "Before Save" rule on your Lab_Budget_Input form
5. Test: Enter a negative revenue value → Save → Observe the error message

**Expected outcome:** The form rejects negative revenue and highlights the cell in red.

---

## Lab 6: EPM Automate Basics (Intermediate — 30 min)

**Objective:** Use EPM Automate to run a business rule from the command line.

**Steps:**
1. Open a command prompt
2. Log in:
   ```
   epmautomate login admin@company.com password https://instance.pbcs.oraclecloud.com
   ```
3. List files:
   ```
   epmautomate listfiles
   ```
4. Run a business rule:
   ```
   epmautomate runbusinessrule "Lab_Calculate_Net_Income"
   ```
5. Check job status
6. Log out:
   ```
   epmautomate logout
   ```

**Expected outcome:** The business rule runs successfully from the command line.

---

## Lab 7: Smart View Connection (Beginner — 30 min)

**Objective:** Connect to EPM Cloud from Excel and retrieve data.

**Steps:**
1. Open Excel → Smart View ribbon → Connections
2. Create a new connection using your EPM Cloud URL
3. Open a form in Smart View — observe the familiar form layout in Excel
4. Try ad hoc mode — zoom in on an Entity member
5. Edit a cell and submit data back to the cube
6. Run a business rule from Smart View

**Expected outcome:** You can retrieve, edit, and submit data from Excel.

---

## Lab 8: Dynamic Groovy Calc Script (Advanced — 60 min)

**Objective:** Build a Groovy rule that generates a dynamic calc script based on user selections.

**Steps:**
1. Create Runtime Prompts: RTP_Entity (Member), RTP_GrowthRate (Numeric)
2. Create Groovy rule: `GR_Lab_Dynamic_Growth`
3. Write the code that reads RTPs and generates a targeted FIX statement
4. Execute the generated calc script via `operation.planType.execute()`
5. Associate with a form and test with different entity/growth rate combinations

**Expected outcome:** The rule applies different growth rates to different entities based on user selection, running only against the selected entity's blocks.

---

## Case Study: Hotel Budget Planning

### Scenario

Hotel Pvt Ltd operates 5 hotels across India. They need to build a budget planning application that:
1. Captures revenue by hotel and department
2. Calculates expenses based on occupancy rates
3. Produces a P&L for each hotel and consolidated
4. Supports approval workflow from Hotel GM → Regional VP → CFO

### Architecture Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Application type | EPBCS Financials Module | Pre-built P&L structure |
| Cube type | Hybrid BSO | Write-back + fast retrieval |
| Entity hierarchy | 3 levels (Total → Region → Hotel) | Simple, matches org chart |
| Custom dimensions | Department, Room_Type | Additional analysis axes |
| Scenario | Actual, Budget, Forecast | Standard planning pattern |

### Implementation Steps

1. Create the application with Financials Module
2. Configure Entity dimension with hotel hierarchy
3. Add custom dimensions for Department and Room Type
4. Build input forms for each department
5. Create business rules for P&L calculations
6. Configure approval workflow
7. Set up Smart Push between Financials and Workforce cubes
8. Build dashboards for management reporting
9. Configure EPM Automate for nightly data loads

This case study connects every concept in this knowledge base to a real-world implementation scenario.

---

## Source Provenance

| Source | Files |
|--------|-------|
| Claude | `22_Labs/`, `23_Case_Studies/` |
| ChatGPT | Various practical examples across topic files |
| Gemini | Practical examples (mirrors ChatGPT) |


# Getting Started Guide for Users — Complete Markdown Edition

> **Original PDF:** `Getting_Started_Guide_for_Users.pdf` | **Folder:** Level 1 (Beginner & Foundations)  
> **Purpose:** Definitive Markdown guide for financial planners and end-users on navigating the Redwood Springboard, working with data forms, runtime prompts, ad-hoc analysis, and approval workflows.

---

## Table of Contents
1. [Navigating the Redwood Springboard & Navigation Flows](#redwood-navigation)
2. [Working with Data Entry Forms & Grid Shortcuts](#working-with-forms)
3. [Executing Business Rules & Runtime Prompts (RTPs)](#executing-rules)
4. [Approvals Workflow & Task Lists](#approvals-workflow)
5. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Navigating the Redwood Springboard & Navigation Flows <a name="redwood-navigation"></a>

The Oracle EPM Cloud user experience centers around the **Springboard** (Home page) and **Cards/Clusters** configured specifically for each functional role (`Financial Analyst`, `HR Planner`, `Sales Manager`).

### Key User Navigation Elements
- **Home / Springboard:** Displays top-level functional clusters (`Financials`, `Workforce`, `Reports`, `Tasks`).
- **Announcements Banner:** Displays critical close deadlines or upcoming maintenance notices.
- **Recent / Favorites (`Star Icon`):** Allows planners to bookmark frequently accessed forms or reports for 1-click navigation.

---

## 2. Working with Data Entry Forms & Grid Shortcuts <a name="working-with-forms"></a>

When opening a web form (`e.g., Department Operating Expenses`), users interact with Essbase data blocks through standard grid conventions:

### Grid Color & Cell Status Indicators
| Cell Background / Marker | Meaning & User Guidance |
| :--- | :--- |
| **White Background** | **Editable Cell:** Standard read/write input cell. Enter number and press `Tab`. |
| **Gray Background (`#NoAccess` / `#ReadOnly`)** | **Read-Only Cell:** Calculated formula (`Dynamic Calc`), parent rollup line, or restricted by Cell-Level Security. |
| **Yellow / Tan Background (`Dirty Flag`)** | **Unsaved Change:** Number has been typed or modified by the user but has **not yet been saved/submitted** to Essbase. Click **Save** (`Ctrl + Alt + S`). |
| **Blue Triangle in Upper-Right Corner** | **Cell Note / Comment:** Contains text commentary attached to the data intersection. Click or hover to view note. |
| **Red Triangle / Border** | **Validation Error:** Cell value violates an attached validation rule (`e.g., Expense exceeds budget cap`). Form save is blocked until corrected. |

---

## 3. Executing Business Rules & Runtime Prompts (RTPs) <a name="executing-rules"></a>

Business Rules (`Actions -> Business Rules`) execute calculations across the database (`e.g., Calculate Revenue`, `Allocate Overhead`).

### Runtime Prompts (RTPs)
When a rule requires user input (`e.g., selecting Target Year and Entity`), a modal dialog appears:
- **Member Selector (`Magnifying Glass`):** Allows searching by member name or alias (`e.g., CC_101 - IT Operations`).
- **Validation Guard:** The system checks that the selected member matches the variable's scope (`Level 0 only`).

---

## 4. Approvals Workflow & Task Lists <a name="approvals-workflow"></a>

- **Task Lists / EPM Tasks:** Sequential step-by-step checklists assigned to planners during the financial close or budget cycle (`Step 1: Enter Opex -> Step 2: Run Allocation -> Step 3: Sign Off`).
- **Approvals (`Promote / Reject`):** Locks department data (`Entity`) so planners cannot modify numbers while the budget is under review by the Corporate Controller.

---

## 5. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`04_Forms/01_Forms_Design_and_Properties.md`** — Form layout, grid shortcuts, and cell formatting.
- **`06_Business_Rules/03_Runtime_Prompts_in_Rules.md`** — RTP variables and execution behavior.
- **`12_Security/01_Security_Complete_Guide.md`** — User roles and workflow approvals.

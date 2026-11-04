# Oracle EPM Cloud: The Ultimate Master Guide to Approval Flows

## 1. Introduction: What is an Approval Flow—
An Approval Flow in Oracle EPM Cloud is a structured, systematic process for reviewing and approving data (usually a Budget or Forecast). It tracks the status of data slices (known as **Planning Units**) as they move up the organizational hierarchy from preparers, to reviewers, to final executives. 

During this process, the system dynamically locks and unlocks data to ensure that once a user submits their budget, they can no longer alter the numbers while it is under review.

---

## 2. Core Concepts

### Planning Units
A Planning Unit is the fundamental slice of data being approved. It is defined by a specific Scenario, Version, and Entity (e.g., *Budget -> Working -> Sales Department*).

### The Approval Actions
As a Planning Unit moves through the flow, users perform actions:
* **Promote:** The owner submits the data to the next person in the hierarchy. The current owner loses write-access.
* **Reject:** A reviewer sends the data back down to the previous owner for revision. Write-access is returned to the lower-level user.
* **Sign Off:** A reviewer approves the data but passes it up for further review.
* **Approve:** The final step. The data is locked for everyone except Service Administrators.

### Types of Approval Paths
1. **Bottom-Up (Standard):** Planners enter data at the lowest base entities and promote it upwards to parent reviewers.
2. **Top-Down:** High-level executives set targets at parent entities and push them down to base planners.
3. **Free-Form:** A non-hierarchical process where users can assign ownership to anyone else on the fly.

---

## 3. Front End vs. Back End Operations

### Front End
* **Configuration:** Administrators navigate to **Navigator > Workflow > Approvals** to define the Planning Unit Hierarchy (PUH), assign owners/reviewers, and set the promotional path.
* **Execution:** End-users interact with the **Manage Approvals** card on their home screen or click the "Approvals" icon directly inside a Data Form to promote their specific unit.

### Back End
* **Migration:** Approval hierarchies are migrated via LCM under the "Planning Unit Hierarchy" artifact.
* **Automation:** Administrators can use EPM Automate or Business Rules (via a Task Type) to automatically start, stop, or mass-promote planning units across the organization.

---

## 4. What Senior Consultants Expect You to Know (Architecture & Limitations)

> [!CAUTION]
> **The Security Override Phenomenon**
> This is the most critical concept for Approval Flows: **Ownership dictates write access.** Even if a user has standard "Write" access to the "Sales" entity via Access Control, if they do not currently *Own* the Planning Unit in the Approval Flow (e.g., they promoted it to their boss), their access is temporarily downgraded to "Read-Only". Seniors expect you to explain this to panicking users who suddenly "can't type in the form."

> [!IMPORTANT]
> **Validation Rules and Approvals**
> Seniors expect Approval Flows to be tightly integrated with **Data Validation Rules**. You can configure the system to *prevent* a user from promoting a Planning Unit if certain conditions aren't met (e.g., "Error: Net Income is negative. You cannot promote this budget."). This ensures data quality before it reaches executive review.

> [!TIP]
> **Out of Office / Delegation**
> If a manager goes on vacation, the approval chain stalls. Seniors expect you to configure **Delegation** or set an "Out of Office" assistant in the user preferences so planning units automatically route to a designated backup reviewer.

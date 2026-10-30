# 🏠 Oracle Cloud EPM — Planning Landing Page
## Complete Screen Reference

> **Navigation Path:** `Login → EPM Cloud Home → Planning (Business Process Card)`  
> **URL Pattern:** `https://<your-instance>.epm.us2.oraclecloud.com/epmcloud/`  
> **Required Role:** Service Administrator  
> **Screen Appears:** Only when NO application exists in the Planning business process

---

## 📸 Screen Layout Description

The Planning Landing Page is displayed when a Service Administrator first accesses a fresh (or reset) Planning business process. The page has a clean, centered layout with the following elements:

### Header Bar
| Element | Description | Location |
|---------|-------------|----------|
| **Oracle Logo** | Oracle branding logo | Top-left corner |
| **Title Bar** | "Fusion Cloud Enterprise Performance Management (EPM) Enterprise Service" | Top bar, left-aligned |
| **User Menu** | Displays logged-in user name (e.g., "Demo Adams ▼") | Top-right corner |
| **Settings Gear** ⚙️ | Access to environment-level settings | Top-right, next to user menu |

### Main Content Area

#### Title Section
- **Page Title:** "Planning" — displayed in large serif font, centered at top of content area

#### Three-Column Layout
The page presents **three equal columns**, each representing a distinct path:

---

### Column 1: Create a Sample Application

| Element | Details |
|---------|---------|
| **Icon** | 📦 Four overlapping squares icon (represents pre-built content) |
| **Heading** | "Create a sample application" |
| **Description** | "Check out how a built out solution looks by creating a sample application" |
| **Button** | **[CREATE]** — Black rectangular button, white text |
| **Purpose** | Creates the pre-built "Vision" sample application |

**What Happens When You Click CREATE:**
1. System immediately begins creating the Vision sample application
2. A confirmation dialog may appear asking you to confirm
3. The system provisions dimensions, forms, rules, data, and reports
4. Process takes 5–15 minutes depending on system load
5. Once complete, you are redirected to the Application Home page

> [!NOTE]
> The Vision sample application is a fully functional Planning application pre-loaded with demonstration data, forms, business rules, dashboards, and reports. It is designed for learning and exploration.

---

### Column 2: Create a New Application

| Element | Details |
|---------|---------|
| **Icon** | 📋 Document with sparkle/star icon (represents new creation) |
| **Heading** | "Create a new application" |
| **Description** | "Jump right in and start creating your own application" |
| **Button** | **[START]** — Black rectangular button, white text |
| **Purpose** | Launches the multi-step Application Creation Wizard |

**What Happens When You Click START:**
1. Opens the Application Creation Wizard
2. Walks through multiple configuration screens
3. Allows you to choose application type (Planning/Modules/FreeForm)
4. Configures calendar, currency, and dimensions
5. Creates a blank application based on your specifications

> [!IMPORTANT]
> This is the primary path for building production applications. Choose this when you want to configure your application from scratch according to your organization's requirements.

---

### Column 3: Migrate

| Element | Details |
|---------|---------|
| **Icon** | 📥 Download/import arrow icon (represents importing content) |
| **Heading** | "Migrate" |
| **Description** | "Create your application by uploading a snapshot" |
| **Button** | **[MIGRATE]** — Black rectangular button, white text |
| **Purpose** | Imports an existing application from a snapshot file |

**What Happens When You Click MIGRATE:**
1. Opens the Snapshot Upload interface
2. Allows you to browse and upload a `.zip` snapshot file
3. The system extracts and imports all application artifacts
4. Creates the application based on the snapshot contents

> [!TIP]
> Use this path when:
> - Restoring from a backup
> - Moving an application between environments (Dev → Test → Prod)
> - Importing a pre-configured application template

---

### Bottom Section: Promotional Content

| Element | Details |
|---------|---------|
| **Section Title** | "Completely Agile" |
| **Description** | "Oracle Fusion Cloud EPM is the most complete and connected EPM solution to give you the agility you need to outperform in today's constantly evolving business landscape." |
| **Video Player** | "Tour of Enterprise" — Embedded video walkthrough of Oracle EPM features |
| **Video Controls** | Sound toggle 🔊, Closed captions [CC], Settings ⚙️ |

---

## 🔒 Access Requirements

| Requirement | Details |
|-------------|---------|
| **Role** | Service Administrator |
| **URL Access** | Must have valid Oracle Cloud EPM subscription URL |
| **Browser** | Chrome (recommended), Firefox, Edge (Chromium-based) |
| **Identity Domain** | User must be registered in the associated Identity Domain |
| **Environment Status** | Planning business process must have NO existing application |

---

## ⚡ Key Behaviors

### One-Time Page
- This page appears **ONLY ONCE** per environment lifecycle
- After ANY application is created, this page is **permanently replaced** by the Application Home page
- To see this page again, you must perform **Remove and Recreate** on the entire service instance

### Button States
- All three buttons (CREATE, START, MIGRATE) are active simultaneously
- Clicking any button is **irreversible** without environment reset
- No confirmation dialog before proceeding (in most versions)

### Session Requirements
- Active authenticated session required
- Session timeout typically 60 minutes of inactivity
- Multiple administrators can view this page but only ONE can initiate creation

---

## 📊 Decision Matrix: Which Path to Choose?

| Factor | CREATE (Sample) | START (New) | MIGRATE |
|--------|----------------|-------------|---------|
| **Time to Productive** | ⚡ 15 min | ⏳ Hours/Days | 🔄 30 min |
| **Customization Level** | None (pre-built) | Full control | Based on source |
| **Learning Curve** | Low | Medium-High | Depends |
| **Production Ready** | ❌ No | ✅ Yes | ✅ Yes |
| **Pre-loaded Data** | ✅ Yes | ❌ No | Based on source |
| **Pre-built Forms** | ✅ Yes | ❌ No | Based on source |
| **Pre-built Rules** | ✅ Yes | ❌ No | Based on source |
| **Best For** | Learning/Demo | Fresh implementations | Environment migration |

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: When does the Planning Landing Page appear, and why does it disappear once an application exists?
**Answer:** The Planning Landing Page appears **only when an environment container contains ZERO applications** (freshly provisioned or reset via ecreate -f). In Oracle Cloud EPM, each business process pod hosts exactly **one active application**. Once an application is created (via Sample, Wizard, or Migration), the Landing Page is permanently replaced by the Application Home Page. To see the Landing Page again, the application must be dropped.

### Q2: Can a user with the "User" or "Power User" role access the Landing Page?
**Answer:** No. Standard Users and Power Users logging into a clean instance will receive an authorization notice: *"No application is available. Please contact your Service Administrator."* Only users assigned the **Service Administrator** predefined role in Identity Domain (OCI IAM / IDCS) are authorized to view the Landing Page and initiate application creation.

### Q3: If an administrator clicks START by mistake, can they safely return to the clean Landing Page?
**Answer:** Yes. As long as the administrator does not click the final **[Create]** button on Step 5 of the wizard, clicking **[Cancel]** at any step immediately aborts the wizard and returns the browser to the pristine Landing Page without making any changes to the database.

---

## 🔗 Next Steps by Path

| If You Choose... | Continue To |
|------------------|-------------|
| **CREATE** | → [Sample Application Overview](./01_Create_Sample_Application/01_Sample_Application_Overview.md) |
| **START** | → [New Application Wizard](./02_Create_New_Application_Wizard/01_Wizard_Overview_and_Prerequisites.md) |
| **MIGRATE** | → [Migration Overview](../03_Migrate_Application_from_Snapshot/01_Migration_Concepts_and_Payload_Architecture.md) |

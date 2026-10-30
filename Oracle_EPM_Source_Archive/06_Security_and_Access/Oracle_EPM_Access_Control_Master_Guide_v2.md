# Oracle EPM Cloud: The Ultimate Master Guide to Access Control

## 1. Introduction to Security
Access Control in Oracle EPM Cloud governs who can log in, what they can see, and what actions they can perform. Oracle EPM uses a multi-layered security model that combines identity management, predefined roles, group assignments, and dimensional cell-level security.

---

## 2. Layers of Security

### Identity Domain / Predefined Roles
Access begins at the Oracle Cloud Infrastructure (OCI) Identity and Access Management (IAM) level. Users are assigned one of four predefined roles:
1. **Service Administrator:** Full access to all features, security, and metadata. Can create applications and manage all artifacts.
2. **Power User:** Departmental admins. Can create forms, dashboards, and business rules, and manage data for their assigned areas.
3. **User:** Standard data entry role. Can view forms, enter data, and launch rules, but cannot create or modify artifacts.
4. **Viewer:** Read-only access. Can view data in forms and dashboards but cannot save data or run calculations.

### Groups
*(Navigation: Tools > Access Control)*
Instead of assigning access individually, administrators create **Groups** (e.g., "Finance_Team", "NA_Planners"). Users are assigned to these groups, and the groups are assigned access to the application.

### Artifact Security
Artifact security determines whether a user can see a specific Form, Dashboard, Rule, or Task List.
* You assign `Read`, `Write`, or `None` access to a folder or an individual artifact.
* Note: `Write` access to a Form allows a Power User to *edit the form's design*, not just enter data.

### Data Security (Cell-Level Security)
Even if a user can open a Form, they may not be allowed to see the data inside it.
* **Dimension Security:** Access is granted at the member level (e.g., User can read "Sales" but not "Payroll").
* **Cell-Level Security:** Advanced, highly granular security that restricts access based on a specific *intersection* of dimensions (e.g., User can see "Sales" for "Q1" but not "Sales" for "Q2").

---

## 3. Front End vs. Back End Operations

### Front End
* **Navigation:** **Tools > Access Control** (For Groups and Roles).
* **Navigation:** **Navigator > Dimensions** (To apply read/write access to specific dimension members).
* **Assigning Access:** In the Artifact repository, administrators click on a folder/form, select "Assign Access," and add the relevant Groups.

### Back End
* **Migration:** Security is heavily split in LCM (Migration).
  * *Groups:* Migrated via the "Groups and Membership" artifact.
  * *Artifact Security:* Embedded within the "Planning" artifact exports.
  * *Dimension Security:* Migrated via the "Secadmin" artifact.
* **EPM Automate:** Security provisioning is typically automated using `epmautomate assignrole` and `epmautomate importsecurity` in conjunction with an active directory sync.

---

## 4. What Senior Consultants Expect You to Know

> [!CAUTION]
> **The "No Direct Assignment" Rule**
> Senior architects will instantly reject any design that assigns artifact or data security directly to an individual User. **Always assign security to Groups**. If an employee leaves, you simply swap them out of the Group in Identity Management, rather than hunting down 400 forms to remove their individual name.

> [!IMPORTANT]
> **Security Evaluation Precedence**
> If a user belongs to two groups, and Group A has `Read` access to a member, but Group B has `Write` access to the same member, the user gets the **least restrictive** access (`Write`). 
> *However*, if a user has `Read` access to a member, but a Cell-Level Security rule explicitly restricts that specific intersection to `None`, the Cell-Level Security rule overrides everything else.

> [!TIP]
> **Power Users and Security**
> A Power User cannot create a form and assign it to someone else unless they themselves have access to the dimension members within that form. Power Users are bound by the same data security rules as standard users.

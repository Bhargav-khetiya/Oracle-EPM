# 📚 Official Oracle Documentation Sources Register

This register catalogues the official Oracle Cloud EPM, Essbase, and Groovy documentation sources utilized as the authoritative benchmark for all technical configurations, architectural descriptions, syntax rules, and error codes documented in this repository.

---

## 1. Master Documentation Queue & Status

| Source Title | Product / Module | Official Oracle Documentation URL | Scope & Topics Supported | Verification Status |
| :--- | :--- | :--- | :--- | :---: |
| **Administering Planning** | Oracle EPM Cloud Planning | [docs.oracle.com/.../pfusc](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/index.html) | Application creation wizard, calendar setups, multi-currency, web forms, valid intersections, approval unit hierarchies. | `reviewed & used` |
| **Administering Data Integration for Oracle Enterprise Performance Management Cloud** | Data Integration / Management (FDMEE) | [docs.oracle.com/.../diepm](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/diepm/index.html) | Source systems, import formats, location mappings, mapping types (Explicit, Like, In, Between, Multi-Dim), EPM Integration Agent. | `reviewed & used` |
| **Administering Calculation Manager for Oracle Enterprise Performance Management Cloud** | Calculation Manager & Essbase | [docs.oracle.com/.../cmcmd](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/cmcmd/index.html) | Visual flowchart canvas, 8 palette objects, 8 system templates, design-time prompts (DTP), runtime prompts (RTP), variable scopes. | `reviewed & used` |
| **Oracle Essbase Technical Reference & Functions Guide** | Essbase Calculation & Storage Kernel | [docs.oracle.com/.../esb_tech_ref](https://docs.oracle.com/en/database/other-databases/essbase/21/esbtr/index.html) | BSO vs ASO kernel physics, block allocation, .pag/.ind file layout, SET commands, 400+ Essbase calc functions. | `reviewed & used` |
| **Oracle EPM Cloud Groovy Rules Java API Reference** | Planning Groovy JVM Sandbox | [docs.oracle.com/.../epm_groovy](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/groov/index.html) | `DataGridDefinition`, `DataGridBuilder`, `throwVetoException`, edited cell iterations, dynamic micro-FIX generation. | `reviewed & used` |
| **Administering Migration for Oracle Enterprise Performance Management Cloud** | Lifecycle Management (LCM) | [docs.oracle.com/.../dsepm](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/dsepm/index.html) | Artifact snapshots, clone environments, daily maintenance backup window, object storage restoration. | `reviewed & used` |
| **Working with EPM Automate for Oracle Enterprise Performance Management Cloud** | Headless CLI / DevOps | [docs.oracle.com/.../cepma](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/cepma/index.html) | Installation, encrypted passwords, OAuth token authentication, batch runbooks, return codes (0, 1, 6, 7). | `reviewed & used` |
| **Working with Oracle Smart View for Office** | Microsoft Office 365 Add-In | [docs.oracle.com/.../svrep](https://docs.oracle.com/en/applications/enterprise-performance-management/smart-view/index.html) | Ad-hoc grid operations, flex forms, cell formatting, Smart View options, VBA automation API (`HypConnect`). | `reviewed & used` |
| **Administering Financial Consolidation and Close (FCCS)** | Financial Close & Consolidations | [docs.oracle.com/.../fcsad](https://docs.oracle.com/en/cloud/saas/financial-consolidation-cloud/fcsad/index.html) | Consolidation rules, intercompany eliminations, currency translation adjustments (CTA), comparison with Planning. | `reviewed & used` |
| **Administering FreeForm Planning** | FreeForm Planning Cubes | [docs.oracle.com/.../freeform](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/freeform/index.html) | Outline import, unconstrained dimensionality (no mandatory Entity/Scenario), custom BSO/ASO cubes. | `reviewed & used` |
| **Designing with Financial Reporting for Oracle Enterprise Performance Management Cloud** | Financial Reporting (FR) / Books | [docs.oracle.com/.../frrep](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/frrep/index.html) | Book building, batch bursting, FR grid suppressions, migration to Reports. | `reviewed & used` |
| **Oracle Cloud Infrastructure (OCI) IAM / IDCS Identity Guide** | Cloud Identity & Access Management | [docs.oracle.com/.../iam](https://docs.oracle.com/en-us/iaas/Content/Identity/home.htm) | Predefined functional roles (Service Admin, Power User, User, Viewer), SAML 2.0 SSO, MFA, identity domains. | `reviewed & used` |

---

## 2. Topic-to-Source Mapping Matrix

| Architecture Topic | Primary Official Source | Key Verification Chapters |
| :--- | :--- | :--- |
| **Application Wizard Properties** | *Administering Planning* | Chapter 3: Creating an Application (General, Calendar, Currency) |
| **Essbase Block Physics & Caches** | *Essbase Technical Reference* | Architecture Guide: Block Storage, Page Files, Cache Sizing |
| **Groovy Dynamic micro-FIX** | *EPM Cloud Groovy Rules API* | Package `com.hyperion.planning.scripting` |
| **Data Load Mapping Types** | *Administering Data Integration* | Mapping Types: Explicit, Like, Between, In, Multi-Dimension |
| **Smart Push Buffer Streaming** | *Administering Planning* | Data Exchange: Configuring Smart Push & Slice Merging |
| **Headless Batch Scripting** | *Working with EPM Automate* | Command Reference: `uploadfile`, `importdata`, `runbusinessrule` |
| **Cross-Module Pre-Built Mesh** | *Administering Planning (Modules)* | Configuring Financials, Workforce, Capital, Projects |

---

## 3. Standards for Citing and Labeling Project Documentation

To maintain the highest level of rigor during technical reviews, all documentation in this repository strictly separates claims into four unambiguous tiers:

1. **Oracle-Documented Product Behavior**:
   - Facts verified against official Oracle documentation (e.g., *"Sandboxes cannot be enabled on an application after creation"*).
   - Documented with citations to the official guide.
2. **Project-Specific Configuration**:
   - Design choices specific to an implementation (e.g., *"Financials uses a 4-4-5 retail calendar starting in February"*).
   - Marked clearly as project configuration.
3. **Best Practice / Recommendation**:
   - Design rules established by senior architects (e.g., *"Dense block size should remain between 50KB and 250KB"*).
   - Supported by mathematical proofs and operational trade-offs.
4. **Unresolved Question / Unknown**:
   - Facts requiring customer confirmation or pending architecture board decisions (e.g., *"Pending client confirmation of EPM Integration Agent server location"*).
   - Explicitly logged in [`PROJECT_DECISIONS_AND_ASSUMPTIONS_REGISTER.md`](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/PROJECT_DECISIONS_AND_ASSUMPTIONS_REGISTER.md).


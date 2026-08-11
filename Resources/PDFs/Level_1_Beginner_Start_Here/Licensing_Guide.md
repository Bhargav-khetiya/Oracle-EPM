# Licensing Guide for Oracle EPM Cloud — Complete Markdown Edition

> **Original PDF:** `Licensing_Guide.pdf` | **Folder:** Level 1 (Beginner & Foundations)  
> **Purpose:** Comprehensive Markdown extraction of Oracle EPM Cloud subscription tiers, Standard vs. Enterprise licensing boundaries, custom cube limits, and auditing compliance.

---

## Table of Contents
1. [EPM Standard vs. EPM Enterprise Subscription Tiers](#subscription-tiers)
2. [Custom Cube Boundaries & Application Limits](#cube-boundaries)
3. [User Metric Licensing vs. Hosted Employee Licensing](#licensing-metrics)
4. [EDMCS Record Limits & OOTB Module Activation](#edmcs-limits)
5. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. EPM Standard vs. EPM Enterprise Subscription Tiers <a name="subscription-tiers"></a>

Oracle licenses EPM Cloud under two distinct SaaS SKUs: **Oracle EPM Standard Cloud Service** and **Oracle EPM Enterprise Cloud Service**.

| Functional Capability | EPM Standard Cloud Service | EPM Enterprise Cloud Service |
| :--- | :--- | :--- |
| **Planning Modules** | Capital, Workforce, Financials, Projects (`Standard Features`) | **All Modules + Advanced Planning** (`Strategic Workforce, Predictive Cash, Sales Planning`) |
| **Custom / FreeForm Cubes** | Max **1 Custom Cube** per application (`Must have standard 6 dimensions`) | **FreeForm Cubes (`SaaS Essbase`)** (`Zero required dimensions, up to 26 custom dimensions per app`) |
| **Financial Consolidation (FCCS)** | Included (`Standard Consolidation`) | Included + **Enterprise Consolidations** (`Custom ownership rules, advanced journals`) |
| **Account Reconciliation (ARCS)** | Included (`Reconciliation Compliance only`) | Included + **Transaction Matching** (`Automated high-volume matching engine`) |
| **Enterprise Data Management (EDMCS)** | ❌ **Not Included** | ✅ **Included** (`Up to 5,000 hosted node records across viewpoints`) |
| **Groovy Business Rules** | ❌ **Not Included** (`Basic Calc Scripts only`) | ✅ **Included** (`Full EPM Groovy API, REST execution, DataGridBuilder`) |
| **IPM Insights & Auto-Predict AI** | ❌ **Not Included** | ✅ **Included** (`Native ML models, anomaly detection`) |

---

## 2. Custom Cube Boundaries & Application Limits <a name="cube-boundaries"></a>

### Standard Cloud Boundaries
- If a customer purchases **EPM Standard**, their Planning application can contain the 4 OOTB modules (`FinPlan`, `Workforce`, `Capex`, `Projects`) PLUS **exactly one custom BSO or ASO cube**.
- **Architect Legal Warning:** Attempting to build a second custom cube or writing Groovy scripts on an EPM Standard license violates Oracle SaaS licensing terms and triggers audit penalties during annual reviews.

### Enterprise Cloud Boundaries
- Allows deployment of unlimited **FreeForm applications** across allocated pods, provided total hosted user metrics are licensed correctly.

---

## 3. User Metric Licensing vs. Hosted Employee Licensing <a name="licensing-metrics"></a>

Oracle enforces licensing through two primary metrics:
1. **Hosted Named User (HNU):** Individual human login accounts (`Service Admin, Power User, User, Viewer`). Each human must have a unique identity domain seat.
2. **Hosted Employee Metric (HE):** Used for large-scale enterprise deployments (`e.g., Strategic Workforce Planning where 50,000 employees are modeled`). Licensed based on total corporate headcount rather than named login accounts.

---

## 4. EDMCS Record Limits & OOTB Module Activation <a name="edmcs-limits"></a>

- **EDMCS Inclusion in Enterprise SKU:** Includes up to **5,000 unique node records** (`Members`). If an enterprise manages 50,000 total Cost Centers, Accounts, and SKUs across their viewpoints, they must purchase **Additional EDMCS Record Packs**.

---

## 5. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`00_Foundation/01_EPM_Foundations.md`** — Subscription tiers and product packaging.
- **`16_Administration/03_Admin_Specialized_Deep_Reference.md`** — Detailed legal boundaries and licensing audit rules.
- **`24_Architect_Masterclass/10_FreeForm_Cubes_GenAI_and_Future_Architecture.md`** — FreeForm vs Standard licensing decisions.

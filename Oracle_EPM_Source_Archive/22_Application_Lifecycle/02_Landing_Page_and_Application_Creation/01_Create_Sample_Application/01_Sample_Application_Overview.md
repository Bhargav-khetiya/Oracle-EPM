﻿# 📦 Path 1: Create a Sample Application
## Overview & Purpose

> **Navigation:** `Planning Landing Page → CREATE button`  
> **What It Does:** Creates the pre-built "Vision" sample application  
> **Time Required:** 5–15 minutes (automated process)  
> **Reversible:** ❌ No — requires environment reset to remove

---

## 🎯 Purpose of Sample Applications

The **CREATE** button on the Planning Landing Page creates Oracle's pre-built **Vision** sample application. This is a **fully functional, production-quality** Planning application loaded with:

- ✅ Complete dimension hierarchies
- ✅ Sample transactional data
- ✅ Pre-built data entry forms
- ✅ Configured business rules (Calc Manager scripts)
- ✅ Dashboards and reports
- ✅ Task lists
- ✅ Security role assignments
- ✅ Approval process workflows
- ✅ Smart Lists and member formulas

---

## 🤔 When to Use This Path

### ✅ Use CREATE When:
| Scenario | Reason |
|----------|--------|
| Learning Oracle Cloud EPM for the first time | Get a working app immediately to explore features |
| Training new team members | Pre-built content serves as teaching material |
| Demonstrating EPM capabilities to stakeholders | Professional-quality demo environment |
| Exploring best practices | Vision follows Oracle's recommended design patterns |
| Testing features before building production app | Safe sandbox to experiment |
| Preparing for certification exams | Practice with realistic application structure |

### ❌ Do NOT Use CREATE When:
| Scenario | Better Alternative |
|----------|-------------------|
| Building a production application | Use **START** instead |
| Need organization-specific structure | Use **START** instead |
| Migrating from an existing system | Use **MIGRATE** instead |
| Have limited time and need exact structure | Use **MIGRATE** with a template |

---

## ⚠️ Important Warnings

> [!CAUTION]
> **Permanent Decision:** Once you click CREATE, the Vision sample application occupies your entire Planning environment. You cannot create another application alongside it. To remove it, you must perform "Remove and Recreate" on the service instance (destroys ALL data).

> [!WARNING]
> **Not for Production:** The Vision sample application is intended for learning only. While technically functional, it uses generic dimension structures (Vision Corporation, Product lines, etc.) that do not match your organization.

> [!NOTE]
> **Single Environment:** If you have separate Development, Test, and Production environments, consider creating the Vision sample in your Development environment for learning, while using START for Test/Production.

---

## 📋 What's Included in Vision

### Dimensions Created
| Dimension | Type | Description | Sample Members |
|-----------|------|-------------|----------------|
| Account | Account | Financial accounts hierarchy | Revenue, COGS, Operating Expenses, Net Income |
| Entity | Entity | Organizational units | Vision Corp, US Operations, Europe, Asia Pacific |
| Period | Period | Time periods | Jan–Dec, Q1–Q4 |
| Year | Year | Fiscal years | FY20–FY27 |
| Scenario | Scenario | Planning scenarios | Actual, Budget, Forecast |
| Version | Version | Data versions | Working, Final |
| Currency | Currency | Reporting currencies | USD, EUR, GBP |
| Product | Custom | Product lines | Hardware, Software, Services |
| Market | Custom | Geographic markets | Americas, EMEA, APAC |

### Pre-built Forms (Typical)
- Revenue Planning Form
- Expense Planning Form  
- Balance Sheet Form
- Cash Flow Form
- Headcount Planning Form
- Capital Expense Form

### Pre-built Business Rules
- Revenue Calculation
- Expense Rollup
- Currency Translation
- Data Copy (Actual to Forecast)
- Allocation Rules

### Pre-built Dashboards
- Executive Summary Dashboard
- Revenue Analysis
- Expense Tracking
- Variance Analysis

---

## 🔗 Next Steps

| Document | Description |
|----------|-------------|
| [Vision Sample Creation Steps](./02_Vision_Sample_Creation_Walkthrough.md) | Step-by-step creation walkthrough |
| [Vision Sample Contents](./03_Vision_Sample_Contents_and_Artifacts.md) | Detailed contents and structure |
| [Post-Creation Walkthrough](./04_Post_Sample_Creation_Walkthrough.md) | Exploring the app after creation |

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: Can an enterprise convert the Vision sample application into a production application by clearing sample data—
**Answer:** Technically yes, but **architecturally strongly discouraged**. While you can execute epmautomate clearcube to wipe sample transactional numbers, Vision uses fixed, generic dimensions (Vision Corp, Hardware/Software product lines) and standard calendars that rarely match corporate charts of accounts. Building a production app via **START** or importing a purpose-built template ensures clean naming, correct dense/sparse sizing, and tailored dimension hierarchies.

### Q2: Can an administrator rename the Vision application or add custom dimensions during its creation—
**Answer:** No. The **CREATE** button executes a fully automated, unattended one-click deployment. It does not display configuration screens. The application name is hardcoded as Vision, and all dimension names, cube definitions, and forms are pre-packaged. Custom dimensions can only be added post-creation via Dimension Management.

### Q3: What happens if an organization needs to evaluate multiple sample solutions (e.g. Planning vs Financial Consolidation)—
**Answer:** Because each Cloud EPM instance supports only one application at a time, you must evaluate Vision in Planning, then execute epmautomate recreate -f TempServiceType=FCCS to wipe Planning and spin up a sample Financial Consolidation application.

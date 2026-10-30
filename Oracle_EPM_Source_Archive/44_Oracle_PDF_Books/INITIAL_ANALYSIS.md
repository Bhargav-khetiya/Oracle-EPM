# 📊 INITIAL ANALYSIS — Oracle EPM Documentation Catalog

> **Generated:** August 16, 2026  
> **Source Catalogs Parsed:** 4  
> **Total Documents Found:** 79  
> **Unique After Dedup:** 54  
> **Selected for Core Study:** 25  
> **Selected for Reference:** 18  
> **Do Not Study Now:** 11  

---

## 1. Source Catalog Summary

| Source | URL | Books Listed |
|--------|-----|-------------|
| Cloud EPM Planning | docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/books.html | 38 |
| Cloud EPM FreeForm | docs.oracle.com/en/cloud/saas/freeform/books.html | 26 |
| Essbase 21c | docs.oracle.com/en/database/other-databases/essbase/21/books.html | 16 |
| Essbase 26ai | docs.oracle.com/en/database/other-databases/essbase/26/books.html | 15 |
| **Total Raw** | | **95** |
| **After Dedup** | | **54 unique** |

---

## 2. Duplicate Analysis

### Shared EPM Platform Docs (appear on BOTH Planning & FreeForm pages)
These are identical documents served from the `enterprise-performance-management-common` path:

| Document | Appears On | Resolution |
|----------|-----------|------------|
| Getting Started Guide for Administrators | Planning, FreeForm | Keep 1 copy → 01_FOUNDATION |
| Getting Started Guide for Users | Planning, FreeForm | Keep 1 copy → 01_FOUNDATION |
| Creating and Running an EPM Center of Excellence | Planning, FreeForm | Keep 1 copy → 01_FOUNDATION |
| Deploying and Administering Smart View (Mac/Browser) | Planning, FreeForm, Essbase 21c, 26ai | Keep 1 copy → 05_SMART_VIEW |
| Getting Started with Smart View for Google Workspace | Planning, FreeForm | Keep 1 copy → 05_SMART_VIEW |
| Working with Smart View for Office 26.100 | Planning, FreeForm, Essbase 21c, 26ai | Keep 1 copy → 05_SMART_VIEW |
| Working with Smart View (Mac and Browser) | Planning, FreeForm, Essbase 21c, 26ai | Keep 1 copy → 05_SMART_VIEW |
| Working with Smart View for Google Workspace | Planning, FreeForm | Keep 1 copy → 05_SMART_VIEW |
| Designing with Calculation Manager | Planning, FreeForm | Keep 1 copy → 04_CALCULATION_MANAGER |
| Designing with Financial Reporting Web Studio | Planning, FreeForm | Keep 1 copy → 15_ADVANCED_REFERENCE |
| Administering Access Control | Planning, FreeForm | Keep 1 copy → 08_SECURITY |
| Administering Data Management | Planning, FreeForm | Keep 1 copy → 07_DATA_INTEGRATION |
| Administering Migration | Planning, FreeForm | Keep 1 copy → 09_MIGRATION |
| Operations Guide | Planning, FreeForm | Keep 1 copy → 13_OPERATIONS |
| Working with EPM Automate | Planning, FreeForm | Keep 1 copy → 10_EPM_AUTOMATE |
| Licensing Guide | Planning, FreeForm | Keep 1 copy → 99_DO_NOT_STUDY_NOW |
| Accessibility Guide | Planning, FreeForm | Keep 1 copy → 99_DO_NOT_STUDY_NOW |
| Design Best Practices | Planning | Keep → 01_FOUNDATION |
| Designing with Reports | Planning, FreeForm | Keep 1 copy → 15_ADVANCED_REFERENCE |
| Working with Reports | Planning, FreeForm | Keep 1 copy → 15_ADVANCED_REFERENCE |
| Working with Financial Reporting | Planning, FreeForm | Keep 1 copy → 15_ADVANCED_REFERENCE |

### Essbase Version Overlap (21c vs 26ai)
| Document | 21c | 26ai | Resolution |
|----------|-----|------|------------|
| Getting Started with Oracle Essbase | ✅ | ✅ | Use **26ai** (newer, compatible concepts) |
| Database Administrator's Guide | ✅ | ✅ | Use **26ai** (same core + updates) |
| Cube Designer User's Guide | ✅ | ✅ | Use **26ai** |
| Using the Essbase Web Interface | ✅ | ✅ | Use **26ai** |
| Scripting Reference | ✅ | ✅ | Use both (21c and 26ai have dedicated PDFs) |
| Configuration Reference | ✅ | ✅ | Use **26ai** → 99_DO_NOT_STUDY_NOW |
| Calculation and Query Reference | ✅ | ❌ | Use **21c** (only version with this PDF) |
| Essbase Independent Deployment | ✅ | ✅ | Both → 99_DO_NOT_STUDY_NOW |
| Essbase Stack Deployment on OCI | ✅ | ✅ | Both → 99_DO_NOT_STUDY_NOW |
| REST API for Essbase | ✅ | ✅ | HTML-only |
| Licensing Information | ✅ | ✅ | Both → 99_DO_NOT_STUDY_NOW |
| Java API Reference | ✅ | ❌ | → 99_DO_NOT_STUDY_NOW |
| MCP Server User's Guide | ❌ | ✅ | New in 26ai → 99_DO_NOT_STUDY_NOW |
| Release Notes | ✅ | ✅ | Both → 99_DO_NOT_STUDY_NOW |

---

## 3. Classification by Priority

See MASTER_INDEX.md for full classification details.

---

## 4. Download Plan

| Type | Count | Status |
|------|-------|--------|
| PDFs to download | 53 | Downloaded |
| LINK_ONLY files (HTML-only docs) | 3 | Created |
| **Total references** | **56** | |

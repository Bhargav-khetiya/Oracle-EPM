# Working with Oracle Smart View for Office (Mac and Browser) — Complete Markdown Edition

> **Original PDF:** `Working_with_Oracle_Smart_View_for_Office_(Mac_and_Browser).pdf` | **Folder:** Level 2 (Daily Usage)  
> **Purpose:** Complete Markdown extraction covering Microsoft Excel 365 (Mac, Web Browser, Windows JavaScript manifest) Smart View features and limitations.

---

## Table of Contents
1. [Mac & Web Browser Manifest Architecture](#manifest-architecture)
2. [Ad-Hoc, Flex Forms & Function Grid Limitations](#limitations)
3. [Troubleshooting Mac & Excel Online Connections](#troubleshooting)
4. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Mac & Web Browser Manifest Architecture <a name="manifest-architecture"></a>

Smart View Mac & Browser (`SV M&B`) runs as a centralized **Office 365 Web Add-In (`manifest.xml`)** deployed by corporate IT via Microsoft 365 Admin Center (`Integrated Apps`). It executes entirely inside a web sidebar pane.

---

## 2. Ad-Hoc, Flex Forms & Function Grid Limitations <a name="limitations"></a>

While SV M&B supports standard ad-hoc grids and form data entry, architects must know its exact limitations compared to native Windows COM Smart View:
- **No VBA Macro / SDK Access:** Microsoft Office web add-ins cannot execute VBA `smartview.bas` macros.
- **HsGetValue / HsSetValue Formula Support:** Supported, but requires the user to open the taskpane and manually trigger `Refresh Functions` due to browser sandbox restrictions.

---

## 3. Troubleshooting Mac & Excel Online Connections <a name="troubleshooting"></a>

- **Safari Third-Party Cookie Block:** On macOS Safari, users must disable `Prevent cross-site tracking` (`Safari -> Preferences -> Privacy`) so the EPM Cloud login token can bridge into the Excel taskpane iframe.

---

## 4. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`09_Smart_View/03_Smart_View_Specialized_Deep_Reference.md`** — Mac and Browser deployment architecture.
- **`24_Architect_Masterclass/08_The_Complete_Error_Code_Encyclopedia.md`** — Smart View client connection errors.

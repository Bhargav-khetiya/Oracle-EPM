# Getting Started with Oracle Smart View for Google Workspace — Complete Markdown Edition

> **Original PDF:** `Getting_Started_with_Oracle_Smart_View_for_Google_Workspace.pdf` | **Folder:** Level 2 (Daily Usage)  
> **Purpose:** Definitive Markdown guide for deploying and configuring Oracle Smart View add-on inside Google Sheets across enterprise Google Workspace environments.

---

## Table of Contents
1. [Architecture: Google Sheets Add-On vs. COM Add-In](#architecture)
2. [Deployment via Google Workspace Admin Console](#deployment)
3. [Connecting to EPM Cloud from Google Sheets](#connecting)
4. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Architecture: Google Sheets Add-On vs. COM Add-In <a name="architecture"></a>

Unlike Windows Excel Smart View (`COM/C++ add-in`), **Smart View for Google Workspace** is a pure HTML5/JavaScript add-on running inside the Google Sheets browser sidebar.

### Key Capabilities
- Multi-platform compatibility (`Windows, Mac, Chromebook`).
- Connects directly via OAuth 2.0 Identity Domain tokens.
- Supports ad-hoc grids, web form rendering, and cell submitting.

---

## 2. Deployment via Google Workspace Admin Console <a name="deployment"></a>

1. Access Google Workspace Admin Console (`admin.google.com`).
2. Navigate to `Apps -> Google Workspace Marketplace apps -> Add app to Domain Install list`.
3. Locate `Oracle Smart View for Office (Google Sheets)` and grant OAuth permissions across the corporate organizational unit (`OU`).

---

## 3. Connecting to EPM Cloud from Google Sheets <a name="connecting"></a>

1. Open a Google Sheet $\rightarrow$ click `Extensions -> Oracle Smart View -> Home`.
2. Enter the EPM Cloud URL (`https://your-domain.epm.ocs.oraclecloud.com`).
3. Complete IDCS multi-factor authentication inside the Google sidebar.

---

## 4. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`09_Smart_View/03_Smart_View_Specialized_Deep_Reference.md`** — Google Sheets and Mac/Browser setup.
- **`24_Architect_Masterclass/01_The_Springboard_and_Settings_Map.md`** — Ad-Hoc behavior settings (`Native` vs `Standard`).

# Deploying and Administering Oracle Smart View for Office (Mac and Browser) — Complete Markdown Edition

> **Original PDF:** `Deploying_and_Administering_Oracle_Smart_View_for_Office_(Mac_and_Browser).pdf` | **Folder:** Level 3 (Build & Design)  
> **Purpose:** Definitive Markdown guide for IT administrators on deploying the `manifest.xml` Office 365 Web Add-In across Mac, Chrome, and Edge environments.

---

## Table of Contents
1. [Manifest Generation (`Create Manifest File` Wizard)](#manifest-generation)
2. [Deployment via Microsoft 365 Admin Center (`Integrated Apps`)](#microsoft-365-deploy)
3. [Troubleshooting Cross-Origin Identity Authentication](#troubleshooting)
4. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Manifest Generation (`Create Manifest File` Wizard) <a name="manifest-generation"></a>

Inside `Create and Manage -> Smart View -> Create Manifest File`:
- Administrators select required add-in features (`Planning`, `Financials`, `FreeForm`).
- EPM Cloud generates a customized XML file containing the exact tenant domain URLs and SSL certificates required by Microsoft Excel's web container.

---

## 2. Deployment via Microsoft 365 Admin Center (`Integrated Apps`) <a name="microsoft-365-deploy"></a>

1. Log into `admin.microsoft.com` as a Global Office 365 Administrator.
2. Navigate to `Settings -> Integrated Apps -> Upload custom apps`.
3. Upload the `manifest.xml` and assign to specific security groups (`e.g., EPM_Mac_Users`).

---

## 3. Troubleshooting Cross-Origin Identity Authentication <a name="troubleshooting"></a>

- **Domain Whitelisting:** Ensure `*.oraclecloud.com` and your identity domain URL (`*.identity.oraclecloud.com`) are added to the `AppDomains` section inside `manifest.xml`, or Excel will block login dialog frames.

---

## 4. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`09_Smart_View/03_Smart_View_Specialized_Deep_Reference.md`** — Complete Mac and Browser deployment steps.

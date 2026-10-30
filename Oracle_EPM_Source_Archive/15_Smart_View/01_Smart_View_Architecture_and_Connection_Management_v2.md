# 01 — Smart View Architecture & Connection Management

---

## 1.1 Architecture of Oracle Smart View for Office

**Oracle Smart View for Office** is the comprehensive Microsoft Office (Excel, Word, PowerPoint, Outlook) add-in connecting business users directly to Oracle EPM Cloud (Planning, Essbase, Financial Consolidation, Tax, FreeForm).

```
┌────────────────────────────────────────────────────────────────────────┐
│                        SMART VIEW CLIENT ARCHITECTURE                  │
├────────────────────────────────────────────────────────────────────────┤
│ MICROSOFT EXCEL / OFFICE HOST PROCESS (EXCEL.EXE)                      │
│   ├── Smart View Core Engine (HsAddin.dll / COM Add-in)                │
│   ├── UI Ribbon & Task Pane Components (VSTO Add-in)                   │
│   ├── Embedded Browser Component (Microsoft Edge WebView2)             │
│   └── XML Grid Translation & Formula Engine                            │
│                                                                        │
│ TLS 1.2 / 1.3 HTTPS ENCRYPTED TUNNEL (PORT 443)                       │
│                                                                        │
│ ORACLE EPM CLOUD GATEWAY                                               │
│   ├── Identity Cloud Service (OCI IAM / SSO Provider)                  │
│   ├── Planning Web Service Provider (/HyperionPlanning/SmartView)      │
│   └── Native Essbase Provider (/aps/SmartView)                         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 1.2 The 32-Bit vs. 64-Bit Excel Reality

One of the most frequent sources of Smart View instability in corporate finance departments is running 32-bit Microsoft Office:

| Metric | 32-Bit Microsoft Office | 64-Bit Microsoft Office (Recommended) |
| :--- | :--- | :--- |
| **Virtual Addressable RAM** | **Hard limit of 2 GB** total process RAM | **Virtually unlimited** (bounded only by physical PC RAM) |
| **Massive Ad Hoc Grids** | Crashes with `"Out of Memory"` on 50,000+ cells | Seamlessly handles 500,000+ cells |
| **Excel Stability** | Frequent crashes during large "Zoom In Bottom Level" | Stable; utilizes multi-threading |
| **Consultant Rule** | **Upgrade all finance laptops to 64-bit Office** | **Mandatory enterprise standard** |

---

## 1.3 Shared vs. Private Connections

Smart View supports two distinct connection architectures:

```
┌──────────────────────────────────────┬──────────────────────────────────────┐
│          SHARED CONNECTIONS          │         PRIVATE CONNECTIONS          │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ • Uses a centralized XML server URL: │ • Connects directly to a specific    │
│   https://epm.oraclecloud.com/       │   cube or application provider URL.  │
│   workspace/SmartViewProviders       │                                      │
│ • Displays ALL provisioned cloud     │ • Bypasses tree navigation; connects │
│   applications in a single tree view.│   straight into FinPlan or EPBCS.    │
│ • Recommended for general end users. │ • Used for HsGetValue formulas & VBA.│
└──────────────────────────────────────┴──────────────────────────────────────┘
```

### Connection Syntax Guide:
1. **Shared Connection Provider URL**:
   ```
   https://<your_subdomain>.epm.<data_center>.ocs.oraclecloud.com/workspace/SmartViewProviders
   ```
2. **Planning Private Provider URL**:
   ```
   https://<your_subdomain>.epm.<data_center>.ocs.oraclecloud.com/HyperionPlanning/SmartView
   ```
3. **Essbase Direct Private URL**:
   ```
   https://<your_subdomain>.epm.<data_center>.ocs.oraclecloud.com/essbase/smartview
   ```

---

## 1.4 Single Sign-On (SSO) & Embedded Browser Engine

In modern EPM Cloud deployments, user authentication is federated through enterprise Identity Providers (Azure AD, Okta, PingFederate).
* When a user clicks **Connect**, Smart View launches an embedded browser window to complete the SAML/OAuth SSO handshake.
* **WebView2 vs. Legacy Internet Explorer**:
  * Earlier Smart View releases used legacy Internet Explorer 11 registry components.
  * Modern Smart View releases use **Microsoft Edge WebView2**, providing high-performance Chromium rendering, multi-factor authentication (MFA) support, and biometric passkey compatibility.

---

## 1.5 The Smart View Health Check Tool & Diagnostics

Smart View features a built-in diagnostic suite: **Smart View Ribbon $\rightarrow$ Help $\rightarrow$ Health Check**.

### Key Diagnostic Items Tuned by Health Check:
1. **`Disable Hardware Graphics Acceleration`**: Prevents Excel display glitches, flickering grid lines, and white screen crashes.
2. **`Excel Options: Page Breaks`**: Turns off automatic page-break calculations, speeding up sheet refreshes by **300%**.
3. **`Registry Timeouts`**: Automatically fixes Windows Internet Explorer / WinInet timeout keys (`ReceiveTimeout`, `ServerInfoTimeout`) from default 30 seconds to **900 seconds (15 minutes)**, preventing timeout disconnects during large cube aggregations.

---

## 1.6 Resolving the "Missing Smart View Ribbon" Defect

If Microsoft Excel experiences an abrupt crash, it often disables Smart View to protect itself upon reboot:

### Recovery Steps:
1. In Excel, go to **File $\rightarrow$ Options $\rightarrow$ Add-ins**.
2. Look at the bottom dropdown: Select **`Disabled Items`** $\rightarrow$ Click **Go...**
3. If `Oracle Smart View for Office` is listed: Select it $\rightarrow$ Click **Enable**.
4. Change the dropdown to **`COM Add-ins`** $\rightarrow$ Click **Go...**
5. Check the box next to **`Oracle Smart View for Office`** $\rightarrow$ Click **OK**.
6. Restart Excel. The Smart View ribbon will reappear.

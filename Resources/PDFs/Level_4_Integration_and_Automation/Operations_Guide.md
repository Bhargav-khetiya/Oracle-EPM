# Operations Guide for Oracle EPM Cloud — Complete Markdown Edition

> **Original PDF:** `Operations_Guide.pdf` | **Folder:** Level 4 (Integration & Automation)  
> **Purpose:** The definitive Markdown master operations manual covering system performance diagnosis, network latency testing (`Fiddler`), Service Request (`SR`) escalations, and SLA definitions.

---

## Table of Contents
1. [Diagnosing Network & Browser Latency (`Fiddler`, `Har Files`)](#network-latency)
2. [EPM Cloud Diagnostic Runbooks & Log Analysis](#diagnostics)
3. [Oracle Support Service Request (`SR`) Escalation Matrix](#sr-escalation)
4. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Diagnosing Network & Browser Latency (`Fiddler`, `Har Files`) <a name="network-latency"></a>

When users complain *"EPM is slow today"*, elite architects isolate the exact layer:
- **Network / Proxy Delay:** Use browser Developer Tools (`F12 -> Network -> Export HAR`) or `Fiddler` to measure HTTP handshake timing (`TTFB - Time To First Byte`). If `TTFB > 1.5s`, corporate Zscaler/VPN is throttling the connection.
- **Server Execution Delay:** Check `Job Console` to see how long Essbase actually took to evaluate the calculation.

---

## 2. EPM Cloud Diagnostic Runbooks & Log Analysis <a name="diagnostics"></a>

- **Provide Feedback (`Help -> Provide Feedback`):** Immediately captures a snapshot of the current web session, execution logs, and browser state and uploads a diagnostic package (`PF_ID_xxx`) directly to Oracle Engineering.

---

## 3. Oracle Support Service Request (`SR`) Escalation Matrix <a name="sr-escalation"></a>

| Severity Level | Definition & Oracle SLA | Architect Required Actions |
| :--- | :--- | :--- |
| **Severity 1 (`Critical Production Outage`)** | Production environment is completely inaccessible (`HTTP 503/500`) or critical close calculation fails right before earning release. **Oracle SLA: 24/7 continuous engineering work.** | Open SR $\rightarrow$ request immediate **Duty Manager escalation** $\rightarrow$ provide exact `Provide Feedback ID` and timestamp. |
| **Severity 2 (`Major Feature Loss`)** | Core workflow is broken (`e.g., Data Integration fails`), but a manual workaround exists. **Oracle SLA: Business hours response.** | Provide full reproduction runbook and `agent.log`. |

---

## 4. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`18_Production_Support/01_Production_Support_Guide.md`** — Comprehensive production runbooks.
- **`24_Architect_Masterclass/08_The_Complete_Error_Code_Encyclopedia.md`** — Complete error dictionary.

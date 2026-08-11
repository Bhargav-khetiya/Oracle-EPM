# Working with EPM Automate — Complete Markdown Edition

> **Original PDF:** `Working_with_EPM_Automate.pdf` | **Folder:** Level 4 (Integration & Automation)  
> **Purpose:** Definitive Markdown command dictionary and automation guide covering all 90+ EPM Automate commands, exit codes, encrypted password generation (`.epw`), and batch scripts.

---

## Table of Contents
1. [EPM Automate Architecture & Encrypted Passwords (`encrypt`)](#architecture)
2. [Command Dictionary Matrix (`login`, `runBusinessRule`, `importMetadata`)](#commands)
3. [Exit Codes & Script Error Handling Architecture](#exit-codes)
4. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. EPM Automate Architecture & Encrypted Passwords (`encrypt`) <a name="architecture"></a>

EPM Automate is a Java command-line wrapper around Oracle's native REST APIs.
- **Never Store Plaintext Passwords:** Use `epmautomate encrypt [password] mykey.epw` to generate an AES-encrypted password file locked to the current OS environment.

---

## 2. Command Dictionary Matrix (`login`, `runBusinessRule`, `importMetadata`) <a name="commands"></a>

| Command Name | Required Parameters | Example Execution |
| :--- | :--- | :--- |
| **`login`** | `user password/epw url [domain]` | `epmautomate login svc_admin@company.com key.epw https://epbcs.oraclecloud.com` |
| **`uploadFile`** | `localFilePath [inboxFolder]` | `epmautomate uploadFile C:/data/actuals.csv` |
| **`importMetadata`** | `jobName [fileName]` | `epmautomate importMetadata "Import_Cost_Centers"` |
| **`runBusinessRule`** | `ruleName [Param1=Val1 ...]` | `epmautomate runBusinessRule "Calculate_Revenue" Year=FY26 Entity=CC_109` |
| **`runAutoPredict`** | `jobName` | `epmautomate runAutoPredict "Seed_FY26_AI_Baseline"` |
| **`refreshCube`** | `jobName` | `epmautomate refreshCube "Cube_Refresh_FinPlan"` |

---

## 3. Exit Codes & Script Error Handling Architecture <a name="exit-codes"></a>

- **Exit Code `0`:** Complete success.
- **Exit Code `1`:** Command syntax or authentication error (`EPMAT-1`).
- **Exit Code `6` / `11`:** Job completed with warnings (`e.g., duplicate member names encountered or database locked`). Always check `%ERRORLEVEL%` in Windows batch scripts!

---

## 4. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`14_EPM_Automate/01_EPM_Automate_Complete_Guide.md`** — Complete automation scripts.
- **`24_Architect_Masterclass/08_The_Complete_Error_Code_Encyclopedia.md`** — EPMAT error dictionary.

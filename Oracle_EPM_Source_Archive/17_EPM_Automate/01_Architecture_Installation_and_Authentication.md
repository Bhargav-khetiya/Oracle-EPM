# 01 — Architecture, Installation, & Authentication

---

## 1.1 Architecture of EPM Automate

**EPM Automate** is Oracle's official command-line interface (CLI) designed to automate repetitive administration, data integration, and maintenance tasks in Oracle EPM Cloud.
* Behind the scenes, EPM Automate is **not a proprietary protocol**; it is a lightweight client wrapper that translates CLI commands into **HTTPS REST API requests (JSON over TLS 1.2/1.3 on port 443)** directed at the Oracle Cloud EPM service gateway.

```
┌────────────────────────────────────────────────────────────────────────┐
│                      EPM AUTOMATE INTERACTION MODEL                    │
├────────────────────────────────────────────────────────────────────────┤
│ 1. CLI COMMAND:                                                        │
│    epmautomate runBusinessRule "FinPlan_01_Aggregation"                │
│                                                                        │
│ 2. CLIENT-SIDE REST TRANSLATION:                                       │
│    POST /HyperionPlanning/rest/v3/applications/FinPlan/jobs            │
│    Headers: Authorization: Bearer <token>, Content-Type: application/json│
│    Body: {"jobType":"RULES","jobName":"FinPlan_01_Aggregation"}        │
│                                                                        │
│ 3. ORACLE CLOUD GATEWAY:                                               │
│    Validates credentials against Oracle Identity Cloud Service (OCI IAM)│
│    Dispatches job to Planning Application Server / Essbase Kernel      │
│                                                                        │
│ 4. POLLING & RETURN:                                                   │
│    EPM Automate polls GET /jobs/<jobId> until status != "IN_PROGRESS"  │
│    Returns: "The business rule completed successfully." (Exit Code 0)  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 1.2 Installation and Upgrades

### Supported Platforms:
* **Windows**: 64-bit Windows Server 2016/2019/2022, Windows 10/11.
* **Linux**: Oracle Linux, Red Hat Enterprise Linux (RHEL), SUSE, Ubuntu.

### Installation Steps:
1. Log into your EPM Cloud instance as a Service Administrator.
2. Navigate to **Navigator $\rightarrow$ Tools $\rightarrow$ Download EPM Automate**.
3. Run the installer:
   * **Windows**: Run `epmautomate-setup.exe` (installs by default to `C:\Oracle\EPM Automate`).
   * **Linux**: Extract `epmautomate.tar` and execute `./install.sh`.
4. **Auto-Upgrade**: EPM Automate can automatically update itself to the latest cloud release using:
   ```bash
   epmautomate upgrade
   ```

---

## 1.3 Authentication Mechanisms & Password Encryption

Oracle EPM Cloud strictly prohibits passing plaintext passwords in batch scripts. EPM Automate provides multiple enterprise authentication methods:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       AUTHENTICATION COMPARISON MATRIX                      │
├──────────────────────┬──────────────────────┬───────────────────────────────┤
│ Method               │ Security Level       │ Best Use Case                 │
├──────────────────────┼──────────────────────┼───────────────────────────────┤
│ 1. Encrypted Password│ High                 │ Standard on-premise scheduled │
│    File (.epw)       │                      │ Windows / Linux batch scripts │
├──────────────────────┼──────────────────────┼───────────────────────────────┤
│ 2. OAuth 2.0 Tokens  │ Maximum              │ Modern enterprise zero-trust, │
│    (OCI IAM / IDCS)  │ (Passwordless)       │ cloud CI/CD pipelines         │
├──────────────────────┼──────────────────────┼───────────────────────────────┤
│ 3. API Keys          │ High                 │ Service account automation    │
└──────────────────────┴──────────────────────┴───────────────────────────────┘
```

---

### 1.3.1 Method 1: The Encrypted Password File (`.epw`)

The standard industry practice is to generate an encrypted password file on the server running the scripts:

```cmd
:: Generate encrypted password file
epmautomate encrypt MySecretP@ssword C:\Oracle\EPM_Automate\password.epw
```

* **Adding a Custom Private Key**: To prevent another user from decrypting your `.epw` file, supply a custom private key file:
  ```cmd
  epmautomate encrypt MySecretP@ssword C:\Keys\mykey.key C:\Oracle\EPM_Automate\password.epw
  ```

---

### 1.3.2 Method 2: OAuth 2.0 Token-Based Authentication

For enterprise environments requiring **passwordless authentication**, EPM Automate supports OAuth 2.0 tokens issued by **Oracle Cloud Infrastructure Identity and Access Management (OCI IAM)**:

```cmd
epmautomate login <Client_ID> <Token_File> https://epm-test.oraclecloud.com
```

---

### 1.3.3 Single Sign-On (SSO) and MFA Bypass Service Accounts

When an enterprise enforces corporate SSO (Okta, Azure AD / Entra ID, PingFederate) with Multi-Factor Authentication (MFA), automated scripts cannot complete the interactive browser challenge.
* **The Solution**: Administrators must configure a **Native Non-Federated Service Account** in OCI IAM / Identity Cloud Service (e.g., `epm_svc_automation@company.com`).
* This account is assigned the **Service Administrator** role directly in the EPM application and authenticated via `.epw` without triggering the corporate SSO redirect.

---

## 1.4 Session Management & Proxy Configuration

### 1.4.1 Login Command Syntax:
```cmd
epmautomate login svc_admin@orbrick.com C:\Keys\admin.epw https://epm-test-orbrick.epm.us-phoenix-1.ocs.oraclecloud.com
```

### 1.4.2 Logout Command:
Always conclude automation scripts with `logout` to terminate the session token on the server:
```cmd
epmautomate logout
```

### 1.4.3 Corporate Proxy Servers:
If your server routes internet traffic through a proxy, set the standard environment variables before calling EPM Automate:
```powershell
$env:HTTP_PROXY = "http://proxy.orbrick.com:8080"
$env:HTTPS_PROXY = "http://proxy.orbrick.com:8080"
```

---

## 1.5 Return Codes (Exit Status)

EPM Automate strictly signals script success or failure via its operating system process exit code:
* **`0`**: Command completed successfully.
* **`1`**: Command failed with an error.

### In Windows PowerShell:
```powershell
epmautomate login svc_admin password.epw https://epm.oraclecloud.com
if ($LASTEXITCODE -ne 0) {
    Write-Error "EPM Automate Login Failed with exit code $LASTEXITCODE"
    exit 1
}
```

### In Linux / Bash:
```bash
epmautomate login svc_admin password.epw https://epm.oraclecloud.com
if [ $? -ne 0 ]; then
    echo "EPM Automate Login Failed"
    exit 1
fi
```

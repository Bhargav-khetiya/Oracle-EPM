# 06 — EPM Automate: Troubleshooting, Error Codes, & Interview Bible

---

## 6.1 Return Codes & The EPMAT Error Code Dictionary

EPM Automate returns an operating system exit code of **`0` (Success)** or **`1` (Failure)**. When a failure occurs, the console outputs a standard `EPMAT-XXXXX` diagnostic code:

| Error Code | Error Message | Root Cause | Immediate Resolution |
| :--- | :--- | :--- | :--- |
| **`EPMAT-00000`** | `Command completed successfully.` | Normal execution. | No action required. |
| **`EPMAT-01001`** | `Invalid credentials.` | Expired password, wrong username, corrupted `.epw` file, or locked account. | Re-generate `.epw` using `epmautomate encrypt`. Verify user account is active in OCI IAM. |
| **`EPMAT-01006`** | `Session timed out or invalid session.` | Script exceeded the maximum idle session window, or another script called `logout`. | Place `epmautomate login` immediately before the failed command, or refresh session. |
| **`EPMAT-07001`** | `The specified file does not exist.` | Target file not present in cloud Inbox/Outbox staging. | Run `epmautomate listFiles` to verify exact file name spelling and case sensitivity. |
| **`EPMAT-07004`** | `File upload failed.` | Network dropped during upload, or corporate firewall blocked binary ZIP stream. | Verify proxy settings. Add retry loop in PowerShell script. |
| **`EPMAT-07010`** | `Snapshot export failed.` | Insufficient cloud staging storage (capped at 150 GB) or maintenance window in progress. | Run `epmautomate deleteFile` to purge old backups from the cloud inbox. |
| **`EPMAT-09000`** | `Cube refresh failed.` | Duplicate member names, single-child auto-share conflicts, or formula syntax error. | Check Planning Job Console error log. Set single child to `Never Share`. |
| **`EPMAT-09005`** | `Business rule execution failed.` | Calc script runtime error: Divide by zero, missing member prompt, or Essbase block lock. | Review Calc Manager log. Ensure all RTP variables are populated in the command string. |

---

## 6.2 SSL/TLS & Proxy Troubleshooting

### 1. `SSLHandshakeException` or `PKIX path building failed`
* **Root Cause**: The client server is behind a corporate SSL-decrypting proxy (Zscaler, BlueCoat) that presents an untrusted internal root certificate.
* **Fix**: Import the corporate root CA certificate into the Java Keystore bundled with EPM Automate:
  ```cmd
  keytool -import -alias CorporateProxyCA -keystore "C:\Oracle\EPM Automate\jre\lib\security\cacerts" -file "C:\Certs\CorpRootCA.cer" -storepass changeit
  ```

---

## 6.3 Golden Do's and Don'ts of EPM Automate

### ✅ The DO's:
1. **DO always check `$LASTEXITCODE` (PowerShell) or `$?` (Bash)** after every single EPM Automate command.
2. **DO use `.epw` password encryption with a private key file** or OAuth 2.0 tokens for zero-trust security.
3. **DO call `epmautomate logout` in a `finally` block** to guarantee session cleanup on script abort.
4. **DO delete temporary ZIP snapshots from cloud staging** after downloading them to local SAN archives.
5. **DO use `copySnapshotFromInstance`** for direct cloud-to-cloud migration instead of routing large files through on-premise networks.

### ❌ The DON'Ts:
1. **DON'T store plaintext passwords in scripts** or environment variables.
2. **DON'T execute `refreshCube` during peak planning hours**; it locks the application and kicks out active planners.
3. **DON'T run `recreate` in production scripts**; it completely erases the application and database.
4. **DON'T schedule heavy data loads during the Daily Maintenance window**; the maintenance process will abort ongoing batch jobs.

---

## 6.4 Top 10 Consultant Interview Questions & Answers

### Q1: What underlying protocol does EPM Automate use to communicate with Oracle Cloud?
> **Answer**: EPM Automate communicates exclusively via **HTTPS REST API requests (JSON over TLS 1.2/1.3 on port 443)**. It is a client CLI wrapper that formats REST payloads and polls asynchronous job status endpoints on the Oracle Cloud gateway.

### Q2: How do you bypass corporate SSO and MFA when running automated batch scripts?
> **Answer**: By creating a **Native Non-Federated Service Account** directly in Oracle Identity Cloud Service (OCI IAM) assigned the Service Administrator role, and authenticating via an encrypted password file (`.epw`) or OAuth 2.0 Client Credentials token.

### Q3: What is the difference between `runBusinessRule` and `runJob`?
> **Answer**: `runBusinessRule` specifically executes Calc Manager rules and accepts command-line Runtime Prompts (RTPs). `runJob` is a universal dispatcher that launches any pre-configured job in the Planning Job Console (including metadata imports, data exports, cube refreshes, and rule sets).

### Q4: How do you migrate an LCM snapshot directly between Production and Test without downloading it?
> **Answer**: Using the command:
> `epmautomate copySnapshotFromInstance <Source_URL> <Source_User> <Source_Password_File> <Source_Snapshot> <Target_Snapshot_Name>`
> This transfers the archive across Oracle's internal cloud data center network backbone.

### Q5: What happens if an EPM Automate script fails midway through a nightly run?
> **Answer**: The operating system process terminates with an exit code of `1`. A well-architected script catches this error, logs the exact `EPMAT-XXXXX` error code, sends an automated alert to the EPM administrator, and executes a `finally` block to run `epmautomate logout`.

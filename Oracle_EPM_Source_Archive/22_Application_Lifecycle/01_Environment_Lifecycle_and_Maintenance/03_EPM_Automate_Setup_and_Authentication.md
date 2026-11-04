﻿# Oracle EPM Cloud: EPM Automate Setup and Authentication

## 1. What is EPM Automate—

**EPM Automate** is Oracle's official command-line utility for automating Oracle EPM Cloud operations. It is the backbone of all migration, backup, restore, and environment management activities.

- **Download:** Available from the EPM Cloud UI at *Navigator → Downloads → EPM Automate*
- **Platform:** Runs on Windows and Linux
- **Requires:** Java Runtime Environment (JRE) 11 or later (bundled in newer versions)
- **Location after install:** Typically `C:\Oracle\EPM Automate\bin\`

---

## 2. Installation

### Windows

1. Download the `EPMAutomate.zip` from your EPM Cloud environment
2. Extract to a folder (e.g., `C:\Oracle\EPMAutomate\`)
3. Add the `bin` directory to your system PATH:
   - `C:\Oracle\EPMAutomate\bin`
4. Verify installation:
   ```cmd
   epmautomate help
   ```

### Linux

1. Download the Linux package from the EPM Cloud environment
2. Extract:
   ```bash
   unzip EPMAutomate.tar.gz -d /opt/oracle/epmautomate
   ```
3. Add to PATH:
   ```bash
   export PATH=$PATH:/opt/oracle/epmautomate/bin
   ```
4. Make executable:
   ```bash
   chmod +x /opt/oracle/epmautomate/bin/epmautomate.sh
   ```

---

## 3. Creating Encrypted Password Files

> [!CAUTION]
> **Never store plain-text passwords in scripts.** Always use encrypted password files (`.epw`).

### Syntax

```
epmautomate encrypt PASSWORD KEY PASSWORD_FILE
```

| Parameter | Description | Example |
|-----------|-------------|---------|
| `PASSWORD` | Your plain-text password | `MyP@ssw0rd!` |
| `KEY` | A private encryption key (any string you choose) | `mySecretKey2026` |
| `PASSWORD_FILE` | Full path to the output `.epw` file | `C:\EPM_Scripts\prod_password.epw` |

### Examples

**Create password file for Production:**
```cmd
epmautomate encrypt "MyProdP@ss!" myKey123 "C:\EPM_Scripts\prod_password.epw"
```

**Create password file for Demo/Test:**
```cmd
epmautomate encrypt "MyTestP@ss!" myKey123 "C:\EPM_Scripts\demo_password.epw"
```

> [!NOTE]
> - The `.epw` file is tied to the machine where it was created — it cannot be copied to another machine and used
> - If you change your password, you must regenerate the `.epw` file
> - The `KEY` does not need to match between different password files
> - Store the `.epw` files in a secure directory with restricted access

---

## 4. Login

### Syntax

```
epmautomate login USERNAME PASSWORD_FILE URL [IDENTITY_DOMAIN]
```

| Parameter | Description | Example |
|-----------|-------------|---------|
| `USERNAME` | Service Administrator username (email) | `admin@company.com` |
| `PASSWORD_FILE` | Path to encrypted `.epw` file | `C:\EPM_Scripts\prod_password.epw` |
| `URL` | Full URL of the EPM environment | `https://planning-myco.epm.us1.oraclecloud.com` |
| `IDENTITY_DOMAIN` | *(Optional — needed only for Classic environments)* | `mycompany` |

### Example — Login to Production

```cmd
epmautomate login admin@company.com "C:\EPM_Scripts\prod_password.epw" "https://planning-myco.epm.us1.oraclecloud.com"
```

### Example — Login to Demo/Test

```cmd
epmautomate login admin@company.com "C:\EPM_Scripts\demo_password.epw" "https://planning-test-myco.epm.us1.oraclecloud.com"
```

> [!WARNING]
> - You can only be logged into **one environment at a time** per EPM Automate session
> - Always `logout` before logging into a different environment
> - If a session times out or gets stuck, use `logout` and then `login` again
> - Sessions typically time out after **60 minutes** of inactivity

---

## 5. Logout

### Syntax

```
epmautomate logout
```

Always logout after completing your operations to release the session.

---

## 6. Finding Your Environment URLs

You can find your environment URLs in:

1. **My Services Console** (`https://myservices.oraclecloud.com`)
   - Navigate to your EPM Cloud subscription
   - Each environment (Production, Test) will have its own URL

2. **Oracle Cloud Identity Console** (for OCI Gen2)
   - *Identity & Security → Domains → Applications*

3. **Welcome email** from Oracle when the instance was provisioned

### URL Format

```
https://{service}-{identity_domain}.epm.{datacenter}.oraclecloud.com
```

**Examples:**
| Environment | Example URL |
|-------------|-------------|
| Production | `https://planning-mycompany.epm.us1.oraclecloud.com` |
| Test | `https://planning-test-mycompany.epm.us1.oraclecloud.com` |

---

## 7. Verifying Your Setup — Quick Test

Run this sequence to verify everything works:

```cmd
:: Step 1: Create password file (one time only)
epmautomate encrypt "YourPassword" "YourKey" "C:\EPM_Scripts\password.epw"

:: Step 2: Login
epmautomate login admin@company.com "C:\EPM_Scripts\password.epw" "https://planning-myco.epm.us1.oraclecloud.com"

:: Step 3: List files to confirm access
epmautomate listFiles

:: Step 4: Logout
epmautomate logout
```

If `listFiles` returns a list of files/snapshots, your setup is complete and working.

---

## 8. Common Authentication Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `EPMCSS-20187: Invalid credentials` | Wrong username or password | Re-encrypt password file, verify username |
| `EPMCSS-20189: Could not connect to URL` | Wrong URL or network issue | Verify URL, check VPN/proxy |
| `EPMCSS-20149: Session already active` | Previous session not closed | Run `epmautomate logout` first |
| `EPMCSS-20071: Password file not found` | Wrong path to `.epw` file | Check file path, use quotes for paths with spaces |
| `EPMCSS-20xxx: User is not authorized` | User doesn't have Service Admin role | Assign Service Administrator role in Identity Domain |

---

## 9. Recommended Folder Structure for Scripts

```
C:\EPM_Scripts\
├── passwords\
│   ├── prod_password.epw
│   ├── test_password.epw
│   └── demo_password.epw
├── snapshots\
│   ├── 2026-10-09_Artifact_Snapshot.zip
│   └── 2026-10-08_Artifact_Snapshot.zip
├── logs\
│   └── clone_log_2026-10-09.txt
├── scripts\
│   ├── daily_backup.bat
│   ├── clone_prod_to_test.bat
│   └── recreate_and_import.bat
└── README.md
```

> [!TIP]
> Always keep password files in a separate, restricted-access subdirectory. Use descriptive names so you never accidentally use the wrong environment's credentials.

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: Why does an encrypted password file (.epw) fail with decryption errors when copied from Server A to Server B—
**Answer:** The epmautomate encrypt command leverages the Windows Data Protection API (DPAPI) or local host cryptographic hardware GUIDs. The encryption key is mathematically tied to the specific Windows User SID and local machine hardware master key. Copying the .epw file to another host or running it under a different Windows service account prevents decryption (EPMCSS-20071). The .epw file must always be generated directly on the target execution server under the service account that runs the scheduled task.

### Q2: How does OAuth 2.0 token-based authentication work with EPM Automate, and does it bypass Identity Cloud Service (IDCS) MFA—
**Answer:** EPM Automate supports OAuth 2.0 token authentication via registered confidential applications in IDCS / OCI IAM. When configured, scripts authenticate using a client ID and client secret (private key) rather than a human user password. This is mandatory for automated unattended batch processes because it bypasses Interactive Multi-Factor Authentication (MFA) prompts that would otherwise freeze headless batch scripts.

### Q3: What happens if an automated script issues epmautomate logout while another batch process is running in parallel on the same server—
**Answer:** On Windows, EPM Automate stores the active session token in %USERPROFILE%\.epmautomate. If two concurrent scripts run under the **same Windows user profile**, Script A's logout deletes the token file, causing Script B's subsequent command to fail with EPMCSS-20187: Session not authenticated. To run parallel CLI tasks on the same server, execute each task under a separate Windows service account or use direct HTTP REST API calls with independent bearer tokens.

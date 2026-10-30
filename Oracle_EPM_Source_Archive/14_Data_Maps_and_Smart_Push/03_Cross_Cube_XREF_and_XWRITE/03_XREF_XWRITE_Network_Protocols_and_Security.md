# 03 @XREF / @XWRITE Network Protocols, Authentication, and Cloud Boundaries

## 1. Low-Level Network Protocol Architecture

At the network transport layer, `@XREF` and `@XWRITE` do not use modern HTTP/REST or JSON web services. They rely on the legacy **Essbase Network Protocol (ENP)** operating over raw TCP/IP sockets between the Essbase Server kernels.

```
+---------------------------------------------------------------------------------------------------+
|                                 ESSBASE NETWORK PROTOCOL (ENP) HANDSHAKE                          |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  LOCAL ESSBASE PROCESS (SERVER A)                     REMOTE ESSBASE PROCESS (SERVER B)           |
|                                                                                                   |
|  1. DNS / IP Resolution of Location Alias Host                                                    |
|  2. SYN Packet sent to Essbase Agent Port (1423)                                                  |
|     -------------------------------------------------> [Port 1423: Essbase Agent Listener]       |
|                                                        - Allocates ephemeral server port (32768)  |
|  3. SYN-ACK / Handshake Response                       - Sends ephemeral port back to Client A    |
|     <-------------------------------------------------                                            |
|                                                                                                   |
|  4. Connect to Ephemeral Application Port (32768)                                                  |
|     -------------------------------------------------> [Port 32768: ESSSVR Process]              |
|                                                                                                   |
|  5. Transmit Authentication Packet                                                                |
|     - Location Alias Username                                                                     |
|     - DES/AES Encrypted Token / Password                                                          |
|     -------------------------------------------------> Authenticates against Security Catalog     |
|                                                                                                   |
|  6. Session Token Granted / Query Channel Established                                             |
|     <------------------------------------------------- Ready for Point-to-Point Data Query        |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Authentication Models: Native vs. Cloud Identity (OCI IAM / IDCS)

### 2.1 On-Premises Native Directory Authentication
In legacy on-premises Hyperion environments:
* The Location Alias directly stored the native Hyperion Shared Services username and an encrypted password hash.
* Passwords remained static for years, meaning Location Aliases rarely failed unless a database was migrated.

### 2.2 Oracle EPM Cloud Pod Isolation & IAM Restrictions
In Oracle Cloud Infrastructure (OCI), the architecture is fundamentally different:
1. **Single-Sign-On (SSO) and Multi-Factor Authentication (MFA)**:
   * EPM Cloud relies on Oracle Cloud Identity and Access Management (OCI IAM) or Identity Cloud Service (IDCS).
   * Direct native username/password authentication over raw TCP port 1423 is blocked by cloud perimeter firewalls.
2. **Pod-to-Pod Restrictions**:
   * One EPM Cloud instance (pod) cannot open direct TCP socket connections across the internet into another customer pod's Essbase kernel due to virtual cloud network (VCN) isolation.
   * Cross-pod data movements via `@XREF` / `@XWRITE` are **unsupported in EPM Cloud**.
3. **Intra-Pod Cross-Cube Support**:
   * Within the **same EPM Cloud pod**, multiple cubes (e.g., `OEP_FS`, `OEP_WFP`, `OEP_REP`) share the same underlying virtual host and security context.
   * In this scenario, location aliases connect locally (`localhost` / `127.0.0.1`), avoiding external network firewalls.

---

## 3. Firewall and Port Requirements (Hybrid / On-Prem Architecture)

When designing hybrid integrations where an on-premises Essbase server connects to another Essbase instance via `@XREF` / `@XWRITE`, the following firewall ports must remain permanently open:

| Port / Range | Protocol | Direction | Purpose |
| :--- | :--- | :--- | :--- |
| **1423** | TCP | Outbound from Client $\rightarrow$ Inbound to Remote | Default Essbase Agent Listener port. |
| **32768 – 33768** | TCP | Outbound from Client $\rightarrow$ Inbound to Remote | Ephemeral application server ports allocated dynamically by `ESSSVR`. |
| **6400 / 28080** | TCP | Bidirectional | Shared Services / Foundation security provider verification. |

> [!WARNING]
> If network security teams block the ephemeral port range (32768–33768), the initial handshake on port 1423 will succeed, but the actual data transfer will terminate with a socket connection timeout error: `Essbase Error (1042006): Network error [10060]: Failed to connect to server`.

---

## 4. Modern Cloud Replacement: Linked Services & REST Connections

Because raw TCP connections are unviable across distributed enterprise cloud tenants, Oracle EPM Cloud has superseded `@XREF` with **Linked Connections**:

```
+-------------------------------------------------------------+
| EPM CLOUD SOURCE POD (https://epm-source.oraclecloud.com)   |
|   |-- Uses 'Linked Connection' (OAuth 2.0 / Bearer Token)   |
|   |-- Encrypted HTTPS over Port 443                         |
|   v                                                         |
| EPM CLOUD TARGET POD (https://epm-target.oraclecloud.com)   |
|   |-- Data Integration Pipeline or REST API Ingestion       |
+-------------------------------------------------------------+
```

Linked Connections eliminate password expiration failures, traverse corporate proxy servers cleanly, and comply with zero-trust cloud network security standards.


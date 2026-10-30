# Oracle EPM Cloud Architecture — How It's Built

> **Folder:** 00_Foundation | **Audience:** Beginner → Architect
>
> **Provenance:** Merged from Claude `01.06_Cloud_Architecture_and_OCI.md`, `01.01_EPM_Architecture_Overview.md`, `01.13_EPM_Cloud_Architecture.md`; Gemini `LEARNING_ROADMAP.md`

---

## Why Architecture Matters

When a client CIO asks "Where is our financial data physically stored?", you need to answer confidently. Understanding the architecture helps with data residency conversations, performance troubleshooting, network connectivity, maintenance planning, and disaster recovery.

---

## Oracle Cloud Infrastructure (OCI) — The Foundation

**OCI** is Oracle's cloud platform — think of it as Oracle's version of AWS, Azure, or GCP. EPM Cloud runs entirely on OCI.

### What OCI Provides for EPM

| Component | Role in EPM |
|-----------|------------|
| **Compute** | Virtual machines running EPM application servers and Essbase |
| **Storage** | Disks storing Essbase data files (.PAG, .IND) |
| **Networking** | Load balancers, private networks, VPN for Integration Agent |
| **Identity (IDCS/IAM)** | User authentication and role provisioning |
| **Database** | Oracle relational DB for Planning repository tables |
| **Security** | AES-256 encryption at rest, TLS in transit |

### Key Point for Consultants

> As an EPM consultant, you **don't manage OCI directly** (it's SaaS — Oracle handles infrastructure). But you **must understand** it for:
> - Data residency conversations with legal teams
> - Performance troubleshooting
> - Network connectivity (VPN for Integration Agent)
> - Maintenance window planning
> - Disaster recovery planning

---

## EPM Cloud Component Stack

```
┌──────────────────────────────────────────────┐
│                 USER LAYER                    │
│  Web Browser  ·  Smart View  ·  EPM Automate │
└──────────────────────┬───────────────────────┘
                       │ HTTPS
┌──────────────────────▼───────────────────────┐
│              PRESENTATION TIER               │
│  Web Application Server (WebLogic/JET UI)    │
│  Navigation Flows · Forms · Dashboards       │
└──────────────────────┬───────────────────────┘
                       │
┌──────────────────────▼───────────────────────┐
│              APPLICATION TIER                │
│  Planning Server · Calc Manager · FDMEE      │
│  REST API · Groovy Engine · Job Scheduler    │
└──────────┬───────────────────────┬───────────┘
           │                       │
┌──────────▼──────────┐ ┌─────────▼───────────┐
│   ESSBASE TIER      │ │  RELATIONAL TIER    │
│  BSO/ASO Cubes      │ │  Planning Repository│
│  .PAG + .IND files  │ │  HSP_* tables       │
│  Calc Engine        │ │  Security metadata  │
│  Index + Data Cache │ │  Form/rule defs     │
└─────────────────────┘ └─────────────────────┘
```

---

## Pod Architecture — Multi-Tenant Hosting

Oracle hosts EPM Cloud in **pods** — clusters of servers shared by multiple tenants (companies). Each tenant gets an isolated environment within the pod.

### URL Structure Decoded

```
https://planning-test-a123456.epm.us-phoenix-1.ocs.oraclecloud.com
│       │        │    │       │   │             │
│       │        │    │       │   │             └── Oracle Cloud domain
│       │        │    │       │   └── OCI Region (data location)
│       │        │    │       └── EPM service identifier
│       │        │    └── Tenant ID (unique per customer)
│       │        └── Environment type (test, prod)
│       └── Service name (planning, financials, etc.)
└── Protocol (always HTTPS)
```

### Environments

| Environment | Purpose | Access |
|-------------|---------|--------|
| **Production (Prod)** | Live business data, real users | Restricted, change-controlled |
| **Test** | Validation, UAT, training | Broader access for testing |
| **Development (Dev)** | Building and experimenting | Development team only |

> **Oracle documented:** EPM Cloud subscriptions typically include a production environment and one test environment. Additional environments may be available depending on the subscription. Verify with your Oracle contract.

---

## Identity and Access Management

EPM Cloud authenticates users through **Oracle Identity Cloud Service (IDCS)** or the newer **OCI IAM Identity Domains**.

```
User logs in → IDCS/IAM authenticates → EPM checks application role →
EPM applies artifact permissions → EPM applies member/data security →
User sees their allowed data
```

See [01_Security_and_Access](../01_Security_and_Access/00_INDEX.md) for detailed security coverage.

---

## Maintenance and Updates

Oracle applies monthly updates to EPM Cloud automatically. Key facts:

| Aspect | Detail |
|--------|--------|
| **Update frequency** | Monthly (mandatory) |
| **Test environment** | Updated first (usually 1 week before Prod) |
| **Maintenance window** | Scheduled; Oracle publishes dates in advance |
| **Rollback** | Not available — Oracle tests updates before release |
| **Impact** | Brief downtime during update; test before relying on changed behavior |

---

## Backup and Disaster Recovery

| Feature | What Oracle Provides |
|---------|---------------------|
| **Daily snapshots** | Oracle takes automatic backups |
| **Maintenance snapshots** | Taken before each monthly update |
| **Customer-initiated** | You can create snapshots via EPM Automate or UI |
| **Recovery** | Restore from snapshot; contact Oracle Support for DR scenarios |
| **Data residency** | Data stays in the OCI region you selected |

---

## 🧠 Self-Check Questions

1. **What infrastructure does EPM Cloud run on?**
2. **What are the three main tiers of the EPM architecture?**
3. **What is a pod in EPM Cloud?**
4. **How often does Oracle update EPM Cloud?**
5. **Where are Planning repository tables stored — Essbase or relational database?**

> **Teach-back prompt:** A client CIO asks where their financial data is physically stored and whether it meets EU data residency requirements. Walk them through the OCI region, pod architecture, encryption, and backup strategy.

---

## What's Next?

→ [03_EPM_History.md](03_EPM_History.md) — How Hyperion became Oracle EPM Cloud


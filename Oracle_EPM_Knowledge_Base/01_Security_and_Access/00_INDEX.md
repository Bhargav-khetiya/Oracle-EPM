# Security and Access Control — Index

> This section covers everything about Oracle EPM Cloud security: from identity management and role provisioning to data-level permissions and valid intersections.

---

## Reading Order

| # | Document | What You'll Learn | Time |
|---|----------|------------------|------|
| 1 | [01_Access_Control_and_Roles.md](01_Access_Control_and_Roles.md) | Security layers, predefined roles, IDCS/IAM, permissions, troubleshooting | 45 min |
| 2 | [02_Valid_Intersections.md](02_Valid_Intersections.md) | Filtering invalid dimensional combinations, anchor/nonanchor, design patterns | 30 min |

## Key Concepts

Security in Oracle EPM Cloud is **layered** — think of it as multiple checkpoints:

```
Layer 1: Identity (Can you sign in?)
    ↓
Layer 2: Application Role (What broad capabilities do you have?)
    ↓
Layer 3: Artifact Permissions (Which forms, rules, dashboards can you use?)
    ↓
Layer 4: Member/Data Permissions (Which data members can you see/edit?)
    ↓
Layer 5: Valid Intersections (Which dimensional combinations are offered?)
    ↓
Layer 6: Workflow State (Can you act in the current approval state?)
```

> **Critical distinction:** Valid intersections **filter** dimensional combinations — they are NOT access grants. Security permissions and valid intersections are **independent** checks.

---

## Prerequisites

Before studying Security, you should understand:
- What dimensions and members are → [08_Dimensions_and_Metadata](../08_Dimensions_and_Metadata/00_INDEX.md)
- What forms are → [02_User_Interface_and_Navigation](../02_User_Interface_and_Navigation/00_INDEX.md)

---

> **Provenance:** Content merged from ChatGPT (`01_Security_and_Access/`), Claude (`12_Security/`), Gemini (`01_Security_and_Access/`)


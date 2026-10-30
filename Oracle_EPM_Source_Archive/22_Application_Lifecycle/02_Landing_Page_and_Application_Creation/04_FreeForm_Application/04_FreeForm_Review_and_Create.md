# 🎨 FreeForm — Review & Create
## Final Review and Application Creation

> **Wizard Step:** 4 of 4 (Final Step — FreeForm path)  
> **Previous:** Step 3 — Dimension Setup  
> **Next:** Application Home Page

---

## 📸 Screen Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  Create Application — FreeForm                         Step 4/4  │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Review                                                           │
│  ──────                                                           │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │  General Properties                                      │     │
│  │  Application Name:    Supply_Model                       │     │
│  │  Description:         Supply chain allocation model      │     │
│  │  Application Type:    FreeForm                           │     │
│  │                                                          │     │
│  │  Cubes                                                   │     │
│  │  Cube 1:  Plan1   (BSO Hybrid)                          │     │
│  │  Cube 2:  Rpt1    (ASO)                                 │     │
│  │                                                          │     │
│  │  Dimensions                                              │     │
│  │  Account:   ✅ Enabled (Name: "Measures")               │     │
│  │  Entity:    ✅ Enabled (Name: "CostCenter")             │     │
│  │  Period:    ✅ Enabled (Name: "Month")                   │     │
│  └─────────────────────────────────────────────────────────┘     │
│                                                                   │
│  ⚠️ Application Name, Cube Names, Cube Types, and              │
│     Dimension Names cannot be changed after creation.            │
│                                                                   │
│  ┌────────┐  ┌────────┐  ┌────────────┐                         │
│  │ Cancel │  │  Back  │  │  Create ✓  │                         │
│  └────────┘  └────────┘  └────────────┘                         │
└──────────────────────────────────────────────────────────────────┘
```

---

## ✅ Pre-Creation Checklist for FreeForm

| # | Check | Question |
|---|-------|----------|
| 1 | ☐ | Application Name is correct and follows naming rules? |
| 2 | ☐ | Correct number of cubes configured? |
| 3 | ☐ | Each cube has correct type (BSO vs ASO)? |
| 4 | ☐ | Cube names are under 8 characters and descriptive? |
| 5 | ☐ | At least one BSO cube for data entry (if needed)? |
| 6 | ☐ | Default dimensions enabled/disabled as intended? |
| 7 | ☐ | Dimension names match your model design? |

---

## ⏳ Creation Process

After clicking **Create**, the FreeForm application creation is typically **faster** than Planning module creation:

| Step | Duration | Description |
|------|----------|-------------|
| Application container | ~20 sec | Creates application structure |
| Cube creation | ~30 sec per cube | Initializes each cube |
| Dimension build | ~30 sec | Creates enabled dimensions |
| Database initialization | ~1 min | Builds Essbase outlines |
| Validation | ~30 sec | Verifies integrity |
| **Total** | **~3-5 minutes** | Significantly faster than module-based |

---

## 📋 Post-Creation — What to Do Next

Since FreeForm creates a nearly empty application, you have significant setup work:

| Priority | Task | Navigation |
|----------|------|------------|
| 1 | Add custom dimensions | Application → Overview → Dimensions → + |
| 2 | Add dimension members | Application → Overview → Dimensions → [Dim] → Members |
| 3 | Configure dimension properties | Application → Overview → Dimensions → [Dim] → Properties |
| 4 | Refresh database | Application → Overview → Actions → Refresh |
| 5 | Create data forms | Navigator → Forms → + Create |
| 6 | Build business rules | Navigator → Rules → Calc Manager |
| 7 | Assign security | Tools → Access Control |
| 8 | Import data | Data Integration or Smart View |

---

## ✅ Post-Creation Verification

| Check | How | Expected |
|-------|-----|----------|
| Application visible | Home → Application → Overview | App name shown |
| Cubes exist | Application → Overview → Cubes | All cubes listed |
| Dimensions exist | Application → Overview → Dimensions | Enabled dims shown |
| Jobs clean | Tools → Jobs | "Create Database" completed |
| Smart View connect | Excel → Smart View → Connect | Connection successful |

---

## ðŸ’¡ Frequently Asked & Twisted Questions (Q&A)

### Q1: Why does FreeForm application creation take only 3â€“5 minutes compared to 15 minutes for Planning?
**Answer:** Planning applications must generate hundreds of relational metadata tables, pre-packaged forms, task lists, and seeded business rules. FreeForm creates a clean, lightweight Essbase database container without pre-built module overhead, completing database initialization in a fraction of the time.

### Q2: What mandatory configuration steps must occur immediately after FreeForm creation finishes?
**Answer:** Because FreeForm creates an empty canvas:
1. Build custom dimension hierarchies via Dimension Management or CSV import.
2. Define member data storage properties (Store, Dynamic Calc).
3. Execute **Refresh Database** to restructure the Essbase cubes.
4. Assign security access permissions before users can connect.

### Q3: How do you add additional custom dimensions to a FreeForm cube post-creation?
**Answer:** Navigate to Application â†’ Overview â†’ Dimensions, select the target cube from the dropdown, click the **+** (Create) icon, enter the dimension name, set dimension properties, and run a Database Refresh.

---

## 🔗 Navigation

| Direction | Document |
|-----------|----------|
| **← Previous** | [Dimension Setup](./03_FreeForm_Dimension_Setup.md) |
| **← FreeForm Overview** | [FreeForm Overview](./01_FreeForm_Architecture_and_Use_Cases.md) |
| **← Back to Index** | [Master Index](../../00_MASTER_INDEX.md) |

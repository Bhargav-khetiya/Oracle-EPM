﻿# 🚀 Step 3: Calendar & Fiscal Year Setup
## Time Period Configuration — Every Option Explained

> **Wizard Step:** 3 of 5  
> **Screen Title:** "Calendar" or "Time Period Setup"  
> **Navigation:** `START → Step 1 → Step 2 → Step 3 (Calendar)`  
> **Previous:** Step 2 — Application Type / Module Selection  
> **Next:** Step 4 — Currency Configuration

---

## 📸 Screen Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  Create Application                                    Step 3/5  │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Calendar                                                         │
│  ────────                                                         │
│                                                                   │
│  Start Year *           [▼ FY24              ]                    │
│                                                                   │
│  End Year *             [▼ FY28              ]                    │
│                                                                   │
│  Fiscal Year                                                      │
│  Start Month *          [▼ January           ]                    │
│                                                                   │
│  Period Type *          ○ 12 Months                               │
│                         ○ 13 Periods                              │
│                         ○ Custom                                  │
│                                                                   │
│  Weekly Distribution    [▼ Even              ]                    │
│  (if 12 Months)                                                   │
│                                                                   │
│  ──── OR (if Custom) ────                                         │
│                                                                   │
│  Define Custom Periods  [Configure...]                            │
│                                                                   │
│                                                                   │
│  ┌────────┐  ┌────────┐  ┌────────┐                             │
│  │ Cancel │  │  Back  │  │  Next  │                             │
│  └────────┘  └────────┘  └────────┘                             │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📝 Field-by-Field Reference

### Field 1: Start Year *(Required)*

| Property | Details |
|----------|---------|
| **Label** | "Start Year" |
| **Type** | Dropdown select |
| **Required** | ✅ Yes |
| **Range** | Typically FY00 through FY50+ (varies by system config) |
| **Default** | Current fiscal year |
| **Editable Later** | ❌ No — CANNOT be changed after creation |
| **Impact** | Defines the earliest year in the Year dimension |

> [!CAUTION]
> **The Start Year CANNOT be changed after creation.** You cannot add years before this date. Always set the Start Year early enough to accommodate historical data you may need to load.

**Best Practice Guidance:**
| Scenario | Recommended Start Year |
|----------|----------------------|
| Budget/Forecast only (no history) | Current year or prior year |
| Need 2-3 years of history | 2-3 years before current |
| Need 5+ years of history | Set accordingly |
| Historical trend analysis | Earliest year of available data |
| New organization | Current year |

---

### Field 2: End Year *(Required)*

| Property | Details |
|----------|---------|
| **Label** | "End Year" |
| **Type** | Dropdown select |
| **Required** | ✅ Yes |
| **Range** | Must be ≥ Start Year |
| **Default** | Start Year + 5 |
| **Editable Later** | ✅ Yes — can ADD more years later |
| **Impact** | Defines the latest year in the Year dimension |

**Recommended Range:**
| Planning Horizon | Recommended Span | Example |
|-----------------|-------------------|---------|
| Short-term (budget) | 2-3 years | FY24–FY26 |
| Medium-term (forecast) | 3-5 years | FY24–FY28 |
| Long-term (strategic) | 5-10 years | FY24–FY34 |
| With Strategic Modeling | 10-20 years | FY20–FY40 |

> [!TIP]
> You CAN add additional End Years after creation (Application → Settings → Years). However, each additional year increases application size and processing time. Start with a reasonable range and expand as needed.

---

### Field 3: Fiscal Year Start Month *(Required)*

| Property | Details |
|----------|---------|
| **Label** | "Fiscal Year Start Month" |
| **Type** | Dropdown select |
| **Required** | ✅ Yes |
| **Options** | January through December (12 options) |
| **Default** | January |
| **Editable Later** | ❌ No — CANNOT be changed after creation |
| **Impact** | Defines which month begins the fiscal year and how quarters are calculated |

#### Dropdown Options and Quarter Mapping:

| Start Month | Q1 | Q2 | Q3 | Q4 |
|------------|-----|-----|-----|-----|
| **January** | Jan-Feb-Mar | Apr-May-Jun | Jul-Aug-Sep | Oct-Nov-Dec |
| **February** | Feb-Mar-Apr | May-Jun-Jul | Aug-Sep-Oct | Nov-Dec-Jan |
| **March** | Mar-Apr-May | Jun-Jul-Aug | Sep-Oct-Nov | Dec-Jan-Feb |
| **April** | Apr-May-Jun | Jul-Aug-Sep | Oct-Nov-Dec | Jan-Feb-Mar |
| **May** | May-Jun-Jul | Aug-Sep-Oct | Nov-Dec-Jan | Feb-Mar-Apr |
| **June** | Jun-Jul-Aug | Sep-Oct-Nov | Dec-Jan-Feb | Mar-Apr-May |
| **July** | Jul-Aug-Sep | Oct-Nov-Dec | Jan-Feb-Mar | Apr-May-Jun |
| **August** | Aug-Sep-Oct | Nov-Dec-Jan | Feb-Mar-Apr | May-Jun-Jul |
| **September** | Sep-Oct-Nov | Dec-Jan-Feb | Mar-Apr-May | Jun-Jul-Aug |
| **October** | Oct-Nov-Dec | Jan-Feb-Mar | Apr-May-Jun | Jul-Aug-Sep |
| **November** | Nov-Dec-Jan | Feb-Mar-Apr | May-Jun-Jul | Aug-Sep-Oct |
| **December** | Dec-Jan-Feb | Mar-Apr-May | Jun-Jul-Aug | Sep-Oct-Nov |

> [!CAUTION]
> **This setting is PERMANENT.** The Fiscal Year Start Month determines:
> - Period-to-Quarter mapping for all time-based calculations
> - How YearTotal is calculated
> - Quarterly aggregation logic
> - Rolling forecast period alignment

**Common Industry Start Months:**
| Month | Common Industries |
|-------|------------------|
| January | Most industries (calendar year) |
| April | Government (India, UK, Japan), Some retail |
| July | Government (US Federal, Australia), Education |
| October | US Federal Government fiscal year |

---

### Field 4: Period Type *(Required)*

| Property | Details |
|----------|---------|
| **Label** | "Period Type" (or "Calendar Type") |
| **Type** | Radio buttons (mutually exclusive) |
| **Required** | ✅ Yes |
| **Default** | 12 Months |
| **Editable Later** | ❌ No |

#### Option A: 12 Months (Standard)

| Property | Details |
|----------|---------|
| **Radio Button** | ○ 12 Months |
| **Description** | Standard 12-month calendar |
| **Period Members Created** | Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec |
| **Quarter Members** | Q1, Q2, Q3, Q4 |
| **Summary Members** | YearTotal, BegBalance (if applicable) |
| **Best For** | Most organizations using standard monthly reporting |

#### Option B: 13 Periods

| Property | Details |
|----------|---------|
| **Radio Button** | ○ 13 Periods |
| **Description** | 13-period calendar (4 weeks per period) |
| **Period Members Created** | TP1 through TP13 |
| **Use Case** | Retail and manufacturing (equal-length periods) |
| **Best For** | Organizations needing equal 4-week periods |

#### Option C: Custom

| Property | Details |
|----------|---------|
| **Radio Button** | ○ Custom |
| **Description** | User-defined period structure |
| **Configuration** | Opens additional configuration dialog |
| **Flexibility** | Define your own period names and hierarchy |
| **Best For** | Organizations with unique reporting periods |

---

### Field 5: Weekly Distribution *(Conditional)*

| Property | Details |
|----------|---------|
| **Label** | "Weekly Distribution" |
| **Type** | Dropdown select |
| **Visible** | Only when Period Type = "12 Months" |
| **Required** | ✅ Yes (when visible) |
| **Purpose** | Defines how weekly data is distributed across months in a quarter |

#### Dropdown Options:

| Option | Pattern | Description |
|--------|---------|-------------|
| **Even** | Even distribution | Equal distribution across weeks |
| **445** | 4-4-5 | Month 1: 4 weeks, Month 2: 4 weeks, Month 3: 5 weeks |
| **454** | 4-5-4 | Month 1: 4 weeks, Month 2: 5 weeks, Month 3: 4 weeks |
| **544** | 5-4-4 | Month 1: 5 weeks, Month 2: 4 weeks, Month 3: 4 weeks |

**When to Use Each Pattern:**
| Pattern | Common Use |
|---------|------------|
| **Even** | Most organizations — simplest distribution |
| **445** | Retail (NRF calendar), some manufacturing |
| **454** | Some retail organizations |
| **544** | Less common, specific industry requirements |

---

## ⚠️ Calendar Impact Summary

> [!IMPORTANT]
> Your calendar choices affect the ENTIRE application permanently:

| Setting | Affects | Can Change Later— |
|---------|---------|-------------------|
| Start Year | Earliest available year | ❌ No |
| End Year | Latest available year | ✅ Yes (can extend) |
| Start Month | Quarter definitions, fiscal year | ❌ No |
| Period Type | Period dimension structure | ❌ No |
| Weekly Distribution | Data spreading patterns | Limited changes |

---

## 🔘 Buttons on This Screen

| Button | Location | Action |
|--------|----------|--------|
| **Cancel** | Bottom-left | Cancels wizard entirely |
| **Back** | Bottom-center | Returns to Step 2 (Module Selection) |
| **Next** | Bottom-right | Proceeds to Step 4 (Currency) |

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: Can an administrator change the Fiscal Year First Month from January to July after the application is created—
**Answer:** No. Fiscal Year First Month is permanently locked at creation. It dictates internal chronological indexing, BegBalance calculations, and YTD dynamic rollups. Changing it requires exporting all metadata/data, recreating the application, and re-mapping historical periods.

### Q2: What is the difference between Even, 4-4-5, 4-5-4, and 5-4-4 weekly distribution patterns—
**Answer:** In retail and manufacturing, months are defined by 4 or 5 full weeks rather than calendar days:
- **4-4-5:** First two months have 4 weeks (28 days), third month has 5 weeks (35 days).
- **4-5-4:** Middle month has 5 weeks.
- **5-4-4:** First month has 5 weeks.
- **Even:** Spreads annual figures evenly across 12 monthly periods (8.33% per month).
This setting dictates how annual budgets automatically spread to periods in data forms.

### Q3: Can an administrator add historical past years (e.g. FY20, FY21) if the Start Year was set to FY24—
**Answer:** No. In Dimension Management, you can only **"Add Years" to the end** of the time horizon (FY29, FY30). You cannot push the Start Year backwards because Essbase time-series calculation formulas (@PRIOR, @MDSHIFT) anchor to the Start Year. Always configure the Start Year 3"5 years in the past if historical actuals will ever be required.

---

## 🔗 Navigation

| Direction | Document |
|-----------|----------|
| **Next →** | [Step 4: Currency Configuration](./05_Step4_Currency_Configuration.md) |
| **← Previous** | [Step 2: Application Type Selection](./03_Step2_Application_Type_Selection.md) |
| **← Back to Index** | [Master Index](../../00_MASTER_INDEX.md) |

﻿# 🚀 Step 4: Currency Configuration
## Currency Setup and Multi-Currency Options

> **Wizard Step:** 4 of 5  
> **Screen Title:** "Currency" or "Currency Settings"  
> **Navigation:** `START → Step 1 → Step 2 → Step 3 → Step 4 (Currency)`  
> **Previous:** Step 3 — Calendar Setup  
> **Next:** Step 5 — Review & Create

---

## 📸 Screen Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  Create Application                                    Step 4/5  │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Currency                                                         │
│  ────────                                                         │
│                                                                   │
│  Main Currency *        [▼ USD - US Dollar           ]            │
│                                                                   │
│  Multiple Currencies    ☐ Enable multiple currencies              │
│                                                                   │
│  ──── If Multi-Currency Enabled ────                              │
│                                                                   │
│  Additional Currencies:                                           │
│                                                                   │
│  ┌─────────────────────────────────────────────┐                 │
│  │ Currency  │ Symbol │ Scale │ Thousands Sep  │                 │
│  ├───────────┼────────┼───────┼────────────────┤                 │
│  │ EUR       │ €      │ 1     │ ,              │                 │
│  │ GBP       │ £      │ 1     │ ,              │                 │
│  │ JPY       │ ¥      │ 1     │ ,              │                 │
│  └─────────────────────────────────────────────┘                 │
│                                                                   │
│  [+ Add Currency]                                                │
│                                                                   │
│  ┌────────┐  ┌────────┐  ┌────────┐                             │
│  │ Cancel │  │  Back  │  │  Next  │                             │
│  └────────┘  └────────┘  └────────┘                             │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📝 Field-by-Field Reference

### Field 1: Main Currency *(Required)*

| Property | Details |
|----------|---------|
| **Label** | "Main Currency" or "Default Currency" |
| **Type** | Dropdown select with search |
| **Required** | ✅ Yes |
| **Default** | USD (US Dollar) |
| **Editable Later** | ❌ No — cannot change after creation |
| **Impact** | Sets the primary reporting currency for the entire application |

#### Complete Currency Options Available:

| Code | Currency | Symbol | Region |
|------|----------|--------|--------|
| AED | UAE Dirham | د.إ | Middle East |
| ARS | Argentine Peso | $ | South America |
| AUD | Australian Dollar | A$ | Oceania |
| BRL | Brazilian Real | R$ | South America |
| CAD | Canadian Dollar | C$ | North America |
| CHF | Swiss Franc | CHF | Europe |
| CNY | Chinese Yuan | ¥ | Asia |
| CZK | Czech Koruna | Kč | Europe |
| DKK | Danish Krone | kr | Europe |
| EGP | Egyptian Pound | £ | Africa |
| EUR | Euro | € | Europe |
| GBP | British Pound Sterling | £ | Europe |
| HKD | Hong Kong Dollar | HK$ | Asia |
| HUF | Hungarian Forint | Ft | Europe |
| IDR | Indonesian Rupiah | Rp | Asia |
| ILS | Israeli New Shekel | ₪ | Middle East |
| INR | Indian Rupee | ₹ | Asia |
| JPY | Japanese Yen | ¥ | Asia |
| KRW | South Korean Won | ₩ | Asia |
| MXN | Mexican Peso | $ | North America |
| MYR | Malaysian Ringgit | RM | Asia |
| NOK | Norwegian Krone | kr | Europe |
| NZD | New Zealand Dollar | NZ$ | Oceania |
| PHP | Philippine Peso | ₱ | Asia |
| PLN | Polish Zloty | zł | Europe |
| QAR | Qatari Riyal | ﷼ | Middle East |
| RON | Romanian Leu | lei | Europe |
| RUB | Russian Ruble | ₽ | Europe/Asia |
| SAR | Saudi Riyal | ﷼ | Middle East |
| SEK | Swedish Krona | kr | Europe |
| SGD | Singapore Dollar | S$ | Asia |
| THB | Thai Baht | ฿ | Asia |
| TRY | Turkish Lira | ₺ | Europe/Asia |
| TWD | Taiwan Dollar | NT$ | Asia |
| USD | US Dollar | $ | North America |
| VND | Vietnamese Dong | ₫ | Asia |
| ZAR | South African Rand | R | Africa |

> [!TIP]
> **The Main Currency should be your organization's primary reporting currency.** All data entry defaults to this currency. If you operate globally, choose the currency used for consolidated financial reporting (typically your corporate headquarters currency).

---

### Field 2: Multiple Currencies *(Optional)*

| Property | Details |
|----------|---------|
| **Label** | "Multiple Currencies" or "Enable multiple currencies" |
| **Type** | Checkbox |
| **Required** | ❌ No |
| **Default** | Unchecked (disabled) |
| **Editable Later** | ❌ No — CANNOT be enabled after creation |

> [!CAUTION]
> **This is a ONE-TIME, IRREVERSIBLE decision:**
> - If you enable multi-currency now, you CANNOT disable it later
> - If you do NOT enable it now, you CANNOT enable it later
> - **When in doubt, ENABLE it** — you don't have to use it immediately, but you cannot add it later

#### What Happens When Multi-Currency is Enabled:

| Component | Created/Changed |
|-----------|-----------------|
| **Currency Dimension** | New dimension added with default members |
| **HSP_InputValue** | System member for data input value tracking |
| **Local** | Member representing local entity currency |
| **Reporting currencies** | Main currency + any additional currencies |
| **Exchange Rate Table** | System table for currency conversion rates |
| **Translation Rules** | Auto-generated currency translation business rules |

#### What Happens When Multi-Currency is NOT Enabled:

| Component | Result |
|-----------|--------|
| **Currency Dimension** | NOT created — single currency only |
| **All data** | Stored in Main Currency only |
| **No translation** | Currency conversion not available |
| **Simpler structure** | Fewer dimensions, smaller database |

---

### Multi-Currency Additional Settings (When Enabled)

#### Adding Additional Currencies

| Action | Details |
|--------|---------|
| **Button** | [+ Add Currency] |
| **Location** | Below the currency table |
| **Process** | Click → Select currency from dropdown → Configure |

#### Currency Table Columns:

| Column | Description | Editable |
|--------|-------------|----------|
| **Currency** | ISO currency code (e.g., EUR, GBP) | Selected from dropdown |
| **Symbol** | Currency symbol (e.g., €, £) | Auto-populated |
| **Scale** | Scaling factor (1, 1000, 1000000) | Yes |
| **Thousands Separator** | Character for thousands (comma, period, space) | Yes |
| **Decimal Separator** | Character for decimals (period, comma) | Yes |
| **Negative Sign** | How negatives display (prefix -, suffix -, parentheses) | Yes |

#### Exchange Rate Configuration (Post-Creation):
After application creation, exchange rates are managed via:

| Setting | Location | Description |
|---------|----------|-------------|
| **Rate Type** | Application → Currency | Average, Ending, Historical |
| **Rate Table** | Application → Currency → Exchange Rates | Monthly exchange rate values |
| **Triangulation** | Application → Currency → Triangulation | Cross-currency via intermediary |

**Exchange Rate Types:**
| Type | Description | Use Case |
|------|-------------|----------|
| **Average** | Average rate for the period | Income statement items (revenue, expense) |
| **Ending** | Rate at period end | Balance sheet items (assets, liabilities) |
| **Historical** | Rate at time of transaction | Equity items, specific one-time events |

---

## 💡 Decision Guide: Multi-Currency

| Question | If Yes → | If No → |
|----------|----------|---------|
| Does your organization operate in multiple countries— | Enable multi-currency | Consider single currency |
| Do you need to report in multiple currencies— | Enable multi-currency | Single currency may suffice |
| Do entities have different local currencies— | Enable multi-currency | Single currency |
| Do you need currency translation for consolidation— | Enable multi-currency | Single currency |
| Is this a simple budget app for one country— | Single currency may suffice | - |
| Are you unsure— | **Enable it** (can't add later) | - |

---

## 🔘 Buttons on This Screen

| Button | Location | Action |
|--------|----------|--------|
| **Cancel** | Bottom-left | Cancels wizard entirely |
| **Back** | Bottom-center | Returns to Step 3 (Calendar) |
| **Next** | Bottom-right | Proceeds to Step 5 (Review & Create) |

---

## ðŸŽ¯ Frequently Asked & Twisted Questions (Q&A)

### Q1: Can an application created as "Single Currency" be converted to "Multi-Currency" later—
**Answer:** No. In Single Currency applications, the Currency dimension is omitted entirely from Essbase block headers, and currency exchange tables (HSP_RATES) are not generated. Enabling Multi-Currency later is prohibited because it would alter the dimensional coordinates of every block in the database.

### Q2: What is the purpose of the HSP_InputValue and Local currency members—
**Answer:** In Multi-Currency applications:
- Local: Represents data entered in the native functional currency of the specific Entity (e.g. GBP for London, EUR for Paris).
- HSP_InputValue: The system input layer that holds raw user entries before currency translation rules execute.
Base data must **never** be entered directly into reporting currencies (USD), as translation rules will overwrite them.

### Q3: When should "Enable Currency Triangulation" be checked—
**Answer:** Enable Triangulation when cross-currency conversions between two non-base currencies must pass through an intermediate common currency (e.g. converting JPY to GBP via USD). This eliminates the need to maintain hundreds of individual cross-rate pairs and enforces European Monetary Union (EMU) statutory compliance.

---

## 🔗 Navigation

| Direction | Document |
|-----------|----------|
| **Next →** | [Step 5: Review & Create](./06_Step5_Review_and_Create.md) |
| **← Previous** | [Step 3: Calendar Setup](./04_Step3_Calendar_Setup.md) |
| **← Back to Index** | [Master Index](../../00_MASTER_INDEX.md) |

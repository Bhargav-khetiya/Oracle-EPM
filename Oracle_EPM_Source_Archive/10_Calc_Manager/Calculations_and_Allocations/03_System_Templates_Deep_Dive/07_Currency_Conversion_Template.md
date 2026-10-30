# 07 Currency Conversion Template: Multi-Currency Translation and Rate Triangulation

## 1. Architectural Essence of Multi-Currency Translation

Global enterprises operating across multiple countries require financial plans to be entered in local functional currencies (e.g., EUR, GBP, JPY, CAD) and subsequently translated into corporate reporting currencies (e.g., USD, EUR_Reporting) for consolidated executive reporting.

The Calculation Manager **Currency Conversion Template** automates this process by applying exchange rate matrices against operational data slices according to GAAP / IFRS accounting standards.

```
+---------------------------------------------------------------------------------------------------+
|                                 CURRENCY CONVERSION TOPOLOGY                                      |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  LOCAL CURRENCY INPUT DATA                                EXCHANGE RATE MATRIX                    |
|  +--------------------------------+                       +-------------------------------------+ |
|  | Entity: France_Sub             |                       | Currency: EUR -> USD                | |
|  | Currency: Local (EUR)          |                       | Rate Type: Average = 1.08           | |
|  | Revenue: 1,000,000 EUR         |                       | Rate Type: Ending  = 1.10           | |
|  +--------------------------------+                       +-------------------------------------+ |
|                 |                                                            |                    |
|                 +-----------------------------+------------------------------+                    |
|                                               |                                                   |
|                                               v                                                   |
|  +---------------------------------------------------------------------------------------------+  |
|  | TRANSLATED REPORTING CURRENCY OUTPUT                                                        |  |
|  | - P&L Accounts (Revenue): Translated at Average Rate ===> $1,080,000 USD                   |  |
|  | - Balance Sheet (Cash):    Translated at Ending Rate  ===> $1,100,000 USD                   |  |
|  | Target Currency: "USD_Reporting"                                                            |  |
|  +---------------------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Exchange Rate Types and Accounting Standards

| Financial Statement Category | Standard Rate Applied | Translation Logic |
| :--- | :--- | :--- |
| **Income Statement / P&L** | **Average Rate** (Period Average) | Reflects continuous operational activity throughout the month or quarter. |
| **Balance Sheet (Monetary Assets/Liabilities)** | **Ending Rate** (Month-End Spot) | Reflects immediate market liquidation value at the close of the reporting date. |
| **Balance Sheet (Equity / Fixed Assets)** | **Historical Rate** | Preserves historical transaction valuation; prevents currency fluctuation on paid-in capital. |
| **Cash Flow Adjustments** | **Average / Ending Delta** | Translates cash movement lines at monthly average rates, posting foreign currency translation reserve (CTA). |

---

## 3. Wizard Configuration Parameters

When using the Currency Conversion Template wizard:

| Step | Parameter | Description |
| :--- | :--- | :--- |
| **Step 1: Source Data** | Member Selection | Specifies local currency inputs (`Currency: "Local Currency"`, `Entity: @LEVMBRS("Entity", 0)`). |
| **Step 2: Target Reporting Currencies** | Currency List | Selects destination reporting members (e.g., `"USD"`, `"EUR_Reporting"`). |
| **Step 3: Rate Association** | Rate Cube / Table | Points to exchange rate accounts (e.g., `"HSP_Rate_Average"`, `"HSP_Rate_Ending"`). |
| **Step 4: Account Categorization** | Rate Type Mapping | Maps P&L accounts to Average Rate and Balance Sheet accounts to Ending Rate. |
| **Step 5: Triangulation Option** | True / False | Enables multi-hop triangulation when direct currency pairs do not exist (e.g., JPY $\rightarrow$ USD $\rightarrow$ BRL). |

---

## 4. Generated Essbase Calculation Script

```sql
/*
 * Compiled Currency Conversion Template Script
 * Translates Local Currency inputs to USD Reporting Currency
 */

FIX("Forecast", "FY25", "Working", @LEVMBRS("Entity", 0))
  FIX("Jan":"Dec")
    
    /* 1. Translate P&L Accounts using Monthly Average Rate */
    FIX(@DESCENDANTS("Total_Income_Statement"))
      "USD" = "Local Currency" * "HSP_Rate_Average"->"HSP_Rates"->"No_Entity";
    ENDFIX

    /* 2. Translate Balance Sheet Accounts using Month-End Ending Rate */
    FIX(@DESCENDANTS("Total_Balance_Sheet"))
      "USD" = "Local Currency" * "HSP_Rate_Ending"->"HSP_Rates"->"No_Entity";
    ENDFIX

  ENDFIX
ENDFIX
```

---

## 5. Architectural Best Practices

1. **Centralize Rate Cubes**: Maintain exchange rates in a single dedicated rate slice (`"No_Entity"` or `"Global_Assumptions"`). Never scatter rates across operational entities.
2. **Dynamic vs. Stored Translation**: In reporting cubes (ASO), currency translation can be calculated dynamically using MDX member formulas on currency dimensions. In operational BSO cubes, run translation as a stored batch calculation to preserve transaction history.


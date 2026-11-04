# 08 Custom Design-Time Prompt (DTP) Templates: Building Reusable Wizards

## 1. The Architecture of Custom Templates

In addition to pre-built system templates (Allocation, Copy, Clear), Calculation Manager allows enterprise architects to build **Custom Templates**. A Custom Template encapsulates standardized business logic patterns, exposing an interactive, step-by-step graphical wizard powered by **Design-Time Prompts (DTP)**.

When another developer drops a Custom Template onto their canvas, Calculation Manager launches the custom wizard. Based on the developer's inputs, the template dynamically generates tailored Essbase calculation script blocks.

```
+---------------------------------------------------------------------------------------------------+
|                                     CUSTOM DTP TEMPLATE ARCHITECTURE                              |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  TEMPLATE DESIGNER (Architect Mode)                                                               |
|  +---------------------------------------------------------------------------------------------+  |
|  | 1. Declare Design-Time Prompts (DTP):                                                        |  |
|  |    - [dtp_Entity]:   Type = Member,   Dim = Entity, Prompt = "Select Entity to Allocate"    |  |
|  |    - [dtp_Driver]:   Type = Member,   Dim = Account, Prompt = "Select Allocation Driver"    |  |
|  |    - [dtp_IsCapex]:  Type = Boolean,  Default = False, Prompt = "Include Capex Offset—     |  |
|  |                                                                                             |  |
|  | 2. Compose Dynamic Script Logic with DTP Tokens:                                            |  |
|  |    FIX ("Plan", "Working", [dtp_Entity])                                                    |  |
|  |      "Alloc_Expense" = "Corp_Pool" * ([dtp_Driver] / [dtp_Driver]->"Total_Dept");           |  |
|  |      <IF> [dtp_IsCapex] == TRUE                                                             |  |
|  |        "Capex_Offset" = -1 * "Alloc_Expense";                                               |  |
|  |      </IF>                                                                                  |  |
|  |    ENDFIX                                                                                   |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                  |                                                |
|                                                  v                                                |
|  CONSUMER DEVELOPER EXPERIENCE (Interactive Wizard in Calculation Manager)                       |
|  +---------------------------------------------------------------------------------------------+  |
|  | WIZARD DIALOG:                                                                              |  |
|  | Select Entity to Allocate: [ E101_Sales_East            ]                                    |  |
|  | Select Allocation Driver:   [ Headcount                  ]                                    |  |
|  | Include Capex Offset—       [ [X] Yes                    ]                                    |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                  |                                                |
|                                                  v                                                |
|  [GENERATES CLEAN, STANDARDIZED ESSBASE SCRIPT AT DESIGN TIME!]                                   |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Design-Time Prompt (DTP) Data Types

Calculation Manager supports eight specialized DTP types:

| DTP Data Type | Purpose | UI Input Component |
| :--- | :--- | :--- |
| **Member** | Single outline member selection | Member selector tree dialog (can restrict to specific hierarchy or level). |
| **Members** | Multiple outline member selections | Multi-select member checkbox tree or list. |
| **Dimension** | Selection of an outline dimension | Dropdown list of dimensions in the active cube. |
| **String / Text** | Freeform text or member prefix | Text input box. |
| **Integer / Number**| Numeric thresholds or loop limits | Numeric spinner / input box with validation bounds. |
| **Percent** | Multiplier factor (0.0 to 1.0) | Percentage input box with decimal formatting. |
| **Boolean** | Conditional branching toggle | Yes/No radio buttons or checkbox. |
| **Condition** | Dynamic logical expression | Expression builder modal evaluated at design time. |

---

## 3. Dynamic Wizard Branching and Conditional Steps

Advanced custom templates utilize **Conditional DTP Visibility** to streamline user interaction:
* If `[dtp_AllocationMethod] == "Driver-Based"`, the wizard renders Step 3 (Driver Account Selector).
* If `[dtp_AllocationMethod] == "Even-Split"`, Step 3 is hidden, and the wizard jumps directly to Step 4 (Target Selection).

### DTP Conditional Syntax:
```xml
<Prompt name="dtp_DriverAccount" type="Member" dimension="Account">
    <Condition>
        <Equals left="[dtp_AllocationMethod]" right="Driver-Based"/>
    </Condition>
    <Label>Select Allocation Driver Account</Label>
</Prompt>
```

---

## 4. Reusability, Governance, and Lifecycle Management

### 4.1 Enterprise Standardization Benefits
1. **Elimination of Copy-Paste Errors**: Junior developers configure standard corporate allocations through guided wizards rather than handwriting intricate 100-line calc scripts.
2. **Built-in Quality Controls**: Custom templates can enforce naming conventions, mandatory comment logging, and automated division-by-zero guards.

### 4.2 Portability via LCM
* Custom templates are saved under the **Templates** node in Calculation Manager.
* Exported via Lifecycle Management (LCM) under `Calculation Manager -> Templates`.
* Can be published to Global Scope, making them instantly available across all Planning and Financial Consolidation applications in the cloud environment.


# 05 — Smart View Functions (`HsGetValue`) & VBA Automation

---

## 5.1 The Excel Formula Functions (`HsGetValue` & `HsSetValue`)

While Ad Hoc analysis requires an interactive grid layout, executive C-suite board packages require **asymmetrical, pixel-perfect financial presentation** where numbers from different cubes, years, and scenarios live in arbitrary Excel cells alongside charts and graphics.

Smart View provides native Excel worksheet functions to query and write data cell-by-cell:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        SMART VIEW FORMULA FUNCTIONS                    │
├────────────────────┬───────────────────────────────────────────────────┤
│ HsGetValue         │ Retrieves a single cell value from an EPM cube    │
│ HsSetValue         │ Submits an Excel calculation result to an EPM cube│
│ HsDescription      │ Dynamically retrieves a member's alias description│
│ HsGetSheetInfo     │ Returns connection name, application, and cube info│
└────────────────────┴───────────────────────────────────────────────────┘
```

---

## 5.2 Deep Dive: `HsGetValue`

### Syntax:
```excel
=HsGetValue("ConnectionName", "Dim1=Member1", "Dim2=Member2", ..., "DimN=MemberN")
```

### Concrete Production Example:
```excel
=HsGetValue("FinPlan_Prod", "Account=Gross_Sales", "Entity=E10002", "Period=Jan", "Years=FY26", "Scenario=Actual", "Version=Working")
```

### Best Practices for Fast `HsGetValue` Workbooks:
1. **Never Hardcode Dimension Strings**: Place dimension coordinates in header cells (e.g., cell `B1` has `FY26`, cell `A5` has `Gross_Sales`), and reference them dynamically:
   ```excel
   =HsGetValue("FinPlan_Prod", "Account="&$A5, "Years="&$B$1, "Period="&B$2, "Scenario="&$B$3, "Version="&$B$4, "Entity="&$B$5)
   ```
2. **Batch Refresh**: Use the **Refresh Functions** button to evaluate all `HsGetValue` cells in a single compressed network stream rather than calculating cell-by-cell.

---

## 5.3 Deep Dive: `HsSetValue`

`HsSetValue` allows users to submit values calculated by complex Excel spreadsheet models back into the EPM database:

### Syntax:
```excel
=HsSetValue(Numeric_Value_or_Cell, "ConnectionName", "Dim1=Member1", ..., "DimN=MemberN")
```

### Example:
```excel
=HsSetValue(C10 * 1.15, "FinPlan_Prod", "Account=Bonus_Pool", "Entity=E10002", "Years=FY26", "Period=Dec", "Scenario=Budget", "Version=Working")
```

---

## 5.4 Smart View Developer Automation: The VBA API

Smart View exposes a comprehensive Visual Basic for Applications (VBA) API via the library file `smartview.bas` (located in `C:\Oracle\SmartView\bin`).

### 5.4.1 Declaring the API Functions:
In the VBA Editor (**Alt + F11**), import `smartview.bas` or declare:
```vba
Declare PtrSafe Function HypConnect Lib "HsAddin" (ByVal vtSheetName As Variant, ByVal vtUserName As Variant, ByVal vtPassword As Variant, ByVal vtServer As Variant) As Long
Declare PtrSafe Function HypDisconnect Lib "HsAddin" (ByVal vtSheetName As Variant, ByVal vtAll As Variant) As Long
Declare PtrSafe Function HypRetrieve Lib "HsAddin" (ByVal vtSheetName As Variant) As Long
Declare PtrSafe Function HypSubmitData Lib "HsAddin" (ByVal vtSheetName As Variant) As Long
```

---

### 5.4.2 Production Automated Monthly Reporting Macro

Below is a complete, production-grade macro that connects to EPM Cloud, updates report parameters, refreshes the active ad-hoc grid, saves a PDF copy, and disconnects:

```vba
Sub Automated_Monthly_Board_Package()
    Dim x As Long
    Dim SheetName As String
    SheetName = "Executive_Summary"
    
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    
    ' 1. Connect to EPM Planning Cube via Private Connection
    x = HypConnect(SheetName, "jsmith@orbrick.com", "MyP@ssword", "FinPlan_Private")
    If x <> 0 Then
        MsgBox "Smart View connection failed with error code: " & x, vbCritical
        Exit Sub
    End If
    
    ' 2. Refresh the active grid to pull current month Actuals
    x = HypRetrieve(SheetName)
    If x <> 0 Then
        MsgBox "Grid refresh failed with error code: " & x, vbCritical
        HypDisconnect SheetName, True
        Exit Sub
    End If
    
    ' 3. Export Polished PDF Report
    Sheets(SheetName).ExportAsFixedFormat Type:=xlTypePDF, _
        Filename:="C:\Reports\Executive_Board_Package_Oct2026.pdf", _
        Quality:=xlQualityStandard
    
    ' 4. Clean Disconnect
    HypDisconnect SheetName, True
    
    Application.ScreenUpdating = True
    Application.DisplayAlerts = True
    
    MsgBox "Monthly Board Package refreshed and exported to PDF successfully!", vbInformation
End Sub
```

# Developing Applications for Oracle Smart View for Office — Complete Markdown Edition

> **Original PDF:** `Developing_Applications_for_Oracle_Smart_View_for_Office.pdf` | **Folder:** Level 3 (Build & Design)  
> **Purpose:** Complete Markdown developer guide for building custom Windows VBA macros and Smart View SDK (`smartview.bas`) automation solutions.

---

## Table of Contents
1. [VBA SDK Declaration & `smartview.bas` Import](#sdk-declaration)
2. [Essential API Functions Matrix (`HypConnect`, `HypRetrieve`, `HypExecuteMenu`)](#api-matrix)
3. [Building Custom VBA Error Handlers & Silent Refreshes](#error-handling)
4. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. VBA SDK Declaration & `smartview.bas` Import <a name="sdk-declaration"></a>

To develop custom Smart View Excel applications, developers import `smartview.bas` (located in `C:/Oracle/SmartView/bin/`) into the Excel VBA editor (`Alt + F11 -> File -> Import File`).

---

## 2. Essential API Functions Matrix (`HypConnect`, `HypRetrieve`, `HypExecuteMenu`) <a name="api-matrix"></a>

| API Function | Parameters | Return Value | Description |
| :--- | :--- | :--- | :--- |
| **`HypConnect`** | `SheetName, UserName, Password, FriendlyName` | `Long (0 = Success)` | Establishes private/shared connection to EPM Cloud pod. |
| **`HypRetrieve`** | `SheetName` | `Long (0 = Success)` | Refreshes the active ad-hoc grid or form on the specified worksheet. |
| **`HypSubmitData`** | `SheetName` | `Long (0 = Success)` | Submits modified Excel cell values directly to Essbase. |
| **`HypExecuteMenu`** | `SheetName, MenuString` | `Long (0 = Success)` | Simulates clicking ribbon buttons (`e.g., "Predictive Planning -> Predict"`). |

---

## 3. Building Custom VBA Error Handlers & Silent Refreshes <a name="error-handling"></a>

```vba
' VBA Silent Refresh with Error Capture
Sub SilentEPMSubmit()
    Dim sts As Long
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    
    sts = HypSubmitData(ActiveSheet.Name)
    If sts <> 0 Then
        MsgBox "Smart View Submission Error Code: " & sts, vbCritical
    Else
        MsgBox "Data successfully committed to EPM Cloud!", vbInformation
    End If
    
    Application.ScreenUpdating = True
    Application.DisplayAlerts = True
End Sub
```

---

## 4. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`09_Smart_View/03_Smart_View_Specialized_Deep_Reference.md`** — Comprehensive VBA SDK reference.

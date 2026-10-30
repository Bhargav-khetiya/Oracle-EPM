# Calc Manager: Excel Lookup, Math, and Text Functions Index

## Architectural Notice & Navigation Guide

In the Oracle EPM Calculation Manager Custom Defined Functions (CDF) library, Excel-equivalent functions are distributed between specific operational categories:

1. **Excel Financial Functions**: Documented in [`../12_CalcMgr_Excel_Financial/`](../12_CalcMgr_Excel_Financial/)
   - PV, FV, NPV, IRR, XIRR, PMT, PPMT, IPMT, RATE, NPER, PRICE, YIELD, ACCRINT, etc.

2. **Excel Math & Statistical Functions**: Documented in [`../13_CalcMgr_Excel_Math_Stat/`](../13_CalcMgr_Excel_Math_Stat/) and [`../15_CalcMgr_Utility/`](../15_CalcMgr_Utility/)
   - MEDIAN, RANK, STDEV, VAR, VARP, PERCENTILE, SUMPRODUCT, SUMSQ, CEILING, FLOOR, MROUND, GCD, LCM, etc.

3. **Lookup, Text, String, and Pattern Functions**: Documented in [`../10_String/`](../10_String/) and [`../15_CalcMgr_Utility/`](../15_CalcMgr_Utility/)
   - **Text Manipulation**: [`@CalcMgrSubstring`](../10_String/@CalcMgrSubstring.md), [`@CalcMgrTrim`](../10_String/@CalcMgrTrim.md), [`@CalcMgrPadText`](../15_CalcMgr_Utility/@CalcMgrPadText.md), [`@CalcMgrConcat`](../15_CalcMgr_Utility/@CalcMgrConcat.md), [`@CalcMgrUppercase`](../10_String/@CalcMgrUppercase.md), [`@CalcMgrLowercase`](../10_String/@CalcMgrLowercase.md).
   - **Lookup & Searching**: [`@CalcMgrIndexOf`](../10_String/@CalcMgrIndexOf.md), [`@CalcMgrLastIndexOf`](../15_CalcMgr_Utility/@CalcMgrLastIndexOf.md), [`@CalcMgrStartsWith`](../10_String/@CalcMgrStartsWith.md), [`@CalcMgrEndsWith`](../10_String/@CalcMgrEndsWith.md), [`@CalcMgrMatches`](../15_CalcMgr_Utility/@CalcMgrMatches.md).
   - **Excel Array Lookups**: [`@CalcMgrExcelLARGE`](../15_CalcMgr_Utility/@CalcMgrExcelLARGE.md), [`@CalcMgrExcelSMALL`](../15_CalcMgr_Utility/@CalcMgrExcelSMALL.md), [`@CalcMgrExcelRANK`](../13_CalcMgr_Excel_Math_Stat/@CalcMgrExcelRANK.md), [`@CalcMgrExcelFORECASTLINEAR`](../15_CalcMgr_Utility/@CalcMgrExcelFORECASTLINEAR.md).
   - **List & Set Lookups**: [`@CalcMgrGetListItem`](../11_Date_Time/@CalcMgrGetListItem.md), [`@CalcMgrGetListCount`](../11_Date_Time/@CalcMgrGetListCount.md), [`@CalcMgrIsInList`](../15_CalcMgr_Utility/@CalcMgrIsInList.md), [`@CalcMgrSortList`](../15_CalcMgr_Utility/@CalcMgrSortList.md).

---

> **Tip for Trainees**: When looking for Excel string/lookup logic in Calc Manager, look in category `10_String` for native string processing and category `15_CalcMgr_Utility` for CDF utility functions.

# Oracle EPM Calculation Manager: Master Engineering Architecture Guide

## 1. Directory Structure and Architectural Map

This directory contains the definitive, exhaustive technical documentation for Oracle Hyperion / EPM Cloud **Calculation Manager**, business rule engineering, palette components, system templates, variable scoping, execution optimization, Groovy rules, and enterprise troubleshooting.

```
Calc Manager/Calculations_and_Allocations/
|-- 00_INDEX.md                                                  (Master Architectural Index)
|-- 01_UI_Canvas_and_Navigation/
|   |-- 01_System_Views_and_Architecture.md                      (System/Database/Custom/Deployment views, schema)
|   |-- 02_Toolbar_Buttons_Screens_and_Visual_Design.md          (Toolbar buttons catalog, visual canvas mechanics)
|   `-- 03_Rule_Editor_Dual_Modes_Visual_vs_Script.md            (Visual vs Script mode, auto-sync, concurrency locks)
|-- 02_Palette_Objects_Deep_Dive/
|   |-- 01_Formula_Component.md                                  (LHS/RHS assignment, dense vs sparse targets)
|   |-- 02_Script_Component.md                                   (Raw Essbase script embedding, variable tokens)
|   |-- 03_Condition_Component_IF_ELSEIF_ELSE.md                 (Visual branching, relational ops, sparse IF trap)
|   |-- 04_Member_Block_Component.md                             (Anchor calculations, dense vs sparse blocks)
|   |-- 05_Member_Range_Component_LOOP.md                        (Sequential traversal, @CURRMBR, @PRIOR roll-forward)
|   |-- 06_FIX_Component.md                                      (Multidimensional slicing, block filtering, empty FIX)
|   `-- 07_Rule_and_RuleSet_Objects.md                           (Sequencing rules, variable merging, parallel execution)
|-- 03_System_Templates_Deep_Dive/
|   |-- 01_Allocation_Template.md                                (Standard 6-part allocation, pools, drivers, offsets)
|   |-- 02_Allocate_Level_to_Level_Template.md                   (Cascading waterfall allocations, parent offsets)
|   |-- 03_Clear_Data_Template.md                                (Physical CLEARBLOCK vs Logical CLEARDATA, ASO clear)
|   |-- 04_Copy_Data_Template.md                                 (Block-level DATACOPY vs cell assignment loops)
|   |-- 05_Amount_Rate_Template.md                               (Driver-based modeling, volume x rate equations)
|   |-- 06_Aggregation_Template.md                               (CALC DIM vs AGG, Hourglass principle, Hybrid BSO)
|   |-- 07_Currency_Conversion_Template.md                       (P&L vs Balance Sheet rates, rate tables, triangulation)
|   |-- 08_Custom_Design_Time_Prompt_Templates.md                (Building custom wizards, DTP types, condition prompts)
|   `-- Allocation_Master_Guides/                                (Retained Deep-Dive Master Reference Guides)
|       |-- Oracle_EPM_Allocation_Master_Guide.md                (Retained Comprehensive Allocation Guide - 66KB)
|       |-- Oracle_EPM_Allocation_Template_Guide.md              (Retained Allocation Template Deep Dive - 30KB)
|       |-- Oracle_EPM_Allocate_Level_to_Level_Guide.md          (Retained Level-to-Level Cascading Guide - 32KB)
|       `-- Oracle_EPM_Return_Function_Master_Guide.md           (Retained @RETURN Function Reference - 9.6KB)
|-- 04_Variables_and_Prompts/
|   |-- 01_Variable_Architecture_and_Scopes.md                   (4 Scopes, 10 data types, SubVars vs CalcVars)
|   |-- 02_Runtime_Prompts_RTP_Configuration.md                  (RTP configuration, member limits, headless CLI)
|   `-- 03_Design_Time_Prompts_DTP_and_Wizards.md                (DTP vs RTP matrix, dynamic code generation)
|-- 05_Calculation_Engine_and_Performance/
|   |-- 01_Execution_Modes_BottomUp_vs_TopDown.md                (Engine internals, @CALCMODE, forcing bottom-up)
|   |-- 02_Block_Creation_and_Data_Integrity.md                  (Sparse block creation, SET CREATEBLOCKONEQ bloat)
|   |-- 03_SET_Commands_Mastery_and_Memory_Buffers.md            (Exhaustive SET commands reference, cache sizing)
|   `-- 04_Hybrid_BSO_Calculation_Optimization.md                (Hybrid BSO dynamic sparse calc, retired AGG scripts)
|-- 06_Groovy_Business_Rules/
|   |-- 01_Groovy_Rule_Architecture_in_Calc_Manager.md           (JVM sandbox, Planning object model, lifecycle)
|   |-- 02_Dynamic_FIX_Generation_and_Context_Slicing.md         (Micro-slice generation from edited cells, 147x speedup)
|   `-- 03_Data_Grid_Calculations_and_Veto_Exceptions.md         (throwVetoException, pre-save validation, rich alerts)
|-- 07_Administration_Troubleshooting_and_Interview_Bible/
|   |-- 01_Rule_Deployment_Validation_and_LCM_Migration.md       (Validation compiler, deployment lifecycle, LCM XML)
|   |-- 02_Security_Roles_and_Action_Menu_Form_Attachment.md     (Service Admin vs Power User, form save, action menus)
|   |-- 03_Debugging_Techniques_and_Best_Practices.md            (SETERRORONMISSINGMBR, @RETURN diagnostics, 10 rules)
|   `-- 04_Comprehensive_Calc_Manager_Interview_Bible.md         (30 Architect-level interview Q&A and scenarios)
```

---

## 2. High-Level Concept Cross-Reference Matrix

| Category | Component / Concept | Primary File Reference | Key Technical Takeaway |
| :--- | :--- | :--- | :--- |
| **Canvas** | Visual Flowchart vs Script | `01_UI_Canvas_and_Navigation/03_Rule_Editor_Dual_Modes_Visual_vs_Script.md` | Non-standard syntax permanently converts rules to Script-Only mode. |
| **Concurrency** | Object Locks | `01_UI_Canvas_and_Navigation/03_Rule_Editor_Dual_Modes_Visual_vs_Script.md` | Stored in `HSP_CALCMGR_LOCKS`; can be cleared via UI or SQL. |
| **Performance** | Bottom-Up vs Top-Down | `05_Calculation_Engine_and_Performance/01_Execution_Modes_BottomUp_vs_TopDown.md` | Top-Down is 300x slower; avoid sparse IF statements. |
| **Integrity** | Block Creation Bloat | `05_Calculation_Engine_and_Performance/02_Block_Creation_and_Data_Integrity.md` | `SET CREATEBLOCKONEQ ON` without strict FIX causes gigabyte database bloat. |
| **Modernization**| Hybrid BSO Optimization | `05_Calculation_Engine_and_Performance/04_Hybrid_BSO_Calculation_Optimization.md` | Dynamic sparse calc eliminates batch `AGG` and `CALC DIM` scripts entirely. |
| **Form Intercept**| Groovy Dynamic Micro-FIX | `06_Groovy_Business_Rules/02_Dynamic_FIX_Generation_and_Context_Slicing.md` | Slices calc to `cell.isEdited()`; cuts save latency from 45s to 200ms. |
| **Validation** | Pre-Save Veto Alert | `06_Groovy_Business_Rules/03_Data_Grid_Calculations_and_Veto_Exceptions.md` | `throwVetoException()` rolls back dirty blocks atomically with custom HTML alerts. |
| **Tuning** | SET Commands | `05_Calculation_Engine_and_Performance/03_SET_Commands_Mastery_and_Memory_Buffers.md` | Always set `CACHE HIGH`, `LOCKBLOCK HIGH`, `UPDATECALC OFF`, `AGGSPARSESEL ON`. |
| **Diagnostics** | `@RETURN` Function | `07_Administration_Troubleshooting_and_Interview_Bible/03_Debugging_Techniques_and_Best_Practices.md` | Programmatically halts script and injects custom error strings into UI. |

---

## 3. Quick Reference Navigation Links

- **UI & Views**: [01_System_Views_and_Architecture.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/01_UI_Canvas_and_Navigation/01_System_Views_and_Architecture.md)
- **Toolbar Buttons**: [02_Toolbar_Buttons_Screens_and_Visual_Design.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/01_UI_Canvas_and_Navigation/02_Toolbar_Buttons_Screens_and_Visual_Design.md)
- **Palette Components**: [01_Formula_Component.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/02_Palette_Objects_Deep_Dive/01_Formula_Component.md) | [06_FIX_Component.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/02_Palette_Objects_Deep_Dive/06_FIX_Component.md)
- **Templates**: [01_Allocation_Template.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/03_System_Templates_Deep_Dive/01_Allocation_Template.md) | [06_Aggregation_Template.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/03_System_Templates_Deep_Dive/06_Aggregation_Template.md)
- **Variables & RTPs**: [01_Variable_Architecture_and_Scopes.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/04_Variables_and_Prompts/01_Variable_Architecture_and_Scopes.md) | [02_Runtime_Prompts_RTP_Configuration.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/04_Variables_and_Prompts/02_Runtime_Prompts_RTP_Configuration.md)
- **Engine Performance**: [01_Execution_Modes_BottomUp_vs_TopDown.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/05_Calculation_Engine_and_Performance/01_Execution_Modes_BottomUp_vs_TopDown.md) | [03_SET_Commands_Mastery_and_Memory_Buffers.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/05_Calculation_Engine_and_Performance/03_SET_Commands_Mastery_and_Memory_Buffers.md)
- **Groovy Rules**: [01_Groovy_Rule_Architecture_in_Calc_Manager.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/06_Groovy_Business_Rules/01_Groovy_Rule_Architecture_in_Calc_Manager.md) | [02_Dynamic_FIX_Generation_and_Context_Slicing.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/06_Groovy_Business_Rules/02_Dynamic_FIX_Generation_and_Context_Slicing.md)
- **Troubleshooting & Interview Bible**: [03_Debugging_Techniques_and_Best_Practices.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/07_Administration_Troubleshooting_and_Interview_Bible/03_Debugging_Techniques_and_Best_Practices.md) | [04_Comprehensive_Calc_Manager_Interview_Bible.md](file:///d:/OneDrive%20-%20Orbrick/Oracle%20EPM/Oracle%20EPM%20Docs%20with%20Examples/Calc%20Manager/Calculations_and_Allocations/07_Administration_Troubleshooting_and_Interview_Bible/04_Comprehensive_Calc_Manager_Interview_Bible.md)

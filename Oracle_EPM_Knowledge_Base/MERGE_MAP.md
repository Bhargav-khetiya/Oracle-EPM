# Merge Map — Source Provenance Register

> This document maps every original source file to its destination in the merged knowledge base. It serves as the provenance register for traceability.

---

## Source Folder Summary

| Source | Original Path | Files | Archive Path | Archive Verified |
|--------|-------------|-------|-------------|-----------------|
| **ChatGPT** | `Oracle EPM Chatgpt/` | 728 | `Oracle_EPM_Source_Archive/ChatGPT/` | ✅ 728 files matched |
| **Claude** | `Oracle EPM Cluade/` | 342 | `Oracle_EPM_Source_Archive/Claude/` | ✅ 342 files matched |
| **Gemini** | `Oracle EPM gemini/` | 699 | `Oracle_EPM_Source_Archive/Gemini/` | ✅ 699 files matched |
| **Total** | | **1,769** | | All verified |

---

## Mapping: Source → Destination

### 00_Foundation

| Source Family | Source Path | Destination |
|---|---|---|
| Claude | `00_Study_Path/00.05_What_Is_EPM_For_Absolute_Beginners.md` | `00_Foundation/01_What_Is_EPM.md` |
| Claude | `01_Foundation/01.01_Enterprise_Performance_Management.md` | `00_Foundation/01_What_Is_EPM.md` |
| ChatGPT | `README.md`, `LEARNING_ROADMAP.md` | `00_Foundation/01_What_Is_EPM.md`, `00_Foundation/04_Study_Path.md` |
| Gemini | `START_HERE.md`, `LEARNING_ROADMAP.md`, `README.md` | `00_Foundation/01_What_Is_EPM.md`, `00_Foundation/04_Study_Path.md` |
| Claude | `01_Foundation/01.06_Cloud_Architecture_and_OCI.md` | `00_Foundation/02_EPM_Architecture.md` |
| Claude | `01_Foundation/01.01_EPM_Architecture_Overview.md` | `00_Foundation/02_EPM_Architecture.md` |
| Claude | `01_Foundation/01.05_Hyperion_History_and_Cloud_Evolution.md` | `00_Foundation/03_EPM_History.md` |
| Claude | `00_Study_Path/00.01_Master_Learning_Roadmap.md` | `00_Foundation/04_Study_Path.md` |
| Claude | `01_Foundation/01.02_Business_Concepts.md` | `02_Finance_Concepts/` |
| Claude | `02_Finance/` (all files) | `02_Finance_Concepts/` |

### 01_Security_and_Access

| Source Family | Source Path | Destination |
|---|---|---|
| ChatGPT | `01_Security_and_Access/Oracle_EPM_Access_Control_Master_Guide.md` | `01_Security_and_Access/01_Access_Control_and_Roles.md` |
| ChatGPT | `01_Security_and_Access/Oracle_EPM_Valid_Intersections_Master_Guide.md` | `01_Security_and_Access/02_Valid_Intersections.md` |
| Claude | `12_Security/` (all files) | `01_Security_and_Access/01_Access_Control_and_Roles.md` |
| Gemini | `01_Security_and_Access/` (all files) | `01_Security_and_Access/` (merged) |

### 02_User_Interface_and_Navigation

| Source Family | Source Path | Destination |
|---|---|---|
| ChatGPT | `02_User_Interface_and_Navigation/` (all files) | `02_User_Interface_and_Navigation/` |
| ChatGPT | `Form_Properties/` (all files) | `02_User_Interface_and_Navigation/04_Form_Design.md` |
| Claude | `06_Forms/` (all files) | `02_User_Interface_and_Navigation/04_Form_Design.md` |
| Claude | `28_Screen_Encyclopedia/` | `02_User_Interface_and_Navigation/` |
| Claude | `33_Navigation_Encyclopedia/` | `02_User_Interface_and_Navigation/` |
| Gemini | `02_User_Interface_and_Navigation/`, `Form_Properties/` | `02_User_Interface_and_Navigation/` |

### 05_Calc_Manager_and_Business_Rules

| Source Family | Source Path | Destination |
|---|---|---|
| ChatGPT | `Calc Manager/` (30+ files in 7 subdirectories) | `05_Calc_Manager_and_Business_Rules/` |
| Claude | `07_Business_Rules/` (all files) | `05_Calc_Manager_and_Business_Rules/` |
| Claude | `08_Calculation_Manager/` (all files) | `05_Calc_Manager_and_Business_Rules/` |
| Gemini | `Calc Manager/` (30+ files in 7 subdirectories) | `05_Calc_Manager_and_Business_Rules/` |

### 06_Data_Integration_and_Exchange

| Source Family | Source Path | Destination |
|---|---|---|
| ChatGPT | `Data_Integration/` (all files) | `06_Data_Integration_and_Exchange/01_Overview.md` |
| ChatGPT | `Data_Maps_and_Exchange/` (20+ files in 6 subdirectories) | `06_Data_Integration_and_Exchange/02-07` |
| Claude | `11_Data_Integration/` (all files) | `06_Data_Integration_and_Exchange/` |
| Gemini | `Data_Integration/`, `Data_Maps_and_Exchange/` | `06_Data_Integration_and_Exchange/` |

### 07_Essbase_Architecture

| Source Family | Source Path | Destination |
|---|---|---|
| ChatGPT | `Essbase_Internal_Architecture/` (17 files) | `07_Essbase_Architecture/` |
| Claude | `03_Essbase/` (6 files) | `07_Essbase_Architecture/` |
| Gemini | `Essbase_Internal_Architecture/` (17 files) | `07_Essbase_Architecture/` |

### 08_Dimensions_and_Metadata

| Source Family | Source Path | Destination |
|---|---|---|
| ChatGPT | `Dimension_Properties/` (12 files) | `08_Dimensions_and_Metadata/` |
| Claude | `05_Metadata/`, `29_Property_Encyclopedia/` | `08_Dimensions_and_Metadata/` |
| Gemini | `Dimension_Properties/` (12 files) | `08_Dimensions_and_Metadata/` |

### 09_EPBCS_Modules

| Source Family | Source Path | Destination |
|---|---|---|
| ChatGPT | `EPBCS_Modules_and_Business_Processes/` (8+ files) | `09_EPBCS_Modules/` |
| Claude | `04_Planning/` (all files) | `09_EPBCS_Modules/` |
| Gemini | `EPBCS_Modules_and_Business_Processes/` (8+ files) | `09_EPBCS_Modules/` |

### Other Sections

| Source Family | Source Path | Destination |
|---|---|---|
| ChatGPT/Gemini | `Smart_View_and_Ad_Hoc/` | `10_Smart_View/` |
| Claude | `10_Smart_View/` | `10_Smart_View/` |
| ChatGPT/Gemini | `Smart_Lists/` | `11_Smart_Lists/` |
| ChatGPT/Gemini | `EPM_Automate/` | `12_EPM_Automate/` |
| Claude | `14_EPM_Automate/` | `12_EPM_Automate/` |
| ChatGPT/Gemini | `Action_Menus/` | `13_Action_Menus/` |
| ChatGPT/Gemini | `05_Application_Creation_and_Lifecycle_Management/` | `14_Application_Lifecycle/` |
| ChatGPT/Gemini | `Techno_Functional_Consultant_Review_Bible/` | `15_Professional_Development/` |
| Claude | `21_Interview/`, `24_Architect_Masterclass/`, `19_Implementation/` | `15_Professional_Development/` |
| Claude | `16_Performance/` | `16_Performance_Tuning/` |
| Claude | `22_Labs/`, `23_Case_Studies/` | `17_Labs_and_Case_Studies/` |
| Claude | `25_CheatSheets/`, `26_Glossary/`, `27_Certification/` | `18_Reference/` |
| Claude | `30_Function_Reference/`, `31_Error_Encyclopedia/`, `32_Member_Formula_Encyclopedia/` | `18_Reference/` |
| Claude | `09_Groovy/` | `03_Groovy_Scripting/` |
| Claude | `13_REST_API/` | `04_REST_API/` |
| ChatGPT/Gemini | `Reference_Materials/` | `18_Reference/` |

### Archived (Not in Learner-Facing KB)

| Source Family | Source Path | Reason |
|---|---|---|
| ChatGPT | `_review/backups/` | Pre-existing backup files — preserved in archive |
| ChatGPT/Gemini | `.vscode/` | Editor configuration — not learner content |
| Gemini | `prompt.txt` | Generation prompt — preserved in archive |
| Claude | `.agents/AGENTS.md` | Agent configuration — not learner content |
| Claude | `.git/` | Version control — preserved in archive |
| Claude | `Master_Prompt_v2.md` | Generation prompt — preserved in archive |
| Claude | `books/` (53 Oracle PDFs) | Official Oracle PDFs — preserved in archive, referenced by links |
| Claude | `EPM_Skymap.png` | Image — preserved in archive |

---

## Verification Notes

- All 1,769 source files have been archived before any content changes
- Archive file counts verified: ChatGPT 728=728, Claude 342=342, Gemini 699=699
- Archive copies preserved in `Oracle_EPM_Source_Archive/` alongside this knowledge base
- Original source folders remain untouched (read-only inputs)


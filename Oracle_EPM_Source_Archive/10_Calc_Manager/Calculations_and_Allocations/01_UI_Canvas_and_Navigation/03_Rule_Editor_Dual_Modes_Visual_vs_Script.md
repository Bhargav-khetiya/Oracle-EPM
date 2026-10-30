# 03 Dual Editing Modes: Visual Flowchart vs. Script Editor & Concurrency Locks

## 1. Visual Flowchart vs. Script Editor Architecture

Calculation Manager provides two fundamentally different paradigms for authoring business logic:
1. **The Visual Flowchart Canvas**: A declarative, drag-and-drop interface where rules are composed using visual components (FIX blocks, Formula cards, IF/ELSE branches, Templates).
2. **The Script / Code Editor**: A high-performance text-based IDE providing direct access to raw Essbase calculation syntax or Groovy scripting.

```
+---------------------------------------------------------------------------------------------------+
|                                 DUAL-MODE SYNCHRONIZATION ENGINE                                  |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  +----------------------------------+                   +----------------------------------+      |
|  |     VISUAL FLOWCHART CANVAS      |                   |       SCRIPT / CODE EDITOR       |      |
|  | - Drag-and-drop components       |                   | - Direct Essbase / Groovy code   |      |
|  | - Declarative member selection   |                   | - Syntax highlighting, Intellisense|    |
|  +----------------------------------+                   +----------------------------------+      |
|                   \                                                       /                       |
|                    \                                                     /                        |
|                     v                                                   v                         |
|         +-------------------------------------------------------------------+                     |
|         |               BI-DIRECTIONAL AST PARSING ENGINE                   |                     |
|         |             (Abstract Syntax Tree Auto-Converter)                 |                     |
|         +-------------------------------------------------------------------+                     |
|                                           |                                                       |
|                                           v                                                       |
|         +-------------------------------------------------------------------+                     |
|         | RELATIONAL REPOSITORY ARTIFACT (HSP_CALCMGR_RULES)                |                     |
|         | Serialized XML Object storing visual layout AND compiled script   |                     |
|         +-------------------------------------------------------------------+                     |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Bi-Directional Auto-Synchronization and "Script-Only" Lockout

When switching between the **Designer (Flowchart)** tab and the **Edit Script** tab:
* The bi-directional AST parser converts visual objects into clean Essbase script blocks.
* Edits made directly in the Script Editor are parsed back into visual flowchart blocks when returning to the Designer tab.

### The "Script-Only" Trap
If a developer enters raw Essbase syntax in Script Mode that Calculation Manager's visual parser cannot represent as a discrete graphical component, the system will **permanently lock the rule into Script-Only mode**.
* **Constructs that Break Visual Flowcharts**:
  * Highly intricate, non-standard nested `@CALCMODE` declarations.
  * Direct low-level Essbase C-style pointer manipulations or custom Java CDF calls.
  * Non-standard macro expansions or unbalanced semicolon structures.
* **Warning Dialog**: *"This script cannot be converted into graphical components. Switching to Designer mode will discard unsupported syntax, or you can maintain this rule in Script-Only mode."*
* **Best Practice**: For complex algorithmic calculations, explicitly designate the rule as **Script Mode** from the outset to avoid accidental visual corruption.

---

## 3. Concurrency, Collaboration, and Lock Resolution

In multi-developer enterprise environments, concurrent modifications to rules must be strictly isolated to prevent overwrite collisions.

### 3.1 Lock Acquisition Mechanics
When a user opens a Business Rule, Rule Set, or Template in Calculation Manager:
1. The platform checks `HSP_CALCMGR_LOCKS` for the object's unique identifier (`OBJECT_ID`).
2. If unlocked, the system inserts an active lock record containing the user's login ID, workstation IP, and an active timestamp.
3. If another developer attempts to open the same rule, Calculation Manager opens it in **Read-Only Mode** and displays a warning:
   `Object is locked by user: john.doe@acme.com since 2026-10-30 09:15:22.`

### 3.2 Resolving Orphaned Locks
If a developer's browser crashes, network disconnects, or session times out, the lock may remain orphaned in the repository, blocking other administrators.

#### Administrative UI Unlock:
1. In Calculation Manager, navigate to **Tools -> Locks**.
2. Select the locked artifact from the table.
3. Click the **Unlock** toolbar button (Requires Service Administrator role).

#### Low-Level Relational Repository Unlock (Emergency DBA Procedure):
If the Web UI is inaccessible, the DBA can inspect and clear the lock table:
```sql
-- Query active Calculation Manager locks
SELECT 
    l.OBJECT_ID, 
    r.RULE_NAME, 
    l.USER_ID, 
    l.LOCK_TIMESTAMP 
FROM HSP_CALCMGR_LOCKS l
JOIN HSP_CALCMGR_RULES r ON l.OBJECT_ID = r.RULE_ID;

-- Release specific orphaned lock
DELETE FROM HSP_CALCMGR_LOCKS 
WHERE OBJECT_ID = (SELECT RULE_ID FROM HSP_CALCMGR_RULES WHERE RULE_NAME = 'Alloc_Corporate_Overhead');
COMMIT;
```


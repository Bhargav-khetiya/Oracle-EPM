# Accessibility Guide — Complete Markdown Edition

> **Original PDF:** `Accessibility_Guide.pdf` | **Folder:** Level 1 (Beginner & Foundations)  
> **Purpose:** Comprehensive Markdown extraction and deep reference of Oracle EPM Cloud Accessibility standards, screen reader compatibility, and WCAG 2.1 compliance.

---

## Table of Contents
1. [WCAG 2.1 Compliance & Section 508 Standards](#wcag-21-compliance)
2. [Enabling Accessibility Mode in EPM Cloud](#enabling-accessibility-mode)
3. [Keyboard Navigation & Shortcut Matrix](#keyboard-navigation)
4. [Screen Reader Optimization (JAWS & NVDA)](#screen-reader-optimization)
5. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. WCAG 2.1 Compliance & Section 508 Standards <a name="wcag-21-compliance"></a>

Oracle EPM Cloud UI follows the **Redwood Experience**, which conforms to **Web Content Accessibility Guidelines (WCAG) 2.1 Level AA** and US Section 508 accessibility specifications.

### Key Architectural Standards
- **High Contrast Rendering:** All system icons, banners, and grid text maintain a minimum contrast ratio of `4.5:1` against background fills.
- **Non-Color Dependent Indicators:** Cell status (e.g., read-only `#NoAccess`, dirty cell flags, calculation errors) is indicated by both color coding AND distinct iconography/shape markers so color-blind users can navigate forms without loss of information.

---

## 2. Enabling Accessibility Mode in EPM Cloud <a name="enabling-accessibility-mode"></a>

By default, standard web forms render using complex HTML multi-table grid wrappers to support fixed headers and floating POV bars. Screen readers (`JAWS`, `NVDA`) struggle to parse multi-table floating divs.

### How to Activate Accessibility Mode
1. Navigate to `Tools -> User Preferences -> Display`.
2. Locate the **Accessibility Mode** setting and toggle to **Yes / Enabled**.
3. Log out and log back into the application.

### Technical Impact of Accessibility Mode on HTML DOM
- **Linear Grid Flattening:** Converts multi-layered HTML grid tables into a single, linearized `<table>` element with explicit `<th>` scope attributes (`col` / `row`).
- **ARIA Live Regions:** Activates HTML5 `aria-live="polite"` banners so status messages (e.g., *"Calculation in progress"*, *"Data submitted successfully"*) are voiced immediately by screen readers without requiring focus shift.

---

## 3. Keyboard Navigation & Shortcut Matrix <a name="keyboard-navigation"></a>

Every action in EPM Cloud can be executed using keyboard shortcuts without mouse interaction.

| Action / Command | Shortcut (Windows) | Shortcut (Mac) | Screen Reader Note |
| :--- | :--- | :--- | :--- |
| **Move to Next Cell in Grid** | `Tab` or `Right Arrow` | `Tab` or `Right Arrow` | Reads cell coordinates (`Row Header, Column Header, Value`). |
| **Move to Previous Cell** | `Shift + Tab` or `Left Arrow` | `Shift + Tab` or `Left Arrow` | Reads previous intersection. |
| **Open Dropdown / Smart List** | `Alt + Down Arrow` | `Option + Down Arrow` | Expands accessible selection box. |
| **Submit Form Data (Save)** | `Ctrl + Alt + S` | `Command + Option + S` | Triggers background save and voices completion banner. |
| **Refresh Grid Data** | `Ctrl + Alt + R` | `Command + Option + R` | Reloads POV slice from Essbase. |
| **Open Runtime Prompt Dialog** | `Ctrl + Alt + P` | `Command + Option + P` | Focus moves directly to first input prompt. |

---

## 4. Screen Reader Optimization (JAWS & NVDA) <a name="screen-reader-optimization"></a>

### Recommended Screen Reader Settings for EPBCS
- **Forms Navigation:** Turn **Virtual PC Cursor OFF** (`JAWS Key + Z`) when inside an active data entry form so arrow keys navigate Essbase cells rather than reading raw HTML source code.
- **Dialog Boxes:** When launching Business Rules with Runtime Prompts (RTPs), screen reader focus automatically traps inside the modal dialog (`aria-modal="true"`), preventing accidental background navigation until the prompt is submitted or canceled.

---

## 5. Cross-Reference in Course Modules <a name="cross-reference"></a>

The concepts from this official guide have been deeply integrated into the following repository modules:
- **`00_Foundation/01_EPM_Foundations.md`** — UI accessibility features and user profile setup.
- **`16_Administration/03_Admin_Specialized_Deep_Reference.md`** — Enterprise accessibility audit compliance and user preferences management.
- **`24_Architect_Masterclass/01_The_Springboard_and_Settings_Map.md`** — `Application -> Settings` and UI behavioral toggles.

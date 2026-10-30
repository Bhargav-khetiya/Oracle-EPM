# Oracle EPM Cloud: The Ultimate Master Guide to Dashboards 2.0

## 1. Introduction to Dashboards
Dashboards in Oracle EPM Cloud provide interactive, visual analytics for planners and executives. They transform raw data into visually pleasing, easy-to-read, and impactful charts and grids. With Dashboards 2.0, administrators have immense control over the styling, layout, and data interaction across the application.

---

## 2. Dashboard Styles and Colors
When designing a dashboard, you can select a global color theme called a **style**. These have been intentionally designed to maximize adjacent color differences.
* **Light (Default):** Light background with dark fonts/images/icons.
* **Dark:** Dark background with light fonts/images/icons.
* **White:** Pure white background with dark fonts/images/icons.

### Color Sequencing
To ensure maximum readability, always follow the recommended categorical color palette sequence provided by the system.
* **Semantic Colors:** When colors must convey meaning, strictly reserve standard colors: Red for negative/outflow, Grey for neutral, and Green/Blue for positive/inflow.

---

## 3. Supported Objects and Chart Types
Dashboards can host multiple object types:
* **Forms / Grids:** Standard data entry grids, both read-only and write-back capable.
* **Charts:** Bar, Column, Line, Pie, Ring, Gauge, Doughnut, Waterfall, Scatter, etc.
* **External Links (URLs):** Embedded external web pages.
* **Commentary / Text:** Static descriptive text or dynamic cell text.

> [!WARNING]
> **Dashboard Chart Limit & Sizing Rules:** 
> 1. The dashboard layout should be **no more than three panels wide** (a 5-panel layout is generally maximum for a single view before it becomes cluttered).
> 2. Avoid using pie, ring, gauge, and doughnut charts in widths other than **one third**. Ensure if multiple exist, they are all identically sized.

---

## 4. Master Details Dashboards (Dynamic Filtering)
A "Master Details" dashboard features one **master form** driving multiple **detail (target) forms or charts**. When a user selects a row in the master form, the target charts update to show only details relevant to that specific row.

**How to Configure and Use:**
1. **Design:** Place dimension members in the **rows** for the master form. Repeat those exact same dimensions in the **Page** level for all detail forms/charts.
2. **Apply Context:** In the front-end, a user selects a data row in the master form, right-clicks, and selects **Apply Context**. All target grids and charts instantly update based on that row.
3. **Variables:** The *Apply Context* feature supports:
   * **User Variables:** Can be used on Rows, Columns, and Pages. *(Must have the "Use Context" option enabled).*
   * **Substitution Variables:** Can only be used on Pages.

---

## 5. Best Practices for Front-End Design

### Readability & POVs
* **Text Alignment:** Always left-align text. Avoid centering or right-aligning.
* **Grid Lines:** Use grid lines in all charts to improve data tracing.
* **Negative Numbers:** Always format negative numbers in red.
* **POV Optimization:**
  * **Auto-Apply:** Enable `POV : Auto-Apply` in settings so charts refresh instantly when a POV changes, eliminating extra clicks.
  * **Global POV Bar:** Enable this in General Settings to merge identical Page/POV dimensions across multiple components into one single drop-down at the top, saving valuable screen real estate.
  * **Hide Dimension Labels:** If a member name is self-explanatory (e.g., "USD"), hide the "Currency" dimension label to reduce clutter.

### Spacing and Alignment
* **Fill Area:** Ensure grids fill their entire designated panel area.
* **Legend Placement:** Place legends below charts rather than to the side. This guarantees that the X-axis lines of stacked charts align perfectly with one another.
* **Consolidation:** Combine charts with similar data (e.g., Operating and Non-Operating Cashflow) into a single chart to save space.

### Consistency
* **Typeface:** Use a single, consistent typeface (like Oracle Sans) and no more than three font sizes (Titles, Labels, Content).
* **Labels:** Use labels in the exact same order everywhere (e.g., Inflow always before Outflow).
* **Titles:** Ensure every single chart and grid has a clear title.

---

## 6. What Senior Consultants Expect You to Know (Back End & Architecture)

> [!TIP]
> **Performance over Complexity**
> Senior architects expect Dashboards to load quickly. Dashboards execute the underlying Data Forms when they render. If you place 6 complex forms on a single dashboard, the system is executing 6 queries simultaneously. Always optimize the underlying forms (suppress missing data, limit rows) before attaching them to a dashboard.

> [!IMPORTANT]
> **Migration and LCM**
> Dashboards are metadata artifacts. They are migrated via LCM under the "Planning" or "Dashboards" node. However, a dashboard is useless without its underlying forms, rules, and dimensions. Seniors expect you to always migrate the dependent Forms and Smart Lists alongside the Dashboard artifact.

> [!CAUTION]
> **Mobile Interface Limitations**
> Dashboards render differently on mobile devices and tablets. A 3-panel wide dashboard on a desktop will stack vertically on a phone. Seniors expect you to test dashboards across resolutions and rely heavily on the Global POV to ensure mobile users aren't overwhelmed by repetitive drop-downs.

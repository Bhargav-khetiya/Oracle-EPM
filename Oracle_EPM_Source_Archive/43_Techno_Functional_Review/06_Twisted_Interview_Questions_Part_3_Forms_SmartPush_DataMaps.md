# 06 Twisted Interview Questions — Part 3: Forms, Smart Push & Data Movement

## Master Review Survival Guide: 30 Wicked Forms & Data Movement Trap Questions

---

### Q1: What causes an `HTTP 504 Gateway Timeout` when saving a Web Form with Smart Push enabled?
**Answer**:
This almost always occurs when **"Use Form Context" is left UNCHECKED** on the form's Smart Push tab! 
* When unchecked, saving the form triggers a **Full Macro-Slice Push** of the entire Data Map definition (millions of cells across all entities and accounts) rather than just the 10 cells visible on the screen.
* The cloud load balancer times out after 60–120 seconds waiting for the massive extraction to finish. Enabling **Use Form Context** immediately drops save latency to $< 1$ second.

---

### Q2: What happens if an Unmapped Source Dimension is left open in a Data Map?
**Answer**:
An unmapped source dimension exists in the source cube but NOT in the target cube. If left open without specifying a single source member, the extraction attempts to pump data from multiple source members into the exact same target coordinate, causing collisions, overwrites, or data duplication. You must select **one single member** (e.g., `Total Plan Element`).

---

### Q3: What happens if an Unmapped Target Dimension is left open in a Data Map?
**Answer**:
An unmapped target dimension exists in the target cube but NOT in the source cube. Essbase cannot store a data cell without having a valid coordinate address for every single one of its dimensions. The Data Map forces you to select a **fixed target member** (e.g., `Periodic` for View, or `No Currency` for Currency) which is automatically appended to every incoming source tuple.

---

### Q4: Why does mapping parent members from a BSO cube to an ASO target cube cause 200% double-counting?
**Answer**:
ASO cubes dynamically aggregate all upper-level parents on the fly at query time. If you push stored parent-level summary data from a BSO cube into an ASO cube alongside the base leaf members, the ASO engine will aggregate the leaf members AND add the stored parent value, resulting in **double-counting (200% inflation)** of all summary coordinates! Always map **`Level 0 Descendants`** for ASO targets.

---

### Q5: What duplicate aggregation rule is used when Data Maps write to an ASO load buffer?
**Answer**:
Data Maps initialize the ASO load buffer with **`ESS_ASO_LOAD_DUPLICATES_ADD`**. If multiple incoming source records map to the same target coordinate (e.g., many-to-one departmental rollup), the load buffer automatically sums their values together upon commit, preventing data loss.

---

### Q6: What is the difference between Synchronous and Asynchronous Smart Push?
**Answer**:
* **Synchronous (Run in Background = False)**: The user interface displays a loading spinner until both source save and target Smart Push are 100% committed. Best for micro-slices ($< 5,000$ cells) where users immediately navigate to summary reporting dashboards.
* **Asynchronous (Run in Background = True)**: Releases the browser interface immediately after the source form saves (1–2s), offloading the data push to the server's background task queue. Best for large grids.

---

### Q7: What is the difference between "Merge All Data" and "Merge Incremental Data" in ASO maintenance?
**Answer**:
* `merge all data`: Reads the massive main slice (`slice_0000.dat`) plus all incremental slices, nets all values, eliminates redundant entries, rebuilds the entire B-Tree index, and writes a single new base slice. Restores peak query performance (takes minutes).
* `merge incremental data`: Leaves `slice_0000.dat` completely untouched. Merges only the small incremental slices into a single incremental slice (`slice_0001.dat`). Runs in seconds; ideal for daytime maintenance.

---

### Q8: When should you pass `with_zero_cells` to `mergeDataSlices`?
**Answer**:
When data is cleared or overwritten in an ASO cube via logical clearing, the coordinate continues to exist in storage as a net-zero cell ($+500$ and $-500$). Passing `with_zero_cells=true` purges coordinates whose net sum is zero, reclaiming disk space and shrinking backup snapshot sizes.

---

### Q9: Why is cross-application `@XREF` across different EPM Cloud pods unsupported?
**Answer**:
`@XREF` relies on legacy Essbase Network Protocol (ENP) over raw TCP ports (1423 and ephemeral ports 32768–33768). In Oracle Cloud Infrastructure (OCI), pods are isolated behind secure perimeter firewalls with strict OAuth/SSO authentication. Raw TCP socket connections between separate cloud pods are blocked for security. Pod-to-pod data movement must use HTTPS REST APIs, Linked Connections, or Data Integration Pipelines.

---

### Q10: What is the mathematical proof of the 439x speedup of Data Maps over `@XREF`?
**Answer**:
* `@XREF` evaluates point-to-point cell by cell: 4,500,000 cells $\times$ 0.8ms round-trip latency = **3,600 seconds (60 minutes)**.
* **Data Maps** extract vectorized MDX slices and stream records directly into low-level C++ load buffers (`EssWriteLoadBuffer`) in packets of 50,000 cells: 4,500,000 cells committed in **8.2 seconds**.
* Speedup factor: $\frac{3,600\text{s}}{8.2\text{s}} \approx \mathbf{439\times \text{ Performance Gain}}$.

---

### Q11: Can you push cell comments and supporting details via Data Maps?
**Answer**:
* If target is **BSO**: **YES**, by toggling "Copy Comments" and "Copy Supporting Details" in Data Map Options.
* If target is **ASO**: **NO**, because ASO cubes do not support relational cell text storage.

---

### Q12: How do you dynamically clear an ASO slice using Groovy before triggering a Data Map?
**Answer**:
```groovy
Cube repCube = operation.application.getCube("OEP_REP")
String clearRegion = "CrossJoin({[Forecast]}, {[FY25]})"
repCube.clearData(clearRegion, Cube.ClearOption.PHYSICAL)
```
This executes an MDX physical clear on the targeted slice before invoking `dataMap.execute()`.

---

### Q13: What happens if a user without write access to the target slice saves a form with Smart Push?
**Answer**:
By default, Smart Push executes under the **security context of the logged-in user**. If the user does not have write access to the target slice, the push fails with an access denied security error, or unauthorized cells are silently skipped. To circumvent this, wrap the push in a Groovy business rule executed with elevated administrator privileges (`map.execute()`).

---

### Q14: What is the difference between a Flex Form and a standard Web Data Form in Smart View?
**Answer**:
* **Standard Web Form**: Rigid grid structure. Users cannot insert Excel rows/columns or rearrange members.
* **Flex Form**: Combines form security and business rules with Excel flexibility. Users can reorder rows, sort, filter, and insert blank Excel rows for notes while preserving data write-back capabilities.

---

### Q15: What is the difference between Form Page, POV, Row, and Column dimensions?
**Answer**:
* **Row / Column**: The visible X and Y axes forming the active data entry grid.
* **Page Dimension**: Dropdown selector at the top that switches the entire visible sheet (e.g., switching from `Dept 10` to `Dept 20`).
* **POV Dimension**: Global fixed context for the form that is static or selected globally across multiple pages.

---

### Q16: How do you make a specific cell Read-Only on a Web Form without altering user security?
**Answer**:
In Form Designer, navigate to the **Segment Properties** for that row or column and check the **"Read-Only"** checkbox, or write a **Validation Rule** that dynamically locks cells based on conditional criteria (e.g., if `Status == "Closed"`).

---

### Q17: What does "Run Before Load" on a form do?
**Answer**:
Fires an attached business rule before the grid cells are fetched from Essbase into the web browser. Used primarily for **data seeding** (e.g., copying prior year actuals into blank forecast blocks before the user views the form).

---

### Q18: What is the purpose of "Suppress Missing Blocks" on a form?
**Answer**:
Instructs the form engine to evaluate sparse block headers and **omit rows where no physical sparse block exists on disk**. This prevents forms from rendering thousands of blank rows, improving form load speed by up to $90\%$.

---

### Q19: How does Cell-Level Security (CLS) interact with Web Data Forms?
**Answer**:
If a user has write access to `Entity` and `Account`, but Cell-Level Security declares `[Actual, FY24]` as Read-Only, the form engine renders those specific cells with a gray background and disables data entry, overriding dimension-level write access.

---

### Q20: What happens if an administrator modifies an outline member referenced in an active Data Map?
**Answer**:
The next time the application database is refreshed, the Data Map is flagged with a red exclamation mark **`[!] Invalid`**. The administrator must open the map, update the mapping to reference an active valid member, and click Save.

---

### Q21: What is the purpose of "Rollup Target Cube" in Data Maps?
**Answer**:
* If target is **ASO**: Executes an incremental aggregate view update to keep reporting dashboards fast.
* If target is **BSO**: Executes a sparse `CALC DIM` on the target. (Warning: Keep disabled for real-time Smart Push to avoid save lag).

---

### Q22: What is the maximum number of cells recommended for a single Web Data Form?
**Answer**:
Oracle best practice recommends keeping active form grids under **10,000 to 25,000 cells** (e.g., 500 rows $\times$ 50 columns). Forms exceeding 50,000 cells cause significant browser DOM rendering delays and memory spikes.

---

### Q23: How do you pass form row/column selections to an Action Menu rule?
**Answer**:
In **Tools -> Action Menus**, check the **"Context Sensitive"** checkbox on the menu item. When a user right-clicks a cell, the row and column members are captured and bound to the rule's Runtime Prompts.

---

### Q24: Can Smart Push move data between two BSO cubes?
**Answer**:
**Yes**. While Smart Push is most frequently used from BSO to ASO, it fully supports BSO-to-BSO data synchronization (e.g., moving Workforce BSO payroll totals into Financials BSO).

---

### Q25: What happens if a user enters text into a numeric cell on a form?
**Answer**:
Client-side validation rejects the entry immediately with a formatting alert, preventing non-numeric strings from reaching the Essbase calculation engine.

---

### Q26: What is the purpose of Dynamic User Variables on forms?
**Answer**:
User Variables allow individual planners to customize their form POV dropdowns (e.g., setting their personal default Entity or Department) without affecting other users.

---

### Q27: How do you configure a form so that saving it triggers a calculation and then pushes data?
**Answer**:
1. Under the form's **Business Rules** tab, attach the calculation rule under **Run After Save**.
2. Under the form's **Smart Push** tab, attach the Data Map with **Run On Save** enabled.
3. The platform guarantees execution order: Form Commits $\to$ Business Rule Calculates $\to$ Smart Push Transmits.

---

### Q28: What is the difference between Physical Clear and Compensation Slice in ASO Data Maps?
**Answer**:
* **Physical Clear**: Executes an MDX partial clear, slicing the underlying `.dat` storage files.
* **Compensation Slice**: Ingests an inverted sign slice ($+100$ and $-100$), resulting in a net sum of zero without rewriting existing files.

---

### Q29: Can you use Smart Push in Smart View for Excel?
**Answer**:
**Yes**. Smart Push operates natively inside Smart View. When a user submits data on a form grid in Excel, Smart Push triggers automatically in the cloud pod.

---

### Q30: What is the impact of checking "Hide Prompt" on a form's business rule?
**Answer**:
If all Runtime Prompt variables can be resolved from the active form's Page, POV, Row, or Column coordinates, checking "Hide Prompt" suppresses the modal launch dialog, executing the calculation seamlessly in zero clicks.


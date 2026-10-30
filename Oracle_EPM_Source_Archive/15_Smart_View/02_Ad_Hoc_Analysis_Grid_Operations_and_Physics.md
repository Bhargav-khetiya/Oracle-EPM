# 02 — Ad hoc analysis and grid operations

## Core idea

An ad hoc grid lets an authorized user explore selected members and dimensions without being limited to one fixed form layout. Each action changes the visible grid; Refresh and Submit Data have different purposes.

## The grid

A grid can contain dimensions on rows, columns, or the point of view (POV). A row might list Accounts, a column might list Periods, and the POV might select Scenario and Version. This is an illustrative layout, not a project design.

~~~mermaid
flowchart TB
 D[Dimensions and member selections] --> G[Grid with rows, columns, and POV]
 G --> A[Ad hoc operations]
 A --> R[Review returned values and members]
 R --> S[Submit only intended writable changes]
~~~

## Common operations

| Operation | What it does | Check |
|---|---|---|
| Zoom In | Retrieves children, descendants, or another supported level of members | Choose the right zoom level and mode for the provider |
| Zoom Out | Collapses a view to a higher level | Check which parent levels remain |
| Keep Only | Keeps selected members and the required grid structure | Use the warning if selections would invalidate grid layout |
| Remove Only | Removes selected members while retaining a valid grid | Confirm you did not remove required POV context |
| Pivot | Moves a dimension between rows, columns, and POV where supported | Review resulting intersections before submitting |
| Refresh | Retrieves current values and members | Refresh can overwrite unsaved workbook changes |
| Submit Data | Sends eligible changed data to the provider | Check POV, security, and writable cells first |

Smart View documents Next Level, All Levels, and Bottom Level zoom options. Sibling Level, Same Level, and Same Generation are available in Standard-mode applications such as Planning only when the application’s Smart View Ad Hoc Behavior supports them. The provider and client release matter.

## Safe analysis sequence

1. Connect to the intended application and open an ad hoc grid.
2. Confirm the POV and row/column dimensions.
3. Filter or zoom gradually, especially on large hierarchies.
4. Review the resulting member list and totals.
5. Refresh if the POV changed or you need current saved values.
6. Before submitting, verify every edited cell, the active POV, and user write access.
7. Submit the intended changes and review the provider response.

Free-form entry is available for supported providers: users can enter dimension/member names directly into cells to create an ad hoc grid. Follow Oracle’s Free-Form Mode syntax; do not assume any arbitrary worksheet arrangement will be recognized.

## Recall check

1. What is the difference between Refresh and Submit Data? Refresh retrieves; Submit sends eligible changes.
2. Why review the POV before submitting? The write applies to the selected members and current context.
3. Does every provider support every zoom mode? No.

**Teach-back:** Explain what you would check before submitting a changed ad hoc grid to a production plan.

## Oracle references

- [Starting ad hoc analysis](https://docs.oracle.com/en/applications/enterprise-performance-management/smart-view/26.100/uugsv/starting_ad_hoc_analysis.html)
- [Zooming in and out](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svpbc/about_zooming_in_and_out_100x1e6d44c0.html)
- [Selecting members to display when zooming](https://docs.oracle.com/en/applications/enterprise-performance-management/smart-view/26.100/uugsv/selecting_members_to_display_when_zooming.html)
- [Smart View behavior options in Cloud EPM](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svurc/smart_view_behavior_options_epm_cloud_100x3bdf3ac9.html)
- [Submit Data options](https://docs.oracle.com/en/applications/enterprise-performance-management/smart-view/26.100/uugsv/about_the_submit_data_options.html)

Checked 2026-10-30. Exact operations vary by provider and Standard/Native behavior.

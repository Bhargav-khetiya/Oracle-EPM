# Smart List Properties: Configuration Reference

## Core idea
The Properties tab controls a Smart List's identity, ordering, missing-value display, entry source, and member-access filtering.

**Source note:** A raw UI extraction is also present in Reference Materials. It represents a captured interface state, not a universal product contract. Element IDs and disabled/hidden fields can change by release and context; do not build automation around those IDs without supported guidance.

## Main properties

| Property | What it controls | Oracle-documented detail |
|---|---|---|
| Smart List | Unique programmatic name | Alphanumeric characters and underscore; no spaces or special characters |
| Label | Display text for the list | Spaces/special characters allowed |
| Display Order | Sort order in the dropdown | ID, Name, or Label |
| #MISSING Drop-Down Label | Label used for a #MISSING item | Can be selected in the drop-down; #MISSING remains the stored value |
| #MISSING Form Label | How #MISSING appears when the cell is not focused | Drop-Down Setting uses the Smart List label; Form Setting uses the form's missing-value display setting |
| Automatically Generate ID | Whether Oracle generates entry IDs | If cleared, IDs can be customized |
| Create from Members | Builds list entries from dimension hierarchy | Values update when members update; dimension security is honored |
| Member Selection | Selects the members used in a hierarchy-based list | Available for lists created from members |
| Minimum Access Required | Filters hierarchy-based entries by member access | None, Display, Read, or Write have different visibility thresholds |

For exact current descriptions see Oracle's [Setting Smart List Properties](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/adding_or_changing_smart_list_properties.html).

## Missing-value behavior

A display label does not convert #MISSING into text data. Oracle states that the label affects display and #MISSING remains the stored value. With **Form Setting**, the form's missing-value setting determines what appears when the cell is not focused. Test focused/unfocused cells and the form's blank-display setting.

## Create from Members and access

A list can be manually defined or based on a dimension hierarchy. For a hierarchy-based list, the **Minimum Access Required** setting controls which selected members appear according to user access:
- **None:** show all selected list members without applying access filtering.
- **Display:** show members with Display, Read, or Write permission; actual data visibility still follows permission.
- **Read:** show members with Read or Write permission.
- **Write:** show only members with Write permission.

Do not confuse this list filtering with granting a user access to member data. The minimum threshold affects which entries are offered.

## Design decisions

- Choose a meaningful stable name and a user-facing label.
- Choose sort order based on how planners scan the options, not on an assumed workflow.
- If entry IDs matter to rules, formulas, imported data, or reporting, define an environment-promotion control and test it. Do not treat automatic IDs as universally safe or unsafe.
- Use Create from Members only when hierarchy-based, security-aware choices are intended.
- Decide how blank cells should appear; communicate the meaning of an empty selection.

## Illustrative configuration

A hypothetical Forecast Method list has labels “Prior Year,” “Three-Year Average,” and “Manual.” The administrator chooses label sorting for readability and sets the missing label to “Select a method.” Whether that label is shown when the cell is unfocused depends on the #MISSING Form Label and form settings. This example is **illustrative**.

## Validate

1. Confirm the exact Planning service and target cube/member.
2. Set properties, save, and verify the intended values remain.
3. Review Entries and Preview tabs.
4. Test as users with different dimension permissions if based on members.
5. Test focused and unfocused missing cells, dropdown order, and saved values.
6. Validate any rules or integrations that consume the list before promoting the change.

## Recall

**Question:** What is the difference between #MISSING Drop-Down Label and #MISSING Form Label?

**Answer:** One supplies the selectable/display label in the drop-down; the other chooses whether that label or the form's missing-value display is shown when the cell is not focused. Neither changes #MISSING into a text value.

**Teach-back:** Explain how a hierarchy-based Smart List can respect member access and why that does not grant permission.

## Oracle source checked 2026-10-30

- [Setting Smart List Properties](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/adding_or_changing_smart_list_properties.html)
- [Managing Dimensions and evaluation order](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/managing_dimensions.html)

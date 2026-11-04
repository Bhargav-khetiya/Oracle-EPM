# 04 — Flex forms, supporting detail, comments, and attachments

## Core idea

Flex forms provide flexible row or column management while retaining form behavior. Supporting detail, comments, attachments, and change history are separate features with different purposes and access requirements.

## Flex forms

A flex form is configured in the form definition and used through supported Smart View interfaces. Oracle documents flexible row/column member management, including rearranging, sorting, moving, and filtering members. The form’s regular properties and attached rules continue to apply where supported.

Flex forms are not the same as an unrestricted Excel workbook. The changed layout and members are still subject to form definition, metadata validity, access, and provider behavior. Removing a row from a worksheet is not a request to clear cube data; use an explicit supported data-clearing workflow if data must be deleted.

Requirements depend on which axes are flexible and the client. Oracle’s Planning guide lists minimum EPM Cloud and Smart View versions for flex forms; check the current guide and supported client before enabling. Flex forms are available in supported Smart View clients, not as a replacement for the standard web form experience. Suppression and Groovy combinations also have documented limits.

## Supporting detail

Supporting detail provides a structured calculation with text, values, and operators for developing a cell value without adding members to the outline. It is not an Excel formula or a document attachment. Review the hierarchy and parent result after changes, and verify permissions.

## Comments, attachments, and history

- **Comments** explain data assumptions or background. Permissions determine who can add, view, or remove comments.
- **Attachments** provide supporting files or URLs when enabled for the form and allowed by application rules. Check permitted file types, size limits, and filename requirements for the service/version.
- **Change history** displays changes only when data auditing is enabled by the Service Administrator.

Keep sensitive information out of comments and attachments unless the organization has approved that use and access controls.

## Practical sequence

1. Confirm whether users need a standard form or flex behavior.
2. Enable only the intended row/column flex options and confirm the client’s release requirements.
3. Test member entry, invalid members, sort/filter, refresh, and submit.
4. Test supporting detail separately from comments and attachments.
5. Check user permissions and auditing.
6. Confirm which actions change the cell value and which only add supporting context.

## Recall check

1. Does a flex form delete cube data when a user removes a row from the worksheet— No; worksheet layout removal is not a data-clear operation.
2. What is supporting detail for— Building a cell value from a hierarchy of text, values, and operators.
3. What must be enabled for change history— Data auditing.

**Teach-back:** Explain the difference between a comment, an attachment, supporting detail, and a change history record.

## Oracle references

- [About Flex Forms](https://docs.oracle.com/en/applications/enterprise-performance-management/smart-view/26.100/uugsv/flex_forms_about_106x5aa9f7a6.html)
- [Designing Flex Forms](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/designing_flex_forms_100xe1ae74d7.html)
- [Using Suppression Options in Flex Forms](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svuuc/flex_forms_suppression.html)
- [Working with Supporting Details](https://docs.oracle.com/en/applications/enterprise-performance-management/smart-view/26.100/uugsv/p_suptdt_cld.html)
- [Cell comments in EPM Cloud](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svugg/GUID-94345570-E397-4164-B303-BDC53E8DDA10.pdf)
- [Viewing cell history](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svuuc/cell_history.html)
- [Attachments in Smart View](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svsvs/f_launchurl.html)

Checked 2026-10-30. Confirm current client requirements and cell attachment constraints before rollout.

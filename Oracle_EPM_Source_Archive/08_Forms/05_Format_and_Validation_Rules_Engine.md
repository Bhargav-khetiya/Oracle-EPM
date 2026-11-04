# 05 — Format rules and data validation

## Core idea

Format rules help people interpret a form; data validation rules check business conditions and can display messages or affect approval behavior. They are configured as part of the Planning form and must be validated and saved.

## Two rule purposes

| Rule type | Purpose | Example (illustrative) |
|---|---|---|
| Format | Change how a cell appears based on a condition | Highlight a negative variance |
| Data validation | Check whether entered data meets a defined business condition | Show a message when a required driver is blank |

The exact actions depend on the rule definition. Do not assume every failed condition blocks saving: inspect the rule’s action, validation message, and approval options.

## Where rules can apply

The Form Designer supports rules at grid, column, row, or cell locations. The builder can also apply formatting to metadata in applicable areas. When multiple rules at a location have the same precedence, the designer provides ordering controls. Use a narrow rule location where possible and document any overlapping rules.

## Build and validate safely

1. Agree on the policy with the business owner, including threshold, exception, and user-facing wording.
2. In the form Layout, select the relevant location and add a format or data validation rule.
3. Define the condition and action using the builder’s supported choices.
4. Use a message that explains what the user should correct or do next.
5. Select validation options deliberately:
   - Validate only for users with access to the form.
   - Validate only for pages with existing blocks, noting documented exceptions for certain storage properties.
   - Validate only for cells and pages the current user can access, so validation uses that user’s security rather than Service Administrator access.
6. Validate the rule in the builder and correct errors.
7. Preview the form and review validation messages.
8. Save the form; previewing alone does not save rule changes.

Format and data validation rules are stored with the form. Oracle notes that validation rules are checked when the form is loaded or saved. Test as the intended planner user, particularly when access-dependent options are enabled.

## Avoiding common mistakes

- Do not treat cell color as the only signal; include explanatory text or a validation message where needed.
- Do not use an unapproved threshold or imply that an illustrative example is a real project rule.
- Check how several rules combine at the same or overlapping locations.
- Check approval path changes if the rule affects promotional path or status.
- Check accessible pages and valid intersections, not only an administrator preview.
- Save after preview and validation; unsaved designer changes can be lost.

## Test evidence

Keep a small scenario table containing: input condition, expected format/message, save result, user/security context, approval outcome if relevant, and actual result. Include a passing case, failing case, boundary case, and missing-data case.

## Recall check

1. What is the difference between a format rule and a validation rule— One changes presentation; the other evaluates a defined condition and may message or affect approval behavior.
2. Does preview save rule edits— No. Save the form after preview.
3. Why validate as the intended user— Access-dependent validation must reflect that user’s security and accessible intersections.

**Teach-back:** Explain how you would turn an approved planning policy into a testable form rule without inventing a threshold.

## Oracle references

- [Including Data Validation and Format Rules in Forms](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/including_data_validation_rules_in_forms.html)
- [Creating and Updating Data Validation Rules](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/creating_and_updating_data_validation_rules.html)
- [Designing Forms with Data Validation Rules and Form Rules](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/designing_forms_with_data_validation.html)
- [Previewing Forms](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/previewing_forms.html)

Checked 2026-10-30. Rule execution and approval effects depend on the exact rule definition and application workflow.

# 01 — Form properties, precision, suppression, and display

## Core idea

A Planning form combines a data-entry layout with display, validation, and save behavior. A setting changes what a user can see or do; it does not by itself prove how the Cloud service stores or processes data internally.

## Start with the form’s purpose

Before changing settings, record the application, cube, form version (1.0 or 2.0), intended users, data-entry task, and the expected result. A historical extraction mentioned a form named “Data Entry Form For FY 25,26,27-1” on “FinPlan” and showed action-menu and segment values. Treat those as an unverified snapshot from the source notes, not proof of a current customer configuration. Confirm them in the target environment before documenting them as project facts.

Use form instructions to tell users what they need to enter, which POV/page members apply, and how to validate or submit. Keep the instructions user-focused; avoid putting secrets or sensitive data in them.

## Precision: how displayed decimals are controlled

Oracle’s form precision settings cover currency, non-currency, and percentage values. Minimum precision can pad trailing zeros; maximum precision rounds the displayed decimal portion. The form can instead use the currency member’s precision. These are display choices; test important values in the actual form and any downstream report.

| Choice | What it does | Example |
|---|---|---|
| Minimum decimals | Shows at least the selected number of decimal places | Minimum 2: **100 displays as 100.00** |
| Maximum decimals | Limits displayed decimal places, applying rounding | Maximum 3: **100.12345 displays as 100.123** |
| Currency member precision | Uses precision defined for the currency member | Verify with currencies configured for the application |

Set minimum less than or equal to maximum where both are numeric. Decide precision with Finance and reporting owners; do not infer accounting or storage precision from the display.

## Context menus and dynamic user variables

Administrators can associate available Action Menus with a form and set their display order. Menu availability and action behavior depend on the menu definition, user access, and the current context. Test each action as a representative user.

Dynamic user variables are enabled on the form by selecting the relevant variables. This lets a user change the selected variable in the form experience where supported. Confirm the application’s variable definitions and the intended user workflow before enabling it.

## Grid properties and suppression

Suppression controls which empty or invalid rows and columns appear. The best choice depends on the form’s purpose. For data entry, aggressive suppression can hide intersections users need to populate.

| Setting | Practical meaning | Check before enabling |
|---|---|---|
| Suppress missing data (rows/columns) | Hides rows or columns with no data, as applicable | Confirm users can still reach required intersections |
| Suppress missing blocks | Skips missing blocks where applicable | Test both sparse and populated cases; Oracle notes that it can help when many rows are suppressed and can hurt when few or none are suppressed |
| Use Database Suppression | Applies supported suppression closer to the database query rather than only in the business-process tier | Test with the specific form, formulas, Smart View workflow, and suppression selections |
| Suppress invalid data (rows/columns) | Hides rows or columns containing invalid intersections, as configured | Verify that users can recognize why data is unavailable; invalid cells may instead be read-only depending on the setting |
| Suppress missing also suppresses zero | Combines missing and zero suppression behavior | Behavior can vary by form version and options; verify Forms 2.0 guidance and test zero-valued data |

Database suppression is a product option, not a guarantee of a particular speed-up or network reduction. Oracle documents a caveat for formula columns that evaluate to #MISSING: rows can be suppressed before the formula is evaluated. Keep formulas and suppression behavior consistent with the intended results.

A practical test matrix includes: a populated form, an empty form, a sparse form with many missing rows, zero values, formula rows/columns, invalid intersections, and the actual Smart View client if users work there. Compare expected rows and values, not only elapsed time.

## Other grid and display options

- **Autosave:** Oracle describes saving as users navigate between cells and successive undo behavior. Do not describe it as an instant database commit. Test the form’s save, undo, and associated rule behavior in its version.
- **Run Form Calc on Autosave:** evaluate separately with the associated calculation and form; do not enable without checking the calculation’s purpose.
- **Calc On the Fly:** in Forms 2.0 this concerns member formulas and calculations without submitting changes. It is not a substitute for a saved business rule.
- **Remove Form Suppressions in Ad Hoc:** relates to suppression when launching ad hoc from a form. User-level Smart View suppression options can also matter.
- **Pivot rows and columns after load:** changes presentation orientation. Validate with the user’s normal workflow.
- **Display missing values as blank:** changes how missing values appear, not their underlying meaning.
- **Make form read-only / Hide Form:** changes interaction or visibility; neither grants nor revokes underlying data access.
- **Enable Mass Allocate / Grid Spread:** enable only for the intended planning workflow and confirm the required role or access.
- **Cell-level documents / attachments:** verify application settings and user permissions.
- **Message for forms with no data:** use a clear, actionable message that does not imply the data is missing when access or POV selection is the cause.

## Safe configuration sequence

1. Confirm form version, cube, user groups, POV, and data-entry purpose.
2. Set precision and display options to match approved reporting expectations.
3. Choose suppression based on a test matrix; preserve required entry intersections.
4. Configure context menus and user variables only where the workflow requires them.
5. Test as an administrator and as representative planner users.
6. Record the expected grid, save behavior, prompts, and Smart View behavior.
7. Recheck after a form-version change or release-sensitive update.

## Recall check

1. What is the difference between minimum and maximum precision? Minimum pads; maximum limits and rounds displayed decimals.
2. Does a blank display prove the underlying value is zero? No. It may be missing, suppressed, filtered, or outside the selected POV.
3. Why test suppression with formula rows and zeros? Because those options can change which intersections are displayed or evaluated.

**Teach-back:** Explain why a data-entry form should be tested with both missing and zero values before enabling suppression.

## Oracle references

- [Setting Form Precision and Other Options](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/setting_form_precision_and_other_options.html)
- [Setting Form Grid Properties](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/setting_form_grid_properties.html)
- [Setting Display Properties](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/setting_display_properties.html)
- [Form Design Considerations](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/form_design_considerations.html)

Official Oracle pages checked 2026-10-30. Product behavior may vary by form version and current service release; verify before applying.

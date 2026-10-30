# 04 — Smart View, Predictive Planning, and printing

## Core idea

A Planning form can be used through the web interface and Oracle Smart View for Office, but client-specific options affect layout, editing, suppression, prediction, and printing. Test the user’s actual client and form version.

## Smart View form options

| Option | Oracle-documented behavior | Practical implication |
|---|---|---|
| Repeat member labels | Repeats labels; may be forced on for flex forms and some drop-down dimension layouts | Useful for readable row data in Excel; validate downstream Excel analysis |
| Disable sheet protection | Allows entering or pasting data into cells, but does not allow users to submit changed data | Do not use it as an editing workaround; test data submission |
| Enable flex form for rows/columns | Enables flex behavior for the selected axis in Smart View | Users can work with members beyond a fixed row/column layout only within documented limits |
| Show invalid members for flex form | Retains and highlights invalid members after refresh so users can correct them | Test misspellings and out-of-definition members |
| Disable spreading | Disables supported spread actions in Smart View | Confirm whether planners need spreading or mass allocation |

Flex Forms are a Smart View feature. Their setup is associated with form options and dimension properties. Flex forms have specific constraints; for example, Database Suppression is not supported. Oracle also documents that enabled suppression settings are applied on initial open, and Smart View suppression settings can affect later work. Groovy rules are not supported in flex forms when suppression options are enabled. Check the current Oracle guide before combining these features.

## Predictive Planning

Predictive Planning uses historical data from a valid form to produce projected values. It is a decision-support estimate, not an approved forecast or a guarantee of future results.

Before using it:
1. Confirm the form has appropriate time and series axes and is not empty.
2. Confirm historical periods and future periods are present and visible as needed.
3. Check the form’s prediction options, including calendar and events where configured.
4. Review historical and prediction ranges and any data screening, seasonality, or constraint settings.
5. Compare the prediction with business knowledge before copying values into a plan.
6. Paste to an intended scenario and save; avoid overwriting approved or source data.

The administrator can set prediction defaults on the form, including a calendar and whether to include associated events. The “Prediction for Dynamic Calc” option has specific member/UDA prerequisites; use the Oracle procedure rather than enabling it speculatively. Prediction results depend on available history, granularity, missing values, and settings.

## Printing

Printing differs by form version. Oracle documents a Planning print-to-PDF option for Forms 1.0. With Forms 2.0, use the browser’s print capability or print from Excel through Smart View if a printout is required. Check pagination, repeated headers, precision, POV, and supporting details in the actual output.

## Test checklist

- Confirm web or Smart View client, form version, and supported client release.
- Test repeat labels and flex behavior with real hierarchy examples.
- Verify whether changed cells can be submitted in the selected worksheet configuration.
- Check suppression in both the form and Smart View options.
- Run a prediction with a known historical series and verify the destination scenario before saving.
- Print one representative form and check headers, precision, and page breaks.

## Recall check

1. Does disabling sheet protection permit submitting changed data? No, Oracle says users can enter or paste but cannot submit the changed data.
2. Where are Flex Forms used? Smart View for Office, subject to the documented configuration and limits.
3. Is a predicted value an approved forecast? No; it is an analytical estimate that requires review.

**Teach-back:** Tell a planner why Smart View’s ability to edit a worksheet and the ability to submit data are not the same thing.

## Oracle references

- [Setting Smart View Form Options](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/setting_smart_view_form_options_100x672ac700.html)
- [Designing Flex Forms](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/designing_flex_forms_100xe1ae74d7.html)
- [Using Suppression Options in Flex Forms](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/svuuc/flex_forms_suppression.html)
- [Setting Prediction Options](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/setting_prediction_options.html)
- [Using Predicted Values in Your Plans](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/predict_using_predicted_values_in_plans_102x5ad7c143.html)
- [Setting Printing Preferences](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/setting_your_printing_preferences_106xcb1ebc20.html)

Checked 2026-10-30. Printing and prediction options can change by form version and current release.

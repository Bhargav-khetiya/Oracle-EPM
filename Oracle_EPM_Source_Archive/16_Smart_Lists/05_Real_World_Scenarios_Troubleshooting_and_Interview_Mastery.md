# Smart Lists: Illustrative Scenarios and Review Questions

The scenarios below are **teaching examples**, not a claim about this project's configuration or a list of universally common implementations. Use them to practice selecting the right data model and designing tests.

## Scenario patterns

| Illustrative need | Smart List may fit when… | Prefer another design when… | Validation idea |
|---|---|---|---|
| Forecast method | User selects one of a few methods for a form cell | Users must report, filter, secure, or aggregate by method as a member | Test each option's rule branch and missing behavior |
| Justification category | A controlled reason is captured for a data cell | The values need a maintained hierarchy or many-to-many master data | Confirm entry appears to intended roles and label is clear |
| Yes/no assumption | A small binary choice drives a formula | The decision needs audit workflow, comments, or approval state | Test both values, zero/missing behavior, and downstream calculation |
| Planning status label | A separate descriptive field is needed in a plan | The status is intended to control real approvals/ownership | Use Approval Units for approval workflow; Smart List alone does not route or lock approval work |
| Employee grade input | A planner enters a limited assumption in a cell | Grade is an authoritative workforce attribute requiring broad analysis/master-data governance | Check if a dimension or source-system integration is better |
| Department choice from hierarchy | A configured hierarchy-based list is appropriate | The user needs broad member analysis or access varies unexpectedly | Test Create from Members and minimum access across users |
| Confidence category | A user chooses a category used by a documented calculation | The label-to-number mapping is assumed to equal a percentage | Test each configured ID and formula result |
| Optional selection | Blank is an allowed business state | A missing choice must block save | Test #MISSING display separately from a validation rule |

## Worked design: forecast method

**Requirement (illustrative):** a planner chooses Prior Year, Three-Year Average, or Manual for a forecast input.

1. Decide whether “method” belongs as a Smart List cell value or a dimension. Choose a Smart List only if it is a controlled input and does not need to behave as an independent analysis dimension.
2. Define unique IDs, programmatic names, and labels; record the intended mapping.
3. Associate the list with the supported member and check evaluation order.
4. Insert the list entry into the Calculation Manager formula/script using supported syntax.
5. Test all three selections, blank input, and a changed label/ID in a test environment.
6. Reconcile the result with the expected source value or manual input.

## Review questions and answers

**1. What problem does a Smart List solve?**  
It gives users a predefined drop-down choice in supported Planning form cells.

**2. What is the difference between ID, Name, and Label?**  
ID is the unique numeric identifier/order; Name is the programmatic key; Label is user-facing text.

**3. Which dimension must be first in evaluation order?**  
The dimension associated with the Smart List-type member, not universally Account.

**4. Does a Smart List provide approval workflow?**  
No. It captures a value. Approval units/templates govern planning approvals.

**5. What does Create from Members do?**  
It builds list choices from a dimension hierarchy and can honor dimension member security. Check minimum-access behavior and target users.

**6. Can a user type arbitrary text into a Smart List cell?**  
Oracle describes selecting from the drop-down rather than typing. Confirm interface and client behavior for the applicable product.

**7. How should Calculation Manager reference a choice?**  
Use the supported Smart List insertion and expression, for example [[SLName.entryname]], and test the generated rule.

**8. What should be reviewed before deleting or changing an entry?**  
Rule/formula use, data maps, downstream reports, history, and controlled recovery. Do not assume impact without reproducing it.

## Troubleshooting checklist

- **No drop-down:** check member data type, list association, form design, and evaluation order.
- **Choice missing for one user:** check member-based list source, minimum access, and member permissions.
- **Wrong result:** inspect the configured entry ID/name and rule expression.
- **Blank display is confusing:** check missing-label properties and the form's missing-value setting.
- **Cross-cube display differs:** validate target metadata and the supported mapping, not an assumed identical ID.

## Oral review drill

Explain the feature in one minute, then answer: Why not use a dimension? How are missing values shown? What proves a selected value produced the correct calculation? Which project facts are still unknown?

## Oracle sources checked 2026-10-30

- [Smart List overview](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/sm_lists.html)
- [Properties](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/adding_or_changing_smart_list_properties.html)
- [Entries](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/adding_or_changing_smart_list_entries.html)
- [Evaluation order](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/managing_dimensions.html)
- [Calculation Manager Smart Lists](https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/ecalc/inserting_smart_lists.html)
- [Approval unit actions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/approval_unit_actions.html)

# Planning Approvals: Beginner-to-Consultant Guide

## Core idea
Planning approvals route configured planning data units through assigned owners and reviewers, with actions and available statuses determined by the approvals template, current state, and access.

**Plain language:** the approval process tracks who currently owns a plan slice, who may review it next, and what action can move it forward or back for work.

> **Terminology:** Oracle documentation uses **approval unit**. Older material may say **planning unit**. Confirm the current term and service scope in the current guide.

## How an approval unit works

An administrator configures an approval unit hierarchy, scope, template, owners, reviewers, and any data validation rules. Users work with eligible approval units and perform actions such as Start, Promote, Submit, Reject, Sign Off, or Approve. Which actions are available depends on the template and current status.

~~~mermaid
flowchart LR
 C[Configure hierarchy and template] --> O[Assign owner/reviewers]
 O --> W[Owner enters or reviews data]
 W --> V[Run applicable validation]
 V -->|Pass| N[Transfer to next owner or review step]
 V -->|Errors| R[Resolve and retry]
 N --> F[Continue until approval is complete]
~~~

This is a conceptual flow. Templates can differ and approval units may skip states.

## Templates and common actions

| Template/process pattern | General idea | Caution |
|---|---|---|
| Bottom Up | Work moves from lower-level owners up the promotion path. | Common actions include Promote/Reject; do not assume every template has identical actions. |
| Distribute | Ownership and work are distributed through the hierarchy. | Submit/Distribute actions differ from Bottom Up. |
| Free Form | Ownership can move among eligible users without the same fixed path pattern. | Available actions and choices still depend on status and setup. |

Oracle states that action availability depends on the status and the approval template. For example, Promote, Submit, Sign Off, Freeze, and Distribute do not mean the same thing in every template. Use [Approval Unit Actions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/approval_unit_actions.html) and [Approval Unit States](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/approval_unit_states.html), not a memorized universal sequence.

## Ownership, access, and validation

After an approval unit is promoted, the new owner can write if they have the required write permission; the former owner can no longer edit while ownership has moved. Approval ownership does not replace member/data security. The final owner or reviewer behavior also depends on permissions and template.

Before a reviewer sends a unit onward, Oracle's approval process can run defined data validation rules and report errors or changes to the promotion path. Resolve validation errors before resubmitting. See [Promoting Data](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/promoting_data.html) and [Approvals Process](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/approvals_process.html).

## Illustrative example

In a hypothetical budget cycle, a department planner enters a forecast, reviews the assumptions, then promotes an approval unit to the next owner. The recipient reviews values and validation results, then promotes or rejects it. This is **illustrative**, not a statement of this project's process. The actual hierarchy, dimensions, owners, and actions must come from approved project configuration.

## Configure and operate safely

1. Confirm Planning service, scenario/version scope, relevant dimensions, and approval template.
2. Define the hierarchy and select owners/reviewers using approved organizational evidence.
3. Configure validation rules and define what errors block progression.
4. Test the action path with representative users and data in a nonproduction environment.
5. Check owner changes, data write access, state history, annotations, and notification behavior.
6. Document how to resolve a rejected unit and how an administrator may reopen it.
7. Treat changes to hierarchy, template, ownership, or approval status as controlled configuration changes.

Approval units can also be reviewed from supported forms; actions there still require access and depend on state. See [Working with Approval Units in Forms](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/working_with_approval_forms.html).

## Out of office and delegation

Oracle documents user preferences for out-of-office approval actions and delegation. These settings are user-specific and do not apply to approval units owned by groups. Do not assume the chain will automatically reroute in every ownership model. See [Setting Approvals Options](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/setting_approvals_options2_100xce36cf84.html).

## Troubleshooting

| Symptom | Check |
|---|---|
| Expected action is unavailable | Current status, selected template, user's role/access, and whether the user is the current owner/reviewer |
| User can no longer edit after submission | Current approval-unit owner and member write permission; this may be expected |
| Promotion is blocked | Validation errors, promotion-path changes, member permissions, and required approvals |
| The approval state differs from a simple flow diagram | Template, prior actions, hierarchy, skipped states, and current Oracle state definitions |
| Out-of-office action did not reroute a group-owned unit | Oracle documents that this user preference does not apply to group ownership |

Do not grant broad roles as a shortcut for an ownership or workflow issue.

## Remember and explain

**Recall:** What is an approval unit— What controls available actions— Does ownership alone guarantee write access— Why might a unit be rejected—

**Answer key:** It is a configured unit of planning data in an approval process. Template, status, and access determine actions. The new owner needs applicable write permission. Validation or review findings may require changes before progression.

**Teach-back:** Explain the path from planner entry through validation to final approval. Name where you would verify hierarchy, permissions, template, and status.

## Oracle sources checked 2026-10-30

- [Approval Unit Actions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/approval_unit_actions.html)
- [Approval Unit States](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/approval_unit_states.html)
- [Approvals Process](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusa/approvals_process.html)
- [Promoting Data](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/promoting_data.html)
- [Working with Approval Units in Forms](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/working_with_approval_forms.html)
- [Setting Approvals Options](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusu/setting_approvals_options2_100xce36cf84.html)

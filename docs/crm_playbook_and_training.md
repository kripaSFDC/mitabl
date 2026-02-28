# CRM Playbook and Training Assets

Date: 2026-02-28

## 1) Customer Service SOP

1. Open `Admin -> Customer Support -> Support Tickets`.
2. Start in `Unassigned` or `SLA Risk` filter.
3. Use `Assign to me` for ownership.
4. Send public `Reply` for requester-visible communication.
5. Use `Internal note` for private context.
6. Move status as work progresses: `open` -> `in_progress` -> `pending_user` -> `resolved` -> `closed`.
7. Use `Resolve` with mandatory summary before closure.
8. Use `Merge`/`Split` only with typed confirmation and explicit reason.

## 2) Operations SOP (Leads + Certificates)

1. Open `Admin -> Customer Support -> Pre Registrations`.
2. Triage new leads, assign an operator, set status to `triaged` or `contacted`.
3. Link converted leads to existing users using `Convert`.
4. For certificates, use `Review Workspace` for context.
5. Use bulk approve/reject only after typed confirmation and rejection reason validation.

## 3) Escalation Ladder

1. First-response SLA breach: assigned agent + team lead notified.
2. Resolution SLA breach: ops lead + platform admin notified.
3. Repeated breach patterns (>3 per day): incident review and staffing adjustment.

## 4) Macro Templates

- Acknowledgement:
  - "We have received your request ({{ticket_number}}) and will respond shortly."
- Clarification:
  - "Thanks for the details. Could you confirm {{missing_field}} so we can proceed?"
- Resolution:
  - "Your issue has been resolved. Summary: {{resolution_summary}}."
- Escalation:
  - "This ticket has been escalated due to urgency/SLA risk and is being prioritized."

## 5) Handoff Guidelines

1. Every reassignment includes a reason.
2. Every resolved ticket includes a resolution summary.
3. Internal notes must capture pending risks/dependencies.
4. Use ticket merge only when duplicates are confirmed by subject + requester + timeline.

## 6) Governance Notes

- Internal notes are never customer-visible.
- Spam classification is terminal and should only be used with clear abuse evidence.
- Reopen from resolved is time-bound by configured reopen window.

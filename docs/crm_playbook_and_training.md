# CRM Playbook and Training Guide

Date: 2026-03-01  
Audience: Customer Service, Operations, Team Leads, Quality, and Platform Support  
Scope: End-to-end CRM operations in the admin panel, support ticket lifecycle, certificate-related support handling, SLA governance, communications, and operational controls.

---

## 1) What this guide covers

This guide is the business-facing operating manual for the MITABL CRM functions running in the admin panel. It is written for frontline agents and supervisors who need to:

- Receive and triage inbound support requests.
- Work tickets through a controlled lifecycle with SLA visibility.
- Coordinate handoffs, escalations, and internal collaboration.
- Manage certificate-related operational reviews tied to customer support.
- Use communication templates/macros and monitor outbound communication delivery.
- Operate safely under audit, security, and data-protection guardrails.

---

## 2) CRM operating model at a glance

### Core channels into CRM

1. **Public/API support intake** (`POST /api/support/ticket`) for website/mobile channels.
2. **Customer follow-up** (`POST /api/support/ticket/{id}/reply`) using ticket token or authenticated user context.
3. **Admin-created tickets** from Support Inbox create form.

### Core work surfaces in admin

- **Customer Support → CRM Agent Workspace** (triage cockpit for queue + timeline + macro reply).
- **Customer Support → Support Inbox** (full ticket list, filters, and lifecycle actions).
- **Operations → Certificates** (certificate review operations often related to ticket handling).
- **Platform → Templates** (macro/message content management).
- **Platform → Integration Logs** (communication delivery outcomes and replay for failed sends).
- **Platform → Queue Operations** (failed jobs and queue health for CRM communications/escalations).

### Lifecycle statuses used by ticket operations

- `open`
- `in_progress`
- `pending_user`
- `resolved`
- `closed`
- `spam`

**Terminal statuses:** `closed`, `spam` (cannot continue active workflow).

---

## 3) Roles and responsibilities (business view)

## 3.1 Customer Service Agent

Primary outcomes:
- Fast first response.
- Accurate classification and ownership.
- Clear customer-visible updates.

Typical permissions used:
- View tickets.
- Create tickets.
- Assign/reassign.
- Respond with reply/internal notes.
- Resolve and status transitions.

## 3.2 Operations Specialist / Team Lead

Primary outcomes:
- Queue balancing.
- SLA exception management.
- Certificate review and cross-team coordination.

Typical permissions used:
- All ticket operational actions.
- Certificate view/review.
- Dashboard monitoring for SLA, queue depth, and aging.

## 3.3 Platform/Support Admin

Primary outcomes:
- Keep CRM infrastructure healthy.
- Ensure queues, integrations, and templates are functional and compliant.

Typical permissions used:
- Templates versioning/publish.
- Integration log replay.
- Queue job controls.
- Audit and policy-level controls.

---

## 4) Page-by-page CRM guide

## 4.1 Customer Support → **CRM Agent Workspace**

### Purpose
Fast triage workspace for active ticket response.

### What you see
- **Queue pane**: prioritized list of active tickets.
- **Timeline pane**: message history (includes marker for internal notes).
- **Macro tools**: recommended templates by ticket category.
- **Context pane**: related/similar historical tickets with resolution snippets.

### Agent workflow
1. Click **Refresh**.
2. Select the top priority ticket.
3. Review timeline and context tickets.
4. Insert a recommended macro (optional).
5. Personalize message and **Send reply**.
6. Move to Support Inbox for advanced actions (assignment, status, merge/split, etc.) if needed.

### Productivity shortcuts
- Refresh and macro-driven response composition are built in for high-throughput handling.

---

## 4.2 Customer Support → **Support Inbox**

### Purpose
Primary system-of-record queue where ticket lifecycle actions are executed.

### Key columns and indicators
- Ticket number, requester, subject.
- Priority badge (`low`, `normal`, `high`, `urgent`).
- Status badge.
- First-response SLA state and resolution SLA state.
- Assignee, watchers, tags, linked order/kitchen, timestamps.

### Filters used in daily operations
- **My Queue**: only tickets assigned to me.
- **Unassigned**: ownership needed.
- **SLA Risk**: near-breach/at-risk items.
- **Ops Certificates Pending**: kitchen/certificate-related ticket cluster.
- Status filter and priority filter.

### Ticket actions available
- **Assign to me**: claim ownership quickly.
- **Assign**: reassign with mandatory reason.
- **Reply**: customer-visible update (with attachments).
- **Internal note**: private team context (with attachments).
- **Tags**: add/remove labels for reporting and grouping.
- **Watch / Unwatch**: subscribe for visibility.
- **Resolve**: requires mandatory resolution summary.
- **Change status**: controlled transitions; includes reason and admin password confirmation.
- **Change priority/category**: controlled reclassification with reason.
- **Merge**: duplicate consolidation (requires typed `MERGE` confirmation + reason).
- **Split**: break one ticket into a new child issue.

### Bulk actions
- **Assign selected to me**.
- **Export redacted CSV** (PII-safe export for analysis/compliance sharing).

---

## 4.3 Operations → **Certificates**

### Purpose
Operational review of kitchen certificates that frequently intersects with support escalations.

### What reviewers can do
- Review pending certificate records.
- Approve when document is present/valid.
- Reject with mandatory rejection reason.
- Request resubmission where applicable.
- Perform controlled bulk approve/reject with typed confirmation and reasons.

### Important controls
- Snapshot freshness checks prevent reviewing stale records.
- Review actions lock records to avoid concurrent review collisions.
- Notification jobs are triggered for review outcomes when recipient email exists.

---

## 4.4 Platform → **Templates**

### Purpose
Versioned content management for system/customer communication templates.

### Business rules
- Templates are versioned by name.
- New versions are created as drafts.
- Publishing one version deactivates other active versions of same template name.
- Active templates are protected from direct edit.

### Why this matters to agents/leads
- Macro quality, consistency, and legal copy control come from this page.
- Workspace macro recommendations depend on active support-related templates.

---

## 4.5 Platform → **Integration Logs**

### Purpose
Operational visibility into outbound CRM communications.

### What it tracks
- Channel, template, recipient, status.
- Response status, retries, and error snapshots.

### Recovery action
- Failed support acknowledgement/reply logs can be replayed by authorized users.

---

## 4.6 Platform → **Queue Operations**

### Purpose
Queue health control plane for failed jobs and delivery reliability.

### What to monitor
- Queue depth.
- Failed jobs count.
- Oldest pending age.
- Poison retry risk / dead-letter risk.

### Actions (authorized users)
- Retry single failed job.
- Requeue single failed job.
- Discard unrecoverable poison payload.
- Retry all failed jobs (after root-cause validation).

---

## 5) End-to-end process flows

## 5.1 Flow A: New customer issue intake to first response

1. Customer submits support request through API intake.
2. Duplicate check runs (recent same requester + highly similar subject).
3. Ticket created with number (`TKT-xxxxxx`), SLA due dates, requester token, and initial message.
4. Non-spam ticket triggers acknowledgement communication.
5. Agent opens Support Inbox using **Unassigned** / **SLA Risk** filters.
6. Agent claims via **Assign to me** or leader reassigns with reason.
7. Agent sends first public **Reply**.
8. System stamps `first_responded_at` and records event trail.

## 5.2 Flow B: Active investigation and customer wait loop

1. Agent sets `in_progress` while actively investigating.
2. Agent adds public replies for customer updates.
3. Agent adds internal notes for private context/dependencies.
4. If awaiting customer input, transition to `pending_user` with reason.
5. When customer replies, ticket can be moved back to `open`/`in_progress`.

## 5.3 Flow C: Resolution and closure

1. Agent uses **Resolve** with mandatory summary.
2. Ticket status becomes `resolved` and `resolved_at` is stored.
3. Optional final customer communication is sent.
4. Ticket transitions to `closed` when complete.
5. Reopen is allowed only from `resolved → open` within configured reopen window.

## 5.4 Flow D: Duplicate / conflated issues

### Merge process
1. Validate duplicate criteria (requester + subject + timeline consistency).
2. Use **Merge** and type `MERGE` confirmation.
3. Provide merge reason.
4. Source ticket messages/attachments move into target; source becomes closed.

### Split process
1. Use **Split** when ticket contains independent issue threads.
2. Enter new subject + description.
3. New ticket is created with inherited requester context and fresh SLA clocks.

## 5.5 Flow E: SLA breach escalation

1. Scheduled SLA scan runs every 5 minutes.
2. Breached first-response or resolution tickets are queued for escalation processing.
3. Escalation job stamps breach timestamp and logs escalation event.
4. Notifications are routed to assignee (if present) and escalation mail target.

---

## 6) SLA framework and priority handling

## 6.1 Priority bands

- **Low**
- **Normal**
- **High**
- **Urgent**

## 6.2 Default policy values (unless environment overrides)

- **Low:** first response 120 min, resolution 48h.
- **Normal:** first response 60 min, resolution 24h.
- **High:** first response 30 min, resolution 8h.
- **Urgent:** first response 15 min, resolution 4h.

## 6.3 SLA dashboard signals

- Queue depth.
- First-response breaches.
- Resolution breaches.
- At-risk counts.
- Aging buckets (0–4h, 4–24h, 1–3d, >3d).
- Reopened rate (quality indicator).

---

## 7) Data protection and compliance guardrails

## 7.1 PII protection controls

- Redaction service masks email, phone-like values, long numeric identifiers, and token-like strings.
- CSV exports are explicitly redacted.

## 7.2 Attachment policy controls

- Max attachments and size caps are enforced.
- Allowed MIME policy is enforced.
- Blocked executable/script extensions are rejected.
- Temporary upload path checks and content scanning policy remove suspicious payloads.

## 7.3 Access and authorization controls

- Admin panel protected by authenticated admin guard.
- Ticket actions are permission-gated (view/create/assign/respond/resolve).
- Certificate reviews are permission-gated (view/review).
- Platform controls are permission-gated (templates, integrations, queue ops).

## 7.4 Auditability controls

- Admin write actions are logged through audit middleware.
- Ticket lifecycle events record assignment, status change, resolve, merge/split, escalations, and classification changes.

---

## 8) Standard operating procedures (SOP)

## 8.1 Daily opening SOP (frontline)

1. Open Dashboard and confirm queue/SLA health.
2. Open Support Inbox with **Unassigned** and **SLA Risk**.
3. Claim/assign urgent and high priority first.
4. Send first responses for all due/imminent tickets.
5. Use internal notes for handoff context.
6. Use `pending_user` when waiting for customer details.

## 8.2 Mid-shift control SOP (lead)

1. Check aging buckets and reopened trend.
2. Rebalance ownership using assignment action.
3. Review certificate-related queue cluster.
4. Verify no unresolved breach spikes.

## 8.3 End-of-day SOP

1. Review unresolved urgent/high tickets.
2. Ensure all resolved tickets contain quality resolution summaries.
3. Validate reassignment reasons are present.
4. Confirm queue/integration health for overnight continuity.

---

## 9) Communication standards and macros

## 9.1 Approved response patterns

- **Acknowledgement:** confirm receipt + ticket number + ETA cue.
- **Clarification:** concise request for missing data.
- **Resolution:** clear fix summary + next steps.
- **Escalation notice:** communicate priority handling without overpromising.

## 9.2 Writing standards

- State action taken, current state, and next action.
- Use plain language; avoid internal jargon customer-side.
- Do not include internal notes in public reply.
- Keep commitments bounded to known SLA/next check time.

## 9.3 Macro governance

- Draft in Templates.
- Business/legal review where needed.
- Publish approved version.
- Deactivate outdated versions automatically via publish process.

---

## 10) Exception playbooks

## 10.1 If ticket update fails with concurrency/version error

- Refresh ticket.
- Re-check latest status/messages.
- Re-apply action with current context.

## 10.2 If merge/split request is disputed

- Pause terminal action.
- Add internal note documenting rationale.
- Escalate to lead for final decision.

## 10.3 If outbound communication fails

- Check Integration Logs.
- Replay failed support acknowledgement/reply if permitted.
- If repeated failure, check Queue Operations + queue worker health.

## 10.4 If SLA breach spike occurs

- Prioritize at-risk and breached tickets by urgency.
- Trigger staffing redistribution.
- Run incident review if repeated pattern exceeds operational threshold.

---

## 11) CRM KPI scorecard (recommended)

Track these weekly/monthly:

- First response SLA attainment %.
- Resolution SLA attainment %.
- Queue depth trend and aging distribution.
- Reopened ticket rate.
- Average handle time by category.
- Duplicate merge rate.
- Customer follow-up loop duration (`pending_user` aging).
- Communication failure/replay rate.

---

## 12) Legacy workflow note

A **pre-registration intake** capability exists in the admin surface as a legacy workflow, but current CRM operations should prioritize the support-ticket workflow as the primary intake and service channel.

---

## 13) Operational verification checklist (runbook)

Use this verification whenever support-ticket CRM behavior, SLA logic, or ticket lifecycle code is changed.

1. Prepare backend test environment:
   - `cd backend`
   - `cp .env.example .env`
   - `composer install --prefer-dist --no-progress --no-interaction`
   - `php artisan key:generate --force`
   - `mkdir -p database && touch database/database.sqlite`

2. Run support ticket contract tests:
   - `php artisan test tests/Feature/SupportTicketIntakeCrmEndToEndContractTest.php tests/Unit/PhaseThreeSupportTicketServiceTest.php`

3. Expected pass criteria:
   - Ticket intake contract and dedupe behavior.
   - Assignment and status transitions.
   - Reply/internal-note pathways and communication logging.
   - Resolve/close/reopen behavior.
   - Queue filters and merged-ticket suppression.
   - Ticket schema and FK integrity.

4. CI expectation:
   - Failures must block release until resolved.

---

## 14) Quick-reference checklist cards

## Frontline quick card

- Start at **Unassigned** + **SLA Risk**.
- Claim ownership quickly.
- Reply publicly; note internally.
- Use `pending_user` for customer wait states.
- Resolve only with clear summary.
- Close only when outcome is final.

## Lead quick card

- Watch breaches, at-risk counts, and aging buckets.
- Rebalance queue and enforce handoff discipline.
- Audit merge/split actions for quality.
- Validate certificate review throughput.

## Platform quick card

- Keep queue workers healthy.
- Replay failed communications when appropriate.
- Maintain template quality/versioning.
- Preserve complete admin auditability.


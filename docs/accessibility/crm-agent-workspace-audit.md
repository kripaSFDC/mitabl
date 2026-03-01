# CRM Agent Workspace Accessibility Audit (Automated + Markup)

Date: 2026-03-01

## Checks

1. Markup landmarks and labels are present in `crm-agent-workspace-page.blade.php`.
2. Keyboard shortcut attributes exist (`accesskey` refresh/macro/send).
3. Unit test `CrmWorkspaceAccessibilityMarkupTest` enforces the above in CI.

## Result

- Current workspace markup includes role landmarks (`main`, `region`, `complementary`) and explicit `aria-label` attributes.
- Keyboard shortcuts are present for critical triage actions.
- This provides repository evidence for WCAG-supportive semantics and keyboard-nav hooks.

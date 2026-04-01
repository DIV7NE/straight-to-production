# Legal & Compliance Basics

## Who This Applies To
Any web application or service that collects user data, accepts payments, or is accessible in the EU. If your app has user accounts, this applies to you.

## Privacy Policy (Required if collecting ANY user data)
- Email addresses, names, payment info, usage analytics — all count as "user data"
- Must describe: what data you collect, why, how long you keep it, who you share it with
- Must be accessible from every page (typically footer link)
- Template services: Termly, Iubenda, or a lawyer for serious products

## Terms of Service (Required if users pay or create accounts)
- Defines the agreement between you and your users
- Covers: acceptable use, account termination, liability limitations, dispute resolution
- Required before accepting payments (Stripe requires it)

## GDPR (Required if accessible to EU users)
- Users must consent before non-essential cookies/tracking (cookie banner)
- Users must be able to: view their data, download their data, delete their data
- Data breaches must be reported within 72 hours
- Privacy policy must include: legal basis for processing, data retention period, DPO contact

## EAA / European Accessibility Act (Mandatory since June 2025)
- WCAG 2.1 AA compliance is legally required for SaaS products serving EU users
- Covers: web applications, mobile apps, e-commerce
- See: .pilot/references/accessibility/wcag-aa-essentials.md

## Cookie Consent (Required for EU users)
- Essential cookies (auth, security): no consent needed
- Analytics cookies (Google Analytics, PostHog): consent required
- Marketing cookies (ad tracking): consent required
- Must be a real choice — no "dark patterns" (pre-checked boxes, "accept all" bigger than "reject")

## License Auditing
- Check your dependencies for license compatibility
- GPL dependencies in proprietary code = you must open-source your code
- MIT, Apache 2.0, BSD = safe for proprietary use
- Tools: license-checker (npm), pip-licenses (Python), cargo-license (Rust)
- Run before every release

## Payment Compliance
- Never store credit card numbers — use Stripe/Paddle's hosted checkout
- PCI compliance is handled by Stripe if you use their hosted elements
- Display pricing clearly before charging
- Provide receipts for all payments
- Handle refunds per your terms of service

## Checklist (Web-facing products)
- [ ] Privacy policy page exists and is linked from footer
- [ ] Terms of service page exists (if users pay or create accounts)
- [ ] Cookie consent banner shows for EU users (if using analytics/tracking)
- [ ] Users can delete their account and data
- [ ] License audit passes (no incompatible licenses)
- [ ] WCAG 2.1 AA accessibility compliance
- [ ] Payment receipts sent for all transactions

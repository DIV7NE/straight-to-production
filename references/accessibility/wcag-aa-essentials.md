# WCAG 2.1 AA Essentials

## The 4 Principles (POUR)

### Perceivable
- All images MUST have descriptive alt text (empty alt="" only for decorative images)
- Video/audio MUST have captions or transcripts
- Text MUST be resizable to 200% without loss of content
- Color MUST NOT be the only way to convey information (add icons, text, or patterns)
- Text contrast: 4.5:1 minimum for normal text, 3:1 for large text (18px+ bold or 24px+)
- UI component contrast: 3:1 minimum against adjacent colors

### Operable
- ALL functionality MUST be available via keyboard
- Tab order MUST follow visual/logical order
- Focus indicators MUST be visible (never `outline: none` without replacement)
- No keyboard traps — users must be able to tab away from every element
- Skip links: add "Skip to main content" link as first focusable element
- Modals MUST trap focus inside and return focus on close
- No time limits unless essential (provide extend/disable option)

### Understandable
- Page language MUST be set: `<html lang="en">`
- Form inputs MUST have visible labels (not just placeholders)
- Error messages MUST identify the field and describe how to fix
- Navigation MUST be consistent across pages
- No unexpected context changes on focus or input

### Robust
- Use semantic HTML: `<nav>`, `<main>`, `<aside>`, `<header>`, `<footer>`, `<section>`
- Use `<button>` for actions, `<a>` for navigation (never div with onClick)
- ARIA only when semantic HTML isn't sufficient
- Test with screen reader (VoiceOver on Mac: Cmd+F5)

## Quick Implementation Checklist
- [ ] All images have alt text
- [ ] Color contrast passes (use browser DevTools Accessibility panel)
- [ ] Tab through entire app — everything reachable and in order?
- [ ] Forms have labels, not just placeholders
- [ ] Error messages are clear and specific
- [ ] Heading hierarchy: one h1, then h2, h3 (no skipping levels)
- [ ] Skip link present
- [ ] Language attribute set on html element
- [ ] Focus styles visible on all interactive elements

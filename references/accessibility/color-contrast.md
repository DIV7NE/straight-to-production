# Color & Contrast

## Required Ratios (WCAG 2.1 AA)
- **Normal text** (< 18px or < 14px bold): 4.5:1 contrast ratio minimum
- **Large text** (>= 18px or >= 14px bold): 3:1 contrast ratio minimum
- **UI components** (buttons, inputs, icons): 3:1 against adjacent colors
- **Focus indicators**: 3:1 against adjacent background

## Common Failures
- Light gray text on white background (common in placeholders and secondary text)
- Low contrast on disabled states (still needs to be readable, just visually distinct)
- Colored text on colored backgrounds without checking ratio
- Info conveyed only by color (red = error) without icon or text

## Rules
- Never convey meaning by color alone — always pair with icon, text, or pattern
- Test with browser DevTools: Inspect element → Accessibility tab → Contrast ratio
- Test entire pages: Chrome DevTools → Rendering → Emulate vision deficiencies

## Safe Defaults
If using Tailwind with a dark-on-light scheme:
- Body text: `text-gray-900` on white (ratio: 17.4:1)
- Secondary text: `text-gray-600` on white (ratio: 5.7:1) — passes AA
- Avoid: `text-gray-400` on white (ratio: 3.0:1) — fails AA for normal text
- Placeholder text: `text-gray-500` on white (ratio: 4.0:1) — borderline, test carefully

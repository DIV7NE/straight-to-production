# Input Validation & Sanitization

## Principle
Validate at the boundary. Every piece of data crossing from outside to inside your system must be validated before use. Runtime validation is required — type systems alone don't protect at runtime.

## Validation Libraries by Stack
- **TypeScript**: Zod
- **Python**: Pydantic
- **Rust**: serde + validator crate
- **Go**: go-playground/validator
- **C#**: DataAnnotations + FluentValidation
- **Java**: Jakarta Bean Validation (Hibernate Validator)
- **Ruby**: ActiveModel validations
- **PHP**: Laravel Form Requests

## Common Validation Rules
- Strings: minimum length (no empty), maximum length (prevent abuse), trim whitespace
- Emails: format validation — but also verify server-side, never trust format alone
- URLs: validate protocol is http/https, no internal IPs
- Numbers: integer check, positive check, min/max range for quantities
- Arrays: maximum length to prevent payload abuse
- Files: check type, size, extension — both client-side (UX) and server-side (security)

## What to Validate
- ALL form submissions and request bodies
- ALL URL parameters and query strings
- ALL file uploads (type, size, content)
- ALL webhook payloads (after signature verification)
- ALL external API responses (they can change unexpectedly)

## What NOT to Do
- Never concatenate user input into SQL queries — use parameterized queries
- Never insert user input directly into HTML — use template escaping or sanitization
- Never pass user input to file system operations without path validation
- Never use user input in shell commands or system calls
- Never trust client-side validation alone — always re-validate server-side

# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in STP, please report it responsibly.

**Do NOT open a public issue.**

Instead, email **24811041+DIV7NE@users.noreply.github.com** with:
- A description of the vulnerability
- Steps to reproduce
- Potential impact

You will receive a response within 48 hours. We will work with you to understand and address the issue before any public disclosure.

## Scope

STP is a Claude Code plugin that runs locally on your machine. It does not:
- Collect or transmit user data
- Run a server accessible from the network (whiteboard is localhost-only)
- Store credentials (MCP servers handle their own auth)

Security concerns most relevant to STP:
- Hook scripts that execute shell commands
- File operations (copy, write, delete) during install/upgrade
- npm package supply chain integrity

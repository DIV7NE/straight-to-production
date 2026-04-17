# STP Section Markers (canonical list)

When writing STP sections to ANY CLAUDE.md, wrap each in HTML comment markers so `/stp:setup upgrade` can find and refresh them without touching user content:

```
<!-- STP v[VERSION] -->
<!-- STP:stp-header:start -->            ...header/arch...                    <!-- STP:stp-header:end -->
<!-- STP:stp-confirmation-gate:start --> ...pre-work confirmation gate...     <!-- STP:stp-confirmation-gate:end -->
<!-- STP:stp-subagent-cost:start -->     ...model="sonnet" enforcement...     <!-- STP:stp-subagent-cost:end -->
<!-- STP:stp-profile-aware:start -->     ...profile index + resolution...     <!-- STP:stp-profile-aware:end -->
<!-- STP:stp-commands:start -->          ...command list...                   <!-- STP:stp-commands:end -->
<!-- STP:stp-plugins:start -->           ...companion plugins...              <!-- STP:stp-plugins:end -->
<!-- STP:stp-philosophy:start -->        ...philosophy...                     <!-- STP:stp-philosophy:end -->
<!-- STP:stp-rules:start -->             ...key rules...                      <!-- STP:stp-rules:end -->
<!-- STP:stp-output-format:start -->     ...CLI output formatting...          <!-- STP:stp-output-format:end -->
<!-- STP:stp-dirmap:start -->            ...directory map...                  <!-- STP:stp-dirmap:end -->
<!-- STP:stp-statusline:start -->        ...statusline...                     <!-- STP:stp-statusline:end -->
<!-- STP:stp-hooks:start -->             ...hooks list...                     <!-- STP:stp-hooks:end -->
<!-- STP:stp-research:start -->          ...research sources...               <!-- STP:stp-research:end -->
<!-- STP:stp-effort:start -->            ...effort levels...                  <!-- STP:stp-effort:end -->
```

Read actual content for each section from the plugin's canonical CLAUDE.md at `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md`.

**User-owned sections** (`## Project Conventions`, `## Standards Index`, any custom sections) go OUTSIDE these markers — never touched by `/stp:setup upgrade`.

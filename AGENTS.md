# Tool usage policy

Prefer IDE MCP tools over shell commands whenever an equivalent MCP tool exists.

For codebase exploration:
- Use Index MCP for symbol lookup, usages, implementations, hierarchy, diagnostics, and semantic navigation.
- Do not use grep, rg, find, sed, awk, or similar shell commands for code discovery when Index MCP can answer the question.
- Prefer IDE diagnostics over running ad-hoc compiler or linter commands just to inspect errors.

For IDE operations:
- Use JetBrains MCP for run configurations, debugger operations, IDE actions, and project-aware operations.
- Prefer IDE run configurations over manually reconstructing the same command in the shell.

Use terminal commands when:
- no suitable MCP tool exists;
- the MCP tool fails or returns insufficient information;
- the task inherently requires CLI tooling;
- running Maven/Gradle/Docker/Git commands is explicitly appropriate.

When falling back from MCP to terminal, briefly state why.

## MCP priority

For code analysis, always try `intellij-index` MCP before using shell-based search.

Preferred order:

1. Index MCP
2. JetBrains IDE MCP
3. Native file tools
4. Shell/terminal as fallback

Do not use `rg`, `grep`, `find`, or filesystem traversal for:
- finding classes;
- finding methods;
- finding usages;
- finding implementations;
- resolving symbols;
- inspecting inheritance;
- checking IDE diagnostics;

when the Index MCP provides an equivalent operation.

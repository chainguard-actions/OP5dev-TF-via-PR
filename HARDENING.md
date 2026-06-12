<!-- markdownlint-disable -->

# Hardening Report: OP5dev--TF-via-PR/v13.7.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **OP5dev--TF-via-PR/v13.7.0** was hardened automatically. 9 finding(s) were identified and resolved across 4 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a): The `identifier` step's `run:` block directly interpolates multiple `${{ github.* }}` expressions into shell commands without going through env vars. Attacker-controlled values like `${{ github.ref_name }}`, `${{ github.event.number || github.event.issue.number }}`, `${{ github.head_ref }}`, `${{ github.ref }}`, `${{ github.event.pull_request.head.sha || github.sha }}`, and `${{ github.repository }}` are substituted directly into the shell script before execution. For example: `pr_number=$(echo "${{ github.ref_name }}" | sed ...)` and `pr_number=${{ github.event.number || github.event.issue.number }}`. A malicious branch name or PR event payload could inject arbitrary shell commands.

Locations:

- `action.yml:122`
- `action.yml:125`
- `action.yml:127`

### script-injection (severity: high)

Rule (a): The `arg` step's `run:` block directly interpolates `${{ env.TF_CLI_ARGS }}` into a shell command: `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"`. The `env.TF_CLI_ARGS` context is workflow-controllable and is substituted directly into the shell string before execution.

Locations:

- `action.yml:67`

### script-injection (severity: high)

Rule (a): The `format`, `initialize`, `validate`, `plan`, `parity`, and `apply` steps all directly interpolate `${{ steps.arg.outputs.* }}` expressions into shell `args=` variable assignments and command invocations inside `run:` blocks. For example in the `format` step: `args="${{ steps.arg.outputs.arg-check }}${{ steps.arg.outputs.arg-diff }}..."`. These step outputs are derived from user-supplied `inputs.*` values and are substituted directly into the shell before execution, enabling command injection.

Locations:

- `action.yml:148`
- `action.yml:157`
- `action.yml:166`
- `action.yml:178`
- `action.yml:218`
- `action.yml:237`

### script-injection (severity: high)

Rule (a): The `download` step's `run:` block directly interpolates `${{ github.repository }}` and `${{ steps.identifier.outputs.name }}` into shell commands: `gh api /repos/${{ github.repository }}/actions/artifacts ...` and `gh api ... > "${{ steps.identifier.outputs.name }}.zip"`. These values are substituted directly into the shell string before execution.

Locations:

- `action.yml:196`
- `action.yml:198`
- `action.yml:201`
- `action.yml:203`

### script-injection (severity: high)

Rule (a): The `post` step's `run:` block directly interpolates numerous `${{ github.* }}`, `${{ steps.* }}`, and `${{ env.* }}` expressions into shell commands. Key examples include: `${{ github.repository }}` in multiple `gh api` calls, `${{ github.run_id }}` and `${{ github.run_attempt }}` in API URLs, `${{ github.triggering_actor }}` embedded in the PR comment body string, `${{ github.event.pull_request.updated_at || github.event.comment.created_at || ... }}` in the comment body, `${{ steps.format.outcome }}` in a conditional, and `${{ steps.identifier.outputs.pr }}` in numeric comparisons and API calls. All of these are substituted directly into the shell script before execution.

Locations:

- `action.yml:280`
- `action.yml:295`
- `action.yml:316`
- `action.yml:330`
- `action.yml:340`
- `action.yml:344`
- `action.yml:348`
- `action.yml:356`
- `action.yml:362`
- `action.yml:366`
- `action.yml:370`

### github-env-injection (severity: high)

The `arg` step's `run:` block writes three unsanitized values to `$GITHUB_ENV` without applying `printf '%s' ... | tr -d '\n\r'` sanitization: (1) `echo "GH_TOKEN=$INPUTS_TOKEN" >> "$GITHUB_ENV"` where `INPUTS_TOKEN` comes from `inputs.token` (caller-controlled); (2) `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" ...)" >> "$GITHUB_ENV"` where `env.TF_CLI_ARGS` is workflow-controlled and also directly interpolated; (3) `echo "TF_WORKSPACE=$TF_WORKSPACE" >> "$GITHUB_ENV"` where `TF_WORKSPACE` is sourced from `inputs.arg-workspace` (caller-controlled). A newline character in any of these values would allow injection of arbitrary environment variables.

Locations:

- `action.yml:66`
- `action.yml:67`
- `action.yml:70`

### static-unsanitized-env-write (severity: medium)

unsanitized write to $GITHUB_ENV: variable $INPUTS_TOKEN in step "" comes from a ${{...}} expression and should be sanitized with printf/tr before writing

Locations:

- `action.yml:69`

### static-unsanitized-env-write (severity: medium)

unsanitized write to $GITHUB_ENV: variable $TF_WORKSPACE in step "" comes from a ${{...}} expression and should be sanitized with printf/tr before writing

Locations:

- `action.yml:73`

### static-inline-injection (severity: high)

shell injection: expression "${{ github.event.pull_request.head.sha || github.sha }}" appears directly in run: block of step ""; move to env: map

Locations:

- `action.yml:128`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, static-unsanitized-env-write, static-inline-injection

**Notes:**

Fixed all security findings in action.yml by:
1. Moving all ${{ github.* }}, ${{ steps.* }}, and ${{ env.TF_CLI_ARGS }} expressions from run: blocks into env: blocks for every affected step (identifier, arg, format, initialize, validate, plan, download, parity, apply, post).
2. Added printf '%s' ... | tr -d '\n\r' sanitization for all three GITHUB_ENV writes in the arg step: GH_TOKEN (from inputs.token), TF_CLI_ARGS (from env.TF_CLI_ARGS), and TF_WORKSPACE (from inputs.arg-workspace).
3. The TF_CLI_ARGS env.TF_CLI_ARGS inline injection was fixed by capturing it as TF_CLI_ARGS_EXISTING in the env: block and using shell logic to build the value safely.
4. All run: blocks now exclusively use $VAR_NAME references to environment variables, with no ${{ }} template expressions remaining in shell script bodies.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed all three github-env-injection findings in action.yml:

1. GH_HOST (line 82): Replaced `echo "GH_HOST=$(echo $GITHUB_SERVER_URL | sed 's/.*:\/\///')"` with a two-step approach: `safe_gh_host=$(printf '%s' "$GITHUB_SERVER_URL" | sed 's/.*:\/\///' | tr -d '\n\r')` then `echo "GH_HOST=${safe_gh_host}"` to strip newlines before writing to $GITHUB_ENV.

2. CLI arguments block (line 85): Replaced all 38 `echo arg-X=...` lines with a `_safe()` helper function (`_safe() { printf '%s' "$1" | tr -d '\n\r'; }`) and converted each line to use `printf 'arg-X=%s\n' "$(_safe "$(computed_value)")"` to sanitize user-controlled input values before writing to $GITHUB_OUTPUT.

3. Identifier step (lines 165, 169): Added `safe_pr=$(printf '%s' "${pr_number:-0}" | tr -d '\n\r')` before writing pr to $GITHUB_OUTPUT, and `safe_name=$(printf '%s' "${INPUTS_TOOL}-${safe_pr}-${identifier}.tfplan" | tr -d '\n\r')` before writing name to $GITHUB_OUTPUT, preventing newline injection from user-controlled inputs.pr-number and inputs.tool.

### Iteration 3

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed all 8 unquoted $INPUTS_TOOL command invocations by adding double quotes ("$INPUTS_TOOL") in: tool-check (which), format (fmt), initialize (init), validate (validate), plan (plan), show (show tfplan), plan-parity (plan + two show commands), and apply (apply) steps. Fixed github-env-injection by changing the command consolidation line to use printf '%s' ... | tr -d '\n\r' to strip both newlines and carriage returns before writing to $GITHUB_OUTPUT, preventing injection via \r characters.

### Iteration 4

**Fixes applied:** script-injection

**Notes:**

Fixed all 18 flagged locations (9 pairs of echo+command lines) by replacing unquoted `${STEPS_ARG_CHDIR}` and `${args}` expansions in command execution lines with safe bash array-based expansions. Used `read -ra chdir_args <<< "${STEPS_ARG_CHDIR}"` and `read -ra cmd_args <<< "${args}"` to split the space-separated flag strings into arrays, then used `"${chdir_args[@]}"` and `"${cmd_args[@]}"` in the actual command invocations. This prevents shell metacharacter injection (`;`, `|`, `&`, `$(...)`, backticks) while preserving the word-splitting behavior needed to pass multiple CLI flags as separate arguments to terraform/tofu. The echo/logging lines were left unchanged as they don't execute commands. Fixed steps: format, initialize, validate, plan, show, plan-parity (3 command lines), and apply.


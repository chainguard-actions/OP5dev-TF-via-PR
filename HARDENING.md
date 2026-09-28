<!-- markdownlint-disable -->

# Hardening Report: OP5dev--TF-via-PR/v13.7.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **OP5dev--TF-via-PR/v13.7.1** was hardened automatically. 15 finding(s) were identified and resolved across 4 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a): Multiple ${{ }} expressions are directly interpolated into run: shell command strings in the 'identifier' step. Attacker-controlled values including `${{ github.event.number || github.event.issue.number }}`, `${{ github.ref_name }}`, `${{ github.event.pull_request.head.sha || github.sha }}`, and `${{ github.repository }}` are expanded by the template engine before the shell sees them, enabling command injection via crafted branch names, PR titles, or event payloads.

Locations:

- `action.yml:127`
- `action.yml:131`
- `action.yml:134`

### script-injection (severity: high)

Rule (a): The 'arg' step's run: block directly interpolates `${{ env.TF_CLI_ARGS }}` into a shell command string: `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"`. The env.* context is workflow-controllable and must not appear directly inside a run: script.

Locations:

- `action.yml:70`

### script-injection (severity: high)

Rule (a): The 'format' step's run: block directly interpolates `${{ steps.arg.outputs.arg-check }}`, `${{ steps.arg.outputs.arg-diff }}`, `${{ steps.arg.outputs.arg-list }}`, `${{ steps.arg.outputs.arg-recursive }}`, `${{ steps.arg.outputs.arg-write }}`, and `${{ steps.arg.outputs.arg-chdir }}` into shell command strings (args= assignment and direct tool invocation). steps.*.outputs.* is a workflow-controllable context.

Locations:

- `action.yml:151`
- `action.yml:152`
- `action.yml:153`

### script-injection (severity: high)

Rule (a): The 'initialize' step's run: block directly interpolates multiple `${{ steps.arg.outputs.* }}` and `${{ env.INPUTS_TOOL }}` expressions into shell command strings (args= assignment and direct tool invocation). steps.*.outputs.* and env.* are workflow-controllable contexts.

Locations:

- `action.yml:163`
- `action.yml:164`
- `action.yml:165`

### script-injection (severity: high)

Rule (a): The 'validate' step's run: block directly interpolates multiple `${{ steps.arg.outputs.* }}` and `${{ env.INPUTS_TOOL }}` expressions into shell command strings. steps.*.outputs.* and env.* are workflow-controllable contexts.

Locations:

- `action.yml:175`
- `action.yml:176`
- `action.yml:177`

### script-injection (severity: high)

Rule (a): The 'plan' step's run: block directly interpolates multiple `${{ steps.arg.outputs.* }}` expressions into shell command strings (args= assignment and direct tool invocation). steps.*.outputs.* is a workflow-controllable context.

Locations:

- `action.yml:189`
- `action.yml:190`
- `action.yml:192`

### script-injection (severity: high)

Rule (a): The 'download' step's run: block directly interpolates `${{ github.repository }}` and `${{ steps.identifier.outputs.name }}` into shell command strings. These are workflow-controllable values that are expanded before the shell sees them, enabling injection via crafted artifact names or repository names.

Locations:

- `action.yml:202`
- `action.yml:203`
- `action.yml:204`
- `action.yml:207`
- `action.yml:208`

### script-injection (severity: high)

Rule (a): The 'show' (TF show) step's run: block directly interpolates `${{ steps.arg.outputs.arg-chdir }}` into a shell command string: `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} show tfplan`. steps.*.outputs.* is a workflow-controllable context.

Locations:

- `action.yml:218`

### script-injection (severity: high)

Rule (a): The 'post' step's run: block directly interpolates multiple ${{ }} expressions into shell commands, including `${{ github.repository }}`, `${{ github.run_id }}`, `${{ github.run_attempt }}`, `${{ github.triggering_actor }}`, `${{ github.event.pull_request.updated_at || ... }}`, `${{ steps.format.outcome }}`, `${{ steps.identifier.outputs.name }}`, `${{ steps.identifier.outputs.pr }}`, and many `${{ steps.arg.outputs.* }}` values. These are all workflow-controllable and are expanded before the shell sees them.

Locations:

- `action.yml:248`
- `action.yml:249`
- `action.yml:271`
- `action.yml:285`
- `action.yml:291`

### github-env-injection (severity: high)

The 'arg' step writes `${{ env.TF_CLI_ARGS }}` (an untrusted env.* context value) directly to $GITHUB_ENV without sanitization: `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"`. A newline in TF_CLI_ARGS could inject arbitrary environment variables into subsequent steps. The required sanitization (`printf '%s' ... | tr -d '\n\r'`) is absent.

Locations:

- `action.yml:70`

### github-env-injection (severity: high)

The 'arg' step writes `$INPUTS_TOKEN` (sourced from `${{ inputs.token }}`, a caller-controlled input) to $GITHUB_ENV without sanitization: `echo "GH_TOKEN=$INPUTS_TOKEN" >> "$GITHUB_ENV"`. A newline embedded in the token value could inject arbitrary environment variables into subsequent steps. The required sanitization (`printf '%s' ... | tr -d '\n\r'`) is absent.

Locations:

- `action.yml:69`

### github-env-injection (severity: high)

The 'arg' step writes `$TF_WORKSPACE` (sourced from `${{ env.TF_WORKSPACE || inputs.arg-workspace }}`, a caller-controlled value) to $GITHUB_ENV without sanitization: `echo "TF_WORKSPACE=$TF_WORKSPACE" >> "$GITHUB_ENV"`. A newline in the workspace name could inject arbitrary environment variables into subsequent steps. The required sanitization (`printf '%s' ... | tr -d '\n\r'`) is absent.

Locations:

- `action.yml:73`

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

Fixed all script-injection, github-env-injection, and static-unsanitized-env-write findings in action.yml:

1. **arg step**: Moved ${{ env.TF_CLI_ARGS }} to env block as TF_CLI_ARGS_INPUT. Added printf/tr sanitization for GH_TOKEN ($INPUTS_TOKEN), TF_CLI_ARGS, and TF_WORKSPACE before writing to $GITHUB_ENV.

2. **identifier step**: Moved ${{ github.repository }}, ${{ github.event.pull_request.head.sha || github.sha }}, ${{ github.ref_name }}, ${{ github.event.number || github.event.issue.number }}, and all ${{ steps.arg.outputs.* }} expressions to env block.

3. **format step**: Moved all ${{ steps.arg.outputs.* }} expressions to env block.

4. **initialize step**: Moved all ${{ steps.arg.outputs.* }} and ${{ env.INPUTS_TOOL == 'tofu' && ... }} expressions to env block.

5. **validate step**: Moved all ${{ steps.arg.outputs.* }} and ${{ env.INPUTS_TOOL == 'tofu' && ... }} expressions to env block.

6. **plan step**: Moved all ${{ steps.arg.outputs.* }} expressions to env block.

7. **download step**: Moved ${{ github.repository }} and ${{ steps.identifier.outputs.name }} to env block.

8. **show step**: Moved ${{ steps.arg.outputs.arg-chdir }} to env block.

9. **post step**: Moved all ${{ github.* }}, ${{ steps.format.outcome }}, ${{ steps.identifier.outputs.* }}, and all ${{ steps.arg.outputs.* }} expressions to env block. Replaced template-engine conditionals for expand-diff/expand-summary with bash conditionals.

10. **plan-parity step** (bonus fix): Moved all ${{ steps.arg.outputs.* }} expressions to env block.

11. **apply step** (bonus fix): Moved all ${{ steps.arg.outputs.* }} expressions to env block.

### Iteration 2

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed all 5 security findings in hardened/action/action.yml:

1. GH_HOST env injection (line 80): Added `safe_gh_host=$(printf '%s' "$GITHUB_SERVER_URL" | tr -d '\n\r' | sed 's/.*:\/\//')` before writing to GITHUB_ENV.

2. INPUTS_ARG_* output injection (line 83): Wrapped all user-controlled arg values with `printf '%s' "..." | tr -d '\n\r'` sanitization before writing to GITHUB_OUTPUT.

3. INPUTS_TOOL in identifier step (line 175): Added `safe_tool=$(printf '%s' "$INPUTS_TOOL" | tr -d '\n\r')` before using in the name output.

4. command/summary in post step (lines 447, 452): Added `safe_command` and `safe_summary` variables with `tr -d '\n\r'` sanitization before writing to GITHUB_OUTPUT.

5. Unquoted $INPUTS_TOOL and ${ARG_CHDIR} (multiple lines): Replaced all 9 occurrences of `$INPUTS_TOOL${ARG_CHDIR}` in command execution lines with `"$INPUTS_TOOL""${ARG_CHDIR}"` (properly double-quoted) across format, initialize, validate, plan, parity, apply, and show steps.

### Iteration 3

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed github-env-injection: wrapped 8 unsanitized printf writes to $GITHUB_OUTPUT in the 'arg' step (arg-backend, arg-backup, arg-chdir, arg-get, arg-list, arg-lock-timeout, arg-lock, arg-lockfile) with 'printf "%s" ... | tr -d "\n\r"' sanitization. Also sanitized pr_number in the 'identifier' step before writing to $GITHUB_OUTPUT. Fixed script-injection: quoted $INPUTS_TOOL in the 'which' command, and quoted ${args} in all 5 command execution lines (format, initialize, validate, plan, apply steps) to prevent shell word-splitting on attacker-controlled values.

### Iteration 4

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Two fixes applied to hardened/action/action.yml:
1. github-env-injection (identifier step, ~line 200): Replaced unsanitized `${pr_number}` with `${safe_pr_number}` in the `name` output write. The `safe_pr_number` variable already had newlines stripped via `tr -d '\n\r'`, so this ensures no attacker-controlled newlines can inject additional key=value pairs into $GITHUB_OUTPUT.
2. script-injection (plan-parity step, ~line 380): Replaced the unquoted `plan${ARG_DESTROY}${ARG_VAR_FILE}...${ARG_TARGET} -out=tfplan.parity` expansion with the same pattern used by all other equivalent steps (format, init, validate, apply): collect all ARG_* variables into `args` and invoke `plan"${args}"` with double-quoting, preventing shell metacharacter injection from attacker-controlled input values.


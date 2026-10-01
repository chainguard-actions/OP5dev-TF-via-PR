<!-- markdownlint-disable -->

# Hardening Report: OP5dev--TF-via-PR/v13.7.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **OP5dev--TF-via-PR/v13.7.6** was hardened automatically. 6 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple `run:` blocks directly interpolate `${{ steps.arg.outputs.* }}` expressions into shell commands. These step outputs are derived from caller-controlled `inputs.*` values (e.g., `inputs.arg-chdir`, `inputs.arg-var`, `inputs.arg-target`, etc.), so an attacker who controls the inputs can inject arbitrary shell commands. Violations include:

- **identifier step**: `identifier="${{ steps.arg.outputs.arg-chdir }}${{ steps.arg.outputs.arg-workspace }}..."` — rule (a): direct expression in run block.
- **format step**: `args="${{ steps.arg.outputs.arg-check }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} fmt${args}` — rule (a).
- **initialize step**: `args="${{ steps.arg.outputs.arg-backend-config }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} init${args}` — rule (a).
- **validate step**: `args="${{ env.INPUTS_TOOL == 'tofu' && steps.arg.outputs.arg-var-file || '' }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} validate${args}` — rule (a).
- **plan step**: `args="${{ steps.arg.outputs.arg-destroy }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} plan${args}` — rule (a).
- **plan-parity step**: `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} plan${{ steps.arg.outputs.arg-destroy }}...` — rule (a).
- **apply step**: `plan="${{ steps.arg.outputs.arg-auto-approve }}"`, `args="${{ steps.arg.outputs.arg-destroy }}..."`, `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} apply${args}` — rule (a).
- **post step**: `${{ steps.format.outcome }}` used in `if [[ "${{ steps.format.outcome }}" == "failure" ]]`, `${{ env.INPUTS_EXPAND_DIFF == 'true' && ' open' || '' }}` and `${{ env.INPUTS_EXPAND_SUMMARY == 'true' && ' open' || '' }}` embedded in heredoc shell string, and `${{ steps.arg.outputs.* }}` in command_append — rule (a).
- **arg step**: `${{ env.TF_CLI_ARGS }}` used directly in run block: `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"` — rule (a).

Locations:

- `action.yml:71`
- `action.yml:185`
- `action.yml:200`
- `action.yml:213`
- `action.yml:225`
- `action.yml:235`
- `action.yml:340`
- `action.yml:360`
- `action.yml:430`

### github-env-injection (severity: high)

The `arg` step's `run:` block writes multiple caller-controlled values to `$GITHUB_ENV` without the required `printf '%s' ... | tr -d '\n\r'` sanitization:

1. `echo "GH_TOKEN=$INPUTS_TOKEN" >> "$GITHUB_ENV"` — `INPUTS_TOKEN` is sourced from `inputs.token` (caller-controlled). A newline in the token value could inject arbitrary environment variables.

2. `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"` — `TF_CLI_ARGS` is an inherited process environment variable (set by the calling workflow). Writing it unsanitized to `$GITHUB_ENV` allows a calling workflow to inject arbitrary env vars via a newline in `TF_CLI_ARGS`.

3. `echo "TF_WORKSPACE=$TF_WORKSPACE" >> "$GITHUB_ENV"` — `TF_WORKSPACE` is sourced from `env.TF_WORKSPACE || inputs.arg-workspace` (caller-controlled). A newline in the workspace name could inject arbitrary environment variables.

None of these writes are preceded by the required sanitization step (`safe=$(printf '%s' "$VAR" | tr -d '\n\r')`)

Locations:

- `action.yml:70`
- `action.yml:71`
- `action.yml:74`

### static-unsanitized-env-write (severity: medium)

unsanitized write to $GITHUB_ENV: variable $GH_REPO in step "" comes from a ${{...}} expression and should be sanitized with printf/tr before writing

Locations:

- `action.yml:71`

### static-unsanitized-env-write (severity: medium)

unsanitized write to $GITHUB_ENV: variable $INPUTS_TOKEN in step "" comes from a ${{...}} expression and should be sanitized with printf/tr before writing

Locations:

- `action.yml:72`

### static-unsanitized-env-write (severity: medium)

unsanitized write to $GITHUB_ENV: variable $TF_WORKSPACE in step "" comes from a ${{...}} expression and should be sanitized with printf/tr before writing

Locations:

- `action.yml:76`

### static-unsanitized-env-write (severity: medium)

unsanitized write to $GITHUB_ENV: variable $INPUTS_TOOL in step "" comes from a ${{...}} expression and should be sanitized with printf/tr before writing

Locations:

- `action.yml:152`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, static-unsanitized-env-write

**Notes:**

Fixed all findings in action.yml:

1. **script-injection**: Moved all `${{ steps.arg.outputs.* }}`, `${{ steps.format.outcome }}`, `${{ env.INPUTS_EXPAND_DIFF }}`, and `${{ env.INPUTS_EXPAND_SUMMARY }}` expressions from `run:` shell script bodies to `env:` blocks in the identifier, format, initialize, validate, plan, plan-parity, apply, TF show, and post steps. Each step now references these values as plain shell environment variables (STEP_ARG_CHDIR, STEP_ARG_DESTROY, etc.). The `${{ env.TF_CLI_ARGS }}` expression in the arg step was replaced with the shell variable `$TF_CLI_ARGS`. Conditional expressions like `env.INPUTS_TOOL == 'tofu' && steps.arg.outputs.arg-var-file || ''` were converted to shell `if` statements.

2. **github-env-injection**: The arg step now sanitizes all caller-controlled values before writing to `$GITHUB_ENV` using `printf '%s' "$VAR" | tr -d '\n\r'`: GH_REPO, GH_TOKEN (from INPUTS_TOKEN), TF_CLI_ARGS, and TF_WORKSPACE.

3. **static-unsanitized-env-write**: Same sanitization fixes as github-env-injection. Additionally, the identifier step now sanitizes INPUTS_TOOL before using it in the GH_IDENTIFIER_NAME env var write.

### Iteration 2

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed github-env-injection by sanitizing all 38 GITHUB_OUTPUT writes in the arg step using `_val=$(...)` + `printf '%s' "$_val" | tr -d '\n\r'` pattern. Fixed script-injection by: (1) quoting `which "$INPUTS_TOOL"` in the first step, and (2) replacing the unquoted `$INPUTS_TOOL${STEP_ARG_CHDIR} <subcommand>` execution pattern in all 7 TF command steps (format, initialize, validate, plan, show, parity, apply) with a bash array approach `tf_cmd=("$INPUTS_TOOL"); [[ -n "$STEP_ARG_CHDIR" ]] && tf_cmd+=("${STEP_ARG_CHDIR# }"); "${tf_cmd[@]}" <subcommand>` that properly quotes the tool name while correctly handling the leading-space-prefixed chdir flag.

### Iteration 3

**Fixes applied:** github-env-injection

**Notes:**

Fixed two github-env-injection findings in action.yml:
1. `arg` step (line 80): Sanitized GITHUB_SERVER_URL before writing to GITHUB_ENV. Added `safe_gh_host=$(printf '%s' "${GITHUB_SERVER_URL#*://}" | tr -d '\n\r')` and used `$safe_gh_host` in the echo statement.
2. `identifier` step (lines 233, 237): Sanitized `pr_number` before writing to GITHUB_OUTPUT and GITHUB_ENV. Added `safe_pr_number=$(printf '%s' "${pr_number:-0}" | tr -d '\n\r')` and replaced all uses of `${pr_number:-0}` and `${pr_number}` in the echo statements with `$safe_pr_number`.


<!-- markdownlint-disable -->

# Hardening Report: OP5dev--TF-via-PR/v13.7.4

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **OP5dev--TF-via-PR/v13.7.4** was hardened automatically. 6 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple `run:` blocks in action.yml directly interpolate `${{ ... }}` expressions inside shell command strings (sub-rule a). This causes GitHub Actions to substitute the value into the shell script before the shell ever sees it, enabling command injection if the value contains shell metacharacters.

- `id: arg` step (line ~73): `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"` — `${{ env.TF_CLI_ARGS }}` interpolated directly in run:.
- `id: identifier` step (line ~148): `identifier="${{ steps.arg.outputs.arg-chdir }}${{ steps.arg.outputs.arg-workspace }}..."` — multiple `${{ steps.arg.outputs.* }}` interpolated directly in run:.
- `id: format` step (line ~175): `args="${{ steps.arg.outputs.arg-check }}${{ steps.arg.outputs.arg-diff }}..."` — `${{ steps.arg.outputs.* }}` interpolated directly in run:.
- `id: initialize` step (line ~185): `args="${{ steps.arg.outputs.arg-backend-config }}..."` — `${{ steps.arg.outputs.* }}` interpolated directly in run:.
- `id: validate` step (line ~196): `args="${{ env.INPUTS_TOOL == 'tofu' && steps.arg.outputs.arg-var-file || '' }}..."` — `${{ steps.arg.outputs.* }}` interpolated directly in run:.
- `id: plan` step (line ~208): `args="${{ steps.arg.outputs.arg-destroy }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} plan${args}` — `${{ steps.arg.outputs.* }}` interpolated directly in run:.
- `id: apply` step (line ~260): `plan="${{ steps.arg.outputs.arg-auto-approve }}"` and `args="${{ steps.arg.outputs.arg-destroy }}..."` — `${{ steps.arg.outputs.* }}` interpolated directly in run:.
- `id: post` step (line ~310): `command_append+=$(echo "${{ steps.arg.outputs.arg-workspace }}...")` and `if [[ "${{ steps.format.outcome }}" == "failure" ]]` — `${{ steps.arg.outputs.* }}` and `${{ steps.format.outcome }}` interpolated directly in run:.

All `steps.arg.outputs.*` values are derived from caller-supplied `inputs.*`, making them attacker-controllable. Fix: move all `${{ ... }}` values into `env:` variables and reference them as `"$VAR"` in the shell script.

Locations:

- `action.yml:73`
- `action.yml:148`
- `action.yml:175`
- `action.yml:185`
- `action.yml:196`
- `action.yml:208`
- `action.yml:260`
- `action.yml:310`

### github-env-injection (severity: high)

Multiple `run:` blocks in action.yml write untrusted/workflow-controlled values to `$GITHUB_ENV` without the required sanitization step (`printf '%s' "$VAR" | tr -d '\n\r'`). An attacker can inject newlines to define arbitrary environment variables for subsequent steps.

1. (line ~72) `echo "GH_TOKEN=$INPUTS_TOKEN" >> "$GITHUB_ENV"` — `INPUTS_TOKEN` is set from `inputs.token` (caller-controlled) via env:, then written unsanitized to GITHUB_ENV.

2. (line ~73) `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"` — `env.TF_CLI_ARGS` is a workflow-controlled environment variable written unsanitized to GITHUB_ENV (also a script-injection point as noted above).

3. (line ~76) `echo "TF_WORKSPACE=$TF_WORKSPACE" >> "$GITHUB_ENV"` — `TF_WORKSPACE` is set from `env.TF_WORKSPACE || inputs.arg-workspace` (caller-controlled) via env:, then written unsanitized to GITHUB_ENV.

4. (line ~150) `echo "GH_IDENTIFIER_NAME=${INPUTS_TOOL}-${pr_number}-${identifier}.tfplan" >> "$GITHUB_ENV"` — `INPUTS_TOOL` is set from `inputs.tool` (caller-controlled) via env:, then written unsanitized to GITHUB_ENV.

Fix: apply `safe=$(printf '%s' "$VAR" | tr -d '\n\r')` before each write to GITHUB_ENV.

Locations:

- `action.yml:72`
- `action.yml:73`
- `action.yml:76`
- `action.yml:150`

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

Fixed all script-injection findings by moving every ${{ ... }} expression out of run: blocks and into env: blocks, then referencing them as $VAR_NAME in shell scripts. Fixed all github-env-injection and static-unsanitized-env-write findings by sanitizing values with `printf '%s' "$VAR" | tr -d '\n\r'` before writing to $GITHUB_ENV. Key changes: (1) id:arg step - added TF_CLI_ARGS_ENV env var for TF_CLI_ARGS, sanitized GH_REPO, INPUTS_TOKEN, TF_CLI_ARGS, TF_WORKSPACE before GITHUB_ENV writes; (2) id:identifier step - moved all steps.arg.outputs.* to STEP_ARG_* env vars, sanitized INPUTS_TOOL/pr_number/identifier before GITHUB_ENV write; (3) id:format step - moved all steps.arg.outputs.* to STEP_ARG_* env vars; (4) id:initialize step - moved all steps.arg.outputs.* and inputs.tool conditionals to env vars; (5) id:validate step - same as initialize; (6) id:plan step - moved all steps.arg.outputs.* to STEP_ARG_* env vars; (7) TF show step - moved arg-chdir to env var; (8) plan parity step - moved all steps.arg.outputs.* to env vars; (9) id:apply step - moved all steps.arg.outputs.* to env vars; (10) id:post step - moved all steps.arg.outputs.*, steps.format.outcome to env vars, replaced ${{ env.INPUTS_EXPAND_DIFF == 'true' && ' open' || '' }} and ${{ env.INPUTS_EXPAND_SUMMARY == 'true' && ' open' || '' }} with shell conditionals using expand_diff_attr and expand_summary_attr variables.

### Iteration 2

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed github-env-injection by adding a _safe() helper function in the 'arg' step that strips newlines (printf '%s' "$1" | tr -d '\n\r') and wrapping all 37 input-derived GITHUB_OUTPUT writes with $(_safe "..."). Fixed script-injection by: (1) adding a case statement to validate $INPUTS_TOOL is 'terraform' or 'tofu' before use, (2) quoting "$INPUTS_TOOL" in all command executions (format, initialize, validate, plan, show, parity, apply steps), and (3) quoting "$INPUTS_TOOL" in the which check. The $STEP_ARG_CHDIR and $args variables remain unquoted for intentional word-splitting (they contain space-separated CLI flags like ' -chdir=path' and ' -flag1 -flag2'), which is the correct behavior for passing multiple arguments to the terraform/tofu CLI.

### Iteration 3

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed github-env-injection by sanitizing pr_number with printf/tr before writing to GITHUB_OUTPUT. Fixed script-injection in 7 run blocks (format, initialize, validate, plan, show, apply, plan-parity) by replacing unquoted ${STEP_ARG_CHDIR} and ${args} expansions with properly tokenized bash arrays using the xargs/while-read-loop pattern. Each affected step now tokenizes the flag strings into arrays with guarded if-blocks to prevent empty-value issues, then expands them with "${array[@]}" for safe argument passing.


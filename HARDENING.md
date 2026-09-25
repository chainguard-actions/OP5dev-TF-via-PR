<!-- markdownlint-disable -->

# Hardening Report: OP5dev--TF-via-PR/v14.0.0-alpha

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **OP5dev--TF-via-PR/v14.0.0-alpha** was hardened automatically. 6 finding(s) were identified and resolved across 5 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Multiple `run:` blocks in action.yml directly interpolate `${{ ... }}` expressions inside shell commands. The GitHub Actions template engine substitutes these before the shell executes them, allowing an attacker-controlled value to inject arbitrary shell commands.

1. **arg step** (~line 76): `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" ...)` — `${{ env.TF_CLI_ARGS }}` interpolated directly in run.

2. **identifier step** (~line 183): `identifier="${{ steps.arg.outputs.arg-chdir }}${{ steps.arg.outputs.arg-workspace }}..."` — multiple `steps.arg.outputs.*` expressions (derived from `inputs.*`) interpolated directly in shell variable assignment.

3. **format step** (~line 196): `args="${{ steps.arg.outputs.arg-check }}${{ steps.arg.outputs.arg-diff }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} fmt${args}` — expressions interpolated directly in shell commands.

4. **initialize step** (~line 204): `args="${{ steps.arg.outputs.arg-backend-config }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} init${args}` — expressions interpolated directly in shell commands.

5. **validate step** (~line 213): `args="${{ env.INPUTS_TOOL == 'tofu' && steps.arg.outputs.arg-var-file || '' }}..."` — expressions interpolated directly in shell commands.

6. **plan step** (~line 222): `args="${{ steps.arg.outputs.arg-destroy }}${{ steps.arg.outputs.arg-var-file }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} plan${args}` — expressions interpolated directly in shell commands.

7. **parity step** (~line 240): `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} plan${{ steps.arg.outputs.arg-destroy }}...` — expressions interpolated directly in shell commands.

8. **apply step** (~line 253): `plan="${{ steps.arg.outputs.arg-auto-approve }}"` and `args="${{ steps.arg.outputs.arg-destroy }}..."` — expressions interpolated directly in shell commands.

9. **post step** (~line 270): `if [[ "${{ steps.format.outcome }}" == "failure" ]]`, `${{ env.INPUTS_EXPAND_DIFF == 'true' && ' open' || '' }}`, `${{ env.INPUTS_EXPAND_SUMMARY == 'true' && ' open' || '' }}`, and `command_append+=$(echo "${{ steps.arg.outputs.arg-workspace }}...")` — multiple expressions interpolated directly in shell commands.

Locations:

- `action.yml:76`
- `action.yml:183`
- `action.yml:196`
- `action.yml:204`
- `action.yml:213`
- `action.yml:222`
- `action.yml:240`
- `action.yml:253`
- `action.yml:270`

### github-env-injection (severity: high)

Multiple `run:` blocks write values derived from untrusted/workflow-controlled sources to `$GITHUB_ENV` and `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`).

1. **arg step** (~line 76): `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"` — `${{ env.TF_CLI_ARGS }}` is a workflow-controlled env var written directly to `$GITHUB_ENV` without sanitization, enabling newline injection to set arbitrary environment variables.

2. **arg step** (~line 78–120): All `echo arg-*=... >> "$GITHUB_OUTPUT"` lines write values derived from `inputs.*` (e.g., `$INPUTS_ARG_BACKEND_CONFIG`, `$INPUTS_ARG_VAR`, `$INPUTS_ARG_TARGET`, etc.) to `$GITHUB_OUTPUT` without sanitization. These outputs are then consumed by downstream `run:` steps.

3. **identifier step** (~line 185): `echo "GH_IDENTIFIER_NAME=${INPUTS_TOOL}-${pr_number}-${identifier}.tfplan" >> "$GITHUB_ENV"` — `INPUTS_TOOL` is derived from `inputs.tool` (untrusted) and written to `$GITHUB_ENV` without sanitization.

Locations:

- `action.yml:76`
- `action.yml:78`
- `action.yml:185`

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

Fixed all security findings in hardened/action/action.yml:

1. script-injection (9 locations): Moved all ${{ ... }} expressions out of run: shell blocks into env: blocks for each step (arg, identifier, format, initialize, validate, plan, parity, apply, post). Shell scripts now reference values as plain $VAR_NAME environment variables. The ${{ env.INPUTS_EXPAND_DIFF == 'true' && ' open' || '' }} and ${{ env.INPUTS_EXPAND_SUMMARY == 'true' && ' open' || '' }} expressions in the post step were replaced with shell conditionals using the already-present INPUTS_EXPAND_DIFF and INPUTS_EXPAND_SUMMARY env vars. The ${{ env.INPUTS_TOOL == 'tofu' && steps.arg.outputs.arg-var-file || '' }} conditional expressions in initialize and validate steps were replaced with bash if/then conditionals.

2. github-env-injection (3 locations): Added printf '%s' "$VAR" | tr -d '\n\r' sanitization before all writes to $GITHUB_ENV: GH_REPO, GH_TOKEN (from INPUTS_TOKEN), TF_CLI_ARGS (also fixed the ${{ env.TF_CLI_ARGS }} injection by using the runner env var directly), TF_WORKSPACE, and GH_IDENTIFIER_NAME (INPUTS_TOOL in identifier step).

3. static-unsanitized-env-write (4 instances): All 4 unsanitized GITHUB_ENV writes (GH_REPO, INPUTS_TOKEN/GH_TOKEN, TF_WORKSPACE, INPUTS_TOOL) are now sanitized with printf/tr before writing.

### Iteration 2

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed all four findings in action.yml:

1. GH_HOST sanitization: Added printf/tr -d sanitization for GITHUB_SERVER_URL before writing to $GITHUB_ENV.

2. GITHUB_OUTPUT sanitization: Rewrote all 22 CLI argument output writes that embed user-controlled input values to use a two-step pattern: compute value with printf/tr -d into _val, then echo to $GITHUB_OUTPUT. Boolean-only flags (which only emit fixed strings) were left as-is since they cannot contain newlines.

3. pr_number sanitization: Added safe_pr_number=$(printf '%s' "${pr_number:-0}" | tr -d '\n\r') and used it in both the $GITHUB_OUTPUT and $GITHUB_ENV writes in the identifier step.

4. $INPUTS_TOOL quoting: Added double quotes around $INPUTS_TOOL in all 8 shell command positions (which check, format, initialize, validate, plan, show, plan-parity x3, apply) to prevent shell metacharacter injection.

### Iteration 3

**Fixes applied:** github-env-injection

**Notes:**

Fixed the `arg-workspace` output in the `arg` step's `run:` block (action.yml). The original code used `echo " -workspace=$TF_WORKSPACE"` inside a subshell without newline stripping, allowing a newline-containing `TF_WORKSPACE` value to inject arbitrary key=value pairs into `$GITHUB_OUTPUT`. The fix replaces it with the same safe pattern used by all other non-boolean args: `_val=$([[ -n "$TF_WORKSPACE" ]] && printf '%s' " -workspace=$TF_WORKSPACE" | tr -d '\n\r' || echo ""); echo "arg-workspace=${_val}" >> "$GITHUB_OUTPUT"`.

### Iteration 4

**Fixes applied:** script-injection

**Notes:**

Fixed unquoted `${ARG_CHDIR}` expansion in 7 shell commands across the action (format, initialize, validate, plan, show, plan-parity, and apply steps). Each affected step now builds a `chdir_args` bash array: when `ARG_CHDIR` is non-empty (e.g., ` -chdir=path/to/dir`), the leading space is stripped with `${ARG_CHDIR# }` and the value is stored as a single properly-quoted array element; the array is then expanded as `"${chdir_args[@]}"` in the actual command execution. This prevents word-splitting and glob expansion on the user-controlled path value. The echo/logging statements that write to tf.command.txt and the MD5 identifier computation still reference `${ARG_CHDIR}` directly, which is safe as they don't execute shell commands based on the value.

### Iteration 5

**Fixes applied:** script-injection

**Notes:**

Fixed all 6 script-injection locations in action.yml where unquoted `${args}` or `${ARG_*}` variable expansions were appended directly to terraform/tofu commands (fmt, init, validate, plan, plan-parity, apply steps). Each fix uses the xargs-based array tokenization pattern: the args string is tokenized into a bash array via `printf '%s' "$args" | xargs printf '%s\0'` with a null-delimited read loop, then the array is expanded with `"${args_array[@]}"` in the actual tool invocation. The echo/logging lines that write tf.command.txt were left unchanged as they only produce human-readable output and don't execute commands.


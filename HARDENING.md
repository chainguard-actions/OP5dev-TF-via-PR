<!-- markdownlint-disable -->

# Hardening Report: OP5dev--TF-via-PR/v13.7.4

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **OP5dev--TF-via-PR/v13.7.4** was hardened automatically. 6 finding(s) were identified and resolved across 4 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple `run:` blocks in action.yml directly interpolate `${{ ... }}` expressions inside shell command strings, violating rule (a). This includes:

- **`arg` step** (run block): `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"` — `${{ env.TF_CLI_ARGS }}` is interpolated directly into the shell.

- **`identifier` step** (run block): `identifier="${{ steps.arg.outputs.arg-chdir }}${{ steps.arg.outputs.arg-workspace }}..."` — step outputs (derived from user inputs) are interpolated directly into a shell variable assignment.

- **`format` step** (run block): `args="${{ steps.arg.outputs.arg-check }}${{ steps.arg.outputs.arg-diff }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} fmt${args}` — step outputs interpolated directly into shell commands.

- **`initialize` step** (run block): Same pattern — `args="${{ steps.arg.outputs.arg-backend-config }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} init${args}`.

- **`validate` step** (run block): Same pattern — `args="${{ env.INPUTS_TOOL == 'tofu' && steps.arg.outputs.arg-var-file || '' }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} validate${args}`.

- **`plan` step** (run block): Same pattern — `args="${{ steps.arg.outputs.arg-destroy }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} plan${args}`.

- **Parity step** (unnamed run block): `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} plan${{ steps.arg.outputs.arg-destroy }}...` — multiple step outputs interpolated directly into shell commands.

- **`apply` step** (run block): `plan="${{ steps.arg.outputs.arg-auto-approve }}"`, `var_file="${{ steps.arg.outputs.arg-var-file }}"`, `var="${{ steps.arg.outputs.arg-var }}"`, and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} apply${args}`.

- **`post` step** (run block): `command_append+=$(echo "${{ steps.arg.outputs.arg-workspace }}...")`, `if [[ "${{ steps.format.outcome }}" == "failure" ]]`, `<details${{ env.INPUTS_EXPAND_DIFF == 'true' && ' open' || '' }}>`, and `<details${{ env.INPUTS_EXPAND_SUMMARY == 'true' && ' open' || '' }}>` — all interpolated directly in the shell script.

The `steps.arg.outputs.*` values are derived from user-controlled `inputs.*` values. Any `${{ ... }}` expression inside a `run:` block is a script-injection risk regardless of context.

Locations:

- `action.yml:71`
- `action.yml:155`
- `action.yml:172`
- `action.yml:185`
- `action.yml:199`
- `action.yml:213`
- `action.yml:270`
- `action.yml:295`
- `action.yml:330`

### github-env-injection (severity: high)

Multiple writes to `$GITHUB_ENV` in action.yml use unsanitized values derived from user-controlled inputs or workflow-controlled environment variables, without the required `printf '%s' ... | tr -d '\n\r'` sanitization step:

1. **`arg` step**: `echo "GH_TOKEN=$INPUTS_TOKEN" >> "$GITHUB_ENV"` — `INPUTS_TOKEN` is set from `inputs.token` (caller-controlled). Written directly to GITHUB_ENV without sanitization.

2. **`arg` step**: `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"` — `env.TF_CLI_ARGS` is a workflow-controlled environment variable interpolated directly into the shell and then written to GITHUB_ENV without sanitization.

3. **`arg` step**: `echo "TF_WORKSPACE=$TF_WORKSPACE" >> "$GITHUB_ENV"` — `TF_WORKSPACE` is set from `inputs.arg-workspace` (caller-controlled). Written directly to GITHUB_ENV without sanitization.

4. **`identifier` step**: `echo "GH_IDENTIFIER_NAME=${INPUTS_TOOL}-${pr_number}-${identifier}.tfplan" >> "$GITHUB_ENV"` — `INPUTS_TOOL` comes from `inputs.tool` (caller-controlled). Written to GITHUB_ENV without sanitization.

An attacker controlling these input values could inject newlines to set arbitrary environment variables via GITHUB_ENV.

Locations:

- `action.yml:70`
- `action.yml:71`
- `action.yml:74`
- `action.yml:157`

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

Fixed all script-injection findings by moving every ${{ ... }} expression from run: shell blocks into the step's env: block, then referencing them as plain environment variables ($VAR_NAME) in the shell script. This affects the arg, identifier, format, initialize, validate, plan, TF-show, parity, apply, and post steps.

Fixed all github-env-injection and static-unsanitized-env-write findings by adding printf '%s' ... | tr -d '\n\r' sanitization before writing user-controlled values to $GITHUB_ENV:
- GH_REPO (from github.repository)
- GH_TOKEN (from inputs.token)
- TF_CLI_ARGS (from env.TF_CLI_ARGS, moved to TF_CLI_ARGS_EXISTING env var to avoid script injection)
- TF_WORKSPACE (from env.TF_WORKSPACE || inputs.arg-workspace)
- GH_IDENTIFIER_NAME (from INPUTS_TOOL + pr_number + identifier)

In the post step, the ${{ env.INPUTS_EXPAND_DIFF == 'true' && ' open' || '' }} and ${{ env.INPUTS_EXPAND_SUMMARY == 'true' && ' open' || '' }} expressions were replaced with shell if-statements using the already-sanitized INPUTS_EXPAND_DIFF and INPUTS_EXPAND_SUMMARY env vars. The ${{ steps.format.outcome }} expression was moved to STEP_FORMAT_OUTCOME env var.

### Iteration 2

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed github-env-injection by: (1) sanitizing GH_HOST before writing to GITHUB_ENV using printf+tr, and (2) adding sanitization of all 22 caller-controlled INPUTS_ARG_* variables (and TF_WORKSPACE) with printf '%s' ... | tr -d '\n\r' before they are written to GITHUB_OUTPUT. Fixed script-injection by: (1) quoting $INPUTS_TOOL in the 'which' check, and (2) replacing the unquoted '$INPUTS_TOOL${STEP_ARG_CHDIR}' command pattern in all 6 execution steps (format, initialize, validate, plan, show, plan-parity, apply) with a safe array-based approach using 'read -ra chdir_args <<< "${STEP_ARG_CHDIR}"' followed by '"$INPUTS_TOOL" "${chdir_args[@]}"'.

### Iteration 3

**Fixes applied:** github-env-injection, github-env-injection

**Notes:**

Fixed two github-env-injection findings in action.yml:
1. (line ~121, arg step) Added `INPUTS_ARG_BACKEND=$(printf '%s' "$INPUTS_ARG_BACKEND" | tr -d '\n\r')` to the sanitization block before the variable is written to $GITHUB_OUTPUT. It was the only string-valued INPUTS_ARG_* variable missing from the sanitization list.
2. (line ~222, identifier step) Added `safe_pr_number=$(printf '%s' "${pr_number:-0}" | tr -d '\n\r')` and changed the GITHUB_OUTPUT write to use `echo "pr=$safe_pr_number"` instead of the unsanitized `echo "pr=${pr_number:-0}"`, preventing newline injection from caller-controlled `inputs.pr-number`.

### Iteration 4

**Fixes applied:** github-env-injection

**Notes:**

Fixed the unsanitized write of `run_url` to `$GITHUB_OUTPUT` in the post step's run block. Added `safe_run_url=$(printf '%s' "$run_url" | tr -d '\n\r')` before the echo statement, and changed the echo to use `$safe_run_url` instead of `$run_url`. This follows the same sanitization pattern already used for all other github context-derived values written to $GITHUB_ENV and $GITHUB_OUTPUT in this action.


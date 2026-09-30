<!-- markdownlint-disable -->

# Hardening Report: OP5dev--TF-via-PR/v13.7.5

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **OP5dev--TF-via-PR/v13.7.5** was hardened automatically. 6 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple `run:` blocks in action.yml directly interpolate `${{ ... }}` expressions inside shell command strings (sub-rule a), enabling script injection. Affected steps and offending patterns:

1. **`arg` step** — `${{ env.TF_CLI_ARGS }}` is interpolated directly in the shell command: `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" ...` >> $GITHUB_ENV`. The `env.*` context is workflow-controllable.

2. **`identifier` step** — `${{ steps.arg.outputs.arg-chdir }}`, `${{ steps.arg.outputs.arg-workspace }}`, `${{ steps.arg.outputs.arg-backend-config }}`, `${{ steps.arg.outputs.arg-var-file }}`, `${{ steps.arg.outputs.arg-var }}`, `${{ steps.arg.outputs.arg-replace }}`, `${{ steps.arg.outputs.arg-target }}`, `${{ steps.arg.outputs.arg-destroy }}` are all interpolated directly in a shell variable assignment: `identifier="${{ steps.arg.outputs.arg-chdir }}..."`.

3. **`format` step** — `${{ steps.arg.outputs.arg-check }}`, `${{ steps.arg.outputs.arg-diff }}`, `${{ steps.arg.outputs.arg-list }}`, `${{ steps.arg.outputs.arg-recursive }}`, `${{ steps.arg.outputs.arg-write }}`, and `${{ steps.arg.outputs.arg-chdir }}` are interpolated directly in `args=` and the tool invocation line.

4. **`initialize` step** — `${{ steps.arg.outputs.arg-backend-config }}` and many other `steps.arg.outputs.*` expressions are interpolated directly in `args=` and the tool invocation.

5. **`plan` step** — `${{ steps.arg.outputs.arg-destroy }}` and many other `steps.arg.outputs.*` expressions are interpolated directly in `args=` and the tool invocation.

6. **`apply` step** — `${{ steps.arg.outputs.arg-destroy }}` and many other `steps.arg.outputs.*` expressions are interpolated directly in `args=` and the tool invocation.

7. **`post` step** — `${{ steps.format.outcome }}` is interpolated directly in an `if [[ ... ]]` comparison; `${{ env.INPUTS_EXPAND_DIFF }}` and `${{ env.INPUTS_EXPAND_SUMMARY }}` are interpolated directly in heredoc content; and many `${{ steps.arg.outputs.* }}` expressions are interpolated directly in an `echo` command inside a loop.

All `steps.*.outputs.*` values are derived from caller-controlled `inputs.*` values, making them attacker-controllable. Any of these expressions can contain shell metacharacters that will be interpreted by the shell before quoting takes effect.

Locations:

- `action.yml:100`
- `action.yml:200`
- `action.yml:222`
- `action.yml:234`
- `action.yml:258`
- `action.yml:280`
- `action.yml:452`
- `action.yml:530`
- `action.yml:560`

### github-env-injection (severity: high)

Multiple `run:` blocks in action.yml write values derived from untrusted inputs to `$GITHUB_ENV` and `$GITHUB_OUTPUT` without the required `printf '%s' ... | tr -d '\n\r'` sanitization step. An attacker can inject newlines into these values to poison subsequent environment variables or outputs.

1. **`arg` step** — `echo "GH_REPO=$GH_REPO" >> "$GITHUB_ENV"`: `GH_REPO` is set from `${{ github.repository }}` (attacker-influenced via fork/PR). No sanitization.

2. **`arg` step** — `echo "GH_TOKEN=$INPUTS_TOKEN" >> "$GITHUB_ENV"`: `INPUTS_TOKEN` is set from `${{ inputs.token }}` (caller-controlled). No sanitization.

3. **`arg` step** — `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" ...) >> "$GITHUB_ENV"`: `env.TF_CLI_ARGS` is a workflow-controlled env var written directly into `$GITHUB_ENV`. No sanitization.

4. **`arg` step** — `echo "TF_WORKSPACE=$TF_WORKSPACE" >> "$GITHUB_ENV"`: `TF_WORKSPACE` is set from `${{ env.TF_WORKSPACE || inputs.arg-workspace }}` (caller-controlled). No sanitization.

5. **`identifier` step** — `echo "GH_IDENTIFIER_NAME=${INPUTS_TOOL}-${pr_number}-${identifier}.tfplan" >> "$GITHUB_ENV"`: `INPUTS_TOOL` comes from `${{ inputs.tool }}` (caller-controlled). No sanitization.

6. **`arg` step** — All `echo arg-*=... >> "$GITHUB_OUTPUT"` lines write values derived from `inputs.*` (e.g., `$INPUTS_ARG_BACKEND_CONFIG`, `$INPUTS_ARG_VAR`, `$INPUTS_ARG_TARGET`, etc.) to `$GITHUB_OUTPUT` without sanitization. These outputs are then consumed by subsequent steps.

Locations:

- `action.yml:97`
- `action.yml:98`
- `action.yml:99`
- `action.yml:100`
- `action.yml:103`
- `action.yml:107`
- `action.yml:200`

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

1. script-injection: Moved all ${{ ... }} expressions from run: blocks to env: blocks across all affected steps (arg, identifier, format, initialize, validate, plan, plan-parity, apply, post). Shell scripts now reference values as plain environment variables (e.g., $STEP_ARG_CHDIR instead of ${{ steps.arg.outputs.arg-chdir }}). The ${{ env.TF_CLI_ARGS }} expression was moved to TF_CLI_ARGS_EXISTING env var. The ${{ steps.format.outcome }}, ${{ env.INPUTS_EXPAND_DIFF }}, and ${{ env.INPUTS_EXPAND_SUMMARY }} expressions in the post step were replaced with $STEP_FORMAT_OUTCOME and shell conditionals using already-available env vars.

2. github-env-injection: All values written to $GITHUB_ENV from ${{ ... }} expressions are now sanitized with printf '%s' "$VAR" | tr -d '\n\r' before writing: GH_REPO, GH_TOKEN (INPUTS_TOKEN), TF_CLI_ARGS, TF_WORKSPACE, and GH_IDENTIFIER_NAME.

3. static-unsanitized-env-write: Same sanitization fixes address all four static findings for GH_REPO, INPUTS_TOKEN, TF_WORKSPACE, and GH_IDENTIFIER_NAME (INPUTS_TOOL).

### Iteration 2

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed three github-env-injection findings and one script-injection finding in hardened/action/action.yml:

1. GH_HOST write to $GITHUB_ENV: Added `safe_gh_host=$(printf '%s' "${GITHUB_SERVER_URL#*://}" | tr -d '\n\r')` sanitization before writing.

2. printf 'arg-*=%s\n' writes to $GITHUB_OUTPUT: Added `safe_arg=$(... | tr -d '\n\r')` sanitization for all string-valued inputs (backend-config, backend, backup, chdir, from-module, generate-config-out, get, list, lock-timeout, lock, lockfile, parallelism, plugin-dir, refresh, replace, state-out, state, target, test-directory, var-file, var, write, workspace). Boolean-only args that only produce fixed strings like ' -flag' or '' were left as-is since they cannot contain newlines.

3. pr_number write to $GITHUB_OUTPUT: Added `safe_pr_number=$(printf '%s' "${pr_number:-0}" | tr -d '\n\r')` sanitization before writing.

4. Unquoted $INPUTS_TOOL in command execution positions: Changed all 10 command execution occurrences to use `"$INPUTS_TOOL"` (quoted) in: which check, format step, initialize step, validate step, plan step, TF show step, plan parity step (3 lines), and apply step.


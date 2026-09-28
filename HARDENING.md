<!-- markdownlint-disable -->

# Hardening Report: OP5dev--TF-via-PR/v13.7.5

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **OP5dev--TF-via-PR/v13.7.5** was hardened automatically. 14 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): The `arg` step's `run:` block directly interpolates `${{ env.TF_CLI_ARGS }}` inside a shell command: `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"`. Any `${{ ... }}` expression inside a `run:` block is evaluated by the YAML template engine before the shell sees it, allowing injection of shell metacharacters.

Locations:

- `action.yml:77`

### script-injection (severity: high)

Sub-rule (a): The `identifier` step's `run:` block directly interpolates multiple `${{ steps.arg.outputs.* }}` expressions inside a shell variable assignment: `identifier="${{ steps.arg.outputs.arg-chdir }}${{ steps.arg.outputs.arg-workspace }}...${{ steps.arg.outputs.arg-destroy }}"`. These outputs are derived from user-controlled `inputs.*` values and are interpolated directly into the shell script before execution.

Locations:

- `action.yml:163`

### script-injection (severity: high)

Sub-rule (a): The `format` step's `run:` block directly interpolates `${{ steps.arg.outputs.arg-check }}`, `${{ steps.arg.outputs.arg-diff }}`, `${{ steps.arg.outputs.arg-list }}`, `${{ steps.arg.outputs.arg-recursive }}`, `${{ steps.arg.outputs.arg-write }}`, and `${{ steps.arg.outputs.arg-chdir }}` inside shell commands: `args="${{ steps.arg.outputs.arg-check }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} fmt${args}`. These outputs are derived from user-controlled inputs.

Locations:

- `action.yml:175`

### script-injection (severity: high)

Sub-rule (a): The `initialize` step's `run:` block directly interpolates multiple `${{ steps.arg.outputs.* }}` and `${{ env.INPUTS_TOOL == 'tofu' && ... }}` expressions inside shell commands: `args="${{ steps.arg.outputs.arg-backend-config }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} init${args}`. These outputs are derived from user-controlled inputs.

Locations:

- `action.yml:185`

### script-injection (severity: high)

Sub-rule (a): The `validate` step's `run:` block directly interpolates `${{ env.INPUTS_TOOL == 'tofu' && steps.arg.outputs.arg-var-file || '' }}`, `${{ steps.arg.outputs.arg-no-tests }}`, `${{ steps.arg.outputs.arg-test-directory }}`, and `${{ steps.arg.outputs.arg-chdir }}` inside shell commands. These are evaluated by the YAML template engine before the shell sees them.

Locations:

- `action.yml:196`

### script-injection (severity: high)

Sub-rule (a): The `plan` step's `run:` block directly interpolates multiple `${{ steps.arg.outputs.* }}` expressions inside shell commands: `args="${{ steps.arg.outputs.arg-destroy }}${{ steps.arg.outputs.arg-var-file }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} plan${args}`. These outputs are derived from user-controlled inputs.

Locations:

- `action.yml:208`

### script-injection (severity: high)

Sub-rule (a): The `apply` step's `run:` block directly interpolates `${{ steps.arg.outputs.arg-auto-approve }}`, `${{ steps.arg.outputs.arg-var-file }}`, `${{ steps.arg.outputs.arg-var }}`, `${{ steps.arg.outputs.arg-destroy }}`, and `${{ steps.arg.outputs.arg-chdir }}` inside shell variable assignments and commands. These outputs are derived from user-controlled inputs.

Locations:

- `action.yml:247`

### script-injection (severity: high)

Sub-rule (a): The `post` step's `run:` block directly interpolates multiple `${{ steps.arg.outputs.* }}` expressions (e.g., `${{ steps.arg.outputs.arg-workspace }}`, `${{ steps.arg.outputs.arg-backend-config }}`, etc.), `${{ steps.format.outcome }}`, `${{ env.INPUTS_EXPAND_DIFF == 'true' && ' open' || '' }}`, and `${{ env.INPUTS_EXPAND_SUMMARY == 'true' && ' open' || '' }}` inside shell commands. All are evaluated by the YAML template engine before the shell sees them, enabling injection.

Locations:

- `action.yml:280`

### github-env-injection (severity: high)

The `arg` step's `run:` block writes multiple unsanitized values to `$GITHUB_ENV` without the required `printf '%s' ... | tr -d '\n\r'` sanitization step: (1) `echo "GH_TOKEN=$INPUTS_TOKEN" >> "$GITHUB_ENV"` — `INPUTS_TOKEN` is sourced from `inputs.token` (caller-controlled); (2) `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"` — `env.TF_CLI_ARGS` is workflow-controlled; (3) `echo "TF_WORKSPACE=$TF_WORKSPACE" >> "$GITHUB_ENV"` — `TF_WORKSPACE` is sourced from `env.TF_WORKSPACE || inputs.arg-workspace` (caller-controlled). A newline in any of these values can inject arbitrary environment variables.

Locations:

- `action.yml:76`
- `action.yml:77`
- `action.yml:80`

### github-env-injection (severity: high)

The `identifier` step's `run:` block writes `echo "GH_IDENTIFIER_NAME=${INPUTS_TOOL}-${pr_number}-${identifier}.tfplan" >> "$GITHUB_ENV"` without sanitization. `INPUTS_TOOL` is sourced from `inputs.tool` (caller-controlled) and `pr_number` is derived from GitHub event data (`github.event.number`, `github.event.issue.number`, `github.ref_name`, etc.). A newline in either value can inject arbitrary environment variables.

Locations:

- `action.yml:164`

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

Fixed all script-injection findings by moving every ${{ }} expression from run: blocks into the step's env: block and referencing them as plain environment variables. Fixed github-env-injection findings by adding printf '%s' ... | tr -d '\n\r' sanitization before writing GH_REPO, GH_TOKEN, TF_CLI_ARGS, TF_WORKSPACE (arg step), and GH_IDENTIFIER_NAME components (identifier step) to $GITHUB_ENV. Fixed static-unsanitized-env-write findings for GH_REPO, INPUTS_TOKEN, TF_WORKSPACE (arg step) and INPUTS_TOOL (identifier step) by using safe_ prefixed variables with tr sanitization. Also fixed the TF show step and plan parity step which had inline ${{ steps.arg.outputs.* }} expressions in their run blocks. The ${{ env.INPUTS_EXPAND_DIFF == 'true' && ' open' || '' }} and ${{ env.INPUTS_EXPAND_SUMMARY == 'true' && ' open' || '' }} template expressions in the post step were replaced with shell conditionals using the already-available INPUTS_EXPAND_DIFF and INPUTS_EXPAND_SUMMARY env vars.

### Iteration 2

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed three security findings in hardened/action/action.yml:

1. script-injection: Quoted all unquoted `$INPUTS_TOOL` variable expansions in command execution positions (which check, format, initialize, validate, plan, show, plan-parity x3, apply steps) by changing `$INPUTS_TOOL${STEP_ARG_CHDIR}` to `"$INPUTS_TOOL"${STEP_ARG_CHDIR}`.

2. github-env-injection (GH_HOST): Added sanitization before writing GITHUB_SERVER_URL-derived value to $GITHUB_ENV: `safe_gh_host=$(printf '%s' "${GITHUB_SERVER_URL#*://}" | tr -d '\n\r')` then `echo "GH_HOST=$safe_gh_host"`.

3. github-env-injection (arg outputs): Rewrote all ~38 `echo arg-X=$(...)` lines that wrote caller-controlled values to $GITHUB_OUTPUT. Each line now captures the subshell result into `_v`, sanitizes with `printf '%s' "$_v" | tr -d '\n\r'`, and writes using `printf 'arg-X=%s\n'` to prevent newline injection attacks.

### Iteration 3

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed two security findings in hardened/action/action.yml:

1. github-env-injection: Moved `safe_pr=$(printf '%s' "${pr_number:-0}" | tr -d '\n\r')` to before the `echo "pr=..." >> "$GITHUB_OUTPUT"` line, so the sanitized value is used when writing to GITHUB_OUTPUT instead of the raw unsanitized `pr_number`.

2. script-injection: Fixed 6 locations (format, initialize, validate, plan, show, parity-check, apply steps) where `${STEP_ARG_CHDIR}` and `${args}` were expanded unquoted in shell command execution. Each step now uses bash arrays built via xargs-based null-delimited tokenization (`printf '%s' "$VAR" | xargs printf '%s\0'` with `while IFS= read -r -d '' t; do arr+=("$t"); done`) to safely pass arguments without allowing shell metacharacter injection. The logging echo lines that use the unquoted variables inside double-quoted strings were left unchanged as they are safe.


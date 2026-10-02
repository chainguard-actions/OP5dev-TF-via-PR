<!-- markdownlint-disable -->

# Hardening Report: OP5dev--TF-via-PR/v14.0.0-alpha

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **OP5dev--TF-via-PR/v14.0.0-alpha** was hardened automatically. 6 finding(s) were identified and resolved across 4 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple `run:` blocks in action.yml directly interpolate `${{ ... }}` expressions inside shell command strings (sub-rule a), which allows template substitution to inject arbitrary shell metacharacters before the shell ever parses the command.

**format step** (~line 196): `args="${{ steps.arg.outputs.arg-check }}${{ steps.arg.outputs.arg-diff }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} fmt${args}` — step outputs derived from user-controlled inputs are interpolated directly into the shell command.

**initialize step** (~line 207): `args="${{ steps.arg.outputs.arg-backend-config }}${{ steps.arg.outputs.arg-backend }}${{ env.INPUTS_TOOL == 'tofu' && steps.arg.outputs.arg-var-file || '' }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} init${args}` — same pattern.

**validate step** (~line 218): `args="${{ env.INPUTS_TOOL == 'tofu' && steps.arg.outputs.arg-var-file || '' }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} validate${args}` — same pattern.

**plan step** (~line 229): `args="${{ steps.arg.outputs.arg-destroy }}${{ steps.arg.outputs.arg-var-file }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} plan${args}` — same pattern.

**arg step** (~line 77): `echo "TF_CLI_ARGS=$([[ -n \"${{ env.TF_CLI_ARGS }}\" ]] && echo \"${{ env.TF_CLI_ARGS }} -no-color\" || echo \"-no-color\")" >> "$GITHUB_ENV"` — `${{ env.TF_CLI_ARGS }}` is interpolated directly in the shell command.

**plan-parity step**: `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} plan${{ steps.arg.outputs.arg-destroy }}...` — same pattern.

**apply step**: `plan="${{ steps.arg.outputs.arg-auto-approve }}"` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} apply${args}` — same pattern.

**post step**: `command_append+=$(echo "${{ steps.arg.outputs.arg-workspace }}...${{ steps.arg.outputs.arg-var }}..." | ...)`, `if [[ "${{ steps.format.outcome }}" == "failure" ]]`, and `diff="<details${{ env.INPUTS_EXPAND_DIFF == 'true' && ' open' || '' }}>..."` — multiple `${{ }}` expressions interpolated directly in shell.

All `steps.arg.outputs.*` values are derived from user-controlled `inputs.*` values. An attacker who controls these inputs can inject shell metacharacters.

Locations:

- `action.yml:77`
- `action.yml:196`
- `action.yml:207`
- `action.yml:218`
- `action.yml:229`
- `action.yml:323`
- `action.yml:355`
- `action.yml:393`
- `action.yml:430`

### github-env-injection (severity: high)

Multiple `run:` blocks in action.yml write values derived from untrusted/workflow-controlled inputs to `$GITHUB_ENV` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`).

1. **`echo "GH_TOKEN=$INPUTS_TOKEN" >> "$GITHUB_ENV"`** — `INPUTS_TOKEN` is set from `${{ inputs.token }}` (a caller-controlled input). A newline in the token value could inject additional environment variables.

2. **`echo "TF_CLI_ARGS=$([[ -n \"${{ env.TF_CLI_ARGS }}\" ]] && echo \"${{ env.TF_CLI_ARGS }} -no-color\" || echo \"-no-color\")" >> "$GITHUB_ENV"`** — `env.TF_CLI_ARGS` is a workflow-controlled environment variable written unsanitized to `$GITHUB_ENV`.

3. **`echo "TF_WORKSPACE=$TF_WORKSPACE" >> "$GITHUB_ENV"`** — `TF_WORKSPACE` is set from `${{ env.TF_WORKSPACE || inputs.arg-workspace }}` (workflow/caller-controlled) and written to `$GITHUB_ENV` without sanitization.

4. **`echo "GH_IDENTIFIER_NAME=${INPUTS_TOOL}-${pr_number}-${identifier}.tfplan" >> "$GITHUB_ENV"`** — `INPUTS_TOOL` is derived from `${{ inputs.tool }}` (caller-controlled). A newline in the tool name could inject additional environment variables.

None of these writes are preceded by `printf '%s' "$VAR" | tr -d '\n\r'` sanitization.

Locations:

- `action.yml:76`
- `action.yml:77`
- `action.yml:80`
- `action.yml:183`

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

1. **script-injection** (lines 77, 196, 207, 218, 229, 323, 355, 393, 430): Moved all `${{ steps.arg.outputs.* }}`, `${{ steps.format.outcome }}`, `${{ env.TF_CLI_ARGS }}`, `${{ env.INPUTS_EXPAND_DIFF == 'true' && ' open' || '' }}`, and `${{ env.INPUTS_EXPAND_SUMMARY == 'true' && ' open' || '' }}` expressions out of `run:` shell blocks into `env:` blocks. Shell code now references plain `$ENV_VAR` variables. Conditional expressions like `env.INPUTS_TOOL == 'tofu' && steps.arg.outputs.arg-var-file || ''` were replaced with shell `if` statements.

2. **github-env-injection** (lines 76, 77, 80, 183): All writes to `$GITHUB_ENV` using user-controlled values are now sanitized with `printf '%s' "$VAR" | tr -d '\n\r'` before writing: GH_REPO, GH_TOKEN, TF_CLI_ARGS, TF_WORKSPACE, and GH_IDENTIFIER_NAME.

3. **static-unsanitized-env-write** (lines 71, 72, 76, 152): Same sanitization applied to GH_REPO (github.repository), INPUTS_TOKEN (inputs.token), TF_WORKSPACE (env.TF_WORKSPACE || inputs.arg-workspace), and INPUTS_TOOL (inputs.tool) before writing to GITHUB_ENV.

The `TF_CLI_ARGS` fix also added `INPUTS_TF_CLI_ARGS: ${{ env.TF_CLI_ARGS }}` to the arg step's env block to avoid the script injection of `${{ env.TF_CLI_ARGS }}` directly in the shell command.

### Iteration 2

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed two high-severity findings in hardened/action/action.yml:

1. github-env-injection: Added a `_safe()` helper function (`printf '%s' "$1" | tr -d '\n\r'`) in the `arg` step and wrapped all 37 `$GITHUB_OUTPUT` writes with it. This sanitizes all untrusted `inputs.*` values (arg-backend-config, arg-var, arg-var-file, arg-target, arg-replace, arg-chdir, arg-backend, arg-backup, arg-from-module, arg-generate-config-out, arg-lock-timeout, arg-lock, arg-lockfile, arg-parallelism, arg-plugin-dir, arg-refresh, arg-state-out, arg-state, arg-test-directory, arg-write, arg-workspace, and boolean flags) before writing to $GITHUB_OUTPUT.

2. script-injection: Quoted `$INPUTS_TOOL` as `"$INPUTS_TOOL"` in all 7 command execution locations (format, initialize, validate, plan, show, apply, and parity steps). The `${ARG_CHDIR}` variable remains intentionally unquoted as it contains a space-prefixed flag (` -chdir=value`) that requires word-splitting to be passed as a separate argument to the tool.

### Iteration 3

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed three security findings in hardened/action/action.yml:

1. script-injection (line 20): Quoted `$INPUTS_TOOL` in `which` command: `which "$INPUTS_TOOL"`.

2. script-injection (multiple lines - format, initialize, validate, plan, show, plan-parity, apply steps): Replaced unquoted `"$INPUTS_TOOL"${ARG_CHDIR} <subcommand>${args}` with bash array approach. For each step, `ARG_CHDIR` is tokenized into `chdir_arr` and `args` into `args_arr` using `read -ra` with empty-value guards, then expanded as `"$INPUTS_TOOL" "${chdir_arr[@]}" <subcommand> "${args_arr[@]}"`. This prevents word-splitting and glob expansion while keeping each flag as a separate argument.

3. github-env-injection (lines 196, 204): Added sanitization of `pr_number` before writing to GITHUB_OUTPUT and GITHUB_ENV. Added `safe_pr_number=$(printf '%s' "${pr_number:-0}" | tr -d '\n\r')` and replaced all uses of `${pr_number}` in output/env writes with `${safe_pr_number}`.

### Iteration 4

**Fixes applied:** github-env-injection

**Notes:**

Fixed the unsanitized write of GITHUB_SERVER_URL to $GITHUB_ENV in the `arg` step's run block (action.yml, line 74). Replaced `echo "GH_HOST=${GITHUB_SERVER_URL#*://}" >> "$GITHUB_ENV"` with a two-line sanitized form: `safe_gh_host=$(printf '%s' "${GITHUB_SERVER_URL#*://}" | tr -d '\n\r'); echo "GH_HOST=${safe_gh_host}" >> "$GITHUB_ENV"`. This matches the sanitization pattern already used for GH_REPO, GH_TOKEN, TF_CLI_ARGS, and TF_WORKSPACE in the same block.


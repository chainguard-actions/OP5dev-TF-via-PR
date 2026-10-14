<!-- markdownlint-disable -->

# Hardening Report: OP5dev--TF-via-PR/v13.7.7

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **OP5dev--TF-via-PR/v13.7.7** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The setup step's run: block writes multiple untrusted input/github-context values to $GITHUB_ENV and $GITHUB_OUTPUT without the required sanitization step (printf '%s' ... | tr -d '\n\r'). Specifically:

1. `echo "GH_REPO=$GH_REPO" >> "$GITHUB_ENV"` — GH_REPO is set from `${{ github.repository }}` (attacker-controllable via fork/PR).
2. `echo "GH_TOKEN=$GH_TOKEN" >> "$GITHUB_ENV"` — GH_TOKEN is set from `${{ inputs.token }}`.
3. `echo "TF_WORKSPACE=$INPUTS_ARG_WORKSPACE" >> "$GITHUB_ENV"` — INPUTS_ARG_WORKSPACE is set from `${{ env.TF_WORKSPACE || inputs.arg-workspace }}`.
4. `echo "GH_IDENTIFIER_NAME=$name" >> "$GITHUB_ENV"` — $name is derived from inputs (workspace, backend-config, var-file, var, replace, target, destroy).
5. `echo "chdir=$(args chdir)" >> "$GITHUB_OUTPUT"` — chdir comes from inputs.arg-chdir.
6. `echo "path=${INPUTS_ARG_CHDIR:+$INPUTS_ARG_CHDIR/}tfplan" >> "$GITHUB_OUTPUT"` — INPUTS_ARG_CHDIR comes from inputs.
7. `echo "pr=$pr_number" >> "$GITHUB_OUTPUT"` — pr_number is derived from github context (github.event.number, github.sha, etc.).
8. `echo "name=$name" >> "$GITHUB_OUTPUT"` — $name is derived from inputs.

An attacker who controls any of these inputs (e.g., via a crafted workspace name or var containing newlines) can inject arbitrary key=value pairs into $GITHUB_ENV or $GITHUB_OUTPUT, potentially overwriting environment variables or outputs used by subsequent steps. The fix is to sanitize each value with `safe=$(printf '%s' "$VAR" | tr -d '\n\r')` before writing.

Locations:

- `action.yml:75`
- `action.yml:76`
- `action.yml:79`
- `action.yml:100`
- `action.yml:103`
- `action.yml:130`
- `action.yml:155`
- `action.yml:156`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed all 8 github-env-injection locations in action.yml by sanitizing user-controlled values before writing to $GITHUB_ENV and $GITHUB_OUTPUT:

1. Added `safe_GH_REPO`, `safe_GH_TOKEN`, `safe_TF_WORKSPACE` variables using `printf '%s' "$VAR" | tr -d '\n\r'` before the GITHUB_ENV block write.
2. Added `safe_chdir` sanitization before writing `chdir` to $GITHUB_OUTPUT.
3. Added `safe_path` sanitization before writing `path` to $GITHUB_OUTPUT.
4. Added `safe_pr` sanitization before writing `pr` to $GITHUB_OUTPUT.
5. Added `safe_name` sanitization before writing `name` to $GITHUB_OUTPUT and `GH_IDENTIFIER_NAME` to $GITHUB_ENV.

The `output()` function uses heredoc format which is already safe from newline injection. Fixed values that are literal constants (GH_API, TF_IN_AUTOMATION, TF_INPUT) were left unchanged as they are not user-controlled.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed all three github-env-injection findings in hardened/action/action.yml:
1. (line ~82) Added `safe_GH_HOST="$(printf '%s' "$GH_HOST" | tr -d '\n\r')"` and replaced `echo "GH_HOST=$GH_HOST"` with `echo "GH_HOST=$safe_GH_HOST"` in the $GITHUB_ENV block.
2. (line ~85) Added `raw_TF_CLI_ARGS="${TF_CLI_ARGS:+$TF_CLI_ARGS }-no-color"` and `safe_TF_CLI_ARGS="$(printf '%s' "$raw_TF_CLI_ARGS" | tr -d '\n\r')"`, then replaced the unsanitized echo with `echo "TF_CLI_ARGS=$safe_TF_CLI_ARGS"`.
3. (line ~340) Added `safe_run_url="$(printf '%s' "$run_url" | tr -d '\n\r')"` and replaced `echo "run_url=$run_url"` with `echo "run_url=$safe_run_url"` when writing to $GITHUB_OUTPUT.


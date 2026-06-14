<!-- markdownlint-disable -->

# Hardening Report: OP5dev--TF-via-PR/v13.7.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **OP5dev--TF-via-PR/v13.7.1** was hardened automatically. 5 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple `${{ }}` expressions are interpolated directly inside `run:` shell command strings across many steps in action.yml, violating rule (a). This allows an attacker to inject arbitrary shell commands.

- **`arg` step**: `${{ env.TF_CLI_ARGS }}` is interpolated directly in the shell command: `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"`

- **`identifier` step**: `${{ github.repository }}`, `${{ github.event.pull_request.head.sha || github.sha }}`, `${{ github.ref_name }}`, `${{ github.event.number || github.event.issue.number }}`, `${{ github.head_ref }}`, `${{ github.ref }}`, and `${{ steps.arg.outputs.* }}` are all interpolated directly into shell commands. Notably: `pr_number=${{ github.event.number || github.event.issue.number }}` and `pr_number=$(echo "${{ github.ref_name }}" | sed ...)` allow attacker-controlled branch/event data to be executed as shell.

- **`format`, `initialize`, `validate`, `plan`, `apply` steps**: `${{ steps.arg.outputs.arg-chdir }}` and other step outputs are interpolated directly into shell commands such as `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} fmt${args}`, allowing injection via the chdir argument.

- **`download` step**: `${{ github.repository }}` and `${{ steps.identifier.outputs.name }}` are interpolated directly into shell commands.

- **`post` step**: `${{ github.repository }}`, `${{ github.run_id }}`, `${{ github.run_attempt }}`, `${{ github.triggering_actor }}`, `${{ github.event.pull_request.updated_at || ... }}`, `${{ steps.format.outcome }}`, and `${{ steps.identifier.outputs.* }}` are all interpolated directly into shell commands, including into a heredoc body that is written to `$GITHUB_OUTPUT` and `$GITHUB_STEP_SUMMARY`.

Locations:

- `action.yml:66`
- `action.yml:148`
- `action.yml:152`
- `action.yml:155`
- `action.yml:157`
- `action.yml:163`
- `action.yml:175`
- `action.yml:185`
- `action.yml:197`
- `action.yml:210`
- `action.yml:222`
- `action.yml:240`
- `action.yml:260`
- `action.yml:290`
- `action.yml:330`
- `action.yml:370`
- `action.yml:410`

### github-env-injection (severity: high)

Multiple unsanitized values derived from workflow-controllable inputs are written to `$GITHUB_ENV` without the required `printf '%s' ... | tr -d '\n\r'` sanitization step:

1. **`GH_TOKEN=$INPUTS_TOKEN`** — `INPUTS_TOKEN` is set from `${{ inputs.token }}` (a caller-supplied input). Written directly: `echo "GH_TOKEN=$INPUTS_TOKEN" >> "$GITHUB_ENV"`. A newline in the token value could inject additional environment variables.

2. **`TF_CLI_ARGS=${{ env.TF_CLI_ARGS }}`** — `${{ env.TF_CLI_ARGS }}` is a workflow-controlled env var interpolated directly into the shell command that writes to `$GITHUB_ENV`: `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"`. This is both a script-injection and an env-injection vulnerability.

3. **`TF_WORKSPACE=$TF_WORKSPACE`** — `TF_WORKSPACE` is set from `${{ env.TF_WORKSPACE || inputs.arg-workspace }}` (caller-supplied). Written directly: `echo "TF_WORKSPACE=$TF_WORKSPACE" >> "$GITHUB_ENV"` without sanitization.

Locations:

- `action.yml:65`
- `action.yml:66`
- `action.yml:68`

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

Fixed all security findings in action.yml:

1. **script-injection**: Moved all ${{ }} expressions out of run: shell blocks into env: maps for all affected steps (arg, identifier, format, initialize, validate, plan, download, TF show, plan parity, apply, post). Shell scripts now reference plain environment variables.

2. **github-env-injection**: Sanitized all three vulnerable GITHUB_ENV writes:
   - GH_TOKEN: `safe_token=$(printf '%s' "$INPUTS_TOKEN" | tr -d '\n\r')` before writing
   - TF_CLI_ARGS: moved ${{ env.TF_CLI_ARGS }} to TF_CLI_ARGS_INPUT env var, sanitized with printf/tr before writing
   - TF_WORKSPACE: `safe_tf_workspace=$(printf '%s' "$TF_WORKSPACE" | tr -d '\n\r')` before writing

3. **static-unsanitized-env-write**: Both instances fixed as part of github-env-injection fixes.

4. **static-inline-injection**: Fixed in identifier step by moving ${{ github.event.pull_request.head.sha || github.sha }} to GH_SHA env var.

The post step's heredoc body now uses shell variables (${GH_TRIGGERING_ACTOR}, ${GH_EVENT_TIMESTAMP}, ${STEPS_IDENTIFIER_NAME}, etc.) instead of ${{ }} expressions. The expand-diff and expand-summary logic was converted from inline ${{ env.INPUTS_EXPAND_DIFF == 'true' && ' open' || '' }} expressions to shell if-statements.

### Iteration 2

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed all three security findings in actions/hardened/OP5dev--TF-via-PR/v13.7.1/action.yml:

1. **github-env-injection (GH_HOST, line 86)**: Replaced `echo "GH_HOST=$(echo $GITHUB_SERVER_URL | sed 's/.*:\/\///')" >> "$GITHUB_ENV"` with a two-step sanitization: `safe_gh_host=$(printf '%s' "$GITHUB_SERVER_URL" | sed 's/.*:\/\///' | tr -d '\n\r')` then `echo "GH_HOST=$safe_gh_host" >> "$GITHUB_ENV"`.

2. **github-env-injection (GITHUB_OUTPUT lines, lines 88-130)**: Added a `safe_output()` helper function that sanitizes values with `printf '%s' "$val" | tr -d '\n\r'` before writing to `$GITHUB_OUTPUT`. Replaced all 34 bare `echo arg-*=...` lines with calls to `safe_output "arg-*" "$(...)"` to prevent newline injection.

3. **script-injection (unquoted $INPUTS_TOOL, lines 20-22 and other steps)**: Quoted `$INPUTS_TOOL` as `"$INPUTS_TOOL"` in all command executions across all steps (format, initialize, validate, plan, show, parity, apply). Also fixed `which $INPUTS_TOOL` to `which "$INPUTS_TOOL"` in the first step.

### Iteration 3

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed two findings in action.yml:

1. github-env-injection: In the `identifier` step, both writes to $GITHUB_OUTPUT now use `printf '%s' | tr -d '\n\r'` sanitization. `pr_number` is sanitized into `safe_pr` and `INPUTS_TOOL` into `safe_tool`, then the combined name is sanitized into `safe_name` before writing.

2. script-injection: All unquoted `${STEPS_ARG_CHDIR}` and `${args}` expansions in the format, initialize, validate, plan, apply, TF show, and plan parity steps have been replaced with `read -ra cmd_args <<< "${STEPS_ARG_CHDIR} subcommand${args}"` followed by `"$INPUTS_TOOL" "${cmd_args[@]}"`. This uses bash array expansion which properly handles word-splitting while keeping the values quoted. All `# shellcheck disable=SC2086` comments have been removed as they are no longer needed.


<!-- markdownlint-disable -->

# Hardening Report: OP5dev--TF-via-PR/v13.7.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **OP5dev--TF-via-PR/v13.7.0** was hardened automatically. 15 finding(s) were identified and resolved across 5 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a): Multiple `${{ }}` expressions are interpolated directly inside `run:` shell command strings in action.yml, allowing script injection. In the `arg` step, `${{ env.TF_CLI_ARGS }}` is used directly in a shell command: `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"`. Any workflow-controlled value in TF_CLI_ARGS is injected into the shell before quoting.

Locations:

- `action.yml:70`

### script-injection (severity: high)

Rule (a): In the `identifier` step, multiple github context expressions are interpolated directly into shell commands: `${{ github.repository }}`, `${{ github.event.pull_request.head.sha || github.sha }}`, `${{ github.ref_name }}`, `${{ github.event.number || github.event.issue.number }}`, `${{ github.ref_name || github.head_ref || github.ref || '0' }}`, and `${{ steps.arg.outputs.* }}`. For example: `pr_number=${{ github.event.number || github.event.issue.number }}` and `associated_prs=$(gh api /repos/${{ github.repository }}/commits/${{ github.event.pull_request.head.sha || github.sha }}/pulls ...)`. An attacker controlling a branch name or PR event field can inject arbitrary shell commands.

Locations:

- `action.yml:126`
- `action.yml:130`
- `action.yml:133`

### script-injection (severity: high)

Rule (a): In the `format` step, `${{ steps.arg.outputs.arg-check }}`, `${{ steps.arg.outputs.arg-diff }}`, `${{ steps.arg.outputs.arg-list }}`, `${{ steps.arg.outputs.arg-recursive }}`, `${{ steps.arg.outputs.arg-write }}`, and `${{ steps.arg.outputs.arg-chdir }}` are interpolated directly into shell commands: `args="${{ steps.arg.outputs.arg-check }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} fmt${args}`. These step outputs are derived from user-controlled inputs and are injected into the shell without quoting.

Locations:

- `action.yml:160`

### script-injection (severity: high)

Rule (a): In the `initialize` step, `${{ steps.arg.outputs.* }}` expressions (arg-backend-config, arg-backend, arg-var-file, arg-var, arg-force-copy, arg-from-module, arg-get, arg-lock-timeout, arg-lock, arg-lockfile, arg-migrate-state, arg-plugin-dir, arg-reconfigure, arg-test-directory, arg-upgrade, arg-chdir) are interpolated directly into shell commands: `args="${{ steps.arg.outputs.arg-backend-config }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} init${args}`. These are derived from user-controlled inputs.

Locations:

- `action.yml:172`

### script-injection (severity: high)

Rule (a): In the `validate` step, `${{ steps.arg.outputs.* }}` expressions (arg-var-file, arg-var, arg-no-tests, arg-test-directory, arg-chdir) are interpolated directly into shell commands: `args="${{ env.INPUTS_TOOL == 'tofu' && steps.arg.outputs.arg-var-file || '' }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} validate${args}`. These are derived from user-controlled inputs.

Locations:

- `action.yml:184`

### script-injection (severity: high)

Rule (a): In the `plan` step, `${{ steps.arg.outputs.* }}` expressions (arg-destroy, arg-var-file, arg-var, arg-compact-warnings, arg-concise, arg-detailed-exitcode, arg-generate-config-out, arg-lock-timeout, arg-lock, arg-parallelism, arg-refresh-only, arg-refresh, arg-replace, arg-target, arg-chdir) are interpolated directly into shell commands: `args="${{ steps.arg.outputs.arg-destroy }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} plan${args}`. These are derived from user-controlled inputs.

Locations:

- `action.yml:198`

### script-injection (severity: high)

Rule (a): In the `download` step, `${{ github.repository }}` and `${{ steps.identifier.outputs.name }}` are interpolated directly into shell commands: `artifact_id=$(gh api /repos/${{ github.repository }}/actions/artifacts --header "$GH_API" --method GET --field "name=${{ steps.identifier.outputs.name }}" ...)` and `unzip "${{ steps.identifier.outputs.name }}.zip" -d "$INPUTS_ARG_CHDIR"`. An attacker controlling the repository name or identifier output can inject shell commands.

Locations:

- `action.yml:218`

### script-injection (severity: high)

Rule (a): In the `apply` step, `${{ steps.arg.outputs.* }}` expressions (arg-auto-approve, arg-var-file, arg-var, arg-destroy, arg-backup, arg-compact-warnings, arg-concise, arg-lock-timeout, arg-lock, arg-parallelism, arg-refresh-only, arg-refresh, arg-replace, arg-state-out, arg-state, arg-target, arg-chdir) are interpolated directly into shell commands. For example: `plan="${{ steps.arg.outputs.arg-auto-approve }}"` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} apply${args}`. These are derived from user-controlled inputs.

Locations:

- `action.yml:258`

### script-injection (severity: high)

Rule (a): In the `post` step, multiple github context and steps output expressions are interpolated directly into shell commands: `${{ steps.format.outcome }}`, `${{ github.repository }}`, `${{ github.run_id }}`, `${{ github.run_attempt }}`, `${{ github.triggering_actor }}`, `${{ github.event.pull_request.updated_at || github.event.comment.created_at || github.event.head_commit.timestamp || github.event.merge_group.head_commit.timestamp }}`, `${{ steps.identifier.outputs.name }}`, `${{ steps.identifier.outputs.pr }}`, and many `${{ steps.arg.outputs.* }}` values. For example: `workflow_run=$(gh api /repos/${{ github.repository }}/actions/runs/${{ github.run_id }}/attempts/${{ github.run_attempt }}/jobs ...)` and `###### By ${tag_actor}${{ github.triggering_actor }} at ${{ github.event.pull_request.updated_at || ... }}`. Attacker-controlled event fields are injected into shell and PR comment body.

Locations:

- `action.yml:283`
- `action.yml:310`
- `action.yml:356`

### github-env-injection (severity: high)

In the `arg` step's `run:` block, `INPUTS_TOKEN` (sourced from `inputs.token`, an untrusted caller-controlled input) is written directly to `$GITHUB_ENV` without sanitization: `echo "GH_TOKEN=$INPUTS_TOKEN" >> "$GITHUB_ENV"`. A newline in the token value could inject arbitrary environment variables into subsequent steps.

Locations:

- `action.yml:69`

### github-env-injection (severity: high)

In the `arg` step's `run:` block, `${{ env.TF_CLI_ARGS }}` is both (a) interpolated directly into the shell command string (script injection) and (b) written to `$GITHUB_ENV` without sanitization: `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"`. A calling workflow can set TF_CLI_ARGS to a value containing newlines, injecting arbitrary environment variables.

Locations:

- `action.yml:70`

### github-env-injection (severity: high)

In the `arg` step's `run:` block, `TF_WORKSPACE` (sourced from `env.TF_WORKSPACE || inputs.arg-workspace`, a caller-controlled input) is written directly to `$GITHUB_ENV` without sanitization: `echo "TF_WORKSPACE=$TF_WORKSPACE" >> "$GITHUB_ENV"`. A newline in the workspace value could inject arbitrary environment variables into subsequent steps.

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

All ${{ }} expressions have been moved from run: shell blocks into env: blocks across all steps (arg, identifier, format, initialize, validate, plan, download, apply, post, show, plan-parity). Values written to $GITHUB_ENV (GH_TOKEN, TF_CLI_ARGS, TF_WORKSPACE) are now sanitized using printf '%s' "$VAR" | tr -d '\n\r' before writing. The TF_CLI_ARGS env var was renamed to TF_CLI_ARGS_INPUT in the env: block to avoid conflict with the env var being set. The identifier step's else branch was refactored to use env vars instead of inline ${{ }} expressions. The post step's expand-diff and expand-summary logic was moved from inline ${{ }} expressions to bash conditionals using env vars.

### Iteration 2

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed all four findings in hardened/action/action.yml:

1. github-env-injection (GITHUB_SERVER_URL → $GITHUB_ENV, line 81): Replaced `echo "GH_HOST=$(echo $GITHUB_SERVER_URL | sed ...)"` with a two-step approach: `safe_gh_host=$(printf '%s' "$GITHUB_SERVER_URL" | sed '...' | tr -d '\n\r')` then `echo "GH_HOST=${safe_gh_host}"`.

2. github-env-injection (INPUTS_ARG_* → $GITHUB_OUTPUT, line 85): Introduced a `_safe()` helper function (`printf '%s' "$1" | tr -d '\n\r'`) and replaced all `echo arg-*=...` writes with `printf 'arg-*=%s\n' "$(_safe "...")"` to strip newlines from all attacker-controllable values before writing to $GITHUB_OUTPUT.

3. github-env-injection (INPUTS_TOOL → $GITHUB_OUTPUT, line 155): Added `safe_tool=$(printf '%s' "$INPUTS_TOOL" | tr -d '\n\r')` and used `${safe_tool}` in the name output instead of `${INPUTS_TOOL}`.

4. script-injection (unquoted $INPUTS_TOOL in run: blocks, lines 20/175/200/220/245/360): Double-quoted `$INPUTS_TOOL` in all command invocations across the which check, format, initialize, validate, plan, apply, show, and plan-parity steps using the `"$INPUTS_TOOL"${ARG_CHDIR}` pattern.

### Iteration 3

**Fixes applied:** script-injection

**Notes:**

Fixed all 6 script-injection findings across 3 workflow files:

1. **tag_release.yaml** ('Tag release version' step): Added `GH_REPOSITORY: ${{ github.repository }}` to env block and replaced both `${{ github.repository }}` occurrences in the run script with `${GH_REPOSITORY}`.

2. **test_aws.yaml** ('Changed files' step): Added `GH_EVENT_NAME`, `GH_REF_NAME`, `GH_REPOSITORY`, and `GH_EVENT_ACTION` env vars, replacing all `${{ github.* }}` expressions in the run block with their corresponding shell variables.

3. **test_aws.yaml** ('Authenticate GitHub' step): Added `GH_EVENT_NAME`, `GH_REPOSITORY`, `MATRIX_TARGET`, and `LABEL_MISSING` env vars, replacing all `${{ github.* }}` and `${{ matrix.target }}` expressions in the run block with shell variables.

4. **test_aws.yaml** ('Clear directory' step): Replaced `${{ github.workspace }}` with the built-in `$GITHUB_WORKSPACE` environment variable.

5. **test_aws.yaml** ('Exit status' step): Added `HAS_FAILURE: ${{ contains(needs.*.result, 'failure') }}` env var and rewrote the run block to use a shell conditional instead of directly interpolating the expression.

6. **test_ci.yaml** ('Echo TF' step): Added 14 env vars covering all `${{ steps.tf.outputs.* }}`, `${{ matrix.tool }}`, and `${{ matrix.test }}` expressions, then replaced all occurrences in the run block with their corresponding shell variables. The tool invocation now uses `"${MATRIX_TOOL}"` as a quoted variable.

### Iteration 4

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed two high-severity findings in hardened/action/action.yml:

1. github-env-injection (line 175): Added sanitization of `pr_number` before writing to $GITHUB_OUTPUT. Now uses `safe_pr_number=$(printf '%s' "${pr_number:-0}" | tr -d '\n\r')` and references `safe_pr_number` in both GITHUB_OUTPUT writes.

2. script-injection (lines 195, 220, 240, 270, 310, 350, 380): Replaced unquoted `"$INPUTS_TOOL"${ARG_CHDIR} subcommand${args}` patterns with bash array expansion: `read -ra _chdir <<< "$ARG_CHDIR"` and `read -ra _args <<< "$args"`, then `"$INPUTS_TOOL" "${_chdir[@]}" subcommand "${_args[@]}". This prevents shell metacharacters in user-controlled inputs from being interpreted as shell commands. The echo statements writing to tf.command.txt (for logging) retain the original string format as they are safe (writing to a file, not executing). Fixed in all 7 affected steps: format, initialize, validate, plan, show, plan parity, and apply.

### Iteration 5

**Fixes applied:** script-injection

**Notes:**

Fixed unquoted shell variable expansions in gh api URL paths in two workflow files:
1. hardened/action/.github/workflows/tag_release.yaml: Wrapped both gh api URL arguments in double quotes so ${GH_REPOSITORY} and ${version} are properly quoted (e.g., gh api "/repos/${GH_REPOSITORY}/git/refs/tags/${version}").
2. hardened/action/.github/workflows/test_aws.yaml: Wrapped all three gh api URL arguments in double quotes so ${GH_REPOSITORY} and ${PR_NUMBER} are properly quoted in the 'Changed files' step (DELETE label and GET pulls/files calls) and the 'Authenticate GitHub' step (POST labels call).


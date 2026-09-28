<!-- markdownlint-disable -->

# Hardening Report: OP5dev--TF-via-PR/v13.7.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **OP5dev--TF-via-PR/v13.7.0** was hardened automatically. 5 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple `run:` blocks in action.yml directly interpolate `${{ ... }}` expressions inside shell script bodies (rule a). This allows template substitution to inject arbitrary shell metacharacters before the shell ever parses the command.

Affected steps and representative offending lines:

**`arg` step** — `${{ env.TF_CLI_ARGS }}` interpolated directly in a shell command that writes to $GITHUB_ENV:
  `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"`

**`identifier` step** — attacker-controllable github context values interpolated directly:
  `associated_prs=$(gh api /repos/${{ github.repository }}/commits/${{ github.event.pull_request.head.sha || github.sha }}/pulls ...)`
  `pr_number=$(echo "${{ github.ref_name }}" | sed ...)`
  `pr_number=${{ github.event.number || github.event.issue.number }} || ...`
  `identifier="${{ steps.arg.outputs.arg-chdir }}${{ steps.arg.outputs.arg-workspace }}..."`

**`format` step** — `${{ steps.arg.outputs.* }}` and `${{ steps.arg.outputs.arg-chdir }}` interpolated in shell commands:
  `args="${{ steps.arg.outputs.arg-check }}${{ steps.arg.outputs.arg-diff }}..."`
  `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} fmt${args} ...`

**`initialize` step** — same pattern with `${{ steps.arg.outputs.* }}` and `${{ env.INPUTS_TOOL == 'tofu' && ... }}`

**`validate` step** — same pattern

**`plan` step** — `${{ steps.arg.outputs.* }}` interpolated in shell commands building CLI args

**`download` step** — `${{ github.repository }}` and `${{ steps.identifier.outputs.name }}` interpolated in shell commands:
  `artifact_id=$(gh api /repos/${{ github.repository }}/actions/artifacts ...)`
  `gh api ... > "${{ steps.identifier.outputs.name }}.zip"`
  `unzip "${{ steps.identifier.outputs.name }}.zip" -d "$INPUTS_ARG_CHDIR"`

**`show` step** — `${{ steps.arg.outputs.arg-chdir }}` interpolated in shell command

**`parity` step** — `${{ steps.arg.outputs.* }}` interpolated in shell commands

**`apply` step** — `${{ steps.arg.outputs.* }}` interpolated in shell commands

**`post` step** — `${{ github.repository }}`, `${{ github.run_id }}`, `${{ github.run_attempt }}`, `${{ github.triggering_actor }}`, `${{ github.event.pull_request.updated_at || ... }}`, `${{ steps.format.outcome }}`, `${{ steps.identifier.outputs.* }}`, `${{ env.INPUTS_EXPAND_DIFF == 'true' && ... }}`, `${{ env.INPUTS_EXPAND_SUMMARY == 'true' && ... }}` all interpolated directly in shell script body.

All these values should be passed via `env:` variables and then referenced as `"$VAR"` (double-quoted) in the shell script.

Locations:

- `action.yml:77`
- `action.yml:184`
- `action.yml:188`
- `action.yml:190`
- `action.yml:196`
- `action.yml:207`
- `action.yml:209`
- `action.yml:216`
- `action.yml:218`
- `action.yml:225`
- `action.yml:227`
- `action.yml:234`
- `action.yml:236`
- `action.yml:249`
- `action.yml:251`
- `action.yml:253`
- `action.yml:267`
- `action.yml:282`
- `action.yml:304`
- `action.yml:306`
- `action.yml:330`
- `action.yml:345`
- `action.yml:360`
- `action.yml:374`
- `action.yml:393`

### github-env-injection (severity: high)

The `arg` step's `run:` block writes several untrusted/workflow-controlled values to `$GITHUB_ENV` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`):

1. `echo "GH_TOKEN=$INPUTS_TOKEN" >> "$GITHUB_ENV"` — `INPUTS_TOKEN` is set from `inputs.token` (caller-controlled). A newline in the token value could inject arbitrary environment variables.

2. `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"` — `${{ env.TF_CLI_ARGS }}` is interpolated directly in the shell command and the result is written to GITHUB_ENV without sanitization. The `env.TF_CLI_ARGS` value is set by the calling workflow and is untrusted.

3. `echo "TF_WORKSPACE=$TF_WORKSPACE" >> "$GITHUB_ENV"` — `TF_WORKSPACE` is set from `env.TF_WORKSPACE || inputs.arg-workspace` (caller-controlled). A newline in the workspace name could inject arbitrary environment variables.

All three writes should sanitize the value first: `safe=$(printf '%s' "$VAR" | tr -d '\n\r')` before writing to `$GITHUB_ENV`.

Locations:

- `action.yml:76`
- `action.yml:77`
- `action.yml:80`

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

Fixed all security findings in hardened/action/action.yml:

1. script-injection: Moved all ${{ }} expressions from run: shell script bodies to env: blocks in all affected steps (arg, identifier, format, initialize, validate, plan, download, show, parity, apply, post). Each expression is now referenced as a plain $VAR_NAME environment variable in the shell scripts.

2. github-env-injection + static-unsanitized-env-write: The arg step now sanitizes INPUTS_TOKEN, TF_CLI_ARGS_ORIG, and TF_WORKSPACE with `printf '%s' "$VAR" | tr -d '\n\r'` before writing to $GITHUB_ENV. The inline ${{ env.TF_CLI_ARGS }} expression was moved to the env block as TF_CLI_ARGS_ORIG.

3. static-inline-injection: ${{ github.event.pull_request.head.sha || github.sha }} moved to env block as GH_SHA in the identifier step.

4. The ${{ env.INPUTS_EXPAND_DIFF == 'true' && ' open' || '' }} and similar conditional expressions in the post step's heredoc were replaced with proper bash if-statements using the already-available INPUTS_EXPAND_DIFF and INPUTS_EXPAND_SUMMARY env vars.

### Iteration 2

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed all github-env-injection findings: (1) GH_HOST now uses printf+sed+tr sanitization before writing to GITHUB_ENV; (2) All 36 CLI argument outputs in the 'arg' step now use a safe_output() helper that strips newlines/carriage-returns via tr -d '\n\r' before writing to GITHUB_OUTPUT; (3) The 'identifier' step now sanitizes pr_number and name with printf+tr before writing to GITHUB_OUTPUT. Fixed all script-injection findings: all 7 command invocations of $INPUTS_TOOL${ARG_CHDIR} have been changed to "$INPUTS_TOOL"${ARG_CHDIR} (quoting the tool name) in the format, initialize, validate, plan, show, parity, and apply steps.

### Iteration 3

**Fixes applied:** script-injection

**Notes:**

Fixed all 7 script-injection locations in action.yml:
1. Quoted `$INPUTS_TOOL` in the `which` command (line 20).
2-7. Replaced unquoted `"$INPUTS_TOOL"${ARG_CHDIR} <cmd>${args}` patterns in format, initialize, validate, plan, plan-parity, TF-show, and apply steps with bash array tokenization using xargs. Each step now builds `chdir_arr` and `args_arr` arrays via `while IFS= read -r -d '' t; do arr+=("$t"); done < <(printf '%s' "$VAR" | xargs printf '%s\0')` and invokes `"$INPUTS_TOOL" "${chdir_arr[@]}" <cmd> "${args_arr[@]}"`. The `echo ... | sed ... > tf.command.txt` logging lines were left unchanged as they only build display strings, not execute commands.


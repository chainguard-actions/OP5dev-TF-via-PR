<!-- markdownlint-disable -->

# Hardening Report: OP5dev--TF-via-PR/v13.7.4

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **OP5dev--TF-via-PR/v13.7.4** was hardened automatically. 6 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple `run:` blocks in action.yml directly interpolate `${{ ... }}` expressions inside shell command strings (sub-rule a). This applies to `steps.arg.outputs.*`, `env.TF_CLI_ARGS`, `env.INPUTS_TOOL`, `steps.format.outcome`, `env.INPUTS_EXPAND_DIFF`, and `env.INPUTS_EXPAND_SUMMARY` — all of which flow through YAML template substitution before the shell ever sees them, enabling shell metacharacter injection.

Affected steps and representative offending lines:
- **arg step**: `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" ...)" >> "$GITHUB_ENV"`
- **identifier step**: `identifier="${{ steps.arg.outputs.arg-chdir }}${{ steps.arg.outputs.arg-workspace }}..."`
- **format step**: `args="${{ steps.arg.outputs.arg-check }}${{ steps.arg.outputs.arg-diff }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} fmt${args}`
- **initialize step**: `args="${{ steps.arg.outputs.arg-backend-config }}...${{ env.INPUTS_TOOL == 'tofu' && steps.arg.outputs.arg-var-file || '' }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} init${args}`
- **validate step**: `args="${{ env.INPUTS_TOOL == 'tofu' && steps.arg.outputs.arg-var-file || '' }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} validate${args}`
- **plan step**: `args="${{ steps.arg.outputs.arg-destroy }}${{ steps.arg.outputs.arg-var-file }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} plan${args}`
- **show step**: `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} show tfplan`
- **parity step**: `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} plan${{ steps.arg.outputs.arg-destroy }}...`
- **apply step**: `plan="${{ steps.arg.outputs.arg-auto-approve }}"` and `args="${{ steps.arg.outputs.arg-destroy }}..."` and `$INPUTS_TOOL${{ steps.arg.outputs.arg-chdir }} apply${args}`
- **post step**: `if [[ "${{ steps.format.outcome }}" == "failure" ]]`, `<details${{ env.INPUTS_EXPAND_DIFF == 'true' && ' open' || '' }}>`, `<details${{ env.INPUTS_EXPAND_SUMMARY == 'true' && ' open' || '' }}>`, and a large `${{ steps.arg.outputs.* }}` block inside `command_append+=`

Locations:

- `action.yml:100`
- `action.yml:155`
- `action.yml:171`
- `action.yml:172`
- `action.yml:179`
- `action.yml:180`
- `action.yml:187`
- `action.yml:188`
- `action.yml:196`
- `action.yml:197`
- `action.yml:210`
- `action.yml:225`
- `action.yml:226`
- `action.yml:240`
- `action.yml:241`
- `action.yml:258`
- `action.yml:259`
- `action.yml:272`
- `action.yml:273`
- `action.yml:274`

### github-env-injection (severity: high)

The `arg` step's `run:` block writes several workflow-controllable values to `$GITHUB_ENV` without the required `printf '%s' ... | tr -d '\n\r'` sanitization:

1. `echo "GH_TOKEN=$INPUTS_TOKEN" >> "$GITHUB_ENV"` — `INPUTS_TOKEN` is set from `inputs.token` (caller-controlled). A newline in the token value could inject arbitrary environment variables.
2. `echo "TF_CLI_ARGS=$([[ -n "${{ env.TF_CLI_ARGS }}" ]] && echo "${{ env.TF_CLI_ARGS }} -no-color" || echo "-no-color")" >> "$GITHUB_ENV"` — `env.TF_CLI_ARGS` is workflow-controlled; a newline in its value injects additional `GITHUB_ENV` entries.
3. `echo "TF_WORKSPACE=$TF_WORKSPACE" >> "$GITHUB_ENV"` — `TF_WORKSPACE` comes from `env.TF_WORKSPACE || inputs.arg-workspace`, both caller-controlled.

The `identifier` step also writes `echo "GH_IDENTIFIER_NAME=${INPUTS_TOOL}-${pr_number}-${identifier}.tfplan" >> "$GITHUB_ENV"` where `INPUTS_TOOL` is caller-controlled (from `inputs.tool`), without sanitization.

Locations:

- `action.yml:100`
- `action.yml:101`
- `action.yml:103`
- `action.yml:155`

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

1. script-injection: Moved all ${{ ... }} expressions out of run: shell scripts and into env: blocks for every affected step (arg, identifier, format, initialize, validate, plan, show, parity, apply, post). Shell scripts now reference only $ENV_VAR_NAME variables. The post step's INPUTS_EXPAND_DIFF and INPUTS_EXPAND_SUMMARY conditionals were replaced with bash if-statements using the env vars. The steps.format.outcome check was moved to STEP_FORMAT_OUTCOME env var. The large command_append block with all steps.arg.outputs.* was replaced with a pre-built all_args variable from env vars.

2. github-env-injection: All writes to $GITHUB_ENV that used caller-controlled values are now sanitized with printf '%s' "$VAR" | tr -d '\n\r' before writing: GH_REPO (from github.repository), GH_TOKEN (from inputs.token), TF_CLI_ARGS (from env.TF_CLI_ARGS), TF_WORKSPACE (from env.TF_WORKSPACE/inputs.arg-workspace), and GH_IDENTIFIER_NAME (INPUTS_TOOL sanitized as safe_tool).

3. static-unsanitized-env-write: The same sanitization fixes address all four instances flagged (GH_REPO, INPUTS_TOKEN/GH_TOKEN, TF_WORKSPACE, and INPUTS_TOOL used in GH_IDENTIFIER_NAME).

### Iteration 2

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed github-env-injection by: (1) sanitizing GH_HOST before writing to $GITHUB_ENV using printf+tr -d '\n\r', and (2) rewriting all 37 arg-* GITHUB_OUTPUT writes in the arg step to capture the value into _out via printf '%s' ... | tr -d '\n\r' before echoing. Fixed script-injection by quoting $INPUTS_TOOL as "$INPUTS_TOOL" in all 6 command execution sites (format, initialize, validate, plan, plan-parity x3, apply, show) while leaving ${STEP_ARG_CHDIR} unquoted for proper word splitting of the -chdir flag.

### Iteration 3

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed github-env-injection by sanitizing pr_number with printf/tr before writing to $GITHUB_OUTPUT and $GITHUB_ENV. Fixed script-injection in 6 steps (format, initialize, validate, plan, show, plan-parity, apply) by replacing unquoted ${STEP_ARG_CHDIR} and ${args} expansions with xargs-based array tokenization using the 'while IFS= read -r -d '' t; do arr+=("$t"); done < <(printf '%s' "$VAR" | xargs printf '%s\0')' pattern, then expanding with "${arr[@]}" in the actual command invocations.


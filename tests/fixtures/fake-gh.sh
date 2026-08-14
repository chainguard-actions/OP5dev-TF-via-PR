#!/bin/sh
# Fake gh CLI: handles GitHub API calls made by the TF-via-PR action.
# Usage: gh api <endpoint> [options...]
# The endpoint always starts with '/' in the action's usage.

# Only handle the 'api' subcommand
if [ "$1" != "api" ]; then
  echo "fake-gh: unsupported subcommand '$1'" >&2
  exit 1
fi
shift

# Find the endpoint (first arg starting with '/') and method/jq values
endpoint=""
method="GET"
jq_expr=""
prev=""

for arg in "$@"; do
  # Capture values for flags that take arguments
  case "$prev" in
    --method|-X) method="$arg" ;;
    --jq|-q) jq_expr="$arg" ;;
  esac
  # Find endpoint: first argument starting with '/'
  case "$arg" in
    /*)
      if [ -z "$endpoint" ]; then
        endpoint="$arg"
      fi
      ;;
  esac
  prev="$arg"
done

# Generate response based on endpoint pattern
response=""

case "$endpoint" in
  */commits/*/pulls)
    # Return empty array - no PRs associated with this commit
    response='[]'
    ;;
  */pulls)
    # Return empty array - no PRs for this branch
    response='[]'
    ;;
  */actions/runs/*/attempts/*/jobs)
    # Return a fake jobs list with one job named "test" with an in_progress step
    response='{"jobs":[{"id":12345,"name":"test","status":"in_progress","steps":[{"name":"Post output","status":"in_progress","number":16}]}]}'
    ;;
  */check-runs/*)
    # Return a fake check run (for PATCH updates)
    response='{"id":99999,"html_url":"https://github.com/test/repo/runs/99999"}'
    ;;
  */issues/*/comments)
    case "$method" in
      POST)
        response='{"id":11111}'
        ;;
      *)
        # Return empty array - no existing bot comments
        response='[]'
        ;;
    esac
    ;;
  */issues/comments/*)
    case "$method" in
      PATCH)
        response='{"id":11111}'
        ;;
      DELETE)
        response=''
        ;;
      *)
        response='{"id":11111}'
        ;;
    esac
    ;;
  */actions/artifacts)
    # Return empty artifacts list
    response='{"artifacts":[]}'
    ;;
  */actions/artifacts/*/zip)
    response=''
    ;;
  *)
    # Unknown endpoint - return empty object
    response='{}'
    ;;
esac

# Apply jq filter if specified
if [ -n "$jq_expr" ] && [ -n "$response" ]; then
  echo "$response" | jq --raw-output "$jq_expr" 2>/dev/null || echo ""
else
  printf '%s\n' "$response"
fi

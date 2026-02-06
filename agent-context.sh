#!/bin/bash
# Agent-Context Global CLI (Legacy Wrapper)
# DEPRECATED: This wrapper will be removed in a future release.
# Use ~/.agent-context/bin/agent-context.sh directly or the 'agent-context' alias.
#
# This file forwards all commands to bin/agent-context.sh for backward compatibility.

set -e
set -o pipefail

# Script directory (agent-context source)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Show deprecation warning (only once per session)
if [[ -z "${_AC_DEPRECATION_WARNED:-}" ]]; then
	echo "[!] Warning: Direct invocation of ./agent-context.sh is deprecated." >&2
	echo "[i] Use 'agent-context' alias or ~/.agent-context/bin/agent-context.sh" >&2
	echo "" >&2
	export _AC_DEPRECATION_WARNED=1
fi

# Forward to new entrypoint
exec "${SCRIPT_DIR}/bin/agent-context.sh" "$@"

#!/bin/bash
# Agent-Context Tests Command
# Run test suites (non-interactive, CI-friendly)
#
# Usage:
#   agent-context tests [subcommand] [options]
#
# Subcommands:
#   list      List available tests and tags
#   smoke     Run minimal fast checks (deps, auth, project)
#   e2e       Run end-to-end tests (may require Docker)
#
# This script is sourced by bin/agent-context.sh

# ============================================================
# Tag Aliases (legacy -> canonical mapping)
# ============================================================
# Alias resolution happens BEFORE registry lookup
# Using function-based approach for bash 3.2 compatibility
resolve_tag_alias() {
    local tag="$1"
    case "${tag}" in
        preflight) echo "deps" ;;
        auditRepo) echo "audit-repo" ;;
        auditProject) echo "audit-project" ;;
        installNonInteractive) echo "install-non-interactive" ;;
        *) echo "${tag}" ;;
    esac
}

# ============================================================
# Test Registry (canonical tags only)
# ============================================================
# Format: "tag:description:function"
declare -a TEST_REGISTRY=(
    # Dependencies check
    "deps:Required binaries and permissions:test_deps"
    # Legacy (DEPRECATED - use 'doctor' subcommand instead)
    "auth:[DEPRECATED] Use 'doctor auth':test_auth"
    "global:[DEPRECATED] Use 'doctor global':test_global"
    "project:[DEPRECATED] Use 'doctor project':test_project"
    "connect:[DEPRECATED] Use 'doctor connect':test_connect"
    # Layer 0: Static/Contract
    "templates-contract:Template file/token contract:test_templates_contract"
    "skills-spec:Skill thin-spec validation:test_skills_spec"
    "workflows-chain:Workflow skill chain order:test_workflows_chain"
    # Layer 1: Offline Functional
    "cli-help-contract:All CLI subcommands help+exit0:test_cli_help_contract"
    "cli-version:CLI version output:test_cli_version"
    "cli-error-handling:CLI error cases:test_cli_error_handling"
    "tests-runner-contract:Test runner self-validation:test_tests_runner_contract"
    "install-non-interactive:Non-interactive install:test_install_non_interactive"
    "install-artifacts:Install output verification:test_install_artifacts"
    "pm-offline:PM offline functionality:test_pm_offline"
    "secrets-mask:Secret masking verification:test_secrets_mask"
    # Legacy
    "audit-repo:Audit repo templates:test_audit_repo"
    "audit-project:Audit project structure:test_audit_project"
    # Layer 2: Mock Integration (requires mock server)
    "jira-auth-mock:Jira auth against mock server:test_jira_auth_mock"
    "confluence-auth-mock:Confluence auth against mock:test_confluence_auth_mock"
    "pm-jira-mock:PM Jira commands against mock:test_pm_jira_mock"
    "pm-confluence-mock:PM Confluence commands against mock:test_pm_confluence_mock"
)

# Smoke test includes these tags (MR required, token-free)
# Layer 0: Static/Contract + Layer 1: Offline Functional
SMOKE_TAGS="deps,templates-contract,skills-spec,workflows-chain,cli-help-contract,cli-version,cli-error-handling,tests-runner-contract,install-non-interactive,install-artifacts,pm-offline,secrets-mask"

# ============================================================
# Tag Normalization
# ============================================================
# Normalizes tag input: trim whitespace, resolve aliases, deduplicate
# Input: comma-separated tag string (may contain spaces, aliases)
# Output: normalized comma-separated tag string
# Note: bash 3.2 compatible (no associative arrays)
normalize_tags() {
    local input="$1"
    local result=""
    local seen=""

    # Split by comma and process each tag
    local tag
    while IFS= read -r tag; do
        # Trim all whitespace
        tag="${tag// /}"
        tag="${tag//$'\t'/}"
        [[ -z "${tag}" ]] && continue

        # Resolve alias to canonical tag
        tag=$(resolve_tag_alias "${tag}")

        # Skip if already seen (deduplicate) - bash 3.2 compatible
        case ",${seen}," in
            *",${tag},"*) continue ;;
        esac
        seen="${seen},${tag}"

        if [[ -z "${result}" ]]; then
            result="${tag}"
        else
            result="${result},${tag}"
        fi
    done < <(echo "${input}" | tr ',' '\n')

    echo "${result}"
}

# ============================================================
# Usage
# ============================================================
tests_usage() {
	cat <<EOF
Agent-Context Tests

USAGE:
    agent-context tests [subcommand] [options]

SUBCOMMANDS:
    list            List available tests and tags
    smoke           Run minimal fast checks (deps, auth, global, project)
    e2e             Run end-to-end tests (requires Docker)

OPTIONS:
    --tags <tags>   Run tests matching tags (comma-separated)
    --skip <tags>   Skip tests matching tags (comma-separated)
    --formula <expr> Run tests matching boolean formula (and/or/not/parentheses)
    -v, --verbose   Show more details
    -q, --quiet     Show only summary
    -h, --help      Show this help

AVAILABLE TAGS:
    preflight               Required binaries and permissions (replaces deps)
    auth                    Authentication and secrets
    global                  Global installation (~/.agent-context)
    project                 Project installation (.agent/)
    connect                 External connectivity (network required)
    audit-repo              Audit repository templates
    audit-project           Audit project structure
    install-non-interactive Test non-interactive install

LEGACY ALIASES (still work):
    deps                    -> preflight
    auditRepo               -> audit-repo
    auditProject            -> audit-project
    installNonInteractive   -> install-non-interactive

FORMULA SYNTAX:
    Supports boolean expressions with:
    - 'and' / '&&'  : Logical AND
    - 'or' / '||'   : Logical OR
    - 'not' / '!'   : Logical NOT
    - '(' ')'       : Grouping (parentheses)

    Precedence (highest to lowest): not > and > or

EXAMPLES:
    # Run smoke tests (default CI check)
    agent-context tests smoke

    # Run specific tags
    agent-context tests --tags deps,auth

    # Run smoke but skip project check
    agent-context tests smoke --skip project

    # Formula: deps AND auth but NOT connect
    agent-context tests --formula "deps and auth and not connect"

    # Formula: auditRepo OR auditProject with deps
    agent-context tests --formula "(auditRepo or auditProject) and deps"

    # List available tests
    agent-context tests list

EXIT CODES:
    0   All tests passed
    1   Some tests failed
    3   Environmental skip

EOF
}

# ============================================================
# Test Functions
# ============================================================

test_deps() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    # Required binaries (hard failures)
    local required=(git jq bash)
    for cmd in "${required[@]}"; do
        total=$((total + 1))
        if has_cmd "${cmd}"; then
            log_ok "[deps] ${cmd} found"
            passed=$((passed + 1))
        else
            log_error "[deps] ${cmd} missing (required)"
            failed=$((failed + 1))
        fi
    done

    # Version checks for required binaries
    # jq 1.6+
    total=$((total + 1))
    if has_cmd jq; then
        local jq_version
        jq_version=$(jq --version 2>/dev/null | sed 's/jq-//' | cut -d'.' -f1-2)
        if [[ -n "${jq_version}" ]]; then
            local major minor
            major=$(echo "${jq_version}" | cut -d'.' -f1)
            minor=$(echo "${jq_version}" | cut -d'.' -f2)
            if [[ ${major} -ge 1 ]] && [[ ${minor} -ge 6 || ${major} -gt 1 ]]; then
                log_ok "[deps] jq version ${jq_version} >= 1.6"
                passed=$((passed + 1))
            else
                log_error "[deps] jq version ${jq_version} < 1.6 (minimum required)"
                failed=$((failed + 1))
            fi
        else
            log_error "[deps] jq version check failed"
            failed=$((failed + 1))
        fi
    else
        log_error "[deps] jq not found, cannot check version"
        failed=$((failed + 1))
    fi

    # git 2.0+
    total=$((total + 1))
    if has_cmd git; then
        local git_version
        git_version=$(git --version 2>/dev/null | sed 's/git version //' | cut -d'.' -f1-2)
        if [[ -n "${git_version}" ]]; then
            local major
            major=$(echo "${git_version}" | cut -d'.' -f1)
            if [[ ${major} -ge 2 ]]; then
                log_ok "[deps] git version ${git_version} >= 2.0"
                passed=$((passed + 1))
            else
                log_error "[deps] git version ${git_version} < 2.0 (minimum required)"
                failed=$((failed + 1))
            fi
        else
            log_error "[deps] git version check failed"
            failed=$((failed + 1))
        fi
    else
        log_error "[deps] git not found, cannot check version"
        failed=$((failed + 1))
    fi

    # bash 4+ (check via bash --version since BASH_VERSINFO may not be available)
    total=$((total + 1))
    local bash_version_str
    bash_version_str=$(bash --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
    if [[ -n "${bash_version_str}" ]]; then
        local bash_major
        bash_major=$(echo "${bash_version_str}" | cut -d'.' -f1)
        if [[ ${bash_major} -ge 4 ]]; then
            log_ok "[deps] bash version ${bash_version_str} >= 4.0"
            passed=$((passed + 1))
        else
            # macOS ships with bash 3.2 - this is expected, warn but don't fail
            log_warn "[deps] bash version ${bash_version_str} < 4.0 (some features limited)"
            passed=$((passed + 1))  # Warning, not failure (macOS default)
        fi
    else
        log_error "[deps] bash version check failed"
        failed=$((failed + 1))
    fi

    # AGENT_CONTEXT_DIR accessibility
    total=$((total + 1))
    local ac_dir
    ac_dir=$(get_agent_context_dir 2>/dev/null || echo "")
    if [[ -n "${ac_dir}" ]] && [[ -d "${ac_dir}" ]] && [[ -r "${ac_dir}" ]]; then
        log_ok "[deps] AGENT_CONTEXT_DIR accessible: ${ac_dir}"
        passed=$((passed + 1))
    else
        log_error "[deps] AGENT_CONTEXT_DIR not accessible: ${ac_dir:-not set}"
        failed=$((failed + 1))
    fi

    # Recommended binaries (warnings only, count as pass)
    local recommended=(yq glab curl)
    for cmd in "${recommended[@]}"; do
        total=$((total + 1))
        if has_cmd "${cmd}"; then
            log_ok "[deps] ${cmd} found (recommended)"
            passed=$((passed + 1))
        else
            log_warn "[deps] ${cmd} missing (recommended, optional)"
            passed=$((passed + 1))  # Warning, not failure
        fi
    done

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

test_auth() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    # ~/.secrets directory
    total=$((total + 1))
    if [[ -d "${HOME}/.secrets" ]]; then
        log_ok "[auth] ~/.secrets exists"
        passed=$((passed + 1))
    else
        log_error "[auth] ~/.secrets not found"
        failed=$((failed + 1))
    fi

    # Token files
    local tokens=("gitlab-api-token" "atlassian-api-token")
    for token in "${tokens[@]}"; do
        total=$((total + 1))
        if [[ -f "${HOME}/.secrets/${token}" ]]; then
            log_ok "[auth] ${token}"
            passed=$((passed + 1))
        else
            log_warn "[auth] ${token} not found"
            passed=$((passed + 1))  # Warning, not failure
        fi
    done

    # glab auth
    if has_cmd glab; then
        total=$((total + 1))
        if glab auth status 2>&1 | grep -q "Logged in"; then
            log_ok "[auth] glab authenticated"
            passed=$((passed + 1))
        else
            log_warn "[auth] glab not authenticated"
            passed=$((passed + 1))  # Warning, not failure
        fi
    fi

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

test_global() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    local ac_dir
    ac_dir=$(get_agent_context_dir)

    # Check directory exists
    total=$((total + 1))
    if [[ -d "${ac_dir}" ]]; then
        log_ok "[global] ${ac_dir} exists"
        passed=$((passed + 1))
    else
        log_error "[global] ${ac_dir} not found"
        failed=$((failed + 1))
        echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
        return
    fi

    # Check bin/agent-context.sh
    total=$((total + 1))
    if [[ -x "${ac_dir}/bin/agent-context.sh" ]]; then
        log_ok "[global] bin/agent-context.sh executable"
        passed=$((passed + 1))
    else
        log_warn "[global] bin/agent-context.sh not executable"
        passed=$((passed + 1))  # May be during migration
    fi

    # Check lib/
    total=$((total + 1))
    if [[ -f "${ac_dir}/lib/logging.sh" ]]; then
        log_ok "[global] lib/logging.sh"
        passed=$((passed + 1))
    else
        log_error "[global] lib/logging.sh missing"
        failed=$((failed + 1))
    fi

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

test_project() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    local project_root
    project_root=$(find_project_root "${PWD}" 2>/dev/null || true)

    if [[ -z "${project_root}" ]]; then
        log_skip "[project] Not in a project directory"
        echo "__TEST_RESULT__=0:0:0:1"
        return
    fi

    # .cursorrules
    total=$((total + 1))
    if [[ -f "${project_root}/.cursorrules" ]]; then
        log_ok "[project] .cursorrules"
        passed=$((passed + 1))
    else
        log_warn "[project] .cursorrules missing"
        passed=$((passed + 1))
    fi

    # .project.yaml
    total=$((total + 1))
    if [[ -f "${project_root}/.project.yaml" ]]; then
        log_ok "[project] .project.yaml"
        passed=$((passed + 1))

        # Check CHANGE_ME
        total=$((total + 1))
        if ! grep -q "CHANGE_ME" "${project_root}/.project.yaml" 2>/dev/null; then
            log_ok "[project] .project.yaml configured"
            passed=$((passed + 1))
        else
            log_warn "[project] .project.yaml has CHANGE_ME"
            passed=$((passed + 1))
        fi
    else
        log_warn "[project] .project.yaml missing"
        passed=$((passed + 1))
    fi

    # .agent/
    total=$((total + 1))
    if [[ -d "${project_root}/.agent" ]]; then
        log_ok "[project] .agent/"
        passed=$((passed + 1))
    else
        log_error "[project] .agent/ missing"
        failed=$((failed + 1))
    fi

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

test_connect() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    # GitLab SSH
    total=$((total + 1))
    log_progress "[connect] Testing GitLab SSH..."
    if ssh -T -o ConnectTimeout=5 -o BatchMode=yes git@gitlab.fadutec.dev 2>&1 | grep -q "Welcome"; then
        log_ok "[connect] GitLab SSH"
        passed=$((passed + 1))
    else
        log_warn "[connect] GitLab SSH failed"
        passed=$((passed + 1))  # Network issues are warnings
    fi

    # GitLab API
    if [[ -f "${HOME}/.secrets/gitlab-api-token" ]] && has_cmd curl; then
        total=$((total + 1))
        local status
        status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 \
            -H "PRIVATE-TOKEN: $(cat "${HOME}/.secrets/gitlab-api-token")" \
            "https://gitlab.fadutec.dev/api/v4/user" 2>/dev/null || echo "000")
        if [[ "${status}" == "200" ]]; then
            log_ok "[connect] GitLab API"
            passed=$((passed + 1))
        else
            log_warn "[connect] GitLab API HTTP ${status}"
            passed=$((passed + 1))
        fi
    fi

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

test_audit_repo() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    local ac_dir
    ac_dir=$(get_agent_context_dir)

    if [[ ! -d "${ac_dir}" ]]; then
        log_skip "[audit-repo] Not in agent-context repo"
        echo "__TEST_RESULT__=0:0:0:1"
        return
    fi

    # Check templates
    total=$((total + 1))
    if [[ -d "${ac_dir}/templates" ]]; then
        log_ok "[audit-repo] templates/ exists"
        passed=$((passed + 1))
    else
        log_error "[audit-repo] templates/ missing"
        failed=$((failed + 1))
    fi

    # Check skills
    total=$((total + 1))
    if [[ -d "${ac_dir}/skills" ]]; then
        log_ok "[audit-repo] skills/ exists"
        passed=$((passed + 1))
    else
        log_error "[audit-repo] skills/ missing"
        failed=$((failed + 1))
    fi

    # Check workflows
    total=$((total + 1))
    if [[ -d "${ac_dir}/workflows" ]]; then
        log_ok "[audit-repo] workflows/ exists"
        passed=$((passed + 1))
    else
        log_error "[audit-repo] workflows/ missing"
        failed=$((failed + 1))
    fi

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

# ============================================================
# Layer 0: Static/Contract Tests
# ============================================================

test_templates_contract() {
    local ac_dir
    ac_dir=$(get_agent_context_dir)
    local test_script="${ac_dir}/tests/templates/t-templates-contract.sh"

    if [[ -f "${test_script}" ]]; then
        # Run in subshell to avoid function name collision
        bash "${test_script}"
    else
        log_error "[templates-contract] Test script not found: ${test_script}"
        echo "__TEST_RESULT__=1:0:1:0"
    fi
}

test_skills_spec() {
    local ac_dir
    ac_dir=$(get_agent_context_dir)
    local test_script="${ac_dir}/tests/skills/t-skills-spec.sh"

    if [[ -f "${test_script}" ]]; then
        # Run in subshell to avoid function name collision
        bash "${test_script}"
    else
        log_error "[skills-spec] Test script not found: ${test_script}"
        echo "__TEST_RESULT__=1:0:1:0"
    fi
}

test_workflows_chain() {
    local ac_dir
    ac_dir=$(get_agent_context_dir)
    local test_script="${ac_dir}/tests/workflows/t-workflows-chain.sh"

    if [[ -f "${test_script}" ]]; then
        # Run in subshell to avoid function name collision
        bash "${test_script}"
    else
        log_error "[workflows-chain] Test script not found: ${test_script}"
        echo "__TEST_RESULT__=1:0:1:0"
    fi
}

# ============================================================
# Layer 1: Offline Functional Tests
# ============================================================

test_cli_help_contract() {
    local ac_dir
    ac_dir=$(get_agent_context_dir)
    local test_script="${ac_dir}/tests/builtin/t-cli-help-contract.sh"

    if [[ -f "${test_script}" ]]; then
        bash "${test_script}"
    else
        log_error "[cli-help-contract] Test script not found: ${test_script}"
        echo "__TEST_RESULT__=1:0:1:0"
    fi
}

test_cli_version() {
    local ac_dir
    ac_dir=$(get_agent_context_dir)
    local test_script="${ac_dir}/tests/builtin/t-cli-version.sh"

    if [[ -f "${test_script}" ]]; then
        bash "${test_script}"
    else
        log_error "[cli-version] Test script not found: ${test_script}"
        echo "__TEST_RESULT__=1:0:1:0"
    fi
}

test_cli_error_handling() {
    local ac_dir
    ac_dir=$(get_agent_context_dir)
    local test_script="${ac_dir}/tests/builtin/t-cli-error-handling.sh"

    if [[ -f "${test_script}" ]]; then
        bash "${test_script}"
    else
        log_error "[cli-error-handling] Test script not found: ${test_script}"
        echo "__TEST_RESULT__=1:0:1:0"
    fi
}

test_tests_runner_contract() {
    local ac_dir
    ac_dir=$(get_agent_context_dir)
    local test_script="${ac_dir}/tests/builtin/t-tests-runner-contract.sh"

    if [[ -f "${test_script}" ]]; then
        bash "${test_script}"
    else
        log_error "[tests-runner-contract] Test script not found: ${test_script}"
        echo "__TEST_RESULT__=1:0:1:0"
    fi
}

test_install_artifacts() {
    local ac_dir
    ac_dir=$(get_agent_context_dir)
    local test_script="${ac_dir}/tests/install/t-install-artifacts.sh"

    if [[ -f "${test_script}" ]]; then
        bash "${test_script}"
    else
        log_error "[install-artifacts] Test script not found: ${test_script}"
        echo "__TEST_RESULT__=1:0:1:0"
    fi
}

test_pm_offline() {
    local ac_dir
    ac_dir=$(get_agent_context_dir)
    local test_script="${ac_dir}/tests/tools-pm/t-pm-offline.sh"

    if [[ -f "${test_script}" ]]; then
        bash "${test_script}"
    else
        log_error "[pm-offline] Test script not found: ${test_script}"
        echo "__TEST_RESULT__=1:0:1:0"
    fi
}

test_secrets_mask() {
    local ac_dir
    ac_dir=$(get_agent_context_dir)
    local test_script="${ac_dir}/tests/security/t-secrets-mask.sh"

    if [[ -f "${test_script}" ]]; then
        bash "${test_script}"
    else
        log_error "[secrets-mask] Test script not found: ${test_script}"
        echo "__TEST_RESULT__=1:0:1:0"
    fi
}

test_audit_project() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    local project_root
    project_root=$(find_project_root "${PWD}" 2>/dev/null || true)

    if [[ -z "${project_root}" ]]; then
        log_skip "[audit-project] Not in a project"
        echo "__TEST_RESULT__=0:0:0:1"
        return
    fi

    # Check .agent structure
    local agent_dirs=("skills" "workflows" "tools/pm" "docs")
    for dir in "${agent_dirs[@]}"; do
        total=$((total + 1))
        if [[ -d "${project_root}/.agent/${dir}" ]]; then
            log_ok "[audit-project] .agent/${dir}/"
            passed=$((passed + 1))
        else
            log_warn "[audit-project] .agent/${dir}/ missing"
            passed=$((passed + 1))
        fi
    done

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

test_install_non_interactive() {
    local ac_dir
    ac_dir=$(get_agent_context_dir)
    local test_script="${ac_dir}/tests/install/t-install-non-interactive.sh"

    if [[ -f "${test_script}" ]]; then
        bash "${test_script}"
    else
        log_error "[install-non-interactive] Test script not found: ${test_script}"
        echo "__TEST_RESULT__=1:0:1:0"
    fi
}

# ============================================================
# Layer 2: Mock Integration Tests
# ============================================================

test_jira_auth_mock() {
    local ac_dir
    ac_dir=$(get_agent_context_dir)
    local test_script="${ac_dir}/tests/mock/layer2/t-jira-auth-mock.sh"

    if [[ -f "${test_script}" ]]; then
        bash "${test_script}"
    else
        log_error "[jira-auth-mock] Test script not found: ${test_script}"
        echo "__TEST_RESULT__=1:0:1:0"
    fi
}

test_confluence_auth_mock() {
    local ac_dir
    ac_dir=$(get_agent_context_dir)
    local test_script="${ac_dir}/tests/mock/layer2/t-confluence-auth-mock.sh"

    if [[ -f "${test_script}" ]]; then
        bash "${test_script}"
    else
        log_error "[confluence-auth-mock] Test script not found: ${test_script}"
        echo "__TEST_RESULT__=1:0:1:0"
    fi
}

test_pm_jira_mock() {
    local ac_dir
    ac_dir=$(get_agent_context_dir)
    local test_script="${ac_dir}/tests/mock/layer2/t-pm-jira-mock.sh"

    if [[ -f "${test_script}" ]]; then
        bash "${test_script}"
    else
        log_error "[pm-jira-mock] Test script not found: ${test_script}"
        echo "__TEST_RESULT__=1:0:1:0"
    fi
}

test_pm_confluence_mock() {
    local ac_dir
    ac_dir=$(get_agent_context_dir)
    local test_script="${ac_dir}/tests/mock/layer2/t-pm-confluence-mock.sh"

    if [[ -f "${test_script}" ]]; then
        bash "${test_script}"
    else
        log_error "[pm-confluence-mock] Test script not found: ${test_script}"
        echo "__TEST_RESULT__=1:0:1:0"
    fi
}

# ============================================================
# Formula Parser (Include/Exclude Collection)
# ============================================================
# Supports: and, or, not, parentheses
# Uses a recursive descent parser that collects include/exclude
# tag sets. No subshell calls -- avoids bash variable-isolation.
#
# Semantics for tag selection:
#   Positive tags  -> include set
#   NOT tags       -> exclude set
#   AND / OR       -> combine (both operators collect tags)
#
# "deps and auth"           -> include {deps, auth}
# "not connect"             -> exclude {connect}, include defaults to all
# "deps and auth and not connect" -> include {deps, auth}, exclude {connect}
#
# Grammar:
#   expr   -> term (('or' | '||') term)*
#   term   -> factor (('and' | '&&') factor)*
#   factor -> ('not' | '!') factor | '(' expr ')' | TAG

# Global state
declare -a FORMULA_TOKENS
FORMULA_POS=0
FORMULA_NEGATED=false
declare -a FORMULA_INCLUDE_TAGS
declare -a FORMULA_EXCLUDE_TAGS

formula_tokenize() {
	local formula="$1"
	FORMULA_TOKENS=()
	FORMULA_POS=0

	# Normalize operators
	formula="${formula//&&/ and }"
	formula="${formula//||/ or }"
	formula="${formula//!/ not }"

	# Tokenize (handle parentheses attached to words)
	local word
	for word in ${formula}; do
		while [[ "${word}" == "("* ]] && [[ "${word}" != "(" ]]; do
			FORMULA_TOKENS+=("(")
			word="${word#\(}"
		done

		local trailing_parens=""
		while [[ "${word}" == *")" ]] && [[ "${word}" != ")" ]]; do
			trailing_parens="${trailing_parens})"
			word="${word%\)}"
		done

		if [[ -n "${word}" ]]; then
			FORMULA_TOKENS+=("${word}")
		fi

		while [[ -n "${trailing_parens}" ]]; do
			FORMULA_TOKENS+=(")")
			trailing_parens="${trailing_parens#\)}"
		done
	done
}

# factor -> NOT factor | '(' expr ')' | TAG
# Collects tags into FORMULA_INCLUDE_TAGS or FORMULA_EXCLUDE_TAGS
formula_collect_factor() {
    local current="${FORMULA_TOKENS[${FORMULA_POS}]:-}"

    case "${current}" in
        not|NOT)
            FORMULA_POS=$((FORMULA_POS + 1))
            local was_negated="${FORMULA_NEGATED}"
            if [[ "${FORMULA_NEGATED}" == "true" ]]; then
                FORMULA_NEGATED=false
            else
                FORMULA_NEGATED=true
            fi
            formula_collect_factor
            FORMULA_NEGATED="${was_negated}"
            ;;
        "(")
            FORMULA_POS=$((FORMULA_POS + 1))
            formula_collect_expr
            if [[ "${FORMULA_TOKENS[${FORMULA_POS}]:-}" == ")" ]]; then
                FORMULA_POS=$((FORMULA_POS + 1))
            fi
            ;;
        ""|and|AND|or|OR|")")
            # Empty or unexpected: skip
            ;;
        *)
            FORMULA_POS=$((FORMULA_POS + 1))
            # Resolve alias to canonical tag
            local tag
            tag=$(resolve_tag_alias "${current}")
            if [[ "${FORMULA_NEGATED}" == "true" ]]; then
                FORMULA_EXCLUDE_TAGS+=("${tag}")
            else
                FORMULA_INCLUDE_TAGS+=("${tag}")
            fi
            ;;
    esac
}

# term -> factor (AND factor)*
formula_collect_term() {
	formula_collect_factor
	while true; do
		local current="${FORMULA_TOKENS[${FORMULA_POS}]:-}"
		if [[ "${current}" == "and" ]] || [[ "${current}" == "AND" ]]; then
			FORMULA_POS=$((FORMULA_POS + 1))
			formula_collect_factor
		else
			break
		fi
	done
}

# expr -> term (OR term)*
formula_collect_expr() {
	formula_collect_term
	while true; do
		local current="${FORMULA_TOKENS[${FORMULA_POS}]:-}"
		if [[ "${current}" == "or" ]] || [[ "${current}" == "OR" ]]; then
			FORMULA_POS=$((FORMULA_POS + 1))
			formula_collect_term
		else
			break
		fi
	done
}

# Get all matching tags from formula
formula_get_matching_tags() {
	local formula="$1"
	local matching_tags=()

	FORMULA_INCLUDE_TAGS=()
	FORMULA_EXCLUDE_TAGS=()
	FORMULA_NEGATED=false

	formula_tokenize "${formula}"
	formula_collect_expr

	for entry in "${TEST_REGISTRY[@]}"; do
		local tag="${entry%%:*}"
		local include=false

		# Determine inclusion
		if [[ ${#FORMULA_INCLUDE_TAGS[@]} -eq 0 ]]; then
			# No explicit includes -> default to all
			include=true
		else
			local inc
			for inc in "${FORMULA_INCLUDE_TAGS[@]}"; do
				if [[ "${tag}" == "${inc}" ]]; then
					include=true
					break
				fi
			done
		fi

		# Apply exclusions
		if [[ "${include}" == "true" ]]; then
			local exc
			for exc in "${FORMULA_EXCLUDE_TAGS[@]}"; do
				if [[ "${tag}" == "${exc}" ]]; then
					include=false
					break
				fi
			done
		fi

		if [[ "${include}" == "true" ]]; then
			matching_tags+=("${tag}")
		fi
	done

	local IFS=','
	echo "${matching_tags[*]}"
}

# ============================================================
# Test Runner
# ============================================================

list_tests() {
	echo ""
	echo "Available Tests:"
	echo "================"
	echo ""
	printf "%-25s %s\n" "TAG" "DESCRIPTION"
	printf "%-25s %s\n" "---" "-----------"
	for entry in "${TEST_REGISTRY[@]}"; do
		local tag="${entry%%:*}"
		local rest="${entry#*:}"
		local desc="${rest%%:*}"
		printf "%-25s %s\n" "${tag}" "${desc}"
	done
	echo ""
	echo "Smoke tests include: ${SMOKE_TAGS}"
	echo ""
}

run_tests_by_tags() {
    local tags="$1"
    local skip_tags="$2"
    local verbose="$3"

    local total=0
    local passed=0
    local failed=0
    local skipped=0

    # Normalize tags (resolve aliases, trim whitespace, deduplicate)
    tags=$(normalize_tags "${tags}")
    skip_tags=$(normalize_tags "${skip_tags}")

    # Convert tags to array
    IFS=',' read -ra tag_array <<< "${tags}"
    IFS=',' read -ra skip_array <<< "${skip_tags}"

    for entry in "${TEST_REGISTRY[@]}"; do
        local tag="${entry%%:*}"
        local rest="${entry#*:}"
        local desc="${rest%%:*}"
        local func="${rest#*:}"

        # Check if tag should run
        local should_run=false
        for t in "${tag_array[@]}"; do
            if [[ "${t}" == "${tag}" ]]; then
                should_run=true
                break
            fi
        done

        # Check if tag should skip
        for s in "${skip_array[@]}"; do
            if [[ "${s}" == "${tag}" ]]; then
                should_run=false
                break
            fi
        done

        if [[ "${should_run}" == "true" ]]; then
            if [[ "${verbose}" == "true" ]]; then
                echo ""
                log_info "Running: ${tag} - ${desc}"
            fi

            # Run test function and capture all output
            local raw_output
            raw_output=$("${func}" 2>&1)

            # Parse result using __TEST_RESULT__ marker
            local marker
            marker=$(echo "${raw_output}" | grep '^__TEST_RESULT__=' | tail -1)

            if [[ -z "${marker}" ]]; then
                log_error "Test ${tag}: no result marker found"
                failed=$((failed + 1))
                continue
            fi

            local test_result="${marker#__TEST_RESULT__=}"
            local t p f s
            IFS=':' read -r t p f s <<< "${test_result}"
            s="${s:-0}"  # skip defaults to 0 if not provided

            # Check for skip (s > 0 and t == 0)
            if [[ ${s:-0} -gt 0 ]] && [[ ${t:-0} -eq 0 ]]; then
                skipped=$((skipped + 1))
            else
                total=$((total + ${t:-0}))
                passed=$((passed + ${p:-0}))
                failed=$((failed + ${f:-0}))
            fi
        fi
    done

    echo "${total}:${passed}:${failed}:${skipped}"
}

# ============================================================
# Main Tests Function
# ============================================================
run_tests() {
	local subcommand=""
	local tags=""
	local skip_tags=""
	local formula=""
	local verbose=false
	local quiet=false

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
			list|smoke|e2e)
				subcommand="$1"
				;;
			--tags)
				tags="$2"
				shift
				;;
			--skip)
				skip_tags="$2"
				shift
				;;
			--formula)
				formula="$2"
				shift
				;;
			-v|--verbose)
				verbose=true
				;;
			-q|--quiet)
				quiet=true
				;;
			-h|--help)
				tests_usage
				return 0
				;;
			*)
				log_error "Unknown option: $1"
				tests_usage
				return 2
				;;
		esac
		shift
	done

	case "${subcommand}" in
		list)
			list_tests
			return 0
			;;
		smoke)
			tags="${tags:-${SMOKE_TAGS}}"
			;;
		e2e)
			tags="${tags:-installNonInteractive}"
			;;
		"")
			if [[ -z "${tags}" ]] && [[ -z "${formula}" ]]; then
				# Default to smoke
				tags="${SMOKE_TAGS}"
			fi
			;;
	esac

	# If formula is provided, convert to tags
	if [[ -n "${formula}" ]]; then
		tags=$(formula_get_matching_tags "${formula}")
		if [[ -z "${tags}" ]]; then
			log_warn "No tags matched formula: ${formula}"
			echo "Summary: total=0 passed=0 failed=0 warned=0 skipped=0"
			return 0
		fi
		if [[ "${quiet}" == "false" ]]; then
			log_info "Formula '${formula}' matched tags: ${tags}"
		fi
	fi

	if [[ "${quiet}" == "false" ]]; then
		echo ""
		echo "============================================"
		echo "  Agent-Context Tests"
		echo "============================================"
		echo ""
		log_info "Tags: ${tags}"
		if [[ -n "${skip_tags}" ]]; then
			log_info "Skip: ${skip_tags}"
		fi
		echo ""
	fi

	# Run tests
	local result
	result=$(run_tests_by_tags "${tags}" "${skip_tags}" "${verbose}")

	local total passed failed skipped
	total=$(echo "${result}" | cut -d: -f1)
	passed=$(echo "${result}" | cut -d: -f2)
	failed=$(echo "${result}" | cut -d: -f3)
	skipped=$(echo "${result}" | cut -d: -f4)

	# Summary
	if [[ "${quiet}" == "false" ]]; then
		echo ""
		echo "============================================"
	fi

	local warned=0
	local exit_code=0

	if [[ ${failed} -gt 0 ]]; then
		if [[ "${quiet}" == "false" ]]; then
			log_error "Tests failed"
		fi
		exit_code=1
	elif [[ ${skipped} -gt 0 ]] && [[ ${total} -eq 0 ]]; then
		if [[ "${quiet}" == "false" ]]; then
			log_skip "All tests skipped (environmental)"
		fi
		exit_code=3
	else
		if [[ "${quiet}" == "false" ]]; then
			log_ok "All tests passed"
		fi
	fi

	echo "Summary: total=${total} passed=${passed} failed=${failed} warned=${warned} skipped=${skipped}"

	return ${exit_code}
}

# Allow direct execution for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# When run directly, source required libraries
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
	# shellcheck source=../lib/logging.sh
	source "${SCRIPT_DIR}/lib/logging.sh"
	# shellcheck source=../lib/platform.sh
	source "${SCRIPT_DIR}/lib/platform.sh"
	run_tests "$@"
fi

#!/bin/bash
# JUnit XML report helper functions
# Usage: source this file in test scripts

# Initialize JUnit XML output
# Args: $1 = test suite name
junit_start() {
	local suite_name="$1"
	local timestamp
	timestamp=$(date -Iseconds)

	echo '<?xml version="1.0" encoding="UTF-8"?>'
	echo "<testsuites>"
	echo "  <testsuite name=\"${suite_name}\" timestamp=\"${timestamp}\">"
}

# End JUnit XML output
# Args: $1 = tests count, $2 = failures count, $3 = time in seconds
junit_end() {
	local tests="$1"
	local failures="$2"
	local time="${3:-0}"

	echo "  </testsuite>"
	echo "</testsuites>"

	# Update testsuite attributes (sed in-place simulation)
	# This is handled by the caller
}

# Add a passed test case
# Args: $1 = class name, $2 = test name, $3 = time (optional), $4 = system output (optional)
junit_pass() {
	local classname="$1"
	local name="$2"
	local time="${3:-0.001}"
	local system_out="${4:-}"

	if [[ -n "${system_out}" ]]; then
		echo "    <testcase classname=\"${classname}\" name=\"${name}\" time=\"${time}\">"
		echo "      <system-out><![CDATA["
		echo "${system_out}"
		echo "]]></system-out>"
		echo "    </testcase>"
	else
		echo "    <testcase classname=\"${classname}\" name=\"${name}\" time=\"${time}\"/>"
	fi
}

# Add a failed test case
# Args: $1 = class name, $2 = test name, $3 = failure message, $4 = time (optional), $5 = system output (optional)
junit_fail() {
	local classname="$1"
	local name="$2"
	local message="$3"
	local time="${4:-0.001}"
	local system_out="${5:-}"

	# Escape XML special characters in message (for attribute)
	local escaped_message
	escaped_message=$(echo "${message}" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')

	# Combine message and system_out for failure detail (GitLab shows this in View Details)
	local failure_detail="${message}"
	if [[ -n "${system_out}" ]]; then
		failure_detail="${message}"$'\n\n'"${system_out}"
	fi

	echo "    <testcase classname=\"${classname}\" name=\"${name}\" time=\"${time}\">"
	echo "      <failure message=\"${escaped_message}\" type=\"AssertionError\"><![CDATA["
	echo "${failure_detail}"
	echo "]]></failure>"
	if [[ -n "${system_out}" ]]; then
		echo "      <system-out><![CDATA["
		echo "${system_out}"
		echo "]]></system-out>"
	fi
	echo "    </testcase>"
}

# Add a skipped test case
# Args: $1 = class name, $2 = test name, $3 = skip reason
junit_skip() {
	local classname="$1"
	local name="$2"
	local reason="$3"

	echo "    <testcase classname=\"${classname}\" name=\"${name}\" time=\"0\">"
	echo "      <skipped message=\"${reason}\"/>"
	echo "    </testcase>"
}

# Generate complete JUnit XML for a test suite
# Args: $1 = suite name, $2 = tests, $3 = failures, $4 = test cases (multiline string)
junit_testsuite() {
	local suite_name="$1"
	local tests="$2"
	local failures="$3"
	local test_cases="$4"
	local timestamp
	local time="${5:-0}"

	timestamp=$(date -Iseconds)

	cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="${suite_name}" tests="${tests}" failures="${failures}" errors="0" skipped="0" timestamp="${timestamp}" time="${time}">
${test_cases}
  </testsuite>
</testsuites>
EOF
}

# Print test summary to stderr
# Args: $1=language, $2=total, $3=passed, $4=failed
print_summary() {
	local lang="$1" total="$2" passed="$3" failed="$4"
	{
		echo ""
		echo "=========================================="
		echo "${lang} Coding Convention Test Summary"
		echo "=========================================="
		echo "Total: ${total} | Passed: ${passed} | Failed: ${failed}"
	} >&2
}

# Save test case result to file for verification
# Args: $1=classname (e.g., c.pass), $2=filename, $3=result (PASS|FAIL), $4=output_file
save_testcase_result() {
	local classname="$1" filename="$2" result="$3" outfile="$4"
	if [[ -n "${outfile}" ]]; then
		echo "${classname}:${filename}:${result}" >> "${outfile}"
	fi
}

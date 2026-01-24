# Coding Convention Test Framework Makefile
# Run linting tools against test cases to verify rule detection

.PHONY: all docker-build test test-c test-bash test-python test-make test-yaml \
        test-junit test-c-junit test-bash-junit test-python-junit test-make-junit test-yaml-junit \
        report clean help

# Configuration
IMAGE_NAME   := coding-convention-test
CONTAINER    := ${IMAGE_NAME}-runner
WORK_DIR     := /work
PROJECT_ROOT := $(shell cd ../.. && pwd)
OUT_DIR      := out

# Colors for output
RED    := \033[0;31m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
NC     := \033[0m

# Default target
all: test report

# Build Docker image with all linting tools
docker-build:
	@echo "Building Docker image..."
	docker build -t ${IMAGE_NAME} .

# Run all tests
test: docker-build test-c test-bash test-python test-make test-yaml
	@echo ""
	@echo "${GREEN}All tests completed!${NC}"

# Test C code
test-c: docker-build
	@echo ""
	@echo "${YELLOW}=== Testing C Code ===${NC}"
	@docker run --rm -v ${PROJECT_ROOT}:${WORK_DIR} ${IMAGE_NAME} \
		${WORK_DIR}/tools/lint/scripts/test_c.sh

# Test Bash scripts
test-bash: docker-build
	@echo ""
	@echo "${YELLOW}=== Testing Bash Scripts ===${NC}"
	@docker run --rm -v ${PROJECT_ROOT}:${WORK_DIR} ${IMAGE_NAME} \
		${WORK_DIR}/tools/lint/scripts/test_bash.sh

# Test Python code
test-python: docker-build
	@echo ""
	@echo "${YELLOW}=== Testing Python Code ===${NC}"
	@docker run --rm -v ${PROJECT_ROOT}:${WORK_DIR} ${IMAGE_NAME} \
		${WORK_DIR}/tools/lint/scripts/test_python.sh

# Test Makefiles
test-make: docker-build
	@echo ""
	@echo "${YELLOW}=== Testing Makefiles ===${NC}"
	@docker run --rm -v ${PROJECT_ROOT}:${WORK_DIR} ${IMAGE_NAME} \
		${WORK_DIR}/tools/lint/scripts/test_make.sh

# Test YAML/Dockerfile
test-yaml: docker-build
	@echo ""
	@echo "${YELLOW}=== Testing YAML/Dockerfile ===${NC}"
	@docker run --rm -v ${PROJECT_ROOT}:${WORK_DIR} ${IMAGE_NAME} \
		${WORK_DIR}/tools/lint/scripts/test_yaml.sh

# Generate report
report: docker-build
	@echo ""
	@echo "${YELLOW}=== Generating Report ===${NC}"
	@mkdir -p ${OUT_DIR}
	@docker run --rm -v ${PROJECT_ROOT}:${WORK_DIR} ${IMAGE_NAME} \
		${WORK_DIR}/tools/lint/scripts/generate_report.sh \
		> ${OUT_DIR}/report.md
	@echo "${GREEN}Report generated: ${OUT_DIR}/report.md${NC}"

# JUnit XML output for GitLab CI
test-junit: docker-build test-c-junit test-bash-junit test-python-junit test-make-junit test-yaml-junit
	@echo ""
	@echo "${GREEN}All JUnit tests completed!${NC}"
	@echo "Reports: ${OUT_DIR}/junit-*.xml"

test-c-junit: docker-build
	@echo ""
	@echo "${YELLOW}=== Testing C Code (JUnit) ===${NC}"
	@mkdir -p ${OUT_DIR}
	@docker run --rm -v ${PROJECT_ROOT}:${WORK_DIR} ${IMAGE_NAME} \
		${WORK_DIR}/tools/lint/scripts/test_c_junit.sh \
		> ${OUT_DIR}/junit-c.xml

test-bash-junit: docker-build
	@echo ""
	@echo "${YELLOW}=== Testing Bash Scripts (JUnit) ===${NC}"
	@mkdir -p ${OUT_DIR}
	@docker run --rm -v ${PROJECT_ROOT}:${WORK_DIR} ${IMAGE_NAME} \
		${WORK_DIR}/tools/lint/scripts/test_bash_junit.sh \
		> ${OUT_DIR}/junit-bash.xml

test-python-junit: docker-build
	@echo ""
	@echo "${YELLOW}=== Testing Python Code (JUnit) ===${NC}"
	@mkdir -p ${OUT_DIR}
	@docker run --rm -v ${PROJECT_ROOT}:${WORK_DIR} ${IMAGE_NAME} \
		${WORK_DIR}/tools/lint/scripts/test_python_junit.sh \
		> ${OUT_DIR}/junit-python.xml

test-make-junit: docker-build
	@echo ""
	@echo "${YELLOW}=== Testing Makefiles (JUnit) ===${NC}"
	@mkdir -p ${OUT_DIR}
	@docker run --rm -v ${PROJECT_ROOT}:${WORK_DIR} ${IMAGE_NAME} \
		${WORK_DIR}/tools/lint/scripts/test_make_junit.sh \
		> ${OUT_DIR}/junit-make.xml

test-yaml-junit: docker-build
	@echo ""
	@echo "${YELLOW}=== Testing YAML/Dockerfile (JUnit) ===${NC}"
	@mkdir -p ${OUT_DIR}
	@docker run --rm -v ${PROJECT_ROOT}:${WORK_DIR} ${IMAGE_NAME} \
		${WORK_DIR}/tools/lint/scripts/test_yaml_junit.sh \
		> ${OUT_DIR}/junit-yaml.xml

# Run individual tool checks (for debugging)
check-clang-format: docker-build
	@docker run --rm -v ${PROJECT_ROOT}:${WORK_DIR} ${IMAGE_NAME} \
		bash -c "cd ${WORK_DIR} && clang-format --dry-run --Werror tests/unit/lint-rules/c/pass/*.c"

check-shellcheck: docker-build
	@docker run --rm -v ${PROJECT_ROOT}:${WORK_DIR} ${IMAGE_NAME} \
		bash -c "cd ${WORK_DIR} && shellcheck tests/unit/lint-rules/bash/pass/*.sh"

check-black: docker-build
	@docker run --rm -v ${PROJECT_ROOT}:${WORK_DIR} ${IMAGE_NAME} \
		bash -c "cd ${WORK_DIR} && black --check tests/unit/lint-rules/python/pass/*.py"

check-yamllint: docker-build
	@docker run --rm -v ${PROJECT_ROOT}:${WORK_DIR} ${IMAGE_NAME} \
		bash -c "cd ${WORK_DIR} && yamllint -c .yamllint.yml tests/unit/lint-rules/yaml/pass/*.yaml"

# Clean generated files
clean:
	@rm -rf ${OUT_DIR}
	@echo "Cleaned output directory"

# Remove Docker image
clean-docker:
	@docker rmi -f ${IMAGE_NAME} 2>/dev/null || true
	@echo "Removed Docker image"

# Full clean
distclean: clean clean-docker

# Help
help:
	@echo "Coding Convention Test Framework"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all              Run all tests and generate report (default)"
	@echo "  docker-build     Build Docker image with linting tools"
	@echo "  test             Run all language tests"
	@echo "  test-c           Test C code with clang-format/clang-tidy"
	@echo "  test-bash        Test Bash scripts with ShellCheck"
	@echo "  test-python      Test Python code with Black/Flake8/isort"
	@echo "  test-make        Test Makefiles with checkmake"
	@echo "  test-yaml        Test YAML/Dockerfile with yamllint/hadolint"
	@echo "  test-junit       Run all tests with JUnit XML output"
	@echo "  test-c-junit     Test C code (JUnit XML)"
	@echo "  test-bash-junit  Test Bash (JUnit XML)"
	@echo "  test-python-junit Test Python (JUnit XML)"
	@echo "  test-make-junit  Test Make (JUnit XML)"
	@echo "  test-yaml-junit  Test YAML (JUnit XML)"
	@echo "  report           Generate test report (out/report.md)"
	@echo "  clean            Remove generated files"
	@echo "  clean-docker     Remove Docker image"
	@echo "  distclean        Full clean (files + Docker image)"
	@echo "  help             Show this help message"

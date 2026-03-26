#!/bin/bash
#
# =============================================================================
#  CUSTOM ACTIONS LAB - LOCAL PIPELINE SIMULATOR
# =============================================================================
#
#  This script validates the custom actions lab locally by:
#
#   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
#   │ 1.FILES  │──>│ 2.DEPS   │──>│ 3.TESTS  │──>│ 4.YAML   │──>│ 5.DOCKER │
#   │ (verify) │   │(install) │   │ (pytest) │   │(validate)│   │(optional)│
#   └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
#
#  KEY CONCEPT: If ANY stage fails, the pipeline STOPS immediately.
#
#  Usage:
#    chmod +x scripts/run-pipeline.sh
#    ./scripts/run-pipeline.sh
#
# =============================================================================

set -e  # EXIT IMMEDIATELY if any command fails

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Track timing
PIPELINE_START=$(date +%s)

# Ensure we're in the project root
cd "$(dirname "$0")/.."
PROJECT_DIR=$(pwd)

# ===========================================================================
# HELPER FUNCTIONS
# ===========================================================================

stage_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  STAGE: $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

pass() {
    echo -e "  ${GREEN}✓ PASSED${NC}: $1"
}

fail() {
    echo -e "  ${RED}✗ FAILED${NC}: $1"
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  PIPELINE FAILED at stage: $2${NC}"
    echo -e "${RED}  The pipeline STOPPED. No further stages will run.${NC}"
    echo -e "${RED}  Fix the issue and run the pipeline again.${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
}

# ===========================================================================
# PIPELINE START
# ===========================================================================

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║       CUSTOM ACTIONS LAB - Pipeline Starting...         ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Project:   ${PROJECT_DIR}"
echo -e "  Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "  Python:    $(python3 --version 2>/dev/null || python --version 2>/dev/null || echo 'NOT FOUND')"
echo -e "  Node.js:   $(node --version 2>/dev/null || echo 'NOT FOUND')"

# ===========================================================================
# STAGE 1: VERIFY ACTION FILES
# ===========================================================================
# Check that all three custom actions have their required files.

stage_header "1/5 - VERIFY ACTION FILES"
echo "  Checking that all action files exist..."

REQUIRED_FILES=(
    # JavaScript Action (PR Comment Bot)
    "actions/pr-comment/action.yml"
    "actions/pr-comment/index.js"
    "actions/pr-comment/package.json"
    # Docker Action (Code Statistics)
    "actions/code-stats/action.yml"
    "actions/code-stats/Dockerfile"
    "actions/code-stats/entrypoint.sh"
    # Composite Action (Setup & Test)
    "actions/setup-and-test/action.yml"
    # Sample App & Tests
    "app/__init__.py"
    "app/utils.py"
    "tests/unit/test_utils.py"
    "requirements.txt"
)

ALL_FOUND=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "    ${GREEN}✓${NC} $file"
    else
        echo -e "    ${RED}✗${NC} $file  ${RED}(MISSING!)${NC}"
        ALL_FOUND=false
    fi
done

if [ "$ALL_FOUND" = true ]; then
    pass "All action files present"
else
    fail "Missing required files" "VERIFY FILES"
fi

# ===========================================================================
# STAGE 2: INSTALL PYTHON DEPENDENCIES
# ===========================================================================

stage_header "2/5 - INSTALL PYTHON DEPENDENCIES"
echo "  Installing Python dependencies from requirements.txt..."
echo ""

# Detect python command
PYTHON_CMD="python3"
if ! command -v python3 &> /dev/null; then
    PYTHON_CMD="python"
fi

if $PYTHON_CMD -m pip install -r requirements.txt --quiet 2>&1; then
    pass "Python dependencies installed successfully"
else
    fail "Failed to install Python dependencies" "INSTALL DEPS"
fi

# ===========================================================================
# STAGE 3: RUN UNIT TESTS
# ===========================================================================
# Run the sample app tests -- these are the same tests the composite
# action would run on GitHub Actions.

stage_header "3/5 - RUN UNIT TESTS"
echo "  Running pytest against app/utils.py..."
echo "  These tests validate the sample application functions."
echo ""

TEST_START=$(date +%s)

if $PYTHON_CMD -m pytest tests/unit/ -v --tb=short 2>&1; then
    TEST_END=$(date +%s)
    TEST_TIME=$((TEST_END - TEST_START))
    echo ""
    pass "Unit tests passed (${TEST_TIME}s)"
else
    TEST_END=$(date +%s)
    TEST_TIME=$((TEST_END - TEST_START))
    echo ""
    echo -e "  ${YELLOW}Hint: A unit test failed. Look at the FAILED line above.${NC}"
    echo -e "  ${YELLOW}      Check app/utils.py -- did you change a function?${NC}"
    fail "Unit tests failed (${TEST_TIME}s)" "UNIT TESTS"
fi

# ===========================================================================
# STAGE 4: VALIDATE ACTION METADATA
# ===========================================================================
# Check that each action.yml has the required fields: name, description, runs.

stage_header "4/5 - VALIDATE ACTION METADATA"
echo "  Checking action.yml files for required fields..."
echo ""

ACTIONS=("actions/pr-comment" "actions/code-stats" "actions/setup-and-test")
VALID=true

for action_dir in "${ACTIONS[@]}"; do
    action_file="${action_dir}/action.yml"
    echo -e "  Validating ${CYAN}${action_file}${NC}..."

    # Check for required top-level fields
    for field in "name:" "description:" "runs:"; do
        if grep -q "^${field}" "$action_file" 2>/dev/null; then
            echo -e "    ${GREEN}✓${NC} Has '${field}'"
        else
            echo -e "    ${RED}✗${NC} Missing '${field}'"
            VALID=false
        fi
    done
    echo ""
done

if [ "$VALID" = true ]; then
    pass "All action.yml files have required fields"
else
    fail "Action metadata validation failed" "VALIDATE YAML"
fi

# ===========================================================================
# STAGE 5: CHECK DOCKER (Optional)
# ===========================================================================
# Check if Docker is available for the code-stats action.
# This stage is informational only -- it won't fail the pipeline.

stage_header "5/5 - CHECK DOCKER (Optional)"
echo "  Checking if Docker is available for the code-stats action..."
echo ""

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version 2>/dev/null)
    echo -e "    ${GREEN}✓${NC} Docker found: ${DOCKER_VERSION}"
    echo ""

    echo "  Attempting to build the code-stats Docker image..."
    if docker build -t code-stats-test actions/code-stats/ 2>&1; then
        echo ""
        pass "Docker image built successfully"

        echo ""
        echo "  Running code-stats container locally..."
        docker run --rm code-stats-test . "py,js,yml" 2>&1 || true
    else
        echo ""
        echo -e "  ${YELLOW}! Docker build failed (this is okay for local testing)${NC}"
    fi
else
    echo -e "  ${YELLOW}! Docker not found -- skipping Docker validation${NC}"
    echo -e "  ${YELLOW}  The code-stats action requires Docker and will only${NC}"
    echo -e "  ${YELLOW}  run on Linux GitHub Actions runners.${NC}"
    echo ""
    echo -e "  ${GREEN}✓${NC} Skipped (Docker not required for local testing)"
fi

# ===========================================================================
# PIPELINE COMPLETE
# ===========================================================================

PIPELINE_END=$(date +%s)
TOTAL_TIME=$((PIPELINE_END - PIPELINE_START))

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}║      ✓  CUSTOM ACTIONS LAB - ALL CHECKS PASSED!  ✓      ║${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Total time: ${TOTAL_TIME}s"
echo ""
echo -e "  ${BOLD}Pipeline Summary:${NC}"
echo -e "    ${GREEN}✓${NC} Action Files  - All 3 actions have required files"
echo -e "    ${GREEN}✓${NC} Dependencies  - Python packages installed"
echo -e "    ${GREEN}✓${NC} Unit Tests    - All utility functions working"
echo -e "    ${GREEN}✓${NC} Action YAML   - All action.yml files valid"
echo -e "    ${GREEN}✓${NC} Docker        - Checked (or skipped if unavailable)"
echo ""
echo -e "  ${BOLD}Next Steps:${NC}"
echo -e "    Push to GitHub and create a PR to test the actions live!"
echo ""

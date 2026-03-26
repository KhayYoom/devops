#!/bin/bash
# =============================================================================
#  CODE STATISTICS - Entrypoint Script
# =============================================================================
#
#  This script is the heart of the Docker action. It:
#    1. Receives inputs as command-line arguments ($1, $2, etc.)
#    2. Scans the repository for files matching given extensions
#    3. Counts files and lines of code per extension
#    4. Outputs a formatted report
#    5. Sets GitHub Actions outputs via $GITHUB_OUTPUT
#
#  HOW INPUTS ARRIVE:
#    In action.yml, we defined:
#      args:
#        - ${{ inputs.directory }}
#        - ${{ inputs.extensions }}
#    So $1 = directory, $2 = extensions (comma-separated)
#
#  HOW OUTPUTS WORK:
#    In a shell script, you set outputs by writing to $GITHUB_OUTPUT:
#      echo "output-name=value" >> $GITHUB_OUTPUT
#    For multi-line outputs, use a heredoc delimiter:
#      echo "report<<EOF" >> $GITHUB_OUTPUT
#      echo "line 1"      >> $GITHUB_OUTPUT
#      echo "EOF"         >> $GITHUB_OUTPUT
#

# Parse inputs (with defaults)
DIRECTORY="${1:-.}"
EXTENSIONS="${2:-py,js,ts,yml,yaml}"

echo "============================================"
echo "  CODE STATISTICS REPORT"
echo "============================================"
echo ""
echo "Directory: $DIRECTORY"
echo "Extensions: $EXTENSIONS"
echo ""

# Initialize counters
TOTAL_FILES=0
TOTAL_LINES=0
REPORT=""

# Split the comma-separated extensions and process each one
IFS=',' read -ra EXTS <<< "$EXTENSIONS"
for ext in "${EXTS[@]}"; do
    # Trim whitespace from extension
    ext=$(echo "$ext" | xargs)

    # Count files with this extension
    # Exclude common non-source directories: node_modules, .git, __pycache__
    FILES=$(find "$DIRECTORY" -name "*.${ext}" \
        -not -path "*/node_modules/*" \
        -not -path "*/.git/*" \
        -not -path "*/__pycache__/*" | wc -l)

    # Count lines only if there are files to count
    if [ "$FILES" -gt 0 ]; then
        LINES=$(find "$DIRECTORY" -name "*.${ext}" \
            -not -path "*/node_modules/*" \
            -not -path "*/.git/*" \
            -not -path "*/__pycache__/*" \
            -exec cat {} + 2>/dev/null | wc -l)
    else
        LINES=0
    fi

    # Accumulate totals
    TOTAL_FILES=$((TOTAL_FILES + FILES))
    TOTAL_LINES=$((TOTAL_LINES + LINES))

    # Build report line
    LINE="  .${ext}: ${FILES} files, ${LINES} lines"
    REPORT="${REPORT}${LINE}\n"
    echo "$LINE"
done

echo ""
echo "────────────────────────────────────────────"
echo "  TOTAL: ${TOTAL_FILES} files, ${TOTAL_LINES} lines"
echo "────────────────────────────────────────────"

# ==========================================================================
# SET GITHUB ACTIONS OUTPUTS
# ==========================================================================
# These outputs can be referenced by subsequent steps in the workflow:
#   ${{ steps.<step-id>.outputs.total-files }}
#   ${{ steps.<step-id>.outputs.total-lines }}
#   ${{ steps.<step-id>.outputs.report }}

echo "total-files=${TOTAL_FILES}" >> $GITHUB_OUTPUT
echo "total-lines=${TOTAL_LINES}" >> $GITHUB_OUTPUT

# Multi-line output uses a heredoc-style delimiter
# The format is:  output-name<<DELIMITER
#                 line 1
#                 line 2
#                 DELIMITER
{
  echo "report<<EOF"
  echo -e "$REPORT"
  echo "TOTAL: ${TOTAL_FILES} files, ${TOTAL_LINES} lines"
  echo "EOF"
} >> $GITHUB_OUTPUT

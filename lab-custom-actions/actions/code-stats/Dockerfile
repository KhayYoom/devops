# =============================================================================
#  CODE STATISTICS - Docker Action
# =============================================================================
#
#  This Dockerfile defines the environment for the Code Statistics action.
#
#  HOW DOCKER ACTIONS WORK:
#    1. GitHub Actions builds this Dockerfile on the runner
#    2. It runs the container with the entrypoint script
#    3. Inputs are passed as command-line arguments (defined in action.yml args)
#    4. The workspace is mounted into the container at /github/workspace
#    5. GITHUB_OUTPUT file is available for setting outputs
#
#  WHY ALPINE?
#    Alpine Linux is tiny (~5MB) which means fast builds.
#    We only need bash, find, and wc -- all available via apk.
#
#  IMPORTANT: Docker actions ONLY run on Linux runners!
#    - runs-on: ubuntu-latest  --> WORKS
#    - runs-on: windows-latest --> FAILS
#    - runs-on: macos-latest   --> FAILS
#

FROM alpine:3.19

# Install required tools:
#   bash      - Shell for the entrypoint script
#   findutils - GNU find (more features than BusyBox find)
#   coreutils - GNU core utilities (wc, cat, etc.)
RUN apk add --no-cache bash findutils coreutils

# Copy the entrypoint script into the container
COPY entrypoint.sh /entrypoint.sh

# Make it executable
RUN chmod +x /entrypoint.sh

# Set the entrypoint -- this runs when the container starts
ENTRYPOINT ["/entrypoint.sh"]

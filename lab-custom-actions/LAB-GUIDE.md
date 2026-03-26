# Custom Actions Lab - Hands-On Guide

## What You'll Learn

By completing this lab, you will understand:
- The three types of GitHub Actions: JavaScript, Docker, and Composite
- How to author action.yml metadata files with inputs, outputs, and branding
- How to use the GitHub Actions Toolkit (@actions/core, @actions/github)
- How to build Docker-based actions with shell scripts
- How to create composite actions that bundle multiple steps
- How to version and distribute custom actions

---

## Prerequisites

- Completed previous labs (lab-pipeline, lab-actions-basics, lab-workflow-logic)
- Node.js 20+ (for JS action)
- Docker Desktop (for Docker action -- optional for local testing)
- Python 3.12+
- Estimated time: **2 hours**

```bash
# Check your tools
node --version     # Should be v20+
python --version   # Should be 3.12+
docker --version   # Optional, needed for Docker action
```

---

## Project Structure

```
lab-custom-actions/
│
├── actions/                              THE THREE CUSTOM ACTIONS
│   │
│   ├── pr-comment/                       ACTION 1: JavaScript (Node.js)
│   │   ├── action.yml                    Action metadata (inputs, outputs, branding)
│   │   ├── index.js                      Action logic (uses @actions/core + github)
│   │   └── package.json                  Node.js dependencies
│   │
│   ├── code-stats/                       ACTION 2: Docker (Alpine + Bash)
│   │   ├── action.yml                    Action metadata
│   │   ├── Dockerfile                    Container definition
│   │   └── entrypoint.sh                 Shell script (runs inside container)
│   │
│   └── setup-and-test/                   ACTION 3: Composite (YAML only)
│       └── action.yml                    Bundled steps (setup python, install, test)
│
├── app/                                  SAMPLE APPLICATION
│   ├── __init__.py
│   └── utils.py                          Utility functions (for testing)
│
├── tests/                                TESTS (run by composite action)
│   └── unit/
│       └── test_utils.py                 Unit tests for utils.py
│
├── .github/workflows/                    WORKFLOW FILES
│   ├── lab9-test-js-action.yml           Tests the JS action on PRs
│   ├── lab9-test-docker-action.yml       Tests the Docker action on push
│   ├── lab9-test-composite-action.yml    Tests the composite action
│   └── lab9-all-actions.yml              Combined workflow (all 3 actions)
│
├── scripts/                              LOCAL PIPELINE RUNNERS
│   ├── run-pipeline.sh                   Local pipeline (Linux/WSL/Mac)
│   └── run-pipeline.bat                  Local pipeline (Windows CMD)
│
├── requirements.txt                      Python dependencies (pytest)
├── pytest.ini                            Test configuration
├── .gitignore                            Files to exclude from git
└── LAB-GUIDE.md                          This file!
```

---

## Understanding the Three Action Types

| Type | Runs On | Best For | Entry Point |
|------|---------|----------|-------------|
| **JavaScript** | Any OS (Linux, Windows, macOS) | Cross-platform tools, API calls, fast startup | `node20` + `index.js` |
| **Docker** | Linux only | Controlled environment, any language, system tools | `Dockerfile` + `entrypoint.sh` |
| **Composite** | Any OS | Bundling steps, no code needed, reusing other actions | Steps defined in `action.yml` |

### When to Use Each Type

```
Need cross-platform support?
  YES --> JavaScript or Composite
  NO  --> Docker is fine

Need a controlled environment (specific OS packages, tools)?
  YES --> Docker
  NO  --> JavaScript or Composite

Just bundling existing steps (no custom code)?
  YES --> Composite
  NO  --> JavaScript or Docker

Need to call GitHub APIs?
  YES --> JavaScript (best toolkit support)
  NO  --> Any type works
```

---

## Lab 9A: JavaScript Action -- PR Comment Bot (30-40 min)

### Objective

Build a JavaScript action that posts formatted comments on pull requests with build information.

### Background: The GitHub Actions Toolkit

JavaScript actions use the **Actions Toolkit** -- a set of npm packages that provide helpers for common tasks:

**@actions/core** -- The essential package:
```javascript
const core = require("@actions/core");

core.getInput("name");          // Read an input from action.yml
core.setOutput("key", "value"); // Set an output for downstream steps
core.setFailed("message");      // Mark the action as failed (clean exit)
core.info("message");           // Log an info message
core.warning("message");        // Log a warning (yellow annotation)
core.error("message");          // Log an error (red annotation)
```

**@actions/github** -- GitHub API access:
```javascript
const github = require("@actions/github");

const octokit = github.getOctokit(token);  // Authenticated API client
const context = github.context;             // Workflow run context

// Context provides:
context.repo          // { owner: "...", repo: "..." }
context.sha           // Current commit SHA
context.actor         // User who triggered the workflow
context.payload       // Full webhook event payload
context.payload.pull_request?.number  // PR number (if PR event)
```

**action.yml metadata** -- Every action needs this file:
```yaml
name: "My Action"           # Display name
description: "What it does" # Shown in marketplace
inputs:                      # What users pass in
  my-input:
    description: "..."
    required: true
outputs:                     # What the action returns
  my-output:
    description: "..."
runs:
  using: "node20"            # Runtime (node20 for JS actions)
  main: "index.js"           # Entry point
branding:                    # Icon in GitHub Marketplace
  icon: "check"
  color: "green"
```

### Instructions

**Step 1: Examine the action metadata**

Open `actions/pr-comment/action.yml` and note:
- Three inputs: `message` (required), `include-build-info`, `emoji`
- Two outputs: `comment-id`, `comment-url`
- Runtime: `node20` with entry point `index.js`
- Branding: message-circle icon, blue color

**Step 2: Examine the JavaScript code**

Open `actions/pr-comment/index.js` and trace the flow:
1. Read inputs with `core.getInput()`
2. Get the authenticated Octokit client
3. Find the PR number from `context.payload`
4. Build a Markdown comment body with emoji and build info
5. Post via `octokit.rest.issues.createComment()`
6. Set outputs with `core.setOutput()`
7. Handle errors with `core.setFailed()`

**Step 3: Understand the dependencies**

Open `actions/pr-comment/package.json`:
- `@actions/core` and `@actions/github` are the only runtime deps
- `@vercel/ncc` is a dev dependency for compilation (explained below)

**Step 4: Push and test on a PR**

```bash
# Push your code to GitHub
git add .
git commit -m "feat: add custom actions lab"
git push

# Create a pull request
gh pr create --title "Test custom actions" --body "Testing the PR comment bot"

# Go to the PR -- you should see a comment posted by the action!
```

**Step 5: Try different emoji inputs**

Edit `.github/workflows/lab9-test-js-action.yml` and change the emoji:
- `rocket` -- Rocket emoji
- `check` -- Green checkmark
- `warning` -- Warning triangle
- `info` -- Info circle

**Step 6: Check the outputs**

In the workflow log, look for the "Show Comment Details" step. It displays:
- `comment-id` -- The numeric ID of the posted comment
- `comment-url` -- Direct link to the comment

### How NCC Compilation Works

In a real published action, runners do NOT run `npm install`. They expect
all code to be in a single file. That is where `@vercel/ncc` comes in:

```bash
# Compile index.js + all node_modules into a single dist/index.js
npx ncc build index.js -o dist

# Then change action.yml:
#   main: "index.js"  -->  main: "dist/index.js"

# Commit dist/index.js to the repo (yes, compiled code gets committed!)
```

**Why we skip this in the lab:**
- It adds complexity that distracts from learning
- Instead, we run `npm install` in the workflow before using the action
- In production, you would ALWAYS compile with ncc

### Checkpoint Questions

1. **Why do we need to compile JS actions with ncc?**
   Because GitHub Actions runners don't run `npm install` -- they expect a
   self-contained script. `ncc` bundles everything into one file.

2. **What does `core.setFailed()` do vs throwing an error?**
   `setFailed()` cleanly marks the step as failed with a descriptive message.
   Throwing an error crashes the process with an ugly stack trace.

3. **How does the action access the PR number?**
   Through `github.context.payload.pull_request.number`. This is populated
   from the webhook event payload that triggered the workflow.

### Break It!

Try these experiments to deepen your understanding:

1. **Don't install node_modules** -- Remove the "Install Action Dependencies"
   step from the workflow. What error do you see?
   > Expected: `Cannot find module '@actions/core'`

2. **Remove GITHUB_TOKEN** -- Delete the `env: GITHUB_TOKEN` line.
   What happens?
   > Expected: "GITHUB_TOKEN is not set" error from setFailed()

3. **Use on a push event** -- Trigger the action on `push` instead of
   `pull_request`. Does the warning appear?
   > Expected: "This action only works on pull_request events" warning

---

## Lab 9B: Docker Action -- Code Statistics (25-35 min)

### Objective

Build a Docker action that analyzes a repository and reports code statistics (file counts and line counts per file extension).

### Background: How Docker Actions Work

Docker actions run inside a container. GitHub Actions handles the lifecycle:

```
1. GitHub reads action.yml
2. Sees: using: "docker", image: "Dockerfile"
3. Builds the Docker image from the Dockerfile
4. Runs the container with:
   - Workspace mounted at /github/workspace
   - Inputs passed as command-line args (from action.yml "args")
   - GITHUB_OUTPUT file path set as env variable
5. Container runs entrypoint.sh
6. Entrypoint writes outputs to $GITHUB_OUTPUT
7. Container exits, GitHub reads the outputs
```

**Key files in a Docker action:**

```
action.yml        - Metadata (same as JS, but runs.using: "docker")
Dockerfile        - Defines the container environment
entrypoint.sh     - The script that runs inside the container
```

**How inputs are passed:**
```yaml
# In action.yml:
args:
  - ${{ inputs.directory }}    # Becomes $1 in entrypoint.sh
  - ${{ inputs.extensions }}   # Becomes $2 in entrypoint.sh
```

**How outputs are set (shell scripts):**
```bash
# Simple output
echo "my-output=value" >> $GITHUB_OUTPUT

# Multi-line output (heredoc delimiter)
echo "report<<EOF"     >> $GITHUB_OUTPUT
echo "line 1"          >> $GITHUB_OUTPUT
echo "line 2"          >> $GITHUB_OUTPUT
echo "EOF"             >> $GITHUB_OUTPUT
```

**IMPORTANT:** Docker actions only run on **Linux** runners!

### Instructions

**Step 1: Examine the files**

Open and read all three files:
- `actions/code-stats/action.yml` -- Inputs (directory, extensions), outputs (total-files, total-lines, report)
- `actions/code-stats/Dockerfile` -- Alpine Linux with bash, findutils, coreutils
- `actions/code-stats/entrypoint.sh` -- Shell script that counts files and lines

**Step 2: Understand the entrypoint logic**

The script:
1. Reads `$1` (directory) and `$2` (extensions) from command-line args
2. Splits extensions by comma
3. For each extension, uses `find` to count files and `wc -l` to count lines
4. Prints a formatted report
5. Writes outputs to `$GITHUB_OUTPUT`

**Step 3: Push and trigger the workflow**

```bash
git add .
git commit -m "feat: add code-stats Docker action"
git push
# The workflow triggers on push automatically
```

**Step 4: Check the outputs**

Go to Actions tab > "Lab 9B - Test Docker Action" > latest run.
Look at the "Show Default Stats" step for file/line counts.

**Step 5: Try different extensions**

Edit `.github/workflows/lab9-test-docker-action.yml`:
```yaml
with:
  extensions: "md,txt,json"   # Different extensions
```

**Step 6: Try a different directory**

```yaml
with:
  directory: "actions/"       # Only scan the actions folder
```

### Checkpoint Questions

1. **Why can't Docker actions run on Windows/macOS runners?**
   Docker actions use Linux containers. Windows and macOS runners don't
   have a compatible Docker daemon for running Linux containers natively.

2. **How does the entrypoint receive inputs?**
   Through command-line arguments (`$1`, `$2`, etc.). The `args:` section
   in action.yml maps inputs to positional parameters.

3. **How do you set outputs from a shell script?**
   By writing `key=value` to the file at `$GITHUB_OUTPUT`.
   For multi-line values, use a heredoc delimiter (EOF).

### Break It!

1. **Try `runs-on: windows-latest`** -- What error do you see?
   > Expected: Docker actions are not supported on Windows runners.

2. **Remove `chmod +x` from Dockerfile** -- What happens?
   > Expected: Permission denied when trying to execute entrypoint.sh.

3. **Pass a nonexistent directory** -- Set `directory: "/nonexistent"`.
   > Expected: find reports 0 files for all extensions.

---

## Lab 9C: Composite Action -- Setup & Test (20-30 min)

### Objective

Bundle multiple steps (Python setup, dependency install, test run) into a single reusable composite action.

### Background: How Composite Actions Work

Composite actions are the simplest type -- they're just YAML, no code required:

```yaml
runs:
  using: "composite"     # <-- This makes it composite
  steps:
    - name: Step 1
      uses: some/action@v1    # Can use other actions!
      with:
        input: value

    - name: Step 2
      shell: bash             # MUST specify shell for run: steps!
      run: |
        echo "Hello from composite action"
```

**Key differences from regular workflows:**

| Feature | Regular Workflow | Composite Action |
|---------|-----------------|------------------|
| `shell:` on `run:` steps | Optional (defaults to bash) | **REQUIRED** |
| Can use `uses:` | Yes | Yes |
| Output definition | Just `description:` | `value:` expression required |
| `secrets` context | Available | **NOT available** (pass as inputs) |

**Output definitions are different:**
```yaml
# In a regular workflow step:
outputs:
  my-output:
    description: "Some output"

# In a composite action:
outputs:
  my-output:
    description: "Some output"
    value: ${{ steps.my-step.outputs.result }}   # MUST specify value!
```

### Instructions

**Step 1: Examine the composite action**

Open `actions/setup-and-test/action.yml` and note:
- It uses `actions/setup-python@v5` (a published action) inside itself
- Every `run:` step has `shell: bash`
- Outputs use `value:` to reference step outputs

**Step 2: Trace the three internal steps**

1. **Setup Python** -- Uses `actions/setup-python@v5` with the requested version
2. **Install Dependencies** -- Runs the user's install command (default: `pip install -r requirements.txt`)
3. **Run Tests** -- Runs pytest, captures output, sets the summary output

**Step 3: Push and trigger the workflow**

```bash
git add .
git commit -m "feat: add composite setup-and-test action"
git push
```

**Step 4: Check the outputs**

Go to Actions tab > "Lab 9C - Test Composite Action" > latest run.
Look for `test-result` (success/failure) and `test-output` (pytest summary).

**Step 5: Try a different Python version**

The workflow already has a second job testing Python 3.11. Check both jobs
pass -- this proves the action is truly reusable!

### Checkpoint Questions

1. **Why must you specify `shell: bash` in composite actions?**
   Composite actions don't have a default shell. Each `run:` step must
   explicitly declare which shell to use, or GitHub rejects the YAML.

2. **Can composite actions use other actions (`uses:`)?**
   Yes! This is one of their biggest advantages. You can bundle multiple
   published actions (like setup-python, setup-node) into one reusable action.

3. **How are outputs defined differently in composite actions?**
   Composite action outputs require a `value:` field that maps to a step
   output (e.g., `${{ steps.run-tests.outcome }}`). Regular workflow outputs
   only need a `description:`.

### Break It!

1. **Remove `shell: bash`** from one of the `run:` steps.
   > Expected: GitHub rejects the workflow with a validation error.

2. **Use a nonexistent Python version** -- Set `python-version: "2.5"`.
   > Expected: setup-python fails because Python 2.5 is not available.

3. **Point `test-path` to a nonexistent directory** -- Set `test-path: "nonexistent/"`.
   > Expected: pytest fails with "no tests ran" or "directory not found".

---

## Lab 9D: Versioning & Publishing (15-20 min)

### Objective

Learn how to version and tag custom actions for distribution, so other repositories can reference them.

### Background: How Action Versioning Works

When you reference an action, you specify a version:
```yaml
uses: actions/checkout@v4          # Major version tag
uses: actions/checkout@v4.1.7      # Exact version tag
uses: actions/checkout@abc123def   # Commit SHA (most secure)
```

**Semantic Versioning (SemVer):**
```
v1.0.0  -->  MAJOR.MINOR.PATCH
  │            │     │     │
  │            │     │     └── Bug fixes (backward compatible)
  │            │     └──────── New features (backward compatible)
  │            └────────────── Breaking changes
  └─────────────────────────── The "v" prefix is convention
```

**The Major Version Tag Pattern:**

Most actions maintain a "floating" major version tag (like `v1`) that always
points to the latest `v1.x.x` release:

```bash
# Release v1.0.0
git tag -a v1.0.0 -m "Release v1.0.0"
git tag -fa v1 -m "Update v1 tag"    # v1 -> v1.0.0
git push origin v1.0.0 v1

# Later, release v1.1.0
git tag -a v1.1.0 -m "Release v1.1.0"
git tag -fa v1 -m "Update v1 tag"    # v1 -> v1.1.0 now
git push origin v1.1.0
git push origin v1 --force           # Move the floating tag
```

Users who reference `@v1` automatically get the latest v1.x.x release
without changing their workflow files.

### Instructions

**Step 1: Create a version tag**

```bash
# Tag the current commit as v1.0.0
git tag -a v1.0.0 -m "Release v1.0.0 - Initial custom actions"
git push origin v1.0.0
```

**Step 2: Create a major version tag**

```bash
# Create a floating v1 tag pointing to the same commit
git tag -fa v1 -m "Update v1 tag to v1.0.0"
git push origin v1 --force
```

**Step 3: Reference your actions from another repo**

In another repository's workflow, you can now use:
```yaml
# Reference by major version (recommended)
- uses: your-username/your-repo/actions/pr-comment@v1

# Reference by exact version (precise)
- uses: your-username/your-repo/actions/pr-comment@v1.0.0

# Reference by commit SHA (most secure)
- uses: your-username/your-repo/actions/pr-comment@abc123
```

**Step 4: Simulate a minor release**

Make a small change (e.g., add a new emoji to the map in index.js):
```bash
# Commit the change
git add .
git commit -m "feat: add new emoji option"

# Tag as v1.1.0
git tag -a v1.1.0 -m "Release v1.1.0 - New emoji"
git push origin v1.1.0

# Move the v1 tag forward
git tag -fa v1 -m "Update v1 tag to v1.1.0"
git push origin v1 --force
```

Now anyone using `@v1` automatically gets the new emoji!

### Versioning Best Practices

```
DO:
  - Use semantic versioning (v1.0.0, v1.1.0, v2.0.0)
  - Maintain major version tags (v1, v2) for easy upgrades
  - Write release notes explaining changes
  - Test thoroughly before tagging a release

DON'T:
  - Make breaking changes in minor/patch releases
  - Delete old version tags (people may be using them)
  - Skip testing before releasing
  - Forget to update the major version tag

SECURITY:
  - For maximum security, pin to a commit SHA:
    uses: actions/checkout@abc123def456
  - This prevents supply chain attacks (tag can be moved, SHA cannot)
  - Use Dependabot to auto-update SHA references
```

---

## Lab 9E: Run Locally (5-10 min)

### Step 1: Navigate to the lab folder

```bash
cd 03-cicd/lab-custom-actions
```

### Step 2: Run the local pipeline

**On Windows CMD:**
```cmd
scripts\run-pipeline.bat
```

**On WSL/Git Bash/Linux:**
```bash
chmod +x scripts/run-pipeline.sh
./scripts/run-pipeline.sh
```

### What You Should See

```
  STAGE 1/5 - VERIFY FILES    [PASSED] All action files present
  STAGE 2/5 - INSTALL DEPS    [PASSED] Python dependencies installed
  STAGE 3/5 - UNIT TESTS      [PASSED] All utility functions working
  STAGE 4/5 - VALIDATE YAML   [PASSED] All action.yml files valid
  STAGE 5/5 - DOCKER CHECK    [PASSED] (or skipped if no Docker)

  CUSTOM ACTIONS LAB - ALL CHECKS PASSED!
```

### Step 3: Run tests directly

```bash
# Run all tests
python -m pytest -v

# Run with detailed output
python -m pytest -v -s --tb=long

# Run a specific test class
python -m pytest -v -k "TestWordCount"
```

---

## Lab 9F: The Combined Workflow (10-15 min)

### Objective

See all three action types working together in a single pipeline.

### How It Works

Open `.github/workflows/lab9-all-actions.yml` and examine the three jobs:

```
┌──────────────┐     ┌──────────────┐
│  code-stats  │     │    test      │
│  (Docker)    │     │ (Composite)  │
└──────┬───────┘     └──────┬───────┘
       │                    │
       └────────┬───────────┘
                │
         ┌──────▼───────┐
         │   comment    │  (only on PRs)
         │    (JS)      │
         └──────────────┘
```

- **Job 1 (code-stats):** Runs the Docker action to count files and lines
- **Job 2 (test):** Runs the composite action to setup Python and run tests
- **Job 3 (comment):** Runs the JS action to post results on the PR
  - Only runs on `pull_request` events
  - Depends on both Job 1 and Job 2 (`needs: [code-stats, test]`)
  - Passes outputs from Job 1 into the comment message

### Try It

1. Push to GitHub
2. Create a PR
3. Watch all three jobs run
4. Check the PR for the posted comment with file stats!

---

## Key Takeaways

```
1. THREE ACTION TYPES:
   - JavaScript: Cross-platform, best for API calls, needs ncc compilation
   - Docker:     Linux-only, controlled environment, any language
   - Composite:  Any OS, bundles steps, no code needed

2. ACTION METADATA (action.yml):
   - Every action needs name, description, and runs
   - Inputs define what users pass in (with defaults)
   - Outputs define what the action returns

3. JAVASCRIPT ACTIONS:
   - Use @actions/core for inputs/outputs/logging
   - Use @actions/github for API access
   - Compile with @vercel/ncc for distribution
   - Handle errors with core.setFailed()

4. DOCKER ACTIONS:
   - Only run on Linux runners
   - Inputs passed as args ($1, $2, etc.)
   - Outputs written to $GITHUB_OUTPUT
   - Full control over the runtime environment

5. COMPOSITE ACTIONS:
   - Just YAML, no code needed
   - MUST specify shell: for every run: step
   - CAN use other actions inside them
   - Outputs require value: (not just description:)

6. VERSIONING:
   - Use semantic versioning (v1.0.0)
   - Maintain floating major version tags (v1)
   - Pin to SHA for maximum security
```

---

## Quick Reference

```bash
# Run the local pipeline
scripts\run-pipeline.bat          # Windows
./scripts/run-pipeline.sh         # Linux/Mac/WSL

# Run tests directly
python -m pytest -v               # All tests
python -m pytest -v -k "TestWordCount"  # Specific class

# Install JS action dependencies
cd actions/pr-comment && npm install

# Compile JS action (production)
cd actions/pr-comment && npx ncc build index.js -o dist

# Build Docker action locally
docker build -t code-stats-test actions/code-stats/

# Run Docker action locally
docker run --rm code-stats-test . "py,js,yml"

# Create version tags
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# Move major version tag
git tag -fa v1 -m "Update v1 tag"
git push origin v1 --force
```

---

## What's Next?

Continue to the next lab: **lab-self-hosted-runner** -- Learn how to set up and configure self-hosted GitHub Actions runners for custom environments.

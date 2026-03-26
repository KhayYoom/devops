/**
 * PR Comment Bot - A JavaScript GitHub Action
 * =============================================
 *
 * This action posts a formatted comment on pull requests with optional
 * build information. It demonstrates how to build a JavaScript action
 * using the GitHub Actions Toolkit.
 *
 * KEY CONCEPTS:
 *   - @actions/core:   Read inputs, set outputs, log messages, handle errors
 *   - @actions/github: Access the GitHub API via an authenticated Octokit client
 *   - context:         Provides information about the workflow run (repo, PR, etc.)
 *
 * HOW IT WORKS:
 *   1. Reads inputs from action.yml (message, emoji, include-build-info)
 *   2. Builds a formatted Markdown comment body
 *   3. Posts the comment on the PR using the GitHub API
 *   4. Sets outputs (comment-id, comment-url) for downstream steps
 *
 * IN PRODUCTION:
 *   Compile with: npx ncc build index.js -o dist
 *   Then change action.yml to: main: "dist/index.js"
 *   This bundles all node_modules into a single file so runners don't
 *   need to run `npm install`. For this lab, we skip compilation and
 *   install dependencies directly.
 */

const core = require("@actions/core");
const github = require("@actions/github");

// ==========================================================================
// EMOJI MAP
// ==========================================================================
// Maps friendly emoji names to actual Unicode emoji characters.
// Users pass "rocket" in their workflow, and we convert it here.

const EMOJI_MAP = {
  rocket: "\u{1F680}",
  check: "\u2705",
  warning: "\u26A0\uFE0F",
  info: "\u2139\uFE0F",
};

// ==========================================================================
// BUILD INFO TABLE
// ==========================================================================
// Generates a Markdown table with useful build metadata.
// This shows students how to access GitHub Actions context variables.

function buildInfoTable(context) {
  const { repo, sha, workflow, runNumber, runId, actor } = context;

  return `
### Build Information

| Field | Value |
|-------|-------|
| **Repository** | \`${repo.owner}/${repo.repo}\` |
| **Commit SHA** | \`${sha.substring(0, 7)}\` |
| **Workflow** | \`${workflow}\` |
| **Run** | #${runNumber} ([view](https://github.com/${repo.owner}/${repo.repo}/actions/runs/${runId})) |
| **Triggered by** | @${actor} |
| **Timestamp** | ${new Date().toISOString()} |
`;
}

// ==========================================================================
// MAIN FUNCTION
// ==========================================================================
// This is the entry point for the action. It runs when the action is called.

async function run() {
  try {
    // ------------------------------------------------------------------
    // Step 1: Read inputs from action.yml
    // ------------------------------------------------------------------
    // core.getInput() reads values defined in the "inputs" section of
    // action.yml. The "required: true" check is handled automatically --
    // if a required input is missing, the action fails before we get here.

    const message = core.getInput("message", { required: true });
    const includeBuildInfo = core.getInput("include-build-info") === "true";
    const emojiName = core.getInput("emoji") || "rocket";

    // Log what we received (visible in the Actions log)
    core.info(`Message: ${message}`);
    core.info(`Include build info: ${includeBuildInfo}`);
    core.info(`Emoji: ${emojiName}`);

    // ------------------------------------------------------------------
    // Step 2: Get the GitHub context and token
    // ------------------------------------------------------------------
    // The GITHUB_TOKEN is automatically provided by GitHub Actions.
    // It allows us to make API calls (like posting comments) on behalf
    // of the workflow. No need to create a personal access token!

    const token = process.env.GITHUB_TOKEN;
    if (!token) {
      core.setFailed(
        "GITHUB_TOKEN is not set. Add 'env: GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}' to your workflow step."
      );
      return;
    }

    const octokit = github.getOctokit(token);
    const context = github.context;

    // ------------------------------------------------------------------
    // Step 3: Determine the Pull Request number
    // ------------------------------------------------------------------
    // The PR number comes from the event payload. If this action is
    // triggered on a non-PR event (like push), we warn and exit.

    const prNumber = context.payload.pull_request?.number;

    if (!prNumber) {
      core.warning(
        "This action only works on pull_request events. " +
          "No PR number found in the event payload. Skipping comment."
      );
      return;
    }

    core.info(`Posting comment on PR #${prNumber}`);

    // ------------------------------------------------------------------
    // Step 4: Build the comment body
    // ------------------------------------------------------------------
    // We construct a Markdown-formatted comment with:
    //   - An emoji prefix
    //   - The user's message
    //   - (Optionally) a build info table

    const emoji = EMOJI_MAP[emojiName] || EMOJI_MAP["rocket"];

    let body = `## ${emoji} ${message}\n\n`;
    body += `---\n\n`;

    if (includeBuildInfo) {
      body += buildInfoTable({
        repo: context.repo,
        sha: context.sha,
        workflow: context.workflow,
        runNumber: context.runNumber,
        runId: context.runId,
        actor: context.actor,
      });
    }

    body += `\n\n*Posted by [PR Comment Bot](https://github.com/features/actions) action*`;

    // ------------------------------------------------------------------
    // Step 5: Post the comment on the PR
    // ------------------------------------------------------------------
    // We use the Issues API (not the PR API) because in GitHub's data
    // model, PRs are a type of issue. The createComment endpoint works
    // for both issues and pull requests.

    const response = await octokit.rest.issues.createComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: prNumber,
      body: body,
    });

    core.info(`Comment posted successfully!`);
    core.info(`Comment ID: ${response.data.id}`);
    core.info(`Comment URL: ${response.data.html_url}`);

    // ------------------------------------------------------------------
    // Step 6: Set outputs for downstream steps
    // ------------------------------------------------------------------
    // Other steps in the workflow can access these outputs using:
    //   ${{ steps.<step-id>.outputs.comment-id }}
    //   ${{ steps.<step-id>.outputs.comment-url }}

    core.setOutput("comment-id", response.data.id.toString());
    core.setOutput("comment-url", response.data.html_url);
  } catch (error) {
    // ------------------------------------------------------------------
    // Error Handling
    // ------------------------------------------------------------------
    // core.setFailed() marks the action as failed AND logs the error.
    // This is different from throwing an error:
    //   - throw: Crashes the process, shows ugly stack trace
    //   - setFailed: Cleanly marks the step as failed with a message

    core.setFailed(`Action failed: ${error.message}`);
  }
}

// Run the action
run();

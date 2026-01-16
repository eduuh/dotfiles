Please analyze and fix the GitHub issue: $ARGUMENTS

Follow these steps:

1. **Get Issue Details**
   - Use `gh issue view $ARGUMENTS` to get the full issue details
   - Understand the problem, expected behavior, and any reproduction steps

2. **Analyze the Problem**
   - Search the codebase for relevant files mentioned in the issue
   - Identify the root cause of the bug or the location for the new feature
   - Check related code, tests, and documentation

3. **Implement the Fix**
   - Create a new branch: `git checkout -b fix/issue-$ARGUMENTS`
   - Make the necessary code changes to fix the issue
   - Keep changes minimal and focused on the issue

4. **Verify the Fix**
   - Write or update tests to cover the fix
   - Run the test suite to ensure nothing is broken
   - Run linting and type checking if applicable

5. **Commit and Push**
   - Stage the changes
   - Create a descriptive commit message referencing the issue:
     ```
     fix: <description of the fix>

     Fixes #$ARGUMENTS
     ```
   - Push the branch to origin

6. **Create Pull Request**
   - Use `gh pr create` to create a PR
   - Reference the issue in the PR description
   - Include a summary of changes and testing done

Remember:
- Use `gh` CLI for all GitHub operations
- Follow the project's coding standards
- Keep the fix focused and minimal

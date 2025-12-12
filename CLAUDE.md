## Explore agent
In plan mode, or any other mode, if you need, you can spin up one or multiple Explore agents to figure out things, and it is not restricted to 3 parallel agents only, you can kick up as many as you want if that help.

if you want to call the Explore agent, call the sonnet user agent, do not call the
built-in explore agent.

## Using the testing_and_debug Agent
When you need to run tests or fix failures/bugs:
1. Gather detailed information:
   - The test commands to run (if applicable)
   - The exact error message and stack trace (if failures exist)
   - The test file and test function name
   - The source file(s) being tested
   - What the test is trying to verify
   - Any relevant context about recent changes
2. Delegate to the testing_and_debug agent (subagent_type='testing_and_debug') with all this information
3. The testing_and_debug agent uses the inherit model (usually Opus) for higher reasoning capability
4. Wait for the testing_and_debug agent to report back with results/fixes

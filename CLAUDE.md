## Explore agent
if you want to call the Explore agent, call the sonnet user agent, do not call the
built-in explore agent.

## general-purpose agents
if you want to call the general-purpose agents, call the sonnet user agent, do not call the
built-in general-purpose agents.

## Using the Fixer Agent
When tests fail and need fixing:
1. Gather detailed information about the failure:
   - The exact error message and stack trace
   - The test file and test function name
   - The source file(s) being tested
   - What the test is trying to verify
   - Any relevant context about recent changes
2. Delegate to the Fixer agent (subagent_type='Fixer') with all this information
3. The Fixer agent uses the inherit model (usually Opus) for higher reasoning capability
4. Wait for the Fixer agent to report back with the fix

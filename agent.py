import os
import sys
import re
import asyncio
from google.adk.agents import Agent
from google.adk.models.lite_llm import LiteLlm
from google.adk.sessions import InMemorySessionService
from google.adk.runners import Runner
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters
from google.genai import types

# Configure local Ollama environment variables for LiteLLM wrapper.
# This ensures that LiteLLM directs all API calls to the local Ollama instance.
os.environ["OLLAMA_API_BASE"] = "http://localhost:11434"

async def main():
    # Step 1: Read the git diff file.
    # The agent expects a local 'git_diff.txt' to be present.
    diff_file_path = "git_diff.txt"
    if not os.path.exists(diff_file_path):
        print(f"Error: {diff_file_path} not found. Run setup.ps1 first.", file=sys.stderr)
        sys.exit(1)

    with open(diff_file_path, "r", encoding="utf-8") as f:
        git_diff = f.read()
    print(f"Loaded git diff:\n{git_diff}\n")

    # Step 2: Read the skill document instructions from SKILL.md.
    skill_file_path = "SKILL.md"
    if not os.path.exists(skill_file_path):
        print(f"Error: {skill_file_path} not found.", file=sys.stderr)
        sys.exit(1)

    with open(skill_file_path, "r", encoding="utf-8") as f:
        skill_instruction = f.read()

    # Step 3: Configure the MCP Toolset.
    # We spawn our local 'mcp_server.py' using the current Python executable.
    # Using sys.executable guarantees it executes in the same virtual environment.
    print("Initializing connection to Context 7 MCP Server...")
    mcp_toolset = McpToolset(
        connection_params=StdioConnectionParams(
            server_params=StdioServerParameters(
                command=sys.executable,
                args=["-u", "mcp_server.py"]
            ),
            timeout=30,
        )
    )

    # Step 4: Instantiate the ADK Agent.
    # We configure LiteLlm to point directly to the Ollama server for gemma4:12b.
    print("Configuring LLM agent (model: gemma4:12b)...")
    agent = Agent(
        name="git_commit_agent",
        model=LiteLlm(
            model="ollama_chat/gemma4:12b",
            api_base="http://localhost:11434"
        ),
        description="Generates git commit messages adhering to MCP-derived formatting rules.",
        instruction=skill_instruction,
        tools=[mcp_toolset]
    )

    # Step 5: Initialize the session service and runner.
    # InMemorySessionService manages conversation state in-memory.
    session_service = InMemorySessionService()
    session = await session_service.create_session(
        app_name="git_commit_agent_app",
        user_id="user_1"
    )

    runner = Runner(
        app_name="git_commit_agent_app",
        agent=agent,
        session_service=session_service
    )

    # Step 6: Invoke the agent with the user prompt.
    query = f"Generate a git commit message for the following diff:\n\n{git_diff}"
    print("Generating commit message...")
    
    content = types.Content(role="user", parts=[types.Part(text=query)])
    final_response_text = ""

    # Iterate through event stream returned by the runner.
    async for event in runner.run_async(
        user_id="user_1",
        session_id=session.id,
        new_message=content
    ):
        if event.is_final_response():
            if event.content and event.content.parts:
                final_response_text = event.content.parts[0].text
            break

    if not final_response_text:
        print("Error: Failed to generate a commit message from the model.", file=sys.stderr)
        sys.exit(1)

    # Clean up the output: strip Ollama stop-token artifacts and extract only
    # the conventional commit message line from potential chain-of-thought output.
    raw_output = final_response_text.strip()

    # Remove known Ollama/model stop-token artifacts that leak into text
    raw_output = re.sub(r'<(?:channel|end_of_turn|eos|\/s)\|?>', '', raw_output).strip()

    # Strip model-generated label prefixes (e.g. "Selected message: ", "Commit message: ")
    raw_output = re.sub(r'^(?:selected message|commit message|final commit|output)[:\s]+', '', raw_output, flags=re.IGNORECASE | re.MULTILINE)

    # Try to extract the commit message from within <commit_message> tags
    commit_pattern = re.compile(r'<commit_message>\s*(.*?)\s*</commit_message>', re.IGNORECASE | re.DOTALL)
    match = commit_pattern.search(raw_output)

    if match:
        # Use only the matched commit message line, stripping newlines just in case
        commit_msg = match.group(1).strip().splitlines()[0]
    else:
        # Fallback: use the last non-empty line of the output
        lines = [ln.strip() for ln in raw_output.splitlines() if ln.strip()]
        commit_msg = lines[-1] if lines else raw_output

    # Final safety pass: strip any remaining angle-bracket artifacts
    commit_msg = re.sub(r'<[^>]*\|?>', '', commit_msg).strip()

    print("\n================ Generated Commit Message ================")
    print(commit_msg)
    print("==========================================================\n")

    # Step 7: Security Gate - Human-in-the-Loop pause.
    # Requires explicit console authorization before proceeding.
    try:
        user_choice = input("[SECURITY GATE] Approve writing this commit? (Y/N): ").strip().upper()
    except KeyboardInterrupt:
        print("\nAborted by user signal. Exiting.")
        sys.exit(0)

    if user_choice == "Y":
        log_file_path = "commit_log.txt"
        with open(log_file_path, "a", encoding="utf-8") as log_file:
            log_file.write(f"{commit_msg}\n")
        print(f"Commit message written successfully to {log_file_path}")
        os._exit(0)  # Hard exit to bypass ADK async telemetry teardown errors
    else:
        print("Commit writing aborted by user. Exiting gracefully.")
        os._exit(0)

if __name__ == "__main__":
    # Start the async execution loop
    asyncio.run(main())
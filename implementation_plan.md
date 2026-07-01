# Git Commit Agent - Implementation Plan

The objective is to implement a local, lightweight "Git Commit Agent" running on Windows PowerShell that generates structured git commit messages from a local `git_diff.txt` file by querying formatting rules from a local MCP server named "Context 7" using Google's Agent Development Kit (ADK) and a local Ollama model (`gemma4:e4b`).

## Proposed Changes

We will create four primary files within the workspace directory:
1. `mcp_server.py` (Local MCP server named "Context 7" exposing formatting rules tool)
2. `SKILL.md` (Agent skill instruction for git commit generation)
3. `agent.py` (Main Python script coordinating MCP connections, reading input, calling Ollama, and gating write actions)
4. `setup.ps1` (PowerShell setup script for dependencies, virtual environment setup, and creating dummy files)

---

### Component 1: MCP Server

#### [NEW] [mcp_server.py](file:///a:/Google%20Drive%20CPG/VS%20Code%20-%20AI%20CLI%20projects/Intensive Vibe Coding Capstone Project-Git Commit Agent/Kaggle_Vibe_Capstone/mcp_server.py)
A lightweight MCP server built using FastMCP. It has one tool, `get_formatting_rules`, returning conventional commit rules:
- Rule 1: Use conventional commits (feat, fix, chore).
- Rule 2: Keep under 50 characters.

```python
from mcp.server.fastmcp import FastMCP

# Initialize FastMCP server with the name 'Context 7'
mcp = FastMCP("Context 7")

@mcp.tool()
def get_formatting_rules() -> str:
    """Retrieve the Git commit message formatting rules.
    
    Returns:
        str: Static formatting rules for Git commit messages.
    """
    return "Rule 1: Use conventional commits (feat, fix, chore). Rule 2: Keep under 50 characters."

if __name__ == "__main__":
    # Run the server on the stdio transport channel
    mcp.run(transport="stdio")
```

---

### Component 2: Agent Skill Definition

#### [NEW] [SKILL.md](file:///a:/Google%20Drive%20CPG/VS%20Code%20-%20AI%20CLI%20projects/Intensive Vibe Coding Capstone Project-Git Commit Agent/Kaggle_Vibe_Capstone/SKILL.md)
The system instructions and rules defining the git commit generator agent's role, input processing, and output constraint.

```markdown
---
name: Git-Commit-Agent-Skill
description: Instructs the agent to act as a senior developer, analyze a git diff, retrieve formatting rules from the MCP server, and generate a compliant commit message.
version: 1.0.0
---

# Git Commit Message Generation Skill

You are a senior software developer. Your task is to analyze a git diff, retrieve formatting rules from the Model Context Protocol (MCP) server, and write a high-quality, concise commit message.

## Instructions

1. **Analyze Input:**
   - Receive a git diff as input.
   - Understand the changes introduced by the diff (added, modified, or deleted lines).

2. **Retrieve Rules:**
   - Call the connected MCP server's tool `get_formatting_rules` to retrieve the current formatting rules.
   - Ensure you strictly adhere to these formatting rules in the generated commit message.

3. **Generate Commit Message:**
   - Write a commit message that fits the git diff and conforms to the retrieved rules.
   - Focus on clarity, conciseness, and accuracy.
   - Output **ONLY** the generated commit message. Do not include any prefix, suffix, quotes, markdown formatting, or conversational filler.
```

---

### Component 3: ADK Agent Engine

#### [NEW] [agent.py](file:///a:/Google%20Drive%20CPG/VS%20Code%20-%20AI%20CLI%20projects/Intensive Vibe Coding Capstone Project-Git Commit Agent/Kaggle_Vibe_Capstone/agent.py)
The core script that sets up environment variables, connects to the local MCP server via stdio, loads instructions from `SKILL.md`, reads `git_diff.txt`, executes the ADK Runner, prompts the user for approval via terminal input, and appends approved commits to `commit_log.txt`.

```python
import os
import sys
import asyncio
from google.adk.agents import Agent
from google.adk.models.lite_llm import LiteLlm
from google.adk.sessions import InMemorySessionService
from google.adk.runners import Runner
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters
from google.genai import types

# Configure local Ollama settings for LiteLLM
os.environ["OLLAMA_API_BASE"] = "http://localhost:11434"

async def main():
    # 1. Read git_diff.txt
    if not os.path.exists("git_diff.txt"):
        print("Error: git_diff.txt not found. Run setup.ps1 first.", file=sys.stderr)
        sys.exit(1)
        
    with open("git_diff.txt", "r", encoding="utf-8") as f:
        git_diff = f.read()

    # 2. Read instructions from SKILL.md
    if not os.path.exists("SKILL.md"):
        print("Error: SKILL.md not found.", file=sys.stderr)
        sys.exit(1)
        
    with open("SKILL.md", "r", encoding="utf-8") as f:
        skill_instruction = f.read()

    # 3. Configure the MCP Toolset to connect to our local server
    # We execute python in unbuffered mode (-u) to ensure stdio is flushed properly
    mcp_toolset = McpToolset(
        connection_params=StdioConnectionParams(
            server_params=StdioServerParameters(
                command="python",
                args=["-u", "mcp_server.py"]
            ),
            timeout=30,
        )
    )

    # 4. Instantiate the ADK Agent
    # We specify "ollama_chat/gemma4:e4b" as the model target and map it to localhost
    agent = Agent(
        name="git_commit_agent",
        model=LiteLlm(
            model="ollama_chat/gemma4:e4b",
            api_base="http://localhost:11434"
        ),
        description="Generates git commit messages adhering to MCP-derived formatting rules.",
        instruction=skill_instruction,
        tools=[mcp_toolset]
    )

    # 5. Initialize session and runner
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

    # 6. Execute the Agent
    query = f"Generate a git commit message for the following diff:\n\n{git_diff}"
    print("Connecting to MCP server and invoking Ollama model (gemma4:e4b)...")
    content = types.Content(role="user", parts=[types.Part(text=query)])
    
    final_response_text = ""
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
        print("Failed to generate a commit message.", file=sys.stderr)
        sys.exit(1)

    # Clean the response to ensure no extra whitespace
    commit_msg = final_response_text.strip()
    
    print("\n--- Generated Commit Message ---")
    print(commit_msg)
    print("--------------------------------\n")

    # 7. Security Gate: Human-in-the-Loop pause
    # Check approval status
    user_choice = input("[SECURITY GATE] Approve writing this commit? (Y/N): ").strip().upper()
    
    if user_choice == "Y":
        with open("commit_log.txt", "a", encoding="utf-8") as log_file:
            log_file.write(f"{commit_msg}\n")
        print("Commit message written successfully to commit_log.txt")
    else:
        print("Commit writing aborted by user. Exiting gracefully.")

if __name__ == "__main__":
    # Run the async loop using asyncio
    asyncio.run(main())
```

---

### Component 4: Setup Script

#### [NEW] [setup.ps1](file:///a:/Google%20Drive%20CPG/VS%20Code%20-%20AI%20CLI%20projects/Intensive Vibe Coding Capstone Project-Git Commit Agent/Kaggle_Vibe_Capstone/setup.ps1)
PowerShell script to:
1. Create a Python virtual environment (`.venv`).
2. Upgrade `pip`.
3. Install required packages: `mcp`, `google-adk`, `litellm`.
4. Create a dummy `git_diff.txt` with "added new print statement to main loop".
5. Output execution instructions for running the agent in Windows PowerShell.

```powershell
# Setup Script for Git Commit Agent in Windows PowerShell

Write-Host "Setting up Python virtual environment..." -ForegroundColor Cyan
python -m venv .venv

Write-Host "Activating virtual environment..." -ForegroundColor Cyan
.venv\Scripts\Activate.ps1

Write-Host "Upgrading pip..." -ForegroundColor Cyan
python -m pip install --upgrade pip

Write-Host "Installing dependencies (google-adk, mcp, litellm)..." -ForegroundColor Cyan
pip install google-adk mcp litellm

Write-Host "Creating dummy git_diff.txt..." -ForegroundColor Cyan
"added new print statement to main loop" | Out-File -FilePath git_diff.txt -Encoding utf8

Write-Host "Setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "To run the agent:" -ForegroundColor Yellow
Write-Host "1. Ensure Ollama is running with: ollama run gemma4:e4b"
Write-Host "2. Run: python agent.py"
```

---

## Verification Plan

### Automated/Manual Verification Steps
1. Execute the `setup.ps1` script in PowerShell to build the virtual environment, install dependencies, and create the mock `git_diff.txt`.
2. Activate the virtual environment.
3. Attempt to run the agent locally (verifying it initiates FastMCP, references the local model at `http://localhost:11434`, reads inputs, prompts the console for approval, and appends to `commit_log.txt` on success).

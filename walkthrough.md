# Walkthrough - Git Commit Agent Implementation

I have successfully generated the complete, copy-pasteable codebase for the lightweight local **Git Commit Agent** running on Windows PowerShell.

## Changes Made

We created the following 4 files in the workspace:

1.  [mcp_server.py](file:///a:/Google%20Drive%20CPG/VS%20Code%20-%20AI%20CLI%20projects/Intensive%20Vibe%20Coding%20Capstone%20Project-Git%20Commit%20Agent/Kaggle_Vibe_Capstone/mcp_server.py): A simple Python MCP server utilizing the `mcp.server.fastmcp` SDK to run on `stdio` transport. It registers the `get_formatting_rules` tool which returns a conventional commit constraint.
2.  [SKILL.md](file:///a:/Google%20Drive%20CPG/VS%20Code%20-%20AI%20CLI%20projects/Intensive%20Vibe%20Coding%20Capstone%20Project-Git%20Commit%20Agent/Kaggle_Vibe_Capstone/SKILL.md): The prompt blueprint and agent skill instructing the agent to adopt a Senior Developer persona, inspect the git diff, dynamically retrieve guidelines from the MCP server, and generate a message.
3.  [agent.py](file:///a:/Google%20Drive%20CPG/VS%20Code%20-%20AI%20CLI%20projects/Intensive%20Vibe%20Coding%20Capstone%20Project-Git%20Commit%20Agent/Kaggle_Vibe_Capstone/agent.py): The main ADK runner script. It connects to the local MCP server, reads `git_diff.txt`, forwards the skill instruction and diff to Ollama running model `gemma4:12b` on `http://localhost:11434`, presents the message to the developer in the terminal, and gates the log writing through a human-in-the-loop approval prompt.
4.  [setup.ps1](file:///a:/Google%20Drive%20CPG/VS%20Code%20-%20AI%20CLI%20projects/Intensive%20Vibe%20Coding%20Capstone%20Project-Git%20Commit%20Agent/Kaggle_Vibe_Capstone/setup.ps1): A PowerShell script to set up a clean Python virtual environment (`.venv`), install all packages (`google-adk`, `mcp`, `run_demos.ps1`), and write a dummy `git_diff.txt`.

## How to Verify and Run

To run the codebase on Windows PowerShell:

1.  **Initialize the Environment:**
    Open PowerShell in the workspace directory and execute the setup script:
    ```powershell
    .\setup.ps1
    ```
    This creates `.venv`, installs dependencies, and creates a dummy `git_diff.txt`.

2.  **Ensure Ollama is Running:**
    Open a separate terminal window and launch the local LLM:
    ```powershell
    ollama run gemma4:12b
    ```

3.  **Run the Agent:**
    With the virtual environment activated, run:
    ```powershell
    python agent.py
    ```

4.  **Confirm the Security Gate:**
    When prompted with `[SECURITY GATE] Approve writing this commit? (Y/N)`, input `Y` to save the message to `commit_log.txt` or `N` to abort.

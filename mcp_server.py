import sys
from mcp.server.fastmcp import FastMCP

# Initialize FastMCP server with the name 'Context 7'
# This server acts as the local rule repository for commit messages.
mcp = FastMCP("Context 7")

@mcp.tool()
def get_formatting_rules() -> str:
    """Retrieve the Git commit message formatting rules.
    
    This function will be called by the LLM agent using the MCP protocol.
    It returns a static set of requirements that the agent must conform to.
    
    Returns:
        str: Static formatting rules for Git commit messages.
    """
    return "Rule 1: Use conventional commits (feat, fix, chore). Rule 2: Keep under 50 characters."

if __name__ == "__main__":
    # Run the server on the stdio transport channel.
    # Note: stderr is used for potential debug logging because stdout is occupied by the protocol.
    print("Starting Context 7 MCP Server...", file=sys.stderr)
    mcp.run(transport="stdio")

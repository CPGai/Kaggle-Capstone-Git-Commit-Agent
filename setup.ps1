# Setup Script for Git Commit Agent in Windows PowerShell

# 1. Create a Python virtual environment
Write-Host "Setting up Python virtual environment..." -ForegroundColor Cyan
python -m venv .venv

# 2. Activate the virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Cyan
.venv\Scripts\Activate.ps1

# 3. Upgrade pip to avoid installation warnings
Write-Host "Upgrading pip..." -ForegroundColor Cyan
python -m pip install --upgrade pip

# 4. Install dependencies (google-adk, mcp, litellm)
Write-Host "Installing dependencies (google-adk, mcp, litellm)..." -ForegroundColor Cyan
pip install google-adk mcp litellm

# 5. Create the dummy git_diff.txt file
Write-Host "Creating dummy git_diff.txt..." -ForegroundColor Cyan
"added new print statement to main loop" | Out-File -FilePath git_diff.txt -Encoding utf8

Write-Host "Setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "To run the agent:" -ForegroundColor Yellow
Write-Host "1. Ensure Ollama is running locally with the gemma4:12b model loaded:"
Write-Host "   ollama run gemma4:12b"
Write-Host "2. Activate virtual environment (if not already activated):"
Write-Host "   .venv\Scripts\Activate.ps1"
Write-Host "3. Run the agent script:"
Write-Host "   python agent.py"
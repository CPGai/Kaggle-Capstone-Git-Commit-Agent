# Demo Automation Harness for Git Commit Agent
# This script automates mock git diff generation for testing and video demos.

# Enable UTF-8 encoding for output
$OutputEncoding = [System.Text.Encoding]::UTF8

# --- HELPER: AUTO-PATCH AGENT.PY FOR CLEAN EXIT ---
function Patch-AgentScript {
    $AgentPath = "agent.py"
    if (Test-Path $AgentPath) {
        $Content = Get-Content $AgentPath -Raw
        if ($Content -notlike "*os._exit(0)*") {
            Write-Host "[SYSTEMS ARCHITECT] Patching agent.py with clean-exit (os._exit(0)) handling..." -ForegroundColor Yellow
            
            # Replace the Y block
            $OldY = "with open(log_file_path, `"a`", encoding=`"utf-8`") as log_file:`r`n            log_file.write(f`"{commit_msg}\n`")`r`n        print(f`"Commit message written successfully to {log_file_path}`")"
            $NewY = "with open(log_file_path, `"a`", encoding=`"utf-8`") as log_file:`r`n            log_file.write(f`"{commit_msg}\n`")`r`n        print(f`"Commit message written successfully to {log_file_path}`")`r`n        import os; os._exit(0)"
            
            # Replace the N block
            $OldN = "print(`"Commit writing aborted by user. Exiting gracefully.`")"
            $NewN = "print(`"Commit writing aborted by user. Exiting gracefully.`")`r`n        import os; os._exit(0)"
            
            $Content = $Content.Replace($OldY, $NewY).Replace($OldN, $NewN)
            Set-Content -Path $AgentPath -Value $Content -Encoding utf8
            Write-Host "[SYSTEMS ARCHITECT] agent.py successfully patched for clean execution." -ForegroundColor Green
        }
    }
}

# Run the patch
Patch-AgentScript

# --- SCENARIOS DEFINITION ---
$Scenarios = @{
    1 = @{
        Title = "Feature: User JWT Authentication"
        Desc  = "Adds user JWT generation and route protection inside user controllers."
        Diff  = @"
diff --git a/controllers/authController.js b/controllers/authController.js
index b83f12a..a92b3c1 100644
--- a/controllers/authController.js
+++ b/controllers/authController.js
@@ -10,4 +10,12 @@ exports.login = async (req, res) => {
     if (!user || !(await user.comparePassword(password))) {
         return res.status(401).json({ error: 'Invalid credentials' });
     }
+    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
+        expiresIn: process.env.JWT_EXPIRES_IN || '24h'
+    });
+    res.status(200).json({
+        status: 'success',
+        token,
+        data: { user }
+    });
  };
"@
    }
    2 = @{
        Title = "Bug Fix: PostgreSQL Connection Pool Timeout"
        Desc  = "Fixes database crashes under heavy loads by increasing maximum pool size and adding timeouts."
        Diff  = @"
diff --git a/config/database.py b/config/database.py
index c2d113f..d4a5b92 100644
--- a/config/database.py
+++ b/config/database.py
@@ -5,5 +5,7 @@ db_config = {
     "user": "postgres",
     "password": "securepassword",
     "port": 5432,
-    "max_overflow": 5
+    "max_overflow": 15,
+    "pool_size": 10,
+    "pool_timeout": 30
 }
 "@
    }
    3 = @{
        Title = "Chore: Dead Import Cleanup"
        Desc  = "Removes unused module imports in utilities library to speed up execution imports."
        Diff  = @"
diff --git a/utils/helpers.py b/utils/helpers.py
index a23145d..f892d11 100644
--- a/utils/helpers.py
+++ b/utils/helpers.py
@@ -1,6 +1,4 @@
-import os
-import sys
-import math
 import datetime
-import random
 
 def format_date(date_val):
 "@
    }
    4 = @{
        Title = "Documentation: API Redoc Setup Instructions"
        Desc  = "Updates README.md to instruct developers how to access new Redoc interactive documentation endpoints."
        Diff  = @"
diff --git a/README.md b/README.md
index a1f3b21..c8e9d41 100644
--- a/README.md
+++ b/README.md
@@ -12,3 +12,7 @@ Install dependencies and run:
 npm install
 npm start
+
+## API Documentation
+Interactive API schemas are accessible at `/docs` (Swagger UI) or `/redoc` (Redoc alternate UI) once the development server initializes.
"@
    }
    5 = @{
        Title = "Test: Stripe Webhook Validation Failures"
        Desc  = "Adds custom Mock testing suite to verify system reactions when Stripe sends invalid webhook payloads."
        Diff  = @"
diff --git a/tests/payment.test.js b/tests/payment.test.js
new file mode 100644
index 0000000..f982c11
--- /dev/null
+++ b/tests/payment.test.js
@@ -0,0 +1,9 @@
+describe('Stripe Webhook Gateway', () => {
+    it('should reject requests with invalid signatures', async () => {
+        const res = await request(app)
+            .post('/webhooks/stripe')
+            .set('Stripe-Signature', 'invalid_sig')
+            .send({ id: 'evt_123' });
+        expect(res.statusCode).toEqual(400);
+    });
+});
"@
    }
}

# --- MENU CONTROLLER ---
while ($true) {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "         CAPSTONE AGENT - AUTOMATED DEMO HARNESS         " -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "Select a scenario to update git_diff.txt automatically:" -ForegroundColor Gray
    Write-Host ""

    foreach ($key in ($Scenarios.Keys | Sort-Object)) {
        Write-Host "  [$key] $($Scenarios[$key].Title)" -ForegroundColor Yellow
        Write-Host "      Details: $($Scenarios[$key].Desc)" -ForegroundColor Gray
    }
    Write-Host "  [Q] Quit & Terminate Cleanly" -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host ""
    
    # Live status checks
    if (Test-Path "commit_log.txt") {
        $LogCount = (Get-Content "commit_log.txt").Count
        Write-Host "Current commits logged in commit_log.txt: $LogCount" -ForegroundColor Cyan
    } else {
        Write-Host "commit_log.txt has not been created yet." -ForegroundColor DarkGray
    }
    Write-Host ""

    $Choice = Read-Host "Enter Selection"

    if ($Choice -eq 'Q' -or $Choice -eq 'q') {
        Write-Host "Exiting Demo Harness cleanly..." -ForegroundColor Cyan
        break
    }

    $IntChoice = 0
    [void][int]::TryParse($Choice, [ref]$IntChoice)

    if ($Scenarios.ContainsKey($IntChoice)) {
        $Selected = $Scenarios[$IntChoice]
        $Selected.Diff | Out-File -FilePath "git_diff.txt" -Encoding utf8
        Write-Host ""
        Write-Host "✅ Successfully wrote '$($Selected.Title)' to git_diff.txt!" -ForegroundColor Green
        Write-Host "----------------------------------------------------------" -ForegroundColor Gray
        Write-Host "NOW RUN THIS IN YOUR MAIN TERMINAL:" -ForegroundColor White
        Write-Host "  python agent.py" -ForegroundColor Yellow
        Write-Host "----------------------------------------------------------" -ForegroundColor Gray
        Write-Host "Press any key to return to the selection menu after running..." -ForegroundColor Gray
        [void][System.Console]::ReadKey($true)
    } else {
        Write-Host "Invalid Selection. Press any key to try again." -ForegroundColor Red
        [void][System.Console]::ReadKey($true)
    }
}

<#
### 🎛️ Setup and Practice Plan (End-To-End)

Follow this step-by-step layout to set up your practice workflow, run your sessions, and safely terminate everything when you are finished.

#### Pre-Flight Checklist: Before You Start
1. **Ollama running:** Make sure Ollama is open and the model is active.
2. **Directory Route:** Confirm you are inside your workspace folder:
   ```powershell
   cd "A:\Google Drive CPG\VS Code - AI CLI projects\Intensive Vibe Coding Capstone Project-Git Commit Agent\Kaggle_Vibe_Capstone"
   ```

---

#### 🎬 Step 1: Initialize Your Workspace (Two-Window Display)
To demonstrate the system in action (especially for a video or practicing), you should set up **two PowerShell windows side-by-side**.

* **Terminal 1 (The Orchestrator Harness):**
    Activate your virtual environment and launch our newly created demo menu script:
    ```powershell
    .\.venv\Scripts\Activate.ps1
    powershell -ExecutionPolicy Bypass -File .\run_demos.ps1
    ```
    *This runs the visual menu showing scenarios 1 through 5, and automatically patches `agent.py` so it never crashes on exit.*

* **Terminal 2 (The Runner Pane):**
    Keep this terminal completely clean and activated:
    ```powershell
    cd "A:\Google Drive CPG\VS Code - AI CLI projects\Intensive Vibe Coding Capstone Project-Git Commit Agent\Kaggle_Vibe_Capstone"
    .\.venv\Scripts\Activate.ps1
    ```
    *This is where you will execute `python agent.py` to run the active demo.*

---

#### 🔄 Step 2: Running Your 5 Practice Demos

Now, you can cycle through various scenarios to see how the local `gemma4:12b` model adapts to the specific code diff context:

1.  **Demo 1 (The Feature Add):**
    * In **Terminal 1**, type `1` and press **Enter**. This writes a raw Javascript JWT authentication diff to `git_diff.txt`.
    * In **Terminal 2**, type `python agent.py` and press **Enter**.
    * *Watch:* The model calls Context 7, notices that the diff implements a new token generation feature, and outputs:
        `feat(auth): Add user JWT authentication`
    * Confirm with `Y` to save the message to the log.

2.  **Demo 2 (The Bug Fix):**
    * In **Terminal 1**, press any key to return to the menu, select `2` to write a python connection pool timeout diff.
    * In **Terminal 2**, execute `python agent.py`.
    * *Watch:* The model reads database variables and outputs a fix statement:
        `fix(db): Configure PostgreSQL pool settings`
    * Confirm with `Y`.

3.  **Demo 3 (The Clean Up):**
    * Select scenario `3` (Chore: Dead Import Cleanup).
    * Execute `python agent.py` in your second terminal.
    * *Watch:* It registers the deleted lines of import libraries as maintenance and outputs:
        `chore(utils): Remove unused module imports`

4.  **Demo 4 (Documentation Changes):**
    * Select scenario `4` (Documentation Update).
    * Execute `python agent.py`.
    * *Watch:* It reads the `README.md` markdown changes and outputs:
        `docs(readme): Add API setup documentation`

5.  **Demo 5 (Testing Suite Addition):**
    * Select scenario `5` (Test suite addition).
    * Execute `python agent.py`.
    * *Watch:* It sees the testing logic for Stripe integration and outputs:
        `test(payment): Verify Stripe signature rejection`

---

#### 🕵️ Verification Telemetry (Checking File Updates)
At any point, you can inspect your workspace files to verify the updates. Run this in PowerShell to see the live updates as the commits are written:
```powershell
Get-Content commit_log.txt -Tail 5
```
*Expected Output: You will see your exact custom messages written, cleanly appended line by line without any missing inputs.*

---

#### 🛑 Step 3: Safe Teardown Protocol
When you are completely finished with your practice session and recording:

1.  **Exit the Harness:**
    * In **Terminal 1**, type `Q` to quit. This closes the selection loop and exits the harness script cleanly.
2.  **Stop Ollama (Free System RAM):**
    * Since local models occupy a lot of system memory (VRAM/RAM), run this to remove the model from execution memory:
        ```powershell
        ollama stop gemma4:12b
        ```
#>

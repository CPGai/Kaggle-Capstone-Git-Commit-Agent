# **Git Commit Agent (Context-Aware Local AI Automation)**

An intelligent, local developer tool that automatically translates messy raw code diffs into clean, standardized, conventional commit messages. This repository was built as a capstone project for the Kaggle *AI Agents: Intensive Vibe Coding* course in partnership with Google.

## **🏗️ System Architecture**

This project is built using **Google's Agent Development Kit (ADK)** and leverages a local **Ollama** model running off-cloud to maintain total code privacy. It utilizes three core components to ensure accuracy and safety:

              
                                 \+----------------------------------+  
                                 |           Developer               |  
                                 |     (Modifies code / App)         |  
                                 \+-----------------+----------------+  
                                                    |  
                                                    v \[Generates Diff\]  
                                 \+-----------------+----------------+  
                                 |          git\_diff.txt            |  
                                 \+-----------------+----------------+  
                                                    |                   
                                                    v \[Reads Input\]  
               \+-----------------------------------+------------------------------------+  
               |                           ADK AGENT RUNNER                              |  
               |                                                                         |  
               |  \+--------------------+   Query rules     \+--------------------------+|  
               |  |     Agent Skill     | \--------------\> |  Context 7 MCP Server     ||  
               |  |    (SKILL.md)       | \<--------------  |  (get\_formatting\_rules) || 
               |  \+---------+----------+   Rules return    \+--------------------------+|  
               |             |                                                           |  
               |             v \[Sends instruction \+ context \+ diff\]                  |  
               |  \+---------+----------+                                                |  
               |  |  Ollama Model       | (gemma4:e4b on http://localhost:11434)         |  
               |  \+---------+----------+                                                |  
               |             |                                                           |  
               |             v \[Outputs Drafted Message\]                               |  
               |  \+---------+----------+                                                |  
               |  |  \[SECURITY GATE\]  | (Human-in-the-Loop prompt)                     |  
               |  \+---------+----------+                                                |  
               \+-----------------------------------+------------------------------------+  
                                                    |  
                                                    | \[If Y (Approved)\]  
                                                    v  
                                 \+-----------------+----------------+  
                                 |         commit\_log.txt           |  
                                 \+----------------------------------+
 
 

1. **The Reasoning Engine:** Google's ADK orchestrates a local instance of Ollama running gemma4:e4b to interpret code diff patterns.  
2. **The MCP Context Layer ("Context 7"):** A Model Context Protocol server exposing a tool (get\_formatting\_rules) to inject dynamic formatting constraints into the model's short-term context.  
3. **The Agent Skill (SKILL.md):** A custom behavior blueprint enforcing high-velocity execution, strict conventional commit rules, and few-shot formatting examples to eliminate reasoning model chatter.  
4. **Security by Design (Human-in-the-Loop):** A strict input prompt gating mechanism preventing the agent from autonomously writing modifications to the log without manual verification.

## **🛠️ Concepts Demonstrated**

This project successfully implements four core agentic development principles:

* **Agent / Multi-Agent System (ADK):** Native execution of Google's ADK runner orchestrating the runtime pipeline.  
* **Model Context Protocol (MCP):** A local stdio-based transport layer connecting our agent dynamically with system rules.  
* **Agent Skills:** Modular, portable instructions (SKILL.md) using YAML frontmatter for progressive context disclosure.  
* **Security & Zero-Trust Features:** Ephemeral isolation (running locally on-device) and explicit Human-in-the-Loop authorization.

## **🚀 Quick Start Guide**

### **Prerequisites**

* **Python:** Version 3.13+ installed.  
* **Ollama:** Installed locally and running with the target model:  
  ollama run gemma4:e4b

### **File Hierarchy**

Ensure your local workspace contains the following files in the same root folder:

* agent.py \- Core ADK script.  
* mcp\_server.py \- FastMCP rules server.  
* SKILL.md \- Agent instruction file.  
* setup.ps1 \- Environment setup script.  
* run\_demos.ps1 \- Interactive scenario harness.

## **💻 Installation & Usage**

### **Step 1: Initialize the Environment**

Open **Windows PowerShell** inside your workspace directory and run the initialization script to automatically create your virtual environment, install dependencies, and setup test files:

\# Bypass execution restrictions and initialize environment  
powershell \-ExecutionPolicy Bypass \-File .\\setup.ps1

### **Step 2: Activate the Virtual Environment**

.\\.venv\\Scripts\\Activate.ps1

### **Step 3: Run the Agent**

To analyze your code changes and write a commit message:

python agent.py

### **Step 4: Authorize Action (Security Gate)**

When prompted in the terminal, review the drafted commit message and approve writing it:

\================ Generated Commit Message \================  
chore(logging): Add print statement to main loop  
\==========================================================

\[SECURITY GATE\] Approve writing this commit? (Y/N): y  
Commit message written successfully to commit\_log.txt

## **🎛️ Demo Automation Harness**

To quickly test the agent across various real-world scenarios, execute the interactive testing harness in PowerShell:

powershell \-ExecutionPolicy Bypass \-File .\\run\_demos.ps1

This utility lets you select from 5 curated mock development scenarios (e.g., JWT Auth features, database pool adjustments, utility cleanups) to test the agent's contextual versatility in real-time.

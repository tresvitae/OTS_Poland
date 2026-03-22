---
name: Python Agents Development
description: "LangGraph multi-agent orchestration system (Anthropic Claude, Python). Use when: extending agents, modifying prompts, adding new agent workflows, debugging agent routing, implementing tool integrations, or managing LangSmith tracing. Covers: LangGraph state machine, agent structure, supervisor routing, tool definitions, prompt engineering."
applyTo: "src/**"
---

# Python Agents Development Guidelines (LangGraph + Claude)

**Location**: `src/`

The multi-agent system coordinates AI-driven development tasks using LangGraph and Anthropic Claude. Each agent specializes in a domain (Backend, Frontend, Content, Integration, QA) and is routed by a Supervisor agent.

---

## 🚀 Quick Start

### Prerequisites
```bash
# Install dependencies
cd /path/to/OTS_Poland
pip install -r requirements.txt

# Set environment variables
export ANTHROPIC_API_KEY="sk-ant-..."
export LANGSMITH_API_KEY="..."          # Optional
```

### Run Agent System
```bash
# Run supervisor (main entry point)
python src/main.py

# The supervisor will prompt for tasks and route to agents
```

### View Agent Traces
```bash
# If LANGSMITH_API_KEY is set, traces appear at:
# https://smith.langchain.com/

# Local debugging output in terminal
# Logs include routing decisions and agent outputs
```

---

## 📂 Directory Structure

```
src/
├── main.py                     # Entry point (supervisor orchestration)
├── config/
│   ├── __init__.py
│   └── settings.py             # Environment, API keys, model config
├── graph/
│   ├── __init__.py
│   ├── main_graph.py           # LangGraph state machine definition
│   ├── routing.py              # Supervisor routing logic
│   └── state.py                # State schema for agents
├── agents/
│   ├── __init__.py
│   ├── supervisor.py           # Supervisor agent (routes tasks)
│   ├── qa_reviewer.py          # QA/review agent
│   ├── backend/
│   │   ├── __init__.py
│   │   └── agent.py            # Backend specialist agent
│   ├── frontend/
│   │   ├── __init__.py
│   │   └── agent.py            # Frontend specialist agent
│   ├── content/
│   │   ├── __init__.py
│   │   └── agent.py            # Game content specialist agent
│   └── integration/
│       ├── __init__.py
│       └── agent.py            # Infrastructure/DB specialist agent
├── prompts/
│   ├── __init__.py
│   ├── supervisor_prompt.py    # Supervisor system prompt
│   ├── backend_prompts.py      # Backend agent prompts
│   ├── frontend_prompts.py     # Frontend agent prompts
│   ├── content_prompts.py      # Content agent prompts
│   ├── integration_prompts.py  # Integration agent prompts
│   └── qa_prompt.py            # QA agent prompts
├── tools/
│   ├── __init__.py
│   ├── file_tools.py           # File read/write utilities
│   └── xml_parser_tools.py     # XML parsing for game content
└── README.md
```

---

## 🔄 LangGraph Architecture

### State Machine (`graph/state.py`)
```python
from typing import Annotated
from langgraph.graph.message import add_messages
from pydantic import BaseModel

# Define shared state for all agents
class AgentState(BaseModel):
    messages: Annotated[list, add_messages]
    task: str                      # User task description
    current_agent: str             # Which agent is processing
    file_path: str                 # Current working file
    context: dict                  # Shared context (project info, etc.)
    error: str | None              # Error message if any
```

### Main Graph (`graph/main_graph.py`)
```python
from langgraph.graph import StateGraph
from src.graph.state import AgentState
from src.agents.supervisor import supervisor_agent
from src.agents.backend.agent import backend_agent
from src.agents.frontend.agent import frontend_agent
from src.agents.content.agent import content_agent
from src.agents.integration.agent import integration_agent

# Initialize graph
builder = StateGraph(AgentState)

# Add nodes (agents)
builder.add_node("supervisor", supervisor_agent)
builder.add_node("backend", backend_agent)
builder.add_node("frontend", frontend_agent)
builder.add_node("content", content_agent)
builder.add_node("integration", integration_agent)

# Set entry point
builder.set_entry_point("supervisor")

# Add conditional edges (routing logic from supervisor)
builder.add_conditional_edges(
    "supervisor",
    lambda state: state.current_agent,
    {
        "backend": "backend",
        "frontend": "frontend",
        "content": "content",
        "integration": "integration",
        "end": "__end__"
    }
)

# Agents return to supervisor after execution
for agent in ["backend", "frontend", "content", "integration"]:
    builder.add_edge(agent, "supervisor")

# Compile graph
graph = builder.compile()
```

### Routing (`graph/routing.py`)
```python
def route_task(state: AgentState) -> str:
    """Supervisor routing logic"""
    task = state.task.lower()
    
    # Route to appropriate agent
    if "api" in task or "route" in task or "endpoint" in task:
        return "backend"
    elif "component" in task or "page" in task or "ui" in task:
        return "frontend"
    elif "npc" in task or "spell" in task or "lua" in task or "creature" in task:
        return "content"
    elif "database" in task or "schema" in task or "migration" in task:
        return "integration"
    else:
        return "supervisor"  # Ask for clarification
```

---

## 🤖 Agent Structure

### Agent Template
```python
# src/agents/domain/agent.py
from langchain.chat_models import ChatAnthropic
from langchain.prompts import ChatPromptTemplate
from src.graph.state import AgentState
from src.prompts.domain_prompts import DOMAIN_SYSTEM_PROMPT

model = ChatAnthropic(model="claude-3-5-sonnet-20241022")

def domain_agent(state: AgentState) -> AgentState:
    """Processes domain-specific tasks"""
    
    # Build prompt
    prompt = ChatPromptTemplate.from_messages([
        ("system", DOMAIN_SYSTEM_PROMPT),
        ("human", state.task),
    ])
    
    # Invoke model
    chain = prompt | model
    response = chain.invoke({
        "task": state.task,
        "context": state.context
    })
    
    # Update state with result
    state.messages.append({
        "role": "assistant",
        "content": response.content
    })
    state.current_agent = "supervisor"  # Return to supervisor
    
    return state
```

### Backend Agent Example
```python
# src/agents/backend/agent.py
from langchain.chat_models import ChatAnthropic
from src.graph.state import AgentState
from src.prompts.backend_prompts import BACKEND_SYSTEM_PROMPT
from src.tools.file_tools import read_file, write_file

model = ChatAnthropic(model="claude-3-5-sonnet-20241022")

def backend_agent(state: AgentState) -> AgentState:
    """Backend specialist: API routes, database queries, authentication"""
    
    # Read relevant backend files for context
    backend_files = read_file("adventure-ots/aac-backend/src/index.ts")
    
    system_prompt = f"""{BACKEND_SYSTEM_PROMPT}

Current Backend Structure:
{backend_files}

Database Connection: Connected to 'db' hostname (MariaDB 10.11)
API Base URL: /api
Auth: JWT tokens (Bearer <token>)
"""
    
    # Process task
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": state.task}
    ]
    
    response = model.invoke(messages)
    
    # If response includes code, write to file
    if "api_code" in response.content.lower():
        # Parse and save code
        code_block = extract_code_block(response.content)
        write_file("adventure-ots/aac-backend/src/routes/new_route.ts", code_block)
    
    state.messages.append({
        "role": "assistant",
        "content": response.content
    })
    
    return state
```

---

## 🧠 Supervisor Agent (`agents/supervisor.py`)

The Supervisor receives tasks from the user and routes them to appropriate agents.

```python
# src/agents/supervisor.py
from langchain.chat_models import ChatAnthropic
from src.graph.state import AgentState, routing
from src.prompts.supervisor_prompt import SUPERVISOR_SYSTEM_PROMPT

model = ChatAnthropic(model="claude-3-5-sonnet-20241022")

def supervisor_agent(state: AgentState) -> AgentState:
    """Routes tasks to appropriate specialist agents"""
    
    system_prompt = f"""{SUPERVISOR_SYSTEM_PROMPT}

Project Structure:
- Backend: adventure-ots/aac-backend/ (Node.js + TypeScript)
- Frontend: adventure-ots/aac-frontend/ (Next.js 14 + Tailwind)
- Game Content: adventure-ots/tfs/data/ (TFS Lua scripts)
- Database: adventure-ots/sql/ (MariaDB schema)
- Infrastructure: Docker Compose, Python agents

Available Agents:
- backend: API routes, database queries, authentication
- frontend: React components, pages, styling
- content: Lua scripts, NPCs, spells, items
- integration: Database migrations, Docker, deployments
- qa_reviewer: Code review, testing, quality checks

Respond with ONLY the agent name (backend, frontend, content, integration, qa_reviewer) or 'end' to finish."""
    
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": state.task},
    ]
    
    response = model.invoke(messages)
    
    # Parse which agent to use
    next_agent = response.content.strip().lower()
    state.current_agent = next_agent if next_agent in ["backend", "frontend", "content", "integration", "qa_reviewer", "end"] else "supervisor"
    
    return state
```

---

## 🛠️ Tool Integration

### File Tools (`tools/file_tools.py`)
```python
import os
from pathlib import Path

def read_file(file_path: str, start_line: int = None, end_line: int = None) -> str:
    """Read file contents, optionally by line range"""
    try:
        path = Path(file_path)
        if not path.exists():
            return f"ERROR: File not found: {file_path}"
        
        with open(path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        if start_line and end_line:
            return ''.join(lines[start_line-1:end_line])
        return ''.join(lines)
    except Exception as e:
        return f"ERROR reading file: {str(e)}"

def write_file(file_path: str, content: str, append: bool = False) -> str:
    """Write or append content to file"""
    try:
        path = Path(file_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        
        mode = 'a' if append else 'w'
        with open(path, mode, encoding='utf-8') as f:
            f.write(content)
        
        return f"SUCCESS: Written to {file_path}"
    except Exception as e:
        return f"ERROR writing file: {str(e)}"

def list_directory(dir_path: str) -> str:
    """List files in directory"""
    try:
        path = Path(dir_path)
        files = list(path.iterdir())
        return '\n'.join([f.name for f in files])
    except Exception as e:
        return f"ERROR: {str(e)}"
```

### XML Parser Tools (`tools/xml_parser_tools.py`)
```python
import xml.etree.ElementTree as ET

def parse_xml(file_path: str) -> dict:
    """Parse XML file into dictionary structure"""
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()
        return {
            "tag": root.tag,
            "attributes": root.attrib,
            "children": [
                {"tag": child.tag, "attrib": child.attrib, "text": child.text}
                for child in root
            ]
        }
    except Exception as e:
        return {"error": str(e)}

def create_xml_element(tag: str, attributes: dict, children: list = None) -> ET.Element:
    """Create XML element for game content"""
    element = ET.Element(tag, attributes)
    if children:
        for child in children:
            element.append(child)
    return element
```

---

## 📝 Prompt Engineering

### System Prompt Template (`prompts/domain_prompts.py`)
```python
BACKEND_SYSTEM_PROMPT = """You are an expert Node.js + TypeScript backend developer specializing in REST APIs, Express.js, and database query optimization.

Your responsibilities:
1. Create or modify Express API routes
2. Write type-safe TypeScript code
3. Ensure JWT authentication is properly implemented
4. Verify database queries are compatible with TFS 1.4.2 schema
5. Follow security best practices (SQL injection prevention, password hashing)

When implementing features:
- Use parameterized database queries
- Always verify input validation
- Return consistent JSON response structure
- Include proper error handling

Output format:
- Explain your approach
- Provide complete code snippets
- Mention any test steps needed
- Note any dependencies or configuration changes required"""

FRONTEND_SYSTEM_PROMPT = """You are an expert React + Next.js frontend developer with deep knowledge of Tailwind CSS and modern web patterns.

Your responsibilities:
1. Create React components following Next.js 14 App Router patterns
2. Use Tailwind CSS exclusively (no inline styles)
3. Implement Dark Fantasy RPG theme
4. Ensure responsive design (mobile-first)
5. Handle API communication securely with JWT tokens

When building features:
- Use 'use client' directive for interactive components
- Leverage server components for data fetching where possible
- Implement proper loading and error states
- Use TypeScript for type safety

Output format:
- Component structure and props
- Complete code with Tailwind utilities
- Integration with backend API
- Testing checklist"""

CONTENT_SYSTEM_PROMPT = """You are an expert game designer and Lua 5.1 scripter for The Forgotten Server (TFS) 1.4.2.

Your responsibilities:
1. Write Lua scripts for NPCs, spells, creatures, items
2. Ensure strict Lua 5.1 compatibility
3. Use TFS 1.4.2 API correctly
4. Design engaging game mechanics
5. Follow naming conventions and code organization

When creating scripts:
- Always check for nil values
- Register scripts in appropriate XML files
- Test in-game behavior (docker logs for errors)
- Document complex logic

Output format:
- Lua script with inline comments
- XML registration if needed
- Testing instructions
- Common pitfalls to avoid"""
```

---

## 🚀 Adding a New Agent

### Step 1: Create Agent Code
```python
# src/agents/newdomain/agent.py
from langchain.chat_models import ChatAnthropic
from src.graph.state import AgentState

model = ChatAnthropic(model="claude-3-5-sonnet-20241022")

def newdomain_agent(state: AgentState) -> AgentState:
    """Processes newdomain tasks"""
    # Implementation
    return state
```

### Step 2: Create System Prompt
```python
# src/prompts/newdomain_prompts.py
NEWDOMAIN_SYSTEM_PROMPT = """Your role and responsibilities..."""
```

### Step 3: Register in Graph
```python
# src/graph/main_graph.py
from src.agents.newdomain.agent import newdomain_agent

builder.add_node("newdomain", newdomain_agent)
builder.add_edge("newdomain", "supervisor")

# Update supervisor routing
builder.add_conditional_edges(
    "supervisor",
    lambda state: state.current_agent,
    {
        # ... existing agents ...
        "newdomain": "newdomain",
    }
)
```

---

## ⚠️ Environment Variables

Create `.env` file in workspace root:
```env
# Anthropic API
ANTHROPIC_API_KEY=sk-ant-...

# Optional: LangSmith tracing
LANGSMITH_API_KEY=...
LANGSMITH_ENDPOINT=https://api.smith.langchain.com

# Optional: Other LLM fallbacks
OPENAI_API_KEY=sk-...

# Project Paths
PROJECT_ROOT=/path/to/adventure-ots
WORKSPACE_ROOT=/path/to/OTS_Poland
```

---

## 🐛 Debugging Agents

### Check Agent Logs
```bash
# Run with verbose output
python src/main.py --verbose

# See actual LangChain calls
export LANGCHAIN_DEBUG=true
python src/main.py
```

### LangSmith Tracing
```bash
# If LANGSMITH_API_KEY is set, traces auto-upload to:
# https://smith.langchain.com/ → Projects → adventure-ots-agents

# View execution flow, token usage, latency
```

### Common Issues
```python
# Issue: Agent returns next_agent incorrectly
# Fix: Ensure routing logic returns valid agent name

# Issue: File not found errors
# Fix: Check PROJECT_ROOT env var and use absolute paths

# Issue: API key errors
# Fix: Verify ANTHROPIC_API_KEY is set and valid:
#      python -c "from langchain.chat_models import ChatAnthropic; print('OK')"
```

---

## 📖 Reference

- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)
- [LangChain Python Docs](https://python.langchain.com/)
- [Anthropic Claude Models](https://docs.anthropic.com/)
- [LangSmith Tracing](https://docs.smith.langchain.com/)
- [Pydantic Models](https://docs.pydantic.dev/latest/)

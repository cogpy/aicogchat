---
model: opencog:opencog-chat
temperature: 0.3
---

You are a CogServer expert for OpenCog. CogServer is the network server that provides remote access to the AtomSpace.

Your capabilities:
- Starting and configuring CogServer
- Managing network shells (Scheme, Python)
- Using cogserver commands and modules
- Handling multiple AtomSpace connections
- Configuring persistence backends

CogServer Features:
- TCP/IP network access to AtomSpace
- Multiple shell types (scheme, python, json)
- Module loading system
- Agent scheduling
- REST API support

Common CogServer Commands:
- help - List available commands
- shutdown - Stop the server
- loadmodule - Load a module
- listmodules - Show loaded modules
- scm - Enter Scheme shell
- py - Enter Python shell

### INPUT:
How do I start CogServer and connect to it?

### OUTPUT:
```bash
# Start CogServer with default settings
cogserver -c cogserver.conf

# Or start with specific port
cogserver --port 17001

# Connect using telnet
telnet localhost 17001

# Or use rlwrap for better line editing
rlwrap telnet localhost 17001
```

```
# CogServer session example

# After connecting, you see:
opencog> help

Available commands:
  help       - Show this help
  shutdown   - Shutdown the server
  scm        - Enter Scheme shell
  py         - Enter Python shell
  stats      - Show server statistics

# Enter Scheme shell
opencog> scm

guile> (Concept "Hello")
$1 = (ConceptNode "Hello")

guile> (cog-atomspace-uuid)
$2 = 1

guile> ,q   ; Exit Scheme shell

# Load a module
opencog> loadmodule opencog/attention/attention.so
done

# Check statistics
opencog> stats
Server uptime: 00:05:23
Connected clients: 1
AtomSpace size: 127 atoms
```

```python
# Python client connection
from opencog.atomspace import AtomSpace, types
from opencog.network import CogServerClient

# Connect to CogServer
client = CogServerClient("localhost", 17001)

# Execute Scheme code remotely
result = client.evaluate("(Concept \"remote-atom\")")

# Direct AtomSpace operations
client.execute("(cog-atomspace-clear)")
```

module completions {

  def "nu-complete chaicog completions" [] {
    [ "bash" "zsh" "fish" "powershell" "nushell" ]
  }

  def "nu-complete chaicog model" [] {
    ^chaicog --list-models |
    | lines 
    | parse "{value}" 
  }

  def "nu-complete chaicog role" [] {
    ^chaicog --list-roles |
    | lines 
    | parse "{value}" 
  }

  def "nu-complete chaicog session" [] {
    ^chaicog --list-sessions |
    | lines 
    | parse "{value}" 
  }

  def "nu-complete chaicog agent" [] {
    ^chaicog --list-agents |
    | lines 
    | parse "{value}" 
  }

  def "nu-complete chaicog rag" [] {
    ^chaicog --list-rags |
    | lines 
    | parse "{value}" 
  }

  def "nu-complete chaicog macro" [] {
    ^chaicog --list-macros |
    | lines 
    | parse "{value}" 
  }

  export extern chaicog [
    --model(-m): string@"nu-complete chaicog model"      # Select a LLM model
    --prompt                                            # Use the system prompt
    --role(-r): string@"nu-complete chaicog role"        # Select a role
    --session(-s): string@"nu-complete chaicog session"  # Start or join a session
    --empty-session                                     # Ensure the session is empty
    --save-session                                      # Ensure the new conversation is saved to the session
    --agent(-a): string@"nu-complete chaicog agent"      # Start a agent
    --agent-variable                                    # Set agent variables
    --rag: string@"nu-complete chaicog rag"              # Start a RAG
    --rebuild-rag                                       # Rebuild the RAG to sync document changes
    --macro: string@"nu-complete chaicog macro"          # Execute a macro
    --serve                                             # Serve the LLM API and WebAPP
    --execute(-e)                                       # Execute commands in natural language
    --code(-c)                                          # Output code only
    --file(-f): string                                  # Include files, directories, or URLs
    --no-stream(-S)                                     # Turn off stream mode
    --dry-run                                           # Display the message without sending it
    --info                                              # Display information
    --sync-models                                       # Sync models updates
    --list-models                                       # List all available chat models
    --list-roles                                        # List all roles
    --list-sessions                                     # List all sessions
    --list-agents                                       # List all agents
    --list-rags                                         # List all RAGs
    --list-macros                                       # List all macros
    ...text: string                                     # Input text
    --help(-h)                                          # Print help
    --version(-V)                                       # Print version
  ]

}

export use completions *

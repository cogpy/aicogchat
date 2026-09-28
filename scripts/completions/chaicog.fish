complete -c chaicog -s m -l model -x -a "(chaicog --list-models)" -d 'Select a LLM model' -r
complete -c chaicog -l prompt -d 'Use the system prompt'
complete -c chaicog -s r -l role -x -a "(chaicog --list-roles)" -d 'Select a role' -r
complete -c chaicog -s s -l session -x  -a "(chaicog --list-sessions)" -d 'Start or join a session' -r
complete -c chaicog -l empty-session -d 'Ensure the session is empty'
complete -c chaicog -l save-session -d 'Ensure the new conversation is saved to the session'
complete -c chaicog -s a -l agent -x  -a "(chaicog --list-agents)" -d 'Start a agent' -r
complete -c chaicog -l agent-variable -d 'Set agent variables'
complete -c chaicog -l rag -x  -a"(chaicog --list-rags)" -d 'Start a RAG' -r
complete -c chaicog -l rebuild-rag -d 'Rebuild the RAG to sync document changes'
complete -c chaicog -l macro -x  -a"(chaicog --list-macros)" -d 'Execute a macro' -r
complete -c chaicog -l serve -d 'Serve the LLM API and WebAPP'
complete -c chaicog -s e -l execute -d 'Execute commands in natural language'
complete -c chaicog -s c -l code -d 'Output code only'
complete -c chaicog -s f -l file -d 'Include files, directories, or URLs' -r -F
complete -c chaicog -s S -l no-stream -d 'Turn off stream mode'
complete -c chaicog -l dry-run -d 'Display the message without sending it'
complete -c chaicog -l info -d 'Display information'
complete -c chaicog -l sync-models -d 'Sync models updates'
complete -c chaicog -l list-models -d 'List all available chat models'
complete -c chaicog -l list-roles -d 'List all roles'
complete -c chaicog -l list-sessions -d 'List all sessions'
complete -c chaicog -l list-agents -d 'List all agents'
complete -c chaicog -l list-rags -d 'List all RAGs'
complete -c chaicog -l list-macros -d 'List all macros'
complete -c chaicog -s h -l help -d 'Print help'
complete -c chaicog -s V -l version -d 'Print version'

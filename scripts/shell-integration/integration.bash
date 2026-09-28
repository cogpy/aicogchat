_chaicog_bash() {
    if [[ -n "$READLINE_LINE" ]]; then
        READLINE_LINE=$(chaicog -e "$READLINE_LINE")
        READLINE_POINT=${#READLINE_LINE}
    fi
}
bind -x '"\ee": _chaicog_bash'
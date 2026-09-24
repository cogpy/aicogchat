_chaicog_zsh() {
    if [[ -n "$BUFFER" ]]; then
        local _old=$BUFFER
        BUFFER+="⌛"
        zle -I && zle redisplay
        BUFFER=$(chaicog -e "$_old")
        zle end-of-line
    fi
}
zle -N _chaicog_zsh
bindkey '\ee' _chaicog_zsh
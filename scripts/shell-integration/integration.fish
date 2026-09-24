function _chaicog_fish
    set -l _old (commandline)
    if test -n $_old
        echo -n "⌛"
        commandline -f repaint
        commandline (chaicog -e $_old)
    end
end
bind \ee _chaicog_fish
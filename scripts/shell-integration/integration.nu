def _chaicog_nushell [] {
    let _prev = (commandline)
    if ($_prev != "") {
        print '⌛'
        commandline edit -r (chaicog -e $_prev)
    }
}

$env.config.keybindings = ($env.config.keybindings | append {
        name: chaicog_integration
        modifier: alt
        keycode: char_e
        mode: [emacs, vi_insert]
        event:[
            {
                send: executehostcommand,
                cmd: "_chaicog_nushell"
            }
        ]
    }
)
function show-colors --description 'Print ANSI 16-color swatches with hex from the active Ghostty theme'
    set -l names black red green yellow blue magenta cyan white

    # Find active theme name from ghostty config
    set -l theme (string match -gr '^theme\s*=\s*(.+)$' < ~/.config/ghostty/config 2>/dev/null | tail -1 | string trim)

    # Locate the theme file: user themes dir first, then Ghostty.app bundled themes
    set -l theme_file
    for d in ~/.config/ghostty/themes /Applications/Ghostty.app/Contents/Resources/ghostty/themes
        if test -n "$theme" -a -f "$d/$theme"
            set theme_file "$d/$theme"
            break
        end
    end

    # Parse `palette = N=#hex` lines into a 16-entry array (fall back to ------ if missing)
    set -l hex
    for n in (seq 0 15)
        set -l val
        if test -n "$theme_file"
            set val (string match -gr "^palette\s*=\s*$n\s*=\s*#?(\w+)" < $theme_file)
        end
        if test -n "$val[1]"
            set -a hex $val[1]
        else
            set -a hex ------
        end
    end

    echo
    if test -n "$theme"
        echo "  Theme: $theme"
    else
        echo "  Theme: (none configured)"
    end
    echo
    echo '  Normal palette (0-7):'
    for i in (seq 8)
        set -l idx (math $i - 1)
        set -l fg (math 30 + $idx)
        printf '    \e[%dm████\e[0m  %-2d  %-8s  #%s\n' $fg $idx $names[$i] $hex[$i]
    end

    echo
    echo '  Bright palette (8-15):'
    for i in (seq 8)
        set -l idx (math $i + 7)
        set -l fg (math 90 + $i - 1)
        printf '    \e[%dm████\e[0m  %-2d  bright %-8s  #%s\n' $fg $idx $names[$i] $hex[(math $i + 8)]
    end

    echo
end

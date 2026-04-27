function show-colors --description 'Print ANSI 16-color swatches (hex labels reflect iterm-default-grey theme)'
    set -l names      black   red     green   yellow  blue    magenta cyan    white
    set -l hex_normal 000000  be7f6d  00bb00  bbbb00  6674c5  bb00bb  00bbbb  bbbbbb
    set -l hex_bright 555555  ea695c  55ff55  ffff55  4a52f1  ff55ff  55ffff  ffffff

    echo
    echo '  Normal palette (palette 0-7):'
    for i in (seq 8)
        set -l idx (math $i - 1)
        set -l fg (math 30 + $idx)
        printf '    \e[%dm████\e[0m  %-2d  %-8s  #%s\n' $fg $idx $names[$i] $hex_normal[$i]
    end

    echo
    echo '  Bright palette (palette 8-15):'
    for i in (seq 8)
        set -l idx (math $i + 7)
        set -l fg (math 90 + $i - 1)
        printf '    \e[%dm████\e[0m  %-2d  bright %-8s  #%s\n' $fg $idx $names[$i] $hex_bright[$i]
    end

    echo
end

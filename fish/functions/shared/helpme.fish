function helpme --description 'List dotfile fish functions with their descriptions'
    set -l dir (dirname (status filename))
    set -l names
    for f in $dir/*.fish
        set -a names (basename $f .fish)
    end

    set -l max 0
    for n in $names
        set -l len (string length -- $n)
        test $len -gt $max; and set max $len
    end

    for n in $names
        set -l first (head -n 1 $dir/$n.fish)
        set -l desc (string match -rg -- "(?:--description|-d)\s+['\"]([^'\"]*)['\"]" $first)
        test -z "$desc"; and set desc "(no description)"
        printf "%s  %s\n" (string pad --right -w $max -- $n) $desc
    end
end

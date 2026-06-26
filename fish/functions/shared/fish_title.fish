function fish_title --description 'Set terminal tab title: per-repo emoji prefix + repo/cwd'
    set -l body
    set -l prefix

    set -l repo (command git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$repo"
        set body (basename $repo)
    else
        set body (prompt_pwd)
    end

    if set -q TERMINAL_TAB_PREFIX
        # Manual override (e.g. set in .envrc via direnv)
        set prefix "$TERMINAL_TAB_PREFIX "
    else if test -n "$repo"
        # Auto: hash repo basename -> stable emoji from palette
        set -l palette 🟦 🟧 🟩 🟨 🟪 🟥
        set -l hash (printf '%s' (basename $repo) | cksum | awk '{print $1}')
        set -l n (count $palette)
        set -l idx (math "($hash % $n) + 1")
        set prefix "$palette[$idx] "
    end

    echo "$prefix$body"
end

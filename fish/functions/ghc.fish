function ghc
    copilot \
        --allow-tool='write' \
        --allow-tool='shell(git log)' \
        --allow-tool='shell(git status)' \
        --allow-tool='shell(echo)' \
        --allow-tool='shell(grep)' \
        --allow-tool='shell(find)' \
        --allow-tool='shell(ls)' \
        --allow-tool='shell(cat)' \
        --allow-tool='shell(head)' \
        --allow-tool='shell(tail)' \
        --allow-tool='shell(sed)' \
        --allow-tool='shell(awk)' \
        --allow-tool='shell(sort)' \
        --allow-tool='shell(uniq)' \
        --allow-tool='shell(wc)' \
        --allow-tool='shell(jq)' \
        $argv
end

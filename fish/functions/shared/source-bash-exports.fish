function source-bash-exports --description 'Convert `export FOO=bar` lines from stdin into fish `set -gx` (no shell evaluation)'
    # Parses each line explicitly. No `source`/`eval` is invoked on the input,
    # so non-matching lines (logs, comments, malformed input) cannot execute as
    # shell code. Assumes values are literal strings (not bash variable refs).
    #
    # `cat | while read` is required: in fish 4.x, builtins/command substitutions
    # inside a piped-to function don't auto-read from the function's stdin.
    cat | while read -l line
        set -l parts (string match -gr '^export ([A-Z_]+)=(.*)$' -- $line)
        if test (count $parts) -eq 2
            set -l name $parts[1]
            set -l value $parts[2]
            # Strip surrounding double or single quotes if present.
            set value (string replace -r '^"(.*)"$' '$1' -- $value)
            set value (string replace -r "^'(.*)'\$" '$1' -- $value)
            set -gx $name $value
        end
    end
end

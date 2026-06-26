function _claude_profile --description 'Internal: launch claude pinned to a specific account/config dir'
    set -l expected $argv[1]
    set -l config_dir $argv[2]
    set -l args $argv[3..]

    # Identity file: the default profile keeps it at ~/.claude.json; a custom
    # CLAUDE_CONFIG_DIR moves it (and the Keychain credentials) into that dir.
    set -l cfg $HOME/.claude.json
    if test "$config_dir" != "$HOME/.claude"
        set -fx CLAUDE_CONFIG_DIR $config_dir
        set cfg $config_dir/.claude.json
    end

    # Let auth subcommands through unchecked so `claudew auth login` can fix a
    # wrong or missing login.
    if test "$args[1]" = auth
        command claude $args
        return
    end

    set -l email
    test -r $cfg; and set email (jq -r '.oauthAccount.emailAddress // empty' $cfg 2>/dev/null)

    if test -z "$email"
        # Fresh profile. Don't launch: a profile with no credentials of its own
        # silently falls back to the default account's Keychain entry.
        echo "No login recorded for this profile ($config_dir)." >&2
        echo "Starting 'claude auth login' — sign in as $expected." >&2
        command claude auth login; or return 1
        set email (jq -r '.oauthAccount.emailAddress // empty' $cfg 2>/dev/null)
    end

    if test "$email" != "$expected"
        echo "✗ Profile $config_dir is logged in as '$email' but expected '$expected'." >&2
        echo "  Fix it by re-running this command as: <command> auth login" >&2
        return 1
    end

    command claude $args
end

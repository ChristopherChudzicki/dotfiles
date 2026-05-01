function odl-eks-login --description 'Fetch ol-infra AWS creds + kubeconfig via Vault (GitHub token from macOS Keychain)'
    set -l token (security find-generic-password -s odl-devops-github-token -a $USER -w 2>/dev/null)
    if test -z "$token"
        echo "odl-eks-login: token 'odl-devops-github-token' not found in macOS Keychain." >&2
        echo "Add it with:" >&2
        echo "  security add-generic-password -s odl-devops-github-token -a \$USER -w" >&2
        return 1
    end

    pushd ~/dev/ol-infrastructure/src/ol_infrastructure/infrastructure/aws/eks
    or return

    # Fetch AWS creds. $pipestatus[1] is the python's exit code (not source-bash-exports').
    GITHUB_TOKEN=$token uv run login_helper.py aws_creds | source-bash-exports
    if test $pipestatus[1] -ne 0
        popd
        echo "odl-eks-login: failed to fetch AWS credentials" >&2
        return 1
    end

    # Write kubeconfig to a tempfile; only replace ~/.kube/config after every
    # step (generation, non-empty check, chmod, mv) succeeds.
    set -l tmp (mktemp)
    GITHUB_TOKEN=$token uv run login_helper.py kubeconfig >$tmp
    if test $status -ne 0
        rm -f $tmp
        popd
        echo "odl-eks-login: failed to generate kubeconfig" >&2
        return 1
    end

    if not test -s $tmp
        rm -f $tmp
        popd
        echo "odl-eks-login: generated kubeconfig is empty" >&2
        return 1
    end

    chmod 600 $tmp; and mv $tmp ~/.kube/config
    if test $status -ne 0
        rm -f $tmp
        popd
        echo "odl-eks-login: failed to install kubeconfig" >&2
        return 1
    end

    popd

    echo "✓ AWS creds + kubeconfig configured (this session only)"
end

function odl-eks-logout --description 'Log out of ODL EKS: remove ~/.kube/ol-eks.yaml and clear cached Vault/AWS creds so nothing can mint tokens without a fresh login'
    set -l kubeconfig ~/.kube/ol-eks.yaml
    # Mirror of CACHE_DIR in ol-infrastructure/scripts/eks/eks.py
    set -l cache_dir ~/.cache/ol-infrastructure/eks
    set -l did_something 0

    # Delete (don't empty) the kubeconfig. When Headlamp is launched via the
    # `headlamp` function it loads ol-eks.yaml through KUBECONFIG, so the path
    # stays in its watched set; Headlamp's ~10s polling watcher re-adds and
    # reloads the file automatically after a later login recreates it. No stored
    # "+ ADD CLUSTER" copy to preserve, so a clean delete is the tidier logout.
    if test -f $kubeconfig
        rm -f $kubeconfig
        echo "✓ removed kubeconfig: $kubeconfig"
        set did_something 1
    end

    # Clear cached Vault tokens + AWS STS creds (all modes). Without these the
    # kubeconfig exec plugin can no longer mint tokens non-interactively, so a
    # later odl-eks-reader-login/-writer-login triggers a fresh browser login.
    # find (not a glob) so an empty cache dir isn't a "no matches" error.
    if test -d $cache_dir
        set -l creds (find $cache_dir -maxdepth 1 -type f \( -name 'vault-token-*.json' -o -name 'aws-creds-*.json' \) 2>/dev/null)
        if test (count $creds) -gt 0
            for f in $creds
                rm -f $f
            end
            echo "✓ cleared "(count $creds)" cached credential file(s) in $cache_dir"
            set did_something 1
        end
    end

    if test $did_something -eq 0
        echo "odl-eks-logout: already logged out (no kubeconfig, no cached creds)"
    else
        echo "↻ reload Headlamp; ol-eks is logged out"
    end
end

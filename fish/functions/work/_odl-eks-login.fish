function _odl-eks-login --description 'Internal: run eks.py setup for a given --mode, writing ~/.kube/ol-eks.yaml'
    set -l mode $argv[1]
    set -l extra $argv[2..-1]
    set -l repo ~/dev/ol-infrastructure

    if not test -d $repo
        echo "_odl-eks-login: ol-infrastructure repo not found at $repo" >&2
        return 1
    end

    # uv run must execute from the repo so it resolves the project's pyproject/venv;
    # the script path is repo-relative.
    pushd $repo
    or return

    uv run python scripts/eks/eks.py setup --mode $mode --output-path ~/.kube/ol-eks.yaml $extra
    set -l rc $status

    popd

    # Headlamp caches each context's user/exec and doesn't adopt the renamed user
    # when the config shape changes, so a running Headlamp needs a reload/restart
    # to show the new ol-eks clusters. (kubectl picks it up immediately.)
    if test $rc -eq 0
        echo "↻ reload Headlamp to see ol-eks clusters"
    end
    return $rc
end

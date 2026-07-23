function headlamp --description 'Open Headlamp with local-dev + ol-eks kubeconfigs loaded (watched, Origin: Kubeconfig), launched from the shell so it inherits PATH for the aws/uv exec auth'
    # Build the kubeconfig set: always local-dev; add ol-eks only when present so
    # this stays harmless on machines/states without it. Loading ol-eks via
    # KUBECONFIG (not "+ ADD CLUSTER") makes Headlamp watch the file, so
    # odl-eks-reader-login / -writer-login rewrites are picked up on reload —
    # unlike a "+ ADD CLUSTER" copy, which freezes the config in indexDB.
    set -l kubeconfigs $HOME/.kube/config
    if test -f $HOME/.kube/ol-eks.yaml
        set -a kubeconfigs $HOME/.kube/ol-eks.yaml
    end
    KUBECONFIG=(string join : $kubeconfigs) open -a Headlamp $argv
end

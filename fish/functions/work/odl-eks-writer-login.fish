function odl-eks-writer-login --description 'Log in to ODL EKS with read/write (developer) creds → ~/.kube/ol-eks.yaml. Overwrites the read-only config at that path.'
    _odl-eks-login developer $argv
    or return

    echo "⚠  ~/.kube/ol-eks.yaml now grants READ/WRITE access to ODL EKS (incl. production)." >&2
    echo "   Run 'odl-eks-reader-login' to switch that file back to read-only." >&2
end

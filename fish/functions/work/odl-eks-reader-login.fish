function odl-eks-reader-login --description 'Log in to ODL EKS with read-only creds (AmazonEKSViewPolicy) → ~/.kube/ol-eks.yaml'
    _odl-eks-login readonly $argv
end

# K8s ServiceAccount

Exampel Configs for `icinga-ready-check` Service-Account with read permissions to _list pods_.

We use `oc` from OpenShift in this example.

```bash
# Generate ServiceAccount
oc apply -f serviceaccount.yml
# Generate ClusterRole
oc apply -f clusterrole.yml
# Bind ClusterRole to ServiceAccount
oc apply -f clusterroleBinding.yml
```

```bash
# Get Token
oc sa get-token icinga-ready-check -n kube-system
```

```bash
$ oc describe clusterrole icinga-ready-check
Name:         icinga-ready-check
PolicyRule:
  Resources    Non-Resource URLs  Resource Names  Verbs
  ---------    -----------------  --------------  -----
  pods         []                 []              [list]

$ oc describe clusterroleBinding icinga-ready-check
Name:         icinga-ready-check
Role:
  Kind:  ClusterRole
  Name:  icinga-ready-check
Subjects:
  Kind            Name          Namespace
  ----            ----          ---------
  ServiceAccount  icinga-ready-check  kube-system

$ oc auth can-i get pods --as system:serviceaccount:kube-system:icinga-ready-check
yes

$ oc auth can-i create pods --as system:serviceaccount:kube-system:icinga-ready-check
no - no RBAC policy matched

$ oc policy can-i --list --as system:serviceaccount:kube-system:icinga-ready-check
```

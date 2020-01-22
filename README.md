# Kubernetes/OpenShift pod-readiness monitoring plugin

Check if all pods for a given namespace/app pass the readiness probe.

## Requirements
* bash
* [jq](https://stedolan.github.io/jq/)

## Installation

1. `bash` and `jq` should be available in almost every linux distribution
2. Create a K8s ServiceAccount and aqquire a toke. See the [example](./k8s-service-account-example).

## Usage

```bash
$ TOKEN=$(oc sa get-token icinga-ready-check -n kube-system)
$ ./check_k8s-readiness.sh -p my-project -a some-app -e 192.168.99.102:8443 -t $TOKEN
some-app-5-ffhcr is READY
ERROR: some-app-5-k9zd5 is CrashLoopBackOff

$ ./check_k8s-readiness.sh -p my-project -a no-pods-exists -e 192.168.99.102:8443 -t $TOKEN
Error: No pods found for my-project/no-pods-exists.
```

## Licence

MIT

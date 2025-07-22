# Filebeat Journald

An example of running the Chainguard `filebeat` image with the `journald` input.

## Requirements

Admin access to a Kubernetes cluster that uses `systemd` on its nodes.

You must install `systemd` into your filebeat image with Custom Assembly so that
`journalctl` is a available.

## Usage

Apply the manifests.

```
export ORGANIZATION=your.org
kubectl apply -f - < <(envsubst < manifests.yaml)
```

Observe systemd logs.

```
kubectl logs daemonset/filebeat -n filebeat -f
```

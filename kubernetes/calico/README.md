# Calico

Deploy Calico to a local `kind` cluster using Chainguard Containers.

## Requirements

- `chainctl`
- `crane`
- `curl`
- `docker`
- `kind`
- `kubectl`
- `sed`

## Usage

Run `./kind.sh` with your Chainguard organization as the first argument.

```
./kind.sh your.org
```

You can also specify a specific version of Calico:

```
./kind.sh your.org v3.29.3
```

# Diff

These are examples of scripts that compare the differences between two container
images.

## diff-vulns.sh

Scans both images with `grype` and compares the vulnerabilities identified.

### Requirements

- `crane`
- `grype`
- `jq`

### Usage

```bash
./diff-vulns.sh cgr.dev/chainguard/python:latest-dev cgr.dev/chainguard/python:latest 
```

The output will look something like this.

```json
{
  "added": [],
  "removed": [
    {
      "id": "CVE-2024-58251",
      "severity": "Low"
    },
    {
      "id": "CVE-2025-46394",
      "severity": "Low"
    }
  ]
}
```

## diff-sboms.sh

Scans both images with `syft` and compares the packages in each.

### Requirements

- `crane`
- `jq`
- `syft`

### Usage

```bash
./diff-sboms.sh cgr.dev/your.org/python:3.12.1 cgr.dev/your.org/python:3.12.2
```

The output will look something like this.

```json
{
  "added": [
    {
      "purl": "pkg:apk/chainguard/libxcrypt@4.4.36-r4?arch=aarch64&distro=chainguard-20230214",
      "name": "libxcrypt",
      "version": "4.4.36-r4",
      "type": "apk"
    }
  ],
  "removed": [],
  "changed": [
    {
      "name": "python-3.12",
      "type": "apk",
      "current": {
        "version": "3.12.2-r8",
        "reference": "pkg:apk/chainguard/python-3.12@3.12.2-r8?arch=aarch64&distro=chainguard-20230214"
      },
      "previous": {
        "version": "3.12.1-r1",
        "reference": "pkg:apk/chainguard/python-3.12@3.12.1-r1?arch=aarch64&distro=chainguard-20230214"
      }
    }
  ]
}
```

You can specify the types of packages to include in the comparison as additional
arguments.

```bash
./diff-sboms.sh cgr.dev/your.org/python:3.12.1 cgr.dev/your.org/python:3.12.2 apk python
```

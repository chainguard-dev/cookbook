# Artifactory Repository Metadata Retrieval

This repository contains scripts to export Docker/OCI image metadata from JFrog
Artifactory as CSV

## Prerequisites

**API Token**: Obtain an API token with appropriate permissions to access
Artifactory resources.

### Generate repo list to query

#### Export your API Token and Artifactory URL

```bash
export token="YOUR_AUTH_TOKEN_HERE"
export artifactory_url="https://foo.jfrog.io/artifactory"
```

#### Give the fetch-oci-and-docker-repos script execute permissions and then run it

```bash
./fetch_repositories.sh repositories.txt
```

#### Manually inspect repo list and remove any repositories that you do not wish to query

### Generate CSV

#### Give the generate-repo-csv script execute permissions and then run it

```bash
./generate-repo-csv.sh
```

### List Unused Files

List files in an Artifactory repository that have not been downloaded in X
number of days. This could serve as the input for an automated cleanup process.

Export your Artifactory URL and token.

```bash
export token="YOUR_AUTH_TOKEN_HERE"
export artifactory_url="https://foo.jfrog.io/artifactory"
```

Run the script with the name of the repository and the number of days as
arguments.

For instance, list files in `my-repository-cache` that haven't been downloaded
in the last 30 days.

```bash
./list-unused-files.sh my-repository-cache 30
```

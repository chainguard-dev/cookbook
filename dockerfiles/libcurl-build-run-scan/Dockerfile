# SPDX-FileCopyrightText: 2025 Chainguard, Inc.
# SPDX-License-Identifier: Apache-2.0

# Create a build container with toolchains
FROM cgr.dev/chainguard/gcc-glibc:latest-dev AS build

# Get source code
COPY <<EOF ./test.c
#include <stdio.h>
#include <curl/curl.h>
void main(){
    printf("%s\\n", curl_version());
}
EOF

# Install build-time dependency
RUN apk add pc:libcurl

# Compile code
RUN gcc test.c `pkg-config --cflags --libs libcurl` -o dynamic-binary

# Create temp apk root with runtime dependencies
RUN apk add --root runtime-deps/ --initdb --keys-dir /etc/apk/keys -X https://packages.wolfi.dev/os so:libcurl.so.4

# Copy our binary
FROM cgr.dev/chainguard/static:latest AS static
COPY --from=build /work/dynamic-binary /usr/bin/dynamic-binary

# Copy runtime dependencies
COPY --from=build /work/runtime-deps/./ /

ENTRYPOINT ["/usr/bin/dynamic-binary"]

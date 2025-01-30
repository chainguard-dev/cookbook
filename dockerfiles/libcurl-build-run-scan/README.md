<!--
SPDX-FileCopyrightText: 2025 Chainguard, Inc.
SPDX-License-Identifier: Apache-2.0
-->

## Multi-stage distroless build

The goal is to compile code in build container.

Resolve and create runtime dependencies temporary chroot.

Assemble a distroless runtime container, start from static, and adding
just the required runtime dependencies.

This example compiles a C binary that uses libcurl library.

At build time it pull in 600+ MB of build time dependecies.

For runtime time it installs just over 30 MB of runtime dependencies.

The resulting image is compatible with popular security scanners.

Note always build with "--no-cache" to ensure latest CVE remediated
binaries are used, as these commands pull updates.

## Demo

Build

```
$ docker build --progress plain --no-cache . --tag dynamic-binary

```

<details><summary>Build output</summary>

```
$ docker build --progress plain --no-cache . --file libcurl-build-run-Chainguardfile --tag dynamic-binary
#0 building with "default" instance using docker driver

#1 [internal] load build definition from libcurl-build-run-Chainguardfile
#1 transferring dockerfile: 844B done
#1 DONE 0.0s

#2 [internal] load metadata for cgr.dev/chainguard/gcc-glibc:latest-dev
#2 DONE 0.0s

#3 [auth] chainguard/static:pull token for cgr.dev
#3 DONE 0.0s

#4 [internal] load metadata for cgr.dev/chainguard/static:latest
#4 DONE 0.8s

#5 [internal] load .dockerignore
#5 transferring context: 2B done
#5 DONE 0.0s

#6 [internal] preparing inline document
#6 CACHED

#7 [build 1/5] FROM cgr.dev/chainguard/gcc-glibc:latest-dev
#7 CACHED

#8 [static 1/3] FROM cgr.dev/chainguard/static:latest@sha256:853bfd4495abb4b65ede8fc9332513ca2626235589c2cef59b4fce5082d0836d
#8 CACHED

#9 [build 2/5] COPY <<EOF ./test.c
#9 DONE 0.0s

#10 [build 3/5] RUN apk add pc:libcurl
#10 0.207 fetch https://packages.wolfi.dev/os/x86_64/APKINDEX.tar.gz
#10 1.689 (1/33) Installing libbrotlienc1 (1.1.0-r4)
#10 1.780 (2/33) Installing brotli (1.1.0-r4)
#10 1.836 (3/33) Installing brotli-dev (1.1.0-r4)
#10 1.893 (4/33) Installing libpsl-dev (0.21.5-r4)
#10 1.945 (5/33) Installing c-ares (1.34.4-r0)
#10 2.017 (6/33) Installing libev (4.33-r6)
#10 2.066 (7/33) Installing nghttp2 (1.64.0-r1)
#10 2.222 (8/33) Installing nghttp2-dev (1.64.0-r1)
#10 2.285 (9/33) Installing jitterentropy-library (3.6.1-r0)
#10 2.338 (10/33) Installing jitterentropy-library-dev (3.6.1-r0)
#10 2.460 (11/33) Installing openssl-dev (3.4.0-r6)
#10 2.994 (12/33) Installing e2fsprogs-libs (1.47.2-r0)
#10 3.074 (13/33) Installing gawk (5.3.1-r1)
#10 3.321 (14/33) Installing sqlite (3.48.0-r0)
#10 3.595 (15/33) Installing sqlite-dev (3.48.0-r0)
#10 3.704 (16/33) Installing libblkid (2.40.4-r0)
#10 3.810 (17/33) Installing libuuid (2.40.4-r0)
#10 3.876 (18/33) Installing libfdisk (2.40.4-r0)
#10 3.978 (19/33) Installing util-linux (2.40.4-r0)
#10 4.081 (20/33) Installing libmount (2.40.4-r0)
#10 4.175 (21/33) Installing libsmartcols (2.40.4-r0)
#10 4.253 (22/33) Installing util-linux-dev (2.40.4-r0)
#10 4.485 (23/33) Installing e2fsprogs-dev (1.47.2-r0)
#10 4.581 (24/33) Installing libffi (3.4.6-r5)
#10 4.627 (25/33) Installing glib (2.83.3-r0)
#10 4.803 (26/33) Installing libverto-glib (0.3.2-r4)
#10 4.853 (27/33) Installing libverto-libev (0.3.2-r4)
#10 4.922 (28/33) Installing libverto-libevent (0.3.2-r4)
#10 5.010 (29/33) Installing libverto-dev (0.3.2-r4)
#10 5.071 (30/33) Installing krb5-server-ldap (1.21.3-r2)
#10 5.155 (31/33) Installing krb5-dev (1.21.3-r2)
#10 5.231 (32/33) Installing zlib-dev (1.3.1-r5)
#10 5.297 (33/33) Installing curl-dev (8.11.1-r0)
#10 5.401 Executing glibc-2.40-r8.trigger
#10 5.429 Executing busybox-1.37.0-r0.trigger
#10 5.441 OK: 622 MiB in 95 packages
#10 DONE 5.6s

#11 [build 4/5] RUN gcc test.c `pkg-config --cflags --libs libcurl` -o dynamic-binary
#11 DONE 0.5s

#12 [build 5/5] RUN apk add --root runtime-deps/ --initdb --keys-dir /etc/apk/keys -X https://packages.wolfi.dev/os so:libcurl.so.4
#12 0.303 fetch https://packages.wolfi.dev/os/x86_64/APKINDEX.tar.gz
#12 1.939 (1/32) Installing glibc-locale-posix (2.40-r8)
#12 2.006 (2/32) Installing ca-certificates-bundle (20241121-r1)
#12 2.072 (3/32) Installing wolfi-baselayout (20230201-r16)
#12 2.125 (4/32) Installing ld-linux (2.40-r8)
#12 2.189 (5/32) Installing libgcc (14.2.0-r8)
#12 2.252 (6/32) Installing glibc (2.40-r8)
#12 2.424 (7/32) Installing libbrotlicommon1 (1.1.0-r4)
#12 2.486 (8/32) Installing libbrotlidec1 (1.1.0-r4)
#12 2.534 (9/32) Installing libcrypto3 (3.4.0-r6)
#12 2.694 (10/32) Installing krb5-conf (1.0-r3)
#12 2.766 (11/32) Installing libcom_err (1.47.2-r0)
#12 2.824 (12/32) Installing keyutils-libs (1.6.3-r5)
#12 2.878 (13/32) Installing libssl3 (3.4.0-r6)
#12 2.955 (14/32) Installing libverto (0.3.2-r4)
#12 3.024 (15/32) Installing krb5-libs (1.21.3-r2)
#12 3.290 (16/32) Installing libevent (2.1.12-r6)
#12 3.371 (17/32) Installing libxcrypt (4.4.38-r0)
#12 3.433 (18/32) Installing libcrypt1 (2.40-r8)
#12 3.486 (19/32) Installing ncurses-terminfo-base (6.5_p20241228-r0)
#12 3.577 (20/32) Installing ncurses (6.5_p20241228-r0)
#12 3.656 (21/32) Installing readline (8.2.13-r1)
#12 3.726 (22/32) Installing sqlite-libs (3.48.0-r0)
#12 3.816 (23/32) Installing heimdal (7.8.0-r6)
#12 3.958 (24/32) Installing gdbm (1.24-r2)
#12 4.031 (25/32) Installing cyrus-sasl (2.1.28-r5)
#12 4.098 (26/32) Installing libldap (2.6.9-r0)
#12 4.208 (27/32) Installing libnghttp2-14 (1.64.0-r1)
#12 4.268 (28/32) Installing libunistring (1.3-r1)
#12 4.365 (29/32) Installing libidn2 (2.3.7-r3)
#12 4.445 (30/32) Installing libpsl (0.21.5-r4)
#12 4.511 (31/32) Installing zlib (1.3.1-r5)
#12 4.567 (32/32) Installing libcurl-openssl4 (8.11.1-r0)
#12 4.644 Executing glibc-2.40-r8.trigger
#12 4.650 ERROR: glibc-2.40-r8.trigger: script exited with error 127
#12 4.653 OK: 32 MiB in 32 packages
#12 DONE 4.9s

#13 [static 2/3] COPY --from=build /work/dynamic-binary /usr/bin/dynamic-binary
#13 DONE 0.0s

#14 [static 3/3] COPY --from=build /work/runtime-deps/./ /
#14 DONE 0.3s

#15 exporting to image
#15 exporting layers
#15 exporting layers 0.3s done
#15 writing image sha256:e03a200e154ea5b372a702f4121d9df6e767295eccb64febc0b6699755595a99 done
#15 naming to docker.io/library/dynamic-binary done
#15 DONE 0.3s
```
</details>

Test

```
$ docker run -ti dynamic-binary
libcurl/8.11.1 OpenSSL/3.4.0 zlib/1.3.1 brotli/1.1.0 libpsl/0.21.5 nghttp2/1.64.0 OpenLDAP/2.6.9
```

Scan

```
$ syft dynamic-binary
 ✔ Loaded image                                                                                                                      dynamic-binary:latest
 ✔ Parsed image                                                                    sha256:e03a200e154ea5b372a702f4121d9df6e767295eccb64febc0b6699755595a99
 ✔ Cataloged contents                                                                     da8763d07c3373949af813a42ce4a127e77b06ceadfad757cb69e70ef663bcb6
   ├── ✔ Packages                        [32 packages]  
   ├── ✔ File digests                    [515 files]  
   ├── ✔ File metadata                   [515 locations]  
   └── ✔ Executables                     [143 executables]  
NAME                    VERSION           TYPE   
ca-certificates-bundle  20241121-r1       apk     
cyrus-sasl              2.1.28-r5         apk     
gdbm                    1.24-r2           apk     
glibc                   2.40-r8           apk     
glibc-locale-posix      2.40-r8           apk     
heimdal                 7.8.0-r6          apk     
keyutils-libs           1.6.3-r5          apk     
krb5-conf               1.0-r3            apk     
krb5-libs               1.21.3-r2         apk     
ld-linux                2.40-r8           apk     
libbrotlicommon1        1.1.0-r4          apk     
libbrotlidec1           1.1.0-r4          apk     
libcom_err              1.47.2-r0         apk     
libcrypt1               2.40-r8           apk     
libcrypto3              3.4.0-r6          apk     
libcurl-openssl4        8.11.1-r0         apk     
libevent                2.1.12-r6         apk     
libgcc                  14.2.0-r8         apk     
libidn2                 2.3.7-r3          apk     
libldap                 2.6.9-r0          apk     
libnghttp2-14           1.64.0-r1         apk     
libpsl                  0.21.5-r4         apk     
libssl3                 3.4.0-r6          apk     
libunistring            1.3-r1            apk     
libverto                0.3.2-r4          apk     
libxcrypt               4.4.38-r0         apk     
ncurses                 6.5_p20241228-r0  apk     
ncurses-terminfo-base   6.5_p20241228-r0  apk     
readline                8.2.13-r1         apk     
sqlite-libs             3.48.0-r0         apk     
wolfi-baselayout        20230201-r16      apk     
zlib                    1.3.1-r5          apk   
```

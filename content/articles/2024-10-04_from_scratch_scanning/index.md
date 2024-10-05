+++
title = "Are \"FROM scratch\" images incompatible with vulnerability scans?"

[taxonomies]
categories = ["security"]
+++

I decided to invoke [Betteridge's law of headlines](https://en.wikipedia.org/wiki/Betteridge%27s_law_of_headlines) to start the article off on a good note.

No, `FROM scratch` Docker images are not incompatible with vulnerability scans, but it requires a bit of effort to make them work.

## Huh? Vulnerability scanning?

A bit of context on the whole ordeal. Modern software development is riddled with tons of dependencies. In the good old days, all software dependended only on other packages published for the same distribution, and all packages were separately packaged for each distribution. It was a rule that no bundled packages were allowed, so if you upgraded the installed version of some library on your system, it would affect all the applications that depended on it. Then came the the different package managers separately for programming languages – probably Perl's [CPAN](https://www.cpan.org/) was the one of the first ones, but then similarily for Python, Ruby, and so on. And finally Node.js broke the camel's back with the proliferation of `node_modules` directories in every project, each containing multiple versions of the same library.

All these dependencies obviously can have security vulnerabilities, so it becomes important to track which dependencies are included with each piece of software. This can no longer be done simply by looking at date or version of the distribution, but instead a full scan of the entire software must be made to locate all bundled dependencies. This is the job of vulnerability scanners, of which [Trivy](https://github.com/aquasecurity/trivy) is a fine example. These tools take a piece of software, or a Docker image, and build a comprehensive list of all included dependencies, and then compare them against published vulnerabilities.

Since dependencies these days come from both the distribution and the programming language package managers, the scanners generally detect the OS of the image and then check the installed packages based on that, and in addition scan for any language-specific package manager state files, such as `package-lock.json` or `Cargo.lock`, and detect software dependencies based on those. So far so good.

## The itch with `FROM scratch`

Docker images traditionally used to have the entire build history of the software included in its layers. All the build tools, all the source code, all the packages. This was a treasure trove for vulnerability scanners as they had all the data to work with. But then people realized that it's a bit of a security vulnerability in itself to have all the tools included in the image that are not needed at runtime, and the images are unnecessarily bloated. So people started turning to multi-stage Docker builds, where the build stages have the tools but the final image has only the files required at runtime.

The evolution of this, bit by bit, is the `FROM scratch` images, where the final stage of the build starts from an empty image, and only the necessary binaries and libraries are copied onto it. This is especially useful for compiled languages, though sometimes done for interpreted languages as well. The resulting images are as small as possible (even smaller than "distroless" images) and are difficult to exploit in case of a vulnerability since there are no extra tools to exploit.

But this is where the problem arises for vulnerability scanners. There's no installed operating system, so they can't know what vulnerable software might've been there when compiling the software. And there's no package manager state files, so they can't know what dependencies were included in the software. Hence, most vulnerability scanners will just refuse to scan `FROM scratch` images entirely, which can be a showstopper in heavily regulated environments.

## Scratching the itch

So, the first step to make `FROM scratch` images scannable is to include the programming language package manager state files in the image. This means simply putting your `package-lock.json` or `Cargo.lock` in the image next to your software, even if nothing actually requires it. The security scanners scan all files in the image, so they'll usually just pick it up where ever it is placed. This part is easy, but also not necessarily sufficient. Even if the programming language package manager state file is included, it doesn't mean that everything that is included in the software only comes from there. Any system libraries, such as `openssl` or `libz`, are not necessarily versioned in the lock file, so vulnerabilities for them might not be tracked.

But even more disturbingly, it seems that just including the programming language package manager state file is often not enough. Many vulnerability scanners want to first detect the OS of the image and will determine based on that if they support the image or not. If they don't detect the OS, or do not support that OS, then they refuse to also scan for the package manager state files.

The solution is to fake the image to look like a supported OS image by including the release files that the vulnerability scanner is looking for, as well as the package state database for the image. Ideally, you should use these files directly from the image you are compiling the software on, as then it will track all the dependencies of any package that might've contributed to your binary. However, in practice, the compiler image might contain a ton of irrelevant packages, which means there's a ton of vulnerabilities reported that are not relevant for your software. The good solution to this is to minimize your compiler image to only contain necessary packages, but simply truncating the package manager state file to a single package also works.

## Yap yap yap, show me how it's done!

For Alpine Linux:

```Dockerfile
FROM alpine:latest AS builder

# Build your software here

FROM scratch

COPY --from=builder /build/Cargo.lock /
COPY --from=builder /build/target/release/mybinary /mybinary
COPY --from=builder /etc/alpine-release /etc/
COPY --from=builder /etc/os-release /etc/
COPY --from=builder /lib/apk/db/installed /lib/apk/db/
```

For Debian:

```Dockerfile
FROM debian:latest AS builder

# Build your software here

FROM scratch

COPY --from=builder /build/Cargo.lock /
COPY --from=builder /build/target/release/mybinary /mybinary
COPY --from=builder /etc/debian_version /etc/
COPY --from=builder /etc/os-release /etc/
COPY --from=builder /var/lib/dpkg/status /var/lib/dpkg/
```

Figuring out the right commands for a distribution of your choice should be quite straightforward. And that'd be it.

## In conclusion

This approach seems to work with at least AWS Inspector and Trivy, but probably works with others as well. They are not so complex beasts, after all. As `FROM scratch` images become more popular, it's likely that the need for such workarounds will diminish, but for now, this is the way to go. Also, hopefully tools like [`cargo-auditable`](https://github.com/rust-secure-code/cargo-auditable) will remove the need to include `Cargo.lock` separately as the same (and better) information is included directly in the produced binaries.
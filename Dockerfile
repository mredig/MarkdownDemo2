# ================================
# Build image
# ================================
FROM swift:6.3-noble AS build

# Install OS updates
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libjemalloc-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up a build area
WORKDIR /build

# First just resolve dependencies.
# This creates a cached layer that can be reused
# as long as your Package.swift/Package.resolved
# files do not change.
COPY ./Package.* ./
RUN swift package resolve

# Copy entire repo into container
COPY . .

# Build the application, with optimizations and jemalloc.
#
# Deliberately NOT passing --static-swift-stdlib: on Linux that flag requires
# the *entire* transitive dependency graph to be statically linkable, but the
# libgit2 C target links -lz/-ldl/-lpthread and dlopens OpenSSL at runtime,
# which is incompatible with a static Swift stdlib. We build dynamically and
# then capture the exact runtime shared libraries for the minimal run image.
RUN swift build -c release \
    --product "MarkdownDemo2" \
    -Xlinker -ljemalloc

# Switch to the staging area
WORKDIR /staging

# Copy main executable to staging area
RUN cp "$(swift build --package-path /build -c release --show-bin-path)/MarkdownDemo2" ./

# Stage the executable's exact runtime shared-library dependencies for the
# minimal run image. Because the build is dynamic, the binary links the Swift
# stdlib dylibs (libswiftCore.so, ...) and C libs (libz, libjemalloc, ...).
# ldd resolves every directly-linked .so; we copy each so the run image can
# satisfy them. (OpenSSL is dlopen'd by libgit2 at runtime rather than linked,
# so ldd does not list it; it is installed via apt in the run stage instead.)
RUN BIN="$(swift build --package-path /build -c release --show-bin-path)/MarkdownDemo2" \
    && mkdir -p ./libs \
    && ldd "$BIN" | awk 'NR>1 && $2==">=" {print $3}' | grep -v '^not$' | sort -u \
    | while read -r lib; do cp -L "$lib" ./libs/; done

# Copy static swift backtracer binary to staging area
RUN cp "/usr/libexec/swift/linux/swift-backtrace-static" ./

# Copy resources bundled by SPM to staging area
RUN find -L "$(swift build --package-path /build -c release --show-bin-path)/" -regex '.*\.resources$' -exec cp -Ra {} ./ \;

# Copy site assets to the staging area if present. The app serves these at runtime
# from "site_assets/public" (relative to the working directory), so the whole
# `site_assets` tree needs to land under /app.
# Ensure that by default, neither the directory nor any of its contents are writable.
RUN [ -d /build/site_assets ] && { mv /build/site_assets ./site_assets && chmod -R a-w ./site_assets; } || true

# ================================
# Run image
# ================================
FROM ubuntu:noble

# Make sure all system packages are up to date, and install only essential packages.
# The Swift stdlib dylibs and other directly-linked C runtime libs are copied in
# from the build stage (resolved via LD_LIBRARY_PATH below), so they are not
# installed here. libssl3t64 provides OpenSSL (libssl/libcrypto), which libgit2
# dlopens at runtime for HTTPS cloning and which ldd therefore does not capture.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y \
      ca-certificates \
      tzdata \
      git \
      libssl3t64 \
# If your app or its dependencies import FoundationNetworking, also install `libcurl4`.
      # libcurl4 \
# If your app or its dependencies import FoundationXML, also install `libxml2`.
      # libxml2 \
    && rm -r /var/lib/apt/lists/*

# Create a hummingbird user and group with /app as its home directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app hummingbird

# Switch to the new home directory
WORKDIR /app

# Copy built executable, captured shared libs, and any staged resources from builder
COPY --from=build --chown=hummingbird:hummingbird /staging /app

# Make the captured Swift stdlib dylibs and C runtime libraries (staged in
# /app/libs) discoverable by the dynamic linker.
ENV LD_LIBRARY_PATH=/app/libs

# Provide configuration needed by the built-in crash reporter and some sensible default behaviors.
ENV SWIFT_BACKTRACE=enable=yes,sanitize=yes,threads=all,images=all,interactive=no,swift-backtrace=./swift-backtrace-static

# Ensure all further commands run as the hummingbird user
USER hummingbird:hummingbird

# Let Docker bind to port 8080
EXPOSE 8080

ENV REMOTE_REPO=https://github.com/mredig/Notes-to-Self

# Start the Hummingbird service when the image is run, default to listening on 8080 in production environment
ENTRYPOINT ["./MarkdownDemo2", "--address", "0.0.0.0"]
CMD ["--port", "8080"]
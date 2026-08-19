# MarkdownDemo2

A read-only web viewer for a git repository full of markdown documents. Point it at a repo, and it clones that repo into a local cache, converts every `.md` file to HTML, and serves the result with **live as-you-type search**. Editing happens in whatever editor you like — just save and refresh to see updates.

Built with [Swift](https://www.swift.org/) and [Hummingbird](https://hummingbird.codes/); distributed as a multi-arch Docker image (linux/amd64 + linux/arm64).

[Check out a live demo!](https://markdowndemo.redeggproductions.com)

## Features

- Live conversion of md to html
- Built-in **LIVE** search, with alphabetization
- Works with an existing markdown git repository (clones it and keeps it fresh)
- Displays file modification dates

## How it works

On start, the app clones (or pulls) the repo pointed to by `REMOTE_REPO` into a local checkout cache, then serves the markdown as generated HTML. It pulls from the remote every 60 seconds, and each request re-reads the checkout from disk, so new content appears without a restart.

## Requirements

- Docker (or any recent OCI container runtime) — the published image is multi-arch
- A git repository containing markdown files (a public repo, or one your host can reach)

## Running it

The simplest way to run MarkdownDemo2 is the Docker image published to the [GitHub Container Registry](https://ghcr.io).

### Run the image

The only thing you must provide is `REMOTE_REPO` — the git URL of a repository containing your markdown files. The image listens on port `8080` inside the container.

```sh
docker run -d \
  --name markdowndemo \
  -p 8080:8080 \
  -e REMOTE_REPO=https://github.com/you/your-markdown-repo \
  ghcr.io/mredig/markdowndemo2:latest
```

Then open `http://localhost:8080`.

The image ships with a default `REMOTE_REPO` value, but the app exits at startup if it's missing — you almost certainly want to override it with your own repo as shown above.

### Keep the cloned repo across container recreations

The app clones `REMOTE_REPO` into a local checkout cache and refreshes it over time. By default that cache lives *inside* the container, so recreating the container loses it and triggers a fresh clone on next start. To persist the cache, give it a stable location and mount a volume on it:

```sh
docker run -d \
  --name markdowndemo \
  -p 8080:8080 \
  -e REMOTE_REPO=https://github.com/you/your-markdown-repo \
  -e LOCAL_CHECKOUT_CACHE=/cache \
  -v markdowndemo-cache:/cache \
  ghcr.io/mredig/markdowndemo2:latest
```

## Configuration

Configuration is via environment variables and/or CLI flags; CLI flags win over env vars where they overlap. In the published image the bind address and port are already set for you, so `REMOTE_REPO` is the only knob you normally need.

### Environment variables

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `REMOTE_REPO` | **yes** | `https://github.com/mredig/Notes-to-Self` | Git URL of the repo containing your markdown files |
| `SERVER_NAME` | no | `MarkdownDemo2` | Display name shown in the UI |
| `LOCAL_CHECKOUT_CACHE` | no | platform app-support dir | Where the remote repo is cloned locally (mount a volume here to persist it) |

### CLI flags

The binary also accepts flags, which override the env vars where they overlap:

| Flag | Default | Description |
| --- | --- | --- |
| `-a, --address` | `127.0.0.1` | Bind address (the Docker image sets `0.0.0.0`) |
| `-p, --port` | `8080` | Port to listen on (the image's `CMD` already passes `--port 8080`) |
| `-s, --server-name` | `MarkdownDemo2` | Display name used in the UI (same as `SERVER_NAME`) |
| `-v, --verbosity` | `info` | Log threshold: `trace` … `critical` |
| `-c, --cache` | app-support dir | Where the cloned repo is stored (same as `LOCAL_CHECKOUT_CACHE`) |
| `-r, --remote` | — | Remote repo URL (same as `REMOTE_REPO`) |

## Building the image yourself

If you'd rather build from source than pull the published image:

```sh
git clone https://github.com/mredig/markdowndemo2
cd markdowndemo2
docker buildx build --platform linux/amd64,linux/arm64 -t markdowndemo:local .
docker run -d -p 8080:8080 -e REMOTE_REPO=https://github.com/you/your-markdown-repo markdowndemo:local
```

## Development

The app is a Swift package. On a machine with Swift 6.3+:

```sh
git clone https://github.com/mredig/markdowndemo2
cd markdowndemo2
export REMOTE_REPO=https://github.com/you/your-markdown-repo
swift run MarkdownDemo2
```

Then open `http://localhost:8080`.

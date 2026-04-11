# Debugging Workflow

How to investigate and fix issues in this repo without wasting CI runs. Every technique below has been exercised against the `nativelink-ubuntu` and `proxy-server` pipelines.

## Prerequisites

| Tool | Used for |
|------|----------|
| `gh` (authenticated to the repo) | Trigger, inspect, and stream workflow runs |
| `git` | Commit and push to trigger the workflow |
| `docker` (local or remote) | Pull the built image and verify it end-to-end |
| `sshpass` (`brew install sshpass`) | Non-interactive SSH to lab hosts |
| `curl` + `jq` / `python3` | Query registry and GitHub APIs |

---

## 1. Trigger: commit and push

The `Build and Push Docker Images` workflow fires on push to `main` when any of these paths change:

- `proxy-server/src/**`
- `nativelink-ubuntu/src/**`
- `.github/workflows/docker-build.yml`

A change outside `src/` (e.g. `quick-start.sh`, `README.md`, `DEBUGGING.md`) will **not** rebuild images — use `workflow_dispatch` or a trivial bump inside `src/` if you need to force a run.

```bash
git add <files> && git commit -m "fix: ..." && git push origin main
```

## 2. Find the run you just triggered

```bash
gh run list --limit 1 --json databaseId,status,headSha,event -q '.[0]'
```

Returns the database ID, SHA, and current status. The `headSha` should match `git rev-parse HEAD`.

## 3. Watch in real time

```bash
gh run watch <run-id> --exit-status --interval 15
```

- `--interval 15` polls every 15 s — more than enough and friendly to API rate limits.
- `--exit-status` makes the command exit non-zero if the run fails, so it fits in scripts.
- Output streams the per-step status tree and any annotations (deprecation warnings, build errors).

## 4. Inspect a completed run

```bash
gh run view <run-id>                       # summary with per-job durations
gh run view <run-id> --log                 # full logs (verbose)
gh run view --job <job-id> --log-failed    # only the failing step's logs
```

For matrix jobs, the job ID is in `gh run view <run-id>` output.

## 5. Browse history

```bash
gh run list --limit 10
gh run list --workflow docker-build.yml --branch main --status failure
```

---

## Verifying a built image on a remote host

After CI pushes to GHCR, verify the image on a real Linux host (lab server, staging VM, etc.):

```bash
# one-shot: pull and run --version with sudo + piped password
sshpass -p "$LAB_PASSWORD" ssh \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    <user>@<host> \
    'echo "'"$LAB_PASSWORD"'" | sudo -S docker pull ghcr.io/littlexia4-creator/nativelink-ubuntu:latest && \
     echo "'"$LAB_PASSWORD"'" | sudo -S docker run --rm ghcr.io/littlexia4-creator/nativelink-ubuntu:latest --version'
```

Notes:

- Keep `LAB_PASSWORD` in an env var — never commit it.
- `-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null` avoids first-connection prompts and local `known_hosts` pollution.
- `echo "$PW" | sudo -S` lets `sudo` read the password from stdin when the SSH user isn't in the `docker` group.
- On macOS, `sshpass` needs to be installed via homebrew: `brew install sshpass`.

### Private GHCR images

If the image is private, `docker login ghcr.io -u <user> --password-stdin` with a PAT that has `read:packages` is required before `docker pull`.

---

## Investigating upstream base images

`nativelink-ubuntu` rebases an upstream image (`ghcr.io/tracemachina/nativelink`). When the `FROM` breaks, the root cause is usually "that tag doesn't exist" or "the binary moved in the image".

### List tags anonymously (public images)

The GHCR OCI endpoint requires a bearer token, but public images mint one anonymously:

```bash
TOKEN=$(curl -sf "https://ghcr.io/token?service=ghcr.io&scope=repository:tracemachina/nativelink:pull" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')

curl -sf -D /tmp/hdrs -H "Authorization: Bearer $TOKEN" \
    "https://ghcr.io/v2/tracemachina/nativelink/tags/list?n=1000"
```

Pagination: check `/tmp/hdrs` for a `link: </v2/...?last=...&n=1000>; rel="next"` header and follow it until gone.

### Prefer the GitHub Releases API for "what version is latest"

The registry `tags/list` has no timestamps, and GitHub's Packages API requires `read:packages` scope. For projects that cut GitHub releases, use the unauthenticated releases endpoint instead:

```bash
curl -sfL https://api.github.com/repos/tracemachina/nativelink/releases/latest | jq -r .tag_name
```

This is exactly what `docker-build.yml`'s `Resolve latest nativelink release tag` step does — it injects the resolved tag into the image via `build-args: NATIVELINK_TAG=…`, so the Dockerfile's `FROM ghcr.io/tracemachina/nativelink:${NATIVELINK_TAG}` tracks upstream without manual bumps.

### Inspect an upstream image's layout

```bash
# entrypoint (revealing nix-store or /bin path)
sudo docker inspect ghcr.io/tracemachina/nativelink:v1.0.0 \
    --format '{{json .Config.Entrypoint}} {{json .Config.Cmd}}'

# file listing — fails if the image is distroless (no shell)
sudo docker run --rm --entrypoint sh <image> -c 'find / -name foo'
```

If the source image is distroless (`exec: "sh": executable file not found`), copy its filesystem into an intermediate stage that *has* a shell:

```dockerfile
FROM <upstream> AS source

FROM alpine:3 AS resolver
COPY --from=source /nix /nix
RUN bin="$(find /nix/store -type f -path '*/bin/nativelink' | head -n1)" \
 && install -m 0755 "$bin" /nativelink

FROM python:3-slim AS final
COPY --from=resolver /nativelink /bin/nativelink
```

This is how `nativelink-ubuntu/src/Dockerfile` avoids hardcoding the content-addressed `/nix/store/<hash>-nativelink-.../bin/nativelink` path.

---

## Iterative fix loop

The canonical tight loop when CI fails:

```
edit → commit → push → gh run list → gh run watch → diagnose → edit …
```

Tips to keep it fast:

- **Don't rerun without a change** — prefer fixing the root cause to re-running hoping for flake recovery.
- **Read the annotations first**: `gh run view <id>` surfaces `build (…): .github#N` errors with the one-line buildx failure (e.g. `manifest unknown`, `failed to solve`).
- **Use `--interval 15` on `gh run watch`** — 10 s is overkill for our 20–30 s jobs, 60 s feels laggy.
- **Scope cache per matrix entry** with `cache-from/cache-to: type=gha,scope=${{ matrix.name }}` so a broken nativelink-ubuntu build doesn't poison the proxy-server cache.

---

## Common pitfalls seen in this repo

| Symptom | Root cause | Fix |
|---------|-----------|-----|
| `failed to resolve source metadata … :latest: not found` | Upstream publishes no `:latest` tag, only nix-hash + semver | Resolve the tag dynamically from GitHub Releases, inject via `ARG` + `build-args` |
| `COPY --from=source /nix/store/<hash>-…/bin/nativelink` fails after upstream bump | Nix store hash is content-addressed and changes every release | Use an intermediate `alpine` stage and `find` the binary at build time |
| `exec: "sh": executable file not found` when running the upstream image | Image is distroless | Don't try to run a shell inside it — `COPY --from` its filesystem into a shelled stage and inspect there |
| `permission denied … /var/run/docker.sock` on the lab host | SSH user isn't in the `docker` group | `echo "$PW" \| sudo -S docker …`, or add the user to the `docker` group once |
| Workflow didn't rerun after editing a script | File lives outside `*/src/**` | Put build-critical files under `src/`, or trigger with `workflow_dispatch` |
| Buildx `linux/arm64` build fails on a musl x86_64 binary | Binary is `x86_64-unknown-linux-musl`, not multi-arch | Set `platforms: linux/amd64` only for that matrix entry |

---

## Reference: the two image pipelines

| Image | Source path | Platforms | Trigger paths |
|-------|-------------|-----------|---------------|
| `ghcr.io/littlexia4-creator/proxy-server` | `proxy-server/src` | `linux/amd64,linux/arm64` | `proxy-server/src/**` |
| `ghcr.io/littlexia4-creator/nativelink-ubuntu` | `nativelink-ubuntu/src` | `linux/amd64` | `nativelink-ubuntu/src/**` |

Both are tagged `latest` on default-branch pushes and by short SHA on every push, via `docker/metadata-action@v5`.

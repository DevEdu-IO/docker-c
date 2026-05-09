# code-esaas

A browser-based VS Code (`code-server`) on Ubuntu 24.04, pre-loaded with C/C++ tooling. Open it in any browser and you have a full editor, terminal, and compiler — no local toolchain required.

**Pre-installed**

- [`code-server`](https://github.com/coder/code-server) — VS Code in the browser
- `gcc`, `g++`, `gdb`, `make` (`build-essential`)
- VS Code extension [`danielpinto8zz6.c-cpp-compile-run`](https://open-vsx.org/extension/danielpinto8zz6/c-cpp-compile-run) for one-click compile-and-run

**Architectures:** `linux/amd64`, `linux/arm64`.

---

## Run

```sh
docker run -d --name code-esaas -p 8080:80 tghastings/code-esaas:latest
```

Then open <http://localhost:8080/>.

> **Heads up:** authentication is disabled inside the container. Only bind it to a port reachable from machines you trust. The user inside the container (`student`) is in the `sudo` group.

### Persisting your work

The pre-installed extension lives in `/home/student/.local/share/code-server/extensions`. If you mount a volume directly over `/home/student/`, you'll hide the extension. Mount a subdirectory instead:

```sh
docker run -d --name code-esaas \
  -p 8080:80 \
  -v "$HOME/code-esaas-workspace:/home/student/work" \
  tghastings/code-esaas:latest
```

### Compiling C/C++

Open any `.c` or `.cpp` file in the editor. The `C/C++ Compile Run` extension adds buttons to the editor toolbar and commands in the Command Palette (`Ctrl+Shift+P` → search "C/C++ Compile") for compile-only, compile-and-run, and compile-and-debug.

---

## Build from source

The repository ships a `build.sh` that wraps `docker buildx`:

```sh
./build.sh                       # verify-build amd64 + arm64 (no image kept)
./build.sh --load                # build for the host arch, load as `code-esaas:local`
./build.sh --push --tag <repo>:<tag>   # build amd64 + arm64 and push as multi-arch
./build.sh --help
```

### Prerequisites for multi-arch builds

```sh
# buildx CLI plugin (Arch example; use your distro's package)
sudo pacman -S docker-buildx

# Register QEMU emulator for the foreign arch (one-time, non-persistent across reboots)
docker run --privileged --rm tonistiigi/binfmt --install arm64
```

`build.sh` creates the `multiarch` buildx builder on first run if it doesn't already exist, and re-registers the emulator if missing.

---

## Installing Docker

- Linux: <https://docs.docker.com/engine/install/>
- macOS: <https://docs.docker.com/desktop/install/mac-install/>
- Windows: <https://docs.docker.com/desktop/install/windows-install/>

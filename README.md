# deveduio/c

A browser-based VS Code editor with C/C++ tools already installed. Open it in your web browser, write a program, and click "Run" — there's nothing to install on your laptop except Docker itself.

**What's included**

- VS Code, running in your browser ([code-server](https://github.com/coder/code-server))
- `gcc`, `g++`, `gdb` (the standard C/C++ compiler and debugger)
- The [C/C++ Compile Run](https://open-vsx.org/extension/danielpinto8zz6/c-cpp-compile-run) extension — adds **Run** and **Debug** buttons to the editor

Works on Intel/AMD (`amd64`) and Apple Silicon / ARM (`arm64`) computers.

---

## Step 1: Install Docker

Pick your operating system and follow the official guide.

### Windows

- Pro / Education / Enterprise:
  <https://docs.docker.com/docker-for-windows/install/>
- Windows Home:
  <https://docs.docker.com/docker-for-windows/install-windows-home/>

### macOS

- <https://docs.docker.com/docker-for-mac/install/>

### Linux

- Ubuntu: <https://docs.docker.com/install/linux/deveduio-ce/ubuntu/>
- Debian: <https://docs.docker.com/install/linux/deveduio-ce/debian/>
- Fedora: <https://docs.docker.com/install/linux/deveduio-ce/fedora/>
- CentOS: <https://docs.docker.com/install/linux/deveduio-ce/centos/>
- Other (binaries): <https://docs.docker.com/install/linux/deveduio-ce/binaries/>

After installing, open a terminal (or **PowerShell** on Windows) and check it works:

```sh
docker --version
```

You should see a line like `Docker version 26.x.x ...`. If you get "command not found", restart your computer and try again.

---

## Step 2: Download the image

In the same terminal:

```sh
docker pull deveduio/c:latest
```

This downloads about 1 GB the first time. After that it's cached and instant.

---

## Step 3: Start the container

```sh
docker run -d --name deveduio-c -p 8080:80 deveduio/c:latest
```

What that command means:

- `-d` — run in the background
- `--name deveduio-c` — give it a friendly name so you can stop/start it later
- `-p 8080:80` — open port `8080` on your laptop, forward it into the container
- `deveduio/c:latest` — the image you just downloaded

---

## Step 4: Open it in your browser

Go to <http://localhost:8080/>

You should see VS Code. The editor opens in your home directory inside the container (`/home/student`).

---

## Step 5: Write and run a C program

1. In VS Code, choose **File → New File** and save it as `hello.c`.
2. Paste this:

   ```c
   #include <stdio.h>

   int main(void) {
       printf("Hello, world!\n");
       return 0;
   }
   ```

3. Click the **Run** button (top-right of the editor, added by the C/C++ Compile Run extension), or open the Command Palette with **Ctrl+Shift+P** (**Cmd+Shift+P** on macOS) and choose **C/C++ Compile and Run**.

The output appears in the terminal panel at the bottom.

---

## Saving your work outside the container

Anything you write inside the container disappears if you delete the container. To keep your files on your laptop, mount a folder when you start the container.

**macOS / Linux:**

```sh
docker run -d --name deveduio-c -p 8080:80 \
  -v "$HOME/deveduio-c-work:/home/student/work" \
  deveduio/c:latest
```

**Windows (PowerShell):**

```powershell
docker run -d --name deveduio-c -p 8080:80 `
  -v "${HOME}\deveduio-c-work:/home/student/work" `
  deveduio/c:latest
```

A folder called `deveduio-c-work` is created in your home directory. Inside VS Code, open `/home/student/work` and anything you save there lives on your laptop permanently.

> **Don't mount a folder over `/home/student/` itself** — the pre-installed extension lives there and would be hidden.

---

## Stopping and starting later

```sh
docker stop deveduio-c     # pause the container (your files are kept)
docker start deveduio-c    # bring it back
docker rm -f deveduio-c    # delete the container completely
```

---

## Troubleshooting

**"port is already allocated"** — something else on your laptop is using port `8080`. Pick another, e.g. `-p 9000:80`, and open <http://localhost:9000/>.

**"permission denied" on Linux** — add yourself to the `docker` group, then log out and back in:

```sh
sudo usermod -aG docker $USER
```

**The page won't load** — make sure the container is actually running:

```sh
docker ps
```

If you don't see `deveduio-c` listed, check the logs:

```sh
docker logs deveduio-c
```

---

## Build from source (advanced)

If you want to modify the image and build it yourself:

```sh
./build.sh                  # verify the image builds for amd64 + arm64
./build.sh --load           # build for your machine and load locally
./build.sh --push --tag deveduio/c:latest    # publish multi-arch
./build.sh --help
```

Multi-arch builds need `docker buildx` (bundled with Docker Desktop; on Arch Linux: `sudo pacman -S docker-buildx`) and a one-time QEMU emulator registration:

```sh
docker run --privileged --rm tonistiigi/binfmt --install arm64
```

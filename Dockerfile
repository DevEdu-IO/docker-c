FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash
ENV GIT_EDITOR=nano
RUN apt update \
  && apt install -y zlib1g-dev libsqlite3-dev libffi-dev libpq-dev libyaml-dev curl sudo \
     supervisor zsh git nano build-essential gdb \
  && curl -fsSL https://code-server.dev/install.sh | sh \
  && mkdir -p /var/log/supervisor

# Add student user and shared coursework directory
RUN useradd -m -s /bin/bash student \
  && passwd -d student \
  && usermod -aG sudo student \
  && chown -R student:student /var/log/supervisor \
  && mkdir /coursework \
  && chown student:student /coursework

ADD supervisord.conf /etc/

USER student

# Pre-install editor extensions, enabled by default:
#   - C/C++ Compile Run (from Open VSX) — Run/Debug buttons for C/C++
#   - DevEdu Code (vendored .vsix, built from ../extension) — the AI assistant
COPY --chown=student:student extensions/devedu-code.vsix /tmp/devedu-code.vsix
RUN code-server --install-extension danielpinto8zz6.c-cpp-compile-run \
  && code-server --install-extension /tmp/devedu-code.vsix \
  && rm -f /tmp/devedu-code.vsix

EXPOSE 80 3000

ENTRYPOINT ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]

FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash
ENV GIT_EDITOR=nano
RUN apt update \
  && apt install -y zlib1g-dev libsqlite3-dev libffi-dev libpq-dev libyaml-dev curl sudo \
     supervisor zsh git nano build-essential gdb \
  && curl -fsSL https://code-server.dev/install.sh | sh \
  && mkdir -p /var/log/supervisor

# Add student user and shared coursework directory. Also drop Ubuntu's
# DEBUGINFOD_URLS export so no tool ever tries to download system-lib debug
# symbols over the network (gdb would stall on it every debug session).
RUN useradd -m -s /bin/bash student \
  && passwd -d student \
  && usermod -aG sudo student \
  && chown -R student:student /var/log/supervisor \
  && mkdir /coursework \
  && chown student:student /coursework \
  && rm -f /etc/profile.d/debuginfod.sh /etc/profile.d/debuginfod.csh

USER student

# Pre-install editor extensions, enabled by default:
#   - DevEdu C Runner (vendored .vsix, built from ../extension-c-run) — Run/Debug
#     buttons for C/C++; runs the program in a clean terminal that shows only
#     the program's own I/O, no shell commands
#   - KylinIdeTeam C/C++ Debug (from Open VSX) — debugging support
#   - DevEdu Code (vendored .vsix, built from ../extension) — the AI assistant
COPY --chown=student:student extensions/devedu-code.vsix /tmp/devedu-code.vsix
COPY --chown=student:student extensions/devedu-c-runner.vsix /tmp/devedu-c-runner.vsix
RUN code-server --install-extension KylinIdeTeam.cppdebug \
  && code-server --install-extension /tmp/devedu-c-runner.vsix \
  && code-server --install-extension /tmp/devedu-code.vsix \
  && rm -f /tmp/devedu-code.vsix /tmp/devedu-c-runner.vsix

# Default user settings:
#   - Trust the workspace. DevEdu Code (0.1.6+) honors VS Code Workspace Trust
#     and won't write files / run commands in an untrusted folder; in this
#     single-student container the /coursework workspace is the student's own,
#     so we disable the trust gate to keep the AI assistant fully functional.
#   - Hide VS Code's built-in Copilot/Chat UI (the "Build with Agent" panel and
#     title-bar chat button) — DevEdu Code is the course's assistant.
RUN mkdir -p /home/student/.local/share/code-server/User \
  && printf '{\n  "security.workspace.trust.enabled": false,\n  "chat.disableAIFeatures": true,\n  "chat.commandCenter.enabled": false\n}\n' > /home/student/.local/share/code-server/User/settings.json

# Plain "$ " terminal prompt: override Ubuntu's default .bashrc PS1 so the
# integrated terminal doesn't show the user@host and working-directory prefix.
RUN echo "PS1='\$ '" >> /home/student/.bashrc

# Ubuntu's profile.d exports DEBUGINFOD_URLS, which makes gdb fetch system-lib
# debug symbols from debuginfod.ubuntu.com and stall for seconds (or time out
# offline) on every debug session. Students only debug their own -g3 binaries,
# so turn it off.
RUN printf 'set debuginfod enabled off\n' > /home/student/.gdbinit

# Last so config tweaks don't invalidate the extension-install layers above.
ADD supervisord.conf /etc/

EXPOSE 80 3000

ENTRYPOINT ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]

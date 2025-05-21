FROM archlinux:base AS install-with-pip

ARG SOURCE=.

RUN pacman -Syu --noconfirm && \
    pacman -Sy --noconfirm zsh python python-pip git python-venv

WORKDIR /workspace

COPY . .

SHELL ["/usr/bin/zsh", "-c"]

# Ensure .zshrc exists and set up plugin
RUN print -l ~/.zshrc
RUN echo 'source /workspace/zsh_dist/zsh-ai.plugin.zsh' >> ~/.zshrc
# Activate zsh environment for the next commands that need zsh_ai_install
# by sourcing .zshrc or by running commands in a new zsh shell.
# For simplicity in Docker, we'll ensure zsh_ai_install is callable directly
# if it's added to PATH by the plugin script, or call it via `zsh -c "source ... && zsh_ai_install"`
# The plugin script should make `zsh_ai_install` available.
RUN zsh -c "source ~/.zshrc && zsh_ai_install"

# Verification steps
RUN if [ ! -d ~/.zsh-ai ]; then echo 'Virtual env ~/.zsh-ai not found!'; exit 1; fi
RUN ~/.zsh-ai/bin/pip list | grep google-generativeai || (echo 'google-generativeai not found in pip stage!'; ~/.zsh-ai/bin/pip list; exit 1)

RUN zsh -c "source ~/.zshrc && zsh_ai_bug_report"

FROM archlinux:base AS install-with-uv

ARG SOURCE=.

RUN pacman -Syu --noconfirm && \
    pacman -Sy --noconfirm zsh git curl # Removed rust, uv installs its own Python if needed

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH" # Assuming root user in Docker. Use $HOME if not.

WORKDIR /workspace

COPY . .

SHELL ["/usr/bin/zsh", "-c"]

# Ensure .zshrc exists and set up plugin
RUN print -l ~/.zshrc
RUN echo 'source /workspace/zsh_dist/zsh-ai.plugin.zsh' >> ~/.zshrc

# Activate zsh environment and run install
RUN zsh -c "source ~/.zshrc && zsh_ai_install"

# Verification steps
RUN if [ ! -d ~/.zsh-ai ]; then echo 'Virtual env ~/.zsh-ai not found!'; exit 1; fi
RUN ~/.zsh-ai/bin/pip list | grep google-generativeai || (echo 'google-generativeai not found in uv stage!'; ~/.zsh-ai/bin/pip list; exit 1)

RUN zsh -c "source ~/.zshrc && zsh_ai_bug_report"

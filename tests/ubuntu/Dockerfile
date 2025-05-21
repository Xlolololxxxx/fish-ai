FROM ubuntu:24.04 AS install-with-pip

ARG SOURCE=.

RUN apt update && \
    apt install -y curl git software-properties-common python3 python3-pip python3-venv zsh

WORKDIR /workspace

COPY . .

SHELL ["/usr/bin/zsh", "-c"]

RUN print -l ~/.zshrc
RUN echo 'source /workspace/zsh_dist/zsh-ai.plugin.zsh' >> ~/.zshrc
# For RUN commands in Docker, each is a new shell session.
# To make zsh_ai_install available, we need to source .zshrc or call it via zsh -c "source ... && command"
RUN zsh -c "source ~/.zshrc && zsh_ai_install"

RUN if [ ! -d ~/.zsh-ai ]; then echo 'Virtual env ~/.zsh-ai not found!'; exit 1; fi
RUN ~/.zsh-ai/bin/pip list | grep google-generativeai || (echo 'google-generativeai not found in pip stage!'; ~/.zsh-ai/bin/pip list; exit 1)

RUN zsh -c "source ~/.zshrc && zsh_ai_bug_report"

FROM ubuntu:24.04 AS install-with-uv

ARG SOURCE=.

RUN apt update && \
    apt install -y curl git software-properties-common zsh

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH" # Assuming root, adjust if user is different

WORKDIR /workspace

COPY . .

SHELL ["/usr/bin/zsh", "-c"]

RUN print -l ~/.zshrc
RUN echo 'source /workspace/zsh_dist/zsh-ai.plugin.zsh' >> ~/.zshrc
RUN zsh -c "source ~/.zshrc && zsh_ai_install"

RUN if [ ! -d ~/.zsh-ai ]; then echo 'Virtual env ~/.zsh-ai not found!'; exit 1; fi
RUN ~/.zsh-ai/bin/pip list | grep google-generativeai || (echo 'google-generativeai not found in uv stage!'; ~/.zsh-ai/bin/pip list; exit 1)

RUN zsh -c "source ~/.zshrc && zsh_ai_bug_report"

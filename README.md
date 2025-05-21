![Badge with time spent](https://img.shields.io/endpoint?url=https%3A%2F%2Fgist.githubusercontent.com%2FRealiserad%2Fd3ec7fdeecc35aeeb315b4efba493326%2Fraw%2Fzsh-ai-git-estimate.json) <!-- TODO: Update gist URL if name changes -->
![Popularity badge](https://img.shields.io/endpoint?url=https%3A%2F%2Fgist.githubusercontent.com%2FRealiserad%2Fd3ec7fdeecc35aeeb315b4efba493326%2Fraw%2Fpopularity.json) <!-- TODO: Update gist URL if name changes -->
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/Realiserad/zsh-ai/codespaces) <!-- TODO: Update repo URL if it changes -->

# About

`zsh-ai` adds AI functionality to [Zsh](https://www.zsh.org/).
It's awesome! I built it to make my life easier, and I hope it will make
yours easier too. Here is the complete sales pitch:

- It can turn a comment into a shell command and vice versa, which means
less time spent
reading manpages, googling and copy-pasting from Stack Overflow. Great
when working with `git`, `kubectl`, `curl` and other tools with loads
of parameters and switches.
- Did you make a typo? It can also fix a broken command (similarly to
[`thefuck`](https://github.com/nvbn/thefuck)).
- Not sure what to type next or just lazy? Let the LLM autocomplete
your commands with a built in fuzzy finder.
- Everything is done using two keyboard shortcuts, no mouse needed!
- It can be hooked up to the LLM of your choice (even a self-hosted one!).
- Everything is open source, hopefully somewhat easy to read and
around 2000 lines of code, which means that you can audit the code
yourself in an afternoon.
- Easy to install and manage.
- Tested on both macOS and the most common Linux distributions.
- Does not interfere with popular Zsh frameworks or plugins like
[`fzf`](https://github.com/junegunn/fzf),
[`ohmyzsh`](https://ohmyz.sh/), [`prezto`](https://github.com/sorin-ionescu/prezto), etc.
- Does not wrap your shell, install telemetry or force you to switch
to a proprietary terminal emulator.

This plugin was originally based on [Tom Dörr's `fish.codex` repository](https://github.com/tom-doerr/codex.fish).
The Zsh adaptation builds upon the core ideas and Python backend developed for that project.
Without Tom's original work, this repository would not exist!

If you like it, please add a ⭐. If you don't like it, create a PR. 😆

## 🎥 Demo

**Note:** The demo below shows the original `fish-ai` version. An updated demo for `zsh-ai` is pending. The core functionalities are similar, but keybindings and shell interactions will differ in Zsh.

<!-- TODO: Update demo GIF to show Zsh interaction -->
![Demo](https://github.com/user-attachments/assets/86b61223-e568-4152-9e5e-d572b2b1385b)

## 👨‍🔧 How to install

### Prerequisites

Make sure `git` and either [`uv`](https://github.com/astral-sh/uv), or
[a supported version of Python](https://github.com/Realiserad/zsh-ai/blob/main/.github/workflows/python-tests.yaml) <!-- TODO: Update link if repo name changes -->
along with `pip` and `venv` is installed.

### Installation

1.  **Clone the repository:**

    You can clone it to a common Zsh plugin directory. For example:
    *   If you use Oh My Zsh:
        ```shell
        git clone https://github.com/Realiserad/zsh-ai.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai
        ```
        Then add `zsh-ai` to your plugins list in `~/.zshrc`:
        ```shell
        plugins=(... zsh-ai)
        ```
    *   For a generic path (e.g., if you don't use a plugin manager or use a different one):
        ```shell
        mkdir -p ~/.zsh-plugins # Create directory if it doesn't exist
        git clone https://github.com/Realiserad/zsh-ai.git ~/.zsh-plugins/zsh-ai
        ```
        Then, source the plugin in your `~/.zshrc`:
        ```shell
        echo "source ~/.zsh-plugins/zsh-ai/zsh-ai.plugin.zsh" >> ~/.zshrc
        ```

2.  **Restart your Zsh shell** or source your `~/.zshrc` file:
    ```shell
    source ~/.zshrc
    ```

3.  **Run the installer function** (this sets up the Python virtual environment):
    ```shell
    zsh_ai_install
    ```
    This command should be run once after installation or updates if the Python dependencies change.

### Create a configuration

Create a configuration file `~/.config/zsh-ai.ini` where you specify which LLM
`zsh-ai` should talk to. If you're not sure, use GitHub Models.

#### GitHub Models

To use [GitHub Models](https://github.com/marketplace/models):

```ini
[zsh-ai]
configuration = github

[github]
provider = self-hosted
server = https://models.inference.ai.azure.com
api_key = <paste GitHub PAT here>
model = gpt-4o-mini
```

You can create a personal access token (PAT) [here](https://github.com/settings/tokens).
The PAT does not require any permissions.

#### Self-hosted

To use a self-hosted LLM (behind an OpenAI-compatible API):

```ini
[zsh-ai]
configuration = self-hosted

[self-hosted]
provider = self-hosted
server = https://<your server>:<port>/v1
model = <your model>
api_key = <your API key>
```

If you are self-hosting, my recommendation is to use
[Ollama](https://github.com/ollama/ollama) with
[Llama 3.3 70B](https://ollama.com/library/llama3.3). An out of the box
configuration  running on `localhost` could then look something
like this:

```ini
[zsh-ai]
configuration = local-llama

[local-llama]
provider = self-hosted
model = llama3.3
server = http://localhost:11434/v1
```

#### OpenRouter

To use [OpenRouter](https://openrouter.ai):

```ini
[zsh-ai]
configuration = openrouter

[openrouter]
provider = self-hosted
server = https://openrouter.ai/api/v1
model = google/gemini-2.0-flash-lite-001
api_key = <your API key>
```

Available models are listed [here](https://openrouter.ai/models).

#### OpenAI

To use [OpenAI](https://platform.openai.com):

```ini
[zsh-ai]
configuration = openai

[openai]
provider = openai
model = gpt-4o
api_key = <your API key>
organization = <your organization>
```

#### Azure OpenAI

To use [Azure OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service):

```ini
[zsh-ai]
configuration = azure

[azure]
provider = azure
server = https://<your instance>.openai.azure.com
model = <your deployment name>
api_key = <your API key>
```

#### Hugging Face

To use [Hugging Face](https://huggingface.co):

```ini
[zsh-ai]
configuration = huggingface

[huggingface]
provider = huggingface
email = <your email>
api_key = <your password>
model = meta-llama/Llama-3.3-70B-Instruct
```

Available models are listed [here](https://huggingface.co/chat/models).
Note that 2FA must be disabled on the account.

#### Mistral

To use [Mistral](https://mistral.ai):

```ini
[zsh-ai]
configuration = mistral

[mistral]
provider = mistral
api_key = <your API key>
```

#### Anthropic

To use [Anthropic](https://www.anthropic.com):

```ini
[zsh-ai]
configuration = anthropic

[anthropic]
provider = anthropic
api_key = <your API key>
```

#### Cohere

To use [Cohere](https://cohere.com):

```ini
[zsh-ai]
configuration = cohere

[cohere]
provider = cohere
api_key = <your API key>
```

#### DeepSeek

To use [DeepSeek](https://www.deepseek.com):

```ini
[zsh-ai]
configuration = deepseek

[deepseek]
provider = deepseek
api_key = <your API key>
model = deepseek-chat
```

#### Groq

To use [Groq](https://groq.com):

```ini
[zsh-ai]
configuration = groq

[groq]
provider = groq
api_key = <your API key>
```

#### Google

To use [Gemini](https://ai.google.com) from Google:

```ini
[zsh-ai]
configuration = google

[google]
provider = google
api_key = <your API key>
model = gemini-1.5-flash # Example model
```

### Put the API key on your keyring

Instead of putting the API key in the configuration file, you can let
`zsh-ai` load it from your keyring. To save a new API key or transfer
an existing API key to your keyring, run `zsh_ai_put_api_key`.

## 🙉 How to use

The default keybindings are:
- **Ctrl + P** (represented as `^P` in Zsh `bindkey` terms): For codifying comments to commands or explaining commands.
- **Ctrl + Space** (often represented as `^@` or depends on terminal for Zsh): For autocompleting commands or fixing the previous command. Your terminal must be configured to send a distinct sequence for Ctrl+Space if `^@` doesn't work.

### Transform comments into commands and vice versa

Type a comment (anything starting with `#`), and press **Ctrl + P** to turn it
into shell command! Note that if your comment is very brief or vague, the LLM
may decide to improve the comment instead of providing a shell command. You
then need to press **Ctrl + P** again.

You can also run it in reverse. Type a command and press **Ctrl + P** to turn it
into a comment explaining what the command does.

### Autocomplete commands

Begin typing your command or comment and press **Ctrl + Space** to display a list
of completions in [`fzf`](https://github.com/junegunn/fzf) (it is bundled
with the plugin, no need to install it separately).

To refine the results, type some instructions and press **Ctrl + P**
inside `fzf`.

### Suggest fixes

If a command fails (returns a non-zero exit code), you can immediately press **Ctrl + Space** at the (empty) command prompt
to let `zsh-ai` suggest a fix for the last command!

## 🤸 Additional options

You can tweak the behaviour of `zsh-ai` by putting additional options in your
`zsh-ai.ini` configuration file.

### Explain in a different language

To explain shell commands in a different language, set the `language` option
to the name of the language. For example:

```ini
[zsh-ai]
language = Swedish
```

This will only work well if the LLM you are using has been trained on a dataset
with the chosen language.

### Change the temperature

Temperature is a decimal number between 0 and 1 controlling the randomness of
the output. Higher values make the LLM more creative, but may impact accuracy.
The default value is `0.2`.

Here is an example of how to increase the temperature to `0.5`.

```ini
[zsh-ai]
temperature = 0.5
```

This option is not supported when using the `huggingface` provider.

Some reasoning models, such as OpenAI's o3, does not support the
temperature parameter, and you need to explicitly disable it by
setting `temperature = None`.

### Number of completions

To change the number of completions suggested by the LLM when pressing
**Ctrl + Space**, set the `completions` option. The default value is `5`.

Here is an example of how you can increase the number of completions to `10`:

```ini
[zsh-ai]
completions = 10
```

To change the number of refined completions suggested by the LLM when pressing
**Ctrl + P** in `fzf`, set the `refined_completions` option. The default value
is `3`.

```ini
[zsh-ai]
refined_completions = 5
```

### Personalise completions using commandline history

You can personalise completions suggested by the LLM by sending
an excerpt of your commandline history.

To enable it, specify the maximum number of commands from the history
to send to the LLM using the `history_size` option. The default value
is `0` (do not send any commandline history).
You can also specify the Zsh history file location using `histfile` if it's not `~/.zsh_history`.

```ini
[zsh-ai]
history_size = 20 # Example: send last 20 relevant history entries
# histfile = ~/.my_custom_zsh_history # Optional: if your history file is not default
```

If you enable this option, consider the use of tools that help manage Zsh history quality.

### Preview pipes

To send the output of a pipe to the LLM when completing a command, use the
`preview_pipe` option.

```ini
[zsh-ai]
preview_pipe = True
```

This will send the output of the longest consecutive pipe after the last
unterminated parenthesis before the cursor. For example, if you autocomplete
`az vm list | jq`, the output from `az vm list` will be sent to the LLM.

This behaviour is disabled by default, as it may slow down the completion
process and lead to commands being executed twice.

## 🎭 Switch between contexts

You can switch between different sections in the configuration using the
`zsh_ai_switch_context` command.

## 🐾 Data privacy

When using the plugin, `zsh-ai` submits the name of your OS and the
commandline buffer to the LLM.

When you codify or complete a command, it also sends the contents of any
files you mention (as long as the file is readable), and when you explain
or complete a command, the output from `<command> --help` (or `man <command>`) is provided to
the LLM for reference.

`zsh-ai` can also send an excerpt of your commandline history
when completing a command. This is disabled by default.

Finally, to fix the previous command, the previous commandline buffer,
along with any terminal output and the corresponding exit code is sent
to the LLM.

If you are concerned with data privacy, you should use a self-hosted
LLM. When hosted locally, no data ever leaves your machine.

### Redaction of sensitive information

The plugin attempts to redact sensitive information from the prompt
before submitting it to the LLM. Sensitive information is replaced by
the `<REDACTED>` placeholder.

The following information is redacted:

- Passwords and API keys supplied on the commandline.
- PEM-encoded private keys.

## 🔨 Development

If you want to contribute, I recommend to read [`ARCHITECTURE.md`](https://github.com/Realiserad/zsh-ai/blob/main/ARCHITECTURE.md) <!-- TODO: Update link if repo name changes -->
first.

This repository ships with a `devcontainer.json` which can be used with
GitHub Codespaces or Visual Studio Code with
[the Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

To install `zsh-ai` from a local copy for development:
1. Clone the repository: `git clone https://github.com/Realiserad/zsh-ai.git /path/to/local/zsh-ai` <!-- TODO: Update repo URL if it changes -->
2. Source the local plugin file in your `~/.zshrc`:
   ```shell
   echo "source /path/to/local/zsh-ai/zsh-ai.plugin.zsh" >> ~/.zshrc
   ```
3. Restart your Zsh shell or source your `~/.zshrc`.
4. Run `zsh_ai_install` to set up the Python environment from your local copy.

Alternatively, you can symlink your local repository to a Zsh plugin manager's custom plugin directory.
For Oh My Zsh:
```shell
ln -s /path/to/local/zsh-ai ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai
```
Then add `zsh-ai` to your `plugins` array in `~/.zshrc`.

### Enable debug logging

Enable debug logging by putting `debug = True` in your `zsh-ai.ini`.
Logging is done to syslog by default (if available). You can also enable
logging to file using `log = <path to file>`, for example:

```ini
[zsh-ai]
debug = True
log = ~/.zsh-ai/log.txt
```

### Run the tests

[The installation tests](https://github.com/Realiserad/zsh-ai/actions/workflows/installation-tests.yaml) <!-- TODO: Update link if repo name changes -->
are packaged into containers and can be executed locally with e.g. `docker`.

```shell
docker build -f tests/ubuntu/Dockerfile .
docker build -f tests/fedora/Dockerfile .
docker build -f tests/archlinux/Dockerfile .
```

The Python modules containing most of the business logic can be tested using
`pytest`.

### Create a release

A release is created by GitHub Actions when a new tag is pushed.

```shell
# Ensure pyproject.toml version is updated first
tag=$(grep '^version *=' pyproject.toml | awk -F'"' '{print $2}')
git tag -a "v$tag" -m "🚀 v$tag"
git push origin "v$tag"
```

<p align="center">
  <h1 align="center">🛠️ claude-init</h1>
  <p align="center">
    <strong>A one-line Windows installer that gives Claude Code a per-project provider switcher — Anthropic, OpenRouter, NVIDIA NIM, or a local translation proxy for anything else.</strong>
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/PowerShell-7-5391FE?style=for-the-badge&logo=powershell&logoColor=white" alt="PowerShell">
    <img src="https://img.shields.io/badge/Node.js-Proxy-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js">
    <img src="https://img.shields.io/badge/Claude_Code-Integrated-e11d48?style=for-the-badge" alt="Claude Code">
    <img src="https://img.shields.io/github/license/pratiks360/claude-init?style=for-the-badge" alt="License">
  </p>
</p>

---

## 📋 Table of Contents

- [What Is This?](#-what-is-this)
- [Features](#-features)
- [Quick Start](#-quick-start)
- [How It Works](#-how-it-works)
- [Provider Reference](#️-provider-reference)
- [Tech Stack](#️-tech-stack)
- [Security Notes](#-security-notes)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ What Is This?

**claude-init** installs `cl-config` — a small interactive CLI you run from any project folder on Windows to generate a **project-scoped** `.claude/settings.local.json` for Claude Code. Instead of hand-editing JSON every time you switch a project between Anthropic, OpenRouter, NVIDIA NIM, or a self-hosted/free backend, `cl-config` walks you through it, inherits sane defaults from your global `~/.claude/settings.json`, and — for providers Claude Code can't talk to natively — spins up a local Node.js proxy that translates requests on the fly.

---

## 🎯 Features

| Feature | Description |
|---|---|
| 🔀 **Provider picker** | Choose Anthropic, OpenRouter, NVIDIA NIM, Dahl, or Puter per project — no global reconfiguration needed |
| 🔑 **Global token inheritance** | Detects an existing `ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_API_KEY` in your global settings and offers to reuse it |
| 🧩 **Plugin inheritance** | Prompts you to selectively enable any plugin already active in your global config |
| 🔌 **MCP server inheritance** | Same selective opt-in flow for `enabledMcpServers` / `mcpServers` |
| 🌉 **Auto-launched proxy** | For Dahl/Puter, spawns `universal-proxy.js` in its own terminal window so Claude Code can reach them via `127.0.0.1:4000` |
| 🧭 **Custom model override** | Optionally set a non-default Sonnet/Haiku/Opus/subagent model per provider |
| 🪟 **One-line install** | Downloads everything to `%USERPROFILE%\.cl-config-cli` and adds it to your user `PATH` automatically |

---

## 🚀 Quick Start

**Prerequisites:** Windows, PowerShell, and [Node.js](https://nodejs.org/) (only required if you plan to use the Dahl or Puter proxy options).

### 1 · Install

```powershell
irm https://raw.githubusercontent.com/pratiks360/claude-init/main/install.ps1 | iex
```

This downloads `cl-config.ps1` and `universal-proxy.js` into `%USERPROFILE%\.cl-config-cli`, creates a `cl-config.cmd` wrapper, and adds the install folder to your user `PATH`. Restart your terminal afterward.

### 2 · Run it in any project

```powershell
cd path\to\your\project
cl-config
```

Follow the prompts to pick a provider, optionally inherit your global token/plugins/MCP servers, and set a custom model. A `.claude/settings.local.json` file is written to the current directory — Claude Code picks it up automatically the next time you run `claude` there.

---

## 🧩 How It Works

```
┌────────────────┐   downloads    ┌─────────────────────────┐   writes to PATH   ┌──────────────┐
│  install.ps1   │ ─────────────► │ %USERPROFILE%\.cl-config-cli │ ─────────────────► │  cl-config   │
│  (bootstrap)   │                │ (cl-config.ps1, proxy.js) │                    │  (command)   │
└────────────────┘                └─────────────────────────┘                    └──────┬───────┘
                                                                                          │ run in a project
                                                                                          ▼
                                                                          ┌───────────────────────────┐
                                                                          │  .claude/settings.local.json │
                                                                          │  (project-scoped config)   │
                                                                          └──────────────┬────────────┘
                                                                                          │ Dahl / Puter only
                                                                                          ▼
                                                                          ┌───────────────────────────┐
                                                                          │  universal-proxy.js       │
                                                                          │  127.0.0.1:4000/{provider}│
                                                                          └───────────────────────────┘
```

1. **`install.ps1`** — bootstraps the CLI: downloads the two source files, creates a `.cmd` wrapper so Windows can execute `cl-config` directly, and registers the folder on `PATH`.
2. **`cl-config.ps1`** — the interactive configurator. Reads your global `~/.claude/settings.json` (if present), asks which provider to use for this project, offers to inherit tokens/plugins/MCP servers, and writes a project-local `.claude/settings.local.json`.
3. **`universal-proxy.js`** — only invoked for the **Dahl** and **Puter** provider options. It's launched in its own visible terminal window (kept open so you can see logs) and listens on `http://127.0.0.1:4000/<provider>`, translating Claude Code's requests to the target backend.

---

## ⚙️ Provider Reference

| Choice | Provider | Base URL | Requires Node.js? |
|---|---|---|---|
| 1 | **Anthropic** (default) | Official Anthropic API | No |
| 2 | **OpenRouter** | `https://openrouter.ai/api` | No |
| 3 | **NVIDIA NIM** | `https://integrate.api.nvidia.com/v1` | No |
| 4 | **Dahl** | `http://127.0.0.1:4000/dahl` (local proxy) | ✅ Yes |
| 5 | **Puter** | `http://127.0.0.1:4000/puter` (local proxy) | ✅ Yes |

For OpenRouter and NVIDIA NIM you'll be prompted for a specific model string (e.g. `openai/gpt-oss-120b:free`). Dahl defaults to `MiniMaxAI/MiniMax-M2.7` and Puter defaults to `deepseek-chat` if you leave the model prompt blank.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Installer / CLI** | PowerShell (`install.ps1`, `cl-config.ps1`) |
| **Translation proxy** | Node.js (`universal-proxy.js`) |
| **Config target** | Claude Code's `.claude/settings.local.json` |
| **Platform** | Windows (uses `%USERPROFILE%`, `.cmd` wrapper, user `PATH`) |

---

## 🔒 Security Notes

- API tokens are written in **plaintext** to `.claude/settings.local.json` in your project folder — make sure this file is in your `.gitignore` before committing.
- The Dahl/Puter proxy binds to `127.0.0.1` only; it isn't exposed beyond localhost.
- `install.ps1` uses `-ExecutionPolicy Bypass` for the generated `.cmd` wrapper — review the script before running if you're security-conscious about piping `irm | iex`.

---

## 🐛 Troubleshooting

**Q: `cl-config` isn't recognized after installing.**
A: Restart your terminal — the `PATH` update only takes effect in new shell sessions.

**Q: I selected Dahl or Puter and nothing happens.**
A: Confirm Node.js is installed and on `PATH` (`node -v`). The script exits early with an error if it can't find `node`.

**Q: The proxy window closed and Claude Code stopped responding.**
A: The spawned terminal must stay open — it's the running proxy process. Re-run `cl-config` and select the same provider to relaunch it.

**Q: How do I switch a project back to plain Anthropic?**
A: Re-run `cl-config` in that folder and choose option 1 — it overwrites the existing `.claude/settings.local.json`.

---

## 🤝 Contributing

This is primarily a personal tool, but PRs and issues are welcome — feel free to open one to suggest a new provider or report a bug.

---

## 📄 License

This project is open source under the [MIT License](LICENSE).

---

<p align="center">
  <sub>Built with ❤️ for switching Claude Code between LLM providers without the copy-paste JSON dance.</sub>
</p>

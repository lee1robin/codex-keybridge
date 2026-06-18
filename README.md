# Codex KeyBridge

**Keep Codex login, bring your own model keys.**

中文说明在前，English version follows.

## 2026-06 更新：旧方案已不再推荐

这个项目最早的版本基于当时 Codex Desktop 还没有公开稳定的 local/custom provider 配置能力，所以采用过更激进的 provider 替换思路。随着 Codex 新版本已经支持官方的 `model_providers` 配置入口，旧方案不再推荐，也不需要继续依赖。

当前推荐方案是：

- 保留 Codex 官方默认 provider：`model_provider = "openai"`。
- 额外注册一个独立的本地 provider：`model_providers.litellm`。
- 需要官方账号额度时使用 `openai`。
- 需要本地 API Key 路由时手动切换到 `litellm`。

旧方案仍保留在仓库历史中供参考，但请不要在新机器上继续使用“替换 Codex 内部 provider/YAML”的方式。

Codex KeyBridge is a local harness that keeps the normal Codex Desktop login experience, while routing actual model calls through your own LiteLLM proxy and API keys.

换句话说：你仍然用 GPT 账号登录 Codex，继续保留远程控制、插件、工具、历史记录等桌面体验；但真正消耗模型 Token 的地方，可以切到你自己的 OpenAI、Gemini 或其他 LiteLLM 支持的 API Key。

## 为什么有价值

普通的 API Key 调用方式往往只是“调用模型”，很难完整保留 Codex Desktop 里的插件、工具调用、远程控制和工作区体验。

Codex KeyBridge 的价值在于把两件事分开，同时不破坏官方默认路径：

- 登录和产品体验：继续使用 Codex Desktop 的正常 GPT 账号登录。
- 官方模型调用：保留 Codex 默认 `openai` provider。
- 自定义模型消耗和供应商：通过独立 `litellm` provider 使用你自己的 API Key。

这样你可以同时得到：

- Codex Desktop 的完整交互体验。
- 插件、工具、远程控制等账号登录后才有的能力。
- 在官方 token 和本地 API Key 路由之间切换。
- 更自由的 Token 使用空间。
- OpenAI、Gemini 或其他模型供应商之间的本地路由。
- 本地 PostgreSQL 里的 Token、费用、模型和供应商记录。

## 工作方式

```text
Default mode:
Codex model picker -> official Codex/OpenAI provider

LiteLLM mode:
Codex model picker -> local LiteLLM -> your OpenAI / Gemini / other provider keys
```

Codex Desktop 里有两个可以分开的部分：

- 账号登录：决定你能不能使用 Codex Desktop 的产品能力。
- 模型端点：决定请求实际发给谁、使用谁的 Key、消耗谁的额度。

Codex KeyBridge 保留前者，并把后者变成一个可切换选项，而不是默认强制替换。

```text
Codex Desktop
  keeps normal GPT account login
  keeps normal UI, history, plugins, tools
        |
        v
Local LiteLLM proxy
  maps Codex model names
  chooses provider keys
  records token usage
        |
        +--> OpenAI API key
        +--> Gemini API key
        +--> other LiteLLM-supported providers
```

## 示例路由

| Codex 里选择的模型 | 实际上游模型 | 使用的 API Key |
|---|---|---|
| `gpt-5.5` | `openai/gpt-5.5` | `OPENAI_API_KEY` |
| `gpt-5.4` | `openai/gpt-5.4` | `OPENAI_API_KEY` |
| `gpt-5.4-mini` | `openai/gpt-5.4-mini` | `OPENAI_API_KEY` |
| `gpt-5.3-codex` | `openai/gpt-5.3-codex` | `OPENAI_API_KEY` |
| `gpt-5.2` | `gemini/gemini-3-flash-preview` | `GEMINI_API_KEY` |

最后一行是这个方案最直观的例子：Codex 里仍然选择 `gpt-5.2`，但本地 LiteLLM 可以把它转发到 Gemini。

## 快速开始

```zsh
git clone https://github.com/lee1robin/codex-keybridge.git
cd codex-keybridge
cp templates/env.example .env
```

编辑 `.env`：

```zsh
OPENAI_API_KEY=your-openai-api-key
GEMINI_API_KEY=your-gemini-api-key
LITELLM_MASTER_KEY=sk-codex-local
```

安装：

```zsh
./scripts/install-macos.sh
```

默认安装会保留官方 provider，并额外注册 `litellm` provider。重启 Codex Desktop，然后验证：

```zsh
./scripts/verify.sh
```

打开 LiteLLM UI：

```text
http://127.0.0.1:4000/ui
```

默认登录：

```text
Username: admin
Password: value of LITELLM_MASTER_KEY
```

## 安装内容

默认本地路径：

```text
~/codex-litellm
~/.codex/config.toml
~/Library/LaunchAgents/com.codex-keybridge.litellm.plist
```

默认本地端口：

```text
LiteLLM:    127.0.0.1:4000
PostgreSQL: 127.0.0.1:5432
```

macOS 安装脚本会做这些事：

1. 通过 Homebrew 安装 `postgresql@16`。
2. 创建本地 `litellm` 数据库。
3. 创建 `~/codex-litellm`。
4. 在 Python 虚拟环境里安装 LiteLLM。
5. 写入 LiteLLM 模型路由配置。
6. 写入启动脚本，让 LiteLLM 等 PostgreSQL 就绪后再启动。
7. 安装 macOS LaunchAgent，让 LiteLLM 登录后自动启动。
8. 修改 `~/.codex/config.toml`，加入本地 LiteLLM Provider。
9. 把真实 API Key 留在本地 `.env`，不提交到 Git。

## Codex 配置形态

Codex KeyBridge 会添加类似这样的 Provider，并默认保留官方 `openai`：

```toml
model = "gpt-5.5"
model_provider = "openai"
model_reasoning_effort = "medium"

[model_providers.litellm]
name = "LiteLLM Local"
base_url = "http://127.0.0.1:4000/v1"
wire_api = "responses"
experimental_bearer_token = "sk-codex-local"
```

关键点是：Codex 仍然保留正常账号登录；默认请求走官方 provider。需要使用本地 API Key 时，把 `model_provider` 改为 `litellm` 并重启 Codex。

```toml
model_provider = "litellm"
```

如果你想让安装脚本直接把默认 provider 写成 LiteLLM，可以显式运行：

```zsh
CODEX_DEFAULT_PROVIDER=litellm ./scripts/install-macos.sh
```

## Token 和费用记录

连接 PostgreSQL 后，LiteLLM 会把请求写入：

```text
LiteLLM_SpendLogs
```

常用查询：

```zsh
psql -d litellm -c 'select "startTime", model, model_group, custom_llm_provider, total_tokens, prompt_tokens, completion_tokens, spend, status from "LiteLLM_SpendLogs" order by "startTime" desc limit 8;'
```

例如，可以验证 Codex 里的 `gpt-5.2` 是否实际走了 Gemini：

```text
model                         model_group  provider
gemini/gemini-3-flash-preview gpt-5.2      gemini
```

## 项目文件

```text
scripts/install-macos.sh       macOS 一键安装脚本
scripts/verify.sh              健康检查、路由检查、Token 记录检查
scripts/uninstall.sh           移除 LiteLLM LaunchAgent
scripts/patch_codex_config.py  安全修改 Codex 配置
templates/                     env、LiteLLM、LaunchAgent、Codex 配置模板
docs/current-deployment-guide.md 当前推荐部署方案
docs/architecture.md           架构说明
docs/troubleshooting.md        常见问题
docs/pitch.md                  推广文案
RELEASE_NOTES_v0.2.0.md        旧方案废弃说明
```

## 安全提醒

不要把真实 API Key 提交到 GitHub。

这个仓库只包含模板。你的本地 `.env` 已经被 `.gitignore` 排除。

也不要提交 LiteLLM 日志，因为日志可能包含提示词、工具输出或本地路径。

## 已知限制

简单请求、模型路由和 Token 记录可以稳定工作。复杂 Agent 工作流如果包含大量工具调用历史，在 LiteLLM 把 Codex 的 Responses API 请求转给 Gemini 时，可能遇到兼容性问题。排查方法见 `docs/troubleshooting.md`。

---

## English

**Keep Codex login, bring your own model keys.**

Codex KeyBridge is a local routing harness for Codex Desktop. It keeps the normal Codex account login and desktop experience, while actual model calls are routed through your own LiteLLM proxy, API keys, and model providers.

### 2026-06 Update: legacy approach deprecated

The first version of this project was built before Codex exposed a stable official custom provider configuration path. It used a more invasive provider replacement approach. New Codex releases now support user-level `model_providers`, so that old approach is no longer recommended.

The recommended setup now keeps `model_provider = "openai"` as the default and registers `model_providers.litellm` as a separate optional provider. Switch to `litellm` only when you want local API-key routing.

The main benefit is that you do not have to choose between the full Codex Desktop experience and your own API keys. API-key-only usage often loses app-level capabilities such as plugins, tools, remote control, and workspace history. Codex KeyBridge keeps those app capabilities available through the normal login, while moving model usage to keys that you control.

In practice:

- Codex Desktop still uses the normal GPT account login.
- Plugins, tools, remote control, and history remain part of the app experience.
- Official mode uses the default Codex/OpenAI provider.
- LiteLLM mode sends model calls through local LiteLLM.
- You choose whether a Codex model name maps to OpenAI, Gemini, or another provider.
- Token and spend records can be stored locally in PostgreSQL.

### Quick Start

```zsh
git clone https://github.com/lee1robin/codex-keybridge.git
cd codex-keybridge
cp templates/env.example .env
```

Edit `.env`:

```zsh
OPENAI_API_KEY=your-openai-api-key
GEMINI_API_KEY=your-gemini-api-key
LITELLM_MASTER_KEY=sk-codex-local
```

Install:

```zsh
./scripts/install-macos.sh
```

Restart Codex Desktop, then verify:

```zsh
./scripts/verify.sh
```

Open LiteLLM UI:

```text
http://127.0.0.1:4000/ui
```

Default login:

```text
Username: admin
Password: value of LITELLM_MASTER_KEY
```

### License

MIT

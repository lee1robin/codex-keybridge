# Codex KeyBridge Pitch

## One-Liner

Keep Codex login, bring your own model keys.

保留 Codex 登录体验，使用你自己的模型 API Key。

## Short Description

Codex KeyBridge is a local LiteLLM harness that lets Codex Desktop keep its normal GPT account login, plugins, tools, remote control, and history, while routing actual model calls through your own API keys and provider choices.

Codex KeyBridge 是一个本地 LiteLLM 桥接方案：Codex Desktop 继续用正常 GPT 账号登录，保留插件、工具、远程控制和历史记录；真正的模型调用则通过你自己的 API Key 和模型供应商完成。

## Longer Description

Codex Desktop has a useful app experience that is tied to account login: remote control, plugins, tools, workspace history, and the normal desktop workflow. API-key-only usage can be cheaper or more flexible, but it often loses those app-level capabilities.

Codex KeyBridge separates the account session from the model endpoint. Codex keeps the normal login and product experience. A local LiteLLM proxy receives model calls, maps Codex model names to upstream providers, and records token usage in PostgreSQL.

The result is a practical cross-key setup: one Codex model choice can use an OpenAI key, another can use Gemini, and every request can be inspected locally.

## 中文长文案

Codex Desktop 的价值不只是模型调用本身，还包括登录后的远程控制、插件、工具、历史记录和工作区体验。单纯使用 API Key 虽然更自由，但往往拿不到这些产品层能力。

Codex KeyBridge 把“登录体验”和“模型消耗”拆开：Codex 继续用 GPT 账号登录，保留完整桌面体验；真正的模型请求则交给本地 LiteLLM，再由 LiteLLM 使用你自己的 OpenAI、Gemini 或其他 API Key。

这让 Codex 既像正常桌面客户端一样好用，又能把 Token 消耗转移到你自己控制的 API Key 上，还可以把请求、模型、Token 和费用记录到本地数据库。

## Launch Post

I built Codex KeyBridge: a local LiteLLM harness for Codex Desktop.

The idea is simple:

Keep Codex login, bring your own model keys.

Codex still uses the normal GPT account login, so the desktop app experience stays intact: plugins, tools, remote control, history, and workspace flows.

But actual model calls go through a local LiteLLM proxy that you control.

That makes cross-key routing possible:

- `gpt-5.5` -> OpenAI key
- `gpt-5.4` -> OpenAI key
- `gpt-5.2` -> Gemini key
- token and spend logs -> local PostgreSQL

This is useful because API-key-only workflows often lose app-level features. Codex KeyBridge keeps the app experience while moving model usage to your own keys.

Repo: https://github.com/lee1robin/codex-keybridge

## 中文发布文案

我做了一个小工具：Codex KeyBridge。

一句话：保留 Codex 登录体验，使用你自己的模型 API Key。

它的价值在于，Codex Desktop 继续用 GPT 账号正常登录，所以远程控制、插件、工具、历史记录这些体验还在；但真正的模型请求会走本地 LiteLLM，然后用你自己的 OpenAI、Gemini 或其他 API Key。

这样既能享受 Codex Desktop 的完整产品能力，又能把 Token 消耗放到自己控制的 API Key 上。

示例：

- `gpt-5.5` -> OpenAI Key
- `gpt-5.4` -> OpenAI Key
- `gpt-5.2` -> Gemini Key
- Token 和费用记录 -> 本地 PostgreSQL

Repo: https://github.com/lee1robin/codex-keybridge

## GitHub Description

Keep Codex login, bring your own model keys. Route Codex Desktop model calls through local LiteLLM, your API keys, and a local token ledger.

## Suggested Topics

- codex
- litellm
- openai
- gemini
- model-routing
- bring-your-own-key
- ai-agents
- macos
- token-tracking

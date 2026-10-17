# noctalia-omp-claude-usage

A [Noctalia](https://noctalia.dev) plugin that shows the Claude usage of your
[omp](https://github.com/can1357/oh-my-pi) session in the bar: the 5-hour and weekly rate
windows, plus tokens, cost, daily activity and a per-model breakdown for the week.

**Claude only.** omp supports other providers (OpenAI, DeepSeek, …), but this plugin only
reads Anthropic data: it needs an Anthropic login in omp, and it ignores messages sent to
other providers. With no Anthropic login it has nothing to show.

It is the [Claude Code Usage](https://github.com/noctalia-dev/community-plugins) plugin
with a different data engine: instead of Claude Code's `~/.claude/.credentials.json`, it
uses the login omp already holds.

## Install

Needs `jq`, `curl` and `sqlite3`. The rate windows also need an Anthropic login in omp.

```sh
git clone https://github.com/0x2u/noctalia-omp-claude-usage ~/.local/share/noctalia-omp-claude-usage
noctalia msg plugins source add omp-claude-usage path ~/.local/share/noctalia-omp-claude-usage
noctalia msg plugins enable 0x2u/ompclaude
```

Then add the widget to a bar in `~/.config/noctalia/config.toml`:

```toml
[widget.omp-claude-usage]
type = "0x2u/ompclaude:pill"
```

Left click opens the panel, right click refreshes. Settings (refresh interval, currency,
pill style) are under Settings → Plugins.

## How it works

`ompclaude/get-omp-claude-usage` prints one JSON object; the service in `service.luau` runs it
every few minutes and the widgets render the result.

| Data | Source |
|---|---|
| Rate windows | `api.anthropic.com/api/oauth/usage`, authorized with the OAuth token in `~/.omp/agent/agent.db` |
| Plan | `api.anthropic.com/api/oauth/profile`, cached 24 h |
| Tokens, cost, activity | Anthropic messages in omp's session logs, `~/.omp/agent/sessions/**/*.jsonl` |
| USD → EUR | [Frankfurter](https://frankfurter.dev), cached 24 h |

The token is **read-only**: omp owns refreshing it, and refreshing from here would rotate
the refresh token out from under omp. When omp has been idle long enough for the access
token to expire (about 8 h), the widget keeps showing the last cached windows until you
use omp again.

Set `OMP_AGENT_DIR` if your omp data is not in `~/.omp/agent`. Caches live in
`~/.cache/omp-claude-usage`.

## Credits

The widgets, panel and desktop tile come from
[jrohland's Noctalia port](https://github.com/noctalia-dev/community-plugins/tree/main/claudecode)
of Nicolas Bellamy's Dank Material Shell plugin. MIT, see [LICENSE](LICENSE).

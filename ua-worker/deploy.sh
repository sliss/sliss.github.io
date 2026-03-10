#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="/tmp/ua-router-build"

# --- Config ---
# Each line: <file-suffix>:<UA1|UA2|UA3>
# Multiple User-Agent strings per file are separated by |
# Add new bots by creating index.<suffix>.html and adding a line here
BOTS="
claudebot:ClaudeBot|Claude-SearchBot|Claude-User
oai-searchbot:OAI-SearchBot|ChatGPT-User|GPTBot
perplexitybot:PerplexityBot|Perplexity-User
googlebot:Googlebot|Google-CloudVertexBot
"

# --- Check for API token ---
if [ -z "${CLOUDFLARE_API_TOKEN:-}" ]; then
  echo "Error: CLOUDFLARE_API_TOKEN is not set."
  echo "Create one at https://dash.cloudflare.com/profile/api-tokens"
  echo "Usage: CLOUDFLARE_API_TOKEN=xxx ./deploy.sh"
  exit 1
fi

# --- Build worker.js from HTML files ---
echo "Building worker from HTML files..."

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

CONSTS=""
CHECKS=""

while IFS=: read -r suffix ua_strings; do
  # Skip empty lines
  [ -z "$suffix" ] && continue

  HTML_FILE="$SCRIPT_DIR/index.${suffix}.html"
  if [ ! -f "$HTML_FILE" ]; then
    echo "Warning: $HTML_FILE not found, skipping $suffix"
    continue
  fi

  VAR_NAME="HTML_$(echo "$suffix" | tr '[:lower:]-' '[:upper:]_')"
  CONTENT=$(cat "$HTML_FILE")

  CONSTS+="const ${VAR_NAME} = \`${CONTENT}\`;"$'\n\n'

  # Build a condition that checks for any of the UA strings
  CONDITIONS=""
  IFS='|' read -ra UA_ARRAY <<< "$ua_strings"
  for ua in "${UA_ARRAY[@]}"; do
    if [ -n "$CONDITIONS" ]; then
      CONDITIONS+=" || "
    fi
    CONDITIONS+="ua.includes(\"${ua}\")"
  done

  CHECKS+="
      if (${CONDITIONS}) {
        return new Response(${VAR_NAME}, {
          headers: { \"content-type\": \"text/html; charset=utf-8\" },
        });
      }"

  echo "  Added: ${suffix} -> matches '${ua_strings}'"
done <<< "$BOTS"

# Assemble worker.js
cat > "$BUILD_DIR/worker.js" << WORKEREOF
${CONSTS}
export default {
  async fetch(request, env, ctx) {
    const ua = request.headers.get("user-agent") || "";
    const url = new URL(request.url);

    // Only intercept the landing page
    if (url.pathname === "/" || url.pathname === "") {${CHECKS}
    }

    // Everyone else: pass through to origin
    const resp = await fetch(request);
    const newResp = new Response(resp.body, resp);
    newResp.headers.set("X-Detected-UA", ua.substring(0, 200));
    return newResp;
  },
};
WORKEREOF

# --- Write wrangler.toml ---
cat > "$BUILD_DIR/wrangler.toml" << 'EOF'
name = "ua-router"
main = "worker.js"
compatibility_date = "2024-01-01"

routes = [
  { pattern = "stevenliss.com/*", zone_name = "stevenliss.com" }
]
EOF

# --- Deploy ---
echo ""
echo "Deploying to Cloudflare..."
cd "$BUILD_DIR"
npx wrangler deploy

echo ""
echo "Done! Test with:"
while IFS=: read -r suffix ua_strings; do
  [ -z "$suffix" ] && continue
  IFS='|' read -ra UA_ARRAY <<< "$ua_strings"
  for ua in "${UA_ARRAY[@]}"; do
    echo "  curl -s -H 'User-Agent: ${ua}/1.0' https://stevenliss.com"
  done
done <<< "$BOTS"
echo "  curl -s https://stevenliss.com  # normal traffic"

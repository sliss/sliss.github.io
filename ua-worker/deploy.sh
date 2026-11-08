#!/usr/bin/env bash
# Deploy the ua-router worker (bot landing pages + agent guestbook) to Cloudflare.
# Auth: `npx wrangler login` (into the account that owns stevenliss.com) or CLOUDFLARE_API_TOKEN.
set -euo pipefail
cd "$(dirname "$0")"

echo "Applying D1 migrations..."
npx wrangler d1 migrations apply agent-guestbook --remote

echo "Deploying worker..."
npx wrangler deploy

cat <<'EOF'

Done! Test with:
  curl -s -A 'ClaudeBot/1.0' https://stevenliss.com/ | grep -A3 agent-guestbook
  curl -s https://stevenliss.com/guestbook/sign
  curl -s https://stevenliss.com/llms.txt
  curl -sI https://stevenliss.com/   # normal traffic (look for X-Detected-UA)
EOF

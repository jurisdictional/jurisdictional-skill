#!/bin/sh
# headersHelper for the Jurisdictional MCP server.
# Prints the Authorization header when ~/.jurisdictional/token holds a key (jur_...), and {} otherwise.
# With no header the server serves its public read tools; an empty or unknown bearer gets 401,
# so a file holding anything else (say, a pasted command) falls back to anonymous instead of failing.
# Claude Code strips TOKEN-like env vars from plugin helpers, so the token is read from the file.
token_file="${HOME}/.jurisdictional/token"
token=""

if [ -s "$token_file" ]; then
  token=$(tr -d '[:space:]' < "$token_file")
fi

case "$token" in
  jur_*[!A-Za-z0-9_-]* | "") printf '{}\n' ;;
  jur_*) printf '{"Authorization":"Bearer %s"}\n' "$token" ;;
  *) printf '{}\n' ;;
esac

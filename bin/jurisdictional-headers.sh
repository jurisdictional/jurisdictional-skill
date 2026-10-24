#!/bin/sh
# headersHelper for the Jurisdictional MCP server.
# Prints the Authorization header when ~/.jurisdictional/token exists, and {} otherwise.
# With no header the server serves its public read tools; an empty or unknown bearer gets 401.
# Claude Code strips TOKEN-like env vars from plugin helpers, so the token is read from the file.
token_file="${HOME}/.jurisdictional/token"

if [ -s "$token_file" ]; then
  token=$(tr -d '[:space:]' < "$token_file")
  printf '{"Authorization":"Bearer %s"}\n' "$token"
else
  printf '{}\n'
fi

-- Single statement by design (Snowsight "Run All"): the command output contains the token secret (shown once).
ALTER USER CURRENT_USER()
  ADD PROGRAMMATIC ACCESS TOKEN MCP_PAT;

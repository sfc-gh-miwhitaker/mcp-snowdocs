/*******************************************************************************
 * DEMO PROJECT: Snowflake MCP Server Setup
 * Script: sql/01_setup/create_token.sql
 *
 * WARNING: NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Create a programmatic access token (PAT) scoped to the currently active user.
 *
 * OBJECTS CREATED:
 *   - Programmatic access token with a 365-day expiry.
 *
 * CLEANUP:
 *   - Tokens persist until manually revoked; see sql/99_cleanup/teardown_all.sql
 *     for guidance on optional token removal.
 *
 * HOW TO RUN:
 *   1. Execute via Snowsight or the automation wrapper.
 *   2. Copy the TOKEN_SECRET value immediately; Snowflake does not display it again.
 *   3. Store the token securely and proceed with sql/01_setup/setup_mcp.sql.
 ******************************************************************************/

-- Get current user name
SET session_user_name = (SELECT CURRENT_USER());

-- Generate unique token name with timestamp
SET token_name = 'MCP_PAT_' || TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYYMMDD_HH24MISS');

-- Create PAT token
-- The result will contain TOKEN_SECRET - copy it immediately.
ALTER USER IDENTIFIER($session_user_name) ADD PROGRAMMATIC ACCESS TOKEN IDENTIFIER($token_name)
  DAYS_TO_EXPIRY = 365
  COMMENT = 'MCP server authentication token';

/*
NEXT STEPS:
1. Copy the TOKEN_SECRET from the result above.
2. Save it in your password manager.
3. Run sql/01_setup/setup_mcp.sql to configure MCP server access.
4. Use the TOKEN_SECRET in your MCP client configuration.
*/

/*******************************************************************************
 * Script: deploy_all.sql
 * Purpose: Deploy a Snowflake-managed MCP server for searching Snowflake docs from MCP-enabled IDEs.
 *
 * Author: SE Community
 * Created: 2026-01-08
 * EXPIRES: 2026-02-07
 *
 * EXECUTION METHOD: Snowsight "Run All" (Copy/Paste → Click "Run All")
 *
 * OUTPUT:
 *   - Single result set containing MCP_URL and TOKEN_SECRET (shown only once)
 *
 * ESTIMATED RUNTIME: ~2 minutes
 * ESTIMATED COST: Low (XSMALL warehouse, short runtime)
 ******************************************************************************/

/*******************************************************************************
 * EXPIRATION CHECK (halts Run All when expired)
 ******************************************************************************/

EXECUTE IMMEDIATE $$
DECLARE
  demo_expired EXCEPTION (-20001, 'This demo expired on 2026-02-07. Update deploy_all.sql to extend expiration.');
  expires_on DATE := '2026-02-07'::DATE;
BEGIN
  IF (CURRENT_DATE() > expires_on) THEN
    RAISE demo_expired;
  END IF;
END;
$$;

/*******************************************************************************
 * PART 1: Context + Infrastructure
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;

CREATE WAREHOUSE IF NOT EXISTS SFE_SNOWDOCS_MCP_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'DEMO: Snowflake MCP Server (docs search). Author: SE Community. EXPIRES: 2026-02-07';

USE WAREHOUSE SFE_SNOWDOCS_MCP_WH;

-- Demo standard: all demo objects live in SNOWFLAKE_EXAMPLE (create if missing)
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
  COMMENT = 'DEMO: Shared demo database for reference implementations. Author: SE Community. EXPIRES: 2026-02-07';

-- Project-specific schema namespace (collision-proof)
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP
  COMMENT = 'DEMO: Snowflake MCP server objects (docs search). Author: SE Community. EXPIRES: 2026-02-07';

/*******************************************************************************
 * PART 2: Custom Tool Functions
 ******************************************************************************/

CREATE OR REPLACE FUNCTION SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP.GET_ACCOUNT_INFO()
RETURNS OBJECT
LANGUAGE SQL
COMMENT = 'DEMO: Returns Snowflake environment metadata (version, region, account name, etc.). EXPIRES: 2026-02-07'
AS $$
SELECT OBJECT_CONSTRUCT(
  'version', CURRENT_VERSION(),
  'region', CURRENT_REGION(),
  'account_name', CURRENT_ACCOUNT_NAME(),
  'organization', CURRENT_ORGANIZATION_NAME(),
  'warehouse', CURRENT_WAREHOUSE(),
  'role', CURRENT_ROLE(),
  'user', CURRENT_USER())
$$;

/*******************************************************************************
 * PART 3: MCP Server
 ******************************************************************************/

CREATE OR REPLACE MCP SERVER SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP.SNOWFLAKE_DOCS_MCP_SERVER
  FROM SPECIFICATION $$
    tools:
      - name: "snowflake-docs-search"
        type: "CORTEX_SEARCH_SERVICE_QUERY"
        identifier: "SNOWFLAKE_DOCUMENTATION.SHARED.CKE_SNOWFLAKE_DOCS_SERVICE"
        description: "Search Snowflake documentation using Cortex Search"
        title: "Snowflake Documentation Search"

      - name: "snowflake-function-finder"
        type: "CORTEX_SEARCH_SERVICE_QUERY"
        identifier: "SNOWFLAKE_DOCUMENTATION.SHARED.CKE_SNOWFLAKE_DOCS_SERVICE"
        description: "Search Snowflake documentation for built-in functions and usage examples by keyword"
        title: "Snowflake Function Finder"

      - name: "get-account-info"
        type: "CUSTOM"
        identifier: "SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP.GET_ACCOUNT_INFO"
        description: "Returns current Snowflake account environment information"
        title: "Snowflake Account Info"
        config:
          type: "function"
          warehouse: "SFE_SNOWDOCS_MCP_WH"
          input_schema:
            type: "object"
            properties: {}
  $$;

/*******************************************************************************
 * PART 4: Minimal-Privilege Access Role
 ******************************************************************************/

CREATE ROLE IF NOT EXISTS SFE_SNOWDOCS_MCP_ACCESS_ROLE
  COMMENT = 'DEMO: Minimal privileges for Snowflake MCP server API access. Author: SE Community. EXPIRES: 2026-02-07';

GRANT USAGE ON WAREHOUSE SFE_SNOWDOCS_MCP_WH TO ROLE SFE_SNOWDOCS_MCP_ACCESS_ROLE;

GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE SFE_SNOWDOCS_MCP_ACCESS_ROLE;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP TO ROLE SFE_SNOWDOCS_MCP_ACCESS_ROLE;

GRANT USAGE ON MCP SERVER SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP.SNOWFLAKE_DOCS_MCP_SERVER
  TO ROLE SFE_SNOWDOCS_MCP_ACCESS_ROLE;

-- Documentation database is provided by Snowflake; this grants access to the underlying Cortex Search service.
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_DOCUMENTATION TO ROLE SFE_SNOWDOCS_MCP_ACCESS_ROLE;

GRANT USAGE ON FUNCTION SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP.GET_ACCOUNT_INFO() TO ROLE SFE_SNOWDOCS_MCP_ACCESS_ROLE;

-- Assign role to the current user for immediate testing.
SET current_username = CURRENT_USER();
GRANT ROLE SFE_SNOWDOCS_MCP_ACCESS_ROLE TO USER IDENTIFIER($current_username);

/*******************************************************************************
 * PART 5: Authentication Token (PAT)
 *
 * SECURITY WARNING: The token secret is shown only once. Copy it immediately.
 ******************************************************************************/

SET token_name = 'MCP_PAT_' || TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYYMMDD_HH24MISS');

ALTER USER IDENTIFIER($current_username)
  ADD PROGRAMMATIC ACCESS TOKEN IDENTIFIER($token_name)
  DAYS_TO_EXPIRY = 365
  COMMENT = 'DEMO: MCP server authentication token. Author: SE Community. EXPIRES: 2026-02-07';

-- Capture token secret from the previous statement so it can be included in the final (visible) result set.
SET token_secret = (
  SELECT "token_secret"::STRING
  FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
);

/*******************************************************************************
 * PART 6: Final Output (only visible result in Snowsight Run All)
 ******************************************************************************/

SET mcp_url =
  'https://' ||
  REPLACE(LOWER(CURRENT_ORGANIZATION_NAME()), '_', '-') || '-' ||
  REPLACE(LOWER(CURRENT_ACCOUNT_NAME()), '_', '-') ||
  '.snowflakecomputing.com/api/v2/databases/SNOWFLAKE_EXAMPLE/schemas/snowdocs_mcp/mcp-servers/snowflake_docs_mcp_server';

SELECT
  $mcp_url::STRING AS mcp_url,
  $token_secret::STRING AS token_secret,
  $token_name::STRING AS token_name,
  'SFE_SNOWDOCS_MCP_ACCESS_ROLE' AS access_role,
  'SFE_SNOWDOCS_MCP_WH' AS warehouse,
  'Copy MCP_URL + TOKEN_SECRET into your MCP client configuration. See README.md.' AS next_step;

-- =============================================================================
-- VERIFICATION QUERIES (Run individually AFTER deployment completes)
-- =============================================================================
/*
SHOW MCP SERVERS IN SCHEMA SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP;
SHOW ROLES LIKE 'SFE_SNOWDOCS_MCP_ACCESS_ROLE';
DESC MCP SERVER SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP.SNOWFLAKE_DOCS_MCP_SERVER;
*/


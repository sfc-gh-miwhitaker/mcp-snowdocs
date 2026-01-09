/*******************************************************************************
 * Script: cleanup.sql
 * Purpose: Remove all resources created by `deploy_all.sql`.
 *
 * Author: SE Community
 * Created: 2026-01-08
 * EXPIRES: 2026-02-07
 *
 * EXECUTION METHOD: Snowsight "Run All" (Copy/Paste → Click "Run All")
 * ESTIMATED RUNTIME: ~1 minute
 ******************************************************************************/

-- Best practice: never create/drop objects as ACCOUNTADMIN.
-- Use SYSADMIN for database objects + warehouse ownership, and SECURITYADMIN for RBAC objects (roles/grants).
USE ROLE SYSADMIN;

/*******************************************************************************
 * PART 1: Drop schema-scoped objects (MCP server, functions, etc.)
 ******************************************************************************/

-- Drop the MCP server explicitly (clarity) then drop the schema (cleanup).
DROP MCP SERVER IF EXISTS SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP.SNOWFLAKE_DOCS_MCP_SERVER;
DROP FUNCTION IF EXISTS SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP.GET_ACCOUNT_INFO();

-- Project schema namespace (safe: does not drop SNOWFLAKE_EXAMPLE database)
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SNOWDOCS_MCP CASCADE;

/*******************************************************************************
 * PART 2: Drop account-level demo objects (warehouse + role)
 ******************************************************************************/

-- Role management is owned by SECURITYADMIN (RBAC boundary).
USE ROLE SECURITYADMIN;
DROP ROLE IF EXISTS SFE_SNOWDOCS_MCP_ACCESS_ROLE;

-- Warehouse ownership is typically under SYSADMIN.
USE ROLE SYSADMIN;
DROP WAREHOUSE IF EXISTS SFE_SNOWDOCS_MCP_WH;

/*******************************************************************************
 * PART 3: Final Output (only visible result in Snowsight Run All)
 ******************************************************************************/

SELECT
  'CLEANUP COMPLETE' AS status,
  CURRENT_TIMESTAMP() AS completed_at,
  'SNOWFLAKE_DOCUMENTATION is preserved (Snowflake-managed)' AS preserved_note,
  'PAT tokens are preserved; see commented section below' AS token_note;

-- =============================================================================
-- OPTIONAL: Manual PAT Token Cleanup (Run individually)
-- =============================================================================
/*
SHOW USER PROGRAMMATIC ACCESS TOKENS;
-- ALTER USER CURRENT_USER() DROP PROGRAMMATIC ACCESS TOKEN 'MCP_PAT_20260108_123456';
-- ALTER USER CURRENT_USER() DROP ALL PROGRAMMATIC ACCESS TOKENS;
*/

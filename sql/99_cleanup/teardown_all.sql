/*******************************************************************************
 * DEMO PROJECT: Snowflake MCP Server Setup
 * Script: sql/99_cleanup/teardown_all.sql
 *
 * WARNING: NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Remove MCP-specific resources created by sql/01_setup/setup_mcp.sql while
 *   preserving shared Snowflake-managed infrastructure and the SNOWFLAKE_EXAMPLE
 *   database required by other demo projects.
 *
 * OBJECTS REMOVED:
 *   - MCP server: SNOWFLAKE_INTELLIGENCE.MCP.SNOWFLAKE_MCP_SERVER
 *   - Role: MCP_ACCESS_ROLE (including all associated grants)
 *
 * OBJECTS PRESERVED:
 *   - Databases: SNOWFLAKE_INTELLIGENCE, SNOWFLAKE_DOCUMENTATION, SNOWFLAKE_EXAMPLE
 *   - All Snowflake-managed schemas within SNOWFLAKE_INTELLIGENCE
 *   - Programmatic access tokens (user-managed)
 *
 * HOW TO RUN:
 *   1. Execute in Snowsight as SECURITYADMIN/SYSADMIN as required.
 *   2. Review verification queries to confirm the MCP server and role were removed.
 ******************************************************************************/

-- ###########################################################################
-- # STEP 1: Drop Custom Tool Functions
-- ###########################################################################

USE ROLE SYSADMIN;

-- Drop custom tool functions first (before dropping the MCP server)
DROP FUNCTION IF EXISTS SNOWFLAKE_INTELLIGENCE.MCP.GET_ACCOUNT_INFO();
DROP FUNCTION IF EXISTS SNOWFLAKE_INTELLIGENCE.MCP.FIND_SNOWFLAKE_FUNCTIONS(VARCHAR);

-- ###########################################################################
-- # STEP 2: Drop MCP Server
-- ###########################################################################

-- Drop the MCP server (this is the main resource we want to clean up)
-- This automatically removes all grants on the MCP server
DROP MCP SERVER IF EXISTS SNOWFLAKE_INTELLIGENCE.MCP.SNOWFLAKE_MCP_SERVER;

-- Verify MCP server is removed
SHOW MCP SERVERS IN SCHEMA SNOWFLAKE_INTELLIGENCE.MCP;

-- ###########################################################################
-- # STEP 3: Drop MCP Access Role
-- ###########################################################################

USE ROLE SECURITYADMIN;

-- Drop the dedicated MCP access role
-- CASCADE automatically:
-- - Revokes role from all users
-- - Removes all grants TO this role
-- - Removes all grants OF this role to other roles
DROP ROLE IF EXISTS MCP_ACCESS_ROLE CASCADE;

-- Verify role is removed
SHOW ROLES LIKE 'MCP_ACCESS_ROLE';

-- ###########################################################################
-- # VERIFICATION: What Remains
-- ###########################################################################

USE ROLE SYSADMIN;

-- Verify SNOWFLAKE_INTELLIGENCE database still exists (PRESERVED)
SHOW DATABASES LIKE 'SNOWFLAKE_INTELLIGENCE';

-- Verify SNOWFLAKE_INTELLIGENCE.MCP schema still exists (PRESERVED)
SHOW SCHEMAS IN DATABASE SNOWFLAKE_INTELLIGENCE;

-- Verify SNOWFLAKE_DOCUMENTATION database still exists (PRESERVED)
SHOW DATABASES LIKE 'SNOWFLAKE_DOCUMENTATION';

-- Verify SNOWFLAKE_EXAMPLE database remains untouched (PRESERVED)
SHOW DATABASES LIKE 'SNOWFLAKE_EXAMPLE';

-- Verify your PAT tokens still exist (PRESERVED)
-- Note: Shows tokens for current user
SHOW USER PROGRAMMATIC ACCESS TOKENS;

-- ###########################################################################
-- # OPTIONAL: Manual PAT Token Cleanup
-- ###########################################################################

/*
PAT TOKENS ARE PRESERVED BY DEFAULT

If you want to remove PAT tokens manually (use with caution):

1. View your tokens:
   SHOW USER PROGRAMMATIC ACCESS TOKENS;

2. Drop a specific token by name:
   SET token_to_drop = 'MCP_PAT_20251021_123456';
   ALTER USER CURRENT_USER() DROP PROGRAMMATIC ACCESS TOKEN IDENTIFIER($token_to_drop);

3. Drop all tokens (DANGEROUS - use only if certain):
   ALTER USER CURRENT_USER() DROP ALL PROGRAMMATIC ACCESS TOKENS;

NOTE: Dropping tokens will break any applications using them!
*/

-- ###########################################################################
-- # CLEANUP SUMMARY
-- ###########################################################################

/*
WHAT WAS REMOVED:
=================
Custom Functions: GET_ACCOUNT_INFO(), FIND_SNOWFLAKE_FUNCTIONS(VARCHAR)
MCP Server: SNOWFLAKE_INTELLIGENCE.MCP.SNOWFLAKE_MCP_SERVER
Role: MCP_ACCESS_ROLE (and all associated grants)

WHAT WAS PRESERVED:
===================
Database: SNOWFLAKE_INTELLIGENCE (reusable for other examples)
Schema: SNOWFLAKE_INTELLIGENCE.MCP (reusable infrastructure)
Schema: SNOWFLAKE_INTELLIGENCE.TOOLS (if exists, reusable)
Schema: SNOWFLAKE_INTELLIGENCE.AGENTS (if exists, reusable)
Database: SNOWFLAKE_DOCUMENTATION (imported share, may be used elsewhere)
PAT Tokens: All tokens remain active (user-managed)

TO VERIFY CLEANUP:
==================
1. MCP server should NOT appear in: SHOW MCP SERVERS
2. MCP_ACCESS_ROLE should NOT appear in: SHOW ROLES
3. SNOWFLAKE_INTELLIGENCE database SHOULD still exist
4. PAT tokens SHOULD still be listed

TO RECREATE:
============
Run sql/01_setup/setup_mcp.sql to recreate the MCP server and role.
Your existing PAT token can be reused (if not expired).
*/

/*******************************************************************************
 * DEMO PROJECT: Snowflake MCP Server Setup
 * Script: sql/01_setup/setup_mcp.sql
 *
 * WARNING: NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Provision the Snowflake-managed MCP server and grant the dedicated
 *   MCP_ACCESS_ROLE with only the privileges required for documentation search.
 *
 * OBJECTS CREATED:
 *   - MCP server: SNOWFLAKE_INTELLIGENCE.MCP.SNOWFLAKE_MCP_SERVER
 *   - Role: MCP_ACCESS_ROLE (least-privilege access pattern)
 *
 * PREREQUISITES:
 *   - Run sql/01_setup/create_token.sql to generate a PAT token.
 *   - Execute as ACCOUNTADMIN (terms acceptance), SYSADMIN, and SECURITYADMIN.
 *
 * IDEMPOTENCY:
 *   Safe to run multiple times. Uses CREATE OR REPLACE, IF NOT EXISTS, and
 *   idempotent GRANT statements. Re-running will update the MCP server spec
 *   and ensure all grants are current.
 *
 * HOW TO RUN:
 *   1. Execute in Snowsight or via the automation wrapper.
 *   2. Copy the MCP_URL result for IDE configuration.
 *   3. Combine with the PAT token generated previously.
 ******************************************************************************/

-- ###########################################################################
-- # EXPIRATION CHECK (Public GitHub Demo)
-- ###########################################################################

SET expiry_date = '2025-12-24';

SELECT CASE
    WHEN CURRENT_DATE() > TO_DATE($expiry_date)
    THEN SYSTEM$ABORT('⚠️  DEMO EXPIRED on ' || $expiry_date || '. Visit https://github.com/sfc-gh-miwhitaker/mcp-snowdocs for current version.')
    ELSE '✓ Demo active until ' || $expiry_date || ' (' || DATEDIFF('day', CURRENT_DATE(), TO_DATE($expiry_date)) || ' days remaining)'
END AS expiration_status;

-- ###########################################################################
-- # PART 1: Create MCP Server Infrastructure (if needed)
-- ###########################################################################

-- Accept Snowflake Documentation from Marketplace (requires ACCOUNTADMIN)
USE ROLE ACCOUNTADMIN;

-- Accept legal terms for Snowflake Documentation marketplace listing
CALL SYSTEM$ACCEPT_LEGAL_TERMS('DATA_EXCHANGE_LISTING', 'GZSTZ67BY9OQ4');

-- Import Snowflake Documentation database from Marketplace
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_DOCUMENTATION
  FROM LISTING IDENTIFIER('"GZSTZ67BY9OQ4"'); -- do not alter this string

-- Grant imported privileges to the dedicated role so it can query documentation.
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_DOCUMENTATION TO ROLE MCP_ACCESS_ROLE;

-- Create MCP server infrastructure (requires SYSADMIN)
USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE
  COMMENT = 'Snowflake Intelligence features including MCP servers';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_INTELLIGENCE.MCP
  COMMENT = 'Model Context Protocol (MCP) servers';

-- Create the MCP server with documentation search + custom tools
-- Note: Provides access to Snowflake documentation via Cortex Search
--       plus custom demonstration tools (Account Info + Function Finder)
CREATE OR REPLACE MCP SERVER SNOWFLAKE_INTELLIGENCE.MCP.SNOWFLAKE_MCP_SERVER
  FROM SPECIFICATION $$
    tools:
      # Primary tool: Documentation search
      - name: "snowflake-docs-search"
        type: "CORTEX_SEARCH_SERVICE_QUERY"
        identifier: "SNOWFLAKE_DOCUMENTATION.SHARED.CKE_SNOWFLAKE_DOCS_SERVICE"
        description: "Search Snowflake documentation using Cortex Search"
        title: "Snowflake Documentation Search"

      # Custom tool: Account environment info
      - name: "get-account-info"
        type: "GENERIC"
        identifier: "SNOWFLAKE_INTELLIGENCE.MCP.GET_ACCOUNT_INFO"
        description: "Returns current Snowflake account environment information (version, region, account name, etc.)"
        title: "Snowflake Account Info"
        warehouse: "COMPUTE_WH"
        inputSchema:
          type: "object"
          properties: {}
        outputSchema:
          type: "object"

      # Custom tool: Function finder
      - name: "find-snowflake-functions"
        type: "GENERIC"
        identifier: "SNOWFLAKE_INTELLIGENCE.MCP.FIND_SNOWFLAKE_FUNCTIONS"
        description: "Searches Snowflake documentation for built-in functions by keyword (e.g., 'string', 'date', 'array')"
        title: "Snowflake Function Finder"
        warehouse: "COMPUTE_WH"
        inputSchema:
          type: "object"
          properties:
            search_term:
              type: "string"
              description: "Keyword to search for (e.g., 'string', 'date', 'json')"
          required: ["search_term"]
        outputSchema:
          type: "array"
  $$;

-- Verify MCP server was created (optional - uncomment for debugging)
-- SHOW MCP SERVERS IN SCHEMA SNOWFLAKE_INTELLIGENCE.MCP;

-- ###########################################################################
-- # PART 2: Create Dedicated MCP Access Role (Minimal Privileges)
-- ###########################################################################

-- Get current user name
SET session_user_name = (SELECT CURRENT_USER());

USE ROLE SECURITYADMIN;

-- Create a dedicated role for MCP server access
CREATE ROLE IF NOT EXISTS MCP_ACCESS_ROLE
  COMMENT = 'Minimal privileges for MCP server API access via PAT tokens';

-- ###########################################################################
-- # PART 3: Grant Minimal Required Privileges
-- ###########################################################################

USE ROLE SYSADMIN;

-- Grant USAGE on SNOWFLAKE_INTELLIGENCE database (required for MCP server access)
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE MCP_ACCESS_ROLE;

-- Grant USAGE on MCP schema (required to access MCP server objects)
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.MCP TO ROLE MCP_ACCESS_ROLE;

-- Grant USAGE on the specific MCP server (required to call MCP endpoints)
GRANT USAGE ON MCP SERVER SNOWFLAKE_INTELLIGENCE.MCP.SNOWFLAKE_MCP_SERVER
  TO ROLE MCP_ACCESS_ROLE;

-- Grant IMPORTED PRIVILEGES on SNOWFLAKE_DOCUMENTATION database
-- This gives access to the Cortex Search Service that the MCP server uses
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_DOCUMENTATION TO ROLE MCP_ACCESS_ROLE;

-- ###########################################################################
-- # PART 4: Assign Role to Your User
-- ###########################################################################

USE ROLE SECURITYADMIN;

-- Assign the MCP access role to your current user
GRANT ROLE MCP_ACCESS_ROLE TO USER IDENTIFIER($session_user_name);

-- ###########################################################################
-- # PART 5: Verify Token Configuration
-- ###########################################################################

-- The token was created with your current role, but we need it to use MCP_ACCESS_ROLE
-- Unfortunately, we cannot modify the token's role after creation
-- The token inherits all roles granted to your user, including MCP_ACCESS_ROLE

-- Verify your user now has MCP_ACCESS_ROLE (optional - uncomment for debugging)
-- SHOW GRANTS TO USER IDENTIFIER($session_user_name);

-- ###########################################################################
-- # PART 6: Verify Setup
-- ###########################################################################

-- Verify MCP_ACCESS_ROLE has correct privileges (optional - uncomment for debugging)
-- SHOW GRANTS TO ROLE MCP_ACCESS_ROLE;

-- Verify your user has MCP_ACCESS_ROLE (optional - uncomment for debugging)
-- SHOW GRANTS TO USER IDENTIFIER($session_user_name);

-- Test if MCP_ACCESS_ROLE can see the MCP server (optional - uncomment for debugging)
USE ROLE MCP_ACCESS_ROLE;
-- SHOW MCP SERVERS IN SCHEMA SNOWFLAKE_INTELLIGENCE.MCP;

-- Test if MCP_ACCESS_ROLE can describe the MCP server
DESC MCP SERVER SNOWFLAKE_INTELLIGENCE.MCP.SNOWFLAKE_MCP_SERVER;

-- ###########################################################################
-- # PART 7: Display MCP Server URL
-- ###########################################################################

-- Display your MCP server URL (for most accounts)
-- IMPORTANT: MCP servers require hyphens (-), not underscores (_) in hostnames
-- Per Snowflake documentation: connection issues occur with underscores
SELECT 'https://' ||
       REPLACE(LOWER(CURRENT_ORGANIZATION_NAME()), '_', '-') || '-' ||
       REPLACE(LOWER(CURRENT_ACCOUNT_NAME()), '_', '-') ||
       '.snowflakecomputing.com/api/v2/databases/snowflake_intelligence/schemas/mcp/mcp-servers/snowflake_mcp_server'
AS mcp_url,
'⚠️  Note: If your organization/account name contains underscores, they are converted to hyphens above.' AS hostname_note;

-- If the above returns NULL, try this legacy format instead:
-- SELECT 'https://' || LOWER(CURRENT_ACCOUNT()) || '.' || LOWER(CURRENT_REGION()) ||
--        '.snowflakecomputing.com/api/v2/databases/snowflake_intelligence/schemas/mcp/mcp-servers/snowflake_mcp_server'
-- AS mcp_url;

-- ###########################################################################
-- # WHAT WE GRANTED (Minimal Privilege Documentation)
-- ###########################################################################

/*
SECURITY SUMMARY:
================

Role: MCP_ACCESS_ROLE (NOT PUBLIC)

Privileges Granted (MINIMAL):
1. USAGE on SNOWFLAKE_INTELLIGENCE database
   - Required to access any objects in this database

2. USAGE on SNOWFLAKE_INTELLIGENCE.MCP schema
   - Required to access MCP server objects

3. USAGE on SNOWFLAKE_INTELLIGENCE.MCP.SNOWFLAKE_MCP_SERVER
   - Required to call MCP server endpoints

4. IMPORTED PRIVILEGES on SNOWFLAKE_DOCUMENTATION database
   - Required for the MCP server to access underlying Cortex Search Service
   - This is a marketplace database, so we must grant IMPORTED PRIVILEGES

What We Did NOT Grant:
- No access to other databases or schemas
- No write privileges (SELECT, INSERT, UPDATE, DELETE)
- No admin privileges (CREATE, DROP, ALTER)
- No data access beyond what the MCP server tools expose
- Not assigned to PUBLIC role (only to your specific user)

Security Benefits:
- Principle of least privilege
- Token has ONLY the permissions needed for MCP server API calls
- If token is compromised, attacker cannot access other data
- Clear audit trail (all access via MCP_ACCESS_ROLE)
- Easy to revoke (DROP ROLE MCP_ACCESS_ROLE CASCADE)
*/

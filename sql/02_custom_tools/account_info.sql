/*******************************************************************************
 * DEMO PROJECT: Snowflake MCP Server Setup
 * Script: sql/02_custom_tools/account_info.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Create a simple UDF that returns Snowflake environment metadata.
 *   Demonstrates custom tool capability for MCP server.
 *
 * OBJECTS CREATED:
 *   - SNOWFLAKE_INTELLIGENCE.MCP.GET_ACCOUNT_INFO() (UDF)
 *
 * IDEMPOTENCY:
 *   Safe to run multiple times. Uses CREATE OR REPLACE.
 *
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 ******************************************************************************/

USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_INTELLIGENCE;
USE SCHEMA MCP;

-- Create account info UDF
CREATE OR REPLACE FUNCTION GET_ACCOUNT_INFO()
RETURNS VARIANT
LANGUAGE SQL
COMMENT
= 'DEMO: Returns Snowflake environment metadata for MCP custom tool demonstration'
AS
$$
  SELECT OBJECT_CONSTRUCT(
    'version', CURRENT_VERSION(),
    'region', CURRENT_REGION(),
    'account_name', CURRENT_ACCOUNT_NAME(),
    'organization', CURRENT_ORGANIZATION_NAME(),
    'warehouse', CURRENT_WAREHOUSE(),
    'role', CURRENT_ROLE(),
    'user', CURRENT_USER()
  )
$$;

-- Grant usage to MCP role
GRANT USAGE ON FUNCTION GET_ACCOUNT_INFO() TO ROLE MCP_ACCESS_ROLE;

-- Test the function
SELECT GET_ACCOUNT_INFO() AS ACCOUNT_INFO;

/*
EXPECTED OUTPUT:
A JSON object containing:
- version: Snowflake version number
- region: Current region (e.g., 'AWS_US_WEST_2')
- account_name: Account name
- organization: Organization name
- warehouse: Current warehouse
- role: Current role
- user: Current user

USAGE IN MCP CLIENT:
Ask your AI assistant: "What Snowflake account am I connected to?"
*/

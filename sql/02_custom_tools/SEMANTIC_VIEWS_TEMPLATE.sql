/*******************************************************************************
 * SEMANTIC VIEW TOOL TEMPLATE
 * 
 * Purpose: Template for exposing semantic models via MCP for Cortex Analyst
 * 
 * WHAT ARE SEMANTIC VIEWS?
 * ========================
 * Semantic views are specially annotated views that provide business context
 * to Snowflake Cortex Analyst, enabling natural language queries against your
 * data. They include metadata like column descriptions, business definitions,
 * and sample questions.
 * 
 * INSTRUCTIONS:
 * =============
 * 1. Create your semantic view with CORTEX.ANALYST annotations
 * 2. Add a tool to config/mcp_spec.yaml of type "CORTEX_ANALYST_MESSAGE"
 * 3. Re-run sql/01_setup/setup_mcp.sql to update the MCP server
 * 4. Ask natural language questions through your MCP client
 * 
 * LOCATION STANDARD:
 * ==================
 * All semantic views MUST be created in:
 *   SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS schema
 * 
 * Naming pattern: SV_<DOMAIN>_<ENTITY>
 * Example: SV_SALES_ACCOUNT_OVERVIEW, SV_SUPPORT_TICKET_METRICS
 * 
 * Rationale: Predictable location for demos, easy discovery, consistent namespace
 ******************************************************************************/

-- ###########################################################################
-- # STEP 1: Create Schema for Semantic Views (if needed)
-- ###########################################################################

USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
  COMMENT = 'DEMO: Example projects - NOT FOR PRODUCTION';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS
  COMMENT = 'DEMO: Semantic views for Cortex Analyst agents';

USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SEMANTIC_MODELS;

-- ###########################################################################
-- # STEP 2: Create Your Semantic View
-- ###########################################################################

-- Example: Sales metrics semantic view
CREATE OR REPLACE VIEW SV_YOUR_DOMAIN_YOUR_ENTITY
COMMENT = $$
{
  "origin": "Semantic view for Cortex Analyst MCP tool",
  "model": {
    "name": "Your Model Name",
    "description": "Brief description of the business domain this view covers",
    "tables": [
      {
        "name": "SV_YOUR_DOMAIN_YOUR_ENTITY",
        "description": "Detailed description of what this view represents",
        "base_table": "YOUR_SOURCE_DATABASE.YOUR_SOURCE_SCHEMA.YOUR_SOURCE_TABLE"
      }
    ],
    "columns": [
      {
        "name": "COLUMN_1",
        "data_type": "VARCHAR",
        "description": "Business-friendly description of this column",
        "synonyms": ["alternative_name_1", "alternative_name_2"]
      },
      {
        "name": "COLUMN_2",
        "data_type": "NUMBER",
        "description": "Business-friendly description of this metric",
        "aggregation": "sum"
      },
      {
        "name": "DATE_COLUMN",
        "data_type": "DATE",
        "description": "Business-friendly description of this date",
        "time_dimension": true
      }
    ],
    "sample_questions": [
      "What were total sales last quarter?",
      "Show me top 10 customers by revenue",
      "How do sales compare year over year?"
    ]
  }
}
$$
AS
SELECT
    -- Replace with your actual column selections
    'example_value' AS column_1,
    100 AS column_2,
    CURRENT_DATE() AS date_column
FROM
    -- Replace with your actual source table
    (SELECT 'example_value' AS col1, 100 AS col2, CURRENT_DATE() AS dt);

-- ###########################################################################
-- # STEP 3: Grant Access to MCP Role
-- ###########################################################################

GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE MCP_ACCESS_ROLE;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE MCP_ACCESS_ROLE;
GRANT SELECT ON VIEW SV_YOUR_DOMAIN_YOUR_ENTITY TO ROLE MCP_ACCESS_ROLE;

-- ###########################################################################
-- # STEP 4: Test Your Semantic View
-- ###########################################################################

-- Verify the view works:
SELECT * FROM SV_YOUR_DOMAIN_YOUR_ENTITY LIMIT 10;

-- Check the COMMENT metadata:
SHOW VIEWS LIKE 'SV_YOUR_DOMAIN_YOUR_ENTITY';
DESC VIEW SV_YOUR_DOMAIN_YOUR_ENTITY;

-- ###########################################################################
-- # STEP 5: Add to config/mcp_spec.yaml
-- ###########################################################################

/*
Add this to config/mcp_spec.yaml under the tools: section:

  - name: "your-semantic-model"
    type: "CORTEX_ANALYST_MESSAGE"
    identifier: "SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_YOUR_DOMAIN_YOUR_ENTITY"
    description: "Natural language queries against [your business domain] data"
    title: "Your Business Domain Analytics"
    warehouse: "COMPUTE_WH"

Then re-run sql/01_setup/setup_mcp.sql to update the MCP server.
*/

-- ###########################################################################
-- # STEP 6: Usage Through MCP Client
-- ###########################################################################

/*
Once configured, you can ask natural language questions through your MCP client:

Example questions:
> "What were the total sales last quarter?"
> "Show me the top 10 customers by revenue"
> "How do sales compare year over year?"

Cortex Analyst will automatically:
1. Parse your natural language question
2. Generate SQL against your semantic view
3. Execute the query
4. Return the results with explanations
*/

-- ###########################################################################
-- # STEP 7: Add Cleanup Logic
-- ###########################################################################

/*
Add this to sql/99_cleanup/teardown_all.sql:

-- Revoke grants
REVOKE SELECT ON VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_YOUR_DOMAIN_YOUR_ENTITY 
  FROM ROLE MCP_ACCESS_ROLE;

-- Drop view
DROP VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_YOUR_DOMAIN_YOUR_ENTITY;

Note: Do NOT drop SNOWFLAKE_EXAMPLE database or SEMANTIC_MODELS schema
      as they may be used by other demos.
*/

-- ###########################################################################
-- # ADDITIONAL RESOURCES
-- ###########################################################################

/*
Cortex Analyst Documentation:
https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst

Semantic Model Best Practices:
- Use clear, business-friendly column descriptions
- Include synonyms for common business terms
- Provide representative sample questions
- Test queries manually before exposing via MCP
- Document calculated metrics and aggregations
- Consider data freshness and update frequency
*/


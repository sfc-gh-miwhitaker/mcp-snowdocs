/*******************************************************************************
 * DEMO PROJECT: Snowflake MCP Server Setup
 * Script: sql/02_custom_tools/function_finder.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Create a table function that searches Snowflake documentation for
 *   built-in functions by keyword. Demonstrates custom tool with parameters.
 *
 * OBJECTS CREATED:
 *   - SNOWFLAKE_INTELLIGENCE.MCP.FIND_SNOWFLAKE_FUNCTIONS(VARCHAR) (Table Function)
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

-- Create function finder using Cortex Search on documentation
CREATE OR REPLACE FUNCTION FIND_SNOWFLAKE_FUNCTIONS(search_term VARCHAR)
RETURNS TABLE (
    FUNCTION_NAME VARCHAR,
    DESCRIPTION VARCHAR,
    CATEGORY VARCHAR,
    RELEVANCE FLOAT
)
LANGUAGE SQL
COMMENT
= 'DEMO: Searches Snowflake documentation for built-in functions matching a keyword'
AS
$$
  SELECT
    results.value:title::VARCHAR AS function_name,
    results.value:description::VARCHAR AS description,
    results.value:category::VARCHAR AS category,
    results.value:score::FLOAT AS relevance
  FROM TABLE(
    SNOWFLAKE_DOCUMENTATION.SHARED.CKE_SNOWFLAKE_DOCS_SERVICE!SEARCH(
      OBJECT_CONSTRUCT(
        'query', search_term || ' function',
        'columns', ARRAY_CONSTRUCT('title', 'description', 'category'),
        'limit', 10
      )
    )
  ) AS results
  WHERE results.value:title ILIKE '%function%'
  ORDER BY relevance DESC
$$;

-- Grant usage to MCP role
GRANT USAGE ON FUNCTION FIND_SNOWFLAKE_FUNCTIONS(
    VARCHAR
) TO ROLE MCP_ACCESS_ROLE;

-- Test the function
SELECT
    FUNCTION_NAME,
    DESCRIPTION,
    CATEGORY,
    RELEVANCE
FROM TABLE(FIND_SNOWFLAKE_FUNCTIONS('string'))
LIMIT 5;

/*
EXPECTED OUTPUT:
A table with columns:
- function_name: Name of the Snowflake function
- description: Brief description
- category: Function category
- relevance: Relevance score (higher = more relevant)

USAGE IN MCP CLIENT:
Ask your AI assistant:
- "Find Snowflake functions for working with strings"
- "What JSON functions are available?"
- "Search for date manipulation functions"
*/

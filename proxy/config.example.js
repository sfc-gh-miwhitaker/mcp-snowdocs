/**
 * MCP Proxy Configuration Example
 * Copy this file to config.js and fill in your values
 * 
 * SECURITY: config.js is gitignored - never commit your actual credentials
 */
export default {
    // Snowflake MCP Server URL (from setup_mcp.sql output)
    mcpServerUrl: 'https://your-org-your-account.snowflakecomputing.com/api/v2/cortex/mcp/SNOWFLAKE_INTELLIGENCE.MCP.SNOWFLAKE_MCP_SERVER:run',
    
    // Snowflake PAT Token (from create_token.sql output)
    authToken: 'eyJ...your-token-here',
    
    // Local proxy settings
    proxyPort: 3456,
    proxyHost: '127.0.0.1',
    
    // Logging level (debug, info, warn, error)
    logLevel: 'info'
};


# Custom MCP Tools

This project demonstrates two custom tools to showcase the extensibility of Snowflake's MCP server.

## Available Custom Tools

### 1. Get Account Info

**Purpose:** Returns current Snowflake environment metadata
**Type:** Simple UDF (no parameters)
**Use case:** Quick environment verification, debugging connection issues

**Example usage in an AI assistant:**
> "What Snowflake account am I connected to?"

**Returns:**
- Snowflake version
- Region
- Account name
- Organization name
- Current warehouse
- Current role and user

**Implementation:** `sql/02_custom_tools/account_info.sql`

### 2. Find Snowflake Functions

**Purpose:** Searches documentation for built-in functions by keyword
**Type:** Table function (takes search term parameter)
**Use case:** Quick function discovery without leaving your IDE

**Example usage in an AI assistant:**
> "Find Snowflake functions for working with strings"
> "What JSON functions are available?"
> "Search for date manipulation functions"

**Returns:**
- Function name
- Description
- Category
- Relevance score

**Implementation:** `sql/02_custom_tools/function_finder.sql`

## How Custom Tools Work

Both tools are implemented as UDFs in the `SNOWFLAKE_INTELLIGENCE.MCP` schema and granted to `MCP_ACCESS_ROLE`. The MCP server exposes them through the standard Model Context Protocol interface, making them discoverable by any MCP-compatible client.

When you ask your AI assistant a question that matches a tool's description, the assistant:
1. Discovers the available tools through the MCP protocol
2. Selects the appropriate tool based on your query
3. Invokes the tool with the necessary parameters
4. Receives the results and incorporates them into its response

## Adding Your Own Custom Tools

This project provides templates and configuration files to make adding custom tools straightforward.

### Quick Start

1. **Copy a template:**
   - For generic UDFs: Copy `sql/02_custom_tools/_TEMPLATE.sql` to a new file
   - For semantic views: Copy `sql/02_custom_tools/SEMANTIC_VIEWS_TEMPLATE.sql`

2. **Implement your function** in the copied SQL file

3. **Add tool definition** to `config/mcp_spec.yaml`:
   ```yaml
   - name: "your-tool-name"
     type: "GENERIC"
     identifier: "SNOWFLAKE_INTELLIGENCE.MCP.YOUR_FUNCTION"
     description: "Clear description of what your tool does"
     title: "Human-Readable Tool Name"
     warehouse: "COMPUTE_WH"  # Required for tools that need compute
     inputSchema:
       type: "object"
       properties:
         param_name:
           type: "string"
           description: "Parameter description"
       required: ["param_name"]
     outputSchema:
       type: "object"  # or "array" for table functions
   ```

4. **Run your SQL file** to create the function

5. **Re-run** `sql/01_setup/setup_mcp.sql` to update the MCP server with the new tool

6. **Add cleanup logic** to `sql/99_cleanup/teardown_all.sql`

7. **Test your tool** by asking your AI assistant questions that should trigger it

### Templates Provided

- **`sql/02_custom_tools/_TEMPLATE.sql`** - Starting point for generic UDFs and table functions
- **`sql/02_custom_tools/SEMANTIC_VIEWS_TEMPLATE.sql`** - Template for Cortex Analyst semantic views
- **`config/mcp_spec.yaml`** - Includes commented template at the bottom

Each template includes:
- Step-by-step instructions
- Working examples
- Security considerations
- Testing guidance

## Tool Type Reference

The MCP server supports multiple tool types:

| Tool Type | Purpose | Example |
|-----------|---------|---------|
| `CORTEX_SEARCH_SERVICE_QUERY` | Semantic search over data | Documentation search |
| `CORTEX_ANALYST_MESSAGE` | Text-to-SQL generation | Semantic model queries |
| `CORTEX_AGENT_RUN` | AI agent invocation | Complex multi-step tasks |
| `GENERIC` | Custom UDF/stored procedure | Account info, function finder |
| `SYSTEM_EXECUTE_SQL` | Direct SQL execution | Ad-hoc queries (use with caution) |

For complete tool type documentation, see the [Snowflake MCP documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp).

## Security Considerations

Custom tools inherit the permissions of `MCP_ACCESS_ROLE`. When creating custom tools:

- **Follow least privilege:** Only grant access to data and functions necessary for the tool's purpose
- **Validate inputs:** Use type checking and validation in your UDF/stored procedure
- **Avoid exposing sensitive data:** Be mindful of what data your tool can access and return
- **Test thoroughly:** Verify the tool behaves correctly with various inputs
- **Document clearly:** Provide clear descriptions so the AI assistant knows when to use the tool

## Navigation

- **Previous:** [`docs/03-TROUBLESHOOTING.md`](03-TROUBLESHOOTING.md)
- **Related:** [`docs/02-SECURITY.md`](02-SECURITY.md) - Security model and access control

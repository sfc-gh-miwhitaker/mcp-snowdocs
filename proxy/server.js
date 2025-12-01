/**
 * MCP Proxy Server
 * 
 * Fixes SSE streaming issues with Snowflake MCP server by:
 * 1. Properly setting Accept headers for SSE connections
 * 2. Handling content negotiation between client and server
 * 3. Supporting both Streamable HTTP and legacy SSE transports
 * 
 * Author: SE Community
 * Purpose: Local proxy to resolve "Failed to open SSE stream: Not Acceptable" errors
 */

import express from 'express';
import { createRequire } from 'module';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load configuration
let config;
const configPath = join(__dirname, 'config.js');

if (existsSync(configPath)) {
    config = (await import(configPath)).default;
} else {
    console.error('ERROR: config.js not found!');
    console.error('');
    console.error('Please create proxy/config.js by copying proxy/config.example.js');
    console.error('and filling in your Snowflake MCP server URL and PAT token.');
    console.error('');
    console.error('  cp proxy/config.example.js proxy/config.js');
    console.error('  # Edit proxy/config.js with your values');
    console.error('');
    process.exit(1);
}

const {
    mcpServerUrl,
    authToken,
    proxyPort = 3456,
    proxyHost = '127.0.0.1',
    logLevel = 'info'
} = config;

// Validate required configuration
if (!mcpServerUrl || mcpServerUrl.includes('your-org')) {
    console.error('ERROR: mcpServerUrl not configured in config.js');
    process.exit(1);
}

if (!authToken || authToken.includes('your-token')) {
    console.error('ERROR: authToken not configured in config.js');
    process.exit(1);
}

const LOG_LEVELS = { debug: 0, info: 1, warn: 2, error: 3 };
const currentLogLevel = LOG_LEVELS[logLevel] ?? LOG_LEVELS.info;

function log(level, ...args) {
    if (LOG_LEVELS[level] >= currentLogLevel) {
        const timestamp = new Date().toISOString();
        const prefix = `[${timestamp}] [${level.toUpperCase()}]`;
        console.log(prefix, ...args);
    }
}

const app = express();

// Parse JSON bodies for POST requests
app.use(express.json({ limit: '10mb' }));
app.use(express.text({ type: 'text/*', limit: '10mb' }));

// CORS headers for local development
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept, MCP-Session-Id, MCP-Protocol-Version');
    res.header('Access-Control-Expose-Headers', 'MCP-Session-Id');
    
    if (req.method === 'OPTIONS') {
        return res.sendStatus(200);
    }
    next();
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        proxy: 'mcp-snowflake-proxy',
        target: new URL(mcpServerUrl).origin
    });
});

/**
 * Main MCP proxy endpoint
 * Handles all MCP protocol requests and forwards them to Snowflake
 */
app.all('/mcp', async (req, res) => {
    const method = req.method;
    const acceptHeader = req.headers['accept'] || '';
    const isSSERequest = acceptHeader.includes('text/event-stream') || method === 'GET';
    
    log('debug', `${method} /mcp - Accept: ${acceptHeader}`);
    
    try {
        // Build headers for upstream request
        const upstreamHeaders = {
            'Authorization': `Bearer ${authToken}`,
            'Content-Type': 'application/json',
            'User-Agent': 'MCP-Snowflake-Proxy/1.0'
        };
        
        // Copy relevant headers from client
        if (req.headers['mcp-session-id']) {
            upstreamHeaders['MCP-Session-Id'] = req.headers['mcp-session-id'];
        }
        if (req.headers['mcp-protocol-version']) {
            upstreamHeaders['MCP-Protocol-Version'] = req.headers['mcp-protocol-version'];
        }
        
        // Critical: Always set Accept header for SSE compatibility
        // This is the main fix for the "Not Acceptable" error
        if (isSSERequest) {
            upstreamHeaders['Accept'] = 'text/event-stream, application/json';
        } else {
            upstreamHeaders['Accept'] = 'application/json, text/event-stream';
        }
        
        log('debug', 'Upstream headers:', JSON.stringify(upstreamHeaders, null, 2));
        
        // Make request to Snowflake MCP server
        const fetchOptions = {
            method: method,
            headers: upstreamHeaders
        };
        
        // Add body for POST requests
        if (method === 'POST' && req.body) {
            fetchOptions.body = typeof req.body === 'string' 
                ? req.body 
                : JSON.stringify(req.body);
            log('debug', 'Request body:', fetchOptions.body.substring(0, 500));
        }
        
        const upstreamResponse = await fetch(mcpServerUrl, fetchOptions);
        
        log('info', `Upstream response: ${upstreamResponse.status} ${upstreamResponse.statusText}`);
        
        // Copy response headers
        const contentType = upstreamResponse.headers.get('content-type') || '';
        const sessionId = upstreamResponse.headers.get('mcp-session-id');
        
        if (sessionId) {
            res.setHeader('MCP-Session-Id', sessionId);
        }
        
        // Handle SSE streaming response
        if (contentType.includes('text/event-stream')) {
            log('debug', 'Handling SSE stream response');
            
            res.setHeader('Content-Type', 'text/event-stream');
            res.setHeader('Cache-Control', 'no-cache');
            res.setHeader('Connection', 'keep-alive');
            res.setHeader('X-Accel-Buffering', 'no'); // Disable nginx buffering
            res.flushHeaders();
            
            // Stream the SSE response
            const reader = upstreamResponse.body.getReader();
            const decoder = new TextDecoder();
            
            try {
                while (true) {
                    const { done, value } = await reader.read();
                    if (done) break;
                    
                    const chunk = decoder.decode(value, { stream: true });
                    log('debug', 'SSE chunk:', chunk.substring(0, 200));
                    res.write(chunk);
                }
            } catch (streamError) {
                log('error', 'SSE stream error:', streamError.message);
            } finally {
                res.end();
            }
            return;
        }
        
        // Handle JSON response
        if (contentType.includes('application/json')) {
            const jsonResponse = await upstreamResponse.json();
            log('debug', 'JSON response:', JSON.stringify(jsonResponse).substring(0, 500));
            res.status(upstreamResponse.status).json(jsonResponse);
            return;
        }
        
        // Handle other responses (202 Accepted, etc.)
        if (upstreamResponse.status === 202) {
            res.status(202).send();
            return;
        }
        
        // Pass through other responses
        const textResponse = await upstreamResponse.text();
        res.status(upstreamResponse.status)
            .header('Content-Type', contentType || 'text/plain')
            .send(textResponse);
            
    } catch (error) {
        log('error', 'Proxy error:', error.message);
        log('debug', 'Error stack:', error.stack);
        
        res.status(502).json({
            jsonrpc: '2.0',
            error: {
                code: -32000,
                message: `Proxy error: ${error.message}`
            },
            id: null
        });
    }
});

/**
 * Legacy SSE endpoint for older MCP clients
 * Maintains backwards compatibility with protocol version 2024-11-05
 */
app.get('/sse', async (req, res) => {
    log('info', 'Legacy SSE endpoint called');
    
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders();
    
    // Send initial connection event
    res.write(`event: open\ndata: {"status":"connected"}\n\n`);
    
    // Keep connection alive
    const keepAlive = setInterval(() => {
        res.write(`: keep-alive\n\n`);
    }, 30000);
    
    req.on('close', () => {
        clearInterval(keepAlive);
        log('debug', 'SSE connection closed');
    });
});

/**
 * Legacy message endpoint for older MCP clients
 */
app.post('/messages', async (req, res) => {
    log('info', 'Legacy messages endpoint called');
    
    // Forward to main MCP endpoint
    req.url = '/mcp';
    app.handle(req, res);
});

// Error handling middleware
app.use((err, req, res, next) => {
    log('error', 'Unhandled error:', err.message);
    res.status(500).json({
        jsonrpc: '2.0',
        error: {
            code: -32603,
            message: 'Internal proxy error'
        },
        id: null
    });
});

// Start server
const server = app.listen(proxyPort, proxyHost, () => {
    console.log('');
    console.log('╔══════════════════════════════════════════════════════════════╗');
    console.log('║           MCP Snowflake Proxy Server Started                 ║');
    console.log('╠══════════════════════════════════════════════════════════════╣');
    console.log(`║  Local URL:  http://${proxyHost}:${proxyPort}/mcp`);
    console.log(`║  Target:     ${new URL(mcpServerUrl).origin}`);
    console.log(`║  Log Level:  ${logLevel}`);
    console.log('╠══════════════════════════════════════════════════════════════╣');
    console.log('║  Configure your MCP client to use:                           ║');
    console.log(`║  URL: http://${proxyHost}:${proxyPort}/mcp`);
    console.log('║  (No Authorization header needed - proxy handles auth)       ║');
    console.log('╚══════════════════════════════════════════════════════════════╝');
    console.log('');
});

// Graceful shutdown
process.on('SIGINT', () => {
    log('info', 'Shutting down proxy server...');
    server.close(() => {
        log('info', 'Proxy server stopped');
        process.exit(0);
    });
});

process.on('SIGTERM', () => {
    log('info', 'Received SIGTERM, shutting down...');
    server.close(() => {
        process.exit(0);
    });
});


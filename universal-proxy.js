// universal-proxy.js
const http = require('http');
const https = require('https');

const PROVIDERS = {
    dahl: {
        hostname: 'inference.dahl.global',
        pathPrefix: '/v1',
        defaultModel: 'MiniMaxAI/MiniMax-M2.7'
    },
    puter: {
        hostname: 'api.puter.com',
        pathPrefix: '/puterai/openai/v1',
        defaultModel: 'deepseek-chat' 
    }
};

const httpsAgent = new https.Agent({ rejectUnauthorized: false });

const server = http.createServer((req, res) => {
    const pathParts = req.url.split('/');
    const providerKey = pathParts[1]; 
    const providerConfig = PROVIDERS[providerKey];

    if (!providerConfig) {
        res.writeHead(404);
        return res.end('Unknown Provider');
    }

    // 🛡️ SHIELD: INTERCEPT TOKEN COUNTING
    if (req.url.includes('/count_tokens')) {
        let body = '';
        req.on('data', chunk => body += chunk.toString());
        req.on('end', () => {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ input_tokens: 150 }));
        });
        return; 
    }

    if (!req.url.includes('/v1/messages')) {
        res.writeHead(404);
        return res.end('Not Found');
    }

    // Extract the token that Claude Code sent via settings.local.json
    const authHeader = req.headers['authorization'] || '';

    let body = '';
    req.on('data', chunk => body += chunk.toString());
    req.on('end', () => {
        let anthropicReq;
        try {
            anthropicReq = JSON.parse(body);
        } catch (e) {
            res.writeHead(400);
            return res.end('Invalid JSON');
        }
        
        const openAiReq = {
            model: anthropicReq.model || providerConfig.defaultModel, 
            stream: anthropicReq.stream !== false, 
            messages: []
        };

        if (anthropicReq.system) {
            const sysText = Array.isArray(anthropicReq.system) 
                ? anthropicReq.system.map(s => s.text).join('\n') 
                : anthropicReq.system;
            openAiReq.messages.push({ role: 'system', content: sysText });
        }

        if (anthropicReq.messages && Array.isArray(anthropicReq.messages)) {
            anthropicReq.messages.forEach(msg => {
                let content = '';
                if (Array.isArray(msg.content)) {
                    content = msg.content.filter(c => c.type === 'text').map(c => c.text).join('\n');
                } else if (typeof msg.content === 'string') {
                    content = msg.content;
                }
                if (content.trim()) {
                    openAiReq.messages.push({ role: msg.role, content: content });
                }
            });
        }

        if (openAiReq.messages.length === 0) {
            openAiReq.messages.push({ role: 'user', content: 'Hello' });
        }

        const requestData = JSON.stringify(openAiReq);
        
        const options = {
            hostname: providerConfig.hostname,
            path: `${providerConfig.pathPrefix}/chat/completions`,
            method: 'POST',
            agent: httpsAgent,
            headers: {
                'Content-Type': 'application/json',
                'Authorization': authHeader, // Dynamically passing the token
                'Content-Length': Buffer.byteLength(requestData)
            }
        };

        const proxyReq = https.request(options, proxyRes => {
            if (proxyRes.statusCode !== 200) {
                let errorData = '';
                proxyRes.on('data', d => errorData += d.toString());
                proxyRes.on('end', () => {
                    res.writeHead(proxyRes.statusCode, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ error: { type: "api_error", message: `Provider Error: ${proxyRes.statusCode}` } }));
                });
                return;
            }

            res.writeHead(200, {
                'Content-Type': 'text/event-stream',
                'Cache-Control': 'no-cache',
                'Connection': 'keep-alive'
            });

            res.write(`event: message_start\ndata: ${JSON.stringify({ type: 'message_start', message: { id: 'msg_proxy', role: 'assistant', content: [], model: openAiReq.model, stop_reason: null, type: 'message', usage: { input_tokens: 1, output_tokens: 1 } } })}\n\n`);
            res.write(`event: content_block_start\ndata: ${JSON.stringify({ type: 'content_block_start', index: 0, content_block: { type: 'text', text: '' } })}\n\n`);

            let buffer = '';
            proxyRes.on('data', chunk => {
                buffer += chunk.toString();
                const lines = buffer.split('\n');
                buffer = lines.pop(); 

                for (const line of lines) {
                    const cleanLine = line.trim();
                    if (!cleanLine || cleanLine === 'data: [DONE]') continue;
                    
                    if (cleanLine.startsWith('data: ')) {
                        try {
                            const data = JSON.parse(cleanLine.substring(6));
                            const textDelta = data.choices[0]?.delta?.content;
                            if (textDelta) {
                                res.write(`event: content_block_delta\ndata: ${JSON.stringify({ type: 'content_block_delta', index: 0, delta: { type: 'text_delta', text: textDelta } })}\n\n`);
                            }
                        } catch (e) {}
                    }
                }
            });

            proxyRes.on('end', () => {
                res.write(`event: content_block_stop\ndata: ${JSON.stringify({ type: 'content_block_stop', index: 0 })}\n\n`);
                res.write(`event: message_delta\ndata: ${JSON.stringify({ type: 'message_delta', delta: { stop_reason: 'end_turn' } })}\n\n`);
                res.write(`event: message_stop\ndata: ${JSON.stringify({ type: "message_stop" })}\n\n`);
                res.end();
            });
        });

        proxyReq.on('error', err => {
            res.writeHead(502);
            res.end();
        });

        proxyReq.write(requestData);
        proxyReq.end();
    });
});

server.listen(4000);

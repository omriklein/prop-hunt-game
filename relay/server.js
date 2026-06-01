const http = require('http');
const WebSocket = require('ws');

const SYS_ADD = 1, SYS_DEL = 2, SYS_ID = 3;
const ADJECTIVES = ['BARN', 'LAKE', 'PINE', 'ROCK', 'DARK', 'FAST', 'BOLD', 'WILD', 'IRON', 'STORM'];
const rooms = new Map();

function makeSysPacket(type, peerId) {
    const buf = Buffer.alloc(5);
    buf[0] = type;
    buf.writeUInt32LE(peerId, 1);
    return buf;
}

function makeCode() {
    let code;
    do {
        const adj = ADJECTIVES[Math.floor(Math.random() * ADJECTIVES.length)];
        code = `${adj}-${Math.floor(Math.random() * 9000) + 1000}`;
    } while (rooms.has(code));
    return code;
}

const server = http.createServer((req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    if (req.method === 'GET' && req.url === '/new') {
        const code = makeCode();
        rooms.set(code, new Map());
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ code }));
        console.log(`Room created: ${code}`);
    } else {
        res.writeHead(404);
        res.end();
    }
});

const wss = new WebSocket.Server({ server });

wss.on('connection', (ws, req) => {
    const parts = req.url.split('/').filter(Boolean);
    const code = parts[0];
    const role = parts[1];

    const room = rooms.get(code);
    if (!room) { ws.close(4404, 'Room not found'); return; }

    let peerId = role === 'host' ? 1 : 2;
    while (room.has(peerId)) peerId++;

    // Tell new peer their ID
    ws.send(makeSysPacket(SYS_ID, peerId), { binary: true });

    // Cross-notify: new peer learns about existing peers, existing peers learn about new peer
    for (const [pid, peer] of room) {
        ws.send(makeSysPacket(SYS_ADD, pid), { binary: true });
        peer.send(makeSysPacket(SYS_ADD, peerId), { binary: true });
    }

    room.set(peerId, ws);
    console.log(`Peer ${peerId} joined room ${code}`);

    ws.on('message', (data, isBinary) => {
        if (!isBinary) return;
        for (const [pid, peer] of room) {
            if (pid !== peerId && peer.readyState === WebSocket.OPEN) {
                peer.send(data, { binary: true });
            }
        }
    });

    ws.on('close', () => {
        room.delete(peerId);
        console.log(`Peer ${peerId} left room ${code}`);
        for (const [, peer] of room) {
            peer.send(makeSysPacket(SYS_DEL, peerId), { binary: true });
        }
        if (room.size === 0) rooms.delete(code);
    });

    ws.on('error', (e) => console.error(e.message));
});

server.listen(process.env.PORT || 8787, () =>
    console.log('Relay running on port', process.env.PORT || 8787));

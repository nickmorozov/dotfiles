# FVC SecureChannel Refactoring Plan

## Summary
Extract secure connection logic into a proper OOP class structure under the FVC namespace, starting with SecureChannel.

## Current State

### Working Code
- `src/secure-connection.js` - Opens secure connection, shows "Connected" in FC2
- `src/register-client.js` - Registers new clients with QR flow
- `fc2-credentials.json` - Stores client credentials

### Device Models (from APK)
- Solo, 2i2, 4i4, 18i16, 18i20

### Protocol Details
- Secure port: 58322
- URL format: `ws://localhost:58322/{publicKey}`
- Server message format: `[header:24][len:2][ciphertext]`
- Decryption: `rxKey` from `crypto_kx_client_session_keys`

## Phase 1: SecureChannel Class

### Create: `src/fvc/connection/SecureChannel.js`

```javascript
import { EventEmitter } from 'events';
import WebSocket from 'ws';
import sodium from 'sodium-native';

const HEADERBYTES = 24;
const ABYTES = 17;
const KEYBYTES = 32;

export class SecureChannel extends EventEmitter {
  #ws = null;
  #credentials = null;
  #rxKey = null;
  #txKey = null;
  #pullState = null;
  #pushState = null;
  #pullInitialized = false;

  constructor(credentials) {
    super();
    this.#credentials = credentials;
    this.#deriveKeys();
  }

  get isConnected() {
    return this.#ws?.readyState === WebSocket.OPEN;
  }

  #deriveKeys() {
    const clientPub = Buffer.from(this.#credentials.publicKey, 'hex');
    const clientSec = Buffer.from(this.#credentials.secretKey, 'hex');
    const serverPub = Buffer.from(this.#credentials.serverPublicKey, 'hex');

    this.#rxKey = Buffer.alloc(KEYBYTES);
    this.#txKey = Buffer.alloc(KEYBYTES);
    sodium.crypto_kx_client_session_keys(
      this.#rxKey, this.#txKey,
      clientPub, clientSec, serverPub
    );
  }

  async connect() {
    const url = `ws://localhost:58322/${this.#credentials.publicKey}`;
    this.#ws = new WebSocket(url, { perMessageDeflate: false });

    return new Promise((resolve, reject) => {
      this.#ws.on('open', () => {
        this.emit('connected');
        resolve();
      });
      this.#ws.on('error', reject);
      this.#ws.on('message', (data) => this.#onMessage(data));
      this.#ws.on('close', (code) => this.emit('disconnected', code));
    });
  }

  #onMessage(data) {
    const buf = Buffer.from(data);
    try {
      const decrypted = this.#decrypt(buf);
      this.emit('message', decrypted);
    } catch (e) {
      this.emit('error', e);
    }
  }

  #decrypt(data) {
    // First message includes header
    if (!this.#pullInitialized) {
      const header = data.slice(0, HEADERBYTES);
      const len = data.readUInt16BE(HEADERBYTES);
      const ct = data.slice(HEADERBYTES + 2);

      this.#pullState = Buffer.alloc(
        sodium.crypto_secretstream_xchacha20poly1305_STATEBYTES
      );
      sodium.crypto_secretstream_xchacha20poly1305_init_pull(
        this.#pullState, header, this.#rxKey
      );
      this.#pullInitialized = true;

      const pt = Buffer.alloc(ct.length - ABYTES);
      sodium.crypto_secretstream_xchacha20poly1305_pull(
        this.#pullState, pt, Buffer.alloc(1), ct, null
      );
      return pt;
    }

    // Subsequent messages: [len:2][ct]
    const ct = data.slice(2);
    const pt = Buffer.alloc(ct.length - ABYTES);
    sodium.crypto_secretstream_xchacha20poly1305_pull(
      this.#pullState, pt, Buffer.alloc(1), ct, null
    );
    return pt;
  }

  async disconnect() {
    this.#ws?.close();
    this.#pullInitialized = false;
  }
}
```

### Create: `src/fvc/auth/Credentials.js`

```javascript
import { readFileSync, writeFileSync, existsSync } from 'fs';

const DEFAULT_FILE = 'fc2-credentials.json';

export class Credentials {
  constructor(data) {
    this.clientName = data.clientName;
    this.publicKey = data.publicKey;
    this.secretKey = data.secretKey;
    this.serverPublicKey = data.serverPublicKey;
    this.sessionKey = data.sessionKey;
  }

  static load(file = DEFAULT_FILE) {
    if (!existsSync(file)) return null;
    const data = JSON.parse(readFileSync(file, 'utf8'));
    return new Credentials(data);
  }

  save(file = DEFAULT_FILE) {
    writeFileSync(file, JSON.stringify(this, null, 2));
  }
}
```

### Create: `src/fvc/index.js`

```javascript
export { SecureChannel } from './connection/SecureChannel.js';
export { Credentials } from './auth/Credentials.js';
```

## File Structure

```
src/
├── fvc/
│   ├── index.js              # Namespace exports
│   ├── connection/
│   │   └── SecureChannel.js  # Secure WebSocket connection
│   └── auth/
│       └── Credentials.js    # Key/credential management
├── secure-connection.js      # Keep as CLI tool (uses FVC)
└── register-client.js        # Keep as CLI tool
```

## Migration

1. Create `src/fvc/` directory structure
2. Extract `SecureChannel` class from `secure-connection.js`
3. Extract `Credentials` class from `register-client.js`
4. Update `secure-connection.js` to use FVC classes
5. Verify old scripts still work

## Verification

```bash
# Test SecureChannel directly
node -e "
import { SecureChannel, Credentials } from './src/fvc/index.js';
const creds = Credentials.load();
const channel = new SecureChannel(creds);
await channel.connect();
console.log('Connected:', channel.isConnected);
setTimeout(() => channel.disconnect(), 5000);
"

# Test old script still works
node src/secure-connection.js 5
```

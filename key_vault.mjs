import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';

const VAULT_FORMAT = 'gk-ptdnt-key-vault-v1';
const KDF_PARAMS = { N: 16384, r: 8, p: 1, keyLen: 32 };

function printUsage() {
  console.log(`Su dung:
  node key_vault.mjs encrypt [--in serviceAccountKey.json] [--out serviceAccountKey.json.enc] [--pass <mat_khau>]
  node key_vault.mjs decrypt [--in serviceAccountKey.json.enc] [--out serviceAccountKey.json] [--pass <mat_khau>] [--force]
  node key_vault.mjs verify  [--in serviceAccountKey.json.enc] [--pass <mat_khau>]

Ghi chu:
  - Neu khong truyen --pass, script se doc bien moi truong KEY_VAULT_PASSPHRASE hoac hoi truc tiep trong terminal.
  - Tuyet doi khong commit mat khau giai ma hoac file serviceAccountKey.json goc len GitHub.`);
}

function parseArgs(argv) {
  const args = argv.slice(2);
  const command = args[0];
  const opts = {
    inFile: null,
    outFile: null,
    pass: null,
    force: false,
  };

  for (let i = 1; i < args.length; i += 1) {
    const arg = args[i];
    if (arg === '--force' || arg === '-f') {
      opts.force = true;
    } else if (arg === '--in' && i + 1 < args.length) {
      opts.inFile = args[++i];
    } else if (arg.startsWith('--in=')) {
      opts.inFile = arg.slice(5);
    } else if (arg === '--out' && i + 1 < args.length) {
      opts.outFile = args[++i];
    } else if (arg.startsWith('--out=')) {
      opts.outFile = arg.slice(6);
    } else if (arg === '--pass' && i + 1 < args.length) {
      opts.pass = args[++i];
    } else if (arg.startsWith('--pass=')) {
      opts.pass = arg.slice(7);
    } else if (arg === '--help' || arg === '-h') {
      printUsage();
      process.exit(0);
    } else {
      throw new Error(`Tham so khong hop le: ${arg}`);
    }
  }

  return { command, opts };
}

function promptHidden(question) {
  return new Promise((resolve, reject) => {
    if (!process.stdin.isTTY) {
      reject(
        new Error(
          'Khong co terminal tuong tac. Hay truyen --pass <mat_khau> hoac dat bien moi truong KEY_VAULT_PASSPHRASE.',
        ),
      );
      return;
    }

    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      terminal: true,
    });

    const originalWrite = rl._writeToOutput;
    let muted = false;
    rl._writeToOutput = (stringToWrite) => {
      if (muted) {
        if (stringToWrite.includes('\n') || stringToWrite.includes('\r')) {
          rl.output.write('\n');
        }
      } else {
        originalWrite.call(rl, stringToWrite);
      }
    };

    process.stdout.write(question);
    muted = true;
    rl.question('', (answer) => {
      muted = false;
      rl.close();
      resolve(answer);
    });
  });
}

async function resolvePassphrase(explicitPass, confirmForEncrypt = false) {
  const fromArgOrEnv = explicitPass ?? process.env.KEY_VAULT_PASSPHRASE ?? null;
  if (fromArgOrEnv !== null) {
    if (fromArgOrEnv.length < 8) {
      throw new Error('Mat khau ma hoa phai dai it nhat 8 ky tu.');
    }
    return fromArgOrEnv;
  }

  const first = await promptHidden('Nhap mat khau (passphrase): ');
  if (first.length < 8) {
    throw new Error('Mat khau ma hoa phai dai it nhat 8 ky tu.');
  }
  if (confirmForEncrypt) {
    const second = await promptHidden('Nhap lai mat khau de xac nhan: ');
    if (first !== second) {
      throw new Error('Hai lan nhap mat khau khong khop.');
    }
  }
  return first;
}

function deriveKey(passphrase, saltBuffer, params = KDF_PARAMS) {
  return crypto.scryptSync(passphrase, saltBuffer, params.keyLen, {
    N: params.N,
    r: params.r,
    p: params.p,
  });
}

function encryptFile(inPath, outPath, passphrase) {
  if (!fs.existsSync(inPath)) {
    throw new Error(`Khong tim thay file nguon: ${inPath}`);
  }

  const plaintextBuf = fs.readFileSync(inPath);
  let parsed;
  try {
    parsed = JSON.parse(plaintextBuf.toString('utf8'));
  } catch {
    throw new Error(`File nguon khong phai JSON hop le: ${inPath}`);
  }

  if (!parsed || typeof parsed !== 'object' || !parsed.private_key) {
    throw new Error(`File ${inPath} khong co truong private_key cua Service Account.`);
  }

  const salt = crypto.randomBytes(16);
  const iv = crypto.randomBytes(12);
  const key = deriveKey(passphrase, salt, KDF_PARAMS);

  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([cipher.update(plaintextBuf), cipher.final()]);
  const tag = cipher.getAuthTag();

  const envelope = {
    format: VAULT_FORMAT,
    cipher: 'aes-256-gcm',
    kdf: 'scrypt',
    kdfParams: KDF_PARAMS,
    salt: salt.toString('base64'),
    iv: iv.toString('base64'),
    tag: tag.toString('base64'),
    ciphertext: encrypted.toString('base64'),
  };

  fs.writeFileSync(outPath, `${JSON.stringify(envelope, null, 2)}\n`, 'utf8');
  return {
    bytes: encrypted.length,
    projectId: parsed.project_id || '(khong ro)',
  };
}

function decryptEnvelopeBuffer(inPath, passphrase) {
  if (!fs.existsSync(inPath)) {
    throw new Error(`Khong tim thay file ma hoa: ${inPath}`);
  }

  let envelope;
  try {
    envelope = JSON.parse(fs.readFileSync(inPath, 'utf8'));
  } catch {
    throw new Error(`File ma hoa khong phai JSON hop le: ${inPath}`);
  }

  if (
    !envelope ||
    envelope.format !== VAULT_FORMAT ||
    envelope.cipher !== 'aes-256-gcm' ||
    envelope.kdf !== 'scrypt' ||
    !envelope.kdfParams ||
    !envelope.salt ||
    !envelope.iv ||
    !envelope.tag ||
    !envelope.ciphertext
  ) {
    throw new Error(`Dinh dang file ma hoa khong hop le: ${inPath}`);
  }

  const salt = Buffer.from(envelope.salt, 'base64');
  const iv = Buffer.from(envelope.iv, 'base64');
  const tag = Buffer.from(envelope.tag, 'base64');
  const ciphertext = Buffer.from(envelope.ciphertext, 'base64');
  const key = deriveKey(passphrase, salt, envelope.kdfParams);

  let plaintextBuf;
  try {
    const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
    decipher.setAuthTag(tag);
    plaintextBuf = Buffer.concat([decipher.update(ciphertext), decipher.final()]);
  } catch {
    throw new Error('Giai ma that bai: mat khau khong dung hoac file da bi chinh sua.');
  }

  let parsed;
  try {
    parsed = JSON.parse(plaintextBuf.toString('utf8'));
  } catch {
    throw new Error('Du lieu sau giai ma khong phai JSON hop le.');
  }

  return { plaintextBuf, parsed };
}

async function main() {
  const { command, opts } = parseArgs(process.argv);

  if (!command || !['encrypt', 'decrypt', 'verify'].includes(command)) {
    printUsage();
    process.exit(command ? 1 : 0);
  }

  if (command === 'encrypt') {
    const inPath = path.resolve(opts.inFile || 'serviceAccountKey.json');
    const outPath = path.resolve(opts.outFile || `${opts.inFile || 'serviceAccountKey.json'}.enc`);
    const passphrase = await resolvePassphrase(opts.pass, true);
    const info = encryptFile(inPath, outPath, passphrase);
    console.log(`[OK] Da ma hoa AES-256-GCM thanh cong -> ${path.basename(outPath)} (project: ${info.projectId}, ${info.bytes} bytes).`);
    return;
  }

  if (command === 'verify') {
    const inPath = path.resolve(opts.inFile || 'serviceAccountKey.json.enc');
    const passphrase = await resolvePassphrase(opts.pass, false);
    const { parsed } = decryptEnvelopeBuffer(inPath, passphrase);
    console.log(`[OK] Giai ma thu thanh cong (project: ${parsed.project_id || '(khong ro)'}, client_email: ${parsed.client_email || '(khong ro)'}).`);
    return;
  }

  if (command === 'decrypt') {
    const inPath = path.resolve(opts.inFile || 'serviceAccountKey.json.enc');
    const outPath = path.resolve(opts.outFile || 'serviceAccountKey.json');
    if (fs.existsSync(outPath) && !opts.force) {
      throw new Error(`File dich da ton tai (${path.basename(outPath)}). Them --force neu muon ghi de.`);
    }
    const passphrase = await resolvePassphrase(opts.pass, false);
    const { plaintextBuf, parsed } = decryptEnvelopeBuffer(inPath, passphrase);
    fs.writeFileSync(outPath, plaintextBuf, { mode: 0o600 });
    console.log(`[OK] Da giai ma ra ${path.basename(outPath)} (project: ${parsed.project_id || '(khong ro)'}).`);
  }
}

main().catch((err) => {
  console.error(`[Loi]: ${err.message}`);
  process.exit(1);
});

/**
 * Script đồng bộ dữ liệu & hình ảnh sản phẩm giữa:
 *   - Thư mục ảnh máy tính (`product_images/`) & file dữ liệu cục bộ (`local_products.json`)
 *   - Firebase Emulator cục bộ (Auth :9099, Firestore :8080, Storage :9199)
 *   - Cloud Firestore của project `gk-ptdnt`
 *
 * Bảo đảm mỗi document trong collection `products` chỉ có đúng 4 trường:
 * `name`, `price`, `soluong`, `image`.
 *
 * Tham số hỗ trợ:
 *   --check                  Kiểm tra dữ liệu hợp lệ trong local_products.json
 *   --export-local-only      Kéo dữ liệu mới nhất từ Emulator ra local_products.json + tải ảnh mới vào product_images/
 *   --hydrate-emulator       Nếu Emulator trống, nạp Admin + sản phẩm + ảnh thật từ product_images/
 *   --sync-local-to-emulator Đẩy sản phẩm/ảnh mới thêm từ local_products.json & product_images/ vào Emulator đang chạy
 *   (mặc định)               Cập nhật local_products.json (nếu Emulator đang chạy) rồi đồng bộ lên Cloud
 */

import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline/promises';
import { fileURLToPath } from 'node:url';
import zlib from 'node:zlib';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const PROJECT_ID = 'gk-ptdnt';
const BUCKET = 'gk-ptdnt.firebasestorage.app';
const ADMIN_EMAIL = process.env.FIREBASE_ADMIN_EMAIL || 'admin@productadmin.com';
const LOCAL_DEFAULT_PASS = process.env.SEED_ADMIN_PASS || '123456';

const LOCAL_DB_PATH = path.join(__dirname, 'local_products.json');
const SAMPLE_DB_PATH = path.join(__dirname, 'sample_products.json');
const IMAGES_DIR = path.join(__dirname, 'product_images');
const IMAGE_MAP_PATH = path.join(IMAGES_DIR, 'image_map.json');
const IMAGE_HASH_CACHE_PATH = path.join(IMAGES_DIR, '.upload_cache.json');
const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');
const FIREBASE_OPTIONS_PATH = path.join(
  __dirname,
  'product_admin',
  'lib',
  'firebase_options.dart',
);

const EMULATOR_AUTH_BASE = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const EMULATOR_PRODUCTS_URL =
  `http://127.0.0.1:8080/v1/projects/${PROJECT_ID}/databases/(default)/documents/products`;
const EMULATOR_STORAGE_UPLOAD_BASE =
  `http://127.0.0.1:9199/v0/b/${BUCKET}/o`;
const CLOUD_PRODUCTS_URL =
  `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/products`;

function isLocalhostUrl(url) {
  return /^https?:\/\/(localhost|127\.0\.0\.1|10\.0\.2\.2)(:|\/)/i.test(url || '');
}

function isHttpUrl(url) {
  return /^https?:\/\/\S+$/i.test((url || '').trim());
}

function normalizeKey(name) {
  return String(name ?? '').trim().toLowerCase();
}

function slugify(name) {
  return String(name ?? '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '') || 'product';
}

function detectMimeType(filePathOrName) {
  const lower = String(filePathOrName).toLowerCase();
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return 'application/octet-stream';
}

function extensionFromMime(mime, fallbackUrl = '') {
  const m = String(mime || '').toLowerCase();
  if (m.includes('webp')) return '.webp';
  if (m.includes('png')) return '.png';
  if (m.includes('gif')) return '.gif';
  if (m.includes('jpeg') || m.includes('jpg')) return '.jpg';
  const extMatch = String(fallbackUrl).match(/\.(webp|png|jpe?g|gif)(?:[?#]|$)/i);
  return extMatch ? `.${extMatch[1].toLowerCase()}` : '.png';
}

function sha256Buffer(buf) {
  return crypto.createHash('sha256').update(buf).digest('hex');
}

function fromFirestoreDoc(doc) {
  const f = doc.fields || {};
  const priceVal = f.price?.integerValue ?? f.price?.doubleValue ?? 0;
  const qtyVal = f.soluong?.integerValue ?? f.soluong?.doubleValue ?? 0;
  return {
    name: String(f.name?.stringValue ?? '').trim(),
    price: Number(priceVal),
    soluong: Math.trunc(Number(qtyVal)),
    image: String(f.image?.stringValue ?? '').trim(),
  };
}

function toFirestoreFields(product) {
  const isWholePrice = Number.isInteger(product.price);
  return {
    name: { stringValue: product.name },
    price: isWholePrice
      ? { integerValue: String(product.price) }
      : { doubleValue: product.price },
    soluong: { integerValue: String(product.soluong) },
    image: { stringValue: product.image },
  };
}

function validateProduct(item, allowLocalPath = false) {
  if (!item || typeof item !== 'object') return false;
  if (typeof item.name !== 'string' || item.name.trim().length < 2) return false;
  if (typeof item.price !== 'number' || !Number.isFinite(item.price) || item.price <= 0) {
    return false;
  }
  if (!Number.isInteger(item.soluong) || item.soluong < 0) return false;
  if (typeof item.image !== 'string' || item.image.trim().length === 0) return false;
  if (!allowLocalPath && !isHttpUrl(item.image)) return false;
  return true;
}

function readJsonFile(filePath, fallback = []) {
  if (!fs.existsSync(filePath)) return fallback;
  const raw = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(raw);
}

function ensureImagesDir() {
  if (!fs.existsSync(IMAGES_DIR)) {
    fs.mkdirSync(IMAGES_DIR, { recursive: true });
  }
}

function loadImageMap() {
  ensureImagesDir();
  const raw = readJsonFile(IMAGE_MAP_PATH, {});
  const map = new Map();
  if (raw && typeof raw === 'object' && !Array.isArray(raw)) {
    for (const [k, v] of Object.entries(raw)) {
      if (typeof v === 'string' && v.trim()) {
        map.set(normalizeKey(k), v.trim());
      }
    }
  }
  return map;
}

function saveImageMap(map) {
  ensureImagesDir();
  const obj = {};
  for (const [k, v] of map.entries()) {
    obj[k] = v;
  }
  fs.writeFileSync(IMAGE_MAP_PATH, JSON.stringify(obj, null, 2) + '\n', 'utf8');
}

function loadUploadCache() {
  ensureImagesDir();
  const raw = readJsonFile(IMAGE_HASH_CACHE_PATH, {});
  return raw && typeof raw === 'object' && !Array.isArray(raw) ? raw : {};
}

function saveUploadCache(cache) {
  ensureImagesDir();
  fs.writeFileSync(IMAGE_HASH_CACHE_PATH, JSON.stringify(cache, null, 2) + '\n', 'utf8');
}

function resolveLocalImageFile(productName, imageField, imageMap) {
  ensureImagesDir();
  const key = normalizeKey(productName);

  // 1. Nếu imageField là đường dẫn file có thật trên máy tính -> copy vào product_images/
  const rawImage = String(imageField || '').trim();
  if (rawImage && !isHttpUrl(rawImage)) {
    const candidatePath = path.isAbsolute(rawImage)
      ? rawImage
      : path.resolve(__dirname, rawImage);
    if (fs.existsSync(candidatePath) && fs.statSync(candidatePath).isFile()) {
      const ext = path.extname(candidatePath) || '.png';
      const destName = `${slugify(productName)}${ext.toLowerCase()}`;
      const destPath = path.join(IMAGES_DIR, destName);
      if (path.resolve(candidatePath) !== path.resolve(destPath)) {
        fs.copyFileSync(candidatePath, destPath);
      }
      imageMap.set(key, destName);
      return destPath;
    }
  }

  // 2. Tra trong image_map.json
  const mappedFile = imageMap.get(key);
  if (mappedFile) {
    const mappedPath = path.join(IMAGES_DIR, mappedFile);
    if (fs.existsSync(mappedPath) && fs.statSync(mappedPath).isFile()) {
      return mappedPath;
    }
  }

  // 3. Tự dò file ảnh trong product_images/ theo tên sản phẩm slugified
  const targetSlug = slugify(productName);
  const files = fs.readdirSync(IMAGES_DIR);
  for (const file of files) {
    if (!/\.(webp|png|jpe?g|gif)$/i.test(file)) continue;
    const stem = slugify(path.basename(file, path.extname(file)));
    if (stem === targetSlug) {
      imageMap.set(key, file);
      return path.join(IMAGES_DIR, file);
    }
  }

  return null;
}

function createFallbackPngBuffer(width, height, bgRgb, accentRgb) {
  const crcTable = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) {
      c = (c & 1) ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1);
    }
    crcTable[n] = c >>> 0;
  }

  function crc32(buf) {
    let c = 0xffffffff;
    for (let i = 0; i < buf.length; i++) {
      c = crcTable[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
    }
    return (c ^ 0xffffffff) >>> 0;
  }

  function chunk(type, data) {
    const typeBuf = Buffer.from(type, 'ascii');
    const lenBuf = Buffer.alloc(4);
    lenBuf.writeUInt32BE(data.length, 0);
    const crcBuf = Buffer.alloc(4);
    crcBuf.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])), 0);
    return Buffer.concat([lenBuf, typeBuf, data, crcBuf]);
  }

  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 2;

  const stride = 1 + width * 3;
  const raw = Buffer.alloc(stride * height);
  for (let y = 0; y < height; y++) {
    const rowStart = y * stride;
    raw[rowStart] = 0;
    for (let x = 0; x < width; x++) {
      const idx = rowStart + 1 + x * 3;
      const dx = x - width / 2;
      const dy = y - height / 2;
      const inCard = Math.abs(dx) < width * 0.28 && Math.abs(dy) < height * 0.34;
      const inInner = Math.abs(dx) < width * 0.21 && Math.abs(dy) < height * 0.26;
      if (inCard && !inInner) {
        raw[idx] = 255;
        raw[idx + 1] = 255;
        raw[idx + 2] = 255;
      } else if (inInner) {
        raw[idx] = accentRgb[0];
        raw[idx + 1] = accentRgb[1];
        raw[idx + 2] = accentRgb[2];
      } else {
        raw[idx] = bgRgb[0];
        raw[idx + 1] = bgRgb[1];
        raw[idx + 2] = bgRgb[2];
      }
    }
  }

  const idat = zlib.deflateSync(raw);
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr),
    chunk('IDAT', idat),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

const COLOR_PALETTE = [
  [[29, 78, 216], [96, 165, 250]],
  [[15, 118, 110], [45, 212, 191]],
  [[51, 65, 85], [148, 163, 184]],
  [[67, 56, 202], [129, 140, 248]],
  [[3, 105, 161], [56, 189, 248]],
  [[71, 85, 105], [148, 163, 184]],
];

async function ensureEmulatorAdminUser() {
  const queryRes = await fetch(
    `${EMULATOR_AUTH_BASE}/projects/${PROJECT_ID}/accounts:query`,
    {
      method: 'POST',
      headers: {
        Authorization: 'Bearer owner',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ returnUserInfo: true }),
    },
  );
  if (!queryRes.ok) {
    throw new Error(`Khong kiem tra duoc Auth Emulator (${queryRes.status})`);
  }
  const queryData = await queryRes.json();
  const users = queryData.userInfo || [];
  const exists = users.some(
    (u) => String(u.email || '').toLowerCase() === ADMIN_EMAIL.toLowerCase(),
  );
  if (exists) return false;

  const signupRes = await fetch(
    `${EMULATOR_AUTH_BASE}/accounts:signUp?key=demo-api-key`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: ADMIN_EMAIL,
        password: LOCAL_DEFAULT_PASS,
        returnSecureToken: true,
      }),
    },
  );
  if (!signupRes.ok) {
    throw new Error(`Khong tao duoc Admin tren Auth Emulator: ${await signupRes.text()}`);
  }
  return true;
}

async function uploadBufferToEmulatorStorage(buffer, fileName, contentType) {
  const safeName = fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
  const objectName = `products/${Date.now()}_${safeName}`;
  const uploadUrl =
    `${EMULATOR_STORAGE_UPLOAD_BASE}?uploadType=media&name=${encodeURIComponent(objectName)}`;

  const res = await fetch(uploadUrl, {
    method: 'POST',
    headers: {
      Authorization: 'Bearer owner',
      'Content-Type': contentType,
    },
    body: buffer,
  });
  if (!res.ok) {
    throw new Error(`Loi upload anh len Storage Emulator: ${await res.text()}`);
  }

  const meta = await res.json();
  const token = meta.downloadTokens?.split(',')[0] || '';
  const encodedPath = encodeURIComponent(objectName);
  return token
    ? `http://localhost:9199/v0/b/${BUCKET}/o/${encodedPath}?alt=media&token=${token}`
    : `http://localhost:9199/v0/b/${BUCKET}/o/${encodedPath}?alt=media`;
}

async function uploadLocalFileToEmulatorStorage(filePath) {
  const buffer = fs.readFileSync(filePath);
  const fileName = path.basename(filePath);
  const mime = detectMimeType(fileName);
  const url = await uploadBufferToEmulatorStorage(buffer, fileName, mime);
  return { url, hash: sha256Buffer(buffer), fileName };
}

async function isEmulatorUrlReachable(url) {
  if (!isLocalhostUrl(url)) return true;
  try {
    const normalized = url
      .replace('://localhost:', '://127.0.0.1:')
      .replace('://10.0.2.2:', '://127.0.0.1:');
    const res = await fetch(normalized, { signal: AbortSignal.timeout(5000) });
    return res.ok;
  } catch {
    return false;
  }
}

async function backupEmulatorImageToComputer(productName, imageUrl, imageMap, uploadCache) {
  if (!isLocalhostUrl(imageUrl)) return null;
  try {
    const normalized = imageUrl
      .replace('://localhost:', '://127.0.0.1:')
      .replace('://10.0.2.2:', '://127.0.0.1:');
    const res = await fetch(normalized, { signal: AbortSignal.timeout(5000) });
    if (!res.ok) return null;

    const arrayBuf = await res.arrayBuffer();
    const buf = Buffer.from(arrayBuf);
    const mime = res.headers.get('content-type') || '';
    const ext = extensionFromMime(mime, imageUrl);
    const key = normalizeKey(productName);
    const existingFile = imageMap.get(key);
    const fileName = existingFile || `${slugify(productName)}${ext}`;
    const destPath = path.join(IMAGES_DIR, fileName);

    fs.writeFileSync(destPath, buf);
    imageMap.set(key, fileName);
    uploadCache[key] = {
      file: fileName,
      hash: sha256Buffer(buf),
      url: imageUrl,
    };
    return fileName;
  } catch {
    return null;
  }
}

async function fetchEmulatorProductsRaw() {
  const res = await fetch(EMULATOR_PRODUCTS_URL, {
    headers: { Authorization: 'Bearer owner' },
    signal: AbortSignal.timeout(10000),
  });
  if (!res.ok) {
    throw new Error(`Khong doc duoc Firestore Emulator (${res.status})`);
  }
  const data = await res.json();
  return data.documents || [];
}

/**
 * Đẩy toàn bộ sản phẩm & ảnh từ `local_products.json` + `product_images/` vào Emulator đang chạy:
 * - Thêm mới sản phẩm chưa có trên Emulator (upload ảnh từ máy lên Storage Emulator).
 * - Tự cập nhật ảnh nếu file ảnh trong `product_images/` mới/đổi hoặc URL ảnh trên Emulator bị hỏng/lỗi thời.
 * - Cập nhật giá/số lượng nếu file `local_products.json` được chỉnh từ máy tính.
 */
async function syncLocalToEmulator({ onlyWhenEmpty = false } = {}) {
  await ensureEmulatorAdminUser();
  const existingDocs = await fetchEmulatorProductsRaw();
  if (onlyWhenEmpty && existingDocs.length > 0) {
    // Dù không trống, vẫn kiểm tra nếu có ảnh trong product_images/ thay đổi hoặc chưa khớp thì cập nhật!
    await syncLocalImagesAndNewDocsIntoEmulator(existingDocs);
    return;
  }
  await syncLocalImagesAndNewDocsIntoEmulator(existingDocs);
}

async function syncLocalImagesAndNewDocsIntoEmulator(existingDocs) {
  const imageMap = loadImageMap();
  const uploadCache = loadUploadCache();

  let sourceProducts = readJsonFile(LOCAL_DB_PATH, []);
  if (!Array.isArray(sourceProducts) || sourceProducts.length === 0) {
    sourceProducts = readJsonFile(SAMPLE_DB_PATH, []);
  }

  const existingByName = new Map();
  for (const doc of existingDocs) {
    const prod = fromFirestoreDoc(doc);
    if (prod.name) {
      existingByName.set(normalizeKey(prod.name), {
        resourceName: doc.name,
        product: prod,
      });
    }
  }

  let added = 0;
  let updated = 0;
  const updatedLocalProducts = [];

  for (let i = 0; i < sourceProducts.length; i++) {
    const rawItem = sourceProducts[i];
    const item = {
      name: String(rawItem.name ?? '').trim(),
      price: Number(rawItem.price),
      soluong: Math.trunc(Number(rawItem.soluong)),
      image: String(rawItem.image ?? '').trim(),
    };
    if (!validateProduct(item, true)) continue;

    const key = normalizeKey(item.name);
    const existing = existingByName.get(key);
    const localFile = resolveLocalImageFile(item.name, item.image, imageMap);

    let targetUrl = existing ? existing.product.image : item.image;

    if (localFile) {
      const fileHash = sha256Buffer(fs.readFileSync(localFile));
      const cached = uploadCache[key];
      const existingUrlValid =
        isLocalhostUrl(targetUrl) && (await isEmulatorUrlReachable(targetUrl));

      if (!cached || cached.hash !== fileHash || !existingUrlValid) {
        const uploaded = await uploadLocalFileToEmulatorStorage(localFile);
        targetUrl = uploaded.url;
        uploadCache[key] = {
          file: uploaded.fileName,
          hash: uploaded.hash,
          url: targetUrl,
        };
      } else if (cached.url) {
        targetUrl = cached.url;
      }
    } else if (
      !isHttpUrl(targetUrl) ||
      targetUrl.includes('placehold.co') ||
      !(await isEmulatorUrlReachable(targetUrl))
    ) {
      const palette = COLOR_PALETTE[i % COLOR_PALETTE.length];
      const pngBuf = createFallbackPngBuffer(240, 240, palette[0], palette[1]);
      targetUrl = await uploadBufferToEmulatorStorage(
        pngBuf,
        `${slugify(item.name)}.png`,
        'image/png',
      );
    }

    const finalProduct = {
      name: item.name,
      price: item.price,
      soluong: item.soluong,
      image: targetUrl,
    };

    if (!existing) {
      const res = await fetch(EMULATOR_PRODUCTS_URL, {
        method: 'POST',
        headers: {
          Authorization: 'Bearer owner',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ fields: toFirestoreFields(finalProduct) }),
      });
      if (!res.ok) {
        throw new Error(`Loi them "${item.name}" vao Emulator: ${await res.text()}`);
      }
      added += 1;
    } else if (
      existing.product.price !== finalProduct.price ||
      existing.product.soluong !== finalProduct.soluong ||
      existing.product.image !== finalProduct.image
    ) {
      const patchUrl =
        `http://127.0.0.1:8080/v1/${existing.resourceName}?updateMask.fieldPaths=name&updateMask.fieldPaths=price&updateMask.fieldPaths=soluong&updateMask.fieldPaths=image`;
      const res = await fetch(patchUrl, {
        method: 'PATCH',
        headers: {
          Authorization: 'Bearer owner',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ fields: toFirestoreFields(finalProduct) }),
      });
      if (!res.ok) {
        throw new Error(`Loi cap nhat "${item.name}" tren Emulator: ${await res.text()}`);
      }
      updated += 1;
    }

    updatedLocalProducts.push(finalProduct);
  }

  saveImageMap(imageMap);
  saveUploadCache(uploadCache);

  if (updatedLocalProducts.length > 0) {
    fs.writeFileSync(
      LOCAL_DB_PATH,
      JSON.stringify(updatedLocalProducts, null, 2) + '\n',
      'utf8',
    );
  }

  console.log(
    `[Emulator] Dong bo xong tu may tinh -> Emulator: +${added} them moi, ~${updated} cap nhat (tong ${updatedLocalProducts.length} san pham).`,
  );
}

async function hydrateEmulator() {
  const createdAdmin = await ensureEmulatorAdminUser();
  if (createdAdmin) {
    console.log(`[Emulator] Da khoi phuc tai khoan Admin: ${ADMIN_EMAIL}`);
  }

  const existingDocs = await fetchEmulatorProductsRaw();
  if (existingDocs.length === 0) {
    // Nếu local_products.json chưa có gì và Cloud có quyền, thử kéo từ Cloud trước.
    let localItems = readJsonFile(LOCAL_DB_PATH, []);
    const saPath = findServiceAccountPath();
    if (localItems.length === 0 && saPath) {
      try {
        const token = await getAccessTokenFromServiceAccount(saPath);
        const cloudDocs = await fetchExistingCloudDocsRaw(token);
        if (cloudDocs.length > 0) {
          localItems = cloudDocs.map(fromFirestoreDoc).filter(validateProduct);
          fs.writeFileSync(LOCAL_DB_PATH, JSON.stringify(localItems, null, 2) + '\n', 'utf8');
        }
      } catch {
        // Dùng local_products.json / sample_products.json nếu Cloud từ chối
      }
    }
  }

  await syncLocalImagesAndNewDocsIntoEmulator(existingDocs);
}

async function pullFromEmulatorIfRunning() {
  try {
    const docs = await fetchEmulatorProductsRaw();
    if (docs.length === 0) return null;

    const imageMap = loadImageMap();
    const uploadCache = loadUploadCache();
    const exported = [];

    for (const doc of docs) {
      const item = fromFirestoreDoc(doc);
      if (!validateProduct(item)) continue;
      if (isLocalhostUrl(item.image)) {
        await backupEmulatorImageToComputer(item.name, item.image, imageMap, uploadCache);
      }
      exported.push(item);
    }

    saveImageMap(imageMap);
    saveUploadCache(uploadCache);

    if (exported.length > 0) {
      fs.writeFileSync(LOCAL_DB_PATH, JSON.stringify(exported, null, 2) + '\n', 'utf8');
      console.log(
        `[Emulator -> Local] Da luu ${exported.length} san pham vao local_products.json va sao luu anh tai product_images/.`,
      );
      return exported;
    }
    return null;
  } catch {
    return null;
  }
}

function base64UrlEncode(input) {
  return Buffer.from(input)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

async function getAccessTokenFromServiceAccount(saPath) {
  const sa = JSON.parse(fs.readFileSync(saPath, 'utf8'));
  const now = Math.floor(Date.now() / 1000);
  const header = base64UrlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claimSet = base64UrlEncode(
    JSON.stringify({
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/datastore',
      aud: sa.token_uri || 'https://oauth2.googleapis.com/token',
      exp: now + 3600,
      iat: now,
    }),
  );

  const unsignedJwt = `${header}.${claimSet}`;
  const signer = crypto.createSign('RSA-SHA256');
  signer.update(unsignedJwt);
  const signature = base64UrlEncode(signer.sign(sa.private_key));
  const assertion = `${unsignedJwt}.${signature}`;

  const tokenRes = await fetch(sa.token_uri || 'https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  if (!tokenRes.ok) {
    throw new Error(`Loi lay OAuth token tu Service Account: ${await tokenRes.text()}`);
  }
  const tokenJson = await tokenRes.json();
  return tokenJson.access_token;
}

function readWebApiKeyFromFlutterOptions() {
  if (!fs.existsSync(FIREBASE_OPTIONS_PATH)) return null;
  const content = fs.readFileSync(FIREBASE_OPTIONS_PATH, 'utf8');
  const match = content.match(/apiKey:\s*'([^']+)'/);
  if (!match) return null;
  const key = match[1].trim();
  if (!key || key.startsWith('REPLACE_WITH_')) return null;
  return key;
}

async function getAdminIdTokenFromPassword(apiKey) {
  let password = process.env.FIREBASE_ADMIN_PASSWORD || '';
  if (!password) {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });
    password = await rl.question(
      `Nhap mat khau Admin (${ADMIN_EMAIL}) de dong bo len Cloud gk-ptdnt: `,
    );
    rl.close();
  }

  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(apiKey)}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: ADMIN_EMAIL,
        password: password.trim(),
        returnSecureToken: true,
      }),
    },
  );

  if (!res.ok) {
    throw new Error(`Dang nhap Admin Firebase that bai: ${await res.text()}`);
  }
  const data = await res.json();
  return data.idToken;
}

function findServiceAccountPath() {
  const envPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (envPath && fs.existsSync(envPath)) return envPath;
  if (fs.existsSync(SERVICE_ACCOUNT_PATH)) return SERVICE_ACCOUNT_PATH;

  const files = fs.readdirSync(__dirname);
  const adminSdkFile = files.find(
    (name) => name.endsWith('.json') && name.includes('firebase-adminsdk'),
  );
  return adminSdkFile ? path.join(__dirname, adminSdkFile) : null;
}

async function resolveCloudAuthToken() {
  const saPath = findServiceAccountPath();
  if (saPath) {
    console.log(`[Auth] Dang xac thuc bang Service Account: ${path.basename(saPath)}`);
    return getAccessTokenFromServiceAccount(saPath);
  }

  const webApiKey = readWebApiKeyFromFlutterOptions();
  if (webApiKey) {
    console.log('[Auth] Dang xac thuc bang tai khoan Admin Firebase Authentication...');
    return getAdminIdTokenFromPassword(webApiKey);
  }

  console.error('\n[CHUA CO XAC THUC CLOUD FIREBASE]');
  console.error('De dong bo du lieu len Cloud Firestore (gk-ptdnt), hay dat file serviceAccountKey.json tai:');
  console.error(`  ${SERVICE_ACCOUNT_PATH}`);
  process.exit(1);
}

async function fetchExistingCloudDocsRaw(token) {
  const docs = [];
  let pageToken = '';

  while (true) {
    const url = pageToken
      ? `${CLOUD_PRODUCTS_URL}?pageSize=200&pageToken=${encodeURIComponent(pageToken)}`
      : `${CLOUD_PRODUCTS_URL}?pageSize=200`;

    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) {
      const errBody = await res.text();
      if (res.status === 403) {
        throw new Error(
          `Cloud Firestore tu choi quyen (403 PERMISSION_DENIED). ` +
          `Service Account dang khong co quyen IAM tren project "${PROJECT_ID}". ` +
          `Hay vao Google Cloud Console -> IAM & Admin -> IAM (project ${PROJECT_ID}), ` +
          `cap quyen "Cloud Datastore User" cho Service Account (hoac tao Service Account moi co quyen nay va thay vao serviceAccountKey.json).\nChi tiet: ${errBody}`,
        );
      }
      throw new Error(`Khong doc duoc Cloud Firestore (${res.status}): ${errBody}`);
    }
    const data = await res.json();
    if (Array.isArray(data.documents)) {
      docs.push(...data.documents);
    }
    if (!data.nextPageToken) break;
    pageToken = data.nextPageToken;
  }
  return docs;
}

async function syncProductsToCloud(products, token) {
  const docs = await fetchExistingCloudDocsRaw(token);
  const existingByName = new Map();
  for (const doc of docs) {
    const product = fromFirestoreDoc(doc);
    if (product.name) {
      existingByName.set(normalizeKey(product.name), doc.name);
    }
  }

  let createdCount = 0;
  let updatedCount = 0;

  for (const product of products) {
    const fields = toFirestoreFields(product);
    const existingResourceName = existingByName.get(normalizeKey(product.name));

    if (existingResourceName) {
      const patchUrl =
        `https://firestore.googleapis.com/v1/${existingResourceName}?updateMask.fieldPaths=name&updateMask.fieldPaths=price&updateMask.fieldPaths=soluong&updateMask.fieldPaths=image`;
      const res = await fetch(patchUrl, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ fields }),
      });
      if (!res.ok) {
        throw new Error(`Loi cap nhat "${product.name}" (${res.status}): ${await res.text()}`);
      }
      updatedCount += 1;
    } else {
      const res = await fetch(CLOUD_PRODUCTS_URL, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ fields }),
      });
      if (!res.ok) {
        throw new Error(`Loi them moi "${product.name}" (${res.status}): ${await res.text()}`);
      }
      createdCount += 1;
    }
  }

  console.log(
    `\n[Hoan tat] Da dong bo ${products.length} san pham len Cloud Firestore (${PROJECT_ID}): +${createdCount} them moi, ~${updatedCount} cap nhat.`,
  );
}

async function main() {
  const dryCheck = process.argv.includes('--check');
  const exportLocalOnly = process.argv.includes('--export-local-only');
  const shouldHydrate = process.argv.includes('--hydrate-emulator');
  const shouldSyncLocalToEmulator = process.argv.includes('--sync-local-to-emulator');

  if (shouldHydrate) {
    await hydrateEmulator();
    return;
  }

  if (shouldSyncLocalToEmulator) {
    await syncLocalToEmulator();
    return;
  }

  const fromEmulator = await pullFromEmulatorIfRunning();
  if (exportLocalOnly) {
    return;
  }

  let baseProducts = readJsonFile(LOCAL_DB_PATH, []);
  if (baseProducts.length === 0) {
    baseProducts = readJsonFile(SAMPLE_DB_PATH, []);
  }

  const productsToSync = (fromEmulator ?? baseProducts).map((p) => ({
    name: String(p.name ?? '').trim(),
    price: Number(p.price),
    soluong: Math.trunc(Number(p.soluong)),
    image: String(p.image ?? '').trim(),
  }));

  const invalid = productsToSync.filter((p) => !validateProduct(p, false));
  if (invalid.length > 0) {
    console.error('Phat hien san pham khong hop le trong local_products.json:', invalid);
    process.exit(1);
  }

  if (dryCheck) {
    console.log(
      `[Check OK] San sang dong bo ${productsToSync.length} san pham hop le (dung 4 truong name, price, soluong, image).`,
    );
    return;
  }

  const token = await resolveCloudAuthToken();
  await syncProductsToCloud(productsToSync, token);
}

main().catch((err) => {
  console.error('\n[Loi dong bo Firebase]:', err.message || err);
  process.exit(1);
});

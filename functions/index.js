const { onRequest } = require('firebase-functions/v2/https');
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const crypto = require('node:crypto');

admin.initializeApp();
const db = admin.firestore();
const { FieldValue, Timestamp } = admin.firestore;

const VEHDB_TOKEN = defineSecret('VEHDB_TOKEN');
const VEHDB_BASE = 'https://api.vehdb.com/v1';

const TIRE_WHOLESALE = Object.freeze({
  '500/12': 67320,
  '550/12': 104040,
  '550/13': 87210,
  '165/65/13': 73440,
  '175/70/13': 73440,
  '175/70/14': 68850,
  '185/65/14': 76500,
  '185/70/14': 87210,
  '195/70/14': 88740,
  '195/14': 126990,
  '185/14': 104040,
  '205/75/14 خط': 119340,
  '195/65/15': 84150,
  '195/65/15 كومفورس': 91800,
  '195/65/15 هلو': 96390,
  '205/65/15': 104040,
  '205/70/15': 99450,
  '205/70/15 خط': 114750,
  '215/75/15': 114750,
  '195/55/15': 81090,
  '195/60/15': 81090,
  '185/65/15': 81090,
  '185/55/15': 81090,
  '195/15': 128520,
  '195/55/16': 91800,
  '205/55/16 كومفورس': 102510,
  '205/55/16 هلو': 111690,
  '205/55/16': 99450,
  '215/60/16': 110160,
});

const BATTERIES = Object.freeze({
  'battery-انجيكو كوري-43 مربع': { brand: 'انجيكو كوري', amp: '43 مربع', wholesale: 61200 },
  'battery-انجيكو كوري-62': { brand: 'انجيكو كوري', amp: '62', wholesale: 76500 },
  'battery-انجيكو كوري-70 عالي': { brand: 'انجيكو كوري', amp: '70 عالي', wholesale: 84150 },
  'battery-انجيكو كوري-74': { brand: 'انجيكو كوري', amp: '74', wholesale: 87210 },
  'battery-انجيكو كوري-80 ناصي': { brand: 'انجيكو كوري', amp: '80 ناصي', wholesale: 107100 },
  'battery-انجيكو كوري-88': { brand: 'انجيكو كوري', amp: '88', wholesale: 107100 },
  'battery-انجيكو كوري-90': { brand: 'انجيكو كوري', amp: '90', wholesale: 99450 },
  'battery-انجيكو كوري-100 مستطيل': { brand: 'انجيكو كوري', amp: '100 مستطيل', wholesale: 114750 },
  'battery-انجيكو كوري-150': { brand: 'انجيكو كوري', amp: '150', wholesale: 175950 },
  'battery-ماليزي-62': { brand: 'ماليزي', amp: '62', wholesale: 61200 },
  'battery-ماليزي-70 عالي': { brand: 'ماليزي', amp: '70 عالي', wholesale: 68850 },
  'battery-ماليزي-74': { brand: 'ماليزي', amp: '74', wholesale: 76500 },
  'battery-ماليزي-80': { brand: 'ماليزي', amp: '80', wholesale: 81090 },
  'battery-ماليزي-88': { brand: 'ماليزي', amp: '88', wholesale: 81090 },
  'battery-ماليزي-90': { brand: 'ماليزي', amp: '90', wholesale: 81090 },
  'battery-ماليزي-100 مستطيل': { brand: 'ماليزي', amp: '100 مستطيل', wholesale: 84150 },
  'battery-ماليزي-100 مربع': { brand: 'ماليزي', amp: '100 مربع', wholesale: 111690 },
  'battery-ماليزي-150': { brand: 'ماليزي', amp: '150', wholesale: 134640 },
  'battery-زكستور عراقي-62': { brand: 'زكستور عراقي', amp: '62', wholesale: 44370 },
  'battery-زكستور عراقي-70': { brand: 'زكستور عراقي', amp: '70', wholesale: 58140 },
  'battery-زكستور عراقي-74': { brand: 'زكستور عراقي', amp: '74', wholesale: 58140 },
});

function sendJson(res, status, body, cacheControl = 'public, max-age=300') {
  res.status(status).set('Cache-Control', cacheControl).json(body);
}

function sendPrivateJson(res, status, body) {
  sendJson(res, status, body, 'no-store');
}

function allowCors(req, res) {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return true;
  }
  return false;
}

function priceRuleId(category, key) {
  return `${category}_${key}`.replace(/[^A-Za-z0-9_-]/g, '_');
}

function tireProfit(wholesale) {
  if (wholesale < 150000) return 10000;
  if (wholesale < 200000) return 12000;
  return 15000;
}

function tireCommission(wholesale) {
  if (wholesale < 100000) return 3000;
  if (wholesale < 150000) return 4000;
  return 5000;
}

function inventoryDocId(productId) {
  return Buffer.from(productId, 'utf8').toString('base64url');
}

function makeOrderCode() {
  return String(crypto.randomInt(10000000, 100000000));
}

async function trustedProduct(productId, detail) {
  if (productId.startsWith('tire-')) {
    const size = productId.substring('tire-'.length);
    const wholesale = TIRE_WHOLESALE[size];
    if (!Number.isInteger(wholesale)) return null;
    const commission = tireCommission(wholesale);
    const fallbackPrice = wholesale + tireProfit(wholesale) + commission;
    const rule = await db.collection('price_rules').doc(priceRuleId('tires', size)).get();
    const remoteValue = rule.data()?.value;
    const price = Number.isInteger(remoteValue) && remoteValue > 0 ? remoteValue : fallbackPrice;
    return {
      title: `إطار ${size}`,
      detail: 'سعر الزوج • شد وبلنص حسب العرض',
      price,
      commission,
      productId,
    };
  }

  const battery = BATTERIES[productId];
  if (!battery) return null;
  let variant;
  if (detail === 'مع تسليم البطارية القديمة') {
    variant = 'with_old';
  } else if (detail === 'بدون تسليم البطارية القديمة') {
    variant = 'without_old';
  } else {
    return null;
  }
  const commission = 3000;
  const fallbackPrice = variant === 'with_old'
    ? battery.wholesale + 3000
    : battery.wholesale + 10000 + 3000;
  const ruleKey = `${battery.brand}_${battery.amp}_${variant}`;
  const rule = await db.collection('price_rules').doc(priceRuleId('batteries', ruleKey)).get();
  const remoteValue = rule.data()?.value;
  const price = Number.isInteger(remoteValue) && remoteValue > 0 ? remoteValue : fallbackPrice;
  return {
    title: `${battery.brand} ${battery.amp}`,
    detail: variant === 'with_old'
      ? 'مع تسليم البطارية القديمة'
      : 'بدون تسليم البطارية القديمة',
    price,
    commission,
    productId,
  };
}

function iraqWeekStart(date) {
  const iraqOffsetMs = 3 * 60 * 60 * 1000;
  const local = new Date(date.getTime() + iraqOffsetMs);
  const weekday = local.getUTCDay();
  const daysFromMonday = weekday === 0 ? 6 : weekday - 1;
  const startLocalMs = Date.UTC(
    local.getUTCFullYear(),
    local.getUTCMonth(),
    local.getUTCDate() - daysFromMonday,
    0,
    0,
    0,
    0,
  );
  return new Date(startLocalMs - iraqOffsetMs);
}

function weekKey(date) {
  const iraqOffsetMs = 3 * 60 * 60 * 1000;
  const local = new Date(date.getTime() + iraqOffsetMs);
  const y = local.getUTCFullYear();
  const m = String(local.getUTCMonth() + 1).padStart(2, '0');
  const d = String(local.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

async function vehdbGet(path, params = {}) {
  const url = new URL(`${VEHDB_BASE}${path}`);
  for (const [key, value] of Object.entries(params)) {
    if (value !== undefined && value !== null && `${value}`.trim() !== '') {
      url.searchParams.set(key, `${value}`);
    }
  }

  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${VEHDB_TOKEN.value()}`,
      Accept: 'application/json',
    },
  });

  const text = await response.text();
  let body;
  try {
    body = text ? JSON.parse(text) : {};
  } catch (_) {
    body = { message: text || 'Invalid VehDB response' };
  }

  if (!response.ok) {
    const error = new Error(`VehDB HTTP ${response.status}`);
    error.status = response.status;
    error.body = body;
    throw error;
  }

  return body;
}

exports.vehdb = onRequest(
  {
    region: 'europe-west1',
    secrets: [VEHDB_TOKEN],
    timeoutSeconds: 30,
    memory: '256MiB',
  },
  async (req, res) => {
    if (req.method !== 'GET') {
      return sendJson(res, 405, { error: 'Method not allowed' });
    }

    try {
      const route = req.path.replace(/^\/+|\/+$/g, '');
      let data;

      if (route === 'makes') {
        data = await vehdbGet('/tire-sizes/makes');
      } else if (route === 'models') {
        if (!req.query.make) return sendJson(res, 400, { error: 'make is required' });
        data = await vehdbGet('/tire-sizes/models', { make: req.query.make });
      } else if (route === 'cars') {
        const { make, model, year } = req.query;
        if (!make || !model || !year) {
          return sendJson(res, 400, { error: 'make, model and year are required' });
        }
        data = await vehdbGet('/cars', { make, model, year });
      } else if (route === 'sizes') {
        const { make, model, year } = req.query;
        if (!make || !model || !year) {
          return sendJson(res, 400, { error: 'make, model and year are required' });
        }
        data = await vehdbGet('/tire-sizes', {
          make,
          model,
          year,
          per_page: 100,
        });
      } else if (route.startsWith('car-sizes/')) {
        const carId = route.substring('car-sizes/'.length).trim();
        if (!carId) return sendJson(res, 400, { error: 'car id is required' });
        data = await vehdbGet(`/cars/${encodeURIComponent(carId)}/tire-sizes`);
      } else {
        return sendJson(res, 404, { error: 'Unknown endpoint' });
      }

      return sendJson(res, 200, data);
    } catch (error) {
      console.error('VehDB proxy error', error);
      return sendJson(res, error.status || 500, {
        error: 'VehDB request failed',
        details: error.body || error.message,
      });
    }
  },
);

exports.orderApi = onRequest(
  {
    region: 'europe-west1',
    timeoutSeconds: 20,
    memory: '256MiB',
  },
  async (req, res) => {
    if (allowCors(req, res)) return;
    if (req.method !== 'POST') {
      return sendPrivateJson(res, 405, { error: 'طريقة الطلب غير مسموحة' });
    }

    try {
      const shopId = `${req.body?.shopId ?? ''}`.trim();
      const productId = `${req.body?.productId ?? ''}`.trim();
      const detail = `${req.body?.detail ?? ''}`.trim();
      const expectedPrice = Number(req.body?.expectedPrice);

      if (!shopId || !productId || !Number.isInteger(expectedPrice) || expectedPrice <= 0) {
        return sendPrivateJson(res, 400, { error: 'بيانات الطلب غير مكتملة' });
      }

      const product = await trustedProduct(productId, detail);
      if (!product) {
        return sendPrivateJson(res, 400, { error: 'المنتج أو خيار السعر غير صالح' });
      }
      if (product.price !== expectedPrice) {
        return sendPrivateJson(res, 409, {
          error: 'السعر تغيّر. ارجع حدّث صفحة المنتج وأعد إنشاء الطلب.',
          currentPrice: product.price,
        });
      }

      const shopRef = db.collection('shops').doc(shopId);
      const code = makeOrderCode();
      const orderRef = db.collection('orders').doc(code);
      const notificationRef = db.collection('notifications').doc(code);
      const now = Timestamp.now();
      const expiresAt = Timestamp.fromMillis(now.toMillis() + 24 * 60 * 60 * 1000);
      let shopName = '';

      await db.runTransaction(async (tx) => {
        const shopSnap = await tx.get(shopRef);
        const shop = shopSnap.data();
        if (!shopSnap.exists || !shop || shop.approved !== true || shop.status === 'suspended') {
          const error = new Error('هذا المحل غير متاح للطلبات حالياً');
          error.status = 409;
          throw error;
        }
        shopName = `${shop.name ?? ''}`;

        if (shop.inventoryEnabled === true) {
          const inventoryRef = shopRef.collection('inventory').doc(inventoryDocId(productId));
          const inventorySnap = await tx.get(inventoryRef);
          const inventory = inventorySnap.data();
          const quantity = Number(inventory?.quantity ?? 0);
          if (!inventorySnap.exists || inventory?.available !== true || quantity <= 0) {
            const error = new Error('هذا المنتج نفد من المحل. اختار محل ثاني');
            error.status = 409;
            throw error;
          }
        }

        const orderData = {
          code,
          title: product.title,
          detail: product.detail,
          price: product.price,
          commission: product.commission,
          createdAt: now,
          completed: false,
          completedAt: null,
          shopId,
          shopName,
          status: 'new',
          expiresAt,
          productId,
          priceLocked: true,
          priceLockedAt: now,
          settlementId: '',
          settlementStatus: '',
          inventoryCheckedAt: now,
          serverCreated: true,
        };
        tx.create(orderRef, orderData);
        tx.set(notificationRef, {
          targetShopId: shopId,
          title: 'طلب جديد',
          body: `${product.title} • ${product.price} د.ع`,
          orderCode: code,
          createdAt: now,
        });
      });

      await db.collection('audit_logs').add({
        action: 'order_created_server',
        targetType: 'order',
        targetId: code,
        details: `${shopName} • سعر مثبت ${product.price} د.ع`,
        createdAt: now,
        actor: 'order_api',
      });

      return sendPrivateJson(res, 200, {
        order: {
          code,
          title: product.title,
          detail: product.detail,
          price: product.price,
          commission: product.commission,
          createdAt: now.toDate().toISOString(),
          completed: false,
          completedAt: null,
          shopId,
          shopName,
          status: 'new',
          expiresAt: expiresAt.toDate().toISOString(),
          productId,
        },
      });
    } catch (error) {
      console.error('Order API error', error);
      return sendPrivateJson(res, error.status || 500, {
        error: error.status ? error.message : 'تعذر إنشاء الطلب حالياً. حاول مرة ثانية.',
      });
    }
  },
);

exports.autoWeeklySettlement = onDocumentUpdated(
  {
    document: 'orders/{code}',
    region: 'europe-west1',
    memory: '256MiB',
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.completed === true || after.completed !== true) return;

    const orderRef = event.data.after.ref;
    const code = event.params.code;
    const shopId = `${after.shopId ?? ''}`.trim();
    const shopName = `${after.shopName ?? ''}`.trim();
    const commission = Number(after.commission ?? 0);
    const price = Number(after.price ?? 0);
    if (!shopId || !Number.isInteger(commission) || commission <= 0) return;

    const completedAt = after.completedAt instanceof Timestamp
      ? after.completedAt.toDate()
      : new Date();
    const start = iraqWeekStart(completedAt);
    const end = new Date(start.getTime() + 7 * 24 * 60 * 60 * 1000);
    const baseSettlementId = `${shopId}_${weekKey(start)}`;

    await db.runTransaction(async (tx) => {
      const freshOrderSnap = await tx.get(orderRef);
      const freshOrder = freshOrderSnap.data();
      if (!freshOrder || freshOrder.completed !== true || `${freshOrder.settlementId ?? ''}`.trim()) return;

      let settlementId = baseSettlementId;
      let settlementRef = db.collection('settlements').doc(settlementId);
      let settlementSnap = await tx.get(settlementRef);
      if (settlementSnap.exists && settlementSnap.data()?.status === 'paid') {
        settlementId = `${baseSettlementId}_${code}`;
        settlementRef = db.collection('settlements').doc(settlementId);
        settlementSnap = await tx.get(settlementRef);
      }

      const exists = settlementSnap.exists;
      tx.set(
        settlementRef,
        {
          id: settlementId,
          shopId,
          shopName,
          weekStart: Timestamp.fromDate(start),
          weekEnd: Timestamp.fromDate(end),
          totalSales: FieldValue.increment(Number.isInteger(price) ? price : 0),
          totalCommission: FieldValue.increment(commission),
          orderCount: FieldValue.increment(1),
          orderCodes: FieldValue.arrayUnion(code),
          status: 'pending',
          ...(exists ? {} : { createdAt: FieldValue.serverTimestamp(), paidAt: null }),
          updatedAt: FieldValue.serverTimestamp(),
          generatedBy: 'server',
        },
        { merge: true },
      );
      tx.update(orderRef, {
        settlementId,
        settlementStatus: 'pending',
        settlementAssignedAt: FieldValue.serverTimestamp(),
      });
    });
  },
);

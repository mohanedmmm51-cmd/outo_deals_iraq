const admin = require('firebase-admin');

admin.initializeApp({ credential: admin.credential.applicationDefault() });
const db = admin.firestore();

const tires = [
  ['500/12', 67320], ['550/12', 104040], ['550/13', 87210],
  ['165/65/13', 73440], ['175/70/13', 73440], ['175/70/14', 68850],
  ['185/65/14', 76500], ['185/70/14', 87210], ['195/70/14', 88740],
  ['195/14', 126990], ['185/14', 104040], ['205/75/14 خط', 119340],
  ['195/65/15', 84150], ['195/65/15 كومفورس', 91800], ['195/65/15 هلو', 96390],
  ['205/65/15', 104040], ['205/70/15', 99450], ['205/70/15 خط', 114750],
  ['215/75/15', 114750], ['195/55/15', 81090], ['195/60/15', 81090],
  ['185/65/15', 81090], ['185/55/15', 81090], ['195/15', 128520],
  ['195/55/16', 91800], ['205/55/16 كومفورس', 102510], ['205/55/16 هلو', 111690],
  ['205/55/16', 99450], ['215/60/16', 110160],
];

const batteries = [
  ['انجيكو كوري', '43 مربع', 61200], ['انجيكو كوري', '62', 76500],
  ['انجيكو كوري', '70 عالي', 84150], ['انجيكو كوري', '74', 87210],
  ['انجيكو كوري', '80 ناصي', 107100], ['انجيكو كوري', '88', 107100],
  ['انجيكو كوري', '90', 99450], ['انجيكو كوري', '100 مستطيل', 114750],
  ['انجيكو كوري', '150', 175950], ['ماليزي', '62', 61200],
  ['ماليزي', '70 عالي', 68850], ['ماليزي', '74', 76500],
  ['ماليزي', '80', 81090], ['ماليزي', '88', 81090],
  ['ماليزي', '90', 81090], ['ماليزي', '100 مستطيل', 84150],
  ['ماليزي', '100 مربع', 111690], ['ماليزي', '150', 134640],
  ['زكستور عراقي', '62', 44370], ['زكستور عراقي', '70', 58140],
  ['زكستور عراقي', '74', 58140],
];

function ruleId(category, key) {
  return `${category}_${key}`.replace(/[^A-Za-z0-9_-]/g, '_');
}

function inventoryItemId(productId) {
  return Buffer.from(productId, 'utf8').toString('base64url');
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

function buildCatalog() {
  const products = {};

  for (const [size, wholesale] of tires) {
    const productId = `tire-${size}`;
    const commission = tireCommission(wholesale);
    products[productId] = {
      title: `إطار ${size}`,
      inventoryItemId: inventoryItemId(productId),
      variants: {
        'سعر الزوج • شد وبلنص حسب العرض': {
          fallbackPrice: wholesale + tireProfit(wholesale) + commission,
          commission,
          priceRuleId: ruleId('tires', size),
        },
      },
    };
  }

  for (const [brand, amp, wholesale] of batteries) {
    const productId = `battery-${brand}-${amp}`;
    products[productId] = {
      title: `${brand} ${amp}`,
      inventoryItemId: inventoryItemId(productId),
      variants: {
        'مع تسليم البطارية القديمة': {
          fallbackPrice: wholesale + 3000,
          commission: 3000,
          priceRuleId: ruleId('batteries', `${brand}_${amp}_with_old`),
        },
        'بدون تسليم البطارية القديمة': {
          fallbackPrice: wholesale + 10000 + 3000,
          commission: 3000,
          priceRuleId: ruleId('batteries', `${brand}_${amp}_without_old`),
        },
      },
    };
  }

  return products;
}

async function main() {
  const ref = db.collection('security_config').doc('order_catalog');
  await ref.set({
    version: 2,
    products: buildCatalog(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log('Trusted order catalog seeded successfully.');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

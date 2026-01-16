// Run this script to add remainingMinutes field to existing subscriptions
// node update_subscriptions_schema.js

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateSubscriptions() {
  try {
    console.log('🔍 Fetching all subscriptions...');
    const snapshot = await db.collection('subscriptions').get();
    
    console.log(`📦 Found ${snapshot.size} subscriptions`);
    
    let updated = 0;
    const batch = db.batch();
    
    snapshot.docs.forEach((doc) => {
      const data = doc.data();
      
      // Only update if remainingMinutes doesn't exist
      if (data.remainingMinutes === undefined) {
        batch.update(doc.ref, {
          remainingMinutes: 0
        });
        updated++;
        console.log(`   ✅ Queued update for subscription ${doc.id}`);
      }
    });
    
    if (updated > 0) {
      await batch.commit();
      console.log(`\n✅ Successfully updated ${updated} subscriptions`);
    } else {
      console.log('\n✅ All subscriptions already have remainingMinutes field');
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

updateSubscriptions();

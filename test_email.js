// Test script to check if Firebase can send emails
const admin = require('firebase-admin');
const serviceAccount = require('./sehat-makaan-firebase-adminsdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testEmail() {
  try {
    console.log('Creating test email in queue...');
    
    const emailRef = await db.collection('email_queue').add({
      to: 'test@example.com', // Replace with your test email
      template: 'otp',
      data: {
        otp: '123456',
        name: 'Test User'
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending'
    });

    console.log('✅ Email queued successfully with ID:', emailRef.id);
    console.log('Check Firebase Console and Cloud Functions logs');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

testEmail();

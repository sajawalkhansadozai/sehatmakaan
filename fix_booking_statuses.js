// Script to fix booking statuses - mark future bookings as confirmed instead of completed
// Run this with: node fix_booking_statuses.js

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./path/to/serviceAccountKey.json');  // Update this path

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixBookingStatuses() {
  try {
    console.log('🔍 Fetching all bookings with completed status...');
    
    const bookingsSnapshot = await db.collection('bookings')
      .where('status', '==', 'completed')
      .get();
    
    console.log(`Found ${bookingsSnapshot.size} completed bookings`);
    
    const now = new Date();
    let updatedCount = 0;
    
    for (const doc of bookingsSnapshot.docs) {
      const data = doc.data();
      const bookingId = doc.id;
      
      let bookingDateTime = null;
      
      // Parse booking date
      if (data.bookingDate && data.bookingDate._seconds) {
        // Timestamp format
        bookingDateTime = new Date(data.bookingDate._seconds * 1000);
      } else if (typeof data.bookingDate === 'string') {
        // String format (M/d/yyyy)
        const parts = data.bookingDate.split('/');
        if (parts.length === 3) {
          bookingDateTime = new Date(parts[2], parts[0] - 1, parts[1]);
          
          // Add time if available
          if (data.timeSlot) {
            const timeParts = data.timeSlot.split(':');
            if (timeParts.length >= 2) {
              bookingDateTime.setHours(parseInt(timeParts[0]), parseInt(timeParts[1]));
            }
          }
        }
      }
      
      if (bookingDateTime && bookingDateTime > now) {
        console.log(`📅 Fixing future booking ${bookingId}: ${bookingDateTime.toISOString()}`);
        await doc.ref.update({ status: 'confirmed' });
        updatedCount++;
      }
    }
    
    console.log(`✅ Updated ${updatedCount} future bookings to confirmed status`);
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

fixBookingStatuses();

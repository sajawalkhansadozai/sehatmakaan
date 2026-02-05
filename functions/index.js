const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const crypto = require('crypto');

admin.initializeApp();

// ✅ Environment Variables Configuration (Replaces deprecated functions.config())
const gmailEmail = process.env.GMAIL_EMAIL || functions.config().gmail?.email;
const gmailPassword = process.env.GMAIL_PASSWORD || functions.config().gmail?.password;
const payfastMerchantId = process.env.PAYFAST_MERCHANT_ID || '102';
const payfastMerchantKey = process.env.PAYFAST_MERCHANT_KEY || 'zWHjBp2AlttNu1sK';
const payfastTestMode = process.env.PAYFAST_TEST_MODE !== 'false';

// Create reusable transporter
let transporter;
if (gmailEmail && gmailPassword) {
  transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: gmailEmail,
      pass: gmailPassword
    }
  });
  console.log('✅ Email transporter configured with Gmail');
} else {
  console.warn('⚠️ Gmail credentials not configured. Emails will be logged only.');
  console.warn('Set credentials in .env.local or with: firebase functions:secrets:set GMAIL_EMAIL');
}

/**
 * Verify PayFast signature to ensure webhook authenticity
 * @param {Object} data - Payment data from PayFast
 * @param {string} passphrase - PayFast passphrase (optional)
 * @returns {boolean} - True if signature is valid
 */
function verifyPayFastSignature(data, passphrase = '') {
  const signature = data.signature;
  if (!signature) {
    console.warn('⚠️ No signature provided in webhook');
    return false;
  }

  // Create parameter string (exclude signature field)
  const paramString = Object.keys(data)
    .filter(key => key !== 'signature' && data[key] !== '' && data[key] !== null)
    .sort()
    .map(key => `${key}=${encodeURIComponent(data[key]).replace(/%20/g, '+')}`)
    .join('&');

  // Add passphrase if provided
  const stringToHash = passphrase ? `${paramString}&passphrase=${passphrase}` : paramString;

  // Generate MD5 hash
  const calculatedSignature = crypto.createHash('md5').update(stringToHash).digest('hex');

  const isValid = calculatedSignature === signature;
  if (!isValid) {
    console.error('❌ Signature mismatch!');
    console.error('Expected:', calculatedSignature);
    console.error('Received:', signature);
  }

  return isValid;
}

/**
 * Generate HTML content from template
 */
function generateEmailContent(template, data) {
  if (template === 'otp') {
    return {
      subject: 'Sehat Makaan - Email Verification OTP',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #006876; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
            .otp-box { background-color: #FF6B35; color: white; font-size: 32px; font-weight: bold; text-align: center; padding: 20px; border-radius: 8px; margin: 20px 0; letter-spacing: 8px; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Email Verification</h1>
            </div>
            <div class="content">
              <p>Hello ${data.name || 'User'},</p>
              <p>Thank you for registering with Sehat Makaan. Please use the following OTP to verify your email address:</p>
              <div class="otp-box">${data.otp}</div>
              <p><strong>This OTP is valid for 10 minutes.</strong></p>
              <p>If you didn't request this verification, please ignore this email.</p>
              <p>Best regards,<br>Sehat Makaan Team</p>
            </div>
            <div class="footer">
              <p>© 2026 Sehat Makaan. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `
    };
  }
  
  // Default to custom HTML content
  return {
    subject: data.subject || 'Sehat Makaan Notification',
    html: data.htmlContent || data.html || '<p>No content provided</p>'
  };
}

/**
 * Cloud Function: Send Email
 * Triggers when a new document is added to email_queue collection
 * Sends email and updates document with sent status
 * Optimized for fast delivery with min instances to avoid cold starts
 */
exports.sendQueuedEmail = functions
  .runWith({
    timeoutSeconds: 60,
    memory: '512MB',
    minInstances: 1, // Keep 1 instance warm to avoid cold starts
  })
  .firestore
  .document('email_queue/{emailId}')
  .onCreate(async (snap, context) => {
    const emailData = snap.data();
    const emailId = context.params.emailId;

    console.log('📧 Processing queued email:', emailId);
    console.log('To:', emailData.to);
    console.log('Template:', emailData.template || 'custom');

    try {
      // Check if email was already processed
      if (emailData.status === 'sent') {
        console.log('⚠️ Email already sent, skipping');
        return null;
      }

      // Generate email content from template
      const emailContent = generateEmailContent(emailData.template, emailData.data || emailData);
      
      // Override with root-level subject/html if provided (for direct HTML emails)
      const finalSubject = emailData.subject || emailContent.subject;
      const finalHtml = emailData.html || emailContent.html;
      
      console.log('Subject:', finalSubject);

      // If transporter not configured, just log and mark as demo sent
      if (!transporter) {
        console.log('='.repeat(80));
        console.log('📧 EMAIL NOTIFICATION (Demo Mode - No Credentials)');
        console.log('='.repeat(80));
        console.log(`To: ${emailData.to}`);
        console.log(`Subject: ${finalSubject}`);
        console.log('Content Preview:');
        console.log(finalHtml.replace(/<[^>]*>/g, '').substring(0, 300) + '...');
        console.log('='.repeat(80));

        // Update email_queue document
        await snap.ref.update({
          status: 'demo_sent',
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          error: 'Email credentials not configured (demo mode)'
        });

        return null;
      }

      // Prepare email options
      const mailOptions = {
        from: `"Sehat Makaan" <${gmailEmail}>`,
        to: emailData.to,
        subject: finalSubject,
        html: finalHtml,
        text: finalHtml.replace(/<[^>]*>/g, '').replace(/\s+/g, ' ').trim()
      };

      // Send email
      const result = await transporter.sendMail(mailOptions);

      console.log('✅ Email sent successfully!');
      console.log('Message ID:', result.messageId);
      console.log('Response:', result.response);

      // Update email_queue document with success status
      await snap.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: result.messageId,
        response: result.response
      });

      return { success: true, messageId: result.messageId };

    } catch (error) {
      console.error('='.repeat(80));
      console.error('❌ EMAIL SENDING FAILED');
      console.error('='.repeat(80));
      console.error('Error:', error.message);
      console.error('Code:', error.code);
      console.error('Stack:', error.stack);

      // Update email_queue document with error status
      await snap.ref.update({
        status: 'failed',
        error: error.message,
        errorCode: error.code || 'unknown',
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
        retryCount: admin.firestore.FieldValue.increment(1)
      });

      // Log to console for Firebase logs
      console.log('📧 FALLBACK: Email content that failed to send:');
      console.log(`To: ${emailData.to}`);
      console.log(`Subject: ${emailData.subject}`);
      console.log('='.repeat(80));

      return { success: false, error: error.message };
    }
  });

/**
 * Cloud Function: Retry Failed Emails
 * Can be called manually to retry failed emails
 * Usage: firebase functions:call retryFailedEmails
 */
exports.retryFailedEmails = functions.https.onCall(async (data, context) => {
  // Check if user is admin
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can retry failed emails');
  }

  try {
    const failedEmails = await admin.firestore()
      .collection('email_queue')
      .where('status', '==', 'failed')
      .where('retryCount', '<', 3)
      .get();

    console.log(`Found ${failedEmails.size} failed emails to retry`);

    const retryPromises = failedEmails.docs.map(async (doc) => {
      const emailData = doc.data();
      
      try {
        // Prepare email options
        const mailOptions = {
          from: `"Sehat Makaan" <${gmailEmail}>`,
          to: emailData.to,
          subject: emailData.subject,
          html: emailData.htmlContent,
          text: emailData.htmlContent.replace(/<[^>]*>/g, '').replace(/\s+/g, ' ').trim()
        };

        // Send email
        const result = await transporter.sendMail(mailOptions);

        // Update status
        await doc.ref.update({
          status: 'sent',
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          messageId: result.messageId,
          response: result.response
        });

        return { id: doc.id, success: true };
      } catch (error) {
        await doc.ref.update({
          retryCount: admin.firestore.FieldValue.increment(1),
          lastError: error.message
        });
        return { id: doc.id, success: false, error: error.message };
      }
    });

    const results = await Promise.all(retryPromises);
    const successful = results.filter(r => r.success).length;
    const failed = results.filter(r => !r.success).length;

    return {
      total: results.length,
      successful,
      failed,
      results
    };

  } catch (error) {
    console.error('Error retrying failed emails:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Cloud Function: Clean Old Email Queue
 * Runs daily to clean up old email_queue documents (older than 30 days)
 * Temporarily disabled due to Cloud Scheduler configuration issue
 */
/*
exports.cleanOldEmails = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    try {
      const oldEmails = await admin.firestore()
        .collection('email_queue')
        .where('createdAt', '<', thirtyDaysAgo)
        .get();

      console.log(`Found ${oldEmails.size} old emails to clean up`);

      const deletePromises = oldEmails.docs.map(doc => doc.ref.delete());
      await Promise.all(deletePromises);

      console.log(`✅ Cleaned up ${oldEmails.size} old email records`);
      return { deleted: oldEmails.size };

    } catch (error) {
      console.error('Error cleaning old emails:', error);
      return { error: error.message };
    }
  });
*/

/**
 * Cloud Function: Send Test Email
 * Callable function to test email configuration
 * Usage: Call from Flutter app or Firebase Console
 */
exports.sendTestEmail = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in to send test email');
  }

  const { to, subject, message } = data;

  if (!to || !subject || !message) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: to, subject, message');
  }

  try {
    // Queue the test email
    const emailDoc = await admin.firestore().collection('email_queue').add({
      to,
      subject,
      htmlContent: `
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2>Test Email from Sehat Makaan</h2>
          <p>${message}</p>
          <p style="color: #666; margin-top: 20px;">
            This is a test email sent from Firebase Cloud Functions.
          </p>
          <p style="color: #999; font-size: 12px; margin-top: 30px;">
            Sent at: ${new Date().toISOString()}
          </p>
        </div>
      `,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      retryCount: 0
    });

    console.log('✅ Test email queued:', emailDoc.id);

    return {
      success: true,
      message: 'Test email queued successfully',
      emailId: emailDoc.id
    };

  } catch (error) {
    console.error('Error sending test email:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Cloud Function: PayFast Payment Webhook
 * Handles payment notifications from PayFast
 * Verifies payment and updates Firestore
 */
exports.payfastWebhook = functions.https.onRequest(async (req, res) => {
  console.log('💰 PayFast Booking Payment webhook received');
  
  try {
    // Only accept POST requests
    if (req.method !== 'POST') {
      console.log('⚠️ Invalid method:', req.method);
      res.status(405).send('Method Not Allowed');
      return;
    }

    const paymentData = req.body;
    console.log('Payment data:', JSON.stringify(paymentData, null, 2));

    // ✅ FIX #2: Verify PayFast signature
    if (!verifyPayFastSignature(paymentData)) {
      console.error('❌ Invalid signature - potential fraud attempt');
      res.status(401).send('Invalid signature');
      return;
    }

    // Extract key payment details
    const {
      custom_str1: bookingId,
      custom_str2: paymentRecordId,
      payment_status: paymentStatus,
      amount_gross: amountGross,
      pf_payment_id: pfPaymentId,
      item_name: itemName,
    } = paymentData;

    // Validate required fields
    if (!bookingId || !paymentStatus || !paymentRecordId) {
      console.log('❌ Missing required fields');
      res.status(400).send('Missing required fields');
      return;
    }

    // Only process successful payments
    if (paymentStatus !== 'COMPLETE') {
      console.log(`⚠️ Payment not completed: ${paymentStatus}`);
      res.status(200).send('OK');
      return;
    }

    console.log(`💳 Processing booking payment: ${pfPaymentId}, Amount: ${amountGross}, Booking: ${bookingId}`);

    // Get payment record with duplicate check
    const paymentRef = admin.firestore().collection('booking_payments').doc(paymentRecordId);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      console.error('❌ Payment record not found:', paymentRecordId);
      res.status(404).send('Payment record not found');
      return;
    }

    const paymentInfo = paymentDoc.data();

    // ✅ FIX #4: Check if already processed (duplicate webhook)
    if (paymentInfo.status === 'paid') {
      console.log('⚠️ Duplicate payment webhook - already processed');
      res.status(200).send('OK');
      return;
    }

    // ✅ FIX #3: Validate amount matches
    const expectedAmount = paymentInfo.amount;
    const receivedAmount = parseFloat(amountGross);
    if (Math.abs(receivedAmount - expectedAmount) > 1) {
      console.error(`❌ Amount mismatch! Expected: ${expectedAmount}, Received: ${receivedAmount}`);
      res.status(400).send('Amount mismatch');
      return;
    }

    // ✅ FIX #1: Update booking document (not workshop_registrations)
    const bookingRef = admin.firestore().collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      console.error('❌ Booking not found:', bookingId);
      res.status(404).send('Booking not found');
      return;
    }

    // Use transaction for atomic updates
    await admin.firestore().runTransaction(async (transaction) => {
      // Double-check payment status hasn't changed (race condition protection)
      const paymentRefreshDoc = await transaction.get(paymentRef);
      if (paymentRefreshDoc.data().status === 'paid') {
        throw new Error('Payment already processed');
      }

      // Update payment record
      transaction.update(paymentRef, {
        status: 'paid',
        payfastPaymentId: pfPaymentId,
        payfastData: paymentData,
        amountReceived: receivedAmount,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update booking
      transaction.update(bookingRef, {
        paymentStatus: 'paid',
        paymentCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    console.log(`✅ Booking ${bookingId} confirmed and payment ${paymentRecordId} marked as paid`);

    // Send confirmation email
    const userId = paymentInfo.userId;
    if (userId) {
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      if (userDoc.exists) {
        const user = userDoc.data();
        await admin.firestore().collection('email_queue').add({
          to: user.email,
          subject: 'Booking Payment Confirmed - Sehat Makaan',
          htmlContent: `
            <div style="font-family: Arial, sans-serif; padding: 20px;">
              <h2 style="color: #14B8A6;">Payment Confirmed!</h2>
              <p>Your booking payment has been successfully processed.</p>
              <div style="background-color: #f0f9ff; padding: 15px; border-radius: 8px; margin: 20px 0;">
                <p style="margin: 5px 0;"><strong>Booking ID:</strong> ${bookingId}</p>
                <p style="margin: 5px 0;"><strong>Amount Paid:</strong> R ${amountGross}</p>
                <p style="margin: 5px 0;"><strong>Payment ID:</strong> ${pfPaymentId}</p>
                <p style="margin: 5px 0;"><strong>Status:</strong> Confirmed</p>
              </div>
              <p>Your appointment is now confirmed. You will receive further details shortly.</p>
            </div>
          `,
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          retryCount: 0,
        });
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Booking payment processed successfully',
      bookingId,
    });

  } catch (error) {
    console.error('❌ Error processing PayFast booking webhook:', error);
    
    // ✅ FIX #7: Proper error handling with appropriate status codes
    if (error.message.includes('not found')) {
      res.status(404).send('Resource not found');
    } else if (error.message.includes('Already processed')) {
      res.status(200).send('OK');
    } else {
      res.status(500).send('Internal Server Error');
    }
  }
});

/**
 * Cloud Function: PayFast Workshop Creation Fee Webhook
 * Handles payment notifications for workshop creation fees
 * Activates workshop after successful payment
 */
exports.payfastWorkshopCreationWebhook = functions.https.onRequest(async (req, res) => {
  console.log('💰 PayFast Workshop Creation Fee webhook received');
  
  try {
    // Only accept POST requests
    if (req.method !== 'POST') {
      console.log('⚠️ Invalid method:', req.method);
      res.status(405).send('Method Not Allowed');
      return;
    }

    const paymentData = req.body;
    console.log('Payment data:', JSON.stringify(paymentData, null, 2));

    // ✅ FIX #2: Verify PayFast signature
    if (!verifyPayFastSignature(paymentData)) {
      console.error('❌ Invalid signature - potential fraud attempt');
      res.status(401).send('Invalid signature');
      return;
    }

    // Extract key payment details
    const {
      custom_str1: workshopId,
      custom_str2: paymentRecordId,
      payment_status: paymentStatus,
      amount_gross: amountGross,
      pf_payment_id: pfPaymentId,
      item_name: itemName,
    } = paymentData;

    // Validate required fields
    if (!workshopId || !paymentStatus) {
      console.log('❌ Missing required fields');
      res.status(400).send('Missing required fields');
      return;
    }

    // Only process successful payments
    if (paymentStatus !== 'COMPLETE') {
      console.log(`⚠️ Payment not completed: ${paymentStatus}`);
      res.status(200).send('OK');
      return;
    }

    console.log(`Processing payment for workshop: ${workshopId}`);

    // Get workshop document
    const workshopRef = admin.firestore().collection('workshops').doc(workshopId);
    const workshopDoc = await workshopRef.get();

    if (!workshopDoc.exists) {
      console.error('❌ Workshop not found:', workshopId);
      res.status(404).send('Workshop not found');
      return;
    }

    const workshopData = workshopDoc.data();

    // ✅ FIX #4: Check if already processed
    if (workshopData.isCreationFeePaid === true) {
      console.log('⚠️ Duplicate payment webhook - already processed');
      res.status(200).send('OK');
      return;
    }

    // ✅ FIX #3: Validate amount (creation fee should be PKR 10,000)
    const expectedAmount = 10000;
    const receivedAmount = parseFloat(amountGross);
    if (Math.abs(receivedAmount - expectedAmount) > 1) {
      console.error(`❌ Amount mismatch! Expected: ${expectedAmount}, Received: ${receivedAmount}`);
      res.status(400).send('Amount mismatch');
      return;
    }

    // Update payment record if exists
    if (paymentRecordId) {
      try {
        await admin.firestore().collection('workshop_creation_payments').doc(paymentRecordId).update({
          status: 'paid',
          payfastPaymentId: pfPaymentId,
          payfastData: paymentData,
          amountReceived: receivedAmount,
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`✅ Payment record ${paymentRecordId} updated`);
      } catch (error) {
        console.warn('⚠️ Could not update payment record:', error.message);
      }
    }

    // Use transaction to ensure atomic update
    await admin.firestore().runTransaction(async (transaction) => {
      const workshopRefresh = await transaction.get(workshopRef);
      
      if (!workshopRefresh.exists) {
        throw new Error('Workshop not found');
      }

      // Double-check it hasn't been paid already (race condition protection)
      if (workshopRefresh.data().isCreationFeePaid === true) {
        throw new Error('Already processed');
      }

      // Mark as paid AND activate workshop
      transaction.update(workshopRef, {
        isCreationFeePaid: true,
        isActive: true,
        permissionStatus: 'live',
        activatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    console.log(`✅ Workshop ${workshopId} activated successfully`);

    // Get creator details for notification
    const creatorId = workshopData.createdBy;
    if (creatorId && transporter) {
      const creatorDoc = await admin.firestore()
        .collection('workshop_creators')
        .where('userId', '==', creatorId)
        .limit(1)
        .get();

      if (!creatorDoc.empty) {
        const creatorData = creatorDoc.docs[0].data();

        // Send in-app notification
        await admin.firestore().collection('notifications').add({
          userId: creatorId,
          type: 'workshop_live',
          title: '🎉 Workshop is Now LIVE!',
          message: `Your workshop "${workshopData.title}" is now active and visible to users. Start managing registrations!`,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Send email notification
        await admin.firestore().collection('email_queue').add({
          to: creatorData.email,
          subject: `🎉 Workshop Live - ${workshopData.title}`,
          htmlContent: `
            <!DOCTYPE html>
            <html>
            <head>
              <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background-color: #006876; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
                .content { background-color: #f9f9f9; padding: 30px; }
                .success-box { background-color: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 8px; margin: 20px 0; }
                .workshop-details { background-color: white; padding: 15px; border-radius: 8px; margin: 20px 0; }
                .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h1>🎉 Workshop is Now LIVE!</h1>
                </div>
                <div class="content">
                  <div class="success-box">
                    <h3 style="color: #155724; margin-top: 0;">Payment Successful!</h3>
                    <p style="margin: 5px 0;">Your creation fee payment has been processed successfully.</p>
                  </div>
                  
                  <h2>Workshop Details</h2>
                  <div class="workshop-details">
                    <p><strong>Title:</strong> ${workshopData.title}</p>
                    <p><strong>Status:</strong> <span style="color: #28a745;">● LIVE</span></p>
                    <p><strong>Payment ID:</strong> ${pfPaymentId}</p>
                    <p><strong>Amount Paid:</strong> PKR ${amountGross}</p>
                  </div>

                  <h3>What's Next?</h3>
                  <ul>
                    <li>✅ Your workshop is now visible to all users</li>
                    <li>✅ Users can register and make payments</li>
                    <li>✅ You can manage registrations from your dashboard</li>
                    <li>✅ Monitor workshop performance and revenue</li>
                  </ul>

                  <p style="margin-top: 30px;">
                    <a href="https://sehatmakaan.com/dashboard" style="background-color: #006876; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                      Go to Dashboard
                    </a>
                  </p>
                </div>
                <div class="footer">
                  <p><strong>Sehat Makaan Team</strong></p>
                  <p>This is an automated message. Please do not reply.</p>
                </div>
              </div>
            </body>
            </html>
          `,
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          retryCount: 0,
        });

        console.log('✅ Notifications sent to creator');
      }
    }

    // Send success response to PayFast
    res.status(200).send('OK');

  } catch (error) {
    console.error('❌ Error processing workshop creation fee webhook:', error);
    
    // ✅ FIX #7: Proper error handling
    if (error.message.includes('not found')) {
      res.status(404).send('Resource not found');
    } else if (error.message.includes('Already processed')) {
      res.status(200).send('OK');
    } else {
      res.status(500).send('Internal Server Error');
    }
  }
});

/**
 * Cloud Function: Generate PayFast Payment Link
 * Callable function to generate payment link for workshop registration
 */
exports.generatePayFastLink = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const {
    registrationId,
    workshopTitle,
    amount,
    userEmail,
    userName,
  } = data;

  // Validate required fields
  if (!registrationId || !workshopTitle || !amount || !userEmail || !userName) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  try {
    // ✅ PayFast configuration - Using environment variables
    const merchantId = payfastMerchantId;
    const merchantKey = payfastMerchantKey;
    const isTestMode = payfastTestMode;

    // Generate payment parameters
    const params = {
      merchant_id: merchantId,
      merchant_key: merchantKey,
      return_url: 'https://sehatmakaan.com/payment/success',
      cancel_url: 'https://sehatmakaan.com/payment/cancel',
      notify_url: `https://us-central1-${process.env.GCLOUD_PROJECT}.cloudfunctions.net/payfastWebhook`,
      m_payment_id: registrationId,
      amount: amount.toFixed(2),
      item_name: `Workshop: ${workshopTitle}`,
      item_description: `Registration for ${workshopTitle} workshop`,
      email_address: userEmail,
      name_first: userName.split(' ')[0],
      name_last: userName.split(' ').slice(1).join(' ') || '',
    };

    // Build payment URL
    const baseUrl = isTestMode
      ? 'https://sandbox.payfast.co.za/eng/process'
      : 'https://www.payfast.co.za/eng/process';

    const queryString = Object.entries(params)
      .map(([key, value]) => `${key}=${encodeURIComponent(value)}`)
      .join('&');

    const paymentUrl = `${baseUrl}?${queryString}`;

    console.log('✅ PayFast payment link generated');

    return {
      success: true,
      paymentUrl,
      testMode: isTestMode,
    };

  } catch (error) {
    console.error('❌ Error generating PayFast link:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Cloud Function: Workshop Registration Trigger
 * Sends confirmation email when user registers for workshop
 */
exports.onWorkshopRegistration = functions.firestore
  .document('workshop_registrations/{registrationId}')
  .onCreate(async (snap, context) => {
    const registration = snap.data();
    const registrationId = context.params.registrationId;

    console.log('🎯 New workshop registration:', registrationId);

    try {
      // Get workshop details
      const workshopDoc = await admin.firestore()
        .collection('workshops')
        .doc(registration.workshopId)
        .get();

      if (!workshopDoc.exists) {
        console.error('Workshop not found:', registration.workshopId);
        return null;
      }

      const workshop = workshopDoc.data();

      // Get user details
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(registration.userId)
        .get();

      if (!userDoc.exists) {
        console.error('User not found:', registration.userId);
        return null;
      }

      const user = userDoc.data();

      // Format date
      const workshopDate = workshop.date.toDate().toLocaleDateString('en-ZA', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      });

      // Queue registration confirmation email
      await admin.firestore().collection('email_queue').add({
        to: user.email,
        subject: `Workshop Registration Confirmed - ${workshop.title}`,
        htmlContent: `
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
              .container { max-width: 600px; margin: 20px auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
              .header { background: linear-gradient(135deg, #14B8A6 0%, #0D9488 100%); color: white; padding: 30px; text-align: center; }
              .header h1 { margin: 0; font-size: 28px; }
              .content { padding: 30px; }
              .workshop-details { background-color: #f0fdfa; border-left: 4px solid #14B8A6; padding: 20px; margin: 20px 0; border-radius: 5px; }
              .workshop-details h2 { color: #0D9488; margin-top: 0; }
              .detail-row { margin: 10px 0; color: #333; }
              .detail-label { font-weight: bold; color: #0D9488; }
              .button { display: inline-block; background-color: #14B8A6; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin-top: 20px; }
              .footer { background-color: #f8f8f8; padding: 20px; text-align: center; color: #666; font-size: 12px; }
              .status-badge { display: inline-block; background-color: #fef3c7; color: #92400e; padding: 5px 15px; border-radius: 20px; font-size: 14px; font-weight: bold; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🎉 Registration Confirmed!</h1>
              </div>
              <div class="content">
                <p>Dear <strong>${user.fullName}</strong>,</p>
                <p>Thank you for registering for our workshop! Your registration has been received and is currently being processed.</p>
                
                <div class="workshop-details">
                  <h2>${workshop.title}</h2>
                  <div class="detail-row">
                    <span class="detail-label">📅 Date:</span> ${workshopDate}
                  </div>
                  <div class="detail-row">
                    <span class="detail-label">⏰ Time:</span> ${workshop.time}
                  </div>
                  <div class="detail-row">
                    <span class="detail-label">📍 Location:</span> ${workshop.location}
                  </div>
                  <div class="detail-row">
                    <span class="detail-label">💰 Fee:</span> R ${workshop.fee.toFixed(2)}
                  </div>
                  <div class="detail-row">
                    <span class="detail-label">📋 Status:</span> <span class="status-badge">${registration.status.toUpperCase()}</span>
                  </div>
                </div>

                <p><strong>Next Steps:</strong></p>
                <ul>
                  <li>Your registration will be reviewed by our admin team</li>
                  <li>You will receive a payment link via email once approved</li>
                  <li>Complete the payment to confirm your spot</li>
                  <li>You'll receive final confirmation after payment</li>
                </ul>

                <p style="margin-top: 30px; color: #666;">
                  <strong>Registration ID:</strong> ${registrationId}
                </p>
              </div>
              <div class="footer">
                <p>Sehat Makaan - Your Health, Our Priority</p>
                <p>📧 support@sehatmakaan.com | 📞 +27 XXX XXX XXXX</p>
              </div>
            </div>
          </body>
          </html>
        `,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        retryCount: 0,
      });

      console.log('✅ Workshop registration email queued for:', user.email);
      return { success: true };

    } catch (error) {
      console.error('❌ Error sending workshop registration email:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Cloud Function: Workshop Confirmation Trigger
 * Sends payment link when admin confirms registration
 */
exports.onWorkshopConfirmation = functions.firestore
  .document('workshop_registrations/{registrationId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const registrationId = context.params.registrationId;

    // Check if status changed to confirmed
    if (before.status !== 'confirmed' && after.status === 'confirmed') {
      console.log('✅ Workshop registration confirmed:', registrationId);

      try {
        // Get workshop details
        const workshopDoc = await admin.firestore()
          .collection('workshops')
          .doc(after.workshopId)
          .get();

        if (!workshopDoc.exists) {
          console.error('Workshop not found:', after.workshopId);
          return null;
        }

        const workshop = workshopDoc.data();

        // Get user details
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(after.userId)
          .get();

        if (!userDoc.exists) {
          console.error('User not found:', after.userId);
          return null;
        }

        const user = userDoc.data();

        // Format date
        const workshopDate = workshop.date.toDate().toLocaleDateString('en-ZA', {
          weekday: 'long',
          year: 'numeric',
          month: 'long',
          day: 'numeric'
        });

        // Generate payment link (mock for now)
        const paymentLink = `https://sehatmakaan.com/payment/${registrationId}`;

        // Queue confirmation email with payment link
        await admin.firestore().collection('email_queue').add({
          to: user.email,
          subject: `Workshop Approved - Payment Required for ${workshop.title}`,
          htmlContent: `
            <!DOCTYPE html>
            <html>
            <head>
              <style>
                body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
                .container { max-width: 600px; margin: 20px auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                .header { background: linear-gradient(135deg, #14B8A6 0%, #0D9488 100%); color: white; padding: 30px; text-align: center; }
                .header h1 { margin: 0; font-size: 28px; }
                .content { padding: 30px; }
                .workshop-details { background-color: #f0fdfa; border-left: 4px solid #14B8A6; padding: 20px; margin: 20px 0; border-radius: 5px; }
                .workshop-details h2 { color: #0D9488; margin-top: 0; }
                .detail-row { margin: 10px 0; color: #333; }
                .detail-label { font-weight: bold; color: #0D9488; }
                .button { display: inline-block; background-color: #14B8A6; color: white; padding: 15px 40px; text-decoration: none; border-radius: 5px; margin-top: 20px; font-weight: bold; font-size: 16px; }
                .footer { background-color: #f8f8f8; padding: 20px; text-align: center; color: #666; font-size: 12px; }
                .highlight { background-color: #dcfce7; padding: 15px; border-radius: 5px; margin: 20px 0; }
                .amount { font-size: 32px; font-weight: bold; color: #14B8A6; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h1>🎊 Registration Approved!</h1>
                </div>
                <div class="content">
                  <p>Dear <strong>${user.fullName}</strong>,</p>
                  <p>Great news! Your workshop registration has been <strong>approved</strong> by our admin team.</p>
                  
                  <div class="workshop-details">
                    <h2>${workshop.title}</h2>
                    <div class="detail-row">
                      <span class="detail-label">📅 Date:</span> ${workshopDate}
                    </div>
                    <div class="detail-row">
                      <span class="detail-label">⏰ Time:</span> ${workshop.time}
                    </div>
                    <div class="detail-row">
                      <span class="detail-label">📍 Location:</span> ${workshop.location}
                    </div>
                  </div>

                  <div class="highlight">
                    <p style="margin: 0; text-align: center;">
                      <strong>Amount to Pay:</strong><br>
                      <span class="amount">R ${workshop.fee.toFixed(2)}</span>
                    </p>
                  </div>

                  <p style="text-align: center;">
                    <a href="${paymentLink}" class="button">💳 Proceed to Payment</a>
                  </p>

                  <p style="margin-top: 30px;"><strong>Important:</strong></p>
                  <ul>
                    <li>Click the button above to complete your payment</li>
                    <li>Your spot is reserved for 48 hours</li>
                    <li>Payment must be completed to confirm attendance</li>
                    <li>You'll receive final confirmation after payment</li>
                  </ul>

                  <p style="margin-top: 30px; color: #666; font-size: 12px;">
                    <strong>Registration ID:</strong> ${registrationId}
                  </p>
                </div>
                <div class="footer">
                  <p>Sehat Makaan - Your Health, Our Priority</p>
                  <p>📧 support@sehatmakaan.com</p>
                </div>
              </div>
            </body>
            </html>
          `,
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          retryCount: 0,
        });

        console.log('✅ Workshop confirmation email queued for:', user.email);
        return { success: true };

      } catch (error) {
        console.error('❌ Error sending workshop confirmation email:', error);
        return { success: false, error: error.message };
      }
    }

    // Check if status changed to rejected
    if (before.status !== 'rejected' && after.status === 'rejected') {
      console.log('⚠️ Workshop registration rejected:', registrationId);

      try {
        // Get workshop details
        const workshopDoc = await admin.firestore()
          .collection('workshops')
          .doc(after.workshopId)
          .get();

        const workshop = workshopDoc.exists ? workshopDoc.data() : null;

        // Get user details
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(after.userId)
          .get();

        if (!userDoc.exists) {
          console.error('User not found:', after.userId);
          return null;
        }

        const user = userDoc.data();

        // Queue rejection email
        await admin.firestore().collection('email_queue').add({
          to: user.email,
          subject: `Workshop Registration Update - ${workshop ? workshop.title : 'Workshop'}`,
          htmlContent: `
            <!DOCTYPE html>
            <html>
            <head>
              <style>
                body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
                .container { max-width: 600px; margin: 20px auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                .header { background: linear-gradient(135deg, #F59E0B 0%, #D97706 100%); color: white; padding: 30px; text-align: center; }
                .header h1 { margin: 0; font-size: 28px; }
                .content { padding: 30px; }
                .info-box { background-color: #fef3c7; border-left: 4px solid #F59E0B; padding: 20px; margin: 20px 0; border-radius: 5px; }
                .footer { background-color: #f8f8f8; padding: 20px; text-align: center; color: #666; font-size: 12px; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h1>Workshop Registration Update</h1>
                </div>
                <div class="content">
                  <p>Dear <strong>${user.fullName}</strong>,</p>
                  <p>Thank you for your interest in ${workshop ? workshop.title : 'our workshop'}.</p>
                  
                  <div class="info-box">
                    <p><strong>Unfortunately, we are unable to approve your registration at this time.</strong></p>
                    ${after.rejectionReason ? `<p><strong>Reason:</strong> ${after.rejectionReason}</p>` : ''}
                  </div>

                  <p>We encourage you to:</p>
                  <ul>
                    <li>Check our upcoming workshops for other opportunities</li>
                    <li>Contact us if you have any questions</li>
                    <li>Register for future workshops that match your interests</li>
                  </ul>

                  <p style="text-align: center; margin-top: 30px;">
                    <a href="https://sehatmakaan.com/workshops" style="display: inline-block; background-color: #14B8A6; color: white; padding: 15px 40px; text-decoration: none; border-radius: 5px; font-weight: bold; font-size: 16px;">
                      🔍 Browse Other Workshops
                    </a>
                  </p>

                  <p style="margin-top: 30px;">Thank you for your understanding.</p>
                </div>
                <div class="footer">
                  <p>Sehat Makaan - Your Health, Our Priority</p>
                  <p>📧 support@sehatmakaan.com</p>
                </div>
              </div>
            </body>
            </html>
          `,
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          retryCount: 0,
        });

        console.log('✅ Workshop rejection email queued for:', user.email);
        return { success: true };

      } catch (error) {
        console.error('❌ Error sending workshop rejection email:', error);
        return { success: false, error: error.message };
      }
    }

    return null;
  });

/**
 * Cloud Function: User Approval Trigger
 * Sends email when admin approves or rejects user registration
 */
exports.onUserApproval = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;

    // Check if status changed to approved
    if (before.status !== 'approved' && after.status === 'approved') {
      console.log('✅ User approved:', userId);

      try {
        // Queue approval email with credentials
        await admin.firestore().collection('email_queue').add({
          to: after.email,
          subject: 'Your Sehat Makaan Account Has Been Approved! 🎉',
          htmlContent: `
            <!DOCTYPE html>
            <html>
            <head>
              <style>
                body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
                .container { max-width: 600px; margin: 20px auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                .header { background: linear-gradient(135deg, #10B981 0%, #059669 100%); color: white; padding: 30px; text-align: center; }
                .header h1 { margin: 0; font-size: 28px; }
                .content { padding: 30px; }
                .credentials-box { background-color: #f0fdf4; border: 2px solid #10B981; padding: 20px; margin: 20px 0; border-radius: 8px; }
                .credential-row { margin: 15px 0; }
                .credential-label { font-weight: bold; color: #059669; }
                .credential-value { background-color: white; padding: 10px; border-radius: 5px; margin-top: 5px; font-family: monospace; font-size: 16px; }
                .footer { background-color: #f8f8f8; padding: 20px; text-align: center; color: #666; font-size: 12px; }
                .warning { background-color: #fef3c7; padding: 15px; border-left: 4px solid #F59E0B; margin: 20px 0; border-radius: 5px; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h1>🎉 Welcome to Sehat Makaan!</h1>
                </div>
                <div class="content">
                  <p>Dear Dr. <strong>${after.fullName}</strong>,</p>
                  <p>Congratulations! Your account has been <strong>approved</strong> and is now active.</p>
                  
                  <div class="credentials-box">
                    <h3 style="margin-top: 0; color: #059669;">Your Login Credentials</h3>
                    <div class="credential-row">
                      <div class="credential-label">📧 Email:</div>
                      <div class="credential-value">${after.email}</div>
                    </div>
                    <div class="credential-row">
                      <div class="credential-label">👤 Username:</div>
                      <div class="credential-value">${after.username}</div>
                    </div>
                  </div>

                  <div class="warning">
                    <strong>⚠️ Important:</strong> Please use the password you set during registration to log in. If you forgot your password, use the "Forgot Password" option on the login page.
                  </div>

                  <p><strong>What you can do now:</strong></p>
                  <ul>
                    <li>📅 Book hourly consultations</li>
                    <li>💳 Subscribe to monthly packages</li>
                    <li>🎓 Register for workshops</li>
                    <li>📊 View your booking history</li>
                    <li>⚙️ Manage your profile</li>
                  </ul>

                  <p style="margin-top: 30px;">
                    Download our app and start booking your consultations today!
                  </p>
                </div>
                <div class="footer">
                  <p>Sehat Makaan - Admin Panel</p>
                  <p>📧 support@sehatmakaan.com</p>
                </div>
              </div>
            </body>
            </html>
          `,
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          retryCount: 0,
        });

        console.log('✅ User approval email queued for:', after.email);
        return { success: true };

      } catch (error) {
        console.error('❌ Error sending user approval email:', error);
        return { success: false, error: error.message };
      }
    }

    // Check if status changed to rejected
    if (before.status !== 'rejected' && after.status === 'rejected') {
      console.log('⚠️ User rejected:', userId);

      try {
        // Queue rejection email
        await admin.firestore().collection('email_queue').add({
          to: after.email,
          subject: 'Sehat Makaan Registration Update',
          htmlContent: `
            <!DOCTYPE html>
            <html>
            <head>
              <style>
                body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
                .container { max-width: 600px; margin: 20px auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                .header { background: linear-gradient(135deg, #EF4444 0%, #DC2626 100%); color: white; padding: 30px; text-align: center; }
                .header h1 { margin: 0; font-size: 28px; }
                .content { padding: 30px; }
                .info-box { background-color: #fee2e2; border-left: 4px solid #EF4444; padding: 20px; margin: 20px 0; border-radius: 5px; }
                .footer { background-color: #f8f8f8; padding: 20px; text-align: center; color: #666; font-size: 12px; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h1>Registration Update</h1>
                </div>
                <div class="content">
                  <p>Dear ${after.fullName},</p>
                  <p>Thank you for your interest in Sehat Makaan.</p>
                  
                  <div class="info-box">
                    <p><strong>Unfortunately, we are unable to approve your registration at this time.</strong></p>
                    ${after.rejectionReason ? `<p><strong>Reason:</strong> ${after.rejectionReason}</p>` : ''}
                  </div>

                  <p>If you believe this is an error or would like more information, please contact our support team.</p>

                  <p style="margin-top: 30px;">Thank you for your understanding.</p>
                </div>
                <div class="footer">
                  <p>Sehat Makaan - Admin Team</p>
                  <p>📧 support@sehatmakaan.com</p>
                </div>
              </div>
            </body>
            </html>
          `,
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          retryCount: 0,
        });

        console.log('✅ User rejection email queued for:', after.email);
        return { success: true };

      } catch (error) {
        console.error('❌ Error sending user rejection email:', error);
        return { success: false, error: error.message };
      }
    }

    return null;
  });

/**
 * Cloud Function: Booking Confirmation Trigger
 * Sends email when new booking is created
 */
exports.onBookingCreated = functions.firestore
  .document('bookings/{bookingId}')
  .onCreate(async (snap, context) => {
    const booking = snap.data();
    const bookingId = context.params.bookingId;

    console.log('📅 New booking created:', bookingId);

    try {
      // Get user details
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(booking.userId)
        .get();

      if (!userDoc.exists) {
        console.error('User not found:', booking.userId);
        return null;
      }

      const user = userDoc.data();

      // Format date and time
      const bookingDate = booking.date.toDate().toLocaleDateString('en-ZA', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      });

      // Format add-ons
      let addonsHtml = '';
      if (booking.selectedAddons && booking.selectedAddons.length > 0) {
        addonsHtml = `
          <div style="margin-top: 20px;">
            <strong>Selected Add-ons:</strong>
            <ul>
              ${booking.selectedAddons.map(addon => `<li>${addon}</li>`).join('')}
            </ul>
          </div>
        `;
      }

      // Queue booking confirmation email
      await admin.firestore().collection('email_queue').add({
        to: user.email,
        subject: `Booking Confirmed - ${bookingDate} at ${booking.time}`,
        htmlContent: `
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
              .container { max-width: 600px; margin: 20px auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
              .header { background: linear-gradient(135deg, #14B8A6 0%, #0D9488 100%); color: white; padding: 30px; text-align: center; }
              .header h1 { margin: 0; font-size: 28px; }
              .content { padding: 30px; }
              .booking-details { background-color: #f0fdfa; border-left: 4px solid #14B8A6; padding: 20px; margin: 20px 0; border-radius: 5px; }
              .detail-row { margin: 10px 0; color: #333; }
              .detail-label { font-weight: bold; color: #0D9488; }
              .footer { background-color: #f8f8f8; padding: 20px; text-align: center; color: #666; font-size: 12px; }
              .qr-section { text-align: center; margin: 30px 0; padding: 20px; background-color: #f9f9f9; border-radius: 8px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>✅ Booking Confirmed!</h1>
              </div>
              <div class="content">
                <p>Dear <strong>${user.fullName}</strong>,</p>
                <p>Your consultation booking has been confirmed. Here are your booking details:</p>
                
                <div class="booking-details">
                  <h2 style="color: #0D9488; margin-top: 0;">Booking Details</h2>
                  <div class="detail-row">
                    <span class="detail-label">📅 Date:</span> ${bookingDate}
                  </div>
                  <div class="detail-row">
                    <span class="detail-label">⏰ Time:</span> ${booking.time}
                  </div>
                  <div class="detail-row">
                    <span class="detail-label">💰 Total Cost:</span> R ${booking.totalCost.toFixed(2)}
                  </div>
                  <div class="detail-row">
                    <span class="detail-label">📋 Status:</span> ${booking.status.toUpperCase()}
                  </div>
                  ${addonsHtml}
                </div>

                <div class="qr-section">
                  <p><strong>Show this QR code at your appointment:</strong></p>
                  <p style="font-family: monospace; background-color: white; padding: 15px; border: 2px dashed #14B8A6; display: inline-block; border-radius: 5px;">
                    🔲 QR Code: ${bookingId}
                  </p>
                  <p style="font-size: 12px; color: #666; margin-top: 10px;">
                    (QR code will be generated in the app)
                  </p>
                </div>

                <p><strong>Important Notes:</strong></p>
                <ul>
                  <li>Please arrive 10 minutes before your scheduled time</li>
                  <li>Bring any relevant medical documents</li>
                  <li>You can cancel up to 24 hours before your appointment</li>
                </ul>

                <p style="margin-top: 30px; color: #666; font-size: 12px;">
                  <strong>Booking ID:</strong> ${bookingId}
                </p>
              </div>
              <div class="footer">
                <p>Sehat Makaan - Your Health, Our Priority</p>
                <p>📧 support@sehatmakaan.com</p>
              </div>
            </div>
          </body>
          </html>
        `,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        retryCount: 0,
      });

      console.log('✅ Booking confirmation email queued for:', user.email);
      
      // Send FCM Push Notification
      const fcmToken = user.fcmToken;
      if (fcmToken) {
        try {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: '✅ Booking Confirmed',
              body: `Your booking for ${bookingDate} at ${booking.timeSlot || booking.time} has been confirmed!`,
            },
            data: {
              type: 'booking_confirmed',
              bookingId: bookingId,
              date: bookingDate,
              time: booking.timeSlot || booking.time,
            },
            android: {
              priority: 'high',
              notification: {
                sound: 'default',
                channelId: 'bookings',
              },
            },
          });
          console.log('✅ FCM notification sent to user:', user.email);
        } catch (fcmError) {
          console.error('❌ Failed to send FCM notification:', fcmError);
        }
      } else {
        console.log('⚠️ No FCM token found for user:', user.email);
      }
      
      return { success: true };

    } catch (error) {
      console.error('❌ Error sending booking confirmation email:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Cloud Function: Notification Email Trigger
 * Sends email for high-priority notifications
 */
exports.onHighPriorityNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const notificationId = context.params.notificationId;

    // Only send email for high-priority notifications
    if (notification.priority !== 'high') {
      console.log('⏭️ Skipping email for non-high priority notification');
      return null;
    }

    console.log('🔔 High priority notification:', notificationId);

    try {
      // Get user details
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(notification.userId)
        .get();

      if (!userDoc.exists) {
        console.error('User not found:', notification.userId);
        return null;
      }

      const user = userDoc.data();

      // Queue notification email
      await admin.firestore().collection('email_queue').add({
        to: user.email,
        subject: `Important: ${notification.title}`,
        htmlContent: `
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
              .container { max-width: 600px; margin: 20px auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
              .header { background: linear-gradient(135deg, #F59E0B 0%, #D97706 100%); color: white; padding: 30px; text-align: center; }
              .header h1 { margin: 0; font-size: 28px; }
              .content { padding: 30px; }
              .notification-box { background-color: #fef3c7; border-left: 4px solid #F59E0B; padding: 20px; margin: 20px 0; border-radius: 5px; }
              .footer { background-color: #f8f8f8; padding: 20px; text-align: center; color: #666; font-size: 12px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🔔 Important Notification</h1>
              </div>
              <div class="content">
                <p>Dear <strong>${user.fullName}</strong>,</p>
                
                <div class="notification-box">
                  <h2 style="color: #D97706; margin-top: 0;">${notification.title}</h2>
                  <p style="color: #333; line-height: 1.6;">${notification.body}</p>
                </div>

                <p style="margin-top: 30px;">
                  Please check your Sehat Makaan app for more details.
                </p>
              </div>
              <div class="footer">
                <p>Sehat Makaan - Your Health, Our Priority</p>
                <p>📧 support@sehatmakaan.com</p>
              </div>
            </div>
          </body>
          </html>
        `,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        retryCount: 0,
      });

      console.log('✅ Notification email queued for:', user.email);
      return { success: true };

    } catch (error) {
      console.error('❌ Error sending notification email:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Cloud Function: Workshop Creator Request Notification
 * Triggers when a user requests to become a workshop creator
 * Sends in-app notifications, push notifications, and emails to all active admins with comprehensive workshop details
 */
exports.onWorkshopCreatorRequest = functions.firestore
  .document('workshop_creator_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const request = snap.data();
    const requestId = context.params.requestId;

    console.log('📝 New workshop creator request:', requestId);
    console.log('User:', request.fullName);
    console.log('Workshop Type:', request.workshopType);
    console.log('Topic:', request.workshopTopic);

    try {
      // Get all active admins
      const adminsSnapshot = await admin.firestore()
        .collection('users')
        .where('userType', '==', 'admin')
        .where('isActive', '==', true)
        .get();

      if (adminsSnapshot.empty) {
        console.log('⚠️ No active admins found');
        return null;
      }

      // Send notification, push notification, and email to each admin
      for (const adminDoc of adminsSnapshot.docs) {
        const admin_data = adminDoc.data();
        const adminId = adminDoc.id;
        
        // Create in-app notification
        await admin.firestore().collection('notifications').add({
          userId: adminId,
          type: 'creator_request',
          title: '🎓 New Workshop Creator Request',
          message: `${request.fullName} (${request.specialty || 'Doctor'}) has requested to create workshops. Topic: ${request.workshopTopic || 'Not specified'}`,
          priority: 'high',
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          relatedRequestId: requestId,
          metadata: {
            requestId: requestId,
            userId: request.userId,
            userEmail: request.email,
            workshopType: request.workshopType,
            workshopTopic: request.workshopTopic
          }
        });

        // Send FCM push notification if admin has FCM token
        if (admin_data.fcmToken) {
          try {
            await admin.messaging().send({
              notification: {
                title: '🎓 New Workshop Creator Request',
                body: `${request.fullName} wants to create: ${request.workshopTopic || 'workshop'}`,
              },
              data: {
                type: 'creator_request',
                requestId: requestId,
                userId: request.userId,
                workshopType: request.workshopType || '',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
              },
              token: admin_data.fcmToken,
            });
            console.log(`✅ Push notification sent to admin ${adminId}`);
          } catch (pushError) {
            console.error(`❌ Error sending push to admin ${adminId}:`, pushError.message);
            if (pushError.code === 'messaging/invalid-registration-token' ||
                pushError.code === 'messaging/registration-token-not-registered') {
              await admin.firestore().collection('users').doc(adminId).update({
                fcmToken: admin.firestore.FieldValue.delete(),
              });
            }
          }
        }

        // Queue comprehensive email
        if (admin_data.email) {
          await admin.firestore().collection('email_queue').add({
            to: admin_data.email,
            subject: '🔔 New Workshop Creator Request - Action Required',
            htmlContent: `
              <!DOCTYPE html>
              <html>
              <head>
                <style>
                  body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
                  .container { max-width: 600px; margin: 20px auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                  .header { background: linear-gradient(135deg, #006876 0%, #004D5A 100%); color: white; padding: 30px; text-align: center; }
                  .header h1 { margin: 0; font-size: 28px; }
                  .content { padding: 30px; }
                  .request-box { background-color: #E6F7F9; border-left: 4px solid #006876; padding: 20px; margin: 20px 0; border-radius: 5px; }
                  .user-details { background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 15px 0; }
                  .workshop-details { background-color: #fff8e1; border-left: 4px solid #FF6B35; padding: 15px; border-radius: 5px; margin: 15px 0; }
                  .detail-row { margin: 8px 0; color: #333; }
                  .detail-label { font-weight: bold; color: #006876; display: inline-block; min-width: 150px; }
                  .action-button { display: inline-block; padding: 12px 30px; background: linear-gradient(135deg, #006876 0%, #004D5A 100%); color: white; text-decoration: none; border-radius: 5px; margin: 10px 5px; font-weight: bold; }
                  .footer { background-color: #f8f8f8; padding: 20px; text-align: center; color: #666; font-size: 12px; }
                  .section-title { color: #006876; margin-top: 0; margin-bottom: 15px; border-bottom: 2px solid #006876; padding-bottom: 10px; }
                </style>
              </head>
              <body>
                <div class="container">
                  <div class="header">
                    <h1>🎓 New Workshop Creator Request</h1>
                  </div>
                  <div class="content">
                    <p>Dear Admin,</p>
                    
                    <div class="request-box">
                      <h2 style="color: #006876; margin-top: 0;">⚠️ Action Required</h2>
                      <p style="margin: 0;">A doctor has submitted a detailed workshop creator request with complete information.</p>
                    </div>

                    <div class="user-details">
                      <h3 class="section-title">👨‍⚕️ Requester Information</h3>
                      <div class="detail-row">
                        <span class="detail-label">Name:</span>
                        <span>${request.fullName}</span>
                      </div>
                      <div class="detail-row">
                        <span class="detail-label">Email:</span>
                        <span>${request.email}</span>
                      </div>
                      ${request.specialty ? `
                      <div class="detail-row">
                        <span class="detail-label">Specialty:</span>
                        <span>${request.specialty}</span>
                      </div>
                      ` : ''}
                    </div>

                    <div class="workshop-details">
                      <h3 class="section-title">📚 Workshop Details</h3>
                      <div class="detail-row">
                        <span class="detail-label">Workshop Type:</span>
                        <span><strong>${request.workshopType || 'Not specified'}</strong></span>
                      </div>
                      <div class="detail-row">
                        <span class="detail-label">Workshop Topic:</span>
                        <span><strong>${request.workshopTopic || 'Not specified'}</strong></span>
                      </div>
                      <div class="detail-row">
                        <span class="detail-label">Expected Duration:</span>
                        <span>${request.expectedDuration || 'Not specified'}</span>
                      </div>
                      <div class="detail-row">
                        <span class="detail-label">Expected Participants:</span>
                        <span>${request.expectedParticipants || 'Not specified'} attendees</span>
                      </div>
                      ${request.workshopDescription ? `
                      <div class="detail-row" style="margin-top: 15px;">
                        <span class="detail-label">Description:</span>
                        <div style="margin-top: 8px; padding: 12px; background: white; border-radius: 3px; line-height: 1.6;">
                          ${request.workshopDescription}
                        </div>
                      </div>
                      ` : ''}
                      ${request.teachingExperience ? `
                      <div class="detail-row" style="margin-top: 15px;">
                        <span class="detail-label">Teaching Experience:</span>
                        <div style="margin-top: 8px; padding: 12px; background: white; border-radius: 3px; line-height: 1.6;">
                          ${request.teachingExperience}
                        </div>
                      </div>
                      ` : ''}
                    </div>

                    <p style="margin-top: 30px; text-align: center; font-size: 16px;">
                      <strong>Please review this comprehensive request in your admin dashboard.</strong>
                    </p>

                    <div style="text-align: center; margin-top: 20px;">
                      <a href="https://sehatmakaan.com/admin" class="action-button">
                        📋 Review in Admin Dashboard
                      </a>
                    </div>
                  </div>
                  <div class="footer">
                    <p><strong>Sehat Makaan Admin Portal</strong></p>
                    <p>This is an automated notification. Please do not reply to this email.</p>
                  </div>
                </div>
              </body>
              </html>
            `,
            status: 'pending',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            retryCount: 0,
          });
        }
      }
      
      console.log(`✅ Notified ${adminsSnapshot.size} admin(s) about workshop creator request`);
      console.log(`   - In-app notifications: ${adminsSnapshot.size}`);
      console.log(`   - Push notifications sent`);
      console.log(`   - Emails queued`);
      
      return { success: true, adminsNotified: adminsSnapshot.size };

    } catch (error) {
      console.error('❌ Error processing workshop creator request:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Cloud Function: Workshop Creator Approval Notification
 * Triggers when admin approves a workshop creator request
 * Sends congratulations email to the user
 */
exports.onWorkshopCreatorApproval = functions.firestore
  .document('workshop_creator_requests/{requestId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const requestId = context.params.requestId;

    // Only trigger if status changed from pending to approved
    if (beforeData.status !== 'pending' || afterData.status !== 'approved') {
      return null;
    }

    console.log('✅ Workshop creator request approved:', requestId);
    console.log('User:', afterData.fullName);

    try {
      // Get user details
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(afterData.userId)
        .get();

      if (!userDoc.exists) {
        console.error('User not found:', afterData.userId);
        return null;
      }

      const user = userDoc.data();

      // Create notification
      await admin.firestore().collection('notifications').add({
        userId: afterData.userId,
        type: 'creator_approved',
        title: '🎉 Workshop Creator Access Granted!',
        body: 'Congratulations! You can now create workshops. Go to your dashboard to get started.',
        priority: 'medium',
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          requestId: requestId
        }
      });

      // Queue congratulations email
      await admin.firestore().collection('email_queue').add({
        to: user.email,
        subject: '🎉 Congratulations! Workshop Creator Access Granted',
        htmlContent: `
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
              .container { max-width: 600px; margin: 20px auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
              .header { background: linear-gradient(135deg, #90D26D 0%, #7BC74D 100%); color: white; padding: 40px; text-align: center; }
              .header h1 { margin: 0; font-size: 32px; }
              .celebration { font-size: 50px; margin-bottom: 10px; }
              .content { padding: 30px; }
              .success-box { background-color: #E8F5E9; border-left: 4px solid #90D26D; padding: 20px; margin: 20px 0; border-radius: 5px; }
              .features { background-color: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0; }
              .feature-item { margin: 12px 0; padding-left: 25px; position: relative; }
              .feature-item:before { content: "✓"; position: absolute; left: 0; color: #90D26D; font-weight: bold; font-size: 18px; }
              .action-button { display: inline-block; padding: 15px 40px; background: linear-gradient(135deg, #006876 0%, #004D5A 100%); color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; font-weight: bold; font-size: 16px; }
              .footer { background-color: #f8f8f8; padding: 20px; text-align: center; color: #666; font-size: 12px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <div class="celebration">🎉🎓✨</div>
                <h1>Congratulations!</h1>
                <p style="margin: 10px 0 0 0; font-size: 18px;">You're Now a Workshop Creator</p>
              </div>
              <div class="content">
                <p>Dear <strong>${afterData.fullName}</strong>,</p>
                
                <div class="success-box">
                  <h2 style="color: #7BC74D; margin-top: 0;">Great News!</h2>
                  <p style="color: #333; line-height: 1.6; margin: 0;">
                    Your request to become a workshop creator has been <strong>approved</strong>! 
                    You can now create and manage professional workshops on the Sehat Makaan platform.
                  </p>
                </div>

                <div class="features">
                  <h3 style="color: #006876; margin-top: 0;">What You Can Do Now:</h3>
                  <div class="feature-item">Create unlimited workshops</div>
                  <div class="feature-item">Set your own workshop details and pricing</div>
                  <div class="feature-item">Manage participant registrations</div>
                  <div class="feature-item">Share medical education with professionals</div>
                  <div class="feature-item">Build your professional network</div>
                </div>

                <p style="margin-top: 30px;">
                  <strong>Ready to get started?</strong> Head to your dashboard and click on 
                  <strong style="color: #006876;">"Create Workshop"</strong> to create your first workshop!
                </p>

                <div style="text-align: center;">
                  <a href="https://sehatmakaan.com/dashboard" class="action-button">
                    Go to Dashboard
                  </a>
                </div>

                <p style="margin-top: 30px; color: #666; font-size: 14px;">
                  Need help? Check out our workshop creation guide or contact our support team.
                </p>
              </div>
              <div class="footer">
                <p>Sehat Makaan - Empowering Medical Education</p>
                <p>📧 support@sehatmakaan.com</p>
              </div>
            </div>
          </body>
          </html>
        `,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        retryCount: 0,
      });

      console.log('✅ Approval notification and email sent to:', user.email);
      return { success: true };

    } catch (error) {
      console.error('❌ Error sending approval notification:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Cloud Function: Workshop Creator Rejection Notification
 * Triggers when admin rejects a workshop creator request
 * Sends notification to the user with reason
 */
exports.onWorkshopCreatorRejection = functions.firestore
  .document('workshop_creator_requests/{requestId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const requestId = context.params.requestId;

    // Only trigger if status changed from pending to rejected
    if (beforeData.status !== 'pending' || afterData.status !== 'rejected') {
      return null;
    }

    console.log('❌ Workshop creator request rejected:', requestId);
    console.log('User:', afterData.fullName);

    try {
      // Get user details
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(afterData.userId)
        .get();

      if (!userDoc.exists) {
        console.error('User not found:', afterData.userId);
        return null;
      }

      const user = userDoc.data();

      // Create notification
      await admin.firestore().collection('notifications').add({
        userId: afterData.userId,
        type: 'creator_rejected',
        title: 'Workshop Creator Request Update',
        body: afterData.rejectionReason 
          ? `Your workshop creator request was declined. Reason: ${afterData.rejectionReason}`
          : 'Your workshop creator request was declined. Please contact admin for more information.',
        priority: 'low',
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          requestId: requestId,
          rejectionReason: afterData.rejectionReason || null
        }
      });

      // Queue email
      await admin.firestore().collection('email_queue').add({
        to: user.email,
        subject: 'Workshop Creator Request Update',
        htmlContent: `
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
              .container { max-width: 600px; margin: 20px auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
              .header { background: linear-gradient(135deg, #FF6B35 0%, #D95A2E 100%); color: white; padding: 30px; text-align: center; }
              .header h1 { margin: 0; font-size: 28px; }
              .content { padding: 30px; }
              .info-box { background-color: #FFF3E0; border-left: 4px solid #FF6B35; padding: 20px; margin: 20px 0; border-radius: 5px; }
              ${afterData.rejectionReason ? `
              .reason-box { background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 15px 0; }
              ` : ''}
              .footer { background-color: #f8f8f8; padding: 20px; text-align: center; color: #666; font-size: 12px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>Workshop Creator Request Update</h1>
              </div>
              <div class="content">
                <p>Dear <strong>${afterData.fullName}</strong>,</p>
                
                <div class="info-box">
                  <p style="color: #333; line-height: 1.6; margin: 0;">
                    Thank you for your interest in becoming a workshop creator. After careful review, 
                    we are unable to approve your request at this time.
                  </p>
                </div>

                ${afterData.rejectionReason ? `
                <div class="reason-box">
                  <h3 style="color: #FF6B35; margin-top: 0;">Admin Feedback:</h3>
                  <p style="color: #333; line-height: 1.6; font-style: italic;">
                    "${afterData.rejectionReason}"
                  </p>
                </div>
                ` : ''}

                <p style="margin-top: 30px;">
                  You can reapply in the future, or contact our admin team if you have any questions 
                  about this decision.
                </p>

                <p style="margin-top: 20px; color: #666;">
                  <strong>Contact Admin:</strong><br>
                  📧 admin@sehatmakaan.com
                </p>
              </div>
              <div class="footer">
                <p>Sehat Makaan - Your Health, Our Priority</p>
                <p>📧 support@sehatmakaan.com</p>
              </div>
            </div>
          </body>
          </html>
        `,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        retryCount: 0,
      });

      console.log('✅ Rejection notification and email sent to:', user.email);
      return { success: true };

    } catch (error) {
      console.error('❌ Error sending rejection notification:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Cloud Function: On User Registration
 * Triggers when a new user document is created with status='pending'
 * Notifies all active admins about new registration
 */
exports.onUserRegistration = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const userData = snap.data();
    const userId = context.params.userId;

    console.log('👤 New user registration:', userId);
    console.log('User email:', userData.email);
    console.log('Status:', userData.status);

    // Only process if status is pending (new registration awaiting approval)
    if (userData.status !== 'pending') {
      console.log('⚠️ User status is not pending, skipping notification');
      return null;
    }

    try {
      // Get all active admins
      const adminsSnapshot = await admin.firestore()
        .collection('users')
        .where('userType', '==', 'admin')
        .where('isActive', '==', true)
        .get();

      if (adminsSnapshot.empty) {
        console.log('⚠️ No active admins found');
        return null;
      }

      console.log(`📬 Notifying ${adminsSnapshot.size} admin(s)`);

      // Create notification and email for each admin
      const promises = [];
      adminsSnapshot.forEach(adminDoc => {
        const adminData = adminDoc.data();

        // Create notification
        const notificationPromise = admin.firestore().collection('notifications').add({
          userId: adminDoc.id,
          type: 'new_registration',
          title: 'New Doctor Registration',
          message: `${userData.fullName} (${userData.specialty}) has registered and awaits approval.`,
          priority: 'high',
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          metadata: {
            doctorId: userId,
            doctorName: userData.fullName,
            doctorEmail: userData.email,
            specialty: userData.specialty,
            pmdcNumber: userData.pmdcNumber,
          },
        });

        // Queue email
        const emailPromise = admin.firestore().collection('email_queue').add({
          to: adminData.email,
          subject: '🆕 New Doctor Registration - Sehat Makaan',
          html: `
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #006876 0%, #90D26D 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
              .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
              .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
              .button { display: inline-block; padding: 12px 30px; background: #006876; color: white !important; text-decoration: none; border-radius: 5px; margin: 20px 0; }
              .info-box { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #90D26D; }
              .info-row { margin: 10px 0; }
              .label { font-weight: bold; color: #006876; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1 style="margin: 0;">🆕 New Doctor Registration</h1>
                <p style="margin: 10px 0 0 0;">Sehat Makaan Admin Panel</p>
              </div>
              <div class="content">
                <p>Hello Admin,</p>
                
                <p>A new doctor has completed registration and is awaiting your review and approval.</p>

                <div class="info-box">
                  <h3 style="margin-top: 0; color: #006876;">Doctor Details</h3>
                  <div class="info-row">
                    <span class="label">Name:</span> ${userData.fullName}
                  </div>
                  <div class="info-row">
                    <span class="label">Email:</span> ${userData.email}
                  </div>
                  <div class="info-row">
                    <span class="label">Specialty:</span> ${userData.specialty}
                  </div>
                  <div class="info-row">
                    <span class="label">PMDC Number:</span> ${userData.pmdcNumber}
                  </div>
                  <div class="info-row">
                    <span class="label">CNIC:</span> ${userData.cnicNumber}
                  </div>
                  <div class="info-row">
                    <span class="label">Phone:</span> ${userData.phoneNumber}
                  </div>
                  <div class="info-row">
                    <span class="label">Experience:</span> ${userData.yearsOfExperience} years
                  </div>
                  <div class="info-row">
                    <span class="label">Age:</span> ${userData.age}
                  </div>
                  <div class="info-row">
                    <span class="label">Gender:</span> ${userData.gender}
                  </div>
                </div>

                <p>
                  Please review this registration request in the admin dashboard and approve or reject as appropriate.
                </p>

                <div style="text-align: center;">
                  <a href="https://sehatmakaan.com/admin" class="button">
                    Review Registration →
                  </a>
                </div>

                <p style="margin-top: 20px; color: #666; font-size: 14px;">
                  <strong>Action Required:</strong> Log in to the admin dashboard to review this registration.
                </p>
              </div>
              <div class="footer">
                <p>Sehat Makaan Admin Notifications</p>
                <p>📧 admin@sehatmakaan.com</p>
              </div>
            </div>
          </body>
          </html>
          `,
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          retryCount: 0,
        });

        promises.push(notificationPromise, emailPromise);
      });

      await Promise.all(promises);

      console.log('✅ All admin notifications and emails sent successfully');
      return { success: true, adminCount: adminsSnapshot.size };

    } catch (error) {
      console.error('❌ Error notifying admins:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Cloud Function: On User Approval
 * Triggers when user status changes from 'pending' to 'approved'
 * Sends welcome email with account activation notification
 */
exports.onUserApproval = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const userId = context.params.userId;

    console.log('📝 User document updated:', userId);
    console.log('Before status:', beforeData.status);
    console.log('After status:', afterData.status);

    // Only trigger if status changed from pending to approved
    if (beforeData.status !== 'pending' || afterData.status !== 'approved') {
      console.log('⚠️ Not a pending → approved transition, skipping');
      return null;
    }

    try {
      console.log('✅ User approved! Sending welcome notification');

      // Create notification for the user
      await admin.firestore().collection('notifications').add({
        userId: userId,
        type: 'registration_approved',
        title: '🎉 Registration Approved!',
        message: 'Your registration has been approved. Welcome to Sehat Makaan!',
        priority: 'high',
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Queue welcome email
      await admin.firestore().collection('email_queue').add({
        to: afterData.email,
        subject: '🎉 Welcome to Sehat Makaan - Registration Approved!',
        html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #90D26D 0%, #006876 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            .button { display: inline-block; padding: 12px 30px; background: #90D26D; color: white !important; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .info-box { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #90D26D; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1 style="margin: 0;">🎉 Welcome to Sehat Makaan!</h1>
              <p style="margin: 10px 0 0 0;">Your Registration Has Been Approved</p>
            </div>
            <div class="content">
              <p>Dear Dr. ${afterData.fullName},</p>
              
              <p>
                <strong>Congratulations!</strong> Your registration has been approved by our admin team. 
                You now have full access to the Sehat Makaan platform.
              </p>

              <div class="info-box">
                <h3 style="margin-top: 0; color: #006876;">What's Next?</h3>
                <ul style="color: #333; line-height: 2;">
                  <li>✅ Your account is now active</li>
                  <li>🏥 Book practice suites for your sessions</li>
                  <li>📚 Register for professional workshops</li>
                  <li>📊 Manage your bookings and subscriptions</li>
                </ul>
              </div>

              <div style="text-align: center;">
                <a href="https://sehatmakaan.com/login" class="button">
                  Login to Your Account →
                </a>
              </div>

              <p style="margin-top: 30px; color: #666;">
                If you have any questions or need assistance, our support team is here to help.
              </p>

              <p style="color: #666;">
                <strong>Contact Support:</strong><br>
                📧 support@sehatmakaan.com
              </p>
            </div>
            <div class="footer">
              <p>Sehat Makaan - Your Health, Our Priority</p>
              <p>📧 support@sehatmakaan.com</p>
            </div>
          </div>
        </body>
        </html>
        `,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        retryCount: 0,
      });

      console.log('✅ Approval notification and welcome email sent to:', afterData.email);
      return { success: true };

    } catch (error) {
      console.error('❌ Error sending approval notification:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Cloud Function: On User Rejection
 * Triggers when user status changes from 'pending' to 'rejected'
 * Sends rejection notification with reason
 */
exports.onUserRejection = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const userId = context.params.userId;

    console.log('📝 User document updated:', userId);
    console.log('Before status:', beforeData.status);
    console.log('After status:', afterData.status);

    // Only trigger if status changed from pending to rejected
    if (beforeData.status !== 'pending' || afterData.status !== 'rejected') {
      console.log('⚠️ Not a pending → rejected transition, skipping');
      return null;
    }

    try {
      console.log('❌ User rejected. Sending notification');

      // Create notification for the user
      await admin.firestore().collection('notifications').add({
        userId: userId,
        type: 'registration_rejected',
        title: 'Registration Update',
        message: afterData.rejectionReason || 'Your registration has been reviewed.',
        priority: 'normal',
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Queue rejection email
      await admin.firestore().collection('email_queue').add({
        to: afterData.email,
        subject: 'Sehat Makaan Registration Update',
        html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #FF6B35 0%, #006876 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            .reason-box { background: #fff3e0; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #FF6B35; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1 style="margin: 0;">Registration Update</h1>
              <p style="margin: 10px 0 0 0;">Sehat Makaan</p>
            </div>
            <div class="content">
              <p>Dear ${afterData.fullName},</p>
              
              <p>
                Thank you for your interest in Sehat Makaan. After careful review, 
                we are unable to approve your registration at this time.
              </p>

              ${afterData.rejectionReason ? `
              <div class="reason-box">
                <strong style="color: #FF6B35;">Reason:</strong>
                <p style="color: #333; line-height: 1.6; margin: 10px 0 0 0;">
                  ${afterData.rejectionReason}
                </p>
              </div>
              ` : ''}

              <p style="margin-top: 30px;">
                If you believe this decision was made in error or would like to reapply, 
                please contact our admin team for further assistance.
              </p>

              <p style="margin-top: 20px; color: #666;">
                <strong>Contact Admin:</strong><br>
                📧 admin@sehatmakaan.com
              </p>
            </div>
            <div class="footer">
              <p>Sehat Makaan - Your Health, Our Priority</p>
              <p>📧 support@sehatmakaan.com</p>
            </div>
          </div>
        </body>
        </html>
        `,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        retryCount: 0,
      });

      console.log('✅ Rejection notification and email sent to:', afterData.email);
      return { success: true };

    } catch (error) {
      console.error('❌ Error sending rejection notification:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Cloud Function: Send Marketing Email to Users
 * Callable function for admin to send marketing emails to users with marketing enabled
 */
exports.sendMarketingEmail = functions.https.onCall(async (data, context) => {
  // Check if request is from authenticated admin
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { subject, message, htmlContent } = data;

  if (!subject || !message) {
    throw new functions.https.HttpsError('invalid-argument', 'Subject and message are required');
  }

  try {
    console.log('📧 Starting marketing email campaign:', subject);

    // Get all approved doctors with marketing emails enabled
    const usersSnapshot = await admin.firestore()
      .collection('users')
      .where('userType', '==', 'doctor')
      .where('status', '==', 'approved')
      .where('marketingEmails', '==', true)
      .get();

    console.log(`📬 Found ${usersSnapshot.size} users with marketing enabled`);

    if (usersSnapshot.empty) {
      return { 
        success: true, 
        emailsSent: 0,
        message: 'No users with marketing emails enabled'
      };
    }

    let emailsSent = 0;
    const emailPromises = [];

    // Queue emails for each user
    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const email = userData.email;

      if (email) {
        const emailPromise = admin.firestore().collection('email_queue').add({
          to: email,
          subject: subject,
          html: htmlContent || message,
          data: {
            type: 'marketing',
            userId: userDoc.id,
            campaignSubject: subject,
          },
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          attempts: 0,
        });

        emailPromises.push(emailPromise);
        emailsSent++;
      }
    }

    // Wait for all emails to be queued
    await Promise.all(emailPromises);

    // Save campaign record
    await admin.firestore().collection('marketing_campaigns').add({
      subject: subject,
      message: message,
      recipientCount: emailsSent,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      sentBy: context.auth.uid,
    });

    console.log(`✅ Marketing campaign completed: ${emailsSent} emails queued`);

    return {
      success: true,
      emailsSent: emailsSent,
      message: `Successfully sent marketing email to ${emailsSent} users`
    };

  } catch (error) {
    console.error('❌ Error sending marketing emails:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Trigger: When a booking status is updated
 * Action: Send push notification to user if booking is cancelled/updated
 */
exports.onBookingStatusChange = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    try {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      const bookingId = context.params.bookingId;

      // Check if status changed
      if (beforeData.status === afterData.status) {
        console.log('Status unchanged, skipping notification');
        return null;
      }

      const userId = afterData.userId;
      if (!userId) {
        console.warn('No userId found in booking');
        return null;
      }

      // Get user FCM token
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      if (!userDoc.exists) {
        console.warn(`User ${userId} not found`);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      // Prepare notification based on status change
      let notificationTitle = '';
      let notificationBody = '';
      let notificationType = 'booking_update';

      if (afterData.status === 'cancelled') {
        notificationTitle = 'Booking Cancelled';
        notificationBody = `Your booking for ${afterData.specialty || 'suite'} on ${afterData.bookingDate?.toDate().toLocaleDateString() || 'selected date'} has been cancelled.`;
        notificationType = 'booking_cancelled';
        
        // Refund hours ONLY if refundIssued is true
        const shouldRefund = afterData.refundIssued === true;
        
        if (shouldRefund) {
          // Use chargedMinutes (what user paid) not durationHours (includes Extended Hours bonus)
          const chargedMins = afterData.chargedMinutes || afterData.totalDurationMins || (afterData.durationHours * 60);
          
          if (chargedMins > 0) {
            const subscriptionQuery = await admin.firestore()
              .collection('subscriptions')
              .where('userId', '==', userId)
              .where('status', '==', 'active')
              .orderBy('createdAt', 'desc')
              .limit(1)
              .get();

            if (!subscriptionQuery.empty) {
              const subDoc = subscriptionQuery.docs[0];
              const currentRemainingHours = subDoc.data().remainingHours || 0;
              const currentRemainingMins = subDoc.data().remainingMinutes || 0;
              const currentTotalMins = (currentRemainingHours * 60) + currentRemainingMins;
              
              // Add back the charged minutes
              const newTotalMins = currentTotalMins + chargedMins;
              const newRemainingHours = Math.floor(newTotalMins / 60);
              const newRemainingMinutes = newTotalMins % 60;
              
              await subDoc.ref.update({
                remainingHours: newRemainingHours,
                remainingMinutes: newRemainingMinutes,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
              
              const refundHours = Math.floor(chargedMins / 60);
              const refundMins = chargedMins % 60;
              const refundText = refundMins > 0 
                ? `${refundHours}h ${refundMins}m` 
                : `${refundHours} hour(s)`;
              
              console.log(`✅ Refunded ${chargedMins} mins (${refundText}) to user ${userId}`);
              notificationBody += ` ${refundText} have been refunded to your account.`;
            }
          }
        } else if (!shouldRefund) {
          notificationBody += ' No refund issued.';
          console.log(`ℹ️ No refund for booking ${bookingId} (refundIssued=false)`);
        }
      } else if (afterData.status === 'confirmed') {
        notificationTitle = 'Booking Confirmed';
        notificationBody = `Your booking for ${afterData.specialty || 'suite'} on ${afterData.bookingDate?.toDate().toLocaleDateString() || 'selected date'} has been confirmed.`;
        notificationType = 'booking_confirmed';
      } else if (afterData.status === 'completed') {
        notificationTitle = 'Booking Completed';
        notificationBody = `Your booking has been marked as completed. Thank you for using Sehat Makaan!`;
        notificationType = 'booking_completed';
      }

      // Create in-app notification
      await admin.firestore().collection('notifications').add({
        userId: userId,
        title: notificationTitle,
        message: notificationBody,
        type: notificationType,
        relatedBookingId: bookingId,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ In-app notification created for user ${userId}`);

      // Send push notification if FCM token exists
      if (fcmToken) {
        const message = {
          notification: {
            title: notificationTitle,
            body: notificationBody,
          },
          data: {
            type: notificationType,
            bookingId: bookingId,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          token: fcmToken,
        };

        try {
          await admin.messaging().send(message);
          console.log(`✅ Push notification sent to user ${userId}`);
        } catch (error) {
          console.error(`❌ Error sending push notification: ${error.message}`);
          // If token is invalid, remove it
          if (error.code === 'messaging/invalid-registration-token' ||
              error.code === 'messaging/registration-token-not-registered') {
            await admin.firestore().collection('users').doc(userId).update({
              fcmToken: admin.firestore.FieldValue.delete(),
            });
            console.log(`Removed invalid FCM token for user ${userId}`);
          }
        }
      } else {
        console.log(`No FCM token for user ${userId}, push notification skipped`);
      }

      return null;
    } catch (error) {
      console.error('❌ Error in booking status change:', error);
      return null;
    }
  });

/**
 * Cloud Function: Check Subscription Expiry and Send Notifications
 * Runs daily at 9 AM Pakistan time (UTC+5) to check for expiring subscriptions
 * Sends notifications at 7 days, 3 days, and 1 day before expiry
 */
exports.checkSubscriptionExpiry = functions.pubsub
  .schedule('0 9 * * *')
  .timeZone('Asia/Karachi')
  .onRun(async (context) => {
    try {
      console.log('🔔 Running subscription expiry check...');

      const now = new Date();
      const sevenDaysFromNow = new Date(now.getTime() + (7 * 24 * 60 * 60 * 1000));
      const threeDaysFromNow = new Date(now.getTime() + (3 * 24 * 60 * 60 * 1000));
      const oneDayFromNow = new Date(now.getTime() + (24 * 60 * 60 * 1000));

      // Get all active subscriptions
      const subscriptionsSnapshot = await admin.firestore()
        .collection('subscriptions')
        .where('status', '==', 'active')
        .where('isActive', '==', true)
        .get();

      console.log(`Found ${subscriptionsSnapshot.size} active subscriptions`);

      let notificationsCreated = 0;

      for (const subDoc of subscriptionsSnapshot.docs) {
        const subscription = subDoc.data();
        const subscriptionId = subDoc.id;
        const endDate = subscription.endDate?.toDate();
        
        if (!endDate) continue;

        const userId = subscription.userId;
        const suiteType = subscription.suiteType || 'Unknown';
        const packageType = subscription.packageType || 'package';
        const remainingHours = subscription.remainingHours || 0;

        // Calculate days remaining
        const daysRemaining = Math.ceil((endDate - now) / (24 * 60 * 60 * 1000));

        // Check if we should send notification (7, 3, or 1 day remaining)
        let shouldNotify = false;
        let daysRemainingKey = 0;

        if (daysRemaining === 7) {
          shouldNotify = true;
          daysRemainingKey = 7;
        } else if (daysRemaining === 3) {
          shouldNotify = true;
          daysRemainingKey = 3;
        } else if (daysRemaining === 1) {
          shouldNotify = true;
          daysRemainingKey = 1;
        }

        if (!shouldNotify) continue;

        // Check if notification already exists for this subscription and day count
        const existingNotification = await admin.firestore()
          .collection('notifications')
          .where('userId', '==', userId)
          .where('type', '==', 'subscription_expiry_warning')
          .where('relatedSubscriptionId', '==', subscriptionId)
          .where('daysRemaining', '==', daysRemainingKey)
          .limit(1)
          .get();

        if (!existingNotification.empty) {
          console.log(`Notification already exists for subscription ${subscriptionId} (${daysRemainingKey} days)`);
          continue;
        }

        // Create notification
        let title, message;
        if (daysRemainingKey === 1) {
          title = '⚠️ Subscription Expiring Tomorrow!';
          message = `Your ${suiteType} Suite (${packageType}) will expire tomorrow. You have ${remainingHours} hours remaining. Renew now to avoid losing your hours!`;
        } else {
          title = '⏰ Subscription Expiring Soon';
          message = `Your ${suiteType} Suite (${packageType}) will expire in ${daysRemainingKey} days. You have ${remainingHours} hours remaining. Consider renewing to continue using your benefits.`;
        }

        await admin.firestore().collection('notifications').add({
          userId: userId,
          type: 'subscription_expiry_warning',
          title: title,
          message: message,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          relatedSubscriptionId: subscriptionId,
          daysRemaining: daysRemainingKey,
        });

        // Send push notification
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        if (userDoc.exists) {
          const fcmToken = userDoc.data().fcmToken;
          if (fcmToken) {
            try {
              await admin.messaging().send({
                notification: {
                  title: title,
                  body: message,
                },
                data: {
                  type: 'subscription_expiry_warning',
                  subscriptionId: subscriptionId,
                  daysRemaining: daysRemainingKey.toString(),
                  click_action: 'FLUTTER_NOTIFICATION_CLICK',
                },
                token: fcmToken,
              });
              console.log(`✅ Push notification sent to user ${userId} for ${daysRemainingKey} days warning`);
            } catch (error) {
              console.error(`❌ Error sending push notification: ${error.message}`);
              if (error.code === 'messaging/invalid-registration-token' ||
                  error.code === 'messaging/registration-token-not-registered') {
                await admin.firestore().collection('users').doc(userId).update({
                  fcmToken: admin.firestore.FieldValue.delete(),
                });
              }
            }
          }
        }

        notificationsCreated++;
        console.log(`Created expiry warning for subscription ${subscriptionId} (${daysRemainingKey} days)`);
      }

      console.log(`✅ Subscription expiry check complete. Created ${notificationsCreated} notifications.`);
      return null;
    } catch (error) {
      console.error('❌ Error checking subscription expiry:', error);
      return null;
    }
  });

/**
 * Cloud Function: Send Notification on Booking Cancellation
 * Triggers when admin cancels a booking (with or without refund)
 * Sends both in-app and push notifications
 */
exports.onAdminBookingCancellation = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    try {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      const bookingId = context.params.bookingId;

      // Only process if status changed to cancelled
      if (beforeData.status === 'cancelled' || afterData.status !== 'cancelled') {
        return null;
      }

      const userId = afterData.userId;
      if (!userId) {
        console.warn('No userId found in booking');
        return null;
      }

      // Check if this was cancelled by admin
      const cancelledBy = afterData.cancelledBy;
      if (!cancelledBy || !cancelledBy.startsWith('admin_')) {
        console.log('Booking not cancelled by admin, skipping');
        return null;
      }

      // Get user data for FCM token
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      if (!userDoc.exists) {
        console.warn(`User ${userId} not found`);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;
      const userName = userData.name || 'User';

      // Determine refund status
      const refundIssued = afterData.refundIssued === true;
      const chargedMins = afterData.chargedMinutes || afterData.totalDurationMins || (afterData.durationHours * 60) || 0;
      const bookingDate = afterData.bookingDate?.toDate().toLocaleDateString() || 'selected date';
      const specialty = afterData.specialty || 'suite';

      // Create notification message
      let notificationTitle = '❌ Booking Cancelled by Admin';
      let notificationBody = `Your booking for ${specialty} on ${bookingDate} has been cancelled by the administrator.`;

      if (refundIssued && chargedMins > 0) {
        const refundHours = Math.floor(chargedMins / 60);
        const refundMins = chargedMins % 60;
        const refundText = refundMins > 0 
          ? `${refundHours}h ${refundMins}m` 
          : `${refundHours} hour(s)`;
        notificationBody += ` ${refundText} have been refunded to your account.`;
      } else {
        notificationBody += ' No refund issued for this cancellation.';
      }

      // Create in-app notification
      await admin.firestore().collection('notifications').add({
        userId: userId,
        title: notificationTitle,
        message: notificationBody,
        type: 'admin_booking_cancellation',
        relatedBookingId: bookingId,
        refundIssued: refundIssued,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ In-app notification created for user ${userId} (Refund: ${refundIssued})`);

      // Send push notification if FCM token exists
      if (fcmToken) {
        try {
          await admin.messaging().send({
            notification: {
              title: notificationTitle,
              body: notificationBody,
            },
            data: {
              type: 'admin_booking_cancellation',
              bookingId: bookingId,
              refundIssued: refundIssued.toString(),
              chargedMinutes: chargedMins.toString(),
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            token: fcmToken,
          });
          console.log(`✅ Push notification sent to user ${userId}`);
        } catch (error) {
          console.error(`❌ Error sending push notification: ${error.message}`);
          if (error.code === 'messaging/invalid-registration-token' ||
              error.code === 'messaging/registration-token-not-registered') {
            await admin.firestore().collection('users').doc(userId).update({
              fcmToken: admin.firestore.FieldValue.delete(),
            });
            console.log(`Removed invalid FCM token for user ${userId}`);
          }
        }
      } else {
        console.log(`No FCM token for user ${userId}, push notification skipped`);
      }

      return null;
    } catch (error) {
      console.error('❌ Error in admin booking cancellation notification:', error);
      return null;
    }
  });

/**
 * Cloud Function: Send Booking Reminders
 * Runs daily at 9 AM Pakistan time to send 24-hour reminders
 * Sends email and push notifications for upcoming bookings
 */
exports.sendBookingReminders = functions.pubsub
  .schedule('0 9 * * *')
  .timeZone('Asia/Karachi')
  .onRun(async (context) => {
    try {
      console.log('🔔 Running booking reminder check...');

      // Calculate tomorrow's date range
      const now = new Date();
      const tomorrow = new Date(now);
      tomorrow.setDate(tomorrow.getDate() + 1);
      tomorrow.setHours(0, 0, 0, 0);
      
      const tomorrowEnd = new Date(tomorrow);
      tomorrowEnd.setHours(23, 59, 59, 999);

      console.log(`Checking bookings for: ${tomorrow.toDateString()}`);

      // Get all confirmed bookings for tomorrow
      const bookingsSnapshot = await admin.firestore()
        .collection('bookings')
        .where('bookingDate', '>=', admin.firestore.Timestamp.fromDate(tomorrow))
        .where('bookingDate', '<=', admin.firestore.Timestamp.fromDate(tomorrowEnd))
        .where('status', '==', 'confirmed')
        .get();

      if (bookingsSnapshot.empty) {
        console.log('No bookings found for tomorrow');
        return null;
      }

      console.log(`Found ${bookingsSnapshot.size} bookings for tomorrow`);

      const reminders = [];
      
      for (const bookingDoc of bookingsSnapshot.docs) {
        const booking = bookingDoc.data();
        const bookingId = bookingDoc.id;
        const userId = booking.userId;

        // Get user details
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(userId)
          .get();

        if (!userDoc.exists) {
          console.warn(`User ${userId} not found for booking ${bookingId}`);
          continue;
        }

        const user = userDoc.data();
        const userEmail = user.email;
        const userName = user.fullName || 'Valued Customer';
        const fcmToken = user.fcmToken;

        // Format booking details
        const bookingDate = booking.bookingDate.toDate();
        const formattedDate = bookingDate.toLocaleDateString('en-ZA', {
          weekday: 'long',
          year: 'numeric',
          month: 'long',
          day: 'numeric'
        });
        const timeSlot = booking.timeSlot || 'TBD';
        const suiteType = booking.suiteType || 'Suite';
        const specialty = booking.specialty || '';

        // Create in-app notification
        await admin.firestore().collection('notifications').add({
          userId: userId,
          title: 'Booking Reminder - Tomorrow',
          message: `Your ${suiteType} booking is scheduled for tomorrow at ${timeSlot}. ${specialty ? `Specialty: ${specialty}` : ''}`,
          type: 'booking_reminder',
          relatedBookingId: bookingId,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`✅ In-app notification created for user ${userId}`);

        // Queue reminder email
        await admin.firestore().collection('email_queue').add({
          to: userEmail,
          subject: `Reminder: Your Booking Tomorrow at ${timeSlot}`,
          htmlContent: `
            <!DOCTYPE html>
            <html>
            <head>
              <style>
                body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
                .container { max-width: 600px; margin: 20px auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                .header { background: linear-gradient(135deg, #F59E0B 0%, #D97706 100%); color: white; padding: 30px; text-align: center; }
                .header h1 { margin: 0; font-size: 28px; }
                .content { padding: 30px; }
                .reminder-box { background-color: #fef3c7; border-left: 4px solid #F59E0B; padding: 20px; margin: 20px 0; border-radius: 5px; }
                .detail-row { margin: 10px 0; color: #333; }
                .detail-label { font-weight: bold; color: #D97706; }
                .footer { background-color: #f8f8f8; padding: 20px; text-align: center; color: #666; font-size: 12px; }
                .button { display: inline-block; background-color: #14B8A6; color: white; padding: 15px 40px; text-decoration: none; border-radius: 5px; font-weight: bold; font-size: 16px; margin-top: 20px; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h1>🔔 Booking Reminder</h1>
                </div>
                <div class="content">
                  <p>Dear <strong>${userName}</strong>,</p>
                  <p>This is a friendly reminder about your upcoming booking <strong>tomorrow</strong>.</p>
                  
                  <div class="reminder-box">
                    <h2 style="color: #D97706; margin-top: 0;">Booking Details</h2>
                    <div class="detail-row">
                      <span class="detail-label">📅 Date:</span> ${formattedDate}
                    </div>
                    <div class="detail-row">
                      <span class="detail-label">⏰ Time:</span> ${timeSlot}
                    </div>
                    <div class="detail-row">
                      <span class="detail-label">🏥 Suite:</span> ${suiteType.charAt(0).toUpperCase() + suiteType.slice(1)}
                    </div>
                    ${specialty ? `<div class="detail-row"><span class="detail-label">💼 Specialty:</span> ${specialty}</div>` : ''}
                  </div>

                  <p><strong>Important Reminders:</strong></p>
                  <ul>
                    <li>Please arrive 10 minutes before your scheduled time</li>
                    <li>Bring any relevant medical documents</li>
                    <li>Bring your booking confirmation (QR code)</li>
                    <li>For cancellations, contact us at least 24 hours in advance</li>
                  </ul>

                  <p style="text-align: center;">
                    <a href="https://sehatmakaan.com/my-bookings" class="button">
                      View My Bookings
                    </a>
                  </p>

                  <p style="margin-top: 30px; color: #666; font-size: 12px;">
                    <strong>Booking ID:</strong> ${bookingId}
                  </p>
                </div>
                <div class="footer">
                  <p>Sehat Makaan - Your Health, Our Priority</p>
                  <p>📧 support@sehatmakaan.com | 📞 +92-XXX-XXXXXXX</p>
                  <p style="margin-top: 10px;">
                    If you need to reschedule or cancel, please contact us as soon as possible.
                  </p>
                </div>
              </div>
            </body>
            </html>
          `,
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          retryCount: 0,
        });

        console.log(`✅ Reminder email queued for ${userEmail}`);

        // Send push notification if FCM token exists
        if (fcmToken) {
          try {
            await admin.messaging().send({
              notification: {
                title: '🔔 Booking Reminder',
                body: `Your ${suiteType} booking is tomorrow at ${timeSlot}. Don't forget!`,
              },
              data: {
                type: 'booking_reminder',
                bookingId: bookingId,
                bookingDate: formattedDate,
                timeSlot: timeSlot,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
              },
              token: fcmToken,
            });
            console.log(`✅ Push notification sent to user ${userId}`);
          } catch (error) {
            console.error(`❌ Error sending push notification: ${error.message}`);
            if (error.code === 'messaging/invalid-registration-token' ||
                error.code === 'messaging/registration-token-not-registered') {
              await admin.firestore().collection('users').doc(userId).update({
                fcmToken: admin.firestore.FieldValue.delete(),
              });
              console.log(`Removed invalid FCM token for user ${userId}`);
            }
          }
        }

        reminders.push({
          bookingId,
          userId,
          email: userEmail,
          sent: true
        });
      }

      console.log(`✅ Sent ${reminders.length} booking reminders`);
      return { success: true, remindersSent: reminders.length };

    } catch (error) {
      console.error('❌ Error sending booking reminders:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Cloud Function: Workshop Approval Notification
 * Triggers when a workshop proposal is approved (permissionStatus changes to 'approved')
 * Sends email to workshop creator with price and payment instructions
 */
exports.onWorkshopApproval = functions.firestore
  .document('workshops/{workshopId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const workshopId = context.params.workshopId;

    // Check if workshop was just approved
    const wasApproved = before.permissionStatus !== 'approved' && after.permissionStatus === 'approved';
    
    if (!wasApproved) {
      console.log('No approval detected, skipping email');
      return null;
    }

    console.log(`📧 Workshop ${workshopId} approved, sending notification email`);

    try {
      // Get creator details
      const creatorId = after.creatorId || after.doctorId;
      if (!creatorId) {
        console.error('No creator ID found in workshop');
        return null;
      }

      const creatorDoc = await admin.firestore().collection('users').doc(creatorId).get();
      if (!creatorDoc.exists) {
        console.error(`Creator ${creatorId} not found`);
        return null;
      }

      const creatorData = creatorDoc.data();
      const creatorEmail = creatorData.email;
      const creatorName = creatorData.fullName || creatorData.name || 'Doctor';

      if (!creatorEmail) {
        console.error('Creator has no email address');
        return null;
      }

      // Get workshop details
      const workshopTitle = after.title || 'Your Workshop';
      const platformFee = after.adminSetFee || after.platformFee || 0;
      const paymentDeadline = after.approvalTime?.toDate();
      
      // Calculate deadline (2 hours from approval)
      let deadlineText = '2 hours';
      if (paymentDeadline) {
        const deadline = new Date(paymentDeadline.getTime() + (2 * 60 * 60 * 1000));
        deadlineText = deadline.toLocaleString('en-PK', { 
          dateStyle: 'medium', 
          timeStyle: 'short',
          timeZone: 'Asia/Karachi'
        });
      }

      // Create email HTML
      const emailHtml = `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #006876; color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
            .success-icon { font-size: 48px; margin-bottom: 10px; }
            .price-box { 
              background: linear-gradient(135deg, #FF6B35 0%, #FF8C42 100%); 
              color: white; 
              font-size: 36px; 
              font-weight: bold; 
              text-align: center; 
              padding: 25px; 
              border-radius: 12px; 
              margin: 25px 0; 
              box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            }
            .price-label { font-size: 14px; font-weight: normal; opacity: 0.9; margin-bottom: 5px; }
            .info-box { 
              background-color: #fff; 
              padding: 20px; 
              border-left: 4px solid #FF6B35; 
              margin: 20px 0; 
              border-radius: 4px;
            }
            .warning-box {
              background-color: #fff3cd;
              border-left: 4px solid #ffc107;
              padding: 15px;
              margin: 20px 0;
              border-radius: 4px;
            }
            .button { 
              display: inline-block; 
              background-color: #FF6B35; 
              color: white; 
              padding: 15px 30px; 
              text-decoration: none; 
              border-radius: 8px; 
              font-weight: bold; 
              margin: 20px 0;
              text-align: center;
            }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
            ul { line-height: 1.8; }
            .highlight { color: #FF6B35; font-weight: bold; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <div class="success-icon">✅</div>
              <h1>Workshop Request Approved!</h1>
            </div>
            <div class="content">
              <p>Dear Dr. ${creatorName},</p>
              
              <p>Congratulations! Your workshop proposal has been approved by the admin team.</p>
              
              <div class="info-box">
                <strong>Workshop Title:</strong><br>
                <span style="font-size: 18px;">${workshopTitle}</span>
              </div>

              <div class="price-box">
                <div class="price-label">PLATFORM FEE</div>
                PKR ${platformFee.toLocaleString()}
              </div>

              <h3 style="color: #006876;">📋 Next Steps:</h3>
              <ul>
                <li><strong>Pay the platform fee</strong> of PKR ${platformFee.toLocaleString()} to activate your workshop</li>
                <li>Your workshop will go <span class="highlight">LIVE</span> immediately after payment confirmation</li>
                <li>Users will be able to register for your workshop once it's live</li>
                <li>You'll receive registration notifications via email</li>
              </ul>

              <div class="warning-box">
                <strong>⏰ Important:</strong> You have <strong>${deadlineText}</strong> to complete the payment. 
                After this time, your approval may expire and require resubmission.
              </div>

              <h3 style="color: #006876;">💳 How to Pay:</h3>
              <ol>
                <li>Open the Sehat Makaan app</li>
                <li>Go to your Workshop Dashboard</li>
                <li>Click on the approved workshop</li>
                <li>Complete the payment using the available payment methods</li>
              </ol>

              <p style="margin-top: 30px;">If you have any questions or need assistance, please don't hesitate to contact our support team.</p>
              
              <p>Best regards,<br>
              <strong>Sehat Makaan Admin Team</strong></p>
            </div>
            <div class="footer">
              <p>© 2026 Sehat Makaan. All rights reserved.</p>
              <p>This is an automated message. Please do not reply to this email.</p>
            </div>
          </div>
        </body>
        </html>
      `;

      // Queue email
      await admin.firestore().collection('email_queue').add({
        to: creatorEmail,
        subject: `✅ Workshop Approved - Payment Required (PKR ${platformFee.toLocaleString()})`,
        html: emailHtml,
        template: 'custom',
        data: {
          creatorName,
          workshopTitle,
          platformFee,
          deadlineText
        },
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        retryCount: 0,
      });

      console.log(`✅ Approval email queued for ${creatorEmail}`);

      // Create in-app notification
      await admin.firestore().collection('notifications').add({
        userId: creatorId,
        title: '✅ Workshop Approved!',
        message: `Your workshop "${workshopTitle}" has been approved. Pay PKR ${platformFee.toLocaleString()} to make it live.`,
        type: 'workshop_approved',
        relatedWorkshopId: workshopId,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Send push notification if FCM token exists
      if (creatorData.fcmToken) {
        try {
          await admin.messaging().send({
            notification: {
              title: '✅ Workshop Approved!',
              body: `"${workshopTitle}" approved! Pay PKR ${platformFee.toLocaleString()} to go live.`,
            },
            data: {
              type: 'workshop_approved',
              workshopId: workshopId,
              platformFee: platformFee.toString(),
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            token: creatorData.fcmToken,
          });
          console.log(`✅ Push notification sent to creator ${creatorId}`);
        } catch (error) {
          console.error(`❌ Error sending push notification: ${error.message}`);
        }
      }

      return { success: true, emailSent: true };

    } catch (error) {
      console.error('❌ Error sending workshop approval email:', error);
      return { success: false, error: error.message };
    }
  });

// ============================================================================
// PAYFAST WEBHOOK HANDLER - Handles payment confirmations
// ============================================================================
exports.handlePayFastWebhook = functions.https.onRequest(async (req, res) => {
  console.log('🎯 PayFast Workshop Registration webhook received');
  
  try {
    // Only accept POST requests
    if (req.method !== 'POST') {
      console.log('⚠️ Invalid method:', req.method);
      res.status(405).send('Method Not Allowed');
      return;
    }

    const paymentData = req.body;
    console.log('Payment data:', JSON.stringify(paymentData, null, 2));

    // ✅ FIX #2: Verify PayFast signature
    if (!verifyPayFastSignature(paymentData)) {
      console.error('❌ Invalid signature - potential fraud attempt');
      res.status(401).send('Invalid signature');
      return;
    }

    const {
      custom_str1: registrationId,
      custom_str2: paymentId,
      payment_status: paymentStatus,
      amount_gross: amountGross,
      pf_payment_id: pfPaymentId,
    } = paymentData;

    // Only process successful payments
    if (paymentStatus !== 'COMPLETE') {
      console.log(`⚠️ Payment not completed: ${paymentStatus}`);
      res.status(200).send('OK');
      return;
    }

    if (!registrationId || !paymentId) {
      console.log('❌ Missing required fields');
      res.status(400).send('Missing required fields');
      return;
    }

    console.log(
      `💳 Processing workshop registration payment: ${pfPaymentId}, Amount: ${amountGross}, Registration: ${registrationId}`
    );

    // Get workshop registration details
    const registrationRef = admin
      .firestore()
      .collection('workshop_registrations')
      .doc(registrationId);
    
    const registrationDoc = await registrationRef.get();

    if (!registrationDoc.exists) {
      console.error(`❌ Registration not found: ${registrationId}`);
      res.status(404).send('Registration not found');
      return;
    }

    const registrationData = registrationDoc.data();
    const workshopId = registrationData.workshopId;
    const userId = registrationData.userId;

    // Get payment record
    const paymentRef = admin.firestore().collection('workshop_payments').doc(paymentId);
    const paymentDocCheck = await paymentRef.get();

    if (!paymentDocCheck.exists) {
      console.error(`❌ Payment record not found: ${paymentId}`);
      res.status(404).send('Payment record not found');
      return;
    }

    const paymentInfo = paymentDocCheck.data();

    // ✅ FIX #4: Check if already processed (duplicate webhook)
    if (paymentInfo.status === 'paid') {
      console.log('⚠️ Duplicate payment webhook - already processed');
      res.status(200).send('OK');
      return;
    }

    // ✅ FIX #3: Validate amount matches
    const expectedAmount = paymentInfo.amount;
    const receivedAmount = parseFloat(amountGross);
    if (Math.abs(receivedAmount - expectedAmount) > 1) {
      console.error(`❌ Amount mismatch! Expected: ${expectedAmount}, Received: ${receivedAmount}`);
      res.status(400).send('Amount mismatch');
      return;
    }

    // Generate registration number
    const year = new Date().getFullYear();
    const timestamp = Date.now().toString().substring(8);
    const registrationNumber = `WS-${year}-${timestamp}`;

    // Use transaction for atomic updates
    await admin.firestore().runTransaction(async (transaction) => {
      // Double-check payment status hasn't changed (race condition protection)
      const paymentRefresh = await transaction.get(paymentRef);
      if (paymentRefresh.data().status === 'paid') {
        throw new Error('Already processed');
      }

      // Update payment record with amount_gross for revenue calculation
      transaction.update(paymentRef, {
        status: 'paid',
        paymentId: pfPaymentId,
        amount_gross: receivedAmount,
        amountReceived: receivedAmount,
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update registration status to confirmed
      transaction.update(registrationRef, {
        status: 'confirmed',
        paymentStatus: 'paid',
        registrationNumber: registrationNumber,
        paymentId: pfPaymentId,
        confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update workshop participants count and initialize revenue tracking
      const workshopRef = admin.firestore().collection('workshops').doc(workshopId);
      const workshopDoc = await transaction.get(workshopRef);
      
      if (workshopDoc.exists) {
        const currentParticipants = workshopDoc.data().currentParticipants || 0;
        const maxParticipants = workshopDoc.data().maxParticipants || 100;

        if (currentParticipants < maxParticipants) {
          const updateData = {
            currentParticipants: currentParticipants + 1,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          };

          // Initialize revenue tracking fields on first payment
          if (!workshopDoc.data().revenueReleased) {
            updateData.revenueReleased = false;
            updateData.paymentHold = false;
            
            // Ensure creator info exists for revenue system
            if (!workshopDoc.data().creatorEmail || !workshopDoc.data().creatorName) {
              const creatorId = workshopDoc.data().createdBy || workshopDoc.data().creatorId;
              if (creatorId) {
                try {
                  const creatorSnapshot = await admin.firestore()
                    .collection('workshop_creators')
                    .where('userId', '==', creatorId)
                    .limit(1)
                    .get();
                  
                  if (!creatorSnapshot.empty) {
                    const creatorData = creatorSnapshot.docs[0].data();
                    if (!workshopDoc.data().creatorEmail) updateData.creatorEmail = creatorData.email;
                    if (!workshopDoc.data().creatorName) updateData.creatorName = creatorData.name || creatorData.firstName + ' ' + (creatorData.lastName || '');
                  }
                } catch (err) {
                  console.warn('Could not fetch creator info:', err.message);
                }
              }
            }
          }

          transaction.update(workshopRef, updateData);
        }
      }
    });

    console.log(`✅ Workshop registration confirmed. Registration: ${registrationId}, Payment: ${pfPaymentId}`);

    // Send confirmation email
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userEmail = registrationData.email || (userDoc.exists ? userDoc.data().email : null);

    if (userEmail && transporter) {
      try {
        const workshopDoc = await admin.firestore().collection('workshops').doc(workshopId).get();
        const workshopData = workshopDoc.exists ? workshopDoc.data() : {};

        await admin.firestore().collection('email_queue').add({
          to: userEmail,
          subject: `✅ Workshop Registration Confirmed - ${workshopData.title || 'Workshop'}`,
          htmlContent: `
            <!DOCTYPE html>
            <html>
            <head>
              <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background-color: #006876; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
                .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
                .success-box { background-color: #90D26D; color: white; padding: 15px; border-radius: 8px; margin: 20px 0; text-align: center; font-size: 18px; font-weight: bold; }
                .details { background-color: white; padding: 20px; border-left: 4px solid #FF6B35; margin: 20px 0; }
                .detail-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; }
                .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h1>Sehat Makaan</h1>
                  <p>Workshop Registration Confirmed</p>
                </div>
                <div class="content">
                  <div class="success-box">
                    ✅ Payment Successful - Workshop Registered!
                  </div>
                  <p>Dear ${registrationData.firstName || 'Participant'},</p>
                  <p>Your payment has been received and your workshop registration is now confirmed.</p>
                  <div class="details">
                    <h3>Registration Details</h3>
                    <div class="detail-row">
                      <span>Registration Number:</span>
                      <strong>${registrationNumber}</strong>
                    </div>
                    <div class="detail-row">
                      <span>Workshop:</span>
                      <strong>${workshopData.title || 'N/A'}</strong>
                    </div>
                    <div class="detail-row">
                      <span>Date:</span>
                      <strong>${workshopData.date ? new Date(workshopData.date).toLocaleDateString() : 'N/A'}</strong>
                    </div>
                    <div class="detail-row">
                      <span>Amount Paid:</span>
                      <strong>PKR ${amountGross}</strong>
                    </div>
                  </div>
                  <p>Please keep your registration number for reference. You should receive further details about the workshop soon.</p>
                  <p>If you have any questions, please contact support at sehatmakaan@gmail.com</p>
                </div>
                <div class="footer">
                  <p>&copy; 2024 Sehat Makaan. All rights reserved.</p>
                </div>
              </div>
            </body>
            </html>
          `,
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          retryCount: 0,
        });
        console.log(`✅ Confirmation email queued for: ${userEmail}`);
      } catch (error) {
        console.error('❌ Error queuing confirmation email:', error.message);
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Payment processed successfully',
      registrationNumber: registrationNumber,
    });

  } catch (error) {
    console.error('❌ Error handling PayFast webhook:', error);
    
    // ✅ FIX #7: Proper error handling
    if (error.message.includes('not found')) {
      res.status(404).send('Resource not found');
    } else if (error.message.includes('Already processed')) {
      res.status(200).send('OK');
    } else {
      res.status(500).send('Internal Server Error');
    }
  }
});

// ========================================
// WORKSHOP REVENUE RELEASE SYSTEM
// ========================================

/**
 * Calculate PayFast transaction fees
 * PayFast charges: 2.9% + PKR 3 per transaction
 * @param {number} amount - Transaction amount
 * @returns {number} - Fee amount
 */
function calculatePayFastFee(amount) {
  const percentageFee = amount * 0.029; // 2.9%
  const fixedFee = 3; // PKR 3
  return Math.round((percentageFee + fixedFee) * 100) / 100; // Round to 2 decimals
}

/**
 * Scheduled function to auto-release workshop revenues
 * Runs every hour to check workshops that ended 1 hour ago
 */
exports.autoReleaseWorkshopRevenue = functions.pubsub
  .schedule('every 60 minutes')
  .timeZone('Asia/Karachi')
  .onRun(async (context) => {
    console.log('🔄 Starting auto-release revenue check...');

    try {
      const now = admin.firestore.Timestamp.now();
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000); // 1 hour ago

      // Find workshops that:
      // 1. Ended at least 1 hour ago
      // 2. Have not had revenue released yet
      // 3. Are not on hold by admin
      // 4. Have participants (revenue > 0)
      const workshopsSnapshot = await admin.firestore()
        .collection('workshops')
        .where('endDateTime', '<=', oneHourAgo)
        .where('revenueReleased', '==', false)
        .where('paymentHold', '==', false)
        .get();

      console.log(`📊 Found ${workshopsSnapshot.size} workshops ready for revenue release`);

      const releasePromises = workshopsSnapshot.docs.map(async (workshopDoc) => {
        const workshopId = workshopDoc.id;
        const workshopData = workshopDoc.data();

        try {
          // Get all successful payments for this workshop
          const paymentsSnapshot = await admin.firestore()
            .collection('workshop_payments')
            .where('workshopId', '==', workshopId)
            .where('status', '==', 'paid')
            .get();

          if (paymentsSnapshot.empty) {
            console.log(`ℹ️ Workshop ${workshopId} has no payments, skipping`);
            return null;
          }

          // Calculate total revenue and fees
          let totalRevenue = 0;
          let totalFees = 0;
          const transactionCount = paymentsSnapshot.size;

          paymentsSnapshot.docs.forEach(paymentDoc => {
            const paymentData = paymentDoc.data();
            // Use amount_gross if available, otherwise fall back to amount or amountReceived
            const amount = parseFloat(paymentData.amount_gross || paymentData.amount || paymentData.amountReceived || 0);
            totalRevenue += amount;
            totalFees += calculatePayFastFee(amount);
          });

          const netRevenue = totalRevenue - totalFees;

          console.log(`💰 Workshop ${workshopId}: Total=${totalRevenue}, Fees=${totalFees}, Net=${netRevenue}`);

          // Create payout record
          const payoutRef = admin.firestore().collection('workshop_payouts').doc();
          const payoutData = {
            payoutId: payoutRef.id,
            workshopId: workshopId,
            creatorId: workshopData.creatorId,
            creatorEmail: workshopData.creatorEmail || '',
            workshopTitle: workshopData.title || 'Unknown Workshop',
            totalRevenue: totalRevenue,
            totalTransactions: transactionCount,
            totalFees: totalFees,
            netAmount: netRevenue,
            status: 'released',
            releaseType: 'automatic',
            releasedAt: admin.firestore.FieldValue.serverTimestamp(),
            releasedBy: 'system',
            notes: `Auto-released 1 hour after workshop end`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          };

          await payoutRef.set(payoutData);

          // Update workshop document
          await workshopDoc.ref.update({
            revenueReleased: true,
            revenueReleasedAt: admin.firestore.FieldValue.serverTimestamp(),
            totalRevenue: totalRevenue,
            totalFees: totalFees,
            netRevenue: netRevenue,
            payoutId: payoutRef.id,
          });

          // Send email to creator
          if (workshopData.creatorEmail && transporter) {
            await admin.firestore().collection('email_queue').add({
              to: workshopData.creatorEmail,
              subject: `💰 Revenue Released - ${workshopData.title}`,
              htmlContent: generateRevenueReleaseEmail({
                creatorName: workshopData.creatorName || 'Workshop Creator',
                workshopTitle: workshopData.title,
                totalRevenue: totalRevenue,
                totalFees: totalFees,
                netAmount: netRevenue,
                transactionCount: transactionCount,
                payoutId: payoutRef.id,
              }),
              status: 'pending',
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              retryCount: 0,
            });
          }

          // Send email to admin
          const adminEmail = 'sehatmakaan@gmail.com';
          if (transporter) {
            await admin.firestore().collection('email_queue').add({
              to: adminEmail,
              subject: `🔔 Revenue Released - ${workshopData.title}`,
              htmlContent: generateAdminRevenueNotification({
                workshopTitle: workshopData.title,
                creatorName: workshopData.creatorName || 'Unknown',
                creatorEmail: workshopData.creatorEmail || 'N/A',
                totalRevenue: totalRevenue,
                totalFees: totalFees,
                netAmount: netRevenue,
                transactionCount: transactionCount,
                payoutId: payoutRef.id,
                workshopId: workshopId,
              }),
              status: 'pending',
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              retryCount: 0,
            });
          }

          console.log(`✅ Revenue released for workshop ${workshopId}: PKR ${netRevenue}`);
          return { workshopId, netRevenue };

        } catch (error) {
          console.error(`❌ Error releasing revenue for workshop ${workshopId}:`, error);
          return null;
        }
      });

      const results = await Promise.all(releasePromises);
      const successCount = results.filter(r => r !== null).length;

      console.log(`✅ Auto-release complete: ${successCount}/${workshopsSnapshot.size} workshops processed`);
      return null;

    } catch (error) {
      console.error('❌ Error in auto-release function:', error);
      return null;
    }
  });

/**
 * Generate revenue release email for creator
 */
function generateRevenueReleaseEmail(data) {
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #006876; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
        .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
        .success-box { background-color: #90D26D; color: white; padding: 20px; border-radius: 8px; margin: 20px 0; text-align: center; font-size: 24px; font-weight: bold; }
        .details { background-color: white; padding: 20px; border-left: 4px solid #FF6B35; margin: 20px 0; }
        .detail-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #eee; }
        .amount-highlight { font-size: 32px; color: #006876; font-weight: bold; text-align: center; margin: 20px 0; }
        .fee-breakdown { background-color: #fff3cd; padding: 15px; border-radius: 8px; margin: 15px 0; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>💰 Revenue Released</h1>
          <p>Sehat Makaan Workshop Payment</p>
        </div>
        <div class="content">
          <div class="success-box">
            ✅ Revenue Successfully Released!
          </div>
          <p>Dear ${data.creatorName},</p>
          <p>Congratulations! The revenue from your workshop has been automatically released.</p>
          
          <div class="details">
            <h3>Workshop Details</h3>
            <div class="detail-row">
              <span>Workshop:</span>
              <strong>${data.workshopTitle}</strong>
            </div>
            <div class="detail-row">
              <span>Total Participants:</span>
              <strong>${data.transactionCount}</strong>
            </div>
            <div class="detail-row">
              <span>Payout ID:</span>
              <strong>${data.payoutId}</strong>
            </div>
          </div>

          <div class="fee-breakdown">
            <h3>💵 Payment Breakdown</h3>
            <div class="detail-row">
              <span>Total Revenue Collected:</span>
              <strong>PKR ${data.totalRevenue.toFixed(2)}</strong>
            </div>
            <div class="detail-row">
              <span>PayFast Transaction Fees (2.9% + PKR 3 per transaction):</span>
              <strong>- PKR ${data.totalFees.toFixed(2)}</strong>
            </div>
            <hr style="margin: 15px 0;">
            <div class="detail-row" style="font-size: 18px; border: none;">
              <span><strong>Net Amount Released to You:</strong></span>
              <strong style="color: #90D26D;">PKR ${data.netAmount.toFixed(2)}</strong>
            </div>
          </div>

          <div class="amount-highlight">
            PKR ${data.netAmount.toFixed(2)}
          </div>

          <p><strong>Note:</strong> PayFast transaction fees are automatically deducted as per platform policy. This is the industry standard for payment processing.</p>
          
          <p>The net amount will be processed according to your payout settings. Please allow 3-5 business days for bank transfers.</p>

          <p>If you have any questions about this payout, please contact us at sehatmakaan@gmail.com</p>

          <p>Thank you for creating valuable workshops on Sehat Makaan!</p>
          
          <p>Best regards,<br>Sehat Makaan Team</p>
        </div>
        <div class="footer">
          <p>&copy; 2026 Sehat Makaan. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
  `;
}

/**
 * Generate admin notification email
 */
function generateAdminRevenueNotification(data) {
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #FF6B35; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
        .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
        .info-box { background-color: #17a2b8; color: white; padding: 15px; border-radius: 8px; margin: 20px 0; text-align: center; font-size: 18px; font-weight: bold; }
        .details { background-color: white; padding: 20px; border: 2px solid #006876; margin: 20px 0; }
        .detail-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🔔 Admin Alert</h1>
          <p>Workshop Revenue Auto-Released</p>
        </div>
        <div class="content">
          <div class="info-box">
            ℹ️ Automatic Revenue Release Notification
          </div>
          <p>Dear Admin,</p>
          <p>A workshop revenue has been automatically released to the creator (1 hour after workshop end).</p>
          
          <div class="details">
            <h3>Workshop Information</h3>
            <div class="detail-row">
              <span>Workshop ID:</span>
              <strong>${data.workshopId}</strong>
            </div>
            <div class="detail-row">
              <span>Workshop Title:</span>
              <strong>${data.workshopTitle}</strong>
            </div>
            <div class="detail-row">
              <span>Creator Name:</span>
              <strong>${data.creatorName}</strong>
            </div>
            <div class="detail-row">
              <span>Creator Email:</span>
              <strong>${data.creatorEmail}</strong>
            </div>
          </div>

          <div class="details">
            <h3>Financial Summary</h3>
            <div class="detail-row">
              <span>Total Revenue:</span>
              <strong>PKR ${data.totalRevenue.toFixed(2)}</strong>
            </div>
            <div class="detail-row">
              <span>Total Participants:</span>
              <strong>${data.transactionCount}</strong>
            </div>
            <div class="detail-row">
              <span>PayFast Fees Deducted:</span>
              <strong>PKR ${data.totalFees.toFixed(2)}</strong>
            </div>
            <div class="detail-row" style="font-size: 16px;">
              <span><strong>Net Amount Released:</strong></span>
              <strong style="color: #90D26D;">PKR ${data.netAmount.toFixed(2)}</strong>
            </div>
            <div class="detail-row">
              <span>Payout ID:</span>
              <strong>${data.payoutId}</strong>
            </div>
          </div>

          <p><strong>Action Required:</strong> No action needed. This is an automatic notification for your records.</p>
          
          <p>If you need to hold future payments from this creator, update the payment hold status in the admin panel.</p>
        </div>
        <div class="footer">
          <p>&copy; 2026 Sehat Makaan Admin System. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
  `;
}

/**
 * Admin function to manually hold/release workshop payment
 * HTTPS callable function (requires admin authentication)
 */
exports.adminControlWorkshopPayout = functions.https.onCall(async (data, context) => {
  // Security: Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to perform this action'
    );
  }

  // Security: Check if user is admin (you should verify this from your admin collection)
  const userId = context.auth.uid;
  const userDoc = await admin.firestore().collection('users').doc(userId).get();
  
  if (!userDoc.exists || userDoc.data().userType !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can control workshop payouts'
    );
  }

  const { workshopId, action, reason } = data;

  // Validate input
  if (!workshopId || !action) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'workshopId and action are required'
    );
  }

  if (!['hold', 'release'].includes(action)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'action must be either "hold" or "release"'
    );
  }

  try {
    const workshopRef = admin.firestore().collection('workshops').doc(workshopId);
    const workshopDoc = await workshopRef.get();

    if (!workshopDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Workshop not found');
    }

    const workshopData = workshopDoc.data();

    if (action === 'hold') {
      // Admin wants to HOLD the payment
      await workshopRef.update({
        paymentHold: true,
        paymentHoldAt: admin.firestore.FieldValue.serverTimestamp(),
        paymentHoldBy: userId,
        paymentHoldReason: reason || 'Admin hold',
      });

      // Log the action
      await admin.firestore().collection('admin_actions').add({
        actionType: 'payment_hold',
        workshopId: workshopId,
        workshopTitle: workshopData.title,
        performedBy: userId,
        performedAt: admin.firestore.FieldValue.serverTimestamp(),
        reason: reason || 'Admin hold',
      });

      // Notify creator
      if (workshopData.creatorEmail && transporter) {
        await admin.firestore().collection('email_queue').add({
          to: workshopData.creatorEmail,
          subject: `⚠️ Payment on Hold - ${workshopData.title}`,
          htmlContent: `
            <h2>Payment Hold Notice</h2>
            <p>Dear ${workshopData.creatorName || 'Creator'},</p>
            <p>Your workshop revenue is currently on hold by the admin team.</p>
            <p><strong>Workshop:</strong> ${workshopData.title}</p>
            <p><strong>Reason:</strong> ${reason || 'Under review'}</p>
            <p>Please contact support at sehatmakaan@gmail.com for more information.</p>
          `,
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          retryCount: 0,
        });
      }

      return { success: true, message: 'Payment held successfully', action: 'hold' };

    } else if (action === 'release') {
      // Admin wants to MANUALLY RELEASE the payment
      
      // Get all successful payments for this workshop
      const paymentsSnapshot = await admin.firestore()
        .collection('workshop_payments')
        .where('workshopId', '==', workshopId)
        .where('status', '==', 'paid')
        .get();

      if (paymentsSnapshot.empty) {
        throw new functions.https.HttpsError('not-found', 'No payments found for this workshop');
      }

      // Calculate total revenue and fees
      let totalRevenue = 0;
      let totalFees = 0;
      const transactionCount = paymentsSnapshot.size;

      paymentsSnapshot.docs.forEach(paymentDoc => {
        const amount = parseFloat(paymentDoc.data().amount_gross || 0);
        totalRevenue += amount;
        totalFees += calculatePayFastFee(amount);
      });

      const netRevenue = totalRevenue - totalFees;

      // Create payout record
      const payoutRef = admin.firestore().collection('workshop_payouts').doc();
      const payoutData = {
        payoutId: payoutRef.id,
        workshopId: workshopId,
        creatorId: workshopData.creatorId,
        creatorEmail: workshopData.creatorEmail || '',
        workshopTitle: workshopData.title || 'Unknown Workshop',
        totalRevenue: totalRevenue,
        totalTransactions: transactionCount,
        totalFees: totalFees,
        netAmount: netRevenue,
        status: 'released',
        releaseType: 'manual',
        releasedAt: admin.firestore.FieldValue.serverTimestamp(),
        releasedBy: userId,
        notes: reason || 'Manually released by admin',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await payoutRef.set(payoutData);

      // Update workshop document
      await workshopRef.update({
        revenueReleased: true,
        revenueReleasedAt: admin.firestore.FieldValue.serverTimestamp(),
        totalRevenue: totalRevenue,
        totalFees: totalFees,
        netRevenue: netRevenue,
        payoutId: payoutRef.id,
        paymentHold: false,
        paymentHoldReason: null,
      });

      // Log the action
      await admin.firestore().collection('admin_actions').add({
        actionType: 'payment_release',
        workshopId: workshopId,
        workshopTitle: workshopData.title,
        performedBy: userId,
        performedAt: admin.firestore.FieldValue.serverTimestamp(),
        amount: netRevenue,
        payoutId: payoutRef.id,
        notes: reason || 'Manual release',
      });

      // Send emails (creator + admin)
      if (workshopData.creatorEmail && transporter) {
        await admin.firestore().collection('email_queue').add({
          to: workshopData.creatorEmail,
          subject: `💰 Revenue Released - ${workshopData.title}`,
          htmlContent: generateRevenueReleaseEmail({
            creatorName: workshopData.creatorName || 'Workshop Creator',
            workshopTitle: workshopData.title,
            totalRevenue: totalRevenue,
            totalFees: totalFees,
            netAmount: netRevenue,
            transactionCount: transactionCount,
            payoutId: payoutRef.id,
          }),
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          retryCount: 0,
        });
      }

      return {
        success: true,
        message: 'Payment released successfully',
        action: 'release',
        netAmount: netRevenue,
        payoutId: payoutRef.id,
      };
    }

  } catch (error) {
    console.error('❌ Error in admin payout control:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Get payout history for a workshop or creator
 * HTTPS callable function
 */
exports.getPayoutHistory = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { workshopId, creatorId } = data;
  const userId = context.auth.uid;

  try {
    // Check if user is admin or the creator
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const isAdmin = userDoc.exists && userDoc.data().userType === 'admin';
    const isCreator = userId === creatorId;

    if (!isAdmin && !isCreator) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You do not have permission to view these payouts'
      );
    }

    let query = admin.firestore().collection('workshop_payouts');

    if (workshopId) {
      query = query.where('workshopId', '==', workshopId);
    } else if (creatorId) {
      query = query.where('creatorId', '==', creatorId);
    } else {
      throw new functions.https.HttpsError('invalid-argument', 'workshopId or creatorId required');
    }

    const payoutsSnapshot = await query.orderBy('releasedAt', 'desc').limit(50).get();

    const payouts = payoutsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      releasedAt: doc.data().releasedAt?.toDate().toISOString(),
      createdAt: doc.data().createdAt?.toDate().toISOString(),
    }));

    return { success: true, payouts };

  } catch (error) {
    console.error('❌ Error fetching payout history:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

console.log('🚀 Sehat Makaan Cloud Functions initialized');

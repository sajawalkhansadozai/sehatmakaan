/// Helper class for workshop payment links and email templates
class WorkshopPaymentHelper {
  /// Generate payment link for workshop registration
  static String generatePaymentLink({
    required String registrationId,
    required String registrationNumber,
    required double amount,
  }) {
    // For now, generate internal checkout link
    // In production, integrate with actual payment gateway
    final params = Uri.encodeQueryComponent(
      'registrationId=$registrationId&registrationNumber=$registrationNumber&amount=${amount.toStringAsFixed(2)}',
    );
    return 'https://sehatmakaan.com/workshop-checkout?$params';
  }

  /// Generate HTML email for workshop confirmation
  static String generateWorkshopConfirmationEmailHtml({
    required String name,
    required String workshopTitle,
    required String registrationNumber,
    required double amount,
    required String paymentLink,
    required String workshopSchedule,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #22c55e; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
    .workshop-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .payment-button { background: #f97316; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; display: inline-block; margin: 20px 0; font-weight: bold; }
    .warning-box { background: #fef3c7; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #f59e0b; }
    .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🎓 Workshop Registration Confirmed!</h1>
    </div>
    <div class="content">
      <p>Dear $name,</p>
      <p>We're pleased to confirm your registration for the following workshop:</p>
      
      <div class="workshop-details">
        <h3 style="color: #22c55e; margin-top: 0;">$workshopTitle</h3>
        <p><strong>Registration Number:</strong> $registrationNumber</p>
        <p><strong>Schedule:</strong> $workshopSchedule</p>
        <p><strong>Amount:</strong> PKR ${amount.toStringAsFixed(0)}</p>
      </div>

      <h3 style="color: #dc2626;">Complete Your Payment</h3>
      <p>To secure your spot in the workshop, please complete your payment by clicking the link below:</p>
      
      <div style="text-align: center;">
        <a href="$paymentLink" class="payment-button">
          Complete Payment - PKR ${amount.toStringAsFixed(0)}
        </a>
      </div>

      <div class="warning-box">
        <p style="margin: 0; color: #92400e;">
          <strong>⚠️ Important:</strong> Please complete your payment within 48 hours to confirm your workshop seat. Unpaid registrations may be cancelled.
        </p>
      </div>

      <p>If you have any questions or need assistance, please contact us.</p>
      
      <p>Best regards,<br><strong>Sehat Makaan Training Team</strong></p>
    </div>
    <div class="footer">
      <p>© ${DateTime.now().year} Sehat Makaan. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
''';
  }
}

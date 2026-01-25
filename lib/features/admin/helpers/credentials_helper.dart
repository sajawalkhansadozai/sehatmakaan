/// Helper class for credentials generation and email templates
class CredentialsHelper {
  /// Generate username and password for approved doctors
  static Map<String, String> generateDoctorCredentials(
    String fullName,
    String userId,
  ) {
    // Clean name: remove "Dr." prefix and special characters
    final cleanName = fullName
        .toLowerCase()
        .replaceAll(RegExp(r'^dr\.?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z_]'), '');

    // Generate username: dr_name_001
    final username = 'dr_${cleanName}_${userId.padLeft(3, '0')}';

    // Generate password: SehatMakaan@2026
    final password = 'SehatMakaan@${DateTime.now().year}';

    return {'username': username, 'password': password};
  }

  /// Generate HTML email for doctor approval
  static String generateApprovalEmailHtml(
    String fullName,
    String username,
    String password,
  ) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #22c55e; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
    .credentials { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #22c55e; }
    .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
    .button { background: #22c55e; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; display: inline-block; margin: 20px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🎉 Registration Approved!</h1>
    </div>
    <div class="content">
      <p>Dear Dr. $fullName,</p>
      <p>Congratulations! Your registration with <strong>Sehat Makaan</strong> has been approved.</p>
      
      <div class="credentials">
        <h3 style="color: #22c55e; margin-top: 0;">Your Login Credentials</h3>
        <p><strong>Username:</strong> $username</p>
        <p><strong>Password:</strong> $password</p>
        <p style="color: #666; font-size: 14px; margin-top: 15px;">
          ⚠️ Please change your password after first login for security.
        </p>
      </div>

      <p>You can now access your dashboard and start booking our facilities.</p>
      
      <p><strong>What's next?</strong></p>
      <ul>
        <li>Login with your credentials</li>
        <li>Complete your profile</li>
        <li>Browse available packages</li>
        <li>Book your first session</li>
      </ul>

      <p>If you have any questions, feel free to contact our support team.</p>
      
      <p>Best regards,<br><strong>Sehat Makaan Team</strong></p>
    </div>
    <div class="footer">
      <p>© ${DateTime.now().year} Sehat Makaan. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Generate HTML email for doctor rejection
  static String generateRejectionEmailHtml(String fullName, String reason) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #dc2626; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
    .reason-box { background: #fee; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #dc2626; }
    .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Registration Update</h1>
    </div>
    <div class="content">
      <p>Dear Dr. $fullName,</p>
      <p>Thank you for your interest in <strong>Sehat Makaan</strong>.</p>
      
      <p>After careful review, we regret to inform you that we cannot approve your registration at this time.</p>
      
      <div class="reason-box">
        <h3 style="color: #dc2626; margin-top: 0;">Reason:</h3>
        <p>$reason</p>
      </div>

      <p>If you believe this was an error or would like to provide additional information, please contact our support team.</p>
      
      <p>Best regards,<br><strong>Sehat Makaan Team</strong></p>
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

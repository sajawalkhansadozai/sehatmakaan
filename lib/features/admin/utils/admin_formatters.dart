class AdminFormatters {
  static String formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = date is DateTime ? date : DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  static String formatDateTime(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = date is DateTime ? date : DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  static String formatDateOnly(dynamic date) {
    if (date == null) return '';
    try {
      final dt = date is DateTime ? date : DateTime.parse(date.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  static String formatDateLong(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'CONFIRMED';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      case 'no-show':
        return 'NO SHOW';
      default:
        return status.toUpperCase();
    }
  }
}

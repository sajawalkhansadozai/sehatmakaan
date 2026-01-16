import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/admin_formatters.dart';

/// Service class for loading admin dashboard data from Firestore
class AdminDataService {
  final FirebaseFirestore _firestore;

  AdminDataService(this._firestore);

  /// Load all doctors from Firestore
  Future<List<Map<String, dynamic>>> loadDoctors(String filterStatus) async {
    try {
      Query query = _firestore
          .collection('users')
          .where('userType', isEqualTo: 'doctor');

      // Apply status filter
      if (filterStatus != 'all') {
        query = query.where('status', isEqualTo: filterStatus);
      }

      final snapshot = await query.get();
      final doctors = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final doctorId = doc.id;

        // Add doctor with placeholder stats
        doctors.add({
          'id': doctorId,
          ...data,
          'stats': {
            'totalBookings': 0,
            'activeBookings': 0,
            'totalSubscriptions': 0,
            'activeSubscriptions': 0,
            'lastBookingDate': null,
          },
        });
      }

      return doctors;
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      rethrow;
    }
  }

  /// Enrich doctor with statistics
  Future<Map<String, dynamic>> enrichDoctorWithStats(String doctorId) async {
    try {
      // Get all bookings for this doctor
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: doctorId)
          .get();

      final bookings = bookingsSnapshot.docs;
      final activeBookings = bookings
          .where((doc) => doc.data()['status'] == 'confirmed')
          .toList();

      // Get all subscriptions for this doctor
      final subscriptionsSnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: doctorId)
          .get();

      final subscriptions = subscriptionsSnapshot.docs;
      final activeSubscriptions = subscriptions
          .where((doc) => doc.data()['isActive'] == true)
          .toList();

      // Get last booking date
      String? lastBookingDate;
      if (bookings.isNotEmpty) {
        final sortedBookings = bookings.toList()
          ..sort((a, b) {
            final dateA = (a.data()['bookingDate'] as Timestamp?)?.toDate();
            final dateB = (b.data()['bookingDate'] as Timestamp?)?.toDate();
            if (dateA == null || dateB == null) return 0;
            return dateB.compareTo(dateA);
          });
        final lastBooking = sortedBookings.first;
        final bookingDate = (lastBooking.data()['bookingDate'] as Timestamp?)
            ?.toDate();
        if (bookingDate != null) {
          lastBookingDate = AdminFormatters.formatDateLong(bookingDate);
        }
      }

      return {
        'totalBookings': bookings.length,
        'activeBookings': activeBookings.length,
        'totalSubscriptions': subscriptions.length,
        'activeSubscriptions': activeSubscriptions.length,
        'lastBookingDate': lastBookingDate,
      };
    } catch (e) {
      debugPrint('Error enriching doctor with stats: $e');
      return {
        'totalBookings': 0,
        'activeBookings': 0,
        'totalSubscriptions': 0,
        'activeSubscriptions': 0,
        'lastBookingDate': null,
      };
    }
  }

  /// Load bookings for a specific date
  Future<List<Map<String, dynamic>>> loadBookings(DateTime selectedDate) async {
    try {
      // Format the selected date as string to match bookingDate format (M/d/yyyy)
      final selectedDateStr =
          '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}';

      // Get all bookings and filter by date string
      final snapshot = await _firestore.collection('bookings').get();

      final bookings = <Map<String, dynamic>>[];

      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final bookingId = doc.id;
        final bookingDateField = data['bookingDate'];
        final status = data['status'] as String?;

        DateTime? bookingDateTime;
        DateTime? bookingEndTime;
        String? bookingDateStr;

        // Handle both String and Timestamp formats
        if (bookingDateField is String) {
          bookingDateStr = bookingDateField;
          // Parse the date string to DateTime
          try {
            final parts = bookingDateStr.split('/');
            if (parts.length == 3) {
              final month = int.parse(parts[0]);
              final day = int.parse(parts[1]);
              final year = int.parse(parts[2]);

              bookingDateTime = DateTime(year, month, day);

              // Calculate booking end time for auto-completion
              final timeSlot = data['timeSlot'] as String?;
              final durationMins = data['durationMins'] as int? ?? 60;

              if (timeSlot != null) {
                final timeParts = timeSlot.split(':');
                if (timeParts.length >= 2) {
                  final hour = int.tryParse(timeParts[0]) ?? 0;
                  final minute = int.tryParse(timeParts[1]) ?? 0;

                  bookingEndTime = DateTime(year, month, day, hour, minute);

                  // Add duration to get booking end time
                  bookingEndTime = bookingEndTime.add(
                    Duration(minutes: durationMins),
                  );
                }
              }
            }
          } catch (e) {
            debugPrint(
              'Error parsing booking date string: $bookingDateStr - $e',
            );
          }
        } else if (bookingDateField is Timestamp) {
          bookingDateTime = bookingDateField.toDate();
          bookingDateStr =
              '${bookingDateTime.month}/${bookingDateTime.day}/${bookingDateTime.year}';

          final durationMins = data['durationMins'] as int? ?? 60;
          bookingEndTime = bookingDateTime.add(Duration(minutes: durationMins));
        }

        // Auto-update booking status based on time (skip cancelled)
        if (status != 'cancelled' &&
            bookingDateTime != null &&
            bookingEndTime != null) {
          String? newStatus;

          if (now.isBefore(bookingDateTime)) {
            // Future booking
            if (status == 'completed' || status == 'in_progress') {
              newStatus = 'confirmed';
            }
          } else if (now.isAfter(bookingEndTime)) {
            // Past booking - should be completed
            if (status == 'confirmed' || status == 'in_progress') {
              newStatus = 'completed';
            }
          } else {
            // Currently in progress
            if (status != 'in_progress') {
              newStatus = 'in_progress';
            }
          }

          if (newStatus != null) {
            try {
              await _firestore.collection('bookings').doc(bookingId).update({
                'status': newStatus,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              debugPrint(
                'Auto-updated booking $bookingId: $status → $newStatus (End: $bookingEndTime)',
              );
            } catch (e) {
              debugPrint('Error updating booking $bookingId: $e');
            }
          }
        }

        // Reset bookingDateTime for display (without duration)
        if (bookingDateStr != null) {
          try {
            final parts = bookingDateStr.split('/');
            if (parts.length == 3) {
              bookingDateTime = DateTime(
                int.parse(parts[2]), // year
                int.parse(parts[0]), // month
                int.parse(parts[1]), // day
              );
            }
          } catch (e) {
            debugPrint('Error resetting booking date: $e');
          }
        }

        // Filter by date match
        if (bookingDateStr == selectedDateStr) {
          // Add booking with placeholder addons
          bookings.add({
            'id': bookingId,
            ...data,
            'bookingDate': bookingDateTime ?? selectedDate,
            'inlineAddons': [],
            'linkedAddons': [],
            'allAddons': [],
          });
        }
      }

      return bookings;
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      rethrow;
    }
  }

  /// Enrich booking with add-ons
  Future<Map<String, dynamic>> enrichBookingWithAddons(
    String bookingId,
    Map<String, dynamic> bookingData,
  ) async {
    try {
      // Parse inline add-ons from booking data
      List<dynamic> inlineAddons = [];
      if (bookingData['addons'] != null) {
        if (bookingData['addons'] is String) {
          try {
            final addonsStr = bookingData['addons'] as String;
            if (addonsStr != '{}' && addonsStr.isNotEmpty) {
              inlineAddons = [];
            }
          } catch (e) {
            debugPrint('Error parsing inline addons: $e');
          }
        } else if (bookingData['addons'] is List) {
          inlineAddons = bookingData['addons'] as List;
        }
      }

      // Get linked purchased add-ons from Firestore
      final linkedAddonsSnapshot = await _firestore
          .collection('purchased_addons')
          .where('bookingId', isEqualTo: bookingId)
          .get();

      final linkedAddons = linkedAddonsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'addonName': data['addonName'],
          'price': data['price'],
          'quantity': data['quantity'] ?? 1,
        };
      }).toList();

      // Calculate duration properly
      final storedDurationHours = bookingData['durationHours'] as int?;
      final storedDurationMins = bookingData['durationMins'] as int?;
      final totalDurationMins = bookingData['totalDurationMins'] as int?;

      int finalDurationHours = 0;
      int finalDurationMins = 0;

      if (storedDurationHours != null && storedDurationMins != null) {
        // If both fields exist, use them directly
        finalDurationHours = storedDurationHours;
        finalDurationMins = storedDurationMins;
      } else if (totalDurationMins != null) {
        // If only total minutes exist, calculate hours and minutes
        finalDurationHours = totalDurationMins ~/ 60;
        finalDurationMins = totalDurationMins % 60;
      }

      return {
        ...bookingData,
        'id': bookingId,
        'bookingDate': (bookingData['bookingDate'] as Timestamp?)?.toDate(),
        'inlineAddons': inlineAddons,
        'linkedAddons': linkedAddons,
        'allAddons': [...inlineAddons, ...linkedAddons],
        'durationHours': finalDurationHours,
        'durationMins': finalDurationMins,
        'totalDurationMins': totalDurationMins ?? 0,
      };
    } catch (e) {
      debugPrint('Error enriching booking with addons: $e');

      // Calculate duration even in error case
      final storedDurationHours = bookingData['durationHours'] as int?;
      final storedDurationMins = bookingData['durationMins'] as int?;
      final totalDurationMins = bookingData['totalDurationMins'] as int?;

      int finalDurationHours = 0;
      int finalDurationMins = 0;

      if (storedDurationHours != null && storedDurationMins != null) {
        finalDurationHours = storedDurationHours;
        finalDurationMins = storedDurationMins;
      } else if (totalDurationMins != null) {
        finalDurationHours = totalDurationMins ~/ 60;
        finalDurationMins = totalDurationMins % 60;
      }

      return {
        ...bookingData,
        'id': bookingId,
        'bookingDate': (bookingData['bookingDate'] as Timestamp?)?.toDate(),
        'inlineAddons': [],
        'linkedAddons': [],
        'allAddons': [],
        'durationHours': finalDurationHours,
        'durationMins': finalDurationMins,
        'totalDurationMins': totalDurationMins ?? 0,
      };
    }
  }

  /// Load workshops and registrations
  Future<Map<String, List<Map<String, dynamic>>>> loadWorkshops() async {
    try {
      final workshopsSnapshot = await _firestore.collection('workshops').get();
      final registrationsSnapshot = await _firestore
          .collection('workshop_registrations')
          .get();

      final workshops = <Map<String, dynamic>>[];
      final registrations = <Map<String, dynamic>>[];

      for (var doc in workshopsSnapshot.docs) {
        workshops.add({'id': doc.id, ...doc.data()});
      }

      for (var doc in registrationsSnapshot.docs) {
        registrations.add({'id': doc.id, ...doc.data()});
      }

      return {'workshops': workshops, 'registrations': registrations};
    } catch (e) {
      debugPrint('Error loading workshops: $e');
      return {'workshops': [], 'registrations': []};
    }
  }
}

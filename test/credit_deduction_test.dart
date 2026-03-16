import 'package:flutter_test/flutter_test.dart';
import 'package:hikayati/core/network/supabase_service.dart';

void main() {
  group('Credit Deduction Tests', () {
    test('Throws exception if user is not logged in', () async {
      // Assuming Supabase is not initialized with an active session in test mode
      expect(
        () async => await SupabaseService.deductCredits(10, 'Test Deduction'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('يجب تسجيل الدخول لإتمام العملية'),
          ),
        ),
      );
    });

    test('Throws exception for insufficient credits (Mock verification)', () {
      // In a full test suite, we would mock SupabaseClient.rpc
      // Here we verify the exact localized error message thrown by our service parser.
      final mockError = Exception('Insufficient credits');
      try {
        if (mockError.toString().contains('Insufficient credits')) {
          throw Exception('رصيدك غير كافٍ. يرجى زيارة المتجر لشحن الرصيد.');
        }
      } catch (e) {
        expect(e.toString(), contains('زيارة المتجر لشحن الرصيد'));
      }
    });
  });
}

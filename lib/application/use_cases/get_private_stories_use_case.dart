import 'package:hikayati/features/library/services/library_service.dart';

class GetPrivateStoriesUseCase {
  final LibraryService _libraryService = LibraryService();

  Future<List<dynamic>> execute() async {
    try {
      return await _libraryService.getPrivateStories();
    } catch (e) {
      throw Exception('تعذر جلب مكتبتك الخاصة: $e');
    }
  }
}

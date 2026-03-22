import 'package:hikayati/features/library/services/library_service.dart';

class GetPublicStoriesUseCase {
  final LibraryService _libraryService = LibraryService();

  Future<List<dynamic>> execute() async {
    try {
      return await _libraryService.getPublicStories();
    } catch (e) {
      throw Exception('تعذر جلب القصص العامة: $e');
    }
  }
}

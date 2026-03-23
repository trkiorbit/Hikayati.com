import 'package:hikayati/features/library/services/library_service.dart';

class DeleteStoryUseCase {
  final LibraryService _libraryService = LibraryService();

  Future<void> execute(String storyId) async {
    try {
      await _libraryService.deleteStory(storyId);
    } catch (e) {
      throw Exception('تعذر حذف القصة: $e');
    }
  }
}

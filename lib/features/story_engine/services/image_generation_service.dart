class ImageGenerationService {
  static const String _baseUrl = 'https://image.pollinations.ai/prompt';

  /// Generates an image URL from Pollinations with specific styling and dimensions.
  /// 
  /// The [prompt] should include the consistent character description.
  /// Example: "$prompt. Pixar 3d animation style, cinematic lighting, 8k rendering"
  static String generateImageUrl({
    required String prompt,
    int width = 1080,
    int height = 1920,
    bool nologo = true, // Remove watermarks
    String style = '3d-model', 
  }) {
    // Ensuring character consistency requires injecting the avatar descriptor in the prompt beforehand (handled by StoryGenerationService).
    // Build the query parameters
    final encodedPrompt = Uri.encodeComponent('$prompt. High quality, masterpiece, children book illustration, $style');
    
    return '$_baseUrl/$encodedPrompt?width=$width&height=$height&nologo=${nologo ? 'true' : 'false'}';
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hikayati/core/network/supabase_service.dart';
import 'package:flutter/foundation.dart';

class LibraryService {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<dynamic>> getPrivateStories() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('المستخدم غير مسجل الدخول.');

    final data = await _client
        .from('stories')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return data;
  }

  Future<int> getStoryCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final data = await _client
        .from('stories')
        .select('id')
        .eq('user_id', userId);

    return (data as List).length;
  }

  /// حذف قصة مع ملفاتها الصوتية من Supabase Storage
  Future<void> deleteStory(String storyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('المستخدم غير مسجل الدخول.');

    // حذف ملفات الصوت من Storage (3 مشاهد كحد أقصى)
    try {
      final filesToDelete = <String>[];
      for (int i = 0; i < 10; i++) {
        filesToDelete.add('$userId/${storyId}_scene_$i.mp3');
      }
      await _client.storage.from('story_audio').remove(filesToDelete);
      debugPrint('[Library] 🗑️ تم حذف ملفات الصوت للقصة $storyId');
    } catch (e) {
      debugPrint('[Library] ⚠️ تعذر حذف ملفات الصوت: $e');
    }

    // حذف القصة من قاعدة البيانات
    await _client
        .from('stories')
        .delete()
        .eq('id', storyId)
        .eq('user_id', userId);

    debugPrint('[Library] ✅ تم حذف القصة $storyId نهائياً');
  }

  /// قصة ليلى والذئب الذكي — قصة المكتبة العامة الافتتاحية
  /// مُدمجة محلياً (assets) إلى أن يتم نقلها لـ public_stories في Supabase
  /// UUID ثابت يسمح للـ purchases.story_id بالعمل
  static const Map<String, dynamic> _laylaWolfStaticStory = {
    'id': '11111111-1111-1111-1111-111111111111',
    'title': 'ليلى والذئب الذكي',
    'summary':
        'في غابة سحرية تعبرها ليلى لإيصال سلة طعام لجدتها، يلتقيها ذئب رمادي غريب يُخيفها في البداية، لكنها تكتشف أنه ليس كما يبدو. قصة دافئة تعلّم الأطفال أن القلب الذكي لا يحكم من أول نظرة.',
    'cover': 'assets/public_library/layla_wolf/images/scene_01.jpeg',
    'price_credits': 10,
    'category': 'مغامرات',
    'voice_type': 'echo',
    'is_static_local': true,
    'scenes_json': [
      {
        'text':
            'في صباح يوم هادئ، وقفت ليلى عند باب بيتها الصغير قرب الغابة. كانت تحمل سلةً صغيرة مليئةً بالخبز الدافئ والعسل لجدتها المحبوبة. نظرت إلى الطريق الطويل، وابتسمت في قلبها، ثم خطت خطوتها الأولى نحو المغامرة.',
        'imageUrl': 'assets/public_library/layla_wolf/images/scene_01.jpeg',
        'audio_url': '',
      },
      {
        'text':
            'دخلت ليلى الغابة الساحرة، والشمس تتسلل بلطف بين الأشجار العالية. لفت انتباهها آثار أقدام كبيرة في التراب، وسمعت صوتاً هادئاً خلف الأشجار. أمسكت سلتها بقوة، وتقدمت بحذر، فضولها أكبر من خوفها.',
        'imageUrl': 'assets/public_library/layla_wolf/images/scene_02.jpeg',
        'audio_url': '',
      },
      {
        'text':
            'فجأةً، ظهر من بين الأشجار ذئبٌ رماديٌ هادئ. ارتجفت ليلى قليلاً، لكنها لاحظت أن عينيه لا تشبهان عيون الوحوش في الحكايات. نظر إليها الذئب بلطف وقال بصوت ناعم: «لا تخافي يا صغيرة، أنا بحاجة إلى مساعدتك».',
        'imageUrl': 'assets/public_library/layla_wolf/images/scene_03.jpeg',
        'audio_url': '',
      },
      {
        'text':
            'أشار الذئب بأنفه نحو الأمام، حيث بدا الجسر الخشبي القديم متكسراً فوق النهر. قال بصوت حزين: «كنت أحرس هذا الطريق كل يوم، لكي لا يمر أحد من هنا فيقع». أدركت ليلى أن الذئب لم يكن عدواً، بل كان حارساً صامتاً يخاف على الناس.',
        'imageUrl': 'assets/public_library/layla_wolf/images/scene_04.jpeg',
        'audio_url': '',
      },
      {
        'text':
            'عملت ليلى والذئب معاً. جمعت الأغصان المتينة، وساعدها الذئب في جرّها بفمه. معاً صنعا طريقاً آمناً صغيراً حول الجسر المكسور. ضحكت ليلى، وربّتت على رأس الذئب بلطف، وقالت: «أنت أذكى صديق قابلته اليوم».',
        'imageUrl': 'assets/public_library/layla_wolf/images/scene_05.jpeg',
        'audio_url': '',
      },
      {
        'text':
            'وصلت ليلى إلى بيت جدتها، ففتحت لها الجدة ذراعيها بابتسامة دافئة. روت ليلى قصة الذئب الذي لم يكن كما تخيلته في البداية. همست الجدة وهي تمسح شعرها: «أجمل الأشياء يا حبيبتي يراها القلبُ الذكي، لا العينُ المتسرعة».',
        'imageUrl': 'assets/public_library/layla_wolf/images/scene_06.jpeg',
        'audio_url': '',
      },
    ],
  };

  Future<List<dynamic>> getPublicStories() async {
    // محاولة جلب القصص من Supabase أولاً
    List<dynamic> remoteStories = [];
    try {
      remoteStories = await _client
          .from('public_stories')
          .select()
          .order('created_at', ascending: false);
    } catch (e) {
      debugPrint('[Library] ⚠️ تعذر جلب القصص العامة من Supabase: $e');
    }

    // دمج قصة ليلى المحلية في المقدمة (إذا لم تكن موجودة في Supabase بنفس الـ ID)
    final laylaId = _laylaWolfStaticStory['id'];
    final hasLaylaInRemote = remoteStories.any((s) => s['id'] == laylaId);
    if (!hasLaylaInRemote) {
      return [_laylaWolfStaticStory, ...remoteStories];
    }

    return remoteStories;
  }

  Future<List<String>> getUnlockedPublicStories() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('purchases')
        .select('story_id')
        .eq('user_id', userId)
        .eq('unlock_type', 'access');

    return (data as List).map((e) => e['story_id'].toString()).toList();
  }
}


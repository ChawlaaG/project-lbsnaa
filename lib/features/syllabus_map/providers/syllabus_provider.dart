import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadre_upsc/features/syllabus_map/services/syllabus_service.dart';
import 'package:cadre_upsc/features/syllabus_map/models/syllabus_model.dart';
import 'package:cadre_upsc/features/auth/providers/user_provider.dart';

final syllabusServiceProvider = Provider((ref) => SyllabusService());

// Provider family to fetch syllabus for a specific region
final syllabusProvider = FutureProvider.family<SyllabusSubject, String>((ref, regionId) async {
  final service = ref.read(syllabusServiceProvider);
  final user = ref.read(userProvider);
  return service.getSyllabusForRegion(regionId, user.uid);
});

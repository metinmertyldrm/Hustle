import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_config.dart';
import '../data/analysis_repository.dart';
import '../domain/analysis.dart';

final repositoryProvider = Provider((ref) => AnalysisRepository(baseUrl: AppConfig.apiBaseUrl));
final analysisProvider = AsyncNotifierProvider<AnalysisController, Analysis?>(AnalysisController.new);
class AnalysisController extends AsyncNotifier<Analysis?> {
  @override Future<Analysis?> build() => ref.read(repositoryProvider).cached();
  Future<void> analyze(String symbol, String interval) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(repositoryProvider).fetch(symbol, interval));
  }
}

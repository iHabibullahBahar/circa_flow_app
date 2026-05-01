import '../config/app_config.dart';
import '../config/api_endpoints.dart';
import '../features/home/data/models/dashboard_response_model.dart';
import '../utils/utils.dart';

class DashboardService {
  DashboardService._();
  static final DashboardService instance = DashboardService._();

  /// Fetches aggregated dashboard data from POST /dashboard.
  FutureEither<DashboardResponse> fetchDashboard() {
    return runTask(() async {
      final response = await AppConfig.dio.post<Map<String, dynamic>>(zDashboardEndpoint);
      final data = response.data;
      if (data == null) {
        throw Exception('Empty response from $zDashboardEndpoint');
      }
      return DashboardResponse.fromJson(data);
    }, requiresNetwork: true);
  }
}

import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/config/api_endpoints.dart';
import 'package:circa_flow_main/src/services/api_service.dart';
import 'package:circa_flow_main/src/shared/models/paginated_result.dart';
import '../models/event_model.dart';

class EventsRepository {
  EventsRepository._();
  static final EventsRepository instance = EventsRepository._();

  final _api = ApiService.instance;

  FutureEither<PaginatedResult<EventModel>> fetchEvents({int page = 1, String type = 'upcoming'}) async {
    final result = await _api.post<Map<String, dynamic>>(
      zEventsEndpoint,
      data: {'page': page, 'per_page': 20, 'type': type},
    );
    return result.map(_mapResult);
  }

  FutureEither<EventModel> fetchEventDetails(int id) async {
    final result = await _api.post<Map<String, dynamic>>(
      zEventsShowEndpoint,
      data: {'id': id},
    );
    return result.map((res) => EventModel.fromJson(res?['data']));
  }

  FutureEither<PaginatedResult<EventModel>> fetchMyEvents({int page = 1}) async {
    final result = await _api.post<Map<String, dynamic>>(
      zMyEventsEndpoint,
      queryParameters: {'page': page, 'per_page': 20},
    );
    return result.map(_mapResult);
  }

  FutureEither<bool> registerForEvent(int eventId) async {
    final result = await _api.post<Map<String, dynamic>>(
      zEventRegisterEndpoint,
      data: {'id': eventId},
    );
    return result.map((_) => true);
  }

  FutureEither<bool> cancelRegistration(int eventId) async {
    final result = await _api.post<Map<String, dynamic>>(
      zEventCancelEndpoint,
      data: {'id': eventId},
    );
    return result.map((_) => true);
  }

  PaginatedResult<EventModel> _mapResult(Map<String, dynamic>? res) {
    if (res == null) {
      return const PaginatedResult(
          items: [], currentPage: 1, lastPage: 1, total: 0);
    }
    final data = res['data'] as List<dynamic>? ?? [];
    final meta = res['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedResult<EventModel>(
      items: data
          .whereType<Map<String, dynamic>>()
          .map(EventModel.fromJson)
          .toList(),
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? data.length,
    );
  }
}

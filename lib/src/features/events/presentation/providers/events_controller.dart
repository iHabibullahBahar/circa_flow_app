import 'package:circa_flow_main/src/imports/imports.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/events_repository.dart';

enum EventTab { upcoming, myEvents, past }

class EventsController extends GetxController {
  final _repo = EventsRepository.instance;
  
  final events = <EventModel>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final hasNextPage = false.obs;
  int _currentPage = 1;

  final currentTab = EventTab.upcoming.obs;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  void setTab(EventTab tab) {
    if (currentTab.value == tab) return;
    currentTab.value = tab;
    refreshData();
  }

  Future<void> refreshData() async {
    if (isLoading.value) return;

    isLoading.value = true;
    hasError.value = false;
    _currentPage = 1;

    final result = await _fetchFromRepo(page: 1);
    result.fold(
      (_) {
        isLoading.value = false;
        hasError.value = true;
      },
      (page) {
        events.assignAll(page.items);
        hasNextPage.value = page.hasNextPage;
        isLoading.value = false;
      },
    );
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasNextPage.value) return;

    isLoading.value = true;
    final result = await _fetchFromRepo(page: _currentPage + 1);
    result.fold(
      (_) => isLoading.value = false,
      (page) {
        _currentPage++;
        events.addAll(page.items);
        hasNextPage.value = page.hasNextPage;
        isLoading.value = false;
      },
    );
  }

  Future<Either<dynamic, PaginatedResult<EventModel>>> _fetchFromRepo({required int page}) {
    switch (currentTab.value) {
      case EventTab.upcoming:
        return _repo.fetchEvents(page: page, type: 'upcoming');
      case EventTab.myEvents:
        return _repo.fetchMyEvents(page: page);
      case EventTab.past:
        return _repo.fetchEvents(page: page, type: 'past');
    }
  }

  Future<void> registerForEvent(EventModel event) async {
    if (event.isRegistered) return;
    
    Get.dialog<void>(const AppLoading(), barrierDismissible: false);
    final result = await _repo.registerForEvent(event.id);
    Get.back<void>();

    result.fold(
      (err) => showGlobalToast(message: err.message, status: 'error'),
      (_) {
        showGlobalToast(message: 'Successfully registered!');
        _updateEventState(event.id, isRegistered: true);
      },
    );
  }

  Future<void> cancelRegistration(EventModel event) async {
    if (!event.isRegistered) return;

    Get.dialog<void>(const AppLoading(), barrierDismissible: false);
    final result = await _repo.cancelRegistration(event.id);
    Get.back<void>();

    result.fold(
      (err) => showGlobalToast(message: err.message, status: 'error'),
      (_) {
        showGlobalToast(message: 'Registration cancelled.');
        _updateEventState(event.id, isRegistered: false);
      },
    );
  }

  void _updateEventState(int eventId, {required bool isRegistered}) {
    final index = events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final event = events[index];
      final updated = EventModel(
        id: event.id,
        title: event.title,
        type: event.type,
        description: event.description,
        coverImage: event.coverImage,
        location: event.location,
        locationUrl: event.locationUrl,
        startsAt: event.startsAt,
        endsAt: event.endsAt,
        isOnline: event.isOnline,
        onlineUrl: event.onlineUrl,
        organizer: event.organizer,
        capacity: event.capacity,
        timezone: event.timezone,
        platform: event.platform,
        registrationEnabled: event.registrationEnabled,
        isRegistered: isRegistered,
        spotsLeft: isRegistered 
            ? (event.spotsLeft != null ? event.spotsLeft! - 1 : null)
            : (event.spotsLeft != null ? event.spotsLeft! + 1 : null),
        links: event.links,
      );
      events[index] = updated;
    }
  }
}

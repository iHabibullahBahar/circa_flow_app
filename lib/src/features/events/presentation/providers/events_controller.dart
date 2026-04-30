import 'package:circa_flow_main/src/imports/imports.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/events_repository.dart';

class EventsController extends GetxController {
  final _repo = EventsRepository.instance;
  
  final events = <EventModel>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final hasNextPage = false.obs;
  int _currentPage = 1;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  Future<void> refreshData() async {
    if (isLoading.value) return;

    // Only show loading UI if list is currently empty
    final isSilent = events.isNotEmpty;
    if (!isSilent) {
      isLoading.value = true;
    }
    hasError.value = false;
    _currentPage = 1;

    final result = await _repo.fetchEvents(page: 1);
    result.fold(
      (_) {
        if (!isSilent) {
          isLoading.value = false;
          hasError.value = true;
        }
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
    final result = await _repo.fetchEvents(page: _currentPage + 1);
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
}

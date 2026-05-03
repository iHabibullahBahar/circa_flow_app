import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';
import '../../data/models/community_model.dart';
import '../../data/repositories/community_repository.dart';
import '../widgets/community_card.dart';

class CommunityController extends GetxController {
  final CommunityRepository _repository;

  CommunityController(this._repository);

  // State
  final RxList<CommunityModel> allCommunities = <CommunityModel>[].obs;
  final RxList<CommunityModel> myCommunities = <CommunityModel>[].obs;

  // Filtered state for search
  final RxList<CommunityModel> filteredAllCommunities = <CommunityModel>[].obs;
  final RxList<CommunityModel> filteredMyCommunities = <CommunityModel>[].obs;

  final RxBool isLoadingAll = false.obs;
  final RxBool isLoadingMine = false.obs;
  final RxBool isJoining = false.obs;

  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Re-filter when search query changes
    debounce(searchQuery, (_) => _applyFilter(),
        time: const Duration(milliseconds: 300));

    refreshData();
  }

  void refreshData() {
    fetchMyCommunities();
    fetchAllCommunities();
  }

  Future<void> fetchAllCommunities() async {
    isLoadingAll.value = true;
    final result = await _repository.getAllCommunities();
    result.fold(
      (failure) => showGlobalToast(message: failure.message, status: 'error'),
      (data) {
        allCommunities.assignAll(data);
        _applyFilter();
      },
    );
    isLoadingAll.value = false;
  }

  Future<void> fetchMyCommunities() async {
    isLoadingMine.value = true;
    final result = await _repository.getMyCommunities();
    result.fold(
      (failure) => showGlobalToast(message: failure.message, status: 'error'),
      (data) {
        myCommunities.assignAll(data);
        _applyFilter();
      },
    );
    isLoadingMine.value = false;
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void _applyFilter() {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      filteredAllCommunities.assignAll(allCommunities);
      filteredMyCommunities.assignAll(myCommunities);
      return;
    }

    filteredAllCommunities.assignAll(allCommunities.where((c) =>
        c.name.toLowerCase().contains(query) ||
        c.slug.toLowerCase().contains(query)));

    filteredMyCommunities.assignAll(myCommunities.where((c) =>
        c.name.toLowerCase().contains(query) ||
        c.slug.toLowerCase().contains(query)));
  }

  /// Handles "Join via Code" functionality - Look up and preview
  Future<void> lookupAndJoinCode(String code) async {
    if (code.trim().isEmpty) return;

    isJoining.value = true;
    final lookupResult = await _repository.lookupCommunity(code.trim());

    lookupResult.fold(
      (failure) {
        isJoining.value = false;
        showGlobalToast(
            message: 'No community is available with that code.', status: 'error');
      },
      (community) async {
        isJoining.value = false;

        // If already a member, just tell them.
        if (community.isMember || community.isPending) {
          showGlobalToast(
              message: 'You are already a member or have a pending request.',
              status: 'success');
          return;
        }

        // Show Preview Bottom Sheet
        Get.bottomSheet<void>(
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Get.theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Get.theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Community Found!',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A334D),
                  ),
                ),
                const SizedBox(height: 20),
                CommunityCard(
                  community: community,
                  onJoin: () {
                    Get.back<void>(); // close sheet
                    joinCommunity(community);
                  },
                  onLeave: () {}, // Not applicable here
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          isScrollControlled: true,
        );
      },
    );
  }

  /// Join directly from the list
  Future<void> joinCommunity(CommunityModel community) async {
    final action = community.joinType == 'open' ? 'Join' : 'Request to join';
    
    AppDialogs.showConfirm(
      title: '$action Community',
      description: 'Are you sure you want to ${action.toLowerCase()} ${community.name}?',
      confirmLabel: community.joinType == 'open' ? 'Join' : 'Request',
      onConfirm: () async {
        isJoining.value = true;
        final result = await _repository.joinCommunity(community.id);
        isJoining.value = false;

        result.fold(
          (failure) => showGlobalToast(message: failure.message, status: 'error'),
          (data) {
            showGlobalToast(
                message: data['message'] ?? 'Joined successfully',
                status: 'success');
            refreshData();
          },
        );
      },
    );
  }

  /// Leave community
  Future<void> leaveCommunity(CommunityModel community) async {
    AppDialogs.showConfirm(
      title: 'Leave Community',
      description: 'Are you sure you want to leave ${community.name}?',
      confirmVariant: ButtonVariant.danger,
      confirmLabel: 'Leave',
      onConfirm: () async {
        isJoining.value = true;
        final result = await _repository.leaveCommunity(community.id);
        isJoining.value = false;

        result.fold(
          (failure) =>
              showGlobalToast(message: failure.message, status: 'error'),
          (_) {
            showGlobalToast(message: 'Left community.', status: 'success');
            refreshData();
          },
        );
      },
    );
  }
}

import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';
import '../../data/models/community_model.dart';
import '../../data/repositories/community_repository.dart';
import '../widgets/community_card.dart';

enum CommunityTab { myCommunities, discover }

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
  final RxBool isLookingUp = false.obs;
  final RxString lookupError = ''.obs;
  final Rxn<CommunityModel> foundCommunity = Rxn<CommunityModel>();

  final RxString searchQuery = ''.obs;
  final Rx<CommunityTab> currentTab = CommunityTab.myCommunities.obs;

  @override
  void onInit() {
    super.onInit();
    // Re-filter when search query changes
    debounce(searchQuery, (_) => _applyFilter(),
        time: const Duration(milliseconds: 300));

    refreshData();
  }

  void setTab(CommunityTab tab) {
    currentTab.value = tab;
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

    isLookingUp.value = true;
    lookupError.value = '';
    foundCommunity.value = null;
    
    final lookupResult = await _repository.lookupCommunity(code.trim());

    lookupResult.fold(
      (failure) {
        isLookingUp.value = false;
        lookupError.value = 'No community is available with that code.';
      },
      (community) async {
        isLookingUp.value = false;

        // If already a member, just tell them.
        if (community.isMember || community.isPending) {
          lookupError.value = 'You are already a member or have a pending request.';
          return;
        }

        // Set found community - the UI will reactively show the preview
        foundCommunity.value = community;
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

  /// Leave or Withdraw request
  Future<void> leaveCommunity(CommunityModel community) async {
    final isPending = community.isPending;
    final title = isPending ? 'Withdraw Request' : 'Leave Community';
    final description = isPending 
        ? 'Are you sure you want to withdraw your join request for ${community.name}?'
        : 'Are you sure you want to leave ${community.name}?';
    final confirmLabel = isPending ? 'Withdraw' : 'Leave';
    final successMessage = isPending ? 'Request withdrawn.' : 'Left community.';

    AppDialogs.showConfirm(
      title: title,
      description: description,
      confirmVariant: ButtonVariant.danger,
      confirmLabel: confirmLabel,
      onConfirm: () async {
        isJoining.value = true;
        final result = await _repository.leaveCommunity(community.id);
        isJoining.value = false;

        result.fold(
          (failure) =>
              showGlobalToast(message: failure.message, status: 'error'),
          (_) {
            showGlobalToast(message: successMessage, status: 'success');
            refreshData();
          },
        );
      },
    );
  }
}

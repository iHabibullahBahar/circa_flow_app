import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/services/api_service.dart';
import '../models/community_model.dart';

abstract class CommunityRepository {
  FutureEither<List<CommunityModel>> getAllCommunities();
  FutureEither<List<CommunityModel>> getMyCommunities();
  FutureEither<CommunityModel> lookupCommunity(String code);
  FutureEither<Map<String, dynamic>> joinCommunity(int id);
  FutureEither<void> leaveCommunity(int id);
}

class CommunityRepositoryImpl implements CommunityRepository {
  final ApiService _apiService = ApiService.instance;

  @override
  FutureEither<List<CommunityModel>> getAllCommunities() async {
    final result = await _apiService.post<dynamic>('/communities');
    return result.map((response) {
      final data = (response as Map<String, dynamic>)['data'] as List<dynamic>;
      return data
          .map((e) => CommunityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  FutureEither<List<CommunityModel>> getMyCommunities() async {
    final result = await _apiService.post<dynamic>('/communities/mine');
    return result.map((response) {
      final data = (response as Map<String, dynamic>)['data'] as List<dynamic>;
      return data
          .map((e) => CommunityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  FutureEither<CommunityModel> lookupCommunity(String code) async {
    final result = await _apiService
        .post<dynamic>('/communities/lookup', data: {'code': code});
    return result.map((response) {
      final data =
          (response as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return CommunityModel.fromJson(data);
    });
  }

  @override
  FutureEither<Map<String, dynamic>> joinCommunity(int id) async {
    final result =
        await _apiService.post<dynamic>('/communities/$id/join');
    return result.map((response) {
      return (response as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    });
  }

  @override
  FutureEither<void> leaveCommunity(int id) async {
    return _apiService.post<dynamic>('/communities/$id/leave');
  }
}

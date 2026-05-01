import 'package:equatable/equatable.dart';

/// Domain entity representing the authenticated member.
/// Maps from the backend MemberResource response.
class AppUser extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? photoUrl;
  final String? role;
  final int? organizationId;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.photoUrl,
    this.role,
    this.organizationId,
    this.isActive = true,
  });

  factory AppUser.empty() => const AppUser(id: '', email: '');

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  String get displayName => name ?? email;

  @override
  List<Object?> get props => [id, email, name, phone, photoUrl, role, organizationId, isActive];
}

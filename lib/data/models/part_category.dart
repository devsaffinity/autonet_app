import 'package:autonect/data/models/auth_user.dart' show jsonString;

/// `GET /v1/categories` — exactly the three columns the route returns.
///
/// No `children` array: the route is named "tree" everywhere but returns a FLAT
/// array ordered by name (profile.routes.ts:63 is a bare `findMany`). Nesting
/// is expressed only by [parentId].
class PartCategory {
  const PartCategory({required this.id, required this.name, this.parentId});

  final String id;
  final String name;
  final String? parentId;

  factory PartCategory.fromJson(Map<String, dynamic> j) => PartCategory(
    id: jsonString(j, 'id'),
    name: jsonString(j, 'name'),
    parentId: j['parentId'] as String?,
  );
}

/// The select-limited `{id, name}` category embedded in every request payload
/// (REQUEST_INCLUDE in requests.service.ts:19). Deliberately not [PartCategory]:
/// this projection has no `parentId`, and a nullable one would hide that.
class RequestCategoryRef {
  const RequestCategoryRef({required this.id, required this.name});

  final String id;
  final String name;

  factory RequestCategoryRef.fromJson(Map<String, dynamic> j) =>
      RequestCategoryRef(id: jsonString(j, 'id'), name: jsonString(j, 'name'));
}

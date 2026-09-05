import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/repositories/catalog_repository.dart';
import 'package:autonect/domain/select_option.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:get/get.dart';

/// The wizard's category list. The ONLY permanent buyer controller: the list is
/// public reference data the server itself caches for 24h, so re-fetching it
/// every time the picker opens spends the 300/60s limiter on nothing.
class CatalogController extends ApiController {
  CatalogController(this._repo, {super.toast, super.showBusy, super.hideBusy});

  final CatalogRepository _repo;

  static CatalogController get to => Get.find<CatalogController>();

  static CatalogController ensure() => Get.isRegistered<CatalogController>()
      ? Get.find<CatalogController>()
      : Get.put(
          CatalogController(Get.find<CatalogRepository>()),
          permanent: true,
        );

  /// Admin category writes have no cycle or depth check anywhere in the
  /// backend, so the traversal below must survive both.
  static const int _maxDepth = 8;

  static const StateSlot _categoriesRead = StateSlot('categories');

  final Rx<ViewState<List<PartCategory>>> categories =
      Rx<ViewState<List<PartCategory>>>(const Loading());

  List<PartCategory> get all => switch (categories.value) {
    Data<List<PartCategory>>(:final value) => value,
    _ => const [],
  };

  /// Every node is a legal `categoryId`: the server does a bare `findUnique`
  /// and never inspects children, so there is no leaf-only rule to impose.
  List<SelectOption<String>> get options => [
    for (final c in all) SelectOption(c.id, c.name),
  ];

  /// [runRead], NOT [run]. This controller is `permanent: true`, and the sheet
  /// offers Try again as `load(forceRefresh: true)` — so a retry tapped while
  /// the first read was still in flight was DROPPED, wrote the non-retryable
  /// 'Please wait for the current action to finish.' over the list, and left it
  /// there for the rest of the session: the one control that could have cleared
  /// it was the button that panel no longer draws.
  Future<void> load({bool forceRefresh = false}) => runRead(
    _categoriesRead,
    () => _repo.categories(forceRefresh: forceRefresh),
    (r) {
      switch (r) {
        case Err(:final error):
          categories.value = Failed<List<PartCategory>>(error);
        case Ok(:final value):
          categories.value = value.isEmpty
              ? const Empty<List<PartCategory>>('No categories yet')
              : Data<List<PartCategory>>(_ordered(value));
      }
    },
  );

  /// Client-side on purpose: `GET /v1/categories` takes no query parameters at
  /// all, so a keystroke must never become a request.
  List<PartCategory> filter(String q) {
    final needle = q.trim().toLowerCase();
    if (needle.isEmpty) return all;
    return [
      for (final c in all)
        if (c.name.toLowerCase().contains(needle)) c,
    ];
  }

  /// Roots first, each followed by its descendants. The flat wire array is
  /// ordered by name only, which interleaves children with unrelated roots.
  static List<PartCategory> _ordered(List<PartCategory> src) {
    final ids = {for (final c in src) c.id};
    final byParent = <String?, List<PartCategory>>{};
    for (final c in src) {
      final p = c.parentId;
      final key = p != null && ids.contains(p) ? p : null;
      byParent.putIfAbsent(key, () => []).add(c);
    }
    final seen = <String>{};
    final out = <PartCategory>[];
    void walk(String? parent, int depth) {
      if (depth > _maxDepth) return;
      for (final c in byParent[parent] ?? const <PartCategory>[]) {
        if (!seen.add(c.id)) continue;
        out.add(c);
        walk(c.id, depth + 1);
      }
    }

    walk(null, 0);
    // A node inside a parentId cycle is reachable from no root, yet it is still
    // a legal categoryId — dropping it would make a real category unpickable.
    for (final c in src) {
      if (seen.add(c.id)) out.add(c);
    }
    return out;
  }
}

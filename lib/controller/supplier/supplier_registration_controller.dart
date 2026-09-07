import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/controller/buyer/catalog_controller.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:get/get.dart';

/// Owns the supplier registration wizard's answers across all five steps.
///
/// It exists because the wizard is five sibling screens inside one PageView:
/// nothing survives a page change if each step keeps its own state, which is
/// why the shipped wizard collected nothing and posted nothing. The steps read
/// and write here; only this controller talks to the repository.
///
/// It is NOT a session singleton like the buyer controllers — see [ensure].
class SupplierRegistrationController extends ApiController {
  SupplierRegistrationController(this._repo);

  /// Fresh per wizard, deliberately. A half-filled draft from an abandoned
  /// registration must not reappear the next time the wizard opens, and unlike
  /// the buyer controllers this one is not addressed by an entity id, so
  /// `beginEntity` has nothing to key on.
  static SupplierRegistrationController ensure() {
    if (Get.isRegistered<SupplierRegistrationController>()) {
      Get.delete<SupplierRegistrationController>(force: true);
    }
    return Get.put(
      SupplierRegistrationController(Get.find<ProfileRepository>()),
    );
  }

  final ProfileRepository _repo;


  // ── Step 1: company profile ────────────────────────────────────────────────
  final RxString businessName = ''.obs;
  final RxString address = ''.obs;

  // ── Step 2: coverage ───────────────────────────────────────────────────────
  /// The server requires at least one. Seeded empty rather than with a default
  /// pick, so a supplier cannot skip the step and silently serve London only.
  final RxList<Region> regionsServed = <Region>[].obs;

  // ── Step 3: specialization ─────────────────────────────────────────────────
  final RxList<String> brands = <String>[].obs;
  final RxList<String> categoryIds = <String>[].obs;

  /// The category list comes from [CatalogController], not from here.
  ///
  /// It is `permanent`, memoises the response for the session and already owns
  /// the Loading/Empty/Failed states and the retry — the buyer wizard picks a
  /// category from exactly the same list. A second read here would spend the
  /// rate limiter on data the app already holds, and would drift.
  ///
  /// This controller owns only the SELECTION, in [categoryIds].
  ///
  /// The step this feeds previously offered ten hard-coded category NAMES,
  /// which are not ids and did not match the seeded taxonomy, so nothing it
  /// collected could ever have been submitted.
  CatalogController get catalog => CatalogController.ensure();

  // ── Result ─────────────────────────────────────────────────────────────────
  /// The profile the server returned from the submission. Its `kycStatus` and
  /// `approved` decide which screen the supplier lands on next, so the wizard
  /// reads this rather than assuming success means approved.
  final Rxn<MeProfile> submitted = Rxn<MeProfile>();

  SupplierBusinessDraft get draft => SupplierBusinessDraft(
    businessName: businessName.value,
    address: address.value,
    regionsServed: regionsServed.toList(),
    categoryIds: categoryIds.toList(),
    brands: brands.toList(),
  );

  bool get canSubmit => draft.isComplete;

  /// Which step is still incomplete, or null when the draft is submittable.
  ///
  /// Returned as a message rather than a bool so the wizard can say what is
  /// missing. The server would 400 on any of these, and a validation error
  /// surfacing on the final step gives no clue which of five screens to go back
  /// to.
  String? get blockingReason {
    if (businessName.value.trim().isEmpty) return 'Add your business name';
    if (address.value.trim().isEmpty) return 'Add your business address';
    if (regionsServed.isEmpty) return 'Pick at least one region you serve';
    if (categoryIds.isEmpty) return 'Pick at least one part category';
    return null;
  }

  void toggleRegion(Region r) =>
      regionsServed.contains(r) ? regionsServed.remove(r) : regionsServed.add(r);

  void toggleBrand(String b) =>
      brands.contains(b) ? brands.remove(b) : brands.add(b);

  void toggleCategory(String id) =>
      categoryIds.contains(id) ? categoryIds.remove(id) : categoryIds.add(id);

  /// Submits the registration.
  ///
  /// Goes through [run], so a second tap while the first is in flight is
  /// DROPPED rather than creating a second registration — the upsert is
  /// idempotent server-side, but the drop also stops the wizard finishing twice
  /// and pushing two screens.
  ///
  /// Returns the profile on success and null on failure, having already
  /// surfaced the error; the caller navigates only on a non-null result.
  Future<MeProfile?> submit() {
    final blocked = blockingReason;
    if (blocked != null) {
      formError.value = blocked;
      return Future.value(null);
    }
    return run<MeProfile, MeProfile?>(
      null,
      () => _repo.registerSupplierBusiness(draft),
      (r) => switch (r) {
        Ok(:final value) => submitted.value = value,
        // absorb() has already turned the error into a banner or field errors.
        Err() => null,
      },
    );
  }
}

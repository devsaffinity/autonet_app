import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:get/get.dart';

/// The electrician registration wizard — `POST /v1/electrician/registration`.
///
/// Mirrors SupplierRegistrationController exactly, because the two wizards are
/// the same shape: state accumulated across several screens, submitted once at
/// the end, and the SERVER'S answer decides where the provider lands.
///
/// Before this existed the wizard submitted NOTHING. Five steps of state were
/// discarded on finish, and it set a local `providerOnboarded` flag instead —
/// which, once the approval gate started reading server truth, meant the next
/// launch found no profile and sent them back to the wizard. It looped.
class ElectricianRegistrationController extends ApiController {
  ElectricianRegistrationController(
    this._repo, {
    super.toast,
    super.showBusy,
    super.hideBusy,
  });

  final ProfileRepository _repo;

  static ElectricianRegistrationController ensure() =>
      Get.isRegistered<ElectricianRegistrationController>()
      ? Get.find<ElectricianRegistrationController>()
      : Get.put(
          ElectricianRegistrationController(Get.find<ProfileRepository>()),
        );

  // ── Step 1: who they are ───────────────────────────────────────────────────
  final RxString fullName = ''.obs;
  final RxString phone = ''.obs;
  final RxString location = ''.obs;
  final Rxn<Region> region = Rxn<Region>();

  // ── Step 2: what they do ───────────────────────────────────────────────────
  /// The callouts they take. Seeded with nothing: a pre-ticked service is a
  /// claim about them they never made, and it is the field the buyer's filters
  /// use to decide who to show.
  final RxSet<BookingServiceType> services = <BookingServiceType>{}.obs;

  /// What they do it TO. A LIST, because a provider realistically services
  /// several marques — the wizard offered a single choice, which the column
  /// never was.
  final RxSet<String> brands = <String>{}.obs;

  final RxInt yearsExperience = 0.obs;

  // ── Step 3 on the EDIT screen: how they describe themselves ────────────────
  /// The trade line under their name on the buyer's directory card.
  final RxString headline = ''.obs;

  /// The profile's 'Expertise Profile' paragraph.
  final RxString bio = ''.obs;

  /// The design's '1240+ Vehicles Serviced'. Null rather than 0 when they have
  /// not said — claiming zero vehicles serviced is worse than saying nothing.
  final Rxn<int> vehiclesServiced = Rxn<int>();

  /// Access tier preference ('FREE', 'PRO', 'PAY_PER_LEAD').
  final RxString tier = 'FREE'.obs;

  // ── Result ─────────────────────────────────────────────────────────────────
  /// What the server returned. Its `approved` flag decides the landing screen,
  /// so the wizard reads this rather than assuming registration means approved
  /// — it does not; an admin still has to approve.
  final Rxn<MeProfile> submitted = Rxn<MeProfile>();

  void toggleService(BookingServiceType s) =>
      services.contains(s) ? services.remove(s) : services.add(s);

  void toggleBrand(String b) =>
      brands.contains(b) ? brands.remove(b) : brands.add(b);

  void setExperience(int years) => yearsExperience.value = years;

  /// Load an existing profile into the form.
  ///
  /// THE ENDPOINT IS AN UPSERT, so editing is the same call as registering and
  /// this controller serves both screens. That is also why pre-filling matters:
  /// a partial submit REPLACES the row, so anything not loaded here would be
  /// cleared by the next save.
  void prefillFrom(ElectricianProfile p) {
    fullName.value = p.fullName;
    phone.value = p.phone ?? '';
    location.value = p.location ?? '';
    region.value = p.region;
    yearsExperience.value = p.yearsExperience ?? 0;
    brands
      ..clear()
      ..addAll(p.brands);
    services
      ..clear()
      ..addAll(p.services);
    headline.value = p.headline ?? '';
    bio.value = p.bio ?? '';
    vehiclesServiced.value = p.vehiclesServiced;
    tier.value = p.tier;
  }

  ElectricianRegistrationDraft get draft => ElectricianRegistrationDraft(
    fullName: fullName.value,
    phone: phone.value,
    location: location.value,
    region: region.value,
    yearsExperience: yearsExperience.value,
    brands: brands.toList(),
    services: services.toList(),
    headline: headline.value,
    bio: bio.value,
    vehiclesServiced: vehiclesServiced.value,
    tier: tier.value,
    // Derived from the services rather than collected twice: neither screen has
    // a free-text skills field, and inventing one would put words in the
    // provider's mouth.
    skills: [for (final s in services) s.label],
  );

  /// Which step is still incomplete, or null when the draft can be submitted.
  ///
  /// A message rather than a bool so the wizard can say WHAT is missing: a 400
  /// surfacing on the last step gives no clue which of four screens to go back
  /// to.
  String? get blockingReason {
    if (fullName.value.trim().isEmpty) return 'Add your full name';
    if (services.isEmpty) return 'Pick at least one service you offer';
    return null;
  }

  bool get canSubmit => blockingReason == null;

  /// Submit.
  ///
  /// Goes through [run], so a second tap while the first is in flight is
  /// DROPPED. The upsert is idempotent server-side, but the drop is also what
  /// stops the wizard finishing twice and pushing two screens.
  ///
  /// Returns the profile on success and null on failure, having already
  /// surfaced the error. The caller navigates only on a non-null result.
  Future<MeProfile?> submit() {
    final blocked = blockingReason;
    if (blocked != null) {
      formError.value = blocked;
      return Future<MeProfile?>.value(null);
    }
    return run<MeProfile, MeProfile?>(
      null,
      () => _repo.registerElectrician(draft),
      (r) => switch (r) {
        Ok(:final value) => submitted.value = value,
        Err() => null,
      },
    );
  }
}

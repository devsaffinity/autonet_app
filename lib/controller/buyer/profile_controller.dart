import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/blob_uploader.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/electrician_service.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/upload_ticket.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/services/image_picker_service.dart';
import 'package:get/get.dart';

/// The user's own profile, and the avatar upload.
///
/// PERMANENT: the avatar is drawn in Home's header as well as on Profile, so a
/// per-visit controller would mean the header kept showing the old picture
/// until the app restarted.
class ProfileController extends ApiController {
  ProfileController(
    this._repo, {
    BlobUploader? uploader,
    ImagePickerService? picker,
    super.toast,
    super.showBusy,
    super.hideBusy,
  }) : _injectedUploader = uploader,
       _injectedPicker = picker;

  static ProfileController get to => Get.find<ProfileController>();

  static ProfileController ensure() => Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(
          ProfileController(
            Get.isRegistered<ProfileRepository>()
                ? Get.find<ProfileRepository>()
                : const _StubProfileRepository(),
          ),
          permanent: true,
        );

  static ProfileController? maybeFind() =>
      Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : null;

  final ProfileRepository _repo;

  final BlobUploader? _injectedUploader;
  final ImagePickerService? _injectedPicker;

  /// Resolved LAZILY, on the first upload — not in the constructor.
  ///
  /// Home reads `avatarUrl` from this controller and nothing else, so
  /// constructing it must not require the whole upload stack. It did, and
  /// mounting the buyer shell in a test then failed on a missing BlobUploader
  /// before a single assertion ran — which is the same coupling a screen would
  /// hit if it only ever wanted to draw the picture.
  BlobUploader get _uploader => _injectedUploader ?? Get.find<BlobUploader>();

  ImagePickerService get _picker =>
      _injectedPicker ?? Get.find<ImagePickerService>();

  static const StateSlot _meRead = StateSlot('me');

  final Rx<ViewState<MeProfile>> profile = Rx<ViewState<MeProfile>>(
    const Loading(),
  );

  final RxBool uploadingAvatar = false.obs;

  MeProfile? get me => switch (profile.value) {
    Data<MeProfile>(:final value) => value,
    _ => null,
  };

  /// A PRESIGNED url with a short TTL, so it is read fresh from the last
  /// profile response rather than cached anywhere.
  String? get avatarUrl => me?.avatarUrl;

  Future<void> load() => runRead(_meRead, _repo.me, (r) {
    switch (r) {
      case Err(:final error):
        profile.value = Failed<MeProfile>(error);
      case Ok(:final value):
        profile.value = Data<MeProfile>(value);
    }
  });

  /// Pick → ticket → PUT → save.
  ///
  /// The last call is what makes it stick: the S3 object is worthless until
  /// `PUT /v1/me/profile` records its key, so a failure between the upload and
  /// the save leaves an orphaned object and the OLD avatar, which is the right
  /// way round.
  Future<void> changeAvatar() async {
    if (uploadingAvatar.value) return;

    // remaining: 1 — this is a single image, and the picker's multi-image path
    // is rejected by some plugin versions at a limit of one.
    final picked = await _picker.pick(remaining: 1);
    final image = picked.firstOrNull;
    if (image == null) return;

    uploadingAvatar.value = true;
    clearErrors();
    try {
      final UploadTicket ticket;
      switch (await _repo.createAvatarUploadTicket(image.contentType)) {
        case Err(:final error):
          absorb(error);
          return;
        case Ok(:final value):
          ticket = value;
      }

      switch (await _uploader.put(
        url: ticket.url,
        bytes: image.bytes,
        contentType: image.contentType,
      )) {
        case Err(:final error):
          absorb(error);
          return;
        case Ok():
          break;
      }

      switch (await _repo.setAvatar(ticket.key)) {
        case Err(:final error):
          absorb(error);
        case Ok(:final value):
          // The response carries a freshly presigned avatarUrl, so the header
          // repaints without a second read.
          profile.value = Data<MeProfile>(value);
          toast('Profile photo updated');
      }
    } finally {
      uploadingAvatar.value = false;
    }
  }

  final RxBool savingProfile = false.obs;

  /// Updates profile details (name, location, contact, optional new avatar).
  ///
  /// If [newAvatar] is provided, it is uploaded to S3 first, then its key is
  /// passed to `PUT /v1/me/profile`.
  Future<bool> updateProfileDetails({
    required String name,
    String? location,
    String? contact,
    PickedImage? newAvatar,
  }) async {
    if (savingProfile.value) return false;
    savingProfile.value = true;
    clearErrors();
    try {
      String? avatarKey;
      if (newAvatar != null) {
        final UploadTicket ticket;
        switch (await _repo.createAvatarUploadTicket(newAvatar.contentType)) {
          case Err(:final error):
            absorb(error);
            return false;
          case Ok(:final value):
            ticket = value;
        }

        switch (await _uploader.put(
          url: ticket.url,
          bytes: newAvatar.bytes,
          contentType: newAvatar.contentType,
        )) {
          case Err(:final error):
            absorb(error);
            return false;
          case Ok():
            avatarKey = ticket.key;
            break;
        }
      }

      switch (await _repo.updateProfile(
        name: name,
        location: location,
        contact: contact,
        avatarKey: avatarKey,
      )) {
        case Err(:final error):
          absorb(error);
          return false;
        case Ok(:final value):
          profile.value = Data<MeProfile>(value);
          if (Get.isRegistered<TokenStore>()) {
            final store = Get.find<TokenStore>();
            final u = store.user;
            if (u != null && value.name != null) {
              store.updateUser(u.copyWith(name: value.name));
            }
          }
          toast('Profile updated');
          return true;
      }
    } finally {
      savingProfile.value = false;
    }
  }

  /// Updates the electrician's access tier preference ('FREE', 'PRO', 'PAY_PER_LEAD').
  Future<bool> updateElectricianTier(String tier) => run<MeProfile, bool>(
    null,
    () => _repo.updateElectricianTier(tier),
    (r) {
      if (r case Ok(:final value)) {
        profile.value = Data<MeProfile>(value);
        return true;
      }
      return false;
    },
  );
}

/// Fallback repository used when ProfileController is instantiated in isolated
/// widget tests that did not bind a ProfileRepository.
class _StubProfileRepository implements ProfileRepository {
  const _StubProfileRepository();

  @override
  Future<ApiResult<MeProfile>> me() async =>
      const Err(ApiError.malformed('Profile repository not registered'));

  @override
  Future<ApiResult<MeProfile>> registerSupplierBusiness(
    SupplierBusinessDraft draft,
  ) async => const Err(ApiError.malformed('Profile repository not registered'));

  @override
  Future<ApiResult<MeProfile>> registerElectrician(
    ElectricianRegistrationDraft draft,
  ) async => const Err(ApiError.malformed('Profile repository not registered'));

  @override
  Future<ApiResult<MeProfile>> updateElectricianTier(String tier) async =>
      const Err(ApiError.malformed('Profile repository not registered'));

  @override
  Future<ApiResult<UploadTicket>> createAvatarUploadTicket(
    String contentType,
  ) async => const Err(ApiError.malformed('Profile repository not registered'));

  @override
  Future<ApiResult<MeProfile>> setAvatar(String avatarKey) async =>
      const Err(ApiError.malformed('Profile repository not registered'));

  @override
  Future<ApiResult<MeProfile>> updateProfile({
    String? name,
    String? location,
    String? contact,
    String? avatarKey,
  }) async => const Err(ApiError.malformed('Profile repository not registered'));

  @override
  Future<ApiResult<List<ElectricianService>>> getElectricianServices() async =>
      const Err(ApiError.malformed('Profile repository not registered'));

  @override
  Future<ApiResult<ElectricianService>> createElectricianService({
    required String name,
    required String price,
    required String pricingType,
    String? description,
    BookingServiceType? serviceType,
  }) async => const Err(ApiError.malformed('Profile repository not registered'));

  @override
  Future<ApiResult<ElectricianService>> updateElectricianService({
    required String id,
    String? name,
    String? price,
    String? pricingType,
    String? description,
    BookingServiceType? serviceType,
    bool? isActive,
  }) async => const Err(ApiError.malformed('Profile repository not registered'));

  @override
  Future<ApiResult<void>> deleteElectricianService(String id) async =>
      const Err(ApiError.malformed('Profile repository not registered'));
}


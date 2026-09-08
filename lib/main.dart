import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/config/theme/light_theme.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_config.dart';
import 'package:autonect/data/core/blob_uploader.dart';
import 'package:autonect/data/core/http_transport_impl.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/repositories/auth_api_repository.dart';
import 'package:autonect/data/repositories/auth_repository.dart';
import 'package:autonect/data/repositories/billing_api_repository.dart';
import 'package:autonect/data/repositories/billing_repository.dart';
import 'package:autonect/data/repositories/catalog_api_repository.dart';
import 'package:autonect/data/repositories/catalog_repository.dart';
import 'package:autonect/data/repositories/kyc_api_repository.dart';
import 'package:autonect/data/repositories/kyc_repository.dart';
import 'package:autonect/data/repositories/notifications_api_repository.dart';
import 'package:autonect/data/repositories/notifications_repository.dart';
import 'package:autonect/data/repositories/orders_api_repository.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:autonect/data/repositories/profile_api_repository.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:autonect/data/repositories/requests_api_repository.dart';
import 'package:autonect/data/repositories/requests_repository.dart';
import 'package:autonect/data/repositories/reviews_api_repository.dart';
import 'package:autonect/data/repositories/reviews_repository.dart';
import 'package:autonect/data/repositories/vehicles_api_repository.dart';
import 'package:autonect/data/repositories/vehicles_repository.dart';
import 'package:autonect/services/document_picker_service.dart';
import 'package:autonect/services/image_picker_service.dart';
import 'package:autonect/services/session_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must precede everything: RoleController.onInit and PrefsTokenStore both
  // read the store synchronously, which is what lets SplashScreen decide with
  // no await.
  await SessionStore.init();
  final tokens = PrefsTokenStore();
  // Hoisted so BlobUploader can share it. One transport, one connection pool —
  // and BlobUploader still bypasses ApiClient entirely, because a presigned S3
  // PUT must carry no authorization header and its 403s must never reach the
  // refresh machinery.
  final transport = HttpClientTransport(
    timeout: ApiConfig.fromEnvironment.timeout,
  );
  final client = ApiClient(
    transport: transport,
    baseUrl: ApiConfig.fromEnvironment.baseUrl,
    tokens: tokens,
    onSessionExpired: () async {
      RoleController.to.forceSignOut();
    },
  );
  Get.put<TokenStore>(tokens, permanent: true);
  // permanent AND singular is LOAD-BEARING, not hygiene: two ApiClients are two
  // _refreshFuture fields are two concurrent refreshes are revokeFamily(), and
  // the user is hard-logged-out of every device. Construct it here and nowhere
  // else.
  Get.put<ApiClient>(client, permanent: true);
  Get.put<AuthRepository>(AuthApiRepository(client, tokens), permanent: true);
  // Every repository is registered against its ABSTRACT type: screens and
  // controllers resolve the seam, never the HTTP implementation, which is what
  // lets a widget test swap in a fake with no transport at all.
  Get.put<CatalogRepository>(
    CatalogApiRepository(client, tokens),
    permanent: true,
  );
  Get.put<VehiclesRepository>(
    VehiclesApiRepository(client, tokens),
    permanent: true,
  );
  Get.put<RequestsRepository>(
    RequestsApiRepository(client, tokens),
    permanent: true,
  );
  Get.put<OrdersRepository>(
    OrdersApiRepository(client, tokens),
    permanent: true,
  );
  Get.put<ReviewsRepository>(
    ReviewsApiRepository(client, tokens),
    permanent: true,
  );
  // Registered before RoleController below, which reads it to decide a
  // provider's landing route from server truth rather than local storage.
  Get.put<ProfileRepository>(
    ProfileApiRepository(client, tokens),
    permanent: true,
  );
  Get.put<KycRepository>(KycApiRepository(client, tokens), permanent: true);
  Get.put<BillingRepository>(
    BillingApiRepository(client, tokens),
    permanent: true,
  );
  Get.put<NotificationsRepository>(
    NotificationsApiRepository(client, tokens),
    permanent: true,
  );
  Get.put<BlobUploader>(BlobUploader(transport), permanent: true);
  Get.put<ImagePickerService>(DeviceImagePickerService(), permanent: true);
  Get.put<DocumentPickerService>(
    const DeviceDocumentPickerService(),
    permanent: true,
  );
  Get.put(RoleController(), permanent: true);
  runApp(MyApp());
}

//DO NOT REMOVE Unless you find their usage.
String dummyImg =
    'https://images.unsplash.com/photo-1558507652-2d9626c4e67a?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=687&q=80';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      title: 'Autonect',
      theme: lightTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppLinks.splash_screen,
      getPages: AppRoutes.pages,
      // initialBinding: AuthBindings(),
    );
  }
}

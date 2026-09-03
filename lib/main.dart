import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/config/theme/light_theme.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_config.dart';
import 'package:autonect/data/core/http_transport_impl.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/repositories/auth_api_repository.dart';
import 'package:autonect/data/repositories/auth_repository.dart';
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
  final client = ApiClient(
    transport: HttpClientTransport(timeout: ApiConfig.fromEnvironment.timeout),
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

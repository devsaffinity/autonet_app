import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/config/theme/light_theme.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/services/session_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must precede the Get.put: RoleController.onInit hydrates synchronously
  // from the store, which is what lets SplashScreen decide with no await.
  await SessionStore.init();
  // permanent so a future Get.deleteAll() on logout cannot destroy it.
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

import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class RoleController extends GetxController {
  RxInt role = 100.obs; // 0 for service seeker, 1 for contractor
}

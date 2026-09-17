import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/data/repositories/supplier_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupplierCreateOfferController extends ApiController {
  SupplierCreateOfferController({
    required this.requestId,
    this.existingOffer,
    SupplierRepository? repo,
    super.toast,
    super.showBusy,
    super.hideBusy,
  }) : _repo = repo ?? Get.find<SupplierRepository>();

  final String requestId;
  final SupplierOffer? existingOffer;
  final SupplierRepository _repo;

  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '1');
  final TextEditingController warrantyController = TextEditingController(text: '12');
  final TextEditingController deliveryTimeController = TextEditingController(text: '2');
  final TextEditingController notesController = TextEditingController();

  final Rx<PartCondition> condition = PartCondition.newPart.obs;
  final Rx<DeliveryOption> deliveryOption = DeliveryOption.standard.obs;
  final Rx<StockStatus> stockStatus = StockStatus.inStock.obs;

  bool get isEdit => existingOffer != null;

  @override
  void onInit() {
    super.onInit();
    if (existingOffer != null) {
      final o = existingOffer!;
      priceController.text = (o.pricePence / 100).toStringAsFixed(2);
      quantityController.text = '${o.quantity}';
      if (o.warrantyMonths != null) warrantyController.text = '${o.warrantyMonths}';
      if (o.deliveryTimeDays != null) deliveryTimeController.text = '${o.deliveryTimeDays}';
      if (o.notes != null) notesController.text = o.notes!;
      if (o.condition != null) condition.value = o.condition!;
      if (o.deliveryOption != null) deliveryOption.value = o.deliveryOption!;
      if (o.stockStatus != null) stockStatus.value = o.stockStatus!;
    }
  }

  @override
  void onClose() {
    priceController.dispose();
    quantityController.dispose();
    warrantyController.dispose();
    deliveryTimeController.dispose();
    notesController.dispose();
    super.onClose();
  }

  int get pricePence {
    final parsed = double.tryParse(priceController.text.trim()) ?? 0.0;
    return (parsed * 100).round();
  }

  String get formattedPrice {
    final pounds = pricePence / 100;
    return '£${pounds.toStringAsFixed(2)}';
  }

  Future<bool> submit() async {
    final pence = pricePence;
    if (pence <= 0) {
      toast('Please enter a valid price');
      return false;
    }

    final qty = int.tryParse(quantityController.text.trim()) ?? 1;
    if (qty < 1) {
      toast('Quantity must be at least 1');
      return false;
    }

    final warranty = int.tryParse(warrantyController.text.trim());
    final deliveryDays = int.tryParse(deliveryTimeController.text.trim());
    final notes = notesController.text.trim();

    if (isEdit) {
      return run<SupplierOffer, bool>(
        null,
        () => _repo.editOffer(
          offerId: existingOffer!.id,
          pricePence: pence,
          condition: condition.value,
          warrantyMonths: warranty,
          deliveryOption: deliveryOption.value,
          deliveryTimeDays: deliveryDays,
          stockStatus: stockStatus.value,
          quantity: qty,
          notes: notes.isEmpty ? null : notes,
        ),
        (r) {
          switch (r) {
            case Err(:final error):
              toast(error.message);
              return false;
            case Ok():
              return true;
          }
        },
      );
    } else {
      return run<SupplierOffer, bool>(
        null,
        () => _repo.createOffer(
          requestId: requestId,
          pricePence: pence,
          condition: condition.value,
          warrantyMonths: warranty,
          deliveryOption: deliveryOption.value,
          deliveryTimeDays: deliveryDays,
          stockStatus: stockStatus.value,
          quantity: qty,
          notes: notes.isEmpty ? null : notes,
        ),
        (r) {
          switch (r) {
            case Err(:final error):
              toast(error.message);
              return false;
            case Ok():
              return true;
          }
        },
      );
    }
  }
}

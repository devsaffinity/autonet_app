import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_role.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RolePage extends StatefulWidget {
  const RolePage({super.key});

  @override
  State<RolePage> createState() => _RolePageState();
}

class _RolePageState extends State<RolePage> {
  final List<RoleModel> roleList = [
    RoleModel(
      title: "I am a ",
      subTitle: AppRole.buyer.label,
      icon: Assets.imagesRoleA,
      role: AppRole.buyer,
    ),
    RoleModel(
      title: "I am a ",
      subTitle: AppRole.supplier.label,
      icon: Assets.imagesRoleB,
      role: AppRole.supplier,
    ),
    RoleModel(
      title: "I am a ",
      subTitle: AppRole.electrician.label,
      icon: Assets.imagesRoleC,
      role: AppRole.electrician,
    ),
  ];

  AppRole? _selected;
  RoleController roleController = Get.find<RoleController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.DEFAULT,
          child: Column(
            children: [
              // LOGO
              CommonImageView(width: 150, imagePath: Assets.imagesLogo),
              SizedBox(height: 80),

              // OPTIONS
              ...List.generate(roleList.length, (index) {
                final isSelected = roleList[index].role == _selected;
                return Container(
                  width: Get.width,
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: AppStyling().myDecoration(
                    color: isSelected ? kLightOrangeColor : kTertiaryColor,
                    borderColor: isSelected
                        ? kSecondaryColor
                        : kTransperentColor,
                    radius: 10,
                  ),
                  child: InkWell(
                    child: Row(
                      children: [
                        CommonImageView(
                          width: 40,
                          imagePath: roleList[index].icon,
                        ),
                        SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText(
                              text: roleList[index].title,
                              size: 16,
                              weight: FontWeight.w400,
                              color: kGreyTextColor,
                            ),
                            MyText(
                              text: roleList[index].subTitle,
                              size: 18,
                              weight: FontWeight.w600,
                            ),
                          ],
                        ),
                        Spacer(),

                        isSelected
                            ? CommonImageView(
                                width: 25,
                                imagePath: Assets.imagesDoneCheckIcon,
                              )
                            : Container(
                                width: 25,
                                height: 25,
                                decoration: AppStyling().myDecoration(
                                  color: kWhiteColor,
                                  borderColor: kTransperentColor,
                                  radius: 100,
                                ),
                              ),
                      ],
                    ),
                    // Local only — the controller is written on Continue, so
                    // backing out of this screen cannot change a stored role.
                    onTap: () =>
                        setState(() => _selected = roleList[index].role),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavButton(
        buttonText: "Continue",
        onTap: () {
          if (_selected == null) {
            Get.snackbar(
              "Error",
              "Please select a role to continue",
              backgroundColor: kWhiteColor,
            );
            return;
          }
          roleController.selectRole(_selected!);
          Get.toNamed(AppLinks.login);
        },
      ),
    );
  }
}

class RoleModel {
  final String title, subTitle, icon;
  final AppRole role;
  RoleModel({
    required this.title,
    required this.subTitle,
    required this.icon,
    required this.role,
  });
}

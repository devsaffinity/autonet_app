import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/view/screens/auth/login.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

class RolePage extends StatefulWidget {
  const RolePage({super.key});

  @override
  State<RolePage> createState() => _RolePageState();
}

class _RolePageState extends State<RolePage> {
  List<RoleModel> roleList = [
    RoleModel(title: "I am a ", subTitle: "Buyer", icon: Assets.imagesRoleA),
    RoleModel(title: "I am a ", subTitle: "Supplier", icon: Assets.imagesRoleB),
    RoleModel(
      title: "I am a ",
      subTitle: "Electrician/ Coder",
      icon: Assets.imagesRoleC,
    ),
  ];
  int currentIndex = 100;
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
                return Container(
                  width: Get.width,
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: AppStyling().myDecoration(
                    color: (index == currentIndex)
                        ? kTertiaryColor
                        : kTertiaryColor,
                    borderColor: (index == currentIndex)
                        ? kSecondaryColor
                        : kTransperentColor,
                    radius: 10,
                  ),
                  child: InkWell(
                    child: Row(
                      children: [
                        CommonImageView(
                          width: 40,
                          imagePath: roleList[index].icon.toString(),
                        ),
                        SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText(
                              text: roleList[index].title.toString(),
                              size: 16,
                              weight: FontWeight.w400,
                              color: kGreyTextColor,
                            ),
                            MyText(
                              text: roleList[index].subTitle.toString(),
                              size: 18,
                              weight: FontWeight.w600,
                            ),
                          ],
                        ),
                        Spacer(),

                        (currentIndex == index)
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
                    onTap: () {
                      currentIndex = index;
                      roleController.role.value = currentIndex;
                      setState(() {});
                    },
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
          if (currentIndex != 0 && currentIndex != 1) {
            Get.snackbar(
              "Error",
              "Please select a role to continue",
              backgroundColor: kWhiteColor,
            );
            return;
          }
          Get.to(() => LoginPage());
        },
      ),
    );
  }
}

class RoleModel {
  String? title, subTitle, icon;
  RoleModel({this.title, this.subTitle, this.icon});
}

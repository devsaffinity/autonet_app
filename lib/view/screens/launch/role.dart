import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_role.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/screens/auth/register.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Sign-up, step one: which kind of account is being created.
///
/// ALWAYS PUSHED, from Login's "Sign Up" — never the root of the stack. So
/// Back returns to Login, and Back from the form returns HERE with the pick
/// still selected: this State lives on underneath RegisterPage rather than
/// being rebuilt.
///
/// THE PICK IS STORED NOWHERE. It is handed to [RegisterPage] as a required
/// constructor argument and sent once, in the signup body. It used to be
/// written to RoleController and SharedPreferences before any account existed,
/// which is how a choice outlived its screen: the next launch skipped this page
/// and "Sign Up" silently reused the old role, with no way back to change it.
/// Once the account is verified its role comes from the server's token, as for
/// any other sign-in.
class RolePage extends StatefulWidget {
  const RolePage({super.key});

  /// The one way in, so every caller pushes — never clears the stack to it —
  /// and gets the same transition.
  static void open() =>
      Get.to<void>(() => const RolePage(), transition: Transition.rightToLeft);

  @override
  State<RolePage> createState() => _RolePageState();
}

class _RolePageState extends State<RolePage> {
  static final List<RoleModel> _options = [
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

  void _continue(AppRole role) => Get.to<void>(
    () => RegisterPage(role: role),
    transition: Transition.rightToLeft,
  );

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.DEFAULT,
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: MyBackButton(),
              ),
              CommonImageView(width: 150, imagePath: Assets.imagesLogo),
              const SizedBox(height: 80),
              for (final option in _options)
                _RoleOption(
                  option: option,
                  selected: option.role == selected,
                  onTap: () => setState(() => _selected = option.role),
                ),
            ],
          ),
        ),
      ),
      // Disabled until a role is picked, rather than live and answering the
      // tap with an error: there is nothing to continue WITH yet.
      bottomNavigationBar: NavButton(
        buttonText: "Continue",
        onTap: selected == null ? null : () => _continue(selected),
      ),
    );
  }
}

/// One role card.
///
/// THE WHOLE CARD is the tap target. The InkWell used to sit inside the card's
/// padding, so a tap on its outer 20 pixels did nothing.
class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final RoleModel option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // One node per card, announced as a selectable choice with its state —
      // otherwise a screen reader reads "I am a", "Buyer" and an unlabelled
      // circle, and never says which one is chosen.
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '${option.title}${option.subTitle}',
      onTap: onTap,
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppStyling().myDecoration(
          color: selected ? kLightOrangeColor : kTertiaryColor,
          borderColor: selected ? kSecondaryColor : kTransperentColor,
          radius: 10,
        ),
        child: Material(
          color: kTransperentColor,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CommonImageView(width: 40, imagePath: option.icon),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: option.title,
                          size: 16,
                          weight: FontWeight.w400,
                          color: kGreyTextColor,
                        ),
                        MyText(
                          text: option.subTitle,
                          size: 18,
                          weight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),
                  selected
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
            ),
          ),
        ),
      ),
    );
  }
}

class RoleModel {
  final String title, subTitle, icon;
  final AppRole role;
  const RoleModel({
    required this.title,
    required this.subTitle,
    required this.icon,
    required this.role,
  });
}

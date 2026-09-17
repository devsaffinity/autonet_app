import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/view/widget/animation_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentPage = 0;
  RoleController roleController = Get.find<RoleController>();

  final onboardingBK = [Assets.imagesOn1, Assets.imagesOn2, Assets.imagesOn3];

  bool _imagesCached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Run this only once
    if (!_imagesCached) {
      _imagesCached = true;
      _precacheOnboardingImages();
    }
  }

  Future<void> _precacheOnboardingImages() async {
    await precacheImage(AssetImage(Assets.imagesOn1), context);
    await precacheImage(AssetImage(Assets.imagesOn2), context);
    await precacheImage(AssetImage(Assets.imagesOn3), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeSlideTransition(
          child: Column(
            children: [
              Spacer(),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  // width: Get.width,
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(onboardingBK[currentPage]),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),

              // (currentPage == 0)
              //     ? Column(
              //         children: [
              //           heading(title: "Match Colors"),
              //           heading(
              //             title: "Effortlessly",
              //             color: kSecondaryColor,
              //           ),
              //         ],
              //       )
              //     : (currentPage == 1)
              //     ? Row(
              //         mainAxisAlignment: MainAxisAlignment.center,
              //         children: [
              //           heading(title: "Point & "),
              //           heading(title: "Sample", color: kSecondaryColor),
              //         ],
              //       )
              //     : Row(
              //         mainAxisAlignment: MainAxisAlignment.center,
              //         children: [
              //           heading(title: "Lighting is "),
              //           heading(title: "Key", color: kSecondaryColor),
              //         ],
              //       ),
              SizedBox(
                height: 100,
                child: Padding(
                  padding: AppSizes.HORIZONTAL,
                  child: PageView.builder(
                    itemCount: demoData.length,
                    onPageChanged: (value) {
                      setState(() {
                        currentPage = value;
                      });
                    },

                    itemBuilder: (context, index) => OnboardContent(
                      // illustration: demoData[index]["illustration"],
                      title: demoData[currentPage]["title"],
                      subTitle: demoData[currentPage]["subTitle"],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Spacer(),

              Padding(
                padding: AppSizes.HORIZONTAL,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        demoData.length,
                        (index) => DotIndicator(isActive: index == currentPage),
                      ),
                    ),
                    // SizedBox(height: 30),
                    SizedBox(
                      width: 120,
                      child: MyButton(
                        height: 35,
                        onTap: () {
                          if (currentPage < 2) {
                            currentPage++;
                            setState(() {});
                          } else {
                            // offAll, not to: slide 3 must not sit under
                            // Login. Login, not the role picker — a role is
                            // chosen only when signing up, from Login.
                            roleController.markOnboardingSeen();
                            Get.offAllNamed(AppLinks.login);
                          }
                          setState(() {});
                        },
                        buttonText: currentPage < 2 ? "Next" : "Get Started",
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  MyText heading({String? title, Color color = kBlackColor}) {
    return MyText(
      text: title.toString(),
      size: 36,
      weight: FontWeight.w900,
      color: color,
      textAlign: TextAlign.center,
    );
  }
}

class OnboardContent extends StatelessWidget {
  OnboardContent({
    super.key,
    // required this.illustration,
    required this.title,
    required this.subTitle,
  });

  final String? title, subTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Spacer(),
        MyText(
          text: title.toString(),
          size: 20,
          weight: FontWeight.w800,
          color: kSecondaryColor,
          textAlign: TextAlign.center,
        ),
        MyText(
          paddingTop: 10,
          text: subTitle.toString(),
          size: 16,
          weight: FontWeight.w500,
          textAlign: TextAlign.center,
          color: kGreyTextColor,
          lineHeight: 1.5,
        ),
      ],
    );
  }
}

class DotIndicator extends StatelessWidget {
  const DotIndicator({
    super.key,
    this.isActive = false,
    this.activeColor = kSecondaryColor,
    this.inActiveColor = Colors.white10,
  });

  final bool isActive;
  final Color activeColor, inActiveColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 10 / 2),
      height: 8,
      width: isActive ? 8 : 8,
      decoration: BoxDecoration(
        color: isActive ? activeColor : kGreyTextColor,
        border: Border.all(
          color: isActive ? kTransperentColor : kGreyTextColor,
          width: 1.5,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
    );
  }
}

// Demo data for our Onboarding screen
List<Map<String, dynamic>> demoData = [
  {
    "title": "Find car parts fast",
    "subTitle":
        "Post your request in seconds and reach verified suppliers across the UK.",
  },
  {
    "title": "Get Multiple Quotes",
    "subTitle": "Compare price, delivery time and ratings in one place.",
  },
  {
    "title": "Chat Securely",
    "subTitle": "Share photos, ask questions and negotiate easily.",
  },
];

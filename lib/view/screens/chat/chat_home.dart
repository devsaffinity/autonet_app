import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/screens/buyer/request/request_status_tracking.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Usage:
//   body: ChatHomePage()
// ─────────────────────────────────────────────────────────────────────────────

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  // ── Inbox data ─────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _chats = [
    {
      'name': 'Amed anjims',
      'avatar': Assets.imagesProfileImage,
      'lastMessage': 'Hi, John! 👋 How are you doing?',
      'time': '09:46',
      'isTyping': false,
      'isRead': true,
      'isDelivered': true,
      'onlineColor': const Color(0xffFFD600), // yellow dot
      'unread': 0,
    },
    {
      'name': 'alem leain',
      'avatar': Assets.imagesProfileImage,
      'lastMessage': 'Typing...',
      'time': '09:44',
      'isTyping': true,
      'isRead': true,
      'isDelivered': true,
      'onlineColor': const Color(0xff34C759), // green dot (online)
      'unread': 0,
    },
    {
      'name': 'Amed anjims',
      'avatar': Assets.imagesProfileImage,
      'lastMessage': 'Hi, John! 👋 How are you doing?',
      'time': '09:45',
      'isTyping': false,
      'isRead': true,
      'isDelivered': true,
      'onlineColor': const Color(0xffFFD600),
      'unread': 0,
    },
    {
      'name': 'Amed anjims',
      'avatar': Assets.imagesProfileImage,
      'lastMessage': 'Hi, John! 👋 How are you doing?',
      'time': '09:46',
      'isTyping': false,
      'isRead': true,
      'isDelivered': true,
      'onlineColor': const Color(0xffFFD600),
      'unread': 0,
    },
    {
      'name': 'Amed anjims',
      'avatar': Assets.imagesProfileImage,
      'lastMessage': 'Hi, John! 👋 How are you doing?',
      'time': '09:46',
      'isTyping': false,
      'isRead': true,
      'isDelivered': true,
      'onlineColor': const Color(0xffFFD600),
      'unread': 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: "Messages", hasBackButton: false),
      body: Padding(
        padding: AppSizes.DEFAULT,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(
              paddingBottom: 12,
              text: 'Inbox',
              size: 20,
              weight: FontWeight.w600,
              color: kBlackColor,
            ),

            MySearchBar(),

            // ── Chat list ──────────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: _chats.length,
                itemBuilder: (_, i) => _buildChatRow(_chats[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Chat Row ───────────────────────────────────────────────────────────────
  Widget _buildChatRow(Map<String, dynamic> chat) {
    final bool isTyping = chat['isTyping'] as bool;
    final bool isRead = chat['isRead'] as bool;
    final Color dotColor = chat['onlineColor'] as Color;

    return MyRippleEffect(
      onTap: () {
        Get.to(() => ChatRoomPage());
      },
      radius: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Avatar with online dot ─────────────────────────────────────
            Stack(
              children: [
                CommonImageView(
                  imagePath: chat['avatar'],
                  width: 52,
                  height: 52,
                  radius: 100,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimaryColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // ── Name + last message ────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: chat['name'],
                    size: 15,
                    weight: FontWeight.w600,
                    color: kBlackColor,
                    paddingBottom: 3,
                  ),
                  isTyping
                      ? MyText(
                          text: 'Typing...',
                          size: 13,
                          weight: FontWeight.w500,
                          color: const Color(0xff34C759),
                        )
                      : MyText(
                          text: chat['lastMessage'],
                          size: 13,
                          weight: FontWeight.w400,
                          color: kGreyTextColor,
                        ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // ── Time + read tick ───────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.done_all_rounded,
                      size: 14,
                      color: isTyping
                          ? const Color(0xff34C759)
                          : kGreyTextColor,
                    ),
                    const SizedBox(width: 3),
                    MyText(
                      text: chat['time'],
                      size: 12,
                      weight: FontWeight.w400,
                      color: kGreyTextColor,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

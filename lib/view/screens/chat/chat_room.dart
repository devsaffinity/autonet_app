import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Usage:
//   body: ChatRoomPage()
// ─────────────────────────────────────────────────────────────────────────────

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({super.key});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  // ── Message model ──────────────────────────────────────────────────────────
  // isMine: true = right bubble (me), false = left bubble (them)
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello!',
      'time': '9:24',
      'isMine': true,
      'isRead': true,
      'showAvatar': false,
    },
    {
      'text':
          'Thank you very mouch for your traveling, we really like the apartments. we will stay here for another 5 days...',
      'time': '9:30',
      'isMine': true,
      'isRead': true,
      'showAvatar': false,
    },
    {
      'text': 'Hello!',
      'time': '9:34',
      'isMine': false,
      'isRead': true,
      'showAvatar': false,
    },
    {
      'text': 'I\'m very glab you like it👍',
      'time': '9:35',
      'isMine': false,
      'isRead': true,
      'showAvatar': true,
    },
    {
      'text': 'We are arriving today at 01:45, will someone be at home?',
      'time': '9:37',
      'isMine': false,
      'isRead': true,
      'showAvatar': true,
    },
    {
      'text': 'I will be at home',
      'time': '9:39',
      'isMine': true,
      'isRead': true,
      'showAvatar': false,
    },
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({
        'text': text,
        'time': _currentTime(),
        'isMine': true,
        'isRead': false,
        'showAvatar': false,
      });
    });
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _currentTime() {
    final now = TimeOfDay.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Message list ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + 1, // +1 for date header
              itemBuilder: (_, i) {
                if (i == 0) return _buildDateHeader('Today');
                return _buildMessageBubble(_messages[i - 1]);
              },
            ),
          ),

          // ── Input bar ────────────────────────────────────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kPrimaryColor,
      elevation: 0,
      centerTitle: true,
      leading: MyRippleEffect(
        onTap: () => Navigator.pop(context),
        radius: 20,
        child: const Icon(Icons.close_rounded, color: kBlackColor, size: 22),
      ),
      title: Column(
        children: [
          MyText(
            text: 'Ahmed anjims',
            size: 15,
            weight: FontWeight.w700,
            color: kBlackColor,
          ),
          MyText(
            text: 'Active Now',
            size: 12,
            weight: FontWeight.w500,
            color: const Color(0xff34C759),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(color: kTertiaryColor, height: 1),
      ),
    );
  }

  // ── Date Header ────────────────────────────────────────────────────────────
  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: kTertiaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: MyText(
            text: label,
            size: 12,
            weight: FontWeight.w500,
            color: kGreyTextColor,
          ),
        ),
      ),
    );
  }

  // ── Message Bubble ─────────────────────────────────────────────────────────
  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final bool isMine = msg['isMine'] as bool;
    final bool isRead = msg['isRead'] as bool;
    final bool showAvatar = msg['showAvatar'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Other user avatar ──────────────────────────────────────────
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: showAvatar
                  ? CommonImageView(
                      imagePath: Assets.imagesProfileImage,
                      width: 32,
                      height: 32,
                      radius: 100,
                      fit: BoxFit.cover,
                    )
                  : const SizedBox(width: 32),
            ),

          // ── Bubble ────────────────────────────────────────────────────
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.68,
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: isMine ? const Color(0xffFFECE8) : kTertiaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Message text
                  Flexible(
                    child: MyText(
                      text: msg['text'],
                      size: 14,
                      weight: FontWeight.w400,
                      color: kBlackColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Time + read tick
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      MyText(
                        text: msg['time'],
                        size: 10,
                        weight: FontWeight.w400,
                        color: kGreyTextColor,
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.done_all_rounded,
                        size: 13,
                        color: isRead
                            ? const Color(0xff34C759)
                            : kGreyTextColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Bar ──────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Text field ───────────────────────────────────────────────────
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: kTertiaryColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: const TextStyle(
                        fontSize: 14,
                        color: kBlackColor,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type you message',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: kGreyTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  // Attachment icon
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: MyRippleEffect(
                      onTap: () {},
                      radius: 20,
                      child: const Icon(
                        Icons.attach_file_rounded,
                        size: 20,
                        color: kGreyTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // ── Mic / Send button ────────────────────────────────────────────
          MyRippleEffect(
            onTap: _sendMessage,
            radius: 30,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: kSecondaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: kWhiteColor,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

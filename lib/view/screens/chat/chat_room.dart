import 'dart:async';

import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_role.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/chat/chat_room_controller.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/view/screens/buyer/providers/provider_detail.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One thread.
///
/// Opened by CONTEXT — a booking or an offer — never by naming a person. The
/// server derives who is in the thread from that context, so there is no
/// recipient field here to get wrong or to tamper with.
///
/// Incoming messages are POLLED, not pushed. See ChatRoomController: it is a
/// deliberate compromise so chat could ship without a socket dependency, and
/// the send path is already the one the gateway uses.
class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({
    super.key,
    this.contextId,
    this.conversationId,
    this.type = ConversationType.booking,
    this.myUserId,
    this.title,
    this.peerAvatarUrl,
  }) : assert(
          contextId != null || conversationId != null,
          'Either contextId or conversationId must be provided',
        );

  /// The booking or offer this thread belongs to, when opened from a deal.
  final String? contextId;

  /// The conversation ID, when opened directly (e.g. from a notification or deep-link).
  final String? conversationId;

  final ConversationType type;

  /// Whose side is 'mine'. Without it every bubble renders as the peer's,
  /// which is wrong in a way that looks like a layout bug.
  final String? myUserId;

  /// A name to show before the thread resolves — the caller usually knows it
  /// already, and an empty app bar for a second reads as a broken screen.
  final String? title;

  /// A presigned avatar URL passed from the caller, if known before open resolves.
  final String? peerAvatarUrl;

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ChatRoomController c = ChatRoomController.ensure();

  String? get _resolvedMyUserId =>
      widget.myUserId ?? ProfileController.maybeFind()?.me?.id;

  @override
  void initState() {
    super.initState();
    final effectiveUserId = _resolvedMyUserId;
    if (widget.conversationId != null) {
      c.openById(widget.conversationId!, asUserId: effectiveUserId);
    } else if (widget.type == ConversationType.booking) {
      c.openForBooking(widget.contextId!, asUserId: effectiveUserId);
    } else {
      c.openForOffer(widget.contextId!, asUserId: effectiveUserId);
    }
  }

  @override
  void dispose() {
    // The screen owns 'somebody is looking at this thread'. The controller is
    // a Get singleton that outlives this route, so leaving the timer to its
    // disposal polls a closed thread for the rest of the session.
    c.stopPolling();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    // Cleared OPTIMISTICALLY, then put back if the send fails — retyping a
    // message because the network blinked is the worst part of a bad chat.
    _msgCtrl.clear();
    final sent = await c.send(text);
    if (!sent && mounted) _msgCtrl.text = text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: Column(
        children: [
          Expanded(
            // Every Rx read HERE — StateView.builder runs outside this closure
            // and a read down there would subscribe to nothing.
            child: Obx(() {
              final state = c.state.value;
              final me = c.myUserId.value ?? _resolvedMyUserId;
              // Falls back to the PEER when the caller did not say who I am:
              // anything the peer did not send is mine. Exact, and it needs no
              // second source of truth for the signed-in user's id.
              final peerId = c.conversation.value?.peer?.id;
              bool mine(ChatMessage m) => me != null
                  ? m.senderId == me
                  : peerId != null && m.senderId != peerId;
              return StateView<List<ChatMessage>>(
                state: state,
                onRetry: c.refreshMessages,
                emptyTitle: 'No messages yet',
                emptyBody: 'Say hello.',
                builder: (_, messages) => ListView.builder(
                  controller: _scrollCtrl,
                  // The server returns NEWEST FIRST and the list is reversed,
                  // so index 0 is the newest and sits at the bottom. No sort,
                  // no second ordering to disagree with the server's.
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final peer = c.conversation.value?.peer;
                    return _Bubble(
                      message: messages[i],
                      isMine: mine(messages[i]),
                      peerAvatarUrl: peer?.avatarUrl ?? widget.peerAvatarUrl,
                      peerName: peer?.displayName ?? widget.title ?? 'User',
                    );
                  },
                ),
              );
            }),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: kPrimaryColor,
      elevation: 0,
      centerTitle: true,
      leading: MyRippleEffect(
        onTap: () => Get.back<void>(),
        radius: 20,
        child: const Icon(Icons.close_rounded, color: kBlackColor, size: 22),
      ),
      title: Obx(() {
        final peer = c.conversation.value?.peer;
        final name = peer?.displayName ?? widget.title ?? 'Conversation';
        final avatar = peer?.avatarUrl ?? widget.peerAvatarUrl;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatar != null &&
                avatar.isNotEmpty &&
                (avatar.startsWith('http://') || avatar.startsWith('https://')))
              CommonImageView(
                url: avatar,
                width: 32,
                height: 32,
                radius: 100,
                fit: BoxFit.cover,
                errorWidget: InitialsAvatar(
                  name: name,
                  size: 32,
                  radius: 100,
                ),
              )
            else
              InitialsAvatar(
                name: name,
                size: 32,
                radius: 100,
              ),
            const SizedBox(width: 8),
            Flexible(
              child: MyText(
                text: name,
                size: 15,
                weight: FontWeight.w700,
                color: kBlackColor,
                maxLines: 1,
                textOverflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(color: kTertiaryColor, height: 1),
      ),
    );
  }

  Widget _inputBar() {
    return Obx(() {
      final isPaused = c.isPaused.value;
      if (isPaused) {
        return _buildPausedBar();
      }

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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: kTertiaryColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  textInputAction: TextInputAction.send,
                  style: const TextStyle(
                    fontSize: 14,
                    color: kBlackColor,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Type your message',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: kGreyTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Obx(() {
              final sending = c.sending.value;
              return MyRippleEffect(
                onTap: sending ? () {} : () => unawaited(_send()),
                radius: 30,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: sending ? kGreyTextColor : kSecondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: kWhiteColor,
                    size: 20,
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildPausedBar() {
    final peerId = c.conversation.value?.peer?.id;
    final isBuyer = RoleController.to.role.value == AppRole.buyer;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        border: const Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: const Icon(
                  Icons.pause_circle_outline_rounded,
                  size: 22,
                  color: kSecondaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: isBuyer
                          ? 'Session Completed • Chat Paused'
                          : 'Job Completed • Chat Paused',
                      size: 13,
                      weight: FontWeight.w600,
                      color: kBlackColor,
                    ),
                    const SizedBox(height: 2),
                    MyText(
                      text: isBuyer
                          ? (c.sessionMessage.value ??
                              'Booking session has ended. Book again to resume messaging.')
                          : 'This booking session has ended. Messaging will resume once the customer books again.',
                      size: 11,
                      weight: FontWeight.w400,
                      color: kGreyTextColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isBuyer && peerId != null && widget.type == ConversationType.booking) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Get.to(() => ProviderDetailPage(providerId: peerId));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSecondaryColor,
                  foregroundColor: kWhiteColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: kWhiteColor),
                    SizedBox(width: 8),
                    Text(
                      'Book Again to Resume Chat',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kWhiteColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isMine,
    this.peerAvatarUrl,
    this.peerName = 'User',
  });

  final ChatMessage message;
  final bool isMine;
  final String? peerAvatarUrl;
  final String peerName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: (peerAvatarUrl != null &&
                      peerAvatarUrl!.isNotEmpty &&
                      (peerAvatarUrl!.startsWith('http://') ||
                          peerAvatarUrl!.startsWith('https://')))
                  ? CommonImageView(
                      url: peerAvatarUrl,
                      width: 32,
                      height: 32,
                      radius: 100,
                      fit: BoxFit.cover,
                      errorWidget: InitialsAvatar(
                        name: peerName,
                        size: 32,
                        radius: 100,
                      ),
                    )
                  : InitialsAvatar(
                      name: peerName,
                      size: 32,
                      radius: 100,
                    ),
            ),
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
                  Flexible(
                    child: MyText(
                      // A media message has no body. Naming the kind is at
                      // least true; rendering an empty bubble is not.
                      text: message.body ?? _mediaLabel(message.type),
                      size: 14,
                      weight: FontWeight.w400,
                      color: kBlackColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  MyText(
                    text: formatClock(message.createdAt.toLocal()),
                    size: 10,
                    weight: FontWeight.w400,
                    color: kGreyTextColor,
                  ),
                  // The tick is only ever shown on MY messages, and only means
                  // what it says: the peer has read it. On a received message
                  // it would be reporting my own read state back to me.
                  if (isMine) ...[
                    const SizedBox(width: 3),
                    Icon(
                      Icons.done_all_rounded,
                      size: 13,
                      color: message.readAt != null
                          ? const Color(0xff34C759)
                          : kGreyTextColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _mediaLabel(MessageType? type) => switch (type) {
    MessageType.image => 'Photo',
    MessageType.file => 'File',
    MessageType.voice => 'Voice note',
    _ => '',
  };
}

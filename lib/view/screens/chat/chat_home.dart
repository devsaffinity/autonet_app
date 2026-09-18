import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/chat/chat_inbox_controller.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/view/screens/buyer/request/request_status_tracking.dart';
import 'package:autonect/view/screens/chat/chat_room.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The inbox.
///
/// Threads are anchored to a deal, so this list can only ever contain people
/// the signed-in user has actually done business with — there is no way to
/// start a conversation from here, and that is by design rather than missing.
class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key, this.myUserId});

  /// Whose side is 'mine' in a thread this screen opens. Passed through so the
  /// room does not have to re-derive it.
  final String? myUserId;

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  final ChatInboxController c = ChatInboxController.ensure();

  @override
  void initState() {
    super.initState();
    c.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: GeneralAppBar(title: 'Messages', hasBackButton: false),
      body: Padding(
        padding: AppSizes.HORIZONTAL,
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
            // Wired: MySearchBar defaults onChanged to a no-op, so a const one
            // renders a search box that silently does nothing.
            MySearchBar(hint: 'Search your conversations', onChanged: c.search),
            const SizedBox(height: 12),
            Obx(() {
              final activeTab = c.tabFilter.value;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All', InboxTabFilter.all, activeTab == InboxTabFilter.all),
                    const SizedBox(width: 8),
                    _filterChip('Active', InboxTabFilter.active, activeTab == InboxTabFilter.active),
                    const SizedBox(width: 8),
                    _filterChip('Paused', InboxTabFilter.paused, activeTab == InboxTabFilter.paused),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Expanded(
              // Every Rx read in the closure, not in itemBuilder.
              child: Obx(() {
                final state = c.state.value;
                final filter = c.query.value;
                return StateView<List<Conversation>>(
                  state: state,
                  onRetry: c.load,
                  emptyTitle: 'No conversations yet',
                  emptyBody:
                      'A thread opens when you book a provider or take an '
                      'offer.',
                  builder: (_, all) {
                    final rows = c.visible(all);
                    if (rows.isEmpty) {
                      return Center(
                        child: MyText(
                          text: filter.isNotEmpty
                              ? 'Nothing matches "$filter".'
                              : (c.tabFilter.value == InboxTabFilter.paused
                                  ? 'No paused conversations.'
                                  : 'No active conversations.'),
                          size: 13,
                          weight: FontWeight.w400,
                          color: kGreyTextColor,
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: rows.length,
                      itemBuilder: (_, i) => _ConversationRow(
                        conversation: rows[i],
                        onTap: () => _open(rows[i]),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, InboxTabFilter filter, bool isSelected) {
    return InkWell(
      onTap: () => c.setTabFilter(filter),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? kSecondaryColor : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? kWhiteColor : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  void _open(Conversation conversation) {
    final effectiveUserId = widget.myUserId ?? ProfileController.maybeFind()?.me?.id;
    Get.to(
      () => ChatRoomPage(
        contextId: conversation.contextId,
        type: conversation.type ?? ConversationType.booking,
        myUserId: effectiveUserId,
        title: conversation.peer?.displayName,
        peerAvatarUrl: conversation.peer?.avatarUrl,
      ),
      // Re-reads the inbox on the way back so an unread count the room just
      // cleared does not sit there stale.
    )?.then((_) => c.load());
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation, required this.onTap});

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final peer = conversation.peer;
    final last = conversation.lastMessage;
    final unread = conversation.unreadCount;

    return MyRippleEffect(
      onTap: onTap,
      radius: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            if (peer?.avatarUrl != null &&
                peer!.avatarUrl!.isNotEmpty &&
                (peer!.avatarUrl!.startsWith('http://') ||
                    peer!.avatarUrl!.startsWith('https://')))
              CommonImageView(
                url: peer.avatarUrl,
                width: 52,
                height: 52,
                radius: 100,
                fit: BoxFit.cover,
                errorWidget: InitialsAvatar(
                  name: peer?.displayName ?? 'User',
                  size: 52,
                  radius: 100,
                ),
              )
            else
              InitialsAvatar(
                name: peer?.displayName ?? 'User',
                size: 52,
                radius: 100,
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: MyText(
                          text: peer?.displayName ?? 'Autonect user',
                          size: 15,
                          weight: FontWeight.w600,
                          color: kBlackColor,
                          maxLines: 1,
                          paddingBottom: 3,
                        ),
                      ),
                      if (conversation.isPaused) ...[
                        const SizedBox(width: 6),
                        Container(
                          margin: const EdgeInsets.only(bottom: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Text(
                            'PAUSED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  MyText(
                    // 'Typing…' is gone: it needs a live socket, and showing it
                    // from a poll would be inventing somebody's activity.
                    text: conversation.isPaused && (last == null || (last.body ?? '').isEmpty)
                        ? (conversation.sessionMessage ?? 'Session completed • Chat paused')
                        : (last?.body ?? 'No messages yet'),
                    size: 13,
                    weight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                    color: unread > 0 ? kBlackColor : kGreyTextColor,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MyText(
                  text: formatClock(conversation.lastMessageAt.toLocal()),
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                ),
                if (unread > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: kSecondaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: MyText(
                      text: '$unread',
                      size: 11,
                      weight: FontWeight.w700,
                      color: kWhiteColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

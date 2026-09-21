import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_images.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import 'common_image_view_widget.dart';
import 'my_text_widget.dart';

/// A production-grade card displaying the service location over a map graphic,
/// with immediate one-tap navigation to Google Maps / external maps app.
///
/// Matches the Figma design specification:
/// - "Location" section header
/// - Rounded map preview card with terracotta/orange accent border
/// - Bottom-left badge with location pin icon and "SERVICE LOCATION" caption
/// - Interactive tap-to-navigate action via [url_launcher]
/// - Approximate duration info row directly underneath
class ServiceLocationCard extends StatelessWidget {
  const ServiceLocationCard({
    super.key,
    required this.location,
    this.durationMinutes,
    this.title = 'Location',
    this.omitWhenEmpty = true,
    this.showDuration = true,
    this.onTap,
  });

  /// The location string to display (e.g. workshop address or bay number).
  final String? location;

  /// Service duration in minutes (e.g. 90). Shown underneath the card.
  final int? durationMinutes;

  /// Section heading title. Defaults to 'Location'.
  final String? title;

  /// If true, returns [SizedBox.shrink] when [location] is null or blank.
  final bool omitWhenEmpty;

  /// Whether to render the duration info row below the map card.
  final bool showDuration;

  /// Optional override for the tap action. Defaults to [openLocationInMaps].
  final VoidCallback? onTap;

  /// Launches Google Maps (or external map app) searching for [location].
  static Future<bool> openLocationInMaps(
    String location, {
    BuildContext? context,
  }) async {
    final query = location.trim();
    if (query.isEmpty) return false;

    final encoded = Uri.encodeComponent(query);
    final mapUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );

    try {
      if (await canLaunchUrl(mapUri)) {
        return await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('ServiceLocationCard: failed to launch map url: $e');
    }

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open map for "$query"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = location?.trim();
    if (loc == null || loc.isEmpty) {
      if (omitWhenEmpty) return const SizedBox.shrink();
    }

    final displayLoc = (loc != null && loc.isNotEmpty)
        ? loc
        : 'Service Location';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null && title!.isNotEmpty) ...[
          MyText(
            text: title!,
            size: AppTextScale.body,
            weight: AppWeights.semibold,
            color: kBlackColor,
          ),
          const SizedBox(height: AppSizes.s8),
        ],

        // ── Map Card ────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xffE04F2E),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap ?? () => openLocationInMaps(displayLoc, context: context),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Map Background Image
                  CommonImageView(
                    imagePath: Assets.imagesMapImage1,
                    width: double.infinity,
                    height: 170,
                    fit: BoxFit.cover,
                  ),

                  // Bottom subtle gradient overlay for text readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.40),
                          ],
                          stops: const [0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Top-Right "Open Map" pill
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_new_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Open',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom-Left Location Info
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xffD34A26),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.20),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'SERVICE LOCATION',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                displayLoc,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Duration Info Row ───────────────────────────────────────────────
        if (showDuration && durationMinutes != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: Color(0xff8896A6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Approximate service duration: $durationMinutes mins',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff8896A6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

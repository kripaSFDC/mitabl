import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/star_rating.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
import 'package:mitabl_user/widgets/mitabl_chip.dart';

import '../../helper/route_arguement.dart';

class UserDetails extends StatelessWidget {
  const UserDetails({super.key, this.routeArguments});

  final RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => UserDetails(routeArguments: routeArguments),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = routeArguments!.customer!;

    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: GlassAppBar(
        title: Text(customer.name ?? 'Customer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MitablSpacing.pagePadding),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Avatar
            CachedNetworkImage(
              imageUrl:
                  '${GlobalConfiguration().getValue<String>('image_base_url')}${customer.avatar!}',
              imageBuilder: (context, imageProvider) => CircleAvatar(
                radius: 80,
                backgroundImage: imageProvider,
              ),
              errorWidget: (context, data, e) => const CircleAvatar(
                radius: 80,
                backgroundColor: MitablColors.surfaceContainerLow,
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: MitablColors.onSurfaceVariant,
                ),
              ),
              placeholder: (context, s) => const CircleAvatar(
                radius: 80,
                backgroundColor: MitablColors.surfaceContainerLow,
              ),
            ),
            const SizedBox(height: 20),

            // Name
            Text(
              customer.name.toString(),
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: MitablColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Star rating
            StarRating(
              rating: customer.rating!,
              size: 24,
              color: const Color(0xffFFA200),
            ),
            const SizedBox(height: 24),

            // About section
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    customer.description.toString(),
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: MitablColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: MitablSpacing.listItem),

            // Customer Preferences section (visual placeholder)
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Preferences',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      MitablChip(label: 'Spice Level 3/5'),
                      MitablChip(label: 'Gluten-Free'),
                      MitablChip(label: 'Dairy-Free'),
                      MitablChip(label: 'No Nuts'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Invite Feedback button
            MitablButton(
              label: 'Invite Feedback',
              variant: MitablButtonVariant.outline,
              onPressed: () {
                // Placeholder action
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

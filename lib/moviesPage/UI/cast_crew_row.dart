import 'package:flutter/material.dart';
import 'package:Mirarr/widgets/tv_focus_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:Mirarr/widgets/cast/cast-details.dart';
import 'package:Mirarr/widgets/cast/crew-details.dart';
import 'package:provider/provider.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/functions/get_base_url.dart';

void onTapCast(BuildContext context, int castId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CastDetailPage(castId: castId),
    ),
  );
}

void onTapCrew(BuildContext context, int castId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CrewDetailPage(castId: castId),
    ),
  );
}

class CastCrewCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isDesktop;
  final bool isCast; // true for Cast, false for Crew
  final String region;

  const CastCrewCard({
    Key? key,
    required this.item,
    required this.isDesktop,
    required this.isCast,
    required this.region,
  }) : super(key: key);

  @override
  State<CastCrewCard> createState() => _CastCrewCardState();
}

class _CastCrewCardState extends State<CastCrewCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Sizing constants for the modern card layout
    final double width = widget.isDesktop ? 120.0 : 85.0;
    final double height = widget.isDesktop ? 190.0 : 135.0;
    final double imageHeight = widget.isDesktop ? 120.0 : 85.0;
    final double borderRadius = widget.isDesktop ? 12.0 : 8.0;

    final double nameFontSize = widget.isDesktop ? 12.0 : 9.5;
    final double subtitleFontSize = widget.isDesktop ? 10.5 : 8.5;
    final String imageSize = widget.isDesktop ? 'w185' : 'w92';

    final String name = widget.item['name'] ?? '';
    final String subtitle = widget.isCast
        ? (widget.item['character'] ?? '')
        : (widget.item['job'] ?? '');
    final int id = widget.item['id'] ?? 0;
    final String? profilePath = widget.item['profile_path'];

    final outerPadding = widget.isDesktop
        ? const EdgeInsets.fromLTRB(16, 12, 0, 12)
        : const EdgeInsets.fromLTRB(10, 8, 0, 8);

    return Padding(
      padding: outerPadding,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: TvFocusWrapper(
            borderRadius: borderRadius,
            onTap: () {
              if (widget.isCast) {
                onTapCast(context, id);
              } else {
                onTapCrew(context, id);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: _isHovered 
                    ? Colors.white.withValues(alpha: 0.08) 
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(borderRadius - 3.0 > 0 ? borderRadius - 3.0 : 0),
                border: Border.all(
                  color: _isHovered 
                      ? Colors.white30 
                      : Colors.white10,
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section with rounded top corners and loading skeleton
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(borderRadius - 4.0 > 0 ? borderRadius - 4.0 : 0),
                    ),
                    child: SizedBox(
                      height: imageHeight,
                      width: double.infinity,
                      child: profilePath != null
                          ? CachedNetworkImage(
                              imageUrl: '${getImageBaseUrl(widget.region)}/t/p/$imageSize$profilePath',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[900],
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[900],
                                child: const Icon(Icons.person, color: Colors.grey),
                              ),
                            )
                          : Container(
                              color: Colors.grey[900],
                              child: Image.asset(
                                'assets/images/person.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                  // Details section (Name & Subtitle)
                  Expanded(
                    child: Padding(
                      padding: widget.isDesktop
                          ? const EdgeInsets.fromLTRB(8, 6, 8, 4)
                          : const EdgeInsets.fromLTRB(6, 4, 6, 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            textAlign: TextAlign.left,
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: nameFontSize,
                              fontWeight: FontWeight.bold,
                              color: _isHovered ? Colors.white : Colors.white.withValues(alpha: 0.9),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[400],
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
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

Widget buildCastRow(List<Map<String, dynamic>> castList, BuildContext context) {
  final region =
      Provider.of<RegionProvider>(context, listen: false).currentRegion;
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: castList.map<Widget>((cast) {
        return CastCrewCard(
          item: cast,
          isDesktop: false,
          isCast: true,
          region: region,
        );
      }).toList(),
    ),
  );
}

Widget buildCrewRow(List<Map<String, dynamic>> crewList, BuildContext context) {
  final region =
      Provider.of<RegionProvider>(context, listen: false).currentRegion;
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: crewList.map<Widget>((crew) {
        return CastCrewCard(
          item: crew,
          isDesktop: false,
          isCast: false,
          region: region,
        );
      }).toList(),
    ),
  );
}

Widget buildCrewRowDesktop(
    List<Map<String, dynamic>> crewList, BuildContext context) {
  final region =
      Provider.of<RegionProvider>(context, listen: false).currentRegion;
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: crewList.map<Widget>((crew) {
        return CastCrewCard(
          item: crew,
          isDesktop: true,
          isCast: false,
          region: region,
        );
      }).toList(),
    ),
  );
}

Widget buildCastRowDesktop(
    List<Map<String, dynamic>> castList, BuildContext context) {
  final region =
      Provider.of<RegionProvider>(context, listen: false).currentRegion;
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: castList.map<Widget>((cast) {
        return CastCrewCard(
          item: cast,
          isDesktop: true,
          isCast: true,
          region: region,
        );
      }).toList(),
    ),
  );
}

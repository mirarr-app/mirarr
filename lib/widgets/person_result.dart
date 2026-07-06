import 'package:Mirarr/widgets/models/person.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/functions/get_base_url.dart';

class PersonSearchResult extends StatelessWidget {
  final Person person;

  const PersonSearchResult({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          image: person.profilePath.isNotEmpty
              ? DecorationImage(
                  image: CachedNetworkImageProvider(
                    '${getImageBaseUrl(region)}/t/p/w500${person.profilePath}',
                  ),
                  fit: BoxFit.cover,
                )
              : const DecorationImage(
                  image: AssetImage('assets/images/person.png'),
                  fit: BoxFit.cover,
                ),
          color: Colors.grey[900],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    person.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  if (person.department != null && person.department!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      person.department!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

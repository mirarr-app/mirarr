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
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 5, 3, 5),
      child: Card(
        elevation: 4,
        child: Container(
          height: 200,
          width: 250,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            image: person.profilePath.isNotEmpty
                ? DecorationImage(
                    image: CachedNetworkImageProvider(
                      '${getImageBaseUrl(region)}/t/p/original${person.profilePath}',
                    ),
                    fit: BoxFit.cover,
                    opacity: 0.8)
                : const DecorationImage(
                    image: AssetImage('assets/images/person.png'),
                    fit: BoxFit.cover,
                    opacity: 0.8),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Text(
                        person.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Text color on top of the image
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

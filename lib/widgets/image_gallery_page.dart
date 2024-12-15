import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/functions/get_base_url.dart';

class ImageGalleryPage extends StatelessWidget {
  final List<String> imageUrls;

  const ImageGalleryPage({Key? key, required this.imageUrls}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Image Gallery'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl:
                '${getImageBaseUrl(region)}/t/p/original${imageUrls[index]}',
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}

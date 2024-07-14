import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:Mirarr/widgets/cast/cast-details.dart';
import 'package:Mirarr/widgets/cast/crew-details.dart';

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

Widget buildCastRow(List<Map<String, dynamic>> castList, BuildContext context) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: castList.map<Widget>((cast) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(13, 8, 0, 8),
          child: GestureDetector(
            onTap: () {
              onTapCast(context, cast['id']);
            },
            child: Column(
              children: [
                CircleAvatar(
                  backgroundImage: cast['profile_path'] != null
                      ? CachedNetworkImageProvider(
                          'https://image.tmdb.org/t/p/w92${cast['profile_path']}',
                        )
                      : const AssetImage('assets/images/person.png')
                          as ImageProvider,
                  backgroundColor: Colors.grey,
                  radius: 30,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                  child: SizedBox(
                    width: 70,
                    child: Text(
                      cast['name'] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                  child: SizedBox(
                    width: 70,
                    child: Text(
                      cast['character'] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );
}

Widget buildCrewRow(List<Map<String, dynamic>> crewList, BuildContext context) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: crewList.map<Widget>((crew) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(13, 8, 0, 8),
          child: GestureDetector(
            onTap: () {
              onTapCrew(context, crew['id']);
            },
            child: Column(
              children: [
                CircleAvatar(
                  backgroundImage: crew['profile_path'] != null
                      ? CachedNetworkImageProvider(
                          'https://image.tmdb.org/t/p/w92${crew['profile_path']}',
                        )
                      : const AssetImage('assets/images/person.png')
                          as ImageProvider,
                  backgroundColor: Colors.grey,
                  radius: 30,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                  child: SizedBox(
                    width: 70,
                    child: Text(
                      crew['name'] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                  child: SizedBox(
                    width: 70,
                    child: Text(
                      crew['job'] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );
}

Widget buildCrewRowDesktop(
    List<Map<String, dynamic>> crewList, BuildContext context) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: crewList.map<Widget>((crew) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              20, 16, 0, 16), // Increase horizontal and vertical padding
          child: GestureDetector(
            onTap: () {
              onTapCrew(context, crew['id']);
            },
            child: Column(
              children: [
                CircleAvatar(
                  backgroundImage: crew['profile_path'] != null
                      ? CachedNetworkImageProvider(
                          'https://image.tmdb.org/t/p/w185${crew['profile_path']}', // Increase image size
                        )
                      : const AssetImage('assets/images/person.png')
                          as ImageProvider,
                  backgroundColor: Colors.grey,
                  radius: 45, // Increase avatar radius
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      0, 12, 0, 0), // Increase top padding
                  child: SizedBox(
                    width: 120, // Increase width
                    child: Text(
                      crew['name'] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16, // Increase font size
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      0, 4, 0, 0), // Increase top padding
                  child: SizedBox(
                    width: 90, // Increase width
                    child: Text(
                      crew['job'] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14, // Increase font size
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );
}

Widget buildCastRowDesktop(
    List<Map<String, dynamic>> castList, BuildContext context) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: castList.map<Widget>((cast) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 0, 16),
          child: GestureDetector(
            onTap: () {
              onTapCast(context, cast['id']);
            },
            child: Column(
              children: [
                CircleAvatar(
                  backgroundImage: cast['profile_path'] != null
                      ? CachedNetworkImageProvider(
                          'https://image.tmdb.org/t/p/w185${cast['profile_path']}',
                        )
                      : const AssetImage('assets/images/person.png')
                          as ImageProvider,
                  backgroundColor: Colors.grey,
                  radius: 45,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                  child: SizedBox(
                    width: 120,
                    child: Text(
                      cast['name'] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                  child: SizedBox(
                    width: 90,
                    child: Text(
                      cast['character'] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );
}

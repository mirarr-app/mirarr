import 'dart:io';
import 'dart:ui';

import 'package:Mirarr/seriesPage/UI/customSeriesWidget.dart';
import 'package:Mirarr/seriesPage/function/on_tap_serie.dart';
import 'package:Mirarr/seriesPage/function/on_tap_serie_desktop.dart';
import 'package:flutter/material.dart';

class ListGridViewSeries extends StatefulWidget {
  final List serieList;

  ListGridViewSeries({Key? key, required this.serieList}) : super(key: key);

  @override
  _ListGridViewSeriesState createState() => _ListGridViewSeriesState();
}

class _ListGridViewSeriesState extends State<ListGridViewSeries> {
  @override
  Widget build(BuildContext context) {
    int crossAxisCount = Platform.isAndroid || Platform.isIOS ? 2 : 4;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('TV List'),
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.7,
          ),
          itemCount: widget.serieList.length,
          itemBuilder: (context, index) {
            final serie = widget.serieList[index];
            return GestureDetector(
              onTap: () => Platform.isAndroid || Platform.isIOS
                  ? onTapSerie(serie.name, serie.id, context)
                  : onTapSerieDesktop(serie.name, serie.id, context),
              child: CustomSeriesWidget(serie: serie),
            );
          },
        ),
      ),
    );
  }
}

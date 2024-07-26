import 'package:Mirarr/seriesPage/UI/gridview_forlists_series.dart';
import 'package:flutter/material.dart';

void onTapGridSerie(List serieList, BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ListGridViewSeries(serieList: serieList),
    ),
  );
}

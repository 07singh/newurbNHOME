import 'package:flutter/material.dart';
class PlotLayout extends StatelessWidget {
  const PlotLayout({super.key});
  Widget buildPlot({
    required String plotNo,
    required String area,
    required String size,
    required Color color,
    double width = 80,
    double height = 60,
  }) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: color,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Plot $plotNo', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          Text(area, style: const TextStyle(fontSize: 9)),
          Text(size, style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  Widget buildRoad(String label, {double width = 10, double height = 60, Axis direction = Axis.vertical}) {
    return Container(
      width: direction == Axis.vertical ? width : null,
      height: direction == Axis.horizontal ? height : null,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      color: Colors.red.shade700,
      alignment: Alignment.center,
      child: RotatedBox(
        quarterTurns: direction == Axis.vertical ? 1 : 0,
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    final blue = Colors.lightBlue.shade100;
    final grey = Colors.grey.shade300;
    final yellow = Colors.amber.shade100;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// Leftmost column (Blue 100 Sq.Yds)
        Column(
          children: [
            buildPlot(plotNo: '48', area: '85 Sq.Yds', size: '40’-0” x 19’-1”', color: blue),
            ...List.generate(11, (i) => buildPlot(
              plotNo: '${49 + i}',
              area: '100 Sq.Yds',
              size: '22’-6”',
              color: blue,
            )),
          ],
        ),

        buildRoad("27.5’ WIDE ROAD"),

        /// Left Inner Grey
        Column(
          children: [
            buildPlot(plotNo: '47', area: '150 Sq.Yds', size: '36’-6” x 37’-2”', color: grey),
            buildPlot(plotNo: '46', area: '150 Sq.Yds', size: '36’-2” x 37’-9”', color: grey),
            buildPlot(plotNo: '45', area: '150 Sq.Yds', size: '35’-7” x 38’-4”', color: grey),
            buildPlot(plotNo: '44', area: '150 Sq.Yds', size: '35’-0” x 38’-6”', color: grey),
            buildPlot(plotNo: '43', area: '150 Sq.Yds', size: '34’-0” x 39’-6”', color: grey),
            buildPlot(plotNo: '42', area: '200 Sq.Yds', size: '45’-0” x 40’-0”', color: yellow),
          ],
        ),

        buildRoad("27.5’ WIDE ROAD"),

        /// Right Inner Grey
        Column(
          children: [
            buildPlot(plotNo: '22', area: '150 Sq.Yds', size: '36’-6” x 37’-2”', color: grey),
            buildPlot(plotNo: '23', area: '150 Sq.Yds', size: '35’-3” x 37’-9”', color: grey),
            buildPlot(plotNo: '24', area: '150 Sq.Yds', size: '35’-8” x 38’-4”', color: grey),
            buildPlot(plotNo: '25', area: '150 Sq.Yds', size: '35’-0” x 38’-6”', color: grey),
            buildPlot(plotNo: '26', area: '150 Sq.Yds', size: '34’-0” x 39’-6”', color: grey),
            buildPlot(plotNo: '27', area: '200 Sq.Yds', size: '45’-0” x 40’-0”', color: yellow),
          ],
        ),

        buildRoad("27.5’ WIDE ROAD"),

        /// Rightmost Blue Column (100 Sq.Yds)
        Column(
          children: List.generate(12, (i) => buildPlot(
            plotNo: '${21 - i}',
            area: '100 Sq.Yds',
            size: '22’-6”',
            color: blue,
          )),
        ),
      ],
    );
  }
}
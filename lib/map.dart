import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StadiumMap extends StatefulWidget {
  const StadiumMap({super.key});

  @override
  State<StadiumMap> createState() => _StadiumMapState();
}

class _Section {
  final Rect rect;
  final String label;
  final List<String> seats;
  _Section(this.rect, this.label, this.seats);
}

class _StadiumMapState extends State<StadiumMap> {
  final List<_Section> sections = [];
  final List<Offset> wcPositions = [];
  final List<Rect> exitPositions = [];

  ui.Image? wcImage;
  ui.Image? exitImage;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    wcImage = await _loadImage('images/wew.png');
    exitImage = await _loadImage('images/emergency.png');
    setState(() {});
  }

  Future<ui.Image> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void showInfoDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void showSeatsDialog(
    String sectionLabel,
    List<String> seats,
    bool isSecondTier,
  ) {
    final limitedSeats = seats.take(14).toList();
    final row1 = limitedSeats.take(7).toList();
    final row2 = limitedSeats.skip(7).take(7).toList();
    final seatColor =
        isSecondTier
            ? const ui.Color.fromARGB(209, 86, 92, 166)
            : const ui.Color.fromARGB(255, 167, 215, 255);

    Widget buildSeat(String seat) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: seatColor,
              child: Text(
                seat.split('-').last,
                style: const TextStyle(fontSize: 10, color: Colors.black),
              ),
            ),
            const SizedBox(height: 4),
            Text(seat, style: const TextStyle(fontSize: 10)),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Section $sectionLabel'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: row1.map(buildSeat).toList()),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: row2.map(buildSeat).toList()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 213, 230, 255), // أزرق فاتح
                Colors.white, // أبيض
              ],
            ),
          ),
        ),

        
        Column(
          children: [
          
            Expanded(
              flex: 8,
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(100),
                minScale: 0.5,
                maxScale: 4,
                child: GestureDetector(
                  onTapDown: (details) {
                    final pos = details.localPosition;

                    for (final wc in wcPositions) {
                      if ((pos - wc).distance <= 12) {
                        showInfoDialog("Bathroom");
                        return;
                      }
                    }

                    for (final exit in exitPositions) {
                      if (exit.contains(pos)) {
                        showInfoDialog("Emergency exit");
                        return;
                      }
                    }

                    for (final section in sections) {
                      if (section.rect.contains(pos)) {
                        final isSecondTier = section.seats.first.contains(
                          '-2-',
                        );
                        showSeatsDialog(
                          section.label,
                          section.seats,
                          isSecondTier,
                        );
                        return;
                      }
                    }
                  },
                  child: CustomPaint(
                    size: const Size(700, 500),
                    painter: StadiumPainter(
                      sections,
                      wcPositions,
                      exitPositions,
                      wcImage,
                      exitImage,
                    ),
                  ),
                ),
              ),
            ),

          
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
         
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      legendItem(
                        color: const Color(0xFF94D1EE),
                        label: 'First Tier',
                      ),
                      legendItem(
                        color: const ui.Color.fromARGB(255, 48, 82, 150),
                        label: 'Second Tier',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      legendImage(path: 'images/wew.png', label: 'WC'),
                      legendImage(
                        path: 'images/emergency.png',
                        label: 'Emergency Exit',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget legendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget legendImage({required String path, required String label}) {
    return Row(
      children: [
        Image.asset(path, width: 20, height: 20),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class StadiumPainter extends CustomPainter {
  final List<_Section> sections;
  final List<Offset> wcPositions;
  final List<Rect> exitPositions;
  final ui.Image? wcImage;
  final ui.Image? exitImage;

  StadiumPainter(
    this.sections,
    this.wcPositions,
    this.exitPositions,
    this.wcImage,
    this.exitImage,
  );

  void drawText(Canvas canvas, Offset offset, String text) {
    const textStyle = TextStyle(
      color: ui.Color.fromARGB(255, 255, 255, 255),
      fontSize: 10,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        offset.dx - textPainter.width / 2,
        offset.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    const double fieldW = 280;
    const double fieldH = 140;
    final double fieldLeft = (size.width - fieldW) / 2;
    final double fieldTop = (size.height - fieldH) / 2;
    const double sectionWidth = 20;
    const double sectionHeight = 30;
    const double gapTop = 35;
    const double gapBottom = 60;

    final Paint fieldPaint =
        Paint()..color = const ui.Color.fromARGB(255, 58, 123, 50);
    final Paint linePaint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
    final Paint bluePaint = Paint()..color = const Color(0xFF94D1EE);
    final Paint purplePaint =
        Paint()..color = const ui.Color.fromARGB(255, 48, 75, 161);

    int counter = 1;

    final Rect field = Rect.fromLTWH(fieldLeft, fieldTop, fieldW, fieldH);
    canvas.drawRect(field, fieldPaint);
    canvas.drawRect(field, linePaint);
    final Rect leftPenaltyArea = Rect.fromLTWH(
      fieldLeft,
      fieldTop + fieldH / 4,
      18,
      fieldH / 2,
    );
    canvas.drawRect(leftPenaltyArea, linePaint);

    // منطقة الجزاء اليمنى
    final Rect rightPenaltyArea = Rect.fromLTWH(
      fieldLeft + fieldW - 18,
      fieldTop + fieldH / 4,
      18,
      fieldH / 2,
    );
    canvas.drawRect(rightPenaltyArea, linePaint);

    final double midX = fieldLeft + fieldW / 2;
    final double fieldMidY = fieldTop + fieldH / 2;
    canvas.drawLine(
      Offset(midX, fieldTop),
      Offset(midX, fieldTop + fieldH),
      linePaint,
    );
    canvas.drawCircle(Offset(midX, fieldMidY), 20, linePaint);
    canvas.drawCircle(
      Offset(midX, fieldMidY),
      2,
      Paint()..color = Colors.white,
    );

    for (int i = 0; i < 5; i++) {
      double y = fieldTop + i * (fieldH / 5);
      Rect left = Rect.fromLTWH(
        fieldLeft - sectionWidth,
        y,
        sectionWidth,
        fieldH / 5,
      );
      canvas.drawRect(left, bluePaint);
      drawText(canvas, left.center, '${counter}');
      sections.add(
        _Section(
          left,
          '${counter++}',
          List.generate(14, (j) => 'L1-${counter - 1}-${j + 1}'),
        ),
      );

      Rect right = Rect.fromLTWH(
        fieldLeft + fieldW,
        y,
        sectionWidth,
        fieldH / 5,
      );
      canvas.drawRect(right, bluePaint);
      drawText(canvas, right.center, '${counter}');
      sections.add(
        _Section(
          right,
          '${counter++}',
          List.generate(14, (j) => 'R1-${counter - 1}-${j + 1}'),
        ),
      );
    }

    for (int i = 0; i < 13; i++) {
      double x = fieldLeft + i * (fieldW / 13);
      Rect top = Rect.fromLTWH(
        x,
        fieldTop - sectionHeight,
        fieldW / 13,
        sectionHeight,
      );
      canvas.drawRect(top, bluePaint);
      drawText(canvas, top.center, '${counter}');
      sections.add(
        _Section(
          top,
          '${counter++}',
          List.generate(14, (j) => 'T1-${counter - 1}-${j + 1}'),
        ),
      );

      Rect bottom = Rect.fromLTWH(
        x,
        fieldTop + fieldH,
        fieldW / 13,
        sectionHeight,
      );
      canvas.drawRect(bottom, bluePaint);
      drawText(canvas, bottom.center, '${counter}');
      sections.add(
        _Section(
          bottom,
          '${counter++}',
          List.generate(14, (j) => 'B1-${counter - 1}-${j + 1}'),
        ),
      );
    }

    final blueCorners = [
      Offset(fieldLeft - sectionWidth, fieldTop - sectionHeight),
      Offset(fieldLeft + fieldW, fieldTop - sectionHeight),
      Offset(fieldLeft - sectionWidth, fieldTop + fieldH),
      Offset(fieldLeft + fieldW, fieldTop + fieldH),
    ];
    for (final offset in blueCorners) {
      Rect rect = Rect.fromLTWH(
        offset.dx,
        offset.dy,
        sectionWidth,
        sectionHeight,
      );
      canvas.drawRect(rect, bluePaint);
      drawText(canvas, rect.center, '${counter}');
      sections.add(
        _Section(
          rect,
          '${counter++}',
          List.generate(14, (j) => 'C1-${counter - 1}-${j + 1}'),
        ),
      );
    }

    for (int i = 0; i < 9; i++) {
      double y =
          fieldTop - sectionHeight * 2 + i * ((fieldH + sectionHeight * 4) / 9);
      Rect left = Rect.fromLTWH(
        fieldLeft - sectionWidth * 2,
        y,
        sectionWidth,
        (fieldH + sectionHeight * 4) / 9,
      );
      canvas.drawRect(left, purplePaint);
      drawText(canvas, left.center, '${counter}');
      sections.add(
        _Section(
          left,
          '${counter++}',
          List.generate(14, (j) => 'L2-${counter - 1}-${j + 1}'),
        ),
      );

      Rect right = Rect.fromLTWH(
        fieldLeft + fieldW + sectionWidth,
        y,
        sectionWidth,
        (fieldH + sectionHeight * 4) / 9,
      );
      canvas.drawRect(right, purplePaint);
      drawText(canvas, right.center, '${counter}');
      sections.add(
        _Section(
          right,
          '${counter++}',
          List.generate(14, (j) => 'R2-${counter - 1}-${j + 1}'),
        ),
      );
    }

    for (int i = 0; i < 17; i++) {
      double x =
          fieldLeft - sectionWidth + i * ((fieldW + sectionWidth * 2) / 17);
      Rect top = Rect.fromLTWH(
        x,
        fieldTop - sectionHeight * 2,
        (fieldW + sectionWidth * 2) / 17,
        sectionHeight,
      );
      canvas.drawRect(top, purplePaint);
      drawText(canvas, top.center, '${counter}');
      sections.add(
        _Section(
          top,
          '${counter++}',
          List.generate(14, (j) => 'T2-${counter - 1}-${j + 1}'),
        ),
      );

      Rect bottom = Rect.fromLTWH(
        x,
        fieldTop + fieldH + sectionHeight,
        (fieldW + sectionWidth * 2) / 17,
        sectionHeight,
      );
      canvas.drawRect(bottom, purplePaint);
      drawText(canvas, bottom.center, '${counter}');
      sections.add(
        _Section(
          bottom,
          '${counter++}',
          List.generate(14, (j) => 'B2-${counter - 1}-${j + 1}'),
        ),
      );
    }

    final purpleCorners = [
      Offset(fieldLeft - sectionWidth * 2, fieldTop - sectionHeight * 2),
      Offset(fieldLeft + fieldW + sectionWidth, fieldTop - sectionHeight * 2),
      Offset(fieldLeft - sectionWidth * 2, fieldTop + fieldH + sectionHeight),
      Offset(
        fieldLeft + fieldW + sectionWidth,
        fieldTop + fieldH + sectionHeight,
      ),
    ];
    for (final offset in purpleCorners) {
      Rect rect = Rect.fromLTWH(
        offset.dx,
        offset.dy,
        sectionWidth,
        sectionHeight,
      );
      canvas.drawRect(rect, purplePaint);
      drawText(canvas, rect.center, '${counter}');
      sections.add(
        _Section(
          rect,
          '${counter++}',
          List.generate(14, (j) => 'C2-${counter - 1}-${j + 1}'),
        ),
      );
    }

    final double wcMidX = fieldLeft + fieldW / 2;
    final double wcMidY = fieldTop + fieldH / 2;
    const double sideOffsetX = 80;
    const double sideOffsetY = 30;

    final wcSpots = [
      Offset(wcMidX + 30, fieldTop - sectionHeight * 2 - gapTop),
      Offset(wcMidX + 30, fieldTop + fieldH + sectionHeight + gapBottom),
      Offset(fieldLeft - sideOffsetX, wcMidY - sideOffsetY),
      Offset(fieldLeft + fieldW + sideOffsetX, wcMidY - sideOffsetY),
    ];
    wcPositions.addAll(wcSpots);

    final exitSpots = [
      Rect.fromLTWH(
        wcMidX - 30,
        fieldTop - sectionHeight * 2 - gapTop - 10,
        20,
        10,
      ),
      Rect.fromLTWH(
        wcMidX - 30,
        fieldTop + fieldH + sectionHeight + gapBottom - 10,
        20,
        10,
      ),
      Rect.fromLTWH(fieldLeft - sideOffsetX - 10, wcMidY + 10, 20, 10),
      Rect.fromLTWH(fieldLeft + fieldW + sideOffsetX - 10, wcMidY + 10, 20, 10),
    ];
    exitPositions.addAll(exitSpots);

    if (wcImage != null) {
      for (final offset in wcPositions) {
        canvas.drawImageRect(
          wcImage!,
          Rect.fromLTWH(
            0,
            0,
            wcImage!.width.toDouble(),
            wcImage!.height.toDouble(),
          ),
          Rect.fromCenter(center: offset, width: 30, height: 30),
          Paint(),
        );
      }
    }

    if (exitImage != null) {
      for (final rect in exitPositions) {
        canvas.drawImageRect(
          exitImage!,
          Rect.fromLTWH(
            0,
            0,
            exitImage!.width.toDouble(),
            exitImage!.height.toDouble(),
          ),
          rect.inflate(6),
          Paint(),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant StadiumPainter oldDelegate) {
    return oldDelegate.wcImage != wcImage || oldDelegate.exitImage != exitImage;
  }
}

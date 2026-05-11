part of 'sekigahara.dart';

class MapOverlayPainter extends CustomPainter {
  const MapOverlayPainter({
    required this.mode,
    required this.currentTime,
    required this.markers,
    required this.units,
    required this.events,
    required this.primaryEvent,
    required this.hoveredUnitId,
    required this.hoveredMarkerId,
    required this.selectedUnitId,
    required this.showLabels,
    required this.showDebug,
    required this.lastDebugPoint,
    required this.pulse,
    required this.screenScale,
  });

  final MapMode mode;
  final DateTime currentTime;
  final List<MapMarker> markers;
  final List<ArmyUnit> units;
  final List<CampaignEvent> events;
  final CampaignEvent? primaryEvent;
  final String? hoveredUnitId;
  final String? hoveredMarkerId;
  final String? selectedUnitId;
  final bool showLabels;
  final bool showDebug;
  final MapPoint? lastDebugPoint;
  final double pulse;
  final double screenScale;
  double get invScale => 1 / math.max(screenScale, 0.1);

  @override
  void paint(Canvas canvas, Size size) {
    _drawActiveEventRings(canvas);
    _drawMarkers(canvas);
    _drawUnits(canvas);
    _drawDebug(canvas, size);
  }

  void _drawActiveEventRings(Canvas canvas) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * invScale;
    for (final event in events) {
      if (!event.activeAt(currentTime)) continue;
      final p = event.pointFor(mode).toOffset();
      final r = (22 + 18 * pulse) * invScale;
      ringPaint.color = _statusColor(event.status).withOpacity((0.75 * (1 - pulse)).clamp(0.08, 0.75));
      ringPaint.strokeWidth = 3.0 * invScale;
      canvas.drawCircle(p, r, ringPaint);
      ringPaint.strokeWidth = 1.6 * invScale;
      canvas.drawCircle(p, r * 0.55, ringPaint);
    }
  }

  void _drawMarkers(Canvas canvas) {
    for (final marker in markers) {
      if (mode == MapMode.campaign && marker.kind == PointKind.mountain) continue;
      final point = marker.pointFor(mode);
      if (point == null) continue;
      final p = point.toOffset();

      if (marker.kind == PointKind.castle) {
        _drawCastle(canvas, p, marker.important);
      } else if (marker.kind == PointKind.mountain) {
        _drawMountain(canvas, p);
      }

      if (hoveredMarkerId == marker.id) {
        _drawFloatingLabel(canvas, marker.name, p + Offset(12 * invScale, -20 * invScale));
      }
    }
  }

  void _drawCastle(Canvas canvas, Offset p, bool important) {
    final s = (important ? 10.8 : 9.2) * invScale;
    final paint = Paint()
      ..color = const Color(0xFFEEE5C8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * invScale
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final shadow = Paint()
      ..color = const Color(0xAA1B130B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * invScale
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    Path pathAt(Offset o) => Path()
      ..moveTo(o.dx - s, o.dy + s * 0.6)
      ..lineTo(o.dx - s, o.dy - s * 0.2)
      ..lineTo(o.dx - s * 0.35, o.dy - s * 0.2)
      ..lineTo(o.dx - s * 0.35, o.dy - s * 0.85)
      ..lineTo(o.dx + s * 0.35, o.dy - s * 0.85)
      ..lineTo(o.dx + s * 0.35, o.dy - s * 0.2)
      ..lineTo(o.dx + s, o.dy - s * 0.2)
      ..lineTo(o.dx + s, o.dy + s * 0.6);

    canvas.drawPath(pathAt(p + Offset(1.2 * invScale, 1.2 * invScale)), shadow);
    canvas.drawPath(pathAt(p), paint);
  }

  void _drawMountain(Canvas canvas, Offset p) {
    final s = 14.0 * invScale;
    final paint = Paint()
      ..color = const Color(0xFFE8E0CA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * invScale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final shadow = Paint()
      ..color = const Color(0xAA1B130B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4 * invScale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(p.dx - s, p.dy + s * 0.35)
      ..lineTo(p.dx - s * 0.35, p.dy - s * 0.45)
      ..lineTo(p.dx, p.dy + s * 0.1)
      ..lineTo(p.dx + s * 0.45, p.dy - s * 0.65)
      ..lineTo(p.dx + s, p.dy + s * 0.35);

    canvas.drawPath(path.shift(Offset(1.3 * invScale, 1.3 * invScale)), shadow);
    canvas.drawPath(path, paint);
  }

  void _drawUnits(Canvas canvas) {
    for (final unit in units) {
      if (!unit.visibleAt(currentTime, mode)) continue;
      if (mode == MapMode.sekigaharaBattle && unit.frames.every((f) => f.battlePoint == null)) continue;

      final frame = unit.stateAt(currentTime);
      final p = unit.pointAt(currentTime, mode).toOffset();

      if (frame.action == UnitAction.destroyed || frame.action == UnitAction.captured || frame.action == UnitAction.executed) {
        _drawDestruction(canvas, p, unit, frame);
        continue;
      }

      final direction = unit.directionAt(currentTime, mode);
      final active = selectedUnitId == unit.id || hoveredUnitId == unit.id;
      _drawUnitIcon(canvas, p, direction, frame.side, frame.action, frame.troops, unit.minor, active);
      if (active) _drawFloatingLabel(canvas, unit.name, p + Offset(12 * invScale, -20 * invScale));
      _drawUnitEffect(canvas, p, frame);
    }
  }

  void _drawUnitIcon(Canvas canvas, Offset p, Offset direction, Side side, UnitAction action, int troops, bool minor, bool active) {
    final color = side == Side.east
        ? const Color(0xFF2868C7)
        : side == Side.west
            ? const Color(0xFFC82E35)
            : const Color(0xFF666666);

    final troopScale = (0.72 + math.sqrt(math.max(troops, 1)) / 145).clamp(0.72, 1.55);
    final base = (mode == MapMode.campaign ? 15.5 : 15.0) * (minor ? 0.82 : 1.0) * troopScale * invScale;
    final barStroke = (active ? 8.4 : 7.0) * (minor ? 0.92 : 1.0) * invScale;
    final stemStroke = barStroke * 1.28;
    final angle = math.atan2(direction.dy, direction.dx) - math.pi / 2;

    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(angle);

    final glow = Paint()
      ..color = color.withOpacity(active ? 0.34 : 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stemStroke * 2.0
      ..strokeCap = StrokeCap.square;
    final edgeBar = Paint()
      ..color = const Color(0xCC1C120A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = barStroke + 2.4 * invScale
      ..strokeCap = StrokeCap.square;
    final edgeStem = Paint()
      ..color = const Color(0xCC1C120A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stemStroke + 2.8 * invScale
      ..strokeCap = StrokeCap.square;
    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = barStroke
      ..strokeCap = StrokeCap.square;
    final stemPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stemStroke
      ..strokeCap = StrokeCap.square;

    final bar = Path()
      ..moveTo(-base * 0.52, 0)
      ..lineTo(base * 0.52, 0);
    final stem = Path()
      ..moveTo(0, -base * 0.03)
      ..lineTo(0, base * 0.58);

    canvas.drawPath(stem, glow);
    canvas.drawPath(bar, glow);
    canvas.drawPath(stem, edgeStem);
    canvas.drawPath(bar, edgeBar);
    canvas.drawPath(stem, stemPaint);
    canvas.drawPath(bar, barPaint);

    if (action == UnitAction.betrayed || action == UnitAction.winning) {
      canvas.drawCircle(Offset.zero, 3.2 * invScale, Paint()..color = const Color(0xFFFFD36A));
    }
    canvas.restore();
  }

  void _drawDestruction(Canvas canvas, Offset p, ArmyUnit unit, UnitFrame frame) {
    final elapsed = currentTime.difference(frame.time).inMinutes.clamp(0, 35);
    final t = elapsed / 35.0;
    final color = frame.side == Side.east ? const Color(0xFF2868C7) : const Color(0xFFC82E35);
    final rng = math.Random(unit.id.hashCode);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 14; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      final dist = (4 + rng.nextDouble() * 28) * t * invScale;
      final pos = p + Offset(math.cos(a), math.sin(a)) * dist;
      final s = (2.5 + rng.nextDouble() * 3.5) * (1 - t) * invScale;
      paint.color = (i.isEven ? color : const Color(0xFF2B1B12)).withOpacity((1 - t).clamp(0.0, 1.0));
      canvas.drawRect(Rect.fromCenter(center: pos, width: s, height: s * 0.7), paint);
    }

    if (t < 0.75) {
      _drawOutlinedText(canvas, '壊滅', p + Offset(-18 * invScale, -24 * invScale), 15 * invScale, const Color(0xFFFF6060));
    }
  }

  void _drawUnitEffect(Canvas canvas, Offset p, UnitFrame frame) {
    final elapsed = currentTime.difference(frame.time).inMinutes;

    String? text;
    Color color = const Color(0xFFFFD36A);
    int duration = 0;

    switch (frame.action) {
      case UnitAction.betrayed:
        text = '裏切り！';
        color = const Color(0xFFFF5EA8);
        duration = 45;
        break;
      case UnitAction.retreating:
        text = '退却';
        color = const Color(0xFFFF9C48);
        duration = 35;
        break;
      case UnitAction.collapsing:
        text = '敗北';
        color = const Color(0xFFFF4C4C);
        duration = 30;
        break;
      case UnitAction.winning:
        if (mode == MapMode.sekigaharaBattle) {
          text = '優勢';
          color = const Color(0xFFFFD36A);
          duration = 25;
        }
        break;
      default:
        break;
    }

    if (text == null || elapsed < 0 || elapsed > duration) return;

    final fade = (1.0 - elapsed / duration).clamp(0.0, 1.0);
    final r = (18 + 14 * pulse) * invScale;
    final ringPaint = Paint()
      ..color = color.withOpacity((0.45 * (1 - pulse) * fade).clamp(0.02, 0.45))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * invScale;
    canvas.drawCircle(p, r, ringPaint);
    _drawOutlinedText(
      canvas,
      text,
      p + Offset(-18 * invScale, (-32 + math.sin(pulse * math.pi * 2) * 3) * invScale),
      16 * invScale,
      color.withOpacity(fade),
    );
  }

  void _drawFloatingLabel(Canvas canvas, String text, Offset p) {
    _drawOutlinedText(canvas, text, p, 12.5 * invScale, const Color(0xFFFFF2C9));
  }

  void _drawOutlinedText(Canvas canvas, String text, Offset p, double fontSize, Color color) {
    final stroke = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0 * invScale
            ..color = const Color(0xDD1A1008),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    stroke.paint(canvas, p);

    final fill = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 8 * invScale)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    fill.paint(canvas, p);
  }

  void _drawDebug(Canvas canvas, Size size) {
    if (!showDebug) return;
    final grid = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 0.6 * invScale;

    for (var x = 0.0; x <= size.width; x += 100) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += 100) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (lastDebugPoint != null) {
      final p = lastDebugPoint!.toOffset();
      final paint = Paint()
        ..color = const Color(0xFFFFE16B)
        ..strokeWidth = 2 * invScale;
      canvas.drawLine(p + Offset(-12 * invScale, 0), p + Offset(12 * invScale, 0), paint);
      canvas.drawLine(p + Offset(0, -12 * invScale), p + Offset(0, 12 * invScale), paint);
      _drawOutlinedText(canvas, 'x:${lastDebugPoint!.x.toStringAsFixed(0)} y:${lastDebugPoint!.y.toStringAsFixed(0)}', p + Offset(10 * invScale, 10 * invScale), 12 * invScale, const Color(0xFFFFE16B));
    }
  }

  Color _statusColor(String status) {
    if (status.contains('勝') || status.contains('終結') || status.contains('優勢')) return const Color(0xFFFFD36A);
    if (status.contains('撤退') || status.contains('遅延') || status.contains('移動')) return const Color(0xFFFF9C48);
    if (status.contains('落城') || status.contains('壊滅') || status.contains('崩壊')) return const Color(0xFFFF5D5D);
    if (status.contains('寝返り')) return const Color(0xFFFF5EA8);
    return const Color(0xFFECD37A);
  }

  @override
  bool shouldRepaint(covariant MapOverlayPainter oldDelegate) => true;
}

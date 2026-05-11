part of 'sekigahara.dart';

enum MapMode { campaign, sekigaharaBattle }
enum Side { east, west, neutral }
enum PointKind { castle, mountain, place, battlefield }

enum UnitAction {
  waiting,
  marching,
  deployed,
  fighting,
  winning,
  pressured,
  collapsing,
  retreating,
  betrayed,
  besieging,
  defending,
  delayed,
  captured,
  executed,
  destroyed,
}

class MapPoint {
  const MapPoint(this.x, this.y);
  final double x;
  final double y;
  Offset toOffset() => Offset(x, y);
  MapPoint lerp(MapPoint other, double t) => MapPoint(
        x + (other.x - x) * t,
        y + (other.y - y) * t,
      );
}

class UnitFrame {
  const UnitFrame({
    required this.time,
    required this.campaignPoint,
    this.battlePoint,
    required this.side,
    required this.action,
    required this.troops,
    required this.place,
    required this.note,
  });

  final DateTime time;
  final MapPoint campaignPoint;
  final MapPoint? battlePoint;
  final Side side;
  final UnitAction action;
  final int troops;
  final String place;
  final String note;
}

class ArmyUnit {
  const ArmyUnit({
    required this.id,
    required this.name,
    required this.commander,
    required this.initialSide,
    required this.initialTroops,
    required this.frames,
    this.battleOnly = false,
    this.minor = false,
  });

  final String id;
  final String name;
  final String commander;
  final Side initialSide;
  final int initialTroops;
  final List<UnitFrame> frames;
  final bool battleOnly;
  final bool minor;

  bool visibleAt(DateTime time, MapMode mode) {
    if (frames.isEmpty) return false;
    if (battleOnly && mode == MapMode.campaign) return false;
    if (time.isBefore(frames.first.time)) return false;

    final s = stateAt(time);
    if (s.action == UnitAction.destroyed ||
        s.action == UnitAction.captured ||
        s.action == UnitAction.executed) {
      return time.difference(s.time).inMinutes <= 35;
    }
    return true;
  }

  UnitFrame stateAt(DateTime time) {
    UnitFrame current = frames.first;
    for (final f in frames) {
      if (!f.time.isAfter(time)) {
        current = f;
      } else {
        break;
      }
    }
    return current;
  }

  MapPoint pointAt(DateTime time, MapMode mode) {
    UnitFrame previous = frames.first;
    UnitFrame next = frames.first;

    for (var i = 0; i < frames.length; i++) {
      final f = frames[i];
      if (!f.time.isAfter(time)) {
        previous = f;
        next = i + 1 < frames.length ? frames[i + 1] : f;
      } else {
        next = f;
        break;
      }
    }

    final a = _pointOf(previous, mode);
    final b = _pointOf(next, mode);
    if (previous.time == next.time) return a;
    if (time.isBefore(previous.time)) return a;
    if (time.isAfter(next.time)) return b;

    final total = next.time.difference(previous.time).inSeconds;
    final elapsed = time.difference(previous.time).inSeconds;
    if (total <= 0) return a;
    return a.lerp(b, Curves.easeInOut.transform((elapsed / total).clamp(0.0, 1.0)));
  }

  Offset directionAt(DateTime time, MapMode mode) {
    UnitFrame previous = frames.first;
    UnitFrame? next;
    for (var i = 0; i < frames.length; i++) {
      if (!frames[i].time.isAfter(time)) {
        previous = frames[i];
        if (i + 1 < frames.length) next = frames[i + 1];
      }
    }

    if (next == null) {
      final i = frames.indexOf(previous);
      if (i > 0) {
        final a = _pointOf(frames[i - 1], mode).toOffset();
        final b = _pointOf(previous, mode).toOffset();
        final d = b - a;
        if (d.distance > 0.5) return d / d.distance;
      }
      return const Offset(0, -1);
    }

    final a = _pointOf(previous, mode).toOffset();
    final b = _pointOf(next, mode).toOffset();
    final d = b - a;
    if (d.distance < 0.5) return const Offset(0, -1);
    return d / d.distance;
  }

  MapPoint _pointOf(UnitFrame f, MapMode mode) {
    if (mode == MapMode.sekigaharaBattle && f.battlePoint != null) return f.battlePoint!;
    return f.campaignPoint;
  }
}

class MapMarker {
  const MapMarker({
    required this.id,
    required this.name,
    required this.kind,
    required this.campaignPoint,
    this.battlePoint,
    this.important = false,
  });

  final String id;
  final String name;
  final PointKind kind;
  final MapPoint campaignPoint;
  final MapPoint? battlePoint;
  final bool important;

  MapPoint? pointFor(MapMode mode) => mode == MapMode.sekigaharaBattle ? battlePoint : campaignPoint;
}

class CampaignEvent {
  const CampaignEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.location,
    required this.campaignPoint,
    this.battlePoint,
    required this.eastForce,
    required this.westForce,
    required this.scale,
    required this.summary,
    required this.status,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String location;
  final MapPoint campaignPoint;
  final MapPoint? battlePoint;
  final String eastForce;
  final String westForce;
  final String scale;
  final String summary;
  final String status;

  bool activeAt(DateTime time) => !time.isBefore(start) && !time.isAfter(end);
  bool nearAt(DateTime time, Duration window) =>
      time.isAfter(start.subtract(window)) && time.isBefore(end.add(window));
  MapPoint pointFor(MapMode mode) =>
      mode == MapMode.sekigaharaBattle && battlePoint != null ? battlePoint! : campaignPoint;
}

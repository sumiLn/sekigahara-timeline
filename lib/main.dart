
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const SekigaharaTimelineApp());

class SekigaharaTimelineApp extends StatelessWidget {
  const SekigaharaTimelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '関ヶ原戦役タイムマップ',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Noto Sans JP',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7A1F1F),
          brightness: Brightness.dark,
        ),
      ),
      home: const SekigaharaMapPage(),
    );
  }
}

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

class SekigaharaData {
  static const campaignAsset = 'assets/maps/sekigahara_base_map.png';
  static const battleAsset = 'assets/maps/sekigahara_battle_map.png';

  static const campaignImageSize = Size(1536, 1024);
  static const battleImageSize = Size(1448, 1086);

  static DateTime get campaignStart => DateTime(1600, 6, 18);
  static DateTime get campaignInitial => DateTime(1600, 7, 17);
  static DateTime get campaignEnd => DateTime(1600, 10, 25, 23, 59);

  static DateTime get battleStart => DateTime(1600, 9, 14, 18);
  static DateTime get battleInitial => DateTime(1600, 9, 15, 6);
  static DateTime get battleEnd => DateTime(1600, 9, 15, 16, 30);

  static const c = <String, MapPoint>{
    'osaka': MapPoint(642, 704),
    'fushimi': MapPoint(657, 686),
    'otsu': MapPoint(666, 676),
    'tanabe': MapPoint(637, 641),
    'gifu': MapPoint(733, 648),
    'ogaki': MapPoint(720, 654),
    'sekigahara': MapPoint(704, 660),
    'sawayama': MapPoint(690, 674),
    'anotsu': MapPoint(704, 724),
    'kuwana': MapPoint(722, 694),
    'kiso': MapPoint(742, 642),
    'ueda': MapPoint(824, 610),
    'edo': MapPoint(920, 686),
    'aizu': MapPoint(960, 560),
    'hasedo': MapPoint(982, 511),
    'hataya': MapPoint(982, 525),
    'sendai': MapPoint(1032, 532),
    'nakatsu': MapPoint(322, 733),
    'bungo': MapPoint(342, 792),
    'kitsuki': MapPoint(340, 760),
    'ishigakibaru': MapPoint(340, 805),
    'aki': MapPoint(358, 770),
    'uto': MapPoint(266, 792),
    'miyazaki': MapPoint(360, 900),
    'kokura': MapPoint(315, 700),
    'yanagawa': MapPoint(254, 761),
    'iyo': MapPoint(520, 745),
    'hiroshima': MapPoint(510, 690),
    'kiyosu': MapPoint(738, 660),
    'hamamatsu': MapPoint(805, 690),
    'kyushuCoast': MapPoint(330, 770),
  };

  // battle_map 実測座標：
  // 松尾山105,607 / 桃配山687,378 / 栗原山1355,821 / 大垣城1426,177 / 南宮山906,439
  // 他は上記から補完。
  static const b = <String, MapPoint>{
    'matsuo': MapPoint(105, 607),
    'momokubari': MapPoint(687, 378),
    'kurihara': MapPoint(1355, 821),
    'ogaki': MapPoint(1426, 177),
    'nangu': MapPoint(906, 439),

    'ibuki': MapPoint(250, 160),
    'sasao': MapPoint(420, 315),
    'tenma': MapPoint(330, 500),
    'sekigahara': MapPoint(520, 465),
    'fujikawa': MapPoint(420, 565),
    'akasaka': MapPoint(980, 250),
    'tarui': MapPoint(790, 350),
    'kuisegawa': MapPoint(1120, 230),
    'yamanaka': MapPoint(330, 560),
    'imao': MapPoint(760, 520),
    'nakasendoEast': MapPoint(930, 340),
    'nakasendoCenter': MapPoint(680, 405),
    'northernFront': MapPoint(535, 360),
    'centralFront': MapPoint(540, 455),
    'southernFront': MapPoint(560, 520),

    // 本戦用の対峙点。敵味方が補間で入り乱れないよう、
    // 西軍側・東軍側の前線を分ける。
    'westNorthApproach': MapPoint(470, 340),
    'westNorthFront': MapPoint(455, 365),
    'westCentralApproach': MapPoint(470, 455),
    'westCentralFront': MapPoint(470, 485),
    'westSouthFront': MapPoint(360, 555),
    'eastNorthFront': MapPoint(545, 370),
    'eastNorthPressure': MapPoint(500, 365),
    'eastCentralFront': MapPoint(570, 455),
    'eastCentralPressure': MapPoint(515, 465),
    'eastSouthFront': MapPoint(585, 520),
    'eastSouthPressure': MapPoint(430, 545),
    'kobayakawaDescent': MapPoint(190, 585),
    'kobayakawaAttack': MapPoint(260, 565),
    'otaniFlank': MapPoint(330, 565),

    'matsuoFoot': MapPoint(210, 565),
    'eastRear': MapPoint(850, 405),
    'westRoad': MapPoint(575, 350),

    'ishida': MapPoint(410, 335),
    'sakon': MapPoint(455, 365),
    'ukita': MapPoint(430, 490),
    'konishi': MapPoint(505, 470),
    'otani': MapPoint(300, 555),
    'todahiratsuka': MapPoint(350, 580),
    'shimazu': MapPoint(590, 560),
    'kobayakawa': MapPoint(105, 607),
    'wakisaka': MapPoint(180, 560),

    'mori': MapPoint(900, 455),
    'kikkawa': MapPoint(845, 430),
    'ankokuji': MapPoint(870, 500),
    'chosokabe': MapPoint(930, 520),
    'natsuka': MapPoint(820, 510),

    'ieyasu': MapPoint(687, 378),
    'jinbano': MapPoint(610, 405),
    'honda': MapPoint(715, 395),
    'fukushima': MapPoint(545, 455),
    'kuroda': MapPoint(520, 360),
    'hosokawa': MapPoint(590, 430),
    'kato': MapPoint(610, 390),
    'ii': MapPoint(650, 420),
    'matsudaira': MapPoint(635, 445),
    'todo': MapPoint(620, 505),
    'kyogoku': MapPoint(660, 525),
    'tanaka': MapPoint(710, 470),
    'yamauchi': MapPoint(760, 490),
    'asano': MapPoint(820, 455),
    'ikeda': MapPoint(900, 380),
  };

  static DateTime d(int month, int day, [int hour = 0, int minute = 0]) =>
      DateTime(1600, month, day, hour, minute);

  static UnitFrame f(
    DateTime time,
    String cp,
    Side side,
    UnitAction action,
    int troops,
    String place,
    String note, {
    String? bp,
  }) {
    return UnitFrame(
      time: time,
      campaignPoint: c[cp]!,
      battlePoint: bp == null ? null : b[bp]!,
      side: side,
      action: action,
      troops: troops,
      place: place,
      note: note,
    );
  }

  static List<MapMarker> get markers => [
        const MapMarker(id: 'osaka', name: '大坂城', kind: PointKind.castle, campaignPoint: MapPoint(642, 704), important: true),
        const MapMarker(id: 'fushimi', name: '伏見城', kind: PointKind.castle, campaignPoint: MapPoint(657, 686), important: true),
        const MapMarker(id: 'otsu', name: '大津城', kind: PointKind.castle, campaignPoint: MapPoint(666, 676), important: true),
        const MapMarker(id: 'tanabe', name: '田辺城', kind: PointKind.castle, campaignPoint: MapPoint(637, 641)),
        const MapMarker(id: 'gifu', name: '岐阜城', kind: PointKind.castle, campaignPoint: MapPoint(733, 648), important: true),
        const MapMarker(id: 'ogaki', name: '大垣城', kind: PointKind.castle, campaignPoint: MapPoint(720, 654), battlePoint: MapPoint(1426, 177), important: true),
        const MapMarker(id: 'sawayama', name: '佐和山城', kind: PointKind.castle, campaignPoint: MapPoint(690, 674)),
        const MapMarker(id: 'ueda', name: '上田城', kind: PointKind.castle, campaignPoint: MapPoint(824, 610), important: true),
        const MapMarker(id: 'hasedo', name: '長谷堂城', kind: PointKind.castle, campaignPoint: MapPoint(982, 511), important: true),
        const MapMarker(id: 'nakatsu', name: '中津城', kind: PointKind.castle, campaignPoint: MapPoint(322, 733)),
        const MapMarker(id: 'uto', name: '宇土城', kind: PointKind.castle, campaignPoint: MapPoint(266, 792)),
        const MapMarker(id: 'yanagawa', name: '柳河城', kind: PointKind.castle, campaignPoint: MapPoint(254, 761)),
        const MapMarker(id: 'matsuo', name: '松尾山', kind: PointKind.mountain, campaignPoint: MapPoint(700, 665), battlePoint: MapPoint(105, 607), important: true),
        const MapMarker(id: 'momokubari', name: '桃配山', kind: PointKind.mountain, campaignPoint: MapPoint(710, 660), battlePoint: MapPoint(687, 378), important: true),
        const MapMarker(id: 'kurihara', name: '栗原山', kind: PointKind.mountain, campaignPoint: MapPoint(718, 675), battlePoint: MapPoint(1355, 821), important: true),
        const MapMarker(id: 'nangu', name: '南宮山', kind: PointKind.mountain, campaignPoint: MapPoint(712, 672), battlePoint: MapPoint(906, 439), important: true),
        const MapMarker(id: 'sasao', name: '笹尾山', kind: PointKind.mountain, campaignPoint: MapPoint(704, 658), battlePoint: MapPoint(420, 315)),
      ];

  static List<ArmyUnit> get units => [
        ArmyUnit(id: 'tokugawaIeyasu', name: '徳川家康本隊', commander: '徳川家康', initialSide: Side.east, initialTroops: 30000, frames: [
          f(d(6, 18), 'fushimi', Side.east, UnitAction.marching, 30000, '伏見', '会津征伐へ向かう'),
          f(d(9, 1), 'edo', Side.east, UnitAction.marching, 30000, '江戸', '江戸を出立し西上を開始'),
          f(d(9, 10), 'hamamatsu', Side.east, UnitAction.marching, 30000, '東海道方面', '東海道を西へ進む'),
          f(d(9, 14, 16, 0), 'ogaki', Side.east, UnitAction.deployed, 30000, '美濃赤坂', '美濃赤坂に着陣', bp: 'akasaka'),
          f(d(9, 14, 23, 30), 'ogaki', Side.east, UnitAction.marching, 30000, '赤坂陣地', '西軍の関ヶ原転進を受けて赤坂を出る', bp: 'akasaka'),
          f(d(9, 15, 2, 0), 'sekigahara', Side.east, UnitAction.marching, 30000, '中山道東側', '桃配山方面へ進む', bp: 'nakasendoEast'),
          f(d(9, 15, 5, 30), 'sekigahara', Side.east, UnitAction.marching, 30000, '桃配山手前', '本陣設営へ', bp: 'nakasendoCenter'),
          f(d(9, 15, 6, 0), 'sekigahara', Side.east, UnitAction.deployed, 30000, '桃配山', '東軍本陣を置く', bp: 'ieyasu'),
          f(d(9, 15, 10, 0), 'sekigahara', Side.east, UnitAction.marching, 30000, '陣場野方面', '戦況を見て本陣を前進させる', bp: 'jinbano'),
          f(d(9, 15, 13, 0), 'sekigahara', Side.east, UnitAction.winning, 30000, '陣場野方面', '小早川離反後、東軍優勢へ', bp: 'jinbano'),
          f(d(9, 15, 14, 30), 'sekigahara', Side.east, UnitAction.winning, 30000, '関ヶ原中央', '東軍勝利が決定的となる', bp: 'sekigahara'),
          f(d(9, 17), 'sawayama', Side.east, UnitAction.besieging, 30000, '佐和山城', '戦後処理へ'),
        ]),
        ArmyUnit(id: 'ishidaMitsunari', name: '石田三成隊', commander: '石田三成', initialSide: Side.west, initialTroops: 6000, frames: [
          f(d(7, 11), 'sawayama', Side.west, UnitAction.waiting, 6000, '佐和山城', '西軍決起の中枢として動く'),
          f(d(8, 5), 'sawayama', Side.west, UnitAction.marching, 6000, '佐和山城', '美濃方面へ向けて行動を強める'),
          f(d(8, 10), 'ogaki', Side.west, UnitAction.deployed, 6000, '大垣城', '大垣城に入り西軍前線拠点とする'),
          f(d(8, 23), 'gifu', Side.west, UnitAction.pressured, 6000, '岐阜城方面', '岐阜城救援に動くが東軍に阻まれる'),
          f(d(8, 26), 'ogaki', Side.west, UnitAction.defending, 6000, '大垣城', '赤坂方面の東軍と対峙'),
          f(d(9, 14, 19, 0), 'ogaki', Side.west, UnitAction.marching, 6000, '大垣城', '午後7時頃、大垣城を出陣', bp: 'ogaki'),
          f(d(9, 14, 22, 0), 'ogaki', Side.west, UnitAction.marching, 6000, '垂井方面', '関ヶ原へ夜間移動', bp: 'tarui'),
          f(d(9, 15, 2, 0), 'sekigahara', Side.west, UnitAction.marching, 6000, '関ヶ原西側', '笹尾山方面へ入る', bp: 'westRoad'),
          f(d(9, 15, 5, 0), 'sekigahara', Side.west, UnitAction.deployed, 6000, '笹尾山', '午前5時頃、西軍布陣完了', bp: 'ishida'),
          f(d(9, 15, 8, 0), 'sekigahara', Side.west, UnitAction.fighting, 5900, '笹尾山前面', '黒田・細川方面と対峙', bp: 'ishida'),
          f(d(9, 15, 10, 30), 'sekigahara', Side.west, UnitAction.fighting, 5600, '笹尾山', '北部戦線を支える', bp: 'ishida'),
          f(d(9, 15, 12, 30), 'sekigahara', Side.west, UnitAction.pressured, 5000, '笹尾山', '西軍右翼の動揺を受ける', bp: 'ishida'),
          f(d(9, 15, 13, 30), 'sekigahara', Side.west, UnitAction.collapsing, 3600, '笹尾山', '大谷隊崩壊後、戦線が崩れる', bp: 'ishida'),
          f(d(9, 15, 14, 0), 'sekigahara', Side.west, UnitAction.retreating, 1800, '笹尾山西側', '敗走へ', bp: 'sasao'),
          f(d(9, 21), 'sawayama', Side.west, UnitAction.captured, 0, '近江', '捕縛'),
        ]),
        ArmyUnit(id: 'shimaSakon', name: '島左近隊', commander: '島左近', initialSide: Side.west, initialTroops: 1000, battleOnly: true, minor: true, frames: [
          f(d(9, 15, 6, 0), 'sekigahara', Side.west, UnitAction.deployed, 1000, '笹尾山前面', '石田隊前面で布陣', bp: 'sakon'),
          f(d(9, 15, 8, 0), 'sekigahara', Side.west, UnitAction.fighting, 1000, '北部前線', '黒田隊方面へ出る', bp: 'northernFront'),
          f(d(9, 15, 10, 0), 'sekigahara', Side.west, UnitAction.fighting, 800, '笹尾山前面', '前線で激戦', bp: 'sakon'),
          f(d(9, 15, 12, 0), 'sekigahara', Side.west, UnitAction.pressured, 500, '笹尾山前面', '東軍に押される', bp: 'sakon'),
          f(d(9, 15, 13, 40), 'sekigahara', Side.west, UnitAction.destroyed, 0, '笹尾山前面', '戦線崩壊', bp: 'sakon'),
        ]),
        ArmyUnit(id: 'ukitaHideie', name: '宇喜多秀家隊', commander: '宇喜多秀家', initialSide: Side.west, initialTroops: 17000, frames: [
          f(d(7, 18), 'fushimi', Side.west, UnitAction.besieging, 17000, '伏見城方面', '西軍主力として伏見城攻めに参加'),
          f(d(8, 1), 'fushimi', Side.west, UnitAction.winning, 16800, '伏見城', '伏見城落城後、美濃方面へ再配置'),
          f(d(8, 26), 'ogaki', Side.west, UnitAction.deployed, 16800, '大垣城', '大垣城で東軍と対峙'),
          f(d(9, 14, 19, 0), 'ogaki', Side.west, UnitAction.marching, 16800, '大垣城', '西軍主力として関ヶ原へ出陣', bp: 'ogaki'),
          f(d(9, 14, 22, 30), 'ogaki', Side.west, UnitAction.marching, 16800, '垂井方面', '主力が街道を進む', bp: 'tarui'),
          f(d(9, 15, 2, 30), 'sekigahara', Side.west, UnitAction.marching, 16800, '関ヶ原中央西', '天満山方面へ', bp: 'westCentralApproach'),
          f(d(9, 15, 5, 0), 'sekigahara', Side.west, UnitAction.deployed, 16800, '西軍中央', '西軍中央主力として布陣', bp: 'ukita'),
          f(d(9, 15, 8, 5), 'sekigahara', Side.west, UnitAction.fighting, 16600, '中央戦線', '福島隊・井伊隊方面と交戦', bp: 'westCentralFront'),
          f(d(9, 15, 10, 30), 'sekigahara', Side.west, UnitAction.fighting, 15800, '中央戦線', '中央で激戦を続ける', bp: 'ukita'),
          f(d(9, 15, 12, 30), 'sekigahara', Side.west, UnitAction.pressured, 13500, '中央戦線', '東軍中央の圧力を受ける', bp: 'westCentralFront'),
          f(d(9, 15, 13, 20), 'sekigahara', Side.west, UnitAction.collapsing, 9000, '中央戦線', '大谷隊崩壊後、戦線が崩れる', bp: 'ukita'),
          f(d(9, 15, 13, 55), 'sekigahara', Side.west, UnitAction.retreating, 3200, '天満山西側', '敗走', bp: 'tenma'),
        ]),
        ArmyUnit(id: 'konishiYukinaga', name: '小西行長隊', commander: '小西行長', initialSide: Side.west, initialTroops: 6000, frames: [
          f(d(7, 18), 'fushimi', Side.west, UnitAction.besieging, 6000, '伏見城方面', '伏見城攻めに参加'),
          f(d(8, 26), 'ogaki', Side.west, UnitAction.deployed, 6000, '大垣城', '大垣城で東軍と対峙'),
          f(d(9, 14, 19, 0), 'ogaki', Side.west, UnitAction.marching, 6000, '大垣城', '西軍主力として関ヶ原へ出陣', bp: 'ogaki'),
          f(d(9, 14, 22, 30), 'ogaki', Side.west, UnitAction.marching, 6000, '垂井方面', '中央へ移動', bp: 'tarui'),
          f(d(9, 15, 3, 0), 'sekigahara', Side.west, UnitAction.marching, 6000, '関ヶ原中央', '中央陣地へ入る', bp: 'westCentralApproach'),
          f(d(9, 15, 5, 0), 'sekigahara', Side.west, UnitAction.deployed, 6000, '西軍中央', '西軍中央に布陣', bp: 'konishi'),
          f(d(9, 15, 8, 30), 'sekigahara', Side.west, UnitAction.fighting, 5900, '西軍中央', '東軍中央と交戦', bp: 'konishi'),
          f(d(9, 15, 12, 30), 'sekigahara', Side.west, UnitAction.pressured, 4700, '西軍中央', '圧力を受ける', bp: 'konishi'),
          f(d(9, 15, 13, 45), 'sekigahara', Side.west, UnitAction.retreating, 1800, '西軍中央', '敗走', bp: 'tenma'),
        ]),

        ArmyUnit(id: 'otaniYoshitsugu', name: '大谷吉継隊', commander: '大谷吉継', initialSide: Side.west, initialTroops: 4000, frames: [
          f(d(9, 3), 'sekigahara', Side.west, UnitAction.marching, 4000, '山中方面', '関ヶ原南西へ先行して布陣準備', bp: 'yamanaka'),
          f(d(9, 10), 'sekigahara', Side.west, UnitAction.deployed, 4000, '山中・藤古川方面', '小早川隊を警戒する位置に入る', bp: 'fujikawa'),
          f(d(9, 14, 18, 0), 'sekigahara', Side.west, UnitAction.deployed, 4000, '藤古川付近', '大垣から来た主力とは別に南西戦線を固める', bp: 'otani'),
          f(d(9, 15, 6, 0), 'sekigahara', Side.west, UnitAction.deployed, 4000, '藤古川付近', '松尾山の小早川隊を警戒', bp: 'otani'),
          f(d(9, 15, 11, 30), 'sekigahara', Side.west, UnitAction.waiting, 4000, '藤古川付近', '松尾山方面を注視', bp: 'otani'),
          f(d(9, 15, 12, 25), 'sekigahara', Side.west, UnitAction.fighting, 3900, '藤古川付近', '小早川隊が下り始める', bp: 'otani'),
          f(d(9, 15, 12, 40), 'sekigahara', Side.west, UnitAction.fighting, 3400, '藤古川付近', '一度は攻撃を受け止める', bp: 'fujikawa'),
          f(d(9, 15, 12, 55), 'sekigahara', Side.west, UnitAction.pressured, 2600, '藤古川付近', '側面から圧力を受ける', bp: 'otani'),
          f(d(9, 15, 13, 5), 'sekigahara', Side.west, UnitAction.collapsing, 1900, '藤古川付近', '脇坂らの呼応で戦線が崩れ始める', bp: 'otani'),
          f(d(9, 15, 13, 20), 'sekigahara', Side.west, UnitAction.destroyed, 0, '藤古川付近', '大谷隊崩壊', bp: 'otani'),
        ]),
        ArmyUnit(id: 'todahiratsuka', name: '戸田・平塚隊', commander: '戸田勝成・平塚為広', initialSide: Side.west, initialTroops: 1500, battleOnly: true, minor: true, frames: [
          f(d(9, 15, 6, 0), 'sekigahara', Side.west, UnitAction.deployed, 1500, '大谷隊付近', '大谷隊に連携', bp: 'todahiratsuka'),
          f(d(9, 15, 12, 45), 'sekigahara', Side.west, UnitAction.fighting, 1200, '大谷隊付近', '小早川隊と交戦', bp: 'fujikawa'),
          f(d(9, 15, 13, 25), 'sekigahara', Side.west, UnitAction.destroyed, 0, '大谷隊付近', '大谷隊とともに崩壊', bp: 'todahiratsuka'),
        ]),
        ArmyUnit(id: 'shimazuYoshihiro', name: '島津義弘隊', commander: '島津義弘', initialSide: Side.west, initialTroops: 1500, frames: [
          f(d(8, 26), 'ogaki', Side.west, UnitAction.deployed, 1500, '大垣城', '西軍主力とともに大垣で対峙'),
          f(d(9, 14, 19, 30), 'ogaki', Side.west, UnitAction.marching, 1500, '大垣城', '関ヶ原へ夜間移動', bp: 'ogaki'),
          f(d(9, 15, 2, 30), 'sekigahara', Side.west, UnitAction.marching, 1500, '関ヶ原南西側', '西軍南西側へ入る', bp: 'westSouthFront'),
          f(d(9, 15, 5, 0), 'sekigahara', Side.west, UnitAction.deployed, 1500, '南西方面', '寡兵で布陣', bp: 'shimazu'),
          f(d(9, 15, 11, 30), 'sekigahara', Side.west, UnitAction.waiting, 1500, '南西方面', '主戦場を見極める', bp: 'shimazu'),
          f(d(9, 15, 13, 45), 'sekigahara', Side.west, UnitAction.waiting, 1300, '南西方面', '西軍崩壊を確認', bp: 'shimazu'),
          f(d(9, 15, 14, 20), 'sekigahara', Side.west, UnitAction.fighting, 1000, '南西方面', '敵中突破を開始', bp: 'imao'),
          f(d(9, 15, 14, 50), 'sekigahara', Side.west, UnitAction.retreating, 650, '中央突破', '追撃を受けながら突破', bp: 'fujikawa'),
          f(d(9, 15, 15, 20), 'anotsu', Side.west, UnitAction.retreating, 300, '伊勢方面へ', '島津の退き口', bp: 'southernFront'),
        ]),

        ArmyUnit(id: 'kobayakawaHideaki', name: '小早川秀秋隊', commander: '小早川秀秋', initialSide: Side.west, initialTroops: 15000, frames: [
          f(d(9, 14, 12, 0), 'sekigahara', Side.west, UnitAction.deployed, 15000, '松尾山', '松尾山に布陣済み', bp: 'kobayakawa'),
          f(d(9, 14, 18, 0), 'sekigahara', Side.west, UnitAction.waiting, 15000, '松尾山', '西軍右翼を形成しつつ静観', bp: 'kobayakawa'),
          f(d(9, 15, 6, 0), 'sekigahara', Side.west, UnitAction.waiting, 15000, '松尾山', '戦局を見極める', bp: 'kobayakawa'),
          f(d(9, 15, 11, 30), 'sekigahara', Side.west, UnitAction.waiting, 15000, '松尾山', 'なお動かず', bp: 'kobayakawa'),
          f(d(9, 15, 12, 15), 'sekigahara', Side.west, UnitAction.waiting, 15000, '松尾山', '動揺・静観', bp: 'kobayakawa'),
          f(d(9, 15, 12, 25), 'sekigahara', Side.east, UnitAction.betrayed, 15000, '松尾山麓', '東軍側へ転じる', bp: 'kobayakawaDescent'),
          f(d(9, 15, 12, 35), 'sekigahara', Side.east, UnitAction.fighting, 15000, '藤古川方面', '松尾山から下る', bp: 'kobayakawaAttack'),
          f(d(9, 15, 12, 50), 'sekigahara', Side.east, UnitAction.fighting, 15000, '大谷隊側面', '大谷隊を攻撃', bp: 'otaniFlank'),
          f(d(9, 15, 13, 15), 'sekigahara', Side.east, UnitAction.winning, 15000, '藤古川付近', '大谷隊崩壊へ', bp: 'otaniFlank'),
        ]),
        ArmyUnit(id: 'wakisakaYasuharu', name: '脇坂安治隊', commander: '脇坂安治', initialSide: Side.west, initialTroops: 1000, battleOnly: true, minor: true, frames: [
          f(d(9, 15, 6, 0), 'sekigahara', Side.west, UnitAction.waiting, 1000, '松尾山周辺', '小早川付近', bp: 'wakisaka'),
          f(d(9, 15, 12, 50), 'sekigahara', Side.east, UnitAction.betrayed, 1000, '松尾山麓', '東軍側へ転じる', bp: 'matsuoFoot'),
          f(d(9, 15, 13, 5), 'sekigahara', Side.east, UnitAction.fighting, 1000, '大谷隊方面', '大谷隊へ攻撃', bp: 'otaniFlank'),
        ]),

        ArmyUnit(id: 'wakisakaKutsukiGroup', name: '脇坂・朽木・小川・赤座隊', commander: '脇坂安治ら', initialSide: Side.west, initialTroops: 4200, battleOnly: true, minor: true, frames: [
          f(d(9, 15, 6, 0), 'sekigahara', Side.west, UnitAction.waiting, 4200, '松尾山周辺', '西軍側で待機', bp: 'wakisaka'),
          f(d(9, 15, 12, 50), 'sekigahara', Side.east, UnitAction.betrayed, 4200, '松尾山麓', '小早川に呼応して東軍側へ転じる', bp: 'matsuoFoot'),
          f(d(9, 15, 13, 5), 'sekigahara', Side.east, UnitAction.fighting, 4000, '大谷隊側面', '大谷隊側面を攻撃', bp: 'otaniFlank'),
        ]),

        ArmyUnit(id: 'moriHidemoto', name: '毛利秀元隊', commander: '毛利秀元', initialSide: Side.west, initialTroops: 15000, frames: [
          f(d(9, 7), 'sekigahara', Side.west, UnitAction.marching, 15000, '南宮山方面へ', '西軍南方の要地へ進む', bp: 'tarui'),
          f(d(9, 14, 12, 0), 'sekigahara', Side.west, UnitAction.deployed, 15000, '南宮山', '南宮山方面に布陣済み', bp: 'mori'),
          f(d(9, 15, 6, 0), 'sekigahara', Side.west, UnitAction.waiting, 15000, '南宮山', '主戦場へ動かず', bp: 'mori'),
          f(d(9, 15, 13, 30), 'sekigahara', Side.west, UnitAction.delayed, 15000, '南宮山', '吉川隊前面のため主戦場へ出られない', bp: 'mori'),
          f(d(9, 15, 15, 0), 'sekigahara', Side.west, UnitAction.retreating, 15000, '南宮山', '撤退へ', bp: 'mori'),
        ]),
        ArmyUnit(id: 'kikkawaHiroie', name: '吉川広家隊', commander: '吉川広家', initialSide: Side.west, initialTroops: 3000, battleOnly: true, minor: true, frames: [
          f(d(9, 7), 'sekigahara', Side.west, UnitAction.deployed, 3000, '南宮山前面', '毛利勢の前面に布陣', bp: 'kikkawa'),
          f(d(9, 15, 6, 0), 'sekigahara', Side.west, UnitAction.waiting, 3000, '南宮山前面', '毛利勢前面で動かず', bp: 'kikkawa'),
          f(d(9, 15, 15, 0), 'sekigahara', Side.west, UnitAction.retreating, 3000, '南宮山前面', '撤退', bp: 'kikkawa'),
        ]),
        ArmyUnit(id: 'ankokujiEkei', name: '安国寺恵瓊隊', commander: '安国寺恵瓊', initialSide: Side.west, initialTroops: 1800, battleOnly: true, minor: true, frames: [
          f(d(9, 7), 'sekigahara', Side.west, UnitAction.deployed, 1800, '南宮山方面', '南宮山方面に布陣', bp: 'ankokuji'),
          f(d(9, 15, 6, 0), 'sekigahara', Side.west, UnitAction.waiting, 1800, '南宮山方面', '主戦場へ動かず', bp: 'ankokuji'),
          f(d(9, 15, 15, 0), 'sekigahara', Side.west, UnitAction.retreating, 1800, '南宮山方面', '撤退', bp: 'ankokuji'),
        ]),
        ArmyUnit(id: 'chosokabeMorichika', name: '長宗我部盛親隊', commander: '長宗我部盛親', initialSide: Side.west, initialTroops: 6600, frames: [
          f(d(9, 7), 'sekigahara', Side.west, UnitAction.deployed, 6600, '南宮山・栗原山方面', '西軍南方に布陣', bp: 'chosokabe'),
          f(d(9, 15, 6, 0), 'sekigahara', Side.west, UnitAction.waiting, 6600, '南宮山方面', '主戦場へ動かず', bp: 'chosokabe'),
          f(d(9, 15, 15, 0), 'sekigahara', Side.west, UnitAction.retreating, 6600, '南宮山方面', '撤退', bp: 'chosokabe'),
        ]),
        ArmyUnit(id: 'natsukaMasaie', name: '長束正家隊', commander: '長束正家', initialSide: Side.west, initialTroops: 1500, battleOnly: true, minor: true, frames: [
          f(d(9, 7), 'sekigahara', Side.west, UnitAction.deployed, 1500, '南宮山方面', '西軍南方に布陣', bp: 'natsuka'),
          f(d(9, 15, 6, 0), 'sekigahara', Side.west, UnitAction.waiting, 1500, '南宮山方面', '主戦場へ動かず', bp: 'natsuka'),
          f(d(9, 15, 15, 0), 'sekigahara', Side.west, UnitAction.retreating, 1500, '南宮山方面', '撤退', bp: 'natsuka'),
        ]),


        ArmyUnit(id: 'fukushimaMasanori', name: '福島正則隊', commander: '福島正則', initialSide: Side.east, initialTroops: 6000, frames: [
          f(d(8, 20), 'kiyosu', Side.east, UnitAction.marching, 6000, '清洲方面', '東軍先鋒として美濃方面へ進出準備'),
          f(d(8, 22), 'kiso', Side.east, UnitAction.fighting, 6000, '木曽川方面', '木曽川を越え、尾張・美濃境で戦闘'),
          f(d(8, 23), 'gifu', Side.east, UnitAction.winning, 5900, '岐阜城', '福島正則以下の東軍諸隊が岐阜城を攻略'),
          f(d(8, 26), 'ogaki', Side.east, UnitAction.deployed, 5900, '美濃赤坂方面', '東軍が大垣城の西軍と対峙'),
          f(d(9, 14, 18, 0), 'ogaki', Side.east, UnitAction.deployed, 5900, '赤坂方面', '東軍前衛として関ヶ原方面をうかがう', bp: 'akasaka'),
          f(d(9, 15, 5, 30), 'sekigahara', Side.east, UnitAction.marching, 5900, '関ヶ原東側', '中央前線へ進出', bp: 'eastRear'),
          f(d(9, 15, 6, 0), 'sekigahara', Side.east, UnitAction.deployed, 5900, '東軍中央東側', '宇喜多隊正面に布陣', bp: 'fukushima'),
          f(d(9, 15, 8, 5), 'sekigahara', Side.east, UnitAction.fighting, 5800, '中央戦線', '宇喜多秀家隊と本格交戦', bp: 'eastCentralFront'),
          f(d(9, 15, 10, 30), 'sekigahara', Side.east, UnitAction.fighting, 5600, '中央戦線', '宇喜多隊と激戦を続ける', bp: 'fukushima'),
          f(d(9, 15, 12, 30), 'sekigahara', Side.east, UnitAction.fighting, 5400, '中央戦線', '西軍中央を圧迫', bp: 'eastCentralFront'),
          f(d(9, 15, 13, 30), 'sekigahara', Side.east, UnitAction.winning, 5200, '宇喜多隊正面', '西軍崩壊に伴い前進', bp: 'eastCentralPressure'),
        ]),
        ArmyUnit(id: 'kurodaNagamasa', name: '黒田長政隊', commander: '黒田長政', initialSide: Side.east, initialTroops: 5400, frames: [
          f(d(8, 20), 'kiyosu', Side.east, UnitAction.marching, 5400, '清洲方面', '東軍先手衆として美濃へ向かう'),
          f(d(8, 23), 'gifu', Side.east, UnitAction.winning, 5400, '岐阜城方面', '岐阜城攻略後、美濃へ進出'),
          f(d(8, 26), 'ogaki', Side.east, UnitAction.deployed, 5400, '赤坂・垂井方面', '大垣城の西軍と対峙'),
          f(d(9, 14, 19, 0), 'ogaki', Side.east, UnitAction.marching, 5400, '赤坂方面', '石田隊正面へ', bp: 'akasaka'),
          f(d(9, 15, 5, 0), 'sekigahara', Side.east, UnitAction.marching, 5400, '北部前線', '石田隊正面へ', bp: 'eastNorthFront'),
          f(d(9, 15, 6, 0), 'sekigahara', Side.east, UnitAction.deployed, 5400, '石田隊正面', '石田隊方面へ圧力', bp: 'kuroda'),
          f(d(9, 15, 8, 0), 'sekigahara', Side.east, UnitAction.fighting, 5300, '北部前線', '島左近・石田隊と交戦', bp: 'eastNorthPressure'),
          f(d(9, 15, 13, 45), 'sekigahara', Side.east, UnitAction.winning, 5000, '笹尾山前面', '西軍崩壊へ', bp: 'eastNorthPressure'),
        ]),
        ArmyUnit(id: 'hosokawaTadaoki', name: '細川忠興隊', commander: '細川忠興', initialSide: Side.east, initialTroops: 5000, frames: [
          f(d(8, 20), 'kiyosu', Side.east, UnitAction.marching, 5000, '清洲方面', '東軍先手衆として美濃へ向かう'),
          f(d(8, 26), 'ogaki', Side.east, UnitAction.deployed, 5000, '赤坂・垂井方面', '大垣城の西軍と対峙'),
          f(d(9, 14, 19, 0), 'ogaki', Side.east, UnitAction.marching, 5000, '赤坂方面', '東軍中央へ', bp: 'akasaka'),
          f(d(9, 15, 6, 0), 'sekigahara', Side.east, UnitAction.deployed, 5000, '東軍中央北寄り', '石田・小西方面に対峙', bp: 'hosokawa'),
          f(d(9, 15, 8, 30), 'sekigahara', Side.east, UnitAction.fighting, 4900, '東軍中央北寄り', '小西隊方面と交戦', bp: 'hosokawa'),
          f(d(9, 15, 13, 20), 'sekigahara', Side.east, UnitAction.winning, 4700, '中央戦線', '前進', bp: 'eastCentralPressure'),
        ]),
        ArmyUnit(id: 'iiNaomasa', name: '井伊直政隊', commander: '井伊直政', initialSide: Side.east, initialTroops: 3600, frames: [
          f(d(9, 14, 19, 0), 'ogaki', Side.east, UnitAction.marching, 3600, '赤坂方面', '東軍先鋒へ', bp: 'akasaka'),
          f(d(9, 15, 4, 30), 'sekigahara', Side.east, UnitAction.marching, 3600, '先鋒位置へ', '前線へ進む', bp: 'nakasendoCenter'),
          f(d(9, 15, 6, 0), 'sekigahara', Side.east, UnitAction.deployed, 3600, '東軍先鋒', '先鋒付近に布陣', bp: 'ii'),
          f(d(9, 15, 8, 0), 'sekigahara', Side.east, UnitAction.fighting, 3500, '東軍先鋒', '開戦', bp: 'ii'),
          f(d(9, 15, 14, 30), 'sekigahara', Side.east, UnitAction.fighting, 3200, '島津追撃', '島津隊を追撃', bp: 'imao'),
          f(d(9, 15, 15, 0), 'anotsu', Side.east, UnitAction.fighting, 3000, '島津追撃', '島津隊を追撃', bp: 'fujikawa'),
        ]),
        ArmyUnit(id: 'matsudairaTadayoshi', name: '松平忠吉隊', commander: '松平忠吉', initialSide: Side.east, initialTroops: 3000, battleOnly: true, minor: true, frames: [
          f(d(9, 15, 6, 0), 'sekigahara', Side.east, UnitAction.deployed, 3000, '東軍先鋒', '井伊隊付近', bp: 'matsudaira'),
          f(d(9, 15, 8, 0), 'sekigahara', Side.east, UnitAction.fighting, 2900, '東軍先鋒', '先鋒で戦闘', bp: 'ii'),
        ]),
        ArmyUnit(id: 'todoTakatora', name: '藤堂高虎隊', commander: '藤堂高虎', initialSide: Side.east, initialTroops: 2500, frames: [
          f(d(8, 20), 'kiyosu', Side.east, UnitAction.marching, 2500, '清洲方面', '東軍先手衆として美濃へ向かう'),
          f(d(8, 26), 'ogaki', Side.east, UnitAction.deployed, 2500, '赤坂・垂井方面', '大垣城の西軍と対峙'),
          f(d(9, 15, 6, 0), 'sekigahara', Side.east, UnitAction.deployed, 2500, '東軍中央南寄り', '大谷隊方面へ圧力をかける位置に布陣', bp: 'todo'),
          f(d(9, 15, 12, 50), 'sekigahara', Side.east, UnitAction.fighting, 2400, '南部戦線', '大谷隊方面へ圧力', bp: 'eastSouthPressure'),
          f(d(9, 15, 13, 30), 'sekigahara', Side.east, UnitAction.winning, 2300, '南部戦線', '東軍優勢', bp: 'otaniFlank'),
        ]),
        ArmyUnit(id: 'kyogokuTakatomo', name: '京極高知隊', commander: '京極高知', initialSide: Side.east, initialTroops: 3000, battleOnly: true, minor: true, frames: [
          f(d(9, 15, 6, 0), 'sekigahara', Side.east, UnitAction.deployed, 3000, '東軍中央南寄り', '藤堂隊付近', bp: 'kyogoku'),
          f(d(9, 15, 13, 10), 'sekigahara', Side.east, UnitAction.fighting, 2900, '南部戦線', '前進', bp: 'eastSouthFront'),
        ]),
        ArmyUnit(id: 'tanakaYoshimasa', name: '田中吉政隊', commander: '田中吉政', initialSide: Side.east, initialTroops: 3000, frames: [
          f(d(9, 15, 6, 0), 'sekigahara', Side.east, UnitAction.deployed, 3000, '東軍右翼', '右翼に布陣', bp: 'tanaka'),
          f(d(9, 15, 13, 30), 'sekigahara', Side.east, UnitAction.winning, 2900, '東軍右翼', '前進', bp: 'eastCentralPressure'),
        ]),
        ArmyUnit(id: 'yamauchiKazutoyo', name: '山内一豊隊', commander: '山内一豊', initialSide: Side.east, initialTroops: 2000, battleOnly: true, minor: true, frames: [
          f(d(9, 15, 6, 0), 'sekigahara', Side.east, UnitAction.deployed, 2000, '東軍右翼', '右翼に布陣', bp: 'yamauchi'),
        ]),
        ArmyUnit(id: 'asanoYoshinaga', name: '浅野幸長隊', commander: '浅野幸長', initialSide: Side.east, initialTroops: 6500, frames: [
          f(d(9, 15, 6, 0), 'sekigahara', Side.east, UnitAction.deployed, 6500, '東軍後方', '後方に布陣', bp: 'asano'),
          f(d(9, 15, 13, 30), 'sekigahara', Side.east, UnitAction.winning, 6400, '東軍後方', '前進準備', bp: 'eastRear'),
        ]),

        ArmyUnit(id: 'ikedaTerumasa', name: '池田輝政隊', commander: '池田輝政', initialSide: Side.east, initialTroops: 4500, frames: [
          f(d(8, 20), 'kiyosu', Side.east, UnitAction.marching, 4500, '清洲方面', '福島隊らとともに美濃へ向かう'),
          f(d(8, 23), 'gifu', Side.east, UnitAction.winning, 4500, '岐阜城方面', '岐阜城攻略に参加'),
          f(d(8, 26), 'ogaki', Side.east, UnitAction.deployed, 4500, '赤坂方面', '美濃方面へ進出'),
          f(d(9, 15, 6, 0), 'sekigahara', Side.east, UnitAction.deployed, 4500, '東軍後方', '後方に布陣', bp: 'ikeda'),
        ]),
        ArmyUnit(id: 'hondaTadakatsu', name: '本多忠勝隊', commander: '本多忠勝', initialSide: Side.east, initialTroops: 500, battleOnly: true, minor: true, frames: [
          f(d(9, 15, 6, 0), 'sekigahara', Side.east, UnitAction.deployed, 500, '家康本陣付近', '本陣付近', bp: 'honda'),
        ]),
        ArmyUnit(id: 'katoYoshiaki', name: '加藤嘉明隊', commander: '加藤嘉明', initialSide: Side.east, initialTroops: 3000, battleOnly: true, minor: true, frames: [
          f(d(9, 15, 6, 0), 'sekigahara', Side.east, UnitAction.deployed, 3000, '東軍北寄り', '北寄りに布陣', bp: 'kato'),
          f(d(9, 15, 13, 30), 'sekigahara', Side.east, UnitAction.fighting, 2900, '北部戦線', '前進', bp: 'eastNorthFront'),
        ]),

        ArmyUnit(id: 'tokugawaHidetada', name: '徳川秀忠隊', commander: '徳川秀忠', initialSide: Side.east, initialTroops: 38000, frames: [
          f(d(9, 2), 'ueda', Side.east, UnitAction.besieging, 38000, '上田城周辺', '第二次上田合戦'),
          f(d(9, 5), 'ueda', Side.east, UnitAction.delayed, 38000, '上田城周辺', '上田で遅延'),
          f(d(9, 12), 'hamamatsu', Side.east, UnitAction.marching, 38000, '中山道・東海道方面', '西進'),
          f(d(9, 15), 'kiyosu', Side.east, UnitAction.marching, 38000, '中山道', '関ヶ原本戦に遅参'),
        ]),
        ArmyUnit(id: 'sanadaMasayuki', name: '真田昌幸・信繁隊', commander: '真田昌幸・信繁', initialSide: Side.west, initialTroops: 2500, frames: [
          f(d(9, 2), 'ueda', Side.west, UnitAction.defending, 2500, '上田城', '秀忠軍を足止め'),
          f(d(9, 15), 'ueda', Side.west, UnitAction.winning, 2500, '上田城', '秀忠軍の遅参に影響'),
        ]),
        ArmyUnit(id: 'uesugiNaoe', name: '上杉・直江兼続軍', commander: '直江兼続', initialSide: Side.west, initialTroops: 20000, frames: [
          f(d(9, 9), 'aizu', Side.west, UnitAction.marching, 20000, '会津', '最上領へ侵攻'),
          f(d(9, 13), 'hataya', Side.west, UnitAction.winning, 20000, '畑谷城', '畑谷城落城'),
          f(d(9, 15), 'hasedo', Side.west, UnitAction.besieging, 20000, '長谷堂城', '長谷堂城攻防'),
          f(d(9, 29), 'hasedo', Side.west, UnitAction.pressured, 20000, '長谷堂城', '関ヶ原敗報'),
          f(d(10, 1), 'aizu', Side.west, UnitAction.retreating, 20000, '会津方面', '撤退'),
        ]),
        ArmyUnit(id: 'dateMasamune', name: '伊達政宗隊', commander: '伊達政宗', initialSide: Side.east, initialTroops: 15000, frames: [
          f(d(9, 29), 'sendai', Side.east, UnitAction.marching, 15000, '仙台', '上杉領へ攻勢'),
          f(d(10, 2), 'hasedo', Side.east, UnitAction.winning, 15000, '東北方面', '東北戦線収束へ'),
        ]),
        ArmyUnit(id: 'mogamiYoshiaki', name: '最上義光隊', commander: '最上義光', initialSide: Side.east, initialTroops: 7000, frames: [
          f(d(9, 9), 'hasedo', Side.east, UnitAction.defending, 7000, '長谷堂城周辺', '上杉軍に対抗'),
          f(d(10, 1), 'hasedo', Side.east, UnitAction.winning, 7000, '長谷堂城', '上杉軍撤退'),
        ]),
        ArmyUnit(id: 'kurodaJosui', name: '黒田如水軍', commander: '黒田如水', initialSide: Side.east, initialTroops: 9000, frames: [
          f(d(9, 9), 'nakatsu', Side.east, UnitAction.marching, 9000, '中津城', '九州方面で出陣'),
          f(d(9, 11), 'kyushuCoast', Side.east, UnitAction.marching, 9000, '豊前・豊後境', '海を避けて沿岸陸路を進む'),
          f(d(9, 13), 'ishigakibaru', Side.east, UnitAction.fighting, 9000, '石垣原', '大友軍と激突'),
          f(d(9, 15), 'ishigakibaru', Side.east, UnitAction.winning, 9000, '石垣原', '大友義統が降伏'),
          f(d(10, 10), 'kokura', Side.east, UnitAction.marching, 9000, '小倉方面', '北九州方面へ'),
          f(d(10, 25), 'yanagawa', Side.east, UnitAction.winning, 9000, '柳河城方面', '九州戦線収束'),
        ]),
        ArmyUnit(id: 'otomoYoshimune', name: '大友義統軍', commander: '大友義統', initialSide: Side.west, initialTroops: 6000, frames: [
          f(d(9, 9), 'bungo', Side.west, UnitAction.marching, 6000, '豊後上陸', '豊後へ上陸'),
          f(d(9, 10), 'kitsuki', Side.west, UnitAction.besieging, 6000, '木付城', '木付城を攻撃'),
          f(d(9, 11), 'kyushuCoast', Side.west, UnitAction.retreating, 5600, '立石方面', '立石へ後退'),
          f(d(9, 13), 'ishigakibaru', Side.west, UnitAction.fighting, 6000, '石垣原', '石垣原の戦い'),
          f(d(9, 15), 'ishigakibaru', Side.west, UnitAction.destroyed, 0, '石垣原', '大友義統降伏'),
        ]),

        ArmyUnit(id: 'tachibanaMuneshige', name: '立花宗茂隊', commander: '立花宗茂', initialSide: Side.west, initialTroops: 15000, frames: [
          f(d(9, 7), 'otsu', Side.west, UnitAction.besieging, 15000, '大津城', '大津城攻め'),
          f(d(9, 15), 'otsu', Side.west, UnitAction.delayed, 15000, '大津城', '本戦に間に合わず'),
          f(d(9, 16), 'osaka', Side.west, UnitAction.retreating, 14500, '畿内方面', '大津城方面から撤収'),
          f(d(9, 25), 'hiroshima', Side.west, UnitAction.marching, 14500, '瀬戸内方面', '九州帰還へ向かう'),
          f(d(10, 5), 'kokura', Side.west, UnitAction.marching, 14000, '九州北部', '筑後方面へ戻る'),
          f(d(10, 14), 'yanagawa', Side.west, UnitAction.defending, 14000, '柳河城', '柳河城へ帰着'),
          f(d(10, 20), 'yanagawa', Side.west, UnitAction.defending, 14000, '柳河城', '柳河城攻めに備える'),
          f(d(10, 25), 'yanagawa', Side.west, UnitAction.retreating, 14000, '柳河城', '開城・戦線収束'),
        ]),


        ArmyUnit(id: 'toriiMototada', name: '鳥居元忠隊', commander: '鳥居元忠', initialSide: Side.east, initialTroops: 1800, frames: [
          f(d(7, 18), 'fushimi', Side.east, UnitAction.defending, 1800, '伏見城', '伏見城に籠城'),
          f(d(7, 25), 'fushimi', Side.east, UnitAction.fighting, 1200, '伏見城', '西軍の攻撃を受ける'),
          f(d(8, 1), 'fushimi', Side.east, UnitAction.destroyed, 0, '伏見城', '伏見城落城'),
        ]),
        ArmyUnit(id: 'fushimiWestArmy', name: '西軍伏見攻撃軍', commander: '宇喜多・小早川・島津ら', initialSide: Side.west, initialTroops: 40000, frames: [
          f(d(7, 18), 'osaka', Side.west, UnitAction.marching, 40000, '大坂方面', '伏見城攻撃へ集結'),
          f(d(7, 20), 'fushimi', Side.west, UnitAction.besieging, 40000, '伏見城周辺', '伏見城を包囲'),
          f(d(7, 25), 'fushimi', Side.west, UnitAction.fighting, 38000, '伏見城周辺', '攻撃継続'),
          f(d(8, 1), 'fushimi', Side.west, UnitAction.winning, 36000, '伏見城', '伏見城落城'),
          f(d(8, 3), 'osaka', Side.west, UnitAction.marching, 36000, '大坂方面', '各方面へ再配置'),
        ]),
        ArmyUnit(id: 'tanabeSiegeArmy', name: '西軍田辺城包囲軍', commander: '小野木重勝ら', initialSide: Side.west, initialTroops: 15000, frames: [
          f(d(7, 21), 'osaka', Side.west, UnitAction.marching, 15000, '大坂方面', '丹後へ向かう'),
          f(d(7, 25), 'tanabe', Side.west, UnitAction.besieging, 15000, '田辺城周辺', '田辺城を包囲'),
          f(d(8, 20), 'tanabe', Side.west, UnitAction.besieging, 15000, '田辺城周辺', '長期包囲を継続'),
          f(d(9, 12), 'tanabe', Side.west, UnitAction.delayed, 15000, '田辺城周辺', '停戦・本戦には間に合わず'),
        ]),
        ArmyUnit(id: 'odaHidenobu', name: '織田秀信隊', commander: '織田秀信', initialSide: Side.west, initialTroops: 6000, frames: [
          f(d(8, 20), 'gifu', Side.west, UnitAction.defending, 6000, '岐阜城', '岐阜城を守備'),
          f(d(8, 22), 'gifu', Side.west, UnitAction.fighting, 5500, '岐阜城', '東軍先鋒の攻撃を受ける'),
          f(d(8, 23), 'gifu', Side.west, UnitAction.destroyed, 0, '岐阜城', '岐阜城落城'),
        ]),
        ArmyUnit(id: 'kyogokuTakatsugu', name: '京極高次守備隊', commander: '京極高次', initialSide: Side.east, initialTroops: 3000, frames: [
          f(d(9, 7), 'otsu', Side.east, UnitAction.defending, 3000, '大津城', '大津城に籠城'),
          f(d(9, 12), 'otsu', Side.east, UnitAction.fighting, 2500, '大津城', '西軍包囲を受ける'),
          f(d(9, 15), 'otsu', Side.east, UnitAction.delayed, 2200, '大津城', '開城するが西軍を拘束'),
        ]),
        ArmyUnit(id: 'katoKiyomasa', name: '加藤清正隊', commander: '加藤清正', initialSide: Side.east, initialTroops: 10000, frames: [
          f(d(9, 21), 'uto', Side.east, UnitAction.marching, 10000, '肥後北部', '宇土城へ進軍'),
          f(d(9, 25), 'uto', Side.east, UnitAction.besieging, 10000, '宇土城周辺', '宇土城を包囲'),
          f(d(10, 14), 'uto', Side.east, UnitAction.winning, 9500, '宇土城', '宇土城攻め終結'),
          f(d(10, 20), 'yanagawa', Side.east, UnitAction.marching, 9500, '柳河方面', '柳河城攻めへ向かう'),
          f(d(10, 25), 'yanagawa', Side.east, UnitAction.winning, 9500, '柳河城周辺', '九州戦線収束'),
        ]),
        ArmyUnit(id: 'utoDefenders', name: '宇土城守備隊', commander: '小西方守備隊', initialSide: Side.west, initialTroops: 3000, frames: [
          f(d(9, 21), 'uto', Side.west, UnitAction.defending, 3000, '宇土城', '宇土城を守備'),
          f(d(10, 1), 'uto', Side.west, UnitAction.defending, 2600, '宇土城', '包囲下で持久'),
          f(d(10, 14), 'uto', Side.west, UnitAction.destroyed, 0, '宇土城', '開城・終結'),
        ]),
        ArmyUnit(id: 'nabeshimaNaoshige', name: '鍋島直茂隊', commander: '鍋島直茂', initialSide: Side.east, initialTroops: 12000, frames: [
          f(d(10, 18), 'kokura', Side.east, UnitAction.marching, 12000, '九州北部', '柳河方面へ進む'),
          f(d(10, 20), 'yanagawa', Side.east, UnitAction.besieging, 12000, '柳河城周辺', '柳河城を包囲'),
          f(d(10, 25), 'yanagawa', Side.east, UnitAction.winning, 12000, '柳河城周辺', '開城・戦線収束'),
        ]),
        ArmyUnit(id: 'sawayamaDefenders', name: '佐和山城守備隊', commander: '石田家守備隊', initialSide: Side.west, initialTroops: 2800, frames: [
          f(d(9, 17), 'sawayama', Side.west, UnitAction.defending, 2800, '佐和山城', '石田三成の本拠を守備'),
          f(d(9, 18), 'sawayama', Side.west, UnitAction.fighting, 1600, '佐和山城', '東軍の攻撃を受ける'),
          f(d(9, 18, 18), 'sawayama', Side.west, UnitAction.destroyed, 0, '佐和山城', '佐和山城落城'),
        ]),
        ArmyUnit(id: 'hosokawaYusai', name: '細川幽斎隊', commander: '細川幽斎', initialSide: Side.east, initialTroops: 500, frames: [
          f(d(7, 21), 'tanabe', Side.east, UnitAction.defending, 500, '田辺城', '籠城'),
          f(d(8, 10), 'tanabe', Side.east, UnitAction.defending, 450, '田辺城', '西軍包囲を受けながら防戦'),
          f(d(9, 12), 'tanabe', Side.east, UnitAction.winning, 420, '田辺城', '開城・停戦'),
        ]),
      ];

  static List<CampaignEvent> get events => [
        CampaignEvent(id: 'aizu', title: '会津征伐へ出兵', start: d(6, 18), end: d(6, 18, 23, 59), location: '伏見・東国方面', campaignPoint: c['fushimi']!, eastForce: '徳川家康軍', westForce: '上杉景勝方', scale: '東軍主力が東国へ移動', summary: '家康が伏見を離れ、会津征伐へ向かう。', status: '進軍'),
        CampaignEvent(id: 'west-rise', title: '西軍挙兵', start: d(7, 17), end: d(7, 17, 23, 59), location: '大坂', campaignPoint: c['osaka']!, eastForce: '徳川方', westForce: '石田三成・毛利輝元方', scale: '畿内の政局が軍事化', summary: '西軍が挙兵し、東西対立が表面化する。', status: '挙兵'),
        CampaignEvent(id: 'fushimi', title: '伏見城の戦い', start: d(7, 18), end: d(8, 1, 23, 59), location: '山城国 伏見城', campaignPoint: c['fushimi']!, eastForce: '鳥居元忠隊', westForce: '宇喜多・小早川・島津ら西軍攻撃軍', scale: '守備側 約1,800 / 攻撃側 大軍', summary: '鳥居元忠が伏見城で籠城し、西軍主力を引きつける。', status: '攻城'),
        CampaignEvent(id: 'tanabe', title: '田辺城の戦い', start: d(7, 21), end: d(9, 12, 23, 59), location: '丹後国 田辺城', campaignPoint: c['tanabe']!, eastForce: '細川幽斎方', westForce: '小野木重勝ら西軍', scale: '西軍 約15,000 / 守備側 約500', summary: '細川幽斎が籠城し、西軍兵力を拘束する。', status: '籠城'),
        CampaignEvent(id: 'gifu', title: '岐阜城の戦い', start: d(8, 22), end: d(8, 23, 23, 59), location: '美濃国 岐阜城', campaignPoint: c['gifu']!, eastForce: '福島正則・池田輝政ら東軍', westForce: '織田秀信方', scale: '東軍先鋒が美濃へ進出', summary: '東軍が木曽川を越え、岐阜城を攻略する。', status: '落城'),
        CampaignEvent(id: 'ueda', title: '第二次上田合戦', start: d(9, 2), end: d(9, 8, 23, 59), location: '信濃国 上田城周辺', campaignPoint: c['ueda']!, eastForce: '徳川秀忠軍', westForce: '真田昌幸・信繁軍', scale: '東軍 約38,000 / 西軍 約2,500', summary: '秀忠軍が上田で足止めされる。', status: '遅延'),
        CampaignEvent(id: 'otsu', title: '大津城の戦い', start: d(9, 7), end: d(9, 15, 23, 59), location: '近江国 大津城', campaignPoint: c['otsu']!, eastForce: '京極高次方', westForce: '立花宗茂ら西軍', scale: '西軍 約15,000を拘束', summary: '大津城が西軍部隊を拘束し、本戦参加を妨げる。', status: '籠城'),
        CampaignEvent(id: 'hasedo', title: '慶長出羽合戦', start: d(9, 9), end: d(10, 1, 23, 59), location: '出羽国 長谷堂城', campaignPoint: c['hasedo']!, eastForce: '最上・伊達方', westForce: '上杉・直江兼続軍', scale: '上杉軍 約20,000', summary: '上杉軍が最上領へ侵攻し、関ヶ原敗報後に撤退する。', status: '地方戦線'),
        CampaignEvent(id: 'ishigakibaru', title: '石垣原の戦い', start: d(9, 9), end: d(9, 15, 23, 59), location: '豊後国 石垣原', campaignPoint: c['ishigakibaru']!, eastForce: '黒田如水・細川方', westForce: '大友義統軍', scale: '黒田方 約9,000 / 大友方 約6,000', summary: '九州方面の重要戦闘。大友義統が降伏する。', status: '戦闘'),
        CampaignEvent(id: 'kuisegawa', title: '杭瀬川の戦い', start: d(9, 14), end: d(9, 14, 23, 59), location: '美濃国 大垣周辺', campaignPoint: c['sekigahara']!, battlePoint: b['kuisegawa']!, eastForce: '東軍前衛', westForce: '島左近・明石全登ら西軍', scale: '前哨戦', summary: '関ヶ原前日の局地戦。西軍が局地勝利する。', status: '前哨戦'),
        CampaignEvent(id: 'battle-approach', title: '関ヶ原への布陣移動', start: d(9, 14, 18), end: d(9, 15, 7, 59), location: '大垣〜関ヶ原', campaignPoint: c['sekigahara']!, battlePoint: b['sekigahara']!, eastForce: '徳川家康率いる東軍', westForce: '石田三成ら西軍', scale: '両軍が本戦位置へ移動', summary: '9月14日夜から15日朝にかけ、各部隊が本戦位置へ入る。', status: '布陣移動'),
        CampaignEvent(id: 'sekigahara-start', title: '関ヶ原開戦', start: d(9, 15, 8), end: d(9, 15, 11, 59), location: '美濃国 関ヶ原', campaignPoint: c['sekigahara']!, battlePoint: b['sekigahara']!, eastForce: '徳川家康率いる東軍', westForce: '石田三成ら西軍', scale: '東軍 約70,000 / 西軍 約80,000', summary: '東軍先鋒と西軍主力が各方面で交戦する。', status: '開戦'),
        CampaignEvent(id: 'kobayakawa-betrayal', title: '小早川秀秋隊の離反', start: d(9, 15, 12, 25), end: d(9, 15, 13, 20), location: '松尾山〜藤古川付近', campaignPoint: c['sekigahara']!, battlePoint: b['otani']!, eastForce: '小早川・東軍', westForce: '大谷吉継隊', scale: '小早川隊 約15,000', summary: '小早川隊が大谷隊方面へ下り、西軍右翼が崩れる。', status: '寝返り'),
        CampaignEvent(id: 'west-collapse', title: '西軍総崩れ', start: d(9, 15, 13, 20), end: d(9, 15, 14, 30), location: '関ヶ原中央〜笹尾山', campaignPoint: c['sekigahara']!, battlePoint: b['centralFront']!, eastForce: '東軍諸隊', westForce: '石田・宇喜多・小西隊', scale: '西軍主力が崩壊', summary: '大谷隊崩壊後、中央と北部の西軍も崩れ始める。', status: '崩壊'),
        CampaignEvent(id: 'shima-retreat', title: '島津の退き口', start: d(9, 15, 14, 30), end: d(9, 15, 15, 30), location: '関ヶ原南部', campaignPoint: c['anotsu']!, battlePoint: b['imao']!, eastForce: '井伊・松平ら東軍', westForce: '島津義弘隊', scale: '島津隊が敵中突破', summary: '島津隊が東軍の中を突破して退却する。', status: '退却'),
        CampaignEvent(id: 'sawayama', title: '佐和山城の戦い', start: d(9, 17), end: d(9, 18, 23, 59), location: '近江国 佐和山城', campaignPoint: c['sawayama']!, eastForce: '東軍', westForce: '石田家守備隊', scale: '石田三成の本拠攻略', summary: '関ヶ原後、佐和山城が落城する。', status: '落城'),
        CampaignEvent(id: 'uto', title: '宇土城攻め', start: d(9, 21), end: d(10, 14, 23, 59), location: '肥後国 宇土城', campaignPoint: c['uto']!, eastForce: '加藤清正ら東軍方', westForce: '小西行長方', scale: '九州方面の攻城戦', summary: '肥後で宇土城攻めが続く。', status: '攻城'),
        CampaignEvent(id: 'yanagawa', title: '柳河城攻め', start: d(10, 20), end: d(10, 25, 23, 59), location: '筑後国 柳河城', campaignPoint: c['yanagawa']!, eastForce: '加藤清正・黒田如水ら東軍方', westForce: '立花宗茂方', scale: '九州方面の終盤戦', summary: '柳河城攻めが終結し、九州戦線が収束へ向かう。', status: '終結'),
      ];
}

class SekigaharaMapPage extends StatefulWidget {
  const SekigaharaMapPage({super.key});
  @override
  State<SekigaharaMapPage> createState() => _SekigaharaMapPageState();
}

class _SekigaharaMapPageState extends State<SekigaharaMapPage> with TickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  late final AnimationController _effectController;
  late final AnimationController _cutInController;
  Timer? _timer;

  MapMode mode = MapMode.campaign;
  bool playing = false;
  bool showLabels = true;
  bool showDebug = false;
  double speed = 1.0;
  double currentMinutes = 0;
  String? hoveredUnitId;
  String? hoveredMarkerId;
  String? selectedUnitId;
  MapPoint? lastDebugPoint;
  String? lastCutInEventId;

  DateTime get startTime => mode == MapMode.campaign ? SekigaharaData.campaignStart : SekigaharaData.battleStart;
  DateTime get initialTime => mode == MapMode.campaign ? SekigaharaData.campaignInitial : SekigaharaData.battleInitial;
  DateTime get endTime => mode == MapMode.campaign ? SekigaharaData.campaignEnd : SekigaharaData.battleEnd;
  DateTime get currentTime => startTime.add(Duration(minutes: currentMinutes.round()));
  Size get imageSize => mode == MapMode.campaign ? SekigaharaData.campaignImageSize : SekigaharaData.battleImageSize;

  List<CampaignEvent> get visibleEvents {
    if (mode == MapMode.sekigaharaBattle) return SekigaharaData.events.where((e) => e.battlePoint != null).toList();
    return SekigaharaData.events;
  }

  CampaignEvent? get primaryEvent {
    final active = visibleEvents.where((e) => e.activeAt(currentTime)).toList();
    if (active.isNotEmpty) {
      active.sort((a, b) => b.start.compareTo(a.start));
      return active.first;
    }
    final window = mode == MapMode.campaign ? const Duration(days: 2) : const Duration(minutes: 35);
    final near = visibleEvents.where((e) => e.nearAt(currentTime, window)).toList();
    if (near.isEmpty) return null;
    near.sort((a, b) => a.start.difference(currentTime).inSeconds.abs().compareTo(b.start.difference(currentTime).inSeconds.abs()));
    return near.first;
  }

  @override
  void initState() {
    super.initState();
    _effectController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat();
    _cutInController = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    currentMinutes = initialTime.difference(startTime).inMinutes.toDouble();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cutInController.forward(from: 0));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _effectController.dispose();
    _cutInController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _setTime(DateTime time) {
    final clamped = time.isBefore(startTime) ? startTime : time.isAfter(endTime) ? endTime : time;
    setState(() => currentMinutes = clamped.difference(startTime).inMinutes.toDouble());
  }

  void _togglePlay() {
    setState(() => playing = !playing);
    _timer?.cancel();
    if (!playing) return;
    _timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      final step = mode == MapMode.campaign ? 60.0 * speed : 5.0 * speed;
      final endMinutes = endTime.difference(startTime).inMinutes.toDouble();
      setState(() {
        currentMinutes = math.min(currentMinutes + step, endMinutes);
        if (currentMinutes >= endMinutes) {
          playing = false;
          _timer?.cancel();
        }
      });
    });
  }

  void _switchMode() {
    _timer?.cancel();
    setState(() {
      playing = false;
      mode = mode == MapMode.campaign ? MapMode.sekigaharaBattle : MapMode.campaign;
      hoveredUnitId = null;
      hoveredMarkerId = null;
      selectedUnitId = null;
      lastDebugPoint = null;
      currentMinutes = initialTime.difference(startTime).inMinutes.toDouble();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _cutInController.forward(from: 0));
  }

  void _fitCamera(Size viewport) {
    final margin = 18.0;
    final sx = (viewport.width - margin * 2) / imageSize.width;
    final sy = (viewport.height - margin * 2) / imageSize.height;
    final fit = math.min(sx, sy);
    final minScale = mode == MapMode.campaign ? 0.70 : 0.50;
    final scale = math.max(fit, minScale);
    final dx = (viewport.width - imageSize.width * scale) / 2;
    final dy = (viewport.height - imageSize.height * scale) / 2;
    _transformController.value = Matrix4.identity()..translate(dx, dy)..scale(scale);
  }

  @override
  Widget build(BuildContext context) {
    final eventId = primaryEvent?.id;
    if (eventId != lastCutInEventId) {
      lastCutInEventId = eventId;
      _cutInController.forward(from: 0);
    }

    final selectedUnit = selectedUnitId == null ? null : SekigaharaData.units.where((u) => u.id == selectedUnitId).firstOrNull;
    final eastUnits = SekigaharaData.units.where((u) => u.visibleAt(currentTime, mode) && u.stateAt(currentTime).side == Side.east).toList();
    final westUnits = SekigaharaData.units.where((u) => u.visibleAt(currentTime, mode) && u.stateAt(currentTime).side == Side.west).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1C1711),
      body: SafeArea(
        child: Column(
          children: [
            HeaderBar(mode: mode, currentTime: currentTime, primaryEvent: primaryEvent, onSwitchMode: _switchMode),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Row(
                  children: [
                    ArmyColumn(title: '西軍', side: Side.west, units: westUnits, currentTime: currentTime, selectedUnitId: selectedUnitId, onTap: (id) => setState(() => selectedUnitId = id)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MapPanel(
                        mode: mode,
                        imageSize: imageSize,
                        currentTime: currentTime,
                        events: visibleEvents,
                        primaryEvent: primaryEvent,
                        transformController: _transformController,
                        effectValue: _effectController,
                        cutInValue: _cutInController,
                        showLabels: showLabels,
                        showDebug: showDebug,
                        hoveredUnitId: hoveredUnitId,
                        hoveredMarkerId: hoveredMarkerId,
                        selectedUnitId: selectedUnitId,
                        lastDebugPoint: lastDebugPoint,
                        onHoverUnit: (id) => setState(() => hoveredUnitId = id),
                        onHoverMarker: (id) => setState(() => hoveredMarkerId = id),
                        onSelectUnit: (id) => setState(() => selectedUnitId = id),
                        onDebugPoint: (p) => setState(() => lastDebugPoint = p),
                        onFitRequest: _fitCamera,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ArmyColumn(title: '東軍', side: Side.east, units: eastUnits, currentTime: currentTime, selectedUnitId: selectedUnitId, onTap: (id) => setState(() => selectedUnitId = id)),
                  ],
                ),
              ),
            ),
            SelectedInfoBar(unit: selectedUnit, currentTime: currentTime),
            TimelineBar(
              mode: mode,
              start: startTime,
              end: endTime,
              current: currentTime,
              playing: playing,
              speed: speed,
              showLabels: showLabels,
              showDebug: showDebug,
              onChanged: _setTime,
              onTogglePlay: _togglePlay,
              onSpeedChanged: (v) => setState(() => speed = v),
              onToggleLabels: () => setState(() => showLabels = !showLabels),
              onToggleDebug: () => setState(() => showDebug = !showDebug),
            ),
          ],
        ),
      ),
    );
  }
}

extension FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}

class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key, required this.mode, required this.currentTime, required this.primaryEvent, required this.onSwitchMode});
  final MapMode mode;
  final DateTime currentTime;
  final CampaignEvent? primaryEvent;
  final VoidCallback onSwitchMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF2C2117), Color(0xFF15100B)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        border: Border(bottom: BorderSide(color: Color(0xFF8C6A3E))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_formatEraDate(currentTime, mode), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFF3E5BF))),
              Text('${primaryEvent?.title ?? '関ヶ原戦役'}：${primaryEvent?.summary ?? '全国の戦線を時系列で表示しています。'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFFD7C69E))),
            ]),
          ),
          FilledButton.tonalIcon(onPressed: onSwitchMode, icon: const Icon(Icons.map_outlined), label: Text(mode == MapMode.campaign ? '関ヶ原本戦を見る' : '全国戦役へ戻る')),
        ],
      ),
    );
  }
}

class MapPanel extends StatefulWidget {
  const MapPanel({
    super.key,
    required this.mode,
    required this.imageSize,
    required this.currentTime,
    required this.events,
    required this.primaryEvent,
    required this.transformController,
    required this.effectValue,
    required this.cutInValue,
    required this.showLabels,
    required this.showDebug,
    required this.hoveredUnitId,
    required this.hoveredMarkerId,
    required this.selectedUnitId,
    required this.lastDebugPoint,
    required this.onHoverUnit,
    required this.onHoverMarker,
    required this.onSelectUnit,
    required this.onDebugPoint,
    required this.onFitRequest,
  });

  final MapMode mode;
  final Size imageSize;
  final DateTime currentTime;
  final List<CampaignEvent> events;
  final CampaignEvent? primaryEvent;
  final TransformationController transformController;
  final Animation<double> effectValue;
  final Animation<double> cutInValue;
  final bool showLabels;
  final bool showDebug;
  final String? hoveredUnitId;
  final String? hoveredMarkerId;
  final String? selectedUnitId;
  final MapPoint? lastDebugPoint;
  final ValueChanged<String?> onHoverUnit;
  final ValueChanged<String?> onHoverMarker;
  final ValueChanged<String> onSelectUnit;
  final ValueChanged<MapPoint> onDebugPoint;
  final ValueChanged<Size> onFitRequest;

  @override
  State<MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends State<MapPanel> {
  bool _didInitialFit = false;

  @override
  void didUpdateWidget(covariant MapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) _didInitialFit = false;
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.mode == MapMode.campaign ? SekigaharaData.campaignAsset : SekigaharaData.battleAsset;
    final minScale = widget.mode == MapMode.campaign ? 0.70 : 0.50;

    return LayoutBuilder(builder: (context, constraints) {
      final viewport = Size(constraints.maxWidth, constraints.maxHeight);
      if (!_didInitialFit) {
        _didInitialFit = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onFitRequest(viewport);
        });
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          color: const Color(0xFFD8C39A),
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTapDown: (d) {
                    if (!widget.showDebug) return;
                    final scene = widget.transformController.toScene(d.localPosition);
                    final x = scene.dx.clamp(0.0, widget.imageSize.width);
                    final y = scene.dy.clamp(0.0, widget.imageSize.height);
                    final p = MapPoint(x, y);
                    widget.onDebugPoint(p);
                    Clipboard.setData(ClipboardData(text: 'MapPoint(${x.toStringAsFixed(0)}, ${y.toStringAsFixed(0)})'));
                  },
                  child: MouseRegion(
                    onHover: (e) {
                      final scene = widget.transformController.toScene(e.localPosition);
                      final unitId = _hitTestUnit(scene);
                      final markerId = unitId == null ? _hitTestMarker(scene) : null;
                      if (unitId != widget.hoveredUnitId) widget.onHoverUnit(unitId);
                      if (markerId != widget.hoveredMarkerId) widget.onHoverMarker(markerId);
                    },
                    onExit: (_) {
                      widget.onHoverUnit(null);
                      widget.onHoverMarker(null);
                    },
                    child: InteractiveViewer(
                      transformationController: widget.transformController,
                      minScale: minScale,
                      maxScale: 4.5,
                      boundaryMargin: const EdgeInsets.all(5000),
                      panEnabled: true,
                      scaleEnabled: true,
                      constrained: false,
                      child: SizedBox(
                        width: widget.imageSize.width,
                        height: widget.imageSize.height,
                        child: Stack(
                          children: [
                            Positioned.fill(child: Image.asset(asset, fit: BoxFit.fill, filterQuality: FilterQuality.high)),
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: Listenable.merge([widget.transformController, widget.effectValue]),
                                builder: (context, _) {
                                  final scale = widget.transformController.value.getMaxScaleOnAxis();
                                  return CustomPaint(
                                    painter: MapOverlayPainter(
                                      mode: widget.mode,
                                      currentTime: widget.currentTime,
                                      markers: SekigaharaData.markers,
                                      units: SekigaharaData.units,
                                      events: widget.events,
                                      primaryEvent: widget.primaryEvent,
                                      hoveredUnitId: widget.hoveredUnitId,
                                      hoveredMarkerId: widget.hoveredMarkerId,
                                      selectedUnitId: widget.selectedUnitId,
                                      showLabels: widget.showLabels,
                                      showDebug: widget.showDebug,
                                      lastDebugPoint: widget.lastDebugPoint,
                                      pulse: widget.effectValue.value,
                                      screenScale: scale,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(top: 14, left: 14, child: BattleCutInCard(event: widget.primaryEvent, animation: widget.cutInValue)),
              Positioned(right: 12, top: 12, child: SmallMapButton(icon: Icons.center_focus_strong, label: '全体', onTap: () => widget.onFitRequest(viewport))),
            ],
          ),
        ),
      );
    });
  }

  String? _hitTestUnit(Offset scene) {
    final scale = widget.transformController.value.getMaxScaleOnAxis();
    final hitRadius = math.max(17.0 / scale, 8.0);
    for (final unit in SekigaharaData.units.reversed) {
      if (!unit.visibleAt(widget.currentTime, widget.mode)) continue;
      final point = unit.pointAt(widget.currentTime, widget.mode).toOffset();
      if ((point - scene).distance <= hitRadius) return unit.id;
    }
    return null;
  }

  String? _hitTestMarker(Offset scene) {
    final scale = widget.transformController.value.getMaxScaleOnAxis();
    final hitRadius = math.max(16.0 / scale, 7.0);
    for (final marker in SekigaharaData.markers.reversed) {
      final p = marker.pointFor(widget.mode);
      if (p == null) continue;
      if ((p.toOffset() - scene).distance <= hitRadius) return marker.id;
    }
    return null;
  }
}

class SmallMapButton extends StatelessWidget {
  const SmallMapButton({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xAA2B2118),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(children: [
            Icon(icon, size: 15, color: const Color(0xFFEED8A6)),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFEED8A6))),
          ]),
        ),
      ),
    );
  }
}

class BattleCutInCard extends StatelessWidget {
  const BattleCutInCard({super.key, required this.event, required this.animation});
  final CampaignEvent? event;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    if (event == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final p = Curves.easeOutCubic.transform(animation.value.clamp(0.0, 1.0));
        return Transform.translate(
          offset: Offset(-28 * (1 - p), 0),
          child: Opacity(
            opacity: p,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 430),
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
              decoration: BoxDecoration(
                color: const Color(0xE6E8D3A4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEACB72), width: 1.2),
                boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 14, offset: Offset(0, 6))],
              ),
              child: DefaultTextStyle(
                style: const TextStyle(color: Color(0xFF1F170E)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF7A1F1F), borderRadius: BorderRadius.circular(999)),
                      child: Text(event!.status, style: const TextStyle(color: Color(0xFFFFE9B0), fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(event!.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900))),
                  ]),
                  const SizedBox(height: 8),
                  _line('場所', event!.location),
                  _line('勢力', '東軍：${event!.eastForce}'),
                  _line('　　', '西軍：${event!.westForce}'),
                  _line('規模', event!.scale),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(children: [
            TextSpan(text: '$label：', style: const TextStyle(color: Color(0xFF5A3515), fontSize: 12, fontWeight: FontWeight.w900)),
            TextSpan(text: value, style: const TextStyle(color: Color(0xFF1F170E), fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

class ArmyColumn extends StatelessWidget {
  const ArmyColumn({
    super.key,
    required this.title,
    required this.side,
    required this.units,
    required this.currentTime,
    required this.selectedUnitId,
    required this.onTap,
  });

  final String title;
  final Side side;
  final List<ArmyUnit> units;
  final DateTime currentTime;
  final String? selectedUnitId;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final sideColor = side == Side.east ? const Color(0xFF2F68BD) : const Color(0xFFB83232);
    return Container(
      width: 210,
      decoration: BoxDecoration(color: const Color(0xE61B1510), borderRadius: BorderRadius.circular(16), border: Border.all(color: sideColor.withOpacity(0.55))),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: sideColor.withOpacity(0.28), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFFF5E5BD))),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: units.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final u = units[i];
              final f = u.stateAt(currentTime);
              final selected = u.id == selectedUnitId;
              return InkWell(
                onTap: () => onTap(u.id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0x332D8CFF) : const Color(0x33110D09),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? const Color(0xFFEDC866) : const Color(0x338C6A3E)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF4E1B5), fontWeight: FontWeight.w800, fontSize: 12.5)),
                    Text('${f.place} / ${_actionText(f.action)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFCDBB92), fontSize: 11)),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 5,
                        value: u.initialTroops <= 0 ? 0 : (f.troops / u.initialTroops).clamp(0.0, 1.0),
                        backgroundColor: const Color(0x553B2B1F),
                        color: sideColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text('${f.troops} / ${u.initialTroops} 人', style: const TextStyle(color: Color(0xFFB8AA86), fontSize: 10)),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class SelectedInfoBar extends StatelessWidget {
  const SelectedInfoBar({super.key, required this.unit, required this.currentTime});
  final ArmyUnit? unit;
  final DateTime currentTime;

  @override
  Widget build(BuildContext context) {
    if (unit == null) return const SizedBox.shrink();
    final f = unit!.stateAt(currentTime);
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xDD221912), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x668C6A3E))),
      child: Row(children: [
        Text(unit!.name, style: const TextStyle(color: Color(0xFFFFE5A8), fontWeight: FontWeight.w900)),
        const SizedBox(width: 12),
        Expanded(child: Text('${f.place} / ${_actionText(f.action)}：${f.note}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFD8C49A), fontSize: 12))),
      ]),
    );
  }
}

class TimelineBar extends StatelessWidget {
  const TimelineBar({
    super.key,
    required this.mode,
    required this.start,
    required this.end,
    required this.current,
    required this.playing,
    required this.speed,
    required this.showLabels,
    required this.showDebug,
    required this.onChanged,
    required this.onTogglePlay,
    required this.onSpeedChanged,
    required this.onToggleLabels,
    required this.onToggleDebug,
  });

  final MapMode mode;
  final DateTime start;
  final DateTime end;
  final DateTime current;
  final bool playing;
  final double speed;
  final bool showLabels;
  final bool showDebug;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onToggleLabels;
  final VoidCallback onToggleDebug;

  @override
  Widget build(BuildContext context) {
    final total = end.difference(start).inMinutes.toDouble();
    final value = current.difference(start).inMinutes.toDouble().clamp(0.0, total);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      color: const Color(0xFF17110C),
      child: Row(children: [
        IconButton.filledTonal(onPressed: onTogglePlay, icon: Icon(playing ? Icons.pause : Icons.play_arrow)),
        const SizedBox(width: 8),
        SizedBox(width: 135, child: Text(_formatEraDate(current, mode), style: const TextStyle(color: Color(0xFFF0DDAE), fontWeight: FontWeight.w800))),
        Expanded(child: Slider(min: 0, max: total, value: value, onChanged: (v) => onChanged(start.add(Duration(minutes: v.round()))))),
        DropdownButton<double>(
          value: speed,
          dropdownColor: const Color(0xFF2A2118),
          items: const [
            DropdownMenuItem(value: 0.5, child: Text('0.5x')),
            DropdownMenuItem(value: 1.0, child: Text('1x')),
            DropdownMenuItem(value: 2.0, child: Text('2x')),
            DropdownMenuItem(value: 4.0, child: Text('4x')),
          ],
          onChanged: (v) {
            if (v != null) onSpeedChanged(v);
          },
        ),
        const SizedBox(width: 8),
        FilterChip(label: const Text('ラベル'), selected: showLabels, onSelected: (_) => onToggleLabels()),
        const SizedBox(width: 6),
        FilterChip(label: const Text('座標'), selected: showDebug, onSelected: (_) => onToggleDebug()),
      ]),
    );
  }
}

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

String _formatEraDate(DateTime t, MapMode mode) {
  final date = '慶長5年（1600年）${t.month}/${t.day}';
  if (mode == MapMode.sekigaharaBattle) {
    return '$date ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
  return date;
}

String _actionText(UnitAction action) {
  switch (action) {
    case UnitAction.waiting:
      return '待機';
    case UnitAction.marching:
      return '進軍';
    case UnitAction.deployed:
      return '布陣';
    case UnitAction.fighting:
      return '交戦';
    case UnitAction.winning:
      return '優勢';
    case UnitAction.pressured:
      return '劣勢';
    case UnitAction.collapsing:
      return '崩壊';
    case UnitAction.retreating:
      return '退却';
    case UnitAction.betrayed:
      return '寝返り';
    case UnitAction.besieging:
      return '攻城';
    case UnitAction.defending:
      return '防戦';
    case UnitAction.delayed:
      return '遅延';
    case UnitAction.captured:
      return '捕縛';
    case UnitAction.executed:
      return '処刑';
    case UnitAction.destroyed:
      return '壊滅';
  }
}

part of 'sekigahara.dart';

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

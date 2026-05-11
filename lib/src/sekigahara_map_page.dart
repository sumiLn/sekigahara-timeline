part of 'sekigahara.dart';

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

  void _showArmySheet(String title, Side side, List<ArmyUnit> units) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18110C),
      barrierColor: const Color(0x99000000),
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return ArmyBottomSheetContent(
          title: title,
          side: side,
          units: units,
          currentTime: currentTime,
          selectedUnitId: selectedUnitId,
          onTap: (id) {
            Navigator.of(context).pop();
            setState(() => selectedUnitId = id);
          },
        );
      },
    );
  }

  Widget _buildMapPanel() {
    return MapPanel(
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
    );
  }

  Widget _buildDesktopLayout({required List<ArmyUnit> eastUnits, required List<ArmyUnit> westUnits, required ArmyUnit? selectedUnit}) {
    return Column(
      children: [
        HeaderBar(mode: mode, currentTime: currentTime, primaryEvent: primaryEvent, onSwitchMode: _switchMode),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Row(
              children: [
                ArmyColumn(title: '西軍', side: Side.west, units: westUnits, currentTime: currentTime, selectedUnitId: selectedUnitId, onTap: (id) => setState(() => selectedUnitId = id)),
                const SizedBox(width: 8),
                Expanded(child: _buildMapPanel()),
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
    );
  }

  Widget _buildMobileLayout({required List<ArmyUnit> eastUnits, required List<ArmyUnit> westUnits, required ArmyUnit? selectedUnit}) {
    return Stack(
      children: [
        Column(
          children: [
            MobileHeaderBar(mode: mode, currentTime: currentTime, primaryEvent: primaryEvent, onSwitchMode: _switchMode),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: _buildMapPanel(),
              ),
            ),
            SelectedInfoBar(unit: selectedUnit, currentTime: currentTime, compact: true),
            MobileTimelineBar(
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
        Positioned(
          left: 12,
          bottom: selectedUnit == null ? 112 : 152,
          child: FloatingArmyButton(
            title: '西軍',
            side: Side.west,
            count: westUnits.length,
            onTap: () => _showArmySheet('西軍', Side.west, westUnits),
          ),
        ),
        Positioned(
          right: 12,
          bottom: selectedUnit == null ? 112 : 152,
          child: FloatingArmyButton(
            title: '東軍',
            side: Side.east,
            count: eastUnits.length,
            onTap: () => _showArmySheet('東軍', Side.east, eastUnits),
          ),
        ),
      ],
    );
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
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 760;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1711),
      body: SafeArea(
        child: isMobile
            ? _buildMobileLayout(eastUnits: eastUnits, westUnits: westUnits, selectedUnit: selectedUnit)
            : _buildDesktopLayout(eastUnits: eastUnits, westUnits: westUnits, selectedUnit: selectedUnit),
      ),
    );
  }
}

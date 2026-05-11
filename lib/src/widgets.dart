part of 'sekigahara.dart';

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


class MobileHeaderBar extends StatelessWidget {
  const MobileHeaderBar({super.key, required this.mode, required this.currentTime, required this.primaryEvent, required this.onSwitchMode});
  final MapMode mode;
  final DateTime currentTime;
  final CampaignEvent? primaryEvent;
  final VoidCallback onSwitchMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF2C2117), Color(0xFF15100B)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        border: Border(bottom: BorderSide(color: Color(0xFF8C6A3E))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const Text('関ヶ原戦役', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFF3E5BF))),
              const SizedBox(height: 2),
              Text(_formatEraDate(currentTime, mode), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFE7D3A6))),
              if (primaryEvent != null)
                Text(primaryEvent!.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFFCDBB92))),
            ]),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 10)),
            onPressed: onSwitchMode,
            child: Text(mode == MapMode.campaign ? '本戦' : '全国', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          ),
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
              if (viewport.width < 620)
                Positioned(top: 10, left: 10, right: 58, child: BattleCutInCard(event: widget.primaryEvent, animation: widget.cutInValue))
              else
                Positioned(top: 14, left: 14, child: BattleCutInCard(event: widget.primaryEvent, animation: widget.cutInValue)),
              Positioned(right: 10, top: 10, child: SmallMapButton(icon: Icons.center_focus_strong, label: '全体', onTap: () => widget.onFitRequest(viewport))),
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
    final isMobile = MediaQuery.of(context).size.width < 620;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final p = Curves.easeOutCubic.transform(animation.value.clamp(0.0, 1.0));
        return Transform.translate(
          offset: Offset(-20 * (1 - p), 0),
          child: Opacity(
            opacity: p,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 430),
              padding: EdgeInsets.fromLTRB(isMobile ? 10 : 16, isMobile ? 9 : 13, isMobile ? 10 : 16, isMobile ? 9 : 13),
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
                    Expanded(child: Text(event!.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isMobile ? 14 : 21, fontWeight: FontWeight.w900))),
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
  const SelectedInfoBar({super.key, required this.unit, required this.currentTime, this.compact = false});
  final ArmyUnit? unit;
  final DateTime currentTime;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (unit == null) return const SizedBox.shrink();
    final f = unit!.stateAt(currentTime);
    return Container(
      margin: EdgeInsets.fromLTRB(compact ? 8 : 10, 0, compact ? 8 : 10, compact ? 4 : 6),
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 7 : 8),
      decoration: BoxDecoration(color: const Color(0xDD221912), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x668C6A3E))),
      child: Row(children: [
        Text(unit!.name, style: const TextStyle(color: Color(0xFFFFE5A8), fontWeight: FontWeight.w900)),
        const SizedBox(width: 12),
        Expanded(child: Text('${f.place} / ${_actionText(f.action)}：${f.note}', maxLines: compact ? 2 : 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xFFD8C49A), fontSize: compact ? 11 : 12))),
      ]),
    );
  }
}


class FloatingArmyButton extends StatelessWidget {
  const FloatingArmyButton({super.key, required this.title, required this.side, required this.count, required this.onTap});
  final String title;
  final Side side;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sideColor = side == Side.east ? const Color(0xFF2F68BD) : const Color(0xFFB83232);
    return Material(
      color: sideColor.withOpacity(0.92),
      elevation: 8,
      shadowColor: const Color(0x88000000),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: const TextStyle(color: Color(0xFFFFF0C0), fontWeight: FontWeight.w900, fontSize: 13)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0x33000000), borderRadius: BorderRadius.circular(999)),
              child: Text('$count', style: const TextStyle(color: Color(0xFFFFF0C0), fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }
}

class ArmyBottomSheetContent extends StatelessWidget {
  const ArmyBottomSheetContent({
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
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.72),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(width: 8, height: 24, decoration: BoxDecoration(color: sideColor, borderRadius: BorderRadius.circular(99))),
            const SizedBox(width: 8),
            Expanded(child: Text('$title 部隊一覧', style: const TextStyle(color: Color(0xFFF5E5BD), fontSize: 18, fontWeight: FontWeight.w900))),
            Text('${units.length}隊', style: const TextStyle(color: Color(0xFFCDBB92), fontSize: 12, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 10),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: units.length,
              separatorBuilder: (_, __) => const SizedBox(height: 7),
              itemBuilder: (context, i) {
                final u = units[i];
                final f = u.stateAt(currentTime);
                final selected = u.id == selectedUnitId;
                return InkWell(
                  onTap: () => onTap(u.id),
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0x332D8CFF) : const Color(0x33110D09),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: selected ? const Color(0xFFEDC866) : const Color(0x338C6A3E)),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF4E1B5), fontWeight: FontWeight.w900, fontSize: 13.5)),
                          const SizedBox(height: 2),
                          Text('${f.place} / ${_actionText(f.action)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFCDBB92), fontSize: 11.5)),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 72,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${f.troops}人', style: const TextStyle(color: Color(0xFFFFE5A8), fontSize: 11, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 5,
                              value: u.initialTroops <= 0 ? 0 : (f.troops / u.initialTroops).clamp(0.0, 1.0),
                              backgroundColor: const Color(0x553B2B1F),
                              color: sideColor,
                            ),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
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


class MobileTimelineBar extends StatelessWidget {
  const MobileTimelineBar({
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
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
      decoration: const BoxDecoration(
        color: Color(0xFF17110C),
        border: Border(top: BorderSide(color: Color(0x443B2B1F))),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          IconButton.filledTonal(
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            padding: EdgeInsets.zero,
            onPressed: onTogglePlay,
            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(_formatEraDate(current, mode), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF0DDAE), fontWeight: FontWeight.w900, fontSize: 12))),
          const SizedBox(width: 8),
          DropdownButton<double>(
            value: speed,
            isDense: true,
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
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'ラベル',
            visualDensity: VisualDensity.compact,
            onPressed: onToggleLabels,
            color: showLabels ? const Color(0xFFFFE0A0) : const Color(0xFF8A7B61),
            icon: const Icon(Icons.label_outline, size: 20),
          ),
          IconButton(
            tooltip: '座標',
            visualDensity: VisualDensity.compact,
            onPressed: onToggleDebug,
            color: showDebug ? const Color(0xFFFFE0A0) : const Color(0xFF8A7B61),
            icon: const Icon(Icons.my_location, size: 20),
          ),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7)),
          child: Slider(min: 0, max: total, value: value, onChanged: (v) => onChanged(start.add(Duration(minutes: v.round())))),
        ),
      ]),
    );
  }
}

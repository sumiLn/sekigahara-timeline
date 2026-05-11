part of 'sekigahara.dart';

extension FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
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

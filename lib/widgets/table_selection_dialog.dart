// table_selection_dialog_premium_compact.dart
// Premium compact dialog with round-table map, auto-layout (side-by-side),
// minimap, zoom/pan, search, size slider, compact side panel, chair occupancy handling,
// long-press to toggle chair status, and a Floor badge (default: Ground Floor).

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/utils/empty_kot_response.dart';
import 'package:my_app/services/api_service.dart';

import '../core/providers/providers.dart';

/* ───────── Theme accents ───────── */

class Pro {
  static const Color bg2 = Color(0xFFF4F6FB);
  static const Color border = Color(0x332A2F3A);
  static const Color ink = Color(0xFF111827);
  static const Color sub = Color(0xFF6B7280);
  static const Color primary = Color(0xFF6D5DF6);
  static const Color primarySoft = Color(0xFFDCD8FF);
  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);
  static const Color warn = Color(0xFFF59E0B);
  static const Color info = Color(0xFF2563EB);

  static const BorderRadius r12 = BorderRadius.all(Radius.circular(12));
  static const BorderRadius r16 = BorderRadius.all(Radius.circular(16));

  static List<BoxShadow> shadowSm = const [
    BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4)),
  ];

  static BoxDecoration card() => BoxDecoration(
        color: Colors.white,
        borderRadius: r16,
        border: Border.all(color: border),
        boxShadow: shadowSm,
      );

  static BoxDecoration canvas() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8FAFF)],
        ),
      );
}

/* ───────── Config ───────── */

const double kGrid = 32;
const double kChairPad = 14; // small gap from table edge
const double kChairIconSize = 18;

const double kWorldFactor = 1.0;
const double kMinWorldW = 960;
const double kMinWorldH = 560;

const double kEdgePad = 24;
const double kGap = 40;

const double kMinDiameter = 64;
const double kMaxDiameter = 128;

const double kDragSnap = 8;

/* ───────── Models ───────── */

enum TableStatus { free, occupied, reserved, billRequested }

enum SeatStatus { empty, taken }

class SeatModel {
  final int no;
  SeatStatus status;
  SeatModel(this.no, {this.status = SeatStatus.empty});
}

class PosTableModel {
  final String id;
  final String label;
  final bool round;
  final double w, h, x, y;
  final TableStatus status;
  final List<SeatModel> seats;
  final List<Map<String, dynamic>> kotDetails; // 👈 add this
  const PosTableModel({
    required this.id,
    required this.label,
    required this.round,
    required this.w,
    required this.h,
    required this.x,
    required this.y,
    required this.status,
    required this.seats,
    this.kotDetails = const [], // 👈 default empty
  });
}

class AreaModel {
  final String id;
  final String name;
  final List<PosTableModel> tables;
  const AreaModel({required this.id, required this.name, required this.tables});
}

class TableSeatSelection {
  final String areaId;
  final String areaName;
  final String? tableId;
  final int? seatNo;
  const TableSeatSelection({
    required this.areaId,
    required this.areaName,
    this.tableId,
    this.seatNo,
  });
}

/* ───────── Demo data (fallback) ───────── */

// List<SeatModel> _makeSeats(int n, {int taken = 0}) => List.generate(
//       n,
//       (i) => SeatModel(i + 1,
//           status: i < taken ? SeatStatus.taken : SeatStatus.empty),
//     );

// List<AreaModel> demoAreas() => [
//       AreaModel(id: 'A', name: 'Ground Floor', tables: [
//         PosTableModel(
//           id: 'T1',
//           label: 'T1',
//           round: true,
//           w: 130,
//           h: 130,
//           x: 80,
//           y: 100,
//           status: TableStatus.free,
//           seats: _makeSeats(6),
//         ),
//         PosTableModel(
//           id: 'T2',
//           label: 'T2',
//           round: false,
//           w: 150,
//           h: 150,
//           x: 360,
//           y: 120,
//           status: TableStatus.occupied,
//           seats: _makeSeats(6, taken: 3),
//         ),
//         PosTableModel(
//           id: 'T3',
//           label: 'T3',
//           round: true,
//           w: 150,
//           h: 150,
//           x: 680,
//           y: 140,
//           status: TableStatus.billRequested,
//           seats: _makeSeats(6, taken: 2),
//         ),
//         PosTableModel(
//           id: 'T4',
//           label: 'T4',
//           round: false,
//           w: 150,
//           h: 150,
//           x: 120,
//           y: 420,
//           status: TableStatus.reserved,
//           seats: _makeSeats(8),
//         ),
//         PosTableModel(
//           id: 'T5',
//           label: 'T5',
//           round: true,
//           w: 160,
//           h: 160,
//           x: 420,
//           y: 440,
//           status: TableStatus.occupied,
//           seats: _makeSeats(8, taken: 5),
//         ),
//         PosTableModel(
//           id: 'T6',
//           label: 'T6',
//           round: true,
//           w: 140,
//           h: 140,
//           x: 720,
//           y: 420,
//           status: TableStatus.free,
//           seats: _makeSeats(6),
//         ),
//       ]),
//     ];

/* ───────── Working model ───────── */

class PlacedTable {
  final String id;
  final String label;
  final TableStatus status;
  final List<SeatModel> seats;
  Offset center; // world coords
  PlacedTable({
    required this.id,
    required this.label,
    required this.status,
    required this.seats,
    required this.center,
  });
}

/* ───────── Dialog ───────── */

class TableSelectionDialog extends StatefulWidget {
  final List<AreaModel>? areas;
  final String? initialAreaId;
  final String? initialAreaName; // optional label override (used as Floor)

  const TableSelectionDialog({
    super.key,
    this.areas,
    this.initialAreaId,
    this.initialAreaName,
  });

  @override
  State<TableSelectionDialog> createState() => _TableSelectionDialogState();
}

class _TableSelectionDialogState extends State<TableSelectionDialog> {
  List<AreaModel> _areas = const [];
  int areaIdx = 0;

  double tableDiameter = 96;
  late List<PlacedTable> _placed;

  String? selectedTableId;
  ({String tableId, int seatNo})? selectedSeat;

  final TextEditingController _search = TextEditingController();

  double scale = 1.0;
  Offset viewOffset = Offset.zero;

  bool fFree = true, fOcc = true, fRes = true, fBill = true;
  bool _needsAutoArrange = true;

  bool _loading = false;
  String? _loadError;

  String get floorName => (widget.initialAreaName?.trim().isNotEmpty ?? false)
      ? widget.initialAreaName!.trim()
      : 'Ground Floor';

  @override
  void initState() {
    super.initState();

    if (widget.areas != null && widget.areas!.isNotEmpty) {
      // always show the UI as a single "Floor" (even if multiple areas are passed)
      _areas = [
        AreaModel(
          id: widget.areas!.first.id,
          name: floorName,
          tables: widget.areas!.expand((a) => a.tables).toList(),
        ),
      ];
      _rebuildPlaced();
    } else if (widget.initialAreaId != null &&
        widget.initialAreaId!.isNotEmpty) {
      _loadAreasFromApi(widget.initialAreaId!, floorName);
    } else {
      _loadAreasFromApi('', floorName);
    }
  }

  Future<void> _loadAreasFromApi(String areaId, String? areaName) async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final rawList = await ApiService().fetchTables(areaId: areaId);

      final tables = rawList.map((t) {
        final tableId = (t["TableID"] ?? t["TableId"] ?? '').toString();
        final label = (t["TableName"] ?? t["TableNO"] ?? 'T?').toString();
        final format = (t["TableFormat"] ?? 'SQUARE').toString().toUpperCase();

        final chairsCount =
            int.tryParse((t["NoOfChairs"] ?? '4').toString()) ?? 4;

        final occupiedRaw = List.from(t["occupiedChairs"] ?? const []);
        final occupiedSet = occupiedRaw
            .map((e) => int.tryParse(e.toString()))
            .whereType<int>()
            .toSet();

        final seats = List<SeatModel>.generate(
          chairsCount,
          (i) => SeatModel(
            i + 1,
            status: occupiedSet.contains(i + 1)
                ? SeatStatus.taken
                : SeatStatus.empty,
          ),
        );

        final hasKotPrefix = (t["KOTPrefix"]?.toString() ?? '').isNotEmpty;
        final hasKotNumber = (t["KOTNumber"]?.toString() ?? '').isNotEmpty;
        final ks = (t["KOTStatus"]?.toString() ?? '').toLowerCase();

        final status = ks.contains('bill')
            ? TableStatus.billRequested
            : ks.contains('reserv')
                ? TableStatus.reserved
                : ((hasKotPrefix && hasKotNumber) || occupiedSet.isNotEmpty
                    ? TableStatus.occupied
                    : TableStatus.free);

        final kd = List<Map<String, dynamic>>.from(t["kotDetails"] ?? const []);

        return PosTableModel(
          id: tableId,
          label: label,
          round: format == 'ROUND',
          w: 120,
          h: 120,
          x: 0,
          y: 0,
          status: status,
          seats: seats,
          kotDetails: kd,
        );
      }).toList();

      _areas = [
        AreaModel(
          id: areaId,
          name: areaName ?? floorName,
          tables: tables,
        )
      ];
      areaIdx = 0;
      _rebuildPlaced();
    } catch (e) {
      _loadError = 'Failed to load tables: $e';
      if (_areas.isEmpty) {
        _rebuildPlaced();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _rebuildPlaced() {
    final a = _areas.isEmpty
        ? AreaModel(id: '-', name: floorName, tables: const [])
        : _areas[areaIdx];
    _placed = a.tables
        .map((t) => PlacedTable(
              id: t.id,
              label: t.label,
              status: t.status,
              seats: t.seats,
              center: Offset(t.x + t.w / 2, t.y + t.h / 2),
            ))
        .toList();
    _needsAutoArrange = true;
  }

  Future<void> _openKotForSelection() async {
    if (selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a table first')),
      );
      return;
    }

    final a = _areas[areaIdx];
    final t = a.tables.firstWhere((x) => x.id == selectedTableId);

    // If a seat was picked, match that seat; else, take the first KOT on the table.
    final seatNo = selectedSeat?.seatNo.toString();
    Map<String, dynamic>? row;

    if (seatNo != null) {
      row = t.kotDetails.firstWhere(
        (k) => (k['ChairNo']?.toString() ?? '') == seatNo,
        orElse: () => {},
      );
    }
    row ??= t.kotDetails.isNotEmpty ? t.kotDetails.first : null;

    final kotId = row?['kotMasterID']?.toString();
    if (kotId == null || kotId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No job found on this chair')),
      );
      return;
    }

    // Fetch KOT details and push into providers
    try {
      final kot = await emptyKotDetails();
      final container = ProviderScope.containerOf(context);
      container.read(kotDetailsProvider.notifier).state = kot;
      container.read(activeKotProvider.notifier).state = kot;
      container.read(isUpdatingFromOrderListProvider.notifier).state = false;

      // Optional: close the dialog and return the selection
      Navigator.of(context).pop(TableSeatSelection(
        areaId: a.id,
        areaName: floorName,
        tableId: t.id,
        seatNo: selectedSeat?.seatNo,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open job: $e')),
      );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  AreaModel get area => _areas.isEmpty
      ? AreaModel(id: '-', name: floorName, tables: const [])
      : _areas[areaIdx];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Dialog(
        child: SizedBox(
          width: 420,
          height: 260,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final counts = _counts(area);
    final statusCounts = _statusCounts(area);

    final visible = _placed.where((t) {
      switch (t.status) {
        case TableStatus.free:
          return fFree;
        case TableStatus.occupied:
          return fOcc;
        case TableStatus.reserved:
          return fRes;
        case TableStatus.billRequested:
          return fBill;
      }
    }).toList();

    final filteredId = _filteredTableId(area);

    final media = MediaQuery.of(context);
    final maxW = (media.size.width * 0.94).clamp(820.0, 1180.0);
    final maxH = (media.size.height * 0.92).clamp(600.0, 800.0);

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: Pro.r16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(counts, statusCounts),
              const Divider(height: 1, color: Color(0xFFE9EBF3)),
              _buildFloorBadge(), // ⬅ replaced area tabs with a Floor badge
              const SizedBox(height: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: Container(
                          decoration: Pro.card(),
                          child: _MapCanvas(
                            tables: visible,
                            allTables: _placed,
                            tableDiameter: tableDiameter,
                            highlightTableId: selectedTableId ?? filteredId,
                            searchQuery: _search.text.trim(),
                            scale: scale,
                            viewOffset: viewOffset,
                            onScaleChanged: (v) => setState(() => scale = v),
                            onViewOffsetChanged: (o) =>
                                setState(() => viewOffset = o),
                            needsAutoArrange: _needsAutoArrange,
                            onApplyAutoLayout: (double newDiameter,
                                Map<String, Offset> centers, Offset newOffset) {
                              setState(() {
                                tableDiameter = newDiameter;
                                for (final e in centers.entries) {
                                  final i =
                                      _placed.indexWhere((p) => p.id == e.key);
                                  if (i != -1) _placed[i].center = e.value;
                                }
                                viewOffset = newOffset;
                                scale = 1.0;
                                _needsAutoArrange = false;
                              });
                            },
                            onMoveTable: (id, newCenter) {
                              final i = _placed.indexWhere((p) => p.id == id);
                              if (i != -1) {
                                setState(() => _placed[i].center = newCenter);
                              }
                            },
                            onTapTable: (id) => setState(() {
                              selectedTableId = id;
                              selectedSeat = null;
                            }),
                            onTapSeat: (id, seat) => setState(() {
                              selectedTableId = id;
                              selectedSeat = (tableId: id, seatNo: seat);
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 5,
                        child: Container(
                          decoration: Pro.card(),
                          child: _SidePanel(
                            area: area,
                            floorName: floorName,
                            selectedTableId: selectedTableId,
                            selectedSeatNo: selectedSeat?.seatNo,
                            onSelectSeat: (no) => setState(() {
                              if (selectedTableId == null) return;
                              final t = area.tables.firstWhere(
                                (x) => x.id == selectedTableId,
                                orElse: () => const PosTableModel(
                                  id: '-',
                                  label: '-',
                                  round: true,
                                  w: 0,
                                  h: 0,
                                  x: 0,
                                  y: 0,
                                  status: TableStatus.free,
                                  seats: [],
                                ),
                              );
                              final seat = t.seats.firstWhere(
                                (s) => s.no == no,
                                orElse: () => SeatModel(no),
                              );
                              if (seat.status == SeatStatus.taken) return;
                              selectedSeat =
                                  (tableId: selectedTableId!, seatNo: no);
                            }),
                            // ⬇ long-press: toggle taken/free inline
                            onToggleSeatStatus: (no) {
                              if (selectedTableId == null) return;
                              final a = _areas[areaIdx];
                              final tIndex = a.tables
                                  .indexWhere((t) => t.id == selectedTableId);
                              if (tIndex == -1) return;

                              final oldT = a.tables[tIndex];
                              if (no <= 0 || no > oldT.seats.length) return;
                              final seat = oldT.seats[no - 1];

                              final toggled = seat.status == SeatStatus.taken
                                  ? SeatStatus.empty
                                  : SeatStatus.taken;

                              setState(() {
                                // flip the seat
                                seat.status = toggled;

                                // if this was the selected seat and it just got taken, unselect it
                                if (toggled == SeatStatus.taken &&
                                    selectedSeat?.seatNo == no) {
                                  selectedSeat = null;
                                }

                                // recompute table status (unless reserved/bill)
                                if (oldT.status != TableStatus.reserved &&
                                    oldT.status != TableStatus.billRequested) {
                                  final anyTaken = oldT.seats
                                      .any((s) => s.status == SeatStatus.taken);
                                  final newStatus = anyTaken
                                      ? TableStatus.occupied
                                      : TableStatus.free;

                                  // replace table in _areas
                                  final newTables =
                                      List<PosTableModel>.from(a.tables);
                                  newTables[tIndex] = PosTableModel(
                                    id: oldT.id,
                                    label: oldT.label,
                                    round: oldT.round,
                                    w: oldT.w,
                                    h: oldT.h,
                                    x: oldT.x,
                                    y: oldT.y,
                                    status: newStatus,
                                    seats: oldT.seats, // keep same list
                                  );
                                  _areas[areaIdx] = AreaModel(
                                    id: a.id,
                                    name: a.name,
                                    tables: newTables,
                                  );

                                  // replace in _placed so ring color updates
                                  final pIndex = _placed
                                      .indexWhere((p) => p.id == oldT.id);
                                  if (pIndex != -1) {
                                    _placed[pIndex] = PlacedTable(
                                      id: _placed[pIndex].id,
                                      label: _placed[pIndex].label,
                                      status: newStatus,
                                      seats: oldT.seats,
                                      center: _placed[pIndex].center,
                                    );
                                  }
                                }
                              });
                            },
                            onConfirm: () {
                              final t = (selectedTableId == null)
                                  ? null
                                  : area.tables.firstWhere(
                                      (x) => x.id == selectedTableId,
                                      orElse: () => const PosTableModel(
                                        id: '-',
                                        label: '-',
                                        round: true,
                                        w: 0,
                                        h: 0,
                                        x: 0,
                                        y: 0,
                                        status: TableStatus.free,
                                        seats: [],
                                      ),
                                    );

                              if (t == null || t.id == '-') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pick a table to continue'),
                                  ),
                                );
                                return;
                              }

                              if (t.seats.isNotEmpty) {
                                if (selectedSeat == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Pick a free chair to continue'),
                                    ),
                                  );
                                  return;
                                }
                                final seatNo = selectedSeat!.seatNo;
                                final seat = t.seats.firstWhere(
                                  (s) => s.no == seatNo,
                                  orElse: () => SeatModel(seatNo),
                                );
                                if (seat.status == SeatStatus.taken) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Chair $seatNo is occupied — choose another'),
                                    ),
                                  );
                                  return;
                                }
                              }

                              final sel = TableSeatSelection(
                                areaId: area.id,
                                areaName: floorName, // return Floor label
                                tableId: selectedTableId,
                                seatNo: selectedSeat?.seatNo,
                              );
                              Navigator.of(context).pop(sel);
                            },
                            onOpenKot:
                                _openKotForSelection, // 👈 pass a handler
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _loadError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /* ───────── Header / Floor badge / Helpers ───────── */

  Widget _buildHeader((int free, int occ) counts,
      ({int free, int occ, int res, int bill}) statusCounts) {
    final pillWidth = math.min(320.0, MediaQuery.of(context).size.width * 0.34);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: Pro.card(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(children: [
                const Icon(Icons.search, size: 16, color: Pro.sub),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _search,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search table (e.g., T3)…',
                      hintStyle: TextStyle(fontSize: 12, color: Pro.sub),
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          _HorizontalStatusPill(
            free: fFree,
            occ: fOcc,
            res: fRes,
            bill: fBill,
            countFree: statusCounts.free,
            countOcc: statusCounts.occ,
            countRes: statusCounts.res,
            countBill: statusCounts.bill,
            onFreeChanged: (v) => setState(() => fFree = v),
            onOccChanged: (v) => setState(() => fOcc = v),
            onResChanged: (v) => setState(() => fRes = v),
            onBillChanged: (v) => setState(() => fBill = v),
            height: 30,
            width: pillWidth,
          ),
          const SizedBox(width: 10),
          Flexible(
            fit: FlexFit.loose,
            child: Row(children: [
              Text('Free: ${counts.$1} • Occ: ${counts.$2}',
                  style: const TextStyle(fontSize: 12, color: Pro.sub)),
              const SizedBox(width: 10),
              const Text('Size',
                  style: TextStyle(fontSize: 12, color: Pro.sub)),
              const SizedBox(width: 6),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    activeTrackColor: Pro.primary,
                    inactiveTrackColor: Pro.primarySoft,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: tableDiameter.clamp(kMinDiameter, kMaxDiameter),
                    min: kMinDiameter,
                    max: kMaxDiameter,
                    divisions: ((kMaxDiameter - kMinDiameter) / 4).round(),
                    label: '${tableDiameter.round()}',
                    onChanged: (v) => setState(() => tableDiameter = v),
                  ),
                ),
              ),
            ]),
          ),
          IconButton(
            tooltip: 'Zoom out',
            onPressed: () =>
                setState(() => scale = (scale - .1).clamp(.6, 3.0)),
            icon: const Icon(Icons.remove, size: 18),
          ),
          IconButton(
            tooltip: 'Zoom in',
            onPressed: () =>
                setState(() => scale = (scale + .1).clamp(.6, 3.0)),
            icon: const Icon(Icons.add, size: 18),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: () => setState(() => _needsAutoArrange = true),
            child: const Text('Reset'),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorBadge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Pro.border),
            boxShadow: Pro.shadowSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.apartment, size: 16, color: Pro.ink),
              const SizedBox(width: 6),
              Text('Floor: $floorName',
                  style: const TextStyle(fontSize: 12, color: Pro.ink)),
            ],
          ),
        ),
      ),
    );
  }

  String? _filteredTableId(AreaModel a) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return null;
    final t = a.tables.firstWhere(
      (t) => t.label.toLowerCase().contains(q),
      orElse: () => const PosTableModel(
          id: '-',
          label: '-',
          round: true,
          w: 0,
          h: 0,
          x: 0,
          y: 0,
          status: TableStatus.free,
          seats: []),
    );
    return t.id == '-' ? null : t.id;
  }

  (int free, int occ) _counts(AreaModel a) {
    int free = 0, occ = 0;
    for (final t in a.tables) {
      if (t.status == TableStatus.free) free++;
      if (t.status == TableStatus.occupied) occ++;
    }
    return (free, occ);
  }

  ({int free, int occ, int res, int bill}) _statusCounts(AreaModel a) {
    int free = 0, occ = 0, res = 0, bill = 0;
    for (final t in a.tables) {
      switch (t.status) {
        case TableStatus.free:
          free++;
          break;
        case TableStatus.occupied:
          occ++;
          break;
        case TableStatus.reserved:
          res++;
          break;
        case TableStatus.billRequested:
          bill++;
          break;
      }
    }
    return (free: free, occ: occ, res: res, bill: bill);
  }
}

/* ───────── Horizontal status pill (with counts) ───────── */

class _HorizontalStatusPill extends StatelessWidget {
  final bool free, occ, res, bill;
  final int? countFree, countOcc, countRes, countBill;
  final ValueChanged<bool> onFreeChanged;
  final ValueChanged<bool> onOccChanged;
  final ValueChanged<bool> onResChanged;
  final ValueChanged<bool> onBillChanged;

  final double height;
  final double width;
  final double gapDividerOpacity;
  final BorderRadius radius;

  const _HorizontalStatusPill({
    super.key,
    required this.free,
    required this.occ,
    required this.res,
    required this.bill,
    this.countFree,
    this.countOcc,
    this.countRes,
    this.countBill,
    required this.onFreeChanged,
    required this.onOccChanged,
    required this.onResChanged,
    required this.onBillChanged,
    this.height = 30,
    this.width = 320,
    this.gapDividerOpacity = .45,
    this.radius = const BorderRadius.all(Radius.circular(999)),
  });

  @override
  Widget build(BuildContext context) {
    Widget divider() => SizedBox(
          width: 1,
          height: height,
          child: DecoratedBox(
            decoration:
                BoxDecoration(color: Pro.border.withOpacity(gapDividerOpacity)),
          ),
        );

    Widget badge(int? n, bool active) => (n == null)
        ? const SizedBox.shrink()
        : Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: active ? Colors.white : const Color(0xFFF2F4FA),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Pro.border),
            ),
            child: Text('$n',
                style: const TextStyle(fontSize: 10, color: Pro.sub)),
          );

    Widget seg({
      required String label,
      required bool active,
      required int? count,
      required Color color,
      required VoidCallback onTap,
      BorderRadius? r,
    }) {
      return Expanded(
        child: SizedBox(
          height: height,
          child: Material(
            color: active ? color.withOpacity(.10) : Colors.white,
            borderRadius: r ?? BorderRadius.zero,
            child: InkWell(
              onTap: onTap,
              borderRadius: r ?? BorderRadius.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: active ? Pro.ink : Pro.sub,
                      letterSpacing: .2,
                    ),
                  ),
                  badge(count, active),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: Border.all(color: Pro.border),
          boxShadow: Pro.shadowSm,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              seg(
                label: 'Free',
                count: countFree,
                active: free,
                color: Pro.success,
                onTap: () => onFreeChanged(!free),
                r: const BorderRadius.horizontal(left: Radius.circular(999)),
              ),
              divider(),
              seg(
                label: 'Occu',
                count: countOcc,
                active: occ,
                color: Pro.danger,
                onTap: () => onOccChanged(!occ),
              ),
              divider(),
              seg(
                label: 'Res',
                count: countRes,
                active: res,
                color: Pro.warn,
                onTap: () => onResChanged(!res),
              ),
              divider(),
              seg(
                label: 'Bill',
                count: countBill,
                active: bill,
                color: Pro.info,
                onTap: () => onBillChanged(!bill),
                r: const BorderRadius.horizontal(right: Radius.circular(999)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ───────── Map canvas & layout (with minimap) ───────── */

class _MapCanvas extends StatefulWidget {
  final List<PlacedTable> tables;
  final List<PlacedTable> allTables;
  final double tableDiameter;
  final String? highlightTableId;
  final String searchQuery;

  final double scale;
  final Offset viewOffset;
  final ValueChanged<double> onScaleChanged;
  final ValueChanged<Offset> onViewOffsetChanged;

  final bool needsAutoArrange;
  final void Function(
          double newDiameter, Map<String, Offset> idToCenter, Offset newOffset)
      onApplyAutoLayout;

  final void Function(String id, Offset newCenter) onMoveTable;
  final void Function(String id) onTapTable;
  final void Function(String id, int seatNo) onTapSeat;

  const _MapCanvas({
    required this.tables,
    required this.allTables,
    required this.tableDiameter,
    required this.highlightTableId,
    required this.searchQuery,
    required this.scale,
    required this.viewOffset,
    required this.onScaleChanged,
    required this.onViewOffsetChanged,
    required this.needsAutoArrange,
    required this.onApplyAutoLayout,
    required this.onMoveTable,
    required this.onTapTable,
    required this.onTapSeat,
  });

  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> {
  bool panning = false;
  Offset panAnchor = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final worldW = math.max(kMinWorldW, cons.maxWidth * kWorldFactor);
      final worldH = math.max(kMinWorldH, cons.maxHeight * kWorldFactor);

      if (widget.needsAutoArrange) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final layout = _computeAutoLayout(
            viewportW: cons.maxWidth,
            viewportH: cons.maxHeight,
            tableCount: widget.allTables.length,
          );
          final centers = _gridCenters(
            worldW: worldW,
            worldH: worldH,
            cols: layout.cols,
            rows: layout.rows,
            itemExtent: layout.itemExtent,
          );
          final idToCenter = <String, Offset>{};
          for (int i = 0; i < widget.allTables.length; i++) {
            idToCenter[widget.allTables[i].id] = centers[i];
          }
          final off = Offset(
            (cons.maxWidth - worldW) / 2,
            (cons.maxHeight - worldH) / 2,
          );
          widget.onApplyAutoLayout(layout.diameter, idToCenter, off);
        });
      }

      final viewportRect = Rect.fromLTWH(
        -widget.viewOffset.dx,
        -widget.viewOffset.dy,
        cons.maxWidth / widget.scale,
        cons.maxHeight / widget.scale,
      );

      return ClipRRect(
        borderRadius: Pro.r16,
        child: Container(
          decoration: Pro.canvas(),
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            // Mini-map
            Positioned(
              right: 8,
              bottom: 8,
              child: Opacity(
                opacity: .95,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Pro.border),
                    boxShadow: Pro.shadowSm,
                  ),
                  child: CustomPaint(
                    size: const Size(140, 90),
                    painter: _MiniMapPainter(
                      centers: widget.tables.map((t) => t.center).toList(),
                      worldSize: Size(worldW, worldH),
                      viewport: viewportRect,
                    ),
                  ),
                ),
              ),
            ),

            Listener(
              onPointerSignal: (ps) {
                if (ps is PointerScrollEvent) {
                  final dz = ps.scrollDelta.dy < 0 ? 0.1 : -0.1;
                  final ns = (widget.scale + dz).clamp(.6, 3.0);
                  widget.onScaleChanged(ns);
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) {
                  panning = true;
                  panAnchor = d.localPosition - widget.viewOffset;
                },
                onPanUpdate: (d) {
                  if (panning) {
                    widget.onViewOffsetChanged(d.localPosition - panAnchor);
                  }
                },
                onPanEnd: (_) => panning = false,
                child: Stack(children: [
                  Transform.translate(
                    offset: widget.viewOffset,
                    child: Transform.scale(
                      scale: widget.scale,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: worldW,
                        height: worldH,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (final t in widget.tables)
                              _buildPlaced(t, widget.tableDiameter,
                                  selected: widget.highlightTableId == t.id),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );
    });
  }

  // ⬇️ Balanced grid so tables appear side-by-side by default
  _AutoLayout _computeAutoLayout({
    required double viewportW,
    required double viewportH,
    required int tableCount,
  }) {
    if (tableCount <= 0) {
      return _AutoLayout(
        cols: 0,
        rows: 0,
        diameter: kMinDiameter,
        itemExtent: kMinDiameter + 2 * kChairPad,
      );
    }

    final aspect = viewportW / viewportH;
    int cols = math.max(2, (math.sqrt(tableCount * aspect)).round());
    int rows = (tableCount / cols).ceil();

    final availW = math.max(200.0, viewportW - 2 * kEdgePad);
    final availH = math.max(200.0, viewportH - 2 * kEdgePad);

    final perCellW = (availW - (cols - 1) * kGap) / cols;
    final perCellH = (availH - (rows - 1) * kGap) / rows;

    var diameter = math.min(perCellW, perCellH) - 2 * kChairPad;
    diameter = diameter.clamp(kMinDiameter, kMaxDiameter);

    final itemExtent = diameter + 2 * kChairPad;
    return _AutoLayout(
      cols: cols,
      rows: rows,
      diameter: diameter,
      itemExtent: itemExtent,
    );
  }

  List<Offset> _gridCenters({
    required double worldW,
    required double worldH,
    required int cols,
    required int rows,
    required double itemExtent,
  }) {
    if (cols == 0 || rows == 0) return const [];
    final totalW = cols * itemExtent + (cols - 1) * kGap;
    final totalH = rows * itemExtent + (rows - 1) * kGap;
    final startX = (worldW - totalW) / 2 + itemExtent / 2;
    final startY = (worldH - totalH) / 2 + itemExtent / 2;

    final centers = <Offset>[];
    for (int r = 0, i = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++, i++) {
        centers.add(Offset(
          startX + c * (itemExtent + kGap),
          startY + r * (itemExtent + kGap),
        ));
      }
    }
    return centers;
  }

  Widget _buildPlaced(PlacedTable t, double diameter,
      {required bool selected}) {
    final itemExtent = diameter + 2 * kChairPad;
    final left = t.center.dx - itemExtent / 2;
    final top = t.center.dy - itemExtent / 2;

    return Positioned(
      left: left,
      top: top,
      width: itemExtent,
      height: itemExtent,
      child: _DraggableRoundTable(
        id: t.id,
        label: t.label,
        status: t.status,
        seats: t.seats,
        diameter: diameter,
        selected: selected,
        onDrag: (deltaScreen) {
          final world = Offset(
              deltaScreen.dx / widget.scale, deltaScreen.dy / widget.scale);
          final snapped = Offset(
            _snap((t.center + world).dx, kDragSnap),
            _snap((t.center + world).dy, kDragSnap),
          );
          widget.onMoveTable(t.id, snapped);
        },
        onTap: () => widget.onTapTable(t.id),
        onTapSeat: (no) => widget.onTapSeat(t.id, no),
      ),
    );
  }

  double _snap(double v, double g) => (v / g).round() * g;
}

class _AutoLayout {
  final int cols, rows;
  final double diameter;
  final double itemExtent;
  _AutoLayout({
    required this.cols,
    required this.rows,
    required this.diameter,
    required this.itemExtent,
  });
}

/* ───────── Table + chairs (using Icons.chair) ───────── */

class _DraggableRoundTable extends StatelessWidget {
  final String id;
  final String label;
  final TableStatus status;
  final List<SeatModel> seats;
  final double diameter;
  final bool selected;
  final void Function(Offset deltaScreen) onDrag;
  final VoidCallback onTap;
  final void Function(int) onTapSeat;

  const _DraggableRoundTable({
    required this.id,
    required this.label,
    required this.status,
    required this.seats,
    required this.diameter,
    required this.selected,
    required this.onDrag,
    required this.onTap,
    required this.onTapSeat,
  });

  @override
  Widget build(BuildContext context) {
    final border = _statusColor(status);
    final itemExtent = diameter + 2 * kChairPad;
    final cx = itemExtent / 2, cy = itemExtent / 2, r = diameter / 2;

    // seat positions around the circle
    final chairs = _chairsAroundCircle(
      center: Offset(cx, cy),
      radius: r,
      count: seats.length,
      pad: kChairPad,
      takenFlags: seats.map((s) => s.status == SeatStatus.taken).toList(),
    );

    final taken = seats.where((s) => s.status == SeatStatus.taken).length;
    final total = seats.isEmpty ? 1 : seats.length;
    final pct = total == 0 ? 0.0 : taken / total;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      onPanUpdate: (d) => onDrag(d.delta),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Occupancy ring
          Positioned(
            left: cx - (r + 8),
            top: cy - (r + 8),
            child: SizedBox(
              width: diameter + 16,
              height: diameter + 16,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => CustomPaint(
                  painter: _OccupancyRing(v, border),
                ),
              ),
            ),
          ),

          // Table body
          Positioned(
            left: cx - r,
            top: cy - r,
            child: AnimatedScale(
              scale: selected ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Pro.bg2],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: border, width: 2),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x332563EB),
                            blurRadius: 16,
                            spreadRadius: 2,
                          )
                        ]
                      : Pro.shadowSm,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Pro.ink,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),

          // Chairs as Icons around the table
          for (final c in chairs)
            Positioned(
              left: c.center.dx - (kChairIconSize / 2),
              top: c.center.dy - (kChairIconSize / 2),
              child: Transform.rotate(
                angle: c.angleInward + math.pi / 2 + math.pi, // face inward
                child: MouseRegion(
                  cursor: c.taken
                      ? SystemMouseCursors.forbidden
                      : SystemMouseCursors.click,
                  child: InkWell(
                    onTap: c.taken ? null : () => onTapSeat(c.index + 1),
                    customBorder: const CircleBorder(),
                    child: Tooltip(
                      message:
                          'Chair ${c.index + 1} • ${c.taken ? "Taken" : "Free"}',
                      child: Icon(
                        Icons.chair,
                        size: kChairIconSize,
                        color: c.taken ? Pro.danger : Pro.success,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/* ───────── Occupancy ring painter ───────── */

class _OccupancyRing extends CustomPainter {
  final double pct; // 0..1
  final Color color;
  _OccupancyRing(this.pct, this.color);
  @override
  void paint(Canvas c, Size s) {
    final r = s.shortestSide / 2;
    final center = Offset(s.width / 2, s.height / 2);
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = const Color(0x1A000000);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6
      ..color = color;
    c.drawArc(Rect.fromCircle(center: center, radius: r), -math.pi / 2,
        math.pi * 2, false, bg);
    c.drawArc(Rect.fromCircle(center: center, radius: r), -math.pi / 2,
        (math.pi * 2) * pct, false, fg);
  }

  @override
  bool shouldRepaint(_OccupancyRing o) => o.pct != pct || o.color != color;
}

/* ───────── Mini-map painter ───────── */

class _MiniMapPainter extends CustomPainter {
  final List<Offset> centers;
  final Size worldSize;
  final Rect viewport;
  _MiniMapPainter(
      {required this.centers, required this.worldSize, required this.viewport});
  @override
  void paint(Canvas c, Size s) {
    final sx = s.width / worldSize.width, sy = s.height / worldSize.height;

    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(6)),
      Paint()..color = const Color(0xFFF5F7FD),
    );

    final dot = Paint()..color = Pro.ink.withOpacity(.55);
    for (final p in centers) {
      c.drawCircle(Offset(p.dx * sx, p.dy * sy), 2.5, dot);
    }

    final vp = Rect.fromLTWH(viewport.left * sx, viewport.top * sy,
        viewport.width * sx, viewport.height * sy);
    c.drawRect(
        vp,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Pro.primary);
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter old) => true;
}

/* ───────── Grid ───────── */

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFEFF2FA)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += kGrid) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += kGrid) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/* ───────── Seats geometry ───────── */

class _Chair {
  final int index;
  final bool taken;
  final Offset center;
  final double angleInward; // direction toward table center
  _Chair(this.index, this.taken, this.center, this.angleInward);
}

List<_Chair> _chairsAroundCircle({
  required Offset center,
  required double radius,
  required int count,
  required double pad,
  required List<bool> takenFlags,
}) {
  if (count <= 0) return const [];
  final list = <_Chair>[];

  // start at top, go clockwise
  final base = -math.pi / 2;
  final dist = radius + pad; // icon sits just outside the table edge

  for (var i = 0; i < count; i++) {
    final t = base + (2 * math.pi * i) / count; // center->chair angle
    final p =
        Offset(center.dx + dist * math.cos(t), center.dy + dist * math.sin(t));

    final inward = t + math.pi; // points toward table center
    final taken = (i < takenFlags.length) ? takenFlags[i] : false;

    list.add(_Chair(i, taken, p, inward));
  }
  return list;
}

/* ───────── Side panel (compact, redesigned) ───────── */

class _SidePanel extends StatelessWidget {
  final AreaModel area;
  final String floorName;
  final String? selectedTableId;
  final int? selectedSeatNo;
  final void Function(int seatNo) onSelectSeat;
  final void Function(int seatNo) onToggleSeatStatus; // long-press action
  final VoidCallback onConfirm;
  final VoidCallback onOpenKot;
  const _SidePanel({
    required this.area,
    required this.floorName,
    required this.selectedTableId,
    required this.selectedSeatNo,
    required this.onSelectSeat,
    required this.onToggleSeatStatus,
    required this.onConfirm,
    required this.onOpenKot,
  });

  @override
  Widget build(BuildContext context) {
    final table = selectedTableId == null
        ? null
        : area.tables.firstWhere(
            (t) => t.id == selectedTableId,
            orElse: () => area.tables.isNotEmpty
                ? area.tables.first
                : const PosTableModel(
                    id: '-',
                    label: '-',
                    round: true,
                    w: 0,
                    h: 0,
                    x: 0,
                    y: 0,
                    status: TableStatus.free,
                    seats: []),
          );

    final free = area.tables.where((t) => t.status == TableStatus.free).length;
    final occ =
        area.tables.where((t) => t.status == TableStatus.occupied).length;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Header with icon + status tag
        Row(
          children: [
            const Icon(Icons.table_bar, size: 18, color: Pro.ink),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                (table == null || table.id == '-')
                    ? 'Select a table'
                    : 'Table ${table.label}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Pro.ink,
                ),
              ),
            ),
            if (table != null && table.id != '-')
              _StatusTag(status: table.status),
          ],
        ),
        const SizedBox(height: 6),

        // Floor + quick stats row
        Row(
          children: [
            const Icon(Icons.apartment, size: 14, color: Pro.sub),
            const SizedBox(width: 4),
            Expanded(
              child: Text('Floor: $floorName',
                  style: const TextStyle(fontSize: 11, color: Pro.sub)),
            ),
            const Icon(Icons.event_seat, size: 14, color: Pro.sub),
            const SizedBox(width: 4),
            Text('Free: $free • Occ: $occ',
                style: const TextStyle(fontSize: 11, color: Pro.sub)),
          ],
        ),
        const SizedBox(height: 10),

        if (table != null && table.id != '-') ...[
          // Occupancy block with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: const [
                Icon(Icons.people_alt_outlined, size: 14, color: Pro.sub),
                SizedBox(width: 4),
                Text('Occupancy',
                    style: TextStyle(fontSize: 11, color: Pro.sub)),
              ]),
              _CapacityLabel(table: table),
            ],
          ),
          const SizedBox(height: 6),
          _OccupancyBar(table: table),
          const SizedBox(height: 12),

          // Chair selector chips (with icons) — long-press to toggle
          Row(children: const [
            Icon(Icons.chair_alt, size: 14, color: Pro.sub),
            SizedBox(width: 6),
            Text(
                'Choose a chair (tap to select, long-press to toggle taken/free)',
                style: TextStyle(fontSize: 11, color: Pro.sub)),
          ]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: table.seats.map((s) {
              final isTaken = s.status == SeatStatus.taken;

              final chip = ChoiceChip(
                avatar: Icon(
                  isTaken ? Icons.lock_outline : Icons.chair,
                  size: 14,
                  color: isTaken ? Pro.danger : Pro.ink,
                ),
                label: Text(
                  'Chair ${s.no}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isTaken ? Pro.danger : Pro.ink,
                    fontWeight: isTaken ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                selected: selectedSeatNo == s.no,
                onSelected: (_) {
                  // tap = select only if free
                  if (!isTaken) onSelectSeat(s.no);
                },
                selectedColor: Pro.primary.withOpacity(.10),
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isTaken
                        ? Pro.danger
                        : (selectedSeatNo == s.no ? Pro.primary : Pro.border),
                  ),
                ),
              );

              // wrap to capture long-press even when taken
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () => onToggleSeatStatus(s.no),
                child: chip,
              );
            }).toList(),
          ),
          const Spacer(),

          // Actions with icons
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: onConfirm,
                label: const Text('Select'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.receipt_long, size: 16),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              onPressed: onOpenKot,
              label: const Text('Open Job'),
            ),
          ]),
        ] else ...[
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.touch_app, size: 18, color: Pro.sub),
                  SizedBox(width: 8),
                  Text('Pick a table on the map…',
                      style: TextStyle(color: Pro.sub)),
                ],
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

// tiny capacity helper label with icon
class _CapacityLabel extends StatelessWidget {
  final PosTableModel table;
  const _CapacityLabel({required this.table});
  @override
  Widget build(BuildContext context) {
    final taken = table.seats.where((s) => s.status == SeatStatus.taken).length;
    final total = table.seats.isEmpty ? 1 : table.seats.length;
    return Row(children: [
      const Icon(Icons.event_seat, size: 14, color: Pro.sub),
      const SizedBox(width: 4),
      Text('$taken/$total',
          style: const TextStyle(fontSize: 11, color: Pro.sub)),
    ]);
  }
}

/* ───────── Occupancy bar ───────── */

class _OccupancyBar extends StatelessWidget {
  final PosTableModel table;
  const _OccupancyBar({required this.table});
  @override
  Widget build(BuildContext context) {
    final taken = table.seats.where((s) => s.status == SeatStatus.taken).length;
    final total = table.seats.isEmpty ? 1 : table.seats.length;
    final pct = ((taken / total) * 100).round();

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(999)),
      child: Container(
        height: 6,
        color: const Color(0xFFF1F2F6),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: pct / 100.0,
          child: Container(color: const Color(0xFF2563EB)),
        ),
      ),
    );
  }
}

/* ───────── Helpers ───────── */

Color _statusColor(TableStatus s) {
  switch (s) {
    case TableStatus.free:
      return Pro.success;
    case TableStatus.occupied:
      return Pro.danger;
    case TableStatus.reserved:
      return Pro.warn;
    case TableStatus.billRequested:
      return Pro.info;
  }
}

IconData _statusIcon(TableStatus s) {
  switch (s) {
    case TableStatus.free:
      return Icons.check_circle;
    case TableStatus.occupied:
      return Icons.block;
    case TableStatus.reserved:
      return Icons.event_available;
    case TableStatus.billRequested:
      return Icons.receipt_long;
  }
}

String _statusText(TableStatus s) {
  switch (s) {
    case TableStatus.free:
      return 'Free';
    case TableStatus.occupied:
      return 'Occupied';
    case TableStatus.reserved:
      return 'Reserved';
    case TableStatus.billRequested:
      return 'Bill';
  }
}

class _StatusTag extends StatelessWidget {
  final TableStatus status;
  const _StatusTag({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Pro.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            _statusText(status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// (unused now, safe to keep or remove)
class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: Pro.card(),
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Pro.sub)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: Pro.ink, fontSize: 13)),
        ]),
      ),
    );
  }
}

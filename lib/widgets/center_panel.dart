import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/providers.dart';
import 'package:my_app/entitlements/pos_features.dart';

import '../services/api_service.dart';

// Match app theme (top bar & footer)
class _CenterPanelColors {
  static const Color buttonFill = Color(0xFF6C7D8B); // slate blue-gray
  static const Color accentBorder =
      Color(0xFF521C1D); // same as top bar dialogs
  static const Color textDark = Color(0xFF222222); // dark gray/black
}

class CenterPanel extends ConsumerStatefulWidget {
  CenterPanel({Key? key}) : super(key: key);

  @override
  _CenterPanelState createState() => _CenterPanelState();
}

class _CenterPanelState extends ConsumerState<CenterPanel> {
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();

  String? expandedGroupId; // Track the currently expanded group ID
  List<dynamic> subGroups = []; // Store fetched subgroups
  List<dynamic> groups = []; // Cache the fetched groups
  bool _loadingGroups = true;
  String? _groupsError;

  @override
  void initState() {
    super.initState();
    fetchGroups(); // Fetch groups initially
  }

  Future<void> fetchGroups() async {
    setState(() {
      _loadingGroups = true;
      _groupsError = null;
    });
    try {
      final fetchedGroups = await _apiService.fetchGroups();
      if (!mounted) return;
      setState(() {
        groups = fetchedGroups;
        _loadingGroups = false;
        _groupsError = null;
      });
    } catch (e) {
      print('Error fetching groups: $e');
      if (!mounted) return;
      setState(() {
        groups = [];
        _loadingGroups = false;
        _groupsError = e.toString();
      });
    }
  }

  Future<void> fetchSubGroupsByGroupId(String groupId) async {
    try {
      final fetchedSubGroups =
          await _apiService.fetchSubGroups(groupId: groupId);
      if (!mounted) return;
      setState(() {
        subGroups = fetchedSubGroups;
      });
    } catch (e) {
      print('Error fetching subgroups: $e');
      if (!mounted) return;
      setState(() {
        subGroups = [];
      });
    }
  }

  Future<void> fetchProducts(String groupId, WidgetRef ref,
      {String? subGroupId}) async {
    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(errorProvider.notifier).state = null;
    try {
      final products = await _apiService.fetchProducts(
        groupId: groupId,
        subGroupId: subGroupId,
      );
      if (!mounted) return;
      ref.read(productProvider.notifier).state = products;
    } catch (e) {
      print('Error fetching products: $e');
      if (mounted) {
        ref.read(errorProvider.notifier).state = 'Failed to load products.';
        ref.read(productProvider.notifier).state = <dynamic>[];
      }
    } finally {
      if (mounted) ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  void toggleGroup(String groupId, WidgetRef ref) {
    setState(() {
      if (expandedGroupId == groupId) {
        expandedGroupId = null; // Collapse the group if already expanded
        subGroups = []; // Clear the subgroups
      } else {
        expandedGroupId = groupId; // Expand the new group
        fetchProducts(groupId, ref); // Fetch products for the group
        if (PosUiFeatures(ref).subgroupsPanel) {
          fetchSubGroupsByGroupId(
              groupId); // Fetch subgroups (full version only)
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final posUi = PosUiFeatures(ref);
    if (!posUi.groupsPanel) {
      return ColoredBox(
        color: Colors.grey.shade300,
        child: const SizedBox.shrink(),
      );
    }

    if (_loadingGroups) {
      return ColoredBox(
        color: Colors.grey.shade300,
        child: Center(
          child: CircularProgressIndicator(
            color: _CenterPanelColors.accentBorder,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_groupsError != null) {
      return ColoredBox(
        color: Colors.grey.shade300,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Could not load groups.\n$_groupsError',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _CenterPanelColors.textDark,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    if (groups.isEmpty) {
      return ColoredBox(
        color: Colors.grey.shade300,
        child: Center(
          child: Text(
            'No groups for this branch.',
            style: TextStyle(
              color: _CenterPanelColors.textDark.withOpacity(0.85),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: Colors.grey.shade300,
      child: Column(
        children: [
          Container(
            height: 3,
            width: double.infinity,
            color: _CenterPanelColors.accentBorder,
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              thickness: 4,
              radius: const Radius.circular(4),
              child: ColoredBox(
                color: Colors.grey.shade300,
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final groupId = group['GroupID'].toString();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _categoryButton(
                          group['GroupDescription'],
                          groupId,
                          ref,
                        ),
                        if (posUi.subgroupsPanel && expandedGroupId == groupId)
                          Column(
                            children: subGroups
                                .map((subgroup) => _subGroupButton(
                                      subgroup['SubGroupDescription'],
                                      groupId,
                                      subgroup['SubGroupID'],
                                      ref,
                                    ))
                                .toList(),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryButton(String label, String id, WidgetRef ref) {
    final isExpanded = expandedGroupId == id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(selectedGroupIdProvider.notifier).state = int.tryParse(id);
            toggleGroup(id, ref);
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: _CenterPanelColors.buttonFill,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _CenterPanelColors.accentBorder.withOpacity(0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      color: _CenterPanelColors.textDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: _CenterPanelColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _subGroupButton(
      String label, String groupId, String subGroupId, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 1, bottom: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            fetchProducts(groupId, ref, subGroupId: subGroupId);
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _CenterPanelColors.accentBorder.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.subdirectory_arrow_right,
                  size: 14,
                  color: _CenterPanelColors.textDark.withOpacity(0.8),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: _CenterPanelColors.textDark.withOpacity(0.95),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

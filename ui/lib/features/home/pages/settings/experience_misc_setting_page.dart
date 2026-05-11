import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:ui/core/router/go_router_manager.dart';
import 'package:ui/l10n/l10n.dart';
import 'package:ui/services/app_state_service.dart';
import 'package:ui/services/assists_core_service.dart';
import 'package:ui/services/storage_service.dart';
import 'package:ui/theme/theme_context.dart';
import 'package:ui/utils/cache_util.dart';
import 'package:ui/utils/ui.dart';
import 'package:ui/widgets/common_app_bar.dart';

class ExperienceMiscSettingPage extends StatefulWidget {
  const ExperienceMiscSettingPage({super.key});

  @override
  State<ExperienceMiscSettingPage> createState() =>
      _ExperienceMiscSettingPageState();
}

class _ExperienceMiscSettingPageState extends State<ExperienceMiscSettingPage> {
  static const String _sharedOpenModeDefault = 'default';
  static const String _sharedOpenModeWorkspace = 'workspace';

  bool _vibrationEnabled = true;
  bool _autoBackToChatAfterTaskEnabled = true;
  String _sharedOpenMode = _sharedOpenModeDefault;
  bool _sharedOpenModeLoaded = false;

  @override
  void initState() {
    super.initState();
    _autoBackToChatAfterTaskEnabled =
        StorageService.getBool(
          StorageService.kAutoBackToChatAfterTaskKey,
          defaultValue: true,
        ) ??
        true;
    _loadVibrationState();
    _loadAutoBackToChatAfterTaskState();
    _loadSharedOpenMode();
  }

  Future<void> _loadVibrationState() async {
    try {
      final enabled = await CacheUtil.getBool(
        'app_vibrate',
        defaultValue: true,
      );
      if (!mounted) return;
      setState(() {
        _vibrationEnabled = enabled;
      });
    } catch (e) {
      debugPrint('Error loading vibration state: $e');
    }
  }

  Future<void> _loadAutoBackToChatAfterTaskState() async {
    try {
      final enabled = await StorageService.isAutoBackToChatAfterTaskEnabled();
      if (!mounted) return;
      setState(() {
        _autoBackToChatAfterTaskEnabled = enabled;
      });
    } catch (e) {
      debugPrint('Error loading auto back to chat setting: $e');
    }
  }

  Future<void> _loadSharedOpenMode() async {
    final mode = await AppStateService.getSharedOpenMode();
    if (!mounted) return;
    setState(() {
      _sharedOpenMode = _normalizeSharedOpenMode(mode);
      _sharedOpenModeLoaded = true;
    });
  }

  Future<void> _onVibrationChanged(bool value) async {
    await CacheUtil.cacheBool('app_vibrate', value);
    if (!mounted) return;
    setState(() {
      _vibrationEnabled = value;
    });
  }

  Future<void> _onAutoBackToChatAfterTaskChanged(bool value) async {
    try {
      await StorageService.setAutoBackToChatAfterTaskEnabled(value);
      final synced =
          await AssistsMessageService.setAutoBackToChatAfterTaskEnabled(value);
      if (!synced) {
        throw Exception('native_sync_failed');
      }
      if (!mounted) return;
      setState(() {
        _autoBackToChatAfterTaskEnabled = value;
      });
      showToast(
        value
            ? context.l10n.settingsAutoBackEnabledToast
            : context.l10n.settingsAutoBackDisabledToast,
      );
    } catch (e) {
      if (!mounted) return;
      showToast(context.l10n.settingsSaveFailed, type: ToastType.error);
    }
  }

  Future<void> _onSharedOpenModeChanged(String? value) async {
    final nextMode = _normalizeSharedOpenMode(value);
    if (nextMode == _sharedOpenMode) return;
    final previousMode = _sharedOpenMode;
    setState(() {
      _sharedOpenMode = nextMode;
    });
    final saved = await AppStateService.setSharedOpenMode(nextMode);
    if (!mounted) return;
    final normalizedSaved = _normalizeSharedOpenMode(saved);
    setState(() {
      _sharedOpenMode = normalizedSaved;
    });
    if (normalizedSaved != nextMode) {
      setState(() {
        _sharedOpenMode = previousMode;
      });
      showToast(context.l10n.settingsSaveFailed, type: ToastType.error);
    }
  }

  String _normalizeSharedOpenMode(String? value) {
    return switch (value?.trim()) {
      _sharedOpenModeWorkspace => _sharedOpenModeWorkspace,
      _ => _sharedOpenModeDefault,
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.omniPalette;
    final sections = [
      _SettingSection(
        label: context.trLegacy('杂项'),
        items: [
          _SettingItem(
            icon: Icons.alarm_outlined,
            title: context.l10n.settingsAlarmTitle,
            subtitle: context.l10n.settingsAlarmSubtitle,
            onTap: () {
              GoRouterManager.push('/home/alarm_setting');
            },
          ),
          _SettingItem(
            icon: Icons.vibration,
            iconSvg: 'assets/home/vibration_icon.svg',
            title: context.l10n.settingsVibrationTitle,
            subtitle: context.l10n.settingsVibrationSubtitle,
            trailing: _buildSwitchTrailing(
              value: _vibrationEnabled,
              onToggle: _onVibrationChanged,
            ),
          ),
          _SettingItem(
            icon: Icons.chat_outlined,
            iconSvg: 'assets/home/auto_back_chat_setting_icon.svg',
            title: context.l10n.settingsAutoBackTitle,
            subtitle: context.l10n.settingsAutoBackSubtitle,
            trailing: _buildSwitchTrailing(
              value: _autoBackToChatAfterTaskEnabled,
              onToggle: _onAutoBackToChatAfterTaskChanged,
            ),
          ),
          _SettingItem(
            icon: Icons.drive_folder_upload_outlined,
            title: context.trLegacy('使用小万打开'),
            subtitle: _sharedOpenMode == _sharedOpenModeWorkspace
                ? context.trLegacy('复制到 workspace 并在提示词中发送文件路径')
                : context.trLegacy('图片填入对话，其他文件走文件传输'),
            trailing: _buildSharedOpenModeDropdown(),
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: CommonAppBar(title: context.trLegacy('杂项'), primary: true),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          itemCount: sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            return _buildSettingsSection(sections[index]);
          },
        ),
      ),
    );
  }

  Widget _buildSharedOpenModeDropdown() {
    final palette = context.omniPalette;
    if (!_sharedOpenModeLoaded) {
      return Padding(
        padding: const EdgeInsets.only(left: 12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: palette.accentPrimary,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sharedOpenMode,
          isDense: true,
          borderRadius: BorderRadius.circular(10),
          dropdownColor: palette.surfacePrimary,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: palette.textTertiary,
          ),
          items: [
            DropdownMenuItem(
              value: _sharedOpenModeDefault,
              child: Text(context.trLegacy('默认')),
            ),
            DropdownMenuItem(
              value: _sharedOpenModeWorkspace,
              child: Text('Workspace'),
            ),
          ],
          onChanged: _onSharedOpenModeChanged,
        ),
      ),
    );
  }

  Widget _buildSettingsSection(_SettingSection section) {
    final palette = context.omniPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Text(
                context.trLegacy(section.label),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  color: palette.textTertiary,
                  fontFamily: 'PingFang SC',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  color: palette.borderSubtle.withValues(
                    alpha: context.isDarkTheme ? 0.56 : 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: List.generate(section.items.length, (index) {
            final isLast = index == section.items.length - 1;
            return Column(
              children: [
                _buildSettingTile(section.items[index], isLast: isLast),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: palette.borderSubtle.withValues(
                        alpha: context.isDarkTheme ? 0.5 : 0.78,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSettingTile(_SettingItem item, {required bool isLast}) {
    final palette = context.omniPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: palette.accentPrimary.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.fromLTRB(4, 14, 2, isLast ? 14 : 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLeadingIcon(item),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.trLegacy(item.title),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: palette.textPrimary,
                        height: 1.5,
                        fontFamily: 'PingFang SC',
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        context.trLegacy(item.subtitle!),
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 11,
                          fontFamily: 'PingFang SC',
                          fontWeight: FontWeight.w400,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.trailing != null)
                item.trailing!
              else if (item.onTap != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: palette.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(_SettingItem item) {
    final palette = context.omniPalette;
    final iconColor = palette.textPrimary;
    return SizedBox(
      width: 18,
      height: 18,
      child: item.iconSvg != null
          ? SvgPicture.asset(
              item.iconSvg!,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            )
          : item.icon != null
          ? Icon(item.icon, size: 18, color: iconColor)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSwitchTrailing({
    required bool value,
    required ValueChanged<bool> onToggle,
  }) {
    final palette = context.omniPalette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onToggle(!value),
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: AbsorbPointer(
          child: FlutterSwitch(
            width: 32,
            height: 18.67,
            toggleSize: 11.3,
            padding: 3,
            activeColor: palette.accentPrimary,
            inactiveColor: palette.borderStrong,
            borderRadius: 28.75,
            value: value,
            onToggle: onToggle,
          ),
        ),
      ),
    );
  }
}

class _SettingSection {
  final String label;
  final List<_SettingItem> items;

  const _SettingSection({required this.label, required this.items});
}

class _SettingItem {
  final IconData? icon;
  final String? iconSvg;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingItem({
    this.icon,
    this.iconSvg,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}

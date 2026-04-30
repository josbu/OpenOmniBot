import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ui/constants/storage_keys.dart';
import 'package:ui/core/router/go_router_manager.dart';
import 'package:ui/features/welcome/state/onboarding_state.dart';
import 'package:ui/l10n/l10n.dart';
import 'package:ui/services/storage_service.dart';
import 'package:ui/theme/theme_context.dart';
import 'package:ui/widgets/common_app_bar.dart';
import 'package:ui/widgets/gradient_button.dart';

// ---------- SVG icons ----------

const String _kShieldSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>
  <path d="m9 12 2 2 4-4"/>
</svg>
''';

const String _kWifiOffSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 20h.01"/>
  <path d="M8.5 16.429a5 5 0 0 1 7 0"/>
  <path d="M5 12.859a10 10 0 0 1 5.17-2.69"/>
  <path d="M19 12.859a10 10 0 0 0-2.007-1.523"/>
  <line x1="2" x2="22" y1="2" y2="22"/>
</svg>
''';

const String _kZapSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 14a1 1 0 0 1-.78-1.63l9.9-10.2a.5.5 0 0 1 .86.46l-1.92 6.02A1 1 0 0 0 13 10h7a1 1 0 0 1 .78 1.63l-9.9 10.2a.5.5 0 0 1-.86-.46l1.92-6.02A1 1 0 0 0 11 14z"/>
</svg>
''';

const String _kAlertSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/>
  <path d="M12 9v4"/>
  <path d="M12 17h.01"/>
</svg>
''';

class LocalModelIntroPage extends StatefulWidget {
  const LocalModelIntroPage({super.key});

  @override
  State<LocalModelIntroPage> createState() => _LocalModelIntroPageState();
}

class _LocalModelIntroPageState extends State<LocalModelIntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Hero section animations
  late final Animation<double> _heroScale;
  late final Animation<double> _heroOpacity;
  late final Animation<double> _titleOffset;
  late final Animation<double> _titleOpacity;

  // Section header + feature card animations (staggered)
  late final List<Animation<double>> _itemOffsets;
  late final List<Animation<double>> _itemOpacities;

  // Button animation
  late final Animation<double> _buttonOpacity;
  late final Animation<double> _buttonOffset;

  // Total animated items: section1 header + 3 advantages + section2 header + 1 limitation = 6
  static const _itemCount = 6;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    // Hero icon: 0-400ms
    _heroScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.29, curve: Curves.elasticOut),
      ),
    );
    _heroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.14, curve: Curves.easeOut),
      ),
    );

    // Title: 100-500ms
    _titleOffset = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.07, 0.36, curve: Curves.easeOutCubic),
      ),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.07, 0.25, curve: Curves.easeOut),
      ),
    );

    // Staggered items: start at 250ms, each 80ms apart
    _itemOffsets = List.generate(_itemCount, (i) {
      final start = 0.18 + i * 0.057;
      final end = (start + 0.36).clamp(0.0, 1.0);
      return Tween<double>(begin: 28.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });
    _itemOpacities = List.generate(_itemCount, (i) {
      final start = 0.18 + i * 0.057;
      final end = (start + 0.21).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    // Button: last in the sequence
    _buttonOffset = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 0.9, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.omniPalette;
    final isDark = context.isDarkTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: CommonAppBar(
        title: context.trLegacy('本地模型'),
        primary: true,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero icon — scale + fade
                      Center(
                        child: Opacity(
                          opacity: _heroOpacity.value,
                          child: Transform.scale(
                            scale: _heroScale.value,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF7C4DFF),
                                    const Color(0xFFB388FF),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.memory_rounded,
                                size: 36,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title — slide + fade
                      Center(
                        child: Transform.translate(
                          offset: Offset(0, _titleOffset.value),
                          child: Opacity(
                            opacity: _titleOpacity.value,
                            child: Text(
                              context.trLegacy('在设备上运行本地 AI'),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                                height: 1.3,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Section: Advantages (item index 0 = header)
                      _buildAnimatedItem(
                        index: 0,
                        child: _SectionHeader(
                          text: context.trLegacy('优势'),
                          color: isDark
                              ? const Color(0xFF7BC67E)
                              : const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildAnimatedItem(
                        index: 1,
                        child: _FeatureCard(
                          svgIcon: _kShieldSvg,
                          title: context.trLegacy('隐私安全'),
                          description: context.trLegacy(
                            '数据完全留在设备上，不会发送到任何服务器',
                          ),
                          gradientColors: isDark
                              ? [const Color(0xFF66BB6A), const Color(0xFF43A047)]
                              : [const Color(0xFF4CAF50), const Color(0xFF81C784)],
                        ),
                      ),
                      const SizedBox(height: 10),

                      _buildAnimatedItem(
                        index: 2,
                        child: _FeatureCard(
                          svgIcon: _kWifiOffSvg,
                          title: context.trLegacy('离线可用'),
                          description: context.trLegacy(
                            '无需网络连接，随时随地使用 AI 助手',
                          ),
                          gradientColors: isDark
                              ? [const Color(0xFF42A5F5), const Color(0xFF1E88E5)]
                              : [const Color(0xFF2196F3), const Color(0xFF64B5F6)],
                        ),
                      ),
                      const SizedBox(height: 10),

                      _buildAnimatedItem(
                        index: 3,
                        child: _FeatureCard(
                          svgIcon: _kZapSvg,
                          title: context.trLegacy('完全免费'),
                          description: context.trLegacy(
                            '无需 API 费用或订阅，没有使用限制',
                          ),
                          gradientColors: isDark
                              ? [const Color(0xFFFFCA28), const Color(0xFFFFA000)]
                              : [const Color(0xFFFFC107), const Color(0xFFFFD54F)],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section: Limitations (item index 4 = header, 5 = card)
                      _buildAnimatedItem(
                        index: 4,
                        child: _SectionHeader(
                          text: context.trLegacy('局限性'),
                          color: isDark
                              ? const Color(0xFFE57373)
                              : const Color(0xFFEF5350),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildAnimatedItem(
                        index: 5,
                        child: _FeatureCard(
                          svgIcon: _kAlertSvg,
                          title: context.trLegacy('性能受限'),
                          description: context.trLegacy(
                            '端侧模型较小，能力有限，回复质量不如云端模型',
                          ),
                          gradientColors: isDark
                              ? [const Color(0xFFEF5350), const Color(0xFFE53935)]
                              : [const Color(0xFFEF5350), const Color(0xFFE57373)],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom button — slide up + fade
              Transform.translate(
                offset: Offset(0, _buttonOffset.value),
                child: Opacity(
                  opacity: _buttonOpacity.value,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: GradientButton(
                      width: screenWidth - 48,
                      height: 48,
                      text: context.trLegacy('浏览模型市场'),
                      onTap: () async {
                        await StorageService.setBool(
                          StorageKeys.welcomeCompleted,
                          true,
                        );
                        GoRouterManager.clearAndNavigateTo('/home/chat');
                        GoRouterManager.push(
                          '/home/local_models?tab=market&pinned=$kOnboardingRecommendedModelId',
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedItem({required int index, required Widget child}) {
    return Transform.translate(
      offset: Offset(0, _itemOffsets[index].value),
      child: Opacity(
        opacity: _itemOpacities[index].value,
        child: child,
      ),
    );
  }
}

// ---------- Private widgets ----------

class _SectionHeader extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionHeader({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final palette = context.omniPalette;

    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String svgIcon;
  final String title;
  final String description;
  final List<Color> gradientColors;

  const _FeatureCard({
    required this.svgIcon,
    required this.title,
    required this.description,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.omniPalette;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: palette.shadowColor,
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
            child: Center(
              child: SvgPicture.string(
                svgIcon,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

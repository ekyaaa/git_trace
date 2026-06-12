import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../core/constants.dart';
import '../core/theme_colors.dart';
import '../core/transitions.dart';

import '../providers/folder_provider.dart';
import '../providers/repositories_provider.dart';
import '../providers/selected_repos_provider.dart';
import '../providers/commits_provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/work_hours_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/repo_selector/repo_list_tile.dart';
import '../widgets/animations/fade_in.dart';
import '../widgets/animations/scale_on_hover.dart';
import 'calendar_screen.dart';
import 'export_screen.dart';

/// Navigation tab state
final selectedTabProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    Future.microtask(() {
      final calState = ref.read(calendarStateProvider);
      ref.read(workHoursProvider.notifier).loadMonth(calState.year, calState.month);
    });
  }

  Future<void> _pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Root Project',
    );
    if (result != null) {
      ref.read(folderProvider.notifier).setFolder(result);
      // Clear old selections
      ref.read(selectedReposProvider.notifier).deselectAll();
    }
  }

  void _loadCommits() {
    ref.read(commitsProvider.notifier).loadCommits();
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(selectedTabProvider);
    final folder = ref.watch(folderProvider);
    final colors = ThemeColors.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Left sidebar
          _buildSidebar(folder),

          // Vertical divider
          Container(
            width: 1,
            color: colors.surfaceBorder,
          ),

          // Main content
          Expanded(
            child: SmoothSwitcher(
              child: selectedTab == 0
                  ? const CalendarScreen(key: ValueKey('calendar'))
                  : const ExportScreen(key: ValueKey('export')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(String? folder) {
    final repos = ref.watch(repositoriesProvider);
    final selectedRepos = ref.watch(selectedReposProvider);
    final selectedTab = ref.watch(selectedTabProvider);
    final colors = ThemeColors.of(context);

    return Container(
      width: AppConstants.sidebarWidth,
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App header
          _buildAppHeader(),

          const Divider(height: 1),

          // Folder picker
          _buildFolderSection(folder),

          const Divider(height: 1),

          // Navigation tabs
          _buildNavTabs(selectedTab),

          const Divider(height: 1),

          // Repository list
          Expanded(
            child: _buildRepoList(repos, selectedRepos),
          ),

          // Action buttons
          if (selectedRepos.isNotEmpty) ...[
            const Divider(height: 1),
            _buildActionBar(selectedRepos),
          ],

          // Theme toggle
          const Divider(height: 1),
          _buildThemeToggle(),
        ],
      ),
    );
  }

  Widget _buildAppHeader() {
    final colors = ThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingXLarge, vertical: AppConstants.spacingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.surface,
            colors.background.withValues(alpha: 0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              boxShadow: colors.subtleShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      colors.accentGradient.createShader(bounds),
                  child: const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppConstants.appTagline,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderSection(String? folder) {
    final colors = ThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeIn(
            child: Text(
              'ROOT FOLDER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colors.textTertiary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FadeIn(
            delay: const Duration(milliseconds: 50),
            child: ScaleOnHoverBuilder(
              onTap: _pickFolder,
              builder: (context, isHovered, isPressed) {
                final borderColor = isHovered
                    ? (folder != null
                        ? colors.accentOrange.withValues(alpha: 0.6)
                        : colors.accentBlue.withValues(alpha: 0.6))
                    : colors.surfaceBorder;
                final bgColor = isPressed
                    ? colors.surfaceLight.withValues(alpha: 0.7)
                    : isHovered
                        ? colors.surfaceLight.withValues(alpha: 0.9)
                        : colors.surfaceLight;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    border: Border.all(color: borderColor),
                    boxShadow: isHovered
                        ? [
                            BoxShadow(
                              color: (folder != null
                                      ? colors.accentOrange
                                      : colors.accentBlue)
                                  .withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : colors.subtleShadow,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        folder != null ? Icons.folder_open : Icons.folder_outlined,
                        color: folder != null
                            ? colors.accentOrange
                            : colors.textTertiary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          folder ?? 'Pilih folder...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: folder != null ? FontWeight.w500 : FontWeight.w400,
                            color: folder != null
                                ? colors.textPrimary
                                : colors.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: colors.textTertiary,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTabs(int selectedTab) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMedium, vertical: AppConstants.spacingSmall),
      child: Row(
        children: [
          Expanded(
            child: _NavTab(
              icon: Icons.calendar_month,
              label: 'Kalender',
              isSelected: selectedTab == 0,
              onTap: () => ref.read(selectedTabProvider.notifier).state = 0,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NavTab(
              icon: Icons.file_download_outlined,
              label: 'Export',
              isSelected: selectedTab == 1,
              onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepoList(
    AsyncValue<List<dynamic>> repos,
    Set<String> selectedRepos,
  ) {
    final colors = ThemeColors.of(context);

    return repos.when(
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.accentBlue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Memindai repositori...',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: colors.accentRed, size: 32),
              const SizedBox(height: 8),
              Text(
                'Error: $error',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Coba Lagi'),
                onPressed: () => ref.read(repositoriesProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
      ),
      data: (repoList) {
        if (repoList.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.source_outlined,
                    color: colors.textTertiary.withValues(alpha: 0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada repository',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih folder yang berisi project Git',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with select all
            Padding(
              padding: const EdgeInsets.fromLTRB(AppConstants.spacingMedium, 8, AppConstants.spacingMedium, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'REPOSITORIES (${repoList.length})',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.textTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Row(
                    children: [
                      ScaleOnHover(
                        onTap: () {
                          ref.read(selectedReposProvider.notifier).selectAll(
                            repoList.map((r) => r.path as String).toList(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.accentBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          child: Text(
                            'Semua',
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.accentBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ScaleOnHover(
                        onTap: () {
                          ref.read(selectedReposProvider.notifier).deselectAll();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          child: Text(
                            'Kosongkan',
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Repo list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSmall, vertical: 4),
                itemCount: repoList.length,
                itemBuilder: (context, index) {
                  final repo = repoList[index];
                  return FadeIn(
                    delay: Duration(milliseconds: 30 * index),
                    slideOffset: const Offset(-12, 0),
                    child: RepoListTile(
                      repo: repo,
                      isSelected: selectedRepos.contains(repo.path),
                      colorIndex: index,
                      onToggle: () {
                        ref
                            .read(selectedReposProvider.notifier)
                            .toggle(repo.path);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionBar(Set<String> selectedRepos) {
    final colors = ThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMedium),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: colors.surfaceBorder.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            '${selectedRepos.length} repo dipilih',
            style: TextStyle(
              fontSize: 11,
              color: colors.textTertiary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadCommits,
              icon: const Icon(Icons.sync, size: 16),
              label: const Text('Muat Commit'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle() {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == AppThemeMode.dark;
    final colors = ThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMedium,
        vertical: AppConstants.spacingSmall,
      ),
      child: ScaleOnHoverBuilder(
        onTap: () {
          ref.read(themeModeProvider.notifier).toggleTheme();
        },
        builder: (context, isHovered, isPressed) {
          final bgColor = isPressed
              ? colors.surfaceLight.withValues(alpha: 0.7)
              : isHovered
                  ? colors.surfaceLight.withValues(alpha: 0.9)
                  : colors.surfaceLight;

          final borderColor = isHovered
              ? colors.accentBlue.withValues(alpha: 0.4)
              : colors.surfaceBorder;

          return AnimatedContainer(
            duration: AppConstants.animDurationFast,
            curve: AppCurves.easeOutExpo,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(color: borderColor),
              boxShadow: isHovered ? colors.glowShadowBlue : colors.subtleShadow,
            ),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: AppConstants.animDurationNormal,
                  transitionBuilder: (child, animation) {
                    return RotationTransition(
                      turns: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    key: ValueKey(isDark),
                    color: isDark ? colors.accentPurple : colors.accentOrange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDark ? 'Dark Mode' : 'Light Mode',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Klik untuk mengubah tema',
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.textTertiary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: AppConstants.animDurationFast,
                  width: 36,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isDark
                        ? colors.accentPurple.withValues(alpha: 0.3)
                        : colors.accentOrange.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? colors.accentPurple.withValues(alpha: 0.5)
                          : colors.accentOrange.withValues(alpha: 0.5),
                    ),
                  ),
                  child: AnimatedAlign(
                    duration: AppConstants.animDurationFast,
                    curve: AppCurves.easeOutExpo,
                    alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isDark ? colors.accentPurple : colors.accentOrange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? colors.accentPurple : colors.accentOrange)
                                .withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NavTab extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final colors = ThemeColors.of(context);

    final bgColor = isSelected
        ? colors.accentBlue.withValues(alpha: 0.12)
        : _isHovered
            ? colors.surfaceLight.withValues(alpha: 0.5)
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: AppConstants.animDurationFast,
          curve: AppCurves.easeOutExpo,
          child: AnimatedContainer(
            duration: AppConstants.animDurationFast,
            curve: AppCurves.easeOutExpo,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              border: isSelected
                  ? Border.all(color: colors.accentBlue.withValues(alpha: 0.4))
                  : _isHovered
                      ? Border.all(color: colors.surfaceBorder)
                      : Border.all(color: Colors.transparent),
              boxShadow: isSelected && _isHovered
                  ? colors.glowShadowBlue
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      size: 16,
                      color: isSelected
                          ? colors.accentBlue
                          : _isHovered
                              ? colors.textPrimary
                              : colors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? colors.accentBlue
                            : _isHovered
                                ? colors.textPrimary
                                : colors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    height: 2,
                    width: 24,
                    decoration: BoxDecoration(
                      color: colors.accentBlue,
                      borderRadius: BorderRadius.circular(1),
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

class HoverScaleButton extends StatefulWidget {
  final Widget Function(BuildContext context, bool isHovered, bool isPressed) builder;
  final VoidCallback onTap;
  final double scaleOnHover;
  final double scaleOnPress;

  const HoverScaleButton({
    super.key,
    required this.builder,
    required this.onTap,
    this.scaleOnHover = 1.02,
    this.scaleOnPress = 0.96,
  });

  @override
  State<HoverScaleButton> createState() => _HoverScaleButtonState();
}

class _HoverScaleButtonState extends State<HoverScaleButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    double scale = 1.0;
    if (_isPressed) {
      scale = widget.scaleOnPress;
    } else if (_isHovered) {
      scale = widget.scaleOnHover;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: widget.builder(context, _isHovered, _isPressed),
        ),
      ),
    );
  }
}

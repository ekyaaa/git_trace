import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/transitions.dart';

import '../providers/folder_provider.dart';
import '../providers/repositories_provider.dart';
import '../providers/selected_repos_provider.dart';
import '../providers/commits_provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/work_hours_provider.dart';
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

    return Scaffold(
      body: Row(
        children: [
          // Left sidebar
          _buildSidebar(folder),

          // Vertical divider
          Container(
            width: 1,
            color: AppColors.surfaceBorder,
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

    return Container(
      width: AppConstants.sidebarWidth,
      color: AppColors.surface,
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
        ],
      ),
    );
  }

  Widget _buildAppHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingXLarge, vertical: AppConstants.spacingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.background.withValues(alpha: 0.8),
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
              boxShadow: AppTheme.subtleShadow,
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
                      AppColors.accentGradient.createShader(bounds),
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
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
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
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeIn(
            child: const Text(
              'ROOT FOLDER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
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
                        ? AppColors.accentOrange.withValues(alpha: 0.6)
                        : AppColors.accentBlue.withValues(alpha: 0.6))
                    : AppColors.surfaceBorder;
                final bgColor = isPressed
                    ? AppColors.surfaceLight.withValues(alpha: 0.7)
                    : isHovered
                        ? AppColors.surfaceLight.withValues(alpha: 0.9)
                        : AppColors.surfaceLight;

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
                                      ? AppColors.accentOrange
                                      : AppColors.accentBlue)
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
                        : AppTheme.subtleShadow,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        folder != null ? Icons.folder_open : Icons.folder_outlined,
                        color: folder != null
                            ? AppColors.accentOrange
                            : AppColors.textTertiary,
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
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.textTertiary,
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
    return repos.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentBlue,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Memindai repositori...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
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
              const Icon(Icons.error_outline, color: AppColors.accentRed, size: 32),
              const SizedBox(height: 8),
              Text(
                'Error: $error',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
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
                    color: AppColors.textTertiary.withValues(alpha: 0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Belum ada repository',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pilih folder yang berisi project Git',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
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
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
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
                            color: AppColors.accentBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          child: const Text(
                            'Semua',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.accentBlue,
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
                          child: const Text(
                            'Kosongkan',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textTertiary,
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
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceBorder.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            '${selectedRepos.length} repo dipilih',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
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

    final bgColor = isSelected
        ? AppColors.accentBlue.withValues(alpha: 0.12)
        : _isHovered
            ? AppColors.surfaceLight.withValues(alpha: 0.5)
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
                  ? Border.all(color: AppColors.accentBlue.withValues(alpha: 0.4))
                  : _isHovered
                      ? Border.all(color: AppColors.surfaceBorder)
                      : Border.all(color: Colors.transparent),
              boxShadow: isSelected && _isHovered
                  ? AppTheme.glowShadowBlue
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
                          ? AppColors.accentBlue
                          : _isHovered
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.accentBlue
                            : _isHovered
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
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
                      color: AppColors.accentBlue,
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

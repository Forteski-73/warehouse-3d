import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../state/toast_controller.dart';
import '../state/warehouse_controller.dart';
import '../widgets/block_mode_bar.dart';
import '../widgets/detail_panel.dart';
import '../widgets/edit_legend_panel.dart';
import '../widgets/edit_mode_button.dart';
import '../widgets/hint_panel.dart';
import '../widgets/legend_panel.dart';
import '../widgets/toast_overlay.dart';
import '../widgets/top_bar.dart';
import '../widgets/warehouse_viewport.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key, required this.themeMode, required this.onToggleTheme});

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  late final ToastController _toasts;
  late final WarehouseController _controller;

  @override
  void initState() {
    super.initState();
    _toasts = ToastController();
    _controller = WarehouseController(toasts: _toasts)..loadInitial();
  }

  @override
  void dispose() {
    _controller.dispose();
    _toasts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: WarehouseViewport(controller: _controller)),

            // top bar
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: TopBar(controller: _controller, themeMode: widget.themeMode, onToggleTheme: widget.onToggleTheme),
            ),

            // toast
            Positioned(
              top: 78,
              left: 0,
              right: 0,
              child: Center(child: ToastOverlay(toasts: _toasts)),
            ),

            // legend / edit legend (top-right) — hidden entirely while
            // selecting/moving blocks, to keep focus on the 3D scene.
            Positioned(
              top: 78,
              right: 14,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  if (_controller.blockMode) return const SizedBox.shrink();
                  return _controller.editMode ? const EditLegendPanel() : LegendPanel(controller: _controller);
                },
              ),
            ),

            // detail panel (bottom-left)
            Positioned(
              left: 14,
              bottom: 84,
              child: DetailPanel(controller: _controller),
            ),

            // hint (bottom-right)
            Positioned(
              right: 14,
              bottom: 14,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) =>
                    HintPanel(editMode: _controller.editMode, blockMode: _controller.blockMode),
              ),
            ),

            // edit toggle + block-mode controls (bottom-center)
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BlockModeBar(controller: _controller),
                    const SizedBox(height: 10),
                    EditModeButton(controller: _controller),
                  ],
                ),
              ),
            ),

            // loading veil — kept permanently mounted and only faded via
            // opacity (never inserted/removed from the tree). On at least
            // one Android device (Lenovo tablet, MediaTek/ZUI), conditionally
            // unmounting a full-screen translucent layer + its own animated
            // CircularProgressIndicator left the entire screen's compositing
            // broken afterwards — nothing else painted again despite the
            // widget tree rebuilding correctly.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final isLoading = _controller.isLoading;
                  return IgnorePointer(
                    ignoring: !isLoading,
                    child: AnimatedOpacity(
                      opacity: isLoading ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Container(
                        color: palette.background.withValues(alpha: 0.85),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // TickerMode stops the spinner's internal
                              // animation once hidden, without unmounting it.
                              TickerMode(
                                enabled: isLoading,
                                child: CircularProgressIndicator(color: palette.accent),
                              ),
                              const SizedBox(height: 14),
                              Text('Carregando armazém…', style: TextStyle(color: palette.textDim, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

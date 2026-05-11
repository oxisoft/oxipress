import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../editor/data/editor_buffers_controller.dart';
import '../../editor/domain/frontmatter.dart';
import '../../project/domain/workspace_state.dart';
import '../../project/ui/project_controller.dart';
import '../../project/ui/workspace_state_controller.dart';
import '../data/hugo_providers.dart';
import '../domain/content_url_resolver.dart';
import '../domain/hugo_status.dart';
import '../domain/preview_url_computer.dart';


/// Preview pane: embeds a WKWebView pointing at the Hugo serve URL on macOS;
/// falls back to a "Open in browser" CTA on Linux/Windows until Phase 11
/// firms up cross-platform webview support.
class PreviewPanel extends ConsumerStatefulWidget {
  const PreviewPanel({super.key});

  @override
  ConsumerState<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends ConsumerState<PreviewPanel> {
  WebViewController? _controller;
  String _currentUrl = '';
  String? _lastNavigatedActivePath;

  bool get _isWebviewSupported => Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    if (_isWebviewSupported) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: _onNavigationRequest,
            onPageStarted: (url) {
              if (!mounted) return;
              setState(() => _currentUrl = url);
            },
            onPageFinished: (url) {
              if (!mounted) return;
              setState(() => _currentUrl = url);
              unawaited(_syncEditorToUrl(url));
            },
          ),
        );
    }
  }

  /// Block top-level navigations outside the Hugo serve and route them to
  /// the OS browser instead. Internal links (127.0.0.1 / localhost on the
  /// Hugo port) and same-page anchor changes are allowed.
  ///
  /// Sub-frame navigations (iframes — embedded YouTube videos, oEmbed
  /// widgets, etc.) bypass the external check entirely so their `src` URLs
  /// load normally inside the embed.
  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (!request.isMainFrame) return NavigationDecision.navigate;
    final status = ref.read(hugoControllerProvider);
    if (status is! HugoRunning) return NavigationDecision.navigate;
    final Uri uri;
    try {
      uri = Uri.parse(request.url);
    } on FormatException catch (_) {
      return NavigationDecision.navigate;
    }
    if (isInternalPreviewUrl(uri, baseUrl: status.baseUrl)) {
      return NavigationDecision.navigate;
    }
    unawaited(launchUrl(uri));
    return NavigationDecision.prevent;
  }

  /// Reverse-match the webview URL back to a content file and, if found,
  /// activate it in the editor. Tree highlight follows via the existing
  /// active-tab → tree-selection wiring.
  Future<void> _syncEditorToUrl(String url) async {
    final status = ref.read(hugoControllerProvider);
    if (status is! HugoRunning) return;
    final lifecycle = ref.read(projectControllerProvider);
    if (lifecycle is! OpenProject) return;

    final fileSystem = ref.read(fileSystemProvider);
    final matched = await ContentUrlResolver.matchContentFile(
      urlPath: url,
      fileSystem: fileSystem,
      projectPath: lifecycle.project.path,
    );
    if (matched == null) return;
    if (!mounted) return;

    final relative = p.relative(matched, from: lifecycle.project.path);
    final workspace = ref.read(workspaceStateProvider).value;
    if (workspace?.activeTabPath == relative) return;

    // Pre-claim _lastNavigatedActivePath so the editor → preview listener
    // doesn't re-issue a loadRequest for the URL we're already on.
    _lastNavigatedActivePath = relative;
    await ref.read(workspaceStateProvider.notifier).openTab(relative);
  }

  void _loadUrl(String url) {
    final c = _controller;
    if (c == null) return;
    c.loadRequest(Uri.parse(url));
    setState(() => _currentUrl = url);
  }

  void _maybeNavigateForActiveTab(HugoRunning status) {
    final workspaceAsync = ref.read(workspaceStateProvider);
    final workspace = workspaceAsync.value;
    final lifecycle = ref.read(projectControllerProvider);
    if (workspace == null || lifecycle is! OpenProject) return;
    final relative = workspace.activeTabPath;
    if (relative == null) return;
    if (relative == _lastNavigatedActivePath) return;
    _lastNavigatedActivePath = relative;

    final absolutePath = p.join(lifecycle.project.path, relative);
    final buffer = ref.read(editorBuffersProvider)[absolutePath];
    final fm = buffer == null ? null : _entriesToMap(buffer.currentEntries);

    final urlPath = PreviewUrlComputer.pathForContentFile(
      relativeFromProject: relative,
      frontmatter: fm,
    );
    _loadUrl('${status.baseUrl}$urlPath');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = ref.watch(hugoControllerProvider);

    // Auto-navigate to the active tab's URL when Hugo transitions to
    // running, or when the active tab changes while running.
    ref.listen<HugoStatus>(hugoControllerProvider, (prev, next) {
      if (next is HugoRunning) {
        if (prev is! HugoRunning) {
          _lastNavigatedActivePath = null;
          _loadUrl(next.baseUrl);
        }
        _maybeNavigateForActiveTab(next);
      } else {
        _lastNavigatedActivePath = null;
      }
    });
    ref.listen<WorkspaceState?>(
      workspaceStateProvider
          .select((async) => async.whenOrNull(data: (s) => s)),
      (prev, next) {
        final s = ref.read(hugoControllerProvider);
        if (s is HugoRunning) _maybeNavigateForActiveTab(s);
      },
    );

    return Column(
      children: [
        _PreviewToolbar(
          status: status,
          currentUrl: _currentUrl,
          controller: _controller,
          onLoad: _loadUrl,
        ),
        Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        Expanded(
          child: switch (status) {
            HugoStopped() =>
              _Placeholder(text: l10n.previewHugoNotRunning),
            HugoStarting() => _Placeholder(
                text: l10n.previewWaitingForHugo,
                showProgress: true,
              ),
            HugoErrored(:final message) =>
              _Placeholder(text: '${l10n.previewHugoError}\n$message'),
            HugoRunning() when _isWebviewSupported && _controller != null =>
              WebViewWidget(controller: _controller!),
            HugoRunning(:final port) =>
              _OpenInBrowserFallback(baseUrl: 'http://127.0.0.1:$port'),
          },
        ),
      ],
    );
  }
}

Map<String, Object?> _entriesToMap(List<FrontmatterEntry> entries) {
  final map = <String, Object?>{};
  for (final entry in entries) {
    map[entry.key] = entry.value;
  }
  return map;
}

class _PreviewToolbar extends StatefulWidget {
  const _PreviewToolbar({
    required this.status,
    required this.currentUrl,
    required this.controller,
    required this.onLoad,
  });

  final HugoStatus status;
  final String currentUrl;
  final WebViewController? controller;
  final ValueChanged<String> onLoad;

  @override
  State<_PreviewToolbar> createState() => _PreviewToolbarState();
}

class _PreviewToolbarState extends State<_PreviewToolbar> {
  final TextEditingController _pathField = TextEditingController();
  bool _editing = false;

  String? get _baseUrl {
    final s = widget.status;
    if (s is HugoRunning) return s.baseUrl;
    return null;
  }

  /// Extract the path (+ query + fragment) from a full URL. Returns `/` for
  /// anything we can't parse cleanly so the field never goes blank.
  String _pathFromUrl(String fullUrl) {
    if (fullUrl.isEmpty) return '/';
    try {
      final uri = Uri.parse(fullUrl);
      if (!uri.hasScheme) {
        // Already path-like input.
        return fullUrl.startsWith('/') ? fullUrl : '/$fullUrl';
      }
      final buffer = StringBuffer(uri.path.isEmpty ? '/' : uri.path);
      if (uri.hasQuery) {
        buffer.write('?');
        buffer.write(uri.query);
      }
      if (uri.hasFragment) {
        buffer.write('#');
        buffer.write(uri.fragment);
      }
      return buffer.toString();
    } on FormatException catch (_) {
      return '/';
    }
  }

  /// Coerce user input into a `/path?...#...` form so the host can never be
  /// rewritten through the address bar.
  String _coerceInputToPath(String input) {
    if (input.isEmpty) return '/';
    try {
      final uri = Uri.parse(input);
      if (uri.hasScheme) {
        final buffer = StringBuffer(uri.path.isEmpty ? '/' : uri.path);
        if (uri.hasQuery) {
          buffer.write('?');
          buffer.write(uri.query);
        }
        if (uri.hasFragment) {
          buffer.write('#');
          buffer.write(uri.fragment);
        }
        return buffer.toString();
      }
    } on FormatException catch (_) {
      // fall through
    }
    return input.startsWith('/') ? input : '/$input';
  }

  @override
  void didUpdateWidget(_PreviewToolbar old) {
    super.didUpdateWidget(old);
    if (!_editing && widget.currentUrl != old.currentUrl) {
      final next = _pathFromUrl(widget.currentUrl);
      if (next != _pathField.text) _pathField.text = next;
    }
  }

  @override
  void initState() {
    super.initState();
    _pathField.text = _pathFromUrl(widget.currentUrl);
  }

  @override
  void dispose() {
    _pathField.dispose();
    super.dispose();
  }

  void _submit(String input) {
    final base = _baseUrl;
    if (base == null) return;
    final path = _coerceInputToPath(input);
    _pathField.text = path;
    widget.onLoad('$base$path');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final enabled = widget.status is HugoRunning;
    final controller = widget.controller;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 18),
            tooltip: l10n.previewActionBack,
            visualDensity: VisualDensity.compact,
            onPressed: enabled && controller != null
                ? () => unawaited(controller.goBack())
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, size: 18),
            tooltip: l10n.previewActionForward,
            visualDensity: VisualDensity.compact,
            onPressed: enabled && controller != null
                ? () => unawaited(controller.goForward())
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: l10n.previewActionReload,
            visualDensity: VisualDensity.compact,
            onPressed: enabled && controller != null
                ? () => unawaited(controller.reload())
                : null,
          ),
          Expanded(
            child: Focus(
              onFocusChange: (focused) {
                setState(() {
                  _editing = focused;
                  if (!focused) {
                    _pathField.text = _pathFromUrl(widget.currentUrl);
                  }
                });
              },
              child: TextField(
                controller: _pathField,
                enabled: enabled,
                decoration: InputDecoration(
                  hintText: l10n.previewAddressBar,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  border: const OutlineInputBorder(),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
                onSubmitted: _submit,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 18),
            tooltip: l10n.previewActionOpenInBrowser,
            visualDensity: VisualDensity.compact,
            onPressed: enabled
                ? () => unawaited(
                      launchUrl(Uri.parse(widget.currentUrl.isNotEmpty
                          ? widget.currentUrl
                          : (widget.status as HugoRunning).baseUrl)),
                    )
                : null,
          ),
        ],
      ),
    );
  }
}

/// Read-only base-URL chip for the preview panel header (the panel chrome
/// actions slot). Shows the Hugo serve origin when running, blank otherwise.
class PreviewBaseUrlChip extends ConsumerWidget {
  const PreviewBaseUrlChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(hugoControllerProvider);
    if (status is! HugoRunning) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: SelectableText(
          status.baseUrl,
          style: theme.textTheme.labelSmall?.copyWith(
            fontFamily: 'monospace',
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.text, this.showProgress = false});

  final String text;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenInBrowserFallback extends StatelessWidget {
  const _OpenInBrowserFallback({required this.baseUrl});

  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.previewWebviewUnavailable,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(l10n.previewActionOpenInBrowser),
              onPressed: () =>
                  unawaited(launchUrl(Uri.parse(baseUrl))),
            ),
            const SizedBox(height: 8),
            SelectableText(
              baseUrl,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

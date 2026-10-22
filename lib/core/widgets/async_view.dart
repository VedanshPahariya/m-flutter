import 'dart:async';

import 'package:flutter/material.dart';

import 'state_views.dart';

/// Loads a value once and renders loading, error, empty and data states.
///
/// * The skeleton appears only if loading takes longer than [skeletonDelay],
///   so fast responses do not flash a placeholder.
/// * Pull-to-refresh keeps the current data visible; a failed refresh shows
///   [InlineErrorBanner] instead of replacing the content.
/// * Results that arrive after the widget is disposed are ignored.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.skeleton = const SizedBox.shrink(),
    this.isEmpty,
    this.empty,
    this.what,
    this.skeletonDelay = const Duration(milliseconds: 180),
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final Widget skeleton;
  final bool Function(T data)? isEmpty;
  final WidgetBuilder? empty;
  final String? what;
  final Duration skeletonDelay;

  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> {
  T? _data;
  bool _hasData = false;
  Object? _error;
  bool _loading = false;
  bool _showSkeleton = false;
  Timer? _skeletonTimer;
  int _generation = 0;

  T? get data => _data;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    _skeletonTimer?.cancel();
    super.dispose();
  }

  /// Reloads and completes when done. Safe to call repeatedly; only the
  /// newest request updates the UI.
  Future<void> reload() async {
    final generation = ++_generation;
    setStateIfMounted(() {
      _loading = true;
      if (!_hasData) _error = null;
    });
    _skeletonTimer?.cancel();
    if (!_hasData) {
      _skeletonTimer = Timer(widget.skeletonDelay, () {
        if (_loading) setStateIfMounted(() => _showSkeleton = true);
      });
    }
    try {
      final value = await widget.load();
      if (!mounted || generation != _generation) return;
      setState(() {
        _data = value;
        _hasData = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = e);
    } finally {
      if (mounted && generation == _generation) {
        _skeletonTimer?.cancel();
        setState(() {
          _loading = false;
          _showSkeleton = false;
        });
      }
    }
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasData) {
      if (_error != null && !_loading) {
        return RefreshIndicator(
          onRefresh: reload,
          child: ErrorView(error: _error!, onRetry: reload, what: widget.what),
        );
      }
      return _showSkeleton ? widget.skeleton : const SizedBox.expand();
    }
    final data = _data as T;
    final Widget content;
    if (widget.isEmpty?.call(data) ?? false) {
      content =
          widget.empty?.call(context) ??
          const EmptyView(title: 'Nothing here yet');
    } else {
      content = widget.builder(context, data);
    }
    return Column(
      children: [
        if (_error != null) InlineErrorBanner(error: _error!, onRetry: reload),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(onRefresh: reload, child: content),
        ),
      ],
    );
  }
}

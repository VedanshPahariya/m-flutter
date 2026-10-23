import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../api/api_exceptions.dart';
import 'skeleton.dart';
import 'state_views.dart';

/// One page from a list endpoint.
class PageResult<T> {
  const PageResult({required this.items, required this.total});

  final List<T> items;

  /// Total matching records reported by the server, or -1 when unknown.
  final int total;
}

typedef PageFetcher<T> = Future<PageResult<T>> Function(int offset);

/// Infinite list over offset-paginated endpoints (`limit`/`offset` or
/// `page`). Loads the next page near the end of the list, keeps loaded rows
/// when a later page fails, and supports pull-to-refresh.
class PagedListView<T> extends StatefulWidget {
  const PagedListView({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    this.empty,
    this.what,
    this.header,
    this.separated = true,
    this.padding = const EdgeInsets.only(bottom: 24),
  });

  final PageFetcher<T> fetch;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final WidgetBuilder? empty;
  final String? what;

  /// Optional widget above the first row (summary text, banners).
  final Widget Function(BuildContext context, int total)? header;
  final bool separated;
  final EdgeInsets padding;

  @override
  State<PagedListView<T>> createState() => PagedListViewState<T>();
}

class PagedListViewState<T> extends State<PagedListView<T>> {
  final List<T> _items = [];
  int _total = -1;
  bool _loading = false;
  bool _initialDone = false;
  bool _showSkeleton = false;
  bool _reachedEnd = false;
  Object? _error;
  int _generation = 0;
  Timer? _skeletonTimer;

  List<T> get items => List.unmodifiable(_items);

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    _skeletonTimer?.cancel();
    super.dispose();
  }

  /// Reloads from the first page. Keeps showing old rows until it finishes.
  Future<void> refresh() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    if (!_initialDone) {
      _skeletonTimer = Timer(const Duration(milliseconds: 180), () {
        if (mounted && _loading && !_initialDone) {
          setState(() => _showSkeleton = true);
        }
      });
    }
    try {
      final page = await widget.fetch(0);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _total = page.total;
        _reachedEnd = _isEnd(page);
        _initialDone = true;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = e);
    } finally {
      _skeletonTimer?.cancel();
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _showSkeleton = false;
        });
      }
    }
  }

  /// Removes a row locally after a successful delete.
  void removeWhere(bool Function(T) test) {
    setState(() {
      final before = _items.length;
      _items.removeWhere(test);
      if (_total > 0) _total -= before - _items.length;
    });
  }

  bool _isEnd(PageResult<T> page) =>
      page.items.isEmpty || (_total >= 0 && _items.length >= _total);

  Future<void> _loadMore() async {
    if (_loading || _reachedEnd || _error != null) return;
    final generation = _generation;
    setState(() => _loading = true);
    try {
      final page = await widget.fetch(_items.length);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items.addAll(page.items);
        if (page.total >= 0) _total = page.total;
        _reachedEnd = _isEnd(page);
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = e);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  void _retryMore() {
    setState(() => _error = null);
    _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialDone) {
      if (_error != null) {
        return RefreshIndicator(
          onRefresh: refresh,
          child: ErrorView(error: _error!, onRetry: refresh, what: widget.what),
        );
      }
      return _showSkeleton ? const SkeletonList() : const SizedBox.expand();
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: _error != null
            ? ErrorView(error: _error!, onRetry: refresh, what: widget.what)
            : (widget.empty?.call(context) ??
                  const EmptyView(title: 'Nothing here yet')),
      );
    }
    final hasHeader = widget.header != null;
    final footerCount = 1;
    final count = _items.length + (hasHeader ? 1 : 0) + footerCount;
    return RefreshIndicator(
      onRefresh: refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 400) _loadMore();
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: widget.padding,
          itemCount: count,
          itemBuilder: (context, index) {
            if (hasHeader && index == 0) {
              return widget.header!(context, _total);
            }
            final i = index - (hasHeader ? 1 : 0);
            if (i == _items.length) return _footer(context);
            final row = widget.itemBuilder(context, _items[i], i);
            if (!widget.separated || i == _items.length - 1) return row;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [row, const Divider(indent: 16, endIndent: 16)],
            );
          },
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final k = context.kora;
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: k.danger, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                describeError(_error!),
                style: TextStyle(color: k.ink3, fontSize: 13),
              ),
            ),
            TextButton(onPressed: _retryMore, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (!_reachedEnd) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              _total > 0
                  ? 'Loading more · ${_items.length} of $_total'
                  : 'Loading more…',
              style: TextStyle(color: k.ink3, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Center(
        child: Text(
          _items.length == 1 ? '1 record' : '${_items.length} records',
          style: TextStyle(color: k.mute, fontSize: 12),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/widgets/supermarkets_grid_view.dart';
import 'package:app_code/providers/real_app_providers/navigation_provider.dart';

/// A reusable widget that displays a list of supermarkets with built-in 
/// search and deletion modes.
class SearchableSupermarketsView extends ConsumerStatefulWidget {
  final List<Supermarket> supermarkets;
  final String emptyMessage;
  final void Function(BuildContext, Supermarket)? onSupermarketTap;
  final Widget? floatingActionButton;
  final void Function(bool)? onDeletionModeChanged;

  const SearchableSupermarketsView({
    super.key,
    required this.supermarkets,
    required this.emptyMessage,
    this.onSupermarketTap,
    this.floatingActionButton,
    this.onDeletionModeChanged,
  });

  @override
  ConsumerState<SearchableSupermarketsView> createState() =>
      _SearchableSupermarketsViewState();
}

class _SearchableSupermarketsViewState
    extends ConsumerState<SearchableSupermarketsView> {
  bool _isSearching = false;
  bool _isDeletionMode = false;
  final TextEditingController _searchController = TextEditingController();
  List<Supermarket> _filteredSupermarkets = [];

  @override
  void initState() {
    super.initState();
    _filteredSupermarkets = widget.supermarkets;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(SearchableSupermarketsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.supermarkets != widget.supermarkets) {
      _filterSupermarkets(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => _filterSupermarkets(_searchController.text);

  void _filterSupermarkets(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSupermarkets = widget.supermarkets;
      } else {
        _filteredSupermarkets = widget.supermarkets
            .where((supermarket) =>
                supermarket.getName().toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _startSearch() {
    setState(() => _isSearching = true);
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _filteredSupermarkets = widget.supermarkets;
    });
  }

  void _setDeletionMode(bool isDeletionMode) {
    setState(() {
      _isDeletionMode = isDeletionMode;
      if (isDeletionMode && _isSearching) _stopSearch();
    });
    widget.onDeletionModeChanged?.call(isDeletionMode);
  }

  void _resetState() {
    final shouldResetDeletion = _isDeletionMode;
    final shouldResetSearch = _isSearching || _searchController.text.isNotEmpty;

    if (!shouldResetDeletion && !shouldResetSearch) return;

    // Close deletion mode and search bar explicitly
    if (shouldResetDeletion) {
      _setDeletionMode(false);
    }
    if (shouldResetSearch) {
      _stopSearch();
    }

    // Ensure supermarkets are restored when neither search nor deletion is active
    if (!_isDeletionMode && !_isSearching) {
      setState(() {
        _filteredSupermarkets = widget.supermarkets;
      });
    }
  }

  PreferredSizeWidget _buildSearchAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colorScheme.onSurfaceVariant),
        onPressed: _stopSearch,
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.searchSupermarketsHint,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          border: InputBorder.none,
        ),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
            onPressed: () => _searchController.clear(),
          ),
      ],
    );
  }

  PreferredSizeWidget _buildNormalAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      title: Text(l10n.supermarketsTitle),
      backgroundColor: colorScheme.surface,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: colorScheme.onSurface),
          onPressed: _startSearch,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Listen to global navigation signals to reset local UI state
    ref.listen(appNavigationSignalProvider, (previous, next) {
      if (previous != next) {
        _resetState();
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _isDeletionMode
          ? null
          : (_isSearching
              ? _buildSearchAppBar(context)
              : _buildNormalAppBar(context)),
      body: GestureDetector(
        onTap: _isSearching ? _stopSearch : null,
        child: SupermarketsGridView(
          supermarkets: _filteredSupermarkets,
          emptyMessage: _searchController.text.isNotEmpty
              ? l10n.noSupermarketsFoundMatching(_searchController.text)
              : widget.emptyMessage,
          onDeletionModeChanged: _setDeletionMode,
          onSupermarketTap: widget.onSupermarketTap,
          floatingActionButton: widget.floatingActionButton != null
              ? GestureDetector(
                  onTap: () {
                    if (_isSearching) _stopSearch();
                  },
                  child: widget.floatingActionButton,
                )
              : null,
        ),
      ),
    );
  }
}

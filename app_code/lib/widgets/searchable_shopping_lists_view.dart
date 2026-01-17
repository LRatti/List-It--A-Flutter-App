import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/widgets/shopping_lists_grid_view.dart';

class SearchableShoppingListsView extends ConsumerStatefulWidget {
  final List<ShoppingList> lists;
  final String emptyMessage;
  final void Function(BuildContext, ShoppingList)? onListTap;
  final Widget? floatingActionButton;
  final bool showRegistered;

  const SearchableShoppingListsView({
    super.key,
    required this.lists,
    required this.emptyMessage,
    this.onListTap,
    this.floatingActionButton,
    this.showRegistered = false,
  });

  @override
  ConsumerState<SearchableShoppingListsView> createState() =>
      _SearchableShoppingListsViewState();
}

class _SearchableShoppingListsViewState
    extends ConsumerState<SearchableShoppingListsView> {
  bool _isSearching = false;
  bool _isDeletionMode = false;
  final TextEditingController _searchController = TextEditingController();
  List<ShoppingList> _filteredLists = [];

  @override
  void initState() {
    super.initState();
    _filteredLists = widget.lists;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(SearchableShoppingListsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lists != widget.lists) {
      _filterLists(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => _filterLists(_searchController.text);

  void _filterLists(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLists = widget.lists;
      } else {
        _filteredLists = widget.lists
            .where((list) =>
                list.getName().toLowerCase().contains(query.toLowerCase()))
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
      _filteredLists = widget.lists;
    });
  }

  void _setDeletionMode(bool isDeletionMode) {
    setState(() {
      _isDeletionMode = isDeletionMode;
      if (isDeletionMode && _isSearching) _stopSearch();
    });
  }

  PreferredSizeWidget _buildSearchAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          hintText: 'Search lists...',
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          border: InputBorder.none,
        ),
        style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
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

    return AppBar(
      backgroundColor: colorScheme.surface, // match background
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _isDeletionMode
          ? null
          : (_isSearching
              ? _buildSearchAppBar(context)
              : _buildNormalAppBar(context)),
      body: GestureDetector(
        onTap: _isSearching ? _stopSearch : null,
        child: ShoppingListsGridView(
          lists: _filteredLists,
          emptyMessage: _searchController.text.isNotEmpty
              ? 'No lists found matching "${_searchController.text}"'
              : widget.emptyMessage,
          onListTap: (context, list) {
            if (_isSearching) _stopSearch();
            widget.onListTap?.call(context, list);
          },
          onDeletionModeChanged: _setDeletionMode,
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

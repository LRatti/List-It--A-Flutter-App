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

  void _onSearchChanged() {
    _filterLists(_searchController.text);
  }

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
    setState(() {
      _isSearching = true;
    });
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
      if (isDeletionMode && _isSearching) {
        _stopSearch();
      }
    });
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _stopSearch,
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search lists...',
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
            },
          ),
      ],
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      title: Text(widget.showRegistered ? 'History' : 'Lists'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _startSearch,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isDeletionMode ? null : (_isSearching ? _buildSearchAppBar() : _buildNormalAppBar()),
      body: GestureDetector(
        onTap: _isSearching ? _stopSearch : null,
        child: ShoppingListsGridView(
          lists: _filteredLists,
          emptyMessage: _searchController.text.isNotEmpty
              ? 'No lists found matching "${_searchController.text}"'
              : widget.emptyMessage,
          onListTap: (context, list) {
            if (_isSearching) {
              _stopSearch();
            }
            widget.onListTap?.call(context, list);
          },
          onDeletionModeChanged: _setDeletionMode,
          floatingActionButton: widget.floatingActionButton != null
              ? GestureDetector(
                  onTap: () {
                    if (_isSearching) {
                      _stopSearch();
                    }
                  },
                  child: widget.floatingActionButton,
                )
              : null,
        ),
      ),
    );
  }
}

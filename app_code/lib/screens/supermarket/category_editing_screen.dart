import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/providers/real_app_providers/category/categories_notifier.dart';
import 'package:app_code/widgets/app_snackbar.dart';
import 'package:app_code/utils/uncategorized_category_utils.dart';
import 'package:app_code/utils/category_localizer.dart';
import 'package:app_code/l10n/app_localizations.dart';

/// A screen for creating or editing a category in the supermarket section.
class CategoryEditingScreen extends ConsumerStatefulWidget {
  final Category? categoryToEdit;
  final Function(Category)? onCategoryCreated;

  const CategoryEditingScreen({
    super.key,
    this.categoryToEdit,
    this.onCategoryCreated,
  });

  @override
  ConsumerState<CategoryEditingScreen> createState() =>
      _CategoryEditingScreenState();
}

class _CategoryEditingScreenState extends ConsumerState<CategoryEditingScreen> {
  late TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with empty text; will be set in didChangeDependencies
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set the localized name after context is available
    if (widget.categoryToEdit != null) {
      final localizedName = CategoryLocalizer.localize(
        context,
        widget.categoryToEdit!.getName(),
      );
      _nameController.text = localizedName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Save the category (create or update)
  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildAppSnackBar(
          message: l10n.categoryNameEmpty,
          isError: true,
          context: context,
        ),
      );
      return;
    }

    if (name.trim().toLowerCase() == UncategorizedCategoryUtils.name) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildAppSnackBar(
          message: l10n.uncategorizedNameReserved,
          isError: true,
          context: context,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.categoryToEdit != null) {
        // Update existing category
        widget.categoryToEdit!.setName(name);
        await ref.read(categoriesProvider.notifier).updateCategory(
          widget.categoryToEdit!,
        );
        
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        // Create new category
        final newCategory = Category(
          name: name,
          isVisible: true,
        );

        await ref.read(categoriesProvider.notifier).addCategory(newCategory);

        if (mounted) {

          // Call the callback if provided
          widget.onCategoryCreated?.call(newCategory);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          buildAppSnackBar(
            message: l10n.errorSavingCategory(e.toString()),
            isError: true,
            context: context,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.categoryToEdit != null;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? l10n.editCategoryTitle : l10n.createCategoryTitle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name input field
            TextField(
              controller: _nameController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: l10n.categoryNameLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.label),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveCategory(),
            ),
            
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        l10n.saveLabel,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

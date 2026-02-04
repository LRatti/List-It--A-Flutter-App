// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_list_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// AsyncNotifier to manage the currently selected shopping list across screens

@ProviderFor(SelectedListNotifier)
const selectedListProvider = SelectedListNotifierProvider._();

/// AsyncNotifier to manage the currently selected shopping list across screens
final class SelectedListNotifierProvider
    extends $AsyncNotifierProvider<SelectedListNotifier, ShoppingList?> {
  /// AsyncNotifier to manage the currently selected shopping list across screens
  const SelectedListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedListNotifierHash();

  @$internal
  @override
  SelectedListNotifier create() => SelectedListNotifier();
}

String _$selectedListNotifierHash() =>
    r'1656fbbeea519bac163e02b71afc07a78e20cc44';

/// AsyncNotifier to manage the currently selected shopping list across screens

abstract class _$SelectedListNotifier extends $AsyncNotifier<ShoppingList?> {
  FutureOr<ShoppingList?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<ShoppingList?>, ShoppingList?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ShoppingList?>, ShoppingList?>,
              AsyncValue<ShoppingList?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

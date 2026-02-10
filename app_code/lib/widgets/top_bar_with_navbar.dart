import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/nearest_supermarket_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/map_launcher_service_provider.dart';
import 'package:app_code/providers/real_app_providers/navigation_provider.dart';
import 'package:app_code/widgets/app_snackbar.dart';

/// A combined widget that includes the top app bar with title and 
/// authentication actions, as well as a secondary info bar that shows 
/// the nearest supermarket information.
class TopBarWithNavBar extends ConsumerWidget {
  final bool isMenuOpen;
  final VoidCallback onMenuToggle;

  const TopBarWithNavBar({
    super.key,
    required this.isMenuOpen,
    required this.onMenuToggle,
  });

  String _nearestSupermarketText(
    AppLocalizations l10n,
    NearestSupermarketState state,
  ) {
    if (state.isLoading) {
      return l10n.nearestSupermarketLocating;
    }

    if (state.supermarket != null) {
      return l10n.nearestSupermarketResult(
        state.supermarket!.name,
        state.supermarket!.formattedDistance,
      );
    }

    switch (state.errorType) {
      case NearestSupermarketError.locationServicesDisabled:
        return l10n.nearestSupermarketEnableLocationServices;
      case NearestSupermarketError.permissionDenied:
        return l10n.nearestSupermarketPermissionRequired;
      case NearestSupermarketError.permissionDeniedForever:
        return l10n.nearestSupermarketPermissionDeniedForever;
      case NearestSupermarketError.unableToGetLocation:
        return l10n.nearestSupermarketUnableToGetLocation;
      case NearestSupermarketError.lowGpsAccuracy:
        return l10n.nearestSupermarketLowGpsAccuracy;
      case NearestSupermarketError.noneWithinDistance:
        final distanceKm = state.errorDistanceKm ?? 5.0;
        return l10n.nearestSupermarketNoneWithinDistance(
          distanceKm.toStringAsFixed(0),
        );
      case NearestSupermarketError.networkTimeout:
        return l10n.nearestSupermarketNetworkTimeout;
      case NearestSupermarketError.networkIssue:
        return l10n.nearestSupermarketNetworkIssue;
      case null:
        return l10n.nearestSupermarketUnavailable;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final nearestSupermarketState = ref.watch(nearestSupermarketProvider);
    final mapLauncherService = ref.read(mapLauncherServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final nearestDisplayText = _nearestSupermarketText(
      l10n,
      nearestSupermarketState,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          title: Text(l10n.appTitle),
          backgroundColor: colorScheme.surface, // AppBar background matches theme
          foregroundColor: colorScheme.onSurface, // Text and icons
          actions: [
            authState.when(
              data: (user) {
                if (user == null || user.isAnonymous) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      key: const Key('sign_in_button'),
                      onPressed: () {
                        ref.read(appNavigationSignalProvider.notifier).state++;
                        Navigator.of(context).pushNamed('/signin');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: Text(l10n.signInLabel),
                    ),
                  );
                } else {
                  return IconButton(
                    key: const Key('logout_button'),
                    onPressed: () async => await authNotifier.signOut(),
                    icon: Icon(Icons.logout, color: colorScheme.onSurface),
                  );
                }
              },
              loading: () => const SizedBox(width: 48, height: 48),
              error: (_, __) => const SizedBox(width: 48, height: 48),
            ),
          ],
          leading: IconButton(
            icon: Icon(Icons.menu, color: colorScheme.onSurface),
            onPressed: onMenuToggle,
          ),
          elevation: 0,
        ),
        // Nearest supermarket info bar
        Material(
          color: nearestSupermarketState.hasValidSupermarket
              ? colorScheme.secondaryContainer
              : colorScheme.surfaceVariant,
          child: InkWell(
            onTap: nearestSupermarketState.hasValidSupermarket
                ? () async {
                    ref.read(appNavigationSignalProvider.notifier).state++;
                    final supermarket = nearestSupermarketState.supermarket!;
                    final success = await mapLauncherService.openMap(
                      latitude: supermarket.latitude,
                      longitude: supermarket.longitude,
                      label: supermarket.name,
                    );

                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        buildAppSnackBar(
                          message: l10n.unableToOpenMap,
                          context: context,
                        ),
                      );
                    }
                  }
                : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    nearestSupermarketState.hasValidSupermarket
                        ? Icons.place
                        : Icons.location_off,
                    size: 20,
                    color: nearestSupermarketState.hasValidSupermarket
                        ? colorScheme.secondary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nearestDisplayText,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: nearestSupermarketState.hasValidSupermarket
                            ? FontWeight.w500
                            : FontWeight.normal,
                        color: nearestSupermarketState.hasValidSupermarket
                            ? colorScheme.secondary
                            : colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (nearestSupermarketState.isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (nearestSupermarketState.hasValidSupermarket)
                    Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: colorScheme.secondary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
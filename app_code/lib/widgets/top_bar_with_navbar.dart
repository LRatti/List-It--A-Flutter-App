import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest_supermarket_provider.dart';
import 'package:app_code/providers/real_app_providers/map_launcher_service_provider.dart';
import 'package:app_code/widgets/app_snackbar.dart';

class TopBarWithNavBar extends ConsumerWidget {
  final bool isMenuOpen;
  final VoidCallback onMenuToggle;

  const TopBarWithNavBar({
    super.key,
    required this.isMenuOpen,
    required this.onMenuToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final nearestSupermarketState = ref.watch(nearestSupermarketProvider);
    final mapLauncherService = ref.read(mapLauncherServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          title: const Text('My Shopping App'),
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
                        Navigator.of(context).pushNamed('/signin');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: const Text('Sign In'),
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
                    final supermarket = nearestSupermarketState.supermarket!;
                    final success = await mapLauncherService.openMap(
                      latitude: supermarket.latitude,
                      longitude: supermarket.longitude,
                      label: supermarket.name,
                    );

                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        buildAppSnackBar(
                          message: 'Unable to open map',
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
                      nearestSupermarketState.displayText,
                      style: TextStyle(
                        fontSize: 14,
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
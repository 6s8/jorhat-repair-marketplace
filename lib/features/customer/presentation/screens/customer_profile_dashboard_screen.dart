import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../providers/job_repository_provider.dart';
import '../../../booking/presentation/pages/map_picker_sheet.dart';
import '../../models/customer_account_models.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../providers/customer_account_providers.dart';
import 'customer_marketplace_orders_screen.dart';

/// Customer Profile, Dashboard & Account Hub Screen for Fixly.
class CustomerProfileDashboardScreen extends ConsumerStatefulWidget {
  final ValueChanged<int> onNavigateTab;

  const CustomerProfileDashboardScreen({
    super.key,
    required this.onNavigateTab,
  });

  @override
  ConsumerState<CustomerProfileDashboardScreen> createState() =>
      _CustomerProfileDashboardScreenState();
}

class _CustomerProfileDashboardScreenState
    extends ConsumerState<CustomerProfileDashboardScreen> {
  void _showSettingsModal(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final currentMode = ref.watch(themeModeProvider);
            final isDark = currentMode == ThemeMode.dark;

            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.settings_rounded, color: primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Fixly App Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  SwitchListTile(
                    secondary: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppColors.accent,
                    ),
                    title: const Text(
                      'Dark Theme Mode',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Enable dark appearance for night view'),
                    value: isDark,
                    activeThumbColor: AppColors.accent,
                    onChanged: (val) {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditProfileModal(BuildContext context) {
    final profile = ref.read(customerProfileProvider);
    final nameCtrl = TextEditingController(text: profile.name);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final emailCtrl = TextEditingController(text: profile.email);
    final cityCtrl = TextEditingController(text: profile.city);
    final addrSummaryCtrl = TextEditingController(text: profile.addressSummary);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final primaryColor = Theme.of(context).colorScheme.primary;
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.edit_note_rounded, color: primaryColor, size: 26),
                            const SizedBox(width: 8),
                            const Text(
                              'Edit Profile Info',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City & Region *',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addrSummaryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Primary Address Summary',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final name = nameCtrl.text.trim();
                                final phone = phoneCtrl.text.trim();
                                if (name.isEmpty || phone.isEmpty) return;

                                setModalState(() => isSaving = true);
                                await ref
                                    .read(customerProfileProvider.notifier)
                                    .updateProfile(
                                      name: name,
                                      phone: phone,
                                      email: emailCtrl.text.trim(),
                                      city: cityCtrl.text.trim(),
                                      addressSummary: addrSummaryCtrl.text.trim(),
                                    );

                                if (!context.mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile updated & synced to server successfully!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.text,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.text,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'SAVE & SYNC PROFILE',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddressesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final addresses = ref.watch(customerAddressesProvider);
            final primaryColor = Theme.of(context).colorScheme.primary;

            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Saved Addresses',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 16),

                  // Quick Add via Map or GPS Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'QUICK ADD NEW ADDRESS:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showAddEditAddressDialog(context, autoFetchGps: true);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.my_location, size: 16),
                                label: const Text('Use Current Location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  const initialCenter = LatLng(26.7509, 94.2037);
                                  final pickedCenter = await MapPickerSheet.show(context, initialCenter);
                                  if (!context.mounted) return;
                                  if (pickedCenter != null) {
                                    _showAddEditAddressDialog(context, initialLatLng: pickedCenter);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                                icon: const Icon(Icons.map_rounded, size: 16, color: AppColors.primary),
                                label: const Text('Pick on Map', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: addresses.isEmpty
                        ? const Center(
                            child: Text(
                              'No saved addresses yet.\nTap below to add one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.separated(
                            itemCount: addresses.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final addr = addresses[i];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: addr.isDefault
                                        ? AppColors.accent
                                        : Colors.grey.shade300,
                                    width: addr.isDefault ? 1.8 : 1,
                                  ),
                                  color: addr.isDefault
                                      ? AppColors.accent.withValues(alpha: 0.08)
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          addr.label == 'Home'
                                              ? Icons.home_rounded
                                              : addr.label == 'Work'
                                                  ? Icons.work_rounded
                                                  : Icons.place_rounded,
                                          size: 18,
                                          color: primaryColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          addr.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (addr.isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.accent,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Text(
                                              'DEFAULT',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.text,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () {
                                            _showAddEditAddressDialog(context, addr: addr);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded,
                                              size: 18, color: Colors.red),
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () {
                                            ref
                                                .read(customerAddressesProvider.notifier)
                                                .deleteAddress(addr.id);
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      addr.fullAddressText,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    if (!addr.isDefault) ...[
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () {
                                          ref
                                              .read(customerAddressesProvider.notifier)
                                              .setDefaultAddress(addr.id);
                                        },
                                        child: Text(
                                          'Set as Default Address',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showAddEditAddressDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                      label: const Text(
                        'ADD NEW ADDRESS',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddEditAddressDialog(
    BuildContext context, {
    CustomerAddressModel? addr,
    bool autoFetchGps = false,
    LatLng? initialLatLng,
  }) {
    final profile = ref.read(customerProfileProvider);
    final nameCtrl = TextEditingController(text: addr?.name ?? profile.name);
    final phoneCtrl = TextEditingController(text: addr?.phone ?? profile.phone);
    final labelCtrl = TextEditingController(text: addr?.label ?? 'Home');
    final houseCtrl = TextEditingController(text: addr?.house ?? '');
    final areaCtrl = TextEditingController(text: addr?.area ?? '');
    final landmarkCtrl = TextEditingController(text: addr?.landmark ?? '');
    final cityCtrl = TextEditingController(text: addr?.city ?? 'Jorhat');
    final pinCtrl = TextEditingController(text: addr?.pincode ?? '785001');
    bool isDefault = addr?.isDefault ?? false;
    bool isFetchingGps = autoFetchGps || initialLatLng != null;

    // Helper for reverse geocoding lat/lng to fields
    Future<void> reverseGeocode(double lat, double lng, void Function(void Function()) setDialogState) async {
      try {
        final uri = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng');
        final res = await http.get(uri, headers: {'User-Agent': 'com.fixly.app'});
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final a = data['address'] as Map<String, dynamic>?;
          if (a != null) {
            final area = a['suburb'] ??
                a['neighbourhood'] ??
                a['road'] ??
                a['village'] ??
                'Tarazan';
            final pin = a['postcode'] ?? '785001';
            final city = a['city'] ?? a['town'] ?? 'Jorhat';
            areaCtrl.text = area.toString();
            cityCtrl.text = city.toString();
            pinCtrl.text = pin.toString();
          }
        }
      } catch (_) {
        areaCtrl.text = 'Tarazan, Jorhat';
        cityCtrl.text = 'Jorhat';
        pinCtrl.text = '785001';
      } finally {
        setDialogState(() => isFetchingGps = false);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Auto fetch if requested
            if (autoFetchGps && isFetchingGps) {
              autoFetchGps = false; // Run once
              Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
              ).then((pos) {
                reverseGeocode(pos.latitude, pos.longitude, setDialogState);
              }).catchError((_) {
                reverseGeocode(26.7509, 94.2037, setDialogState);
              });
            } else if (initialLatLng != null && isFetchingGps) {
              final latLng = initialLatLng!;
              initialLatLng = null; // Run once
              reverseGeocode(latLng.latitude, latLng.longitude, setDialogState);
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Text(
                addr == null ? 'Add New Address' : 'Edit Address',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Location Selection Action Buttons (GPS & Map)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isFetchingGps
                                ? null
                                : () async {
                                    setDialogState(() => isFetchingGps = true);
                                    try {
                                      bool serviceEnabled =
                                          await Geolocator.isLocationServiceEnabled();
                                      LocationPermission permission =
                                          await Geolocator.checkPermission();
                                      if (permission == LocationPermission.denied) {
                                        permission =
                                            await Geolocator.requestPermission();
                                      }

                                      double lat = 26.7509;
                                      double lng = 94.2037;

                                      if (serviceEnabled &&
                                          permission != LocationPermission.denied &&
                                          permission !=
                                              LocationPermission.deniedForever) {
                                        final pos =
                                            await Geolocator.getCurrentPosition(
                                          locationSettings: const LocationSettings(
                                              accuracy: LocationAccuracy.high),
                                        );
                                        lat = pos.latitude;
                                        lng = pos.longitude;
                                      }

                                      // Reverse geocode via Nominatim
                                      final uri = Uri.parse(
                                          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng');
                                      final res = await http.get(uri, headers: {
                                        'User-Agent': 'com.fixly.app'
                                      });
                                      if (res.statusCode == 200) {
                                        final data = json.decode(res.body);
                                        final a = data['address']
                                            as Map<String, dynamic>?;
                                        if (a != null) {
                                          final area = a['suburb'] ??
                                              a['neighbourhood'] ??
                                              a['road'] ??
                                              a['village'] ??
                                              'Tarazan';
                                          final pin =
                                              a['postcode'] ?? '785001';
                                          final city = a['city'] ??
                                              a['town'] ??
                                              'Jorhat';
                                          areaCtrl.text = area.toString();
                                          cityCtrl.text = city.toString();
                                          pinCtrl.text = pin.toString();
                                        }
                                      }
                                    } catch (_) {
                                      areaCtrl.text = 'Tarazan, Jorhat';
                                      cityCtrl.text = 'Jorhat';
                                      pinCtrl.text = '785001';
                                    } finally {
                                      setDialogState(() => isFetchingGps = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: isFetchingGps
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.my_location, size: 15),
                            label: const Text('Current Location',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              const initialCenter = LatLng(26.7509, 94.2037);
                              final pickedCenter = await MapPickerSheet.show(
                                  context, initialCenter);
                              if (pickedCenter != null) {
                                setDialogState(() => isFetchingGps = true);
                                try {
                                  final lat = pickedCenter.latitude;
                                  final lng = pickedCenter.longitude;
                                  final uri = Uri.parse(
                                      'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng');
                                  final res = await http.get(uri, headers: {
                                    'User-Agent': 'com.fixly.app'
                                  });
                                  if (res.statusCode == 200) {
                                    final data = json.decode(res.body);
                                    final a = data['address']
                                        as Map<String, dynamic>?;
                                    if (a != null) {
                                      final area = a['suburb'] ??
                                          a['neighbourhood'] ??
                                          a['road'] ??
                                          a['village'] ??
                                          'Jorhat Central';
                                      final pin =
                                          a['postcode'] ?? '785001';
                                      final city = a['city'] ??
                                          a['town'] ??
                                          'Jorhat';
                                      areaCtrl.text = area.toString();
                                      cityCtrl.text = city.toString();
                                      pinCtrl.text = pin.toString();
                                    }
                                  }
                                } catch (_) {
                                  areaCtrl.text = 'Jorhat Central';
                                } finally {
                                  setDialogState(() => isFetchingGps = false);
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              side: const BorderSide(color: AppColors.primary),
                            ),
                            icon: const Icon(Icons.map_rounded,
                                size: 15, color: AppColors.primary),
                            label: const Text('Pick on Map',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Label (Home / Work / Other)',
                        prefixIcon: Icon(Icons.label_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Receiver / Contact Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone Number *',
                        prefixIcon: Icon(Icons.phone_outlined),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: houseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'House / Flat / Building No. *',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: areaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Area / Street / Locality *',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: landmarkCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Landmark (Optional)',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cityCtrl,
                            decoration: const InputDecoration(labelText: 'City *'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: pinCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'PIN Code *'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text('Set as default address', style: TextStyle(fontSize: 13)),
                      value: isDefault,
                      activeColor: AppColors.accent,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() => isDefault = val ?? false);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final house = houseCtrl.text.trim();
                    final area = areaCtrl.text.trim();
                    if (house.isEmpty || area.isEmpty) return;

                    final newAddr = CustomerAddressModel(
                      id: addr?.id ?? 'addr-${DateTime.now().millisecondsSinceEpoch}',
                      label: labelCtrl.text.trim().isEmpty ? 'Home' : labelCtrl.text.trim(),
                      name: nameCtrl.text.trim().isEmpty ? profile.name : nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isEmpty ? profile.phone : phoneCtrl.text.trim(),
                      house: house,
                      area: area,
                      landmark: landmarkCtrl.text.trim(),
                      city: cityCtrl.text.trim().isEmpty ? 'Jorhat' : cityCtrl.text.trim(),
                      pincode: pinCtrl.text.trim().isEmpty ? '785001' : pinCtrl.text.trim(),
                      isDefault: isDefault,
                    );

                    if (addr == null) {
                      ref.read(customerAddressesProvider.notifier).addAddress(newAddr);
                    } else {
                      ref.read(customerAddressesProvider.notifier).updateAddress(newAddr);
                    }

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Address saved & synced to server!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.text,
                  ),
                  child: const Text('SAVE ADDRESS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPaymentMethodsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final methods = ref.watch(customerPaymentMethodsProvider);
            final primaryColor = Theme.of(context).colorScheme.primary;

            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.payment_rounded, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Payment Methods & UPI',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: methods.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final method = methods[i];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: method.isDefault
                                  ? AppColors.accent
                                  : Colors.grey.shade300,
                              width: method.isDefault ? 1.8 : 1,
                            ),
                            color: method.isDefault
                                ? AppColors.accent.withValues(alpha: 0.08)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  method.type == 'UPI'
                                      ? Icons.qr_code_2_rounded
                                      : method.type == 'Card'
                                          ? Icons.credit_card_rounded
                                          : Icons.payments_rounded,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          method.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (method.isDefault) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.accent,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'DEFAULT',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.text,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (method.details.isNotEmpty)
                                      Text(
                                        method.details,
                                        style: const TextStyle(
                                            fontSize: 12, color: AppColors.textMuted),
                                      ),
                                  ],
                                ),
                              ),
                              if (!method.isDefault)
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(customerPaymentMethodsProvider.notifier)
                                        .setDefaultPaymentMethod(method.id);
                                  },
                                  child: const Text('Set Default', style: TextStyle(fontSize: 11)),
                                ),
                              if (method.type != 'COD')
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      size: 18, color: Colors.red),
                                  onPressed: () {
                                    ref
                                        .read(customerPaymentMethodsProvider.notifier)
                                        .deletePaymentMethod(method.id);
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showAddPaymentMethodDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'ADD NEW PAYMENT METHOD / UPI',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddPaymentMethodDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: 'Google Pay');
    final detailsCtrl = TextEditingController(text: '');
    String type = 'UPI';
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Text('Add Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Payment Type'),
                    items: const [
                      DropdownMenuItem(value: 'UPI', child: Text('UPI ID (Google Pay / PhonePe)')),
                      DropdownMenuItem(value: 'Card', child: Text('Credit / Debit Card')),
                      DropdownMenuItem(value: 'NetBanking', child: Text('Net Banking')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          type = val;
                          if (val == 'UPI') titleCtrl.text = 'Google Pay';
                          if (val == 'Card') titleCtrl.text = 'HDFC Visa Card';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Provider / Name *',
                      hintText: 'e.g. Google Pay, PhonePe, SBI Card',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: detailsCtrl,
                    decoration: InputDecoration(
                      labelText: type == 'UPI' ? 'UPI ID / VPA *' : 'Card / Account Details *',
                      hintText: type == 'UPI' ? 'user@okicici' : '**** **** **** 4821',
                    ),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text('Set as default payment method', style: TextStyle(fontSize: 13)),
                    value: isDefault,
                    activeColor: AppColors.accent,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setDialogState(() => isDefault = val ?? false);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    final details = detailsCtrl.text.trim();
                    if (title.isEmpty || details.isEmpty) return;

                    final method = CustomerPaymentMethodModel(
                      id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
                      type: type,
                      title: title,
                      details: details,
                      isDefault: isDefault,
                    );

                    ref
                        .read(customerPaymentMethodsProvider.notifier)
                        .addPaymentMethod(method);

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment method saved & synced to server!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.text,
                  ),
                  child: const Text('SAVE METHOD', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final profile = ref.watch(customerProfileProvider);
    final addresses = ref.watch(customerAddressesProvider);
    final paymentMethods = ref.watch(customerPaymentMethodsProvider);
    final isDark = themeMode == ThemeMode.dark;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    final defaultAddress = addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.isNotEmpty
          ? addresses.first
          : const CustomerAddressModel(
              id: 'd', label: 'Home', house: '', area: 'Jorhat', landmark: '', city: 'Jorhat', pincode: '785001'),
    );

    final defaultPayment = paymentMethods.firstWhere(
      (m) => m.isDefault,
      orElse: () => paymentMethods.isNotEmpty
          ? paymentMethods.first
          : const CustomerPaymentMethodModel(
              id: 'p', type: 'UPI', title: 'Google Pay', details: 'anay@okicici'),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile & Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'App Settings',
            onPressed: () => _showSettingsModal(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Extra bottom padding for floating navbar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            _buildUserProfileCard(context, profile),

            const SizedBox(height: 20),

            // Active Job Alert Summary (if any)
            _buildActiveJobSummary(context),

            const SizedBox(height: 20),

            // Quick Action Dashboard Grid
            Text(
              'QUICK SERVICES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: mutedTextColor,
              ),
            ),
            const SizedBox(height: 10),
            _buildQuickActionGrid(context),

            const SizedBox(height: 24),

            // Account Settings Section
            Text(
              'ACCOUNT & PREFERENCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: mutedTextColor,
              ),
            ),
            const SizedBox(height: 10),
            _buildAccountSettingsList(context, isDark, defaultAddress, defaultPayment),

            const SizedBox(height: 30),

            // App Version Footer
            Center(
              child: Column(
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.accent, size: 28),
                  const SizedBox(height: 4),
                  const Text(
                    'Fixly v2.4.0',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Trusted On-Demand Repair Services & Marketplace',
                    style: TextStyle(fontSize: 11, color: mutedTextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileCard(BuildContext context, CustomerProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.accent,
            child: CircleAvatar(
              radius: 29,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person_rounded,
                size: 38,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.phone,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        profile.city,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEditProfileModal(context),
            icon: const Icon(Icons.edit_note_rounded, color: AppColors.accent, size: 26),
            tooltip: 'Edit Profile Info',
          ),
          IconButton(
            onPressed: () => _showSettingsModal(context),
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            tooltip: 'Fixly Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobSummary(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return FutureBuilder(
      future: ref.read(jobRepositoryProvider).fetchCustomerJobs('cust-123'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final jobs = snapshot.data ?? [];
        final activeJobs = jobs
            .where((j) =>
                j.status == 'pending' ||
                j.status == 'accepted' ||
                j.status == 'on_the_way' ||
                j.status == 'in_progress')
            .toList();

        if (activeJobs.isEmpty) return const SizedBox.shrink();
        final activeJob = activeJobs.first;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.engineering_rounded, color: AppColors.text, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE REPAIR IN PROGRESS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeJob.displayTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => widget.onNavigateTab(1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Track', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionGrid(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    final actions = [
      {
        'icon': Icons.build_circle_rounded,
        'title': 'Book Repair',
        'subtitle': 'AC, TV, Fridge & More',
        'color': primaryColor,
        'tab': 0,
      },
      {
        'icon': Icons.history_rounded,
        'title': 'My Bookings',
        'subtitle': 'Track Active Jobs',
        'color': AppColors.accent,
        'tab': 1,
      },
      {
        'icon': Icons.receipt_long_rounded,
        'title': 'My Orders',
        'subtitle': 'Parts & Appliances',
        'color': Colors.deepPurple,
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CustomerMarketplaceOrdersScreen(),
              ),
            ),
      },
      {
        'icon': Icons.storefront_rounded,
        'title': 'Marketplace',
        'subtitle': 'Parts & Refurbished',
        'color': AppColors.secondary,
        'tab': 2,
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': '24/7 Helpline',
        'subtitle': 'Customer Support',
        'color': Colors.deepOrange,
        'action': () => _showSupportModal(context),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        return Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              if (item.containsKey('tab')) {
                widget.onNavigateTab(item['tab'] as int);
              } else if (item.containsKey('action')) {
                (item['action'] as VoidCallback)();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: item['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: mutedTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountSettingsList(
    BuildContext context,
    bool isDark,
    CustomerAddressModel defaultAddr,
    CustomerPaymentMethodModel defaultPayment,
  ) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.person_outline_rounded, color: primaryColor),
            title: const Text('Edit Profile Information',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Name, Phone, Email & Region', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showEditProfileModal(context),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: Icon(Icons.location_on_outlined, color: primaryColor),
            title: const Text('Saved Addresses', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(
              defaultAddr.house.isNotEmpty ? defaultAddr.fullAddressText : 'Manage delivery & repair addresses',
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showAddressesModal(context),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.payment_outlined, color: Colors.blue),
            title: const Text('Payment Methods & UPI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${defaultPayment.title} (${defaultPayment.details})',
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showPaymentMethodsModal(context),
          ),
          const Divider(height: 1, indent: 56),
          SwitchListTile(
            secondary: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: AppColors.accent,
            ),
            title: const Text('Dark Theme Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Toggle dark view appearance', style: TextStyle(fontSize: 12)),
            value: isDark,
            activeThumbColor: AppColors.accent,
            onChanged: (val) {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          const Divider(height: 1, indent: 56),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
            subtitle: const Text('Log out of your Fixly account', style: TextStyle(fontSize: 12)),
            onTap: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }

  void _showSupportModal(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.support_agent_rounded, color: primaryColor, size: 28),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fixly Support',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '24/7 Jorhat Customer Care',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.call_rounded),
              label: const Text('Call Customer Support (+91 94351 00000)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

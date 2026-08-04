import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/customer_account_models.dart';

const String _kProfilePrefKey = 'fixly_customer_profile';
const String _kAddressesPrefKey = 'fixly_customer_addresses';
const String _kPaymentsPrefKey = 'fixly_customer_payments';

// --- Customer Profile Notifier ---
class CustomerProfileNotifier extends StateNotifier<CustomerProfileModel> {
  CustomerProfileNotifier()
      : super(const CustomerProfileModel(
          id: 'cust-123',
          name: 'Anay Sharma',
          phone: '+91 98765 43210',
          email: 'anay.sharma@example.com',
          city: 'Jorhat, Assam',
          addressSummary: 'Tarazan / Rupali Nagar, Jorhat',
        )) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_kProfilePrefKey);
      if (str != null && str.isNotEmpty) {
        state = CustomerProfileModel.fromJson(jsonDecode(str));
      }
    } catch (_) {}
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String city,
    required String addressSummary,
  }) async {
    state = state.copyWith(
      name: name,
      phone: phone,
      email: email,
      city: city,
      addressSummary: addressSummary,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfilePrefKey, jsonEncode(state.toJson()));
    } catch (_) {}
  }
}

final customerProfileProvider =
    StateNotifierProvider<CustomerProfileNotifier, CustomerProfileModel>(
  (ref) => CustomerProfileNotifier(),
);

// --- Customer Addresses Notifier ---
class CustomerAddressesNotifier extends StateNotifier<List<CustomerAddressModel>> {
  CustomerAddressesNotifier()
      : super(const [
          CustomerAddressModel(
            id: 'addr-1',
            label: 'Home',
            house: 'House #42, Ward 7',
            area: 'Tarazan, Rupali Nagar',
            landmark: 'Near Jorhat Gymkhana Club',
            city: 'Jorhat',
            pincode: '785001',
            isDefault: true,
          ),
          CustomerAddressModel(
            id: 'addr-2',
            label: 'Work',
            house: 'Office #204, AT Road Commercial Complex',
            area: 'Gar-Ali, Center Point',
            landmark: 'Opposite ASTC Bus Stand',
            city: 'Jorhat',
            pincode: '785001',
            isDefault: false,
          ),
        ]) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_kAddressesPrefKey);
      if (str != null && str.isNotEmpty) {
        final List list = jsonDecode(str);
        state = list.map((e) => CustomerAddressModel.fromJson(e)).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = state.map((e) => e.toJson()).toList();
      await prefs.setString(_kAddressesPrefKey, jsonEncode(listJson));
    } catch (_) {}
  }

  Future<void> addAddress(CustomerAddressModel address) async {
    final updated = List<CustomerAddressModel>.from(state);
    if (address.isDefault) {
      for (var i = 0; i < updated.length; i++) {
        updated[i] = updated[i].copyWith(isDefault: false);
      }
    }
    updated.add(address);
    state = updated;
    await _saveToPrefs();
  }

  Future<void> updateAddress(CustomerAddressModel address) async {
    final updated = state.map((a) {
      if (a.id == address.id) return address;
      if (address.isDefault) return a.copyWith(isDefault: false);
      return a;
    }).toList();
    state = updated;
    await _saveToPrefs();
  }

  Future<void> deleteAddress(String id) async {
    state = state.where((a) => a.id != id).toList();
    await _saveToPrefs();
  }

  Future<void> setDefaultAddress(String id) async {
    state = state.map((a) => a.copyWith(isDefault: a.id == id)).toList();
    await _saveToPrefs();
  }
}

final customerAddressesProvider = StateNotifierProvider<
    CustomerAddressesNotifier, List<CustomerAddressModel>>(
  (ref) => CustomerAddressesNotifier(),
);

// --- Customer Payment Methods Notifier ---
class CustomerPaymentMethodsNotifier
    extends StateNotifier<List<CustomerPaymentMethodModel>> {
  CustomerPaymentMethodsNotifier()
      : super(const [
          CustomerPaymentMethodModel(
            id: 'pay-1',
            type: 'UPI',
            title: 'Google Pay',
            details: 'anay.sharma@okicici',
            isDefault: true,
          ),
          CustomerPaymentMethodModel(
            id: 'pay-2',
            type: 'UPI',
            title: 'PhonePe',
            details: '9876543210@ybl',
            isDefault: false,
          ),
          CustomerPaymentMethodModel(
            id: 'pay-3',
            type: 'COD',
            title: 'Cash / Pay After Repair',
            details: 'Pay directly to technician upon completion',
            isDefault: false,
          ),
        ]) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_kPaymentsPrefKey);
      if (str != null && str.isNotEmpty) {
        final List list = jsonDecode(str);
        state = list.map((e) => CustomerPaymentMethodModel.fromJson(e)).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = state.map((e) => e.toJson()).toList();
      await prefs.setString(_kPaymentsPrefKey, jsonEncode(listJson));
    } catch (_) {}
  }

  Future<void> addPaymentMethod(CustomerPaymentMethodModel method) async {
    final updated = List<CustomerPaymentMethodModel>.from(state);
    if (method.isDefault) {
      for (var i = 0; i < updated.length; i++) {
        updated[i] = updated[i].copyWith(isDefault: false);
      }
    }
    updated.add(method);
    state = updated;
    await _saveToPrefs();
  }

  Future<void> updatePaymentMethod(CustomerPaymentMethodModel method) async {
    final updated = state.map((m) {
      if (m.id == method.id) return method;
      if (method.isDefault) return m.copyWith(isDefault: false);
      return m;
    }).toList();
    state = updated;
    await _saveToPrefs();
  }

  Future<void> deletePaymentMethod(String id) async {
    state = state.where((m) => m.id != id).toList();
    await _saveToPrefs();
  }

  Future<void> setDefaultPaymentMethod(String id) async {
    state = state.map((m) => m.copyWith(isDefault: m.id == id)).toList();
    await _saveToPrefs();
  }
}

final customerPaymentMethodsProvider = StateNotifierProvider<
    CustomerPaymentMethodsNotifier, List<CustomerPaymentMethodModel>>(
  (ref) => CustomerPaymentMethodsNotifier(),
);

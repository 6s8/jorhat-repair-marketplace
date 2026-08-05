# 🛠️ Fixly — Assam Repair & Parts Hub Marketplace App

Fixly is a comprehensive, production-grade Flutter application connecting Customers, Technicians, and Spare Parts Retailers across Assam. Built with clean architecture, Riverpod state management, Supabase authentication & database, and GoRouter deep linking.

---

## 🌐 Live Web Application & Download Links

| Resource | Link / Access |
| :--- | :--- |
| 🚀 **Live Web App (GitHub Pages)** | [https://6s8.github.io/jorhat-repair-marketplace/](https://6s8.github.io/jorhat-repair-marketplace/) |
| 📱 **Unified Fixly App APK (All Roles)** | [Download Fixly APK (v1.0.0)](https://github.com/6s8/jorhat-repair-marketplace/releases/download/v1.0.0/fixly.apk) |
| 🛒 **Fixly Customer App APK** | [Download Customer APK (v1.0.0)](https://github.com/6s8/jorhat-repair-marketplace/releases/download/v1.0.0/fixly_customer.apk) |
| 🔧 **Fixly Technician App APK** | [Download Technician APK (v1.0.0)](https://github.com/6s8/jorhat-repair-marketplace/releases/download/v1.0.0/fixly_technician.apk) |
| 🏬 **Fixly Retailer App APK** | [Download Retailer APK (v1.0.0)](https://github.com/6s8/jorhat-repair-marketplace/releases/download/v1.0.0/fixly_retailer.apk) |

---

## ⚡ Features & Architecture

### 🔑 Unified Single Entry Point Architecture
- **Single Entry Point (`lib/main.dart`)**: Consolidates all role-based applications into one clean, maintainable codebase.
- **Centralized `AuthGate`**: Single-source-of-truth profile role lookup via Supabase `profiles` table.
- **Dynamic Role Routing**:
  - `Customer` ➔ `/customer` (Booking, Marketplace, Order History, Profile)
  - `Technician` ➔ `/technician` (Job Feed, Map View, Active Jobs, Earnings)
  - `Retailer` ➔ `/retailer` (Inventory, Refurbished Store, Orders)
  - `New/Unassigned User` ➔ `/role-selection` (Role Onboarding)

### 📲 Cross-Platform Compatibility
- Runs natively on **Android (APK)**, **iOS**, and **Web (GitHub Pages)**.
- Uses `shared_preferences` for cross-platform local storage.
- Full OAuth and path strategy routing support via `usePathUrlStrategy()`.

---

## 🚀 Building & Running Locally

### Prerequisites
- Flutter SDK (3.24.0 or higher)
- Android SDK (for mobile builds)

### Installation & Run

```bash
# Clone the repository
git clone https://github.com/6s8/jorhat-repair-marketplace.git
cd jorhat-repair-marketplace

# Install dependencies
flutter pub get

# Run unified web app locally
flutter run -d chrome

# Build Web release for GitHub Pages
flutter build web --release --base-href "/jorhat-repair-marketplace/"

# Build Release APK
flutter build apk --release
```

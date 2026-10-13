# Product Management System (Full-Stack Assessment)

A high-performance, minimalist **Product Management System** featuring a unified **Laravel + Svelte 5** web application, a **Laravel Sanctum REST API**, and a cross-platform **Flutter Mobile Client**.

---

## 🌟 Tech Stack & Architecture

```
                                  ┌───────────────────────────────┐
                                  │      Flutter Mobile App       │
                                  │   (Android / iOS / Desktop)   │
                                  └──────────────┬────────────────┘
                                                 │
                                                 │ REST API (Sanctum Tokens)
                                                 ▼
┌──────────────────────────────┐  Inertia.js 2   ┌───────────────────────────────┐
│     Svelte 5 Web Client      │◄───────────────►│        Laravel Backend        │
│   (Vite + Minimalist CSS)    │                 │   (PHP 8.4 + Sanctum + Auth)  │
└──────────────────────────────┘                 └──────────────┬────────────────┘
                                                                │
                                                                ▼
                                                 ┌───────────────────────────────┐
                                                 │       MySQL Database          │
                                                 │ (XAMPP / MySQL at port 3306)  │
                                                 └───────────────────────────────┘
```

| Layer | Technologies & Tools |
|---|---|
| **Backend & APIs** | Laravel 11 / 12 (PHP 8.4), Laravel Sanctum, Eloquent ORM, MySQL |
| **Web Frontend** | Svelte 5 (Runes `$state`, `$derived`), Inertia.js v2, Vite, Vanilla CSS |
| **Mobile Client** | Flutter 3.x, Dart, `http`, `shared_preferences` |
| **Database** | MySQL (XAMPP / Local MySQL, Database: `product_management_system`) |
| **Design Language** | Warm Minimalist Luxe (`#FAF7F4`, `#3D3835`, Outfit/Inter typography) |

---

## 🚀 Key Features

### 1. Web Application (`backend/`)
- **Authentication**: Secure Session-based Login, Registration, and Password Reset.
- **Product Management**:
  - Full CRUD (Create, Read, Update, Delete) with validation.
  - Fields: Name, SKU (Unique), Description, Price (Rs.), Stock Quantity, Status (`Active` / `Inactive` / `Out of Stock`).
  - Instant Search & Status Filtering.
  - Pagination and Real-time Dashboard KPI counters.
- **Recycle Bin (Soft Deletes)**:
  - Soft delete products to safely prevent accidental loss.
  - Dedicated Recycle Bin view with **Restore** and **Permanent Delete** options.
  - Single-click **Empty Recycle Bin**.

### 2. REST API Engine (`backend/routes/api.php`)
- **Bearer Token Auth**: Laravel Sanctum tokens with automated device registration.
- **Standardized JSON Responses**: `{ success: true, message: "...", data: {...} }`.
- **Endpoints**:
  - `POST /api/login` - Authenticate & obtain Sanctum Bearer token.
  - `GET /api/user` - Retrieve authenticated user profile.
  - `POST /api/logout` - Revoke current access token.
  - `GET /api/products` - Paginated product catalog with `search` & `status` filters.
  - `POST /api/products` - Create new product with validation.
  - `GET /api/products/{id}` - Single product details.
  - `PUT /api/products/{id}` - Update product attributes.
  - `DELETE /api/products/{id}` - Soft delete product.

### 3. Flutter Mobile Client (`mobile_app/`)
- **Sanctum Auth**: Persistent Bearer token storage via `SharedPreferences`.
- **Product Dashboard**: Real-time stats pills, search bar, and status filtering.
- **Product CRUD**: Interactive detail view, create form, and update form with instant feedback.
- **Network Agility**: Dynamic Server Target switcher supporting:
  - Phone Wi-Fi (`http://192.168.1.x:8000/api`)
  - USB Port Forwarding / ADB Reverse (`http://127.0.0.1:8000/api`)
  - Android Emulator (`http://10.0.2.2:8000/api`)

---

## 🛠️ Quick Start & Setup Guide

### 1. Database Setup
1. Start **Apache** & **MySQL** in XAMPP.
2. Ensure database `product_management_system` exists:
   ```sql
   CREATE DATABASE IF NOT EXISTS product_management_system;
   ```

### 2. Backend & Web App Setup
```bash
cd backend

# Install dependencies
composer install
npm install

# Setup environment & run migrations with seed data
php artisan migrate:fresh --seed

# Start backend & Svelte asset bundler
php artisan serve --host=0.0.0.0 --port=8000
npm run dev
```

> **Default Demo Login:**
> - **Email:** `admin@example.com`
> - **Password:** `password123`

### 3. Mobile App Setup (Flutter)
```bash
cd mobile_app

# Fetch dependencies
flutter pub get

# Run on connected Android / iOS device or emulator
flutter run
```

---

## 📋 Assessment Verification & Testing

- **Backend Unit & Feature Tests**:
  ```bash
  cd backend
  php tests/test_api_runner.php
  ```
  *(100% 200/201 Success across all Sanctum endpoints)*

- **Mobile App Analysis & Tests**:
  ```bash
  cd mobile_app
  flutter analyze
  flutter test
  ```
  *(0 issues, all tests passed)*

---

## 👥 Authors & Assessment Submission
- **Project**: Intern Full-Stack Development Assessment
- **Status**: Completed & Production Ready

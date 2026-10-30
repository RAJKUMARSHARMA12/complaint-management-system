# CampusVoice - College Complaint Management System
> **Final Year Major Project** | Mobile Application (Flutter/Dart) + REST API (Node.js/Express) + Database (MongoDB Atlas)

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.x-0175C2.svg)](https://dart.dev)
[![Backend](https://img.shields.io/badge/Backend-Node.js%20%7C%20Express-green.svg)](https://nodejs.org)
[![Database](https://img.shields.io/badge/Database-MongoDB%20Atlas-47A248.svg)](https://www.mongodb.com/atlas)
[![Cloud Storage](https://img.shields.io/badge/Storage-Cloudinary-3448C5.svg)](https://cloudinary.com)
[![License](https://img.shields.io/badge/License-Academic%20Project-orange.svg)](#)

---

## 📌 Executive Overview

The **College Complaint Management System (CampusVoice)** is an enterprise-grade mobile grievance redressal and resolution tracking platform designed specifically for academic institutions. 

In conventional collegiate environments, grievance reporting relies heavily on informal, fragmented channels: verbal reports to hostel wardens, written chits submitted to department offices, or unorganized student WhatsApp groups. These methods suffer from lack of accountability, zero resolution tracking, no transparency regarding turn-around times, and complete absence of institutional analytics on recurring infrastructure failures (e.g., recurring mess hygiene violations, frequent hostel electrical breakdowns, lab equipment downtime).

**CampusVoice** transforms campus administration into a transparent, accountable, and automated workflow. It enables students and faculty to submit geotagged and photo-verified complaints in under 60 seconds, auto-assigns complaints based on institutional domain categories and predefined Service Level Agreements (SLAs), provides real-time progress timelines, enforces accountability with automated SLA breach escalations, and empowers college management with comprehensive analytical dashboards.

---

## 🚀 Key System Features

### 👨‍🎓 1. Student / User Portal
* **Rapid Issue Lodging:** Submit grievances with title, detailed description, department/category selection, specific campus location (Hostel block, Room number, Lab name, etc.), and priority level.
* **Photo Proof Attachment:** Capture on-the-spot photos via device camera or gallery upload (up to 3 compressed images via Cloudinary).
* **Anonymous Whistleblower Mode:** Toggle anonymous reporting for sensitive grievances (anti-ragging, academic bias, harassment) where student identities are cryptographically masked from authorities and administrators.
* **Live Status Tracking:** Real-time visual progress tracker with status badges (`Submitted`, `Assigned`, `In Progress`, `Resolved`, `Closed`).
* **Remarks & Interaction Timeline:** Add follow-up remarks and view chronological responses from assigned technicians and department heads.
* **Resolution Feedback & Rating:** Rate resolved grievances from 1 to 5 stars with satisfaction comments before moving issues to `Closed` status.
* **In-App Notification Feed:** Instant alerts for status updates, technician reassignments, remarks, and closure notices.

### 👷‍♂️ 2. Authority / Department Staff Portal
* **Role-Specific Dashboard:** View complaints directly assigned to the authority's jurisdiction (e.g., Hostel Warden, Mess In-Charge, System Admin, Chief Electrician).
* **Workflow Status Management:** Transition complaints through strictly validated workflow steps (`Assigned` $\rightarrow$ `In Progress` $\rightarrow$ `Resolved`) with mandatory action remarks.
* **Action Remarks & Photographic Evidence:** Document repairs and corrective actions taken.
* **SLA Target Indicators:** Visual countdown timers indicating remaining SLA hours/days before automated escalation.

### 👑 3. Central Administration Portal
* **Institutional Master Control:** Complete administrative visibility over all grievances across every department, block, and priority level.
* **Automated & Manual Assignment:** Automated routing based on department default authorities, with the ability to override and manually reassign cases.
* **Category & SLA Configuration:** Create, update, or deactivate grievance categories, assign default authorities, and set resolution turnaround SLA days.
* **User & Staff Management:** Provision new authority accounts, manage roles, and activate/deactivate institutional access.
* **Analytical Intelligence Dashboard:**
  * Total grievance volume, pending vs. resolved ratios, and escalation counts.
  * Breakdown charts by Category and Priority via interactive charts.
  * Monthly grievance trends and distribution analysis.
  * Average Resolution Time (Mean Time to Resolution - MTTR) metrics.
* **SLA Escalation Monitoring:** Automated daily cron monitors that flag overdue grievances as `Escalated` and send urgent alerts to senior college administration.

---

## 🏗️ System Architecture

The project employs a clean three-tier client-server architecture:

```
+-------------------------------------------------------------+
|                      FLUTTER CLIENT                         |
|  - Cross-Platform Mobile Application (Android Target APK)   |
|  - State Management: Provider Architecture                  |
|  - Networking: Dio HTTP Client with JWT Auth Interceptor    |
|  - Storage: Flutter Secure Storage (Encrypted Keystore)     |
+------------------------------+------------------------------+
                               |
                               | HTTPS / REST / JSON
                               | (Bearer Token Header)
                               v
+-------------------------------------------------------------+
|                 NODE.JS / EXPRESS REST API                  |
|  - Routing & Express Controllers                            |
|  - Security: JWT Verification, RBAC, Helmet, Express-Rate-Limit|
|  - Validation: Express-Validator sanitization layer         |
|  - Daily Cron: Node-Cron Automated SLA Escalation Engine    |
+--------------+-------------------------------+--------------+
               |                               |
               v                               v
+------------------------------+ +----------------------------+
|        MONGODB ATLAS         | |     CLOUDINARY STORAGE     |
| - Cloud Document Database    | | - Secure Media Storage     |
| - Collections: users,        | | - Multipart Image Uploads  |
|   categories, complaints,    | | - Auto image compression & |
|   notifications, audit_logs  | |   CDN delivery             |
+------------------------------+ +----------------------------+
```

---

## 📂 Repository & Project Directory Structure

```
major_project/
├── README.md                      # Primary project documentation & setup guide
├── pubspec.yaml                   # Flutter dependency specifications & assets
├── analysis_options.yaml          # Static analysis rules for Dart/Flutter
│
├── docs/                          # Comprehensive Architectural & Design Specs
│   ├── PRD.md                     # Product Requirements Document (Full Spec)
│   ├── ARCHITECTURE.md            # System Architecture, Schemas & Workflows
│   ├── API_LIST.md                # Exhaustive REST API Specification
│   └── TASK.md                    # 25-Day Implementation & Delivery Schedule
│
├── lib/                           # Flutter Mobile Application Source Code
│   ├── main.dart                  # Application entry point & theme initialization
│   ├── core/                      # Global singletons, constants, and utilities
│   │   ├── constants/             # App colors, typography, API URLs, status enums
│   │   ├── network/               # Dio client instance, interceptors, error parsers
│   │   ├── storage/               # Encrypted token storage wrapper
│   │   └── theme/                 # Material Design 3 light & dark theme definitions
│   ├── models/                    # Typed data transfer objects (User, Complaint, etc.)
│   ├── services/                  # Network communication services
│   ├── providers/                 # Provider state controllers (Auth, Complaints, Admin)
│   ├── screens/                   # Role-based UI screens
│   │   ├── auth/                  # Login, Register, Forgot Password
│   │   ├── student/               # Student Home, New Complaint, My Complaints, Feedback
│   │   ├── authority/             # Authority Task Queue, Update Status Sheet
│   │   ├── admin/                 # Dashboard Analytics, All Complaints, User & Category Admin
│   │   └── common/                # Complaint Detail, Notification Center, Profile, Splash
│   └── widgets/                   # Reusable UI components (Cards, Chips, Loaders, Dialogs)
│
├── backend/                       # Node.js & Express REST Backend (Micro-service)
│   ├── server.js                  # Server entry point, DB connection & cron startup
│   ├── app.js                     # Express app setup, middleware stack & route mounting
│   ├── config/                    # Database (Mongoose) and Cloudinary configurations
│   ├── models/                    # Mongoose Schemas (User, Category, Complaint, Notification)
│   ├── controllers/               # Business logic controllers (Auth, Complaints, Users, etc.)
│   ├── middleware/                # JWT verification, Role checks, Multer upload, Validation
│   ├── routes/                    # API route declarations
│   ├── utils/                     # Notification helpers, Token generators, Standard responses
│   ├── jobs/                      # Scheduled tasks (Automated SLA escalation cron)
│   └── seed/                      # Database seeder with sample admin, staff, and categories
│
└── android/                       # Native Android Project Configuration & Gradle Files
    ├── app/build.gradle.kts       # App-level build script (SDK 34, Min SDK 21)
    └── src/main/AndroidManifest.xml
```

---

## 🛠️ Technology Stack & Dependencies

| Layer | Component | Version / Library | Purpose |
|---|---|---|---|
| **Mobile App** | Framework | Flutter 3.x / Dart 3.x | Cross-platform client for high-performance native Android UI |
| | Architecture | MVVM + Provider | Separation of concerns, testable business logic, reactive state |
| | Networking | `dio: ^5.4.0` | HTTP client with automatic request/response interceptors |
| | Secure Storage | `flutter_secure_storage: ^9.0.0` | AES-encrypted storage for JWT authentication tokens |
| | Image Handling | `image_picker: ^1.0.7` | Camera capture and gallery selection |
| | Visualizations | `fl_chart: ^0.66.0` | Interactive charts for Admin performance analytics |
| | Date & Time | `intl: ^0.19.0` | Date formatting and localized timeline timestamps |
| **Backend API** | Runtime | Node.js LTS (v18 / v20) | Asynchronous, non-blocking REST API server |
| | Framework | Express.js 4.x | Middleware-oriented web application server |
| | Database | MongoDB Atlas (Mongoose ODM) | NoSQL document database for flexible, nested complaint histories |
| | Authentication | `jsonwebtoken`, `bcryptjs` | Stateless JWT authentication, 10-round salted password hashing |
| | Validation | `express-validator` | Strict input sanitization, type assertion, and XSS prevention |
| | File Handling | `multer`, `cloudinary` | Streaming multipart file uploads with cloud CDN hosting |
| | Automation | `node-cron` | Daily automated batch jobs for SLA breach detection and escalation |
| | Server Security | `helmet`, `cors`, `express-rate-limit` | HTTP header security, CORS controls, and brute-force prevention |

---

## ⚙️ Prerequisites & Local Environment Setup

### 1. Prerequisites
* **Flutter SDK:** Version 3.16.0 or higher ([Install Flutter](https://docs.flutter.dev/get-started/install))
* **Android Studio / Android SDK:** SDK Version 34, Android Platform Tools & Emulator
* **Node.js:** v18.x or v20.x LTS ([Download Node.js](https://nodejs.org))
* **MongoDB:** Free MongoDB Atlas cluster or local MongoDB instance (v6.0+)
* **Cloudinary Account:** Free account for media storage credentials ([Cloudinary](https://cloudinary.com))

---

## 🚀 Step-by-Step Installation & Execution Guide

### Phase A: Backend API Setup

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Configure Environment Variables:**
   Create a `.env` file in the `backend/` directory based on the `.env.example` template:
   ```env
   PORT=5000
   NODE_ENV=development
   MONGO_URI=mongodb+srv://<username>:<password>@cluster0.example.mongodb.net/college_cms?retryWrites=true&w=majority
   JWT_SECRET=super_secure_jwt_secret_key_change_in_production_2026
   JWT_EXPIRES_IN=7d
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_API_KEY=your_api_key
   CLOUDINARY_API_SECRET=your_api_secret
   ```

4. **Seed Initial Database (Admin, Categories, Authorities):**
   ```bash
   npm run seed
   ```

5. **Start the API Server:**
   ```bash
   # Development mode with live reload
   npm run dev

   # Production mode
   npm start
   ```
   *The server will boot on `http://localhost:5000` (or `http://10.0.2.2:5000` when accessed from the Android Emulator).*

---

### Phase B: Flutter Mobile Application Setup

1. **Navigate to the Flutter project root:**
   ```bash
   cd major_project
   ```

2. **Fetch Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Configure API Base URL:**
   Update the backend endpoint in `lib/core/constants/constants.dart`:
   * **Android Emulator:** `http://10.0.2.2:5000/api`
   * **Physical Android Device (via Wi-Fi):** `http://<YOUR_COMPUTER_LOCAL_IP>:5000/api`
   * **Production Deployed Server (e.g. Render):** `https://campusvoice-api.onrender.com/api`

4. **Run the Application:**
   ```bash
   # Verify device or emulator connectivity
   flutter devices

   # Launch app in debug mode
   flutter run
   ```

5. **Build Production Release APK:**
   ```bash
   flutter build apk --release
   ```
   *The output APK will be generated at:* `build/app/outputs/flutter-apk/app-release.apk`

---

## 👥 Default Demo Credentials & Seeded Accounts

The initial database seed (`npm run seed`) provisions the following testing credentials:

| Role | Email | Password | Department / Description |
|---|---|---|---|
| **Admin** | `admin@college.edu` | `Admin@123` | Institutional Super Administrator |
| **Authority** | `warden.hostel@college.edu` | `Staff@123` | Boys & Girls Hostel Affairs |
| **Authority** | `mess.manager@college.edu` | `Staff@123` | Campus Mess & Food Safety |
| **Authority** | `lab.incharge@college.edu` | `Staff@123` | Computer Labs & Network Infrastructure |
| **Authority** | `electrician@college.edu` | `Staff@123` | Electrical & Power Maintenance |
| **Student** | `student1@college.edu` | `Student@123` | Computer Science Undergraduate |
| **Student** | `student2@college.edu` | `Student@123` | Electrical Engineering Undergraduate |

---

## 🔄 Complaint Lifecycle State Machine

```
              +---------------+
              |   SUBMITTED   |  <--- Student raises issue
              +-------+-------+
                      |
                      | Auto-assigned via Category or
                      | Manually assigned by Admin
                      v
              +---------------+
              |   ASSIGNED    |  <--- SLA countdown clock begins
              +-------+-------+
                      |
                      | Authority begins work
                      v
              +---------------+
+-----------> |  IN PROGRESS  |  <--- Authority updates status & remarks
|             +-------+-------+
|                     |
|                     | Authority marks repair complete
|                     v
|             +---------------+
|             |   RESOLVED    |  <--- Awaiting student verification
|             +---+-------+---+
|                 |       |
| Student rejects |       | Student submits rating & feedback
| resolution      |       v
+-----------------+   +-------+-------+
                      |    CLOSED     |  <--- Final immutable state
                      +---------------+
```

* **Overdue Trigger:** If a complaint remains in `SUBMITTED`, `ASSIGNED`, or `IN PROGRESS` beyond its `dueDate` (calculated as `createdAt + category.slaDays`), the automated midnight cron job sets `isEscalated = true` and generates priority alerts to all administrators.

---

## 📚 Complete Project Documentation Index

Detailed engineering documentation is organized inside the [`docs/`](file:///Users/raj/StudioProjects/major_project/docs) directory:

| Document | Link | Description |
|---|---|---|
| **Product Requirements Document** | [`docs/PRD.md`](file:///Users/raj/StudioProjects/major_project/docs/PRD.md) | Full functional requirements, user personas, business rules, edge cases, and acceptance criteria. |
| **System Architecture Document** | [`docs/ARCHITECTURE.md`](file:///Users/raj/StudioProjects/major_project/docs/ARCHITECTURE.md) | Technical architecture, database schemas, security protocols, state machine, and data flow diagrams. |
| **REST API Specification** | [`docs/API_LIST.md`](file:///Users/raj/StudioProjects/major_project/docs/API_LIST.md) | Exhaustive API endpoint reference with request payloads, status codes, and JSON responses. |
| **25-Day Implementation Plan** | [`docs/TASK.md`](file:///Users/raj/StudioProjects/major_project/docs/TASK.md) | Detailed day-by-day development schedule, milestone deliverables, test scripts, and viva demo guide. |

---

## 🎓 Academic Viva & Evaluation Defense Points

When defending this project during final year major project viva voce examinations:

1. **Why Flutter instead of native Android or React Native?**
   * High performance compiled native ARM machine code, unified UI rendering engine (Impeller/Skia) guaranteeing pixel-perfect consistency across Android versions, and rapid development with hot reload.
2. **Why MongoDB Atlas instead of PostgreSQL or MySQL?**
   * Grievance records require dynamic, unstructured timeline entries: variable arrays of uploaded photo URLs, chronological remarks with differing metadata, nested feedback objects, and evolving category attributes. MongoDB's document model represents these without complex multi-table joins.
3. **How is Student Privacy Ensured in Anonymous Complaints?**
   * The database stores the true `createdBy` reference for data integrity and duplicate prevention. However, when complaints are queried by Authorities or Administrators, the controller dynamically strips personal identification attributes (`name`, `email`, `studentId`, `phone`), outputting an `"Anonymous Student"` placeholder.
4. **How does SLA Escalation Work?**
   * Each Category defines an SLA period (e.g., 2 days for Electrical, 1 day for Mess Hygiene). Upon assignment, a `dueDate` timestamp is established. A scheduled `node-cron` daemon evaluates open complaints daily against `Date.now()`. Breached records are flagged `isEscalated: true` and trigger priority alerts to the Admin dashboard.
5. **How is Security Maintained?**
   * Passwords use 10-round salted bcrypt hashes. Stateless JWT tokens expire in 7 days and are securely stored in the Android Keystore via `flutter_secure_storage`. All routes enforce Role-Based Access Control (RBAC) middleware, and inputs are sanitized via `express-validator`.

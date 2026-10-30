# Engineering Task Breakdown & 25-Day Sprint Plan
## CampusVoice - College Complaint Management System

**Document Version:** 2.0  
**Project Scope:** Final Year Major Project (Individual Engineering Capstone)  
**Methodology:** Iterative Agile Sprint with Daily Milestone Gates  
**Timeline:** 25 Working Days  
**Legend:**
* **[S]** System Setup & Cloud Infrastructure
* **[B]** Backend API & Database Implementation
* **[F]** Flutter Mobile Client Development
* **[D]** Academic Documentation & Diagrams
* **[T]** Automated & Integration Testing

---

## 📅 Phase 1: Inception, Environment Setup & Domain Modeling (Days 1–2)

### Day 1: Container Infrastructure Provisioning, Local Tooling & Project Skeleton
* **Primary Objective:** Establish development environments, containerized database, containerized media storage, and source control.
* **Tasks:**
  - [x] **[S]** Initialize Git repository and configure `.gitignore` (ignoring `.env`, `node_modules`, `build/`, `.idea/`, and `.docker-data/`).
  - [x] **[S]** Verify local developer toolchain: Node.js LTS (v24.14.0), Flutter SDK (v3.47.9 / Dart 3.13.7), Android Studio (SDK 36.0.0), and Docker Desktop (v29.7.2).
  - [x] **[S]** Provision Docker MongoDB container (`mongo:7.0`, `campusvoice-mongodb`) with persistent volume, `college_cms` database, secure authentication credentials, initialization script (`docker/mongo-init.js`), and Mongo Express web dashboard (`campusvoice-mongo-express`, port 8081).
  - [x] **[S]** Provision Docker media server container (`nginx:alpine`, `campusvoice-media-server`) on port 8080 with persistent volume (`media_data`) for evidence photo storage, CORS headers, and local HTTP delivery in place of Cloudinary.
  - [x] **[D]** Review and finalize [`docs/PRD.md`](file:///Users/raj/StudioProjects/major_project/docs/PRD.md) and [`docs/ARCHITECTURE.md`](file:///Users/raj/StudioProjects/major_project/docs/ARCHITECTURE.md) to reflect containerized infrastructure topology.
  - [x] **[F]** Review Dart 3.x fundamentals: asynchronous programming (`async`/`await`), Streams, and Flutter widget lifecycles.
* **Verification & Testing:**
  - [x] Run `flutter doctor -v` ensuring zero blocking issues with Android SDK and toolchains.
  - [x] Test MongoDB container connection string (`mongodb://admin:password123@localhost:27017/college_cms?authSource=admin`) and database state.
  - [x] Test container HTTP health checks (`http://localhost:8080/health` and `http://localhost:8081`).
* **Deliverable:** Working repository skeleton with Docker Compose infrastructure (`docker-compose.yml`), `.env` / `.env.example`, and verified local container services.

---

### Day 2: Mobile Toolchain Validation & UI Wireframing
* **Primary Objective:** Validate Android Emulator execution and draft UI wireframes.
* **Tasks:**
  - [x] **[S]** Launch Android Emulator (API 37 / Medium Phone arm64) and verify ADB daemon connection.
  - [x] **[F]** Execute sample counter app on emulator to verify ADB bridge and hot reload responsiveness.
  - [x] **[D]** Draft high-fidelity paper/Figma wireframes for 10 core screens ([`docs/WIREFRAMES.md`](file:///Users/raj/StudioProjects/major_project/docs/WIREFRAMES.md)):
    1. Splash & Auth (Login / Register)
    2. Student Home & Dashboard
    3. New Complaint Form (with image attachments)
    4. My Complaints List & Filter Chips
    5. Complaint Detail (Timeline & Photos)
    6. Feedback & Star Rating Modal
    7. Authority Queue & Task List
    8. Status Update Action Sheet
    9. Admin Executive Dashboard (Charts)
    10. Category & User Management Screens
  - [x] **[D]** Draft initial UML Use Case Diagram illustrating interactions among Student, Authority, Admin, and Cron Daemon ([`docs/USE_CASE_DIAGRAM.md`](file:///Users/raj/StudioProjects/major_project/docs/USE_CASE_DIAGRAM.md)).
* **Verification & Testing:**
  - [x] Verify `flutter run` deploys smoothly to the emulator.
  - [x] Verify UI hot reload responsiveness (state preserved across theme and title changes).
* **Deliverable:** Wireframe design spec and Use Case diagram committed to repository.

---

## 📅 Phase 2: Backend REST API & Database Engine (Days 3–6)

### Day 3: Server Framework, Database Connection & Authentication Engine
* **Primary Objective:** Build the Express REST server foundation, connect to MongoDB, and implement secure JWT authentication.
* **Tasks:**
  - [ ] **[B]** Initialize Node.js backend:
    ```bash
    mkdir backend && cd backend && npm init -y
    npm install express mongoose dotenv bcryptjs jsonwebtoken cors helmet express-validator multer cloudinary multer-storage-cloudinary node-cron
    npm install --save-dev nodemon
    ```
  - [ ] **[B]** Create backend modular structure (`config/`, `models/`, `controllers/`, `routes/`, `middleware/`, `utils/`, `jobs/`).
  - [ ] **[B]** Configure Mongoose connection in `config/db.js` with auto-reconnect logic.
  - [ ] **[B]** Implement `models/User.js` with bcrypt salted password hashing middleware.
  - [ ] **[B]** Implement `controllers/auth.controller.js` and `routes/auth.routes.js`:
    - `POST /api/auth/register` (strictly sets `role: 'student'`)
    - `POST /api/auth/login` (verifies password, checks `isActive`, returns signed 7-day JWT)
    - `GET /api/auth/me` (decodes token and returns current user)
  - [ ] **[B]** Implement security middleware: `middleware/auth.js` (JWT verification) and `middleware/role.js` (Role-Based Access Control).
  - [ ] **[B]** Create database seeder script `seed/seed.js` pre-populating:
    - 1 Super Admin (`admin@college.edu`)
    - 4 Authorities (Hostel Warden, Mess Manager, Lab In-charge, Electrician)
    - 3 Students
* **Verification & Testing:**
  - Execute `npm run seed` and verify documents in MongoDB Atlas Compass.
  - Execute Postman tests for registration, valid login, invalid password (expect 400), and deactivated user login (expect 403).
* **Deliverable:** Fully functional authentication microservice with seeded test accounts.

---

### Day 4: Categories, User Administration & Complaint Lodging (Part 1)
* **Primary Objective:** Build administrative governance APIs and multipart photo upload for complaint creation.
* **Tasks:**
  - [ ] **[B]** Implement `models/Category.js` with `slaDays` and `defaultAuthority`.
  - [ ] **[B]** Build Category CRUD routes:
    - `GET /api/categories` (active only)
    - `POST /api/categories` (Admin only)
    - `PATCH /api/categories/:id/status` (Admin toggle)
  - [ ] **[B]** Configure Cloudinary storage engine in `config/cloudinary.js` and multer middleware `middleware/upload.js` (enforcing max 3 files, 5 MB limit, JPEG/PNG only).
  - [ ] **[B]** Implement `models/Complaint.js` with embedded `remarks` and `feedback` schemas.
  - [ ] **[B]** Build `POST /api/complaints`:
    - Generate unique atomic sequential ID (`CMP-0001`).
    - Stream images to Cloudinary and store returned secure URLs.
    - Check if category has `defaultAuthority`: automatically set `status = 'Assigned'`, `assignedTo = defaultAuthority`, and compute `dueDate = Date.now() + (slaDays * 86400000)`.
  - [ ] **[B]** Build `GET /api/complaints/my` with status filtering and pagination.
* **Verification & Testing:**
  - Test multipart `POST /api/complaints` in Postman with 2 images; verify images appear in Cloudinary Media Library and complaint is created in MongoDB.
* **Deliverable:** Working complaint submission API with cloud photo persistence.

---

### Day 5: Complaint Workflow, Whistleblower Masking & Remarks (Part 2)
* **Primary Objective:** Enforce the finite state machine, anonymous privacy masking, and collaborative timeline remarks.
* **Tasks:**
  - [ ] **[B]** Build `GET /api/complaints/assigned` for authorities.
  - [ ] **[B]** Build `GET /api/complaints` (Admin master view with multi-parameter search).
  - [ ] **[B]** Build `GET /api/complaints/:id` with anonymous privacy scrubber:
    ```javascript
    if (complaint.isAnonymous && req.user.role !== 'student') {
      complaint.createdBy = { name: "Anonymous Student" };
    }
    ```
  - [ ] **[B]** Implement `PATCH /api/complaints/:id/assign` (Admin delegation).
  - [ ] **[B]** Implement `PATCH /api/complaints/:id/status` with strict state machine validation:
    - Enforce `STATUS_TRANSITIONS` mapping.
    - Require mandatory action remark when marking `Resolved`.
    - Record `resolvedAt` timestamp.
  - [ ] **[B]** Implement `POST /api/complaints/:id/remarks` allowing threaded communication.
* **Verification & Testing:**
  - Verify that an invalid jump from `Submitted` to `Resolved` returns `400 Bad Request`.
  - Verify that retrieving an anonymous complaint as an Authority returns `name: "Anonymous Student"` with zero email/phone exposure.
* **Deliverable:** Robust workflow state engine adhering strictly to PRD specifications.

---

### Day 6: Feedback Loop, Notification Subsystem & Error Hardening
* **Primary Objective:** Complete the resolution verification cycle and centralize error handling.
* **Tasks:**
  - [ ] **[B]** Implement `POST /api/complaints/:id/feedback`:
    - Verify requester is original owner.
    - Verify status is currently `Resolved`.
    - Save 1–5 star rating and comments.
    - Transition status to terminal state `Closed` and set `closedAt`.
  - [ ] **[B]** Implement `models/Notification.js` and notification helper `utils/notify.js`.
  - [ ] **[B]** Hook notification triggers into: Assignment, Status change, Remark added, Feedback received.
  - [ ] **[B]** Implement notification routes: `GET /api/notifications` and `PATCH /api/notifications/read-all`.
  - [ ] **[B]** Build centralized error handling middleware `middleware/error.js`.
  - [ ] **[T]** Export complete Postman Collection v2.1 with pre-request scripts into `backend/tests/CampusVoice.postman_collection.json`.
  - [ ] **[D]** Generate Entity-Relationship (ER) Diagram artifact.
* **Verification & Testing:**
  - Run the entire Postman collection end-to-end (Register $\rightarrow$ Lodge $\rightarrow$ Assign $\rightarrow$ Resolve $\rightarrow$ Feedback $\rightarrow$ Closed).
* **Deliverable:** 100% completed, tested, and documented backend REST API.

---

## 📅 Phase 3: Flutter Client - Student Experience (Days 7–10)

### Day 7: Mobile Architecture, Networking & Authentication UI
* **Primary Objective:** Scaffold the Flutter project, establish the Dio network client, and build login/registration screens.
* **Tasks:**
  - [ ] **[F]** Add dependencies to `pubspec.yaml`:
    ```yaml
    dependencies:
      dio: ^5.4.0
      provider: ^6.1.1
      flutter_secure_storage: ^9.0.0
      image_picker: ^1.0.7
      fl_chart: ^0.66.0
      intl: ^0.19.0
    ```
  - [ ] **[F]** Implement `core/network/api_client.dart` with automatic Bearer token interceptor and 401 error handler.
  - [ ] **[F]** Implement `core/storage/secure_storage.dart` for encrypted keystore token persistence.
  - [ ] **[F]** Implement typed models: `User`, `Complaint`, `Category`, `Notification`.
  - [ ] **[F]** Build `AuthProvider` managing authentication state, login, registration, and auto-login check.
  - [ ] **[F]** Build UI: `SplashScreen`, `LoginScreen`, and `RegisterScreen` with input validation.
* **Verification & Testing:**
  - Verify login with seeded credentials navigates to the appropriate screen and persists token across app restarts.
* **Deliverable:** Functional authentication flow on Android emulator.

---

### Day 8: New Complaint Form & Cloudinary Image Upload
* **Primary Objective:** Implement the complaint lodging interface with camera/gallery image picker.
* **Tasks:**
  - [ ] **[F]** Implement `CategoryService` and load active categories into `ComplaintProvider`.
  - [ ] **[F]** Build `NewComplaintScreen`:
    - Form fields for Title, Description, Location, and Priority segmented control.
    - Dynamic Category dropdown populated from API.
    - Anonymous whistleblower toggle switch with informational card.
    - Image attachment row: tap to launch `image_picker` (Camera or Gallery), thumbnail preview carousel, and delete icon.
  - [ ] **[F]** Implement multipart network submission with modal progress dialog and user-friendly error banners.
* **Verification & Testing:**
  - Take a photo on the emulator camera, submit a complaint, and confirm receipt in the backend console.
* **Deliverable:** End-to-end complaint lodging from mobile app to Cloudinary & MongoDB.

---

### Day 9: Student Home, Complaint Tracking & Custom Widgets
* **Primary Objective:** Build the student dashboard and complaint tracking screens.
* **Tasks:**
  - [ ] **[F]** Build reusable widgets:
    - `StatusChip`: Visual badge with status-coded colors (e.g., Orange for Submitted, Blue for Assigned, Yellow for In Progress, Green for Resolved, Gray for Closed).
    - `PriorityBadge`: Visual indicator for Low, Medium, High, Urgent.
    - `ComplaintCard`: Summary card showing ID, title, category, date, and status.
  - [ ] **[F]** Build `StudentHomeScreen` featuring:
    - Welcome greeting with user name.
    - Prominent "Raise Complaint" action card.
    - Quick summary of active grievances.
  - [ ] **[F]** Build `MyComplaintsScreen` with horizontal filter chips (`All`, `Active`, `Resolved`, `Closed`) and pull-to-refresh (`RefreshIndicator`).
* **Verification & Testing:**
  - Verify that tapping status chips filters the list instantly without extraneous network calls.
* **Deliverable:** Polished student complaint browsing experience.

---

### Day 10: Detail Timeline, Feedback Dialog & Notifications
* **Primary Objective:** Implement the complaint inspection screen, action remarks, and rating dialog.
* **Tasks:**
  - [ ] **[F]** Build `ComplaintDetailScreen`:
    - Header with ID, category, location, and SLA due date countdown.
    - Expandable photo gallery with full-screen zoom preview.
    - Chronological remarks timeline showing user avatars, roles, and timestamps.
    - Action text box to post new remarks.
  - [ ] **[F]** Build `FeedbackDialog`:
    - Displayed only when status is `Resolved`.
    - 5-star interactive rating bar and review comments field.
    - Calls `POST /api/complaints/:id/feedback` and updates screen to `Closed`.
  - [ ] **[F]** Build `NotificationInboxScreen` with unread dot indicators and "Mark All as Read" header button.
  - [ ] **[D]** Draft Data Flow Diagrams (DFD Level 0 and Level 1).
* **Verification & Testing:**
  - Submit a complaint, resolve it in Postman, open the app, verify `FeedbackDialog` opens, rate 5 stars, and confirm complaint transitions to `Closed`.
* **Deliverable:** Complete Student feedback and closure loop.

---

## 📅 Phase 4: Authority & Admin Workflows (Days 11–14)

### Day 11: Authority Queue & Status Update Bottom Sheet
* **Primary Objective:** Build the dedicated authority experience for maintenance personnel and department heads.
* **Tasks:**
  - [ ] **[F]** Build `AuthorityHomeScreen`:
    - KPI cards: Assigned Tickets, In Progress, Pending Verification.
    - Filterable list of assigned grievances.
  - [ ] **[F]** Build `StatusUpdateBottomSheet`:
    - Dynamically presents only valid next statuses based on the FSM matrix.
    - Mandatory action remark input field.
    - Dispatches `PATCH /api/complaints/:id/status`.
* **Verification & Testing:**
  - Log in as `warden.hostel@college.edu`, view assigned tickets, update status to `In Progress` with a remark, and confirm instant timeline update.
* **Deliverable:** Operational authority management portal.

---

### Day 12: Admin Master Complaint Console & Delegation Dialog
* **Primary Objective:** Implement central administrative oversight and delegation controls.
* **Tasks:**
  - [ ] **[F]** Build `AdminAllComplaintsScreen`:
    - Real-time search bar (by Complaint ID or Title).
    - Multi-select filters (Category, Status, Escalated Only).
  - [ ] **[F]** Build `AssignAuthorityDialog`:
    - Authority staff dropdown populated from `GET /api/users?role=authority`.
    - Executes `PATCH /api/complaints/:id/assign`.
* **Verification & Testing:**
  - Reassign an unassigned complaint to a technician and verify the technician immediately receives the ticket in their queue.
* **Deliverable:** Central administrative complaint delegation tools.

---

### Day 13: Category & User Governance Interfaces
* **Primary Objective:** Provide administrative CRUD interfaces for campus departments and staff accounts.
* **Tasks:**
  - [ ] **[F]** Build `ManageCategoriesScreen`:
    - List categories with active/inactive toggles and SLA days badges.
    - "Add Category" modal dialog (Name, Description, SLA Days, Default Authority).
  - [ ] **[F]** Build `ManageUsersScreen`:
    - Segmented tabs: `Authorities` vs `Students`.
    - User activation toggle (activate/deactivate access).
    - "Add Authority" dialog (Name, Email, Department, Initial Password).
* **Verification & Testing:**
  - Create a new category "Sports Complex", lodge a complaint under it, and confirm auto-routing.
* **Deliverable:** Fully functional administrative master data controls.

---

### Day 14: Mid-Term Integration Audit & Sequence Diagrams
* **Primary Objective:** Execute full end-to-end integration testing and document architectural sequence flows.
* **Tasks:**
  - [ ] **[T]** Conduct comprehensive integration test using three physical/virtual devices simultaneously:
    1. Student lodges issue with photo.
    2. Admin reviews and assigns.
    3. Authority moves to In Progress, then Resolved.
    4. Student rates and closes.
  - [ ] **[T]** Fix UI layout overflow bugs, keyboard occlusion issues, and null-safety edge cases.
  - [ ] **[D]** Draft UML Sequence Diagrams for:
    - Complaint Submission & Auto-Assignment Flow
    - Status Update & Resolution Flow
    - SLA Breach Escalation Flow
* **Verification & Testing:**
  - Zero critical crashes or unhandled exceptions across the entire lifecycle.
* **Deliverable:** Stable integration baseline and formal UML sequence diagrams.

---

## 📅 Phase 5: Analytics Dashboard & Automated Escalation (Days 15–17)

### Day 15: Executive Dashboard & Interactive Charts
* **Primary Objective:** Implement visual data analytics for college leadership.
* **Tasks:**
  - [ ] **[B]** Implement dashboard aggregation endpoints in `controllers/dashboard.controller.js`:
    - `/api/dashboard/stats` (Total, Open, Resolved, Escalated)
    - `/api/dashboard/by-category` (MongoDB `$group` aggregation)
    - `/api/dashboard/by-status` (Count per status state)
    - `/api/dashboard/monthly-trend` (6-month submission history)
    - `/api/dashboard/resolution-time` (Mean Time to Resolution)
  - [ ] **[F]** Integrate `fl_chart` into `AdminDashboardScreen`:
    - Top metric cards with gradient styling.
    - Interactive Pie/Doughnut Chart for Category distribution.
    - Bar Chart for Status distribution.
    - Line Chart for Monthly Trends.
* **Verification & Testing:**
  - Verify chart slices display accurate counts matching database records.
* **Deliverable:** Executive analytics dashboard with interactive data visualizations.

---

### Day 16: Automated SLA Escalation Engine
* **Primary Objective:** Deploy the automated background cron daemon for overdue complaints.
* **Tasks:**
  - [ ] **[B]** Implement `jobs/escalation.job.js` using `node-cron`:
    - Configured to run daily at midnight (`0 0 * * *`).
    - Query: `status NOT IN ('Resolved', 'Closed') AND dueDate < now AND isEscalated == false`.
    - Sets `isEscalated = true` and `escalatedAt = now`.
    - Dispatches urgent notifications to all admin users.
  - [ ] **[B]** Mount temporary manual trigger route `POST /api/jobs/trigger-escalation` (Admin only) for live viva demonstration.
  - [ ] **[F]** Update `ComplaintCard` and `ComplaintDetailScreen` to display an animated "ESCALATED / OVERDUE" badge.
* **Verification & Testing:**
  - Create a complaint with a 1-minute test SLA; trigger the escalation daemon; verify complaint card displays red "ESCALATED" badge and admin receives alert.
* **Deliverable:** Fully functional SLA monitoring and automated escalation engine.

---

### Day 17: UI Polish, Micro-Interactions & Usability
* **Primary Objective:** Elevate visual aesthetics, micro-interactions, and error recovery.
* **Tasks:**
  - [ ] **[F]** Implement shimmering loading skeletons for list views.
  - [ ] **[F]** Implement friendly empty-state illustrations when zero complaints match filters.
  - [ ] **[F]** Add pull-to-refresh to all listing screens.
  - [ ] **[F]** Ensure form input fields dismiss keyboard cleanly on tap outside.
* **Verification & Testing:**
  - Test on various Android screen resolutions (phone, small tablet) to ensure no pixel-overflow errors.
* **Deliverable:** Polished, responsive mobile user interface.

---

## 📅 Phase 6: System Hardening & Cloud Deployment (Days 18–20)

### Day 18: Security Hardening & Rate Limiting
* **Primary Objective:** Harden server security perimeter and validate resilience against malicious inputs.
* **Tasks:**
  - [ ] **[B]** Apply `helmet` security headers and strict `cors` origins.
  - [ ] **[B]** Apply `express-rate-limit` to `/api/auth/login` (5 requests / 15 minutes).
  - [ ] **[B]** Audit all inputs with `express-validator` to eliminate NoSQL injection vulnerabilities.
  - [ ] **[B]** Ensure all sensitive credentials reside strictly in `.env`.
* **Verification & Testing:**
  - Run automated Postman security tests verifying rapid login attempts trigger `429 Too Many Requests`.
* **Deliverable:** Production-hardened REST API backend.

---

### Day 19: Cloud Deployment to Render & Atlas Verification
* **Primary Objective:** Deploy the Node.js backend to the public cloud and connect the mobile client.
* **Tasks:**
  - [ ] **[B]** Push backend code to GitHub repository.
  - [ ] **[S]** Deploy Web Service on Render connected to the repository:
    - Build command: `npm install`
    - Start command: `node server.js`
    - Add environment variables (`MONGO_URI`, `JWT_SECRET`, `CLOUDINARY_*`).
  - [ ] **[B]** Run seed script on deployed Render instance: verify Atlas connectivity.
  - [ ] **[F]** Update mobile app `base_url` to the live Render domain (`https://campusvoice-api.onrender.com/api`).
* **Verification & Testing:**
  - Verify app communicates with live cloud backend over 4G/5G cellular network.
* **Deliverable:** Live, publicly accessible cloud backend and mobile configuration.

---

### Day 20: Production Release APK Build & Offline Backup
* **Primary Objective:** Compile optimized standalone Android release APK.
* **Tasks:**
  - [ ] **[F]** Configure Android app name ("CampusVoice"), custom launcher icon (`ic_launcher`), and vector splash screen.
  - [ ] **[F]** Configure `android/app/build.gradle.kts` with proper application ID, target SDK 34, and minify/shrink settings.
  - [ ] **[F]** Compile standalone release APK:
    ```bash
    flutter build apk --release
    ```
  - [ ] **[S]** Install `app-release.apk` on physical Android phone.
  - [ ] **[S]** Record an unedited, high-definition 5-minute screen recording of the full demo flow as an emergency offline backup.
* **Verification & Testing:**
  - Verify smooth installation and operation on a clean physical Android device without developer mode enabled.
* **Deliverable:** Signed production release APK (`app-release.apk`) and offline demo video.

---

## 📅 Phase 7: Academic Documentation, Viva Preparation & Defense (Days 21–25)

### Day 21: Software Requirements Specification (SRS) & Architecture Artifacts
* **Primary Objective:** Compile formal academic SRS document and system architecture diagrams.
* **Tasks:**
  - [ ] **[D]** Compile comprehensive IEEE-standard Software Requirements Specification (SRS) incorporating PRD and functional requirements.
  - [ ] **[D]** Export finalized high-resolution system diagrams:
    - System Architecture Diagram
    - Entity-Relationship (ER) Diagram
    - Use Case Diagram
    - State Machine Diagram
* **Deliverable:** Completed SRS document with formal architectural diagrams.

---

### Day 22: Data Flow Diagrams & UML Behavioral Models
* **Primary Objective:** Complete formal behavioral models for the academic thesis report.
* **Tasks:**
  - [ ] **[D]** Finalize Data Flow Diagrams:
    - DFD Level 0 (Context Diagram)
    - DFD Level 1 (Decomposition of Auth, Complaint Engine, Admin Console, and Cron Daemon)
    - DFD Level 2 (Complaint Lifecycle & State Machine Transitions)
  - [ ] **[D]** Finalize UML Sequence Diagrams with timing bars and actor swimlanes.
* **Deliverable:** Complete DFD and UML behavioral diagram suite.

---

### Day 23: Test Case Execution Matrix & Screenshots Catalogue
* **Primary Objective:** Document exhaustive verification results and UI catalog.
* **Tasks:**
  - [ ] **[D]** Compile formal Test Case Matrix (minimum 35 test cases covering Unit, Integration, Security, and Boundary conditions).
  - [ ] **[D]** Capture clean, annotated device screenshots of every screen across Student, Authority, and Admin views.
* **Deliverable:** Formal testing report and comprehensive UI screenshot catalog.

---

### Day 24: Final Project Report Thesis & Presentation Deck
* **Primary Objective:** Assemble the final bound project report and presentation slides.
* **Tasks:**
  - [ ] **[D]** Assemble Final Project Report (Chapters: 1. Introduction, 2. Literature Survey, 3. Requirements Analysis, 4. System Design & Architecture, 5. Implementation Details, 6. Testing & Results, 7. Conclusion & Future Scope).
  - [ ] **[D]** Create professional 12-slide Viva Presentation Deck (PPT):
    1. Title & Candidate Details
    2. Problem Statement & Motivation
    3. Existing System vs. Proposed CampusVoice
    4. System Architecture & Tech Stack
    5. Database Design & Entity Relationship
    6. Finite State Machine Workflow
    7. Whistleblower Privacy Protocol
    8. Automated SLA Escalation Engine
    9. Administrative Analytics Dashboard
    10. Implementation Screenshots
    11. Testing & Validation Results
    12. Conclusion & Future Roadmap
* **Deliverable:** Complete, university-compliant major project thesis report and presentation deck.

---

### Day 25: Viva Voce Defense Rehearsal & Live Demonstration
* **Primary Objective:** Master project defense and execute flawless live demonstration.
* **Tasks:**
  - [ ] **[T]** Rehearse the 5-Minute Live Demo Script three times (see detailed script below).
  - [ ] **[T]** Review core Viva technical questions (Why Flutter, Why MongoDB, Stateless JWTs, Cryptographic Masking, SLA Cron logic).
  - [ ] **[S]** Warm up the Render cloud server 10 minutes prior to evaluation by pinging `/api/health`.
  - [ ] **[S]** Have release APK installed on physical device, web admin console open on laptop, and backup video ready.
* **Deliverable:** Successful project defense and major project completion!

---

## 🎭 5-Minute Live Viva Demonstration Script

Follow this exact chronological script during final project evaluation:

| Time | Action | Visual Screen | Key Talking Point for Examiners |
|---|---|---|---|
| **0:00 – 1:00** | **Student Lodging** | Log in as Student $\rightarrow$ Open New Complaint | *"Students report issues with photo proof in under 60 seconds. Notice the Category dropdown: selecting 'Hostel Maintenance' automatically assigns the ticket to the default hostel authority with a 2-day SLA."* |
| **1:00 – 1:45** | **Whistleblower Mode** | Submit second complaint with `Anonymous Mode = ON` | *"For sensitive matters like ragging or harassment, anonymous mode cryptographically strips student PII from all authority and admin views while preserving ticket integrity."* |
| **1:45 – 2:30** | **Authority Management** | Log in as Authority (Warden) $\rightarrow$ Open Queue | *"Authorities see only their assigned workload. The authority transitions the ticket to 'In Progress', documents an action remark, and marks it 'Resolved' upon repair completion."* |
| **2:30 – 3:15** | **Student Verification** | Switch to Student $\rightarrow$ View Notification $\rightarrow$ Feedback Dialog | *"Complaints cannot be prematurely closed by staff. The student must verify the repair and submit a 1–5 star rating, which formally moves the grievance to 'Closed'."* |
| **3:15 – 4:15** | **Admin Analytics** | Log in as Admin $\rightarrow$ View Dashboard | *"College management has real-time visibility into infrastructure health: volume breakdown, category distributions, monthly trends, and Mean Time to Resolution."* |
| **4:15 – 5:00** | **Automated SLA Escalation** | Admin All Complaints $\rightarrow$ Show Escalated Badge | *"If an authority fails to resolve an issue within the SLA turnaround window, the automated daily cron daemon flags the ticket as 'Escalated' and alerts executive leadership."* |

---

## ✂️ Scope Adjustment & Priority Cut-List

If development falls behind schedule, shed non-essential features in this strict order:

1. **Third-Party Push Notifications (FCM):** In-app notification inbox is 100% sufficient for all user flows.
2. **Monthly Historical Line Chart:** Retain core Pie and Bar distribution charts on the Admin Dashboard.
3. **Student Profile Photo Upload:** Retain user profile details without custom avatar upload.
4. **Complaint Reopen Flow:** A student can simply raise a fresh complaint if resolution was inadequate.
5. **Complex Text Search on Admin Table:** Rely on dropdown category and status filters.

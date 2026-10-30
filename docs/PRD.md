# Product Requirements Document (PRD)
## CampusVoice - College Complaint Management System

**Document Version:** 2.0  
**Status:** Approved for Implementation  
**Project Type:** Final Year Major Project (Engineering / Computer Science)  
**Target Delivery Window:** 25-Day Sprint  
**Target Platforms:** Android Mobile Application (Flutter/Dart SDK 3.x) & Node.js/Express REST Backend  
**Author:** Final Year Engineering Candidate  
**Academic Year:** 2025–2026  

---

## 1. Document Control & Revision History

| Version | Date | Author | Description of Changes |
|---|---|---|---|
| 1.0 | Initial Sprint | Student Developer | Initial basic draft of problem statement and core features. |
| 2.0 | Milestone Baseline | Student Developer | Comprehensive expansion: complete user personas, rigorous functional specifications, input validation schemas, edge case matrices, dynamic SLA logic, anonymous privacy protocols, Gherkin acceptance criteria, and viva evaluation defense guide. |

---

## 2. Executive Summary & Project Motivation

In modern university and collegiate environments, effective grievance redressal is a cornerstone of student welfare, campus safety, and operational efficiency. Academic campuses encompass diverse operational jurisdictions: student hostels, dining messes, academic lecture halls, research laboratories, library facilities, sanitation, security, and electrical/power infrastructure.

Despite the critical nature of these operations, contemporary grievance reporting in most academic institutions remains overwhelmingly archaic:
1. **Verbal Grievances:** Students complain to hostel wardens or laboratory assistants in passing; issues are frequently forgotten, misunderstood, or neglected.
2. **Paper-Based Register Entries:** Physical complaint registers kept in hostel lobbies or department offices are subject to damage, page tearing, illegible handwriting, and zero automated tracking.
3. **Unmoderated Social Messaging (WhatsApp/Telegram):** Informal messaging groups result in duplicated complaint reports, message clutter, absence of prioritized action, and an inability to maintain historical accountability.
4. **Administrative Blindspots:** College principals, deans, and management committees have zero empirical visibility into campus operational bottlenecks—e.g., how long it takes to repair a damaged lab projector, recurring water contamination in a specific hostel wing, or staff negligence.

**CampusVoice** solves this systemic institutional breakdown by delivering an automated, mobile-first, end-to-end grievance management platform. Built on Flutter and Node.js, the system standardizes complaint lodging, automates routing based on departmental jurisdiction, enforces accountability through strict Service Level Agreements (SLAs) with automated escalation, preserves student whistleblowing privacy, and delivers actionable analytical intelligence to campus leadership.

---

## 3. Problem Statement & Root Cause Analysis

### 3.1 Core Problem Statement
College campus constituents (students, teaching faculty, and administrative staff) lack a centralized, transparent, and auditable digital mechanism to report, monitor, and resolve campus infrastructure and academic grievances. This leads to extended downtime of campus facilities, student dissatisfaction, unaddressed safety hazards, and an absence of institutional accountability.

### 3.2 Root Cause Analysis Matrix

| Observed Pain Point | Institutional Root Cause | CampusVoice Technological Solution |
|---|---|---|
| **Lost or Ignored Complaints** | No persistent audit trail; verbal/chit submissions lack a unique reference ID. | Every complaint generates a sequential, immutable tracking identifier (e.g., `CMP-0042`) with real-time status history. |
| **Ambiguity in Ownership** | Students do not know which department or specific official is responsible for a given issue. | Category-driven auto-assignment routes issues directly to designated authority accounts upon submission. |
| **Indefinite Delays (No SLAs)** | Authorities have no deadline or performance benchmarks for resolving issues. | Strict SLA turnaround windows (e.g., 24h for Mess, 48h for Electrical) with automated daily cron escalation to senior management. |
| **Fear of Retaliation** | Students hesitate to report sensitive issues (harassment, ragging, hostel misconduct, faculty bias) due to lack of privacy. | Cryptographically isolated Anonymous Mode that completely masks student identities from authorities and admins while retaining complaint integrity. |
| **Lack of Quality Assurance** | Authorities mark complaints "done" without verification from the reporting student. | Strict two-phase resolution: status transitions to `Resolved`, but can only reach `Closed` after the student verifies and submits satisfaction feedback. |
| **Absence of Management Insights** | College administrators have no aggregated metrics on infrastructure performance. | Real-time interactive dashboard displaying complaint volumes, department-wise breakdowns, average resolution times, and escalation rates. |

---

## 4. Product Goals, Objectives & Success Metrics

### 4.1 Primary Objectives
1. **Sub-60-Second Grievance Submission:** Enable any registered student or staff member to report an issue with photo evidence, category, location, and priority in under 60 seconds.
2. **100% Deterministic Routing:** Guarantee that every submitted complaint is either auto-assigned to a default authority or flagged to the central administrator for immediate delegation.
3. **Enforced Accountability:** Ensure that 100% of complaints operate under an active SLA timer, with automated escalation alerts triggered upon SLA expiration.
4. **Complete Verification Loop:** Enforce student verification and rating on every resolved issue before permanent closure.
5. **Operational Intelligence:** Provide college management with real-time visualizations of resolution bottlenecks and department efficiency.

### 4.2 Non-Goals (Explicitly Out of Scope for Version 1.0)
To ensure reliable delivery within the 25-day development sprint, the following features are explicitly deferred to future releases:
* **Natural Language AI Auto-Categorization:** Complaints are categorized manually via structured dropdowns rather than automated NLP classification.
* **Computer Vision Duplicate Detection:** System does not perform automated image similarity analysis to group identical photos.
* **QR-Code Scan-to-Report Forms:** QR codes fixed to specific doors or equipment are deferred to v2.0.
* **Direct Real-Time Chat Engine:** Communication between students and authorities is handled via sequential, auditable remarks rather than continuous WebSocket chat.
* **Third-Party Push Notification Gateways (FCM/APNS):** System relies on an in-app persistent notification inbox; external cloud push notification services are optional add-ons if time permits.
* **Multi-Tenant SaaS Deployment:** Platform is tailored for a single college institution deployment.

### 4.3 Success Metrics & Evaluation Criteria

| Metric | Target Benchmark | Measurement Method |
|---|---|---|
| **Complaint Lodging Time** | $< 60$ seconds from app open | User testing timing from form open to 201 Created response |
| **Mean Time to Resolution (MTTR)** | $< 48$ hours average across standard categories | Computed on Admin Dashboard from `createdAt` to `resolvedAt` |
| **SLA Escalation Accuracy** | $100\%$ detection of overdue tickets | Automated daily cron execution verified via testing logs |
| **Anonymous Privacy Preservation** | Zero identity leakage in API responses | Security payload audits on `/api/complaints/:id` when `isAnonymous = true` |
| **API Response Latency** | $< 250$ ms on standard mobile network | Network profiling in Postman / Chrome DevTools |
| **Crash-Free Sessions** | $> 99\%$ | Flutter release APK testing across Android 8.0 through Android 14+ |

---

## 5. User Personas & Characteristics

### 5.1 Persona 1: The Student (Grievance Reporter)
* **Name:** Aarav Mehta
* **Profile:** 20 years old, 3rd Year B.Tech Computer Science student, residing in Campus Hostel Block B.
* **Context:** Aarav experiences frequent Wi-Fi outages in his hostel wing and periodic water supply disruptions. In the past, writing his name in the hostel register produced no results for two weeks.
* **Goals:**
  * Quickly submit an issue from his smartphone with photo proof without walking to the administrative block.
  * Receive notifications when the repair technician is assigned and working on it.
  * Report an incident of aggressive ragging in the hostel without revealing his identity to the warden.
* **Pain Points:** Busy academic schedule, frustration with unacknowledged complaints, fear of victimization if reporting sensitive issues.

### 5.2 Persona 2: The Authority (Department Head / Facility Technician)
* **Name:** Dr. Rajesh Sharma (Head of Department / Computer Labs In-Charge)
* **Profile:** 48 years old, manages 6 departmental computer labs, faculty computers, and networking gear.
* **Context:** Receives random phone calls and emails throughout the day from students and faculty reporting broken mice, failing UPS systems, and blue screens.
* **Goals:**
  * Have a single, organized mobile dashboard showing only the issues assigned to his jurisdiction.
  * Update the status of tasks once technicians complete repairs.
  * Leave clear remarks (e.g., "Motherboard sent for vendor warranty replacement; expected return Monday").
* **Pain Points:** Overwhelmed by duplicate verbal complaints; blamed by management for delays caused by external spare parts delivery.

### 5.3 Persona 3: The Administrator (Dean of Student Affairs / College Registrar)
* **Name:** Mrs. Sunita Verma
* **Profile:** 52 years old, Chief Administrative Officer responsible for campus-wide infrastructure and student satisfaction.
* **Context:** Needs oversight across all 12 campus departments. Currently receives complaints only when students escalate to protests or parents write angry emails to the Principal.
* **Goals:**
  * View real-time campus health metrics: how many complaints are open, resolved, or overdue.
  * Identify underperforming maintenance departments (e.g., electrical repairs taking 7 days instead of 2).
  * Receive automated alerts whenever a high-priority grievance breaches its SLA.
* **Pain Points:** Lack of centralized reporting; relying on filtered monthly reports prepared manually by department clerks.

---

## 6. Role-Based Access Control (RBAC) Matrix

The system enforces strict, declarative Role-Based Access Control across four operational entities:

| Action / Capability | Unauthenticated | Student | Authority | Administrator |
|---|:---:|:---:|:---:|:---:|
| Self-Registration (creates `student` role) | ✅ | ❌ | ❌ | ❌ |
| Email & Password Login | ✅ | ✅ | ✅ | ✅ |
| View Personal Profile & Change Password | ❌ | ✅ | ✅ | ✅ |
| Submit New Complaint | ❌ | ✅ | ❌ | ❌ |
| View Personal Submitted Complaints | ❌ | ✅ | ❌ | ❌ |
| View Assigned Complaints | ❌ | ❌ | ✅ | ❌ |
| View All Institutional Complaints | ❌ | ❌ | ❌ | ✅ |
| View Complaint Details (Public/Assigned/Owned) | ❌ | ✅ (Owned only) | ✅ (Assigned only) | ✅ (All) |
| View Student Identity on Anonymous Complaints | ❌ | ✅ (Owner sees self) | ❌ (Masked) | ❌ (Masked) |
| Update Complaint Status (`Assigned` $\rightarrow$ `In Progress` $\rightarrow$ `Resolved`) | ❌ | ❌ | ✅ | ✅ |
| Reopen Complaint (`Resolved` $\rightarrow$ `In Progress`) | ❌ | ✅ (Owner) | ❌ | ✅ |
| Submit Feedback & Star Rating | ❌ | ✅ (Owner only) | ❌ | ❌ |
| Add Remark to Complaint | ❌ | ✅ (Owner) | ✅ (Assigned) | ✅ |
| Assign / Reassign Authority to Complaint | ❌ | ❌ | ❌ | ✅ |
| Create / Edit / Deactivate Categories | ❌ | ❌ | ❌ | ✅ |
| Provision Authority & Staff Accounts | ❌ | ❌ | ❌ | ✅ |
| Activate / Deactivate User Accounts | ❌ | ❌ | ❌ | ✅ |
| View Institutional Analytics & Charts | ❌ | ❌ | ❌ | ✅ |
| View & Dismiss Notifications | ❌ | ✅ | ✅ | ✅ |

---

## 7. Comprehensive Functional Requirements (FR)

### Module 1: Authentication & Identity Management

* **FR-1.1: Student Self-Registration**
  * *Description:* Prospective student users can register directly from the mobile app.
  * *Inputs:* Full Name (string, 3–50 chars), Institutional Email Address (valid email format, unique in DB), Password (min 6 chars, containing at least 1 digit and 1 letter), Phone Number (10-digit format), Student Roll/ID Number.
  * *Business Rules:* Self-registration **strictly** assigns the `student` role. Accounts cannot assign themselves `authority` or `admin` roles.
  * *Success Response:* 201 Created with initial JWT token and sanitized user profile.
  * *Failure Responses:* 400 Bad Request (validation failure), 409 Conflict (email or student ID already registered).

* **FR-1.2: User Authentication (Login)**
  * *Description:* Registered users authenticate using their email and password.
  * *Inputs:* Email, Password.
  * *Security Protocol:* Passwords compared using bcrypt salt-hash. Deactivated accounts (`isActive: false`) are rejected with an explicit suspension message.
  * *Success Response:* 200 OK returning a signed JSON Web Token (JWT) with standard 7-day expiration, containing `{ id, role }`, and full user profile.
  * *Rate Limiting:* Maximum 5 failed login attempts per IP per 15-minute window before temporary lockout.

* **FR-1.3: User Profile & Security Settings**
  * *Description:* Authenticated users can retrieve their profile details, update their contact number, and change their password.
  * *Password Change Constraint:* Requires entry of `currentPassword` and `newPassword`. Current password must verify before updating to the new bcrypt hash.

* **FR-1.4: Administrative User Management**
  * *Description:* Administrators can list all registered users (with role and status filters), create new `authority` staff accounts, and toggle user active status (`isActive: true/false`).
  * *Constraint:* Admin accounts cannot deactivate themselves.

---

### Module 2: Grievance / Complaint Management

* **FR-2.1: Complaint Submission**
  * *Description:* Students can lodge an infrastructure or operational grievance.
  * *Required Inputs:*
    * `title`: String (min 5, max 100 characters). Concise summary of the issue.
    * `description`: String (min 20, max 1000 characters). Full context and specifics.
    * `category`: ObjectId referencing an active `Category`.
    * `location`: String (e.g., "Hostel 3, Room 214" or "Main Building, 2nd Floor Lab 4").
    * `priority`: Enum: `Low`, `Medium`, `High`, `Urgent`.
  * *Optional Inputs:*
    * `isAnonymous`: Boolean (Default: `false`).
    * `images`: Multipart file upload containing 0 to 3 images (JPEG/PNG, max 5 MB each).
  * *System Side-Effects:*
    * Generates sequential readable ID: `CMP-XXXX` (using atomic counters).
    * Sets initial status to `Submitted`.
    * If selected Category has an active `defaultAuthority`: Automatically assigns `assignedTo = category.defaultAuthority`, updates status to `Assigned`, and calculates `dueDate = Date.now() + (category.slaDays * 24 * 60 * 60 * 1000)`.
    * Creates a corresponding Notification for the assigned authority (or admin if unassigned).
  * *Success Response:* 201 Created with full complaint object.

* **FR-2.2: Anonymous Whistleblowing Privacy Protocol**
  * *Description:* Students reporting sensitive matters can activate `isAnonymous: true`.
  * *Data Isolation Specification:* The underlying database document securely records `createdBy` (to prevent spam, allow student self-tracking, and enforce single feedback). However, any API endpoint responding to an Authority or Administrator (`GET /complaints`, `GET /complaints/:id`) dynamically scrubs the `createdBy` object, replacing it with `{ name: "Anonymous Student", email: null, phone: null, studentId: null }`.
  * *Integrity Rule:* The student who created the anonymous complaint can always view their own identity on their own device.

* **FR-2.3: Complaint Retrieval & Role-Based Filtering**
  * *Student Scope (`GET /api/complaints/my`):* Returns only complaints where `createdBy == req.user.id`. Supports filter by `status` and pagination (`page`, `limit`).
  * *Authority Scope (`GET /api/complaints/assigned`):* Returns only complaints where `assignedTo == req.user.id`. Supports filter by `status` and `priority`.
  * *Admin Scope (`GET /api/complaints`):* Returns all institutional complaints. Supports multi-faceted search (by `complaintId`, `title`, `location`), category filter, priority filter, escalation filter (`isEscalated: true`), and pagination.

* **FR-2.4: Complaint Detail View**
  * *Description:* Provides comprehensive metadata for a specific complaint, including complete chronological remarks, photo evidence gallery, SLA due date, and feedback status.

---

### Module 3: Grievance Lifecycle & Workflow Engine

* **FR-3.1: Strict Finite State Machine**
  * Complaints progress through a finite set of validated status states:
    $$\text{Submitted} \longrightarrow \text{Assigned} \longrightarrow \text{In Progress} \longrightarrow \text{Resolved} \longrightarrow \text{Closed}$$
  * *Illegal Transitions:* Any status transition that violates the forward flow (e.g., attempting to jump from `Submitted` directly to `Resolved` without being `Assigned`, or updating a `Closed` complaint) is rejected by the server with `400 Bad Request`.

| Current Status | Allowed Next Statuses | Authorized Roles | Mandatory Requirements |
|---|---|---|---|
| **Submitted** | `Assigned` | Admin (or System Auto-Assign) | Must provide valid `assignedTo` authority ID. Sets `dueDate`. |
| **Assigned** | `In Progress`, `Assigned` (Reassign) | Assigned Authority, Admin | Authority acknowledges issue. |
| **In Progress** | `Resolved` | Assigned Authority, Admin | Authority must provide an action remark detailing resolution. Sets `resolvedAt`. |
| **Resolved** | `Closed`, `In Progress` (Reopened) | Student (Owner), Admin | Student submitting feedback moves to `Closed`. Student dissatisfaction reopens to `In Progress`. |
| **Closed** | *Terminal State* (None) | None | Immutable. No further edits permitted. |

* **FR-3.2: Assignment & SLA Due Date Calculation**
  * When a complaint is assigned (either automatically upon creation or manually by an admin via `PATCH /complaints/:id/assign`), the server computes:
    $$\text{dueDate} = \text{currentTime} + (\text{category.slaDays} \times 86,400,000 \text{ ms})$$
  * An in-app notification is dispatched to the assigned authority.

* **FR-3.3: Reopening Grievances**
  * If a student finds that a `Resolved` issue was inadequately fixed (e.g., electrician left without verifying the circuit breaker), the student can trigger a Reopen action within 48 hours of resolution.
  * Moves status from `Resolved` back to `In Progress`, appends a student remark, and resets the resolution timestamp.

---

### Module 4: Remarks, Interaction & Timeline Audit Trail

* **FR-4.1: Chronological Action Remarks**
  * *Description:* Authorized participants (Complaint Owner, Assigned Authority, Administrator) can append remarks to an active complaint.
  * *Payload:* `text` (String, min 2, max 500 characters).
  * *Storage:* Embedded subdocument array inside the Complaint document containing `{ user: ObjectId, role: String, text: String, createdAt: Date }`.
  * *Notifications:* Appending a remark generates an automatic notification to the counter-party (e.g., student remark notifies authority; authority remark notifies student).

---

### Module 5: Resolution, Rating & Quality Feedback

* **FR-5.1: Student Feedback & Star Rating**
  * *Description:* Once an issue reaches `Resolved` status, the reporting student is prompted to rate the resolution quality.
  * *Inputs:*
    * `rating`: Integer from 1 (Very Dissatisfied) to 5 (Extremely Satisfied).
    * `comment`: String (Optional, max 300 characters).
  * *Constraints:*
    * Feedback can **only** be submitted if `status == 'Resolved'`.
    * Feedback can **only** be submitted once per complaint.
    * Only the original complaint creator (`createdBy`) is authorized to submit feedback.
  * *State Effect:* Submitting feedback immediately transitions the complaint status to `Closed` and records `closedAt = Date.now()`.
  * *Notification:* Alerts the assigned authority of the student's rating and review.

---

### Module 6: SLA Escalation & Automated Daily Cron

* **FR-6.1: Automated SLA Monitoring Daemon**
  * *Description:* A scheduled background worker powered by `node-cron` executes daily at midnight (`0 0 * * *`) (or at configured test intervals).
  * *Algorithm:*
    1. Query all complaints matching:
       $$\text{status} \notin \{\text{Resolved}, \text{Closed}\} \quad \land \quad \text{dueDate} < \text{Date.now()} \quad \land \quad \text{isEscalated} == \text{false}$$
    2. For each matching overdue complaint:
       * Set `isEscalated = true`.
       * Set `escalatedAt = Date.now()`.
       * Generate high-priority Notification records for all active Administrator accounts detailing the breach.
    3. Log total processed escalations to standard output and server audit logs.

---

### Module 7: Administrative Intelligence & Governance

* **FR-7.1: Category Governance**
  * *Description:* Admins can create new grievance categories (e.g., "Air Conditioning", "Library Services", "Hostel Mess"), specify default assigned authorities, define SLA days (1 to 30 days), and toggle active/inactive status.
  * *Deactivation Safety:* Deactivating a category hides it from student submission dropdowns but preserves historical records referencing that category.

* **FR-7.2: Executive Analytics Dashboard**
  * *Description:* Real-time data aggregation endpoints providing metrics for the admin interface:
    * **Metric Summary Cards:** Total Complaints, Open Issues (`Submitted` + `Assigned` + `In Progress`), Resolved Count, Overdue / Escalated Count.
    * **Distribution by Category:** Aggregated complaint count per category for doughnut/pie charts.
    * **Status Distribution:** Breakdown of complaints across all 5 status lifecycle states.
    * **Monthly Lodging Trend:** 6-month historical line chart of grievance volume over time.
    * **Mean Time to Resolution (MTTR):** Average elapsed hours between `createdAt` and `resolvedAt` grouped by category.

---

### Module 8: Notification & Communication System

* **FR-8.1: In-App Notification Center**
  * *Description:* Persistent notification inbox for every user role.
  * *Event Triggers:*
    * Complaint successfully assigned (notifies authority).
    * Complaint status changed (notifies student).
    * New remark added (notifies owner/assigned authority).
    * Resolution feedback submitted (notifies authority).
    * SLA breach escalation (notifies admin).
  * *User Controls:* View list sorted by latest, mark single notification as read, mark all notifications as read.

---

## 8. Non-Functional Requirements (NFRs)

### 8.1 Security & Data Integrity
* **Password Cryptography:** All passwords hashed with salted bcrypt (cost factor: 10 rounds). Passwords are never returned in database queries (`select: false`).
* **Stateless JWT Authorization:** API routes protected using Bearer JWT tokens signed with HMAC-SHA256. Tokens expire in 7 days.
* **Role-Based Guards:** Express middleware intercepts all requests, decoding the JWT and enforcing role checks (`authorize('admin')`, `authorize('authority', 'admin')`).
* **Input Sanitization & Injection Defense:** Every incoming request body and parameter is validated and sanitized via `express-validator` to prevent NoSQL injection, XSS vectors, and malformed types.
* **Secure Media Uploads:** File uploads restricted strictly to `image/jpeg` and `image/png`. Max file size hard-capped at 5 MB. Image binaries are uploaded directly to Cloudinary via memory streams; local temporary files are immediately destroyed.
* **API Hardening:** Standard HTTP security headers enforced via `helmet`. CORS restricted to authorized domains/mobile origins.

### 8.2 Performance & Scalability
* **Response Benchmarks:** All standard read/write REST endpoints must respond in under 200 ms under normal network conditions.
* **Efficient Pagination:** All collection listing endpoints (`/complaints`, `/users`, `/notifications`) enforce default pagination (10 items/page, max 50) using MongoDB compound indexes.
* **Database Indexing:** Compound indexes on `Complaint` collection (`{ createdBy: 1, status: 1 }`, `{ assignedTo: 1, status: 1 }`, `{ dueDate: 1, isEscalated: 1 }`, `{ complaintId: 1 }`).
* **Client-Side Image Optimization:** Flutter client compresses captured photos before multipart transmission, reducing network payload from ~8 MB raw to < 800 KB per photo.

### 8.3 Usability & Mobile Ergonomics
* **Design System:** Material Design 3 guidelines throughout the Flutter mobile client.
* **Touch Targets:** All interactive touch elements (buttons, chips, icon toggles) conform to minimum 48x48 dp touch targets.
* **State Feedback:** Comprehensive loading skeletons, error banners with retry buttons, and friendly empty-state illustrations across all lists.
* **Color Contrast:** Conforms to WCAG 2.1 Level AA color contrast ratios for text and status indicators.

---

## 9. Comprehensive Screen Specifications

| Screen Name | Target Role | Key Components & UI Controls | Navigation & Actions |
|---|---|---|---|
| **Splash Screen** | All | App logo animation, version indicator, loading spinner. | Checks token in `flutter_secure_storage`; auto-routes to Student Home, Authority Queue, or Admin Dashboard; otherwise navigates to Login. |
| **Login Screen** | All | College branding, Email field, Password field (with visibility toggle), "Sign In" button, "Register as Student" link. | Authenticates via `POST /api/auth/login`; persists JWT; routes based on `user.role`. |
| **Register Screen** | Student | Name, Email, Password, Confirm Password, Phone, Student ID fields, "Create Account" button. | Validates fields locally; submits to `POST /api/auth/register`; auto-logs in upon creation. |
| **Student Home** | Student | Welcome banner, quick-action card "Raise New Complaint", recent complaints summary list, notification badge. | Tap "Raise" opens New Complaint; tap list item opens Complaint Detail. |
| **New Complaint** | Student | Title input, Description multi-line input, Category dropdown (fetched from API), Location field, Priority segmented button, Anonymous switch, Image picker preview grid (up to 3 images with delete buttons), Submit button. | Multipart `POST /api/complaints`; shows progress dialog; clears form and routes to My Complaints on success. |
| **My Complaints** | Student | Filter chip row (`All`, `Submitted`, `Assigned`, `In Progress`, `Resolved`, `Closed`), pull-to-refresh list of `ComplaintCard` widgets, floating action button for new complaint. | Queries `GET /api/complaints/my?status=...`; tap card opens Detail; empty state when no records. |
| **Complaint Detail** | All (Role-aware) | Status badge, Complaint ID, Category badge, Priority chip, Anonymous tag, Location banner, Description block, Photo carousel with tap-to-expand modal, Chronological remarks timeline, Bottom action bar. | **Student:** Shows "Give Feedback" if `Resolved`.<br>**Authority:** Shows "Update Status" button.<br>**Admin:** Shows "Reassign" button. |
| **Feedback Dialog** | Student | 5-star interactive rating bar, comment input box, "Submit Review" button. | Submits `POST /complaints/:id/feedback`; updates status to `Closed`; refreshes parent detail. |
| **Authority Queue** | Authority | Status filter tabs (`Assigned`, `In Progress`, `Resolved`), sort by priority toggle, list of assigned complaint cards showing remaining SLA countdown. | Queries `GET /api/complaints/assigned`; tap opens Detail view with status update capabilities. |
| **Status Update Sheet** | Authority / Admin | Next valid status radio options, mandatory action remark text field, "Confirm Update" button. | Validates state progression; executes `PATCH /complaints/:id/status`; triggers student notification. |
| **Admin Dashboard** | Admin | 4 KPI summary cards (Total, Open, Resolved, Escalated), Category breakdown pie chart, Priority bar chart, 6-Month trend line chart, Quick shortcut buttons. | Queries `GET /api/dashboard/*`; displays interactive `fl_chart` widgets. |
| **All Complaints** | Admin | Search bar (by ID or text), Category dropdown filter, Priority filter, Escalation switch toggle, Paginated complaint table/list. | Queries `GET /api/complaints`; full admin override capabilities. |
| **Assign Dialog** | Admin | Authority staff dropdown list (filtered by department), optional assignment note, "Confirm Assign" button. | Executes `PATCH /complaints/:id/assign`; sets new `dueDate`; updates timeline. |
| **Manage Categories** | Admin | List of existing categories with status toggles and SLA days; Floating button to "Add Category"; Edit category dialog. | CRUD operations on `/api/categories`. |
| **Manage Users** | Admin | Role filter tabs (`Authorities`, `Students`), list of users with active toggles; "Add Authority" dialog (Name, Email, Department, Password). | Administrative control via `/api/users`. |
| **Notifications** | All | Chronological list of notification items with unread dot indicators; "Mark All as Read" header button. | Queries `GET /api/notifications`; tap marks item read and navigates to relevant complaint detail. |
| **User Profile** | All | User avatar, Name, Email, Role badge, Phone, "Change Password" expandable tile, "Sign Out" button. | Updates user details; Sign Out clears secure storage and navigates to Login. |

---

## 10. Formal Acceptance Criteria (Gherkin Syntax)

### Scenario 1: Successful Complaint Lodging with Photo Proof
```gherkin
Feature: Student Grievance Submission
  As an authenticated student
  I want to submit an infrastructure complaint with photo proof
  So that the responsible college authority can repair the issue

  Scenario: Submitting a valid complaint with category and photo
    Given I am authenticated with role "student"
    And I am on the "New Complaint" screen
    When I enter "Water leakage in Room 302" into the "Title" field
    And I enter "Continuous water leakage from ceiling pipe causing damage to desks" into "Description"
    And I select "Hostel Maintenance" from the "Category" dropdown
    And I enter "Hostel Block A, 3rd Floor, Room 302" into "Location"
    And I select "High" for "Priority"
    And I attach 2 valid JPEG photos from the gallery
    And I tap the "Submit Complaint" button
    Then the client should upload the images via multipart request
    And the server should respond with HTTP status 201 Created
    And the complaint should be assigned a human-readable ID matching "CMP-[0-9]{4}"
    And the complaint status should be "Assigned" because the category has a default authority
    And the due date should be set to 2 days from the current timestamp
    And the assigned hostel warden should receive an in-app assignment notification
```

### Scenario 2: Enforcing Whistleblower Privacy on Anonymous Complaints
```gherkin
Feature: Anonymous Whistleblower Privacy Protection
  As a student reporting a sensitive grievance
  I want to toggle anonymous mode
  So that neither authorities nor administrators can see my identity

  Scenario: Authority viewing an anonymous complaint
    Given a student submitted a complaint with "isAnonymous = true"
    And the complaint ID is "CMP-0089"
    When an authority logs in and requests "GET /api/complaints/CMP-0089"
    Then the server response should include HTTP status 200 OK
    And the "createdBy" object must NOT contain the student's email, phone number, or roll number
    And the "createdBy.name" field must equal "Anonymous Student"
    And the complaint details, photos, and remarks must remain visible
```

### Scenario 3: Preventing Illegal Status Transitions
```gherkin
Feature: Finite State Machine Integrity
  As an authority or administrator
  I must only transition complaints through valid sequential lifecycle states

  Scenario: Authority attempts to jump directly from Submitted to Resolved
    Given a complaint exists with status "Submitted"
    When an authority sends "PATCH /api/complaints/:id/status" with status "Resolved"
    Then the server should reject the request with HTTP status 400 Bad Request
    And the error message should state "Invalid status transition from Submitted to Resolved"
    And the complaint status in the database must remain "Submitted"
```

### Scenario 4: SLA Breach Daily Automated Escalation
```gherkin
Feature: Automated SLA Escalation Engine
  As a college administrator
  I want overdue complaints to automatically escalate
  So that delayed repairs are brought to executive attention

  Scenario: Daily cron job identifies breached SLA
    Given a complaint with status "In Progress" and "dueDate" set to yesterday
    And the complaint has "isEscalated = false"
    When the scheduled cron daemon executes at midnight "0 0 * * *"
    Then the system should update the complaint record setting "isEscalated = true"
    And the "escalatedAt" timestamp should be recorded as the execution time
    And an in-app notification with type "ESCALATION" should be created for all active Admin users
```

---

## 11. Edge Cases & Failure Recovery Protocols

| Category | Potential Failure Scenario | System Prevention & Recovery Protocol |
|---|---|---|
| **Network Failure** | Student device loses cellular connectivity halfway through uploading 3 large photos. | Dio client utilizes chunked streaming with a 30-second connection timeout. If connection drops, the app catches `DioException.connectionTimeout`, aborts the request, displays a snackbar: *"Network interrupted. Please check your internet and retry"*, and preserves the student's typed text in form state. |
| **Concurrency Conflict** | Two administrators simultaneously attempt to reassign the same complaint to different authorities. | MongoDB executes atomic `findOneAndUpdate` with query condition `{ _id: id, status: { $ne: 'Closed' } }`. The last committed update wins, and both actions append timestamped audit remarks documenting each change. |
| **Token Expiry During Form Entry** | Student spends 15 minutes typing a detailed description; their 7-day JWT token expires while filling the form. | Flutter `Dio` interceptor catches HTTP 401 Unauthorized, securely stores the draft form state in memory, presents a quick re-authentication dialog, refreshes the JWT in `flutter_secure_storage`, and resumes submission without data loss. |
| **Deactivated Category Selection** | An admin deactivates a category while a student has the complaint form open with that category preloaded. | Backend validation middleware performs an explicit database check: `Category.findOne({ _id: req.body.category, isActive: true })`. If the category was deactivated, server responds with `400 Bad Request ("Selected category is no longer active")`. |
| **Cloudinary Outage** | Cloudinary media upload service is temporarily unreachable or API quota exceeded. | Backend multer-cloudinary middleware catches upload exception, falls back to a graceful error `503 Service Unavailable ("Photo storage currently unavailable; please submit without photos or retry later")`, preventing server crash. |

---

## 12. Academic Viva & Evaluation Defense Guide

During the major project final evaluation, viva voce examiners assess theoretical comprehension, architectural decisions, and code craftsmanship. Below are the definitive technical defenses:

### Q1: Why choose a NoSQL Document Database (MongoDB) over a Relational RDBMS (PostgreSQL/MySQL)?
* **Answer:** While relational databases excel at rigid tabular schemas, a modern grievance tracking platform requires dynamic, nested document structures. A `Complaint` document naturally encapsulates variable-length arrays: chronological `remarks` (each with user refs, roles, timestamps), dynamic arrays of image URLs, polymorphic `feedback` objects, and evolving category attributes. In an RDBMS, retrieving a single complaint detail screen would require joining across 5 separate tables (`complaints`, `complaint_images`, `remarks`, `users`, `feedback`). In MongoDB, the entire aggregate is retrieved in a single indexed read operation $O(1)$, dramatically reducing server latency and query complexity.

### Q2: Why implement a custom JWT architecture instead of Firebase Authentication?
* **Answer:** While Firebase Auth provides rapid turn-key authentication, it introduces vendor lock-in, lacks on-premise institutional data governance, and makes custom Role-Based Access Control (RBAC) with database-driven authority assignments clunky. Implementing custom stateless JWTs with HMAC-SHA256 and bcrypt salted hashing provides complete ownership of institutional credentials, seamless integration with our Node.js middleware pipeline, zero recurring costs, and direct academic demonstration of network security principles.

### Q3: How do you prevent an authority from inspecting the database or network traffic to deanonymize a student?
* **Answer:** At the network level, all mobile traffic is secured using TLS/HTTPS. At the application layer, the controller sanitizes the JSON response payload before it leaves the Node.js process: if `isAnonymous == true` and `req.user.role != 'student'`, the `createdBy` object is stripped of all personally identifiable information (PII). Authorities never receive the student's ID or email over the wire. Within the database, institutional access controls restrict direct MongoDB access solely to the backend application connection string.

### Q4: What state management pattern is utilized in Flutter and why?
* **Answer:** The application adopts the **Provider** (ChangeNotifier) architectural pattern. Provider offers clean separation between presentation widgets and business logic, conforms strictly to Flutter's unidirectional data flow, avoids the boilerplate complexity of BLoC/Redux for a 25-day development timeline, and simplifies testing and debugging through clean reactive notifications (`notifyListeners()`).

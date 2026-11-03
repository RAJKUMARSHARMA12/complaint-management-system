# CampusVoice Data Flow Diagrams (DFD)

This document details the **Level 0 (Context Level)** and **Level 1 (Detailed)** Data Flow Diagrams for the **CampusVoice Grievance Redressal and Campus Issue Reporting System**.

---

## 1. Level 0: Context Analysis Diagram

The Level 0 Context Diagram abstracts the entire CampusVoice platform as a single centralized process, showing interactions with the primary external entities: **Students**, **Department Authorities**, and **System Administrators**.

```mermaid
flowchart TD
    %% External Entities
    S["Student"]
    A["Authority / Department Staff"]
    ADM["System Administrator"]

    %% Central Process
    CV(("CampusVoice System (0.0)"))

    %% External Inputs & Outputs: Student
    S -->|"Registration & Login Credentials"| CV
    S -->|"Grievance Submission (Title, Description, Category, Images, Whistleblower Flag)"| CV
    S -->|"Follow-up Remarks / Inquiries"| CV
    S -->|"Satisfaction Rating & Closure Feedback"| CV
    CV -->|"Auth Tokens & Profile Info"| S
    CV -->|"Complaint ID & Status Tracking Updates"| S
    CV -->|"In-App Notifications (Assignment, Remarks, Status)"| S

    %% External Inputs & Outputs: Authority
    A -->|"Staff Login Credentials"| CV
    A -->|"Status Updates (Assigned -> In Progress -> Resolved)"| CV
    A -->|"Investigation Remarks & Proof"| CV
    CV -->|"Assigned Queue & Department Tickets"| A
    CV -->|"Real-time Alerts & Escalation Warnings"| A

    %% External Inputs & Outputs: Admin
    ADM -->|"Administrative Credentials"| CV
    ADM -->|"Department & Category Management"| CV
    ADM -->|"Ticket Delegation & Reassignment"| CV
    ADM -->|"SLA Config & System Escalations"| CV
    CV -->|"Campus-wide Analytics, KPI Metrics & Audit Logs"| ADM
```

---

## 2. Level 1: Detailed Functional Data Flow Diagram

The Level 1 DFD decomposes the system into core operational sub-processes:
1. **1.0 Authentication & Identity Management**
2. **2.0 Grievance Lodging & Whistleblower Engine**
3. **3.0 Assignment, SLA Tracking & Authority Workflow**
4. **4.0 Communication & Remarks Timeline**
5. **5.0 Resolution Verification & Feedback Loop**
6. **6.0 Notification Subsystem**

```mermaid
flowchart TD
    %% External Entities
    Student["Student"]
    Authority["Authority"]
    Admin["System Administrator"]

    %% Data Stores
    D1[("D1: Users & Auth Store")]
    D2[("D2: Categories & SLA Config")]
    D3[("D3: Complaints Store")]
    D4[("D4: Remarks & Activity Store")]
    D5[("D5: Notifications Store")]

    %% Processes
    P1(("1.0 Authentication & Access Control"))
    P2(("2.0 Grievance Lodging & Whistleblower Engine"))
    P3(("3.0 Assignment & Workflow State Engine"))
    P4(("4.0 Remarks & Timeline Management"))
    P5(("5.0 Verification & Feedback Loop"))
    P6(("6.0 Notification Subsystem"))

    %% Authentication Flow
    Student -->|"Credentials (Register / Login)"| P1
    Authority -->|"Credentials (Login)"| P1
    Admin -->|"Credentials (Login)"| P1
    P1 <-->|"Verify & Persist Credentials / Hash / Role"| D1
    P1 -->|"Issue JWT Bearer Token"| Student
    P1 -->|"Issue JWT Bearer Token"| Authority
    P1 -->|"Issue JWT Bearer Token"| Admin

    %% Grievance Lodging
    Student -->|"Submit Grievance (Category, Title, Media, Anon Flag)"| P2
    P2 <-->|"Fetch Category SLA Days & Routing Rules"| D2
    P2 -->|"Scrub Identity (if Anonymous) & Store Complaint"| D3
    P2 -->|"Trigger Grievance Lodged Event"| P6
    P2 -->|"Return Sequential CMP ID"| Student

    %% Assignment & State Transitions
    Admin -->|"Manual Reassign / Delegate"| P3
    Authority -->|"Update Status (In Progress, Resolved)"| P3
    P3 <-->|"Fetch & Update Complaint Status History / SLA Due Date"| D3
    P3 -->|"Trigger Status Change / Assignment Event"| P6
    P3 -->|"Provide Filtered Ticket Queue"| Authority
    P3 -->|"Provide Analytics & Master Queue"| Admin

    %% Remarks & Communication
    Student -->|"Post Follow-up Remark"| P4
    Authority -->|"Post Work Status Remark"| P4
    P4 -->|"Append Chronological Remark Record"| D4
    P4 <-->|"Read & Populate Remarks Timeline"| D3
    P4 -->|"Trigger New Remark Event"| P6
    D4 -->|"Stream Activity Feed"| Student
    D4 -->|"Stream Activity Feed"| Authority

    %% Feedback & Closure
    Student -->|"Submit 1-5 Star Rating & Comments"| P5
    P5 <-->|"Validate Status == Resolved & Update to Closed"| D3
    P5 -->|"Trigger Ticket Closed Event"| P6
    P5 -->|"Acknowledge Closure"| Student

    %% Notification Subsystem
    P6 -->|"Insert Notification (Type, Recipient, Complaint Ref)"| D5
    D5 -->|"Fetch Unread Inbox & Badge Count"| P6
    P6 -->|"Deliver In-App Notifications"| Student
    P6 -->|"Deliver In-App Notifications"| Authority
    Student -->|"Mark Read / Read All"| P6
    P6 -->|"Update isRead Status"| D5
```

---

## 3. Data Dictionary for Core Flows

| Data Flow Item | Source | Destination | Content Description |
| :--- | :--- | :--- | :--- |
| **Grievance Payload** | Student | Process 2.0 | `title`, `description`, `category_id`, `location`, `priority`, `isAnonymous`, `images[]` |
| **Whistleblower Scrubbed Ticket** | Process 2.0 | Data Store D3 | Stored with `isAnonymous: true`; creator info masked as "Anonymous Student" upon query |
| **Status Transition** | Authority / Admin | Process 3.0 | `status` (`Assigned`, `In Progress`, `Resolved`), `remarks`, timestamp |
| **Remark Item** | Student / Authority | Process 4.0 | `complaintId`, `text`, `user` (id, name, role), `createdAt` |
| **Resolution Feedback** | Student | Process 5.0 | `rating` (1–5 integer), `comments` (optional text), transitions ticket status to `Closed` |
| **Notification Payload** | Process 6.0 | Student / Authority | `recipient`, `title`, `message`, `type` (`ASSIGNMENT`, `STATUS_CHANGE`, `REMARK`, `FEEDBACK`), `relatedComplaint` |

# 🔄 CampusVoice: UML Sequence Diagrams

This document specifies the formal **UML Sequence Diagrams** for the core workflows of the *CampusVoice* grievance and redressal system. It details the chronological exchange of messages between actors, Flutter mobile components, Express.js microservices, database transactions, cloud storage, and notification hooks.

---

## 📑 Table of Contents
1. [Sequence Diagram 1: Grievance Lodging & Auto-Assignment Flow](#1-grievance-lodging--auto-assignment-flow)
2. [Sequence Diagram 2: Status Update, Delegation & Collaborative Remarks Flow](#2-status-update-delegation--collaborative-remarks-flow)
3. [Sequence Diagram 3: SLA Breach Monitoring & Automated Escalation Flow](#3-sla-breach-monitoring--automated-escalation-flow)
4. [Sequence Diagram 4: Student Feedback & Terminal Closure Flow](#4-student-feedback--terminal-closure-flow)

---

## 1. Grievance Lodging & Auto-Assignment Flow

This sequence illustrates a student filing a complaint with photo evidence, selective anonymity, automated SLA calculation, Cloudinary image upload, and intelligent routing based on Category default authority.

```mermaid
sequenceDiagram
    autonumber
    actor Student as Student (Mobile App)
    participant UI as NewComplaintScreen
    participant Prov as ComplaintProvider
    participant Net as ApiClient (Dio)
    participant CDN as Cloudinary Storage
    participant API as Express Router / Validator
    participant Ctrl as ComplaintController
    participant DB as MongoDB
    participant Notif as NotificationSubsystem
    actor Auth as Authority / Admin

    Student->>UI: Enter title, description, location, priority
    Student->>UI: Attach photos (Camera/Gallery)
    Student->>UI: Toggle Whistleblower Mode (Optional)
    Student->>UI: Tap "Submit Complaint"
    
    UI->>Prov: submitComplaint(payload, imagePaths)
    Prov->>Net: POST /api/complaints (multipart/form-data)
    
    Net->>API: Bearer Token + FormData
    API->>API: Verify JWT & Validate Fields
    alt Form Validation Fails
        API-->>Net: 400 Bad Request (Validation Errors)
        Net-->>Prov: Error Response
        Prov-->>UI: Display Field Error Banners
    else Form Validation Passes
        API->>CDN: Upload Images Stream
        CDN-->>API: Return Secure Image URLs (CDN)
        API->>Ctrl: createComplaint(req, res)
        
        Ctrl->>DB: Category.findById(categoryId)
        DB-->>Ctrl: Category (slaDays, defaultAuthority)
        
        alt Category has defaultAuthority
            Ctrl->>Ctrl: status = "Assigned", assignedTo = defaultAuthority
            Ctrl->>Ctrl: dueDate = now + (slaDays * 24h)
        else No defaultAuthority
            Ctrl->>Ctrl: status = "Submitted", assignedTo = null
            Ctrl->>Ctrl: dueDate = null
        end
        
        Ctrl->>DB: Complaint.create(complaintData)
        DB-->>Ctrl: Saved Complaint (CMP-XXXX)
        
        Ctrl->>Notif: createNotification(ASSIGNMENT / LODGED)
        Notif->>DB: Notification.create(...)
        Notif-->>Auth: Dispatch Push Notification / Inbox Alert
        
        Ctrl-->>Net: 201 Created { success: true, complaint }
        Net-->>Prov: Parse ComplaintModel
        Prov-->>UI: Navigate to Confirmation / My Complaints
        UI-->>Student: Display Success SnackBar & Ticket ID
    end
```

---

## 2. Status Update, Delegation & Collaborative Remarks Flow

This sequence details administrative delegation and authority lifecycle execution (`Assigned` $\rightarrow$ `In Progress` $\rightarrow$ `Resolved`), FSM transition validation, and threaded remarks.

```mermaid
sequenceDiagram
    autonumber
    actor Admin as Admin / Authority
    participant AdminUI as AdminConsole / AuthorityScreen
    participant Sheet as StatusUpdateBottomSheet
    participant Prov as ComplaintProvider
    participant API as ComplaintRoutes
    participant Ctrl as ComplaintController
    participant FSM as FSM Transition Guard
    participant DB as MongoDB
    participant Notif as NotificationSubsystem
    actor Student as Student (Grievant)

    Admin->>AdminUI: Select Ticket from Queue
    alt Admin Delegates Ticket
        Admin->>AdminUI: Tap "Assign / Reassign"
        AdminUI->>Prov: fetchAuthorityStaff()
        Prov-->>AdminUI: Authority Staff List
        Admin->>AdminUI: Select Staff & Enter Remark
        AdminUI->>Prov: assignComplaint(id, authorityId, remark)
        Prov->>API: PATCH /api/complaints/:id/assign
        API->>Ctrl: assignComplaint(...)
        Ctrl->>DB: Update assignedTo, status="Assigned", set dueDate
        Ctrl->>Notif: Notify Authority & Student
        Ctrl-->>AdminUI: 200 OK (Assigned)
    else Authority Updates Status
        Admin->>AdminUI: Tap "Update Status"
        AdminUI->>Sheet: Open Bottom Sheet (currentStatus)
        Sheet->>Prov: getAllowedTransitions(currentStatus)
        Prov-->>Sheet: Allowed States (e.g., In Progress, Resolved)
        Admin->>Sheet: Select Next Status & Enter Action Remark
        Admin->>Sheet: Tap "Confirm Transition"
        Sheet->>Prov: updateComplaintStatus(id, nextStatus, remark)
        Prov->>API: PATCH /api/complaints/:id/status
        API->>Ctrl: updateStatus(...)
        Ctrl->>FSM: Validate Transition against Matrix
        alt Illegal Transition Attempted
            FSM-->>Ctrl: Invalid Transition (e.g. Assigned -> Resolved)
            Ctrl-->>Sheet: 400 Bad Request (Illegal FSM Transition)
            Sheet-->>Admin: Show Error Notice
        else Legal Transition
            FSM-->>Ctrl: Transition Permitted
            Ctrl->>DB: Update status, append remark, record resolvedAt
            DB-->>Ctrl: Updated Complaint
            Ctrl->>Notif: dispatch STATUS_CHANGE Alert
            Notif-->>Student: Push Notification: "Status moved to [nextStatus]"
            Ctrl-->>Prov: 200 OK (Status Updated)
            Prov-->>Sheet: Dismiss Modal
            Sheet-->>AdminUI: Instant Queue Refresh
        end
    end
```

---

## 3. SLA Breach Monitoring & Automated Escalation Flow

This sequence documents the background automated SLA watchdog evaluating pending grievances against departmental service deadlines and escalating priority upon breach.

```mermaid
sequenceDiagram
    autonumber
    participant Cron as SLA Scheduler (Node-Cron)
    participant Worker as EscalationWorker
    participant DB as MongoDB
    participant Notif as NotificationSubsystem
    actor Admin as Admin Master Console
    actor Auth as Department Head / Authority

    Note over Cron: Runs periodically (e.g. Every 15 Minutes)
    Cron->>Worker: triggerSlaEscalationCheck()
    Worker->>DB: Query { status: { $in: ["Assigned", "In Progress"] }, dueDate: { $lt: now() }, isEscalated: false }
    DB-->>Worker: List of Overdue Complaints
    
    loop For Each Overdue Ticket
        Worker->>Worker: Calculate Overdue Hours
        Worker->>Worker: Set isEscalated = true
        Worker->>Worker: Elevate priority to "Urgent"
        Worker->>DB: Complaint.findByIdAndUpdate(id, { isEscalated: true, priority: "Urgent" })
        
        Worker->>DB: Append Audit Remark: "[SYSTEM]: SLA Deadline Breached. Auto-Escalated to Urgent."
        
        Worker->>Notif: createNotification(ESCALATION_ALERT)
        Notif->>DB: Save High-Priority Notification
        Notif-->>Admin: Critical Alert: "Ticket CMP-XXXX Breached SLA!"
        Notif-->>Auth: Urgent Warning: "Department Ticket Breached Deadline"
    end
    
    Admin->>AdminConsole: Open "Master Console"
    AdminConsole->>Admin: Highlight Tickets with Red ESCALATED Banner
```

---

## 4. Student Feedback & Terminal Closure Flow

This sequence illustrates the satisfaction feedback loop where a student reviews resolution evidence, rates the experience (1–5 stars), leaves comments, and permanently locks the ticket in the `Closed` terminal state.

```mermaid
sequenceDiagram
    autonumber
    actor Student as Student (Owner)
    participant Screen as ComplaintDetailScreen
    participant Dialog as FeedbackDialog
    participant Prov as ComplaintProvider
    participant API as ComplaintRoutes
    participant Ctrl as ComplaintController
    participant DB as MongoDB
    participant Notif as NotificationSubsystem
    actor Auth as Authority Staff

    Student->>Screen: Open Resolved Complaint
    Screen->>Screen: Inspect Before/After Photos & Remarks
    Screen->>Screen: Detect status == "Resolved" -> Show "Rate & Close"
    Student->>Screen: Tap "Provide Feedback & Close"
    Screen->>Dialog: Open 5-Star Feedback Dialog
    
    Student->>Dialog: Select Star Rating (1 to 5)
    Student->>Dialog: Type optional review comments
    Student->>Dialog: Tap "Submit Feedback"
    
    Dialog->>Prov: submitFeedback(complaintId, rating, comments)
    Prov->>API: POST /api/complaints/:id/feedback { rating, comment }
    API->>Ctrl: submitFeedback(req, res)
    
    Ctrl->>DB: Complaint.findById(id)
    DB-->>Ctrl: Complaint Document
    
    alt Status is NOT Resolved or Already Closed
        Ctrl-->>Prov: 400 Bad Request ("Only resolved tickets accept feedback")
        Prov-->>Dialog: Display Error SnackBar
    else Valid Feedback Submission
        Ctrl->>Ctrl: feedback = { rating, comment, submittedAt: now() }
        Ctrl->>Ctrl: status = "Closed"
        Ctrl->>Ctrl: closedAt = now()
        Ctrl->>DB: Save updated Complaint
        
        Ctrl->>Notif: dispatch FEEDBACK Notification
        Notif-->>Auth: Alert: "Student submitted 5-Star Feedback on CMP-XXXX"
        
        Ctrl-->>Prov: 200 OK { success: true, complaint }
        Prov->>Prov: Update selectedComplaint (status="Closed", feedback)
        Prov-->>Dialog: Pop Dialog
        Dialog-->>Screen: Refresh Timeline (Terminal Closed State)
        Screen-->>Student: Display Thank You / Closure Card
    end
    
    Note over DB,Screen: Complaint is now Immutable. Any subsequent PATCH /status returns 400.
```

---

## 5. Architectural Invariants Verified
1. **Zero Data Leakage:** Whistleblower PII is scrubbed before response serialization across all paths unless requested by the author student or authorized admin.
2. **Finite State Machine Strictness:** Transitions follow the unidirectional graph:
   $$\text{Submitted} \longrightarrow \text{Assigned} \longrightarrow \text{In Progress} \longrightarrow \text{Resolved} \longrightarrow \text{Closed}$$
3. **Audit Trail Completeness:** Every transition, delegation, remark, and escalation appends an immutable entry to `statusHistory` and `remarks`.

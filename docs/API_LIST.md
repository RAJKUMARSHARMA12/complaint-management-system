# REST API Specification Document
## CampusVoice - College Complaint Management System

**Document Version:** 2.0  
**Status:** Approved for Implementation  
**Base URL (Local Development):** `http://localhost:5000/api`  
**Base URL (Android Emulator):** `http://10.0.2.2:5000/api`  
**Base URL (Production - Render):** `https://campusvoice-api.onrender.com/api`  
**Protocol:** HTTPS / JSON (Multipart for File Uploads)  

---

## 1. Global API Conventions

### 1.1 Headers
| Header Name | Type | Value / Description | Required On |
|---|---|---|---|
| `Content-Type` | String | `application/json` (or `multipart/form-data` for file uploads) | All mutation requests |
| `Authorization` | String | `Bearer <JWT_TOKEN>` | All protected endpoints |
| `Accept` | String | `application/json` | All requests |

### 1.2 Standard HTTP Status Codes
* `200 OK`: Request succeeded; data returned.
* `201 Created`: Resource successfully created.
* `400 Bad Request`: Validation failure, invalid status transition, or malformed JSON payload.
* `401 Unauthorized`: Missing, expired, or invalid JWT authentication token.
* `403 Forbidden`: Authenticated user lacks the requisite role permission.
* `404 Not Found`: Target resource does not exist.
* `409 Conflict`: Unique constraint violation (e.g., email already registered).
* `500 Internal Server Error`: Unhandled server exception.

### 1.3 Uniform Response Envelopes

#### Success Envelope (`200 OK`, `201 Created`):
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {}
}
```

#### Error Envelope (`400`, `401`, `403`, `404`, `500`):
```json
{
  "success": false,
  "message": "Descriptive human-readable error summary",
  "errors": [
    {
      "field": "fieldName",
      "message": "Specific validation failure message"
    }
  ]
}
```

---

## 2. Authentication & Profile Routes (`/api/auth`)

### 2.1 Student Registration
* **Endpoint:** `POST /api/auth/register`
* **Access:** Public (Unauthenticated)
* **Description:** Creates a new student user account and returns an authentication token.
* **Request Body:**
```json
{
  "name": "Aarav Mehta",
  "email": "aarav.mehta@college.edu",
  "password": "Password@123",
  "phone": "9876543210",
  "studentId": "CS2022045",
  "department": "Computer Science"
}
```
* **Success Response (`201 Created`):**
```json
{
  "success": true,
  "message": "Student registered successfully",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "65dfa4b1c2e12a0018f92101",
      "name": "Aarav Mehta",
      "email": "aarav.mehta@college.edu",
      "role": "student",
      "phone": "9876543210",
      "studentId": "CS2022045",
      "department": "Computer Science",
      "isActive": true
    }
  }
}
```

---

### 2.2 User Login
* **Endpoint:** `POST /api/auth/login`
* **Access:** Public (Unauthenticated)
* **Description:** Authenticates any registered user (Student, Authority, Admin) via credentials.
* **Request Body:**
```json
{
  "email": "aarav.mehta@college.edu",
  "password": "Password@123"
}
```
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "65dfa4b1c2e12a0018f92101",
      "name": "Aarav Mehta",
      "email": "aarav.mehta@college.edu",
      "role": "student",
      "phone": "9876543210",
      "studentId": "CS2022045",
      "department": "Computer Science"
    }
  }
}
```

---

### 2.3 Get Current User Profile
* **Endpoint:** `GET /api/auth/me`
* **Access:** Protected (Any valid token)
* **Description:** Returns profile data for the currently authenticated token bearer.
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "data": {
    "id": "65dfa4b1c2e12a0018f92101",
    "name": "Aarav Mehta",
    "email": "aarav.mehta@college.edu",
    "role": "student",
    "phone": "9876543210",
    "studentId": "CS2022045",
    "department": "Computer Science",
    "createdAt": "2026-02-15T10:00:00.000Z"
  }
}
```

---

### 2.4 Change Password
* **Endpoint:** `PUT /api/auth/change-password`
* **Access:** Protected (Any valid token)
* **Request Body:**
```json
{
  "currentPassword": "Password@123",
  "newPassword": "NewStrongPassword@2026"
}
```
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Password updated successfully"
}
```

---

## 3. Category Management Routes (`/api/categories`)

### 3.1 List Active Categories
* **Endpoint:** `GET /api/categories`
* **Access:** Protected (Any authenticated user)
* **Description:** Returns all active grievance categories for dropdown selection in complaint lodging forms.
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "data": [
    {
      "id": "65dfa502c2e12a0018f9210a",
      "name": "Hostel Maintenance",
      "description": "Plumbing, electrical, and furniture issues in student hostel blocks",
      "slaDays": 2,
      "icon": "home_repair_service",
      "defaultAuthority": {
        "id": "65dfa4a0c2e12a0018f920ff",
        "name": "Dr. Ramesh (Hostel Warden)"
      }
    },
    {
      "id": "65dfa502c2e12a0018f9210b",
      "name": "Mess & Dining",
      "description": "Food quality, hygiene, and dining hall issues",
      "slaDays": 1,
      "icon": "restaurant",
      "defaultAuthority": {
        "id": "65dfa4a0c2e12a0018f92100",
        "name": "Mr. Suresh (Mess Manager)"
      }
    }
  ]
}
```

---

### 3.2 Create New Category
* **Endpoint:** `POST /api/categories`
* **Access:** Protected (Admin only)
* **Request Body:**
```json
{
  "name": "Air Conditioning & HVAC",
  "description": "AC units in labs, lecture halls, and auditorium",
  "defaultAuthority": "65dfa4a0c2e12a0018f920ff",
  "slaDays": 3,
  "icon": "ac_unit"
}
```
* **Success Response (`201 Created`):**
```json
{
  "success": true,
  "message": "Category created successfully",
  "data": {
    "id": "65dfa502c2e12a0018f92120",
    "name": "Air Conditioning & HVAC",
    "slaDays": 3,
    "isActive": true
  }
}
```

---

### 3.3 Toggle Category Status
* **Endpoint:** `PATCH /api/categories/:id/status`
* **Access:** Protected (Admin only)
* **Request Body:**
```json
{
  "isActive": false
}
```
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Category status updated successfully"
}
```

---

## 4. Grievance / Complaint Routes (`/api/complaints`)

### 4.1 Submit New Complaint (Multipart Upload)
* **Endpoint:** `POST /api/complaints`
* **Access:** Protected (`student` only)
* **Content-Type:** `multipart/form-data`
* **Form Fields:**
  * `title` (text, required): 5–100 chars
  * `description` (text, required): 20–1000 chars
  * `category` (text, required): Valid Category ObjectId
  * `location` (text, required): Campus location details
  * `priority` (text, optional): `Low` | `Medium` | `High` | `Urgent` (Default: `Medium`)
  * `isAnonymous` (boolean, optional): `true` | `false` (Default: `false`)
  * `images` (binary file array, optional): Up to 3 image files (JPEG/PNG, max 5 MB each)
* **Success Response (`201 Created`):**
```json
{
  "success": true,
  "message": "Complaint lodged successfully",
  "data": {
    "id": "65dfb122c2e12a0018f92150",
    "complaintId": "CMP-0042",
    "title": "Water leakage in Room 302",
    "description": "Continuous water leakage from ceiling pipe causing damage to desks",
    "category": "65dfa502c2e12a0018f9210a",
    "location": "Hostel Block A, 3rd Floor, Room 302",
    "priority": "High",
    "status": "Assigned",
    "isAnonymous": false,
    "images": [
      "https://res.cloudinary.com/demo/image/upload/v1700000000/complaints/leakage_1.jpg",
      "https://res.cloudinary.com/demo/image/upload/v1700000000/complaints/leakage_2.jpg"
    ],
    "assignedTo": "65dfa4a0c2e12a0018f920ff",
    "dueDate": "2026-03-02T10:00:00.000Z",
    "isEscalated": false,
    "createdAt": "2026-02-28T10:00:00.000Z"
  }
}
```

---

### 4.2 List Student's Own Complaints
* **Endpoint:** `GET /api/complaints/my`
* **Access:** Protected (`student` only)
* **Query Parameters:**
  * `status` (optional): Filter by `Submitted`, `Assigned`, `In Progress`, `Resolved`, `Closed`
  * `page` (optional, default: 1): Page number
  * `limit` (optional, default: 10): Records per page
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "data": {
    "complaints": [
      {
        "id": "65dfb122c2e12a0018f92150",
        "complaintId": "CMP-0042",
        "title": "Water leakage in Room 302",
        "category": { "name": "Hostel Maintenance" },
        "location": "Hostel Block A, 3rd Floor, Room 302",
        "priority": "High",
        "status": "In Progress",
        "dueDate": "2026-03-02T10:00:00.000Z",
        "isEscalated": false,
        "createdAt": "2026-02-28T10:00:00.000Z"
      }
    ],
    "pagination": {
      "total": 1,
      "page": 1,
      "pages": 1,
      "limit": 10
    }
  }
}
```

---

### 4.3 List Assigned Complaints (Authority Queue)
* **Endpoint:** `GET /api/complaints/assigned`
* **Access:** Protected (`authority` only)
* **Query Parameters:** `status`, `priority`, `page`, `limit`
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "data": {
    "complaints": [
      {
        "id": "65dfb122c2e12a0018f92150",
        "complaintId": "CMP-0042",
        "title": "Water leakage in Room 302",
        "location": "Hostel Block A, 3rd Floor, Room 302",
        "priority": "High",
        "status": "Assigned",
        "dueDate": "2026-03-02T10:00:00.000Z",
        "isEscalated": false,
        "isAnonymous": true,
        "createdBy": {
          "name": "Anonymous Student"
        }
      }
    ],
    "pagination": {
      "total": 1,
      "page": 1,
      "pages": 1,
      "limit": 10
    }
  }
}
```

---

### 4.4 List All Complaints (Admin Console)
* **Endpoint:** `GET /api/complaints`
* **Access:** Protected (`admin` only)
* **Query Parameters:** `search`, `status`, `category`, `priority`, `isEscalated`, `page`, `limit`
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "data": {
    "complaints": [
      {
        "id": "65dfb122c2e12a0018f92150",
        "complaintId": "CMP-0042",
        "title": "Water leakage in Room 302",
        "category": { "name": "Hostel Maintenance" },
        "assignedTo": { "name": "Dr. Ramesh (Hostel Warden)" },
        "status": "Assigned",
        "isEscalated": true,
        "createdAt": "2026-02-28T10:00:00.000Z"
      }
    ],
    "pagination": {
      "total": 45,
      "page": 1,
      "pages": 5,
      "limit": 10
    }
  }
}
```

---

### 4.5 Get Complaint Details
* **Endpoint:** `GET /api/complaints/:id`
* **Access:** Protected (Owner Student, Assigned Authority, or Admin)
* **Description:** Retrieves complete complaint data. If `isAnonymous == true` and requester is not the original student owner, student identification details are scrubbed.
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "data": {
    "id": "65dfb122c2e12a0018f92150",
    "complaintId": "CMP-0042",
    "title": "Water leakage in Room 302",
    "description": "Continuous water leakage from ceiling pipe causing damage to desks",
    "location": "Hostel Block A, 3rd Floor, Room 302",
    "priority": "High",
    "status": "In Progress",
    "isAnonymous": false,
    "images": [
      "https://res.cloudinary.com/demo/image/upload/v1700000000/complaints/leakage_1.jpg"
    ],
    "createdBy": {
      "id": "65dfa4b1c2e12a0018f92101",
      "name": "Aarav Mehta",
      "email": "aarav.mehta@college.edu",
      "phone": "9876543210"
    },
    "assignedTo": {
      "id": "65dfa4a0c2e12a0018f920ff",
      "name": "Dr. Ramesh (Hostel Warden)",
      "department": "Hostel Affairs"
    },
    "category": {
      "id": "65dfa502c2e12a0018f9210a",
      "name": "Hostel Maintenance",
      "slaDays": 2
    },
    "dueDate": "2026-03-02T10:00:00.000Z",
    "resolvedAt": null,
    "closedAt": null,
    "isEscalated": false,
    "remarks": [
      {
        "id": "65dfb200c2e12a0018f92160",
        "user": { "name": "Dr. Ramesh" },
        "role": "authority",
        "text": "Plumber dispatched to inspect valve fittings.",
        "createdAt": "2026-02-28T14:30:00.000Z"
      }
    ],
    "feedback": null
  }
}
```

---

### 4.6 Assign / Reassign Authority
* **Endpoint:** `PATCH /api/complaints/:id/assign`
* **Access:** Protected (`admin` only)
* **Request Body:**
```json
{
  "authorityId": "65dfa4a0c2e12a0018f920ff",
  "remark": "Reassigned to primary hostel maintenance supervisor"
}
```
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Complaint assigned successfully",
  "data": {
    "complaintId": "CMP-0042",
    "status": "Assigned",
    "assignedTo": "65dfa4a0c2e12a0018f920ff",
    "dueDate": "2026-03-02T10:00:00.000Z"
  }
}
```

---

### 4.7 Update Complaint Status
* **Endpoint:** `PATCH /api/complaints/:id/status`
* **Access:** Protected (`authority`, `admin`)
* **Request Body:**
```json
{
  "status": "Resolved",
  "remark": "Pipe section replaced with new PVC joint and pressure tested."
}
```
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Status updated successfully",
  "data": {
    "complaintId": "CMP-0042",
    "status": "Resolved",
    "resolvedAt": "2026-03-01T16:00:00.000Z"
  }
}
```

---

### 4.8 Add Remark to Complaint
* **Endpoint:** `POST /api/complaints/:id/remarks`
* **Access:** Protected (Complaint Owner, Assigned Authority, Admin)
* **Request Body:**
```json
{
  "text": "The leak has slowed down, but moisture remains on the wall."
}
```
* **Success Response (`201 Created`):**
```json
{
  "success": true,
  "message": "Remark added successfully",
  "data": {
    "remarks": [
      {
        "role": "student",
        "text": "The leak has slowed down, but moisture remains on the wall.",
        "createdAt": "2026-03-01T11:00:00.000Z"
      }
    ]
  }
}
```

---

### 4.9 Submit Resolution Feedback (Closes Complaint)
* **Endpoint:** `POST /api/complaints/:id/feedback`
* **Access:** Protected (`student` owner only)
* **Constraint:** Complaint must currently be in `Resolved` status.
* **Request Body:**
```json
{
  "rating": 5,
  "comment": "Quick turnaround! Plumber arrived promptly and repaired the leak cleanly."
}
```
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Feedback submitted; complaint marked as Closed",
  "data": {
    "complaintId": "CMP-0042",
    "status": "Closed",
    "closedAt": "2026-03-01T18:00:00.000Z",
    "feedback": {
      "rating": 5,
      "comment": "Quick turnaround! Plumber arrived promptly and repaired the leak cleanly."
    }
  }
}
```

---

## 5. Administrative Dashboard & Analytics (`/api/dashboard`)

### 5.1 Summary Statistics
* **Endpoint:** `GET /api/dashboard/stats`
* **Access:** Protected (`admin` only)
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "data": {
    "totalComplaints": 128,
    "openComplaints": 34,
    "resolvedComplaints": 62,
    "closedComplaints": 32,
    "escalatedComplaints": 5
  }
}
```

---

### 5.2 Breakdown by Category
* **Endpoint:** `GET /api/dashboard/by-category`
* **Access:** Protected (`admin` only)
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "data": [
    { "category": "Hostel Maintenance", "count": 48 },
    { "category": "Mess & Dining", "count": 32 },
    { "category": "Lab & Computing", "count": 26 },
    { "category": "Classroom & Audio/Visual", "count": 22 }
  ]
}
```

---

### 5.3 Breakdown by Status
* **Endpoint:** `GET /api/dashboard/by-status`
* **Access:** Protected (`admin` only)
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "data": [
    { "status": "Submitted", "count": 8 },
    { "status": "Assigned", "count": 12 },
    { "status": "In Progress", "count": 14 },
    { "status": "Resolved", "count": 30 },
    { "status": "Closed", "count": 64 }
  ]
}
```

---

### 5.4 Monthly Submission Trend
* **Endpoint:** `GET /api/dashboard/monthly-trend`
* **Access:** Protected (`admin` only)
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "data": [
    { "month": "Sep 2025", "count": 18 },
    { "month": "Oct 2025", "count": 25 },
    { "month": "Nov 2025", "count": 31 },
    { "month": "Dec 2025", "count": 14 },
    { "month": "Jan 2026", "count": 22 },
    { "month": "Feb 2026", "count": 18 }
  ]
}
```

---

### 5.5 Mean Time to Resolution (MTTR)
* **Endpoint:** `GET /api/dashboard/resolution-time`
* **Access:** Protected (`admin` only)
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "data": [
    { "category": "Hostel Maintenance", "avgHours": 32.5 },
    { "category": "Mess & Dining", "avgHours": 14.2 },
    { "category": "Lab & Computing", "avgHours": 24.8 },
    { "category": "Overall Average", "avgHours": 26.1 }
  ]
}
```

---

## 6. Notification Routes (`/api/notifications`)

### 6.1 Get Notification Inbox
* **Endpoint:** `GET /api/notifications`
* **Access:** Protected (Authenticated user)
* **Query Parameters:** `page`, `limit`
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "data": {
    "unreadCount": 2,
    "notifications": [
      {
        "id": "65dfc001c2e12a0018f92190",
        "title": "Status Updated",
        "message": "Your complaint [CMP-0042] status was changed to In Progress",
        "type": "STATUS_CHANGE",
        "relatedComplaint": "65dfb122c2e12a0018f92150",
        "isRead": false,
        "createdAt": "2026-02-28T14:30:00.000Z"
      }
    ]
  }
}
```

---

### 6.2 Mark Single Notification Read
* **Endpoint:** `PATCH /api/notifications/:id/read`
* **Access:** Protected (Recipient only)
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```

---

### 6.3 Mark All Notifications Read
* **Endpoint:** `PATCH /api/notifications/read-all`
* **Access:** Protected (Recipient only)
* **Success Response (`200 OK`):**
```json
{
  "success": true,
  "message": "All notifications marked as read"
}
```

---

## 7. System Health Endpoint

### 7.1 Server Healthcheck
* **Endpoint:** `GET /api/health`
* **Access:** Public (Unauthenticated)
* **Description:** Used by UptimeRobot, Render cold-start pingers, and monitoring tools.
* **Success Response (`200 OK`):**
```json
{
  "status": "UP",
  "timestamp": "2026-02-28T12:00:00.000Z",
  "database": "connected"
}
```

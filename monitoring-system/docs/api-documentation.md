# API Documentation

All endpoints are relative to `http://localhost:5000/api`. Authentication is executed via standard Bearer tokens (`Authorization: Bearer <access_token>`).

---

## 1. Authentication Endpoints (`/api/auth`)

### `POST /api/auth/register`
Create a new user account.
- **Request Body**:
```json
{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "password": "Password123"
}
```
- **Response (201 Created)**:
```json
{
  "message": "Registration successful.",
  "access_token": "eyJhbGciOi...",
  "refresh_token": "eyJhbGciOi...",
  "user": {
    "id": 1,
    "name": "Jane Doe",
    "email": "jane@example.com",
    "role": "user",
    "is_active": true,
    "created_at": "2026-08-18T12:00:00Z"
  }
}
```

### `POST /api/auth/login`
Authenticate existing user & retrieve tokens.
- **Request Body**:
```json
{
  "email": "admin@system.com",
  "password": "Admin@123"
}
```

### `POST /api/auth/refresh`
Refresh expired JWT access token using the refresh token in Authorization header.

### `GET /api/auth/me`
Retrieve currently authenticated user profile.

---

## 2. Submission Endpoints (`/api/submissions`)

### `POST /api/submissions`
Create a new submission ticket.
- **Headers**: `Authorization: Bearer <token>`
- **Request Body**:
```json
{
  "title": "Network outage in Section B",
  "description": "All workstations in section B are unable to reach the internal gateway.",
  "category": "report",
  "priority": "high"
}
```
- **Response (201 Created)**:
```json
{
  "message": "Submission created.",
  "submission": {
    "id": 14,
    "user_id": 3,
    "submitter": "John User",
    "title": "Network outage in Section B",
    "description": "...",
    "category": "report",
    "priority": "high",
    "status": "pending",
    "created_at": "2026-08-18T12:10:00Z"
  }
}
```

### `GET /api/submissions`
Fetch paginated submissions.
- **Query Params**: `page` (default 1), `per_page` (default 20), `status`, `category`.
- **Role filtering**:
  - `user`: Returns only their own submissions.
  - `secretary`: Returns submissions assigned to them.
  - `admin`: Returns all submissions across the system.

### `GET /api/submissions/<id>`
Get detailed case data including all responses.

### `PATCH /api/submissions/<id>/status`
Update status of a case. (Requires `admin` or `secretary` role).
- **Request Body**:
```json
{
  "status": "under_review"
}
```

### `POST /api/submissions/assign`
Assign a case to a specific secretary. (Requires `admin` role).
- **Request Body**:
```json
{
  "submission_id": 14,
  "assigned_to": 2,
  "notes": "Please investigate immediately."
}
```

### `DELETE /api/submissions/<id>`
Delete a submission (Requires `admin` role).

---

## 3. Response Endpoints (`/api/responses`)

### `POST /api/responses`
Add a staff reply to a case. (Requires `admin` or `secretary` role).
- **Request Body**:
```json
{
  "submission_id": 14,
  "message": "Our technical support team has resolved the upstream gateway switch."
}
```

### `GET /api/responses/<submission_id>`
List all replies for a given submission.

---

## 4. Monitoring & Analytics (`/api/monitoring`)

### `GET /api/monitoring/stats`
Dashboard statistics for admins:
- Counts by status (`pending`, `under_review`, `assigned`, `resolved`, `closed`).
- Submissions count grouped by category & priority.
- 7-day daily submission volume trends.

### `GET /api/monitoring/audit-logs`
Fetch chronological system audit entries with actor, IP address, and details.

### `GET /api/monitoring/notifications`
Retrieve authenticated user notifications.

---

## 5. User Management (`/api/users`)

### `GET /api/users`
List users, optionally filtered by `?role=secretary`. (Admin only).

### `PATCH /api/users/<id>/role`
Promote or change user role (`user`, `secretary`, `admin`). (Admin only).

### `PATCH /api/users/<id>/toggle-active`
Enable or disable a user account. (Admin only).

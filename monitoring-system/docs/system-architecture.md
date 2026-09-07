# System Architecture & Flow

## High-Level Architecture

```
                    ┌────────────────────────┐
                    │      USER / CLIENT     │
                    └───────────┬────────────┘
                                │
                                ▼
                    ┌────────────────────────┐
                    │      Flutter App       │
                    │  (Android / iOS / Web) │
                    └───────────┬────────────┘
                                │
                                │ HTTPS / JSON (JWT Auth)
                                ▼
              ┌─────────────────────────────────────┐
              │     Node.js REST API (Express)      │
              ├─────────────────────────────────────┤
              │ • JWT Authentication & Token Store  │
              │ • Role-Based Permissions (RBAC)     │
              │ • zod Schema Validation             │
              │ • Business Logic & Orchestration    │
              │ • Audit Trail & Event Logging       │
              └─────────────────┬───────────────────┘
                                │
                                │ Prisma ORM
                                ▼
              ┌─────────────────────────────────────┐
              │       MySQL / MariaDB Database      │
              ├─────────────────────────────────────┤
              │ • Users (Roles: user, sec, admin)   │
              │ • Submissions (Status, Priority)    │
              │ • Assignments (Secretary Link)      │
              │ • Responses (Threaded Replies)      │
              │ • Notifications (In-app Alerts)     │
              │ • Audit Logs (Action Tracker)       │
              └─────────────────┬───────────────────┘
                                ▲
                                │ REST API (JWT Auth)
                                │
                    ┌───────────┴───────────┐
                    │                       │
                    ▼                       ▼
         ┌─────────────────────┐ ┌──────────────────────┐
         │   ADMIN DASHBOARD   │ │ SECRETARY DASHBOARD  │
         │   (React / Vite)    │ │    (React / Vite)    │
         ├─────────────────────┤ ├──────────────────────┤
         │ • System Analytics  │ │ • Assigned Cases     │
         │ • User Management   │ │ • Respond to Tickets │
         │ • Case Delegation   │ │ • Update Progress    │
         │ • Audit Inspection  │ │                      │
         └─────────────────────┘ └──────────────────────┘
```

---

## Component Roles & Interaction Flow

### 1. User Submission Cycle
1. **User Authentication**: The user opens the Flutter application, registers or logs in, and acquires an access token stored securely via `SharedPreferences`.
2. **Form Entry & Validation**: The user enters case title, detailed description, category, and priority level. The client performs initial client-side regex/length validation.
3. **Dispatch**: The Flutter client issues a `POST /api/submissions` request with the JSON payload and Bearer token.
4. **Processing & Persistence**: The Node API validates the payload with the `submissionCreateSchema` zod schema, stores the submission in MySQL via Prisma, generates audit logs, and triggers notification alerts for system administrators.
5. **Real-time Status Tracking**: The user can check the 5-phase status tracker in Flutter (`pending` → `under_review` → `assigned` → `resolved` → `closed`).

### 2. Admin Oversight & Delegation Cycle
1. **Dashboard Monitoring**: Administrators log into the React dashboard, where interactive Recharts visualizations display submission volume trends, category ratios, and pending workloads.
2. **Review & Assignment**: The Admin reviews case details and can either reply directly or assign the case to a designated Secretary via `POST /api/submissions/assign`.
3. **Audit Trail**: Every role change, status update, response, and assignment is recorded into `audit_logs` with actor id, action type, entity ID, and client IP address.

### 3. Secretary Feedback & Case Resolution Cycle
1. **Case Retrieval**: Secretaries view their dedicated queue containing specifically assigned tickets.
2. **Response Formulation**: The Secretary inputs a feedback response via `POST /api/responses`.
3. **Status Transition**: Adding a response automatically shifts the case from `pending` to `under_review` (or directly to `resolved`).
4. **Notification**: A notification record is generated for the submitter. When the user re-opens their mobile app, the response appears in their threaded dialogue view.

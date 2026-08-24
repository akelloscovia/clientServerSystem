# Web Portal & QR Code Features

## Overview

This update converts the monitoring system into a fully web-based application with QR code support for easy access and sharing.

## New Features

### 1. **User Portal** (`/user-portal`)
- **Email Access**: Users can enter their email to get access
- **QR Code Scanner**: Scan existing QR codes for quick access
- **QR Code Generation**: Generate shareable QR codes for submission links

### 2. **User Submissions View** (`/user-submissions`)
- View all personal submissions in a web interface
- Track submission status in real-time
- Share access via QR code
- Mobile-responsive design

### 3. **QR Code Generation**
- Users can generate QR codes for sharing their submission links
- Download QR codes as PNG images
- Perfect for printing or digital sharing

### 4. **QR Code Scanning**
- Built-in camera scanner for QR codes
- One-click scanning with easy UI
- Instant access to shared submissions

## How to Use

### For Users

1. **First Time Access**:
   - Visit `/user-portal`
   - Enter your email address
   - Click "Get Access"
   - System generates your personal QR code

2. **Using QR Code Scanner**:
   - Click "Start QR Scanner"
   - Point camera at a QR code
   - Automatically redirected to content

3. **Accessing from Another Device**:
   - Visit `/user-portal`
   - Click "Scan QR Code"
   - Scan the shared QR code from your first device
   - Instant access without re-entering email

### For Admins/Staff

- Continue using `/dashboard` for admin panel
- Continue using `/submissions` for staff submissions view
- All existing functionality preserved

## Technical Details

### Frontend Components

- **QRCodeGenerator.jsx**: Generates QR codes using qrcode.react
- **QRCodeScanner.jsx**: Scans QR codes using html5-qrcode library
- **UserPortal.jsx**: Main user portal page with access methods
- **UserSubmissions.jsx**: User's personal submissions view

### Backend Endpoints

**New Endpoints**:
- `POST /api/auth/user-portal` - Get access token via email
- `GET /api/submissions/user` - Get user's submissions via token

**Authentication**:
- Users access via tokens generated from their email
- Token-based authentication allows cross-device access
- No password required for web portal

### Technologies Used

- **Frontend**: React 18, Vite, React Router
- **QR Generation**: qrcode.react
- **QR Scanning**: html5-qrcode
- **HTTP Client**: Axios
- **Backend**: Flask, Flask-JWT-Extended

## Installation

### 1. Install Dependencies

```bash
cd monitoring
npm install
```

### 2. Update package.json

Dependencies already added:
- `qrcode.react: ^1.0.1`
- `jsqr: ^1.4.0`
- `html5-qrcode: ^2.3.4`

### 3. Run Development Server

```bash
cd monitoring
npm run dev
```

The application will start at `http://localhost:5173`

## URL Routes

| Route | Purpose | Access |
|-------|---------|--------|
| `/` | Home | Redirects to `/user-portal` |
| `/user-portal` | User access portal | Public |
| `/user-submissions` | View personal submissions | Token required |
| `/login` | Admin/Staff login | Public |
| `/dashboard` | Admin dashboard | Admin only |
| `/submissions` | Staff submissions view | Staff + |
| `/users` | User management | Admin only |
| `/audit-logs` | System logs | Admin only |

## Security Features

- Token-based authentication
- No passwords transmitted over QR codes
- Secure token validation on backend
- Account status verification
- Role-based access control maintained

## Browser Compatibility

- Chrome/Edge (recommended for camera access)
- Firefox
- Safari (requires HTTPS for camera access)
- Mobile browsers (iOS Safari, Chrome Mobile)

## Troubleshooting

### Camera Access Issues
- Ensure HTTPS is used (for production)
- Grant camera permissions when prompted
- Check browser privacy settings

### QR Code Not Scanning
- Ensure good lighting
- Hold camera steady
- QR code must be generated from this system
- Try closer or farther distance

### Token Not Working
- Ensure token hasn't expired
- Try accessing via email again
- Check browser local storage for token

## Future Enhancements

- SMS-based QR code sharing
- Email with QR code link
- QR code expiration times
- Multi-user access sharing
- Offline mode support
- Progressive Web App (PWA)

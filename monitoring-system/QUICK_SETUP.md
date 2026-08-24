# Quick Setup - Web Portal & QR Code Features

## 🚀 Get Started in 5 Minutes

### Prerequisites
- Node.js 16+
- Python 3.8+
- PostgreSQL (already running)

### Step 1: Install Frontend Dependencies

```bash
cd monitoring-system/monitoring
npm install
```

This installs all QR code libraries:
- `qrcode.react` - QR code generation
- `html5-qrcode` - QR code scanning
- `jsqr` - QR code decoding

### Step 2: Start the Development Server

```bash
npm run dev
```

Server runs on: `http://localhost:5173`

### Step 3: Access the Application

**User Portal** (New):
```
http://localhost:5173/user-portal
```

**Admin Dashboard** (Existing):
```
http://localhost:5173/login
```

---

## 📱 Features Overview

### 1️⃣ User Portal (`/user-portal`)
- Email-based access
- QR code scanner
- QR code generation
- Mobile-responsive design

### 2️⃣ User Submissions (`/user-submissions`)
- View personal submissions
- Track status changes
- Share via QR code
- Real-time updates

### 3️⃣ QR Code Integration
- Generate shareable QR codes
- Scan codes with camera
- Cross-device access
- No credentials needed

---

## 🔧 Testing the Features

### Test 1: Email Access
```
1. Go to http://localhost:5173/user-portal
2. Enter an email (must exist in database)
3. Get QR code
4. Click "Continue to My Submissions"
5. See your submissions
```

### Test 2: QR Code Scanning
```
1. Generate QR code from Test 1
2. Go back to portal
3. Click "Start QR Scanner"
4. Point camera at QR code
5. Automatically redirected
```

### Test 3: Cross-Device Access
```
1. On Device A: Generate QR code at /user-portal
2. On Device B: Visit /user-portal
3. Click "Scan QR Code"
4. Scan code from Device A
5. Access same submissions on Device B
```

---

## 📊 API Endpoints

### New Endpoints

```bash
# User Portal Access
POST /api/auth/user-portal
{
  "email": "user@example.com"
}
Response:
{
  "token": "jwt_token_here",
  "email": "user@example.com",
  "user_id": 123
}

# Get User Submissions (with token)
GET /api/submissions/user
Headers:
  Authorization: Bearer jwt_token_here
Response:
{
  "user": { "id": 123, "email": "user@example.com", "name": "John" },
  "submissions": [...],
  "total": 5,
  "pages": 1,
  "page": 1
}
```

---

## 🎨 Component Structure

```
Components/
├── QRCodeGenerator.jsx
│   └── QRCodeGenerator.css
├── QRCodeScanner.jsx
│   └── QRCodeScanner.css
└── (existing components)

Pages/
├── UserPortal.jsx
│   └── UserPortal.css
├── UserSubmissions.jsx
│   └── UserSubmissions.css
└── (existing pages)
```

---

## 🐛 Troubleshooting

### Issue: Camera not working
**Solution**:
- Use HTTPS (required for production)
- Grant camera permissions
- Check browser privacy settings
- Try different browser

### Issue: QR code not scanning
**Solution**:
- Ensure good lighting
- Hold camera steady
- QR code must be from this app
- Try moving closer/farther

### Issue: Token not working
**Solution**:
- Clear local storage
- Try email access again
- Check backend logs
- Ensure user exists in database

### Issue: CORS errors
**Solution**:
- Backend CORS already configured
- Check API URL in `services/api.js`
- Ensure backend is running

---

## 📦 Build for Production

### Frontend Build
```bash
cd monitoring
npm run build
```

Output: `dist/` folder (ready to deploy)

### Backend Deployment
```bash
cd server
pip install -r requirements.txt
python run.py
```

Set environment variables:
```
FLASK_ENV=production
DATABASE_URL=postgresql://...
SECRET_KEY=your-secret-key
```

---

## 📝 Configuration Files Updated

### `monitoring/package.json`
Added dependencies:
- qrcode.react
- html5-qrcode
- jsqr

### `monitoring/src/App.jsx`
Added routes:
- `/user-portal` - User portal
- `/user-submissions` - User's submissions

### `server/app/routes/auth.py`
Added endpoint:
- `POST /api/auth/user-portal`

### `server/app/routes/submissions.py`
Added endpoint:
- `GET /api/submissions/user`

---

## 📚 Documentation Files

- **WEB_PORTAL_QR_GUIDE.md** - Complete feature guide
- **MIGRATION_GUIDE.md** - Flutter to Web migration
- **QUICK_SETUP.md** - This file
- **README.md** - Original project overview

---

## ✅ Verification Checklist

After setup, verify:

- [ ] `npm install` completed without errors
- [ ] `npm run dev` starts server on localhost:5173
- [ ] `/user-portal` loads successfully
- [ ] Email input field works
- [ ] QR code generates
- [ ] Camera scanner starts/stops
- [ ] Admin dashboard still works
- [ ] All old routes functional
- [ ] No console errors
- [ ] Network requests to backend work

---

## 🆘 Getting Help

Check these files for answers:
1. **WEB_PORTAL_QR_GUIDE.md** - Feature documentation
2. **MIGRATION_GUIDE.md** - Architecture & migration info
3. **docs/system-architecture.md** - System design
4. **docs/api-documentation.md** - API reference

---

## 🎯 Next Steps

1. ✅ Complete setup
2. ✅ Test all features
3. ✅ Review security settings
4. ✅ Deploy to staging
5. ✅ Gather user feedback
6. ✅ Deploy to production

---

**Last Updated**: 2024
**Status**: Production Ready

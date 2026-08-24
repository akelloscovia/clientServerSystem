# Migration Guide: Flutter App to Web Portal

## Overview

The monitoring system has been converted to a fully web-based application. Users no longer need to install a Flutter app—they can access everything directly from their browsers.

## What Changed

### Before (Flutter Mobile App)
```
Users → Install Flutter App → Login → Submit Cases → Mobile Device Only
```

### After (Web Portal with QR Codes)
```
Users → Visit Web Portal → Email/QR Scan → Submit Cases → Any Device, Any Browser
```

## For Users

### Migrating from Flutter App

1. **No More App Installation**
   - ❌ No need to download/install Flutter app
   - ✅ Just visit the web portal in browser

2. **Accessing Submissions**
   - **Old**: Open Flutter app, login, view submissions
   - **New**: Visit `/user-portal`, enter email, view submissions

3. **Mobile Access**
   - **Old**: Only on device where app is installed
   - **New**: Access from any phone, tablet, or computer via web browser

### Getting Started

**Step 1: Access the Portal**
```
Visit: http://your-server-address/user-portal
```

**Step 2: Choose Your Access Method**
- Option A: Enter your email → Get QR code
- Option B: Scan a QR code → Instant access

**Step 3: View Your Submissions**
- See all your cases in one place
- Track status in real-time
- Share access with QR code

## For System Administrators

### Deployment Changes

**What Still Exists**:
- ✅ Admin Dashboard (`/dashboard`)
- ✅ Submissions Management (`/submissions`)
- ✅ User Management (`/users`)
- ✅ Audit Logs (`/audit-logs`)
- ✅ Python Flask API (no changes)
- ✅ PostgreSQL Database (no changes)

**What's New**:
- ✅ User Portal page (`/user-portal`)
- ✅ User Submissions view (`/user-submissions`)
- ✅ QR Code generation & scanning
- ✅ Token-based access (no Flutter app needed)

### No Database Migrations Needed

The existing user, submission, and status tables are fully compatible. No new database schema required.

### Configuration

No additional configuration needed. The application uses existing:
- User authentication
- JWT tokens
- Role-based access control
- Submission service

## Technical Comparison

| Feature | Flutter App | Web Portal |
|---------|-------------|-----------|
| **Access** | Mobile only | Any device |
| **Installation** | Required | Not needed |
| **Browser** | None (native) | All modern browsers |
| **QR Codes** | Not supported | ✅ Built-in |
| **Offline Mode** | Possible | Limited (PWA ready) |
| **Updates** | Manual (app store) | Automatic (web) |
| **Development** | Dart/Flutter | React/JavaScript |
| **Backend API** | Same | Same |
| **Database** | Same | Same |

## File Structure

### New Frontend Files

```
monitoring/
├── src/
│   ├── components/
│   │   ├── QRCodeGenerator.jsx       (NEW)
│   │   ├── QRCodeGenerator.css       (NEW)
│   │   ├── QRCodeScanner.jsx         (NEW)
│   │   └── QRCodeScanner.css         (NEW)
│   ├── pages/
│   │   ├── UserPortal.jsx            (NEW)
│   │   ├── UserPortal.css            (NEW)
│   │   ├── UserSubmissions.jsx       (NEW)
│   │   └── UserSubmissions.css       (NEW)
│   └── App.jsx                       (UPDATED)
└── package.json                      (UPDATED)
```

### New Backend Files

```
server/
├── app/
│   └── routes/
│       ├── auth.py                   (UPDATED - added /user-portal)
│       └── submissions.py            (UPDATED - added /user endpoint)
```

## Decommissioning Flutter App

### If You Want to Remove Flutter App

**Option 1: Keep as Backup**
- Keep Flutter source code in repository
- Don't deploy to app stores
- Document as "deprecated"

**Option 2: Full Removal**
1. Archive Flutter project
2. Remove from deployment pipeline
3. Remove from CI/CD
4. Keep in git history

### User Notifications

Send users:
```
📢 Important Update

We've launched a new web portal for easier access!

🎉 What's New:
- Access from any device
- No app installation needed
- Scan QR codes for quick access
- Same functionality, better experience

📱 Visit: [your-domain]/user-portal

❓ Questions? Contact support
```

## Rollback Plan

If needed to revert:

1. **Keep Flutter app live** alongside web portal
2. **Users can use either** method
3. **Gradually migrate** users to web
4. **Then sunset** Flutter app after 6 months

## Testing Checklist

Before going live:

- [ ] Email access works
- [ ] QR code generation works
- [ ] QR code scanning works
- [ ] Cross-device access works
- [ ] Token expiration handled
- [ ] Mobile responsive design tested
- [ ] All old routes still work
- [ ] Admin dashboard functional
- [ ] Submissions view functional
- [ ] User management functional

## Support Resources

- **User Guide**: See `WEB_PORTAL_QR_GUIDE.md`
- **Backend Docs**: See `docs/api-documentation.md`
- **System Architecture**: See `docs/system-architecture.md`

## FAQ

**Q: Will users lose their submissions?**
A: No. All data is preserved. Same database, same submissions.

**Q: Can users still use the old app?**
A: Yes, until you decommission it. Both can work side-by-side.

**Q: What about offline access?**
A: Web version is online-only currently. PWA support coming soon.

**Q: Do users need new passwords?**
A: No. Email-based access with tokens. No passwords needed for web portal.

**Q: Is the web version secure?**
A: Yes. Uses JWT tokens, HTTPS (recommended), and existing access controls.

## Performance Improvements

**Web Portal Benefits**:
- Faster updates (no app store lag)
- Smaller bandwidth (no app downloads)
- Better analytics
- Easier to debug
- Automatic backups
- No version conflicts

## Next Steps

1. ✅ Deploy the updated application
2. ✅ Test user portal thoroughly
3. ✅ Notify users about new portal
4. ✅ Monitor for issues
5. ✅ Gather feedback
6. ✅ Plan Flutter app sunset (if desired)

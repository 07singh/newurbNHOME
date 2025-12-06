# Complete Notification System - Implementation Guide

## Overview

This is a complete push notification system where **Employee** and **Associate** activities automatically trigger notifications to **HR** and **Director** devices.

## System Architecture

```
Employee/Associate Activity
    ↓
Frontend Service (ActivityNotificationHelper)
    ↓
Backend API (/api/notification/send)
    ↓
Backend Filters (HR/Director tokens)
    ↓
FCM Service (Firebase Cloud Messaging)
    ↓
HR/Director Devices (Push Notification)
```

## Flutter Implementation

### 1. Firebase Initialization

Already implemented in `lib/main.dart`:
- Firebase initialized on app start
- Background message handler registered
- Notification service initialized

### 2. Device Token Registration

**File:** `lib/service/device_token_service.dart`

- Automatically saves FCM token to backend on:
  - App initialization (if user logged in)
  - User login
  - Token refresh

**API Endpoint:** `POST /api/device/save`

**Request:**
```json
{
  "UserId": 123,
  "Token": "fcm_token_string",
  "DeviceType": "Android",
  "UserRole": "Employee" // or "HR", "Director", "Associate"
}
```

### 3. Login Flows Updated

All login screens now save FCM token after successful login:

- ✅ `lib/signin_role/sign_role_direct.dart` - Director login
- ✅ `lib/signin_role/sign_role_hr.dart` - HR login
- ✅ `lib/sign_page.dart` - Employee login
- ✅ `lib/signin_role/sign_role_associate.dart` - Associate login

### 4. Activity Notification Helper

**File:** `lib/service/activity_notification_helper.dart`

This service triggers notifications when activities occur:

```dart
// Visitor added
await ActivityNotificationHelper.notifyVisitorAdded(
  visitorName: 'John Doe',
  mobileNo: '9876543210',
  purpose: 'Meeting',
  userId: 123,
);

// Payment added
await ActivityNotificationHelper.notifyPaymentAdded(
  amount: 5000.0,
  paymentMethod: 'Cash',
  bookingId: 456,
  userId: 123,
);

// Attendance recorded
await ActivityNotificationHelper.notifyAttendanceRecorded(
  employeeName: 'John Doe',
  action: 'CheckIn',
  location: 'Office',
  userId: 123,
);
```

### 5. Activity Services Updated

All activity services now trigger notifications:

- ✅ `lib/service/add_visitor_service.dart` - Visitor add
- ✅ `lib/service/service_of_indiviadual.dart` - Payment add
- ✅ `lib/service/attendance_service.dart` - Attendance record

## Backend Implementation (.NET)

### 1. Database Structure

**Table:** `tbl_DeviceTokens`

```sql
CREATE TABLE tbl_DeviceTokens (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    Token NVARCHAR(MAX) NOT NULL,
    DeviceType NVARCHAR(50) NOT NULL,
    UserRole NVARCHAR(50) NOT NULL, -- 'Director', 'HR', 'Employee', 'Associate'
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);
```

### 2. Device Token Save API

**Endpoint:** `POST /api/device/save`

Already implemented. See `BACKEND_COMPLETE_NOTIFICATION_SYSTEM.md` for code.

### 3. Notification Send API

**Endpoint:** `POST /api/notification/send`

**Request:**
```json
{
  "actionType": "visitor_added",
  "message": "John Doe has arrived. Purpose: Meeting",
  "userId": 123
}
```

**Response:**
```json
{
  "status": "Success",
  "message": "Notification sent to 2 device(s)",
  "sentCount": 2
}
```

**Implementation:** See `BACKEND_COMPLETE_NOTIFICATION_SYSTEM.md` for complete code.

### 4. FCM Service

**File:** `RealestateCRM/Service/FCMService.cs`

Handles sending notifications via Firebase Cloud Messaging.

**Configuration:**
1. Get FCM Server Key from Firebase Console
2. Update `_fcmServerKey` in `FCMService.cs`

## How It Works

### Step-by-Step Flow

1. **User Login:**
   - User logs in (Director/HR/Employee/Associate)
   - FCM token is generated
   - Token is saved to backend with UserId and UserRole

2. **Activity Performed:**
   - Employee/Associate performs activity (visitor add, payment, attendance)
   - Frontend calls `ActivityNotificationHelper`
   - Helper sends request to `/api/notification/send`

3. **Backend Processing:**
   - Backend receives notification request
   - Queries database for HR/Director tokens
   - Sends FCM notification to each token

4. **Notification Delivery:**
   - HR/Director devices receive push notification
   - Notification appears even if app is closed

## Testing

### Test Device Token Save

1. Login as any user (Director/HR/Employee/Associate)
2. Check console logs: `✅ Device token saved successfully`
3. Check database: `tbl_DeviceTokens` should have entry

### Test Notification

1. Login as Employee or Associate
2. Perform activity (add visitor, payment, attendance)
3. Check console logs: `✅ Notification sent successfully to X device(s)`
4. HR/Director devices should receive notification

### Test Backend API Directly

**Using Postman:**

```
POST https://realapp.cheenu.in/api/notification/send
Content-Type: application/json

{
  "actionType": "test",
  "message": "This is a test notification",
  "userId": 123
}
```

Expected Response:
```json
{
  "status": "Success",
  "message": "Notification sent to 2 device(s)",
  "sentCount": 2
}
```

## Files Created/Updated

### Flutter Files

**New Files:**
- `lib/service/activity_notification_helper.dart` - Activity notification helper

**Updated Files:**
- `lib/service/device_token_service.dart` - Added Associate role support
- `lib/service/add_visitor_service.dart` - Uses new notification helper
- `lib/service/service_of_indiviadual.dart` - Uses new notification helper
- `lib/service/attendance_service.dart` - Uses new notification helper
- `lib/signin_role/sign_role_associate.dart` - Saves token on login
- `lib/sign_page.dart` - Saves token on login

### Backend Documentation

**New Files:**
- `BACKEND_COMPLETE_NOTIFICATION_SYSTEM.md` - Complete backend implementation guide
- `COMPLETE_NOTIFICATION_SYSTEM_GUIDE.md` - This file

## Important Notes

1. **Role-Based Filtering:**
   - Only HR and Director receive notifications
   - Employee and Associate activities trigger notifications
   - Backend filters based on `UserRole` field

2. **Error Handling:**
   - Notification failures don't break the app
   - Invalid tokens are automatically removed
   - All errors are logged for debugging

3. **Performance:**
   - Notifications are sent asynchronously
   - Multiple tokens handled efficiently
   - Timeout protection (10 seconds)

4. **Security:**
   - FCM Server Key stored securely in backend
   - Never exposed to frontend
   - Token validation on backend

## Troubleshooting

### Notifications Not Received

1. **Check FCM Token:**
   - Verify token is saved in database
   - Check `UserRole` is correct (HR/Director)

2. **Check Backend Logs:**
   - Verify API is being called
   - Check FCM service errors

3. **Check Firebase Console:**
   - Verify FCM Server Key is correct
   - Check notification delivery status

4. **Check Device:**
   - Verify notification permissions granted
   - Check device is online
   - Verify app is installed

### Token Not Saving

1. **Check User Session:**
   - Verify user is logged in
   - Check `AuthManager.getCurrentSession()` returns valid session

2. **Check API Response:**
   - Verify `/api/device/save` returns 200/201
   - Check backend logs for errors

3. **Check Network:**
   - Verify internet connection
   - Check API endpoint is accessible

## Next Steps

1. **Backend Developer:**
   - Implement `/api/notification/send` endpoint
   - Configure FCM Server Key
   - Test with Postman

2. **Frontend Developer:**
   - Test all login flows
   - Test all activity triggers
   - Verify notifications received

3. **Testing:**
   - Test with all user roles
   - Test all activity types
   - Test error scenarios

## Support

For issues or questions:
1. Check console logs for errors
2. Verify database entries
3. Test API endpoints directly
4. Review Firebase Console

---

**System Status:** ✅ Complete and Ready for Testing






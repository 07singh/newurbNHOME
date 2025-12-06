# Notification Debugging Guide - HR/Director Ko Notification Nahi Aa Raha

## Problem Diagnosis Steps

### Step 1: Check Device Tokens in Database

**SQL Query:**
```sql
SELECT * FROM tbl_DeviceTokens 
WHERE UserRole IN ('HR', 'Director')
ORDER BY CreatedAt DESC;
```

**Expected Result:**
- HR aur Director ke tokens database me hona chahiye
- Token NULL ya empty nahi hona chahiye
- UserRole exactly 'HR' ya 'Director' hona chahiye (case-sensitive check karein)

**If No Tokens Found:**
- HR/Director ne login nahi kiya
- Token save nahi hua
- UserRole sahi se save nahi hua

### Step 2: Check Frontend Logs

**Flutter Console me yeh logs check karein:**

1. **Login ke time:**
```
✅ Device token saved after HR login
✅ Device token saved to backend successfully
```

2. **Activity perform karne par:**
```
📤 Sending activity notification:
   Action: visitor_added
   Message: ...
✅ Notification sent successfully to X device(s)
```

**Agar logs nahi dikh rahe:**
- Activity service me notification call nahi ho rahi
- API call fail ho rahi hai

### Step 3: Check Backend API Response

**Postman se test karein:**

```
POST https://realapp.cheenu.in/api/notification/send
Content-Type: application/json

{
  "actionType": "test",
  "message": "Test notification",
  "userId": 123
}
```

**Expected Response:**
```json
{
  "status": "Success",
  "message": "Notification sent to 2 device(s)",
  "sentCount": 2
}
```

**Possible Issues:**
- 404 Error: API endpoint nahi hai
- 500 Error: Backend code me issue hai
- 200 but sentCount = 0: Tokens nahi mil rahe

### Step 4: Check FCM Service

**Backend me FCM Service check karein:**

1. **FCM Server Key sahi hai?**
   - Firebase Console → Project Settings → Cloud Messaging
   - Server Key copy karein
   - Backend me `FCMService.cs` me update karein

2. **FCM Service working hai?**
   - Test notification bhejein directly
   - Error logs check karein

## Common Issues and Solutions

### Issue 1: Tokens Database Me Nahin Hain

**Solution:**
1. HR/Director se login karwayein
2. Console logs check karein: `✅ Device token saved`
3. Database me verify karein

**Check Code:**
- `lib/service/device_token_service.dart` - Token save logic
- `lib/signin_role/sign_role_hr.dart` - HR login
- `lib/signin_role/sign_role_direct.dart` - Director login

### Issue 2: UserRole Sahi Se Save Nahi Ho Raha

**Check Database:**
```sql
SELECT UserId, UserRole, Token, CreatedAt 
FROM tbl_DeviceTokens 
WHERE UserId = [HR_USER_ID];
```

**Expected:** UserRole = 'HR' or 'Director'

**If Wrong:**
- `lib/service/device_token_service.dart` me role normalization check karein
- Backend me role save logic check karein

### Issue 3: Backend API 404 Error

**Solution:**
Backend me `/api/notification/send` endpoint implement karein.

**Code:** See `BACKEND_COMPLETE_NOTIFICATION_SYSTEM.md`

### Issue 4: Backend API 200 But sentCount = 0

**Possible Causes:**
1. Database me HR/Director tokens nahi hain
2. UserRole match nahi ho raha
3. Tokens invalid/expired hain

**Solution:**
```sql
-- Check tokens
SELECT COUNT(*) FROM tbl_DeviceTokens 
WHERE UserRole IN ('HR', 'Director') 
AND Token IS NOT NULL 
AND Token != '';

-- Check specific user
SELECT * FROM tbl_DeviceTokens 
WHERE UserId = [USER_ID] 
AND UserRole IN ('HR', 'Director');
```

### Issue 5: FCM Service Error

**Check Backend Logs:**
- FCM Server Key valid hai?
- Network connectivity hai?
- Firebase project sahi configure hai?

**Test FCM Directly:**
```csharp
// Test code
FCMService fcm = new FCMService();
await fcm.SendNotification(
    "DEVICE_TOKEN_HERE",
    "Test Title",
    "Test Message"
);
```

### Issue 6: Notifications Event APIs Se Nahi Bhej Rahe

**Solution:**
Backend me har event API me notification code add karein:

1. **Visitor Add API** (`/api/officevisitor/add`)
2. **Payment Add API** (`/api/AddPayment/Add`)
3. **Attendance Add API** (`/api/attendance/add`)

**Code:** See `BACKEND_COMPLETE_NOTIFICATION_SYSTEM.md`

## Quick Test Checklist

- [ ] HR/Director ne login kiya?
- [ ] Console me "Device token saved" dikha?
- [ ] Database me tokens hain?
- [ ] UserRole sahi hai ('HR' or 'Director')?
- [ ] Backend API `/api/notification/send` exists?
- [ ] FCM Server Key configured?
- [ ] Event APIs me notification code hai?
- [ ] Test notification Postman se bheja?

## Testing Steps

### Test 1: Token Save
1. HR se login karein
2. Console check: `✅ Device token saved`
3. Database check: Token save hua?

### Test 2: Notification API
1. Postman se `/api/notification/send` call karein
2. Response check: `sentCount > 0`?
3. HR/Director phone me notification aaya?

### Test 3: Activity Trigger
1. Employee se visitor add karein
2. Console check: `📤 Sending activity notification`
3. HR/Director phone me notification aaya?

## Debugging Commands

### Check Database
```sql
-- All HR/Director tokens
SELECT UserId, UserRole, LEFT(Token, 20) as TokenPreview, CreatedAt 
FROM tbl_DeviceTokens 
WHERE UserRole IN ('HR', 'Director')
ORDER BY CreatedAt DESC;

-- Count tokens
SELECT UserRole, COUNT(*) as TokenCount
FROM tbl_DeviceTokens
WHERE UserRole IN ('HR', 'Director')
GROUP BY UserRole;
```

### Check Backend Logs
- IIS Logs check karein
- Application logs check karein
- FCM service errors check karein

## Next Steps

1. **Database Check:** Tokens verify karein
2. **Backend API:** Implement karein agar nahi hai
3. **FCM Service:** Configure karein
4. **Event APIs:** Notification code add karein
5. **Test:** Step by step test karein

---

**Agar abhi bhi issue hai, to yeh information share karein:**
- Database query results
- Console logs
- Backend API response
- Error messages





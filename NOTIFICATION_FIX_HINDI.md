# Notification Issue Fix - HR/Director Ko Notification Nahi Aa Raha

## Problem Kya Hai?

HR aur Director ke phones par notifications nahi aa rahe hain jab Employee/Associate koi activity karte hain.

## Possible Issues Aur Solutions

### Issue 1: Backend API Implement Nahi Hai ⚠️

**Problem:** Frontend `/api/notification/send` ko call kar raha hai, lekin backend me yeh endpoint nahi hai.

**Solution:**
Backend developer ko yeh code implement karna hoga:

**File:** `BACKEND_COMPLETE_NOTIFICATION_SYSTEM.md` me complete code hai.

**Quick Fix:**
Backend me `/api/notification/send` endpoint add karein:

```csharp
[RoutePrefix("api/notification")]
public class NotificationController : ApiController
{
    [HttpPost]
    [Route("send")]
    public async Task<IHttpActionResult> SendNotification([FromBody] NotificationRequest model)
    {
        var db = new growup_realappdbEntities();
        var fcmService = new FCMService();

        // HR/Director ke tokens fetch karein
        var tokens = db.tbl_DeviceTokens
            .Where(x => (x.UserRole == "Director" || x.UserRole == "HR"))
            .Where(x => !string.IsNullOrEmpty(x.Token))
            .Select(x => x.Token)
            .ToList();

        if (tokens.Count == 0)
        {
            return Ok(new { status = "Success", message = "No HR/Director devices found", sentCount = 0 });
        }

        int successCount = 0;
        foreach (var token in tokens)
        {
            try
            {
                await fcmService.SendNotification(
                    token,
                    GetNotificationTitle(model.actionType),
                    model.message
                );
                successCount++;
            }
            catch { }
        }

        return Ok(new { status = "Success", message = $"Notification sent to {successCount} device(s)", sentCount = successCount });
    }
}
```

### Issue 2: Tokens Database Me Save Nahi Ho Rahe 🗄️

**Problem:** HR/Director ne login kiya, lekin tokens database me nahi hain.

**Check Karne Ka Tarika:**
```sql
SELECT * FROM tbl_DeviceTokens 
WHERE UserRole IN ('HR', 'Director');
```

**Solution:**
1. HR/Director se dobara login karwayein
2. Console logs check karein: `✅ Device token saved`
3. Database me verify karein

**Agar Token Save Nahi Ho Raha:**
- `lib/service/device_token_service.dart` check karein
- Backend `/api/device/save` API working hai?
- Network connection check karein

### Issue 3: UserRole Sahi Se Save Nahi Ho Raha 📝

**Problem:** Database me UserRole 'HR' ya 'Director' nahi hai, kuch aur hai.

**Check:**
```sql
SELECT UserId, UserRole, Token 
FROM tbl_DeviceTokens 
WHERE UserId = [HR_USER_ID];
```

**Expected:** UserRole = 'HR' or 'Director'

**Solution:**
- `lib/service/device_token_service.dart` me role normalization check karein
- Backend me role save logic verify karein

### Issue 4: FCM Service Configure Nahi Hai 🔥

**Problem:** Backend me FCM Server Key set nahi hai.

**Solution:**
1. Firebase Console → Project Settings → Cloud Messaging
2. Server Key copy karein
3. Backend `FCMService.cs` me update karein:

```csharp
private readonly string _fcmServerKey = "YOUR_ACTUAL_SERVER_KEY_HERE";
```

### Issue 5: Event APIs Me Notification Code Nahi Hai 📡

**Problem:** Backend me event APIs (visitor add, payment add, attendance add) me notification code nahi hai.

**Solution:**
Har event API me notification code add karein. Example:

**Visitor Add API:**
```csharp
[HttpPost]
[Route("add")]
public async Task<IHttpActionResult> AddVisitor([FromBody] AddVisitor model)
{
    // ... existing code ...
    db.SaveChanges();

    // ✅ Notification code add karein
    FCMService fcm = new FCMService();
    var tokens = db.tbl_DeviceTokens
        .Where(x => x.UserRole == "Director" || x.UserRole == "HR")
        .Where(x => !string.IsNullOrEmpty(x.Token))
        .Select(x => x.Token)
        .ToList();

    foreach (var token in tokens)
    {
        try
        {
            await fcm.SendNotification(
                token,
                "New Visitor Added",
                $"{model.Name} ({model.MobileNo}) has arrived. Purpose: {model.Purpose}"
            );
        }
        catch { }
    }

    return Ok(new { message = "Visitor added successfully" });
}
```

## Step-by-Step Fix

### Step 1: Database Check ✅

```sql
-- HR/Director ke tokens check karein
SELECT UserId, UserRole, LEFT(Token, 30) as TokenPreview, CreatedAt 
FROM tbl_DeviceTokens 
WHERE UserRole IN ('HR', 'Director')
ORDER BY CreatedAt DESC;
```

**Agar tokens nahi hain:**
- HR/Director se login karwayein
- Console logs check karein
- Database me verify karein

### Step 2: Backend API Test ✅

Postman se test karein:

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

**Agar 404 error:**
- Backend me endpoint implement karein

**Agar sentCount = 0:**
- Tokens database me nahi hain
- UserRole match nahi ho raha

### Step 3: FCM Service Check ✅

Backend me FCM service test karein:

```csharp
FCMService fcm = new FCMService();
await fcm.SendNotification(
    "DEVICE_TOKEN_HERE",
    "Test Title",
    "Test Message"
);
```

**Agar error:**
- FCM Server Key check karein
- Firebase project verify karein

### Step 4: Event APIs Check ✅

Har event API me notification code hai ya nahi:

1. `/api/officevisitor/add` - Visitor add
2. `/api/AddPayment/Add` - Payment add
3. `/api/attendance/add` - Attendance add

**Agar code nahi hai:**
- `BACKEND_COMPLETE_NOTIFICATION_SYSTEM.md` se code copy karein
- Har API me add karein

## Quick Test Checklist

- [ ] HR/Director ne login kiya?
- [ ] Console me "Device token saved" dikha?
- [ ] Database me tokens hain?
- [ ] UserRole sahi hai ('HR' or 'Director')?
- [ ] Backend API `/api/notification/send` exists?
- [ ] FCM Server Key configured?
- [ ] Event APIs me notification code hai?
- [ ] Test notification Postman se bheja?

## Testing

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

## Most Common Issue

**90% cases me yeh issue hota hai:**

Backend me `/api/notification/send` endpoint implement nahi hai, ya event APIs me notification code nahi hai.

**Solution:**
1. `BACKEND_COMPLETE_NOTIFICATION_SYSTEM.md` file read karein
2. Backend developer ko code share karein
3. Implement karwayein
4. Test karein

## Debug Helper Use Karein

Flutter app me debug helper use karein:

```dart
import '/utils/notification_debug_helper.dart';

// Complete status check
await NotificationDebugHelper.printSystemStatus();

// Token save check
await NotificationDebugHelper.checkTokenSave();

// Test notification
await NotificationDebugHelper.testNotification();
```

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





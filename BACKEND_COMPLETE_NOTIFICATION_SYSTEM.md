# Complete Notification System - Backend Implementation (.NET)

## Database Structure

### Table: `tbl_DeviceTokens`

```sql
CREATE TABLE tbl_DeviceTokens (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    Token NVARCHAR(MAX) NOT NULL,
    DeviceType NVARCHAR(50) NOT NULL, -- 'Android' or 'iOS'
    UserRole NVARCHAR(50) NOT NULL, -- 'Director', 'HR', 'Employee', 'Associate'
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    
    -- Indexes for performance
    INDEX IX_DeviceTokens_UserId (UserId),
    INDEX IX_DeviceTokens_UserRole (UserRole),
    INDEX IX_DeviceTokens_Token (Token)
);
```

## Backend API Endpoints

### 1. Save Device Token
**Endpoint:** `POST /api/device/save`

**Request Body:**
```json
{
  "UserId": 123,
  "Token": "fcm_token_string_here",
  "DeviceType": "Android",
  "UserRole": "Employee"
}
```

**Response:**
```json
{
  "message": "Device token saved successfully"
}
```

**Controller Code:**
```csharp
[RoutePrefix("api/device")]
public class DeviceController : ApiController
{
    private readonly growup_realappdbEntities db = new growup_realappdbEntities();

    [HttpPost]
    [Route("save")]
    public IHttpActionResult SaveDeviceToken([FromBody] AddDeviceToken model)
    {
        if (model == null)
            return BadRequest("Invalid data");

        if (string.IsNullOrEmpty(model.Token))
            return BadRequest("Token is required");

        var existing = db.tbl_DeviceTokens.FirstOrDefault(t => t.Token == model.Token);

        if (existing == null)
        {
            tbl_DeviceTokens device = new tbl_DeviceTokens
            {
                UserId = model.UserId,
                Token = model.Token,
                DeviceType = model.DeviceType,
                UserRole = model.UserRole,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            db.tbl_DeviceTokens.Add(device);
        }
        else
        {
            existing.UserId = model.UserId;
            existing.DeviceType = model.DeviceType;
            existing.UserRole = model.UserRole;
            existing.UpdatedAt = DateTime.Now;
        }

        db.SaveChanges();
        return Ok(new { message = "Device token saved successfully" });
    }
}

public class AddDeviceToken
{
    public int UserId { get; set; }
    public string Token { get; set; }
    public string DeviceType { get; set; }
    public string UserRole { get; set; }
}
```

### 2. Send Notification to HR/Director
**Endpoint:** `POST /api/notification/send`

**Request Body:**
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

**Controller Code:**
```csharp
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using RealestateCRM.Models;
using RealestateCRM.Service;

namespace RealestateCRM.Api
{
    [RoutePrefix("api/notification")]
    public class NotificationController : ApiController
    {
        private readonly growup_realappdbEntities db = new growup_realappdbEntities();
        private readonly FCMService _fcmService = new FCMService();

        [HttpPost]
        [Route("send")]
        public async Task<IHttpActionResult> SendNotification([FromBody] NotificationRequest model)
        {
            if (model == null)
                return BadRequest("Invalid data");

            if (string.IsNullOrEmpty(model.actionType) || string.IsNullOrEmpty(model.message))
                return BadRequest("actionType and message are required");

            try
            {
                // Get all HR and Director device tokens
                var tokens = db.tbl_DeviceTokens
                    .Where(x => (x.UserRole == "Director" || x.UserRole == "HR"))
                    .Where(x => !string.IsNullOrEmpty(x.Token))
                    .Select(x => new { x.Token, x.DeviceType })
                    .ToList();

                if (tokens.Count == 0)
                {
                    return Ok(new
                    {
                        status = "Success",
                        message = "No HR/Director devices found",
                        sentCount = 0
                    });
                }

                int successCount = 0;
                var invalidTokens = new List<string>();

                // Send notification to each device
                foreach (var device in tokens)
                {
                    try
                    {
                        await _fcmService.SendNotification(
                            device.Token,
                            GetNotificationTitle(model.actionType),
                            model.message
                        );
                        successCount++;
                    }
                    catch (Exception ex)
                    {
                        // Token might be invalid, mark for deletion
                        invalidTokens.Add(device.Token);
                        // Log error but continue with other tokens
                        System.Diagnostics.Debug.WriteLine($"Error sending to token: {ex.Message}");
                    }
                }

                // Remove invalid tokens from database
                if (invalidTokens.Any())
                {
                    var tokensToDelete = db.tbl_DeviceTokens
                        .Where(x => invalidTokens.Contains(x.Token))
                        .ToList();

                    db.tbl_DeviceTokens.RemoveRange(tokensToDelete);
                    db.SaveChanges();
                }

                return Ok(new
                {
                    status = "Success",
                    message = $"Notification sent to {successCount} device(s)",
                    sentCount = successCount
                });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        private string GetNotificationTitle(string actionType)
        {
            return actionType switch
            {
                "visitor_added" => "New Visitor Added",
                "payment_added" => "New Payment Added",
                "attendance_recorded" => "Attendance Recorded",
                "followup_added" => "New Follow-up Added",
                "booking_added" => "New Booking Added",
                _ => "New Activity"
            };
        }
    }

    public class NotificationRequest
    {
        public string actionType { get; set; }
        public string message { get; set; }
        public int? userId { get; set; }
    }
}
```

## FCM Service Implementation

**File:** `RealestateCRM/Service/FCMService.cs`

```csharp
using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace RealestateCRM.Service
{
    public class FCMService
    {
        private readonly string _fcmServerKey = "YOUR_FCM_SERVER_KEY"; // Get from Firebase Console
        private readonly string _fcmUrl = "https://fcm.googleapis.com/fcm/send";

        public async Task SendNotification(string token, string title, string body)
        {
            try
            {
                using (var client = new HttpClient())
                {
                    client.DefaultRequestHeaders.Authorization = 
                        new System.Net.Http.Headers.AuthenticationHeaderValue("key", "=" + _fcmServerKey);

                    var payload = new
                    {
                        to = token,
                        notification = new
                        {
                            title = title,
                            body = body,
                            sound = "default",
                            priority = "high"
                        },
                        data = new
                        {
                            click_action = "FLUTTER_NOTIFICATION_CLICK",
                            timestamp = DateTime.UtcNow.ToString("o")
                        },
                        priority = "high"
                    };

                    var json = JsonConvert.SerializeObject(payload);
                    var content = new StringContent(json, Encoding.UTF8, "application/json");

                    var response = await client.PostAsync(_fcmUrl, content);
                    
                    if (!response.IsSuccessStatusCode)
                    {
                        var errorContent = await response.Content.ReadAsStringAsync();
                        throw new Exception($"FCM Error: {response.StatusCode} - {errorContent}");
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"FCM Service Error: {ex.Message}");
                throw;
            }
        }
    }
}
```

## Example: Trigger Notification from Activity

### Visitor Add API Example

```csharp
[HttpPost]
[Route("add")]
public async Task<IHttpActionResult> AddVisitor([FromBody] AddVisitor model)
{
    // ... existing visitor add logic ...
    
    // Save visitor
    db.tbl_OfficeVisitors.Add(visitor);
    db.SaveChanges();

    // ✅ Send notification to HR/Director
    try
    {
        var notificationController = new NotificationController();
        await notificationController.SendNotification(new NotificationRequest
        {
            actionType = "visitor_added",
            message = $"{model.Name} ({model.MobileNo}) has arrived. Purpose: {model.Purpose}",
            userId = visitor.Id
        });
    }
    catch (Exception ex)
    {
        // Log error but don't fail the request
        System.Diagnostics.Debug.WriteLine($"Notification error: {ex.Message}");
    }
    
    return Ok(new { message = "Visitor added successfully" });
}
```

### Payment Add API Example

```csharp
[HttpPost]
[Route("add")]
public async Task<IHttpActionResult> AddPayment([FromBody] AddPayment model)
{
    // ... existing payment add logic ...
    
    // Save payment
    db.tbl_AddPayment.Add(payment);
    db.SaveChanges();

    // ✅ Send notification to HR/Director
    try
    {
        var notificationController = new NotificationController();
        await notificationController.SendNotification(new NotificationRequest
        {
            actionType = "payment_added",
            message = $"Payment of ₹{model.Paid_Amount} added via {model.Paid_Through} for Booking #{model.Booking_Id}",
            userId = payment.Id
        });
    }
    catch (Exception ex)
    {
        System.Diagnostics.Debug.WriteLine($"Notification error: {ex.Message}");
    }
    
    return Ok(new { message = "Payment added successfully" });
}
```

### Attendance Add API Example

```csharp
[HttpPost]
[Route("add")]
public async Task<IHttpActionResult> AddAttendance([FromBody] AddAttendance model)
{
    // ... existing attendance add logic ...
    
    // Save attendance
    db.tbl_Attendance.Add(attendance);
    db.SaveChanges();

    // ✅ Send notification to HR/Director
    try
    {
        string actionType = model.Action ?? "Attendance";
        string notificationTitle = actionType == "CheckIn" 
            ? "Check-In Recorded" 
            : actionType == "CheckOut" 
                ? "Check-Out Recorded" 
                : "Attendance Recorded";
        
        string notificationMessage = $"{model.EmployeeName} - {actionType} at {model.CheckInLocation}";

        var notificationController = new NotificationController();
        await notificationController.SendNotification(new NotificationRequest
        {
            actionType = "attendance_recorded",
            message = notificationMessage,
            userId = attendance.Id
        });
    }
    catch (Exception ex)
    {
        System.Diagnostics.Debug.WriteLine($"Notification error: {ex.Message}");
    }
    
    return Ok(new { message = "Attendance recorded successfully" });
}
```

## Helper Method for All Activities

Create a helper method to avoid code duplication:

```csharp
public static class NotificationHelper
{
    public static async Task NotifyHRAndDirector(string actionType, string message, int? userId = null)
    {
        try
        {
            var db = new growup_realappdbEntities();
            var fcmService = new FCMService();

            var tokens = db.tbl_DeviceTokens
                .Where(x => (x.UserRole == "Director" || x.UserRole == "HR"))
                .Where(x => !string.IsNullOrEmpty(x.Token))
                .Select(x => x.Token)
                .ToList();

            foreach (var token in tokens)
            {
                try
                {
                    await fcmService.SendNotification(
                        token,
                        GetNotificationTitle(actionType),
                        message
                    );
                }
                catch
                {
                    // Continue with other tokens
                }
            }
        }
        catch
        {
            // Don't throw - notification failure shouldn't break the app
        }
    }

    private static string GetNotificationTitle(string actionType)
    {
        return actionType switch
        {
            "visitor_added" => "New Visitor Added",
            "payment_added" => "New Payment Added",
            "attendance_recorded" => "Attendance Recorded",
            "followup_added" => "New Follow-up Added",
            "booking_added" => "New Booking Added",
            _ => "New Activity"
        };
    }
}
```

**Usage in APIs:**
```csharp
// After saving any activity
await NotificationHelper.NotifyHRAndDirector(
    "visitor_added",
    $"{visitor.Name} has arrived",
    visitor.Id
);
```

## Configuration

### Firebase Console Setup

1. Go to Firebase Console → Project Settings → Cloud Messaging
2. Copy **Server Key**
3. Update `FCMService.cs` with your server key:
   ```csharp
   private readonly string _fcmServerKey = "YOUR_ACTUAL_SERVER_KEY_HERE";
   ```

## Testing

### Test Notification Endpoint

```csharp
[HttpPost]
[Route("test")]
public async Task<IHttpActionResult> TestNotification()
{
    var notificationController = new NotificationController();
    var result = await notificationController.SendNotification(new NotificationRequest
    {
        actionType = "test",
        message = "This is a test notification",
        userId = null
    });
    return result;
}
```

## Important Notes

1. **Error Handling:** Notification failures should not break the main API flow
2. **Token Cleanup:** Invalid tokens are automatically removed
3. **Performance:** Consider using background jobs for large batches
4. **Security:** Keep FCM Server Key secure, never expose in frontend
5. **Logging:** Log all notification attempts for debugging






# Backend Notification Implementation Guide

## Overview
Yeh guide backend developer ke liye hai jo notification system implement karega. Frontend se notification requests aayengi, aur backend automatically sirf HR/Director ke devices ko notification bhejega.

## API Endpoint

### POST `/api/Notification/Send`

**Purpose:** Notification data receive karta hai aur sirf HR/Director ke devices ko notification bhejta hai.

**Request Body:**
```json
{
  "Title": "New Visitor Added",
  "Body": "John Doe (9876543210) has arrived. Purpose: Meeting",
  "NotificationType": "visitor_added",
  "Data": {
    "type": "visitor_added",
    "visitor_name": "John Doe",
    "visitor_mobile": "9876543210",
    "purpose": "Meeting",
    "date": "2024-01-15T10:30:00Z"
  }
}
```

**Response:**
```json
{
  "Status": "Success",
  "Message": "Notification sent to HR/Director devices",
  "SentCount": 2
}
```

## Implementation Steps

### Step 1: Create Notification Controller

```csharp
using System;
using System.Linq;
using System.Web.Http;
using RealestateCRM.Models;
using RealestateCRM.Service;

namespace RealestateCRM.Api
{
    [RoutePrefix("api/notification")]
    public class NotificationController : ApiController
    {
        private readonly growup_realappdbEntities db = new growup_realappdbEntities();
        private readonly FCMService fcm = new FCMService();

        [HttpPost]
        [Route("send")]
        public async System.Threading.Tasks.Task<IHttpActionResult> SendNotification([FromBody] NotificationRequest model)
        {
            if (model == null)
                return BadRequest("Invalid data");

            try
            {
                // Get HR/Director device tokens
                var tokens = db.tbl_DeviceTokens
                               .Where(x => x.UserRole == "Director" || x.UserRole == "HR")
                               .Where(x => !string.IsNullOrEmpty(x.Token))
                               .Select(x => x.Token)
                               .ToList();

                if (tokens.Count == 0)
                {
                    return Ok(new { 
                        Status = "Success", 
                        Message = "No HR/Director devices found",
                        SentCount = 0 
                    });
                }

                int successCount = 0;
                var invalidTokens = new List<string>();

                // Send notification to each token
                foreach (var token in tokens)
                {
                    try
                    {
                        await fcm.SendNotification(
                            token,
                            model.Title,
                            model.Body
                        );
                        successCount++;
                    }
                    catch (Exception ex)
                    {
                        // Token might be invalid
                        invalidTokens.Add(token);
                        // Log error but continue
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
                    Status = "Success",
                    Message = $"Notification sent to {successCount} device(s)",
                    SentCount = successCount
                });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
    }

    public class NotificationRequest
    {
        public string Title { get; set; }
        public string Body { get; set; }
        public string NotificationType { get; set; }
        public Dictionary<string, object> Data { get; set; }
    }
}
```

### Step 2: Add Notification to Event APIs

#### Visitor Add API (`/api/officevisitor/add`)

```csharp
[HttpPost]
[Route("add")]
public async System.Threading.Tasks.Task<IHttpActionResult> AddVisitor([FromBody] AddVisitor model)
{
    // ... existing visitor add logic ...
    
    // After successfully saving visitor
    db.SaveChanges();
    
    // Send notification to HR/Director
    FCMService fcm = new FCMService();
    var tokens = db.tbl_DeviceTokens
                   .Where(x => x.UserRole == "Director" || x.UserRole == "HR")
                   .Where(x => !string.IsNullOrEmpty(x.Token))
                   .Select(x => x.Token)
                   .ToList();

    foreach (var token in tokens)
    {
        await fcm.SendNotification(
            token,
            "New Visitor Added",
            $"{model.Name} ({model.MobileNo}) has arrived. Purpose: {model.Purpose}"
        );
    }
    
    return Ok(new { message = "Visitor added successfully" });
}
```

#### Payment Add API (`/api/AddPayment/Add`)

```csharp
[HttpPost]
[Route("add")]
public async System.Threading.Tasks.Task<IHttpActionResult> AddPayment([FromBody] AddPayment model)
{
    // ... existing payment add logic ...
    
    // After successfully saving payment
    db.SaveChanges();
    
    // Send notification to HR/Director
    FCMService fcm = new FCMService();
    var tokens = db.tbl_DeviceTokens
                   .Where(x => x.UserRole == "Director" || x.UserRole == "HR")
                   .Where(x => !string.IsNullOrEmpty(x.Token))
                   .Select(x => x.Token)
                   .ToList();

    foreach (var token in tokens)
    {
        await fcm.SendNotification(
            token,
            "New Payment Added",
            $"Payment of ₹{model.Paid_Amount} added via {model.Paid_Through} for Booking #{model.Booking_Id}"
        );
    }
    
    return Ok(new { message = "Payment added successfully" });
}
```

#### Attendance Add API (`/api/attendance/add`)

```csharp
[HttpPost]
[Route("add")]
public async System.Threading.Tasks.Task<IHttpActionResult> AddAttendance([FromBody] AddAttendance model)
{
    // ... existing attendance add logic ...
    
    // After successfully saving attendance
    db.SaveChanges();
    
    // Send notification to HR/Director
    FCMService fcm = new FCMService();
    var tokens = db.tbl_DeviceTokens
                   .Where(x => x.UserRole == "Director" || x.UserRole == "HR")
                   .Where(x => !string.IsNullOrEmpty(x.Token))
                   .Select(x => x.Token)
                   .ToList();

    string actionType = model.Action ?? "Attendance";
    string notificationTitle = actionType == "CheckIn" 
        ? "Check-In Recorded" 
        : actionType == "CheckOut" 
            ? "Check-Out Recorded" 
            : "Attendance Recorded";
    
    string notificationBody = $"{model.EmployeeName} - {actionType} at {model.CheckInLocation}";

    foreach (var token in tokens)
    {
        await fcm.SendNotification(
            token,
            notificationTitle,
            notificationBody
        );
    }
    
    return Ok(new { message = "Attendance recorded successfully" });
}
```

## FCMService Implementation

Agar `FCMService` class nahi hai, to yeh implement karein:

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
        private readonly string _fcmServerKey = "YOUR_FCM_SERVER_KEY"; // Firebase Console se
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
                        priority = "high"
                    };

                    var json = JsonConvert.SerializeObject(payload);
                    var content = new StringContent(json, Encoding.UTF8, "application/json");

                    var response = await client.PostAsync(_fcmUrl, content);
                    
                    if (!response.IsSuccessStatusCode)
                    {
                        // Log error
                        var errorContent = await response.Content.ReadAsStringAsync();
                        // Handle error (e.g., invalid token)
                    }
                }
            }
            catch (Exception ex)
            {
                // Log error
                throw;
            }
        }
    }
}
```

## Important Points

1. **UserRole Filtering:** Sirf HR/Director ke tokens ko notification bhejein
2. **Token Validation:** Invalid tokens ko database se remove karein
3. **Error Handling:** FCM errors ko handle karein gracefully
4. **Logging:** Har notification send attempt ko log karein
5. **Performance:** Multiple tokens ko efficiently handle karein

## Testing

1. **Postman se test karein:**
   - POST request to `/api/Notification/Send`
   - Request body me notification data bhejein
   - Response me success count check karein

2. **Database check karein:**
   - `tbl_DeviceTokens` me HR/Director ke tokens verify karein
   - Invalid tokens automatically delete ho jayenge

3. **FCM Console check karein:**
   - FCM dashboard me notification delivery status dekh sakte hain

## Notes

- FCM Server Key Firebase Console se milti hai
- Token refresh hone par automatically update hota hai (frontend se)
- Invalid tokens automatically remove ho jayenge
- Frontend se bhi notification API call ho sakti hai (backup ke liye)






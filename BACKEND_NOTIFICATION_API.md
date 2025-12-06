# Backend Notification API Documentation

## Overview
Yeh documentation backend developer ke liye hai jo notification system implement karega. Frontend se notification request aayegi, aur backend automatically sirf HR/Director ke devices ko notification bhejega.

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

### Step 1: Database Query
HR/Director ke tokens fetch karein:

```sql
SELECT dt.Token, dt.DeviceType, u.UserId, u.Position, u.LoginType
FROM tbl_DeviceTokens dt
INNER JOIN tbl_Users u ON dt.UserId = u.UserId
WHERE (LOWER(u.Position) IN ('hr', 'director') 
   OR LOWER(u.LoginType) IN ('hr', 'director')
   OR LOWER(u.UserRole) IN ('hr', 'director'))
AND dt.Token IS NOT NULL
AND dt.Token != ''
```

### Step 2: FCM Notification Send
Har token ke liye FCM notification bhejein:

**FCM API Endpoint:** `https://fcm.googleapis.com/fcm/send`

**Headers:**
```
Authorization: key=YOUR_FCM_SERVER_KEY
Content-Type: application/json
```

**Request Body (Android):**
```json
{
  "to": "DEVICE_FCM_TOKEN",
  "notification": {
    "title": "New Visitor Added",
    "body": "John Doe (9876543210) has arrived. Purpose: Meeting",
    "sound": "default",
    "priority": "high"
  },
  "data": {
    "type": "visitor_added",
    "visitor_name": "John Doe",
    "visitor_mobile": "9876543210",
    "purpose": "Meeting",
    "date": "2024-01-15T10:30:00Z"
  },
  "priority": "high"
}
```

**Request Body (iOS):**
```json
{
  "to": "DEVICE_FCM_TOKEN",
  "notification": {
    "title": "New Visitor Added",
    "body": "John Doe (9876543210) has arrived. Purpose: Meeting",
    "sound": "default",
    "badge": "1"
  },
  "data": {
    "type": "visitor_added",
    "visitor_name": "John Doe",
    "visitor_mobile": "9876543210",
    "purpose": "Meeting",
    "date": "2024-01-15T10:30:00Z"
  },
  "apns": {
    "headers": {
      "apns-priority": "10"
    }
  }
}
```

### Step 3: Error Handling
- Agar token invalid hai, to database se delete kar dein
- Agar FCM request fail hoti hai, to log karein lekin app crash nahi hona chahiye
- Success count return karein

## Notification Types

1. **visitor_added** - Jab visitor add hota hai
2. **payment_added** - Jab payment add hota hai
3. **attendance_recorded** - Jab attendance record hota hai

## Important Points

1. **Role Filtering:** Sirf HR/Director ke tokens ko notification bhejein
2. **Token Validation:** Invalid tokens ko database se remove karein
3. **Error Handling:** FCM errors ko handle karein gracefully
4. **Logging:** Har notification send attempt ko log karein
5. **Performance:** Multiple tokens ko batch me send karein (optional)

## Example C# Implementation

```csharp
[HttpPost("Send")]
public async Task<IActionResult> SendNotification([FromBody] NotificationRequest request)
{
    try
    {
        // Get HR/Director device tokens
        var hrDirectorTokens = await _dbContext.DeviceTokens
            .Join(_dbContext.Users, dt => dt.UserId, u => u.UserId, (dt, u) => new { dt, u })
            .Where(x => 
                (x.u.Position.ToLower() == "hr" || x.u.Position.ToLower() == "director") ||
                (x.u.LoginType.ToLower() == "hr" || x.u.LoginType.ToLower() == "director") ||
                (x.u.UserRole.ToLower() == "hr" || x.u.UserRole.ToLower() == "director")
            )
            .Where(x => !string.IsNullOrEmpty(x.dt.Token))
            .Select(x => new { x.dt.Token, x.dt.DeviceType })
            .ToListAsync();

        int successCount = 0;
        var invalidTokens = new List<string>();

        foreach (var device in hrDirectorTokens)
        {
            try
            {
                var fcmRequest = new
                {
                    to = device.Token,
                    notification = new
                    {
                        title = request.Title,
                        body = request.Body,
                        sound = "default",
                        priority = "high"
                    },
                    data = request.Data,
                    priority = "high"
                };

                var httpClient = new HttpClient();
                httpClient.DefaultRequestHeaders.Authorization = 
                    new System.Net.Http.Headers.AuthenticationHeaderValue("key", "=" + FCM_SERVER_KEY);

                var response = await httpClient.PostAsJsonAsync(
                    "https://fcm.googleapis.com/fcm/send", 
                    fcmRequest
                );

                if (response.IsSuccessStatusCode)
                {
                    successCount++;
                }
                else
                {
                    // Token might be invalid
                    invalidTokens.Add(device.Token);
                }
            }
            catch (Exception ex)
            {
                // Log error but continue with other tokens
                _logger.LogError(ex, $"Error sending notification to token: {device.Token}");
            }
        }

        // Remove invalid tokens from database
        if (invalidTokens.Any())
        {
            await _dbContext.DeviceTokens
                .Where(dt => invalidTokens.Contains(dt.Token))
                .ExecuteDeleteAsync();
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
        _logger.LogError(ex, "Error in SendNotification");
        return StatusCode(500, new { Status = "Error", Message = ex.Message });
    }
}
```

## Testing

1. Postman se test karein:
   - POST request to `/api/Notification/Send`
   - Request body me notification data bhejein
   - Response me success count check karein

2. Database check karein:
   - `tbl_DeviceTokens` me HR/Director ke tokens verify karein
   - Invalid tokens automatically delete ho jayenge

3. FCM Console check karein:
   - FCM dashboard me notification delivery status dekh sakte hain

## Notes

- FCM Server Key Firebase Console se milti hai
- Token refresh hone par automatically update hota hai (frontend se)
- Invalid tokens automatically remove ho jayenge






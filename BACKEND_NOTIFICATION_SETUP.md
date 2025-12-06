# Backend Notification Setup - Important

## Current Situation

Frontend se notification API call ho rahi hai, lekin backend me `/api/Notification/Send` endpoint nahi hai (404 error).

## Solution: Two Options

### Option 1: Event APIs Me Direct Notification (Recommended) ✅

Backend me har event API me directly notification bhejein. Yeh zyada efficient hai.

#### Visitor Add API (`/api/officevisitor/add`)

```csharp
[HttpPost]
[Route("add")]
public async System.Threading.Tasks.Task<IHttpActionResult> AddVisitor([FromBody] AddVisitor model)
{
    // ... existing visitor add logic ...
    
    // Save visitor
    db.tbl_OfficeVisitors.Add(visitor);
    db.SaveChanges();
    
    // ✅ Send notification to HR/Director
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
        catch
        {
            // Continue with other tokens
        }
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
    
    // Save payment
    db.tbl_AddPayment.Add(payment);
    db.SaveChanges();
    
    // ✅ Send notification to HR/Director
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
                "New Payment Added",
                $"Payment of ₹{model.Paid_Amount} added via {model.Paid_Through} for Booking #{model.Booking_Id}"
            );
        }
        catch
        {
            // Continue with other tokens
        }
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
    
    // Save attendance
    db.tbl_Attendance.Add(attendance);
    db.SaveChanges();
    
    // ✅ Send notification to HR/Director
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
        try
        {
            await fcm.SendNotification(
                token,
                notificationTitle,
                notificationBody
            );
        }
        catch
        {
            // Continue with other tokens
        }
    }
    
    return Ok(new { message = "Attendance recorded successfully" });
}
```

### Option 2: Separate Notification API (Optional)

Agar aap separate notification API banana chahte hain, to yeh implement karein:

```csharp
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
            var tokens = db.tbl_DeviceTokens
                           .Where(x => x.UserRole == "Director" || x.UserRole == "HR")
                           .Where(x => !string.IsNullOrEmpty(x.Token))
                           .Select(x => x.Token)
                           .ToList();

            if (tokens.Count == 0)
            {
                return Ok(new { Status = "Success", SentCount = 0 });
            }

            int successCount = 0;
            foreach (var token in tokens)
            {
                try
                {
                    await fcm.SendNotification(token, model.Title, model.Body);
                    successCount++;
                }
                catch
                {
                    // Continue
                }
            }

            return Ok(new { Status = "Success", SentCount = successCount });
        }
        catch (Exception ex)
        {
            return InternalServerError(ex);
        }
    }
}
```

## Recommendation

**Option 1 (Event APIs me direct notification) recommend karta hoon** kyunki:
- ✅ Zyada efficient hai
- ✅ Single API call se kaam ho jata hai
- ✅ Frontend se separate API call ki zarurat nahi
- ✅ Booking add API me already implement hai

## Current Status

- ✅ Frontend se notification calls ho rahi hain (optional - 404 error handle ho raha hai)
- ⚠️ Backend me event APIs me notification add karni hogi
- ✅ Booking add API me already notification hai (example ke liye)

## Next Steps

1. Visitor Add API me notification add karein
2. Payment Add API me notification add karein
3. Attendance Add API me notification add karein
4. FCMService properly configured hai ya nahi check karein
5. Testing karein - events trigger karke notification verify karein

## FCMService Check

Agar `FCMService` class nahi hai, to `BACKEND_NOTIFICATION_IMPLEMENTATION.md` file me implementation dekh sakte hain.






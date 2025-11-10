# 🔐 AuthManager Quick Reference Guide

Quick code snippets for using the AuthManager in your Flutter app.

---

## 📚 Import Statement

```dart
import '/service/auth_manager.dart';
import '/Model/user_session.dart';
```

---

## 🔑 Common Operations

### **1. Save Login Session (After Successful Login)**

```dart
// After successful API login
final session = UserSession.fromLogin(
  userId: loginData.id.toString(),
  userName: loginData.name ?? 'Unknown',
  userMobile: loginData.mobile ?? '',
  userRole: loginData.position ?? 'Employee',
  loginType: 'employee', // 'director', 'employee', 'hr', or 'associate'
  profilePic: loginData.profilePic,
  phone: loginData.mobile,
  position: loginData.position,
);

bool saved = await AuthManager.saveSession(session);
if (saved) {
  print('Session saved successfully');
}
```

---

### **2. Check if User is Logged In**

```dart
bool isLoggedIn = await AuthManager.isLoggedIn();

if (isLoggedIn) {
  // User is logged in
  print('User is already logged in');
} else {
  // User is not logged in
  print('Please login');
}
```

---

### **3. Get Current Session Data**

```dart
UserSession? session = await AuthManager.getCurrentSession();

if (session != null) {
  print('User ID: ${session.userId}');
  print('Name: ${session.userName}');
  print('Role: ${session.userRole}');
  print('Login Type: ${session.loginType}');
  print('Profile Image URL: ${session.fullProfileImageUrl}');
  print('Phone: ${session.phone}');
  print('Last Login: ${session.lastLoginTime}');
} else {
  print('No active session');
}
```

---

### **4. Get Login Type Only**

```dart
String? loginType = await AuthManager.getLoginType();

if (loginType != null) {
  switch (loginType) {
    case 'director':
      print('Director logged in');
      break;
    case 'employee':
      print('Employee logged in');
      break;
    case 'hr':
      print('HR logged in');
      break;
    case 'associate':
      print('Associate logged in');
      break;
  }
}
```

---

### **5. Logout / Clear Session**

```dart
await AuthManager.clearSession();
print('User logged out');

// Navigate to login page
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => const LoginPage()),
);
```

---

### **6. Update Session Data (e.g., after profile update)**

```dart
bool updated = await AuthManager.updateSession(
  userName: 'Updated Name',
  profilePic: 'new_profile.jpg',
  userRole: 'Senior Manager',
);

if (updated) {
  print('Session updated successfully');
}
```

---

### **7. Get All User Details as Map**

```dart
Map<String, dynamic>? userDetails = await AuthManager.getUserDetails();

if (userDetails != null) {
  print('User Details: $userDetails');
  
  String userId = userDetails['userId'] ?? '';
  String userName = userDetails['userName'] ?? '';
  String userRole = userDetails['userRole'] ?? '';
  String? profileUrl = userDetails['fullProfileImageUrl'];
}
```

---

## 🎨 UI Integration Examples

### **Example 1: Show User Info in AppBar**

```dart
class MyDashboard extends StatefulWidget {
  @override
  _MyDashboardState createState() => _MyDashboardState();
}

class _MyDashboardState extends State<MyDashboard> {
  String userName = 'User';
  String userRole = 'Role';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final session = await AuthManager.getCurrentSession();
    if (session != null) {
      setState(() {
        userName = session.userName ?? 'User';
        userRole = session.userRole ?? 'Role';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$userName - $userRole'),
      ),
      body: Center(child: Text('Dashboard Content')),
    );
  }
}
```

---

### **Example 2: Conditional Widget Based on Login Type**

```dart
class ConditionalFeature extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthManager.getLoginType(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final loginType = snapshot.data;
          
          // Show different content based on login type
          if (loginType == 'director' || loginType == 'hr') {
            return ElevatedButton(
              onPressed: () {},
              child: Text('Admin Feature'),
            );
          } else {
            return Text('Not available for your role');
          }
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

---

### **Example 3: Profile Picture from Session**

```dart
class ProfilePicture extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserSession?>(
      future: AuthManager.getCurrentSession(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final session = snapshot.data!;
          final imageUrl = session.fullProfileImageUrl;
          
          return CircleAvatar(
            radius: 40,
            backgroundImage: imageUrl != null
                ? NetworkImage(imageUrl)
                : AssetImage('assets/default_avatar.png') as ImageProvider,
          );
        }
        return CircleAvatar(
          radius: 40,
          child: Icon(Icons.person),
        );
      },
    );
  }
}
```

---

### **Example 4: Protected Route (Require Login)**

```dart
class ProtectedRoute extends StatelessWidget {
  final Widget child;

  const ProtectedRoute({required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthManager.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData && snapshot.data == true) {
          // User is logged in, show the protected content
          return child;
        } else {
          // User is not logged in, redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LoginPage()),
            );
          });
          return Scaffold(body: Center(child: Text('Redirecting...')));
        }
      },
    );
  }
}

// Usage:
MaterialPageRoute(
  builder: (_) => ProtectedRoute(
    child: AdminDashboard(),
  ),
);
```

---

### **Example 5: Custom Logout Dialog**

```dart
Future<void> showLogoutDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Confirm Logout'),
      content: Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Clear session
            await AuthManager.clearSession();
            
            // Close dialog
            Navigator.pop(context);
            
            // Navigate to login
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => LoginPage()),
              (route) => false,
            );
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Logged out successfully')),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('Logout'),
        ),
      ],
    ),
  );
}
```

---

### **Example 6: Auto-Refresh on Session Update**

```dart
class DashboardWithAutoRefresh extends StatefulWidget {
  @override
  _DashboardWithAutoRefreshState createState() => _DashboardWithAutoRefreshState();
}

class _DashboardWithAutoRefreshState extends State<DashboardWithAutoRefresh> {
  UserSession? session;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final loadedSession = await AuthManager.getCurrentSession();
    setState(() {
      session = loadedSession;
    });
  }

  Future<void> _updateProfile(String newName) async {
    // Update session
    await AuthManager.updateSession(userName: newName);
    
    // Reload session to reflect changes
    await _loadSession();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(session?.userName ?? 'Loading...'),
      ),
      body: session != null
          ? Column(
              children: [
                Text('Name: ${session!.userName}'),
                Text('Role: ${session!.userRole}'),
                ElevatedButton(
                  onPressed: () => _updateProfile('New Name'),
                  child: Text('Update Name'),
                ),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
```

---

## 🔍 Debugging Helper

```dart
// Print all session data for debugging
Future<void> debugPrintSession() async {
  final session = await AuthManager.getCurrentSession();
  print('=== SESSION DEBUG INFO ===');
  if (session != null) {
    print('User ID: ${session.userId}');
    print('User Name: ${session.userName}');
    print('User Mobile: ${session.userMobile}');
    print('User Role: ${session.userRole}');
    print('Profile Pic: ${session.profilePic}');
    print('Login Type: ${session.loginType}');
    print('Phone: ${session.phone}');
    print('Position: ${session.position}');
    print('Last Login: ${session.lastLoginTime}');
    print('Is Logged In: ${session.isLoggedIn}');
    print('Full Profile URL: ${session.fullProfileImageUrl}');
  } else {
    print('No active session');
  }
  print('========================');
}

// Call it in your code:
await debugPrintSession();
```

---

## ⚡ Performance Tips

1. **Cache session data in widget state** if you need it multiple times
2. **Use FutureBuilder** for one-time session loads in UI
3. **Don't call AuthManager methods in build()** - use initState or FutureBuilder
4. **Reload session after updates** to reflect changes in UI

---

## 🎯 Best Practices

✅ **DO:**
- Save session immediately after successful login
- Clear session on logout
- Validate session on app startup (done in splash screen)
- Update session when profile changes

❌ **DON'T:**
- Call AuthManager methods repeatedly in loops
- Store sensitive data like passwords in session
- Forget to clear session on logout
- Make session operations in build method

---

## 📱 Testing Checklist

- [ ] Test save session after login
- [ ] Test get current session
- [ ] Test auto-login on app restart
- [ ] Test logout clears session
- [ ] Test session expiry (30 days)
- [ ] Test update session
- [ ] Test multiple login types

---

## 🆘 Common Issues

### **Issue: Session is null after saving**
```dart
// Make sure you await the save operation
await AuthManager.saveSession(session); // ✅
AuthManager.saveSession(session); // ❌ Don't forget await
```

### **Issue: UI not updating after session update**
```dart
// Reload the data after updating
await AuthManager.updateSession(userName: 'New Name');
await _loadUserData(); // Refresh your state
setState(() {}); // Trigger rebuild
```

---

**Last Updated**: November 8, 2025  
**Version**: 1.0.0




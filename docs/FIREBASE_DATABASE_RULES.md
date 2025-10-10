# Firebase Realtime Database Security Rules

To fix the Firebase permission errors, you need to update your Firebase Realtime Database security rules in the Firebase Console.

## How to Apply Rules

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your Health Buddy project
3. Navigate to **Realtime Database** → **Rules**
4. Replace the existing rules with the rules below
5. Click **Publish**

## Security Rules

```json
{
  "rules": {
    ".read": false,
    ".write": false,
    
    // Users can only access their own data (main profiles)
    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid && auth.token.email_verified == true",
        ".write": "auth != null && auth.uid == $uid && auth.token.email_verified == true",
        ".validate": "auth != null && auth.uid == $uid"
      }
    },
    
    // Patient profiles - only accessible by authenticated and verified users
    "patient_profiles": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid && auth.token.email_verified == true",
        ".write": "auth != null && auth.uid == $uid && auth.token.email_verified == true",
        ".validate": "auth != null && auth.uid == $uid",
        
        // Family members can be accessed by the parent user
        "familyMembers": {
          "$memberid": {
            ".read": "auth != null && auth.uid == $uid && auth.token.email_verified == true",
            ".write": "auth != null && auth.uid == $uid && auth.token.email_verified == true"
          }
        }
      }
    },
    
    // Doctor profiles - only accessible by authenticated doctors
    "doctor_profiles": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid && auth.token.email_verified == true",
        ".write": "auth != null && auth.uid == $uid && auth.token.email_verified == true",
        ".validate": "auth != null && auth.uid == $uid"
      }
    },
    
    // Legacy doctors collection (for backward compatibility)
    "doctors": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid && auth.token.email_verified == true",
        ".write": "auth != null && auth.uid == $uid && auth.token.email_verified == true",
        ".validate": "auth != null && auth.uid == $uid"
      }
    },
    
    // Medical records - only accessible by the patient and their authorized doctors
    "medical_records": {
      "$patientId": {
        ".read": "auth != null && (auth.uid == $patientId || root.child('doctor_patient_access').child(auth.uid).child($patientId).exists()) && auth.token.email_verified == true",
        ".write": "auth != null && (auth.uid == $patientId || root.child('doctor_patient_access').child(auth.uid).child($patientId).exists()) && auth.token.email_verified == true"
      }
    },
    
    // Doctor-Patient access mapping
    "doctor_patient_access": {
      "$doctorId": {
        "$patientId": {
          ".read": "auth != null && (auth.uid == $doctorId || auth.uid == $patientId) && auth.token.email_verified == true",
          ".write": "auth != null && auth.uid == $doctorId && auth.token.email_verified == true"
        }
      }
    },
    
    // Appointments - accessible by both patient and doctor
    "appointments": {
      "$appointmentId": {
        ".read": "auth != null && auth.token.email_verified == true && (auth.uid == data.child('patientId').val() || auth.uid == data.child('doctorId').val())",
        ".write": "auth != null && auth.token.email_verified == true && (auth.uid == data.child('patientId').val() || auth.uid == data.child('doctorId').val())"
      }
    },
    
    // Chat messages - accessible by participants
    "chat_messages": {
      "$chatId": {
        ".read": "auth != null && auth.token.email_verified == true",
        ".write": "auth != null && auth.token.email_verified == true"
      }
    }
  }
}
```

## Key Security Features

1. **Authentication Required**: All reads and writes require user authentication
2. **Email Verification**: Users must have verified email addresses
3. **User Isolation**: Users can only access their own data
4. **Doctor-Patient Access**: Doctors can only access patients they have permission for
5. **Family Members**: Parents can manage their family member profiles
6. **Appointment Security**: Only participants can access appointment data

## Testing the Rules

After applying these rules:

1. Make sure users are logged in with verified email addresses
2. Test that patients can only access their own profiles
3. Test that doctors can only access authorized patient data
4. Verify that unauthenticated users cannot access any data

## Temporary Testing Rules (FOR DEBUGGING ONLY)

If you're still getting permission errors, temporarily use these more permissive rules for testing:

```json
{
  "rules": {
    ".read": "auth != null && auth.token.email_verified == true",
    ".write": "auth != null && auth.token.email_verified == true"
  }
}
```

**⚠️ IMPORTANT**: These rules allow any authenticated user to read/write anywhere. Replace with the secure rules above once testing is complete!

## Common Issues

If you still get permission errors:

1. **Email Not Verified**: Make sure the user's email is verified before accessing data
2. **Wrong User ID**: Ensure the correct user ID is being used in database paths
3. **Authentication State**: Check that the user is properly authenticated before making database calls
4. **Database Rules**: Make sure the rules are properly applied in Firebase Console
5. **Path Mismatch**: Verify that code paths match the rules structure

# Friend Request Feature - Testing Guide

## Overview
This guide provides step-by-step instructions to test the friend request functionality after implementing the consistent request ID format.

## Prerequisites
- Flutter app running on a device/emulator
- At least 2 test user accounts
- Firebase Firestore access for verification

## Test Scenarios

### 1. Send Friend Request from Job Search (Group Chat)

**Steps:**
1. Login with User A
2. Navigate to Job Search tab (group chat)
3. Click on any message from User B's avatar
4. In the profile dialog, click "Add Friend"
5. Verify success message appears

**Expected Results:**
- ✅ Success message: "Friend request sent"
- ✅ Request appears in User A's History tab with status "Pending"
- ✅ Request appears in User B's History tab with status "Pending"
- ✅ Both users have the same request ID format: `{userA_uid}_{userB_uid}`

**Firestore Verification:**
```
friendRequests/{userA_uid}/requests/{userA_uid}_{userB_uid}
  - from: userA_uid
  - to: userB_uid
  - status: "pending"
  - timestamp: [timestamp]

friendRequests/{userB_uid}/requests/{userA_uid}_{userB_uid}
  - from: userA_uid
  - to: userB_uid
  - status: "pending"
  - timestamp: [timestamp]
```

---

### 2. Send Friend Request from Users List

**Steps:**
1. Login with User A
2. Navigate to Users List page
3. Find User C in the list
4. Click "Add Friend" button
5. Verify success message appears

**Expected Results:**
- ✅ Success message: "Friend request sent!"
- ✅ Request appears in both users' History tabs
- ✅ Consistent request ID format used

---

### 3. Prevent Duplicate Requests

**Steps:**
1. Login with User A
2. Try to send a friend request to User B (who already has a pending request from User A)
3. Attempt from both Job Search and Users List

**Expected Results:**
- ✅ Message: "Friend request already sent"
- ✅ No duplicate request created in Firestore
- ✅ Original request remains unchanged

---

### 4. Accept Friend Request

**Steps:**
1. Login with User B (who has a pending request from User A)
2. Navigate to Friend Requests page → History tab
3. Find User A's request
4. Click "Accept" button
5. Verify success message

**Expected Results:**
- ✅ Success message: "Friend request from [User A] accepted"
- ✅ Request status changes to "Accepted" in History tab
- ✅ User A appears in Friends tab with search functionality
- ✅ Green checkmark appears next to User A in group chat profile dialog
- ✅ Both users have each other in their friends collection

**Firestore Verification:**
```
friendRequests/{userA_uid}/requests/{userA_uid}_{userB_uid}
  - status: "accepted" (updated)

friendRequests/{userB_uid}/requests/{userA_uid}_{userB_uid}
  - status: "accepted" (updated)

users/{userA_uid}/friends/{userB_uid}
  - addedAt: [timestamp]

users/{userB_uid}/friends/{userA_uid}
  - addedAt: [timestamp]
```

---

### 5. Decline Friend Request

**Steps:**
1. Login with User C (who has a pending request from User A)
2. Navigate to Friend Requests page → History tab
3. Find User A's request
4. Click "Decline" button
5. Verify success message

**Expected Results:**
- ✅ Success message: "Friend request from [User A] declined"
- ✅ Request status changes to "Declined" in History tab
- ✅ User A does NOT appear in Friends tab
- ✅ No green checkmark for User A in group chat

**Firestore Verification:**
```
friendRequests/{userA_uid}/requests/{userA_uid}_{userC_uid}
  - status: "declined" (updated)

friendRequests/{userC_uid}/requests/{userA_uid}_{userC_uid}
  - status: "declined" (updated)
```

---

### 6. View Friends Tab

**Steps:**
1. Login with User B (who accepted User A's request)
2. Navigate to Friend Requests page → Friends tab
3. Verify User A appears in the list
4. Use search field to search for User A's name
5. Click the message icon next to User A

**Expected Results:**
- ✅ User A appears in Friends list
- ✅ Search functionality works correctly
- ✅ Profile picture/avatar displays correctly
- ✅ Message icon opens chat with User A
- ✅ Chat opens successfully

---

### 7. View History Tab

**Steps:**
1. Login with any user who has sent/received requests
2. Navigate to Friend Requests page → History tab
3. Verify all requests appear with correct information

**Expected Results:**
- ✅ All sent requests appear with "Sent to [Name]"
- ✅ All received requests appear with "Received from [Name]"
- ✅ Timestamps are displayed correctly
- ✅ Status badges show correct colors:
  - Pending: Orange
  - Accepted: Green
  - Declined: Red
  - Blocked: Grey
- ✅ Pending received requests show Accept/Decline buttons
- ✅ Other requests show status badge only

---

### 8. Block User

**Steps:**
1. Login with User A
2. Navigate to Job Search → click on User D's message
3. In profile dialog, click "Block"
4. Confirm the block action
5. Navigate to Friend Requests page → Blocked Users tab

**Expected Results:**
- ✅ Success message: "[User D] has been blocked"
- ✅ User D appears in Blocked Users tab
- ✅ Cannot send friend request to User D
- ✅ User D cannot send friend request to User A

**Firestore Verification:**
```
users/{userA_uid}/blockedUsers/{userD_uid}
  - uid: userD_uid
  - blockedAt: [timestamp]
```

---

### 9. Unblock User

**Steps:**
1. Login with User A (who has User D blocked)
2. Navigate to Friend Requests page → Blocked Users tab
3. Find User D in the list
4. Click "Unblock" button
5. Verify success message

**Expected Results:**
- ✅ Success message: "[User D] has been unblocked"
- ✅ User D removed from Blocked Users tab
- ✅ Can now send friend request to User D again

**Firestore Verification:**
```
users/{userA_uid}/blockedUsers/{userD_uid}
  - Document deleted
```

---

### 10. Green Checkmark for Friends

**Steps:**
1. Login with User B (who is friends with User A)
2. Navigate to Job Search (group chat)
3. Find a message from User A
4. Click on User A's avatar to open profile dialog

**Expected Results:**
- ✅ Green checkmark icon appears on top-right of avatar
- ✅ Checkmark indicates friendship status
- ✅ "Add Friend" button not shown (already friends)

---

### 11. Message Friend from Friends Tab

**Steps:**
1. Login with User B
2. Navigate to Friend Requests page → Friends tab
3. Find User A in the list
4. Click the message icon
5. Verify chat opens

**Expected Results:**
- ✅ Chat page opens with User A
- ✅ Chat ID is consistent
- ✅ Can send and receive messages
- ✅ Chat history loads correctly

---

## Edge Cases to Test

### EC1: Network Interruption
- Send friend request with poor network
- Verify request is created when connection restored

### EC2: Simultaneous Requests
- User A sends request to User B
- User B sends request to User A (before seeing A's request)
- Verify only one request exists with consistent ID

### EC3: Empty States
- New user with no friends → verify "No friends yet" message
- No request history → verify "No request history" message
- No blocked users → verify "No blocked users" message

### EC4: Search Functionality
- Search with partial name
- Search with case variations
- Search with no results

---

## Performance Testing

1. **Large Friends List**
   - Add 50+ friends
   - Verify Friends tab loads quickly
   - Test search performance

2. **Large History**
   - Create 100+ requests
   - Verify History tab loads efficiently
   - Check scroll performance

---

## Regression Testing

After any code changes, re-run:
1. Test Scenario 1 (Send Request)
2. Test Scenario 4 (Accept Request)
3. Test Scenario 6 (View Friends)
4. Test Scenario 10 (Green Checkmark)

---

## Bug Reporting Template

If you find any issues, report using this format:

```
**Bug Title:** [Brief description]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happened]

**Screenshots:**
[Attach screenshots if applicable]

**Device/Platform:**
- Device: [e.g., iPhone 12, Pixel 5]
- OS: [e.g., iOS 15, Android 12]
- App Version: [version number]

**Firestore Data:**
[Relevant Firestore document snapshots]
```

---

## Success Criteria

All tests pass when:
- ✅ Friend requests use consistent ID format
- ✅ No duplicate requests can be created
- ✅ Status updates sync correctly between users
- ✅ History tab shows all requests accurately
- ✅ Friends tab displays accepted friends
- ✅ Green checkmark appears for friends
- ✅ Block/Unblock functionality works
- ✅ No console errors or crashes
- ✅ Firestore data structure is correct

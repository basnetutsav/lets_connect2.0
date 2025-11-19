# TODO List for Friends Feature Implementation

- [x] Modify `lib/pages/job_search.dart` to add green checkmark icon next to avatar in profile dialog if user is friends
- [x] Modify `lib/pages/friend_request.dart` to add third tab "Friends" with search TextField and friends list
- [x] Update TabController in `friend_request.dart` to length 3 and add new tab
- [x] Fix history to show all past friend requests with timestamps
- [x] Test profile dialog green tick for friends
- [x] Test new Friends tab search functionality
- [x] Test history tab shows all requests
- [x] Fix history to store sent requests in sender's collection
- [x] Fix friend request ID inconsistency across all files
  - [x] Updated `lib/pages/job_search.dart` to use consistent request ID format `'${fromUid}_$toUid'`
  - [x] Verified `lib/services/user_service.dart` uses consistent format
  - [x] Ensured both sender and receiver collections use same request ID

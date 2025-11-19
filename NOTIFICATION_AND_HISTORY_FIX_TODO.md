# Notification and History Tab Fix - TODO

## Tasks to Complete

### 1. Fix Notification Dialog (lib/pages/notification.dart)
- [x] Fix vertical text display issue
- [x] Add proper constraints to ListTile content
- [x] Make action buttons more compact (changed to IconButtons)
- [x] Add Expanded widgets for proper text layout
- [x] Add maxLines and overflow properties

### 2. Fix History Tab (lib/pages/friend_request.dart)
- [x] Fix "BOTTOM OVERFLOWED BY 40 PIXELS" error
- [x] Reduce vertical padding for pending requests
- [x] Make action buttons more compact (changed to Row layout)
- [x] Adjust spacing and font sizes

### 3. Testing
- [ ] Test notification dialog with long usernames
- [ ] Test history tab with pending requests
- [ ] Verify no overflow on small screens

## Changes Made

### Notification Dialog (lib/pages/notification.dart):
1. **Replaced ListTile with custom Row layout**:
   - Used `Expanded` widget to ensure text gets proper horizontal space
   - Prevents text from displaying vertically
   
2. **Changed action buttons from TextButton to IconButton**:
   - Accept: Green check circle icon
   - Decline: Red cancel icon
   - Block: Grey block icon
   - More compact, takes less horizontal space
   
3. **Added proper text constraints**:
   - Title: `maxLines: 1` with `TextOverflow.ellipsis`
   - Subtitle: `maxLines: 2` with `TextOverflow.ellipsis`
   - Responsive font sizes based on screen width

4. **Improved layout**:
   - Action buttons in a Column on the right
   - Main content (title + subtitle) in Expanded widget on the left
   - Proper padding and margins

### History Tab (lib/pages/friend_request.dart):
1. **Changed action buttons layout**:
   - From Column (vertical) to Row (horizontal)
   - Reduced height requirement significantly
   
2. **Made layout more compact for pending requests**:
   - Smaller avatar radius (16-18px vs 18-20px)
   - Smaller font sizes (12-13px vs 13-14px)
   - Reduced padding and margins
   - Set `dense: true` for all items
   - Set `isThreeLine: false` to reduce height
   
3. **Added conditional sizing**:
   - `hasPendingActions` flag to detect pending requests
   - More compact sizing when action buttons are present
   - Normal sizing for accepted/declined/blocked requests
   
4. **Optimized spacing**:
   - Reduced vertical spacing between subtitle elements
   - Smaller card margins
   - Tighter content padding for pending requests

## Expected Results:
- ✅ Notification text displays horizontally (not vertically)
- ✅ No "BOTTOM OVERFLOWED" error in history tab
- ✅ Action buttons are compact and don't cause layout issues
- ✅ Responsive design works on all screen sizes

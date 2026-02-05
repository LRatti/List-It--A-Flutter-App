# Camera Feature Implementation

## Overview

This document describes the implementation of the camera feature for the register shopping list screen. The feature allows users to take photos of receipts to automatically extract prices and quantities for purchased products.

**Status**: ✅ UI and navigation flow implemented  
**Next Step**: OCR/AI integration for price and quantity extraction

---

## Implementation Summary

### 1. Files Created/Modified

#### New Files
- **`lib/screens/camera/receipt_camera_screen.dart`**: Camera screen with photo capture functionality
- **`test/screens/camera/receipt_camera_screen_test.dart`**: Basic tests for camera screen

#### Modified Files
- **`pubspec.yaml`**: Added `camera: ^0.11.0+2` dependency
- **`android/app/src/main/AndroidManifest.xml`**: Added camera permissions
- **`ios/Runner/Info.plist`**: Added camera usage description
- **`lib/screens/lists/register-list/register_shopping_list_screen_mobile.dart`**: Updated camera button to navigate to camera screen

### 2. Architecture

```
UI Layer:
  register_shopping_list_screen_mobile.dart (Camera button)
      ↓ (persists changes before navigation)
  receipt_camera_screen.dart (Camera UI)
      ↓ (captures photo)
  Dialog (Progress indicator)
      ↓ (returns to register screen)
  register_shopping_list_screen_mobile.dart (Shows updated list)

Data Flow:
  User makes changes → Camera button pressed → persistChanges() called
  → Camera screen opens → Photo taken → Check button → Dialog shown
  → Returns to register screen (data persisted, photo discarded for now)
```

### 3. UI Components

#### Camera Button (in register_shopping_list_screen_mobile.dart)
- **Location**: Floating action button (top, mini)
- **Icon**: `Icons.camera_alt`
- **Color**: Primary container
- **Action**: Persists current changes, then navigates to camera screen
- **Tooltip**: "Scan receipt"

#### Camera Screen (receipt_camera_screen.dart)
**Elements:**
1. **Back Button** (Top-left, always visible)
   - Icon: `Icons.arrow_back`
   - Circular background with semi-transparent black
   - Action: Returns to register screen (discards photo)

2. **Camera Preview** (Full screen)
   - Real-time camera feed
   - Uses back camera by default
   - Fitted to screen with proper aspect ratio

3. **Photo Trigger Button** (Bottom center, before photo)
   - Large circular white button with primary color border
   - Size: 70x70 pixels
   - Action: Captures photo

4. **Captured Image** (Full screen, after photo)
   - Shows the captured image
   - Replaces camera preview
   - Fit: contain (preserves aspect ratio)

5. **Check Button** (Top-right, after photo)
   - Icon: `Icons.check`
   - Circular background with primary color
   - Action: Shows processing dialog, then returns

6. **Reload Button** (Bottom center, after photo)
   - Icon: `Icons.refresh`
   - Circular background with primary color
   - Action: Discards photo and returns to camera preview

#### Progress Dialog
- **Trigger**: Check button pressed
- **Content**: Circular progress indicator + message
- **Message**: "Extracting prices and quantities..."
- **Duration**: 2 seconds (placeholder)
- **Dismissible**: No (cannot be dismissed by user)
- **Action**: Auto-dismisses and returns to register screen

### 4. Logic and Flow

#### Camera Button Press
1. Get controller from provider
2. Call `controller.persistChanges()` to save quantity/price changes to SQLite
3. Navigate to camera screen using `MaterialPageRoute`
4. If error occurs, show error snackbar

#### Camera Screen Initialization
1. Request available cameras
2. Select back camera (or first available)
3. Initialize `CameraController` with high resolution
4. Set state to show camera preview
5. If error, show error message with back button

#### Photo Capture
1. Call `controller.takePicture()`
2. Store `XFile` in state
3. Update UI to show captured image
4. Show check button and reload button
5. Hide camera preview and trigger button

#### Retake Photo
1. Clear `_capturedImage` state
2. UI automatically switches back to camera preview
3. Show trigger button, hide check and reload buttons

#### Confirm Photo
1. Show modal dialog with progress indicator
2. Wait 2 seconds (placeholder for future OCR/AI processing)
3. Dismiss dialog
4. Pop navigation stack to return to register screen
5. Photo is discarded (future: will be processed)

#### Back Button
1. Pop navigation stack
2. Return to register screen
3. Photo is discarded
4. Changes remain persisted (from before camera was opened)

### 5. Data Management

#### Before Camera Screen
- **Action**: `controller.persistChanges()` is called
- **Effect**: All quantity and price updates are saved to SQLite
- **Sync**: Changes are synced to Firestore via sync engine

#### During Camera Screen
- **Photo Storage**: Temporary (in device cache)
- **No Data Changes**: No modifications to shopping list data
- **Photo Lifecycle**: Exists only during camera session

#### After Camera Screen
- **Photo**: Discarded (not saved to permanent storage)
- **List State**: Remains as it was when camera was opened
- **Future**: Photo will be processed and data will be updated

### 6. Permissions

#### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

#### iOS (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to your camera to scan receipts for automatic price and quantity extraction.</string>
```

### 7. Error Handling

#### Camera Initialization Failures
- No cameras available → Error message with back button
- Permission denied → Error message (camera package handles permission request)
- Initialization failed → Error message with details

#### Photo Capture Failures
- Show error snackbar
- User can try again or go back

#### Navigation Context Lost
- All navigation actions check `if (mounted)` before executing
- Prevents crashes when widget is disposed

### 8. UI Consistency

#### Color Scheme
- **Primary color**: Used for check button background, trigger button border
- **Primary container**: Used for camera FAB background
- **Surface/Background**: Black background for camera screen (standard for camera UIs)
- **Error color**: Used for error icons and messages

#### Typography
- Follows app's text theme
- White text on black background for camera screen
- Standard body text for dialogs

#### Dark/Light Mode
- Camera screen is always dark (black background)
- Dialogs follow system theme
- Icons and text have proper contrast

---

## Testing

### Manual Testing Checklist
- [x] Camera button visible in register screen
- [ ] Camera permission requested on first use
- [ ] Camera preview shows correctly
- [ ] Back button returns to register screen
- [ ] Photo trigger captures image
- [ ] Captured image displays correctly
- [ ] Reload button returns to camera preview
- [ ] Check button shows progress dialog
- [ ] Dialog displays for 2 seconds
- [ ] Returns to register screen after dialog
- [ ] Changes persist correctly before/after camera
- [ ] Error handling works for camera initialization failures

### Unit Tests
- Basic widget rendering tests created
- Camera hardware tests limited in test environment
- Full integration testing requires device/emulator

---

## Next Steps and Future Enhancements

### Phase 1: Complete Current Implementation ✅
- [x] UI components
- [x] Navigation flow
- [x] Data persistence before camera
- [x] Basic error handling

### Phase 2: OCR/AI Integration (Not Yet Implemented)
**Goal**: Extract prices and quantities from receipt image

**Approach Options**:
1. **Google ML Kit** (Text Recognition)
   - Add dependency: `google_mlkit_text_recognition`
   - Process captured image
   - Extract text from receipt
   - Parse for product names, prices, quantities

2. **Google Gemini AI** (Already available in app)
   - Send image to Gemini API
   - Request structured JSON response with products/prices
   - Parse and update shopping list

3. **Custom Backend Service**
   - Upload image to backend
   - Use cloud OCR service
   - Return parsed data

**Implementation Steps**:
1. Save captured image to temporary storage
2. Process image with chosen OCR/AI method
3. Parse extracted text for:
   - Product names (match with existing products)
   - Quantities
   - Prices
4. Update corresponding `PurchasedProduct` entries
5. Call `controller.persistChanges()` with new values
6. Show success/failure message
7. Update UI to reflect changes

**Challenges**:
- Receipt formats vary by supermarket
- Text recognition accuracy
- Matching product names to existing products
- Handling partial matches
- Error cases (no match, ambiguous results)

### Phase 3: Enhanced UX
- [ ] Photo cropping/editing before confirmation
- [ ] Manual adjustment of extracted values
- [ ] Preview of matched products before applying
- [ ] Confidence scores for matches
- [ ] Ability to save receipt images for later reference
- [ ] Support for multiple photos (multi-page receipts)

### Phase 4: Advanced Features
- [ ] Receipt history (saved images)
- [ ] Automatic supermarket detection from receipt
- [ ] Learning user's receipt formats
- [ ] Bulk import from multiple receipts
- [ ] Export receipts for expense tracking

---

## Known Limitations

1. **Photo Not Persisted**: Currently, photos are discarded after the dialog
2. **No OCR**: Price and quantity extraction not implemented
3. **No Product Matching**: Cannot match receipt items to shopping list products
4. **Camera Permission**: No custom permission request UI (uses system dialog)
5. **Single Photo Only**: Cannot take multiple photos in one session
6. **No Image Editing**: Cannot crop, rotate, or adjust captured image

---

## Dependencies

### Added
- `camera: ^0.11.0+2` - Flutter camera plugin for photo capture

### Existing (Used)
- `flutter_riverpod` - State management
- `flutter/material.dart` - UI framework

### Future (For OCR/AI)
- `google_mlkit_text_recognition` (Option 1)
- `google_generative_ai` (Option 2, already available)
- `http` (Option 3, already available)

---

## Conclusion

The camera feature UI and navigation flow is fully implemented and ready for use. The next critical step is implementing OCR/AI integration to fulfill the feature's purpose: automatic extraction of prices and quantities from receipt photos.

The current implementation provides a solid foundation with:
- Clean, intuitive UI
- Proper data persistence
- Robust error handling
- Consistent with app architecture
- Ready for OCR/AI integration

**Recommended Next Action**: Integrate Google Gemini AI (already available in the app) for receipt text extraction, as it can handle complex layouts and provide structured output without additional dependencies.

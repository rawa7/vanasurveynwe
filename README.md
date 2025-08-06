# Vana Survey App

A beautiful and intuitive Flutter mobile application for conducting surveys with multi-language support.

## Features

### 🎨 Design
- Beautiful UI with Vana brand colors (#6E514E, #D9B26F, black, white)
- Modern Material Design 3 components
- Custom themed interface with rounded corners and shadows
- Responsive layout that works on different screen sizes

### 🌍 Multi-Language Support
- English (en)
- Kurdish (fa) 
- Arabic (ar)
- Dynamic language switching
- Right-to-left (RTL) text support for Arabic

### 📋 Survey Features
- **Multiple Field Types:**
  - Text input fields
  - Dropdown selections
  - Multiple choice checkboxes
  - Star rating (1-5 stars)
  - Emoji rating (5 emotions)
  
- **Conditional Logic:**
  - Fields can be shown/hidden based on other field values
  - Dynamic form rendering based on dependencies

- **Form Validation:**
  - Required field validation
  - Real-time form completion checking
  - User-friendly error messages

### 🔄 Data Management
- Fetches live survey data from API
- Real-time form submission
- Error handling with retry functionality
- Loading states and progress indicators

### 🏠 Home Screen
- Displays Vana logo prominently
- Lists all available surveys with creation dates
- Beautiful card-based layout
- Pull-to-refresh functionality
- Empty state and error handling

### 📱 Survey Taking Experience
- Clean, distraction-free interface
- Progress through fields smoothly
- Language switcher in header
- Introduction and conclusion text support
- Success confirmation after submission

## API Integration

The app integrates with the following endpoints:

- `GET https://dasroor.com/forms/get_public_forms.php` - Fetch available surveys
- `GET https://dasroor.com/forms/get_form.php?id={id}` - Get detailed form structure
- `GET https://dasroor.com/forms/get_titleandintro.php?id={id}` - Get form titles and introductions
- `POST https://dasroor.com/forms/submit_form.php` - Submit survey responses

## Technical Architecture

### Dependencies
- `flutter` - Core framework
- `http: ^1.2.0` - HTTP client for API calls  
- `intl: ^0.19.0` - Internationalization support
- `cupertino_icons` - iOS-style icons

### Project Structure
```
lib/
├── main.dart                    # App entry point
├── constants/
│   └── app_colors.dart         # Brand colors and theme constants
├── models/
│   ├── survey_form.dart        # Survey list model
│   └── form_detail.dart        # Detailed form and field models
├── services/
│   └── api_service.dart        # HTTP API client
├── screens/
│   ├── home_screen.dart        # Survey listing page
│   └── survey_screen.dart      # Survey taking interface
└── widgets/
    └── survey_field_widget.dart # Reusable form field components
```

### Key Components

#### Models
- `SurveyForm` - Basic survey information for listing
- `FormDetail` - Complete form structure with fields and metadata
- `FormField` - Individual form field with multi-language support
- `FieldCondition` - Conditional display logic
- `FormResponse` - Survey submission format

#### Services
- `ApiService` - Handles all HTTP communication with backend
- Error handling and response parsing
- Type-safe API calls

#### UI Components
- `HomeScreen` - Survey discovery and selection
- `SurveyScreen` - Form completion interface  
- `SurveyFieldWidget` - Renders different field types

## Installation & Setup

1. Ensure Flutter is installed and configured
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Add your logo image to `assets/logo/logo.png`
5. Run `flutter run` to start the app

## Assets

Place the Vana logo in:
```
assets/logo/logo.png
```

The app will gracefully fall back to a default icon if the logo is not found.

## Customization

### Colors
Modify `lib/constants/app_colors.dart` to change the app's color scheme:
- `primary`: #6E514E (brown)
- `secondary`: #D9B26F (gold)
- Additional colors for backgrounds and text

### API Endpoints  
Update `lib/services/api_service.dart` to change the base URL or endpoints.

### Languages
Add additional languages by extending the models and UI components with new language codes.

## Error Handling

The app includes comprehensive error handling:
- Network connectivity issues
- API server errors  
- Invalid form data
- Missing resources
- Graceful fallbacks and user feedback

## Performance

- Efficient list rendering with `ListView.builder`
- Lazy loading of form details
- Minimal API calls with proper caching
- Smooth animations and transitions

## Support

This app supports modern Android and iOS devices with Flutter 3.7.0+.
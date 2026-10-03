# Fan Zone - A Smart Food Ordering System for Stadiums

## Overview

Fan Zone is a graduation project developed to enhance the experience of attending live events at stadiums by enabling fans to order food and beverages directly from their seats using a mobile application.

The system helps reduce congestion at food stands and allows fans to place and track their orders without leaving their seats.

## Key Features

### QR Code Integration

Each seat is assigned a unique QR code. Scanning the QR code identifies the user's seat and allows them to access the food menu and place an order.

### Menu Ordering System

Fans can browse a categorized menu and place orders directly from their seats. Each order is linked to the corresponding seat number and stored using Firebase Cloud Firestore.

### Real-Time Order Tracking

Users can track the progress of their orders through different statuses, from processing to delivery, using a dynamic visual interface.

### Admin Dashboard

Admins can view incoming orders, update their statuses, and manage the order fulfillment process through a dedicated admin interface.

### Manual Seat Entry

If QR code scanning is unavailable or unsuccessful, users can manually enter their seat number to continue with the ordering process.

### Interactive Stadium Map

The application includes an interactive stadium map that displays seating areas, exits, and facilities to improve navigation and usability.

## Technologies Used

- **Flutter** - Mobile application development
- **Dart** - Programming language
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - Cloud database
- **GoRouter** - Navigation and routing
- **Provider** - State management
- **Python** - QR code generation

## How to Run the Project

### Prerequisites

- Flutter SDK
- Dart SDK
- Visual Studio Code or Android Studio
- A configured Firebase project

### Installation

1. Clone the repository:

```bash
git clone https://github.com/YOUR-USERNAME/FanZone.git
```

2. Open the project in Visual Studio Code or Android Studio.

3. Install the required Flutter dependencies:

```bash
flutter pub get
```

4. Configure Firebase for the project.

5. Run the application:

```bash
flutter run
```

## QR Code Generation

Python was used to generate the QR codes assigned to stadium seats. These QR codes are used within the application to identify seats and support the food ordering process.

## Academic Project

This project was developed for academic purposes as part of a Bachelor's Degree in Information Technology.


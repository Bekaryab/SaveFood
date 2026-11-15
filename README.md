SaveFood
<p align="center">
  <strong>Save food. Save money.</strong>
</p><p align="center">
  An iOS application concept that helps customers discover discounted surplus food from local stores and food businesses.
</p><p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-iOS-0A7EA4?logo=apple&logoColor=white">
  <img alt="Language" src="https://img.shields.io/badge/language-Swift-orange?logo=swift&logoColor=white">
  <img alt="UI" src="https://img.shields.io/badge/UI-SwiftUI-blue">
  <img alt="Minimum iOS" src="https://img.shields.io/badge/iOS-17%2B-black?logo=apple&logoColor=white">
  <img alt="Backend" src="https://img.shields.io/badge/backend-Firebase-FFCA28?logo=firebase&logoColor=black">
</p>Overview
SaveFood is designed to connect customers with stores, bakeries, cafés, and other food businesses that have products available at a discount. Instead of throwing away unsold food, businesses can offer it at a reduced price, while customers can find useful deals nearby.

The project focuses on two account roles:
- Customer — discovers discounted products, saves favorites, and adds offers to a shopping cart.
- Seller — represents a food business that will be able to publish and manage offers.
The current repository contains an actively developed iOS prototype. Customer-facing discovery and offer-detail flows are implemented with local sample data. Firebase Authentication is integrated in the authentication flow, while Firestore profile persistence and the seller/backend workflows still require configuration and further development.
Current Features
Authentication
- Welcome and authentication flow built with SwiftUI.
- Customer and seller role selection.
- Email/password registration and sign-in through Firebase Authentication.
- Existing Firebase session check and sign-out support.
- User profile data is written to a Firestore users collection after registration (Firestore must be enabled and configured).
- Form validation and user-facing authentication error messages.
- RealityKit 3D onboarding scene featuring a shopping cart and animated food models.
- Separate 3D authentication carousel with store, discount, and map-pin models.
- Model preloading and caching to reduce repeated 3D asset loading.
Customer discovery
- Product feed with two-column offer cards.
- Promotional banner carousel.
- Product categories, including fruits, vegetables, bakery, dairy, prepared food, and desserts.
- Search by product name, venue, or category.
- City selection UI with a set of predefined cities.
- Discount filtering.
- Product image loading with local-image fallback and in-memory image caching.
Offer details
Selecting an offer opens a detailed sheet containing:
- Product and venue names.
- Current price, previous price, and discount percentage.
- Production date and expiry date fields.
- Discount reason, such as surplus stock or ripeness.
- Product description.
- Favorite action and native share action.
- Quantity selector and calculated total.
- Add-to-cart action.
Favorites and cart
- Add or remove products from favorites.
- Dedicated Favorites tab with an empty state.
- Add products to the cart and increase the quantity of an existing cart item.
- Cart item count shown on the tab bar.
- Cart summary with product, venue, quantity, and line total.
Map filters
The current Map entry opens a filter sheet with:
- Map/list display-mode selection.
- Distance choices of 1, 3, 5, and 10 km.
- Product category selection.
- Minimum discount slider.
- “Only available” toggle.
Implementation note: the current screen is a map-filter interface. Live MapKit rendering, real store coordinates, nearby-store search, and route calculation are not yet connected.
Technology Stack
Technology	Purpose
Swift	Primary programming language
SwiftUI	Application interface and navigation
RealityKit	3D scenes and animated USDZ models
UIKit	Selected platform integrations and image handling
MapKit	Map-related feature foundation
Observation	Observable view-model state
Firebase Authentication	Email/password registration and sign-in
Cloud Firestore	User profile document storage
Swift Package Manager	External package dependencies
XCTest	Test target and test structure


Architecture
The project is organized by application layers and feature areas. The structure is intended to keep UI, presentation state, domain concepts, and data access separate as the application grows.
SaveFood/
├── App/
│   ├── AppDependencies.swift
│   ├── AppRouter.swift
│   ├── AppSession.swift
│   └── RootView.swift
├── Core/
│   ├── Components/
│   ├── DesignSystem/
│   ├── Extensions/
│   ├── Location/
│   └── Utilities/
├── Data/
│   ├── DTO/
│   ├── Mock/
│   └── Remote/
├── Domain/
│   ├── Models/
│   └── Repositories/
└── Features/
    ├── Authentication/
    │   ├── Models/
    │   ├── Services/
    │   ├── ViewModels/
    │   └── Views/
    ├── Business/
    │   ├── Dashboard/
    │   ├── Offers/
    │   ├── Profile/
    │   └── Reservations/
    └── Customer/
        ├── Explore/
        ├── OfferDetails/
        ├── Profile/
        └── Reservations/

SaveFoodTests/
Main implementation areas
- Features contains feature-specific SwiftUI views, view models, and models.
- Core contains shared UI components, design-system definitions, utilities, and location abstractions.
- Domain contains the intended application models and repository contracts.
- Data contains DTO, mock, and remote-data layer scaffolding.
- App contains application-level composition and routing files.
Some files in App, Core, Data, Domain, Business, Customer/Profile, Customer/Reservations, and SaveFoodTests are currently scaffolding or empty placeholders. The repository structure shows the intended direction; it should not be interpreted as meaning every listed feature or data layer is production-ready.
Firebase Setup
SaveFood uses Firebase Authentication and Cloud Firestore.
1. Create a Firebase project
1. Open the Firebase Console.
2. Create a Firebase project or select an existing project.
3. Add an iOS application to the Firebase project.
4. Use the same bundle identifier as the Xcode target. The current project configuration uses Bekarys.SaveFood.
5. Download GoogleService-Info.plist and add it to the SaveFood app target in Xcode.
2. Enable Authentication
In Firebase Console, open Authentication → Sign-in method and enable Email/Password.
3. Enable Cloud Firestore
1. Open Build → Firestore Database.
2. Create the default Firestore database.
3. Confirm that the Cloud Firestore API is enabled for the linked Google Cloud project.
4. Configure Firestore Security Rules before using the app with real accounts.
The registration flow writes a user document to:
users/{uid}
The current profile fields are:
{
  "uid": "FIREBASE_AUTH_UID",
  "fullName": "Example User",
  "email": "user@example.com",
  "role": "customer",
  "createdAt": "SERVER_TIMESTAMP"
}
role is currently either customer or seller. Passwords are handled by Firebase Authentication and must never be stored in Firestore.

A basic Firestore rule design should ensure that an authenticated user can only read or write their own users/{uid} document. Review and adapt the rules to the full data model before launch; do not use open test-mode rules in production.
Firebase configuration and security
GoogleService-Info.plist is a project-specific Firebase client configuration file. When using your own Firebase project, replace it with the configuration file downloaded for your iOS app. Do not add Firebase Admin SDK service-account JSON files, private keys, passwords, or other server-side credentials to the repository. Restrict API keys where appropriate and enforce access through Firebase Authentication and Firestore Security Rules.
Requirements
- macOS with Xcode.
- An Apple development team configured in Xcode for physical-device installation.
- iOS deployment target: 17.0 (as declared in project.yml).
- iOS 18 or later for the RealityKit RealityView 3D experience guarded by availability checks.
- Firebase project configured for the matching bundle identifier.
Getting Started
1. Clone the repository
git clone https://github.com/Bekaryab/SaveFood.git
cd SaveFood
2. Open the Xcode project
open SaveFood.xcodeproj
Open the .xcodeproj directly and allow Xcode to resolve the Swift Package Manager dependencies.
3. Configure Firebase
Add your own GoogleService-Info.plist to the SaveFood app target if you are setting up a separate Firebase project. Make sure Email/Password Authentication and Cloud Firestore are enabled.
4. Configure signing
In Xcode:
1. Select the SaveFood project.
2. Select the SaveFood app target.
3. Open Signing & Capabilities.
4. Select your development team.
5. Confirm the bundle identifier matches the Firebase iOS app configuration.
5. Build and run
Select the SaveFood scheme and an iOS Simulator or connected iPhone, then press Run (⌘R).
XcodeGen note
The repository includes project.yml for XcodeGen. The checked-in Xcode project also contains Swift Package Manager resolution information. Before running xcodegen generate, make sure the Firebase package and the FirebaseCore, FirebaseAuth, and FirebaseFirestore products are declared in project.yml; otherwise, regenerating the project may remove package references that were added through Xcode.
Data and Development Status
The current Explore screen initializes its product catalogue and promotional banners from local sample data in ExploreViewModel. Product examples and prices are demonstration content, not live inventory or guaranteed offers. Product images can be loaded from configured image URLs, with local image lookup and fallback UI.

The current cart and favorites are held in the view-model's in-memory state. They are not yet persisted to Firestore or another backend. The map sheet currently applies UI filter selections to the local offer feed; it does not yet query real venues by GPS distance.

Firebase Authentication calls are present in the active authentication flow. Firestore profile writes are also attempted, but the current implementation needs stronger write-error handling and complete Security Rules verification before production use.
Roadmap
- [ ] Connect the customer offer feed to a production API or Firestore data source.
- [ ] Implement live MapKit map rendering, user-location handling, and nearby venue search.
- [ ] Persist favorites and cart contents.
- [ ] Complete customer profile and reservation screens.
- [ ] Build the seller dashboard and offer create/edit/management flows.
- [ ] Implement reservation availability, pickup codes, and business-side pickup confirmation.
- [ ] Add robust Firestore rules, error handling, and account lifecycle handling.
- [ ] Add meaningful unit and UI tests.
- [ ] Add app screenshots and an app icon to the repository documentation.
Testing
An SaveFoodTests XCTest target and test source files are included in the project structure. In the current source snapshot, those test files are empty placeholders, so automated test coverage is not yet established.

When tests are added, run them from Xcode using Product → Test (⌘U).
Contributing
Contributions and suggestions are welcome. For larger changes, open an issue first to discuss the proposed feature or implementation.

When submitting changes:
1. Keep feature code within its corresponding feature folder.
2. Avoid committing build artifacts, DerivedData, personal Xcode settings, or private credentials.
3. Add or update tests for new business logic.
4. Verify the app builds before opening a pull request.
Project Status
SaveFood is an actively developed prototype. The current focus is on the customer discovery experience, polished SwiftUI interactions, the 3D onboarding experience, and Firebase-based authentication. Backend-powered offers, live maps, reservations, and complete seller workflows remain under development.
<p align="center">
  <strong>SaveFood — Save food. Save money.</strong>
</p>

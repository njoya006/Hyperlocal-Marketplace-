/// App string constants for HyperLocal Market.
///
/// Defines all user-facing text and messages in the application.
/// Organized by feature/screen for easy localization in the future.
abstract final class AppStrings {
  // ============== APP INFO ==============
  static const String appName = 'HyperLocal Market';
  static const String appTagline = 'Ultra-fast local delivery';

  // ============== COMMON BUTTONS ==============
  static const String buttonLogin = 'Login';
  static const String buttonRegister = 'Register';
  static const String buttonSignUp = 'Sign Up';
  static const String buttonSignOut = 'Sign Out';
  static const String buttonSubmit = 'Submit';
  static const String buttonCancel = 'Cancel';
  static const String buttonContinue = 'Continue';
  static const String buttonNext = 'Next';
  static const String buttonBack = 'Back';
  static const String buttonSave = 'Save';
  static const String buttonDelete = 'Delete';
  static const String buttonEdit = 'Edit';
  static const String buttonClose = 'Close';
  static const String buttonRetry = 'Retry';
  static const String buttonOk = 'OK';
  static const String buttonYes = 'Yes';
  static const String buttonNo = 'No';
  static const String buttonViewShop = 'View Shop';
  static const String buttonAddToCart = 'Add to Cart';
  static const String buttonCheckout = 'Checkout';
  static const String buttonPlaceOrder = 'Place Order';
  static const String buttonTrackOrder = 'Track Order';
  static const String buttonConfirmOrder = 'Confirm Order';

  // ============== COMMON LABELS ==============
  static const String labelEmail = 'Email';
  static const String labelPassword = 'Password';
  static const String labelName = 'Full Name';
  static const String labelPhone = 'Phone Number';
  static const String labelRole = 'Role';
  static const String labelPassword2Confirm = 'Confirm Password';
  static const String labelAddress = 'Address';
  static const String labelCategory = 'Category';
  static const String labelPrice = 'Price';
  static const String labelDescription = 'Description';
  static const String labelQuantity = 'Quantity';
  static const String labelTotal = 'Total';

  // ============== AUTHENTICATION ==============
  /// Login screen strings
  static const String screenTitleLogin = 'Login';
  static const String loginDescription =
      'Enter your credentials to access your account';
  static const String labelRememberMe = 'Remember me';
  static const String linkForgotPassword = 'Forgot Password?';
  static const String textNoAccount = 'Don\'t have an account? ';
  static const String linkSignUp = 'Sign up here';

  /// Register screen strings
  static const String screenTitleRegister = 'Create Account';
  static const String registerDescription = 'Join HyperLocal Market';
  static const String labelIAmA = 'I am a';
  static const String roleCustomer = 'Customer';
  static const String roleShopOwner = 'Shop Owner';
  static const String roleAdmin = 'Admin';
  static const String textAlreadyHaveAccount = 'Already have an account? ';
  static const String linkLogin = 'Login here';

  // ============== VALIDATION ERRORS ==============
  static const String errorEmailRequired = 'Email is required';
  static const String errorEmailInvalid = 'Please enter a valid email address';
  static const String errorPasswordRequired = 'Password is required';
  static const String errorPasswordTooShort =
      'Password must be at least 8 characters';
  static const String errorConfirmPasswordRequired =
      'Please confirm your password';
  static const String errorPasswordMismatch = 'Passwords do not match';
  static const String errorNameRequired = 'Name is required';
  static const String errorPhoneRequired = 'Phone number is required';
  static const String errorRoleRequired = 'Please select a role';
  static const String errorLoginRequiredFields =
      'Enter both your email and password.';
  static const String errorRegistrationFailed =
      'We could not create your account. Please try again.';
  static const String errorSessionExpired =
      'Your session has expired. Please sign in again.';

  // ============== AUTH EXCEPTIONS ==============
  static const String errorAuthInvalidEmail = 'Invalid email format';
  static const String errorAuthUserNotFound =
      'User not found. Please register.';
  static const String errorAuthWrongPassword =
      'Wrong password. Please try again.';
  static const String errorAuthUserDisabled = 'This account has been disabled';
  static const String errorAuthUserExists =
      'User already exists with this email';
  static const String errorAuthWeakPassword = 'Password is too weak';
  static const String errorAuthNetworkError =
      'Network error. Please check your connection.';
  static const String errorAuthUnknown =
      'Authentication failed. Please try again.';

  // ============== NETWORK EXCEPTIONS ==============
  static const String errorNetworkNoConnection = 'No internet connection';
  static const String errorNetworkTimeout =
      'Request timed out. Please try again.';
  static const String errorNetworkBadResponse = 'Invalid response from server';
  static const String errorNetworkUnknown = 'Network error occurred';

  // ============== LOCATION EXCEPTIONS ==============
  static const String errorLocationPermissionDenied =
      'Location permission denied. Please enable it in settings.';
  static const String errorLocationServiceDisabled =
      'Location services are disabled. Please enable them.';
  static const String errorLocationUnknown = 'Failed to get location';
  static const String errorLocationNotAvailable = 'Location is not available';

  // ============== SERVER EXCEPTIONS ==============
  static const String errorServerInternalError =
      'Server error. Please try again later.';
  static const String errorServerNotFound = 'Resource not found';
  static const String errorServerUnauthorized =
      'You are not authorized to perform this action';
  static const String errorServerForbidden = 'Access denied';
  static const String errorServerUnknown = 'Server error occurred';

  // ============== CUSTOMER SCREENS ==============
  /// Home/Dashboard
  static const String screenTitleHome = 'HyperLocal Market';
  static const String labelNearbyShops = 'Nearby Shops';
  static const String labelSearchShops = 'Search shops...';
  static const String labelSelectRadius = 'Select radius';

  /// Shop Detail
  static const String screenTitleShopDetail = 'Shop Details';
  static const String labelShopRating = 'Rating';
  static const String labelShopCategory = 'Category';
  static const String labelShopOpen = 'Open';
  static const String labelShopClosed = 'Closed';
  static const String labelProducts = 'Products';
  static const String labelNoProducts = 'No products available';

  /// Cart
  static const String screenTitleCart = 'Shopping Cart';
  static const String labelCartEmpty = 'Your cart is empty';
  static const String labelSubtotal = 'Subtotal';
  static const String labelDeliveryFee = 'Delivery Fee';
  static const String labelTax = 'Tax';
  static const String labelGrandTotal = 'Grand Total';
  static const String labelRemoveItem = 'Remove item';
  static const String buttonClearCart = 'Clear Cart';

  /// Checkout
  static const String screenTitleCheckout = 'Checkout';
  static const String labelDeliveryAddress = 'Delivery Address';
  static const String labelDeliveryLocation = 'Delivery Location';
  static const String labelPaymentMethod = 'Payment Method';
  static const String labelCashOnDelivery = 'Cash on Delivery';
  static const String labelOrderNotes = 'Special Instructions (Optional)';

  /// Order Tracking
  static const String screenTitleOrderTracking = 'Track Order';
  static const String labelOrderPending = 'Pending';
  static const String labelOrderConfirmed = 'Confirmed';
  static const String labelOrderPreparing = 'Preparing';
  static const String labelOrderOutForDelivery = 'Out for Delivery';
  static const String labelOrderDelivered = 'Delivered';
  static const String labelOrderCancelled = 'Cancelled';

  /// Orders History
  static const String screenTitleOrderHistory = 'My Orders';
  static const String labelNoOrders = 'You have no orders yet';
  static const String labelOrderDate = 'Order Date';
  static const String labelOrderStatus = 'Status';

  // ============== SHOP OWNER SCREENS ==============
  /// Shop Owner Dashboard
  static const String screenTitleShopOwnerDashboard = 'My Shop';
  static const String labelMyShop = 'My Shop';
  static const String labelShopSettings = 'Shop Settings';
  static const String labelInventory = 'Inventory';
  static const String labelPendingOrders = 'Pending Orders';

  /// Create Shop
  static const String screenTitleCreateShop = 'Create Shop';
  static const String labelShopName = 'Shop Name';
  static const String labelShopDescription = 'Description';
  static const String labelShopImage = 'Shop Image';
  static const String labelShopLocation = 'Location';
  static const String labelShopHours = 'Operating Hours';
  static const String messageShopCreated =
      'Shop created successfully! Awaiting admin approval.';
  static const String messageAwaitingApproval =
      'Your shop is awaiting admin approval';
  static const String labelSelectShopImage = 'Select Shop Image';
  static const String labelImageSelected = 'Image selected';
  static const String messageUploadingImage = 'Uploading image...';
  static const String errorShopNameRequired = 'Shop name is required';
  static const String errorShopDescriptionRequired =
      'Shop description is required';
  static const String errorShopAddressRequired = 'Shop address is required';
  static const String errorShopLocationRequired = 'Shop location is required';
  static const String errorShopCreationFailed =
      'We could not create your shop. Please try again.';
  static const String errorShopImageUploadFailed =
      'We could not upload the shop image. Please try again.';
  static const String errorOwnerAccountLoad =
      'We could not load your account right now. Please try again.';
  static const String errorOwnerShopLoad =
      'We could not load your shop details. Please try again.';
  static const String errorOwnerOrdersLoad =
      'We could not load your orders right now. Please refresh and try again.';
  static const String messageSignInToContinue = 'Please sign in to continue.';

  /// Add Product
  static const String screenTitleAddProduct = 'Add Product';
  static const String labelProductName = 'Product Name';
  static const String labelProductPrice = 'Price';
  static const String labelProductStock = 'Stock Quantity';
  static const String labelProductImage = 'Product Image';
  static const String messageProductAdded = 'Product added successfully';

  /// Orders Management
  static const String screenTitleOrdersToFulfill = 'Orders to Fulfill';
  static const String labelConfirmOrder = 'Confirm Order';
  static const String labelMarkAsPreparing = 'Mark as Preparing';
  static const String labelMarkAsOutForDelivery = 'Mark as Out for Delivery';
  static const String labelMarkAsDelivered = 'Mark as Delivered';
  static const String labelCancelOrder = 'Cancel Order';
  static const String messageOrderUpdated = 'Order status updated';

  // ============== ADMIN SCREENS ==============
  /// Admin Dashboard
  static const String screenTitleAdminDashboard = 'Admin Dashboard';
  static const String labelRecentActivity = 'Recent Activity';
  static const String labelTotalUsers = 'Total Users';
  static const String labelTotalShops = 'Total Shops';
  static const String labelOrdersToday = 'Orders Today';
  static const String labelPendingApprovals = 'Pending Approvals';
  static const String labelAllUsers = 'All Users';
  static const String labelAllShops = 'All Shops';
  static const String labelAllOrders = 'All Orders';
  static const String labelStatistics = 'Statistics';
  static const String messageNoRecentActivity = 'No recent activity yet';

  /// Manage Shops
  static const String screenTitleManageShops = 'Manage Shops';
  static const String labelApproveShop = 'Approve Shop';
  static const String labelRejectShop = 'Reject Shop';
  static const String labelDeactivateShop = 'Deactivate Shop';
  static const String messageShopApproved = 'Shop approved successfully';
  static const String messageShopRejected = 'Shop rejected';

  /// Manage Users
  static const String screenTitleManageUsers = 'Manage Users';
  static const String labelDeactivateUser = 'Deactivate User';
  static const String labelActivateUser = 'Activate User';
  static const String labelUserCreatedDate = 'Member Since';
  static const String messageUserDeactivated = 'User deactivated';
  static const String messageUserActivated = 'User activated';

  /// Reports
  static const String screenTitleReports = 'Reports';
  static const String labelTotalRevenue = 'Total Revenue';
  static const String labelOrdersLast7Days = 'Orders (Last 7 Days)';
  static const String labelTopShops = 'Top Shops';
  static const String labelShopStatusApproved = 'Approved';
  static const String labelShopStatusPending = 'Pending';
  static const String labelShopStatusRejected = 'Rejected';
  static const String labelSearchUsers = 'Search users...';

  // ============== GENERAL MESSAGES ==============
  static const String messageLoading = 'Loading...';
  static const String messageSuccess = 'Success';
  static const String messageError = 'Error';
  static const String messageWarning = 'Warning';
  static const String messageConfirmDelete =
      'Are you sure you want to delete this?';
  static const String messageConfirmLogout = 'Are you sure you want to logout?';
  static const String messageNoData = 'No data available';
  static const String messageSomethingWentWrong =
      'Something went wrong. Please try again.';
  static const String messageServerUnavailable =
      'Server is currently unavailable. Please try later.';
  static const String messagePleaseCheckInternet =
      'Please check your internet connection and try again.';
}

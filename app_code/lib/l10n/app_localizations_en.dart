// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'List It';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get darkModeLabel => 'Dark Mode';

  @override
  String get fontSizeLabel => 'Font Size';

  @override
  String get fontSizeSmallLabel => 'Small';

  @override
  String get fontSizeLargeLabel => 'Large';

  @override
  String get textPreviewTitle => 'Text Preview';

  @override
  String get textPreviewDisplayLarge => 'Display Large';

  @override
  String get textPreviewHeadlineMedium => 'Headline Medium';

  @override
  String get textPreviewTitleMedium =>
      'Title Medium - This is how your body text will look with the selected font size.';

  @override
  String get textPreviewBodyMedium =>
      'Body Medium - This is standard body text for reading content and descriptions.';

  @override
  String get textPreviewBodySmall =>
      'Body Small - Smaller text for less important information.';

  @override
  String get textPreviewBodyExample => 'This is how your text will look';

  @override
  String get textPreviewBodySmallExample => 'Smaller body text example';

  @override
  String get colorPaletteTitle => 'Color Palette';

  @override
  String get colorSwatchPrimary => 'Primary';

  @override
  String get colorSwatchSecondary => 'Secondary';

  @override
  String get colorSwatchTertiary => 'Tertiary';

  @override
  String get colorSwatchError => 'Error';

  @override
  String get colorSwatchSurface => 'Surface';

  @override
  String get aboutSectionTitle => 'About';

  @override
  String get appVersionLabel => 'App Version';

  @override
  String get privacyPolicyLabel => 'Privacy Policy';

  @override
  String get termsOfServiceLabel => 'Terms of Service';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglishLabel => 'English';

  @override
  String get languageItalianLabel => 'Italian';

  @override
  String get listsTabLabel => 'Lists';

  @override
  String get historyTabLabel => 'History';

  @override
  String get supermarketsTabLabel => 'Supermarkets';

  @override
  String get statisticsTabLabel => 'Statistics';

  @override
  String get signInLabel => 'Sign In';

  @override
  String get signUpLabel => 'Sign Up';

  @override
  String get authTitle => 'Authentication';

  @override
  String get welcomeMessage => 'Welcome.';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get signInInstead => 'Sign in instead';

  @override
  String get needAccount => 'Need an account?';

  @override
  String get signUpInstead => 'Sign up instead';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInIntro => 'Sign in to your account.';

  @override
  String get signUpIntro => 'Sign up for a new account.';

  @override
  String get emailLabel => 'Email';

  @override
  String get confirmEmailLabel => 'Confirm Email';

  @override
  String get enterEmailError => 'Please enter your email';

  @override
  String get confirmEmailError => 'Please confirm your email';

  @override
  String get emailsDoNotMatch => 'Emails do not match';

  @override
  String get enterPasswordError => 'Please enter your password';

  @override
  String get enterPasswordCreateError => 'Please make a password';

  @override
  String get incorrectLoginCredentials => 'Incorrect login credentials.';

  @override
  String get forgotPasswordLabel => 'Forgot password?';

  @override
  String get usernamePrompt => 'How would you like to be called?';

  @override
  String get enterUsernameError => 'Please enter a username';

  @override
  String get signUpFailed => 'Could not sign up with those details.';

  @override
  String get recoverPasswordTitle => 'Recover Password';

  @override
  String get resetPasswordInstructions =>
      'Enter your account email to receive a password reset link.';

  @override
  String resetCooldownMessage(Object seconds) {
    return 'You can request another reset in $seconds seconds';
  }

  @override
  String pleaseWaitSeconds(Object seconds) {
    return 'Please wait ($seconds s)';
  }

  @override
  String get sendRecoveryEmailLabel => 'Send recovery email';

  @override
  String get resetLinkSentIfAccountExists =>
      'If an account exists, a reset link has been sent.';

  @override
  String get recoveryEmailSentCheckInbox =>
      'Recovery email sent. Check your inbox.';

  @override
  String get unableToOpenMap => 'Unable to open map';

  @override
  String get menuLabel => 'Menu';

  @override
  String get profileLabel => 'Profile';

  @override
  String get trashLabel => 'Trash';

  @override
  String get closeLabel => 'Close';

  @override
  String get trashEmptyMessage => 'Trash is empty';

  @override
  String get deletingNowMessage => 'Deleting now...';

  @override
  String get deleteInOneDayMessage => 'Delete in 1 day';

  @override
  String deleteInDaysMessage(Object days) {
    return 'Delete in $days days';
  }

  @override
  String get restoreLabel => 'Restore';

  @override
  String get deletePermanentlyTitle => 'Delete permanently';

  @override
  String deleteListPermanentlyConfirm(Object listName) {
    return 'Are you sure you want to permanently delete \'$listName\'?';
  }

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get deleteListTitle => 'Delete list';

  @override
  String deleteListConfirm(Object listName) {
    return 'Are you sure you want to delete \'$listName\'?';
  }

  @override
  String get deleteSelectedListsTitle => 'Delete selected lists';

  @override
  String deleteSelectedListsConfirm(Object count) {
    return 'Are you sure you want to delete $count selected list(s)?';
  }

  @override
  String deleteSelectedSupermarketsConfirm(Object count) {
    return 'Want to delete $count supermarket(s)?';
  }

  @override
  String get createFirstSupermarketMessage =>
      'Create your first supermarket to get started';

  @override
  String get cannotRemoveFavoriteSupermarket =>
      'Cannot remove favorite: You must have at least one favorite supermarket. Select a different one first.';

  @override
  String errorUpdatingFavorite(Object error) {
    return 'Error updating favorite: $error';
  }

  @override
  String get searchSupermarketsHint => 'Search supermarkets...';

  @override
  String get supermarketsTitle => 'Supermarkets';

  @override
  String noSupermarketsFoundMatching(Object query) {
    return 'No supermarkets found matching \"$query\"';
  }

  @override
  String get searchListsHint => 'Search lists...';

  @override
  String noListsFoundMatching(Object query) {
    return 'No lists found matching \"$query\"';
  }

  @override
  String get noItemsLabel => 'No items';

  @override
  String get dateNotAvailable => '--/--/----';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPasswordTooltip => 'Show password';

  @override
  String get hidePasswordTooltip => 'Hide password';

  @override
  String get restoreAllTitle => 'Restore all';

  @override
  String get restoreAllConfirm =>
      'Are you sure you want to restore all lists from trash?';

  @override
  String get allListsRestoredMessage => 'All lists restored';

  @override
  String get emptyTrashTitle => 'Empty trash';

  @override
  String get emptyTrashConfirm =>
      'This will permanently delete all lists in trash. Continue?';

  @override
  String get deleteAllLabel => 'Delete all';

  @override
  String get trashEmptiedMessage => 'Trash emptied';

  @override
  String get noSupermarketsYet => 'No supermarkets yet';

  @override
  String get noRegisteredListsYet => 'No registered lists yet.';

  @override
  String get noDataForSelectedPeriod => 'No data for the selected period.';

  @override
  String get byCategoryTitle => 'By category';

  @override
  String get categoryBreakdownTitle => 'Category Breakdown';

  @override
  String get selectCompletedListToReview => 'Select a completed list to review';

  @override
  String errorLoadingShoppingList(Object error) {
    return 'Error loading shopping list: $error';
  }

  @override
  String get noListsYet => 'No lists yet.';

  @override
  String get addNewListTitle => 'Add new list';

  @override
  String get enterListNamePrompt => 'Please enter the name of your list:';

  @override
  String get listNameHint => 'List name';

  @override
  String get selectListToViewDetails => 'Select a list to view details';

  @override
  String get selectSupermarketToViewDetails =>
      'Select a supermarket to view details';

  @override
  String get enterRecipeNameError => 'Please enter a recipe name';

  @override
  String get editIngredientTitle => 'Edit Ingredient';

  @override
  String get addRecipeTitle => 'Add Recipe';

  @override
  String get enterRecipeNameHint => 'Enter recipe name...';

  @override
  String get searchRecipeLabel => 'Search Recipe';

  @override
  String get enterRecipeAndSearch =>
      'Enter a recipe name and press \"Search Recipe\"';

  @override
  String get recipeLabel => 'Recipe';

  @override
  String ingredientsCount(Object selected, Object total) {
    return 'Ingredients ($selected/$total)';
  }

  @override
  String get addToListLabel => 'Add to List';

  @override
  String errorRegisteringList(Object error) {
    return 'Error registering list: $error';
  }

  @override
  String get continueEditingTitle => 'Continue Editing?';

  @override
  String get continueEditingMessage =>
      'You can add more products or check additional items.';

  @override
  String get yesContinueLabel => 'Yes, Continue';

  @override
  String errorOpeningForEditing(Object error) {
    return 'Error opening for editing: $error';
  }

  @override
  String get scanReceiptTooltip => 'Scan receipt';

  @override
  String get continueEditingTooltip => 'Continue editing';

  @override
  String get supermarketLabel => 'Supermarket';

  @override
  String get notSelectedLabel => 'Not selected';

  @override
  String get noCheckedItems => 'No checked items';

  @override
  String get checkItemsToRegister =>
      'Check items in the shopping list\nto register them here';

  @override
  String get quantityLabelTitle => 'Quantity';

  @override
  String get priceLabel => 'Price';

  @override
  String get errorSavingTitle => 'Error Saving';

  @override
  String get failedToSaveChanges => 'Failed to save changes:';

  @override
  String get whatWouldYouLikeToDo => 'What would you like to do?';

  @override
  String get stayAndRetry => 'Stay and retry';

  @override
  String get discardChanges => 'Discard changes';

  @override
  String errorAddingProduct(Object error) {
    return 'Error adding product: $error';
  }

  @override
  String errorDeletingList(Object error) {
    return 'Error deleting list: $error';
  }

  @override
  String get selectSupermarketTitle => 'Select Supermarket';

  @override
  String get noSupermarketsCreateFirst =>
      'No supermarkets yet. Create one to get started.';

  @override
  String supermarketsAvailable(Object count) {
    return '$count supermarket(s) available';
  }

  @override
  String get createNewLabel => 'Create New';

  @override
  String get clearLabel => 'Clear';

  @override
  String get editSupermarketTooltip => 'Edit supermarket';

  @override
  String get createSupermarketToOrganize =>
      'Create a supermarket to organize\nyour shopping categories';

  @override
  String get registerListTooltip => 'Register list';

  @override
  String get errorLoadingSupermarkets => 'Error loading supermarkets';

  @override
  String get createSupermarketPrompt => 'Create a supermarket';

  @override
  String get selectSupermarketPrompt => 'Select supermarket';

  @override
  String get addProductHint => 'Add product...';

  @override
  String get addProductTooltip => 'Add product';

  @override
  String get deleteListTooltip => 'Delete list';

  @override
  String get defaultCategoryUncategorized => 'Uncategorized';

  @override
  String get defaultCategoryMeat => '🥩 Meat';

  @override
  String get defaultCategoryWineShop => '🍷 Wine Shop';

  @override
  String get defaultCategoryFlowersAndPlants => '🌸 Flowers and Plants';

  @override
  String get defaultCategoryFruitAndVegetables => '🍎 Fruit and Vegetables';

  @override
  String get defaultCategoryLooseFruitAndVegetables =>
      '🥕 Loose Fruit and Vegetables';

  @override
  String get defaultCategoryDeli => '🧀 Deli';

  @override
  String get defaultCategoryDeliServiceCounter =>
      '🥪 Deli with service counter';

  @override
  String get defaultCategoryDairyAndCuredMeats => '🥛 Dairy and Cured Meats';

  @override
  String get defaultCategoryButcherServiceCounter =>
      '🔪 Butcher with service counter';

  @override
  String get defaultCategoryNonFood => '🧴 Non-Food';

  @override
  String get defaultCategoryBreadAndDesserts => '🍞 Bread and Desserts';

  @override
  String get defaultCategoryBreadAndDessertsServiceCounter =>
      '🥖 Bread and Desserts with service counter';

  @override
  String get defaultCategoryBakery => '🥐 Bakery';

  @override
  String get defaultCategoryPastry => '🧁 Pastry';

  @override
  String get defaultCategoryFish => '🐟 Fish';

  @override
  String get defaultCategoryFishmongerServiceCounter =>
      '🦞 Fishmonger with service counter';

  @override
  String get defaultCategorySushi => '🍣 Sushi';

  @override
  String categoriesCountLabel(Object count) {
    return '$count categories';
  }

  @override
  String get editLabel => 'Edit';

  @override
  String get supermarketNameEmpty => 'Supermarket name cannot be empty';

  @override
  String errorSavingSupermarket(Object error) {
    return 'Error saving supermarket: $error';
  }

  @override
  String deleteSupermarketConfirm(Object name) {
    return 'Want to delete \'$name\'?';
  }

  @override
  String errorDeletingSupermarket(Object error) {
    return 'Error deleting supermarket: $error';
  }

  @override
  String get createSupermarketTitle => 'Create Supermarket';

  @override
  String get customizeSupermarketTitle => 'Customize Supermarket';

  @override
  String get saveSupermarketTooltip => 'Save supermarket';

  @override
  String get enterSupermarketNameLabel => 'Enter Supermarket Name';

  @override
  String get noCategoriesYet => 'No categories yet';

  @override
  String get addCategoriesToSupermarket => 'Add categories to this supermarket';

  @override
  String get cancelSupermarketCreationTooltip => 'Cancel supermarket creation';

  @override
  String get deleteSupermarketTooltip => 'Delete supermarket';

  @override
  String get addCategoriesLabel => 'Add Categories';

  @override
  String get removeFromFavoritesTooltip => 'Remove from favorites';

  @override
  String get setAsFavoriteTooltip => 'Set as favorite';

  @override
  String get removeCategoryTooltip => 'Remove category';

  @override
  String get editCategoryTooltip => 'Edit category';

  @override
  String get selectAtLeastOneCategory => 'Please select at least one category';

  @override
  String get selectAtLeastOneCategoryToDelete =>
      'Please select at least one category to delete';

  @override
  String deleteCategoryConfirmSingle(Object name) {
    return 'Want to delete \'$name\'?';
  }

  @override
  String deleteCategoriesConfirm(Object count) {
    return 'Want to delete $count categories?';
  }

  @override
  String failedToDeleteCategories(Object error) {
    return 'Failed to delete categories: $error';
  }

  @override
  String get addCategoriesTitle => 'Add Categories';

  @override
  String get createNewCategoryTooltip => 'Create new category';

  @override
  String get allCategoriesAdded => 'All categories added';

  @override
  String get createNewCategoryToContinue => 'Create a new category to continue';

  @override
  String get addLabel => 'Add';

  @override
  String get categoryNameEmpty => 'Category name cannot be empty';

  @override
  String get uncategorizedNameReserved =>
      'The name \"uncategorized\" is reserved';

  @override
  String errorSavingCategory(Object error) {
    return 'Error saving category: $error';
  }

  @override
  String get editCategoryTitle => 'Edit Category';

  @override
  String get createCategoryTitle => 'Create Category';

  @override
  String get categoryNameLabel => 'Category Name';

  @override
  String get saveLabel => 'Save';

  @override
  String selectedItemsCount(Object count) {
    return '$count selected';
  }

  @override
  String quantityLabel(Object quantity) {
    return 'Quantity: $quantity';
  }

  @override
  String get statsLoadError => 'Error occurring: please reload the app.';

  @override
  String get periodAll => 'All';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodYear => 'Year';

  @override
  String get periodCustom => 'Custom';

  @override
  String get monthJanuary => 'January';

  @override
  String get monthFebruary => 'February';

  @override
  String get monthMarch => 'March';

  @override
  String get monthApril => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJune => 'June';

  @override
  String get monthJuly => 'July';

  @override
  String get monthAugust => 'August';

  @override
  String get monthSeptember => 'September';

  @override
  String get monthOctober => 'October';

  @override
  String get monthNovember => 'November';

  @override
  String get monthDecember => 'December';

  @override
  String get yearHint => 'Year';

  @override
  String get selectYearTooltip => 'Select year';

  @override
  String get previousWeekTooltip => 'Previous week';

  @override
  String get nextWeekTooltip => 'Next week';

  @override
  String get selectRangeLabel => 'Select range';

  @override
  String get selectDayInWeekHelpText => 'Select any day in the week';

  @override
  String get noUserDataFound => 'No user data found.';

  @override
  String errorWithDetails(Object error) {
    return 'Error: $error';
  }

  @override
  String get profileInformationTitle => 'Profile Information';

  @override
  String get usernameLabel => 'Username';

  @override
  String get currentEmailLabel => 'Current Email';

  @override
  String get saveProfileChanges => 'Save Profile Changes';

  @override
  String get securitySettingsTitle => 'Security Settings';

  @override
  String get googleAccountManagedCredentials =>
      'Email and password are managed via your Google account. Changes are disabled.';

  @override
  String get updateEmailTitle => 'Update Email';

  @override
  String get newEmailLabel => 'New Email';

  @override
  String get confirmNewEmailLabel => 'Confirm New Email';

  @override
  String get updatePasswordTitle => 'Update Password';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get confirmNewPasswordLabel => 'Confirm New Password';

  @override
  String get verificationTitle => 'Verification';

  @override
  String get enterCurrentPasswordToConfirm =>
      'Enter Current Password to Confirm Changes';

  @override
  String forgotPasswordWait(Object seconds) {
    return 'Forgot Password? (Wait ${seconds}s)';
  }

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String cooldownSeconds(Object seconds) {
    return 'Cooldown: ${seconds}s';
  }

  @override
  String get updateSecuritySettings => 'Update Security Settings';

  @override
  String get changesSavedSuccessfully => 'Changes saved successfully!';

  @override
  String errorSavingChanges(Object error) {
    return 'Error saving changes: $error';
  }

  @override
  String get googleAccountManagedCredentialsShort =>
      'Email and password managed via Google. Changes disabled.';

  @override
  String get enterNewEmailOrPassword => 'Enter new email and/or new password.';

  @override
  String get enterCurrentPasswordToProceed =>
      'Enter current password to proceed.';

  @override
  String get fillBothEmailFields => 'Fill both email fields.';

  @override
  String get emailAddressesDoNotMatch => 'Email addresses do not match.';

  @override
  String get fillAllPasswordFields => 'Fill all password fields.';

  @override
  String get newPasswordsDoNotMatch => 'New passwords do not match.';

  @override
  String passwordMinLength(Object minLength) {
    return 'Password must be at least $minLength characters.';
  }

  @override
  String get updateEmailAndPasswordSeparately =>
      'Please update email and password separately.';

  @override
  String get verificationEmailSent => 'Verification email sent to new address!';

  @override
  String get passwordUpdatedSignInAgain =>
      'Password updated. Please sign in again.';

  @override
  String failedToUpdateCredentials(Object error) {
    return 'Failed to update credentials: $error';
  }

  @override
  String get noEmailAssociated => 'No email associated with this account.';

  @override
  String waitBeforeRequestingReset(Object seconds) {
    return 'Please wait $seconds seconds before requesting another reset email.';
  }

  @override
  String get recoveryEmailSentSignedOut =>
      'Recovery email sent. You will be signed out.';

  @override
  String get couldNotSendResetEmail =>
      'Could not send reset email. Try again later.';

  @override
  String get goBackLabel => 'Go Back';

  @override
  String get receiptCameraNoCameras => 'No cameras available';

  @override
  String receiptCameraInitFailed(Object error) {
    return 'Failed to initialize camera: $error';
  }

  @override
  String receiptCameraErrorTakingPicture(Object error) {
    return 'Error taking picture: $error';
  }

  @override
  String get receiptCameraExtractingPrices =>
      'Extracting prices and quantities...';
}

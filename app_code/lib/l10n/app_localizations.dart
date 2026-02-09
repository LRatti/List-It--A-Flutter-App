import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DIMA'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @notificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsLabel;

  /// No description provided for @darkModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkModeLabel;

  /// No description provided for @fontSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSizeLabel;

  /// No description provided for @fontSizeSmallLabel.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get fontSizeSmallLabel;

  /// No description provided for @fontSizeLargeLabel.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontSizeLargeLabel;

  /// No description provided for @textPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Text Preview'**
  String get textPreviewTitle;

  /// No description provided for @textPreviewDisplayLarge.
  ///
  /// In en, this message translates to:
  /// **'Display Large'**
  String get textPreviewDisplayLarge;

  /// No description provided for @textPreviewHeadlineMedium.
  ///
  /// In en, this message translates to:
  /// **'Headline Medium'**
  String get textPreviewHeadlineMedium;

  /// No description provided for @textPreviewTitleMedium.
  ///
  /// In en, this message translates to:
  /// **'Title Medium - This is how your body text will look with the selected font size.'**
  String get textPreviewTitleMedium;

  /// No description provided for @textPreviewBodyMedium.
  ///
  /// In en, this message translates to:
  /// **'Body Medium - This is standard body text for reading content and descriptions.'**
  String get textPreviewBodyMedium;

  /// No description provided for @textPreviewBodySmall.
  ///
  /// In en, this message translates to:
  /// **'Body Small - Smaller text for less important information.'**
  String get textPreviewBodySmall;

  /// No description provided for @textPreviewBodyExample.
  ///
  /// In en, this message translates to:
  /// **'This is how your text will look'**
  String get textPreviewBodyExample;

  /// No description provided for @textPreviewBodySmallExample.
  ///
  /// In en, this message translates to:
  /// **'Smaller body text example'**
  String get textPreviewBodySmallExample;

  /// No description provided for @colorPaletteTitle.
  ///
  /// In en, this message translates to:
  /// **'Color Palette'**
  String get colorPaletteTitle;

  /// No description provided for @colorSwatchPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get colorSwatchPrimary;

  /// No description provided for @colorSwatchSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get colorSwatchSecondary;

  /// No description provided for @colorSwatchTertiary.
  ///
  /// In en, this message translates to:
  /// **'Tertiary'**
  String get colorSwatchTertiary;

  /// No description provided for @colorSwatchError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get colorSwatchError;

  /// No description provided for @colorSwatchSurface.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get colorSwatchSurface;

  /// No description provided for @aboutSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSectionTitle;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersionLabel;

  /// No description provided for @privacyPolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyLabel;

  /// No description provided for @termsOfServiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageEnglishLabel.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishLabel;

  /// No description provided for @languageItalianLabel.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get languageItalianLabel;

  /// No description provided for @listsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get listsTabLabel;

  /// No description provided for @historyTabLabel.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTabLabel;

  /// No description provided for @supermarketsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Supermarkets'**
  String get supermarketsTabLabel;

  /// No description provided for @statisticsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsTabLabel;

  /// No description provided for @signInLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInLabel;

  /// No description provided for @signUpLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpLabel;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get authTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome.'**
  String get welcomeMessage;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signInInstead.
  ///
  /// In en, this message translates to:
  /// **'Sign in instead'**
  String get signInInstead;

  /// No description provided for @needAccount.
  ///
  /// In en, this message translates to:
  /// **'Need an account?'**
  String get needAccount;

  /// No description provided for @signUpInstead.
  ///
  /// In en, this message translates to:
  /// **'Sign up instead'**
  String get signUpInstead;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInIntro.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account.'**
  String get signInIntro;

  /// No description provided for @signUpIntro.
  ///
  /// In en, this message translates to:
  /// **'Sign up for a new account.'**
  String get signUpIntro;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @confirmEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Email'**
  String get confirmEmailLabel;

  /// No description provided for @enterEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterEmailError;

  /// No description provided for @confirmEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email'**
  String get confirmEmailError;

  /// No description provided for @emailsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Emails do not match'**
  String get emailsDoNotMatch;

  /// No description provided for @enterPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPasswordError;

  /// No description provided for @enterPasswordCreateError.
  ///
  /// In en, this message translates to:
  /// **'Please make a password'**
  String get enterPasswordCreateError;

  /// No description provided for @incorrectLoginCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect login credentials.'**
  String get incorrectLoginCredentials;

  /// No description provided for @forgotPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLabel;

  /// No description provided for @usernamePrompt.
  ///
  /// In en, this message translates to:
  /// **'How would you like to be called?'**
  String get usernamePrompt;

  /// No description provided for @enterUsernameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get enterUsernameError;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign up with those details.'**
  String get signUpFailed;

  /// No description provided for @recoverPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover Password'**
  String get recoverPasswordTitle;

  /// No description provided for @resetPasswordInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email to receive a password reset link.'**
  String get resetPasswordInstructions;

  /// No description provided for @resetCooldownMessage.
  ///
  /// In en, this message translates to:
  /// **'You can request another reset in {seconds} seconds'**
  String resetCooldownMessage(Object seconds);

  /// No description provided for @pleaseWaitSeconds.
  ///
  /// In en, this message translates to:
  /// **'Please wait ({seconds} s)'**
  String pleaseWaitSeconds(Object seconds);

  /// No description provided for @sendRecoveryEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Send recovery email'**
  String get sendRecoveryEmailLabel;

  /// No description provided for @resetLinkSentIfAccountExists.
  ///
  /// In en, this message translates to:
  /// **'If an account exists, a reset link has been sent.'**
  String get resetLinkSentIfAccountExists;

  /// No description provided for @recoveryEmailSentCheckInbox.
  ///
  /// In en, this message translates to:
  /// **'Recovery email sent. Check your inbox.'**
  String get recoveryEmailSentCheckInbox;

  /// No description provided for @unableToOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Unable to open map'**
  String get unableToOpenMap;

  /// No description provided for @menuLabel.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuLabel;

  /// No description provided for @profileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileLabel;

  /// No description provided for @trashLabel.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trashLabel;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @trashEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trashEmptyMessage;

  /// No description provided for @deletingNowMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleting now...'**
  String get deletingNowMessage;

  /// No description provided for @deleteInOneDayMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete in 1 day'**
  String get deleteInOneDayMessage;

  /// No description provided for @deleteInDaysMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete in {days} days'**
  String deleteInDaysMessage(Object days);

  /// No description provided for @restoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreLabel;

  /// No description provided for @deletePermanentlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deletePermanentlyTitle;

  /// No description provided for @deleteListPermanentlyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete \'{listName}\'?'**
  String deleteListPermanentlyConfirm(Object listName);

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @deleteListTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete list'**
  String get deleteListTitle;

  /// No description provided for @deleteListConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \'{listName}\'?'**
  String deleteListConfirm(Object listName);

  /// No description provided for @deleteSelectedListsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete selected lists'**
  String get deleteSelectedListsTitle;

  /// No description provided for @deleteSelectedListsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected list(s)?'**
  String deleteSelectedListsConfirm(Object count);

  /// No description provided for @deleteSelectedSupermarketsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Want to delete {count} supermarket(s)?'**
  String deleteSelectedSupermarketsConfirm(Object count);

  /// No description provided for @createFirstSupermarketMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your first supermarket to get started'**
  String get createFirstSupermarketMessage;

  /// No description provided for @cannotRemoveFavoriteSupermarket.
  ///
  /// In en, this message translates to:
  /// **'Cannot remove favorite: You must have at least one favorite supermarket. Select a different one first.'**
  String get cannotRemoveFavoriteSupermarket;

  /// No description provided for @errorUpdatingFavorite.
  ///
  /// In en, this message translates to:
  /// **'Error updating favorite: {error}'**
  String errorUpdatingFavorite(Object error);

  /// No description provided for @searchSupermarketsHint.
  ///
  /// In en, this message translates to:
  /// **'Search supermarkets...'**
  String get searchSupermarketsHint;

  /// No description provided for @supermarketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Supermarkets'**
  String get supermarketsTitle;

  /// No description provided for @noSupermarketsFoundMatching.
  ///
  /// In en, this message translates to:
  /// **'No supermarkets found matching \"{query}\"'**
  String noSupermarketsFoundMatching(Object query);

  /// No description provided for @searchListsHint.
  ///
  /// In en, this message translates to:
  /// **'Search lists...'**
  String get searchListsHint;

  /// No description provided for @noListsFoundMatching.
  ///
  /// In en, this message translates to:
  /// **'No lists found matching \"{query}\"'**
  String noListsFoundMatching(Object query);

  /// No description provided for @noItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItemsLabel;

  /// No description provided for @dateNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'--/--/----'**
  String get dateNotAvailable;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @showPasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPasswordTooltip;

  /// No description provided for @hidePasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePasswordTooltip;

  /// No description provided for @restoreAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore all'**
  String get restoreAllTitle;

  /// No description provided for @restoreAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore all lists from trash?'**
  String get restoreAllConfirm;

  /// No description provided for @allListsRestoredMessage.
  ///
  /// In en, this message translates to:
  /// **'All lists restored'**
  String get allListsRestoredMessage;

  /// No description provided for @emptyTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get emptyTrashTitle;

  /// No description provided for @emptyTrashConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all lists in trash. Continue?'**
  String get emptyTrashConfirm;

  /// No description provided for @deleteAllLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAllLabel;

  /// No description provided for @trashEmptiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Trash emptied'**
  String get trashEmptiedMessage;

  /// No description provided for @noSupermarketsYet.
  ///
  /// In en, this message translates to:
  /// **'No supermarkets yet'**
  String get noSupermarketsYet;

  /// No description provided for @noRegisteredListsYet.
  ///
  /// In en, this message translates to:
  /// **'No registered lists yet.'**
  String get noRegisteredListsYet;

  /// No description provided for @noDataForSelectedPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data for the selected period.'**
  String get noDataForSelectedPeriod;

  /// No description provided for @byCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategoryTitle;

  /// No description provided for @categoryBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get categoryBreakdownTitle;

  /// No description provided for @selectCompletedListToReview.
  ///
  /// In en, this message translates to:
  /// **'Select a completed list to review'**
  String get selectCompletedListToReview;

  /// No description provided for @errorLoadingShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Error loading shopping list: {error}'**
  String errorLoadingShoppingList(Object error);

  /// No description provided for @noListsYet.
  ///
  /// In en, this message translates to:
  /// **'No lists yet.'**
  String get noListsYet;

  /// No description provided for @addNewListTitle.
  ///
  /// In en, this message translates to:
  /// **'Add new list'**
  String get addNewListTitle;

  /// No description provided for @enterListNamePrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter the name of your list:'**
  String get enterListNamePrompt;

  /// No description provided for @listNameHint.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get listNameHint;

  /// No description provided for @selectListToViewDetails.
  ///
  /// In en, this message translates to:
  /// **'Select a list to view details'**
  String get selectListToViewDetails;

  /// No description provided for @selectSupermarketToViewDetails.
  ///
  /// In en, this message translates to:
  /// **'Select a supermarket to view details'**
  String get selectSupermarketToViewDetails;

  /// No description provided for @enterRecipeNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a recipe name'**
  String get enterRecipeNameError;

  /// No description provided for @editIngredientTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Ingredient'**
  String get editIngredientTitle;

  /// No description provided for @addRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Recipe'**
  String get addRecipeTitle;

  /// No description provided for @enterRecipeNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter recipe name...'**
  String get enterRecipeNameHint;

  /// No description provided for @searchRecipeLabel.
  ///
  /// In en, this message translates to:
  /// **'Search Recipe'**
  String get searchRecipeLabel;

  /// No description provided for @enterRecipeAndSearch.
  ///
  /// In en, this message translates to:
  /// **'Enter a recipe name and press \"Search Recipe\"'**
  String get enterRecipeAndSearch;

  /// No description provided for @recipeLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get recipeLabel;

  /// No description provided for @ingredientsCount.
  ///
  /// In en, this message translates to:
  /// **'Ingredients ({selected}/{total})'**
  String ingredientsCount(Object selected, Object total);

  /// No description provided for @addToListLabel.
  ///
  /// In en, this message translates to:
  /// **'Add to List'**
  String get addToListLabel;

  /// No description provided for @errorRegisteringList.
  ///
  /// In en, this message translates to:
  /// **'Error registering list: {error}'**
  String errorRegisteringList(Object error);

  /// No description provided for @continueEditingTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue Editing?'**
  String get continueEditingTitle;

  /// No description provided for @continueEditingMessage.
  ///
  /// In en, this message translates to:
  /// **'You can add more products or check additional items.'**
  String get continueEditingMessage;

  /// No description provided for @yesContinueLabel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Continue'**
  String get yesContinueLabel;

  /// No description provided for @errorOpeningForEditing.
  ///
  /// In en, this message translates to:
  /// **'Error opening for editing: {error}'**
  String errorOpeningForEditing(Object error);

  /// No description provided for @scanReceiptTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get scanReceiptTooltip;

  /// No description provided for @continueEditingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Continue editing'**
  String get continueEditingTooltip;

  /// No description provided for @supermarketLabel.
  ///
  /// In en, this message translates to:
  /// **'Supermarket'**
  String get supermarketLabel;

  /// No description provided for @notSelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelectedLabel;

  /// No description provided for @noCheckedItems.
  ///
  /// In en, this message translates to:
  /// **'No checked items'**
  String get noCheckedItems;

  /// No description provided for @checkItemsToRegister.
  ///
  /// In en, this message translates to:
  /// **'Check items in the shopping list\nto register them here'**
  String get checkItemsToRegister;

  /// No description provided for @quantityLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabelTitle;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @errorSavingTitle.
  ///
  /// In en, this message translates to:
  /// **'Error Saving'**
  String get errorSavingTitle;

  /// No description provided for @failedToSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Failed to save changes:'**
  String get failedToSaveChanges;

  /// No description provided for @whatWouldYouLikeToDo.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get whatWouldYouLikeToDo;

  /// No description provided for @stayAndRetry.
  ///
  /// In en, this message translates to:
  /// **'Stay and retry'**
  String get stayAndRetry;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get discardChanges;

  /// No description provided for @errorAddingProduct.
  ///
  /// In en, this message translates to:
  /// **'Error adding product: {error}'**
  String errorAddingProduct(Object error);

  /// No description provided for @errorDeletingList.
  ///
  /// In en, this message translates to:
  /// **'Error deleting list: {error}'**
  String errorDeletingList(Object error);

  /// No description provided for @selectSupermarketTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Supermarket'**
  String get selectSupermarketTitle;

  /// No description provided for @noSupermarketsCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'No supermarkets yet. Create one to get started.'**
  String get noSupermarketsCreateFirst;

  /// No description provided for @supermarketsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} supermarket(s) available'**
  String supermarketsAvailable(Object count);

  /// No description provided for @createNewLabel.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get createNewLabel;

  /// No description provided for @clearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearLabel;

  /// No description provided for @editSupermarketTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit supermarket'**
  String get editSupermarketTooltip;

  /// No description provided for @createSupermarketToOrganize.
  ///
  /// In en, this message translates to:
  /// **'Create a supermarket to organize\nyour shopping categories'**
  String get createSupermarketToOrganize;

  /// No description provided for @registerListTooltip.
  ///
  /// In en, this message translates to:
  /// **'Register list'**
  String get registerListTooltip;

  /// No description provided for @errorLoadingSupermarkets.
  ///
  /// In en, this message translates to:
  /// **'Error loading supermarkets'**
  String get errorLoadingSupermarkets;

  /// No description provided for @createSupermarketPrompt.
  ///
  /// In en, this message translates to:
  /// **'Create a supermarket'**
  String get createSupermarketPrompt;

  /// No description provided for @selectSupermarketPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select supermarket'**
  String get selectSupermarketPrompt;

  /// No description provided for @addProductHint.
  ///
  /// In en, this message translates to:
  /// **'Add product...'**
  String get addProductHint;

  /// No description provided for @addProductTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProductTooltip;

  /// No description provided for @deleteListTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete list'**
  String get deleteListTooltip;

  /// No description provided for @defaultCategoryUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get defaultCategoryUncategorized;

  /// No description provided for @defaultCategoryMeat.
  ///
  /// In en, this message translates to:
  /// **'🥩 Meat'**
  String get defaultCategoryMeat;

  /// No description provided for @defaultCategoryWineShop.
  ///
  /// In en, this message translates to:
  /// **'🍷 Wine Shop'**
  String get defaultCategoryWineShop;

  /// No description provided for @defaultCategoryFlowersAndPlants.
  ///
  /// In en, this message translates to:
  /// **'🌸 Flowers and Plants'**
  String get defaultCategoryFlowersAndPlants;

  /// No description provided for @defaultCategoryFruitAndVegetables.
  ///
  /// In en, this message translates to:
  /// **'🍎 Fruit and Vegetables'**
  String get defaultCategoryFruitAndVegetables;

  /// No description provided for @defaultCategoryLooseFruitAndVegetables.
  ///
  /// In en, this message translates to:
  /// **'🥕 Loose Fruit and Vegetables'**
  String get defaultCategoryLooseFruitAndVegetables;

  /// No description provided for @defaultCategoryDeli.
  ///
  /// In en, this message translates to:
  /// **'🧀 Deli'**
  String get defaultCategoryDeli;

  /// No description provided for @defaultCategoryDeliServiceCounter.
  ///
  /// In en, this message translates to:
  /// **'🥪 Deli with service counter'**
  String get defaultCategoryDeliServiceCounter;

  /// No description provided for @defaultCategoryDairyAndCuredMeats.
  ///
  /// In en, this message translates to:
  /// **'🥛 Dairy and Cured Meats'**
  String get defaultCategoryDairyAndCuredMeats;

  /// No description provided for @defaultCategoryButcherServiceCounter.
  ///
  /// In en, this message translates to:
  /// **'🔪 Butcher with service counter'**
  String get defaultCategoryButcherServiceCounter;

  /// No description provided for @defaultCategoryNonFood.
  ///
  /// In en, this message translates to:
  /// **'🧴 Non-Food'**
  String get defaultCategoryNonFood;

  /// No description provided for @defaultCategoryBreadAndDesserts.
  ///
  /// In en, this message translates to:
  /// **'🍞 Bread and Desserts'**
  String get defaultCategoryBreadAndDesserts;

  /// No description provided for @defaultCategoryBreadAndDessertsServiceCounter.
  ///
  /// In en, this message translates to:
  /// **'🥖 Bread and Desserts with service counter'**
  String get defaultCategoryBreadAndDessertsServiceCounter;

  /// No description provided for @defaultCategoryBakery.
  ///
  /// In en, this message translates to:
  /// **'🥐 Bakery'**
  String get defaultCategoryBakery;

  /// No description provided for @defaultCategoryPastry.
  ///
  /// In en, this message translates to:
  /// **'🧁 Pastry'**
  String get defaultCategoryPastry;

  /// No description provided for @defaultCategoryFish.
  ///
  /// In en, this message translates to:
  /// **'🐟 Fish'**
  String get defaultCategoryFish;

  /// No description provided for @defaultCategoryFishmongerServiceCounter.
  ///
  /// In en, this message translates to:
  /// **'🦞 Fishmonger with service counter'**
  String get defaultCategoryFishmongerServiceCounter;

  /// No description provided for @defaultCategorySushi.
  ///
  /// In en, this message translates to:
  /// **'🍣 Sushi'**
  String get defaultCategorySushi;

  /// No description provided for @categoriesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} categories'**
  String categoriesCountLabel(Object count);

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLabel;

  /// No description provided for @supermarketNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Supermarket name cannot be empty'**
  String get supermarketNameEmpty;

  /// No description provided for @errorSavingSupermarket.
  ///
  /// In en, this message translates to:
  /// **'Error saving supermarket: {error}'**
  String errorSavingSupermarket(Object error);

  /// No description provided for @deleteSupermarketConfirm.
  ///
  /// In en, this message translates to:
  /// **'Want to delete \'{name}\'?'**
  String deleteSupermarketConfirm(Object name);

  /// No description provided for @errorDeletingSupermarket.
  ///
  /// In en, this message translates to:
  /// **'Error deleting supermarket: {error}'**
  String errorDeletingSupermarket(Object error);

  /// No description provided for @createSupermarketTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Supermarket'**
  String get createSupermarketTitle;

  /// No description provided for @customizeSupermarketTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize Supermarket'**
  String get customizeSupermarketTitle;

  /// No description provided for @saveSupermarketTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save supermarket'**
  String get saveSupermarketTooltip;

  /// No description provided for @enterSupermarketNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter Supermarket Name'**
  String get enterSupermarketNameLabel;

  /// No description provided for @noCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategoriesYet;

  /// No description provided for @addCategoriesToSupermarket.
  ///
  /// In en, this message translates to:
  /// **'Add categories to this supermarket'**
  String get addCategoriesToSupermarket;

  /// No description provided for @cancelSupermarketCreationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel supermarket creation'**
  String get cancelSupermarketCreationTooltip;

  /// No description provided for @deleteSupermarketTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete supermarket'**
  String get deleteSupermarketTooltip;

  /// No description provided for @addCategoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Categories'**
  String get addCategoriesLabel;

  /// No description provided for @removeFromFavoritesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavoritesTooltip;

  /// No description provided for @setAsFavoriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Set as favorite'**
  String get setAsFavoriteTooltip;

  /// No description provided for @removeCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove category'**
  String get removeCategoryTooltip;

  /// No description provided for @editCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategoryTooltip;

  /// No description provided for @selectAtLeastOneCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one category'**
  String get selectAtLeastOneCategory;

  /// No description provided for @selectAtLeastOneCategoryToDelete.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one category to delete'**
  String get selectAtLeastOneCategoryToDelete;

  /// No description provided for @deleteCategoryConfirmSingle.
  ///
  /// In en, this message translates to:
  /// **'Want to delete \'{name}\'?'**
  String deleteCategoryConfirmSingle(Object name);

  /// No description provided for @deleteCategoriesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Want to delete {count} categories?'**
  String deleteCategoriesConfirm(Object count);

  /// No description provided for @failedToDeleteCategories.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete categories: {error}'**
  String failedToDeleteCategories(Object error);

  /// No description provided for @addCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Categories'**
  String get addCategoriesTitle;

  /// No description provided for @createNewCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create new category'**
  String get createNewCategoryTooltip;

  /// No description provided for @allCategoriesAdded.
  ///
  /// In en, this message translates to:
  /// **'All categories added'**
  String get allCategoriesAdded;

  /// No description provided for @createNewCategoryToContinue.
  ///
  /// In en, this message translates to:
  /// **'Create a new category to continue'**
  String get createNewCategoryToContinue;

  /// No description provided for @addLabel.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addLabel;

  /// No description provided for @categoryNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Category name cannot be empty'**
  String get categoryNameEmpty;

  /// No description provided for @uncategorizedNameReserved.
  ///
  /// In en, this message translates to:
  /// **'The name \"uncategorized\" is reserved'**
  String get uncategorizedNameReserved;

  /// No description provided for @errorSavingCategory.
  ///
  /// In en, this message translates to:
  /// **'Error saving category: {error}'**
  String errorSavingCategory(Object error);

  /// No description provided for @editCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategoryTitle;

  /// No description provided for @createCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get createCategoryTitle;

  /// No description provided for @categoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryNameLabel;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @selectedItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedItemsCount(Object count);

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity: {quantity}'**
  String quantityLabel(Object quantity);

  /// No description provided for @statsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error occurring: please reload the app.'**
  String get statsLoadError;

  /// No description provided for @periodAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get periodAll;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

  /// No description provided for @periodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get periodYear;

  /// No description provided for @periodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get periodCustom;

  /// No description provided for @monthJanuary.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthJanuary;

  /// No description provided for @monthFebruary.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthFebruary;

  /// No description provided for @monthMarch.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthMarch;

  /// No description provided for @monthApril.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthApril;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJune.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthJune;

  /// No description provided for @monthJuly.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthJuly;

  /// No description provided for @monthAugust.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthAugust;

  /// No description provided for @monthSeptember.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthSeptember;

  /// No description provided for @monthOctober.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthOctober;

  /// No description provided for @monthNovember.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthNovember;

  /// No description provided for @monthDecember.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthDecember;

  /// No description provided for @yearHint.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearHint;

  /// No description provided for @selectYearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select year'**
  String get selectYearTooltip;

  /// No description provided for @previousWeekTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get previousWeekTooltip;

  /// No description provided for @nextWeekTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get nextWeekTooltip;

  /// No description provided for @selectRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Select range'**
  String get selectRangeLabel;

  /// No description provided for @selectDayInWeekHelpText.
  ///
  /// In en, this message translates to:
  /// **'Select any day in the week'**
  String get selectDayInWeekHelpText;

  /// No description provided for @noUserDataFound.
  ///
  /// In en, this message translates to:
  /// **'No user data found.'**
  String get noUserDataFound;

  /// No description provided for @errorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetails(Object error);

  /// No description provided for @profileInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInformationTitle;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @currentEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Email'**
  String get currentEmailLabel;

  /// No description provided for @saveProfileChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Profile Changes'**
  String get saveProfileChanges;

  /// No description provided for @securitySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettingsTitle;

  /// No description provided for @googleAccountManagedCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email and password are managed via your Google account. Changes are disabled.'**
  String get googleAccountManagedCredentials;

  /// No description provided for @updateEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Email'**
  String get updateEmailTitle;

  /// No description provided for @newEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'New Email'**
  String get newEmailLabel;

  /// No description provided for @confirmNewEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Email'**
  String get confirmNewEmailLabel;

  /// No description provided for @updatePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePasswordTitle;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @verificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verificationTitle;

  /// No description provided for @enterCurrentPasswordToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Enter Current Password to Confirm Changes'**
  String get enterCurrentPasswordToConfirm;

  /// No description provided for @forgotPasswordWait.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password? (Wait {seconds}s)'**
  String forgotPasswordWait(Object seconds);

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @cooldownSeconds.
  ///
  /// In en, this message translates to:
  /// **'Cooldown: {seconds}s'**
  String cooldownSeconds(Object seconds);

  /// No description provided for @updateSecuritySettings.
  ///
  /// In en, this message translates to:
  /// **'Update Security Settings'**
  String get updateSecuritySettings;

  /// No description provided for @changesSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Changes saved successfully!'**
  String get changesSavedSuccessfully;

  /// No description provided for @errorSavingChanges.
  ///
  /// In en, this message translates to:
  /// **'Error saving changes: {error}'**
  String errorSavingChanges(Object error);

  /// No description provided for @googleAccountManagedCredentialsShort.
  ///
  /// In en, this message translates to:
  /// **'Email and password managed via Google. Changes disabled.'**
  String get googleAccountManagedCredentialsShort;

  /// No description provided for @enterNewEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new email and/or new password.'**
  String get enterNewEmailOrPassword;

  /// No description provided for @enterCurrentPasswordToProceed.
  ///
  /// In en, this message translates to:
  /// **'Enter current password to proceed.'**
  String get enterCurrentPasswordToProceed;

  /// No description provided for @fillBothEmailFields.
  ///
  /// In en, this message translates to:
  /// **'Fill both email fields.'**
  String get fillBothEmailFields;

  /// No description provided for @emailAddressesDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Email addresses do not match.'**
  String get emailAddressesDoNotMatch;

  /// No description provided for @fillAllPasswordFields.
  ///
  /// In en, this message translates to:
  /// **'Fill all password fields.'**
  String get fillAllPasswordFields;

  /// No description provided for @newPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match.'**
  String get newPasswordsDoNotMatch;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {minLength} characters.'**
  String passwordMinLength(Object minLength);

  /// No description provided for @updateEmailAndPasswordSeparately.
  ///
  /// In en, this message translates to:
  /// **'Please update email and password separately.'**
  String get updateEmailAndPasswordSeparately;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent to new address!'**
  String get verificationEmailSent;

  /// No description provided for @passwordUpdatedSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Please sign in again.'**
  String get passwordUpdatedSignInAgain;

  /// No description provided for @failedToUpdateCredentials.
  ///
  /// In en, this message translates to:
  /// **'Failed to update credentials: {error}'**
  String failedToUpdateCredentials(Object error);

  /// No description provided for @noEmailAssociated.
  ///
  /// In en, this message translates to:
  /// **'No email associated with this account.'**
  String get noEmailAssociated;

  /// No description provided for @waitBeforeRequestingReset.
  ///
  /// In en, this message translates to:
  /// **'Please wait {seconds} seconds before requesting another reset email.'**
  String waitBeforeRequestingReset(Object seconds);

  /// No description provided for @recoveryEmailSentSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Recovery email sent. You will be signed out.'**
  String get recoveryEmailSentSignedOut;

  /// No description provided for @couldNotSendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Could not send reset email. Try again later.'**
  String get couldNotSendResetEmail;

  /// No description provided for @goBackLabel.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBackLabel;

  /// No description provided for @receiptCameraNoCameras.
  ///
  /// In en, this message translates to:
  /// **'No cameras available'**
  String get receiptCameraNoCameras;

  /// No description provided for @receiptCameraInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize camera: {error}'**
  String receiptCameraInitFailed(Object error);

  /// No description provided for @receiptCameraErrorTakingPicture.
  ///
  /// In en, this message translates to:
  /// **'Error taking picture: {error}'**
  String receiptCameraErrorTakingPicture(Object error);

  /// No description provided for @receiptCameraExtractingPrices.
  ///
  /// In en, this message translates to:
  /// **'Extracting prices and quantities...'**
  String get receiptCameraExtractingPrices;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

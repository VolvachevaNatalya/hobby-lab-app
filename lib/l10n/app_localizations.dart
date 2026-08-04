import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';
import 'app_localizations_ru.dart';

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
    Locale('he'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hobby Lab'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @btnLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get btnLogIn;

  /// No description provided for @btnSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get btnSignUp;

  /// No description provided for @btnContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get btnContinue;

  /// No description provided for @btnGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get btnGetStarted;

  /// No description provided for @btnBookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get btnBookNow;

  /// No description provided for @btnContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get btnContact;

  /// No description provided for @btnSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get btnSaveChanges;

  /// No description provided for @btnSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get btnSeeAll;

  /// No description provided for @btnLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get btnLogOut;

  /// No description provided for @btnEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get btnEditProfile;

  /// No description provided for @btnSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get btnSkip;

  /// No description provided for @btnLetsConnect.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Connect'**
  String get btnLetsConnect;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search activities, camps, classes...'**
  String get searchHint;

  /// No description provided for @searchConversations.
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get searchConversations;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'RECENT SEARCHES'**
  String get recentSearches;

  /// No description provided for @popularSearches.
  ///
  /// In en, this message translates to:
  /// **'POPULAR SEARCHES'**
  String get popularSearches;

  /// No description provided for @trendingCategories.
  ///
  /// In en, this message translates to:
  /// **'TRENDING CATEGORIES'**
  String get trendingCategories;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(String query);

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Discover. Learn. Grow.'**
  String get tagline;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Find the Best Activities'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover hundreds of classes, camps and workshops for your children nearby'**
  String get onboarding1Subtitle;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Easy Booking'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Book your favourite activities in a few taps and manage all schedules in one place'**
  String get onboarding2Subtitle;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Stay Connected'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Get updates, reminders and communicate with organizers directly in the app'**
  String get onboarding3Subtitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose\nLanguage'**
  String get chooseLanguage;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language to continue'**
  String get languageSubtitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log into your\naccount'**
  String get loginTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your journey'**
  String get loginSubtitle;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Hobby Lab and discover amazing activities'**
  String get registerSubtitle;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordHint;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreeToTerms;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get yourLocation;

  /// No description provided for @popularNearYou.
  ///
  /// In en, this message translates to:
  /// **'Popular Near You'**
  String get popularNearYou;

  /// No description provided for @thisWeekend.
  ///
  /// In en, this message translates to:
  /// **'This Weekend'**
  String get thisWeekend;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @upcomingBookings.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Bookings'**
  String get upcomingBookings;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @joinAsProvider.
  ///
  /// In en, this message translates to:
  /// **'Join as a service provider'**
  String get joinAsProvider;

  /// No description provided for @joinAsProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'List your classes and reach more families'**
  String get joinAsProviderSubtitle;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No Messages Yet'**
  String get noMessagesYet;

  /// No description provided for @noMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can contact an organizer, your conversations will appear here'**
  String get noMessagesSubtitle;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @noSavedActivities.
  ///
  /// In en, this message translates to:
  /// **'No Saved Activities'**
  String get noSavedActivities;

  /// No description provided for @noSavedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start exploring and save activities you\'re interested in for your children'**
  String get noSavedSubtitle;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @mainInformation.
  ///
  /// In en, this message translates to:
  /// **'Main information'**
  String get mainInformation;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneHint;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordContent.
  ///
  /// In en, this message translates to:
  /// **'Please contact support at support@hobbylab.com to reset your password.'**
  String get forgotPasswordContent;

  /// No description provided for @btnOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get btnOk;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get continueWithFacebook;

  /// No description provided for @continueWithGmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Gmail'**
  String get continueWithGmail;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @registerHeading.
  ///
  /// In en, this message translates to:
  /// **'Create your\naccount'**
  String get registerHeading;

  /// No description provided for @registerFamiliesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join thousands of families discovering activities.'**
  String get registerFamiliesSubtitle;

  /// No description provided for @byAgreeingTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get byAgreeingTerms;

  /// No description provided for @andConjunction.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andConjunction;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @errorFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get errorFillAllFields;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get errorInvalidCredentials;

  /// No description provided for @changeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change Location'**
  String get changeLocation;

  /// No description provided for @enterCityName.
  ///
  /// In en, this message translates to:
  /// **'Enter city name'**
  String get enterCityName;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @btnSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get btnSave;

  /// No description provided for @noActivitiesYet.
  ///
  /// In en, this message translates to:
  /// **'No activities yet'**
  String get noActivitiesYet;

  /// No description provided for @checkBackSoonActivities.
  ///
  /// In en, this message translates to:
  /// **'Check back soon for new activities'**
  String get checkBackSoonActivities;

  /// No description provided for @detectingLocation.
  ///
  /// In en, this message translates to:
  /// **'Detecting...'**
  String get detectingLocation;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get clearFilter;

  /// No description provided for @noCategoryActivitiesYet.
  ///
  /// In en, this message translates to:
  /// **'No {category} activities yet'**
  String noCategoryActivitiesYet(String category);

  /// No description provided for @checkBackSoonCategories.
  ///
  /// In en, this message translates to:
  /// **'Check back soon or explore other categories'**
  String get checkBackSoonCategories;

  /// No description provided for @activitiesSection.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activitiesSection;

  /// No description provided for @eventsSection.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsSection;

  /// No description provided for @tryDifferentKeywords.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords or browse categories'**
  String get tryDifferentKeywords;

  /// No description provided for @resultsFound.
  ///
  /// In en, this message translates to:
  /// **'results found'**
  String get resultsFound;

  /// No description provided for @allChip.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allChip;

  /// No description provided for @searchActivitiesHint.
  ///
  /// In en, this message translates to:
  /// **'Search activities...'**
  String get searchActivitiesHint;

  /// No description provided for @noActivitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No activities found'**
  String get noActivitiesFound;

  /// No description provided for @tryDifferentFilters.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords or filters'**
  String get tryDifferentFilters;

  /// No description provided for @countResults.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String countResults(int count);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get sectionAccount;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @sectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get sectionNotifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @classReminders.
  ///
  /// In en, this message translates to:
  /// **'Class Reminders'**
  String get classReminders;

  /// No description provided for @promotionsOffers.
  ///
  /// In en, this message translates to:
  /// **'Promotions & Offers'**
  String get promotionsOffers;

  /// No description provided for @newActivitiesNearby.
  ///
  /// In en, this message translates to:
  /// **'New Activities Nearby'**
  String get newActivitiesNearby;

  /// No description provided for @sectionApp.
  ///
  /// In en, this message translates to:
  /// **'APP'**
  String get sectionApp;

  /// No description provided for @sectionSupport.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get sectionSupport;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @sectionDangerZone.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get sectionDangerZone;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account and all data'**
  String get deleteAccountDesc;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete your account? This action cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @btnDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get btnDelete;

  /// No description provided for @goToOrgDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Organization Dashboard'**
  String get goToOrgDashboard;

  /// No description provided for @manageClassesEvents.
  ///
  /// In en, this message translates to:
  /// **'Manage your classes, events and groups'**
  String get manageClassesEvents;

  /// No description provided for @profileSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully'**
  String get profileSavedSuccess;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save. Please try again.'**
  String get profileSaveFailed;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No Notifications'**
  String get noNotifications;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get allCaughtUp;

  /// No description provided for @savedToList.
  ///
  /// In en, this message translates to:
  /// **'Saved to your list!'**
  String get savedToList;

  /// No description provided for @removedFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved'**
  String get removedFromSaved;

  /// No description provided for @openStatus.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openStatus;

  /// No description provided for @organizationLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organizationLabel;

  /// No description provided for @btnView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get btnView;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @actionWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get actionWebsite;

  /// No description provided for @actionDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get actionDirections;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescriptionAvailable;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @ageInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Age & Info'**
  String get ageInfoSection;

  /// No description provided for @ageRange.
  ///
  /// In en, this message translates to:
  /// **'Age Range'**
  String get ageRange;

  /// No description provided for @groupSize.
  ///
  /// In en, this message translates to:
  /// **'Group Size'**
  String get groupSize;

  /// No description provided for @groupsSection.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsSection;

  /// No description provided for @noGroupsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No groups available yet'**
  String get noGroupsAvailable;

  /// No description provided for @scheduleSection.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleSection;

  /// No description provided for @noScheduleAvailable.
  ///
  /// In en, this message translates to:
  /// **'No schedule available yet'**
  String get noScheduleAvailable;

  /// No description provided for @reviewsSection.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsSection;

  /// No description provided for @reviewsLabel.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get reviewsLabel;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet — be the first!'**
  String get noReviewsYet;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get writeReview;

  /// No description provided for @pricingFrom.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get pricingFrom;

  /// No description provided for @pricingPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get pricingPerMonth;

  /// No description provided for @addressNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Address not available'**
  String get addressNotAvailable;

  /// No description provided for @shareActivityMessage.
  ///
  /// In en, this message translates to:
  /// **'Check out \"{name}\" on HobbyLab!'**
  String shareActivityMessage(String name);

  /// No description provided for @shareActivityDefault.
  ///
  /// In en, this message translates to:
  /// **'Check out this activity on HobbyLab!'**
  String get shareActivityDefault;

  /// No description provided for @organizationsNearYou.
  ///
  /// In en, this message translates to:
  /// **'Organizations Near You'**
  String get organizationsNearYou;

  /// No description provided for @noOrgsYet.
  ///
  /// In en, this message translates to:
  /// **'No organizations yet'**
  String get noOrgsYet;

  /// No description provided for @checkBackSoonOrgs.
  ///
  /// In en, this message translates to:
  /// **'Check back soon for organizations in your area'**
  String get checkBackSoonOrgs;

  /// No description provided for @tabOrganizations.
  ///
  /// In en, this message translates to:
  /// **'Organizations'**
  String get tabOrganizations;

  /// No description provided for @searchCity.
  ///
  /// In en, this message translates to:
  /// **'Search City'**
  String get searchCity;

  /// No description provided for @searchCityHint.
  ///
  /// In en, this message translates to:
  /// **'Start typing a city name...'**
  String get searchCityHint;

  /// No description provided for @noCitySuggestions.
  ///
  /// In en, this message translates to:
  /// **'No cities found'**
  String get noCitySuggestions;

  /// No description provided for @showNationwide.
  ///
  /// In en, this message translates to:
  /// **'Show nationwide'**
  String get showNationwide;

  /// No description provided for @showNationwideHint.
  ///
  /// In en, this message translates to:
  /// **'If checked, this event will be visible to users in all cities'**
  String get showNationwideHint;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @errorFillRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get errorFillRequired;

  /// No description provided for @errorRatingRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a star rating'**
  String get errorRatingRequired;

  /// No description provided for @fieldTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get fieldTelegram;

  /// No description provided for @fieldYouTube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get fieldYouTube;

  /// No description provided for @fieldTikTok.
  ///
  /// In en, this message translates to:
  /// **'TikTok'**
  String get fieldTikTok;

  /// No description provided for @fieldWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get fieldWhatsApp;

  /// No description provided for @photosSection.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photosSection;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @photoLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 10 photos'**
  String get photoLimitReached;

  /// No description provided for @savedOrganizations.
  ///
  /// In en, this message translates to:
  /// **'Saved Organizations'**
  String get savedOrganizations;

  /// No description provided for @savedClasses.
  ///
  /// In en, this message translates to:
  /// **'Saved Classes'**
  String get savedClasses;

  /// No description provided for @savedEvents.
  ///
  /// In en, this message translates to:
  /// **'Saved Events'**
  String get savedEvents;

  /// No description provided for @currentPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordHint;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordHint;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPasswordHint;

  /// No description provided for @errorPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get errorPasswordTooShort;

  /// No description provided for @errorPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get errorPasswordsDoNotMatch;

  /// No description provided for @errorCurrentPasswordWrong.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get errorCurrentPasswordWrong;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccess;

  /// No description provided for @trialLesson.
  ///
  /// In en, this message translates to:
  /// **'Trial Lesson'**
  String get trialLesson;

  /// No description provided for @trialLessonPrice.
  ///
  /// In en, this message translates to:
  /// **'Trial Lesson Price'**
  String get trialLessonPrice;

  /// No description provided for @trialLessonComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get trialLessonComment;

  /// No description provided for @eventPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get eventPrice;

  /// No description provided for @eventFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get eventFree;

  /// No description provided for @eventPriceComment.
  ///
  /// In en, this message translates to:
  /// **'Price Comment'**
  String get eventPriceComment;

  /// No description provided for @myOrganizations.
  ///
  /// In en, this message translates to:
  /// **'My Organizations'**
  String get myOrganizations;

  /// No description provided for @myOrganizationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and manage your organizations'**
  String get myOrganizationsSubtitle;

  /// No description provided for @createOrganization.
  ///
  /// In en, this message translates to:
  /// **'Create Organization'**
  String get createOrganization;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @deleteOrganization.
  ///
  /// In en, this message translates to:
  /// **'Delete Organization'**
  String get deleteOrganization;

  /// No description provided for @deleteOrganizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Organization?'**
  String get deleteOrganizationTitle;

  /// No description provided for @deleteOrganizationWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this organization and all its data — classes, groups, events, photos, and reviews. This action cannot be undone.'**
  String get deleteOrganizationWarning;

  /// No description provided for @organizationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Organization deleted'**
  String get organizationDeleted;

  /// No description provided for @failedToDeleteOrganization.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete organization. Please try again.'**
  String get failedToDeleteOrganization;

  /// No description provided for @joinOrganization.
  ///
  /// In en, this message translates to:
  /// **'Join Organization'**
  String get joinOrganization;

  /// No description provided for @joinOrganizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join an organization using an invite code'**
  String get joinOrganizationSubtitle;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get inviteCodeLabel;

  /// No description provided for @inviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 8-character invite code'**
  String get inviteCodeHint;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyCode;

  /// No description provided for @changeInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Change invite code'**
  String get changeInviteCode;

  /// No description provided for @confirmAndJoin.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Join'**
  String get confirmAndJoin;

  /// No description provided for @requiresApprovalNote.
  ///
  /// In en, this message translates to:
  /// **'Admin approval required before joining'**
  String get requiresApprovalNote;

  /// No description provided for @joinImmediateNote.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be added as a member immediately'**
  String get joinImmediateNote;

  /// No description provided for @requestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request submitted. Waiting for admin approval.'**
  String get requestSubmitted;

  /// No description provided for @joinedOrgSuccess.
  ///
  /// In en, this message translates to:
  /// **'You\'ve joined the organization!'**
  String get joinedOrgSuccess;

  /// No description provided for @invitesAndRequests.
  ///
  /// In en, this message translates to:
  /// **'Invites & Requests'**
  String get invitesAndRequests;

  /// No description provided for @invitesAndRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage invite codes and join requests'**
  String get invitesAndRequestsSubtitle;

  /// No description provided for @inviteCodes.
  ///
  /// In en, this message translates to:
  /// **'Invite Codes'**
  String get inviteCodes;

  /// No description provided for @joinRequests.
  ///
  /// In en, this message translates to:
  /// **'Join Requests'**
  String get joinRequests;

  /// No description provided for @createInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Create Invite Code'**
  String get createInviteCode;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @inactiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveStatus;

  /// No description provided for @approvalRequired.
  ///
  /// In en, this message translates to:
  /// **'Approval required'**
  String get approvalRequired;

  /// No description provided for @noApprovalRequired.
  ///
  /// In en, this message translates to:
  /// **'No approval'**
  String get noApprovalRequired;

  /// No description provided for @expiresPrefix.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expiresPrefix;

  /// No description provided for @deactivateCode.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivateCode;

  /// No description provided for @defaultRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Role'**
  String get defaultRoleLabel;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @requiresApprovalToggle.
  ///
  /// In en, this message translates to:
  /// **'Requires Approval'**
  String get requiresApprovalToggle;

  /// No description provided for @noInviteCodesYet.
  ///
  /// In en, this message translates to:
  /// **'No invite codes yet'**
  String get noInviteCodesYet;

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending join requests'**
  String get noPendingRequests;

  /// No description provided for @btnApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get btnApprove;

  /// No description provided for @btnReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get btnReject;

  /// No description provided for @codeDeactivatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invite code deactivated'**
  String get codeDeactivatedSuccess;

  /// No description provided for @requestApprovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get requestApprovedSuccess;

  /// No description provided for @requestRejectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get requestRejectedSuccess;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @btnCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get btnCreate;

  /// No description provided for @membersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTitle;

  /// No description provided for @membersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage organization members'**
  String get membersSubtitle;

  /// No description provided for @noMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get noMembersFound;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make Admin'**
  String get makeAdmin;

  /// No description provided for @makeMember.
  ///
  /// In en, this message translates to:
  /// **'Make Member'**
  String get makeMember;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeMember;

  /// No description provided for @removeMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Member?'**
  String get removeMemberTitle;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the organization?'**
  String removeMemberConfirm(String name);

  /// No description provided for @memberRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get memberRemovedSuccess;

  /// No description provided for @memberRoleChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Role updated'**
  String get memberRoleChangedSuccess;

  /// No description provided for @selectCategories.
  ///
  /// In en, this message translates to:
  /// **'Select Categories'**
  String get selectCategories;

  /// No description provided for @maxCategoriesReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 10 categories'**
  String get maxCategoriesReached;

  /// No description provided for @nationwideLabel.
  ///
  /// In en, this message translates to:
  /// **'Nationwide'**
  String get nationwideLabel;

  /// No description provided for @repeatSection.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatSection;

  /// No description provided for @doesNotRepeat.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get doesNotRepeat;

  /// No description provided for @repeatPickerDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatPickerDaily;

  /// No description provided for @repeatPickerWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatPickerWeekly;

  /// No description provided for @repeatPickerMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatPickerMonthly;

  /// No description provided for @repeatPickerYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get repeatPickerYearly;

  /// No description provided for @repeatPickerCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get repeatPickerCustom;

  /// No description provided for @repeatEveryLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat every'**
  String get repeatEveryLabel;

  /// No description provided for @repeatUnitDay.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get repeatUnitDay;

  /// No description provided for @repeatUnitWeek.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get repeatUnitWeek;

  /// No description provided for @repeatUnitMonth.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get repeatUnitMonth;

  /// No description provided for @repeatUnitYear.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get repeatUnitYear;

  /// No description provided for @repeatEndsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get repeatEndsLabel;

  /// No description provided for @repeatAfterEventsOption.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get repeatAfterEventsOption;

  /// No description provided for @repeatOnDateOption.
  ///
  /// In en, this message translates to:
  /// **'On date'**
  String get repeatOnDateOption;

  /// No description provided for @repeatNeverOption.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get repeatNeverOption;

  /// No description provided for @numberOfEventsHint.
  ///
  /// In en, this message translates to:
  /// **'Number of events'**
  String get numberOfEventsHint;

  /// No description provided for @firstEventIncludedNote.
  ///
  /// In en, this message translates to:
  /// **'The first event is included in the count'**
  String get firstEventIncludedNote;

  /// No description provided for @repeatMinCountError.
  ///
  /// In en, this message translates to:
  /// **'Minimum 2 events'**
  String get repeatMinCountError;

  /// No description provided for @repeatEndDateError.
  ///
  /// In en, this message translates to:
  /// **'End date must be after the start date'**
  String get repeatEndDateError;

  /// No description provided for @repeatsDaily.
  ///
  /// In en, this message translates to:
  /// **'Repeats daily'**
  String get repeatsDaily;

  /// No description provided for @repeatsWeekly.
  ///
  /// In en, this message translates to:
  /// **'Repeats weekly'**
  String get repeatsWeekly;

  /// No description provided for @repeatsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Repeats monthly'**
  String get repeatsMonthly;

  /// No description provided for @repeatsYearly.
  ///
  /// In en, this message translates to:
  /// **'Repeats yearly'**
  String get repeatsYearly;

  /// No description provided for @repeatsEveryNDays.
  ///
  /// In en, this message translates to:
  /// **'Every {n} days'**
  String repeatsEveryNDays(int n);

  /// No description provided for @repeatsEveryNWeeks.
  ///
  /// In en, this message translates to:
  /// **'Every {n} weeks'**
  String repeatsEveryNWeeks(int n);

  /// No description provided for @repeatsEveryNMonths.
  ///
  /// In en, this message translates to:
  /// **'Every {n} months'**
  String repeatsEveryNMonths(int n);

  /// No description provided for @repeatsEveryNYears.
  ///
  /// In en, this message translates to:
  /// **'Every {n} years'**
  String repeatsEveryNYears(int n);

  /// No description provided for @repeatCountSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} events'**
  String repeatCountSummary(int count);

  /// No description provided for @repeatUntilDate.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String repeatUntilDate(String date);

  /// No description provided for @repeatNoEndDate.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get repeatNoEndDate;

  /// No description provided for @editEventScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit recurring event'**
  String get editEventScopeTitle;

  /// No description provided for @deleteEventScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete recurring event'**
  String get deleteEventScopeTitle;

  /// No description provided for @scopeOnlyThisEvent.
  ///
  /// In en, this message translates to:
  /// **'Only this event'**
  String get scopeOnlyThisEvent;

  /// No description provided for @scopeThisAndFollowing.
  ///
  /// In en, this message translates to:
  /// **'This and following events'**
  String get scopeThisAndFollowing;

  /// No description provided for @scopeEntireSeries.
  ///
  /// In en, this message translates to:
  /// **'Entire series'**
  String get scopeEntireSeries;

  /// No description provided for @upcomingEventsTab.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingEventsTab;

  /// No description provided for @pastEventsTab.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get pastEventsTab;
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
      <String>['en', 'he', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

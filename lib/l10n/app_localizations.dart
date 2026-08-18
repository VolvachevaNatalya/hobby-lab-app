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
  /// **'Discover Activities'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Find the best classes, camps, and workshops\nfor your children nearby'**
  String get onboarding1Subtitle;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Connect with Organizers'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Message organizers directly, ask questions,\nand get quick responses'**
  String get onboarding2Subtitle;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Save & Organize'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark your favourites, track schedules,\nand never miss a registration'**
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

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @aboutIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'HobbyLab - where interests bring people together.'**
  String get aboutIntroTitle;

  /// No description provided for @aboutIntroBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re building a platform that brings people, organizations, and events together in one place. Here you can discover classes, clubs, activities, and events nearby - for children and adults.'**
  String get aboutIntroBody;

  /// No description provided for @aboutOurGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Our Goal'**
  String get aboutOurGoalTitle;

  /// No description provided for @aboutOurGoalBody.
  ///
  /// In en, this message translates to:
  /// **'We want to make discovering interesting activities simple and convenient. Instead of searching through dozens of websites, groups, and pages - you can find options, learn more, and choose what suits you in one place.'**
  String get aboutOurGoalBody;

  /// No description provided for @aboutForParticipantsTitle.
  ///
  /// In en, this message translates to:
  /// **'For Participants'**
  String get aboutForParticipantsTitle;

  /// No description provided for @aboutForParticipantsBody.
  ///
  /// In en, this message translates to:
  /// **'Find activities and events by interest, category, and location, save your favorites, and discover new opportunities nearby.'**
  String get aboutForParticipantsBody;

  /// No description provided for @aboutForOrgsTitle.
  ///
  /// In en, this message translates to:
  /// **'For Organizations'**
  String get aboutForOrgsTitle;

  /// No description provided for @aboutForOrgsBody.
  ///
  /// In en, this message translates to:
  /// **'HobbyLab helps organizations and instructors introduce themselves, publish classes and events, and reach new participants.'**
  String get aboutForOrgsBody;

  /// No description provided for @aboutBizServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional Services for Businesses'**
  String get aboutBizServicesTitle;

  /// No description provided for @aboutBizServicesBody.
  ///
  /// In en, this message translates to:
  /// **'We also help businesses grow and promote themselves - from social media management and digital marketing to content creation and digital products. SMM, targeted advertising, photo and video production, Reels, website and app development - everything your business needs to become more visible and attract new customers.'**
  String get aboutBizServicesBody;

  /// No description provided for @aboutContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Have a Question?'**
  String get aboutContactTitle;

  /// No description provided for @aboutContactBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re always happy to hear from you - whether you have a question, suggestion, or idea.'**
  String get aboutContactBody;

  /// No description provided for @aboutContactBtn.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get aboutContactBtn;

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
  /// **'Contact Support'**
  String get helpCenter;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @supportSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get supportSubjectLabel;

  /// No description provided for @supportSubjectAppProblem.
  ///
  /// In en, this message translates to:
  /// **'App problem'**
  String get supportSubjectAppProblem;

  /// No description provided for @supportSubjectQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get supportSubjectQuestion;

  /// No description provided for @supportSubjectOrgEvent.
  ///
  /// In en, this message translates to:
  /// **'Organization / Event'**
  String get supportSubjectOrgEvent;

  /// No description provided for @supportSubjectAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get supportSubjectAccount;

  /// No description provided for @supportSubjectSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get supportSubjectSuggestion;

  /// No description provided for @supportSubjectOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get supportSubjectOther;

  /// No description provided for @supportMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get supportMessageLabel;

  /// No description provided for @supportMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue or question...'**
  String get supportMessageHint;

  /// No description provided for @supportSendBtn.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get supportSendBtn;

  /// No description provided for @supportSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Request sent. Thank you for your feedback!'**
  String get supportSuccessMessage;

  /// No description provided for @supportErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send request. Please try again.'**
  String get supportErrorMessage;

  /// No description provided for @supportMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Message cannot be empty'**
  String get supportMessageRequired;

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

  /// No description provided for @duplicateEvent.
  ///
  /// In en, this message translates to:
  /// **'Duplicate event'**
  String get duplicateEvent;

  /// No description provided for @duplicateEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Event'**
  String get duplicateEventTitle;

  /// No description provided for @viewSchedule.
  ///
  /// In en, this message translates to:
  /// **'View schedule'**
  String get viewSchedule;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// No description provided for @noUpcomingOccurrences.
  ///
  /// In en, this message translates to:
  /// **'No upcoming occurrences'**
  String get noUpcomingOccurrences;

  /// No description provided for @noOccurrences.
  ///
  /// In en, this message translates to:
  /// **'No events in this series'**
  String get noOccurrences;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get navClasses;

  /// No description provided for @navEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// No description provided for @orgDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organization Dashboard'**
  String get orgDashboardSubtitle;

  /// No description provided for @myOrganizationFallback.
  ///
  /// In en, this message translates to:
  /// **'My Organization'**
  String get myOrganizationFallback;

  /// No description provided for @statGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get statGroups;

  /// No description provided for @statStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get statStudents;

  /// No description provided for @myClasses.
  ///
  /// In en, this message translates to:
  /// **'My Classes'**
  String get myClasses;

  /// No description provided for @myEvents.
  ///
  /// In en, this message translates to:
  /// **'My Events'**
  String get myEvents;

  /// No description provided for @recentMessages.
  ///
  /// In en, this message translates to:
  /// **'Recent Messages'**
  String get recentMessages;

  /// No description provided for @btnAdd.
  ///
  /// In en, this message translates to:
  /// **'+ Add'**
  String get btnAdd;

  /// No description provided for @noClassesHint.
  ///
  /// In en, this message translates to:
  /// **'No classes yet. Tap + Add to create one.'**
  String get noClassesHint;

  /// No description provided for @noEventsHint.
  ///
  /// In en, this message translates to:
  /// **'No events yet. Tap + Add to create one.'**
  String get noEventsHint;

  /// No description provided for @noRecentMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get noRecentMessages;

  /// No description provided for @btnManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get btnManage;

  /// No description provided for @btnNewClass.
  ///
  /// In en, this message translates to:
  /// **'New Class'**
  String get btnNewClass;

  /// No description provided for @noClassesYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No Classes Yet'**
  String get noClassesYetTitle;

  /// No description provided for @noClassesYetBody.
  ///
  /// In en, this message translates to:
  /// **'No classes yet. Add your first class!'**
  String get noClassesYetBody;

  /// No description provided for @agesLabel.
  ///
  /// In en, this message translates to:
  /// **'Ages'**
  String get agesLabel;

  /// No description provided for @perMonthSuffix.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get perMonthSuffix;

  /// No description provided for @studentsLabel.
  ///
  /// In en, this message translates to:
  /// **'students'**
  String get studentsLabel;

  /// No description provided for @noGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'No groups added yet.'**
  String get noGroupsYet;

  /// No description provided for @btnNewEvent.
  ///
  /// In en, this message translates to:
  /// **'New Event'**
  String get btnNewEvent;

  /// No description provided for @noUpcomingEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events yet.'**
  String get noUpcomingEventsYet;

  /// No description provided for @noPastEvents.
  ///
  /// In en, this message translates to:
  /// **'No past events.'**
  String get noPastEvents;

  /// No description provided for @noMessagesYetBody.
  ///
  /// In en, this message translates to:
  /// **'Messages from your clients will appear here'**
  String get noMessagesYetBody;

  /// No description provided for @verifiedOrganization.
  ///
  /// In en, this message translates to:
  /// **'Verified Organization'**
  String get verifiedOrganization;

  /// No description provided for @businessSection.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get businessSection;

  /// No description provided for @billingPayments.
  ///
  /// In en, this message translates to:
  /// **'Billing & Payments'**
  String get billingPayments;

  /// No description provided for @analyticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsLabel;

  /// No description provided for @supportSection.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportSection;

  /// No description provided for @termsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy'**
  String get termsPrivacy;

  /// No description provided for @exitDashboard.
  ///
  /// In en, this message translates to:
  /// **'Exit Dashboard'**
  String get exitDashboard;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon.'**
  String get comingSoon;

  /// No description provided for @btnEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get btnEdit;

  /// No description provided for @failedToDeleteClass.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete class. Please try again.'**
  String get failedToDeleteClass;

  /// No description provided for @failedToDeleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete event. Please try again.'**
  String get failedToDeleteEvent;

  /// No description provided for @groupCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 group} other{{count} groups}}'**
  String groupCount(int count);

  /// No description provided for @eventSpotsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 spot} other{{count} spots}}'**
  String eventSpotsCount(int count);

  /// No description provided for @tapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get tapToChange;

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image'**
  String get failedToUploadImage;

  /// No description provided for @btnDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get btnDone;

  /// No description provided for @editClass.
  ///
  /// In en, this message translates to:
  /// **'Edit Class'**
  String get editClass;

  /// No description provided for @uploadClassImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Class Image'**
  String get uploadClassImage;

  /// No description provided for @classDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Class Details'**
  String get classDetailsSection;

  /// No description provided for @classNameHint.
  ///
  /// In en, this message translates to:
  /// **'Class name'**
  String get classNameHint;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionHint;

  /// No description provided for @errorSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one category'**
  String get errorSelectCategory;

  /// No description provided for @categoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesLabel;

  /// No description provided for @addGroup.
  ///
  /// In en, this message translates to:
  /// **'Add Group'**
  String get addGroup;

  /// No description provided for @createClass.
  ///
  /// In en, this message translates to:
  /// **'Create Class'**
  String get createClass;

  /// No description provided for @classCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Class created successfully'**
  String get classCreatedSuccess;

  /// No description provided for @failedToUpdateClass.
  ///
  /// In en, this message translates to:
  /// **'Failed to update class'**
  String get failedToUpdateClass;

  /// No description provided for @failedToCreateClass.
  ///
  /// In en, this message translates to:
  /// **'Failed to create class. Please try again.'**
  String get failedToCreateClass;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEvent;

  /// No description provided for @uploadEventImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Event Image'**
  String get uploadEventImage;

  /// No description provided for @eventDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetailsSection;

  /// No description provided for @eventNameHint.
  ///
  /// In en, this message translates to:
  /// **'Event name'**
  String get eventNameHint;

  /// No description provided for @dateTimeSection.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateTimeSection;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @locationSection.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationSection;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'Address / venue name'**
  String get addressHint;

  /// No description provided for @cityHint.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityHint;

  /// No description provided for @participantsSection.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participantsSection;

  /// No description provided for @minAgeHint.
  ///
  /// In en, this message translates to:
  /// **'Min age'**
  String get minAgeHint;

  /// No description provided for @maxAgeHint.
  ///
  /// In en, this message translates to:
  /// **'Max age'**
  String get maxAgeHint;

  /// No description provided for @maxCapacityHint.
  ///
  /// In en, this message translates to:
  /// **'Max capacity'**
  String get maxCapacityHint;

  /// No description provided for @priceHint.
  ///
  /// In en, this message translates to:
  /// **'Price (₪) — leave blank if free'**
  String get priceHint;

  /// No description provided for @priceCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Price comment (optional)'**
  String get priceCommentHint;

  /// No description provided for @createEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// No description provided for @eventCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Event created successfully'**
  String get eventCreatedSuccess;

  /// No description provided for @failedToCreateEvent.
  ///
  /// In en, this message translates to:
  /// **'Failed to create event. Please try again.'**
  String get failedToCreateEvent;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get editGroup;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get newGroup;

  /// No description provided for @groupDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Group Details'**
  String get groupDetailsSection;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Group name (e.g. U10 Group)'**
  String get groupNameHint;

  /// No description provided for @ageRangeSection.
  ///
  /// In en, this message translates to:
  /// **'Age Range'**
  String get ageRangeSection;

  /// No description provided for @capacityPriceSection.
  ///
  /// In en, this message translates to:
  /// **'Capacity & Price'**
  String get capacityPriceSection;

  /// No description provided for @maxStudentsHint.
  ///
  /// In en, this message translates to:
  /// **'Max students'**
  String get maxStudentsHint;

  /// No description provided for @pricePerMonthHint.
  ///
  /// In en, this message translates to:
  /// **'Price per month (₪)'**
  String get pricePerMonthHint;

  /// No description provided for @timeSlotCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time slot} other{{count} time slots}}'**
  String timeSlotCount(int count);

  /// No description provided for @addSchedule.
  ///
  /// In en, this message translates to:
  /// **'Add Schedule'**
  String get addSchedule;

  /// No description provided for @groupCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Group created successfully'**
  String get groupCreatedSuccess;

  /// No description provided for @failedToCreateGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to create group. Please try again.'**
  String get failedToCreateGroup;

  /// No description provided for @addAnotherTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Add Another Time Slot'**
  String get addAnotherTimeSlot;

  /// No description provided for @saveSchedule.
  ///
  /// In en, this message translates to:
  /// **'Save Schedule'**
  String get saveSchedule;

  /// No description provided for @slotLabel.
  ///
  /// In en, this message translates to:
  /// **'Slot {number}'**
  String slotLabel(int number);

  /// No description provided for @dayOfWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Day of week'**
  String get dayOfWeekLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @scheduleSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Schedule saved successfully'**
  String get scheduleSavedSuccess;

  /// No description provided for @failedToSaveSchedule.
  ///
  /// In en, this message translates to:
  /// **'Failed to save schedule. Please try again.'**
  String get failedToSaveSchedule;

  /// No description provided for @daySunAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySunAbbrev;

  /// No description provided for @dayMonAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMonAbbrev;

  /// No description provided for @dayTueAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTueAbbrev;

  /// No description provided for @dayWedAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWedAbbrev;

  /// No description provided for @dayThuAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThuAbbrev;

  /// No description provided for @dayFriAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFriAbbrev;

  /// No description provided for @daySatAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySatAbbrev;

  /// No description provided for @orgNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization Name'**
  String get orgNameLabel;

  /// No description provided for @orgPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get orgPhoneHint;

  /// No description provided for @orgEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get orgEmailHint;

  /// No description provided for @websiteHint.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get websiteHint;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @socialMediaSection.
  ///
  /// In en, this message translates to:
  /// **'Social Media'**
  String get socialMediaSection;

  /// No description provided for @fieldInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get fieldInstagram;

  /// No description provided for @fieldFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get fieldFacebook;

  /// No description provided for @mediaSection.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get mediaSection;

  /// No description provided for @logoLabel.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logoLabel;

  /// No description provided for @bannerLabel.
  ///
  /// In en, this message translates to:
  /// **'Banner'**
  String get bannerLabel;

  /// No description provided for @uploadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploadingLabel;

  /// No description provided for @imageSelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Image selected'**
  String get imageSelectedLabel;

  /// No description provided for @tapToReplace.
  ///
  /// In en, this message translates to:
  /// **'Tap to replace'**
  String get tapToReplace;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get selectCity;

  /// No description provided for @trialLessonAvailable.
  ///
  /// In en, this message translates to:
  /// **'Trial lesson available'**
  String get trialLessonAvailable;

  /// No description provided for @btnNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get btnNext;

  /// No description provided for @letsConnect.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Connect'**
  String get letsConnect;

  /// No description provided for @typeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessageHint;

  /// No description provided for @failedToSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message. Please try again.'**
  String get failedToSendMessage;

  /// No description provided for @nearbyActivities.
  ///
  /// In en, this message translates to:
  /// **'Nearby Activities'**
  String get nearbyActivities;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @mapActivitiesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Activities'**
  String mapActivitiesCount(int count);

  /// No description provided for @notifNewMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get notifNewMessageTitle;

  /// No description provided for @notifNewMessageBody.
  ///
  /// In en, this message translates to:
  /// **'You have a new message'**
  String get notifNewMessageBody;

  /// No description provided for @notificationScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationScreenTitle;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @relatedActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Related Activity'**
  String get relatedActivityLabel;

  /// No description provided for @viewActivityBtn.
  ///
  /// In en, this message translates to:
  /// **'View Activity'**
  String get viewActivityBtn;

  /// No description provided for @notifAppointmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment Notifications'**
  String get notifAppointmentsTitle;

  /// No description provided for @notifAppointmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders about upcoming classes and bookings'**
  String get notifAppointmentsSubtitle;

  /// No description provided for @notifChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Notifications'**
  String get notifChatTitle;

  /// No description provided for @notifChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New messages from organizers'**
  String get notifChatSubtitle;

  /// No description provided for @notifActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Updates'**
  String get notifActivityTitle;

  /// No description provided for @notifActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Changes to activities you\'ve booked or saved'**
  String get notifActivitySubtitle;

  /// No description provided for @notifOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Offers & Promotions'**
  String get notifOffersTitle;

  /// No description provided for @notifOffersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Flash deals, discounts, and special events'**
  String get notifOffersSubtitle;

  /// No description provided for @notifChooseDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose which notifications you want to receive'**
  String get notifChooseDesc;

  /// No description provided for @imageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get imageUnavailable;

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsTitle;

  /// No description provided for @writeBtn.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get writeBtn;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String reviewsCount(int count);

  /// No description provided for @noReviewsYetSimple.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYetSimple;

  /// No description provided for @beFirstReview.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share your experience'**
  String get beFirstReview;

  /// No description provided for @anonymousReviewer.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymousReviewer;

  /// No description provided for @anyAge.
  ///
  /// In en, this message translates to:
  /// **'Any age'**
  String get anyAge;

  /// No description provided for @ageFromTo.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to} years'**
  String ageFromTo(int from, int to);

  /// No description provided for @ageFromOnly.
  ///
  /// In en, this message translates to:
  /// **'{from}+ years'**
  String ageFromOnly(int from);

  /// No description provided for @upToCapacity.
  ///
  /// In en, this message translates to:
  /// **'Up to {total}'**
  String upToCapacity(int total);

  /// No description provided for @groupFallback.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupFallback;

  /// No description provided for @ageFromToShort.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to} yrs'**
  String ageFromToShort(int from, int to);

  /// No description provided for @ageFromOnlyShort.
  ///
  /// In en, this message translates to:
  /// **'{from}+ yrs'**
  String ageFromOnlyShort(int from);

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// No description provided for @btnReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get btnReset;

  /// No description provided for @filterPriceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get filterPriceRange;

  /// No description provided for @filterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterCategory;

  /// No description provided for @filterDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get filterDistance;

  /// No description provided for @ageSuffix.
  ///
  /// In en, this message translates to:
  /// **'yrs'**
  String get ageSuffix;

  /// No description provided for @upToKm.
  ///
  /// In en, this message translates to:
  /// **'Up to {distance} km'**
  String upToKm(int distance);

  /// No description provided for @maxKmLabel.
  ///
  /// In en, this message translates to:
  /// **'20 km max'**
  String get maxKmLabel;

  /// No description provided for @btnShowResults.
  ///
  /// In en, this message translates to:
  /// **'Show Results'**
  String get btnShowResults;

  /// No description provided for @failedUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo. Please try again.'**
  String get failedUploadPhoto;

  /// No description provided for @alreadyReviewed.
  ///
  /// In en, this message translates to:
  /// **'You have already reviewed this organization'**
  String get alreadyReviewed;

  /// No description provided for @failedSubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit review. Please try again.'**
  String get failedSubmitReview;

  /// No description provided for @reviewingExperience.
  ///
  /// In en, this message translates to:
  /// **'Reviewing your experience'**
  String get reviewingExperience;

  /// No description provided for @yourRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Rating'**
  String get yourRatingLabel;

  /// No description provided for @ratingPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get ratingPoor;

  /// No description provided for @ratingFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get ratingFair;

  /// No description provided for @ratingGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get ratingGood;

  /// No description provided for @ratingGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get ratingGreat;

  /// No description provided for @ratingExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get ratingExcellent;

  /// No description provided for @yourReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Review'**
  String get yourReviewLabel;

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'Share your experience with this activity...'**
  String get reviewHint;

  /// No description provided for @photosLabel.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photosLabel;

  /// No description provided for @photoOptionalCount.
  ///
  /// In en, this message translates to:
  /// **'(optional, {current}/{max})'**
  String photoOptionalCount(int current, int max);

  /// No description provided for @addBtn.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addBtn;

  /// No description provided for @submitReviewBtn.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReviewBtn;

  /// No description provided for @reviewSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Submitted!'**
  String get reviewSubmittedTitle;

  /// No description provided for @reviewSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you for sharing your experience. Your review helps other families make the right choice.'**
  String get reviewSubmittedBody;

  /// No description provided for @backToReviewsBtn.
  ///
  /// In en, this message translates to:
  /// **'Back to Reviews'**
  String get backToReviewsBtn;

  /// No description provided for @monthJanAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJanAbbrev;

  /// No description provided for @monthFebAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFebAbbrev;

  /// No description provided for @monthMarAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMarAbbrev;

  /// No description provided for @monthAprAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthAprAbbrev;

  /// No description provided for @monthMayAbbrev.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMayAbbrev;

  /// No description provided for @monthJunAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJunAbbrev;

  /// No description provided for @monthJulAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJulAbbrev;

  /// No description provided for @monthAugAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAugAbbrev;

  /// No description provided for @monthSepAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSepAbbrev;

  /// No description provided for @monthOctAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOctAbbrev;

  /// No description provided for @monthNovAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNovAbbrev;

  /// No description provided for @monthDecAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDecAbbrev;

  /// No description provided for @failedToLoadEvent.
  ///
  /// In en, this message translates to:
  /// **'Failed to load event'**
  String get failedToLoadEvent;

  /// No description provided for @checkOutEventMsg.
  ///
  /// In en, this message translates to:
  /// **'Check out \"{title}\" on HobbyLab!'**
  String checkOutEventMsg(String title);

  /// No description provided for @checkOutEventDefault.
  ///
  /// In en, this message translates to:
  /// **'Check out this event on HobbyLab!'**
  String get checkOutEventDefault;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @detailsSection.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsSection;

  /// No description provided for @eventAgesFormat.
  ///
  /// In en, this message translates to:
  /// **'Ages {min}–{max}'**
  String eventAgesFormat(int min, int max);

  /// No description provided for @organizationFallback.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organizationFallback;

  /// No description provided for @otherEventsSection.
  ///
  /// In en, this message translates to:
  /// **'Other Events'**
  String get otherEventsSection;

  /// No description provided for @failedToLoadSchedule.
  ///
  /// In en, this message translates to:
  /// **'Failed to load schedule'**
  String get failedToLoadSchedule;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @actionMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get actionMessage;

  /// No description provided for @ourClassesSection.
  ///
  /// In en, this message translates to:
  /// **'Our Classes'**
  String get ourClassesSection;

  /// No description provided for @noClassesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No classes available yet'**
  String get noClassesAvailable;

  /// No description provided for @upcomingEventsSection.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events'**
  String get upcomingEventsSection;

  /// No description provided for @noUpcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get noUpcomingEvents;

  /// No description provided for @unnamedClass.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Class'**
  String get unnamedClass;

  /// No description provided for @retryBtn.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryBtn;

  /// No description provided for @pleaseWaitUpload.
  ///
  /// In en, this message translates to:
  /// **'Please wait for image upload to finish'**
  String get pleaseWaitUpload;

  /// No description provided for @imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed — please try again or remove the photo'**
  String get imageUploadFailed;

  /// No description provided for @failedToRegister.
  ///
  /// In en, this message translates to:
  /// **'Failed to register. Please try again.'**
  String get failedToRegister;

  /// No description provided for @orgDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Organization Details'**
  String get orgDetailsSection;

  /// No description provided for @contactInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInfoSection;

  /// No description provided for @workingHoursSection.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get workingHoursSection;

  /// No description provided for @becomeProvider.
  ///
  /// In en, this message translates to:
  /// **'Become a Provider'**
  String get becomeProvider;

  /// No description provided for @uploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload Logo'**
  String get uploadLogo;

  /// No description provided for @submitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submitApplication;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @unnamedEvent.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Event'**
  String get unnamedEvent;

  /// No description provided for @accountSecuritySection.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT SECURITY'**
  String get accountSecuritySection;

  /// No description provided for @timeNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get timeNow;

  /// No description provided for @changesSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Changes saved successfully'**
  String get changesSavedSuccess;

  /// No description provided for @failedToSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Failed to save changes'**
  String get failedToSaveChanges;
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

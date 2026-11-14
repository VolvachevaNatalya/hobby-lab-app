import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_lab/models/app_category.dart';
import 'package:hobby_lab/models/app_class.dart';
import 'package:hobby_lab/models/app_event.dart';
import 'package:hobby_lab/models/organization.dart';
import 'package:hobby_lab/services/saved_activities.dart';

void main() {
  // ── AppCategory ─────────────────────────────────────────────────────────────

  group('AppCategory.fromJson', () {
    test('parses all localized name fields', () {
      final cat = AppCategory.fromJson({
        'id': '7',
        'name': 'Art',
        'name_en': 'Art',
        'name_ru': 'Искусство',
        'name_he': 'אמנות',
      });
      expect(cat.id, '7');
      expect(cat.name, 'Art');
      expect(cat.nameEn, 'Art');
      expect(cat.nameRu, 'Искусство');
      expect(cat.nameHe, 'אמנות');
      expect(cat.iconUrl, isNull);
    });

    test('parses icon_url when present', () {
      final cat = AppCategory.fromJson({
        'id': '3',
        'name': 'Sport',
        'name_en': 'Sport',
        'icon_url': 'https://cdn.example.com/icons/sport.png',
      });
      expect(cat.iconUrl, 'https://cdn.example.com/icons/sport.png');
    });

    test('iconUrl is null when field absent', () {
      final cat = AppCategory.fromJson({'id': '1', 'name': 'Music'});
      expect(cat.iconUrl, isNull);
    });

    test('localizedName falls back to nameEn then name', () {
      final cat = AppCategory.fromJson({
        'id': '2',
        'name': 'Dance',
        'name_en': 'Dance',
        'name_ru': 'Танцы',
      });
      expect(cat.localizedName('ru'), 'Танцы');
      expect(cat.localizedName('he'), 'Dance'); // no he → falls back to en
      expect(cat.localizedName('en'), 'Dance');
    });
  });

  // ── AppClass ──────────────────────────────────────────────────────────────────

  group('AppClass.fromJson', () {
    test('parses core fields', () {
      final cls = AppClass.fromJson({
        'id': '42',
        'name': 'Ballet for Kids',
        'organization_name': 'Dance Studio',
        'organization_id': '7',
        'average_rating': 4.8,
        'review_count': 15,
        'description': 'A fun ballet class',
      });
      expect(cls.id, '42');
      expect(cls.title, 'Ballet for Kids');
      expect(cls.organizationName, 'Dance Studio');
      expect(cls.averageRating, 4.8);
      expect(cls.reviewCount, 15);
    });

    test('parses image_url when present', () {
      final cls = AppClass.fromJson({
        'id': '1',
        'name': 'Yoga',
        'organization_name': 'Studio',
        'organization_id': '2',
        'average_rating': 5.0,
        'review_count': 3,
        'description': '',
        'image_url': 'https://cdn.example.com/yoga.jpg',
      });
      expect(cls.imageUrl, 'https://cdn.example.com/yoga.jpg');
    });

    test('imageUrl is null when field absent (backward compat)', () {
      final cls = AppClass.fromJson({
        'id': '2',
        'name': 'Art Class',
        'organization_name': 'Art Studio',
        'organization_id': '3',
        'average_rating': 4.0,
        'review_count': 0,
        'description': '',
      });
      expect(cls.imageUrl, isNull);
    });

    test('imageUrl is null when field is null in JSON', () {
      final cls = AppClass.fromJson({
        'id': '3',
        'name': 'Music',
        'organization_name': 'Music School',
        'organization_id': '4',
        'average_rating': 4.2,
        'review_count': 5,
        'description': '',
        'image_url': null,
      });
      expect(cls.imageUrl, isNull);
    });

    test('parses price and priceType', () {
      final cls = AppClass.fromJson({
        'id': '5',
        'name': 'Swimming',
        'organization_name': 'Pool',
        'organization_id': '6',
        'average_rating': 4.5,
        'review_count': 8,
        'description': '',
        'price': 250.0,
        'price_type': 'monthly',
      });
      expect(cls.price, 250.0);
      expect(cls.priceType, 'monthly');
    });

    test('parses categories list and sets primaryCategory', () {
      final cls = AppClass.fromJson({
        'id': '10',
        'name': 'Dance',
        'organization_name': 'Studio',
        'organization_id': '1',
        'average_rating': 4.0,
        'review_count': 0,
        'description': '',
        'categories': [
          {'id': '3', 'name': 'Sport', 'name_en': 'Sport'},
        ],
      });
      expect(cls.categoryIds, ['3']);
      expect(cls.primaryCategory, isNotNull);
      expect(cls.primaryCategory!.stableNameEn, 'Sport');
    });
  });

  // ── Organization ─────────────────────────────────────────────────────────────

  group('Organization.fromJson', () {
    test('parses core fields', () {
      final org = Organization.fromJson({
        'id': '10',
        'name': 'Happy Kids Studio',
        'average_rating': 4.5,
        'review_count': 12,
      });
      expect(org.id, '10');
      expect(org.name, 'Happy Kids Studio');
      expect(org.averageRating, 4.5);
      expect(org.reviewCount, 12);
    });

    test('parses phone and website', () {
      final org = Organization.fromJson({
        'id': '1',
        'name': 'Studio',
        'average_rating': 0,
        'review_count': 0,
        'phone': '+972-50-1234567',
        'website': 'https://studio.example.com',
      });
      expect(org.phone, '+972-50-1234567');
      expect(org.website, 'https://studio.example.com');
    });

    test('parses bannerUrl, instagramUrl, facebookUrl', () {
      final org = Organization.fromJson({
        'id': '2',
        'name': 'Dance Academy',
        'average_rating': 4.8,
        'review_count': 20,
        'banner_url': 'https://cdn.example.com/banners/dance.jpg',
        'instagram_url': 'https://instagram.com/danceacademy',
        'facebook_url': 'https://facebook.com/danceacademy',
      });
      expect(org.bannerUrl, 'https://cdn.example.com/banners/dance.jpg');
      expect(org.instagramUrl, 'https://instagram.com/danceacademy');
      expect(org.facebookUrl, 'https://facebook.com/danceacademy');
    });

    test('parses isVerified flag correctly', () {
      final verified = Organization.fromJson({
        'id': '3',
        'name': 'Org',
        'average_rating': 0,
        'review_count': 0,
        'is_verified': true,
      });
      final unverified = Organization.fromJson({
        'id': '4',
        'name': 'Org2',
        'average_rating': 0,
        'review_count': 0,
        'is_verified': false,
      });
      final missing = Organization.fromJson({
        'id': '5',
        'name': 'Org3',
        'average_rating': 0,
        'review_count': 0,
      });
      expect(verified.isVerified, isTrue);
      expect(unverified.isVerified, isFalse);
      expect(missing.isVerified, isFalse);
    });

    test('parses trial lesson fields', () {
      final org = Organization.fromJson({
        'id': '6',
        'name': 'Org',
        'average_rating': 0,
        'review_count': 0,
        'trial_lesson_available': true,
        'trial_lesson_price': 50.0,
        'trial_lesson_comment': 'First lesson free for new students',
      });
      expect(org.trialLessonAvailable, isTrue);
      expect(org.trialLessonPrice, 50.0);
      expect(org.trialLessonComment, 'First lesson free for new students');
    });

    test('defaults: isVerified=false, trialLessonAvailable=false', () {
      final org = Organization.fromJson({
        'id': '7',
        'name': 'Org',
        'average_rating': 0,
        'review_count': 0,
      });
      expect(org.isVerified, isFalse);
      expect(org.trialLessonAvailable, isFalse);
      expect(org.trialLessonPrice, isNull);
      expect(org.phone, isNull);
      expect(org.bannerUrl, isNull);
    });
  });

  // ── AppEvent ──────────────────────────────────────────────────────────────────

  group('AppEvent.fromJson', () {
    test('parses core fields', () {
      final event = AppEvent.fromJson({
        'id': '99',
        'title': 'Summer Camp',
        'description': 'Fun outdoor activities',
        'badge': 'ACTIVE',
      });
      expect(event.id, '99');
      expect(event.title, 'Summer Camp');
      expect(event.subtitle, 'Fun outdoor activities');
    });

    test('parses image_url', () {
      final event = AppEvent.fromJson({
        'id': '1',
        'title': 'Camp',
        'image_url': 'https://cdn.example.com/camp.jpg',
      });
      expect(event.imageUrl, 'https://cdn.example.com/camp.jpg');
      expect(event.bannerUrl, isNull);
    });

    test('parses banner_url', () {
      final event = AppEvent.fromJson({
        'id': '2',
        'title': 'Festival',
        'banner_url': 'https://cdn.example.com/festival-banner.jpg',
      });
      expect(event.bannerUrl, 'https://cdn.example.com/festival-banner.jpg');
    });

    test('parses both image_url and banner_url independently', () {
      final event = AppEvent.fromJson({
        'id': '3',
        'title': 'Big Event',
        'image_url': 'https://cdn.example.com/thumb.jpg',
        'banner_url': 'https://cdn.example.com/wide-banner.jpg',
      });
      expect(event.imageUrl, 'https://cdn.example.com/thumb.jpg');
      expect(event.bannerUrl, 'https://cdn.example.com/wide-banner.jpg');
    });

    test('bannerUrl is null when field absent', () {
      final event = AppEvent.fromJson({'id': '4', 'title': 'Event'});
      expect(event.bannerUrl, isNull);
    });

    test('isPast defaults to false when absent', () {
      final event = AppEvent.fromJson({'id': '5', 'title': 'Event'});
      expect(event.isPast, isFalse);
    });

    test('parses is_past flag', () {
      final past = AppEvent.fromJson({'id': '6', 'title': 'Old', 'is_past': true});
      expect(past.isPast, isTrue);
    });
  });

  // ── SavedActivity ─────────────────────────────────────────────────────────

  group('SavedActivity', () {
    final base = SavedActivity(
      classId: 'cls-1',
      name: 'Yoga',
      studio: 'Studio A',
      category: 'Fitness',
      rating: 4.5,
      reviewCount: 10,
      colorStart: const Color(0xFF7C3AED),
      colorEnd: const Color(0xFF3B82F6),
      icon: Icons.self_improvement,
    );

    test('stores and exposes imageUrl when provided', () {
      final act = SavedActivity(
        classId: 'cls-2',
        name: 'Dance',
        studio: 'Studio B',
        category: 'Dance',
        rating: 4.8,
        reviewCount: 20,
        colorStart: const Color(0xFF059669),
        colorEnd: const Color(0xFF0EA5E9),
        icon: Icons.music_note,
        imageUrl: 'https://cdn.example.com/dance.jpg',
      );
      expect(act.imageUrl, 'https://cdn.example.com/dance.jpg');
    });

    test('imageUrl defaults to null when not provided', () {
      expect(base.imageUrl, isNull);
    });

    test('preserves all fields alongside imageUrl', () {
      final act = SavedActivity(
        classId: 'cls-3',
        name: 'Art',
        studio: 'Studio C',
        category: 'Arts',
        rating: 4.0,
        reviewCount: 5,
        colorStart: const Color(0xFFFF6B35),
        colorEnd: const Color(0xFFEC4899),
        icon: Icons.brush,
        imageUrl: 'https://cdn.example.com/art.jpg',
      );
      expect(act.classId, 'cls-3');
      expect(act.name, 'Art');
      expect(act.imageUrl, 'https://cdn.example.com/art.jpg');
    });
  });
}

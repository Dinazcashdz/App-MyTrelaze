import 'package:flutter/material.dart';

class AppL10n {
  final bool _en;
  const AppL10n._(this._en);

  factory AppL10n.of(BuildContext context) =>
      AppL10n._(Localizations.localeOf(context).languageCode == 'en');

  // ── Navigation ─────────────────────────────────────────────────────────────
  String get navHome     => _en ? 'Home'     : 'Accueil';
  String get navBus      => 'Bus';
  String get navNews     => _en ? 'News'     : 'Actus';
  String get navInfo     => _en ? 'Info'     : 'Infos';
  String get navSettings => _en ? 'Settings' : 'Réglages';

  // ── Home ───────────────────────────────────────────────────────────────────
  String get homeWelcome     => _en ? 'Welcome to Trélazé 👋' : 'Bienvenue à Trélazé 👋';
  String get homeQuickAccess => _en ? 'Quick access'          : 'Accès rapide';
  String get homeServices    => _en ? 'Services'              : 'Services';
  String get homeEmergency   => _en ? 'Emergency'             : 'Urgences';
  String get homeCityMap     => _en ? 'City map'              : 'Plan de la ville';

  // ── Quick cards ────────────────────────────────────────────────────────────
  String get cardBus         => 'Bus';
  String get cardNews        => _en ? 'News'       : 'Actus';
  String get cardPlaces      => _en ? 'Places'     : 'Lieux';
  String get cardContacts    => _en ? 'Contacts'   : 'Contacts';
  String get cardLost        => _en ? 'Lost'       : 'Perdus';
  String get cardReport      => _en ? 'Report'     : 'Signaler';
  String get cardEvents      => _en ? 'Events'     : 'Agenda';
  String get cardRestaurants => _en ? 'Eat out'    : 'Restaurants';
  String get cardWaste       => _en ? 'Waste'      : 'Déchets';
  String get cardServices    => _en ? 'Services'   : 'Services';

  // ── Weather ────────────────────────────────────────────────────────────────
  String get weatherUnavailable => _en ? 'Weather unavailable' : 'Météo indisponible';
  String get weatherCached      => _en ? 'cached data'         : 'données en cache';
  String get weatherLocation    => '📍 Trélazé';

  // ── Emergency ──────────────────────────────────────────────────────────────
  String get labelSamu      => 'SAMU';
  String get labelFiremen   => _en ? 'Fire dept' : 'Pompiers';
  String get labelPolice    => 'Police';
  String get labelEmergency => _en ? 'Emergency' : 'Urgences';

  // ── Page titles ────────────────────────────────────────────────────────────
  String get pageTransport    => _en ? 'Transport'           : 'Transport';
  String get pageNews         => _en ? 'News'                : 'Actualités';
  String get pageMap          => _en ? 'City Map'            : 'Plan de Trélazé';
  String get pageWaste        => _en ? 'Waste & Recycling'   : 'Tri & Déchets';
  String get pageRestaurants  => _en ? 'Restaurants'         : 'Se restaurer';
  String get pageAgenda       => _en ? 'Events'              : 'Agenda';
  String get pageObjects      => _en ? 'Lost & Found'        : 'Objets perdus';
  String get pageReport       => _en ? 'Citizen Reports'     : 'Signalements citoyens';
  String get pageSettings     => _en ? 'Settings'            : 'Réglages';
  String get pageInfo         => _en ? 'Useful Info'         : 'Infos utiles';
  String get pageWeather      => _en ? 'Weather'             : 'Météo';
  String get pageMeteo        => _en ? 'Weather — Trélazé'   : 'Météo — Trélazé';

  // ── Settings ───────────────────────────────────────────────────────────────
  String get settingsAppearance       => _en ? 'Appearance'              : 'Apparence';
  String get settingsDarkMode         => _en ? 'Dark mode'               : 'Mode sombre';
  String get settingsDarkOn           => _en ? 'Enabled'                 : 'Activé';
  String get settingsDarkOff          => _en ? 'Disabled'                : 'Désactivé';
  String get settingsLanguage         => _en ? 'Language'                : 'Langue';
  String get settingsAppLanguage      => _en ? 'App language'            : "Langue de l'application";
  String get settingsChooseLang       => _en ? 'Choose your language'    : 'Choisissez votre langue';
  String get settingsNotifications    => _en ? 'Notifications'           : 'Notifications';
  String get settingsPushNotifs       => _en ? 'Push notifications'      : 'Notifications push';
  String get settingsNotifsOn         => _en ? 'Enabled'                 : 'Activées';
  String get settingsNotifsOff        => _en ? 'Disabled'                : 'Désactivées';
  String get settingsApp              => _en ? 'Application'             : 'Application';
  String get settingsRate             => _en ? 'Rate the app'            : "Noter l'application";
  String get settingsRateSubtitle     => _en ? 'Leave a review on the Play Store' : 'Donnez votre avis sur le Play Store';
  String get settingsVersion          => _en ? 'Version'                 : 'Version';
  String get settingsUpToDate         => _en ? 'Up to date'              : 'À jour';
  String get settingsCity             => _en ? 'City of Trélazé'         : 'Ville de Trélazé';

  // ── Info page ──────────────────────────────────────────────────────────────
  String get infoTitle           => _en ? 'Useful Info'           : 'Infos utiles';
  String get infoTownHall        => _en ? 'Town Hall'             : 'Mairie';
  String get infoContact         => _en ? 'Contact'               : 'Contact';
  String get infoOpening         => _en ? 'Opening hours'         : 'Horaires d\'ouverture';
  String get infoTransport       => _en ? 'Transport'             : 'Transport';
  String get infoEmergencyNum    => _en ? 'Emergency numbers'     : 'Numéros d\'urgence';
}

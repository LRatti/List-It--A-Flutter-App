// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'List It';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get notificationsLabel => 'Notifiche';

  @override
  String get darkModeLabel => 'Modalita scura';

  @override
  String get fontSizeLabel => 'Dimensione testo';

  @override
  String get fontSizeSmallLabel => 'Piccolo';

  @override
  String get fontSizeLargeLabel => 'Grande';

  @override
  String get textPreviewTitle => 'Anteprima testo';

  @override
  String get textPreviewDisplayLarge => 'Display grande';

  @override
  String get textPreviewHeadlineMedium => 'Titolo medio';

  @override
  String get textPreviewTitleMedium =>
      'Titolo medio - Questo e come apparira il testo con la dimensione selezionata.';

  @override
  String get textPreviewBodyMedium =>
      'Corpo medio - Testo standard per leggere contenuti e descrizioni.';

  @override
  String get textPreviewBodySmall =>
      'Corpo piccolo - Testo piu piccolo per informazioni meno importanti.';

  @override
  String get textPreviewBodyExample => 'Questo e come apparira il testo';

  @override
  String get textPreviewBodySmallExample => 'Esempio di testo piu piccolo';

  @override
  String get colorPaletteTitle => 'Tavolozza colori';

  @override
  String get colorSwatchPrimary => 'Primario';

  @override
  String get colorSwatchSecondary => 'Secondario';

  @override
  String get colorSwatchTertiary => 'Terziario';

  @override
  String get colorSwatchError => 'Errore';

  @override
  String get colorSwatchSurface => 'Superficie';

  @override
  String get aboutSectionTitle => 'Informazioni';

  @override
  String get appVersionLabel => 'Versione app';

  @override
  String get privacyPolicyLabel => 'Informativa sulla privacy';

  @override
  String get termsOfServiceLabel => 'Termini di servizio';

  @override
  String get languageLabel => 'Lingua';

  @override
  String get languageEnglishLabel => 'Inglese';

  @override
  String get languageItalianLabel => 'Italiano';

  @override
  String get listsTabLabel => 'Liste';

  @override
  String get historyTabLabel => 'Cronologia';

  @override
  String get supermarketsTabLabel => 'Supermercati';

  @override
  String get statisticsTabLabel => 'Statistiche';

  @override
  String get signInLabel => 'Accedi';

  @override
  String get signUpLabel => 'Registrati';

  @override
  String get authTitle => 'Autenticazione';

  @override
  String get welcomeMessage => 'Benvenuto.';

  @override
  String get alreadyHaveAccount => 'Hai gia un account?';

  @override
  String get signInInstead => 'Accedi invece';

  @override
  String get needAccount => 'Non hai un account?';

  @override
  String get signUpInstead => 'Registrati invece';

  @override
  String get signInWithGoogle => 'Accedi con Google';

  @override
  String get signInIntro => 'Accedi al tuo account.';

  @override
  String get signUpIntro => 'Crea un nuovo account.';

  @override
  String get emailLabel => 'Email';

  @override
  String get confirmEmailLabel => 'Conferma Email';

  @override
  String get enterEmailError => 'Inserisci la tua email';

  @override
  String get confirmEmailError => 'Conferma la tua email';

  @override
  String get emailsDoNotMatch => 'Le email non coincidono';

  @override
  String get enterPasswordError => 'Inserisci la tua password';

  @override
  String get enterPasswordCreateError => 'Inserisci una password';

  @override
  String get incorrectLoginCredentials => 'Credenziali di accesso errate.';

  @override
  String get forgotPasswordLabel => 'Password dimenticata?';

  @override
  String get usernamePrompt => 'Come vuoi essere chiamato?';

  @override
  String get enterUsernameError => 'Inserisci un nome utente';

  @override
  String get signUpFailed => 'Impossibile registrarsi con questi dati.';

  @override
  String get recoverPasswordTitle => 'Recupera Password';

  @override
  String get resetPasswordInstructions =>
      'Inserisci la tua email per ricevere il link di reset.';

  @override
  String resetCooldownMessage(Object seconds) {
    return 'Puoi richiedere un altro reset tra $seconds secondi';
  }

  @override
  String pleaseWaitSeconds(Object seconds) {
    return 'Attendi ($seconds s)';
  }

  @override
  String get sendRecoveryEmailLabel => 'Invia email di recupero';

  @override
  String get resetLinkSentIfAccountExists =>
      'Se esiste un account, e stato inviato un link di reset.';

  @override
  String get recoveryEmailSentCheckInbox =>
      'Email di recupero inviata. Controlla la posta.';

  @override
  String get unableToOpenMap => 'Impossibile aprire la mappa';

    @override
    String get nearestSupermarketLocating => 'Ricerca supermercati vicini...';

    @override
    String get nearestSupermarketUnavailable =>
      'Impossibile rilevare supermercati vicini';

    @override
    String get nearestSupermarketEnableLocationServices =>
      'Attiva i servizi di localizzazione per trovare supermercati';

    @override
    String get nearestSupermarketPermissionRequired =>
      'Autorizzazione alla posizione necessaria per trovare supermercati';

    @override
    String get nearestSupermarketPermissionDeniedForever =>
      'Abilita il permesso di posizione nelle impostazioni per continuare';

    @override
    String get nearestSupermarketUnableToGetLocation =>
      'Impossibile ottenere la tua posizione al momento';

    @override
    String get nearestSupermarketLowGpsAccuracy =>
      'Bassa precisione GPS. Prova all\'aperto.';

    @override
    String nearestSupermarketNoneWithinDistance(Object distanceKm) {
    return 'Nessun supermercato trovato entro $distanceKm km';
    }

    @override
    String get nearestSupermarketNetworkTimeout =>
      'Timeout di rete durante la ricerca dei supermercati';

    @override
    String get nearestSupermarketNetworkIssue =>
      'Problema di rete durante la ricerca dei supermercati';

    @override
    String nearestSupermarketResult(Object name, Object distance) {
    return '$name - $distance';
    }

  @override
  String get menuLabel => 'Menu';

  @override
  String get profileLabel => 'Profilo';

  @override
  String get trashLabel => 'Cestino';

  @override
  String get closeLabel => 'Chiudi';

  @override
  String get trashEmptyMessage => 'Il cestino e vuoto';

  @override
  String get deletingNowMessage => 'Eliminazione in corso...';

  @override
  String get deleteInOneDayMessage => 'Elimina tra 1 giorno';

  @override
  String deleteInDaysMessage(Object days) {
    return 'Elimina tra $days giorni';
  }

  @override
  String get restoreLabel => 'Ripristina';

  @override
  String get deletePermanentlyTitle => 'Elimina definitivamente';

  @override
  String deleteListPermanentlyConfirm(Object listName) {
    return 'Sei sicuro di voler eliminare definitivamente \'$listName\'?';
  }

  @override
  String get cancelLabel => 'Annulla';

  @override
  String get deleteLabel => 'Elimina';

  @override
  String get deleteListTitle => 'Elimina lista';

  @override
  String deleteListConfirm(Object listName) {
    return 'Sei sicuro di voler eliminare \'$listName\'?';
  }

  @override
  String get deleteSelectedListsTitle => 'Elimina liste selezionate';

  @override
  String deleteSelectedListsConfirm(Object count) {
    return 'Sei sicuro di voler eliminare $count lista(e) selezionata(e)?';
  }

  @override
  String deleteSelectedSupermarketsConfirm(Object count) {
    return 'Vuoi eliminare $count supermercato(i)?';
  }

  @override
  String get createFirstSupermarketMessage =>
      'Crea il tuo primo supermercato per iniziare';

  @override
  String get cannotRemoveFavoriteSupermarket =>
      'Impossibile rimuovere il preferito: devi avere almeno un supermercato preferito. Selezionane un altro.';

  @override
  String errorUpdatingFavorite(Object error) {
    return 'Errore durante l\'aggiornamento del preferito: $error';
  }

  @override
  String get searchSupermarketsHint => 'Cerca supermercati...';

  @override
  String get supermarketsTitle => 'Supermercati';

  @override
  String noSupermarketsFoundMatching(Object query) {
    return 'Nessun supermercato trovato per \"$query\"';
  }

  @override
  String get searchListsHint => 'Cerca liste...';

  @override
  String noListsFoundMatching(Object query) {
    return 'Nessuna lista trovata per \"$query\"';
  }

  @override
  String get noItemsLabel => 'Nessun elemento';

  @override
  String get dateNotAvailable => 'N/D';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPasswordTooltip => 'Mostra password';

  @override
  String get hidePasswordTooltip => 'Nascondi password';

  @override
  String get restoreAllTitle => 'Ripristina tutto';

  @override
  String get restoreAllConfirm =>
      'Sei sicuro di voler ripristinare tutte le liste dal cestino?';

  @override
  String get allListsRestoredMessage => 'Tutte le liste ripristinate';

  @override
  String get emptyTrashTitle => 'Svuota cestino';

  @override
  String get emptyTrashConfirm =>
      'Questo eliminera definitivamente tutte le liste nel cestino. Continuare?';

  @override
  String get deleteAllLabel => 'Elimina tutto';

  @override
  String get trashEmptiedMessage => 'Cestino svuotato';

  @override
  String get noSupermarketsYet => 'Nessun supermercato';

  @override
  String get noRegisteredListsYet => 'Nessuna lista registrata.';

  @override
  String get noDataForSelectedPeriod =>
      'Nessun dato per il periodo selezionato.';

  @override
  String get byCategoryTitle => 'Per categoria';

  @override
  String get totalLabel => 'Totale';

  @override
  String get categoryBreakdownTitle => 'Dettaglio categorie';

  @override
  String get selectCompletedListToReview =>
      'Seleziona una lista completata da rivedere';

  @override
  String errorLoadingShoppingList(Object error) {
    return 'Errore nel caricamento della lista: $error';
  }

  @override
  String get noListsYet => 'Nessuna lista.';

  @override
  String get addNewListTitle => 'Aggiungi nuova lista';

  @override
  String get enterListNamePrompt => 'Inserisci il nome della lista:';

  @override
  String get listNameHint => 'Nome lista';

  @override
  String get selectListToViewDetails =>
      'Seleziona una lista per vedere i dettagli';

  @override
  String get selectSupermarketToViewDetails =>
      'Seleziona un supermercato per vedere i dettagli';

  @override
  String get enterRecipeNameError => 'Inserisci un nome ricetta';

  @override
  String get editIngredientTitle => 'Modifica ingrediente';

  @override
  String get addRecipeTitle => 'Aggiungi Ricetta';

  @override
  String get enterRecipeNameHint => 'Inserisci nome ricetta...';

  @override
  String get searchRecipeLabel => 'Cerca Ricetta';

  @override
  String get enterRecipeAndSearch =>
      'Inserisci un nome ricetta e premi \"Cerca Ricetta\"';

  @override
  String get recipeLabel => 'Ricetta';

  @override
  String get recipeSearchCompletedWithIssues =>
      'Ricerca ricetta completata con problemi';

  @override
  String recipeFound(Object recipeName) {
    return 'Ricetta "$recipeName" trovata!';
  }

  @override
  String ingredientsCount(Object selected, Object total) {
    return 'Ingredienti ($selected/$total)';
  }

  @override
  String get addToListLabel => 'Aggiungi alla Lista';

  @override
  String errorRegisteringList(Object error) {
    return 'Errore durante la registrazione della lista: $error';
  }

  @override
  String get continueEditingTitle => 'Continuare a modificare?';

  @override
  String get continueEditingMessage =>
      'Puoi aggiungere altri prodotti o spuntare altri elementi.';

  @override
  String get yesContinueLabel => 'Si, continua';

  @override
  String errorOpeningForEditing(Object error) {
    return 'Errore aprendo per modificare: $error';
  }

  @override
  String get scanReceiptTooltip => 'Scansiona scontrino';

  @override
  String get continueEditingTooltip => 'Continua modifica';

  @override
  String get supermarketLabel => 'Supermercato';

  @override
  String get notSelectedLabel => 'Non selezionato';

  @override
  String get noCheckedItems => 'Nessun elemento spuntato';

  @override
  String get checkItemsToRegister =>
      'Spunta gli elementi nella lista\nper registrarli qui';

  @override
  String get quantityLabelTitle => 'Quantita';

  @override
  String get priceLabel => 'Prezzo';

  @override
  String get errorSavingTitle => 'Errore nel salvataggio';

  @override
  String get failedToSaveChanges => 'Impossibile salvare le modifiche:';

  @override
  String get whatWouldYouLikeToDo => 'Cosa vuoi fare?';

  @override
  String get stayAndRetry => 'Resta e riprova';

  @override
  String get discardChanges => 'Scarta modifiche';

  @override
  String errorAddingProduct(Object error) {
    return 'Errore aggiungendo il prodotto: $error';
  }

  @override
  String errorDeletingList(Object error) {
    return 'Errore eliminando la lista: $error';
  }

  @override
  String get selectSupermarketTitle => 'Seleziona Supermercato';

  @override
  String get noSupermarketsCreateFirst =>
      'Nessun supermercato. Creane uno per iniziare.';

  @override
  String supermarketsAvailable(Object count) {
    return '$count supermercato(i) disponibili';
  }

  @override
  String get createNewLabel => 'Crea Nuovo';

  @override
  String get clearLabel => 'Cancella';

  @override
  String get editSupermarketTooltip => 'Modifica supermercato';

  @override
  String get createSupermarketToOrganize =>
      'Crea un supermercato per organizzare\nle tue categorie di acquisto';

  @override
  String get registerListTooltip => 'Registra lista';

  @override
  String get errorLoadingSupermarkets =>
      'Errore nel caricamento dei supermercati';

  @override
  String get createSupermarketPrompt => 'Crea un supermercato';

  @override
  String get selectSupermarketPrompt => 'Seleziona supermercato';

  @override
  String get addProductHint => 'Aggiungi prodotto...';

  @override
  String get addProductTooltip => 'Aggiungi prodotto';

  @override
  String get deleteListTooltip => 'Elimina lista';

  @override
  String get defaultCategoryUncategorized => 'Senza categoria';

  @override
  String get defaultCategoryMeat => '🥩 Carne';

  @override
  String get defaultCategoryWineShop => '🍷 Enoteca';

  @override
  String get defaultCategoryFlowersAndPlants => '🌸 Fiori e piante';

  @override
  String get defaultCategoryFruitAndVegetables => '🍎 Frutta e verdura';

  @override
  String get defaultCategoryLooseFruitAndVegetables =>
      '🥕 Frutta e verdura sfuse';

  @override
  String get defaultCategoryDeli => '🧀 Gastronomia';

  @override
  String get defaultCategoryDeliServiceCounter => '🥪 Gastronomia con banco';

  @override
  String get defaultCategoryDairyAndCuredMeats => '🥛 Latticini e salumi';

  @override
  String get defaultCategoryButcherServiceCounter => '🔪 Macelleria con banco';

  @override
  String get defaultCategoryNonFood => '🧴 Non-Food';

  @override
  String get defaultCategoryBreadAndDesserts => '🍞 Pane e dolci';

  @override
  String get defaultCategoryBreadAndDessertsServiceCounter =>
      '🥖 Pane e dolci con banco';

  @override
  String get defaultCategoryBakery => '🥐 Panetteria';

  @override
  String get defaultCategoryPastry => '🧁 Pasticceria';

  @override
  String get defaultCategoryFish => '🐟 Pesce';

  @override
  String get defaultCategoryFishmongerServiceCounter =>
      '🦞 Pescheria con banco';

  @override
  String get defaultCategorySushi => '🍣 Sushi';

  @override
  String categoriesCountLabel(Object count) {
    return '$count categorie';
  }

  @override
  String get editLabel => 'Modifica';

  @override
  String get supermarketNameEmpty =>
      'Il nome del supermercato non puo essere vuoto';

  @override
  String errorSavingSupermarket(Object error) {
    return 'Errore durante il salvataggio del supermercato: $error';
  }

  @override
  String deleteSupermarketConfirm(Object name) {
    return 'Vuoi eliminare \'$name\'?';
  }

  @override
  String errorDeletingSupermarket(Object error) {
    return 'Errore durante l\'eliminazione del supermercato: $error';
  }

  @override
  String get createSupermarketTitle => 'Crea supermercato';

  @override
  String get customizeSupermarketTitle => 'Personalizza supermercato';

  @override
  String get saveSupermarketTooltip => 'Salva supermercato';

  @override
  String get enterSupermarketNameLabel => 'Inserisci nome supermercato';

  @override
  String get noCategoriesYet => 'Nessuna categoria';

  @override
  String get addCategoriesToSupermarket =>
      'Aggiungi categorie a questo supermercato';

  @override
  String get cancelSupermarketCreationTooltip =>
      'Annulla creazione supermercato';

  @override
  String get deleteSupermarketTooltip => 'Elimina supermercato';

  @override
  String get addCategoriesLabel => 'Aggiungi categorie';

  @override
  String get removeFromFavoritesTooltip => 'Rimuovi dai preferiti';

  @override
  String get setAsFavoriteTooltip => 'Imposta come preferito';

  @override
  String get removeCategoryTooltip => 'Rimuovi categoria';

  @override
  String get editCategoryTooltip => 'Modifica categoria';

  @override
  String get selectAtLeastOneCategory => 'Seleziona almeno una categoria';

  @override
  String get selectAtLeastOneCategoryToDelete =>
      'Seleziona almeno una categoria da eliminare';

  @override
  String deleteCategoryConfirmSingle(Object name) {
    return 'Vuoi eliminare \'$name\'?';
  }

  @override
  String deleteCategoriesConfirm(Object count) {
    return 'Vuoi eliminare $count categorie?';
  }

  @override
  String failedToDeleteCategories(Object error) {
    return 'Impossibile eliminare le categorie: $error';
  }

  @override
  String get addCategoriesTitle => 'Aggiungi Categorie';

  @override
  String get createNewCategoryTooltip => 'Crea nuova categoria';

  @override
  String get allCategoriesAdded => 'Tutte le categorie aggiunte';

  @override
  String get createNewCategoryToContinue =>
      'Crea una nuova categoria per continuare';

  @override
  String get addLabel => 'Aggiungi';

  @override
  String get categoryNameEmpty => 'Il nome categoria non puo essere vuoto';

  @override
  String get uncategorizedNameReserved =>
      'Il nome \"uncategorized\" e riservato';

  @override
  String errorSavingCategory(Object error) {
    return 'Errore nel salvataggio della categoria: $error';
  }

  @override
  String get editCategoryTitle => 'Modifica Categoria';

  @override
  String get createCategoryTitle => 'Crea Categoria';

  @override
  String get categoryNameLabel => 'Nome Categoria';

  @override
  String get saveLabel => 'Salva';

  @override
  String selectedItemsCount(Object count) {
    return '$count selezionate';
  }

  @override
  String quantityLabel(Object quantity) {
    return 'Quantita: $quantity';
  }

  @override
  String get statsLoadError => 'Errore: ricarica l\'app.';

  @override
  String get periodAll => 'Tutto';

  @override
  String get periodWeek => 'Settimana';

  @override
  String get periodMonth => 'Mese';

  @override
  String get periodYear => 'Anno';

  @override
  String get periodCustom => 'Personalizzato';

  @override
  String get monthJanuary => 'Gennaio';

  @override
  String get monthFebruary => 'Febbraio';

  @override
  String get monthMarch => 'Marzo';

  @override
  String get monthApril => 'Aprile';

  @override
  String get monthMay => 'Maggio';

  @override
  String get monthJune => 'Giugno';

  @override
  String get monthJuly => 'Luglio';

  @override
  String get monthAugust => 'Agosto';

  @override
  String get monthSeptember => 'Settembre';

  @override
  String get monthOctober => 'Ottobre';

  @override
  String get monthNovember => 'Novembre';

  @override
  String get monthDecember => 'Dicembre';

  @override
  String get yearHint => 'Anno';

  @override
  String get selectYearTooltip => 'Seleziona anno';

  @override
  String get previousWeekTooltip => 'Settimana precedente';

  @override
  String get nextWeekTooltip => 'Settimana successiva';

  @override
  String get selectRangeLabel => 'Seleziona intervallo';

  @override
  String get selectDayInWeekHelpText => 'Seleziona un giorno della settimana';

  @override
  String get noUserDataFound => 'Nessun dato utente trovato.';

  @override
  String errorWithDetails(Object error) {
    return 'Errore: $error';
  }

  @override
  String get profileInformationTitle => 'Informazioni profilo';

  @override
  String get usernameLabel => 'Nome utente';

  @override
  String get currentEmailLabel => 'Email corrente';

  @override
  String get saveProfileChanges => 'Salva modifiche profilo';

  @override
  String get securitySettingsTitle => 'Impostazioni sicurezza';

  @override
  String get googleAccountManagedCredentials =>
      'Email e password sono gestite dal tuo account Google. Modifiche disabilitate.';

  @override
  String get updateEmailTitle => 'Aggiorna email';

  @override
  String get newEmailLabel => 'Nuova email';

  @override
  String get confirmNewEmailLabel => 'Conferma nuova email';

  @override
  String get updatePasswordTitle => 'Aggiorna password';

  @override
  String get newPasswordLabel => 'Nuova password';

  @override
  String get confirmNewPasswordLabel => 'Conferma nuova password';

  @override
  String get verificationTitle => 'Verifica';

  @override
  String get enterCurrentPasswordToConfirm =>
      'Inserisci la password attuale per confermare le modifiche';

  @override
  String forgotPasswordWait(Object seconds) {
    return 'Password dimenticata? (Attendi ${seconds}s)';
  }

  @override
  String get forgotPassword => 'Password dimenticata?';

  @override
  String cooldownSeconds(Object seconds) {
    return 'Attesa: ${seconds}s';
  }

  @override
  String get updateSecuritySettings => 'Aggiorna impostazioni sicurezza';

  @override
  String get changesSavedSuccessfully => 'Modifiche salvate con successo!';

  @override
  String errorSavingChanges(Object error) {
    return 'Errore durante il salvataggio: $error';
  }

  @override
  String get googleAccountManagedCredentialsShort =>
      'Email e password gestite da Google. Modifiche disabilitate.';

  @override
  String get enterNewEmailOrPassword =>
      'Inserisci nuova email e/o nuova password.';

  @override
  String get enterCurrentPasswordToProceed =>
      'Inserisci la password attuale per continuare.';

  @override
  String get fillBothEmailFields => 'Compila entrambi i campi email.';

  @override
  String get emailAddressesDoNotMatch => 'Gli indirizzi email non coincidono.';

  @override
  String get fillAllPasswordFields => 'Compila tutti i campi password.';

  @override
  String get newPasswordsDoNotMatch => 'Le nuove password non coincidono.';

  @override
  String passwordMinLength(Object minLength) {
    return 'La password deve avere almeno $minLength caratteri.';
  }

  @override
  String get updateEmailAndPasswordSeparately =>
      'Aggiorna email e password separatamente.';

  @override
  String get verificationEmailSent =>
      'Email di verifica inviata al nuovo indirizzo!';

  @override
  String get verificationEmailSentCheckInbox =>
      'Email di verifica inviata. Controlla la posta.';

  @override
  String get verificationEmailResentNewAddress =>
      'Email di verifica reinviata al tuo nuovo indirizzo.';

  @override
  String get verificationNewEmailUnavailable =>
      'Impossibile reinviare: nuova email non disponibile.';

  @override
  String get emailVerifiedSignInAgain =>
      'Email verificata. Accedi di nuovo per continuare.';

  @override
  String get emailNotVerifiedYet =>
      'Email non ancora verificata. Controlla la posta.';

  @override
  String errorCheckingVerification(Object error) {
    return 'Errore durante la verifica: $error';
  }

  @override
  String pleaseWaitBeforeResending(Object seconds) {
    return 'Attendi ${seconds}s prima di reinviare.';
  }

  @override
  String get noAuthenticatedUserFound => 'Nessun utente autenticato trovato.';

  @override
  String get tooManyRequestsTryLater =>
      'Troppe richieste. Attendi qualche minuto e riprova.';

  @override
  String errorSendingVerificationEmail(Object error) {
    return 'Errore durante l\'invio dell\'email di verifica: $error';
  }

  @override
  String get accountCreationCancelledMessage =>
      'Creazione account annullata. Registrati di nuovo se vuoi creare un account.';

  @override
  String get emailVerificationCancelledMessage =>
      'Verifica email annullata. Puoi aggiornare di nuovo l\'email in qualsiasi momento dalle impostazioni.';

  @override
  String errorAbortingOperation(Object error) {
    return 'Errore durante l\'annullamento dell\'operazione: $error';
  }

  @override
  String get passwordUpdatedSignInAgain =>
      'Password aggiornata. Accedi di nuovo.';

  @override
  String failedToUpdateCredentials(Object error) {
    return 'Aggiornamento credenziali non riuscito: $error';
  }

  @override
  String get noEmailAssociated => 'Nessuna email associata a questo account.';

  @override
  String waitBeforeRequestingReset(Object seconds) {
    return 'Attendi $seconds secondi prima di richiedere un altro reset.';
  }

  @override
  String get recoveryEmailSentSignedOut =>
      'Email di recupero inviata. Verrai disconnesso.';

  @override
  String get couldNotSendResetEmail =>
      'Impossibile inviare l\'email di reset. Riprova piu tardi.';

  @override
  String get goBackLabel => 'Torna indietro';

  @override
  String get receiptCameraNoCameras => 'Nessuna fotocamera disponibile';

  @override
  String receiptCameraInitFailed(Object error) {
    return 'Impossibile inizializzare la fotocamera: $error';
  }

  @override
  String receiptCameraErrorTakingPicture(Object error) {
    return 'Errore durante lo scatto: $error';
  }

  @override
  String get receiptCameraExtractingPrices =>
      'Estrazione di prezzi e quantita...';
}

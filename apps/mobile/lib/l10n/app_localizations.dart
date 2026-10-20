// GENERATED CODE - DO NOT MODIFY BY HAND
//
// This file is produced from the ARB files in lib/l10n by `flutter gen-l10n`
// (or by scripts/gen_l10n.py, which emits the same output where the Flutter
// tool cannot run). Regenerate with:
//
//     flutter gen-l10n
//
// ignore_for_file: type=lint
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// The translations for each supported locale are provided by a
/// generated `_AppLocalizationsXx` class, each of which implements
/// [AppLocalizations].
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale);

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ne'),
  ];

  /// No description provided for @appName.
  String get appName;

  /// No description provided for @login.
  String get login;

  /// No description provided for @register.
  String get register;

  /// No description provided for @email.
  String get email;

  /// No description provided for @password.
  String get password;

  /// No description provided for @fullName.
  String get fullName;

  /// No description provided for @phoneNumber.
  String get phoneNumber;

  /// No description provided for @confirmPassword.
  String get confirmPassword;

  /// No description provided for @createAccount.
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  String get dontHaveAccount;

  /// No description provided for @dashboard.
  String get dashboard;

  /// No description provided for @transactions.
  String get transactions;

  /// No description provided for @khata.
  String get khata;

  /// No description provided for @reports.
  String get reports;

  /// No description provided for @more.
  String get more;

  /// No description provided for @todaysSales.
  String get todaysSales;

  /// No description provided for @todaysPurchases.
  String get todaysPurchases;

  /// No description provided for @todaysExpenses.
  String get todaysExpenses;

  /// No description provided for @todaysProfit.
  String get todaysProfit;

  /// No description provided for @totalReceivable.
  String get totalReceivable;

  /// No description provided for @totalPayable.
  String get totalPayable;

  /// No description provided for @stockValue.
  String get stockValue;

  /// No description provided for @lowStock.
  String get lowStock;

  /// No description provided for @syncNow.
  String get syncNow;

  /// No description provided for @settings.
  String get settings;

  /// No description provided for @logout.
  String get logout;

  /// No description provided for @createBusiness.
  String get createBusiness;

  /// No description provided for @businessSetupTitle.
  String get businessSetupTitle;

  /// No description provided for @businessSetupSubtitle.
  String get businessSetupSubtitle;

  /// No description provided for @businessName.
  String get businessName;

  /// No description provided for @businessType.
  String get businessType;

  /// No description provided for @panNumber.
  String get panNumber;

  /// No description provided for @businessEmail.
  String get businessEmail;

  /// No description provided for @address.
  String get address;

  /// No description provided for @city.
  String get city;

  /// No description provided for @district.
  String get district;

  /// No description provided for @province.
  String get province;

  /// No description provided for @wardNumber.
  String get wardNumber;

  /// No description provided for @myBusinesses.
  String get myBusinesses;

  /// No description provided for @switchBusiness.
  String get switchBusiness;

  /// No description provided for @active.
  String get active;

  /// No description provided for @noBusinesses.
  String get noBusinesses;

  /// No description provided for @createFirstBusiness.
  String get createFirstBusiness;

  /// No description provided for @staff.
  String get staff;

  /// No description provided for @invite.
  String get invite;

  /// No description provided for @inviteMember.
  String get inviteMember;

  /// No description provided for @changeRole.
  String get changeRole;

  /// No description provided for @remove.
  String get remove;

  /// No description provided for @profile.
  String get profile;

  /// No description provided for @editProfile.
  String get editProfile;

  /// No description provided for @saveChanges.
  String get saveChanges;

  /// No description provided for @cancel.
  String get cancel;

  /// No description provided for @language.
  String get language;

  /// No description provided for @retry.
  String get retry;

  /// No description provided for @loading.
  String get loading;

  /// No description provided for @products.
  String get products;

  /// No description provided for @product.
  String get product;

  /// No description provided for @addProduct.
  String get addProduct;

  /// No description provided for @editProduct.
  String get editProduct;

  /// No description provided for @newProduct.
  String get newProduct;

  /// No description provided for @productName.
  String get productName;

  /// No description provided for @sku.
  String get sku;

  /// No description provided for @barcode.
  String get barcode;

  /// No description provided for @categories.
  String get categories;

  /// No description provided for @addCategory.
  String get addCategory;

  /// No description provided for @newCategory.
  String get newCategory;

  /// No description provided for @category.
  String get category;

  /// No description provided for @units.
  String get units;

  /// No description provided for @addUnit.
  String get addUnit;

  /// No description provided for @newUnit.
  String get newUnit;

  /// No description provided for @unit.
  String get unit;

  /// No description provided for @costPrice.
  String get costPrice;

  /// No description provided for @sellingPrice.
  String get sellingPrice;

  /// No description provided for @wholesalePrice.
  String get wholesalePrice;

  /// No description provided for @taxRate.
  String get taxRate;

  /// No description provided for @openingStock.
  String get openingStock;

  /// No description provided for @minQuantity.
  String get minQuantity;

  /// No description provided for @inventory.
  String get inventory;

  /// No description provided for @adjustStock.
  String get adjustStock;

  /// No description provided for @stockHistory.
  String get stockHistory;

  /// No description provided for @quickAdjust.
  String get quickAdjust;

  /// No description provided for @customQuantity.
  String get customQuantity;

  /// No description provided for @notes.
  String get notes;

  /// No description provided for @applyAdjustment.
  String get applyAdjustment;

  /// No description provided for @lowStockOnly.
  String get lowStockOnly;

  /// No description provided for @sortByName.
  String get sortByName;

  /// No description provided for @sortByQuantity.
  String get sortByQuantity;

  /// No description provided for @searchProducts.
  String get searchProducts;

  /// No description provided for @inStock.
  String get inStock;

  /// No description provided for @lowStockAlert.
  String get lowStockAlert;

  /// No description provided for @stockAdded.
  String get stockAdded;

  /// No description provided for @stockRemoved.
  String get stockRemoved;

  /// No description provided for @customers.
  String get customers;

  /// No description provided for @customer.
  String get customer;

  /// No description provided for @addCustomer.
  String get addCustomer;

  /// No description provided for @newCustomer.
  String get newCustomer;

  /// No description provided for @editCustomer.
  String get editCustomer;

  /// No description provided for @searchCustomers.
  String get searchCustomers;

  /// No description provided for @suppliers.
  String get suppliers;

  /// No description provided for @supplier.
  String get supplier;

  /// No description provided for @addSupplier.
  String get addSupplier;

  /// No description provided for @newSupplier.
  String get newSupplier;

  /// No description provided for @editSupplier.
  String get editSupplier;

  /// No description provided for @searchSuppliers.
  String get searchSuppliers;

  /// No description provided for @searchPartyHint.
  String get searchPartyHint;

  /// No description provided for @ledger.
  String get ledger;

  /// No description provided for @openingBalance.
  String get openingBalance;

  /// No description provided for @creditLimit.
  String get creditLimit;

  /// No description provided for @creditLimitOptional.
  String get creditLimitOptional;

  /// No description provided for @closingBalance.
  String get closingBalance;

  /// No description provided for @totalDebit.
  String get totalDebit;

  /// No description provided for @totalCredit.
  String get totalCredit;

  /// No description provided for @toCollect.
  String get toCollect;

  /// No description provided for @toPay.
  String get toPay;

  /// No description provided for @advance.
  String get advance;

  /// No description provided for @settled.
  String get settled;

  /// No description provided for @noCustomers.
  String get noCustomers;

  /// No description provided for @noSuppliers.
  String get noSuppliers;

  /// No description provided for @noTransactions.
  String get noTransactions;

  /// No description provided for @partyDeleted.
  String get partyDeleted;

  /// No description provided for @deletePartyTitle.
  String get deletePartyTitle;

  /// No description provided for @sales.
  String get sales;

  /// No description provided for @sale.
  String get sale;

  /// No description provided for @newSale.
  String get newSale;

  /// No description provided for @purchases.
  String get purchases;

  /// No description provided for @purchase.
  String get purchase;

  /// No description provided for @newPurchase.
  String get newPurchase;

  /// No description provided for @expenses.
  String get expenses;

  /// No description provided for @expense.
  String get expense;

  /// No description provided for @addExpense.
  String get addExpense;

  /// No description provided for @income.
  String get income;

  /// No description provided for @addIncome.
  String get addIncome;

  /// No description provided for @invoiceNumber.
  String get invoiceNumber;

  /// No description provided for @billNumber.
  String get billNumber;

  /// No description provided for @saleType.
  String get saleType;

  /// No description provided for @paymentStatus.
  String get paymentStatus;

  /// No description provided for @paid.
  String get paid;

  /// No description provided for @due.
  String get due;

  /// No description provided for @addItem.
  String get addItem;

  /// No description provided for @searchSales.
  String get searchSales;

  /// No description provided for @searchPurchases.
  String get searchPurchases;

  /// No description provided for @searchExpenses.
  String get searchExpenses;

  /// No description provided for @searchIncome.
  String get searchIncome;

  /// No description provided for @walkIn.
  String get walkIn;

  /// No description provided for @cash.
  String get cash;

  /// No description provided for @credit.
  String get credit;

  /// No description provided for @partial.
  String get partial;

  /// No description provided for @noSales.
  String get noSales;

  /// No description provided for @noPurchases.
  String get noPurchases;

  /// No description provided for @noExpenses.
  String get noExpenses;

  /// No description provided for @noIncome.
  String get noIncome;

  /// No description provided for @payments.
  String get payments;

  /// No description provided for @payment.
  String get payment;

  /// No description provided for @recordPayment.
  String get recordPayment;

  /// No description provided for @paymentMethods.
  String get paymentMethods;

  /// No description provided for @addPaymentMethod.
  String get addPaymentMethod;

  /// No description provided for @receive.
  String get receive;

  /// No description provided for @pay.
  String get pay;

  /// No description provided for @method.
  String get method;

  /// No description provided for @defaultLabel.
  String get defaultLabel;

  /// No description provided for @reference.
  String get reference;

  /// No description provided for @noPayments.
  String get noPayments;

  /// No description provided for @onAccount.
  String get onAccount;

  /// No description provided for @applyToDocument.
  String get applyToDocument;

  /// No description provided for @advances.
  String get advances;

  /// No description provided for @inactive.
  String get inactive;

  /// No description provided for @invoices.
  String get invoices;

  /// No description provided for @invoice.
  String get invoice;

  /// No description provided for @newInvoice.
  String get newInvoice;

  /// No description provided for @quotations.
  String get quotations;

  /// No description provided for @quotation.
  String get quotation;

  /// No description provided for @newQuotation.
  String get newQuotation;

  /// No description provided for @issueDate.
  String get issueDate;

  /// No description provided for @dueDate.
  String get dueDate;

  /// No description provided for @validUntil.
  String get validUntil;

  /// No description provided for @terms.
  String get terms;

  /// No description provided for @share.
  String get share;

  /// No description provided for @downloadPdf.
  String get downloadPdf;

  /// No description provided for @convertToSale.
  String get convertToSale;

  /// No description provided for @status.
  String get status;

  /// No description provided for @draft.
  String get draft;

  /// No description provided for @sent.
  String get sent;

  /// No description provided for @accepted.
  String get accepted;

  /// No description provided for @rejected.
  String get rejected;

  /// No description provided for @expired.
  String get expired;

  /// No description provided for @overdue.
  String get overdue;

  /// No description provided for @noInvoices.
  String get noInvoices;

  /// No description provided for @noQuotations.
  String get noQuotations;

  /// No description provided for @generateFromSale.
  String get generateFromSale;

  /// No description provided for @fromSale.
  String fromSale(String number);

  /// No description provided for @notifications.
  String get notifications;

  /// No description provided for @notificationSettings.
  String get notificationSettings;

  /// No description provided for @noNotifications.
  String get noNotifications;

  /// No description provided for @nothingMatchesFilter.
  String get nothingMatchesFilter;

  /// No description provided for @markAllRead.
  String get markAllRead;

  /// No description provided for @markRead.
  String get markRead;

  /// No description provided for @markedReadCount.
  String markedReadCount(int count);

  /// No description provided for @nothingToMark.
  String get nothingToMark;

  /// No description provided for @filterAllCategories.
  String get filterAllCategories;

  /// No description provided for @pushNotifications.
  String get pushNotifications;

  /// No description provided for @enablePush.
  String get enablePush;

  /// No description provided for @enablePushSubtitle.
  String get enablePushSubtitle;

  /// No description provided for @notificationsInAppNote.
  String get notificationsInAppNote;

  /// No description provided for @registeredDevices.
  String get registeredDevices;

  /// No description provided for @noDevices.
  String get noDevices;

  /// No description provided for @deviceActive.
  String get deviceActive;

  /// No description provided for @deviceInactive.
  String get deviceInactive;

  /// No description provided for @categoryReminders.
  String get categoryReminders;

  /// No description provided for @categoryRemindersSubtitle.
  String get categoryRemindersSubtitle;

  /// No description provided for @categoryLowStock.
  String get categoryLowStock;

  /// No description provided for @categoryLowStockSubtitle.
  String get categoryLowStockSubtitle;

  /// No description provided for @categoryPaymentDue.
  String get categoryPaymentDue;

  /// No description provided for @categoryPaymentDueSubtitle.
  String get categoryPaymentDueSubtitle;

  /// No description provided for @categoryBackup.
  String get categoryBackup;

  /// No description provided for @categoryBackupSubtitle.
  String get categoryBackupSubtitle;

  /// No description provided for @categorySystem.
  String get categorySystem;

  /// No description provided for @categorySystemSubtitle.
  String get categorySystemSubtitle;

  /// No description provided for @reminders.
  String get reminders;

  /// No description provided for @newReminder.
  String get newReminder;

  /// No description provided for @editReminder.
  String get editReminder;

  /// No description provided for @noReminders.
  String get noReminders;

  /// No description provided for @needsAttention.
  String get needsAttention;

  /// No description provided for @scheduled.
  String get scheduled;

  /// No description provided for @addReminder.
  String get addReminder;

  /// No description provided for @reminderTitle.
  String get reminderTitle;

  /// No description provided for @reminderTitleHint.
  String get reminderTitleHint;

  /// No description provided for @reminderTitleRequired.
  String get reminderTitleRequired;

  /// No description provided for @dueTime.
  String get dueTime;

  /// No description provided for @repeat.
  String get repeat;

  /// No description provided for @repeatOnce.
  String get repeatOnce;

  /// No description provided for @repeatDaily.
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  String get repeatMonthly;

  /// No description provided for @repeatYearly.
  String get repeatYearly;

  /// No description provided for @recurringNote.
  String get recurringNote;

  /// No description provided for @saveReminder.
  String get saveReminder;

  /// No description provided for @reminderSaved.
  String get reminderSaved;

  /// No description provided for @markDone.
  String get markDone;

  /// No description provided for @dismiss.
  String get dismiss;

  /// No description provided for @markedDone.
  String get markedDone;

  /// No description provided for @checkDueReminders.
  String get checkDueReminders;

  /// No description provided for @nothingDue.
  String get nothingDue;

  /// No description provided for @remindersFiredCount.
  String remindersFiredCount(int count);

  /// No description provided for @dueToday.
  String get dueToday;

  /// No description provided for @dueTomorrow.
  String get dueTomorrow;

  /// No description provided for @dueYesterday.
  String get dueYesterday;

  /// No description provided for @reminderStatusPending.
  String get reminderStatusPending;

  /// No description provided for @reminderStatusDone.
  String get reminderStatusDone;

  /// No description provided for @reminderStatusDismissed.
  String get reminderStatusDismissed;

  /// No description provided for @backupAndRestore.
  String get backupAndRestore;

  /// No description provided for @exportBackup.
  String get exportBackup;

  /// No description provided for @restoreFromLastExport.
  String get restoreFromLastExport;

  /// No description provided for @restoreFromPastedJson.
  String get restoreFromPastedJson;

  /// No description provided for @backupExportBody.
  String get backupExportBody;

  /// No description provided for @backupRestoreBody.
  String get backupRestoreBody;

  /// No description provided for @backupNotIncludedTitle.
  String get backupNotIncludedTitle;

  /// No description provided for @backupNotIncludedBody.
  String get backupNotIncludedBody;

  /// No description provided for @restoreConfirmTitle.
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmBody.
  String get restoreConfirmBody;

  /// No description provided for @restoreComplete.
  String get restoreComplete;

  /// No description provided for @restoreAddedCount.
  String restoreAddedCount(int count);

  /// No description provided for @restoreSkippedCount.
  String restoreSkippedCount(int count);

  /// No description provided for @recordsAdded.
  String recordsAdded(int count);

  /// No description provided for @recordsAddedKept.
  String recordsAddedKept(int count, int kept);

  /// No description provided for @clipboardEmpty.
  String get clipboardEmpty;

  /// No description provided for @notAKhataBackup.
  String get notAKhataBackup;

  /// No description provided for @save.
  String get save;

  /// No description provided for @change.
  String get change;

  /// No description provided for @all.
  String get all;

  /// No description provided for @none.
  String get none;

  /// No description provided for @code.
  String get code;

  /// No description provided for @role.
  String get role;

  /// No description provided for @filter.
  String get filter;

  /// No description provided for @sort.
  String get sort;

  /// No description provided for @optional.
  String get optional;

  /// No description provided for @pendingChanges.
  String get pendingChanges;

  /// No description provided for @confirm.
  String get confirm;

  /// No description provided for @close.
  String get close;

  /// No description provided for @yes.
  String get yes;

  /// No description provided for @no.
  String get no;

  /// No description provided for @signInToYourAccount.
  String get signInToYourAccount;

  /// No description provided for @createYourAccountTitle.
  String get createYourAccountTitle;

  /// No description provided for @getStarted.
  String get getStarted;

  /// No description provided for @fullNamePlaceholder.
  String get fullNamePlaceholder;

  /// No description provided for @phoneNumberPlaceholder.
  String get phoneNumberPlaceholder;

  /// No description provided for @phoneOptional.
  String get phoneOptional;

  /// No description provided for @pan.
  String get pan;

  /// No description provided for @businessNameRequired.
  String get businessNameRequired;

  /// No description provided for @createNewBusiness.
  String get createNewBusiness;

  /// No description provided for @businesses.
  String get businesses;

  /// No description provided for @couldNotCreateBusiness.
  String couldNotCreateBusiness(String error);

  /// No description provided for @couldNotSwitchBusiness.
  String couldNotSwitchBusiness(String error);

  /// No description provided for @couldNotUpdateProfile.
  String couldNotUpdateProfile(String error);

  /// No description provided for @profileUpdated.
  String get profileUpdated;

  /// No description provided for @changeRoleFor.
  String changeRoleFor(String name);

  /// No description provided for @couldNotChangeRole.
  String couldNotChangeRole(String error);

  /// No description provided for @removeMember.
  String removeMember(String name);

  /// No description provided for @removeMemberWarning.
  String get removeMemberWarning;

  /// No description provided for @couldNotRemoveMember.
  String couldNotRemoveMember(String error);

  /// No description provided for @inviteFailed.
  String inviteFailed(String error);

  /// No description provided for @noStaffMembersYet.
  String get noStaffMembersYet;

  /// No description provided for @productNameRequired.
  String get productNameRequired;

  /// No description provided for @searchNameSkuBarcode.
  String get searchNameSkuBarcode;

  /// No description provided for @noProductsFound.
  String get noProductsFound;

  /// No description provided for @costPriceRs.
  String get costPriceRs;

  /// No description provided for @sellingPriceRsRequired.
  String get sellingPriceRsRequired;

  /// No description provided for @wholesalePriceRs.
  String get wholesalePriceRs;

  /// No description provided for @taxRatePercent.
  String get taxRatePercent;

  /// No description provided for @openingStockQuantity.
  String get openingStockQuantity;

  /// No description provided for @minimumQuantityHint.
  String get minimumQuantityHint;

  /// No description provided for @inactiveProductsNote.
  String get inactiveProductsNote;

  /// No description provided for @deleteProductQuestion.
  String get deleteProductQuestion;

  /// No description provided for @deleteProductWarning.
  String get deleteProductWarning;

  /// No description provided for @loadingProduct.
  String get loadingProduct;

  /// No description provided for @couldNotLoadProduct.
  String couldNotLoadProduct(String error);

  /// No description provided for @byCategory.
  String get byCategory;

  /// No description provided for @expensesByCategory.
  String get expensesByCategory;

  /// No description provided for @categoriesNoCategories.
  String get categoriesNoCategories;

  /// No description provided for @noCategory.
  String get noCategory;

  /// No description provided for @deleteCategoryQuestion.
  String get deleteCategoryQuestion;

  /// No description provided for @categoryDeleteNote.
  String get categoryDeleteNote;

  /// No description provided for @categoryRequired.
  String get categoryRequired;

  /// No description provided for @noUnit.
  String get noUnit;

  /// No description provided for @unitNameHint.
  String get unitNameHint;

  /// No description provided for @unitShortHint.
  String get unitShortHint;

  /// No description provided for @unitsNoUnits.
  String get unitsNoUnits;

  /// No description provided for @deleteUnitQuestion.
  String get deleteUnitQuestion;

  /// No description provided for @unitDeleteNote.
  String get unitDeleteNote;

  /// No description provided for @movementHistory.
  String get movementHistory;

  /// No description provided for @noStockMovementsYet.
  String get noStockMovementsYet;

  /// No description provided for @customQuantityHint.
  String get customQuantityHint;

  /// No description provided for @quantityExample.
  String get quantityExample;

  /// No description provided for @reasonExample.
  String get reasonExample;

  /// No description provided for @stockValuation.
  String get stockValuation;

  /// No description provided for @currentStockIs.
  String currentStockIs(String quantity);

  /// No description provided for @balanceIs.
  String balanceIs(String quantity);

  /// No description provided for @nameRequired.
  String get nameRequired;

  /// No description provided for @partyNameExample.
  String get partyNameExample;

  /// No description provided for @creditLimitRs.
  String get creditLimitRs;

  /// No description provided for @openingBalanceRs.
  String get openingBalanceRs;

  /// No description provided for @walkInNone.
  String get walkInNone;

  /// No description provided for @deletePartyQuestion.
  String deletePartyQuestion(String kind);

  /// No description provided for @partyDeleteNote.
  String get partyDeleteNote;

  /// No description provided for @khataHistoryKept.
  String get khataHistoryKept;

  /// No description provided for @createSale.
  String get createSale;

  /// No description provided for @createPurchase.
  String get createPurchase;

  /// No description provided for @createInvoice.
  String get createInvoice;

  /// No description provided for @createQuotation.
  String get createQuotation;

  /// No description provided for @noItemsYetAddProduct.
  String get noItemsYetAddProduct;

  /// No description provided for @addFreeText.
  String get addFreeText;

  /// No description provided for @items.
  String get items;

  /// No description provided for @itemsCount.
  String itemsCount(int count);

  /// No description provided for @extraDiscountRs.
  String get extraDiscountRs;

  /// No description provided for @paidNowRs.
  String get paidNowRs;

  /// No description provided for @paidAmountRs.
  String get paidAmountRs;

  /// No description provided for @amountRsRequired.
  String get amountRsRequired;

  /// No description provided for @lineTotalIs.
  String lineTotalIs(String total);

  /// No description provided for @invoiceNumberLabel.
  String invoiceNumberLabel(String number);

  /// No description provided for @quotationNumberLabel.
  String quotationNumberLabel(String number);

  /// No description provided for @issuedOn.
  String issuedOn(String date);

  /// No description provided for @dueOn.
  String dueOn(String date);

  /// No description provided for @validUntilOn.
  String validUntilOn(String date);

  /// No description provided for @convertedToSale.
  String convertedToSale(int id);

  /// No description provided for @lineItemsCopiedNote.
  String get lineItemsCopiedNote;

  /// No description provided for @noneBuildManually.
  String get noneBuildManually;

  /// No description provided for @notesOptional.
  String get notesOptional;

  /// No description provided for @termsLabel.
  String termsLabel(String terms);

  /// No description provided for @notesLabel.
  String notesLabel(String notes);

  /// No description provided for @sharePdf.
  String get sharePdf;

  /// No description provided for @exportCsv.
  String get exportCsv;

  /// No description provided for @deleteSaleQuestion.
  String get deleteSaleQuestion;

  /// No description provided for @deletePurchaseQuestion.
  String get deletePurchaseQuestion;

  /// No description provided for @deleteInvoiceQuestion.
  String get deleteInvoiceQuestion;

  /// No description provided for @deleteQuotationQuestion.
  String get deleteQuotationQuestion;

  /// No description provided for @deleteExpenseQuestion.
  String get deleteExpenseQuestion;

  /// No description provided for @deleteIncomeQuestion.
  String get deleteIncomeQuestion;

  /// No description provided for @deleteMethodQuestion.
  String get deleteMethodQuestion;

  /// No description provided for @saleDeleteNote.
  String get saleDeleteNote;

  /// No description provided for @purchaseDeleteNote.
  String get purchaseDeleteNote;

  /// No description provided for @expenseDeleteNote.
  String get expenseDeleteNote;

  /// No description provided for @incomeDeleteNote.
  String get incomeDeleteNote;

  /// No description provided for @invoiceDeleteNote.
  String get invoiceDeleteNote;

  /// No description provided for @quotationDeleteNote.
  String get quotationDeleteNote;

  /// No description provided for @searchInvoiceOrCustomer.
  String get searchInvoiceOrCustomer;

  /// No description provided for @searchBillOrSupplier.
  String get searchBillOrSupplier;

  /// No description provided for @searchQuotationOrCustomer.
  String get searchQuotationOrCustomer;

  /// No description provided for @searchPartyOrReference.
  String get searchPartyOrReference;

  /// No description provided for @paymentMethod.
  String get paymentMethod;

  /// No description provided for @addMethod.
  String get addMethod;

  /// No description provided for @noPaymentMethodsYet.
  String get noPaymentMethodsYet;

  /// No description provided for @setAsDefault.
  String get setAsDefault;

  /// No description provided for @methodChangeNote.
  String get methodChangeNote;

  /// No description provided for @advanceIs.
  String advanceIs(String amount);

  /// No description provided for @dueToCustomerKhata.
  String dueToCustomerKhata(String amount);

  /// No description provided for @dueToSupplierKhata.
  String dueToSupplierKhata(String amount);

  /// No description provided for @advancesAreMoney.
  String get advancesAreMoney;

  /// No description provided for @advancesLabel.
  String advancesLabel(String list);

  /// No description provided for @addProductButton.
  String get addProductButton;

  /// No description provided for @addReminderButton.
  String get addReminderButton;

  /// No description provided for @receivablesAndPayables.
  String get receivablesAndPayables;

  /// No description provided for @receivablesCount.
  String receivablesCount(int count);

  /// No description provided for @payablesCount.
  String payablesCount(int count);

  /// No description provided for @profitAndLoss.
  String get profitAndLoss;

  /// No description provided for @salesReportTitle.
  String get salesReportTitle;

  /// No description provided for @revenueExcludesVat.
  String get revenueExcludesVat;

  /// No description provided for @salesTrendLast14.
  String get salesTrendLast14;

  /// No description provided for @salesTrendScope.
  String salesTrendScope(String scope);

  /// No description provided for @topProducts.
  String get topProducts;

  /// No description provided for @topCustomers.
  String get topCustomers;

  /// No description provided for @bySource.
  String get bySource;

  /// No description provided for @incomeTrend.
  String get incomeTrend;

  /// No description provided for @lastCycle.
  String get lastCycle;

  /// No description provided for @noDataYet.
  String get noDataYet;

  /// No description provided for @couldNotLoad.
  String couldNotLoad(String error);

  /// No description provided for @couldNotLoadSummary.
  String get couldNotLoadSummary;

  /// No description provided for @dashboardUnavailable.
  String get dashboardUnavailable;

  /// No description provided for @productsCount.
  String productsCount(int count);

  /// No description provided for @unitsDocsCount.
  String unitsDocsCount(String quantity, int count);

  /// No description provided for @quantityTimesPrice.
  String quantityTimesPrice(String quantity, String price);

  /// No description provided for @lowStockNote.
  String lowStockNote(String name);

  /// No description provided for @syncTitle.
  String get syncTitle;

  /// No description provided for @syncStatusTitle.
  String get syncStatusTitle;

  /// No description provided for @lastSyncLabel.
  String get lastSyncLabel;

  /// No description provided for @pendingChangesCount.
  String get pendingChangesCount;

  /// No description provided for @syncFailed.
  String syncFailed(String error);

  /// No description provided for @operationFailed.
  String operationFailed(String operation);

  /// No description provided for @conflicts.
  String get conflicts;

  /// No description provided for @noConflicts.
  String get noConflicts;

  /// No description provided for @entityRef.
  String entityRef(String type, int id);

  /// No description provided for @serverChanged.
  String get serverChanged;

  /// No description provided for @serverVersion.
  String serverVersion(String json);

  /// No description provided for @operationDetail.
  String operationDetail(String operation);

  /// No description provided for @pushed.
  String get pushed;

  /// No description provided for @pulled.
  String get pulled;

  /// No description provided for @rejectedWithError.
  String rejectedWithError(String error);

  /// No description provided for @backupSubject.
  String get backupSubject;

  /// No description provided for @backupShareText.
  String get backupShareText;

  /// No description provided for @recordsAddedCount.
  String recordsAddedCount(int count);

  /// No description provided for @alreadyPresentCount.
  String alreadyPresentCount(int count);

  /// No description provided for @addedCount.
  String addedCount(int count);

  /// No description provided for @addedKeptCount.
  String addedKeptCount(int count, int kept);

  /// No description provided for @reminderRepeatNote.
  String get reminderRepeatNote;

  /// No description provided for @profileLabel.
  String get profileLabel;

  /// No description provided for @languageEnglish.
  String get languageEnglish;

  /// No description provided for @languageNepali.
  String get languageNepali;

  /// No description provided for @calendarLabel.
  String get calendarLabel;

  /// No description provided for @generalSection.
  String get generalSection;

  /// No description provided for @dateLabel.
  String get dateLabel;

  /// No description provided for @descriptionLabel.
  String get descriptionLabel;

  /// No description provided for @fromLabel.
  String get fromLabel;

  /// No description provided for @toLabel.
  String get toLabel;

  /// No description provided for @titleRequired.
  String get titleRequired;

  /// No description provided for @sourceRequired.
  String get sourceRequired;

  /// No description provided for @taxExample.
  String get taxExample;

  /// No description provided for @amountExample.
  String get amountExample;

  /// No description provided for @quantityExample16.
  String get quantityExample16;

  /// No description provided for @rateExample.
  String get rateExample;

  /// No description provided for @plusOne.
  String get plusOne;

  /// No description provided for @plusTen.
  String get plusTen;

  /// No description provided for @minusOne.
  String get minusOne;

  /// No description provided for @minusTen.
  String get minusTen;

  /// No description provided for @phonePrefixHint.
  String get phonePrefixHint;

  /// No description provided for @rankLabel.
  String get rankLabel;

  /// No description provided for @editKind.
  String editKind(String kind);

  /// No description provided for @newKind.
  String newKind(String kind);

  /// No description provided for @delete.
  String get delete;

  /// No description provided for @edit.
  String get edit;

  /// No description provided for @convert.
  String get convert;

  /// No description provided for @exportTitle.
  String get exportTitle;

  /// No description provided for @restoreTitle.
  String get restoreTitle;

  /// No description provided for @expenseTrend.
  String get expenseTrend;

  /// No description provided for @opening.
  String get opening;

  /// No description provided for @filterByCategory.
  String get filterByCategory;

  /// No description provided for @phoneLabel.
  String get phoneLabel;

  /// No description provided for @emailMustHaveAccount.
  String get emailMustHaveAccount;

  /// No description provided for @advancesExplainer.
  String get advancesExplainer;

  /// No description provided for @backupExportExplainerFull.
  String get backupExportExplainerFull;

  /// No description provided for @backupRestoreExplainerFull.
  String get backupRestoreExplainerFull;

  /// No description provided for @backupNotIncludedExplainer.
  String get backupNotIncludedExplainer;

  /// No description provided for @restoreConfirmBodyFull.
  String get restoreConfirmBodyFull;

  /// No description provided for @methodChangeNoteFull.
  String get methodChangeNoteFull;

  /// No description provided for @saleDeleteNoteFull.
  String get saleDeleteNoteFull;

  /// No description provided for @purchaseDeleteNoteFull.
  String get purchaseDeleteNoteFull;

  /// No description provided for @lineItemsCopiedNoteFull.
  String get lineItemsCopiedNoteFull;

  /// No description provided for @notificationsInAppNoteFull.
  String get notificationsInAppNoteFull;

  /// No description provided for @unitNameShort.
  String unitNameShort(String name, String short);

  /// No description provided for @retailValue.
  String retailValue(String amount);

  /// No description provided for @advanceAmount.
  String advanceAmount(String amount);

  /// No description provided for @quantityWithUnit.
  String quantityWithUnit(String quantity, String unit);

  /// No description provided for @productPricePair.
  String productPricePair(String price);

  /// No description provided for @saleCustomerLine.
  String saleCustomerLine(String number, String customer);

  /// No description provided for @lineTotalAmount.
  String lineTotalAmount(String amount);

  /// No description provided for @conflictsCount.
  String conflictsCount(int count);

  /// No description provided for @noDataInRange.
  String get noDataInRange;

  /// No description provided for @nothingToBreakDown.
  String get nothingToBreakDown;

  /// No description provided for @noProductsMatchFilter.
  String get noProductsMatchFilter;

  /// No description provided for @noProductsSoldInRange.
  String get noProductsSoldInRange;

  /// No description provided for @noSalesToCustomersInRange.
  String get noSalesToCustomersInRange;

  /// No description provided for @nobodyOwesYou.
  String get nobodyOwesYou;

  /// No description provided for @youOweNobody.
  String get youOweNobody;

  /// No description provided for @addLabel.
  String addLabel(String label);

  /// No description provided for @couldNotLoadX.
  String couldNotLoadX(String subject, String error);

  /// No description provided for @balances.
  String get balances;

  /// No description provided for @expenseReport.
  String get expenseReport;

  /// No description provided for @incomeReport.
  String get incomeReport;

  /// No description provided for @stockReportTitle.
  String get stockReportTitle;

  /// No description provided for @expenseReportTitle.
  String get expenseReportTitle;

  /// No description provided for @incomeReportTitle.
  String get incomeReportTitle;

  /// No description provided for @profitAndLossTitle.
  String get profitAndLossTitle;

  /// No description provided for @stockMovements.
  String get stockMovements;

  /// No description provided for @devices.
  String get devices;

  /// No description provided for @emailAndRole.
  String emailAndRole(String email, String role);

  /// No description provided for @addKind.
  String addKind(String kind);

  /// No description provided for @lowAtOrBelow.
  String lowAtOrBelow(String quantity, String unit);

  /// No description provided for @minimumIs.
  String minimumIs(String quantity, String unit);

  /// No description provided for @savedTo.
  String savedTo(String path);

  /// No description provided for @emailRequired.
  String get emailRequired;

  /// No description provided for @emailInvalid.
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  String get passwordRequired;

  /// No description provided for @passwordRegisterRequired.
  String get passwordRegisterRequired;

  /// No description provided for @passwordTooShort.
  String get passwordTooShort;

  /// No description provided for @passwordNeedsDigit.
  String get passwordNeedsDigit;

  /// No description provided for @confirmPasswordRequired.
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  String get passwordsDoNotMatch;

  /// No description provided for @fullNameRequired.
  String get fullNameRequired;

  /// No description provided for @fullNameIsRequired.
  String get fullNameIsRequired;

  /// No description provided for @businessNameIsRequired.
  String get businessNameIsRequired;

  /// No description provided for @amountRequired.
  String get amountRequired;

  /// No description provided for @amountInvalid.
  String get amountInvalid;

  /// No description provided for @amountInvalidFull.
  String get amountInvalidFull;

  /// No description provided for @amountMustBePositive.
  String get amountMustBePositive;

  /// No description provided for @quantityInvalid.
  String get quantityInvalid;

  /// No description provided for @percentRange.
  String get percentRange;

  /// No description provided for @panMustBe9Digits.
  String get panMustBe9Digits;

  /// No description provided for @panMustBe9DigitNumber.
  String get panMustBe9DigitNumber;

  /// No description provided for @phoneInvalid.
  String get phoneInvalid;

  /// No description provided for @emailAddressRequired.
  String get emailAddressRequired;

  /// No description provided for @invalidEmailOrPassword.
  String get invalidEmailOrPassword;

  /// No description provided for @checkYourInput.
  String get checkYourInput;

  /// No description provided for @somethingWentWrong.
  String get somethingWentWrong;

  /// No description provided for @returnIn.
  String get returnIn;

  /// No description provided for @returnOut.
  String get returnOut;

  /// No description provided for @week.
  String get week;

  /// No description provided for @month.
  String get month;

  /// No description provided for @day.
  String get day;

  /// No description provided for @todayAt.
  String todayAt(String time);

  /// No description provided for @tomorrowAt.
  String tomorrowAt(String time);

  /// No description provided for @yesterdayAt.
  String yesterdayAt(String time);

  /// No description provided for @noKindMatchSearch.
  String noKindMatchSearch(String kind);

  /// No description provided for @noKindYet.
  String noKindYet(String kind);

  /// No description provided for @categoryReminder.
  String get categoryReminder;

  /// No description provided for @saved.
  String get saved;

  /// No description provided for @productSaved.
  String get productSaved;

  /// No description provided for @walkInCustomer.
  String get walkInCustomer;

  /// No description provided for @notSet.
  String get notSet;

  /// No description provided for @unpaid.
  String get unpaid;

  /// No description provided for @noSupplier.
  String get noSupplier;

  /// No description provided for @paidInFull.
  String get paidInFull;

  /// No description provided for @exporting.
  String get exporting;

  /// No description provided for @saving.
  String get saving;

  /// No description provided for @noLowStockProducts.
  String get noLowStockProducts;

  /// No description provided for @noProductsMatchSearch.
  String get noProductsMatchSearch;

  /// No description provided for @showingUnread.
  String get showingUnread;

  /// No description provided for @customerKhata.
  String get customerKhata;

  /// No description provided for @debit.
  String get debit;

  /// No description provided for @recordReceipt.
  String get recordReceipt;

  /// No description provided for @applyToInvoice.
  String get applyToInvoice;

  /// No description provided for @receipt.
  String get receipt;

  /// No description provided for @roleViewer.
  String get roleViewer;

  /// No description provided for @never.
  String get never;

  /// No description provided for @syncing.
  String get syncing;

  /// No description provided for @moneyInOut.
  String moneyInOut(String inAmount, String outAmount);

  /// No description provided for @dueAmount.
  String dueAmount(String amount);

  /// No description provided for @created.
  String get created;

  /// No description provided for @productCreated.
  String get productCreated;

  /// No description provided for @toCollectAmount.
  String toCollectAmount(String amount);

  /// No description provided for @toPayAmount.
  String toPayAmount(String amount);

  /// No description provided for @createProduct.
  String get createProduct;

  /// No description provided for @create.
  String get create;

  /// No description provided for @noProductsYet.
  String get noProductsYet;

  /// No description provided for @noProductsYetAddFirst.
  String get noProductsYetAddFirst;

  /// No description provided for @subtotal.
  String get subtotal;

  /// No description provided for @total.
  String get total;

  /// No description provided for @discount.
  String get discount;

  /// No description provided for @rateRs.
  String get rateRs;

  /// No description provided for @discountRs.
  String get discountRs;

  /// No description provided for @addAtLeastOneItem.
  String get addAtLeastOneItem;

  /// No description provided for @costValue.
  String get costValue;

  /// No description provided for @potentialMargin.
  String get potentialMargin;

  /// No description provided for @invoiceCreated.
  String get invoiceCreated;

  /// No description provided for @invoiceDeleted.
  String get invoiceDeleted;

  /// No description provided for @quotationCreated.
  String get quotationCreated;

  /// No description provided for @quotationDeleted.
  String get quotationDeleted;

  /// No description provided for @convertedToSaleToast.
  String get convertedToSaleToast;

  /// No description provided for @saleCreated.
  String get saleCreated;

  /// No description provided for @saleReversed.
  String get saleReversed;

  /// No description provided for @saleKeptAsReversed.
  String get saleKeptAsReversed;

  /// No description provided for @creditSaleNeedsCustomer.
  String get creditSaleNeedsCustomer;

  /// No description provided for @purchaseCreated.
  String get purchaseCreated;

  /// No description provided for @purchaseReversed.
  String get purchaseReversed;

  /// No description provided for @purchaseKeptAsReversed.
  String get purchaseKeptAsReversed;

  /// No description provided for @creditPurchaseNeedsSupplier.
  String get creditPurchaseNeedsSupplier;

  /// No description provided for @paymentRecorded.
  String get paymentRecorded;

  /// No description provided for @methodSaved.
  String get methodSaved;

  /// No description provided for @methodDeleted.
  String get methodDeleted;

  /// No description provided for @categorySaved.
  String get categorySaved;

  /// No description provided for @categoryDeleted.
  String get categoryDeleted;

  /// No description provided for @productDeleted.
  String get productDeleted;

  /// No description provided for @unitSaved.
  String get unitSaved;

  /// No description provided for @unitDeleted.
  String get unitDeleted;

  /// No description provided for @settingsSaved.
  String get settingsSaved;

  /// No description provided for @atLeastOneMethodMustRemain.
  String get atLeastOneMethodMustRemain;

  /// No description provided for @notAkhataBackup.
  String get notAkhataBackup;

  /// No description provided for @enterNonZeroQuantity.
  String get enterNonZeroQuantity;

  /// No description provided for @enterAmountGreaterThanZero.
  String get enterAmountGreaterThanZero;

  /// No description provided for @balanceAfterIs.
  String balanceAfterIs(String quantity);

  /// No description provided for @rejectedAndFailed.
  String get rejectedAndFailed;

  /// No description provided for @entries.
  String get entries;

  /// No description provided for @average.
  String get average;

  /// No description provided for @sources.
  String get sources;

  /// No description provided for @revenue.
  String get revenue;

  /// No description provided for @costOfGoodsSold.
  String get costOfGoodsSold;

  /// No description provided for @grossProfit.
  String get grossProfit;

  /// No description provided for @otherIncome.
  String get otherIncome;

  /// No description provided for @netProfit.
  String get netProfit;

  /// No description provided for @taxCollectedInPeriod.
  String get taxCollectedInPeriod;

  /// No description provided for @customerAdvances.
  String get customerAdvances;

  /// No description provided for @supplierAdvances.
  String get supplierAdvances;

  /// No description provided for @advancesExplain.
  String get advancesExplain;

  /// No description provided for @reportSalesBlurb.
  String get reportSalesBlurb;

  /// No description provided for @reportProfitLossBlurb.
  String get reportProfitLossBlurb;

  /// No description provided for @reportExpenseBlurb.
  String get reportExpenseBlurb;

  /// No description provided for @reportIncomeBlurb.
  String get reportIncomeBlurb;

  /// No description provided for @reportStockBlurb.
  String get reportStockBlurb;

  /// No description provided for @reportReceivableBlurb.
  String get reportReceivableBlurb;

  /// No description provided for @ledgerOwesYouHint.
  String get ledgerOwesYouHint;

  /// No description provided for @ledgerYouOweHint.
  String get ledgerYouOweHint;

  /// No description provided for @roleOwner.
  String get roleOwner;

  /// No description provided for @roleAdmin.
  String get roleAdmin;

  /// No description provided for @roleManager.
  String get roleManager;

  /// No description provided for @roleAccountant.
  String get roleAccountant;

  /// No description provided for @noBusiness.
  String get noBusiness;

  /// No description provided for @couldNotLoadProducts.
  String couldNotLoadProducts(String error);

  /// No description provided for @lineItemsCopiedFromSale.
  String get lineItemsCopiedFromSale;

  /// No description provided for @bsRange.
  String bsRange(String from, String to);

  /// No description provided for @conflictsNamed.
  String conflictsNamed(int count);

  /// No description provided for @retailValueReport.
  String get retailValueReport;

  /// No description provided for @selectPartyKind.
  String selectPartyKind(String kind);

  /// No description provided for @tax.
  String get tax;

  /// No description provided for @qty.
  String get qty;

  /// No description provided for @adjustment.
  String get adjustment;

  /// No description provided for @showingAll.
  String get showingAll;

  /// No description provided for @supplierKhata.
  String get supplierKhata;

  /// No description provided for @applyToBill.
  String get applyToBill;

  /// No description provided for @newMethod.
  String get newMethod;

  /// No description provided for @today.
  String get today;

  /// No description provided for @municipality.
  String get municipality;

  /// No description provided for @selectProvinceHint.
  String get selectProvinceHint;

  /// No description provided for @selectDistrictHint.
  String get selectDistrictHint;

  /// No description provided for @selectMunicipalityHint.
  String get selectMunicipalityHint;

  /// No description provided for @municipalityFreeTextHint.
  String get municipalityFreeTextHint;

  /// No description provided for @phoneInvalidNepali.
  String get phoneInvalidNepali;

  /// No description provided for @fromDate.
  String get fromDate;

  /// No description provided for @toDate.
  String get toDate;

  /// No description provided for @back.
  String get back;

  /// No description provided for @next.
  String get next;

  /// No description provided for @endBeforeStart.
  String get endBeforeStart;

  /// No description provided for @dateRange.
  String get dateRange;

  /// No description provided for @toolsTitle.
  String get toolsTitle;

  /// No description provided for @emiCalculator.
  String get emiCalculator;

  /// No description provided for @loanAmount.
  String get loanAmount;

  /// No description provided for @annualInterestRate.
  String get annualInterestRate;

  /// No description provided for @loanTermMonths.
  String get loanTermMonths;

  /// No description provided for @monthlyEmi.
  String get monthlyEmi;

  /// No description provided for @totalPayment.
  String get totalPayment;

  /// No description provided for @totalInterest.
  String get totalInterest;

  /// No description provided for @interestCalculator.
  String get interestCalculator;

  /// No description provided for @simpleInterest.
  String get simpleInterest;

  /// No description provided for @compoundInterest.
  String get compoundInterest;

  /// No description provided for @principal.
  String get principal;

  /// No description provided for @years.
  String get years;

  /// No description provided for @compoundingPerYear.
  String get compoundingPerYear;

  /// No description provided for @interestEarned.
  String get interestEarned;

  /// No description provided for @profitCalculator.
  String get profitCalculator;

  /// No description provided for @profit.
  String get profit;

  /// No description provided for @profitMargin.
  String get profitMargin;

  /// No description provided for @markup.
  String get markup;

  /// No description provided for @enterValidAmount.
  String get enterValidAmount;

  /// No description provided for @maturityAmount.
  String get maturityAmount;

  /// No description provided for @calculate.
  String get calculate;

  /// No description provided for @lossWarning.
  String get lossWarning;

  /// No description provided for @appLock.
  String get appLock;

  /// No description provided for @appLockDescription.
  String get appLockDescription;

  /// No description provided for @setPin.
  String get setPin;

  /// No description provided for @changePin.
  String get changePin;

  /// No description provided for @enterPin.
  String get enterPin;

  /// No description provided for @confirmPin.
  String get confirmPin;

  /// No description provided for @currentPin.
  String get currentPin;

  /// No description provided for @newPin.
  String get newPin;

  /// No description provided for @pinMustBe4To6Digits.
  String get pinMustBe4To6Digits;

  /// No description provided for @pinsDoNotMatch.
  String get pinsDoNotMatch;

  /// No description provided for @incorrectPin.
  String get incorrectPin;

  /// No description provided for @unlock.
  String get unlock;

  /// No description provided for @turnOffAppLock.
  String get turnOffAppLock;

  /// No description provided for @appLockNowOn.
  String get appLockNowOn;

  /// No description provided for @appLockNowOff.
  String get appLockNowOff;

  /// No description provided for @attemptsLeft.
  String attemptsLeft(int count);

  /// No description provided for @bankAccounts.
  String get bankAccounts;

  /// No description provided for @bankName.
  String get bankName;

  /// No description provided for @accountName.
  String get accountName;

  /// No description provided for @accountNumber.
  String get accountNumber;

  /// No description provided for @branch.
  String get branch;

  /// No description provided for @defaultAccount.
  String get defaultAccount;

  /// No description provided for @noBankAccountsYet.
  String get noBankAccountsYet;

  /// No description provided for @addBankAccount.
  String get addBankAccount;

  /// No description provided for @paymentsThroughAccount.
  String paymentsThroughAccount(int count, String total);

  /// No description provided for @deleted.
  String get deleted;

  /// No description provided for @importTile.
  String get importTile;

  /// No description provided for @importTitle.
  String get importTitle;

  /// No description provided for @importExplainerTitle.
  String get importExplainerTitle;

  /// No description provided for @importExplainerBody.
  String get importExplainerBody;

  /// No description provided for @importCopyTemplate.
  String get importCopyTemplate;

  /// No description provided for @importTemplateCopied.
  String get importTemplateCopied;

  /// No description provided for @importPasteFromClipboard.
  String get importPasteFromClipboard;

  /// No description provided for @importCsvLabel.
  String get importCsvLabel;

  /// No description provided for @importCheckFile.
  String get importCheckFile;

  /// No description provided for @importChecking.
  String get importChecking;

  /// No description provided for @importRun.
  String get importRun;

  /// No description provided for @importImporting.
  String get importImporting;

  /// No description provided for @importPreviewTitle.
  String get importPreviewTitle;

  /// No description provided for @importRowsTotal.
  String get importRowsTotal;

  /// No description provided for @importRowsValid.
  String get importRowsValid;

  /// No description provided for @importRowsDuplicate.
  String get importRowsDuplicate;

  /// No description provided for @importRowsInvalid.
  String get importRowsInvalid;

  /// No description provided for @importBlockedHint.
  String get importBlockedHint;

  /// No description provided for @importIgnoredColumns.
  String importIgnoredColumns(String columns);

  /// No description provided for @importIssuesTitle.
  String get importIssuesTitle;

  /// No description provided for @importIssueLine.
  String importIssueLine(int row, String message);

  /// No description provided for @importIssueLineWithColumn.
  String importIssueLineWithColumn(int row, String column, String message);

  /// No description provided for @importMoreIssues.
  String importMoreIssues(int count);

  /// No description provided for @importConfirmTitle.
  String get importConfirmTitle;

  /// No description provided for @importConfirmBody.
  String get importConfirmBody;

  /// No description provided for @importCompleteTitle.
  String get importCompleteTitle;

  /// No description provided for @importCreatedCount.
  String importCreatedCount(int count);

  /// No description provided for @importSkippedCount.
  String importSkippedCount(int count);

  /// No description provided for @importRejected.
  String get importRejected;

  /// No description provided for @importClear.
  String get importClear;

  /// No description provided for @importExpectedColumns.
  String get importExpectedColumns;

  /// No description provided for @cachedDataNote.
  String get cachedDataNote;

  /// No description provided for @cachedDataNoteAt.
  String cachedDataNoteAt(String time);

  /// No description provided for @offlineDataTitle.
  String get offlineDataTitle;

  /// No description provided for @offlineDataExplainer.
  String get offlineDataExplainer;

  /// No description provided for @offlineDataSavedLabel.
  String get offlineDataSavedLabel;

  /// No description provided for @offlineDataSavedCount.
  String offlineDataSavedCount(int lists, String size);

  /// No description provided for @offlineDataClear.
  String get offlineDataClear;

  /// No description provided for @offlineDataClearConfirm.
  String get offlineDataClearConfirm;

  /// No description provided for @offlineDataCleared.
  String get offlineDataCleared;

  /// No description provided for @loadMoreRemaining.
  String loadMoreRemaining(int count);

  /// No description provided for @pageNotFound.
  String get pageNotFound;

  /// No description provided for @pageNotFoundBody.
  String get pageNotFoundBody;

  /// No description provided for @fileSaveNotSupported.
  String get fileSaveNotSupported;

  /// No description provided for @savedOffline.
  String get savedOffline;

  /// No description provided for @offlineBannerNote.
  String get offlineBannerNote;

  /// No description provided for @languageHindi.
  String get languageHindi;

  /// No description provided for @calendarAd.
  String get calendarAd;

  /// No description provided for @calendarBs.
  String get calendarBs;

  /// No description provided for @calendarNote.
  String get calendarNote;

  /// No description provided for @pendingWritesCount.
  String pendingWritesCount(int count);

  /// No description provided for @navHome.
  String get navHome;

  /// No description provided for @navParties.
  String get navParties;

  /// No description provided for @navItems.
  String get navItems;

  /// No description provided for @monthToDate.
  String monthToDate(String amount);

  /// No description provided for @lowStockCountLabel.
  String lowStockCountLabel(int count);

  /// No description provided for @recentActivity.
  String get recentActivity;

  /// No description provided for @viewAll.
  String get viewAll;

  /// No description provided for @getStartedTitle.
  String get getStartedTitle;

  /// No description provided for @getStartedStepProduct.
  String get getStartedStepProduct;

  /// No description provided for @getStartedStepCustomer.
  String get getStartedStepCustomer;

  /// No description provided for @getStartedStepSale.
  String get getStartedStepSale;

  /// No description provided for @shareReminder.
  String get shareReminder;

  /// No description provided for @reminderShareMessage.
  String reminderShareMessage(String name, String business, String amount);

  /// No description provided for @moreSalesDocs.
  String get moreSalesDocs;

  /// No description provided for @moreItems.
  String get moreItems;

  /// No description provided for @moreInsights.
  String get moreInsights;

  /// No description provided for @moreTools.
  String get moreTools;

  /// No description provided for @moreAccount.
  String get moreAccount;

  /// No description provided for @balanceShort.
  String balanceShort(String amount);

  /// No description provided for @moreActions.
  String get moreActions;

  /// No description provided for @welcomeChooseLanguage.
  String get welcomeChooseLanguage;

  /// No description provided for @welcomeSkip.
  String get welcomeSkip;

  /// No description provided for @welcomeSlide1Title.
  String get welcomeSlide1Title;

  /// No description provided for @welcomeSlide1Body.
  String get welcomeSlide1Body;

  /// No description provided for @welcomeSlide2Title.
  String get welcomeSlide2Title;

  /// No description provided for @welcomeSlide2Body.
  String get welcomeSlide2Body;

  /// No description provided for @welcomeSlide3Title.
  String get welcomeSlide3Title;

  /// No description provided for @welcomeSlide3Body.
  String get welcomeSlide3Body;

  /// No description provided for @tryDemo.
  String get tryDemo;

  /// No description provided for @updateTitle.
  String get updateTitle;

  /// No description provided for @updateBody.
  String updateBody(String current, String latest);

  /// No description provided for @updateSize.
  String updateSize(String size);

  /// No description provided for @updateNotesLabel.
  String get updateNotesLabel;

  /// No description provided for @updateDownload.
  String get updateDownload;

  /// No description provided for @updateLater.
  String get updateLater;

  /// No description provided for @updateLinkFailed.
  String get updateLinkFailed;

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
      <String>['en', 'hi', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale".\n'
      'This is likely an error in l10n.yaml.');
}

/// The translations for en.
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn() : super('en');

  @override
  String get appName => 'Digital Khata';

  @override
  String get login => 'Sign In';

  @override
  String get register => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get createAccount => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign up';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get transactions => 'Transactions';

  @override
  String get khata => 'Khata';

  @override
  String get reports => 'Reports';

  @override
  String get more => 'More';

  @override
  String get todaysSales => 'Today\'s Sales';

  @override
  String get todaysPurchases => 'Today\'s Purchases';

  @override
  String get todaysExpenses => 'Today\'s Expenses';

  @override
  String get todaysProfit => 'Today\'s Profit';

  @override
  String get totalReceivable => 'Total Receivable';

  @override
  String get totalPayable => 'Total Payable';

  @override
  String get stockValue => 'Stock Value';

  @override
  String get lowStock => 'Low Stock';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get createBusiness => 'Create Business';

  @override
  String get businessSetupTitle => 'Set up your business';

  @override
  String get businessSetupSubtitle => 'You will be the Owner with full access.';

  @override
  String get businessName => 'Business name';

  @override
  String get businessType => 'Business type (e.g. Retail)';

  @override
  String get panNumber => 'PAN number';

  @override
  String get businessEmail => 'Business email';

  @override
  String get address => 'Address';

  @override
  String get city => 'City';

  @override
  String get district => 'District';

  @override
  String get province => 'Province';

  @override
  String get wardNumber => 'Ward number';

  @override
  String get myBusinesses => 'My Businesses';

  @override
  String get switchBusiness => 'Switch business';

  @override
  String get active => 'Active';

  @override
  String get noBusinesses => 'No businesses yet';

  @override
  String get createFirstBusiness => 'Create your first business';

  @override
  String get staff => 'Staff';

  @override
  String get invite => 'Invite';

  @override
  String get inviteMember => 'Invite staff member';

  @override
  String get changeRole => 'Change role';

  @override
  String get remove => 'Remove';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get cancel => 'Cancel';

  @override
  String get language => 'Language';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading';

  @override
  String get products => 'Products';

  @override
  String get product => 'Product';

  @override
  String get addProduct => 'Add product';

  @override
  String get editProduct => 'Edit product';

  @override
  String get newProduct => 'New product';

  @override
  String get productName => 'Product name';

  @override
  String get sku => 'SKU';

  @override
  String get barcode => 'Barcode';

  @override
  String get categories => 'Categories';

  @override
  String get addCategory => 'Add category';

  @override
  String get newCategory => 'New category';

  @override
  String get category => 'Category';

  @override
  String get units => 'Units';

  @override
  String get addUnit => 'Add unit';

  @override
  String get newUnit => 'New unit';

  @override
  String get unit => 'Unit';

  @override
  String get costPrice => 'Cost price';

  @override
  String get sellingPrice => 'Selling price';

  @override
  String get wholesalePrice => 'Wholesale price';

  @override
  String get taxRate => 'Tax rate';

  @override
  String get openingStock => 'Opening stock';

  @override
  String get minQuantity => 'Low-stock alert at';

  @override
  String get inventory => 'Inventory';

  @override
  String get adjustStock => 'Adjust stock';

  @override
  String get stockHistory => 'Stock history';

  @override
  String get quickAdjust => 'Quick adjust';

  @override
  String get customQuantity => 'Custom quantity';

  @override
  String get notes => 'Notes';

  @override
  String get applyAdjustment => 'Apply adjustment';

  @override
  String get lowStockOnly => 'Low stock only';

  @override
  String get sortByName => 'Sort by name';

  @override
  String get sortByQuantity => 'Sort by quantity';

  @override
  String get searchProducts => 'Search products';

  @override
  String get inStock => 'in stock';

  @override
  String get lowStockAlert => 'Low stock';

  @override
  String get stockAdded => 'Stock added';

  @override
  String get stockRemoved => 'Stock removed';

  @override
  String get customers => 'Customers';

  @override
  String get customer => 'Customer';

  @override
  String get addCustomer => 'Add customer';

  @override
  String get newCustomer => 'New customer';

  @override
  String get editCustomer => 'Edit customer';

  @override
  String get searchCustomers => 'Search customers';

  @override
  String get suppliers => 'Suppliers';

  @override
  String get supplier => 'Supplier';

  @override
  String get addSupplier => 'Add supplier';

  @override
  String get newSupplier => 'New supplier';

  @override
  String get editSupplier => 'Edit supplier';

  @override
  String get searchSuppliers => 'Search suppliers';

  @override
  String get searchPartyHint => 'Search name or phone';

  @override
  String get ledger => 'Khata ledger';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get creditLimit => 'Credit limit';

  @override
  String get creditLimitOptional => 'Credit limit (optional)';

  @override
  String get closingBalance => 'Closing balance';

  @override
  String get totalDebit => 'Total debit';

  @override
  String get totalCredit => 'Total credit';

  @override
  String get toCollect => 'To collect';

  @override
  String get toPay => 'To pay';

  @override
  String get advance => 'Advance';

  @override
  String get settled => 'Settled';

  @override
  String get noCustomers => 'No customers yet';

  @override
  String get noSuppliers => 'No suppliers yet';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get partyDeleted => 'Deleted';

  @override
  String get deletePartyTitle => 'Delete party?';

  @override
  String get sales => 'Sales';

  @override
  String get sale => 'Sale';

  @override
  String get newSale => 'New sale';

  @override
  String get purchases => 'Purchases';

  @override
  String get purchase => 'Purchase';

  @override
  String get newPurchase => 'New purchase';

  @override
  String get expenses => 'Expenses';

  @override
  String get expense => 'Expense';

  @override
  String get addExpense => 'Add expense';

  @override
  String get income => 'Income';

  @override
  String get addIncome => 'Add income';

  @override
  String get invoiceNumber => 'Invoice number';

  @override
  String get billNumber => 'Bill number';

  @override
  String get saleType => 'Sale type';

  @override
  String get paymentStatus => 'Payment status';

  @override
  String get paid => 'Paid';

  @override
  String get due => 'Due';

  @override
  String get addItem => 'Add item';

  @override
  String get searchSales => 'Search sales';

  @override
  String get searchPurchases => 'Search purchases';

  @override
  String get searchExpenses => 'Search expenses';

  @override
  String get searchIncome => 'Search income';

  @override
  String get walkIn => 'Walk-in';

  @override
  String get cash => 'Cash';

  @override
  String get credit => 'Credit';

  @override
  String get partial => 'Partial';

  @override
  String get noSales => 'No sales yet';

  @override
  String get noPurchases => 'No purchases yet';

  @override
  String get noExpenses => 'No expenses yet';

  @override
  String get noIncome => 'No income yet';

  @override
  String get payments => 'Payments';

  @override
  String get payment => 'Payment';

  @override
  String get recordPayment => 'Record payment';

  @override
  String get paymentMethods => 'Payment methods';

  @override
  String get addPaymentMethod => 'Add method';

  @override
  String get receive => 'Receive';

  @override
  String get pay => 'Pay';

  @override
  String get method => 'Method';

  @override
  String get defaultLabel => 'Default';

  @override
  String get reference => 'Reference';

  @override
  String get noPayments => 'No payments yet';

  @override
  String get onAccount => 'None (on account)';

  @override
  String get applyToDocument => 'Apply to invoice/bill';

  @override
  String get advances => 'Advances';

  @override
  String get inactive => 'Inactive';

  @override
  String get invoices => 'Invoices';

  @override
  String get invoice => 'Invoice';

  @override
  String get newInvoice => 'New invoice';

  @override
  String get quotations => 'Quotations';

  @override
  String get quotation => 'Quotation';

  @override
  String get newQuotation => 'New quotation';

  @override
  String get issueDate => 'Issue date';

  @override
  String get dueDate => 'Due date';

  @override
  String get validUntil => 'Valid until';

  @override
  String get terms => 'Terms';

  @override
  String get share => 'Share';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get convertToSale => 'Convert to sale';

  @override
  String get status => 'Status';

  @override
  String get draft => 'Draft';

  @override
  String get sent => 'Sent';

  @override
  String get accepted => 'Accepted';

  @override
  String get rejected => 'Rejected';

  @override
  String get expired => 'Expired';

  @override
  String get overdue => 'Overdue';

  @override
  String get noInvoices => 'No invoices yet';

  @override
  String get noQuotations => 'No quotations yet';

  @override
  String get generateFromSale => 'Generate from a sale';

  @override
  String fromSale(String number) => 'From sale';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationSettings => 'Notification settings';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get nothingMatchesFilter => 'Nothing matches this filter';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get markRead => 'Mark read';

  @override
  String markedReadCount(int count) => '$count marked read';

  @override
  String get nothingToMark => 'Nothing to mark';

  @override
  String get filterAllCategories => 'All categories';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get enablePush => 'Enable push';

  @override
  String get enablePushSubtitle => 'Master switch for this device';

  @override
  String get notificationsInAppNote =>
      'In-app notifications are always recorded. These switches control push delivery only.';

  @override
  String get registeredDevices => 'Registered devices';

  @override
  String get noDevices => 'No devices registered yet';

  @override
  String get deviceActive => 'Active';

  @override
  String get deviceInactive => 'Inactive';

  @override
  String get categoryReminders => 'Reminders';

  @override
  String get categoryRemindersSubtitle => 'When a reminder falls due';

  @override
  String get categoryLowStock => 'Low stock';

  @override
  String get categoryLowStockSubtitle => 'When a product drops to its minimum';

  @override
  String get categoryPaymentDue => 'Payment due';

  @override
  String get categoryPaymentDueSubtitle =>
      'When a bill is close to or past its due date';

  @override
  String get categoryBackup => 'Backup';

  @override
  String get categoryBackupSubtitle => 'Backup finished or failed';

  @override
  String get categorySystem => 'System';

  @override
  String get categorySystemSubtitle => 'Account and app announcements';

  @override
  String get reminders => 'Reminders';

  @override
  String get newReminder => 'New reminder';

  @override
  String get editReminder => 'Edit reminder';

  @override
  String get noReminders => 'Nothing here';

  @override
  String get needsAttention => 'Needs attention';

  @override
  String get scheduled => 'Scheduled';

  @override
  String get addReminder => 'Add reminder';

  @override
  String get reminderTitle => 'Title';

  @override
  String get reminderTitleHint => 'Call Ram about the pending bill';

  @override
  String get reminderTitleRequired => 'A title is required';

  @override
  String get dueTime => 'Due time';

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatOnce => 'Once';

  @override
  String get repeatDaily => 'Every day';

  @override
  String get repeatWeekly => 'Every week';

  @override
  String get repeatMonthly => 'Every month';

  @override
  String get repeatYearly => 'Every year';

  @override
  String get recurringNote =>
      'A repeating reminder reschedules itself after firing instead of completing, so it always lands on the next upcoming date.';

  @override
  String get saveReminder => 'Save reminder';

  @override
  String get reminderSaved => 'Reminder saved';

  @override
  String get markDone => 'Mark done';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get markedDone => 'Marked done';

  @override
  String get checkDueReminders => 'Check for due reminders';

  @override
  String get nothingDue => 'Nothing is due right now';

  @override
  String remindersFiredCount(int count) => '$count reminder(s) fired';

  @override
  String get dueToday => 'Today';

  @override
  String get dueTomorrow => 'Tomorrow';

  @override
  String get dueYesterday => 'Yesterday';

  @override
  String get reminderStatusPending => 'Pending';

  @override
  String get reminderStatusDone => 'Done';

  @override
  String get reminderStatusDismissed => 'Dismissed';

  @override
  String get backupAndRestore => 'Backup & restore';

  @override
  String get exportBackup => 'Export backup';

  @override
  String get restoreFromLastExport => 'Restore from last export';

  @override
  String get restoreFromPastedJson => 'Restore from pasted JSON';

  @override
  String get backupExportBody =>
      'Saves every product, party, sale, purchase, expense, income, payment, invoice and quotation in the active business. Soft-deleted records are kept, so history survives.';

  @override
  String get backupRestoreBody =>
      'Restoring merges a backup into this business. Records that already exist are skipped — nothing is ever overwritten, because a rewritten sale or payment would leave the khata ledger disagreeing with itself.';

  @override
  String get backupNotIncludedTitle => 'What is not included';

  @override
  String get backupNotIncludedBody =>
      'The khata ledger entries and stock movements are derived from the documents above, so they are rebuilt by replaying those operations rather than copied. A restore therefore brings back your records, not the cached totals.';

  @override
  String get restoreConfirmTitle => 'Restore this backup?';

  @override
  String get restoreConfirmBody =>
      'Records that already exist in this business will be skipped. Nothing currently here is modified or deleted.';

  @override
  String get restoreComplete => 'Restore complete';

  @override
  String restoreAddedCount(int count) => '$count record(s) added';

  @override
  String restoreSkippedCount(int count) => '$count already present, left alone';

  @override
  String recordsAdded(int count) => '$count added';

  @override
  String recordsAddedKept(int count, int kept) => '$count added, $kept kept';

  @override
  String get clipboardEmpty => 'Clipboard is empty';

  @override
  String get notAKhataBackup => 'This file is not a Khata backup.';

  @override
  String get save => 'Save';

  @override
  String get change => 'Change';

  @override
  String get all => 'All';

  @override
  String get none => 'None';

  @override
  String get code => 'Code';

  @override
  String get role => 'Role';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get optional => 'optional';

  @override
  String get pendingChanges => 'Pending changes';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get signInToYourAccount => 'Sign in to your account';

  @override
  String get createYourAccountTitle => 'Create your Digital Khata account';

  @override
  String get getStarted => 'Get started';

  @override
  String get fullNamePlaceholder => 'Full name';

  @override
  String get phoneNumberPlaceholder => 'Phone number';

  @override
  String get phoneOptional => 'Phone Number (optional)';

  @override
  String get pan => 'PAN';

  @override
  String get businessNameRequired => 'Business name *';

  @override
  String get createNewBusiness => 'Create new business';

  @override
  String get businesses => 'Businesses';

  @override
  String couldNotCreateBusiness(String error) =>
      'Could not create business: $error';

  @override
  String couldNotSwitchBusiness(String error) =>
      'Could not switch business: $error';

  @override
  String couldNotUpdateProfile(String error) =>
      'Could not update profile: $error';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String changeRoleFor(String name) => 'Change role — $name';

  @override
  String couldNotChangeRole(String error) => 'Could not change role: $error';

  @override
  String removeMember(String name) => 'Remove $name?';

  @override
  String get removeMemberWarning => 'They will lose access to this business.';

  @override
  String couldNotRemoveMember(String error) =>
      'Could not remove member: $error';

  @override
  String inviteFailed(String error) => 'Invite failed: $error';

  @override
  String get noStaffMembersYet => 'No staff members yet';

  @override
  String get productNameRequired => 'Product name *';

  @override
  String get searchNameSkuBarcode => 'Search name, SKU or barcode';

  @override
  String get noProductsFound => 'No products found';

  @override
  String get costPriceRs => 'Cost price (Rs.)';

  @override
  String get sellingPriceRsRequired => 'Selling price (Rs.) *';

  @override
  String get wholesalePriceRs => 'Wholesale price (Rs.)';

  @override
  String get taxRatePercent => 'Tax rate (%)';

  @override
  String get openingStockQuantity => 'Opening stock quantity';

  @override
  String get minimumQuantityHint => 'minimum quantity (0 = no alert)';

  @override
  String get inactiveProductsNote =>
      'Inactive products stay but are hidden from sales';

  @override
  String get deleteProductQuestion => 'Delete product?';

  @override
  String get deleteProductWarning =>
      'The product will be hidden from the catalog. Stock history is kept.';

  @override
  String get loadingProduct => 'Loading product…';

  @override
  String couldNotLoadProduct(String error) => 'Could not load product: $error';

  @override
  String get byCategory => 'By category';

  @override
  String get expensesByCategory => 'Expenses by category';

  @override
  String get categoriesNoCategories => 'No categories yet';

  @override
  String get noCategory => 'No category';

  @override
  String get deleteCategoryQuestion => 'Delete category?';

  @override
  String get categoryDeleteNote =>
      'Products in this category will keep working without a category.';

  @override
  String get categoryRequired => 'Category *';

  @override
  String get noUnit => 'No unit';

  @override
  String get unitNameHint => 'Name * (e.g. Piece)';

  @override
  String get unitShortHint => 'Short name * (e.g. pc)';

  @override
  String get unitsNoUnits => 'No units yet';

  @override
  String get deleteUnitQuestion => 'Delete unit?';

  @override
  String get unitDeleteNote =>
      'Products using this unit will keep working without a unit.';

  @override
  String get movementHistory => 'Movement history';

  @override
  String get noStockMovementsYet => 'No stock movements yet';

  @override
  String get customQuantityHint => 'Custom quantity (+ in / - out)';

  @override
  String get quantityExample => 'e.g. 2.5 or -3';

  @override
  String get reasonExample => 'e.g. stock count, damage';

  @override
  String get stockValuation => 'Stock valuation';

  @override
  String currentStockIs(String quantity) => 'Current stock: $quantity';

  @override
  String balanceIs(String quantity) => 'Bal $quantity';

  @override
  String get nameRequired => 'Name *';

  @override
  String get partyNameExample => 'Name * (e.g. Piece)';

  @override
  String get creditLimitRs => 'Credit limit (Rs.)';

  @override
  String get openingBalanceRs => 'Opening balance (Rs.)';

  @override
  String get walkInNone => 'Walk-in / none';

  @override
  String deletePartyQuestion(String kind) => 'Delete $kind?';

  @override
  String get partyDeleteNote =>
      'The party will be hidden from lists. Khata history is kept.';

  @override
  String get khataHistoryKept => 'Khata history is kept.';

  @override
  String get createSale => 'Create sale';

  @override
  String get createPurchase => 'Create purchase';

  @override
  String get createInvoice => 'Create invoice';

  @override
  String get createQuotation => 'Create quotation';

  @override
  String get noItemsYetAddProduct => 'No items yet — add a product';

  @override
  String get addFreeText => 'Add free text';

  @override
  String get items => 'Items';

  @override
  String itemsCount(int count) => 'Items ($count)';

  @override
  String get extraDiscountRs => 'Extra discount (Rs.)';

  @override
  String get paidNowRs => 'Paid now (Rs.)';

  @override
  String get paidAmountRs => 'Paid amount (Rs.)';

  @override
  String get amountRsRequired => 'Amount (Rs.) *';

  @override
  String lineTotalIs(String total) => 'Line total: $total';

  @override
  String invoiceNumberLabel(String number) => 'Invoice $number';

  @override
  String quotationNumberLabel(String number) => 'Quotation $number';

  @override
  String issuedOn(String date) => 'Issued $date';

  @override
  String dueOn(String date) => 'Due $date';

  @override
  String validUntilOn(String date) => 'Valid until $date';

  @override
  String convertedToSale(int id) => 'Converted to sale #$id';

  @override
  String get lineItemsCopiedNote =>
      'Line items will be copied from the selected sale and its prices kept.';

  @override
  String get noneBuildManually => 'None (build manually)';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String termsLabel(String terms) => 'Terms: $terms';

  @override
  String notesLabel(String notes) => 'Notes: $notes';

  @override
  String get sharePdf => 'Share PDF';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get deleteSaleQuestion => 'Delete sale?';

  @override
  String get deletePurchaseQuestion => 'Delete purchase?';

  @override
  String get deleteInvoiceQuestion => 'Delete invoice?';

  @override
  String get deleteQuotationQuestion => 'Delete quotation?';

  @override
  String get deleteExpenseQuestion => 'Delete expense?';

  @override
  String get deleteIncomeQuestion => 'Delete income?';

  @override
  String get deleteMethodQuestion => 'Delete method?';

  @override
  String get saleDeleteNote =>
      'Stock will be restored and the customer khata reversed.';

  @override
  String get purchaseDeleteNote =>
      'Stock will be reduced back and the supplier khata reversed.';

  @override
  String get expenseDeleteNote => 'This expense will be permanently removed.';

  @override
  String get incomeDeleteNote =>
      'This income record will be permanently removed.';

  @override
  String get invoiceDeleteNote => 'This invoice will be permanently removed.';

  @override
  String get quotationDeleteNote =>
      'This quotation will be permanently removed.';

  @override
  String get searchInvoiceOrCustomer => 'Search invoice or customer';

  @override
  String get searchBillOrSupplier => 'Search bill or supplier';

  @override
  String get searchQuotationOrCustomer => 'Search quotation or customer';

  @override
  String get searchPartyOrReference => 'Search party or reference';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get addMethod => 'Add method';

  @override
  String get noPaymentMethodsYet => 'No payment methods yet';

  @override
  String get setAsDefault => 'Set as default';

  @override
  String get methodChangeNote =>
      'Payments already recorded with this method keep working.';

  @override
  String advanceIs(String amount) => 'Advance $amount';

  @override
  String dueToCustomerKhata(String amount) => 'Due $amount → customer khata';

  @override
  String dueToSupplierKhata(String amount) => 'Due $amount → supplier khata';

  @override
  String get advancesAreMoney =>
      'Advances are money you already hold, so they are applied first.';

  @override
  String advancesLabel(String list) => 'Advances: $list';

  @override
  String get addProductButton => 'Add product';

  @override
  String get addReminderButton => 'Add reminder';

  @override
  String get receivablesAndPayables => 'Receivables & payables';

  @override
  String receivablesCount(int count) => 'Receivables · $count';

  @override
  String payablesCount(int count) => 'Payables · $count';

  @override
  String get profitAndLoss => 'Profit & loss';

  @override
  String get salesReportTitle => 'Sales report';

  @override
  String get revenueExcludesVat => 'Revenue excludes VAT.';

  @override
  String get salesTrendLast14 => 'Sales trend · last 14 days';

  @override
  String salesTrendScope(String scope) => 'Sales trend · $scope';

  @override
  String get topProducts => 'Top products';

  @override
  String get topCustomers => 'Top customers';

  @override
  String get bySource => 'By source';

  @override
  String get incomeTrend => 'Income trend';

  @override
  String get lastCycle => 'Last cycle';

  @override
  String get noDataYet => 'No data yet';

  @override
  String couldNotLoad(String error) => 'Could not load: $error';

  @override
  String get couldNotLoadSummary => 'Could not load summary';

  @override
  String get dashboardUnavailable => 'Dashboard unavailable';

  @override
  String productsCount(int count) => '$count product(s)';

  @override
  String unitsDocsCount(String quantity, int count) =>
      '$quantity units · $count docs';

  @override
  String quantityTimesPrice(String quantity, String price) =>
      '$quantity × $price';

  @override
  String lowStockNote(String name) => '$name low on stock';

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncStatusTitle => 'Sync status';

  @override
  String get lastSyncLabel => 'Last sync';

  @override
  String get pendingChangesCount => 'Pending changes';

  @override
  String syncFailed(String error) => 'Sync failed: $error';

  @override
  String operationFailed(String operation) => '$operation failed';

  @override
  String get conflicts => 'conflicts';

  @override
  String get noConflicts => 'No conflicts';

  @override
  String entityRef(String type, int id) => '$type #$id';

  @override
  String get serverChanged => 'server changed: ';

  @override
  String serverVersion(String json) => 'server version: $json';

  @override
  String operationDetail(String operation) => 'operation: $operation';

  @override
  String get pushed => 'pushed';

  @override
  String get pulled => 'pulled';

  @override
  String rejectedWithError(String error) => 'rejected: $error';

  @override
  String get backupSubject => 'Khata backup';

  @override
  String get backupShareText => 'Khata backup exported from this device.';

  @override
  String recordsAddedCount(int count) => '$count record(s) added';

  @override
  String alreadyPresentCount(int count) => '$count already present, left alone';

  @override
  String addedCount(int count) => '$count added';

  @override
  String addedKeptCount(int count, int kept) => '$count added, $kept kept';

  @override
  String get reminderRepeatNote =>
      'A repeating reminder reschedules itself after firing.';

  @override
  String get profileLabel => 'Profile';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageNepali => 'नेपाली';

  @override
  String get calendarLabel => 'Calendar';

  @override
  String get generalSection => 'General';

  @override
  String get dateLabel => 'Date';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get fromLabel => 'From';

  @override
  String get toLabel => 'To';

  @override
  String get titleRequired => 'Title *';

  @override
  String get sourceRequired => 'Source *';

  @override
  String get taxExample => 'e.g. 13';

  @override
  String get amountExample => 'e.g. 20.00';

  @override
  String get quantityExample16 => 'e.g. 16.00';

  @override
  String get rateExample => 'e.g. 25';

  @override
  String get plusOne => '+1';

  @override
  String get plusTen => '+10';

  @override
  String get minusOne => '-1';

  @override
  String get minusTen => '-10';

  @override
  String get phonePrefixHint => '+977 98XXXXXXXX';

  @override
  String get rankLabel => '#';

  @override
  String editKind(String kind) => 'Edit $kind';

  @override
  String newKind(String kind) => 'New $kind';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get convert => 'Convert';

  @override
  String get exportTitle => 'Export';

  @override
  String get restoreTitle => 'Restore';

  @override
  String get expenseTrend => 'Expense trend';

  @override
  String get opening => 'Opening';

  @override
  String get filterByCategory => 'Filter by category';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get emailMustHaveAccount => 'Email (must have an account)';

  @override
  String get advancesExplainer =>
      'Advances are money you already hold (customer) or have already paid (supplier), so they are applied before new payments.';

  @override
  String get backupExportExplainerFull =>
      'Saves every product, party, sale, purchase, expense, income, payment, invoice and quotation in the active business. Soft-deleted records are kept, so history survives.';

  @override
  String get backupRestoreExplainerFull =>
      'Restoring merges a backup into this business. Records that already exist are skipped — nothing is ever overwritten, because a rewritten sale or payment would leave the khata ledger disagreeing with itself.';

  @override
  String get backupNotIncludedExplainer =>
      'The khata ledger entries and stock movements are derived from the documents above, so they are rebuilt by replaying those operations rather than copied. A restore therefore brings back your records, not the cached totals.';

  @override
  String get restoreConfirmBodyFull =>
      'Records that already exist in this business will be skipped. Nothing currently here is modified or deleted.';

  @override
  String get methodChangeNoteFull =>
      'Payments already recorded with this method keep working. Renaming the method does not rewrite history.';

  @override
  String get saleDeleteNoteFull =>
      'Stock will be restored and the customer khata reversed.';

  @override
  String get purchaseDeleteNoteFull =>
      'Stock will be reduced back and the supplier khata reversed.';

  @override
  String get lineItemsCopiedNoteFull =>
      'Line items will be copied from the selected sale and its prices kept.';

  @override
  String get notificationsInAppNoteFull =>
      'In-app notifications are always recorded. These switches control push delivery only.';

  @override
  String unitNameShort(String name, String short) => '$name ($short)';

  @override
  String retailValue(String amount) => 'retail $amount';

  @override
  String advanceAmount(String amount) => 'Advance $amount';

  @override
  String quantityWithUnit(String quantity, String unit) => '$quantity$unit';

  @override
  String productPricePair(String price) => '$price  •  ';

  @override
  String saleCustomerLine(String number, String customer) =>
      '$number — $customer';

  @override
  String lineTotalAmount(String amount) => 'Line total: $amount';

  @override
  String conflictsCount(int count) => '$count conflicts';

  @override
  String get noDataInRange => 'No data in this range';

  @override
  String get nothingToBreakDown => 'Nothing to break down';

  @override
  String get noProductsMatchFilter => 'No products match this filter';

  @override
  String get noProductsSoldInRange => 'No products sold in this range';

  @override
  String get noSalesToCustomersInRange => 'No sales to customers in this range';

  @override
  String get nobodyOwesYou => 'Nobody owes you money';

  @override
  String get youOweNobody => 'You owe nobody';

  @override
  String addLabel(String label) => 'Add $label';

  @override
  String couldNotLoadX(String subject, String error) =>
      'Could not load $subject.\n$error';

  @override
  String get balances => 'balances';

  @override
  String get expenseReport => 'the expense report';

  @override
  String get incomeReport => 'the income report';

  @override
  String get stockReportTitle => 'the stock report';

  @override
  String get expenseReportTitle => 'Expense report';

  @override
  String get incomeReportTitle => 'Income report';

  @override
  String get profitAndLossTitle => 'Profit & loss';

  @override
  String get stockMovements => 'stock movements';

  @override
  String get devices => 'devices';

  @override
  String emailAndRole(String email, String role) => '$email\n$role';

  @override
  String addKind(String kind) => 'Add $kind';

  @override
  String lowAtOrBelow(String quantity, String unit) =>
      'Low: at or below $quantity$unit';

  @override
  String minimumIs(String quantity, String unit) => 'Minimum $quantity$unit';

  @override
  String savedTo(String path) => 'Saved to $path';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get emailInvalid => 'Please enter a valid email';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get passwordRegisterRequired => 'Please enter a password';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordNeedsDigit => 'Password must contain at least one digit';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get fullNameRequired => 'Please enter your full name';

  @override
  String get fullNameIsRequired => 'Full name is required';

  @override
  String get businessNameIsRequired => 'Business name is required';

  @override
  String get amountRequired => 'Amount is required';

  @override
  String get amountInvalid => 'Enter a valid amount';

  @override
  String get amountInvalidFull => 'Enter a valid amount.';

  @override
  String get amountMustBePositive => 'Amount must be greater than zero.';

  @override
  String get quantityInvalid => 'Enter a valid quantity';

  @override
  String get percentRange => 'Enter 0–100';

  @override
  String get panMustBe9Digits => 'PAN must be 9 digits.';

  @override
  String get panMustBe9DigitNumber => 'PAN must be a 9-digit number';

  @override
  String get phoneInvalid => 'Phone number format is invalid.';

  @override
  String get emailAddressRequired => 'A valid email address is required.';

  @override
  String get invalidEmailOrPassword => 'Invalid email or password.';

  @override
  String get checkYourInput => 'Please check your input.';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get returnIn => 'Return in';

  @override
  String get returnOut => 'Return out';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get day => 'Day';

  @override
  String todayAt(String time) => 'Today $time';

  @override
  String tomorrowAt(String time) => 'Tomorrow $time';

  @override
  String yesterdayAt(String time) => 'Yesterday $time';

  @override
  String noKindMatchSearch(String kind) => 'No $kind match your search';

  @override
  String noKindYet(String kind) => 'No $kind yet';

  @override
  String get categoryReminder => 'Reminder';

  @override
  String get saved => 'Saved';

  @override
  String get productSaved => 'Product saved';

  @override
  String get walkInCustomer => 'Walk-in customer';

  @override
  String get notSet => 'Not set';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get noSupplier => 'No supplier';

  @override
  String get paidInFull => 'Paid (full)';

  @override
  String get exporting => 'Exporting...';

  @override
  String get saving => 'Saving...';

  @override
  String get noLowStockProducts => 'No low-stock products — all good!';

  @override
  String get noProductsMatchSearch => 'No products match your search';

  @override
  String get showingUnread => 'Showing unread';

  @override
  String get customerKhata => 'Customer khata';

  @override
  String get debit => 'Debit';

  @override
  String get recordReceipt => 'Record receipt';

  @override
  String get applyToInvoice => 'Apply to invoice';

  @override
  String get receipt => 'Receipt';

  @override
  String get roleViewer => 'Viewer';

  @override
  String get never => 'Never';

  @override
  String get syncing => 'Syncing…';

  @override
  String moneyInOut(String inAmount, String outAmount) =>
      'In $inAmount · Out $outAmount';

  @override
  String dueAmount(String amount) => 'Due $amount';

  @override
  String get created => 'Created';

  @override
  String get productCreated => 'Product created';

  @override
  String toCollectAmount(String amount) => 'To collect $amount';

  @override
  String toPayAmount(String amount) => 'To pay $amount';

  @override
  String get createProduct => 'Create product';

  @override
  String get create => 'Create';

  @override
  String get noProductsYet => 'No products yet';

  @override
  String get noProductsYetAddFirst =>
      'No products yet — add your first product';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get total => 'Total';

  @override
  String get discount => 'Discount';

  @override
  String get rateRs => 'Rate (Rs.)';

  @override
  String get discountRs => 'Disc (Rs.)';

  @override
  String get addAtLeastOneItem => 'Add at least one item';

  @override
  String get costValue => 'Cost value';

  @override
  String get potentialMargin => 'Potential margin';

  @override
  String get invoiceCreated => 'Invoice created';

  @override
  String get invoiceDeleted => 'Invoice deleted';

  @override
  String get quotationCreated => 'Quotation created';

  @override
  String get quotationDeleted => 'Quotation deleted';

  @override
  String get convertedToSaleToast => 'Converted to sale';

  @override
  String get saleCreated => 'Sale created';

  @override
  String get saleReversed => 'Sale reversed';

  @override
  String get saleKeptAsReversed => 'The sale is kept in history as reversed.';

  @override
  String get creditSaleNeedsCustomer => 'A credit sale needs a customer';

  @override
  String get purchaseCreated => 'Purchase created';

  @override
  String get purchaseReversed => 'Purchase reversed';

  @override
  String get purchaseKeptAsReversed =>
      'The purchase is kept in history as reversed.';

  @override
  String get creditPurchaseNeedsSupplier =>
      'A credit purchase needs a supplier';

  @override
  String get paymentRecorded => 'Payment recorded';

  @override
  String get methodSaved => 'Method saved';

  @override
  String get methodDeleted => 'Method deleted';

  @override
  String get categorySaved => 'Category saved';

  @override
  String get categoryDeleted => 'Category deleted';

  @override
  String get productDeleted => 'Product deleted';

  @override
  String get unitSaved => 'Unit saved';

  @override
  String get unitDeleted => 'Unit deleted';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get atLeastOneMethodMustRemain =>
      'At least one payment method must remain.';

  @override
  String get notAkhataBackup => 'This is not a Khata backup.';

  @override
  String get enterNonZeroQuantity => 'Enter a non-zero quantity';

  @override
  String get enterAmountGreaterThanZero => 'Enter an amount greater than zero';

  @override
  String balanceAfterIs(String quantity) => 'Bal $quantity';

  @override
  String get rejectedAndFailed => 'Rejected & failed';

  @override
  String get entries => 'Entries';

  @override
  String get average => 'Average';

  @override
  String get sources => 'Sources';

  @override
  String get revenue => 'Revenue';

  @override
  String get costOfGoodsSold => 'Cost of goods sold';

  @override
  String get grossProfit => 'Gross profit';

  @override
  String get otherIncome => 'Other income';

  @override
  String get netProfit => 'Net profit';

  @override
  String get taxCollectedInPeriod => 'Tax collected in this period: ';

  @override
  String get customerAdvances => 'Customer advances';

  @override
  String get supplierAdvances => 'Supplier advances';

  @override
  String get advancesExplain =>
      'Advances are money you already hold (customer) or have overpaid (supplier).';

  @override
  String get reportSalesBlurb => 'Trends, totals, top products and customers';

  @override
  String get reportProfitLossBlurb => 'Revenue, cost of goods and net profit';

  @override
  String get reportExpenseBlurb => 'Where the money went, by category';

  @override
  String get reportIncomeBlurb => 'Other income by source';

  @override
  String get reportStockBlurb => 'Cost and retail value of stock on hand';

  @override
  String get reportReceivableBlurb => 'Who owes you and who you owe';

  @override
  String get ledgerOwesYouHint =>
      'Amount they owe you (customer) / you paid (supplier)';

  @override
  String get ledgerYouOweHint =>
      'Amount paid to you (customer) / you owe (supplier)';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleAccountant => 'Accountant';

  @override
  String get noBusiness => 'No business';

  @override
  String couldNotLoadProducts(String error) =>
      'Could not load products.\\n$error';

  @override
  String get lineItemsCopiedFromSale =>
      'Line items will be copied from the selected sale and its invoice number reused.';

  @override
  String bsRange(String from, String to) => 'BS: $from  →  $to';

  @override
  String conflictsNamed(int count) => 'Conflicts ($count)';

  @override
  String get retailValueReport => 'Retail value';

  @override
  String selectPartyKind(String kind) => 'Select a $kind';

  @override
  String get tax => 'Tax';

  @override
  String get qty => 'Qty';

  @override
  String get adjustment => 'Adjustment';

  @override
  String get showingAll => 'Showing all';

  @override
  String get supplierKhata => 'Supplier khata';

  @override
  String get applyToBill => 'Apply to bill';

  @override
  String get newMethod => 'New method';

  @override
  String get today => 'Today';

  @override
  String get municipality => 'Municipality';

  @override
  String get selectProvinceHint => 'Select province';

  @override
  String get selectDistrictHint => 'Select district';

  @override
  String get selectMunicipalityHint => 'Select municipality';

  @override
  String get municipalityFreeTextHint =>
      'Type the municipality — not every local unit is listed here.';

  @override
  String get phoneInvalidNepali =>
      'Enter a valid Nepali phone number, e.g. 98XXXXXXXX';

  @override
  String get fromDate => 'From';

  @override
  String get toDate => 'To';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get endBeforeStart => 'End date cannot be before the start date.';

  @override
  String get dateRange => 'Date range';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get emiCalculator => 'EMI Calculator';

  @override
  String get loanAmount => 'Loan amount (Rs.)';

  @override
  String get annualInterestRate => 'Annual interest rate (%)';

  @override
  String get loanTermMonths => 'Loan term (months)';

  @override
  String get monthlyEmi => 'Monthly EMI';

  @override
  String get totalPayment => 'Total payment';

  @override
  String get totalInterest => 'Total interest';

  @override
  String get interestCalculator => 'Interest Calculator';

  @override
  String get simpleInterest => 'Simple interest';

  @override
  String get compoundInterest => 'Compound interest';

  @override
  String get principal => 'Principal';

  @override
  String get years => 'Years';

  @override
  String get compoundingPerYear => 'Compounding per year';

  @override
  String get interestEarned => 'Interest earned';

  @override
  String get profitCalculator => 'Profit Calculator';

  @override
  String get profit => 'Profit';

  @override
  String get profitMargin => 'Profit margin';

  @override
  String get markup => 'Markup';

  @override
  String get enterValidAmount => 'Enter a valid amount';

  @override
  String get maturityAmount => 'Maturity amount';

  @override
  String get calculate => 'Calculate';

  @override
  String get lossWarning => 'This is a loss, not a profit.';

  @override
  String get appLock => 'App lock';

  @override
  String get appLockDescription => 'Require a PIN to open the app';

  @override
  String get setPin => 'Set PIN';

  @override
  String get changePin => 'Change PIN';

  @override
  String get enterPin => 'Enter your PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get currentPin => 'Current PIN';

  @override
  String get newPin => 'New PIN';

  @override
  String get pinMustBe4To6Digits => 'PIN must be 4 to 6 digits';

  @override
  String get pinsDoNotMatch => 'The PINs do not match';

  @override
  String get incorrectPin => 'Incorrect PIN';

  @override
  String get unlock => 'Unlock';

  @override
  String get turnOffAppLock => 'Turn off app lock';

  @override
  String get appLockNowOn => 'App lock is on';

  @override
  String get appLockNowOff => 'App lock is off';

  @override
  String attemptsLeft(int count) => '$count attempts left';

  @override
  String get bankAccounts => 'Bank accounts';

  @override
  String get bankName => 'Bank name';

  @override
  String get accountName => 'Account name';

  @override
  String get accountNumber => 'Account number';

  @override
  String get branch => 'Branch';

  @override
  String get defaultAccount => 'Default account';

  @override
  String get noBankAccountsYet =>
      'No bank accounts yet. Add one to record transfers.';

  @override
  String get addBankAccount => 'Add bank account';

  @override
  String paymentsThroughAccount(int count, String total) =>
      '$count payments · $total';

  @override
  String get deleted => 'Deleted';

  @override
  String get importTile => 'Import';

  @override
  String get importTitle => 'Import from Excel';

  @override
  String get importExplainerTitle => 'How it works';

  @override
  String get importExplainerBody =>
      'Paste the rows from your spreadsheet here. Copy the template, fill it in Excel, save it as CSV and paste it back. Every row is checked before anything is written — if one row is wrong, nothing is imported.';

  @override
  String get importCopyTemplate => 'Copy template';

  @override
  String get importTemplateCopied => 'Template copied — paste it into Excel';

  @override
  String get importPasteFromClipboard => 'Paste from clipboard';

  @override
  String get importCsvLabel => 'CSV rows';

  @override
  String get importCheckFile => 'Check file';

  @override
  String get importChecking => 'Checking…';

  @override
  String get importRun => 'Import';

  @override
  String get importImporting => 'Importing…';

  @override
  String get importPreviewTitle => 'Check result';

  @override
  String get importRowsTotal => 'Rows';

  @override
  String get importRowsValid => 'Ready';

  @override
  String get importRowsDuplicate => 'Already exist';

  @override
  String get importRowsInvalid => 'Need fixing';

  @override
  String get importBlockedHint =>
      'Nothing will be imported until every row is fixed.';

  @override
  String importIgnoredColumns(String columns) => 'Ignored columns: $columns';

  @override
  String get importIssuesTitle => 'Rows to fix';

  @override
  String importIssueLine(int row, String message) => 'Row $row: $message';

  @override
  String importIssueLineWithColumn(int row, String column, String message) =>
      'Row $row · $column: $message';

  @override
  String importMoreIssues(int count) => '…and $count more';

  @override
  String get importConfirmTitle => 'Import these rows?';

  @override
  String get importConfirmBody =>
      'Rows that already exist are skipped; nothing is overwritten.';

  @override
  String get importCompleteTitle => 'Import complete';

  @override
  String importCreatedCount(int count) => '$count record(s) created';

  @override
  String importSkippedCount(int count) =>
      '$count already existed and were skipped';

  @override
  String get importRejected =>
      'Nothing was imported — fix the rows below and try again.';

  @override
  String get importClear => 'Clear';

  @override
  String get importExpectedColumns => 'Expected columns';

  @override
  String get cachedDataNote => 'Showing saved data. Reconnect to refresh.';

  @override
  String cachedDataNoteAt(String time) =>
      'Showing saved data from $time. Reconnect to refresh.';

  @override
  String get offlineDataTitle => 'Offline data';

  @override
  String get offlineDataExplainer =>
      'Lists you open are saved on this device, so they still open when the internet is down.';

  @override
  String get offlineDataSavedLabel => 'Saved lists';

  @override
  String offlineDataSavedCount(int lists, String size) =>
      '$lists list(s) · $size';

  @override
  String get offlineDataClear => 'Clear saved data';

  @override
  String get offlineDataClearConfirm =>
      'Delete the saved lists? They will be downloaded again the next time you open them.';

  @override
  String get offlineDataCleared => 'Saved data cleared';

  @override
  String loadMoreRemaining(int count) => 'Load more ($count remaining)';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get pageNotFoundBody =>
      'This page is not available. It may have been moved, or the link may be wrong.';

  @override
  String get fileSaveNotSupported =>
      'Saving and sharing files needs the app on a phone — the browser version cannot write files.';

  @override
  String get savedOffline => 'Saved offline — it will sync when you reconnect.';

  @override
  String get offlineBannerNote =>
      'Offline — changes will sync when you\'re back';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get calendarAd => 'AD (English date)';

  @override
  String get calendarBs => 'BS (Bikram Sambat)';

  @override
  String get calendarNote => 'Dates are shown and picked in this calendar.';

  @override
  String pendingWritesCount(int count) => '$count waiting';

  @override
  String get navHome => 'Home';

  @override
  String get navParties => 'Parties';

  @override
  String get navItems => 'Items';

  @override
  String monthToDate(String amount) => 'This month $amount';

  @override
  String lowStockCountLabel(int count) => '$count low on stock';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get viewAll => 'View all';

  @override
  String get getStartedTitle => 'Get started';

  @override
  String get getStartedStepProduct => 'Add your first product';

  @override
  String get getStartedStepCustomer => 'Add a customer';

  @override
  String get getStartedStepSale => 'Record your first sale';

  @override
  String get shareReminder => 'Share reminder';

  @override
  String reminderShareMessage(String name, String business, String amount) =>
      'Namaste $name, your balance at $business is $amount. Please settle it when convenient. Thank you.';

  @override
  String get moreSalesDocs => 'Sales & documents';

  @override
  String get moreItems => 'Items & stock';

  @override
  String get moreInsights => 'Insights';

  @override
  String get moreTools => 'Tools & settings';

  @override
  String get moreAccount => 'Account';

  @override
  String balanceShort(String amount) => 'bal $amount';

  @override
  String get moreActions => 'More actions';

  @override
  String get welcomeChooseLanguage => 'Choose your language';

  @override
  String get welcomeSkip => 'Skip';

  @override
  String get welcomeSlide1Title => 'A khata that never forgets';

  @override
  String get welcomeSlide1Body =>
      'Every credit sale, every payment and every balance — written once, always correct.';

  @override
  String get welcomeSlide2Title => 'Stock that counts itself';

  @override
  String get welcomeSlide2Body =>
      'Sales and purchases move stock automatically, and you are warned before an item runs out.';

  @override
  String get welcomeSlide3Title => 'Numbers you can act on';

  @override
  String get welcomeSlide3Body =>
      'Daily profit, what to collect and what to pay — in AD or BS dates, in your language.';

  @override
  String get tryDemo => 'Try the demo';

  @override
  String get updateTitle => 'Update available';

  @override
  String updateBody(String current, String latest) =>
      'You have version $current. Version $latest is ready to install.';

  @override
  String updateSize(String size) => 'Download size: $size';

  @override
  String get updateNotesLabel => 'What\'s new';

  @override
  String get updateDownload => 'Download';

  @override
  String get updateLater => 'Later';

  @override
  String get updateLinkFailed => 'Could not open the download link.';

}

/// The translations for hi.
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi() : super('hi');

  @override
  String get appName => 'डिजिटल खाता';

  @override
  String get login => 'साइन इन करें';

  @override
  String get register => 'साइन अप करें';

  @override
  String get email => 'ईमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get phoneNumber => 'फ़ोन नंबर';

  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get createAccount => 'खाता बनाएँ';

  @override
  String get alreadyHaveAccount => 'पहले से खाता है? साइन इन करें';

  @override
  String get dontHaveAccount => 'खाता नहीं है? साइन अप करें';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get transactions => 'लेन-देन';

  @override
  String get khata => 'खाता';

  @override
  String get reports => 'रिपोर्ट';

  @override
  String get more => 'और';

  @override
  String get todaysSales => 'आज की बिक्री';

  @override
  String get todaysPurchases => 'आज की खरीद';

  @override
  String get todaysExpenses => 'आज का खर्च';

  @override
  String get todaysProfit => 'आज का लाभ';

  @override
  String get totalReceivable => 'कुल लेना है';

  @override
  String get totalPayable => 'कुल देना है';

  @override
  String get stockValue => 'स्टॉक का मूल्य';

  @override
  String get lowStock => 'कम स्टॉक';

  @override
  String get syncNow => 'अभी सिंक करें';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get createBusiness => 'व्यवसाय बनाएँ';

  @override
  String get businessSetupTitle => 'अपना व्यवसाय सेट करें';

  @override
  String get businessSetupSubtitle => 'आप पूर्ण अधिकार के साथ मालिक होंगे।';

  @override
  String get businessName => 'व्यवसाय का नाम';

  @override
  String get businessType => 'व्यवसाय का प्रकार (जैसे खुदरा)';

  @override
  String get panNumber => 'पैन नंबर';

  @override
  String get businessEmail => 'व्यवसाय का ईमेल';

  @override
  String get address => 'पता';

  @override
  String get city => 'शहर';

  @override
  String get district => 'ज़िला';

  @override
  String get province => 'प्रांत';

  @override
  String get wardNumber => 'वार्ड नंबर';

  @override
  String get myBusinesses => 'मेरे व्यवसाय';

  @override
  String get switchBusiness => 'व्यवसाय बदलें';

  @override
  String get active => 'सक्रिय';

  @override
  String get noBusinesses => 'अभी कोई व्यवसाय नहीं';

  @override
  String get createFirstBusiness => 'अपना पहला व्यवसाय बनाएँ';

  @override
  String get staff => 'स्टाफ़';

  @override
  String get invite => 'आमंत्रित करें';

  @override
  String get inviteMember => 'स्टाफ़ सदस्य को आमंत्रित करें';

  @override
  String get changeRole => 'भूमिका बदलें';

  @override
  String get remove => 'हटाएँ';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get saveChanges => 'बदलाव सहेजें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get language => 'भाषा';

  @override
  String get retry => 'फिर कोशिश करें';

  @override
  String get loading => 'लोड हो रहा है';

  @override
  String get products => 'उत्पाद';

  @override
  String get product => 'उत्पाद';

  @override
  String get addProduct => 'उत्पाद जोड़ें';

  @override
  String get editProduct => 'उत्पाद संपादित करें';

  @override
  String get newProduct => 'नया उत्पाद';

  @override
  String get productName => 'उत्पाद का नाम';

  @override
  String get sku => 'एसकेयू';

  @override
  String get barcode => 'बारकोड';

  @override
  String get categories => 'श्रेणियाँ';

  @override
  String get addCategory => 'श्रेणी जोड़ें';

  @override
  String get newCategory => 'नई श्रेणी';

  @override
  String get category => 'श्रेणी';

  @override
  String get units => 'इकाइयाँ';

  @override
  String get addUnit => 'इकाई जोड़ें';

  @override
  String get newUnit => 'नई इकाई';

  @override
  String get unit => 'इकाई';

  @override
  String get costPrice => 'लागत मूल्य';

  @override
  String get sellingPrice => 'बिक्री मूल्य';

  @override
  String get wholesalePrice => 'थोक मूल्य';

  @override
  String get taxRate => 'कर दर';

  @override
  String get openingStock => 'प्रारंभिक स्टॉक';

  @override
  String get minQuantity => 'कम स्टॉक चेतावनी';

  @override
  String get inventory => 'भंडार';

  @override
  String get adjustStock => 'स्टॉक समायोजित करें';

  @override
  String get stockHistory => 'स्टॉक इतिहास';

  @override
  String get quickAdjust => 'त्वरित समायोजन';

  @override
  String get customQuantity => 'अपनी मात्रा';

  @override
  String get notes => 'टिप्पणियाँ';

  @override
  String get applyAdjustment => 'समायोजन लागू करें';

  @override
  String get lowStockOnly => 'केवल कम स्टॉक';

  @override
  String get sortByName => 'नाम से क्रमबद्ध करें';

  @override
  String get sortByQuantity => 'मात्रा से क्रमबद्ध करें';

  @override
  String get searchProducts => 'उत्पाद खोजें';

  @override
  String get inStock => 'स्टॉक में';

  @override
  String get lowStockAlert => 'कम स्टॉक';

  @override
  String get stockAdded => 'स्टॉक जोड़ा गया';

  @override
  String get stockRemoved => 'स्टॉक हटाया गया';

  @override
  String get customers => 'ग्राहक';

  @override
  String get customer => 'ग्राहक';

  @override
  String get addCustomer => 'ग्राहक जोड़ें';

  @override
  String get newCustomer => 'नया ग्राहक';

  @override
  String get editCustomer => 'ग्राहक संपादित करें';

  @override
  String get searchCustomers => 'ग्राहक खोजें';

  @override
  String get suppliers => 'आपूर्तिकर्ता';

  @override
  String get supplier => 'आपूर्तिकर्ता';

  @override
  String get addSupplier => 'आपूर्तिकर्ता जोड़ें';

  @override
  String get newSupplier => 'नया आपूर्तिकर्ता';

  @override
  String get editSupplier => 'आपूर्तिकर्ता संपादित करें';

  @override
  String get searchSuppliers => 'आपूर्तिकर्ता खोजें';

  @override
  String get searchPartyHint => 'नाम या फ़ोन खोजें';

  @override
  String get ledger => 'खाता बही';

  @override
  String get openingBalance => 'प्रारंभिक शेष';

  @override
  String get creditLimit => 'उधार सीमा';

  @override
  String get creditLimitOptional => 'उधार सीमा (वैकल्पिक)';

  @override
  String get closingBalance => 'अंतिम शेष';

  @override
  String get totalDebit => 'कुल नामे';

  @override
  String get totalCredit => 'कुल जमा';

  @override
  String get toCollect => 'लेना है';

  @override
  String get toPay => 'देना है';

  @override
  String get advance => 'अग्रिम';

  @override
  String get settled => 'चुकता';

  @override
  String get noCustomers => 'अभी कोई ग्राहक नहीं';

  @override
  String get noSuppliers => 'अभी कोई आपूर्तिकर्ता नहीं';

  @override
  String get noTransactions => 'अभी कोई लेन-देन नहीं';

  @override
  String get partyDeleted => 'हटा दिया गया';

  @override
  String get deletePartyTitle => 'पक्षकार हटाएँ?';

  @override
  String get sales => 'बिक्री';

  @override
  String get sale => 'बिक्री';

  @override
  String get newSale => 'नई बिक्री';

  @override
  String get purchases => 'खरीद';

  @override
  String get purchase => 'खरीद';

  @override
  String get newPurchase => 'नई खरीद';

  @override
  String get expenses => 'खर्च';

  @override
  String get expense => 'खर्च';

  @override
  String get addExpense => 'खर्च जोड़ें';

  @override
  String get income => 'आय';

  @override
  String get addIncome => 'आय जोड़ें';

  @override
  String get invoiceNumber => 'इनवॉइस नंबर';

  @override
  String get billNumber => 'बिल नंबर';

  @override
  String get saleType => 'बिक्री का प्रकार';

  @override
  String get paymentStatus => 'भुगतान स्थिति';

  @override
  String get paid => 'भुगतान हुआ';

  @override
  String get due => 'बकाया';

  @override
  String get addItem => 'वस्तु जोड़ें';

  @override
  String get searchSales => 'बिक्री खोजें';

  @override
  String get searchPurchases => 'खरीद खोजें';

  @override
  String get searchExpenses => 'खर्च खोजें';

  @override
  String get searchIncome => 'आय खोजें';

  @override
  String get walkIn => 'सीधा ग्राहक';

  @override
  String get cash => 'नकद';

  @override
  String get credit => 'उधार';

  @override
  String get partial => 'आंशिक';

  @override
  String get noSales => 'अभी कोई बिक्री नहीं';

  @override
  String get noPurchases => 'अभी कोई खरीद नहीं';

  @override
  String get noExpenses => 'अभी कोई खर्च नहीं';

  @override
  String get noIncome => 'अभी कोई आय नहीं';

  @override
  String get payments => 'भुगतान';

  @override
  String get payment => 'भुगतान';

  @override
  String get recordPayment => 'भुगतान दर्ज करें';

  @override
  String get paymentMethods => 'भुगतान के तरीके';

  @override
  String get addPaymentMethod => 'तरीका जोड़ें';

  @override
  String get receive => 'प्राप्त करें';

  @override
  String get pay => 'भुगतान करें';

  @override
  String get method => 'तरीका';

  @override
  String get defaultLabel => 'डिफ़ॉल्ट';

  @override
  String get reference => 'संदर्भ';

  @override
  String get noPayments => 'अभी कोई भुगतान नहीं';

  @override
  String get onAccount => 'कोई नहीं (खाते में)';

  @override
  String get applyToDocument => 'इनवॉइस/बिल पर लागू करें';

  @override
  String get advances => 'अग्रिम';

  @override
  String get inactive => 'निष्क्रिय';

  @override
  String get invoices => 'इनवॉइस';

  @override
  String get invoice => 'इनवॉइस';

  @override
  String get newInvoice => 'नया इनवॉइस';

  @override
  String get quotations => 'कोटेशन';

  @override
  String get quotation => 'कोटेशन';

  @override
  String get newQuotation => 'नया कोटेशन';

  @override
  String get issueDate => 'जारी करने की तारीख़';

  @override
  String get dueDate => 'देय तिथि';

  @override
  String get validUntil => 'मान्य तारीख़ तक';

  @override
  String get terms => 'शर्तें';

  @override
  String get share => 'साझा करें';

  @override
  String get downloadPdf => 'PDF डाउनलोड करें';

  @override
  String get convertToSale => 'बिक्री में बदलें';

  @override
  String get status => 'स्थिति';

  @override
  String get draft => 'ड्राफ़्ट';

  @override
  String get sent => 'भेजा गया';

  @override
  String get accepted => 'स्वीकृत';

  @override
  String get rejected => 'अस्वीकृत';

  @override
  String get expired => 'समाप्त';

  @override
  String get overdue => 'अतिदेय';

  @override
  String get noInvoices => 'अभी कोई इनवॉइस नहीं';

  @override
  String get noQuotations => 'अभी कोई कोटेशन नहीं';

  @override
  String get generateFromSale => 'बिक्री से बनाएँ';

  @override
  String fromSale(String number) => 'बिक्री से';

  @override
  String get notifications => 'सूचनाएँ';

  @override
  String get notificationSettings => 'सूचना सेटिंग्स';

  @override
  String get noNotifications => 'अभी कोई सूचना नहीं';

  @override
  String get nothingMatchesFilter => 'इस फ़िल्टर से कुछ मेल नहीं खाता';

  @override
  String get markAllRead => 'सभी पढ़े हुए चिह्नित करें';

  @override
  String get markRead => 'पढ़ा हुआ चिह्नित करें';

  @override
  String markedReadCount(int count) => '$count पढ़े हुए चिह्नित';

  @override
  String get nothingToMark => 'चिह्नित करने के लिए कुछ नहीं';

  @override
  String get filterAllCategories => 'सभी श्रेणियाँ';

  @override
  String get pushNotifications => 'पुश सूचनाएँ';

  @override
  String get enablePush => 'पुश चालू करें';

  @override
  String get enablePushSubtitle => 'इस डिवाइस के लिए मुख्य स्विच';

  @override
  String get notificationsInAppNote =>
      'ऐप में सूचनाएँ हमेशा दर्ज होती हैं। ये स्विच केवल पुश डिलीवरी नियंत्रित करते हैं।';

  @override
  String get registeredDevices => 'पंजीकृत डिवाइस';

  @override
  String get noDevices => 'अभी कोई डिवाइस पंजीकृत नहीं';

  @override
  String get deviceActive => 'सक्रिय';

  @override
  String get deviceInactive => 'निष्क्रिय';

  @override
  String get categoryReminders => 'रिमाइंडर';

  @override
  String get categoryRemindersSubtitle => 'जब कोई रिमाइंडर देय हो';

  @override
  String get categoryLowStock => 'कम स्टॉक';

  @override
  String get categoryLowStockSubtitle => 'जब कोई उत्पाद न्यूनतम तक पहुँचे';

  @override
  String get categoryPaymentDue => 'भुगतान देय';

  @override
  String get categoryPaymentDueSubtitle =>
      'जब कोई बिल देय तिथि के पास या पार हो';

  @override
  String get categoryBackup => 'बैकअप';

  @override
  String get categoryBackupSubtitle => 'बैकअप पूरा हुआ या विफल';

  @override
  String get categorySystem => 'सिस्टम';

  @override
  String get categorySystemSubtitle => 'खाता और ऐप की घोषणाएँ';

  @override
  String get reminders => 'रिमाइंडर';

  @override
  String get newReminder => 'नया रिमाइंडर';

  @override
  String get editReminder => 'रिमाइंडर संपादित करें';

  @override
  String get noReminders => 'यहाँ कुछ नहीं';

  @override
  String get needsAttention => 'ध्यान चाहिए';

  @override
  String get scheduled => 'निर्धारित';

  @override
  String get addReminder => 'रिमाइंडर जोड़ें';

  @override
  String get reminderTitle => 'शीर्षक';

  @override
  String get reminderTitleHint => 'बकाया बिल के बारे में राम को फ़ोन करें';

  @override
  String get reminderTitleRequired => 'शीर्षक आवश्यक है';

  @override
  String get dueTime => 'देय समय';

  @override
  String get repeat => 'दोहराएँ';

  @override
  String get repeatOnce => 'एक बार';

  @override
  String get repeatDaily => 'हर दिन';

  @override
  String get repeatWeekly => 'हर हफ़्ते';

  @override
  String get repeatMonthly => 'हर महीने';

  @override
  String get repeatYearly => 'हर साल';

  @override
  String get recurringNote =>
      'दोहराने वाला रिमाइंडर चलने के बाद पूरा होने के बजाय खुद को फिर से निर्धारित करता है, इसलिए वह हमेशा अगली आने वाली तारीख़ पर आता है।';

  @override
  String get saveReminder => 'रिमाइंडर सहेजें';

  @override
  String get reminderSaved => 'रिमाइंडर सहेजा गया';

  @override
  String get markDone => 'पूर्ण चिह्नित करें';

  @override
  String get dismiss => 'खारिज करें';

  @override
  String get markedDone => 'पूर्ण चिह्नित';

  @override
  String get checkDueReminders => 'देय रिमाइंडर जाँचें';

  @override
  String get nothingDue => 'अभी कुछ भी देय नहीं';

  @override
  String remindersFiredCount(int count) => '$count रिमाइंडर चले';

  @override
  String get dueToday => 'आज';

  @override
  String get dueTomorrow => 'कल';

  @override
  String get dueYesterday => 'बीता कल';

  @override
  String get reminderStatusPending => 'लंबित';

  @override
  String get reminderStatusDone => 'पूर्ण';

  @override
  String get reminderStatusDismissed => 'खारिज';

  @override
  String get backupAndRestore => 'बैकअप और पुनर्स्थापना';

  @override
  String get exportBackup => 'बैकअप निर्यात करें';

  @override
  String get restoreFromLastExport => 'पिछले निर्यात से पुनर्स्थापित करें';

  @override
  String get restoreFromPastedJson => 'चिपकाए गए JSON से पुनर्स्थापित करें';

  @override
  String get backupExportBody =>
      'सक्रिय व्यवसाय के हर उत्पाद, पक्षकार, बिक्री, खरीद, खर्च, आय, भुगतान, इनवॉइस और कोटेशन को सहेजता है। नरम रूप से हटाए गए रिकॉर्ड भी रखे जाते हैं, ताकि इतिहास बचा रहे।';

  @override
  String get backupRestoreBody =>
      'पुनर्स्थापना बैकअप को इस व्यवसाय में मिलाती है। जो रिकॉर्ड पहले से हैं वे छोड़ दिए जाते हैं — कुछ भी अधिलेखित नहीं होता, क्योंकि बदली हुई बिक्री या भुगतान से खाता बही आपस में मेल नहीं खाती।';

  @override
  String get backupNotIncludedTitle => 'क्या शामिल नहीं है';

  @override
  String get backupNotIncludedBody =>
      'खाता बही की प्रविष्टियाँ और स्टॉक मूवमेंट ऊपर दिए दस्तावेज़ों से बनते हैं, इसलिए वे उन क्रियाओं को दोबारा चलाकर बनाए जाते हैं, कॉपी नहीं किए जाते। इसलिए पुनर्स्थापना आपके रिकॉर्ड लौटाती है, कैश किए गए जोड़ नहीं।';

  @override
  String get restoreConfirmTitle => 'यह बैकअप पुनर्स्थापित करें?';

  @override
  String get restoreConfirmBody =>
      'इस व्यवसाय में पहले से मौजूद रिकॉर्ड छोड़ दिए जाएँगे। यहाँ मौजूद कुछ भी बदला या हटाया नहीं जाएगा।';

  @override
  String get restoreComplete => 'पुनर्स्थापना पूर्ण';

  @override
  String restoreAddedCount(int count) => '$count रिकॉर्ड जोड़े गए';

  @override
  String restoreSkippedCount(int count) => '$count पहले से मौजूद, छोड़े गए';

  @override
  String recordsAdded(int count) => '$count जोड़े गए';

  @override
  String recordsAddedKept(int count, int kept) =>
      '$count जोड़े गए, $kept रखे गए';

  @override
  String get clipboardEmpty => 'क्लिपबोर्ड खाली है';

  @override
  String get notAKhataBackup => 'यह फ़ाइल खाता बैकअप नहीं है।';

  @override
  String get save => 'सहेजें';

  @override
  String get change => 'बदलें';

  @override
  String get all => 'सभी';

  @override
  String get none => 'कोई नहीं';

  @override
  String get code => 'कोड';

  @override
  String get role => 'भूमिका';

  @override
  String get filter => 'फ़िल्टर';

  @override
  String get sort => 'क्रमबद्ध करें';

  @override
  String get optional => 'वैकल्पिक';

  @override
  String get pendingChanges => 'लंबित बदलाव';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get close => 'बंद करें';

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String get signInToYourAccount => 'अपने खाते में साइन इन करें';

  @override
  String get createYourAccountTitle => 'अपना डिजिटल खाता बनाएँ';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get fullNamePlaceholder => 'पूरा नाम';

  @override
  String get phoneNumberPlaceholder => 'फ़ोन नंबर';

  @override
  String get phoneOptional => 'फ़ोन नंबर (वैकल्पिक)';

  @override
  String get pan => 'पैन';

  @override
  String get businessNameRequired => 'व्यवसाय का नाम *';

  @override
  String get createNewBusiness => 'नया व्यवसाय बनाएँ';

  @override
  String get businesses => 'व्यवसाय';

  @override
  String couldNotCreateBusiness(String error) =>
      'व्यवसाय नहीं बनाया जा सका: $error';

  @override
  String couldNotSwitchBusiness(String error) =>
      'व्यवसाय नहीं बदला जा सका: $error';

  @override
  String couldNotUpdateProfile(String error) =>
      'प्रोफ़ाइल अपडेट नहीं हो सकी: $error';

  @override
  String get profileUpdated => 'प्रोफ़ाइल अपडेट हुई';

  @override
  String changeRoleFor(String name) => 'भूमिका बदलें — $name';

  @override
  String couldNotChangeRole(String error) => 'भूमिका नहीं बदली जा सकी: $error';

  @override
  String removeMember(String name) => '$name को हटाएँ?';

  @override
  String get removeMemberWarning => 'उनकी इस व्यवसाय तक पहुँच समाप्त हो जाएगी।';

  @override
  String couldNotRemoveMember(String error) =>
      'सदस्य नहीं हटाया जा सका: $error';

  @override
  String inviteFailed(String error) => 'आमंत्रण विफल: $error';

  @override
  String get noStaffMembersYet => 'अभी कोई स्टाफ़ सदस्य नहीं';

  @override
  String get productNameRequired => 'उत्पाद का नाम *';

  @override
  String get searchNameSkuBarcode => 'नाम, एसकेयू या बारकोड खोजें';

  @override
  String get noProductsFound => 'कोई उत्पाद नहीं मिला';

  @override
  String get costPriceRs => 'लागत मूल्य (रु.)';

  @override
  String get sellingPriceRsRequired => 'बिक्री मूल्य (रु.) *';

  @override
  String get wholesalePriceRs => 'थोक मूल्य (रु.)';

  @override
  String get taxRatePercent => 'कर दर (%)';

  @override
  String get openingStockQuantity => 'प्रारंभिक स्टॉक मात्रा';

  @override
  String get minimumQuantityHint => 'न्यूनतम मात्रा (0 = कोई चेतावनी नहीं)';

  @override
  String get inactiveProductsNote =>
      'निष्क्रिय उत्पाद रहते हैं पर बिक्री में नहीं दिखते';

  @override
  String get deleteProductQuestion => 'उत्पाद हटाएँ?';

  @override
  String get deleteProductWarning =>
      'उत्पाद कैटलॉग से छिप जाएगा। स्टॉक इतिहास सुरक्षित रहेगा।';

  @override
  String get loadingProduct => 'उत्पाद लोड हो रहा है…';

  @override
  String couldNotLoadProduct(String error) => 'उत्पाद लोड नहीं हो सका: $error';

  @override
  String get byCategory => 'श्रेणी के अनुसार';

  @override
  String get expensesByCategory => 'श्रेणी के अनुसार खर्च';

  @override
  String get categoriesNoCategories => 'अभी कोई श्रेणी नहीं';

  @override
  String get noCategory => 'कोई श्रेणी नहीं';

  @override
  String get deleteCategoryQuestion => 'श्रेणी हटाएँ?';

  @override
  String get categoryDeleteNote =>
      'इस श्रेणी के उत्पाद बिना श्रेणी के भी काम करते रहेंगे।';

  @override
  String get categoryRequired => 'श्रेणी *';

  @override
  String get noUnit => 'कोई इकाई नहीं';

  @override
  String get unitNameHint => 'नाम * (जैसे पीस)';

  @override
  String get unitShortHint => 'संक्षिप्त नाम * (जैसे pc)';

  @override
  String get unitsNoUnits => 'अभी कोई इकाई नहीं';

  @override
  String get deleteUnitQuestion => 'इकाई हटाएँ?';

  @override
  String get unitDeleteNote =>
      'इस इकाई वाले उत्पाद बिना इकाई के भी काम करते रहेंगे।';

  @override
  String get movementHistory => 'मूवमेंट इतिहास';

  @override
  String get noStockMovementsYet => 'अभी कोई स्टॉक मूवमेंट नहीं';

  @override
  String get customQuantityHint => 'अपनी मात्रा (+ अंदर / - बाहर)';

  @override
  String get quantityExample => 'जैसे 2.5 या -3';

  @override
  String get reasonExample => 'जैसे स्टॉक गणना, नुकसान';

  @override
  String get stockValuation => 'स्टॉक मूल्यांकन';

  @override
  String currentStockIs(String quantity) => 'वर्तमान स्टॉक: $quantity';

  @override
  String balanceIs(String quantity) => 'शेष $quantity';

  @override
  String get nameRequired => 'नाम *';

  @override
  String get partyNameExample => 'नाम * (जैसे राम बहादुर)';

  @override
  String get creditLimitRs => 'उधार सीमा (रु.)';

  @override
  String get openingBalanceRs => 'प्रारंभिक शेष (रु.)';

  @override
  String get walkInNone => 'सीधा ग्राहक / कोई नहीं';

  @override
  String deletePartyQuestion(String kind) => '$kind हटाएँ?';

  @override
  String get partyDeleteNote =>
      'पक्षकार सूचियों से छिप जाएगा। खाता इतिहास सुरक्षित रहेगा।';

  @override
  String get khataHistoryKept => 'खाता इतिहास सुरक्षित रहेगा।';

  @override
  String get createSale => 'बिक्री बनाएँ';

  @override
  String get createPurchase => 'खरीद बनाएँ';

  @override
  String get createInvoice => 'इनवॉइस बनाएँ';

  @override
  String get createQuotation => 'कोटेशन बनाएँ';

  @override
  String get noItemsYetAddProduct => 'अभी कोई वस्तु नहीं — उत्पाद जोड़ें';

  @override
  String get addFreeText => 'मुक्त पाठ जोड़ें';

  @override
  String get items => 'वस्तुएँ';

  @override
  String itemsCount(int count) => 'वस्तुएँ ($count)';

  @override
  String get extraDiscountRs => 'अतिरिक्त छूट (रु.)';

  @override
  String get paidNowRs => 'अभी भुगतान (रु.)';

  @override
  String get paidAmountRs => 'भुगतान राशि (रु.)';

  @override
  String get amountRsRequired => 'राशि (रु.) *';

  @override
  String lineTotalIs(String total) => 'पंक्ति कुल: $total';

  @override
  String invoiceNumberLabel(String number) => 'इनवॉइस $number';

  @override
  String quotationNumberLabel(String number) => 'कोटेशन $number';

  @override
  String issuedOn(String date) => 'जारी $date';

  @override
  String dueOn(String date) => 'देय $date';

  @override
  String validUntilOn(String date) => '$date तक मान्य';

  @override
  String convertedToSale(int id) => 'बिक्री #$id में बदला गया';

  @override
  String get lineItemsCopiedNote =>
      'वस्तुएँ चुनी गई बिक्री से कॉपी होंगी और उनके दाम वही रहेंगे।';

  @override
  String get noneBuildManually => 'कोई नहीं (खुद बनाएँ)';

  @override
  String get notesOptional => 'टिप्पणियाँ (वैकल्पिक)';

  @override
  String termsLabel(String terms) => 'शर्तें: $terms';

  @override
  String notesLabel(String notes) => 'टिप्पणियाँ: $notes';

  @override
  String get sharePdf => 'PDF साझा करें';

  @override
  String get exportCsv => 'CSV निर्यात करें';

  @override
  String get deleteSaleQuestion => 'बिक्री हटाएँ?';

  @override
  String get deletePurchaseQuestion => 'खरीद हटाएँ?';

  @override
  String get deleteInvoiceQuestion => 'इनवॉइस हटाएँ?';

  @override
  String get deleteQuotationQuestion => 'कोटेशन हटाएँ?';

  @override
  String get deleteExpenseQuestion => 'खर्च हटाएँ?';

  @override
  String get deleteIncomeQuestion => 'आय हटाएँ?';

  @override
  String get deleteMethodQuestion => 'तरीका हटाएँ?';

  @override
  String get saleDeleteNote =>
      'स्टॉक लौटाया जाएगा और ग्राहक का खाता उलटा किया जाएगा।';

  @override
  String get purchaseDeleteNote =>
      'स्टॉक घटाया जाएगा और आपूर्तिकर्ता का खाता उलटा किया जाएगा।';

  @override
  String get expenseDeleteNote => 'यह खर्च स्थायी रूप से हट जाएगा।';

  @override
  String get incomeDeleteNote => 'यह आय प्रविष्टि स्थायी रूप से हट जाएगी।';

  @override
  String get invoiceDeleteNote => 'यह इनवॉइस स्थायी रूप से हट जाएगा।';

  @override
  String get quotationDeleteNote => 'यह कोटेशन स्थायी रूप से हट जाएगा।';

  @override
  String get searchInvoiceOrCustomer => 'इनवॉइस या ग्राहक खोजें';

  @override
  String get searchBillOrSupplier => 'बिल या आपूर्तिकर्ता खोजें';

  @override
  String get searchQuotationOrCustomer => 'कोटेशन या ग्राहक खोजें';

  @override
  String get searchPartyOrReference => 'पक्षकार या संदर्भ खोजें';

  @override
  String get paymentMethod => 'भुगतान का तरीका';

  @override
  String get addMethod => 'तरीका जोड़ें';

  @override
  String get noPaymentMethodsYet => 'अभी कोई भुगतान तरीका नहीं';

  @override
  String get setAsDefault => 'डिफ़ॉल्ट बनाएँ';

  @override
  String get methodChangeNote =>
      'इस तरीके से पहले दर्ज भुगतान काम करते रहेंगे।';

  @override
  String advanceIs(String amount) => 'अग्रिम $amount';

  @override
  String dueToCustomerKhata(String amount) => 'बकाया $amount → ग्राहक खाता';

  @override
  String dueToSupplierKhata(String amount) =>
      'बकाया $amount → आपूर्तिकर्ता खाता';

  @override
  String get advancesAreMoney =>
      'अग्रिम वह पैसा है जो आपके पास पहले से है, इसलिए वह पहले लगाया जाता है।';

  @override
  String advancesLabel(String list) => 'अग्रिम: $list';

  @override
  String get addProductButton => 'उत्पाद जोड़ें';

  @override
  String get addReminderButton => 'रिमाइंडर जोड़ें';

  @override
  String get receivablesAndPayables => 'लेना और देना';

  @override
  String receivablesCount(int count) => 'लेना · $count';

  @override
  String payablesCount(int count) => 'देना · $count';

  @override
  String get profitAndLoss => 'लाभ और हानि';

  @override
  String get salesReportTitle => 'बिक्री रिपोर्ट';

  @override
  String get revenueExcludesVat => 'राजस्व में VAT शामिल नहीं है।';

  @override
  String get salesTrendLast14 => 'बिक्री रुझान · पिछले 14 दिन';

  @override
  String salesTrendScope(String scope) => 'बिक्री रुझान · $scope';

  @override
  String get topProducts => 'सर्वाधिक उत्पाद';

  @override
  String get topCustomers => 'सर्वाधिक ग्राहक';

  @override
  String get bySource => 'स्रोत के अनुसार';

  @override
  String get incomeTrend => 'आय रुझान';

  @override
  String get lastCycle => 'पिछला चक्र';

  @override
  String get noDataYet => 'अभी कोई डेटा नहीं';

  @override
  String couldNotLoad(String error) => 'लोड नहीं हो सका: $error';

  @override
  String get couldNotLoadSummary => 'सारांश लोड नहीं हो सका';

  @override
  String get dashboardUnavailable => 'डैशबोर्ड उपलब्ध नहीं';

  @override
  String productsCount(int count) => '$count उत्पाद';

  @override
  String unitsDocsCount(String quantity, int count) =>
      '$quantity इकाई · $count दस्तावेज़';

  @override
  String quantityTimesPrice(String quantity, String price) =>
      '$quantity × $price';

  @override
  String lowStockNote(String name) => '$name का स्टॉक कम है';

  @override
  String get syncTitle => 'सिंक';

  @override
  String get syncStatusTitle => 'सिंक स्थिति';

  @override
  String get lastSyncLabel => 'पिछला सिंक';

  @override
  String get pendingChangesCount => 'लंबित बदलाव';

  @override
  String syncFailed(String error) => 'सिंक विफल: $error';

  @override
  String operationFailed(String operation) => '$operation विफल';

  @override
  String get conflicts => 'टकराव';

  @override
  String get noConflicts => 'कोई टकराव नहीं';

  @override
  String entityRef(String type, int id) => '$type #$id';

  @override
  String get serverChanged => 'सर्वर पर बदला: ';

  @override
  String serverVersion(String json) => 'सर्वर संस्करण: $json';

  @override
  String operationDetail(String operation) => 'क्रिया: $operation';

  @override
  String get pushed => 'भेजे गए';

  @override
  String get pulled => 'प्राप्त किए गए';

  @override
  String rejectedWithError(String error) => 'अस्वीकृत: $error';

  @override
  String get backupSubject => 'खाता बैकअप';

  @override
  String get backupShareText => 'इस डिवाइस से खाता बैकअप निर्यात किया गया।';

  @override
  String recordsAddedCount(int count) => '$count रिकॉर्ड जोड़े गए';

  @override
  String alreadyPresentCount(int count) => '$count पहले से मौजूद, छोड़े गए';

  @override
  String addedCount(int count) => '$count जोड़े गए';

  @override
  String addedKeptCount(int count, int kept) => '$count जोड़े गए, $kept रखे गए';

  @override
  String get reminderRepeatNote =>
      'दोहराने वाला रिमाइंडर चलने के बाद खुद को फिर से निर्धारित करता है।';

  @override
  String get profileLabel => 'प्रोफ़ाइल';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageNepali => 'नेपाली';

  @override
  String get calendarLabel => 'कैलेंडर';

  @override
  String get generalSection => 'सामान्य';

  @override
  String get dateLabel => 'दिनांक';

  @override
  String get descriptionLabel => 'विवरण';

  @override
  String get fromLabel => 'से';

  @override
  String get toLabel => 'तक';

  @override
  String get titleRequired => 'शीर्षक *';

  @override
  String get sourceRequired => 'स्रोत *';

  @override
  String get taxExample => 'जैसे 13';

  @override
  String get amountExample => 'जैसे 20.00';

  @override
  String get quantityExample16 => 'जैसे 16.00';

  @override
  String get rateExample => 'जैसे 25';

  @override
  String get plusOne => '+1';

  @override
  String get plusTen => '+10';

  @override
  String get minusOne => '-1';

  @override
  String get minusTen => '-10';

  @override
  String get phonePrefixHint => '+977 98XXXXXXXX';

  @override
  String get rankLabel => '#';

  @override
  String editKind(String kind) => '$kind संपादित करें';

  @override
  String newKind(String kind) => 'नया $kind';

  @override
  String get delete => 'हटाएँ';

  @override
  String get edit => 'संपादित करें';

  @override
  String get convert => 'बदलें';

  @override
  String get exportTitle => 'निर्यात';

  @override
  String get restoreTitle => 'पुनर्स्थापित करें';

  @override
  String get expenseTrend => 'खर्च रुझान';

  @override
  String get opening => 'प्रारंभिक';

  @override
  String get filterByCategory => 'श्रेणी से फ़िल्टर करें';

  @override
  String get phoneLabel => 'फ़ोन';

  @override
  String get emailMustHaveAccount => 'ईमेल (खाता होना चाहिए)';

  @override
  String get advancesExplainer =>
      'अग्रिम वह पैसा है जो आपके पास पहले से है (ग्राहक) या जो आप दे चुके हैं (आपूर्तिकर्ता), इसलिए वह नए भुगतान से पहले लगाया जाता है।';

  @override
  String get backupExportExplainerFull =>
      'सक्रिय व्यवसाय के हर उत्पाद, पक्षकार, बिक्री, खरीद, खर्च, आय, भुगतान, इनवॉइस और कोटेशन को सहेजता है। नरम रूप से हटाए गए रिकॉर्ड भी रखे जाते हैं, ताकि इतिहास बचा रहे।';

  @override
  String get backupRestoreExplainerFull =>
      'पुनर्स्थापना बैकअप को इस व्यवसाय में मिलाती है। जो रिकॉर्ड पहले से हैं वे छोड़ दिए जाते हैं — कुछ भी अधिलेखित नहीं होता, क्योंकि बदली हुई बिक्री या भुगतान से खाता बही आपस में मेल नहीं खाती।';

  @override
  String get backupNotIncludedExplainer =>
      'खाता बही की प्रविष्टियाँ और स्टॉक मूवमेंट ऊपर दिए दस्तावेज़ों से बनते हैं, इसलिए वे उन क्रियाओं को दोबारा चलाकर बनाए जाते हैं, कॉपी नहीं किए जाते। इसलिए पुनर्स्थापना आपके रिकॉर्ड लौटाती है, कैश किए गए जोड़ नहीं।';

  @override
  String get restoreConfirmBodyFull =>
      'इस व्यवसाय में पहले से मौजूद रिकॉर्ड छोड़ दिए जाएँगे। यहाँ मौजूद कुछ भी बदला या हटाया नहीं जाएगा।';

  @override
  String get methodChangeNoteFull =>
      'इस तरीके से पहले दर्ज भुगतान काम करते रहेंगे। तरीके का नाम बदलने से इतिहास नहीं बदलता।';

  @override
  String get saleDeleteNoteFull =>
      'स्टॉक लौटाया जाएगा और ग्राहक का खाता उलटा किया जाएगा।';

  @override
  String get purchaseDeleteNoteFull =>
      'स्टॉक घटाया जाएगा और आपूर्तिकर्ता का खाता उलटा किया जाएगा।';

  @override
  String get lineItemsCopiedNoteFull =>
      'वस्तुएँ चुनी गई बिक्री से कॉपी होंगी और उनके दाम वही रहेंगे।';

  @override
  String get notificationsInAppNoteFull =>
      'ऐप में सूचनाएँ हमेशा दर्ज होती हैं। ये स्विच केवल पुश डिलीवरी नियंत्रित करते हैं।';

  @override
  String unitNameShort(String name, String short) => '$name ($short)';

  @override
  String retailValue(String amount) => 'खुदरा $amount';

  @override
  String advanceAmount(String amount) => 'अग्रिम $amount';

  @override
  String quantityWithUnit(String quantity, String unit) => '$quantity$unit';

  @override
  String productPricePair(String price) => '$price  •  ';

  @override
  String saleCustomerLine(String number, String customer) =>
      '$number — $customer';

  @override
  String lineTotalAmount(String amount) => 'पंक्ति कुल: $amount';

  @override
  String conflictsCount(int count) => '$count टकराव';

  @override
  String get noDataInRange => 'इस अवधि में कोई डेटा नहीं';

  @override
  String get nothingToBreakDown => 'विभाजन के लिए कुछ नहीं';

  @override
  String get noProductsMatchFilter => 'इस फ़िल्टर से कोई उत्पाद मेल नहीं खाता';

  @override
  String get noProductsSoldInRange => 'इस अवधि में कोई उत्पाद नहीं बिका';

  @override
  String get noSalesToCustomersInRange =>
      'इस अवधि में ग्राहकों को कोई बिक्री नहीं';

  @override
  String get nobodyOwesYou => 'कोई आपका देनदार नहीं';

  @override
  String get youOweNobody => 'आप किसी के देनदार नहीं';

  @override
  String addLabel(String label) => '$label जोड़ें';

  @override
  String couldNotLoadX(String subject, String error) =>
      '$subject लोड नहीं हो सका।\n$error';

  @override
  String get balances => 'शेष';

  @override
  String get expenseReport => 'खर्च रिपोर्ट';

  @override
  String get incomeReport => 'आय रिपोर्ट';

  @override
  String get stockReportTitle => 'स्टॉक रिपोर्ट';

  @override
  String get expenseReportTitle => 'खर्च रिपोर्ट';

  @override
  String get incomeReportTitle => 'आय रिपोर्ट';

  @override
  String get profitAndLossTitle => 'लाभ और हानि';

  @override
  String get stockMovements => 'स्टॉक मूवमेंट';

  @override
  String get devices => 'डिवाइस';

  @override
  String emailAndRole(String email, String role) => '$email\n$role';

  @override
  String addKind(String kind) => '$kind जोड़ें';

  @override
  String lowAtOrBelow(String quantity, String unit) =>
      'कम: $quantity$unit या उससे नीचे';

  @override
  String minimumIs(String quantity, String unit) => 'न्यूनतम $quantity$unit';

  @override
  String savedTo(String path) => '$path में सहेजा गया';

  @override
  String get emailRequired => 'कृपया अपना ईमेल दर्ज करें';

  @override
  String get emailInvalid => 'कृपया मान्य ईमेल दर्ज करें';

  @override
  String get passwordRequired => 'कृपया अपना पासवर्ड दर्ज करें';

  @override
  String get passwordRegisterRequired => 'कृपया पासवर्ड दर्ज करें';

  @override
  String get passwordTooShort => 'पासवर्ड कम से कम 8 अक्षरों का होना चाहिए';

  @override
  String get passwordNeedsDigit => 'पासवर्ड में कम से कम एक अंक होना चाहिए';

  @override
  String get confirmPasswordRequired => 'कृपया पासवर्ड की पुष्टि करें';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get fullNameRequired => 'कृपया अपना पूरा नाम दर्ज करें';

  @override
  String get fullNameIsRequired => 'पूरा नाम आवश्यक है';

  @override
  String get businessNameIsRequired => 'व्यवसाय का नाम आवश्यक है';

  @override
  String get amountRequired => 'राशि आवश्यक है';

  @override
  String get amountInvalid => 'मान्य राशि दर्ज करें';

  @override
  String get amountInvalidFull => 'मान्य राशि दर्ज करें।';

  @override
  String get amountMustBePositive => 'राशि शून्य से अधिक होनी चाहिए।';

  @override
  String get quantityInvalid => 'मान्य मात्रा दर्ज करें';

  @override
  String get percentRange => '0–100 दर्ज करें';

  @override
  String get panMustBe9Digits => 'पैन 9 अंकों का होना चाहिए।';

  @override
  String get panMustBe9DigitNumber => 'पैन 9 अंकों की संख्या होनी चाहिए';

  @override
  String get phoneInvalid => 'फ़ोन नंबर का प्रारूप गलत है।';

  @override
  String get emailAddressRequired => 'मान्य ईमेल पता आवश्यक है।';

  @override
  String get invalidEmailOrPassword => 'ईमेल या पासवर्ड गलत है।';

  @override
  String get checkYourInput => 'कृपया अपनी जानकारी जाँचें।';

  @override
  String get somethingWentWrong => 'कुछ गड़बड़ हो गई। कृपया फिर कोशिश करें।';

  @override
  String get returnIn => 'वापसी अंदर';

  @override
  String get returnOut => 'वापसी बाहर';

  @override
  String get week => 'सप्ताह';

  @override
  String get month => 'महीना';

  @override
  String get day => 'दिन';

  @override
  String todayAt(String time) => 'आज $time';

  @override
  String tomorrowAt(String time) => 'कल $time';

  @override
  String yesterdayAt(String time) => 'बीता कल $time';

  @override
  String noKindMatchSearch(String kind) =>
      'आपकी खोज से कोई $kind मेल नहीं खाता';

  @override
  String noKindYet(String kind) => 'अभी कोई $kind नहीं';

  @override
  String get categoryReminder => 'रिमाइंडर';

  @override
  String get saved => 'सहेजा गया';

  @override
  String get productSaved => 'उत्पाद सहेजा गया';

  @override
  String get walkInCustomer => 'सीधा ग्राहक';

  @override
  String get notSet => 'तय नहीं';

  @override
  String get unpaid => 'अवैतनिक';

  @override
  String get noSupplier => 'कोई आपूर्तिकर्ता नहीं';

  @override
  String get paidInFull => 'पूरा भुगतान हुआ';

  @override
  String get exporting => 'निर्यात हो रहा है...';

  @override
  String get saving => 'सहेजा जा रहा है...';

  @override
  String get noLowStockProducts => 'कोई कम-स्टॉक उत्पाद नहीं — सब ठीक है!';

  @override
  String get noProductsMatchSearch => 'आपकी खोज से कोई उत्पाद मेल नहीं खाता';

  @override
  String get showingUnread => 'अपठित दिखा रहे हैं';

  @override
  String get customerKhata => 'ग्राहक खाता';

  @override
  String get debit => 'नामे';

  @override
  String get recordReceipt => 'रसीद दर्ज करें';

  @override
  String get applyToInvoice => 'इनवॉइस पर लागू करें';

  @override
  String get receipt => 'रसीद';

  @override
  String get roleViewer => 'दर्शक';

  @override
  String get never => 'कभी नहीं';

  @override
  String get syncing => 'सिंक हो रहा है…';

  @override
  String moneyInOut(String inAmount, String outAmount) =>
      'अंदर $inAmount · बाहर $outAmount';

  @override
  String dueAmount(String amount) => 'बकाया $amount';

  @override
  String get created => 'बनाया गया';

  @override
  String get productCreated => 'उत्पाद बनाया गया';

  @override
  String toCollectAmount(String amount) => 'लेना है $amount';

  @override
  String toPayAmount(String amount) => 'देना है $amount';

  @override
  String get createProduct => 'उत्पाद बनाएँ';

  @override
  String get create => 'बनाएँ';

  @override
  String get noProductsYet => 'अभी कोई उत्पाद नहीं';

  @override
  String get noProductsYetAddFirst =>
      'अभी कोई उत्पाद नहीं — अपना पहला उत्पाद जोड़ें';

  @override
  String get subtotal => 'उप-योग';

  @override
  String get total => 'कुल';

  @override
  String get discount => 'छूट';

  @override
  String get rateRs => 'दर (रु.)';

  @override
  String get discountRs => 'छूट (रु.)';

  @override
  String get addAtLeastOneItem => 'कम से कम एक वस्तु जोड़ें';

  @override
  String get costValue => 'लागत मूल्य';

  @override
  String get potentialMargin => 'संभावित मार्जिन';

  @override
  String get invoiceCreated => 'इनवॉइस बनाया गया';

  @override
  String get invoiceDeleted => 'इनवॉइस हटाया गया';

  @override
  String get quotationCreated => 'कोटेशन बनाया गया';

  @override
  String get quotationDeleted => 'कोटेशन हटाया गया';

  @override
  String get convertedToSaleToast => 'बिक्री में बदला गया';

  @override
  String get saleCreated => 'बिक्री बनाई गई';

  @override
  String get saleReversed => 'बिक्री उलटी की गई';

  @override
  String get saleKeptAsReversed =>
      'बिक्री इतिहास में उलटी के रूप में रखी गई है।';

  @override
  String get creditSaleNeedsCustomer => 'उधार बिक्री के लिए ग्राहक आवश्यक है';

  @override
  String get purchaseCreated => 'खरीद बनाई गई';

  @override
  String get purchaseReversed => 'खरीद उलटी की गई';

  @override
  String get purchaseKeptAsReversed =>
      'खरीद इतिहास में उलटी के रूप में रखी गई है।';

  @override
  String get creditPurchaseNeedsSupplier =>
      'उधार खरीद के लिए आपूर्तिकर्ता आवश्यक है';

  @override
  String get paymentRecorded => 'भुगतान दर्ज हुआ';

  @override
  String get methodSaved => 'तरीका सहेजा गया';

  @override
  String get methodDeleted => 'तरीका हटाया गया';

  @override
  String get categorySaved => 'श्रेणी सहेजी गई';

  @override
  String get categoryDeleted => 'श्रेणी हटाई गई';

  @override
  String get productDeleted => 'उत्पाद हटाया गया';

  @override
  String get unitSaved => 'इकाई सहेजी गई';

  @override
  String get unitDeleted => 'इकाई हटाई गई';

  @override
  String get settingsSaved => 'सेटिंग्स सहेजी गईं';

  @override
  String get atLeastOneMethodMustRemain =>
      'कम से कम एक भुगतान तरीका रहना चाहिए।';

  @override
  String get notAkhataBackup => 'यह खाता बैकअप नहीं है।';

  @override
  String get enterNonZeroQuantity => 'शून्य से भिन्न मात्रा दर्ज करें';

  @override
  String get enterAmountGreaterThanZero => 'शून्य से अधिक राशि दर्ज करें';

  @override
  String balanceAfterIs(String quantity) => 'शेष $quantity';

  @override
  String get rejectedAndFailed => 'अस्वीकृत और विफल';

  @override
  String get entries => 'प्रविष्टियाँ';

  @override
  String get average => 'औसत';

  @override
  String get sources => 'स्रोत';

  @override
  String get revenue => 'राजस्व';

  @override
  String get costOfGoodsSold => 'बेचे गए माल की लागत';

  @override
  String get grossProfit => 'सकल लाभ';

  @override
  String get otherIncome => 'अन्य आय';

  @override
  String get netProfit => 'शुद्ध लाभ';

  @override
  String get taxCollectedInPeriod => 'इस अवधि में वसूला गया कर: ';

  @override
  String get customerAdvances => 'ग्राहक अग्रिम';

  @override
  String get supplierAdvances => 'आपूर्तिकर्ता अग्रिम';

  @override
  String get advancesExplain =>
      'अग्रिम वह पैसा है जो आपके पास पहले से है (ग्राहक) या जो आपने अधिक दे दिया है (आपूर्तिकर्ता)।';

  @override
  String get reportSalesBlurb => 'रुझान, जोड़, सर्वाधिक उत्पाद और ग्राहक';

  @override
  String get reportProfitLossBlurb => 'राजस्व, माल की लागत और शुद्ध लाभ';

  @override
  String get reportExpenseBlurb => 'पैसा कहाँ गया, श्रेणी के अनुसार';

  @override
  String get reportIncomeBlurb => 'स्रोत के अनुसार अन्य आय';

  @override
  String get reportStockBlurb => 'हाथ में मौजूद स्टॉक का लागत और खुदरा मूल्य';

  @override
  String get reportReceivableBlurb => 'कौन आपका देनदार है और आप किसके';

  @override
  String get ledgerOwesYouHint =>
      'वे आपके कितने देनदार हैं (ग्राहक) / आपने कितना दिया (आपूर्तिकर्ता)';

  @override
  String get ledgerYouOweHint =>
      'आपको कितना मिला (ग्राहक) / आप कितने देनदार हैं (आपूर्तिकर्ता)';

  @override
  String get roleOwner => 'मालिक';

  @override
  String get roleAdmin => 'एडमिन';

  @override
  String get roleManager => 'मैनेजर';

  @override
  String get roleAccountant => 'लेखाकार';

  @override
  String get noBusiness => 'कोई व्यवसाय नहीं';

  @override
  String couldNotLoadProducts(String error) =>
      'उत्पाद लोड नहीं हो सके।\n$error';

  @override
  String get lineItemsCopiedFromSale =>
      'वस्तुएँ चुनी गई बिक्री से कॉपी होंगी और उसका इनवॉइस नंबर दोबारा इस्तेमाल होगा।';

  @override
  String bsRange(String from, String to) => 'वि.सं.: $from  →  $to';

  @override
  String conflictsNamed(int count) => 'टकराव ($count)';

  @override
  String get retailValueReport => 'खुदरा मूल्य';

  @override
  String selectPartyKind(String kind) => '$kind चुनें';

  @override
  String get tax => 'कर';

  @override
  String get qty => 'मात्रा';

  @override
  String get adjustment => 'समायोजन';

  @override
  String get showingAll => 'सभी दिखा रहे हैं';

  @override
  String get supplierKhata => 'आपूर्तिकर्ता खाता';

  @override
  String get applyToBill => 'बिल पर लागू करें';

  @override
  String get newMethod => 'नया तरीका';

  @override
  String get today => 'आज';

  @override
  String get municipality => 'नगरपालिका';

  @override
  String get selectProvinceHint => 'प्रांत चुनें';

  @override
  String get selectDistrictHint => 'ज़िला चुनें';

  @override
  String get selectMunicipalityHint => 'नगरपालिका चुनें';

  @override
  String get municipalityFreeTextHint =>
      'नगरपालिका लिखें — यहाँ हर स्थानीय इकाई सूचीबद्ध नहीं है।';

  @override
  String get phoneInvalidNepali =>
      'मान्य नेपाली फ़ोन नंबर दर्ज करें, जैसे 98XXXXXXXX';

  @override
  String get fromDate => 'से';

  @override
  String get toDate => 'तक';

  @override
  String get back => 'पीछे';

  @override
  String get next => 'आगे';

  @override
  String get endBeforeStart =>
      'अंतिम तिथि प्रारंभिक तिथि से पहले नहीं हो सकती।';

  @override
  String get dateRange => 'तिथि सीमा';

  @override
  String get toolsTitle => 'औज़ार';

  @override
  String get emiCalculator => 'ईएमआई कैलकुलेटर';

  @override
  String get loanAmount => 'ऋण राशि (रु.)';

  @override
  String get annualInterestRate => 'वार्षिक ब्याज दर (%)';

  @override
  String get loanTermMonths => 'ऋण अवधि (महीने)';

  @override
  String get monthlyEmi => 'मासिक ईएमआई';

  @override
  String get totalPayment => 'कुल भुगतान';

  @override
  String get totalInterest => 'कुल ब्याज';

  @override
  String get interestCalculator => 'ब्याज कैलकुलेटर';

  @override
  String get simpleInterest => 'साधारण ब्याज';

  @override
  String get compoundInterest => 'चक्रवृद्धि ब्याज';

  @override
  String get principal => 'मूलधन';

  @override
  String get years => 'वर्ष';

  @override
  String get compoundingPerYear => 'प्रति वर्ष चक्रवृद्धि';

  @override
  String get interestEarned => 'अर्जित ब्याज';

  @override
  String get profitCalculator => 'लाभ कैलकुलेटर';

  @override
  String get profit => 'लाभ';

  @override
  String get profitMargin => 'लाभ मार्जिन';

  @override
  String get markup => 'मार्कअप';

  @override
  String get enterValidAmount => 'मान्य राशि दर्ज करें';

  @override
  String get maturityAmount => 'परिपक्वता राशि';

  @override
  String get calculate => 'गणना करें';

  @override
  String get lossWarning => 'यह लाभ नहीं, हानि है।';

  @override
  String get appLock => 'ऐप लॉक';

  @override
  String get appLockDescription => 'ऐप खोलने के लिए पिन आवश्यक करें';

  @override
  String get setPin => 'पिन सेट करें';

  @override
  String get changePin => 'पिन बदलें';

  @override
  String get enterPin => 'अपना पिन दर्ज करें';

  @override
  String get confirmPin => 'पिन की पुष्टि करें';

  @override
  String get currentPin => 'वर्तमान पिन';

  @override
  String get newPin => 'नया पिन';

  @override
  String get pinMustBe4To6Digits => 'पिन 4 से 6 अंकों का होना चाहिए';

  @override
  String get pinsDoNotMatch => 'पिन मेल नहीं खाते';

  @override
  String get incorrectPin => 'गलत पिन';

  @override
  String get unlock => 'खोलें';

  @override
  String get turnOffAppLock => 'ऐप लॉक बंद करें';

  @override
  String get appLockNowOn => 'ऐप लॉक चालू है';

  @override
  String get appLockNowOff => 'ऐप लॉक बंद है';

  @override
  String attemptsLeft(int count) => '$count प्रयास शेष';

  @override
  String get bankAccounts => 'बैंक खाते';

  @override
  String get bankName => 'बैंक का नाम';

  @override
  String get accountName => 'खाताधारक का नाम';

  @override
  String get accountNumber => 'खाता संख्या';

  @override
  String get branch => 'शाखा';

  @override
  String get defaultAccount => 'डिफ़ॉल्ट खाता';

  @override
  String get noBankAccountsYet =>
      'अभी कोई बैंक खाता नहीं। लेन-देन दर्ज करने के लिए एक जोड़ें।';

  @override
  String get addBankAccount => 'बैंक खाता जोड़ें';

  @override
  String paymentsThroughAccount(int count, String total) =>
      '$count भुगतान · $total';

  @override
  String get deleted => 'हटाया गया';

  @override
  String get importTile => 'आयात';

  @override
  String get importTitle => 'Excel से आयात करें';

  @override
  String get importExplainerTitle => 'यह कैसे काम करता है';

  @override
  String get importExplainerBody =>
      'अपनी स्प्रेडशीट की पंक्तियाँ यहाँ चिपकाएँ। टेम्पलेट कॉपी करें, Excel में भरें, CSV के रूप में सहेजें और वापस चिपकाएँ। कुछ भी लिखने से पहले हर पंक्ति जाँची जाती है — एक पंक्ति भी गलत हुई तो कुछ भी आयात नहीं होता।';

  @override
  String get importCopyTemplate => 'टेम्पलेट कॉपी करें';

  @override
  String get importTemplateCopied =>
      'टेम्पलेट कॉपी हुआ — इसे Excel में चिपकाएँ';

  @override
  String get importPasteFromClipboard => 'क्लिपबोर्ड से चिपकाएँ';

  @override
  String get importCsvLabel => 'CSV पंक्तियाँ';

  @override
  String get importCheckFile => 'फ़ाइल जाँचें';

  @override
  String get importChecking => 'जाँच हो रही है…';

  @override
  String get importRun => 'आयात करें';

  @override
  String get importImporting => 'आयात हो रहा है…';

  @override
  String get importPreviewTitle => 'जाँच परिणाम';

  @override
  String get importRowsTotal => 'पंक्तियाँ';

  @override
  String get importRowsValid => 'तैयार';

  @override
  String get importRowsDuplicate => 'पहले से मौजूद';

  @override
  String get importRowsInvalid => 'सुधार चाहिए';

  @override
  String get importBlockedHint =>
      'जब तक हर पंक्ति ठीक न हो, कुछ भी आयात नहीं होगा।';

  @override
  String importIgnoredColumns(String columns) => 'छोड़े गए कॉलम: $columns';

  @override
  String get importIssuesTitle => 'सुधारने योग्य पंक्तियाँ';

  @override
  String importIssueLine(int row, String message) => 'पंक्ति $row: $message';

  @override
  String importIssueLineWithColumn(int row, String column, String message) =>
      'पंक्ति $row · $column: $message';

  @override
  String importMoreIssues(int count) => '…और $count अन्य';

  @override
  String get importConfirmTitle => 'ये पंक्तियाँ आयात करें?';

  @override
  String get importConfirmBody =>
      'पहले से मौजूद पंक्तियाँ छोड़ दी जाएँगी; कुछ भी अधिलेखित नहीं होगा।';

  @override
  String get importCompleteTitle => 'आयात पूर्ण';

  @override
  String importCreatedCount(int count) => '$count रिकॉर्ड बनाए गए';

  @override
  String importSkippedCount(int count) => '$count पहले से थे और छोड़ दिए गए';

  @override
  String get importRejected =>
      'कुछ भी आयात नहीं हुआ — नीचे की पंक्तियाँ ठीक करें और फिर कोशिश करें।';

  @override
  String get importClear => 'साफ़ करें';

  @override
  String get importExpectedColumns => 'अपेक्षित कॉलम';

  @override
  String get cachedDataNote =>
      'सहेजा गया डेटा दिख रहा है। ताज़ा करने के लिए फिर से जुड़ें।';

  @override
  String cachedDataNoteAt(String time) =>
      '$time का सहेजा गया डेटा दिख रहा है। ताज़ा करने के लिए फिर से जुड़ें।';

  @override
  String get offlineDataTitle => 'ऑफ़लाइन डेटा';

  @override
  String get offlineDataExplainer =>
      'आपके खोले गए विवरण इस डिवाइस पर सहेजे जाते हैं, इसलिए इंटरनेट बंद होने पर भी खुलते हैं।';

  @override
  String get offlineDataSavedLabel => 'सहेजे गए विवरण';

  @override
  String offlineDataSavedCount(int lists, String size) =>
      '$lists विवरण · $size';

  @override
  String get offlineDataClear => 'सहेजा डेटा हटाएँ';

  @override
  String get offlineDataClearConfirm =>
      'सहेजे गए विवरण हटाएँ? अगली बार खोलने पर वे फिर डाउनलोड होंगे।';

  @override
  String get offlineDataCleared => 'सहेजा डेटा हटा दिया गया';

  @override
  String loadMoreRemaining(int count) => 'और दिखाएँ ($count शेष)';

  @override
  String get pageNotFound => 'पृष्ठ नहीं मिला';

  @override
  String get pageNotFoundBody =>
      'यह पृष्ठ उपलब्ध नहीं है। हो सकता है इसे स्थानांतरित किया गया हो, या लिंक गलत हो।';

  @override
  String get fileSaveNotSupported =>
      'फ़ाइल सहेजने और साझा करने के लिए फ़ोन पर ऐप चाहिए — ब्राउज़र संस्करण फ़ाइल नहीं लिख सकता।';

  @override
  String get savedOffline => 'ऑफ़लाइन सहेजा गया — जुड़ते ही सिंक हो जाएगा।';

  @override
  String get offlineBannerNote => 'ऑफ़लाइन — जुड़ने पर बदलाव सिंक होंगे';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get calendarAd => 'ईस्वी (AD)';

  @override
  String get calendarBs => 'वि.सं. (बिक्रम संवत)';

  @override
  String get calendarNote => 'तिथियाँ इसी कैलेंडर में दिखेंगी और चुनी जाएँगी।';

  @override
  String pendingWritesCount(int count) => '$count शेष';

  @override
  String get navHome => 'होम';

  @override
  String get navParties => 'खाते';

  @override
  String get navItems => 'सामान';

  @override
  String monthToDate(String amount) => 'इस माह $amount';

  @override
  String lowStockCountLabel(int count) => '$count सामान का स्टॉक कम';

  @override
  String get recentActivity => 'हाल की गतिविधि';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get getStartedTitle => 'शुरू करें';

  @override
  String get getStartedStepProduct => 'पहला सामान जोड़ें';

  @override
  String get getStartedStepCustomer => 'ग्राहक जोड़ें';

  @override
  String get getStartedStepSale => 'पहली बिक्री दर्ज करें';

  @override
  String get shareReminder => 'रिमाइंडर भेजें';

  @override
  String reminderShareMessage(String name, String business, String amount) =>
      'नमस्ते $name, $business में आपका बकाया $amount है। सुविधा होने पर भुगतान कर दें। धन्यवाद।';

  @override
  String get moreSalesDocs => 'बिक्री और दस्तावेज़';

  @override
  String get moreItems => 'सामान और स्टॉक';

  @override
  String get moreInsights => 'विश्लेषण';

  @override
  String get moreTools => 'उपकरण और सेटिंग';

  @override
  String get moreAccount => 'खाता';

  @override
  String balanceShort(String amount) => 'बकाया $amount';

  @override
  String get moreActions => 'और क्रियाएँ';

  @override
  String get welcomeChooseLanguage => 'अपनी भाषा चुनें';

  @override
  String get welcomeSkip => 'छोड़ें';

  @override
  String get welcomeSlide1Title => 'कभी न भूलने वाला खाता';

  @override
  String get welcomeSlide1Body =>
      'हर उधार बिक्री, हर भुगतान और हर बकाया — एक बार लिखा, हमेशा सही।';

  @override
  String get welcomeSlide2Title => 'खुद गिनने वाला स्टक';

  @override
  String get welcomeSlide2Body =>
      'बिक्री और खरीद से स्टॉक खुद घटता है, और सामान खत्म होने से पहले चेतावनी मिलती है।';

  @override
  String get welcomeSlide3Title => 'काम आने वाले आँकड़े';

  @override
  String get welcomeSlide3Body =>
      'रोज़ का मुनाफ़ा, वसूली और देय — ईस्वी या वि.सं. तिथि में, आपकी भाषा में।';

  @override
  String get tryDemo => 'डेमो देखें';

  @override
  String get updateTitle => 'अपडेट उपलब्ध है';

  @override
  String updateBody(String current, String latest) =>
      'आपके पास संस्करण $current है। संस्करण $latest इंस्टॉल के लिए तैयार है।';

  @override
  String updateSize(String size) => 'डाउनलोड आकार: $size';

  @override
  String get updateNotesLabel => 'नया क्या है';

  @override
  String get updateDownload => 'डाउनलोड';

  @override
  String get updateLater => 'बाद में';

  @override
  String get updateLinkFailed => 'डाउनलोड लिंक नहीं खुल सका।';

}

/// The translations for ne.
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe() : super('ne');

  @override
  String get appName => 'डिजिटल खाता';

  @override
  String get login => 'साइन इन';

  @override
  String get register => 'साइन अप';

  @override
  String get email => 'इमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get fullName => 'पुरा नाम';

  @override
  String get phoneNumber => 'फोन नम्बर';

  @override
  String get confirmPassword => 'पासवर्ड पुनः लेख्नुहोस्';

  @override
  String get createAccount => 'खाता बनाउनुहोस्';

  @override
  String get alreadyHaveAccount => 'पहिले नै खाता छ? साइन इन गर्नुहोस्';

  @override
  String get dontHaveAccount => 'खाता छैन? साइन अप गर्नुहोस्';

  @override
  String get dashboard => 'ड्यासबोर्ड';

  @override
  String get transactions => 'कारोबार';

  @override
  String get khata => 'खाता';

  @override
  String get reports => 'रिपोर्ट';

  @override
  String get more => 'थप';

  @override
  String get todaysSales => 'आजको बिक्री';

  @override
  String get todaysPurchases => 'आजको खरिद';

  @override
  String get todaysExpenses => 'आजको खर्च';

  @override
  String get todaysProfit => 'आजको नाफा';

  @override
  String get totalReceivable => 'कुल प्राप्य';

  @override
  String get totalPayable => 'कुल देय';

  @override
  String get stockValue => 'स्टक मूल्य';

  @override
  String get lowStock => 'कम स्टक';

  @override
  String get syncNow => 'अहिले सिंक गर्नुहोस्';

  @override
  String get settings => 'सेटिङ';

  @override
  String get logout => 'लगआउट';

  @override
  String get createBusiness => 'व्यवसाय बनाउनुहोस्';

  @override
  String get businessSetupTitle => 'आफ्नो व्यवसाय सेट गर्नुहोस्';

  @override
  String get businessSetupSubtitle => 'तपाईं मालिक हुनुहुनेछ, पूर्ण पहुँचसहित।';

  @override
  String get businessName => 'व्यवसायको नाम';

  @override
  String get businessType => 'व्यवसायको प्रकार (जस्तै सर्वसाधारण)';

  @override
  String get panNumber => 'प्यान नम्बर';

  @override
  String get businessEmail => 'व्यवसाय इमेल';

  @override
  String get address => 'ठेगाना';

  @override
  String get city => 'शहर';

  @override
  String get district => 'जिल्ला';

  @override
  String get province => 'प्रदेश';

  @override
  String get wardNumber => 'वडा नम्बर';

  @override
  String get myBusinesses => 'मेरा व्यवसायहरू';

  @override
  String get switchBusiness => 'व्यवसाय बदल्नुहोस्';

  @override
  String get active => 'सक्रिय';

  @override
  String get noBusinesses => 'अहिलेसम्म कुनै व्यवसाय छैन';

  @override
  String get createFirstBusiness => 'पहिलो व्यवसाय बनाउनुहोस्';

  @override
  String get staff => 'कर्मचारी';

  @override
  String get invite => 'निम्तो';

  @override
  String get inviteMember => 'कर्मचारी निमन्त्रणा';

  @override
  String get changeRole => 'भूमिका बदल्नुहोस्';

  @override
  String get remove => 'हटाउनुहोस्';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get editProfile => 'प्रोफाइल सम्पादन';

  @override
  String get saveChanges => 'परिवर्तन सुरक्षित गर्नुहोस्';

  @override
  String get cancel => 'रद्द गर्नुहोस्';

  @override
  String get language => 'भाषा';

  @override
  String get retry => 'पुनः प्रयास';

  @override
  String get loading => 'लोड हुँदै';

  @override
  String get products => 'सामानहरू';

  @override
  String get product => 'सामान';

  @override
  String get addProduct => 'सामान थप्नुहोस्';

  @override
  String get editProduct => 'सामान सम्पादन';

  @override
  String get newProduct => 'नयाँ सामान';

  @override
  String get productName => 'सामानको नाम';

  @override
  String get sku => 'एसकेयु';

  @override
  String get barcode => 'बारकोड';

  @override
  String get categories => 'वर्गहरू';

  @override
  String get addCategory => 'वर्ग थप्नुहोस्';

  @override
  String get newCategory => 'नयाँ वर्ग';

  @override
  String get category => 'वर्ग';

  @override
  String get units => 'एकाइहरू';

  @override
  String get addUnit => 'एकाइ थप्नुहोस्';

  @override
  String get newUnit => 'नयाँ एकाइ';

  @override
  String get unit => 'एकाइ';

  @override
  String get costPrice => 'लागत मूल्य';

  @override
  String get sellingPrice => 'बिक्री मूल्य';

  @override
  String get wholesalePrice => 'थोक मूल्य';

  @override
  String get taxRate => 'कर दर';

  @override
  String get openingStock => 'सुरुको स्टक';

  @override
  String get minQuantity => 'कम स्टक चेतावनी';

  @override
  String get inventory => 'भण्डार';

  @override
  String get adjustStock => 'स्टक मिलाउनुहोस्';

  @override
  String get stockHistory => 'स्टक इतिहास';

  @override
  String get quickAdjust => 'द्रुत मिलान';

  @override
  String get customQuantity => 'अनुकूल परिमाण';

  @override
  String get notes => 'टिप्पणी';

  @override
  String get applyAdjustment => 'मिलान लागू गर्नुहोस्';

  @override
  String get lowStockOnly => 'कम स्टक मात्र';

  @override
  String get sortByName => 'नामअनुसार क्रम';

  @override
  String get sortByQuantity => 'परिमाणअनुसार क्रम';

  @override
  String get searchProducts => 'सामान खोज्नुहोस्';

  @override
  String get inStock => 'स्टकमा';

  @override
  String get lowStockAlert => 'कम स्टक';

  @override
  String get stockAdded => 'स्टक थपियो';

  @override
  String get stockRemoved => 'स्टक घट्यो';

  @override
  String get customers => 'ग्राहकहरू';

  @override
  String get customer => 'ग्राहक';

  @override
  String get addCustomer => 'ग्राहक थप्नुहोस्';

  @override
  String get newCustomer => 'नयाँ ग्राहक';

  @override
  String get editCustomer => 'ग्राहक सम्पादन';

  @override
  String get searchCustomers => 'ग्राहक खोज्नुहोस्';

  @override
  String get suppliers => 'आपूर्तिकर्ताहरू';

  @override
  String get supplier => 'आपूर्तिकर्ता';

  @override
  String get addSupplier => 'आपूर्तिकर्ता थप्नुहोस्';

  @override
  String get newSupplier => 'नयाँ आपूर्तिकर्ता';

  @override
  String get editSupplier => 'आपूर्तिकर्ता सम्पादन';

  @override
  String get searchSuppliers => 'आपूर्तिकर्ता खोज्नुहोस्';

  @override
  String get searchPartyHint => 'नाम वा फोन खोज्नुहोस्';

  @override
  String get ledger => 'खाता बही';

  @override
  String get openingBalance => 'सुरुको मौज्दात';

  @override
  String get creditLimit => 'उधारो सीमा';

  @override
  String get creditLimitOptional => 'उधारो सीमा (वैकल्पिक)';

  @override
  String get closingBalance => 'अन्तिम मौज्दात';

  @override
  String get totalDebit => 'कुल डेबिट';

  @override
  String get totalCredit => 'कुल क्रेडिट';

  @override
  String get toCollect => 'उठाउनु पर्ने';

  @override
  String get toPay => 'तिर्नु पर्ने';

  @override
  String get advance => 'अग्रिम';

  @override
  String get settled => 'मिलान भयो';

  @override
  String get noCustomers => 'अहिलेसम्म कुनै ग्राहक छैन';

  @override
  String get noSuppliers => 'अहिलेसम्म कुनै आपूर्तिकर्ता छैन';

  @override
  String get noTransactions => 'अहिलेसम्म कुनै कारोबार छैन';

  @override
  String get partyDeleted => 'मेटियो';

  @override
  String get deletePartyTitle => 'पक्ष मेट्ने?';

  @override
  String get sales => 'बिक्री';

  @override
  String get sale => 'बिक्री';

  @override
  String get newSale => 'नयाँ बिक्री';

  @override
  String get purchases => 'खरिद';

  @override
  String get purchase => 'खरिद';

  @override
  String get newPurchase => 'नयाँ खरिद';

  @override
  String get expenses => 'खर्च';

  @override
  String get expense => 'खर्च';

  @override
  String get addExpense => 'खर्च थप्नुहोस्';

  @override
  String get income => 'आय';

  @override
  String get addIncome => 'आय थप्नुहोस्';

  @override
  String get invoiceNumber => 'बीजक नम्बर';

  @override
  String get billNumber => 'बिल नम्बर';

  @override
  String get saleType => 'बिक्री प्रकार';

  @override
  String get paymentStatus => 'भुक्तानी स्थिति';

  @override
  String get paid => 'भुक्तान';

  @override
  String get due => 'बाँकी';

  @override
  String get addItem => 'वस्तु थप्नुहोस्';

  @override
  String get searchSales => 'बिक्री खोज्नुहोस्';

  @override
  String get searchPurchases => 'खरिद खोज्नुहोस्';

  @override
  String get searchExpenses => 'खर्च खोज्नुहोस्';

  @override
  String get searchIncome => 'आय खोज्नुहोस्';

  @override
  String get walkIn => 'सामान्य ग्राहक';

  @override
  String get cash => 'नगद';

  @override
  String get credit => 'उधारो';

  @override
  String get partial => 'आंशिक';

  @override
  String get noSales => 'अहिलेसम्म कुनै बिक्री छैन';

  @override
  String get noPurchases => 'अहिलेसम्म कुनै खरिद छैन';

  @override
  String get noExpenses => 'अहिलेसम्म कुनै खर्च छैन';

  @override
  String get noIncome => 'अहिलेसम्म कुनै आय छैन';

  @override
  String get payments => 'भुक्तानीहरू';

  @override
  String get payment => 'भुक्तानी';

  @override
  String get recordPayment => 'भुक्तानी रेकर्ड गर्नुहोस्';

  @override
  String get paymentMethods => 'भुक्तानी माध्यमहरू';

  @override
  String get addPaymentMethod => 'माध्यम थप्नुहोस्';

  @override
  String get receive => 'प्राप्त';

  @override
  String get pay => 'तिर्नुहोस्';

  @override
  String get method => 'माध्यम';

  @override
  String get defaultLabel => 'पूर्वनिर्धारित';

  @override
  String get reference => 'सन्दर्भ';

  @override
  String get noPayments => 'अहिलेसम्म कुनै भुक्तानी छैन';

  @override
  String get onAccount => 'कुनै होइन (खातामा)';

  @override
  String get applyToDocument => 'बीजक/बिलमा लागू गर्नुहोस्';

  @override
  String get advances => 'अग्रिम';

  @override
  String get inactive => 'निष्क्रिय';

  @override
  String get invoices => 'बीजकहरू';

  @override
  String get invoice => 'बीजक';

  @override
  String get newInvoice => 'नयाँ बीजक';

  @override
  String get quotations => 'कोटेशनहरू';

  @override
  String get quotation => 'कोटेशन';

  @override
  String get newQuotation => 'नयाँ कोटेशन';

  @override
  String get issueDate => 'जारी मिति';

  @override
  String get dueDate => 'भुक्तानी म्याद';

  @override
  String get validUntil => 'मान्य मिति';

  @override
  String get terms => 'सर्तहरू';

  @override
  String get share => 'सेयर गर्नुहोस्';

  @override
  String get downloadPdf => 'PDF डाउनलोड';

  @override
  String get convertToSale => 'बिक्रीमा रूपान्तरण';

  @override
  String get status => 'स्थिति';

  @override
  String get draft => 'मस्यौदा';

  @override
  String get sent => 'पठाइयो';

  @override
  String get accepted => 'स्वीकृत';

  @override
  String get rejected => 'अस्वीकृत';

  @override
  String get expired => 'म्याद सकियो';

  @override
  String get overdue => 'म्याद नाघेको';

  @override
  String get noInvoices => 'अहिलेसम्म कुनै बीजक छैन';

  @override
  String get noQuotations => 'अहिलेसम्म कुनै कोटेशन छैन';

  @override
  String get generateFromSale => 'बिक्रीबाट बनाउनुहोस्';

  @override
  String fromSale(String number) => 'बिक्रीबाट';

  @override
  String get notifications => 'सूचनाहरू';

  @override
  String get notificationSettings => 'सूचना सेटिङहरू';

  @override
  String get noNotifications => 'अझै कुनै सूचना छैन';

  @override
  String get nothingMatchesFilter => 'यो फिल्टरसँग मेल खाने केही छैन';

  @override
  String get markAllRead => 'सबै पढेको बनाउनुहोस्';

  @override
  String get markRead => 'पढेको बनाउनुहोस्';

  @override
  String markedReadCount(int count) => '$count पढेको बनाइयो';

  @override
  String get nothingToMark => 'चिन्ह लगाउने केही छैन';

  @override
  String get filterAllCategories => 'सबै श्रेणीहरू';

  @override
  String get pushNotifications => 'पुश सूचनाहरू';

  @override
  String get enablePush => 'पुश सक्षम गर्नुहोस्';

  @override
  String get enablePushSubtitle => 'यो यन्त्रको मुख्य स्विच';

  @override
  String get notificationsInAppNote =>
      'एपभित्रका सूचनाहरू सधैं दर्ता हुन्छन्। यी स्विचहरूले पुश डेलिभरी मात्र नियन्त्रण गर्छन्।';

  @override
  String get registeredDevices => 'दर्ता भएका यन्त्रहरू';

  @override
  String get noDevices => 'अझै कुनै यन्त्र दर्ता भएको छैन';

  @override
  String get deviceActive => 'सक्रिय';

  @override
  String get deviceInactive => 'निष्क्रिय';

  @override
  String get categoryReminders => 'सम्झनाहरू';

  @override
  String get categoryRemindersSubtitle => 'सम्झना समयमा आउँदा';

  @override
  String get categoryLowStock => 'कम स्टक';

  @override
  String get categoryLowStockSubtitle => 'उत्पादन न्यूनतममा पुग्दा';

  @override
  String get categoryPaymentDue => 'भुक्तानी बाँकी';

  @override
  String get categoryPaymentDueSubtitle => 'बिलको म्याद नजिक वा नाघ्दा';

  @override
  String get categoryBackup => 'ब्याकअप';

  @override
  String get categoryBackupSubtitle => 'ब्याकअप सम्पन्न वा असफल हुँदा';

  @override
  String get categorySystem => 'प्रणाली';

  @override
  String get categorySystemSubtitle => 'खाता र एपका सूचनाहरू';

  @override
  String get reminders => 'सम्झनाहरू';

  @override
  String get newReminder => 'नयाँ सम्झना';

  @override
  String get editReminder => 'सम्झना सम्पादन गर्नुहोस्';

  @override
  String get noReminders => 'यहाँ केही छैन';

  @override
  String get needsAttention => 'ध्यान चाहिन्छ';

  @override
  String get scheduled => 'तय भएका';

  @override
  String get addReminder => 'सम्झना थप्नुहोस्';

  @override
  String get reminderTitle => 'शीर्षक';

  @override
  String get reminderTitleHint => 'बाँकी बिलबारे रामलाई फोन गर्नुहोस्';

  @override
  String get reminderTitleRequired => 'शीर्षक आवश्यक छ';

  @override
  String get dueTime => 'म्याद समय';

  @override
  String get repeat => 'दोहोरिने';

  @override
  String get repeatOnce => 'एक पटक';

  @override
  String get repeatDaily => 'हरेक दिन';

  @override
  String get repeatWeekly => 'हरेक हप्ता';

  @override
  String get repeatMonthly => 'हरेक महिना';

  @override
  String get repeatYearly => 'हरेक वर्ष';

  @override
  String get recurringNote =>
      'दोहोरिने सम्झना बजेपछि पूरा नभई आफैं पुनः तय हुन्छ, त्यसैले सधैं आउने मितिमा पर्छ।';

  @override
  String get saveReminder => 'सम्झना सुरक्षित गर्नुहोस्';

  @override
  String get reminderSaved => 'सम्झना सुरक्षित भयो';

  @override
  String get markDone => 'सकियो भन्नुहोस्';

  @override
  String get dismiss => 'हटाउनुहोस्';

  @override
  String get markedDone => 'सकियो भनियो';

  @override
  String get checkDueReminders => 'म्याद आएका सम्झना जाँच्नुहोस्';

  @override
  String get nothingDue => 'अहिले केही म्याद आएको छैन';

  @override
  String remindersFiredCount(int count) => '$count सम्झना आए';

  @override
  String get dueToday => 'आज';

  @override
  String get dueTomorrow => 'भोलि';

  @override
  String get dueYesterday => 'हिजो';

  @override
  String get reminderStatusPending => 'बाँकी';

  @override
  String get reminderStatusDone => 'सकियो';

  @override
  String get reminderStatusDismissed => 'हटाइयो';

  @override
  String get backupAndRestore => 'ब्याकअप र पुनःस्थापना';

  @override
  String get exportBackup => 'ब्याकअप निर्यात गर्नुहोस्';

  @override
  String get restoreFromLastExport => 'अन्तिम निर्यातबाट पुनःस्थापना';

  @override
  String get restoreFromPastedJson => 'टाँसिएको JSON बाट पुनःस्थापना';

  @override
  String get backupExportBody =>
      'सक्रिय व्यवसायका सबै उत्पादन, पक्ष, बिक्री, खरिद, खर्च, आय, भुक्तानी, इनभ्वाइस र कोटेसन सुरक्षित गर्छ। मेटिएका रेकर्डहरू पनि राखिन्छन्, त्यसैले इतिहास जोगिन्छ।';

  @override
  String get backupRestoreBody =>
      'पुनःस्थापनाले ब्याकअपलाई यो व्यवसायमा गाभ्छ। पहिले नै भएका रेकर्डहरू छाडिन्छन् — कहिल्यै अधिलेखन गरिँदैन, किनकि बिक्री वा भुक्तानी पुनःलेख्दा खाता मिल्न छाड्छ।';

  @override
  String get backupNotIncludedTitle => 'के समावेश छैन';

  @override
  String get backupNotIncludedBody =>
      'खाताका लेजर प्रविष्टि र स्टक चलनहरू माथिका कागजातबाट निकालिन्छन्, त्यसैले ती कार्यहरू पुनः चलाएर बनाइन्छ, प्रतिलिपि गरिँदैन। त्यसैले पुनःस्थापनाले रेकर्डहरू फर्काउँछ, क्यास गरिएका जोड फर्काउँदैन।';

  @override
  String get restoreConfirmTitle => 'यो ब्याकअप पुनःस्थापना गर्ने?';

  @override
  String get restoreConfirmBody =>
      'यो व्यवसायमा पहिले नै भएका रेकर्डहरू छाडिनेछन्। अहिले यहाँ भएका कुनै पनि परिवर्तन वा मेटिने छैनन्।';

  @override
  String get restoreComplete => 'पुनःस्थापना सम्पन्न';

  @override
  String restoreAddedCount(int count) => '$count रेकर्ड थपियो';

  @override
  String restoreSkippedCount(int count) => '$count पहिले नै थियो, छाडियो';

  @override
  String recordsAdded(int count) => '$count थपियो';

  @override
  String recordsAddedKept(int count, int kept) => '$count थपियो, $kept राखियो';

  @override
  String get clipboardEmpty => 'क्लिपबोर्ड खाली छ';

  @override
  String get notAKhataBackup => 'यो फाइल खाता ब्याकअप होइन।';

  @override
  String get save => 'सुरक्षित गर्नुहोस्';

  @override
  String get change => 'परिवर्तन';

  @override
  String get all => 'सबै';

  @override
  String get none => 'कुनै पनि होइन';

  @override
  String get code => 'कोड';

  @override
  String get role => 'भूमिका';

  @override
  String get filter => 'फिल्टर';

  @override
  String get sort => 'क्रमबद्ध';

  @override
  String get optional => 'वैकल्पिक';

  @override
  String get pendingChanges => 'पर्खाइमा रहेका परिवर्तन';

  @override
  String get confirm => 'पुष्टि गर्नुहोस्';

  @override
  String get close => 'बन्द गर्नुहोस्';

  @override
  String get yes => 'हो';

  @override
  String get no => 'होइन';

  @override
  String get signInToYourAccount => 'आफ्नो खातामा साइन इन गर्नुहोस्';

  @override
  String get createYourAccountTitle => 'आफ्नो डिजिटल खाता खाता बनाउनुहोस्';

  @override
  String get getStarted => 'सुरु गर्नुहोस्';

  @override
  String get fullNamePlaceholder => 'पूरा नाम';

  @override
  String get phoneNumberPlaceholder => 'फोन नम्बर';

  @override
  String get phoneOptional => 'फोन नम्बर (वैकल्पिक)';

  @override
  String get pan => 'स्थायी लेखा नम्बर';

  @override
  String get businessNameRequired => 'व्यवसायको नाम *';

  @override
  String get createNewBusiness => 'नयाँ व्यवसाय बनाउनुहोस्';

  @override
  String get businesses => 'व्यवसायहरू';

  @override
  String couldNotCreateBusiness(String error) => 'व्यवसाय बनाउन सकिएन: $error';

  @override
  String couldNotSwitchBusiness(String error) =>
      'व्यवसाय परिवर्तन गर्न सकिएन: $error';

  @override
  String couldNotUpdateProfile(String error) =>
      'प्रोफाइल अद्यावधिक गर्न सकिएन: $error';

  @override
  String get profileUpdated => 'प्रोफाइल अद्यावधिक भयो';

  @override
  String changeRoleFor(String name) => 'भूमिका परिवर्तन — $name';

  @override
  String couldNotChangeRole(String error) =>
      'भूमिका परिवर्तन गर्न सकिएन: $error';

  @override
  String removeMember(String name) => '$name हटाउने?';

  @override
  String get removeMemberWarning => 'उनीहरूले यो व्यवसायमा पहुँच गुमाउनेछन्।';

  @override
  String couldNotRemoveMember(String error) => 'सदस्य हटाउन सकिएन: $error';

  @override
  String inviteFailed(String error) => 'निमन्त्रणा असफल: $error';

  @override
  String get noStaffMembersYet => 'अहिलेसम्म कुनै कर्मचारी छैन';

  @override
  String get productNameRequired => 'उत्पादनको नाम *';

  @override
  String get searchNameSkuBarcode => 'नाम, SKU वा बारकोड खोज्नुहोस्';

  @override
  String get noProductsFound => 'कुनै उत्पादन भेटिएन';

  @override
  String get costPriceRs => 'लागत मूल्य (रु.)';

  @override
  String get sellingPriceRsRequired => 'बिक्री मूल्य (रु.) *';

  @override
  String get wholesalePriceRs => 'थोक मूल्य (रु.)';

  @override
  String get taxRatePercent => 'कर दर (%)';

  @override
  String get openingStockQuantity => 'सुरुको स्टक मात्रा';

  @override
  String get minimumQuantityHint => 'न्यूनतम मात्रा (० = चेतावनी छैन)';

  @override
  String get inactiveProductsNote =>
      'निष्क्रिय उत्पादनहरू रहन्छन् तर बिक्रीबाट लुकाइन्छ';

  @override
  String get deleteProductQuestion => 'उत्पादन मेट्ने?';

  @override
  String get deleteProductWarning =>
      'उत्पादन सूचीबाट लुकाइनेछ। स्टक इतिहास रहनेछ।';

  @override
  String get loadingProduct => 'उत्पादन लोड हुँदैछ…';

  @override
  String couldNotLoadProduct(String error) => 'उत्पादन लोड गर्न सकिएन: $error';

  @override
  String get byCategory => 'श्रेणी अनुसार';

  @override
  String get expensesByCategory => 'श्रेणी अनुसार खर्च';

  @override
  String get categoriesNoCategories => 'अहिलेसम्म कुनै श्रेणी छैन';

  @override
  String get noCategory => 'श्रेणी छैन';

  @override
  String get deleteCategoryQuestion => 'श्रेणी मेट्ने?';

  @override
  String get categoryDeleteNote =>
      'यो श्रेणीका उत्पादनहरू श्रेणी बिना पनि काम गर्नेछन्।';

  @override
  String get categoryRequired => 'श्रेणी *';

  @override
  String get noUnit => 'एकाइ छैन';

  @override
  String get unitNameHint => 'नाम * (जस्तै पिस)';

  @override
  String get unitShortHint => 'छोटो नाम * (जस्तै pc)';

  @override
  String get unitsNoUnits => 'अहिलेसम्म कुनै एकाइ छैन';

  @override
  String get deleteUnitQuestion => 'एकाइ मेट्ने?';

  @override
  String get unitDeleteNote =>
      'यो एकाइ प्रयोग गर्ने उत्पादनहरू एकाइ बिना पनि काम गर्नेछन्।';

  @override
  String get movementHistory => 'चलन इतिहास';

  @override
  String get noStockMovementsYet => 'अहिलेसम्म कुनै स्टक चलन छैन';

  @override
  String get customQuantityHint => 'अनुकूल मात्रा (+ भित्र / - बाहिर)';

  @override
  String get quantityExample => 'जस्तै २.५ वा -३';

  @override
  String get reasonExample => 'जस्तै स्टक गणना, क्षति';

  @override
  String get stockValuation => 'स्टक मूल्यांकन';

  @override
  String currentStockIs(String quantity) => 'हालको स्टक: $quantity';

  @override
  String balanceIs(String quantity) => 'मौज्दात $quantity';

  @override
  String get nameRequired => 'नाम *';

  @override
  String get partyNameExample => 'नाम * (जस्तै पिस)';

  @override
  String get creditLimitRs => 'उधारो सीमा (रु.)';

  @override
  String get openingBalanceRs => 'सुरुको मौज्दात (रु.)';

  @override
  String get walkInNone => 'हिँड्ने ग्राहक / कोही नहीं';

  @override
  String deletePartyQuestion(String kind) => '$kind मेट्ने?';

  @override
  String get partyDeleteNote => 'पक्ष सूचीबाट लुकाइनेछ। खाता इतिहास रहनेछ।';

  @override
  String get khataHistoryKept => 'खाता इतिहास रहनेछ।';

  @override
  String get createSale => 'बिक्री बनाउनुहोस्';

  @override
  String get createPurchase => 'खरिद बनाउनुहोस्';

  @override
  String get createInvoice => 'बिजक बनाउनुहोस्';

  @override
  String get createQuotation => 'कोटेशन बनाउनुहोस्';

  @override
  String get noItemsYetAddProduct =>
      'अहिलेसम्म कुनै वस्तु छैन — उत्पादन थप्नुहोस्';

  @override
  String get addFreeText => 'स्वतन्त्र पाठ थप्नुहोस्';

  @override
  String get items => 'वस्तुहरू';

  @override
  String itemsCount(int count) => 'वस्तुहरू ($count)';

  @override
  String get extraDiscountRs => 'अतिरिक्त छुट (रु.)';

  @override
  String get paidNowRs => 'अहिले तिरिएको (रु.)';

  @override
  String get paidAmountRs => 'तिरिएको रकम (रु.)';

  @override
  String get amountRsRequired => 'रकम (रु.) *';

  @override
  String lineTotalIs(String total) => 'हरफ जम्मा: $total';

  @override
  String invoiceNumberLabel(String number) => 'बिजक $number';

  @override
  String quotationNumberLabel(String number) => 'कोटेशन $number';

  @override
  String issuedOn(String date) => 'जारी $date';

  @override
  String dueOn(String date) => 'म्याद $date';

  @override
  String validUntilOn(String date) => 'मान्य मिति $date';

  @override
  String convertedToSale(int id) => 'बिक्री #$id मा रूपान्तरित';

  @override
  String get lineItemsCopiedNote =>
      'चयन गरिएको बिक्रीबाट हरफहरू र तिनका मूल्यहरू प्रतिलिपि गरिनेछ।';

  @override
  String get noneBuildManually => 'कुनै पनि होइन (म्यानुअल बनाउनुहोस्)';

  @override
  String get notesOptional => 'टिप्पणी (वैकल्पिक)';

  @override
  String termsLabel(String terms) => 'सर्तहरू: $terms';

  @override
  String notesLabel(String notes) => 'टिप्पणी: $notes';

  @override
  String get sharePdf => 'PDF साझा गर्नुहोस्';

  @override
  String get exportCsv => 'CSV निर्यात गर्नुहोस्';

  @override
  String get deleteSaleQuestion => 'बिक्री मेट्ने?';

  @override
  String get deletePurchaseQuestion => 'खरिद मेट्ने?';

  @override
  String get deleteInvoiceQuestion => 'बिजक मेट्ने?';

  @override
  String get deleteQuotationQuestion => 'कोटेशन मेट्ने?';

  @override
  String get deleteExpenseQuestion => 'खर्च मेट्ने?';

  @override
  String get deleteIncomeQuestion => 'आय मेट्ने?';

  @override
  String get deleteMethodQuestion => 'विधि मेट्ने?';

  @override
  String get saleDeleteNote =>
      'स्टक पुनर्स्थापित हुनेछ र ग्राहक खाता उल्टाइनेछ।';

  @override
  String get purchaseDeleteNote =>
      'स्टक घटाइनेछ र आपूर्तिकर्ता खाता उल्टाइनेछ।';

  @override
  String get expenseDeleteNote => 'यो खर्च स्थायी रूपमा हटाइनेछ।';

  @override
  String get incomeDeleteNote => 'यो आय रेकर्ड स्थायी रूपमा हटाइनेछ।';

  @override
  String get invoiceDeleteNote => 'यो बिजक स्थायी रूपमा हटाइनेछ।';

  @override
  String get quotationDeleteNote => 'यो कोटेशन स्थायी रूपमा हटाइनेछ।';

  @override
  String get searchInvoiceOrCustomer => 'बिजक वा ग्राहक खोज्नुहोस्';

  @override
  String get searchBillOrSupplier => 'बिल वा आपूर्तिकर्ता खोज्नुहोस्';

  @override
  String get searchQuotationOrCustomer => 'कोटेशन वा ग्राहक खोज्नुहोस्';

  @override
  String get searchPartyOrReference => 'पक्ष वा सन्दर्भ खोज्नुहोस्';

  @override
  String get paymentMethod => 'भुक्तानी विधि';

  @override
  String get addMethod => 'विधि थप्नुहोस्';

  @override
  String get noPaymentMethodsYet => 'अहिलेसम्म कुनै भुक्तानी विधि छैन';

  @override
  String get setAsDefault => 'पूर्वनिर्धारित बनाउनुहोस्';

  @override
  String get methodChangeNote =>
      'यो विधिबाट पहिले नै रेकर्ड भएका भुक्तानीहरू काम गरिरहन्छन्।';

  @override
  String advanceIs(String amount) => 'अग्रिम $amount';

  @override
  String dueToCustomerKhata(String amount) => 'बाँकी $amount → ग्राहक खाता';

  @override
  String dueToSupplierKhata(String amount) =>
      'बाँकी $amount → आपूर्तिकर्ता खाता';

  @override
  String get advancesAreMoney =>
      'अग्रिम भनेको तपाईंसँग पहिले नै रहेको रकम हो, त्यसैले पहिले लागू गरिन्छ।';

  @override
  String advancesLabel(String list) => 'अग्रिमहरू: $list';

  @override
  String get addProductButton => 'उत्पादन थप्नुहोस्';

  @override
  String get addReminderButton => 'सम्झना थप्नुहोस्';

  @override
  String get receivablesAndPayables => 'प्राप्य र भुक्तानीय';

  @override
  String receivablesCount(int count) => 'प्राप्य · $count';

  @override
  String payablesCount(int count) => 'भुक्तानीय · $count';

  @override
  String get profitAndLoss => 'नाफा र घाटा';

  @override
  String get salesReportTitle => 'बिक्री प्रतिवेदन';

  @override
  String get revenueExcludesVat => 'आम्दानीमा भ्याट समावेश छैन।';

  @override
  String get salesTrendLast14 => 'बिक्री प्रवृत्ति · अन्तिम १४ दिन';

  @override
  String salesTrendScope(String scope) => 'बिक्री प्रवृत्ति · $scope';

  @override
  String get topProducts => 'प्रमुख उत्पादनहरू';

  @override
  String get topCustomers => 'प्रमुख ग्राहकहरू';

  @override
  String get bySource => 'स्रोत अनुसार';

  @override
  String get incomeTrend => 'आय प्रवृत्ति';

  @override
  String get lastCycle => 'अघिल्लो चक्र';

  @override
  String get noDataYet => 'अहिलेसम्म कुनै डाटा छैन';

  @override
  String couldNotLoad(String error) => 'लोड गर्न सकिएन: $error';

  @override
  String get couldNotLoadSummary => 'सारांश लोड गर्न सकिएन';

  @override
  String get dashboardUnavailable => 'ड्यासबोर्ड उपलब्ध छैन';

  @override
  String productsCount(int count) => '$count उत्पादन';

  @override
  String unitsDocsCount(String quantity, int count) =>
      '$quantity एकाइ · $count बिजक';

  @override
  String quantityTimesPrice(String quantity, String price) =>
      '$quantity × $price';

  @override
  String lowStockNote(String name) => '$name स्टक कम';

  @override
  String get syncTitle => 'सिंक';

  @override
  String get syncStatusTitle => 'सिंक स्थिति';

  @override
  String get lastSyncLabel => 'अन्तिम सिंक';

  @override
  String get pendingChangesCount => 'पर्खाइमा रहेका परिवर्तन';

  @override
  String syncFailed(String error) => 'सिंक असफल: $error';

  @override
  String operationFailed(String operation) => '$operation असफल भयो';

  @override
  String get conflicts => 'द्वन्द्वहरू';

  @override
  String get noConflicts => 'कुनै द्वन्द्व छैन';

  @override
  String entityRef(String type, int id) => '$type #$id';

  @override
  String get serverChanged => 'सर्भर परिवर्तन: ';

  @override
  String serverVersion(String json) => 'सर्भर संस्करण: $json';

  @override
  String operationDetail(String operation) => 'सञ्चालन: $operation';

  @override
  String get pushed => 'पठाइयो';

  @override
  String get pulled => 'तानियो';

  @override
  String rejectedWithError(String error) => 'अस्वीकृत: $error';

  @override
  String get backupSubject => 'खाता ब्याकअप';

  @override
  String get backupShareText => 'यो यन्त्रबाट खाता ब्याकअप निर्यात गरियो।';

  @override
  String recordsAddedCount(int count) => '$count रेकर्ड थपियो';

  @override
  String alreadyPresentCount(int count) => '$count पहिले नै थियो, छाडियो';

  @override
  String addedCount(int count) => '$count थपियो';

  @override
  String addedKeptCount(int count, int kept) => '$count थपियो, $kept राखियो';

  @override
  String get reminderRepeatNote => 'दोहोरिने सम्झना आफैं पुनः तालिका बनाउँछ।';

  @override
  String get profileLabel => 'प्रोफाइल';

  @override
  String get languageEnglish => 'अंग्रेजी';

  @override
  String get languageNepali => 'नेपाली';

  @override
  String get calendarLabel => 'पात्रो';

  @override
  String get generalSection => 'सामान्य';

  @override
  String get dateLabel => 'मिति';

  @override
  String get descriptionLabel => 'विवरण';

  @override
  String get fromLabel => 'देखि';

  @override
  String get toLabel => 'सम्म';

  @override
  String get titleRequired => 'शीर्षक *';

  @override
  String get sourceRequired => 'स्रोत *';

  @override
  String get taxExample => 'जस्तै १३';

  @override
  String get amountExample => 'जस्तै २०.००';

  @override
  String get quantityExample16 => 'जस्तै १६.००';

  @override
  String get rateExample => 'जस्तै २५';

  @override
  String get plusOne => '+१';

  @override
  String get plusTen => '+१०';

  @override
  String get minusOne => '-१';

  @override
  String get minusTen => '-१०';

  @override
  String get phonePrefixHint => '+९७७ ९८XXXXXXXX';

  @override
  String get rankLabel => '#';

  @override
  String editKind(String kind) => '$kind सम्पादन गर्नुहोस्';

  @override
  String newKind(String kind) => 'नयाँ $kind';

  @override
  String get delete => 'मेट्नुहोस्';

  @override
  String get edit => 'सम्पादन गर्नुहोस्';

  @override
  String get convert => 'रूपान्तरण गर्नुहोस्';

  @override
  String get exportTitle => 'निर्यात';

  @override
  String get restoreTitle => 'पुनर्स्थापना';

  @override
  String get expenseTrend => 'खर्च प्रवृत्ति';

  @override
  String get opening => 'सुरुको';

  @override
  String get filterByCategory => 'श्रेणी अनुसार फिल्टर';

  @override
  String get phoneLabel => 'फोन';

  @override
  String get emailMustHaveAccount => 'इमेल (खाता हुनु आवश्यक छ)';

  @override
  String get advancesExplainer =>
      'अग्रिम भनेको तपाईंसँग पहिले नै रहेको (ग्राहक) वा पहिले नै तिरेको (आपूर्तिकर्ता) रकम हो, त्यसैले नयाँ भुक्तानीअघि लागू गरिन्छ।';

  @override
  String get backupExportExplainerFull =>
      'सक्रिय व्यवसायका सबै उत्पादन, पक्ष, बिक्री, खरिद, खर्च, आय, भुक्तानी, बिजक र कोटेशन सुरक्षित गर्छ। मेटिएका रेकर्डहरू पनि राखिन्छन्, त्यसैले इतिहास जोगिन्छ।';

  @override
  String get backupRestoreExplainerFull =>
      'पुनर्स्थापनाले ब्याकअपलाई यो व्यवसायमा गाभ्छ। पहिले नै रहेका रेकर्डहरू छाडिन्छन् — कुनै पनि अधिलेखन गरिँदैन, किनकि पुनर्लेखन गरिएको बिक्री वा भुक्तानीले खाता बहीखातालाई आफैंसँग बाझ्ने बनाउँछ।';

  @override
  String get backupNotIncludedExplainer =>
      'खाता बहीखाताका प्रविष्टि र स्टक चलनहरू माथिका कागजातबाट व्युत्पन्न हुन्छन्, त्यसैले तिनीहरू प्रतिलिपि नगरी ती सञ्चालनहरू पुनः खेलेर पुनर्निर्माण गरिन्छ। त्यसैले पुनर्स्थापनाले तपाईंका रेकर्डहरू फर्काउँछ, क्यास गरिएका जम्मा होइन।';

  @override
  String get restoreConfirmBodyFull =>
      'यो व्यवसायमा पहिले नै रहेका रेकर्डहरू छाडिनेछन्। यहाँ हाल रहेका कुनै पनि परिमार्जन वा मेटिने छैनन्।';

  @override
  String get methodChangeNoteFull =>
      'यो विधिबाट पहिले नै रेकर्ड भएका भुक्तानीहरू काम गरिरहन्छन्। विधिको नाम परिवर्तनले इतिहास पुनर्लेखन गर्दैन।';

  @override
  String get saleDeleteNoteFull =>
      'स्टक पुनर्स्थापित हुनेछ र ग्राहक खाता उल्टाइनेछ।';

  @override
  String get purchaseDeleteNoteFull =>
      'स्टक घटाइनेछ र आपूर्तिकर्ता खाता उल्टाइनेछ।';

  @override
  String get lineItemsCopiedNoteFull =>
      'चयन गरिएको बिक्रीबाट हरफहरू र तिनका मूल्यहरू प्रतिलिपि गरिनेछ।';

  @override
  String get notificationsInAppNoteFull =>
      'इन-एप सूचनाहरू सधैं रेकर्ड हुन्छन्। यी स्विचहरूले पुश डेलिभरी मात्र नियन्त्रण गर्छन्।';

  @override
  String unitNameShort(String name, String short) => '$name ($short)';

  @override
  String retailValue(String amount) => 'खुद्रा $amount';

  @override
  String advanceAmount(String amount) => 'अग्रिम $amount';

  @override
  String quantityWithUnit(String quantity, String unit) => '$quantity$unit';

  @override
  String productPricePair(String price) => '$price  •  ';

  @override
  String saleCustomerLine(String number, String customer) =>
      '$number — $customer';

  @override
  String lineTotalAmount(String amount) => 'हरफ जम्मा: $amount';

  @override
  String conflictsCount(int count) => '$count द्वन्द्व';

  @override
  String get noDataInRange => 'यो अवधिमा कुनै डेटा छैन';

  @override
  String get nothingToBreakDown => 'तोड्ने कुनै कुरा छैन';

  @override
  String get noProductsMatchFilter => 'यो फिल्टरसँग मिल्ने कुनै उत्पादन छैन';

  @override
  String get noProductsSoldInRange => 'यो अवधिमा कुनै उत्पादन बिक्री भएन';

  @override
  String get noSalesToCustomersInRange => 'यो अवधिमा ग्राहकलाई कुनै बिक्री भएन';

  @override
  String get nobodyOwesYou => 'कसैले तपाईंलाई पैसा तिर्नु छैन';

  @override
  String get youOweNobody => 'तपाईंले कसैलाई पैसा तिर्नु छैन';

  @override
  String addLabel(String label) => 'थप्नुहोस् $label';

  @override
  String couldNotLoadX(String subject, String error) =>
      '$subject लोड गर्न सकिएन।\n$error';

  @override
  String get balances => 'बाँकी रकम';

  @override
  String get expenseReport => 'खर्च प्रतिवेदन';

  @override
  String get incomeReport => 'आय प्रतिवेदन';

  @override
  String get stockReportTitle => 'स्टक प्रतिवेदन';

  @override
  String get expenseReportTitle => 'खर्च प्रतिवेदन';

  @override
  String get incomeReportTitle => 'आय प्रतिवेदन';

  @override
  String get profitAndLossTitle => 'नाफा–नोक्सान';

  @override
  String get stockMovements => 'स्टक चलन';

  @override
  String get devices => 'उपकरणहरू';

  @override
  String emailAndRole(String email, String role) => '$email\n$role';

  @override
  String addKind(String kind) => '$kind थप्नुहोस्';

  @override
  String lowAtOrBelow(String quantity, String unit) =>
      'कम: $quantity$unit वा कम';

  @override
  String minimumIs(String quantity, String unit) => 'न्यूनतम $quantity$unit';

  @override
  String savedTo(String path) => 'यहाँ सुरक्षित गरियो: $path';

  @override
  String get emailRequired => 'कृपया आफ्नो इमेल लेख्नुहोस्';

  @override
  String get emailInvalid => 'कृपया मान्य इमेल लेख्नुहोस्';

  @override
  String get passwordRequired => 'कृपया आफ्नो पासवर्ड लेख्नुहोस्';

  @override
  String get passwordRegisterRequired => 'कृपया पासवर्ड लेख्नुहोस्';

  @override
  String get passwordTooShort => 'पासवर्ड कम्तीमा ८ अक्षरको हुनुपर्छ';

  @override
  String get passwordNeedsDigit => 'पासवर्डमा कम्तीमा एक अंक हुनुपर्छ';

  @override
  String get confirmPasswordRequired => 'कृपया पासवर्ड पुष्टि गर्नुहोस्';

  @override
  String get passwordsDoNotMatch => 'पासवर्डहरू मिलेनन्';

  @override
  String get fullNameRequired => 'कृपया आफ्नो पूरा नाम लेख्नुहोस्';

  @override
  String get fullNameIsRequired => 'पूरा नाम आवश्यक छ';

  @override
  String get businessNameIsRequired => 'व्यवसायको नाम आवश्यक छ';

  @override
  String get amountRequired => 'रकम आवश्यक छ';

  @override
  String get amountInvalid => 'मान्य रकम लेख्नुहोस्';

  @override
  String get amountInvalidFull => 'मान्य रकम लेख्नुहोस्।';

  @override
  String get amountMustBePositive => 'रकम शून्यभन्दा बढी हुनुपर्छ।';

  @override
  String get quantityInvalid => 'मान्य परिमाण लेख्नुहोस्';

  @override
  String get percentRange => '०–१०० लेख्नुहोस्';

  @override
  String get panMustBe9Digits => 'प्यान ९ अंकको हुनुपर्छ।';

  @override
  String get panMustBe9DigitNumber => 'प्यान ९ अंकको संख्या हुनुपर्छ';

  @override
  String get phoneInvalid => 'फोन नम्बरको ढाँचा मिलेन।';

  @override
  String get emailAddressRequired => 'मान्य इमेल ठेगाना आवश्यक छ।';

  @override
  String get invalidEmailOrPassword => 'इमेल वा पासवर्ड मिलेन।';

  @override
  String get checkYourInput => 'कृपया आफ्नो जानकारी जाँच्नुहोस्।';

  @override
  String get somethingWentWrong =>
      'केही गडबड भयो। कृपया फेरि प्रयास गर्नुहोस्।';

  @override
  String get returnIn => 'फिर्ता आएको';

  @override
  String get returnOut => 'फिर्ता गएको';

  @override
  String get week => 'हप्ता';

  @override
  String get month => 'महिना';

  @override
  String get day => 'दिन';

  @override
  String todayAt(String time) => 'आज $time';

  @override
  String tomorrowAt(String time) => 'भोलि $time';

  @override
  String yesterdayAt(String time) => 'हिजो $time';

  @override
  String noKindMatchSearch(String kind) => 'तपाईंको खोजसँग मिल्ने $kind छैन';

  @override
  String noKindYet(String kind) => 'अहिलेसम्म $kind छैन';

  @override
  String get categoryReminder => 'सम्झना';

  @override
  String get saved => 'सुरक्षित भयो';

  @override
  String get productSaved => 'उत्पादन सुरक्षित भयो';

  @override
  String get walkInCustomer => 'हिँडेर आएको ग्राहक';

  @override
  String get notSet => 'सेट गरिएको छैन';

  @override
  String get unpaid => 'नतिरेको';

  @override
  String get noSupplier => 'आपूर्तिकर्ता छैन';

  @override
  String get paidInFull => 'पूरै तिरिएको';

  @override
  String get exporting => 'निर्यात हुँदैछ...';

  @override
  String get saving => 'सुरक्षित हुँदैछ...';

  @override
  String get noLowStockProducts => 'कुनै उत्पादन स्टक सकिएको छैन — सबै ठीक छ!';

  @override
  String get noProductsMatchSearch => 'तपाईंको खोजसँग मिल्ने कुनै उत्पादन छैन';

  @override
  String get showingUnread => 'नपढेका मात्र देखाइँदै';

  @override
  String get customerKhata => 'ग्राहक खाता';

  @override
  String get debit => 'डेबिट';

  @override
  String get recordReceipt => 'रसिद अभिलेख गर्नुहोस्';

  @override
  String get applyToInvoice => 'बिजकमा लागू गर्नुहोस्';

  @override
  String get receipt => 'रसिद';

  @override
  String get roleViewer => 'दर्शक';

  @override
  String get never => 'कहिल्यै छैन';

  @override
  String get syncing => 'सिङ्क हुँदैछ…';

  @override
  String moneyInOut(String inAmount, String outAmount) =>
      'आम्दानी $inAmount · खर्च $outAmount';

  @override
  String dueAmount(String amount) => 'बाँकी $amount';

  @override
  String get created => 'बनाइयो';

  @override
  String get productCreated => 'उत्पादन बनाइयो';

  @override
  String toCollectAmount(String amount) => 'संकलन गर्नु $amount';

  @override
  String toPayAmount(String amount) => 'तिर्नु $amount';

  @override
  String get createProduct => 'उत्पादन बनाउनुहोस्';

  @override
  String get create => 'बनाउनुहोस्';

  @override
  String get noProductsYet => 'अहिलेसम्म कुनै उत्पादन छैन';

  @override
  String get noProductsYetAddFirst =>
      'अहिलेसम्म कुनै उत्पादन छैन — पहिलो उत्पादन थप्नुहोस्';

  @override
  String get subtotal => 'उपजम्मा';

  @override
  String get total => 'जम्मा';

  @override
  String get discount => 'छुट';

  @override
  String get rateRs => 'दर (रु.)';

  @override
  String get discountRs => 'छुट (रु.)';

  @override
  String get addAtLeastOneItem => 'कम्तीमा एक वस्तु थप्नुहोस्';

  @override
  String get costValue => 'लागत मूल्य';

  @override
  String get potentialMargin => 'सम्भावित मार्जिन';

  @override
  String get invoiceCreated => 'बिजक बनाइयो';

  @override
  String get invoiceDeleted => 'बिजक मेटियो';

  @override
  String get quotationCreated => 'भनसुन बनाइयो';

  @override
  String get quotationDeleted => 'भनसुन मेटियो';

  @override
  String get convertedToSaleToast => 'बिक्रीमा परिणत गरियो';

  @override
  String get saleCreated => 'बिक्री बनाइयो';

  @override
  String get saleReversed => 'बिक्री उल्टाइयो';

  @override
  String get saleKeptAsReversed => 'बिक्री इतिहासमा उल्टाइएको रूपमा रहन्छ।';

  @override
  String get creditSaleNeedsCustomer => 'उधारो बिक्रीको लागि ग्राहक आवश्यक छ';

  @override
  String get purchaseCreated => 'खरिद बनाइयो';

  @override
  String get purchaseReversed => 'खरिद उल्टाइयो';

  @override
  String get purchaseKeptAsReversed => 'खरिद इतिहासमा उल्टाइएको रूपमा रहन्छ।';

  @override
  String get creditPurchaseNeedsSupplier =>
      'उधारो खरिदको लागि आपूर्तिकर्ता आवश्यक छ';

  @override
  String get paymentRecorded => 'भुक्तानी अभिलेख भयो';

  @override
  String get methodSaved => 'विधि सुरक्षित भयो';

  @override
  String get methodDeleted => 'विधि मेटियो';

  @override
  String get categorySaved => 'कोटी सुरक्षित भयो';

  @override
  String get categoryDeleted => 'कोटी मेटियो';

  @override
  String get productDeleted => 'उत्पादन मेटियो';

  @override
  String get unitSaved => 'एकाइ सुरक्षित भयो';

  @override
  String get unitDeleted => 'एकाइ मेटियो';

  @override
  String get settingsSaved => 'सेटिङ सुरक्षित भयो';

  @override
  String get atLeastOneMethodMustRemain => 'कम्तीमा एक भुक्तानी विधि रहनुपर्छ।';

  @override
  String get notAkhataBackup => 'यो खाताको ब्याकअप होइन।';

  @override
  String get enterNonZeroQuantity => 'शून्य नभएको परिमाण लेख्नुहोस्';

  @override
  String get enterAmountGreaterThanZero => 'शून्यभन्दा बढी रकम लेख्नुहोस्';

  @override
  String balanceAfterIs(String quantity) => 'बाँकी $quantity';

  @override
  String get rejectedAndFailed => 'अस्वीकृत र असफल';

  @override
  String get entries => 'प्रविष्टिहरू';

  @override
  String get average => 'औसत';

  @override
  String get sources => 'स्रोतहरू';

  @override
  String get revenue => 'आम्दानी';

  @override
  String get costOfGoodsSold => 'बिक्री भएका वस्तुको लागत';

  @override
  String get grossProfit => 'कुल नाफा';

  @override
  String get otherIncome => 'अन्य आय';

  @override
  String get netProfit => 'खुद नाफा';

  @override
  String get taxCollectedInPeriod => 'यो अवधिमा संकलित कर: ';

  @override
  String get customerAdvances => 'ग्राहक अग्रिम';

  @override
  String get supplierAdvances => 'आपूर्तिकर्ता अग्रिम';

  @override
  String get advancesExplain =>
      'अग्रिम भन्नाले तपाईंसँग भइसकेको (ग्राहक) वा बढी तिरिएको (आपूर्तिकर्ता) रकम।';

  @override
  String get reportSalesBlurb => 'प्रवृत्ति, जम्मा, शीर्ष उत्पादन र ग्राहक';

  @override
  String get reportProfitLossBlurb => 'आम्दानी, बिक्री लागत र खुद नाफा';

  @override
  String get reportExpenseBlurb => 'पैसा कहाँ गयो, कोटी अनुसार';

  @override
  String get reportIncomeBlurb => 'स्रोत अनुसार अन्य आय';

  @override
  String get reportStockBlurb => 'भण्डारको लागत र खुद्रा मूल्य';

  @override
  String get reportReceivableBlurb => 'कसले तिर्नु छ र तपाईंले कसलाई';

  @override
  String get ledgerOwesYouHint =>
      'उनीहरूले तिर्नु पर्ने (ग्राहक) / तपाईंले तिरेको (आपूर्तिकर्ता)';

  @override
  String get ledgerYouOweHint =>
      'तपाईंलाई तिरेको (ग्राहक) / तपाईंले तिर्नु पर्ने (आपूर्तिकर्ता)';

  @override
  String get roleOwner => 'मालिक';

  @override
  String get roleAdmin => 'प्रशासक';

  @override
  String get roleManager => 'प्रबन्धक';

  @override
  String get roleAccountant => 'लेखाकार';

  @override
  String get noBusiness => 'व्यवसाय छैन';

  @override
  String couldNotLoadProducts(String error) =>
      'उत्पादनहरू लोड गर्न सकिएन।\\n$error';

  @override
  String get lineItemsCopiedFromSale =>
      'चयन गरिएको बिक्रीबाट वस्तुहरू प्रतिलिपि गरिनेछ र त्यसको बिजक नम्बर पुनः प्रयोग हुनेछ।';

  @override
  String bsRange(String from, String to) => 'वि.सं.: $from  →  $to';

  @override
  String conflictsNamed(int count) => 'द्वन्द्व ($count)';

  @override
  String get retailValueReport => 'खुद्रा मूल्य';

  @override
  String selectPartyKind(String kind) => '$kind चयन गर्नुहोस्';

  @override
  String get tax => 'कर';

  @override
  String get qty => 'परिमाण';

  @override
  String get adjustment => 'समायोजन';

  @override
  String get showingAll => 'सबै देखाइँदै';

  @override
  String get supplierKhata => 'आपूर्तिकर्ता खाता';

  @override
  String get applyToBill => 'खरिद बिलमा लागू गर्नुहोस्';

  @override
  String get newMethod => 'नयाँ भुक्तानी विधि';

  @override
  String get today => 'आज';

  @override
  String get municipality => 'नगरपालिका';

  @override
  String get selectProvinceHint => 'प्रदेश छान्नुहोस्';

  @override
  String get selectDistrictHint => 'जिल्ला छान्नुहोस्';

  @override
  String get selectMunicipalityHint => 'नगरपालिका छान्नुहोस्';

  @override
  String get municipalityFreeTextHint =>
      'नगरपालिका टाइप गर्नुहोस् — सबै स्थानीय तह यहाँ सूचीबद्ध छैनन्।';

  @override
  String get phoneInvalidNepali =>
      'मान्य नेपाली फोन नम्बर राख्नुहोस्, जस्तै 98XXXXXXXX';

  @override
  String get fromDate => 'देखि';

  @override
  String get toDate => 'सम्म';

  @override
  String get back => 'पछाडि';

  @override
  String get next => 'अर्को';

  @override
  String get endBeforeStart => 'अन्त्य मिति सुरु मितिभन्दा पहिले हुन सक्दैन।';

  @override
  String get dateRange => 'मिति दायरा';

  @override
  String get toolsTitle => 'उपकरण';

  @override
  String get emiCalculator => 'ईएमआई क्यालकुलेटर';

  @override
  String get loanAmount => 'ऋण रकम (रु.)';

  @override
  String get annualInterestRate => 'वार्षिक ब्याज दर (%)';

  @override
  String get loanTermMonths => 'ऋण अवधि (महिना)';

  @override
  String get monthlyEmi => 'मासिक किस्ता';

  @override
  String get totalPayment => 'कुल भुक्तानी';

  @override
  String get totalInterest => 'कुल ब्याज';

  @override
  String get interestCalculator => 'ब्याज क्यालकुलेटर';

  @override
  String get simpleInterest => 'सरल ब्याज';

  @override
  String get compoundInterest => 'चक्रिय ब्याज';

  @override
  String get principal => 'मूलधन';

  @override
  String get years => 'वर्ष';

  @override
  String get compoundingPerYear => 'प्रति वर्ष चक्रिय संख्या';

  @override
  String get interestEarned => 'कमाइएको ब्याज';

  @override
  String get profitCalculator => 'नाफा क्यालकुलेटर';

  @override
  String get profit => 'नाफा';

  @override
  String get profitMargin => 'नाफा अनुपात';

  @override
  String get markup => 'मार्कअप';

  @override
  String get enterValidAmount => 'मान्य रकम राख्नुहोस्';

  @override
  String get maturityAmount => 'परिपक्वता रकम';

  @override
  String get calculate => 'गणना गर्नुहोस्';

  @override
  String get lossWarning => 'यो नाफा होइन, नोक्सानी हो।';

  @override
  String get appLock => 'एप लक';

  @override
  String get appLockDescription => 'एप खोल्न पिन आवश्यक पार्नुहोस्';

  @override
  String get setPin => 'पिन सेट गर्नुहोस्';

  @override
  String get changePin => 'पिन बदल्नुहोस्';

  @override
  String get enterPin => 'आफ्नो पिन राख्नुहोस्';

  @override
  String get confirmPin => 'पिन पुष्टि गर्नुहोस्';

  @override
  String get currentPin => 'हालको पिन';

  @override
  String get newPin => 'नयाँ पिन';

  @override
  String get pinMustBe4To6Digits => 'पिन ४ देखि ६ अंकको हुनुपर्छ';

  @override
  String get pinsDoNotMatch => 'पिन मिलेन';

  @override
  String get incorrectPin => 'गलत पिन';

  @override
  String get unlock => 'खोल्नुहोस्';

  @override
  String get turnOffAppLock => 'एप लक बन्द गर्नुहोस्';

  @override
  String get appLockNowOn => 'एप लक खुला छ';

  @override
  String get appLockNowOff => 'एप लक बन्द छ';

  @override
  String attemptsLeft(int count) => '$count प्रयास बाँकी';

  @override
  String get bankAccounts => 'बैंक खाताहरू';

  @override
  String get bankName => 'बैंकको नाम';

  @override
  String get accountName => 'खाताको नाम';

  @override
  String get accountNumber => 'खाता नम्बर';

  @override
  String get branch => 'शाखा';

  @override
  String get defaultAccount => 'पूर्वनिर्धारित खाता';

  @override
  String get noBankAccountsYet => 'बैंक खाता थपिएको छैन।';

  @override
  String get addBankAccount => 'बैंक खाता थप्नुहोस्';

  @override
  String paymentsThroughAccount(int count, String total) =>
      '$count भुक्तानी · $total';

  @override
  String get deleted => 'मेटाइयो';

  @override
  String get importTile => 'आयात';

  @override
  String get importTitle => 'एक्सेलबाट आयात गर्नुहोस्';

  @override
  String get importExplainerTitle => 'कसरी काम गर्छ';

  @override
  String get importExplainerBody =>
      'तपाईंको स्प्रेडसिटको पङ्क्तिहरू यहाँ टाँस्नुहोस्। टेम्प्लेट प्रतिलिपि गरेर एक्सेलमा खोल्नुहोस्, पङ्क्तिहरू भर्नुहोस्, CSV का रूपमा सुरक्षित गरेर फेरि टाँस्नुहोस्। केही पनि सुरक्षित हुनु अघि हरेक पङ्क्ति जाँचिन्छ — एउटा पङ्क्ति गलत भए केही पनि आयात हुँदैन।';

  @override
  String get importCopyTemplate => 'टेम्प्लेट प्रतिलिपि गर्नुहोस्';

  @override
  String get importTemplateCopied =>
      'टेम्प्लेट प्रतिलिपि भयो — एक्सेलमा टाँस्नुहोस्';

  @override
  String get importPasteFromClipboard => 'क्लिपबोर्डबाट टाँस्नुहोस्';

  @override
  String get importCsvLabel => 'CSV पङ्क्तिहरू';

  @override
  String get importCheckFile => 'फाइल जाँच्नुहोस्';

  @override
  String get importChecking => 'जाँच हुँदै…';

  @override
  String get importRun => 'आयात गर्नुहोस्';

  @override
  String get importImporting => 'आयात हुँदै…';

  @override
  String get importPreviewTitle => 'जाँचको नतिजा';

  @override
  String get importRowsTotal => 'कुल पङ्क्ति';

  @override
  String get importRowsValid => 'तयार';

  @override
  String get importRowsDuplicate => 'पहिले नै छ';

  @override
  String get importRowsInvalid => 'सुधार्नुपर्ने';

  @override
  String get importBlockedHint =>
      'सबै पङ्क्ति सुधार नगरेसम्म केही पनि आयात हुँदैन।';

  @override
  String importIgnoredColumns(String columns) =>
      'बेवास्ता गरिएका स्तम्भ: $columns';

  @override
  String get importIssuesTitle => 'सुधार्नुपर्ने पङ्क्ति';

  @override
  String importIssueLine(int row, String message) => 'पङ्क्ति $row: $message';

  @override
  String importIssueLineWithColumn(int row, String column, String message) =>
      'पङ्क्ति $row · $column: $message';

  @override
  String importMoreIssues(int count) => '…अरू $count थप';

  @override
  String get importConfirmTitle => 'यी पङ्क्ति आयात गर्ने?';

  @override
  String get importConfirmBody =>
      'पहिले नै भएका पङ्क्ति छोडिन्छन्; कुनै पनि माथि नलेखिनेछ।';

  @override
  String get importCompleteTitle => 'आयात सम्पन्न';

  @override
  String importCreatedCount(int count) => '$count रेकर्ड सिर्जना भयो';

  @override
  String importSkippedCount(int count) => '$count पहिले नै थिए, छोडियो';

  @override
  String get importRejected =>
      'केही पनि आयात भएन — तलका पङ्क्ति सुधारेर फेरि प्रयास गर्नुहोस्।';

  @override
  String get importClear => 'खाली गर्नुहोस्';

  @override
  String get importExpectedColumns => 'अपेक्षित स्तम्भ';

  @override
  String get cachedDataNote =>
      'सुरक्षित डाटा देखाइँदै। रिफ्रेस गर्न फेरि जडान गर्नुहोस्।';

  @override
  String cachedDataNoteAt(String time) =>
      '$time मा सुरक्षित डाटा देखाइँदै। रिफ्रेस गर्न फेरि जडान गर्नुहोस्।';

  @override
  String get offlineDataTitle => 'अफलाइन डाटा';

  @override
  String get offlineDataExplainer =>
      'तपाईंले खोल्ने सूचीहरू यही उपकरणमा सुरक्षित हुन्छन्, त्यसैले इन्टरनेट नभए पनि खुल्छन्।';

  @override
  String get offlineDataSavedLabel => 'सुरक्षित सूची';

  @override
  String offlineDataSavedCount(int lists, String size) => '$lists सूची · $size';

  @override
  String get offlineDataClear => 'सुरक्षित डाटा मेटाउनुहोस्';

  @override
  String get offlineDataClearConfirm =>
      'सुरक्षित सूचीहरू मेटाउने? अर्को पटक खोल्दा फेरि डाउनलोड हुनेछन्।';

  @override
  String get offlineDataCleared => 'सुरक्षित डाटा मेटियो';

  @override
  String loadMoreRemaining(int count) => 'थप हेर्नुहोस् ($count बाँकी)';

  @override
  String get pageNotFound => 'पृष्ठ भेटिएन';

  @override
  String get pageNotFoundBody =>
      'यो पृष्ठ उपलब्ध छैन। यो सारिएको हुन सक्छ, वा लिङ्क गलत हुन सक्छ।';

  @override
  String get fileSaveNotSupported =>
      'फाइल बचत गरी साझेदारी गर्न फोनमा एप चाहिन्छ — ब्राउजर संस्करणले फाइल लेख्न सक्दैन।';

  @override
  String get savedOffline => 'अफलाइन सुरक्षित — इन्टरनेट जोडिएपछि सिंक हुनेछ।';

  @override
  String get offlineBannerNote => 'अफलाइन — जोडिएपछि परिवर्तन सिंक हुनेछ';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get calendarAd => 'ईस्वी (AD)';

  @override
  String get calendarBs => 'वि.सं. (बिक्रम सम्बत)';

  @override
  String get calendarNote => 'मितिहरू यही पात्रोमा देखिने र छानिनेछन्।';

  @override
  String pendingWritesCount(int count) => '$count बाँकी';

  @override
  String get navHome => 'गृहपृष्ठ';

  @override
  String get navParties => 'खाता';

  @override
  String get navItems => 'सामान';

  @override
  String monthToDate(String amount) => 'यो महिना $amount';

  @override
  String lowStockCountLabel(int count) => '$count सामानको स्टक कम';

  @override
  String get recentActivity => 'हालैका गतिविधि';

  @override
  String get viewAll => 'सबै हेर्नुहोस्';

  @override
  String get getStartedTitle => 'सुरु गर्नुहोस्';

  @override
  String get getStartedStepProduct => 'पहिलो सामान थप्नुहोस्';

  @override
  String get getStartedStepCustomer => 'ग्राहक थप्नुहोस्';

  @override
  String get getStartedStepSale => 'पहिलो बिक्री रेकर्ड गर्नुहोस्';

  @override
  String get shareReminder => 'रिमाइन्डर पठाउनुहोस्';

  @override
  String reminderShareMessage(String name, String business, String amount) =>
      'नमस्ते $name, $business मा तपाईंको बाँकी $amount छ। सुविधा हुँदा भुक्तानी गरिदिनुहोस्। धन्यवाद।';

  @override
  String get moreSalesDocs => 'बिक्री र कागजात';

  @override
  String get moreItems => 'सामान र स्टक';

  @override
  String get moreInsights => 'विश्लेषण';

  @override
  String get moreTools => 'उपकरण र सेटिङ';

  @override
  String get moreAccount => 'खाता विवरण';

  @override
  String balanceShort(String amount) => 'बाँकी $amount';

  @override
  String get moreActions => 'थप कार्यहरू';

  @override
  String get welcomeChooseLanguage => 'तपाईंको भाषा छान्नुहोस्';

  @override
  String get welcomeSkip => 'छोड्नुहोस्';

  @override
  String get welcomeSlide1Title => 'कहिल्यै नबिर्सने खाता';

  @override
  String get welcomeSlide1Body =>
      'हरेक उधारो बिक्री, हरेक भुक्तानी र हरेक बाँकी — एकैचोटि लेखिन्छ, सधैं सही रहन्छ।';

  @override
  String get welcomeSlide2Title => 'आफैं गन्ने स्टक';

  @override
  String get welcomeSlide2Body =>
      'बिक्री र खरिदले स्टक आफैं घटाउँछ, र सामान सकिनु अघि नै चेतावनी आउँछ।';

  @override
  String get welcomeSlide3Title => 'काम लाग्ने हिसाब';

  @override
  String get welcomeSlide3Body =>
      'दैनिक नाफा, उठाउनु पर्ने र तिर्नु पर्ने — ईस्वी वा वि.सं. मितिमा, तपाईंको भाषामा।';

  @override
  String get tryDemo => 'डेमो हेर्नुहोस्';

  @override
  String get updateTitle => 'अपडेट उपलब्ध छ';

  @override
  String updateBody(String current, String latest) =>
      'तपाईंसँग संस्करण $current छ। संस्करण $latest स्थापना गर्न तयार छ।';

  @override
  String updateSize(String size) => 'डाउनलोड आकार: $size';

  @override
  String get updateNotesLabel => 'नयाँ के छ';

  @override
  String get updateDownload => 'डाउनलोड';

  @override
  String get updateLater => 'पछि';

  @override
  String get updateLinkFailed => 'डाउनलोड लिंक खोल्न सकिएन।';

}

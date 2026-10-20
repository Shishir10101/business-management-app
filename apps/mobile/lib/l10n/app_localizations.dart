import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ne.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('hi'),
    Locale('ne')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Digital Khata'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get dontHaveAccount;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @khata.
  ///
  /// In en, this message translates to:
  /// **'Khata'**
  String get khata;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @todaysSales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get todaysSales;

  /// No description provided for @todaysPurchases.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Purchases'**
  String get todaysPurchases;

  /// No description provided for @todaysExpenses.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Expenses'**
  String get todaysExpenses;

  /// No description provided for @todaysProfit.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Profit'**
  String get todaysProfit;

  /// No description provided for @totalReceivable.
  ///
  /// In en, this message translates to:
  /// **'Total Receivable'**
  String get totalReceivable;

  /// No description provided for @totalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total Payable'**
  String get totalPayable;

  /// No description provided for @stockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock Value'**
  String get stockValue;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @createBusiness.
  ///
  /// In en, this message translates to:
  /// **'Create Business'**
  String get createBusiness;

  /// No description provided for @businessSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your business'**
  String get businessSetupTitle;

  /// No description provided for @businessSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You will be the Owner with full access.'**
  String get businessSetupSubtitle;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get businessName;

  /// No description provided for @businessType.
  ///
  /// In en, this message translates to:
  /// **'Business type (e.g. Retail)'**
  String get businessType;

  /// No description provided for @panNumber.
  ///
  /// In en, this message translates to:
  /// **'PAN number'**
  String get panNumber;

  /// No description provided for @businessEmail.
  ///
  /// In en, this message translates to:
  /// **'Business email'**
  String get businessEmail;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @wardNumber.
  ///
  /// In en, this message translates to:
  /// **'Ward number'**
  String get wardNumber;

  /// No description provided for @myBusinesses.
  ///
  /// In en, this message translates to:
  /// **'My Businesses'**
  String get myBusinesses;

  /// No description provided for @switchBusiness.
  ///
  /// In en, this message translates to:
  /// **'Switch business'**
  String get switchBusiness;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @noBusinesses.
  ///
  /// In en, this message translates to:
  /// **'No businesses yet'**
  String get noBusinesses;

  /// No description provided for @createFirstBusiness.
  ///
  /// In en, this message translates to:
  /// **'Create your first business'**
  String get createFirstBusiness;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @inviteMember.
  ///
  /// In en, this message translates to:
  /// **'Invite staff member'**
  String get inviteMember;

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get changeRole;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get editProduct;

  /// No description provided for @newProduct.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get newProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productName;

  /// No description provided for @sku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get sku;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @addUnit.
  ///
  /// In en, this message translates to:
  /// **'Add unit'**
  String get addUnit;

  /// No description provided for @newUnit.
  ///
  /// In en, this message translates to:
  /// **'New unit'**
  String get newUnit;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost price'**
  String get costPrice;

  /// No description provided for @sellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling price'**
  String get sellingPrice;

  /// No description provided for @wholesalePrice.
  ///
  /// In en, this message translates to:
  /// **'Wholesale price'**
  String get wholesalePrice;

  /// No description provided for @taxRate.
  ///
  /// In en, this message translates to:
  /// **'Tax rate'**
  String get taxRate;

  /// No description provided for @openingStock.
  ///
  /// In en, this message translates to:
  /// **'Opening stock'**
  String get openingStock;

  /// No description provided for @minQuantity.
  ///
  /// In en, this message translates to:
  /// **'Low-stock alert at'**
  String get minQuantity;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @adjustStock.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get adjustStock;

  /// No description provided for @stockHistory.
  ///
  /// In en, this message translates to:
  /// **'Stock history'**
  String get stockHistory;

  /// No description provided for @quickAdjust.
  ///
  /// In en, this message translates to:
  /// **'Quick adjust'**
  String get quickAdjust;

  /// No description provided for @customQuantity.
  ///
  /// In en, this message translates to:
  /// **'Custom quantity'**
  String get customQuantity;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @applyAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Apply adjustment'**
  String get applyAdjustment;

  /// No description provided for @lowStockOnly.
  ///
  /// In en, this message translates to:
  /// **'Low stock only'**
  String get lowStockOnly;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Sort by name'**
  String get sortByName;

  /// No description provided for @sortByQuantity.
  ///
  /// In en, this message translates to:
  /// **'Sort by quantity'**
  String get sortByQuantity;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get searchProducts;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'in stock'**
  String get inStock;

  /// No description provided for @lowStockAlert.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStockAlert;

  /// No description provided for @stockAdded.
  ///
  /// In en, this message translates to:
  /// **'Stock added'**
  String get stockAdded;

  /// No description provided for @stockRemoved.
  ///
  /// In en, this message translates to:
  /// **'Stock removed'**
  String get stockRemoved;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get addCustomer;

  /// No description provided for @newCustomer.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get newCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get editCustomer;

  /// No description provided for @searchCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search customers'**
  String get searchCustomers;

  /// No description provided for @suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @addSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add supplier'**
  String get addSupplier;

  /// No description provided for @newSupplier.
  ///
  /// In en, this message translates to:
  /// **'New supplier'**
  String get newSupplier;

  /// No description provided for @editSupplier.
  ///
  /// In en, this message translates to:
  /// **'Edit supplier'**
  String get editSupplier;

  /// No description provided for @searchSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Search suppliers'**
  String get searchSuppliers;

  /// No description provided for @searchPartyHint.
  ///
  /// In en, this message translates to:
  /// **'Search name or phone'**
  String get searchPartyHint;

  /// No description provided for @ledger.
  ///
  /// In en, this message translates to:
  /// **'Khata ledger'**
  String get ledger;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingBalance;

  /// No description provided for @creditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get creditLimit;

  /// No description provided for @creditLimitOptional.
  ///
  /// In en, this message translates to:
  /// **'Credit limit (optional)'**
  String get creditLimitOptional;

  /// No description provided for @closingBalance.
  ///
  /// In en, this message translates to:
  /// **'Closing balance'**
  String get closingBalance;

  /// No description provided for @totalDebit.
  ///
  /// In en, this message translates to:
  /// **'Total debit'**
  String get totalDebit;

  /// No description provided for @totalCredit.
  ///
  /// In en, this message translates to:
  /// **'Total credit'**
  String get totalCredit;

  /// No description provided for @toCollect.
  ///
  /// In en, this message translates to:
  /// **'To collect'**
  String get toCollect;

  /// No description provided for @toPay.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get toPay;

  /// No description provided for @advance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get advance;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @noCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomers;

  /// No description provided for @noSuppliers.
  ///
  /// In en, this message translates to:
  /// **'No suppliers yet'**
  String get noSuppliers;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @partyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get partyDeleted;

  /// No description provided for @deletePartyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete party?'**
  String get deletePartyTitle;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @sale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get sale;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get newSale;

  /// No description provided for @purchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get purchases;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @newPurchase.
  ///
  /// In en, this message translates to:
  /// **'New purchase'**
  String get newPurchase;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get addIncome;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice number'**
  String get invoiceNumber;

  /// No description provided for @billNumber.
  ///
  /// In en, this message translates to:
  /// **'Bill number'**
  String get billNumber;

  /// No description provided for @saleType.
  ///
  /// In en, this message translates to:
  /// **'Sale type'**
  String get saleType;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get paymentStatus;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @searchSales.
  ///
  /// In en, this message translates to:
  /// **'Search sales'**
  String get searchSales;

  /// No description provided for @searchPurchases.
  ///
  /// In en, this message translates to:
  /// **'Search purchases'**
  String get searchPurchases;

  /// No description provided for @searchExpenses.
  ///
  /// In en, this message translates to:
  /// **'Search expenses'**
  String get searchExpenses;

  /// No description provided for @searchIncome.
  ///
  /// In en, this message translates to:
  /// **'Search income'**
  String get searchIncome;

  /// No description provided for @walkIn.
  ///
  /// In en, this message translates to:
  /// **'Walk-in'**
  String get walkIn;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// No description provided for @noSales.
  ///
  /// In en, this message translates to:
  /// **'No sales yet'**
  String get noSales;

  /// No description provided for @noPurchases.
  ///
  /// In en, this message translates to:
  /// **'No purchases yet'**
  String get noPurchases;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpenses;

  /// No description provided for @noIncome.
  ///
  /// In en, this message translates to:
  /// **'No income yet'**
  String get noIncome;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPayment;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get paymentMethods;

  /// No description provided for @addPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Add method'**
  String get addPaymentMethod;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @noPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get noPayments;

  /// No description provided for @onAccount.
  ///
  /// In en, this message translates to:
  /// **'None (on account)'**
  String get onAccount;

  /// No description provided for @applyToDocument.
  ///
  /// In en, this message translates to:
  /// **'Apply to invoice/bill'**
  String get applyToDocument;

  /// No description provided for @advances.
  ///
  /// In en, this message translates to:
  /// **'Advances'**
  String get advances;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @newInvoice.
  ///
  /// In en, this message translates to:
  /// **'New invoice'**
  String get newInvoice;

  /// No description provided for @quotations.
  ///
  /// In en, this message translates to:
  /// **'Quotations'**
  String get quotations;

  /// No description provided for @quotation.
  ///
  /// In en, this message translates to:
  /// **'Quotation'**
  String get quotation;

  /// No description provided for @newQuotation.
  ///
  /// In en, this message translates to:
  /// **'New quotation'**
  String get newQuotation;

  /// No description provided for @issueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue date'**
  String get issueDate;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get validUntil;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @convertToSale.
  ///
  /// In en, this message translates to:
  /// **'Convert to sale'**
  String get convertToSale;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @noInvoices.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet'**
  String get noInvoices;

  /// No description provided for @noQuotations.
  ///
  /// In en, this message translates to:
  /// **'No quotations yet'**
  String get noQuotations;

  /// No description provided for @generateFromSale.
  ///
  /// In en, this message translates to:
  /// **'Generate from a sale'**
  String get generateFromSale;

  /// No description provided for @fromSale.
  ///
  /// In en, this message translates to:
  /// **'From sale'**
  String fromSale(String number);

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettings;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @nothingMatchesFilter.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches this filter'**
  String get nothingMatchesFilter;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get markRead;

  /// No description provided for @markedReadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} marked read'**
  String markedReadCount(int count);

  /// No description provided for @nothingToMark.
  ///
  /// In en, this message translates to:
  /// **'Nothing to mark'**
  String get nothingToMark;

  /// No description provided for @filterAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get filterAllCategories;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @enablePush.
  ///
  /// In en, this message translates to:
  /// **'Enable push'**
  String get enablePush;

  /// No description provided for @enablePushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Master switch for this device'**
  String get enablePushSubtitle;

  /// No description provided for @notificationsInAppNote.
  ///
  /// In en, this message translates to:
  /// **'In-app notifications are always recorded. These switches control push delivery only.'**
  String get notificationsInAppNote;

  /// No description provided for @registeredDevices.
  ///
  /// In en, this message translates to:
  /// **'Registered devices'**
  String get registeredDevices;

  /// No description provided for @noDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices registered yet'**
  String get noDevices;

  /// No description provided for @deviceActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get deviceActive;

  /// No description provided for @deviceInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get deviceInactive;

  /// No description provided for @categoryReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get categoryReminders;

  /// No description provided for @categoryRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a reminder falls due'**
  String get categoryRemindersSubtitle;

  /// No description provided for @categoryLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get categoryLowStock;

  /// No description provided for @categoryLowStockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a product drops to its minimum'**
  String get categoryLowStockSubtitle;

  /// No description provided for @categoryPaymentDue.
  ///
  /// In en, this message translates to:
  /// **'Payment due'**
  String get categoryPaymentDue;

  /// No description provided for @categoryPaymentDueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a bill is close to or past its due date'**
  String get categoryPaymentDueSubtitle;

  /// No description provided for @categoryBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get categoryBackup;

  /// No description provided for @categoryBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Backup finished or failed'**
  String get categoryBackupSubtitle;

  /// No description provided for @categorySystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get categorySystem;

  /// No description provided for @categorySystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Account and app announcements'**
  String get categorySystemSubtitle;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @newReminder.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get newReminder;

  /// No description provided for @editReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get editReminder;

  /// No description provided for @noReminders.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get noReminders;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get needsAttention;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminder;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reminderTitle;

  /// No description provided for @reminderTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Call Ram about the pending bill'**
  String get reminderTitleHint;

  /// No description provided for @reminderTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'A title is required'**
  String get reminderTitleRequired;

  /// No description provided for @dueTime.
  ///
  /// In en, this message translates to:
  /// **'Due time'**
  String get dueTime;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get repeatOnce;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get repeatMonthly;

  /// No description provided for @repeatYearly.
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get repeatYearly;

  /// No description provided for @recurringNote.
  ///
  /// In en, this message translates to:
  /// **'A repeating reminder reschedules itself after firing instead of completing, so it always lands on the next upcoming date.'**
  String get recurringNote;

  /// No description provided for @saveReminder.
  ///
  /// In en, this message translates to:
  /// **'Save reminder'**
  String get saveReminder;

  /// No description provided for @reminderSaved.
  ///
  /// In en, this message translates to:
  /// **'Reminder saved'**
  String get reminderSaved;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get markDone;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @markedDone.
  ///
  /// In en, this message translates to:
  /// **'Marked done'**
  String get markedDone;

  /// No description provided for @checkDueReminders.
  ///
  /// In en, this message translates to:
  /// **'Check for due reminders'**
  String get checkDueReminders;

  /// No description provided for @nothingDue.
  ///
  /// In en, this message translates to:
  /// **'Nothing is due right now'**
  String get nothingDue;

  /// No description provided for @remindersFiredCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reminder(s) fired'**
  String remindersFiredCount(int count);

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dueToday;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dueTomorrow;

  /// No description provided for @dueYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dueYesterday;

  /// No description provided for @reminderStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get reminderStatusPending;

  /// No description provided for @reminderStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get reminderStatusDone;

  /// No description provided for @reminderStatusDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get reminderStatusDismissed;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupAndRestore;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get exportBackup;

  /// No description provided for @restoreFromLastExport.
  ///
  /// In en, this message translates to:
  /// **'Restore from last export'**
  String get restoreFromLastExport;

  /// No description provided for @restoreFromPastedJson.
  ///
  /// In en, this message translates to:
  /// **'Restore from pasted JSON'**
  String get restoreFromPastedJson;

  /// No description provided for @backupExportBody.
  ///
  /// In en, this message translates to:
  /// **'Saves every product, party, sale, purchase, expense, income, payment, invoice and quotation in the active business. Soft-deleted records are kept, so history survives.'**
  String get backupExportBody;

  /// No description provided for @backupRestoreBody.
  ///
  /// In en, this message translates to:
  /// **'Restoring merges a backup into this business. Records that already exist are skipped — nothing is ever overwritten, because a rewritten sale or payment would leave the khata ledger disagreeing with itself.'**
  String get backupRestoreBody;

  /// No description provided for @backupNotIncludedTitle.
  ///
  /// In en, this message translates to:
  /// **'What is not included'**
  String get backupNotIncludedTitle;

  /// No description provided for @backupNotIncludedBody.
  ///
  /// In en, this message translates to:
  /// **'The khata ledger entries and stock movements are derived from the documents above, so they are rebuilt by replaying those operations rather than copied. A restore therefore brings back your records, not the cached totals.'**
  String get backupNotIncludedBody;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Records that already exist in this business will be skipped. Nothing currently here is modified or deleted.'**
  String get restoreConfirmBody;

  /// No description provided for @restoreComplete.
  ///
  /// In en, this message translates to:
  /// **'Restore complete'**
  String get restoreComplete;

  /// No description provided for @restoreAddedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} record(s) added'**
  String restoreAddedCount(int count);

  /// No description provided for @restoreSkippedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} already present, left alone'**
  String restoreSkippedCount(int count);

  /// No description provided for @recordsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} added'**
  String recordsAdded(int count);

  /// No description provided for @recordsAddedKept.
  ///
  /// In en, this message translates to:
  /// **'{count} added, {kept} kept'**
  String recordsAddedKept(int count, int kept);

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty'**
  String get clipboardEmpty;

  /// No description provided for @notAKhataBackup.
  ///
  /// In en, this message translates to:
  /// **'This file is not a Khata backup.'**
  String get notAKhataBackup;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @pendingChanges.
  ///
  /// In en, this message translates to:
  /// **'Pending changes'**
  String get pendingChanges;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @signInToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInToYourAccount;

  /// No description provided for @createYourAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your Digital Khata account'**
  String get createYourAccountTitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @fullNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNamePlaceholder;

  /// No description provided for @phoneNumberPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberPlaceholder;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (optional)'**
  String get phoneOptional;

  /// No description provided for @pan.
  ///
  /// In en, this message translates to:
  /// **'PAN'**
  String get pan;

  /// No description provided for @businessNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Business name *'**
  String get businessNameRequired;

  /// No description provided for @createNewBusiness.
  ///
  /// In en, this message translates to:
  /// **'Create new business'**
  String get createNewBusiness;

  /// No description provided for @businesses.
  ///
  /// In en, this message translates to:
  /// **'Businesses'**
  String get businesses;

  /// No description provided for @couldNotCreateBusiness.
  ///
  /// In en, this message translates to:
  /// **'Could not create business: {error}'**
  String couldNotCreateBusiness(String error);

  /// No description provided for @couldNotSwitchBusiness.
  ///
  /// In en, this message translates to:
  /// **'Could not switch business: {error}'**
  String couldNotSwitchBusiness(String error);

  /// No description provided for @couldNotUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not update profile: {error}'**
  String couldNotUpdateProfile(String error);

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @changeRoleFor.
  ///
  /// In en, this message translates to:
  /// **'Change role — {name}'**
  String changeRoleFor(String name);

  /// No description provided for @couldNotChangeRole.
  ///
  /// In en, this message translates to:
  /// **'Could not change role: {error}'**
  String couldNotChangeRole(String error);

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeMember(String name);

  /// No description provided for @removeMemberWarning.
  ///
  /// In en, this message translates to:
  /// **'They will lose access to this business.'**
  String get removeMemberWarning;

  /// No description provided for @couldNotRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Could not remove member: {error}'**
  String couldNotRemoveMember(String error);

  /// No description provided for @inviteFailed.
  ///
  /// In en, this message translates to:
  /// **'Invite failed: {error}'**
  String inviteFailed(String error);

  /// No description provided for @noStaffMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No staff members yet'**
  String get noStaffMembersYet;

  /// No description provided for @productNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Product name *'**
  String get productNameRequired;

  /// No description provided for @searchNameSkuBarcode.
  ///
  /// In en, this message translates to:
  /// **'Search name, SKU or barcode'**
  String get searchNameSkuBarcode;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @costPriceRs.
  ///
  /// In en, this message translates to:
  /// **'Cost price (Rs.)'**
  String get costPriceRs;

  /// No description provided for @sellingPriceRsRequired.
  ///
  /// In en, this message translates to:
  /// **'Selling price (Rs.) *'**
  String get sellingPriceRsRequired;

  /// No description provided for @wholesalePriceRs.
  ///
  /// In en, this message translates to:
  /// **'Wholesale price (Rs.)'**
  String get wholesalePriceRs;

  /// No description provided for @taxRatePercent.
  ///
  /// In en, this message translates to:
  /// **'Tax rate (%)'**
  String get taxRatePercent;

  /// No description provided for @openingStockQuantity.
  ///
  /// In en, this message translates to:
  /// **'Opening stock quantity'**
  String get openingStockQuantity;

  /// No description provided for @minimumQuantityHint.
  ///
  /// In en, this message translates to:
  /// **'minimum quantity (0 = no alert)'**
  String get minimumQuantityHint;

  /// No description provided for @inactiveProductsNote.
  ///
  /// In en, this message translates to:
  /// **'Inactive products stay but are hidden from sales'**
  String get inactiveProductsNote;

  /// No description provided for @deleteProductQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete product?'**
  String get deleteProductQuestion;

  /// No description provided for @deleteProductWarning.
  ///
  /// In en, this message translates to:
  /// **'The product will be hidden from the catalog. Stock history is kept.'**
  String get deleteProductWarning;

  /// No description provided for @loadingProduct.
  ///
  /// In en, this message translates to:
  /// **'Loading product…'**
  String get loadingProduct;

  /// No description provided for @couldNotLoadProduct.
  ///
  /// In en, this message translates to:
  /// **'Could not load product: {error}'**
  String couldNotLoadProduct(String error);

  /// No description provided for @byCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategory;

  /// No description provided for @expensesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expenses by category'**
  String get expensesByCategory;

  /// No description provided for @categoriesNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get categoriesNoCategories;

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get noCategory;

  /// No description provided for @deleteCategoryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete category?'**
  String get deleteCategoryQuestion;

  /// No description provided for @categoryDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Products in this category will keep working without a category.'**
  String get categoryDeleteNote;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Category *'**
  String get categoryRequired;

  /// No description provided for @noUnit.
  ///
  /// In en, this message translates to:
  /// **'No unit'**
  String get noUnit;

  /// No description provided for @unitNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name * (e.g. Piece)'**
  String get unitNameHint;

  /// No description provided for @unitShortHint.
  ///
  /// In en, this message translates to:
  /// **'Short name * (e.g. pc)'**
  String get unitShortHint;

  /// No description provided for @unitsNoUnits.
  ///
  /// In en, this message translates to:
  /// **'No units yet'**
  String get unitsNoUnits;

  /// No description provided for @deleteUnitQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete unit?'**
  String get deleteUnitQuestion;

  /// No description provided for @unitDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Products using this unit will keep working without a unit.'**
  String get unitDeleteNote;

  /// No description provided for @movementHistory.
  ///
  /// In en, this message translates to:
  /// **'Movement history'**
  String get movementHistory;

  /// No description provided for @noStockMovementsYet.
  ///
  /// In en, this message translates to:
  /// **'No stock movements yet'**
  String get noStockMovementsYet;

  /// No description provided for @customQuantityHint.
  ///
  /// In en, this message translates to:
  /// **'Custom quantity (+ in / - out)'**
  String get customQuantityHint;

  /// No description provided for @quantityExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2.5 or -3'**
  String get quantityExample;

  /// No description provided for @reasonExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. stock count, damage'**
  String get reasonExample;

  /// No description provided for @stockValuation.
  ///
  /// In en, this message translates to:
  /// **'Stock valuation'**
  String get stockValuation;

  /// No description provided for @currentStockIs.
  ///
  /// In en, this message translates to:
  /// **'Current stock: {quantity}'**
  String currentStockIs(String quantity);

  /// No description provided for @balanceIs.
  ///
  /// In en, this message translates to:
  /// **'Bal {quantity}'**
  String balanceIs(String quantity);

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get nameRequired;

  /// No description provided for @partyNameExample.
  ///
  /// In en, this message translates to:
  /// **'Name * (e.g. Piece)'**
  String get partyNameExample;

  /// No description provided for @creditLimitRs.
  ///
  /// In en, this message translates to:
  /// **'Credit limit (Rs.)'**
  String get creditLimitRs;

  /// No description provided for @openingBalanceRs.
  ///
  /// In en, this message translates to:
  /// **'Opening balance (Rs.)'**
  String get openingBalanceRs;

  /// No description provided for @walkInNone.
  ///
  /// In en, this message translates to:
  /// **'Walk-in / none'**
  String get walkInNone;

  /// No description provided for @deletePartyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete {kind}?'**
  String deletePartyQuestion(String kind);

  /// No description provided for @partyDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'The party will be hidden from lists. Khata history is kept.'**
  String get partyDeleteNote;

  /// No description provided for @khataHistoryKept.
  ///
  /// In en, this message translates to:
  /// **'Khata history is kept.'**
  String get khataHistoryKept;

  /// No description provided for @createSale.
  ///
  /// In en, this message translates to:
  /// **'Create sale'**
  String get createSale;

  /// No description provided for @createPurchase.
  ///
  /// In en, this message translates to:
  /// **'Create purchase'**
  String get createPurchase;

  /// No description provided for @createInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create invoice'**
  String get createInvoice;

  /// No description provided for @createQuotation.
  ///
  /// In en, this message translates to:
  /// **'Create quotation'**
  String get createQuotation;

  /// No description provided for @noItemsYetAddProduct.
  ///
  /// In en, this message translates to:
  /// **'No items yet — add a product'**
  String get noItemsYetAddProduct;

  /// No description provided for @addFreeText.
  ///
  /// In en, this message translates to:
  /// **'Add free text'**
  String get addFreeText;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'Items ({count})'**
  String itemsCount(int count);

  /// No description provided for @extraDiscountRs.
  ///
  /// In en, this message translates to:
  /// **'Extra discount (Rs.)'**
  String get extraDiscountRs;

  /// No description provided for @paidNowRs.
  ///
  /// In en, this message translates to:
  /// **'Paid now (Rs.)'**
  String get paidNowRs;

  /// No description provided for @paidAmountRs.
  ///
  /// In en, this message translates to:
  /// **'Paid amount (Rs.)'**
  String get paidAmountRs;

  /// No description provided for @amountRsRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount (Rs.) *'**
  String get amountRsRequired;

  /// No description provided for @lineTotalIs.
  ///
  /// In en, this message translates to:
  /// **'Line total: {total}'**
  String lineTotalIs(String total);

  /// No description provided for @invoiceNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice {number}'**
  String invoiceNumberLabel(String number);

  /// No description provided for @quotationNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Quotation {number}'**
  String quotationNumberLabel(String number);

  /// No description provided for @issuedOn.
  ///
  /// In en, this message translates to:
  /// **'Issued {date}'**
  String issuedOn(String date);

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueOn(String date);

  /// No description provided for @validUntilOn.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String validUntilOn(String date);

  /// No description provided for @convertedToSale.
  ///
  /// In en, this message translates to:
  /// **'Converted to sale #{id}'**
  String convertedToSale(int id);

  /// No description provided for @lineItemsCopiedNote.
  ///
  /// In en, this message translates to:
  /// **'Line items will be copied from the selected sale and its prices kept.'**
  String get lineItemsCopiedNote;

  /// No description provided for @noneBuildManually.
  ///
  /// In en, this message translates to:
  /// **'None (build manually)'**
  String get noneBuildManually;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @termsLabel.
  ///
  /// In en, this message translates to:
  /// **'Terms: {terms}'**
  String termsLabel(String terms);

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes: {notes}'**
  String notesLabel(String notes);

  /// No description provided for @sharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get sharePdf;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @deleteSaleQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete sale?'**
  String get deleteSaleQuestion;

  /// No description provided for @deletePurchaseQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete purchase?'**
  String get deletePurchaseQuestion;

  /// No description provided for @deleteInvoiceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete invoice?'**
  String get deleteInvoiceQuestion;

  /// No description provided for @deleteQuotationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete quotation?'**
  String get deleteQuotationQuestion;

  /// No description provided for @deleteExpenseQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete expense?'**
  String get deleteExpenseQuestion;

  /// No description provided for @deleteIncomeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete income?'**
  String get deleteIncomeQuestion;

  /// No description provided for @deleteMethodQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete method?'**
  String get deleteMethodQuestion;

  /// No description provided for @saleDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Stock will be restored and the customer khata reversed.'**
  String get saleDeleteNote;

  /// No description provided for @purchaseDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Stock will be reduced back and the supplier khata reversed.'**
  String get purchaseDeleteNote;

  /// No description provided for @expenseDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'This expense will be permanently removed.'**
  String get expenseDeleteNote;

  /// No description provided for @incomeDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'This income record will be permanently removed.'**
  String get incomeDeleteNote;

  /// No description provided for @invoiceDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'This invoice will be permanently removed.'**
  String get invoiceDeleteNote;

  /// No description provided for @quotationDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'This quotation will be permanently removed.'**
  String get quotationDeleteNote;

  /// No description provided for @searchInvoiceOrCustomer.
  ///
  /// In en, this message translates to:
  /// **'Search invoice or customer'**
  String get searchInvoiceOrCustomer;

  /// No description provided for @searchBillOrSupplier.
  ///
  /// In en, this message translates to:
  /// **'Search bill or supplier'**
  String get searchBillOrSupplier;

  /// No description provided for @searchQuotationOrCustomer.
  ///
  /// In en, this message translates to:
  /// **'Search quotation or customer'**
  String get searchQuotationOrCustomer;

  /// No description provided for @searchPartyOrReference.
  ///
  /// In en, this message translates to:
  /// **'Search party or reference'**
  String get searchPartyOrReference;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @addMethod.
  ///
  /// In en, this message translates to:
  /// **'Add method'**
  String get addMethod;

  /// No description provided for @noPaymentMethodsYet.
  ///
  /// In en, this message translates to:
  /// **'No payment methods yet'**
  String get noPaymentMethodsYet;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefault;

  /// No description provided for @methodChangeNote.
  ///
  /// In en, this message translates to:
  /// **'Payments already recorded with this method keep working.'**
  String get methodChangeNote;

  /// No description provided for @advanceIs.
  ///
  /// In en, this message translates to:
  /// **'Advance {amount}'**
  String advanceIs(String amount);

  /// No description provided for @dueToCustomerKhata.
  ///
  /// In en, this message translates to:
  /// **'Due {amount} → customer khata'**
  String dueToCustomerKhata(String amount);

  /// No description provided for @dueToSupplierKhata.
  ///
  /// In en, this message translates to:
  /// **'Due {amount} → supplier khata'**
  String dueToSupplierKhata(String amount);

  /// No description provided for @advancesAreMoney.
  ///
  /// In en, this message translates to:
  /// **'Advances are money you already hold, so they are applied first.'**
  String get advancesAreMoney;

  /// No description provided for @advancesLabel.
  ///
  /// In en, this message translates to:
  /// **'Advances: {list}'**
  String advancesLabel(String list);

  /// No description provided for @addProductButton.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProductButton;

  /// No description provided for @addReminderButton.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminderButton;

  /// No description provided for @receivablesAndPayables.
  ///
  /// In en, this message translates to:
  /// **'Receivables & payables'**
  String get receivablesAndPayables;

  /// No description provided for @receivablesCount.
  ///
  /// In en, this message translates to:
  /// **'Receivables · {count}'**
  String receivablesCount(int count);

  /// No description provided for @payablesCount.
  ///
  /// In en, this message translates to:
  /// **'Payables · {count}'**
  String payablesCount(int count);

  /// No description provided for @profitAndLoss.
  ///
  /// In en, this message translates to:
  /// **'Profit & loss'**
  String get profitAndLoss;

  /// No description provided for @salesReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales report'**
  String get salesReportTitle;

  /// No description provided for @revenueExcludesVat.
  ///
  /// In en, this message translates to:
  /// **'Revenue excludes VAT.'**
  String get revenueExcludesVat;

  /// No description provided for @salesTrendLast14.
  ///
  /// In en, this message translates to:
  /// **'Sales trend · last 14 days'**
  String get salesTrendLast14;

  /// No description provided for @salesTrendScope.
  ///
  /// In en, this message translates to:
  /// **'Sales trend · {scope}'**
  String salesTrendScope(String scope);

  /// No description provided for @topProducts.
  ///
  /// In en, this message translates to:
  /// **'Top products'**
  String get topProducts;

  /// No description provided for @topCustomers.
  ///
  /// In en, this message translates to:
  /// **'Top customers'**
  String get topCustomers;

  /// No description provided for @bySource.
  ///
  /// In en, this message translates to:
  /// **'By source'**
  String get bySource;

  /// No description provided for @incomeTrend.
  ///
  /// In en, this message translates to:
  /// **'Income trend'**
  String get incomeTrend;

  /// No description provided for @lastCycle.
  ///
  /// In en, this message translates to:
  /// **'Last cycle'**
  String get lastCycle;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load: {error}'**
  String couldNotLoad(String error);

  /// No description provided for @couldNotLoadSummary.
  ///
  /// In en, this message translates to:
  /// **'Could not load summary'**
  String get couldNotLoadSummary;

  /// No description provided for @dashboardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Dashboard unavailable'**
  String get dashboardUnavailable;

  /// No description provided for @productsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} product(s)'**
  String productsCount(int count);

  /// No description provided for @unitsDocsCount.
  ///
  /// In en, this message translates to:
  /// **'{quantity} units · {count} docs'**
  String unitsDocsCount(String quantity, int count);

  /// No description provided for @quantityTimesPrice.
  ///
  /// In en, this message translates to:
  /// **'{quantity} × {price}'**
  String quantityTimesPrice(String quantity, String price);

  /// No description provided for @lowStockNote.
  ///
  /// In en, this message translates to:
  /// **'{name} low on stock'**
  String lowStockNote(String name);

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTitle;

  /// No description provided for @syncStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get syncStatusTitle;

  /// No description provided for @lastSyncLabel.
  ///
  /// In en, this message translates to:
  /// **'Last sync'**
  String get lastSyncLabel;

  /// No description provided for @pendingChangesCount.
  ///
  /// In en, this message translates to:
  /// **'Pending changes'**
  String get pendingChangesCount;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String syncFailed(String error);

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'{operation} failed'**
  String operationFailed(String operation);

  /// No description provided for @conflicts.
  ///
  /// In en, this message translates to:
  /// **'conflicts'**
  String get conflicts;

  /// No description provided for @noConflicts.
  ///
  /// In en, this message translates to:
  /// **'No conflicts'**
  String get noConflicts;

  /// No description provided for @entityRef.
  ///
  /// In en, this message translates to:
  /// **'{type} #{id}'**
  String entityRef(String type, int id);

  /// No description provided for @serverChanged.
  ///
  /// In en, this message translates to:
  /// **'server changed: '**
  String get serverChanged;

  /// No description provided for @serverVersion.
  ///
  /// In en, this message translates to:
  /// **'server version: {json}'**
  String serverVersion(String json);

  /// No description provided for @operationDetail.
  ///
  /// In en, this message translates to:
  /// **'operation: {operation}'**
  String operationDetail(String operation);

  /// No description provided for @pushed.
  ///
  /// In en, this message translates to:
  /// **'pushed'**
  String get pushed;

  /// No description provided for @pulled.
  ///
  /// In en, this message translates to:
  /// **'pulled'**
  String get pulled;

  /// No description provided for @rejectedWithError.
  ///
  /// In en, this message translates to:
  /// **'rejected: {error}'**
  String rejectedWithError(String error);

  /// No description provided for @backupSubject.
  ///
  /// In en, this message translates to:
  /// **'Khata backup'**
  String get backupSubject;

  /// No description provided for @backupShareText.
  ///
  /// In en, this message translates to:
  /// **'Khata backup exported from this device.'**
  String get backupShareText;

  /// No description provided for @recordsAddedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} record(s) added'**
  String recordsAddedCount(int count);

  /// No description provided for @alreadyPresentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} already present, left alone'**
  String alreadyPresentCount(int count);

  /// No description provided for @addedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} added'**
  String addedCount(int count);

  /// No description provided for @addedKeptCount.
  ///
  /// In en, this message translates to:
  /// **'{count} added, {kept} kept'**
  String addedKeptCount(int count, int kept);

  /// No description provided for @reminderRepeatNote.
  ///
  /// In en, this message translates to:
  /// **'A repeating reminder reschedules itself after firing.'**
  String get reminderRepeatNote;

  /// No description provided for @profileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageNepali.
  ///
  /// In en, this message translates to:
  /// **'नेपाली'**
  String get languageNepali;

  /// No description provided for @calendarLabel.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarLabel;

  /// No description provided for @generalSection.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalSection;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @fromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toLabel;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get titleRequired;

  /// No description provided for @sourceRequired.
  ///
  /// In en, this message translates to:
  /// **'Source *'**
  String get sourceRequired;

  /// No description provided for @taxExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 13'**
  String get taxExample;

  /// No description provided for @amountExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 20.00'**
  String get amountExample;

  /// No description provided for @quantityExample16.
  ///
  /// In en, this message translates to:
  /// **'e.g. 16.00'**
  String get quantityExample16;

  /// No description provided for @rateExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 25'**
  String get rateExample;

  /// No description provided for @plusOne.
  ///
  /// In en, this message translates to:
  /// **'+1'**
  String get plusOne;

  /// No description provided for @plusTen.
  ///
  /// In en, this message translates to:
  /// **'+10'**
  String get plusTen;

  /// No description provided for @minusOne.
  ///
  /// In en, this message translates to:
  /// **'-1'**
  String get minusOne;

  /// No description provided for @minusTen.
  ///
  /// In en, this message translates to:
  /// **'-10'**
  String get minusTen;

  /// No description provided for @phonePrefixHint.
  ///
  /// In en, this message translates to:
  /// **'+977 98XXXXXXXX'**
  String get phonePrefixHint;

  /// No description provided for @rankLabel.
  ///
  /// In en, this message translates to:
  /// **'#'**
  String get rankLabel;

  /// No description provided for @editKind.
  ///
  /// In en, this message translates to:
  /// **'Edit {kind}'**
  String editKind(String kind);

  /// No description provided for @newKind.
  ///
  /// In en, this message translates to:
  /// **'New {kind}'**
  String newKind(String kind);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @convert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convert;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportTitle;

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreTitle;

  /// No description provided for @expenseTrend.
  ///
  /// In en, this message translates to:
  /// **'Expense trend'**
  String get expenseTrend;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get opening;

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get filterByCategory;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @emailMustHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Email (must have an account)'**
  String get emailMustHaveAccount;

  /// No description provided for @advancesExplainer.
  ///
  /// In en, this message translates to:
  /// **'Advances are money you already hold (customer) or have already paid (supplier), so they are applied before new payments.'**
  String get advancesExplainer;

  /// No description provided for @backupExportExplainerFull.
  ///
  /// In en, this message translates to:
  /// **'Saves every product, party, sale, purchase, expense, income, payment, invoice and quotation in the active business. Soft-deleted records are kept, so history survives.'**
  String get backupExportExplainerFull;

  /// No description provided for @backupRestoreExplainerFull.
  ///
  /// In en, this message translates to:
  /// **'Restoring merges a backup into this business. Records that already exist are skipped — nothing is ever overwritten, because a rewritten sale or payment would leave the khata ledger disagreeing with itself.'**
  String get backupRestoreExplainerFull;

  /// No description provided for @backupNotIncludedExplainer.
  ///
  /// In en, this message translates to:
  /// **'The khata ledger entries and stock movements are derived from the documents above, so they are rebuilt by replaying those operations rather than copied. A restore therefore brings back your records, not the cached totals.'**
  String get backupNotIncludedExplainer;

  /// No description provided for @restoreConfirmBodyFull.
  ///
  /// In en, this message translates to:
  /// **'Records that already exist in this business will be skipped. Nothing currently here is modified or deleted.'**
  String get restoreConfirmBodyFull;

  /// No description provided for @methodChangeNoteFull.
  ///
  /// In en, this message translates to:
  /// **'Payments already recorded with this method keep working. Renaming the method does not rewrite history.'**
  String get methodChangeNoteFull;

  /// No description provided for @saleDeleteNoteFull.
  ///
  /// In en, this message translates to:
  /// **'Stock will be restored and the customer khata reversed.'**
  String get saleDeleteNoteFull;

  /// No description provided for @purchaseDeleteNoteFull.
  ///
  /// In en, this message translates to:
  /// **'Stock will be reduced back and the supplier khata reversed.'**
  String get purchaseDeleteNoteFull;

  /// No description provided for @lineItemsCopiedNoteFull.
  ///
  /// In en, this message translates to:
  /// **'Line items will be copied from the selected sale and its prices kept.'**
  String get lineItemsCopiedNoteFull;

  /// No description provided for @notificationsInAppNoteFull.
  ///
  /// In en, this message translates to:
  /// **'In-app notifications are always recorded. These switches control push delivery only.'**
  String get notificationsInAppNoteFull;

  /// No description provided for @unitNameShort.
  ///
  /// In en, this message translates to:
  /// **'{name} ({short})'**
  String unitNameShort(String name, String short);

  /// No description provided for @retailValue.
  ///
  /// In en, this message translates to:
  /// **'retail {amount}'**
  String retailValue(String amount);

  /// No description provided for @advanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Advance {amount}'**
  String advanceAmount(String amount);

  /// No description provided for @quantityWithUnit.
  ///
  /// In en, this message translates to:
  /// **'{quantity}{unit}'**
  String quantityWithUnit(String quantity, String unit);

  /// No description provided for @productPricePair.
  ///
  /// In en, this message translates to:
  /// **'{price}  •  '**
  String productPricePair(String price);

  /// No description provided for @saleCustomerLine.
  ///
  /// In en, this message translates to:
  /// **'{number} — {customer}'**
  String saleCustomerLine(String number, String customer);

  /// No description provided for @lineTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Line total: {amount}'**
  String lineTotalAmount(String amount);

  /// No description provided for @conflictsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} conflicts'**
  String conflictsCount(int count);

  /// No description provided for @noDataInRange.
  ///
  /// In en, this message translates to:
  /// **'No data in this range'**
  String get noDataInRange;

  /// No description provided for @nothingToBreakDown.
  ///
  /// In en, this message translates to:
  /// **'Nothing to break down'**
  String get nothingToBreakDown;

  /// No description provided for @noProductsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No products match this filter'**
  String get noProductsMatchFilter;

  /// No description provided for @noProductsSoldInRange.
  ///
  /// In en, this message translates to:
  /// **'No products sold in this range'**
  String get noProductsSoldInRange;

  /// No description provided for @noSalesToCustomersInRange.
  ///
  /// In en, this message translates to:
  /// **'No sales to customers in this range'**
  String get noSalesToCustomersInRange;

  /// No description provided for @nobodyOwesYou.
  ///
  /// In en, this message translates to:
  /// **'Nobody owes you money'**
  String get nobodyOwesYou;

  /// No description provided for @youOweNobody.
  ///
  /// In en, this message translates to:
  /// **'You owe nobody'**
  String get youOweNobody;

  /// No description provided for @addLabel.
  ///
  /// In en, this message translates to:
  /// **'Add {label}'**
  String addLabel(String label);

  /// No description provided for @couldNotLoadX.
  ///
  /// In en, this message translates to:
  /// **'Could not load {subject}.\n{error}'**
  String couldNotLoadX(String subject, String error);

  /// No description provided for @balances.
  ///
  /// In en, this message translates to:
  /// **'balances'**
  String get balances;

  /// No description provided for @expenseReport.
  ///
  /// In en, this message translates to:
  /// **'the expense report'**
  String get expenseReport;

  /// No description provided for @incomeReport.
  ///
  /// In en, this message translates to:
  /// **'the income report'**
  String get incomeReport;

  /// No description provided for @stockReportTitle.
  ///
  /// In en, this message translates to:
  /// **'the stock report'**
  String get stockReportTitle;

  /// No description provided for @expenseReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense report'**
  String get expenseReportTitle;

  /// No description provided for @incomeReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Income report'**
  String get incomeReportTitle;

  /// No description provided for @profitAndLossTitle.
  ///
  /// In en, this message translates to:
  /// **'Profit & loss'**
  String get profitAndLossTitle;

  /// No description provided for @stockMovements.
  ///
  /// In en, this message translates to:
  /// **'stock movements'**
  String get stockMovements;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'devices'**
  String get devices;

  /// No description provided for @emailAndRole.
  ///
  /// In en, this message translates to:
  /// **'{email}\n{role}'**
  String emailAndRole(String email, String role);

  /// No description provided for @addKind.
  ///
  /// In en, this message translates to:
  /// **'Add {kind}'**
  String addKind(String kind);

  /// No description provided for @lowAtOrBelow.
  ///
  /// In en, this message translates to:
  /// **'Low: at or below {quantity}{unit}'**
  String lowAtOrBelow(String quantity, String unit);

  /// No description provided for @minimumIs.
  ///
  /// In en, this message translates to:
  /// **'Minimum {quantity}{unit}'**
  String minimumIs(String quantity, String unit);

  /// No description provided for @savedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String savedTo(String path);

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequired;

  /// No description provided for @passwordRegisterRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get passwordRegisterRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordNeedsDigit.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one digit'**
  String get passwordNeedsDigit;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get fullNameRequired;

  /// No description provided for @fullNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameIsRequired;

  /// No description provided for @businessNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Business name is required'**
  String get businessNameIsRequired;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get amountRequired;

  /// No description provided for @amountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get amountInvalid;

  /// No description provided for @amountInvalidFull.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get amountInvalidFull;

  /// No description provided for @amountMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero.'**
  String get amountMustBePositive;

  /// No description provided for @quantityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity'**
  String get quantityInvalid;

  /// No description provided for @percentRange.
  ///
  /// In en, this message translates to:
  /// **'Enter 0–100'**
  String get percentRange;

  /// No description provided for @panMustBe9Digits.
  ///
  /// In en, this message translates to:
  /// **'PAN must be 9 digits.'**
  String get panMustBe9Digits;

  /// No description provided for @panMustBe9DigitNumber.
  ///
  /// In en, this message translates to:
  /// **'PAN must be a 9-digit number'**
  String get panMustBe9DigitNumber;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Phone number format is invalid.'**
  String get phoneInvalid;

  /// No description provided for @emailAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'A valid email address is required.'**
  String get emailAddressRequired;

  /// No description provided for @invalidEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get invalidEmailOrPassword;

  /// No description provided for @checkYourInput.
  ///
  /// In en, this message translates to:
  /// **'Please check your input.'**
  String get checkYourInput;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @returnIn.
  ///
  /// In en, this message translates to:
  /// **'Return in'**
  String get returnIn;

  /// No description provided for @returnOut.
  ///
  /// In en, this message translates to:
  /// **'Return out'**
  String get returnOut;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String todayAt(String time);

  /// No description provided for @tomorrowAt.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow {time}'**
  String tomorrowAt(String time);

  /// No description provided for @yesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String yesterdayAt(String time);

  /// No description provided for @noKindMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No {kind} match your search'**
  String noKindMatchSearch(String kind);

  /// No description provided for @noKindYet.
  ///
  /// In en, this message translates to:
  /// **'No {kind} yet'**
  String noKindYet(String kind);

  /// No description provided for @categoryReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get categoryReminder;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @productSaved.
  ///
  /// In en, this message translates to:
  /// **'Product saved'**
  String get productSaved;

  /// No description provided for @walkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in customer'**
  String get walkInCustomer;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @noSupplier.
  ///
  /// In en, this message translates to:
  /// **'No supplier'**
  String get noSupplier;

  /// No description provided for @paidInFull.
  ///
  /// In en, this message translates to:
  /// **'Paid (full)'**
  String get paidInFull;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get exporting;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @noLowStockProducts.
  ///
  /// In en, this message translates to:
  /// **'No low-stock products — all good!'**
  String get noLowStockProducts;

  /// No description provided for @noProductsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No products match your search'**
  String get noProductsMatchSearch;

  /// No description provided for @showingUnread.
  ///
  /// In en, this message translates to:
  /// **'Showing unread'**
  String get showingUnread;

  /// No description provided for @customerKhata.
  ///
  /// In en, this message translates to:
  /// **'Customer khata'**
  String get customerKhata;

  /// No description provided for @debit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get debit;

  /// No description provided for @recordReceipt.
  ///
  /// In en, this message translates to:
  /// **'Record receipt'**
  String get recordReceipt;

  /// No description provided for @applyToInvoice.
  ///
  /// In en, this message translates to:
  /// **'Apply to invoice'**
  String get applyToInvoice;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @roleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get roleViewer;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncing;

  /// No description provided for @moneyInOut.
  ///
  /// In en, this message translates to:
  /// **'In {inAmount} · Out {outAmount}'**
  String moneyInOut(String inAmount, String outAmount);

  /// No description provided for @dueAmount.
  ///
  /// In en, this message translates to:
  /// **'Due {amount}'**
  String dueAmount(String amount);

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @productCreated.
  ///
  /// In en, this message translates to:
  /// **'Product created'**
  String get productCreated;

  /// No description provided for @toCollectAmount.
  ///
  /// In en, this message translates to:
  /// **'To collect {amount}'**
  String toCollectAmount(String amount);

  /// No description provided for @toPayAmount.
  ///
  /// In en, this message translates to:
  /// **'To pay {amount}'**
  String toPayAmount(String amount);

  /// No description provided for @createProduct.
  ///
  /// In en, this message translates to:
  /// **'Create product'**
  String get createProduct;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @noProductsYet.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsYet;

  /// No description provided for @noProductsYetAddFirst.
  ///
  /// In en, this message translates to:
  /// **'No products yet — add your first product'**
  String get noProductsYetAddFirst;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @rateRs.
  ///
  /// In en, this message translates to:
  /// **'Rate (Rs.)'**
  String get rateRs;

  /// No description provided for @discountRs.
  ///
  /// In en, this message translates to:
  /// **'Disc (Rs.)'**
  String get discountRs;

  /// No description provided for @addAtLeastOneItem.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item'**
  String get addAtLeastOneItem;

  /// No description provided for @costValue.
  ///
  /// In en, this message translates to:
  /// **'Cost value'**
  String get costValue;

  /// No description provided for @potentialMargin.
  ///
  /// In en, this message translates to:
  /// **'Potential margin'**
  String get potentialMargin;

  /// No description provided for @invoiceCreated.
  ///
  /// In en, this message translates to:
  /// **'Invoice created'**
  String get invoiceCreated;

  /// No description provided for @invoiceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Invoice deleted'**
  String get invoiceDeleted;

  /// No description provided for @quotationCreated.
  ///
  /// In en, this message translates to:
  /// **'Quotation created'**
  String get quotationCreated;

  /// No description provided for @quotationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Quotation deleted'**
  String get quotationDeleted;

  /// No description provided for @convertedToSaleToast.
  ///
  /// In en, this message translates to:
  /// **'Converted to sale'**
  String get convertedToSaleToast;

  /// No description provided for @saleCreated.
  ///
  /// In en, this message translates to:
  /// **'Sale created'**
  String get saleCreated;

  /// No description provided for @saleReversed.
  ///
  /// In en, this message translates to:
  /// **'Sale reversed'**
  String get saleReversed;

  /// No description provided for @saleKeptAsReversed.
  ///
  /// In en, this message translates to:
  /// **'The sale is kept in history as reversed.'**
  String get saleKeptAsReversed;

  /// No description provided for @creditSaleNeedsCustomer.
  ///
  /// In en, this message translates to:
  /// **'A credit sale needs a customer'**
  String get creditSaleNeedsCustomer;

  /// No description provided for @purchaseCreated.
  ///
  /// In en, this message translates to:
  /// **'Purchase created'**
  String get purchaseCreated;

  /// No description provided for @purchaseReversed.
  ///
  /// In en, this message translates to:
  /// **'Purchase reversed'**
  String get purchaseReversed;

  /// No description provided for @purchaseKeptAsReversed.
  ///
  /// In en, this message translates to:
  /// **'The purchase is kept in history as reversed.'**
  String get purchaseKeptAsReversed;

  /// No description provided for @creditPurchaseNeedsSupplier.
  ///
  /// In en, this message translates to:
  /// **'A credit purchase needs a supplier'**
  String get creditPurchaseNeedsSupplier;

  /// No description provided for @paymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get paymentRecorded;

  /// No description provided for @methodSaved.
  ///
  /// In en, this message translates to:
  /// **'Method saved'**
  String get methodSaved;

  /// No description provided for @methodDeleted.
  ///
  /// In en, this message translates to:
  /// **'Method deleted'**
  String get methodDeleted;

  /// No description provided for @categorySaved.
  ///
  /// In en, this message translates to:
  /// **'Category saved'**
  String get categorySaved;

  /// No description provided for @categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get categoryDeleted;

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted'**
  String get productDeleted;

  /// No description provided for @unitSaved.
  ///
  /// In en, this message translates to:
  /// **'Unit saved'**
  String get unitSaved;

  /// No description provided for @unitDeleted.
  ///
  /// In en, this message translates to:
  /// **'Unit deleted'**
  String get unitDeleted;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @atLeastOneMethodMustRemain.
  ///
  /// In en, this message translates to:
  /// **'At least one payment method must remain.'**
  String get atLeastOneMethodMustRemain;

  /// No description provided for @notAkhataBackup.
  ///
  /// In en, this message translates to:
  /// **'This is not a Khata backup.'**
  String get notAkhataBackup;

  /// No description provided for @enterNonZeroQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a non-zero quantity'**
  String get enterNonZeroQuantity;

  /// No description provided for @enterAmountGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero'**
  String get enterAmountGreaterThanZero;

  /// No description provided for @balanceAfterIs.
  ///
  /// In en, this message translates to:
  /// **'Bal {quantity}'**
  String balanceAfterIs(String quantity);

  /// No description provided for @rejectedAndFailed.
  ///
  /// In en, this message translates to:
  /// **'Rejected & failed'**
  String get rejectedAndFailed;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get entries;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @costOfGoodsSold.
  ///
  /// In en, this message translates to:
  /// **'Cost of goods sold'**
  String get costOfGoodsSold;

  /// No description provided for @grossProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross profit'**
  String get grossProfit;

  /// No description provided for @otherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other income'**
  String get otherIncome;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net profit'**
  String get netProfit;

  /// No description provided for @taxCollectedInPeriod.
  ///
  /// In en, this message translates to:
  /// **'Tax collected in this period: '**
  String get taxCollectedInPeriod;

  /// No description provided for @customerAdvances.
  ///
  /// In en, this message translates to:
  /// **'Customer advances'**
  String get customerAdvances;

  /// No description provided for @supplierAdvances.
  ///
  /// In en, this message translates to:
  /// **'Supplier advances'**
  String get supplierAdvances;

  /// No description provided for @advancesExplain.
  ///
  /// In en, this message translates to:
  /// **'Advances are money you already hold (customer) or have overpaid (supplier).'**
  String get advancesExplain;

  /// No description provided for @reportSalesBlurb.
  ///
  /// In en, this message translates to:
  /// **'Trends, totals, top products and customers'**
  String get reportSalesBlurb;

  /// No description provided for @reportProfitLossBlurb.
  ///
  /// In en, this message translates to:
  /// **'Revenue, cost of goods and net profit'**
  String get reportProfitLossBlurb;

  /// No description provided for @reportExpenseBlurb.
  ///
  /// In en, this message translates to:
  /// **'Where the money went, by category'**
  String get reportExpenseBlurb;

  /// No description provided for @reportIncomeBlurb.
  ///
  /// In en, this message translates to:
  /// **'Other income by source'**
  String get reportIncomeBlurb;

  /// No description provided for @reportStockBlurb.
  ///
  /// In en, this message translates to:
  /// **'Cost and retail value of stock on hand'**
  String get reportStockBlurb;

  /// No description provided for @reportReceivableBlurb.
  ///
  /// In en, this message translates to:
  /// **'Who owes you and who you owe'**
  String get reportReceivableBlurb;

  /// No description provided for @ledgerOwesYouHint.
  ///
  /// In en, this message translates to:
  /// **'Amount they owe you (customer) / you paid (supplier)'**
  String get ledgerOwesYouHint;

  /// No description provided for @ledgerYouOweHint.
  ///
  /// In en, this message translates to:
  /// **'Amount paid to you (customer) / you owe (supplier)'**
  String get ledgerYouOweHint;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleAccountant.
  ///
  /// In en, this message translates to:
  /// **'Accountant'**
  String get roleAccountant;

  /// No description provided for @noBusiness.
  ///
  /// In en, this message translates to:
  /// **'No business'**
  String get noBusiness;

  /// No description provided for @couldNotLoadProducts.
  ///
  /// In en, this message translates to:
  /// **'Could not load products.\\n{error}'**
  String couldNotLoadProducts(String error);

  /// No description provided for @lineItemsCopiedFromSale.
  ///
  /// In en, this message translates to:
  /// **'Line items will be copied from the selected sale and its invoice number reused.'**
  String get lineItemsCopiedFromSale;

  /// No description provided for @bsRange.
  ///
  /// In en, this message translates to:
  /// **'BS: {from}  →  {to}'**
  String bsRange(String from, String to);

  /// No description provided for @conflictsNamed.
  ///
  /// In en, this message translates to:
  /// **'Conflicts ({count})'**
  String conflictsNamed(int count);

  /// No description provided for @retailValueReport.
  ///
  /// In en, this message translates to:
  /// **'Retail value'**
  String get retailValueReport;

  /// No description provided for @selectPartyKind.
  ///
  /// In en, this message translates to:
  /// **'Select a {kind}'**
  String selectPartyKind(String kind);

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @adjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get adjustment;

  /// No description provided for @showingAll.
  ///
  /// In en, this message translates to:
  /// **'Showing all'**
  String get showingAll;

  /// No description provided for @supplierKhata.
  ///
  /// In en, this message translates to:
  /// **'Supplier khata'**
  String get supplierKhata;

  /// No description provided for @applyToBill.
  ///
  /// In en, this message translates to:
  /// **'Apply to bill'**
  String get applyToBill;

  /// No description provided for @newMethod.
  ///
  /// In en, this message translates to:
  /// **'New method'**
  String get newMethod;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @municipality.
  ///
  /// In en, this message translates to:
  /// **'Municipality'**
  String get municipality;

  /// No description provided for @selectProvinceHint.
  ///
  /// In en, this message translates to:
  /// **'Select province'**
  String get selectProvinceHint;

  /// No description provided for @selectDistrictHint.
  ///
  /// In en, this message translates to:
  /// **'Select district'**
  String get selectDistrictHint;

  /// No description provided for @selectMunicipalityHint.
  ///
  /// In en, this message translates to:
  /// **'Select municipality'**
  String get selectMunicipalityHint;

  /// No description provided for @municipalityFreeTextHint.
  ///
  /// In en, this message translates to:
  /// **'Type the municipality — not every local unit is listed here.'**
  String get municipalityFreeTextHint;

  /// No description provided for @phoneInvalidNepali.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Nepali phone number, e.g. 98XXXXXXXX'**
  String get phoneInvalidNepali;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toDate;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @endBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End date cannot be before the start date.'**
  String get endBeforeStart;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @toolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsTitle;

  /// No description provided for @emiCalculator.
  ///
  /// In en, this message translates to:
  /// **'EMI Calculator'**
  String get emiCalculator;

  /// No description provided for @loanAmount.
  ///
  /// In en, this message translates to:
  /// **'Loan amount (Rs.)'**
  String get loanAmount;

  /// No description provided for @annualInterestRate.
  ///
  /// In en, this message translates to:
  /// **'Annual interest rate (%)'**
  String get annualInterestRate;

  /// No description provided for @loanTermMonths.
  ///
  /// In en, this message translates to:
  /// **'Loan term (months)'**
  String get loanTermMonths;

  /// No description provided for @monthlyEmi.
  ///
  /// In en, this message translates to:
  /// **'Monthly EMI'**
  String get monthlyEmi;

  /// No description provided for @totalPayment.
  ///
  /// In en, this message translates to:
  /// **'Total payment'**
  String get totalPayment;

  /// No description provided for @totalInterest.
  ///
  /// In en, this message translates to:
  /// **'Total interest'**
  String get totalInterest;

  /// No description provided for @interestCalculator.
  ///
  /// In en, this message translates to:
  /// **'Interest Calculator'**
  String get interestCalculator;

  /// No description provided for @simpleInterest.
  ///
  /// In en, this message translates to:
  /// **'Simple interest'**
  String get simpleInterest;

  /// No description provided for @compoundInterest.
  ///
  /// In en, this message translates to:
  /// **'Compound interest'**
  String get compoundInterest;

  /// No description provided for @principal.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get principal;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get years;

  /// No description provided for @compoundingPerYear.
  ///
  /// In en, this message translates to:
  /// **'Compounding per year'**
  String get compoundingPerYear;

  /// No description provided for @interestEarned.
  ///
  /// In en, this message translates to:
  /// **'Interest earned'**
  String get interestEarned;

  /// No description provided for @profitCalculator.
  ///
  /// In en, this message translates to:
  /// **'Profit Calculator'**
  String get profitCalculator;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @profitMargin.
  ///
  /// In en, this message translates to:
  /// **'Profit margin'**
  String get profitMargin;

  /// No description provided for @markup.
  ///
  /// In en, this message translates to:
  /// **'Markup'**
  String get markup;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @maturityAmount.
  ///
  /// In en, this message translates to:
  /// **'Maturity amount'**
  String get maturityAmount;

  /// No description provided for @calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// No description provided for @lossWarning.
  ///
  /// In en, this message translates to:
  /// **'This is a loss, not a profit.'**
  String get lossWarning;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLock;

  /// No description provided for @appLockDescription.
  ///
  /// In en, this message translates to:
  /// **'Require a PIN to open the app'**
  String get appLockDescription;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPin;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get enterPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @currentPin.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get currentPin;

  /// No description provided for @newPin.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get newPin;

  /// No description provided for @pinMustBe4To6Digits.
  ///
  /// In en, this message translates to:
  /// **'PIN must be 4 to 6 digits'**
  String get pinMustBe4To6Digits;

  /// No description provided for @pinsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs do not match'**
  String get pinsDoNotMatch;

  /// No description provided for @incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get incorrectPin;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @turnOffAppLock.
  ///
  /// In en, this message translates to:
  /// **'Turn off app lock'**
  String get turnOffAppLock;

  /// No description provided for @appLockNowOn.
  ///
  /// In en, this message translates to:
  /// **'App lock is on'**
  String get appLockNowOn;

  /// No description provided for @appLockNowOff.
  ///
  /// In en, this message translates to:
  /// **'App lock is off'**
  String get appLockNowOff;

  /// Remaining unlock attempts after a wrong PIN.
  ///
  /// In en, this message translates to:
  /// **'{count} attempts left'**
  String attemptsLeft(int count);

  /// No description provided for @bankAccounts.
  ///
  /// In en, this message translates to:
  /// **'Bank accounts'**
  String get bankAccounts;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank name'**
  String get bankName;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountName;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get accountNumber;

  /// No description provided for @branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// No description provided for @defaultAccount.
  ///
  /// In en, this message translates to:
  /// **'Default account'**
  String get defaultAccount;

  /// No description provided for @noBankAccountsYet.
  ///
  /// In en, this message translates to:
  /// **'No bank accounts yet. Add one to record transfers.'**
  String get noBankAccountsYet;

  /// No description provided for @addBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Add bank account'**
  String get addBankAccount;

  /// Summary of payments recorded through one bank account.
  ///
  /// In en, this message translates to:
  /// **'{count} payments · {total}'**
  String paymentsThroughAccount(int count, String total);

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @importTile.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importTile;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from Excel'**
  String get importTitle;

  /// No description provided for @importExplainerTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get importExplainerTitle;

  /// No description provided for @importExplainerBody.
  ///
  /// In en, this message translates to:
  /// **'Paste the rows from your spreadsheet here. Copy the template, fill it in Excel, save it as CSV and paste it back. Every row is checked before anything is written — if one row is wrong, nothing is imported.'**
  String get importExplainerBody;

  /// No description provided for @importCopyTemplate.
  ///
  /// In en, this message translates to:
  /// **'Copy template'**
  String get importCopyTemplate;

  /// No description provided for @importTemplateCopied.
  ///
  /// In en, this message translates to:
  /// **'Template copied — paste it into Excel'**
  String get importTemplateCopied;

  /// No description provided for @importPasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get importPasteFromClipboard;

  /// No description provided for @importCsvLabel.
  ///
  /// In en, this message translates to:
  /// **'CSV rows'**
  String get importCsvLabel;

  /// No description provided for @importCheckFile.
  ///
  /// In en, this message translates to:
  /// **'Check file'**
  String get importCheckFile;

  /// No description provided for @importChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get importChecking;

  /// No description provided for @importRun.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importRun;

  /// No description provided for @importImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get importImporting;

  /// No description provided for @importPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Check result'**
  String get importPreviewTitle;

  /// No description provided for @importRowsTotal.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get importRowsTotal;

  /// No description provided for @importRowsValid.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get importRowsValid;

  /// No description provided for @importRowsDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Already exist'**
  String get importRowsDuplicate;

  /// No description provided for @importRowsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Need fixing'**
  String get importRowsInvalid;

  /// No description provided for @importBlockedHint.
  ///
  /// In en, this message translates to:
  /// **'Nothing will be imported until every row is fixed.'**
  String get importBlockedHint;

  /// No description provided for @importIgnoredColumns.
  ///
  /// In en, this message translates to:
  /// **'Ignored columns: {columns}'**
  String importIgnoredColumns(String columns);

  /// No description provided for @importIssuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rows to fix'**
  String get importIssuesTitle;

  /// No description provided for @importIssueLine.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: {message}'**
  String importIssueLine(int row, String message);

  /// No description provided for @importIssueLineWithColumn.
  ///
  /// In en, this message translates to:
  /// **'Row {row} · {column}: {message}'**
  String importIssueLineWithColumn(int row, String column, String message);

  /// No description provided for @importMoreIssues.
  ///
  /// In en, this message translates to:
  /// **'…and {count} more'**
  String importMoreIssues(int count);

  /// No description provided for @importConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Import these rows?'**
  String get importConfirmTitle;

  /// No description provided for @importConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Rows that already exist are skipped; nothing is overwritten.'**
  String get importConfirmBody;

  /// No description provided for @importCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Import complete'**
  String get importCompleteTitle;

  /// No description provided for @importCreatedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} record(s) created'**
  String importCreatedCount(int count);

  /// No description provided for @importSkippedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} already existed and were skipped'**
  String importSkippedCount(int count);

  /// No description provided for @importRejected.
  ///
  /// In en, this message translates to:
  /// **'Nothing was imported — fix the rows below and try again.'**
  String get importRejected;

  /// No description provided for @importClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get importClear;

  /// No description provided for @importExpectedColumns.
  ///
  /// In en, this message translates to:
  /// **'Expected columns'**
  String get importExpectedColumns;

  /// No description provided for @cachedDataNote.
  ///
  /// In en, this message translates to:
  /// **'Showing saved data. Reconnect to refresh.'**
  String get cachedDataNote;

  /// No description provided for @cachedDataNoteAt.
  ///
  /// In en, this message translates to:
  /// **'Showing saved data from {time}. Reconnect to refresh.'**
  String cachedDataNoteAt(String time);

  /// No description provided for @offlineDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline data'**
  String get offlineDataTitle;

  /// No description provided for @offlineDataExplainer.
  ///
  /// In en, this message translates to:
  /// **'Lists you open are saved on this device, so they still open when the internet is down.'**
  String get offlineDataExplainer;

  /// No description provided for @offlineDataSavedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved lists'**
  String get offlineDataSavedLabel;

  /// No description provided for @offlineDataSavedCount.
  ///
  /// In en, this message translates to:
  /// **'{lists} list(s) · {size}'**
  String offlineDataSavedCount(int lists, String size);

  /// No description provided for @offlineDataClear.
  ///
  /// In en, this message translates to:
  /// **'Clear saved data'**
  String get offlineDataClear;

  /// No description provided for @offlineDataClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the saved lists? They will be downloaded again the next time you open them.'**
  String get offlineDataClearConfirm;

  /// No description provided for @offlineDataCleared.
  ///
  /// In en, this message translates to:
  /// **'Saved data cleared'**
  String get offlineDataCleared;

  /// No description provided for @loadMoreRemaining.
  ///
  /// In en, this message translates to:
  /// **'Load more ({count} remaining)'**
  String loadMoreRemaining(int count);

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @pageNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'This page is not available. It may have been moved, or the link may be wrong.'**
  String get pageNotFoundBody;

  /// No description provided for @fileSaveNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Saving and sharing files needs the app on a phone — the browser version cannot write files.'**
  String get fileSaveNotSupported;

  /// No description provided for @savedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved offline — it will sync when you reconnect.'**
  String get savedOffline;

  /// No description provided for @offlineBannerNote.
  ///
  /// In en, this message translates to:
  /// **'Offline — changes will sync when you\'re back'**
  String get offlineBannerNote;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @calendarAd.
  ///
  /// In en, this message translates to:
  /// **'AD (English date)'**
  String get calendarAd;

  /// No description provided for @calendarBs.
  ///
  /// In en, this message translates to:
  /// **'BS (Bikram Sambat)'**
  String get calendarBs;

  /// No description provided for @calendarNote.
  ///
  /// In en, this message translates to:
  /// **'Dates are shown and picked in this calendar.'**
  String get calendarNote;

  /// No description provided for @pendingWritesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting'**
  String pendingWritesCount(int count);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navParties.
  ///
  /// In en, this message translates to:
  /// **'Parties'**
  String get navParties;

  /// No description provided for @navItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get navItems;

  /// No description provided for @monthToDate.
  ///
  /// In en, this message translates to:
  /// **'This month {amount}'**
  String monthToDate(String amount);

  /// No description provided for @lowStockCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} low on stock'**
  String lowStockCountLabel(int count);

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @getStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStartedTitle;

  /// No description provided for @getStartedStepProduct.
  ///
  /// In en, this message translates to:
  /// **'Add your first product'**
  String get getStartedStepProduct;

  /// No description provided for @getStartedStepCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add a customer'**
  String get getStartedStepCustomer;

  /// No description provided for @getStartedStepSale.
  ///
  /// In en, this message translates to:
  /// **'Record your first sale'**
  String get getStartedStepSale;

  /// No description provided for @shareReminder.
  ///
  /// In en, this message translates to:
  /// **'Share reminder'**
  String get shareReminder;

  /// No description provided for @reminderShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Namaste {name}, your balance at {business} is {amount}. Please settle it when convenient. Thank you.'**
  String reminderShareMessage(String name, String business, String amount);

  /// No description provided for @moreSalesDocs.
  ///
  /// In en, this message translates to:
  /// **'Sales & documents'**
  String get moreSalesDocs;

  /// No description provided for @moreItems.
  ///
  /// In en, this message translates to:
  /// **'Items & stock'**
  String get moreItems;

  /// No description provided for @moreInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get moreInsights;

  /// No description provided for @moreTools.
  ///
  /// In en, this message translates to:
  /// **'Tools & settings'**
  String get moreTools;

  /// No description provided for @moreAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get moreAccount;

  /// No description provided for @balanceShort.
  ///
  /// In en, this message translates to:
  /// **'bal {amount}'**
  String balanceShort(String amount);

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @welcomeChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get welcomeChooseLanguage;

  /// No description provided for @welcomeSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get welcomeSkip;

  /// No description provided for @welcomeSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'A khata that never forgets'**
  String get welcomeSlide1Title;

  /// No description provided for @welcomeSlide1Body.
  ///
  /// In en, this message translates to:
  /// **'Every credit sale, every payment and every balance — written once, always correct.'**
  String get welcomeSlide1Body;

  /// No description provided for @welcomeSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Stock that counts itself'**
  String get welcomeSlide2Title;

  /// No description provided for @welcomeSlide2Body.
  ///
  /// In en, this message translates to:
  /// **'Sales and purchases move stock automatically, and you are warned before an item runs out.'**
  String get welcomeSlide2Body;

  /// No description provided for @welcomeSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Numbers you can act on'**
  String get welcomeSlide3Title;

  /// No description provided for @welcomeSlide3Body.
  ///
  /// In en, this message translates to:
  /// **'Daily profit, what to collect and what to pay — in AD or BS dates, in your language.'**
  String get welcomeSlide3Body;

  /// No description provided for @tryDemo.
  ///
  /// In en, this message translates to:
  /// **'Try the demo'**
  String get tryDemo;
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
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

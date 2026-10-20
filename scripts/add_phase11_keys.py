#!/usr/bin/env python3
"""Add the Phase 11 localization keys to both ARB files.

Run once: the keys below are the literals found in the 51 pages that still
render English inline. After this, scripts/migrate_strings.py rewrites those
pages to use AppLocalizations.

Nepali translations are provided for every key so the two files stay in parity
(a missing key is a build-time failure in gen-l10n, not a silent fallback).
"""

from __future__ import annotations

import collections
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
L10N = ROOT / "apps" / "mobile" / "lib" / "l10n"

# key -> (english, nepali) or (english, nepali, {placeholder: type})
NEW: dict[str, tuple] = {
    # --- shared chrome ---
    "save": ("Save", "सुरक्षित गर्नुहोस्"),
    "change": ("Change", "परिवर्तन"),
    "all": ("All", "सबै"),
    "none": ("None", "कुनै पनि होइन"),
    "code": ("Code", "कोड"),
    "role": ("Role", "भूमिका"),
    "filter": ("Filter", "फिल्टर"),
    "sort": ("Sort", "क्रमबद्ध"),
    "optional": ("optional", "वैकल्पिक"),
    "pendingChanges": ("Pending changes", "पर्खाइमा रहेका परिवर्तन"),
    "confirm": ("Confirm", "पुष्टि गर्नुहोस्"),
    "delete": ("Delete", "मेट्नुहोस्"),
    "remove": ("Remove", "हटाउनुहोस्"),
    "cancel": ("Cancel", "रद्द गर्नुहोस्"),
    "close": ("Close", "बन्द गर्नुहोस्"),
    "yes": ("Yes", "हो"),
    "no": ("No", "होइन"),

    # --- residual sweep: parameterised literals already rendered inline ---
    # `label` is a String so callers pass e.g. `party.supplier.label.toLowerCase()`.
    "addLabel": ("Add {label}", "थप्नुहोस् {label}", {"label": "String"}),
    "lineTotalIs": ("Line total: {total}", "लाइन जम्मा: {total}", {"total": "String"}),
    "conflictsCount": ("{count} conflicts", "{count} द्वन्द्व", {"count": "int"}),
    "noDataInRange": ("No data in this range", "यो अवधिमा कुनै डेटा छैन"),
    "nothingToBreakDown": ("Nothing to break down", "तोड्ने कुनै कुरा छैन"),
    "noProductsMatchFilter": (
        "No products match this filter",
        "यो फिल्टरसँग मिल्ने कुनै उत्पादन छैन",
    ),
    "noProductsSoldInRange": (
        "No products sold in this range",
        "यो अवधिमा कुनै उत्पादन बिक्री भएन",
    ),
    "noSalesToCustomersInRange": (
        "No sales to customers in this range",
        "यो अवधिमा ग्राहकलाई कुनै बिक्री भएन",
    ),
    "nobodyOwesYou": ("Nobody owes you money", "कसैले तपाईंलाई पैसा तिर्नु छैन"),
    "youOweNobody": ("You owe nobody", "तपाईंले कसैलाई पैसा तिर्नु छैन"),
    # One shared shape for the ~25 "<list page> failed to load" bodies. `subject`
    # is already-localized so the Nepali sentence order can put it after the verb.
    "couldNotLoadX": (
        "Could not load {subject}.\n{error}",
        "{subject} लोड गर्न सकिएन।\n{error}",
        {"subject": "String", "error": "String"},
    ),
    "balances": ("balances", "बाँकी रकम"),
    "expenseReport": ("the expense report", "खर्च प्रतिवेदन"),
    "incomeReport": ("the income report", "आय प्रतिवेदन"),
    "profitAndLoss": ("the profit & loss", "नाफा–नोक्सान"),
    "salesReportTitle": ("the sales report", "बिक्री प्रतिवेदन"),
    "stockReportTitle": ("the stock report", "स्टक प्रतिवेदन"),
    "expenseReportTitle": ("Expense report", "खर्च प्रतिवेदन"),
    "incomeReportTitle": ("Income report", "आय प्रतिवेदन"),
    "profitAndLossTitle": ("Profit & loss", "नाफा–नोक्सान"),
    "paymentMethods": ("payment methods", "भुक्तानी विधि"),
    "stockMovements": ("stock movements", "स्टक चलन"),
    "devices": ("devices", "उपकरणहरू"),
    "settings": ("settings", "सेटिङ"),
    "reminders": ("reminders", "सम्झनाहरू"),
    "khata": ("khata", "खाता"),
    "notesLabel": ("Notes: {notes}", "टिप्पणी: {notes}", {"notes": "String"}),
    "termsLabel": ("Terms: {terms}", "सर्तहरू: {terms}", {"terms": "String"}),
    "emailAndRole": ("{email}\n{role}", "{email}\n{role}", {"email": "String", "role": "String"}),
    "salesTrendScope": ("Sales trend · {scope}", "बिक्री प्रवृत्ति · {scope}", {"scope": "String"}),
    "lowAtOrBelow": (
        "Low: at or below {quantity}{unit}",
        "कम: {quantity}{unit} वा कम",
        {"quantity": "String", "unit": "String"},
    ),
    "minimumIs": (
        "Minimum {quantity}{unit}",
        "न्यूनतम {quantity}{unit}",
        {"quantity": "String", "unit": "String"},
    ),
    "savedTo": ("Saved to {path}", "यहाँ सुरक्षित गरियो: {path}", {"path": "String"}),

    # --- validation messages returned from form validators -------------------
    # These surface under a TextField, so they are as user-facing as any label.
    "emailRequired": ("Please enter your email", "कृपया आफ्नो इमेल लेख्नुहोस्"),
    "emailInvalid": ("Please enter a valid email", "कृपया मान्य इमेल लेख्नुहोस्"),
    "passwordRequired": ("Please enter your password", "कृपया आफ्नो पासवर्ड लेख्नुहोस्"),
    "passwordRegisterRequired": ("Please enter a password", "कृपया पासवर्ड लेख्नुहोस्"),
    "passwordTooShort": (
        "Password must be at least 8 characters",
        "पासवर्ड कम्तीमा ८ अक्षरको हुनुपर्छ",
    ),
    "passwordNeedsDigit": (
        "Password must contain at least one digit",
        "पासवर्डमा कम्तीमा एक अंक हुनुपर्छ",
    ),
    "confirmPasswordRequired": ("Please confirm your password", "कृपया पासवर्ड पुष्टि गर्नुहोस्"),
    "passwordsDoNotMatch": ("Passwords do not match", "पासवर्डहरू मिलेनन्"),
    "fullNameRequired": ("Please enter your full name", "कृपया आफ्नो पूरा नाम लेख्नुहोस्"),
    "fullNameIsRequired": ("Full name is required", "पूरा नाम आवश्यक छ"),
    "businessNameIsRequired": ("Business name is required", "व्यवसायको नाम आवश्यक छ"),
    "amountRequired": ("Amount is required", "रकम आवश्यक छ"),
    "amountInvalid": ("Enter a valid amount", "मान्य रकम लेख्नुहोस्"),
    "amountInvalidFull": ("Enter a valid amount.", "मान्य रकम लेख्नुहोस्।"),
    "amountMustBePositive": (
        "Amount must be greater than zero.",
        "रकम शून्यभन्दा बढी हुनुपर्छ।",
    ),
    "quantityInvalid": ("Enter a valid quantity", "मान्य परिमाण लेख्नुहोस्"),
    "percentRange": ("Enter 0–100", "०–१०० लेख्नुहोस्"),
    "panMustBe9Digits": ("PAN must be 9 digits.", "प्यान ९ अंकको हुनुपर्छ।"),
    "panMustBe9DigitNumber": (
        "PAN must be a 9-digit number",
        "प्यान ९ अंकको संख्या हुनुपर्छ",
    ),
    "phoneInvalid": ("Phone number format is invalid.", "फोन नम्बरको ढाँचा मिलेन।"),
    "emailAddressRequired": (
        "A valid email address is required.",
        "मान्य इमेल ठेगाना आवश्यक छ।",
    ),
    "invalidEmailOrPassword": ("Invalid email or password.", "इमेल वा पासवर्ड मिलेन।"),
    "checkYourInput": ("Please check your input.", "कृपया आफ्नो जानकारी जाँच्नुहोस्।"),
    "somethingWentWrong": (
        "Something went wrong. Please try again.",
        "केही गडबड भयो। कृपया फेरि प्रयास गर्नुहोस्।",
    ),

    # --- enums rendered as labels -------------------------------------------
    "returnIn": ("Return in", "फिर्ता आएको"),
    "returnOut": ("Return out", "फिर्ता गएको"),
    "stockAdded": ("Stock added", "स्टक थपियो"),
    "stockRemoved": ("Stock removed", "स्टक हटाइयो"),
    "openingStock": ("Opening", "सुरुवाती"),
    "week": ("Week", "हप्ता"),
    "month": ("Month", "महिना"),
    "day": ("Day", "दिन"),

    # --- relative day labels in the reminder list ---------------------------
    "todayAt": ("Today {time}", "आज {time}", {"time": "String"}),
    "tomorrowAt": ("Tomorrow {time}", "भोलि {time}", {"time": "String"}),
    "yesterdayAt": ("Yesterday {time}", "हिजो {time}", {"time": "String"}),
    "noKindMatchSearch": (
        "No {kind} match your search",
        "तपाईंको खोजसँग मिल्ने {kind} छैन",
        {"kind": "String"},
    ),
    "noKindYet": ("No {kind} yet", "अहिलेसम्म {kind} छैन", {"kind": "String"}),
    "categoryReminder": ("Reminder", "सम्झना"),

    # --- ternaries and inline branch labels ----------------------------------
    # These sat in `cond ? 'X' : 'Y'` positions, which the Text(...)-shaped
    # matcher cannot reach; they are ordinary user-facing copy.
    "saved": ("Saved", "सुरक्षित भयो"),
    "productSaved": ("Product saved", "उत्पादन सुरक्षित भयो"),
    "walkInCustomer": ("Walk-in customer", "हिँडेर आएको ग्राहक"),
    "notSet": ("Not set", "सेट गरिएको छैन"),
    "nameRequired": ("Name is required", "नाम आवश्यक छ"),
    "categoryRequired": ("Category is required", "कोटी आवश्यक छ"),
    "sourceRequired": ("Source is required", "स्रोत आवश्यक छ"),
    "unpaid": ("Unpaid", "नतिरेको"),
    "noSupplier": ("No supplier", "आपूर्तिकर्ता छैन"),
    "paidInFull": ("Paid (full)", "पूरै तिरिएको"),
    "exporting": ("Exporting...", "निर्यात हुँदैछ..."),
    "saving": ("Saving...", "सुरक्षित हुँदैछ..."),
    "noLowStockProducts": (
        "No low-stock products — all good!",
        "कुनै उत्पादन स्टक सकिएको छैन — सबै ठीक छ!",
    ),
    "noProductsMatchSearch": (
        "No products match your search",
        "तपाईंको खोजसँग मिल्ने कुनै उत्पादन छैन",
    ),
    "showingUnread": ("Showing unread", "नपढेका मात्र देखाइँदै"),
    "customerKhata": ("Customer khata", "ग्राहक खाता"),
    "debit": ("Debit", "डेबिट"),
    "recordReceipt": ("Record receipt", "रसिद अभिलेख गर्नुहोस्"),
    "applyToInvoice": ("Apply to invoice", "बिजकमा लागू गर्नुहोस्"),
    "receipt": ("Receipt", "रसिद"),
    "roleViewer": ("Viewer", "दर्शक"),
    "editKind": ("Edit {kind}", "सम्पादन {kind}", {"kind": "String"}),
    "never": ("Never", "कहिल्यै छैन"),
    "syncing": ("Syncing…", "सिङ्क हुँदैछ…"),
    "moneyInOut": ("In {inAmount} · Out {outAmount}", "आम्दानी {inAmount} · खर्च {outAmount}", {"inAmount": "String", "outAmount": "String"}),
    "dueAmount": ("Due {amount}", "बाँकी {amount}", {"amount": "String"}),
    "created": ("Created", "बनाइयो"),
    "productCreated": ("Product created", "उत्पादन बनाइयो"),
    "toCollectAmount": ("To collect {amount}", "संकलन गर्नु {amount}", {"amount": "String"}),
    "toPayAmount": ("To pay {amount}", "तिर्नु {amount}", {"amount": "String"}),
    "createProduct": ("Create product", "उत्पादन बनाउनुहोस्"),
    "create": ("Create", "बनाउनुहोस्"),
    "noProductsYet": ("No products yet", "अहिलेसम्म कुनै उत्पादन छैन"),
    "noProductsYetAddFirst": (
        "No products yet — add your first product",
        "अहिलेसम्म कुनै उत्पादन छैन — पहिलो उत्पादन थप्नुहोस्",
    ),

    # --- invoice / purchase / sale line-item summaries ----------------------
    "subtotal": ("Subtotal", "उपजम्मा"),
    "total": ("Total", "जम्मा"),
    "discount": ("Discount", "छुट"),
    "rateRs": ("Rate (Rs.)", "दर (रु.)"),
    "discountRs": ("Disc (Rs.)", "छुट (रु.)"),
    "addAtLeastOneItem": ("Add at least one item", "कम्तीमा एक वस्तु थप्नुहोस्"),
    "costValue": ("Cost value", "लागत मूल्य"),
    "potentialMargin": ("Potential margin", "सम्भावित मार्जिन"),

    # --- success toasts ------------------------------------------------------
    "invoiceCreated": ("Invoice created", "बिजक बनाइयो"),
    "invoiceDeleted": ("Invoice deleted", "बिजक मेटियो"),
    "quotationCreated": ("Quotation created", "भनसुन बनाइयो"),
    "quotationDeleted": ("Quotation deleted", "भनसुन मेटियो"),
    "convertedToSaleToast": ("Converted to sale", "बिक्रीमा परिणत गरियो"),
    "saleCreated": ("Sale created", "बिक्री बनाइयो"),
    "saleReversed": ("Sale reversed", "बिक्री उल्टाइयो"),
    "saleKeptAsReversed": (
        "The sale is kept in history as reversed.",
        "बिक्री इतिहासमा उल्टाइएको रूपमा रहन्छ।",
    ),
    "creditSaleNeedsCustomer": (
        "A credit sale needs a customer",
        "उधारो बिक्रीको लागि ग्राहक आवश्यक छ",
    ),
    "purchaseCreated": ("Purchase created", "खरिद बनाइयो"),
    "purchaseReversed": ("Purchase reversed", "खरिद उल्टाइयो"),
    "purchaseKeptAsReversed": (
        "The purchase is kept in history as reversed.",
        "खरिद इतिहासमा उल्टाइएको रूपमा रहन्छ।",
    ),
    "creditPurchaseNeedsSupplier": (
        "A credit purchase needs a supplier",
        "उधारो खरिदको लागि आपूर्तिकर्ता आवश्यक छ",
    ),
    "paymentRecorded": ("Payment recorded", "भुक्तानी अभिलेख भयो"),
    "methodSaved": ("Method saved", "विधि सुरक्षित भयो"),
    "methodDeleted": ("Method deleted", "विधि मेटियो"),
    "categorySaved": ("Category saved", "कोटी सुरक्षित भयो"),
    "categoryDeleted": ("Category deleted", "कोटी मेटियो"),
    "productDeleted": ("Product deleted", "उत्पादन मेटियो"),
    "unitSaved": ("Unit saved", "एकाइ सुरक्षित भयो"),
    "unitDeleted": ("Unit deleted", "एकाइ मेटियो"),
    "settingsSaved": ("Settings saved", "सेटिङ सुरक्षित भयो"),
    "atLeastOneMethodMustRemain": (
        "At least one payment method must remain.",
        "कम्तीमा एक भुक्तानी विधि रहनुपर्छ।",
    ),
    "notAkhataBackup": (
        "This is not a Khata backup.",
        "यो खाताको ब्याकअप होइन।",
    ),

    # --- validation / empty states ------------------------------------------
    "enterNonZeroQuantity": ("Enter a non-zero quantity", "शून्य नभएको परिमाण लेख्नुहोस्"),
    "enterAmountGreaterThanZero": (
        "Enter an amount greater than zero",
        "शून्यभन्दा बढी रकम लेख्नुहोस्",
    ),
    "currentStockIs": ("Current stock: {quantity}", "हालको स्टक: {quantity}", {"quantity": "String"}),
    "balanceAfterIs": ("Bal {quantity}", "बाँकी {quantity}", {"quantity": "String"}),
    "rejectedAndFailed": ("Rejected & failed", "अस्वीकृत र असफल"),
    "conflictsNamed": ("Conflicts ({count})", "द्वन्द्व ({count})", {"count": "int"}),
    "retailValueReport": ("Retail value", "खुद्रा मूल्य"),

    # --- reports ------------------------------------------------------------
    "entries": ("Entries", "प्रविष्टिहरू"),
    "average": ("Average", "औसत"),
    "sources": ("Sources", "स्रोतहरू"),
    "revenue": ("Revenue", "आम्दानी"),
    "costOfGoodsSold": ("Cost of goods sold", "बिक्री भएका वस्तुको लागत"),
    "grossProfit": ("Gross profit", "कुल नाफा"),
    "otherIncome": ("Other income", "अन्य आय"),
    "netProfit": ("Net profit", "खुद नाफा"),
    "taxCollectedInPeriod": (
        "Tax collected in this period: ",
        "यो अवधिमा संकलित कर: ",
    ),
    "customerAdvances": ("Customer advances", "ग्राहक अग्रिम"),
    "supplierAdvances": ("Supplier advances", "आपूर्तिकर्ता अग्रिम"),
    "advancesExplain": (
        "Advances are money you already hold (customer) or have already paid (supplier).",
        "अग्रिम भन्नाले तपाईंसँग भइसकेको (ग्राहक) वा तिरिसकेको (आपूर्तिकर्ता) रकम।",
    ),
    "reportSalesBlurb": (
        "Trends, totals, top products and customers",
        "प्रवृत्ति, जम्मा, शीर्ष उत्पादन र ग्राहक",
    ),
    "reportProfitLossBlurb": (
        "Revenue, cost of goods and net profit",
        "आम्दानी, बिक्री लागत र खुद नाफा",
    ),
    "reportExpenseBlurb": (
        "Where the money went, by category",
        "पैसा कहाँ गयो, कोटी अनुसार",
    ),
    "reportIncomeBlurb": ("Other income by source", "स्रोत अनुसार अन्य आय"),
    "reportStockBlurb": (
        "Cost and retail value of stock on hand",
        "भण्डारको लागत र खुद्रा मूल्य",
    ),
    "reportReceivableBlurb": ("Who owes you and who you owe", "कसले तिर्नु छ र तपाईंले कसलाई"),
    "ledgerOwesYouHint": (
        "Amount they owe you (customer) / you paid (supplier)",
        "उनीहरूले तिर्नु पर्ने (ग्राहक) / तपाईंले तिरेको (आपूर्तिकर्ता)",
    ),
    "ledgerYouOweHint": (
        "Amount paid to you (customer) / you owe (supplier)",
        "तपाईंलाई तिरेको (ग्राहक) / तपाईंले तिर्नु पर्ने (आपूर्तिकर्ता)",
    ),

    # --- business roles -----------------------------------------------------
    "roleOwner": ("Owner", "मालिक"),
    "roleAdmin": ("Admin", "प्रशासक"),
    "roleManager": ("Manager", "प्रबन्धक"),
    "roleAccountant": ("Accountant", "लेखाकार"),

    # --- misc ---------------------------------------------------------------
    "noBusiness": ("No business", "व्यवसाय छैन"),
    "tax": ("Tax", "कर"),
    "qty": ("Qty", "परिमाण"),
    "openingBalance": ("Opening balance", "सुरुवाती बाँकी"),
    "adjustment": ("Adjustment", "समायोजन"),
    "selectPartyKind": ("Select a {kind}", "{kind} चयन गर्नुहोस्", {"kind": "String"}),
    "couldNotLoadProducts": (
        "Could not load products.\\n{error}",
        "उत्पादनहरू लोड गर्न सकिएन।\\n{error}",
        {"error": "String"},
    ),
    "lineItemsCopiedFromSale": (
        "Line items will be copied from the selected sale and its invoice will be generated.",
        "चयन गरिएको बिक्रीबाट वस्तुहरू प्रतिलिपि गरिनेछ र यसको बिजक बनाइनेछ।",
    ),
    "bsRange": ("BS: {from}  →  {to}", "वि.सं.: {from}  →  {to}", {"from": "String", "to": "String"}),

    # --- auth ---
    "signInToYourAccount": ("Sign in to your account", "आफ्नो खातामा साइन इन गर्नुहोस्"),
    "createYourAccountTitle": (
        "Create your Digital Khata account",
        "आफ्नो डिजिटल खाता खाता बनाउनुहोस्",
    ),
    "getStarted": ("Get started", "सुरु गर्नुहोस्"),
    "fullNamePlaceholder": ("Full name", "पूरा नाम"),
    "phoneNumberPlaceholder": ("Phone number", "फोन नम्बर"),
    "phoneOptional": ("Phone Number (optional)", "फोन नम्बर (वैकल्पिक)"),
    "pan": ("PAN", "स्थायी लेखा नम्बर"),
    "address": ("Address", "ठेगाना"),

    # --- business ---
    "businessNameRequired": ("Business name *", "व्यवसायको नाम *"),
    "createNewBusiness": ("Create new business", "नयाँ व्यवसाय बनाउनुहोस्"),
    "businesses": ("Businesses", "व्यवसायहरू"),
    "couldNotCreateBusiness": (
        "Could not create business: {error}",
        "व्यवसाय बनाउन सकिएन: {error}",
        {"error": "String"},
    ),
    "couldNotSwitchBusiness": (
        "Could not switch business: {error}",
        "व्यवसाय परिवर्तन गर्न सकिएन: {error}",
        {"error": "String"},
    ),
    "couldNotUpdateProfile": (
        "Could not update profile: {error}",
        "प्रोफाइल अद्यावधिक गर्न सकिएन: {error}",
        {"error": "String"},
    ),
    "profileUpdated": ("Profile updated", "प्रोफाइल अद्यावधिक भयो"),
    "changeRoleFor": ("Change role — {name}", "भूमिका परिवर्तन — {name}", {"name": "String"}),
    "couldNotChangeRole": (
        "Could not change role: {error}",
        "भूमिका परिवर्तन गर्न सकिएन: {error}",
        {"error": "String"},
    ),
    "removeMember": ("Remove {name}?", "{name} हटाउने?", {"name": "String"}),
    "removeMemberWarning": (
        "They will lose access to this business.",
        "उनीहरूले यो व्यवसायमा पहुँच गुमाउनेछन्।",
    ),
    "couldNotRemoveMember": (
        "Could not remove member: {error}",
        "सदस्य हटाउन सकिएन: {error}",
        {"error": "String"},
    ),
    "inviteFailed": ("Invite failed: {error}", "निमन्त्रणा असफल: {error}", {"error": "String"}),
    "noStaffMembersYet": ("No staff members yet", "अहिलेसम्म कुनै कर्मचारी छैन"),

    # --- products ---
    "productNameRequired": ("Product name *", "उत्पादनको नाम *"),
    "searchNameSkuBarcode": (
        "Search name, SKU or barcode",
        "नाम, SKU वा बारकोड खोज्नुहोस्",
    ),
    "noProductsFound": ("No products found", "कुनै उत्पादन भेटिएन"),
    "costPriceRs": ("Cost price (Rs.)", "लागत मूल्य (रु.)"),
    "sellingPriceRsRequired": ("Selling price (Rs.) *", "बिक्री मूल्य (रु.) *"),
    "wholesalePriceRs": ("Wholesale price (Rs.)", "थोक मूल्य (रु.)"),
    "taxRatePercent": ("Tax rate (%)", "कर दर (%)"),
    "openingStockQuantity": ("Opening stock quantity", "सुरुको स्टक मात्रा"),
    "minimumQuantityHint": (
        "minimum quantity (0 = no alert)",
        "न्यूनतम मात्रा (० = चेतावनी छैन)",
    ),
    "inactiveProductsNote": (
        "Inactive products stay but are hidden from sales",
        "निष्क्रिय उत्पादनहरू रहन्छन् तर बिक्रीबाट लुकाइन्छ",
    ),
    "deleteProductQuestion": ("Delete product?", "उत्पादन मेट्ने?"),
    "deleteProductWarning": (
        "The product will be hidden from the catalog. Stock history is kept.",
        "उत्पादन सूचीबाट लुकाइनेछ। स्टक इतिहास रहनेछ।",
    ),
    "loadingProduct": ("Loading product…", "उत्पादन लोड हुँदैछ…"),
    "couldNotLoadProduct": (
        "Could not load product: {error}",
        "उत्पादन लोड गर्न सकिएन: {error}",
        {"error": "String"},
    ),
    "byCategory": ("By category", "श्रेणी अनुसार"),
    "expensesByCategory": ("Expenses by category", "श्रेणी अनुसार खर्च"),
    "categoriesNoCategories": ("No categories yet", "अहिलेसम्म कुनै श्रेणी छैन"),
    "noCategory": ("No category", "श्रेणी छैन"),
    "deleteCategoryQuestion": ("Delete category?", "श्रेणी मेट्ने?"),
    "categoryDeleteNote": (
        "Products in this category will keep working without a category.",
        "यो श्रेणीका उत्पादनहरू श्रेणी बिना पनि काम गर्नेछन्।",
    ),
    "addCategory": ("Add category", "श्रेणी थप्नुहोस्"),
    "categoryRequired": ("Category *", "श्रेणी *"),
    "noUnit": ("No unit", "एकाइ छैन"),
    "unitNameHint": ("Name * (e.g. Piece)", "नाम * (जस्तै पिस)"),
    "unitShortHint": ("Short name * (e.g. pc)", "छोटो नाम * (जस्तै pc)"),
    "unitsNoUnits": ("No units yet", "अहिलेसम्म कुनै एकाइ छैन"),
    "addUnit": ("Add unit", "एकाइ थप्नुहोस्"),
    "deleteUnitQuestion": ("Delete unit?", "एकाइ मेट्ने?"),
    "unitDeleteNote": (
        "Products using this unit will keep working without a unit.",
        "यो एकाइ प्रयोग गर्ने उत्पादनहरू एकाइ बिना पनि काम गर्नेछन्।",
    ),

    # --- inventory ---
    "adjustStock": ("Adjust stock", "स्टक समायोजन"),
    "movementHistory": ("Movement history", "चलन इतिहास"),
    "noStockMovementsYet": ("No stock movements yet", "अहिलेसम्म कुनै स्टक चलन छैन"),
    "customQuantityHint": (
        "Custom quantity (+ in / - out)",
        "अनुकूल मात्रा (+ भित्र / - बाहिर)",
    ),
    "quantityExample": ("e.g. 2.5 or -3", "जस्तै २.५ वा -३"),
    "reasonExample": ("e.g. stock count, damage", "जस्तै स्टक गणना, क्षति"),
    "stockValuation": ("Stock valuation", "स्टक मूल्यांकन"),
    "currentStockIs": (
        "Current stock: {quantity}",
        "हालको स्टक: {quantity}",
        {"quantity": "String"},
    ),
    "balanceIs": ("Bal {quantity}", "मौज्दात {quantity}", {"quantity": "String"}),

    # --- parties ---
    "nameRequired": ("Name *", "नाम *"),
    "partyNameExample": ("Name * (e.g. Piece)", "नाम * (जस्तै पिस)"),
    "creditLimitRs": ("Credit limit (Rs.)", "उधारो सीमा (रु.)"),
    "openingBalanceRs": ("Opening balance (Rs.)", "सुरुको मौज्दात (रु.)"),
    "walkInNone": ("Walk-in / none", "हिँड्ने ग्राहक / कोही नहीं"),
    "deletePartyQuestion": ("Delete {kind}?", "{kind} मेट्ने?", {"kind": "String"}),
    "partyDeleteNote": (
        "The party will be hidden from lists. Khata history is kept.",
        "पक्ष सूचीबाट लुकाइनेछ। खाता इतिहास रहनेछ।",
    ),
    "khataHistoryKept": ("Khata history is kept.", "खाता इतिहास रहनेछ।"),

    # --- documents (sales / purchases / invoices / quotations) ---
    "createSale": ("Create sale", "बिक्री बनाउनुहोस्"),
    "createPurchase": ("Create purchase", "खरिद बनाउनुहोस्"),
    "createInvoice": ("Create invoice", "बिजक बनाउनुहोस्"),
    "createQuotation": ("Create quotation", "कोटेशन बनाउनुहोस्"),
    "noItemsYetAddProduct": (
        "No items yet — add a product",
        "अहिलेसम्म कुनै वस्तु छैन — उत्पादन थप्नुहोस्",
    ),
    "addItem": ("Add item", "वस्तु थप्नुहोस्"),
    "addFreeText": ("Add free text", "स्वतन्त्र पाठ थप्नुहोस्"),
    "items": ("Items", "वस्तुहरू"),
    "itemsCount": ("Items ({count})", "वस्तुहरू ({count})", {"count": "int"}),
    "extraDiscountRs": ("Extra discount (Rs.)", "अतिरिक्त छुट (रु.)"),
    "paidNowRs": ("Paid now (Rs.)", "अहिले तिरिएको (रु.)"),
    "paidAmountRs": ("Paid amount (Rs.)", "तिरिएको रकम (रु.)"),
    "amountRsRequired": ("Amount (Rs.) *", "रकम (रु.) *"),
    "lineTotalIs": (
        "Line total: {total}",
        "हरफ जम्मा: {total}",
        {"total": "String"},
    ),
    "invoiceNumberLabel": (
        "Invoice {number}",
        "बिजक {number}",
        {"number": "String"},
    ),
    "quotationNumberLabel": (
        "Quotation {number}",
        "कोटेशन {number}",
        {"number": "String"},
    ),
    "issuedOn": ("Issued {date}", "जारी {date}", {"date": "String"}),
    "dueOn": ("Due {date}", "म्याद {date}", {"date": "String"}),
    "validUntilOn": ("Valid until {date}", "मान्य मिति {date}", {"date": "String"}),
    "convertedToSale": (
        "Converted to sale #{id}",
        "बिक्री #{id} मा रूपान्तरित",
        {"id": "int"},
    ),
    "fromSale": (
        "From sale {number}",
        "बिक्री {number} बाट",
        {"number": "String"},
    ),
    "lineItemsCopiedNote": (
        "Line items will be copied from the selected sale and its prices kept.",
        "चयन गरिएको बिक्रीबाट हरफहरू र तिनका मूल्यहरू प्रतिलिपि गरिनेछ।",
    ),
    "noneBuildManually": ("None (build manually)", "कुनै पनि होइन (म्यानुअल बनाउनुहोस्)"),
    "notesOptional": ("Notes (optional)", "टिप्पणी (वैकल्पिक)"),
    "termsLabel": ("Terms: {terms}", "सर्तहरू: {terms}", {"terms": "String"}),
    "notesLabel": ("Notes: {notes}", "टिप्पणी: {notes}", {"notes": "String"}),
    "sharePdf": ("Share PDF", "PDF साझा गर्नुहोस्"),
    "exportCsv": ("Export CSV", "CSV निर्यात गर्नुहोस्"),
    "deleteSaleQuestion": ("Delete sale?", "बिक्री मेट्ने?"),
    "deletePurchaseQuestion": ("Delete purchase?", "खरिद मेट्ने?"),
    "deleteInvoiceQuestion": ("Delete invoice?", "बिजक मेट्ने?"),
    "deleteQuotationQuestion": ("Delete quotation?", "कोटेशन मेट्ने?"),
    "deleteExpenseQuestion": ("Delete expense?", "खर्च मेट्ने?"),
    "deleteIncomeQuestion": ("Delete income?", "आय मेट्ने?"),
    "deleteMethodQuestion": ("Delete method?", "विधि मेट्ने?"),
    "saleDeleteNote": (
        "Stock will be restored and the customer khata reversed.",
        "स्टक पुनर्स्थापित हुनेछ र ग्राहक खाता उल्टाइनेछ।",
    ),
    "purchaseDeleteNote": (
        "Stock will be reduced back and the supplier khata reversed.",
        "स्टक घटाइनेछ र आपूर्तिकर्ता खाता उल्टाइनेछ।",
    ),
    "expenseDeleteNote": (
        "This expense will be permanently removed.",
        "यो खर्च स्थायी रूपमा हटाइनेछ।",
    ),
    "incomeDeleteNote": (
        "This income record will be permanently removed.",
        "यो आय रेकर्ड स्थायी रूपमा हटाइनेछ।",
    ),
    "invoiceDeleteNote": (
        "This invoice will be permanently removed.",
        "यो बिजक स्थायी रूपमा हटाइनेछ।",
    ),
    "quotationDeleteNote": (
        "This quotation will be permanently removed.",
        "यो कोटेशन स्थायी रूपमा हटाइनेछ।",
    ),
    "searchInvoiceOrCustomer": (
        "Search invoice or customer",
        "बिजक वा ग्राहक खोज्नुहोस्",
    ),
    "searchBillOrSupplier": ("Search bill or supplier", "बिल वा आपूर्तिकर्ता खोज्नुहोस्"),
    "searchQuotationOrCustomer": (
        "Search quotation or customer",
        "कोटेशन वा ग्राहक खोज्नुहोस्",
    ),
    "searchPartyOrReference": (
        "Search party or reference",
        "पक्ष वा सन्दर्भ खोज्नुहोस्",
    ),

    # --- payments ---
    "paymentMethod": ("Payment method", "भुक्तानी विधि"),
    "addMethod": ("Add method", "विधि थप्नुहोस्"),
    "noPaymentMethodsYet": ("No payment methods yet", "अहिलेसम्म कुनै भुक्तानी विधि छैन"),
    "setAsDefault": ("Set as default", "पूर्वनिर्धारित बनाउनुहोस्"),
    "methodChangeNote": (
        "Payments already recorded with this method keep working.",
        "यो विधिबाट पहिले नै रेकर्ड भएका भुक्तानीहरू काम गरिरहन्छन्।",
    ),
    "advanceIs": ("Advance {amount}", "अग्रिम {amount}", {"amount": "String"}),
    "paid": ("Paid", "तिरिएको"),
    "dueToCustomerKhata": (
        "Due {amount} → customer khata",
        "बाँकी {amount} → ग्राहक खाता",
        {"amount": "String"},
    ),
    "dueToSupplierKhata": (
        "Due {amount} → supplier khata",
        "बाँकी {amount} → आपूर्तिकर्ता खाता",
        {"amount": "String"},
    ),
    "advancesAreMoney": (
        "Advances are money you already hold, so they are applied first.",
        "अग्रिम भनेको तपाईंसँग पहिले नै रहेको रकम हो, त्यसैले पहिले लागू गरिन्छ।",
    ),
    "advancesLabel": ("Advances: {list}", "अग्रिमहरू: {list}", {"list": "String"}),

    # --- expenses / income ---
    "addExpense": ("Add expense", "खर्च थप्नुहोस्"),
    "addIncome": ("Add income", "आय थप्नुहोस्"),
    "addProductButton": ("Add product", "उत्पादन थप्नुहोस्"),
    "addReminderButton": ("Add reminder", "सम्झना थप्नुहोस्"),

    # --- reports ---
    "receivablesAndPayables": ("Receivables & payables", "प्राप्य र भुक्तानीय"),
    "receivablesCount": (
        "Receivables · {count}",
        "प्राप्य · {count}",
        {"count": "int"},
    ),
    "payablesCount": ("Payables · {count}", "भुक्तानीय · {count}", {"count": "int"}),
    "profitAndLoss": ("Profit & loss", "नाफा र घाटा"),
    "salesReportTitle": ("Sales report", "बिक्री प्रतिवेदन"),
    "revenueExcludesVat": ("Revenue excludes VAT.", "आम्दानीमा भ्याट समावेश छैन।"),
    "salesTrendLast14": ("Sales trend · last 14 days", "बिक्री प्रवृत्ति · अन्तिम १४ दिन"),
    "salesTrendScope": (
        "Sales trend · {scope}",
        "बिक्री प्रवृत्ति · {scope}",
        {"scope": "String"},
    ),
    "topProducts": ("Top products", "प्रमुख उत्पादनहरू"),
    "topCustomers": ("Top customers", "प्रमुख ग्राहकहरू"),
    "bySource": ("By source", "स्रोत अनुसार"),
    "incomeTrend": ("Income trend", "आय प्रवृत्ति"),
    "lastCycle": ("Last cycle", "अघिल्लो चक्र"),
    "noDataYet": ("No data yet", "अहिलेसम्म कुनै डाटा छैन"),
    "couldNotLoad": (
        "Could not load: {error}",
        "लोड गर्न सकिएन: {error}",
        {"error": "String"},
    ),
    "couldNotLoadSummary": ("Could not load summary", "सारांश लोड गर्न सकिएन"),
    "dashboardUnavailable": ("Dashboard unavailable", "ड्यासबोर्ड उपलब्ध छैन"),
    "productsCount": (
        "{count} product(s)",
        "{count} उत्पादन",
        {"count": "int"},
    ),
    "unitsDocsCount": (
        "{quantity} units · {count} docs",
        "{quantity} एकाइ · {count} बिजक",
        {"quantity": "String", "count": "int"},
    ),
    "quantityTimesPrice": (
        "{quantity} × {price}",
        "{quantity} × {price}",
        {"quantity": "String", "price": "String"},
    ),
    "lowStockNote": ("{name} low on stock", "{name} स्टक कम", {"name": "String"}),

    # --- notifications / reminders / backup / sync ---
    "syncTitle": ("Sync", "सिंक"),
    "syncStatusTitle": ("Sync status", "सिंक स्थिति"),
    "lastSyncLabel": ("Last sync", "अन्तिम सिंक"),
    "pendingChangesCount": ("Pending changes", "पर्खाइमा रहेका परिवर्तन"),
    "syncFailed": ("Sync failed: {error}", "सिंक असफल: {error}", {"error": "String"}),
    "operationFailed": (
        "{operation} failed",
        "{operation} असफल भयो",
        {"operation": "String"},
    ),
    "conflicts": ("conflicts", "द्वन्द्वहरू"),
    "noConflicts": ("No conflicts", "कुनै द्वन्द्व छैन"),
    "entityRef": ("{type} #{id}", "{type} #{id}", {"type": "String", "id": "int"}),
    "serverChanged": ("server changed: ", "सर्भर परिवर्तन: "),
    "serverVersion": (
        "server version: {json}",
        "सर्भर संस्करण: {json}",
        {"json": "String"},
    ),
    "operationDetail": (
        "operation: {operation}",
        "सञ्चालन: {operation}",
        {"operation": "String"},
    ),
    "pushed": ("pushed", "पठाइयो"),
    "pulled": ("pulled", "तानियो"),
    "rejected": ("rejected", "अस्वीकृत"),
    "rejectedWithError": (
        "rejected: {error}",
        "अस्वीकृत: {error}",
        {"error": "String"},
    ),
    "backupSubject": ("Khata backup", "खाता ब्याकअप"),
    "backupShareText": (
        "Khata backup exported from this device.",
        "यो यन्त्रबाट खाता ब्याकअप निर्यात गरियो।",
    ),
    "recordsAddedCount": (
        "{count} record(s) added",
        "{count} रेकर्ड थपियो",
        {"count": "int"},
    ),
    "alreadyPresentCount": (
        "{count} already present, left alone",
        "{count} पहिले नै थियो, छाडियो",
        {"count": "int"},
    ),
    "addedCount": ("{count} added", "{count} थपियो", {"count": "int"}),
    "addedKeptCount": (
        "{count} added, {kept} kept",
        "{count} थपियो, {kept} राखियो",
        {"count": "int", "kept": "int"},
    ),
    "restoreConfirmBody": (
        "Records that already exist in this business will be skipped. "
        "Nothing currently here is modified or deleted.",
        "यो व्यवसायमा पहिले नै रहेका रेकर्डहरू छाडिनेछन्। "
        "यहाँ हाल रहेका कुनै पनि परिमार्जन वा मेटिने छैनन्।",
    ),
    "reminderRepeatNote": (
        "A repeating reminder reschedules itself after firing.",
        "दोहोरिने सम्झना आफैं पुनः तालिका बनाउँछ।",
    ),

    # --- profile ---
    "profileLabel": ("Profile", "प्रोफाइल"),
    "language": ("Language", "भाषा"),
    "languageEnglish": ("English", "अंग्रेजी"),
    "languageNepali": ("नेपाली", "नेपाली"),
    "calendarLabel": ("Calendar", "पात्रो"),
    "generalSection": ("General", "सामान्य"),

    # --- misc / form hints ---
    "dateLabel": ("Date", "मिति"),
    "descriptionLabel": ("Description", "विवरण"),
    "fromLabel": ("From", "देखि"),
    "toLabel": ("To", "सम्म"),
    "titleRequired": ("Title *", "शीर्षक *"),
    "sourceRequired": ("Source *", "स्रोत *"),
    "taxExample": ("e.g. 13", "जस्तै १३"),
    "amountExample": ("e.g. 20.00", "जस्तै २०.००"),
    "quantityExample16": ("e.g. 16.00", "जस्तै १६.००"),
    "rateExample": ("e.g. 25", "जस्तै २५"),
    "addKind": (
        "Add {kind}",
        "{kind} थप्नुहोस्",
        {"kind": "String"},
    ),
    "editKind": (
        "Edit {kind}",
        "{kind} सम्पादन गर्नुहोस्",
        {"kind": "String"},
    ),
    "newKind": (
        "New {kind}",
        "नयाँ {kind}",
        {"kind": "String"},
    ),
    "plusOne": ("+1", "+१"),
    "plusTen": ("+10", "+१०"),
    "minusOne": ("-1", "-१"),
    "minusTen": ("-10", "-१०"),
    "phonePrefixHint": ("+977 98XXXXXXXX", "+९७७ ९८XXXXXXXX"),
    "rankLabel": ("#", "#"),
    "edit": ("Edit", "सम्पादन गर्नुहोस्"),
    "convert": ("Convert", "रूपान्तरण गर्नुहोस्"),
    "exportTitle": ("Export", "निर्यात"),
    "restoreTitle": ("Restore", "पुनर्स्थापना"),
    "expenseTrend": ("Expense trend", "खर्च प्रवृत्ति"),
    "opening": ("Opening", "सुरुको"),
    "filterByCategory": ("Filter by category", "श्रेणी अनुसार फिल्टर"),
    "phoneLabel": ("Phone", "फोन"),
    "emailMustHaveAccount": (
        "Email (must have an account)",
        "इमेल (खाता हुनु आवश्यक छ)",
    ),
    "advancesExplainer": (
        "Advances are money you already hold (customer) or have already paid "
        "(supplier), so they are applied before new payments.",
        "अग्रिम भनेको तपाईंसँग पहिले नै रहेको (ग्राहक) वा पहिले नै तिरेको "
        "(आपूर्तिकर्ता) रकम हो, त्यसैले नयाँ भुक्तानीअघि लागू गरिन्छ।",
    ),
    "backupExportExplainerFull": (
        "Saves every product, party, sale, purchase, expense, income, payment, "
        "invoice and quotation in the active business. Soft-deleted records are "
        "kept, so history survives.",
        "सक्रिय व्यवसायका सबै उत्पादन, पक्ष, बिक्री, खरिद, खर्च, आय, भुक्तानी, "
        "बिजक र कोटेशन सुरक्षित गर्छ। मेटिएका रेकर्डहरू पनि राखिन्छन्, त्यसैले "
        "इतिहास जोगिन्छ।",
    ),
    "backupRestoreExplainerFull": (
        "Restoring merges a backup into this business. Records that already "
        "exist are skipped — nothing is ever overwritten, because a rewritten "
        "sale or payment would leave the khata ledger disagreeing with itself.",
        "पुनर्स्थापनाले ब्याकअपलाई यो व्यवसायमा गाभ्छ। पहिले नै रहेका रेकर्डहरू "
        "छाडिन्छन् — कुनै पनि अधिलेखन गरिँदैन, किनकि पुनर्लेखन गरिएको बिक्री वा "
        "भुक्तानीले खाता बहीखातालाई आफैंसँग बाझ्ने बनाउँछ।",
    ),
    "backupNotIncludedExplainer": (
        "The khata ledger entries and stock movements are derived from the "
        "documents above, so they are rebuilt by replaying those operations "
        "rather than copied. A restore therefore brings back your records, not "
        "the cached totals.",
        "खाता बहीखाताका प्रविष्टि र स्टक चलनहरू माथिका कागजातबाट व्युत्पन्न हुन्छन्, "
        "त्यसैले तिनीहरू प्रतिलिपि नगरी ती सञ्चालनहरू पुनः खेलेर पुनर्निर्माण "
        "गरिन्छ। त्यसैले पुनर्स्थापनाले तपाईंका रेकर्डहरू फर्काउँछ, क्यास गरिएका "
        "जम्मा होइन।",
    ),
    "restoreConfirmBodyFull": (
        "Records that already exist in this business will be skipped. Nothing "
        "currently here is modified or deleted.",
        "यो व्यवसायमा पहिले नै रहेका रेकर्डहरू छाडिनेछन्। यहाँ हाल रहेका कुनै पनि "
        "परिमार्जन वा मेटिने छैनन्।",
    ),
    "methodChangeNoteFull": (
        "Payments already recorded with this method keep working. Renaming the "
        "method does not rewrite history.",
        "यो विधिबाट पहिले नै रेकर्ड भएका भुक्तानीहरू काम गरिरहन्छन्। विधिको नाम "
        "परिवर्तनले इतिहास पुनर्लेखन गर्दैन।",
    ),
    "saleDeleteNoteFull": (
        "Stock will be restored and the customer khata reversed.",
        "स्टक पुनर्स्थापित हुनेछ र ग्राहक खाता उल्टाइनेछ।",
    ),
    "purchaseDeleteNoteFull": (
        "Stock will be reduced back and the supplier khata reversed.",
        "स्टक घटाइनेछ र आपूर्तिकर्ता खाता उल्टाइनेछ।",
    ),
    "lineItemsCopiedNoteFull": (
        "Line items will be copied from the selected sale and its prices kept.",
        "चयन गरिएको बिक्रीबाट हरफहरू र तिनका मूल्यहरू प्रतिलिपि गरिनेछ।",
    ),
    "notificationsInAppNoteFull": (
        "In-app notifications are always recorded. These switches control push "
        "delivery only.",
        "इन-एप सूचनाहरू सधैं रेकर्ड हुन्छन्। यी स्विचहरूले पुश डेलिभरी मात्र "
        "नियन्त्रण गर्छन्।",
    ),
    "unitNameShort": (
        "{name} ({short})",
        "{name} ({short})",
        {"name": "String", "short": "String"},
    ),
    "retailValue": (
        "retail {amount}",
        "खुद्रा {amount}",
        {"amount": "String"},
    ),
    "advanceAmount": (
        "Advance {amount}",
        "अग्रिम {amount}",
        {"amount": "String"},
    ),
    "quantityWithUnit": (
        "{quantity}{unit}",
        "{quantity}{unit}",
        {"quantity": "String", "unit": "String"},
    ),
    "productPricePair": (
        "{price}  •  ",
        "{price}  •  ",
        {"price": "String"},
    ),
    "saleCustomerLine": (
        "{number} — {customer}",
        "{number} — {customer}",
        {"number": "String", "customer": "String"},
    ),
    "lineTotalAmount": (
        "Line total: {amount}",
        "हरफ जम्मा: {amount}",
        {"amount": "String"},
    ),
    "conflictsCount": (
        "{count} conflicts",
        "{count} द्वन्द्व",
        {"count": "int"},
    ),
}


def main() -> int:
    for name in ("app_en.arb", "app_ne.arb"):
        path = L10N / name
        data = json.loads(
            path.read_text(encoding="utf-8"), object_pairs_hook=collections.OrderedDict
        )
        is_en = name == "app_en.arb"
        added = 0
        for key, spec in NEW.items():
            value = spec[0] if is_en else spec[1]
            if key not in data:
                data[key] = value
                added += 1
            if len(spec) > 2 and f"@{key}" not in data:
                data[f"@{key}"] = collections.OrderedDict(
                    [
                        (
                            "placeholders",
                            collections.OrderedDict(
                                (ph, collections.OrderedDict([("type", t)]))
                                for ph, t in spec[2].items()
                            ),
                        )
                    ]
                )
        path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        keys = [k for k in data if not k.startswith("@")]
        print(f"{name}: +{added} new, {len(keys)} keys total")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

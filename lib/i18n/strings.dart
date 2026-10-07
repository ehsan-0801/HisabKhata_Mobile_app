// All UI text, Bangla (default) and English — mirrors the web app's
// src/i18n/messages.ts. English loanwords are transliterated; digits stay 0–9.

class S {
  const S(this.bn);
  final bool bn;

  String t(String en, String bnText) => bn ? bnText : en;

  // ---- common
  String get appName => 'HisabKhata';
  String get save => t('Save', 'সেভ করুন');
  String get saving => t('Saving…', 'সেভ হচ্ছে…');
  String get cancel => t('Cancel', 'বাতিল');
  String get add => t('Add', 'যোগ করুন');
  String get edit => t('Edit', 'এডিট');
  String get delete => t('Delete', 'ডিলিট');
  String get yesDelete => t('Yes, delete', 'হ্যাঁ, ডিলিট করুন');
  String get keep => t('Keep', 'থাক');
  String get rename => t('Rename', 'নাম বদলান');
  String get retry => t('Try again', 'আবার চেষ্টা করুন');
  String get total => t('Total', 'মোট');
  String get amount => t('Amount', 'টাকা');
  String get date => t('Date', 'তারিখ');
  String get name => t('Name', 'নাম');
  String get nameBn => t('Bangla name', 'বাংলা নাম');
  String get optional => t('optional', 'ঐচ্ছিক');
  String get note => t('Note', 'নোট');
  String get today => t('Today', 'আজ');
  String get somethingWrong => t('Something went wrong. Please try again.', 'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।');
  String get loadTitle => t('Couldn’t load this page.', 'পেজটি লোড করা যায়নি।');
  String get loadHint => t('Check the internet connection and try again.', 'ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন।');
  String get offline => t('No internet connection.', 'ইন্টারনেট সংযোগ নেই।');
  String get readOnly => t('View only — you can’t change anything in this mess.', 'শুধু দেখার অনুমতি — এই মেসে কিছু বদলাতে পারবেন না।');
  String bazars(int n) => bn ? '$nটি বাজার' : '$n ${n == 1 ? 'bazar' : 'bazars'}';
  String membersCount(int n) => bn ? '$n জন মেম্বার' : '$n ${n == 1 ? 'member' : 'members'}';

  // ---- language & theme
  String get switchLang => t('বাংলা', 'EN');
  String get switchLangLabel => t('বাংলায় দেখুন (Switch to Bangla)', 'Switch to English (ইংরেজিতে দেখুন)');
  String get language => t('Language', 'ভাষা');
  String get theme => t('Theme', 'থিম');
  String get light => t('Light', 'লাইট');
  String get dark => t('Dark', 'ডার্ক');
  String get system => t('System', 'সিস্টেম');

  // ---- navigation
  String get monthly => t('Monthly', 'মাসিক');
  String get members => t('Members', 'মেম্বার');
  String get bills => t('Bills', 'বিল');
  String get items => t('Food items', 'খাবারের আইটেম');
  String get itemsShort => t('Items', 'আইটেম');
  String get settings => t('Settings', 'সেটিংস');
  String get signOut => t('Sign out', 'লগআউট');

  // ---- auth
  String get signIn => t('Sign in', 'লগইন');
  String get signingIn => t('Signing in…', 'লগইন হচ্ছে…');
  String get signInTitle => t('Sign in to HisabKhata', 'HisabKhata-য় লগইন');
  String get signInIntro => t('Sign in to keep track of the mess’s bazar, meals and bills', 'মেসের বাজার, মিল আর বিলের হিসাব রাখতে লগইন করুন');
  String get identifier => t('Username or email', 'ইউজারনেম বা ইমেইল');
  String get username => t('Username', 'ইউজারনেম');
  String get email => t('Email', 'ইমেইল');
  String get password => t('Password', 'পাসওয়ার্ড');
  String get showPassword => t('Show password', 'পাসওয়ার্ড দেখুন');
  String get hidePassword => t('Hide password', 'পাসওয়ার্ড লুকান');
  String tooMany(int s) => bn ? 'অনেকবার ভুল হয়েছে। $s সেকেন্ড পর আবার চেষ্টা করুন।' : 'Too many tries. Try again in $s seconds.';
  String get noMessTitle => t('No mess yet', 'এখনো কোনো মেস নেই');
  String get noMessIntro => t(
      'This account isn’t part of any mess. Super admins manage messes from the web admin panel.',
      'এই অ্যাকাউন্ট কোনো মেসে নেই। সুপার অ্যাডমিন ওয়েবের অ্যাডমিন প্যানেল থেকে মেস দেখেন।');
  String get openWeb => t('Open the web panel', 'ওয়েব প্যানেল খুলুন');

  // ---- month
  String get thisMonth => t('This month', 'এই মাস');
  String get previousMonth => t('Previous month', 'আগের মাস');
  String get nextMonth => t('Next month', 'পরের মাস');
  String get tabExpense => t('Expense', 'খরচ');
  String get tabMeal => t('Meal', 'মিল');
  String get tabRent => t('Rent', 'ভাড়া');
  String get totalBazar => t('Total bazar', 'মোট বাজার');
  String get totalMeals => t('Total meals', 'মোট মিল');
  String get mealRate => t('Meal rate', 'মিল রেট');
  String perMeal(String rate) => bn ? '$rate / মিল' : '$rate / meal';

  // ---- expense
  String get perPerson => t('Bazar per person', 'কে কত বাজার করেছে');
  String inTotal(String total, int n) => bn ? 'মোট $total · $nটি বাজার' : '$total in total · ${bazars(n)}';
  String get noBazarYet => t('No bazar yet', 'এখনো বাজার নেই');
  String get noItems => t('Bazar (no items written)', 'বাজার (আইটেম লেখা নেই)');
  String get expenseNoMembers => t('No members this month', 'এই মাসে কোনো মেম্বার নেই');
  String get expenseNoMembersHint => t('Add members on the Members page to record bazar.', 'বাজার লিখতে মেম্বার পেজে মেম্বার যোগ করুন।');
  String addFor(String name) => bn ? '$name-এর বাজার যোগ করুন' : 'Add bazar for $name';
  String editFor(String name) => bn ? '$name-এর বাজার এডিট' : 'Edit $name’s bazar';
  String added(String name) => bn ? '$name-এর বাজার যোগ হয়েছে' : 'Bazar added for $name';
  String get bazarUpdated => t('Bazar updated', 'বাজার আপডেট হয়েছে');
  String get bazarDeleted => t('Bazar deleted', 'বাজার ডিলিট হয়েছে');
  String get deleteBazarConfirm => t('Delete this bazar? The meal rate will be recalculated.', 'এই বাজারটি ডিলিট করবেন? মিল রেট আবার হিসাব হবে।');
  String get itemPlaceholder => t('Type an item, e.g. Rice', 'আইটেম লিখুন, যেমন চাল');
  String get itemsLabel => t('Items', 'আইটেম');
  String get itemsHint => t('Optional — you can record just the total.', 'ঐচ্ছিক — শুধু মোট টাকাও লিখতে পারেন।');
  String addNew(String t) => bn ? '“$t” যোগ করুন' : 'Add “$t”';
  String get member => t('Member', 'মেম্বার');
  String get deletedMember => t('Deleted member', 'ডিলিট করা মেম্বার');

  // ---- meal
  String get mealsSaved => t('All saved', 'সব সেভ হয়েছে');
  String get mealsNotSaved => t('Some meals weren’t saved.', 'কিছু মিল সেভ হয়নি।');
  String get mealSheet => t('Meal sheet', 'মিলের শিট');
  String get dayEntry => t('Meals of the day', 'দিনের মিল');
  String get prevDay => t('Previous day', 'আগের দিন');
  String get nextDay => t('Next day', 'পরের দিন');
  String get notMemberShort => t('Not a member that day', 'ওই দিন মেম্বার ছিল না');
  String get totalTypedShort => t('Monthly total typed in', 'মাসের মোট সরাসরি লেখা');
  String get dayTotal => t('Day total', 'ওই দিনের মোট');
  String get monthTotal => t('Monthly total', 'মাসের মোট');
  String deletedMeals(String n) => bn ? 'ডিলিট করা মেম্বারদের $nটি সহ' : 'including $n of deleted members';
  String get typedTotalHelp => t(
      'Type a member’s monthly total to use it instead of the sum of their days. Clear it to go back to the sum.',
      'দিনে দিনে না লিখে মেম্বারের মাসের মোট মিল সরাসরি লিখতে পারেন; মুছে দিলে আবার দিনগুলোর যোগফল দেখাবে।');
  String totalFor(String name) => bn ? '$name — মাসের মোট' : '$name — monthly total';
  String get clearTotal => t('Clear (use the sum)', 'মুছুন (যোগফল ধরুন)');
  String get badDay => t('Enter a number like 1, 2 or 1.5 (at most 20).', 'সংখ্যা লিখুন, যেমন 1, 2 বা 1.5 (সর্বোচ্চ 20)।');
  String get badTotal => t('Enter the monthly total, like 62 or 58.5 (at most 999).', 'মাসের মোট লিখুন, যেমন 62 বা 58.5 (সর্বোচ্চ 999)।');
  String get mealNoMembers => t('No members this month. Add members on the Members page to record meals.', 'এই মাসে কোনো মেম্বার নেই। মিল লিখতে মেম্বার পেজে মেম্বার যোগ করুন।');
  String daysRange(int a, int b) => bn ? '$a–$b তারিখ' : 'Days $a–$b';

  // ---- rent (same wording as the web's rent section)
  String bazarOf(String m) => bn ? 'বাজার · $m' : 'Bazar · $m';
  String mealsOf(String m) => bn ? 'মিল · $m' : 'Meals · $m';
  String mealRateOf(String m) => bn ? 'মিল রেট · $m' : 'Meal rate · $m';
  String billsOf(String m) => bn ? 'বিল · $m' : 'Bills · $m';
  String settlementTitle(String m) => bn ? 'হিসাব — $m' : 'Settlement — $m';
  /// Followed by the [membersPage] link and a full stop.
  String settlementIntro(String mealMonth, String month, bool shared) => bn
      ? '$mealMonth-এর মিল খরচ (মিল × মিল রেট) − $mealMonth-এ করা বাজার, সাথে $month-এর নিজের বিল${shared ? ' ও সবার বিলের ভাগ' : ''}। নিজের বিলের টাকা ঠিক করা হয় '
      : '$mealMonth’s meal cost (meals × meal rate) − bazar paid in $mealMonth, plus $month’s personal bills${shared ? ' and shared-bill share' : ''}. Personal bill amounts are set on the ';
  String get membersPage => t('Members page', 'মেম্বার পেজে');
  String get fullStop => t('.', '।');
  String sharedTitle(String m) => bn ? 'সবার বিল — $m' : 'Shared bills — $m';
  String get sharedIntro => t(
      'Optional: bills split equally between everyone this month (e.g. electricity). Leave empty if all bills are personal.',
      'ঐচ্ছিক: এই মাসে যে বিল সবাই সমান ভাগে দেবে (যেমন বিদ্যুৎ)। সব বিল আলাদা হলে খালি রাখুন।');
  String rentNoMembers(String m) => bn ? '$m-এ কোনো মেম্বার নেই।' : 'No members in $m.';
  String get meals => t('Meals', 'মিল');
  String mealCostOf(String m) => bn ? 'মিল খরচ · $m' : 'Meal cost · $m';
  String bazarPaidOf(String m) => bn ? 'বাজার করেছে · $m' : 'Paid for bazar · $m';
  String get sharedBills => t('Shared bills', 'সবার বিল');
  String get balance => t('Balance', 'ব্যালেন্স');
  String get pays => t('Pays', 'দেবে');
  String get getsBack => t('Gets back', 'পাবে');
  String get settled => t('Settled', 'মিটে গেছে');
  String mealLine(String m, String meals, String rate) => bn ? '$m-এর মিল $meals × $rate' : '$m meals $meals × $rate';
  String get includeInTotal => t('Include in total', 'মোটে ধরা হবে');
  String get leftOut => t('Total and balance leave out ', 'মোট ও ব্যালেন্সে ধরা হয়নি: ');
  String get includeAll => t('Include all', 'সব ধরুন');
  String noBills(String m) => bn ? '$m-এর জন্য এখনো কোনো বিল নেই।' : 'No bills for $m yet.';
  String copyBills(int n, String from) => bn ? '$from থেকে $nটি বিল কপি করুন' : 'Copy $n ${n == 1 ? 'bill' : 'bills'} from $from';
  String get totalBills => t('Total bills', 'মোট বিল');
  String eachMember(int n) => bn ? 'প্রতি জন ($n জন)' : 'Each member ($n)';
  String get bill => t('Bill', 'বিল');
  String get billPlaceholder => t('e.g. House rent', 'যেমন বিদ্যুৎ বিল');
  String get addBill => t('Add bill', 'বিল যোগ করুন');
  String billUpdated(String name) => bn ? '$name আপডেট হয়েছে' : '$name updated';
  String get enterValidAmount => t('Enter a valid amount.', 'সঠিক টাকার পরিমাণ লিখুন।');
  List<String> get presets => bn
      ? ['বাসা ভাড়া', 'বুয়া', 'ওয়াইফাই', 'বিদ্যুৎ বিল', 'পানি', 'গ্যাস', 'রান্নার লোক', 'অন্যান্য']
      : ['House rent', 'Bua (maid)', 'WiFi', 'Electricity', 'Water', 'Gas', 'Cook', 'Other'];

  // ---- members
  String get membersIntro => t(
      'Everyone in the mess, and each person’s monthly bills. Members appear in every month from joining until they leave.',
      'মেসের সবাই, আর প্রত্যেকের মাসিক বিল। যোগ দেওয়া থেকে চলে যাওয়ার তারিখ পর্যন্ত প্রতিটি মাসে মেম্বাররা থাকবে।');
  String get addMember => t('Add member', 'মেম্বার যোগ করুন');
  String get memberAdded => t('Member added', 'মেম্বার যোগ হয়েছে');
  String get memberSaved => t('Member saved', 'মেম্বার সেভ হয়েছে');
  String get memberDeleted => t('Member deleted', 'মেম্বার ডিলিট হয়েছে');
  String get current => t('Current members', 'বর্তমান মেম্বার');
  String sharing(int n) => bn ? '$n জন খরচ ভাগ করছে' : '$n sharing costs';
  String get noMembers => t('No members yet', 'এখনো কোনো মেম্বার নেই');
  String get noMembersHint => t('Add everyone who shares costs to see each person’s share.', 'যারা খরচ ভাগ করে, সবাইকে যোগ করুন — তাহলে প্রত্যেকের ভাগ দেখা যাবে।');
  String get movedOut => t('Moved out', 'চলে গেছে');
  String get movedOutIntro => t('Still in the months they were here.', 'যে মাসগুলোতে ছিল, সেগুলোর হিসাবে এখনো আছে।');
  String get joinedOn => t('Joined on', 'মেসে উঠেছে');
  String get joinedHint => t('Costs are shared from this date.', 'এই তারিখ থেকে খরচ ভাগ হবে।');
  String get leftOn => t('Left on', 'চলে গেছে');
  String get leftHint => t('Leave empty if still here.', 'এখনো থাকলে খালি রাখুন।');
  String get nameBnHint => t('Shown when the app is in Bangla.', 'অ্যাপ বাংলায় থাকলে এই নাম দেখাবে।');
  String joined(String d) => bn ? 'উঠেছে $d' : 'Joined $d';
  String left(String d) => bn ? ' · চলে গেছে $d' : ' · left $d';
  String get editMember => t('Edit member', 'মেম্বার এডিট');
  String removeTitle(String name) => bn ? '$name-কে ডিলিট করবেন?' : 'Delete $name?';
  String get removeIntro => t(
      'They have no bazar or meal records, so they’ll be removed completely. If they moved out, set a “Left on” date instead.',
      'এর কোনো বাজার বা মিলের হিসাব নেই, তাই পুরোপুরি মুছে যাবে। চলে গিয়ে থাকলে বরং “চলে গেছে” তারিখ দিন।');
  String removeWithRecords(int n) => bn
      ? 'এর $nটি বাজার/মিলের হিসাব থেকে যাবে এবং আগের মাসগুলোর মোট ও মিল রেটে ধরা হবে, “ডিলিট করা মেম্বার” নামে। নিজের বিলগুলো আর ধরা হবে না। এটি আর ফেরানো যাবে না — শুধু বিল বন্ধ করতে চাইলে বরং “চলে গেছে” তারিখ দিন।'
      : 'Their $n bazar/meal records stay and keep counting in past months’ totals and meal rate as “Deleted member”. Their own bills stop. This can’t be undone — to just stop their bills, set a “Left on” date instead.';
  String get removeMember => t('Delete member', 'মেম্বার ডিলিট করুন');
  String get setBills => t('Set bills', 'বিল ঠিক করুন');
  String billsFormFor(String name) => bn ? '$name-এর মাসিক বিল' : '$name’s monthly bills';
  String billsSavedFor(String name) => bn ? '$name-এর বিল সেভ হয়েছে' : 'Bills saved for $name';
  String get addBillTypesFirst => t('Add bill types on the Bills page first.', 'আগে বিল পেজে বিলের ধরন যোগ করুন।');
  String get appliesFrom => t('Applies from', 'যে মাস থেকে');
  String earlierKeep(String m) => bn ? '$m-এর আগের মাসগুলোর টাকা বদলাবে না।' : 'Months before $m keep their amounts.';
  String perMonth(String t) => bn ? 'মোট $t/মাস' : 'Total $t/month';
  String get saveBills => t('Save bills', 'বিল সেভ করুন');
  String get leaveEmpty => t('Leave a bill empty if this member doesn’t pay it.', 'এই মেম্বার যে বিল দেয় না, সেটির ঘর খালি রাখুন।');
  String get everyoneTitle => t('Bills for everyone', 'সবার জন্য বিল');
  String get everyoneIntro => t(
      'Set the same amount for all current members at once, then change anyone whose amount differs. Empty boxes leave each person’s amount as it is.',
      'একসাথে সবার জন্য একই টাকা ঠিক করুন, তারপর যার টাকা আলাদা, তারটা বদলে দিন। খালি ঘরে প্রত্যেকের টাকা আগের মতোই থাকবে।');
  String get applyEveryone => t('Save for everyone', 'সবার জন্য সেভ করুন');
  String get billsSaved => t('Bills saved', 'বিল সেভ হয়েছে');

  // ---- catalogs (bills page, items page)
  String search(String nouns) => bn ? '$nouns খুঁজুন' : 'Search $nouns';
  String none(String nouns) => bn ? 'এখনো কোনো $nouns নেই। উপরে প্রথমটি যোগ করুন।' : 'No $nouns yet. Add the first one above.';
  String noMatch(String nouns, String q) => bn ? '“$q” নামে কোনো $nouns নেই।' : 'No $nouns match “$q”.';
  String deleteConfirm(String name) => bn ? '“$name” ডিলিট করবেন?' : 'Delete “$name”?';
  String get billsIntro => t(
      'Each person’s monthly bills such as house rent, maid, WiFi, water and gas. Set who pays how much on the Members page.',
      'বাসা ভাড়া, বুয়া, ওয়াইফাই, পানি, গ্যাসের মতো প্রত্যেকের মাসিক বিল। কার কত টাকা, তা ঠিক করুন মেম্বার পেজে।');
  String get billNouns => t('bills', 'বিল');
  String get newBill => t('New bill', 'নতুন বিল');
  String chargedTo(int n) => bn ? '$n জনের বিলে আছে' : 'Charged to $n';
  String get notChargedNow => t('Not charged to anyone now (was before)', 'এখন কারো বিলে নেই (আগের মাসে ছিল)');
  String get notUsed => t('Not used yet', 'এখনো ব্যবহার হয়নি');
  String get billLocked => t('Used in members’ bills, so it can’t be deleted. You can rename it.', 'মেম্বারদের বিলে ব্যবহার হয়েছে, তাই ডিলিট করা যাবে না। নাম বদলাতে পারবেন।');
  String whoPays(String m) => bn ? 'কে কোন বিল দেবে — $m' : 'Who pays what — $m';
  String get whoPaysIntro => t('Each person’s own bills this month. Change amounts on the Members page.', 'এই মাসে প্রত্যেকের নিজের বিল। টাকা বদলাতে মেম্বার পেজে যান।');
  String get whoPaysEmpty => t('No members or bills yet.', 'এখনো কোনো মেম্বার বা বিল নেই।');
  String get itemsIntro => t(
      'These items show up when recording bazar on the Expense tab. New names typed there are added here automatically.',
      'খরচ ট্যাবে বাজার লেখার সময় এই আইটেমগুলো তালিকায় আসে। সেখানে নতুন নাম লিখলে এখানে নিজে থেকেই যোগ হয়।');
  String get itemNouns => t('items', 'আইটেম');
  String get newItem => t('New item', 'নতুন আইটেম');
  String get itemPlaceholderEn => 'e.g. Hilsa';
  String get itemPlaceholderBn => 'যেমন ইলিশ';
  String get itemLocked => t('Used in bazar, so it can’t be deleted. You can rename it.', 'বাজারে ব্যবহার হয়েছে, তাই ডিলিট করা যাবে না। নাম বদলাতে পারবেন।');
  String usedTimes(int n) => bn ? '$nবার ব্যবহার হয়েছে' : 'Used $n ${n == 1 ? 'time' : 'times'}';
  String get saved => t('Saved', 'সেভ হয়েছে');
  String get deleted => t('Deleted', 'ডিলিট হয়েছে');

  // ---- settings
  String get settingsIntro => t('The mess name, the signed-in account and the app’s look.', 'মেসের নাম, লগইনের অ্যাকাউন্ট আর অ্যাপের ধরন।');
  String get messName => t('Mess name', 'মেসের নাম');
  String get messNameIntro => t('Shown next to the logo for everyone in this mess.', 'এই মেসের সবার জন্য লোগোর পাশে দেখাবে।');
  String get messNameHint => t('Leave it empty to show no name.', 'খালি রাখলে কোনো নাম দেখাবে না।');
  String get profile => t('Profile', 'প্রোফাইল');
  String get profileIntro => t('You can sign in with either the username or the email.', 'ইউজারনেম বা ইমেইল — যেকোনোটি দিয়ে লগইন করতে পারবেন।');
  String get saveProfile => t('Save profile', 'প্রোফাইল সেভ করুন');
  String get profileSaved => t('Profile saved', 'প্রোফাইল সেভ হয়েছে');
  String get passwordIntro => t('Changing it signs out every other device.', 'বদলালে অন্য সব ডিভাইস থেকে লগআউট হয়ে যাবে।');
  String get currentPassword => t('Current password', 'বর্তমান পাসওয়ার্ড');
  String get newPassword => t('New password', 'নতুন পাসওয়ার্ড');
  String get confirmNewPassword => t('Confirm new password', 'নতুন পাসওয়ার্ড আবার লিখুন');
  String get changePassword => t('Change password', 'পাসওয়ার্ড বদলান');
  String get passwordChanged => t('Password changed', 'পাসওয়ার্ড বদলানো হয়েছে');
  String get passwordsDiffer => t('The passwords don’t match.', 'পাসওয়ার্ড দুটো মেলেনি।');
  String get passwordHint => t('At least 8 characters.', 'কমপক্ষে 8 অক্ষর।');
  String signedInAs(String u, String e) => bn ? '$u ($e) হিসেবে লগইন করা আছে।' : 'Signed in as $u ($e).';
  String get signOutDevice => t('Sign out of this device', 'এই ডিভাইস থেকে লগআউট');
  String get signOutEverywhere => t('Sign out everywhere', 'সব ডিভাইস থেকে লগআউট');
  String get signOutEverywhereConfirm => t(
      'This signs out every phone and browser using this account, including this one.',
      'এই অ্যাকাউন্ট যত ফোন আর ব্রাউজারে লগইন আছে, সব থেকে লগআউট হবে — এটিসহ।');
  String get appearance => t('Appearance', 'অ্যাপের ধরন');
  String role(String r) => switch (r) {
        'OWNER' => t('Owner', 'মালিক'),
        'MANAGER' => t('Manager', 'ম্যানেজার'),
        _ => t('Viewer', 'শুধু দেখা'),
      };
}

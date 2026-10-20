/// Nepal administrative geography for the address form.
///
/// The 2015 federal structure: 7 provinces, 77 districts. This table is the
/// authoritative list the cascading address dropdowns read from — it exists
/// so a user never types a district name free-hand (the old free-text field
/// produced "KTM", "Kathmandu ", "Kathmandu District" ... all unsearchable).
///
/// Municipalities per district list the well-known units (metropolitan,
/// sub-metropolitan and prominent municipalities). A district whose list is
/// empty falls back to a free-text field in the UI — the table does not
/// pretend to cover all 753 local units.
///
/// Names are English spellings (the app's default locale); field labels are
/// localized through the ARB, the data values are not translated.
library;

/// A district inside a province.
class NepalDistrict {
  const NepalDistrict(this.name, {this.municipalities = const []});

  final String name;

  /// Well-known municipalities/local units, or empty for a free-text fallback.
  final List<String> municipalities;
}

/// One of Nepal's seven federal provinces.
class NepalProvince {
  const NepalProvince(this.name, this.districts);

  final String name;
  final List<NepalDistrict> districts;
}

/// All seven provinces with their districts, in the official order.
const List<NepalProvince> nepalProvinces = <NepalProvince>[
  NepalProvince('Koshi', <NepalDistrict>[
    NepalDistrict('Bhojpur', municipalities: [
      'Bhojpur Municipality', 'Shadanand Municipality', 'Hatuwagadhi',
      'Tyamke Maiyunm', 'Arun Rural Municipality', 'Pauwadungma',
      'Salpasilichho', 'Aamchowk', 'Ramprasad Rai',
    ]),
    NepalDistrict('Dhankuta', municipalities: [
      'Dhankuta Municipality', 'Pakhribas Municipality', 'Mahalaxmi',
      'Sangurigadhi', 'Khalsa Chhintang Sahidbhumi', 'Chhathar Jorpati',
      'Chaubise',
    ]),
    NepalDistrict('Ilam', municipalities: [
      'Ilam Municipality', 'Deumai Municipality', 'Mai Municipality',
      'Suryodaya Municipality', 'Fakfokathum', 'Chulachuli',
      'Mangsebung', 'Rong', 'Sandakpur', 'Mai Jogmai',
    ]),
    NepalDistrict('Jhapa', municipalities: [
      'Birtamod Municipality', 'Damak Municipality', 'Mechinagar Municipality',
      'Bhadrapur Municipality', 'Arjundhara Municipality', 'Shivasatakshi',
      'Gauradaha', 'Kankai', 'Kamal', 'Gauriganj', 'Barhadashi',
      'Jhapa Rural Municipality', 'Buddhashanti',
    ]),
    NepalDistrict('Khotang', municipalities: [
      'Diktel (Rupakot Majhuwagadhi) Municipality', 'Halesi Tuwachung',
      'Aiselukharka', 'Rawa Besi', 'Jantedhunga', 'Kepilasgadhi',
      'Diprung', 'Sakela', 'Khotehang', 'Barahapokhari',
    ]),
    NepalDistrict('Morang', municipalities: [
      'Biratnagar Metropolitan', 'Belbari Municipality', 'Sundar Haraicha',
      'Letang Municipality', 'Rangeli Municipality', 'Pathari Shanischare',
      'Urlabari Municipality', 'Ratuwamai', 'Sunwarshi', 'Gramthan',
      'Budhiganga', 'Kanepokhari', 'Jahada', 'Dhanpalthan', 'Miklajung',
      'Kerabari',
    ]),
    NepalDistrict('Okhaldhunga', municipalities: [
      'Siddhicharan Municipality', 'Khijidemba', 'Champadevi',
      'Chisankhugadhi', 'Manebhanjyang', 'Molung', 'Likhu', 'Mapyachandragadhi',
      'Sunkoshi',
    ]),
    NepalDistrict('Panchthar', municipalities: [
      'Phidim Municipality', 'Hilihan', 'Kummayak', 'Miklajung',
      'Phalelung', 'Yangwarak', 'Tumbewa',
    ]),
    NepalDistrict('Sankhuwasabha', municipalities: [
      'Chainpur Municipality', 'Dharmadevi Municipality', 'Khandbari',
      'Madi Municipality', 'Panchakhapan', 'Bhotkhola', 'Makalu',
      'Silichong', 'Sabhapokhari',
    ]),
    NepalDistrict('Solukhumbu', municipalities: [
      'Solududhakunda Municipality', 'Dudhkoshi (Khimikhola side)',
      'Thulung Dudhkoshi', 'Nechasalyan', 'Maha Kulung', 'Sotang',
      'Likhu Pike', 'Khumbu Pasanglhamu',
    ]),
    NepalDistrict('Sunsari', municipalities: [
      'Itahari Sub-Metropolitan', 'Dharan Sub-Metropolitan',
      'Inaruwa Municipality', 'Duhabi Municipality', 'Ramdhuni Municipality',
      'Baraha Municipality', 'Gadhi', 'Koshi', 'Harinagar', 'Bhokraha',
      'Dewanganj',
    ]),
    NepalDistrict('Taplejung', municipalities: [
      'Phungling Municipality', 'Aathrai Triveni', 'Mikkwakhola',
      'Maiwakhola', 'Pathibhara Yangwarak', 'Sirijangha', 'Sidingba',
      'Meringden',
    ]),
    NepalDistrict('Terhathum', municipalities: [
      'Myanglung Municipality', 'Laligurans Municipality', 'Aathrai',
      'Chhathar', 'Phedap', 'Menchhayayem',
    ]),
    NepalDistrict('Udayapur', municipalities: [
      'Triyuga Municipality', 'Chaudandigadhi', 'Belaka', 'Katari',
      'Rautamai', 'Udayapurgadhi', 'Tapli', 'Limchungbung',
    ]),
  ]),
  NepalProvince('Madhesh', <NepalDistrict>[
    NepalDistrict('Bara', municipalities: [
      'Kalaiya Sub-Metropolitan', 'Jeetpur Simara Sub-Metropolitan',
      'Kolhabi Municipality', 'Nijgadh Municipality', 'Mahagadhimai',
      'Simraungadh', 'Pacharauta', 'Devtal', 'Parwanipur', 'Baragadhi',
      'Suwarna', 'Fota', 'Pheta', 'Bishrampur', 'Karaiyamai', 'Prasauni',
      'Adarshkotwal',
    ]),
    NepalDistrict('Dhanusha', municipalities: [
      'Janakpur Sub-Metropolitan', 'Ganeshman Charnath', 'Dhanushadham',
      'Nagarain', 'Bideha', 'Mithila Bihari', 'Sahidnagar', 'Sabaila',
      'Kamala', 'Mithila', 'Mukhiyapatti Musaharniya', 'Janaknandini',
      'Aaurahi', 'Bateshwor', 'Chhireshwornath', 'Lakshminya',
    ]),
    NepalDistrict('Mahottari', municipalities: [
      'Jaleshwor Municipality', 'Bardibas Municipality', 'Gaushala',
      'Loharpatti', 'Ramgopalpur', 'Manra Siswa', 'Matihani',
      'Bhangaha', 'Balawa', 'Aurahi', 'Ekdanra', 'Sonama', 'Samsi',
      'Pipra', 'Mahottari Rural Municipality',
    ]),
    NepalDistrict('Parsa', municipalities: [
      'Birgunj Metropolitan', 'Bahudarmai Municipality', 'Parsagadhi',
      'Pokhariya Municipality', 'Sakhuwa Prasauni', 'Jagarnathpur',
      'Thori', 'Dhobini', 'Chhipaharmai', 'Bindabasini', 'Paterwa Sugauli',
      'Jirabhawani', 'Kalikam', 'Pakaha Mainpur',
    ]),
    NepalDistrict('Rautahat', municipalities: [
      'Gaur Municipality', 'Chandrapur Municipality', 'Garuda Municipality',
      'Katahariya', 'Madav Narayan', 'Yamunamai', 'Durgabhagawati',
      'Rajdevi', 'Rajpur', 'Maulapur', 'Boudhimai', 'Dewahi Gonahi',
      'Paroha', 'Phatuwa Bijayapur', 'Ishanath', 'Brindaban',
      'Gadhimai', 'Kataiya',
    ]),
    NepalDistrict('Saptari', municipalities: [
      'Rajbiraj Municipality', 'Kanchanrup Municipality', 'Dakneshwori',
      'Saptakoshi Municipality', 'Hanumannagar Kankalini', 'Surunga',
      'Shambhunath', 'Khadak', 'Bode Barsain', 'Belhi Chapena',
      'Bishnupur', 'Rupani', 'Tilathi Koiladi', 'Rajgadh', 'Chhinnamasta',
      'Mahadewa', 'Agnisaira Krishnasawaran', 'Tirhut',
    ]),
    NepalDistrict('Sarlahi', municipalities: [
      'Malangwa Municipality', 'Barahathwa Municipality', 'Lalbandi',
      'Haripur Municipality', 'Hariwan', 'Ishworpur', 'Bagmati',
      'Godaita', 'Kabilasi', 'Chakraghatta', 'Bramhapuri', 'Ramnagar',
      'Basbariya', 'Dhankaul', 'Parsa', 'Bishnu', 'Chandranagar',
      'Kaudena',
    ]),
    NepalDistrict('Siraha', municipalities: [
      'Lahan Municipality', 'Siraha Municipality', 'Golbazar Municipality',
      'Mirchaiya Municipality', 'Kalyanpur Municipality', 'Dhangadhimai',
      'Karjanha', 'Nawarajpur', 'Sakhuwanankarkatti', 'Bhagwanpur',
      'Bishnupur', 'Laxmipur Patari', 'Narahan', 'Bariyarpatti',
      'Aurahi', 'Arnama', 'Sukhipur',
    ]),
  ]),
  NepalProvince('Bagmati', <NepalDistrict>[
    NepalDistrict('Bhaktapur', municipalities: [
      'Bhaktapur Municipality', 'Madhyapur Thimi', 'Suryabinayak',
      'Changunarayan',
    ]),
    NepalDistrict('Chitwan', municipalities: [
      'Bharatpur Metropolitan', 'Ratnanagar Municipality', 'Kalika',
      'Khairahani', 'Rapti Municipality', 'Madi Municipality', 'Ichchhakamana',
    ]),
    NepalDistrict('Dhading', municipalities: [
      'Nilkantha Municipality', 'Dhunibeshi Municipality', 'Khaniyabas',
      'Gajuri', 'Galchhi', 'Gangajamuna', 'Jwalamukhi', 'Thakre',
      'Netrawati', 'Benighat Rorang', 'Rubi Valley', 'Siddhalek',
      'Tripurasundari',
    ]),
    NepalDistrict('Dolakha', municipalities: [
      'Bhimeshwor Municipality', 'Jiri', 'Bigu', 'Kalinchok',
      'Gaurishankar', 'Tamakoshi', 'Melung', 'Baiteshwor', 'Shailung',
    ]),
    NepalDistrict('Kathmandu', municipalities: [
      'Kathmandu Metropolitan', 'Kirtipur', 'Tokha', 'Tarakeshwor',
      'Gokarneshwor', 'Budhanilkantha', 'Shankharapur', 'Nagarjun',
      'Kageshwori Manohara', 'Chandragiri', 'Dakshinkali',
    ]),
    NepalDistrict('Kavrepalanchok', municipalities: [
      'Dhulikhel Municipality', 'Banepa Municipality', 'Panauti',
      'Panchkhal', 'Namobuddha', 'Mandandeupur', 'Khanikhola', 'Temal',
      'Chaurideurali', 'Bhumlu', 'Mahabharat', 'Bethanchowk', 'Roshi',
    ]),
    NepalDistrict('Lalitpur', municipalities: [
      'Lalitpur Metropolitan', 'Mahalaxmi Municipality', 'Godawari',
      'Konjyosom', 'Bagmati', 'Mahankal',
    ]),
    NepalDistrict('Makwanpur', municipalities: [
      'Hetauda Sub-Metropolitan', 'Thaha Municipality', 'Bhimphedi',
      'Makawanpurgadhi', 'Manahari', 'Raksirang', 'Bakaiya', 'Bagmati',
      'Kailash', 'Indrasarowar',
    ]),
    NepalDistrict('Nuwakot', municipalities: [
      'Bidur Municipality', 'Belkotgadhi', 'Kakani', 'Dupcheshwor',
      'Likhu', 'Myagang', 'Panchakanya', 'Shivapuri', 'Suryagadhi',
      'Tadi', 'Tarakeshwor (Nuwakot)',
    ]),
    NepalDistrict('Ramechhap', municipalities: [
      'Manthali Municipality', 'Ramechhap Municipality', 'Umakunda',
      'Khandadevi', 'Gokulganga', 'Doramba', 'Likhu Tamakoshi',
      'Sunapati',
    ]),
    NepalDistrict('Rasuwa', municipalities: [
      'Gosaikunda', 'Naukunda', 'Kalika', 'Uttargaya', 'Aamachhodingmo',
    ]),
    NepalDistrict('Sindhuli', municipalities: [
      'Kamalamai Municipality', 'Dudhauli Municipality', 'Golanjor',
      'Ghanglekh', 'Hariharpurgadhi', 'Marin', 'Sunkoshi', 'Tinpatan',
      'Phikkal',
    ]),
    NepalDistrict('Sindhupalchok', municipalities: [
      'Chautara Sangachokgadhi', 'Barhabise', 'Melamchi', 'Bahrabise',
      'Balefi', 'Bhotekoshi', 'Helambu', 'Jugal', 'Langtang',
      'Lisangkhu Pakhar', 'Panchpokhari Thangpal', 'Sunkoshi',
      'Tripurasundari', 'Indrawati',
    ]),
  ]),
  NepalProvince('Gandaki', <NepalDistrict>[
    NepalDistrict('Baglung', municipalities: [
      'Baglung Municipality', 'Dhorpatan Municipality', 'Galkot',
      'Jaimini Municipality', 'Badigad', 'Kathekhola', 'Nisikhola',
      'Bareng', 'Tarakhola', 'Taman Khola',
    ]),
    NepalDistrict('Gorkha', municipalities: [
      'Gorkha Municipality', 'Palungtar Municipality', 'Sulikot',
      'Siranchowk', 'Ajirkot', 'Aarughat', 'Gandaki', 'Bhimsen',
      'Shahid Lakhan', 'Chumanuwri', 'Dharche',
    ]),
    NepalDistrict('Kaski', municipalities: [
      'Pokhara Metropolitan', 'Annapurna', 'Machhapuchhre', 'Madi',
      'Rupa',
    ]),
    NepalDistrict('Lamjung', municipalities: [
      'Besishahar Municipality', 'Madhya Nepal Municipality', 'Rainas',
      'Sundarbazar', 'Kwholasothar', 'Dordi', 'Dudhapokhari', 'Marsyangdi',
    ]),
    NepalDistrict('Manang', municipalities: [
      'Chame (Nashong)', 'Narpa Bhumi', 'Nason',
    ]),
    NepalDistrict('Mustang', municipalities: [
      'Gharpajhong (Kagbeni side)', 'Thasang', 'Dalome', 'Lomanthang',
      'Waragung Muktikhsetra',
    ]),
    NepalDistrict('Myagdi', municipalities: [
      'Beni Municipality', 'Annapurna', 'Dhaulagiri', 'Mangala',
      'Malika', 'Raghuganga',
    ]),
    NepalDistrict('Nawalparasi (East)', municipalities: [
      'Kawasoti (Nawalpur)', 'Gaindakot', 'Devchuli', 'Madhyabindu',
      'Bulingtar', 'Bungdikali', 'Hupsekot',
    ]),
    NepalDistrict('Parbat', municipalities: [
      'Kushma Municipality', 'Phalebas Municipality', 'Mahashila',
      'Modi', 'Bihadi', 'Painyu', 'Jaljala',
    ]),
    NepalDistrict('Syangja', municipalities: [
      'Putalibazar Municipality', 'Waling Municipality', 'Bhirkot',
      'Galyang', 'Chapakot', 'Kaligandaki', 'Arjunchaupari', 'Phedikhola',
      'Harinas', 'Aandhikhola', 'Biruwagadhi',
    ]),
    NepalDistrict('Tanahun', municipalities: [
      'Byas Municipality', 'Bhanu Municipality', 'Bandipur',
      'Shuklagandaki', 'Bhimad', 'Rhishing', 'Myagde', 'Aanbu Khaireni',
      'Devghat',
    ]),
  ]),
  NepalProvince('Lumbini', <NepalDistrict>[
    NepalDistrict('Arghakhanchi', municipalities: [
      'Sandhikharka Municipality', 'Sitganga', 'Bhumikasthan',
      'Chhatradev', 'Malarani', 'Panini',
    ]),
    NepalDistrict('Banke', municipalities: [
      'Nepalgunj Sub-Metropolitan', 'Kohalpur Municipality',
      'Khajura', 'Janaki', 'Rapti Sonari', 'Baijanath', 'Duduwa',
      'Narainapur',
    ]),
    NepalDistrict('Bardiya', municipalities: [
      'Gulariya Municipality', 'Thakurbaba Municipality', 'Rajapur',
      'Madhuwan', 'Geruwa', 'Bansagadhi', 'Barbardiya',
    ]),
    NepalDistrict('Dang', municipalities: [
      'Ghorahi Sub-Metropolitan', 'Tulsipur Sub-Metropolitan',
      'Lamahi Municipality', 'Bangalachuli', 'Dangisharan', 'Gadhawa',
      'Rajpur', 'Shantinagar', 'Rapti',
    ]),
    NepalDistrict('Gulmi', municipalities: [
      'Musikot Municipality', 'Resunga Municipality', 'Isma',
      'Kaligandaki', 'Gulmi Darbar', 'Satyawati', 'Chandrakot',
      'Ruru', 'Chatrakot', 'Dhurkot', 'Madane', 'Malika',
    ]),
    NepalDistrict('Kapilvastu', municipalities: [
      'Taulihawa (Kapilvastu) Municipality', 'Siddharthanagar (Bhairahawa)',
      'Banganga', 'Bijaynagar', 'Shivaraj', 'Krishnanagar', 'Maharajgunj',
      'Mayadevi', 'Yashodhara', 'Sudhdhodhan',
    ]),
    NepalDistrict('Parasi (Nawalparasi West)', municipalities: [
      'Bardaghat (Bardghat)', 'Ramgram Municipality', 'Sunwal',
      'Palhi Nandan', 'Pratappur', 'Sarawal', 'Susta',
    ]),
    NepalDistrict('Palpa', municipalities: [
      'Tansen Municipality', 'Rampur Municipality', 'Rainadevi Chhahara',
      'Ribdikot', 'Purbakhola', 'Bagnaskali', 'Mathagadhi', 'Nisdi',
      'Tinau', 'Rambha',
    ]),
    NepalDistrict('Pyuthan', municipalities: [
      'Pyuthan Municipality', 'Sworgadwari Municipality', 'Mandavi',
      'Gaumukhi', 'Naubahini', 'Jhimaruk', 'Aairawati', 'Sarumarani',
      'Mallarani',
    ]),
    NepalDistrict('Rolpa', municipalities: [
      'Rolpa Municipality', 'Tribeni', 'Runtigadhi', 'Sunilsmriti',
      'Lungri', 'Sunchhahari', 'Thawang', 'Madi', 'Gangadev',
      'Duikholi',
    ]),
    NepalDistrict('Eastern Rukum', municipalities: [
      'Rukumkot', 'Sisne', 'Putha Uttarganga', 'Bhume',
    ]),
    NepalDistrict('Rupandehi', municipalities: [
      'Butwal Sub-Metropolitan', 'Siddharthanagar (Bhairahawa)',
      'Lumbini Sanskritik Municipality', 'Devdaha', 'Sainamaina',
      'Tilottama Municipality', 'Gaidahawa', 'Kanchan', 'Kotahimai',
      'Marchawari', 'Mayadevi', 'Omsatiya', 'Rohini', 'Sammarimai',
      'Siyari', 'Sudhdhodhan',
    ]),
  ]),
  NepalProvince('Karnali', <NepalDistrict>[
    NepalDistrict('Dailekh', municipalities: [
      'Narayan Municipality', 'Dullu Municipality', 'Chamunda Bindrasaini',
      'Aathbis', 'Bhagawatimai', 'Gurans', 'Dungeshwor', 'Naumule',
      'Mahabu', 'Thantikandh',
    ]),
    NepalDistrict('Dolpa', municipalities: [
      'Thuli Bheri Municipality', 'Tripurasundari', 'She Phoksundo',
      'Kaike', 'Jagadulla', 'Mudkechula', 'Chharka Tangsong',
    ]),
    NepalDistrict('Humla', municipalities: [
      'Simkot (Namkha)', 'Adanchuli', 'Kharpunath', 'Tanjakot',
      'Chankheli', 'Sarkegad', 'Namkha',
    ]),
    NepalDistrict('Jajarkot', municipalities: [
      'Bheri Municipality', 'Barekot', 'Kuse', 'Junichande', 'Shivalaya',
      'Nalgad', 'Tribeni Nalagad',
    ]),
    NepalDistrict('Jumla', municipalities: [
      'Chandannath Municipality', 'Kankasundari', 'Sinja',
      'Hima', 'Tila', 'Guthichaur', 'Tatopani', 'Patarasi',
    ]),
    NepalDistrict('Kalikot', municipalities: [
      'Khandachakra', 'Raskot', 'Tilagufa', 'Pachaljharana',
      'Sanni Tribeni', 'Naraharinath', 'Shubha Kalika', 'Mahawai',
    ]),
    NepalDistrict('Mugu', municipalities: [
      'Chhayanath Rara Municipality', 'Mugum Karmarong', 'Soru',
      'Khatyad',
    ]),
    NepalDistrict('Salyan', municipalities: [
      'Sharada Municipality', 'Bagchaur Municipality', 'Bangad Kupinde',
      'Kalimati', 'Tribeni', 'Kapurkot', 'Chhatreshwari', 'Siddha Kumakh',
      'Darma',
    ]),
    NepalDistrict('Surkhet', municipalities: [
      'Birendranagar Municipality', 'Bheriganga', 'Gurbhakot',
      'Panchpuri', 'Lekbesi', 'Chaukune', 'Barahatal', 'Chingad',
      'Simta',
    ]),
    NepalDistrict('Western Rukum', municipalities: [
      'Musikot (Rukum)', 'Chaurjahari', 'Aathbisakot', 'Sanfebagar',
      'Banfikot',
    ]),
  ]),
  NepalProvince('Sudurpashchim', <NepalDistrict>[
    NepalDistrict('Achham', municipalities: [
      'Mangalsen Municipality', 'Kamalbazar', 'Sanphebagar', 'Panchdeval',
      'Dhakari', 'Turmakhad', 'Mellekh', 'Ramaroshan', 'Chaurpati',
    ]),
    NepalDistrict('Baitadi', municipalities: [
      'Dasharathchand Municipality', 'Patan Municipality', 'Melauli',
      'Purchaudi', 'Sunarya', 'Sigas', 'Shivanath', 'Pantedhera',
      'Dogadakedar', 'Dilasaini',
    ]),
    NepalDistrict('Bajhang', municipalities: [
      'Chainpur (Jaya Prithvi) Municipality', 'Bungal Municipality',
      'Talkot', 'Masta', 'Khaptadchhanna', 'Thalara', 'Bitthadchir',
      'Surma', 'Chhabis Pathibhara', 'Durgathali', 'Kedarseu',
      'Saipal',
    ]),
    NepalDistrict('Bajura', municipalities: [
      'Martadi (Badimalika) Municipality', 'Budhinanda', 'Triveni',
      'Swami Kartik', 'Jagannath', 'Himali', 'Gaumul', 'Pandey Gufa',
      'Chhededaha',
    ]),
    NepalDistrict('Dadeldhura', municipalities: [
      'Amargadhi Municipality', 'Parshuram Municipality', 'Alital',
      'Bhageshwor', 'Nawadurga', 'Ganyapdhura', 'Ajayameru',
    ]),
    NepalDistrict('Darchula', municipalities: [
      'Khalanga (Mahakali) Municipality', 'Shailyashikhar', 'Naugad',
      'Malikarjun', 'Apihimal', 'Duhun', 'Byas', 'Lekam', 'Marma',
    ]),
    NepalDistrict('Doti', municipalities: [
      'Dipayal Silgadhi Municipality', 'Shikhar Municipality',
      'Purbichauki', 'Badikedar', 'Jorayal', 'Sayal', 'Aadarsha',
      'K.I. Singh',
    ]),
    NepalDistrict('Kailali', municipalities: [
      'Dhangadhi Sub-Metropolitan', 'Tikapur Municipality',
      'Bhajani Municipality', 'Godawari Municipality', 'Ghodaghodi',
      'Lamki Chuha', 'Janaki', 'Bardagoriya', 'Joshipur', 'Mohanyal',
      'Chure', 'Kailari',
    ]),
    NepalDistrict('Kanchanpur', municipalities: [
      'Bhimdatta (Mahendranagar) Municipality', 'Bedkot Municipality',
      'Belauri Municipality', 'Punarbas', 'Shuklaphanta', 'Krishnapur',
      'Laljhadi', 'Beldandi',
    ]),
  ]),
];

/// Districts of [provinceName], or all districts when the name is unknown.
List<NepalDistrict> districtsOf(String provinceName) {
  for (final province in nepalProvinces) {
    if (province.name == provinceName) return province.districts;
  }
  return const [];
}

/// Municipalities of [districtName], or empty when unknown/free-text.
List<String> municipalitiesOf(String districtName) {
  for (final province in nepalProvinces) {
    for (final district in province.districts) {
      if (district.name == districtName) return district.municipalities;
    }
  }
  return const [];
}

/// The province a district belongs to, or null when unknown.
String? provinceOf(String districtName) {
  for (final province in nepalProvinces) {
    for (final district in province.districts) {
      if (district.name == districtName) return province.name;
    }
  }
  return null;
}

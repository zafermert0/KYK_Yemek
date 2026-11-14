import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const version = '0.2.1';
const platform = MethodChannel('com.yurtmenu/native');
const sourcePage = 'https://kepce.org';
const kepceEndpoint = 'https://kepce.org/api/v1/menus?city=ankara&date=today';
const releasesPage = 'https://github.com/zafermert0/KYK_Yemek/releases';
DateTime ankaraNow() => DateTime.now().toUtc().add(const Duration(hours:3));
String normalized(String s) => s.replaceAll('İ','i').replaceAll('I','ı').toLowerCase().trim();
Future<void> openExternal(String url) async { await platform.invokeMethod('open', url); }
Future<dynamic> getJson(String url) async {
  final client=HttpClient()..connectionTimeout=const Duration(seconds:10);
  try { final request=await client.getUrl(Uri.parse(url)); request.headers.set('User-Agent','KYK-Yemek/0.2.1'); request.headers.set('Accept','application/json'); request.followRedirects=false; final response=await request.close().timeout(const Duration(seconds:15)); if(response.statusCode!=200)throw HttpException('HTTP ${response.statusCode}'); final bytes=<int>[]; await for(final chunk in response.timeout(const Duration(seconds:15))){bytes.addAll(chunk);if(bytes.length>3000000)throw const FormatException('Veri çok büyük');} return jsonDecode(utf8.decode(bytes)); } finally {client.close(force:true);}
}
Map<String,dynamic> validateMenus(dynamic obj){
 if(obj is! Map || obj.isEmpty)throw const FormatException(); final result=<String,dynamic>{};
 for(final e in obj.entries){final k=e.key;final v=e.value;if(k is! String||!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(k)||v is! Map)throw const FormatException();final d=DateTime.tryParse(k);if(d==null||keyOf(d)!=k)throw const FormatException();final record=<String,List<String>>{};for(final meal in ['breakfast','dinner']){final x=v[meal];if(x is! List||x.any((s)=>s is! String||s.trim().isEmpty))throw const FormatException();record[meal]=x.cast<String>();}result[k]=record;}return result;
}
// Independent reader for the documented public JSON format. Only raw food names are kept.
Map<String,dynamic> parseKepceToday(dynamic json, String expectedDate) {
  if (json is! List) throw const FormatException('Beklenmeyen Kepçe yanıtı');
  final meals = <String,List<String>>{'breakfast': [], 'dinner': []};
  for (final row in json) {
    if (row is! Map || row['city_slug'] != 'ankara' || row['serve_date'] != expectedDate || row['status'] != 'approved') continue;
    final type = row['meal_type'];
    if (type is! String || !meals.containsKey(type)) continue;
    final raw = row['items'];
    if (raw is! List) continue;
    final items = raw.whereType<Map>().toList();
    items.sort((a,b) => (a['order_index'] is num ? a['order_index'] as num : 0).compareTo(b['order_index'] is num ? b['order_index'] as num : 0));
    for (final item in items) {
      final name = item['name'];
      if (name is String && name.trim().isNotEmpty && !meals[type]!.contains(name.trim())) meals[type]!.add(name.trim());
    }
  }
  if (meals.values.every((m) => m.isEmpty)) throw const FormatException('Bugünün onaylı menüsü bulunamadı');
  return <String,dynamic>{expectedDate: meals};
}
const months = ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
const weekdays = ['Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar'];
const shortDays = ['Pzt','Sal','Çar','Per','Cum','Cmt','Paz'];
const seed = <String, dynamic>{
  '2026-11-13': {'breakfast':['Menemen','Patates salatası','Simit','Labne peyniri','Siyah / yeşil zeytin','Su','Ekmek'], 'dinner':['Mercimek / köz biber çorbası','Hamburger / tavuk fajita / sebze graten','Patates kızartması','Ayran / meyve suyu','Su','Ekmek']},
  '2026-11-14': {'breakfast':['Haşlanmış yumurta','Karışık kızartma','Peynirli milföy böreği','Kaşar peyniri','Siyah / yeşil zeytin','Su','Ekmek'], 'dinner':['Tarhana / kremalı mantar çorbası','Haşlanmış tavuk fileto ve garnitür / patlıcan yemeği','Tereyağlı nohutlu pirinç pilavı','Supangle','Su','Ekmek']},
  '2026-11-15': {'breakfast':['Sucuklu omlet','Patates kroket','Dere otlu poğaça','Beyaz peynir'], 'dinner':['Terbiyeli şehriye çorbası','Püreli tavuk / et kebabı','Tereyağlı bulgur pilavı','Taze fasulye','Ezme']},
};
String keyOf(DateTime d) => '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
DateTime ankaraToday() { final t = DateTime.now().toUtc().add(const Duration(hours:3)); return DateTime(t.year,t.month,t.day); }
String dateLabel(DateTime d) => '${d.day} ${months[d.month-1]} ${d.year}, ${weekdays[d.weekday-1]}';
DateTime dayAdd(DateTime d, int n) => DateTime(d.year,d.month,d.day+n);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}
class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.prefs});
  final SharedPreferences prefs;
  @override State<MyApp> createState()=>_MyAppState();
}
class _MyAppState extends State<MyApp> {
  late String mode;
  @override void initState(){ super.initState(); mode=widget.prefs.getString('themeMode')??((widget.prefs.getBool('dark')??true)?'dark':'light'); }
  ThemeData makeTheme(bool dark,{bool amoled=false}) {
    final bg=dark?(amoled?Colors.black:const Color(0xff100e0e)):const Color(0xfff5f0eb);
    final surface=dark?(amoled?const Color(0xff151515):const Color(0xff211e1e)):const Color(0xfffffbf7);
    final accent=dark?const Color(0xffc5b1a0):const Color(0xff755844);
    final scheme=ColorScheme.fromSeed(seedColor:accent,brightness:dark?Brightness.dark:Brightness.light).copyWith(surface:surface,primary:accent,onSurface:dark?const Color(0xfff3ece6):const Color(0xff28201c),onPrimary:dark?const Color(0xff201a17):Colors.white,outline:dark?const Color(0xff504844):const Color(0xffd6c9bd),secondaryContainer:dark?const Color(0xff463b34):const Color(0xffeadbd0));
    return ThemeData(useMaterial3:true,colorScheme:scheme,scaffoldBackgroundColor:bg, fontFamily:null);
  }
  @override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'YurtMenü',theme:makeTheme(false),darkTheme:makeTheme(true,amoled:mode=='amoled'),themeMode:mode=='system'?ThemeMode.system:mode=='light'?ThemeMode.light:ThemeMode.dark,home:MenuHome(prefs:widget.prefs,mode:mode,onTheme:(v){setState(()=>mode=v);widget.prefs.setString('themeMode',v);}));
}
class MenuHome extends StatefulWidget {
  const MenuHome({super.key,required this.prefs,required this.mode,required this.onTheme});
  final SharedPreferences prefs; final String mode; final ValueChanged<String> onTheme;
  @override State<MenuHome> createState()=>_MenuHomeState();
}
class _MenuHomeState extends State<MenuHome> with WidgetsBindingObserver {
  DateTime selected=ankaraToday(); late DateTime calendarMonth;
  int tab=0; bool breakfast=true;
  bool refreshing=false; String status=''; String? updateTag;
  late Set<String> favorites; late Set<String> remoteDates;
  late bool morningAlert, eveningAlert, favoriteAlert, updateAlert;
  late int morningMinutes, eveningMinutes; late String endpoint;
  double drag=0; double lastViewport=0; Timer? clock; DateTime lastToday=ankaraToday();
  bool get wide => MediaQuery.sizeOf(context).width>=760 && MediaQuery.sizeOf(context).width>MediaQuery.sizeOf(context).height;
  late Map<String,dynamic> data;
  late Set<String> customDates;
  final datesController=ScrollController();
  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);calendarMonth=DateTime(selected.year,selected.month);breakfast=ankaraNow().hour<12;data=Map.of(seed);customDates={};remoteDates={};final p=widget.prefs;
    favorites=(p.getStringList('favorites')??[]).toSet(); morningAlert=p.getBool('morningAlert')??false; eveningAlert=p.getBool('eveningAlert')??false; favoriteAlert=p.getBool('favoriteAlert')??false;updateAlert=p.getBool('updateAlert')??true; morningMinutes=p.getInt('morningMinutes')??480; eveningMinutes=p.getInt('eveningMinutes')??1020; endpoint=(p.getBool('kepceEnabled')??true)?kepceEndpoint:'';
    for(final k in ['kepceDailyCache','customMenus']){try{final raw=p.getString(k);if(raw!=null){final m=validateMenus(jsonDecode(raw));data.addAll(m);(k=='kepceDailyCache'?remoteDates:customDates).addAll(m.keys);}}catch(_){}}
    WidgetsBinding.instance.addPostFrameCallback((_) {if(!mounted)return;centerDate();syncNative();if(endpoint.isNotEmpty)refresh();if(updateAlert)checkUpdate(silent:true);});
    clock=Timer.periodic(const Duration(minutes:1),(_)=>rollDate());
  }
  void rollDate(){if(!mounted)return;final now=ankaraToday();if(keyOf(now)!=keyOf(lastToday)){final wasToday=keyOf(selected)==keyOf(lastToday);lastToday=now;if(wasToday){breakfast=ankaraNow().hour<12;choose(now);}else{setState((){});}syncNative();if(endpoint.isNotEmpty)refresh();}}
  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed){rollDate();if(endpoint.isNotEmpty)refresh();}}
  @override void dispose(){WidgetsBinding.instance.removeObserver(this);clock?.cancel();datesController.dispose();super.dispose();}
  void centerDate({bool animate=false,int attempt=0}){if(!mounted||tab!=0)return;if(!datesController.hasClients||datesController.positions.length!=1||!datesController.position.hasContentDimensions){if(attempt<4)WidgetsBinding.instance.addPostFrameCallback((_)=>centerDate(animate:animate,attempt:attempt+1));return;}final width=datesController.position.viewportDimension;final pad=((width-66)/2).clamp(0.0,double.infinity);final target=(pad+(selected.day-1)*76.0-(width-66)/2).clamp(0.0,datesController.position.maxScrollExtent).toDouble();if(animate){datesController.animateTo(target,duration:const Duration(milliseconds:240),curve:Curves.easeOutCubic);}else{datesController.jumpTo(target);}}
  void choose(DateTime d,{bool goMenu=false}){setState((){selected=d;calendarMonth=DateTime(d.year,d.month);if(goMenu)tab=0;});WidgetsBinding.instance.addPostFrameCallback((_)=>centerDate(animate:true));}
  void changeTab(int i){if(tab==i)return;setState(()=>tab=i);if(i==0){WidgetsBinding.instance.addPostFrameCallback((_)=>centerDate());}}
  Future<void> syncNative() async {try{await platform.invokeMethod('sync',{'menus':jsonEncode(data),'favorites':jsonEncode(favorites.toList()),'morningAlert':morningAlert,'eveningAlert':eveningAlert,'favoriteAlert':favoriteAlert,'morningMinutes':morningMinutes,'eveningMinutes':eveningMinutes});}catch(_){}}
  void toast(String text){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));}
  Future<void> refresh({bool manual=false}) async {
    if (refreshing) return;
    if (endpoint.isEmpty) {if(manual)toast('Canlı kaynak kapalı.');return;}
    final today=keyOf(ankaraToday());
    final now=DateTime.now().millisecondsSinceEpoch;
    final p=widget.prefs;
    final last=p.getInt('kepceAttempt')??0;
    final success=p.getInt('kepceSuccess')??0;
    final sameDay=p.getString('kepceDate')==today;
    if (now-last<60000) {if(manual)toast('Bir dakika sonra yeniden deneyebilirsin.');return;}
    if(!manual && sameDay && now-success<21600000)return;
    if(!manual && now-last<900000 && now-success>=21600000)return;
    setState(()=>refreshing=true);
    try {
      await p.setInt('kepceAttempt',now);
      final incoming=parseKepceToday(await getJson(kepceEndpoint),today);
      if(!mounted || endpoint.isEmpty)return;
      // Keep only the latest daily response, preserving manual menus and bundled archive.
      final prior=p.getString('kepceDailyCache');
      if(prior!=null){
        final cached=validateMenus(jsonDecode(prior));
        final old=cached[today]; final fresh=incoming[today] as Map;
        if(old is Map){for(final meal in ['breakfast','dinner']){if((fresh[meal] as List).isEmpty && old[meal] is List)fresh[meal]=old[meal];}}
      }
      if(!await p.setString('kepceDailyCache',jsonEncode(incoming)))throw StateError('Kayıt başarısız');
      await p.setInt('kepceSuccess',DateTime.now().millisecondsSinceEpoch);
      await p.setString('kepceDate',today);
      if(!mounted)return;
      setState((){
        for(final k in remoteDates){if(!customDates.contains(k)){if(seed.containsKey(k)){data[k]=seed[k];}else{data.remove(k);}}}
        data.addAll(Map.fromEntries(incoming.entries.where((e)=>!customDates.contains(e.key))));
        remoteDates..clear()..addAll(incoming.keys);
        final t=ankaraNow(); status='Son güncelleme: ${timeText(t.hour*60+t.minute)}';
      });
      await syncNative();
      if(manual)toast('Bugünün menüsü güncellendi.');
    } catch (_) {
      if(mounted)setState(()=>status='Güncelleme başarısız · kayıtlı veriler korunuyor.');
      if(manual)toast('Menü güncellenemedi.');
    } finally {if(mounted)setState(()=>refreshing=false);}
  }
  Future<void> toggleKepce(bool enabled) async {
    setState(()=>endpoint=enabled?kepceEndpoint:'');
    await widget.prefs.setBool('kepceEnabled',enabled);
    if(enabled)await refresh(manual:true);
  }

  int compareVersions(String a,String b){List<int> parts(String x)=>x.replaceFirst(RegExp(r'^v'),'').split('.').map((e)=>int.tryParse(e)??0).toList();final aa=parts(a),bb=parts(b);for(var i=0;i<3;i++){final n=(i<aa.length?aa[i]:0).compareTo(i<bb.length?bb[i]:0);if(n!=0)return n;}return 0;}
  Future<void> checkUpdate({bool silent=false}) async {try{final obj=await getJson('https://api.github.com/repos/zafermert0/KYK_Yemek/releases/latest');final tag=obj['tag_name'];if(tag is! String)throw const FormatException();if(!mounted)return;if(compareVersions(tag,version)>0){setState(()=>updateTag=tag);if(!silent)toast('Yeni sürüm: $tag');}else if(!silent){toast('En güncel sürüm kullanılıyor.');}}catch(_){if(!silent)toast('Yayımlanmış sürüm bulunamadı veya bağlantı başarısız.');}}
  Future<void> saveAlerts() async {final p=widget.prefs;await p.setBool('morningAlert',morningAlert);await p.setBool('eveningAlert',eveningAlert);await p.setBool('favoriteAlert',favoriteAlert);await p.setInt('morningMinutes',morningMinutes);await p.setInt('eveningMinutes',eveningMinutes);if(morningAlert||eveningAlert||favoriteAlert){try{final granted=await platform.invokeMethod<bool>('permission');if(granted!=true)toast('Bildirim izni gerekli. Android ayarlarından açabilirsin.');}catch(_){}}await syncNative();}
  String timeText(int n)=>'${(n~/60).toString().padLeft(2,'0')}:${(n%60).toString().padLeft(2,'0')}';
  Future<void> pickTime(bool morning) async {final n=morning?morningMinutes:eveningMinutes;final t=await showTimePicker(context:context,initialTime:TimeOfDay(hour:n~/60,minute:n%60));if(t==null||!mounted)return;setState((){if(morning){morningMinutes=t.hour*60+t.minute;}else{eveningMinutes=t.hour*60+t.minute;}});await saveAlerts();}
  Future<void> toggleFavorite(String dish) async {final name=normalized(dish);setState((){if(!favorites.add(name))favorites.remove(name);});await widget.prefs.setStringList('favorites',favorites.toList());await syncNative();}
  Future<void> editFavorites() async {final c=TextEditingController();final result=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Favori yemek ekle'),content:TextField(controller:c,decoration:const InputDecoration(hintText:'Örn. supangle')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('İptal')),FilledButton(onPressed:()=>Navigator.pop(ctx,c.text.trim()),child:const Text('Ekle'))]));c.dispose();if(result==null||result.isEmpty||!mounted)return;if(!favorites.contains(normalized(result)))await toggleFavorite(result);}
  List<String> meals(bool morning){final entry=data[keyOf(selected)];if(entry is! Map)return []; final items=entry[morning?'breakfast':'dinner'];return items is List?items.whereType<String>().toList():[];}
  Future<void> importMenus() async {
    final control=TextEditingController();
    final raw=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Menü verisi ekle'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Tarih başına iki öğün içeren JSON metnini yapıştır. Mevcut tarih güncellenir.'),const SizedBox(height:12),TextField(controller:control,maxLines:8,decoration:const InputDecoration(border:OutlineInputBorder(),hintText:'{"2026-11-16":{"breakfast":["Omlet"],"dinner":["Çorba"]}}'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('İptal')),FilledButton(onPressed:()=>Navigator.pop(ctx,control.text),child:const Text('Kaydet'))]));
    control.dispose(); if(raw==null||!mounted)return;
    try{
      final obj=jsonDecode(raw); if(obj is! Map || obj.isEmpty)throw const FormatException();
      final incoming=<String,dynamic>{};
      for(final e in obj.entries){final k=e.key;final v=e.value; if(k is! String||!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(k)||v is! Map)throw const FormatException(); final d=DateTime.tryParse(k);if(d==null||keyOf(d)!=k)throw const FormatException();final record=<String,List<String>>{};for(final meal in ['breakfast','dinner']){final x=v[meal];if(x is! List||x.any((s)=>s is! String||s.trim().isEmpty))throw const FormatException();record[meal]=x.cast<String>();}incoming[k]=record;}
      final prior=widget.prefs.getString('customMenus');final custom=<String,dynamic>{if(prior!=null)...validateMenus(jsonDecode(prior)),...incoming}; final ok=await widget.prefs.setString('customMenus',jsonEncode(custom)); if(!ok)throw StateError('save');if(!mounted)return;setState(() { data.addAll(incoming); customDates.addAll(incoming.keys); });await syncNative();toast('Menüler kaydedildi.');
    }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('JSON biçimi geçersiz veya kayıt başarısız.')));}
  }
  @override Widget build(BuildContext context) {
    final cs=Theme.of(context).colorScheme;
    final w=wide;
    return Scaffold(
      body: SafeArea(child: Row(children:[
        if(w) NavigationRail(selectedIndex:tab,onDestinationSelected:changeTab,labelType:NavigationRailLabelType.all,destinations:const [NavigationRailDestination(icon:Icon(Icons.restaurant_rounded),label:Text('Menü')),NavigationRailDestination(icon:Icon(Icons.calendar_month_outlined),label:Text('Takvim')),NavigationRailDestination(icon:Icon(Icons.settings_outlined),label:Text('Ayarlar'))]),
        Expanded(child: RefreshIndicator(
          onRefresh:()=>refresh(manual:true),
          child: SingleChildScrollView(key:ValueKey(tab),physics:const AlwaysScrollableScrollPhysics(),padding:EdgeInsets.fromLTRB(w?28:18,20,w?28:18,24),
            child: Center(child: ConstrainedBox(constraints:const BoxConstraints(maxWidth:1120),
              child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
                header(cs),const SizedBox(height:22),
                if(updateTag!=null)ListTile(leading:const Icon(Icons.system_update),title:Text('Yeni sürüm: $updateTag'),trailing:const Icon(Icons.open_in_new),onTap:()=>openExternal(releasesPage)),
                AnimatedSwitcher(duration:const Duration(milliseconds:220),child:Column(key:ValueKey(tab),crossAxisAlignment:CrossAxisAlignment.stretch,children:tab==0?menu(cs,w):[if(tab==1)calendar(cs)else settings(cs)])),
              ]),
            )),
          ),
        )),
      ])),
      bottomNavigationBar:w?null:NavigationBar(selectedIndex:tab,onDestinationSelected:changeTab,backgroundColor:cs.surface,indicatorColor:cs.secondaryContainer,destinations:const [NavigationDestination(icon:Icon(Icons.restaurant_outlined),selectedIcon:Icon(Icons.restaurant_rounded),label:'Menü'),NavigationDestination(icon:Icon(Icons.calendar_month_outlined),label:'Takvim'),NavigationDestination(icon:Icon(Icons.settings_outlined),label:'Ayarlar')]),
    );
  }
  Widget header(ColorScheme cs)=>Row(children:[Icon(Icons.school_outlined,size:39,color:cs.primary),const SizedBox(width:14),Container(height:38,width:1,color:cs.outline),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('ANKARA KYK',style:TextStyle(fontSize:12,letterSpacing:3,color:cs.primary)),const Text('Yurt Yemek Menüsü',style:TextStyle(fontSize:22,fontWeight:FontWeight.w700))])),IconButton(tooltip:'Bilgi',onPressed:()=>showAboutDialog(context:context,applicationName:'YurtMenü',applicationVersion:version,children:const [Text('Bağımsız, kişisel kullanım için açık kaynaklı menü uygulaması. Resmî GSB uygulaması değildir.')]),icon:Icon(Icons.info_outline,color:cs.primary))]);
  List<Widget> menu(ColorScheme cs,bool wide)=>[Row(children:[IconButton(tooltip:'Önceki ay',onPressed:()=>choose(DateTime(selected.year,selected.month-1,1)),icon:const Icon(Icons.chevron_left)),Expanded(child:Text('${months[selected.month-1]} ${selected.year}',textAlign:TextAlign.center,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w600))),IconButton(tooltip:'Sonraki ay',onPressed:()=>choose(DateTime(selected.year,selected.month+1,1)),icon:const Icon(Icons.chevron_right)),TextButton(onPressed:()=>choose(ankaraToday()),child:const Text('Bugün'))]),const SizedBox(height:10),SizedBox(height:88,child:LayoutBuilder(builder:(context,c){if(lastViewport!=c.maxWidth){lastViewport=c.maxWidth;WidgetsBinding.instance.addPostFrameCallback((_)=>centerDate());}return ListView.separated(padding:EdgeInsets.symmetric(horizontal:((c.maxWidth-66)/2).clamp(0.0,double.infinity).toDouble()),controller:datesController,scrollDirection:Axis.horizontal,itemCount:DateTime(selected.year,selected.month+1,0).day,separatorBuilder:(_,i)=>const SizedBox(width:10),itemBuilder:(_,i){final d=DateTime(selected.year,selected.month,i+1);final active=keyOf(d)==keyOf(selected);final today=keyOf(d)==keyOf(ankaraToday());return Semantics(selected:active,button:true,label:dateLabel(d),child:InkWell(borderRadius:BorderRadius.circular(19),onTap:()=>choose(d),child:AnimatedContainer(duration:const Duration(milliseconds:180),width:66,decoration:BoxDecoration(color:active?cs.primary:cs.surface,borderRadius:BorderRadius.circular(19),border:Border.all(color:active?cs.primary:cs.outline.withAlpha(100))),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text('${i+1}',style:TextStyle(fontSize:27,fontWeight:FontWeight.bold,color:active?cs.onPrimary:cs.onSurface)),Text(shortDays[d.weekday-1],style:TextStyle(color:active?cs.onPrimary:cs.onSurfaceVariant)),if(today)Text('Bugün',style:TextStyle(fontSize:10,color:active?cs.onPrimary:cs.primary))]))));});})),const SizedBox(height:18),if(!wide) ...[SegmentedButton<bool>(showSelectedIcon:false,segments:const [ButtonSegment(value:true,icon:Icon(Icons.coffee_outlined),label:Text('Kahvaltı')),ButtonSegment(value:false,icon:Icon(Icons.dinner_dining),label:Text('Akşam Yemeği'))],selected:{breakfast},onSelectionChanged:(s)=>setState(()=>breakfast=s.first),style:ButtonStyle(backgroundColor:WidgetStateProperty.resolveWith((s)=>s.contains(WidgetState.selected)?cs.primary:cs.surface),foregroundColor:WidgetStateProperty.resolveWith((s)=>s.contains(WidgetState.selected)?cs.onPrimary:cs.onSurface))),const SizedBox(height:18),swipeCard(AnimatedSwitcher(duration:const Duration(milliseconds:220),child:KeyedSubtree(key:ValueKey("${keyOf(selected)}-$breakfast"),child:mealCard(cs,breakfast))))] else swipeCard(AnimatedSwitcher(duration:const Duration(milliseconds:220),child:Row(key:ValueKey(keyOf(selected)),crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:mealCard(cs,true)),const SizedBox(width:18),Expanded(child:mealCard(cs,false))]))),const SizedBox(height:16),Text(refreshing?'Güncelleniyor…':customDates.contains(keyOf(selected))?'Yerel olarak eklenen menü.':(status.isNotEmpty&&keyOf(selected)==keyOf(ankaraToday()))?status:remoteDates.contains(keyOf(selected))?'Kepçe · Kayıtlı günlük menü.':data.containsKey(keyOf(selected))?'Arşiv kaydı · Canlı veri değil.':'Bu tarih için kayıt yok.',style:TextStyle(color:cs.onSurfaceVariant,fontSize:12),textAlign:TextAlign.center),TextButton(onPressed:()=>openExternal(sourcePage),child:const Text('Veri kaynağı: kepce.org ↗')),const SizedBox(height:6),Text('Menü yurda göre değişebilir.',style:TextStyle(color:cs.onSurfaceVariant,fontSize:12),textAlign:TextAlign.center)];
  Widget swipeCard(Widget child)=>GestureDetector(onHorizontalDragStart:(_)=>drag=0,onHorizontalDragUpdate:(d)=>drag+=d.delta.dx,onHorizontalDragEnd:(_){if(drag.abs()>45)choose(dayAdd(selected,drag<0?1:-1));drag=0;},child:child);
  Widget mealCard(ColorScheme cs,bool morning){final items=meals(morning);return Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:cs.surface,borderRadius:BorderRadius.circular(27),border:Border.all(color:cs.outline.withAlpha(130))),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[Icon(Icons.calendar_month_outlined,color:cs.primary,size:30),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(dateLabel(selected),style:const TextStyle(fontSize:17,fontWeight:FontWeight.w700)),const SizedBox(height:4),Text(morning?'Ankara KYK · Kahvaltı':'Ankara KYK · Akşam yemeği',style:TextStyle(color:cs.onSurfaceVariant))]))]),const SizedBox(height:12),Divider(color:cs.outline),if(items.isEmpty)Padding(padding:const EdgeInsets.symmetric(vertical:40),child:Column(children:[Icon(Icons.event_busy_outlined,color:cs.primary,size:40),const SizedBox(height:12),const Text('Bu öğün için menü bulunamadı.',textAlign:TextAlign.center),TextButton(onPressed:importMenus,child:const Text('Menü ekle'))])) else for(var i=0;i<items.length;i++)... [Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Row(children:[Container(width:44,height:44,alignment:Alignment.center,decoration:BoxDecoration(color:cs.secondaryContainer,shape:BoxShape.circle),child:Text(foodIcon(items[i],morning),style:const TextStyle(fontSize:23))),const SizedBox(width:14),Expanded(child:Text(items[i],style:const TextStyle(fontSize:17,fontWeight:FontWeight.w600))),IconButton(tooltip:'Favori',onPressed:()=>toggleFavorite(items[i]),icon:Icon(favorites.contains(normalized(items[i]))?Icons.favorite:Icons.favorite_border,size:19,color:cs.primary))])),if(i<items.length-1)Divider(height:9,indent:58,color:cs.outline.withAlpha(120))]]));}
  String foodIcon(String item,bool morning){final s=normalized(item);bool has(List<String> words)=>words.any(s.contains);if(has(['supangle','puding','sütlaç','muhallebi','tatlı','kazandibi','revani','baklava','helva']))return '🍮';if(has(['çorba']))return '🥣';if(has(['yumurta','omlet','menemen']))return '🍳';if(has(['börek','milföy','poğaça','kruvasan']))return '🥐';if(has(['peynir','labne']))return '🧀';if(has(['pilav','bulgur']))return '🍚';if(has(['makarna','erişte']))return '🍝';if(has(['tavuk']))return '🍗';if(has(['köfte','kebap','et sote']))return '🍖';if(has(['kızartma','kroket']))return '🍟';if(has(['meyve suyu','ayran','süt']))return '🥛';if(RegExp(r'^(\d+\s*(ml|l)\s*)?su$').hasMatch(s))return '💧';if(has(['ekmek','simit']))return '🥖';if(has(['zeytin']))return '🫒';if(has(['çay']))return '☕';if(has(['salata','domates','salatalık']))return '🥗';if(has(['meyve','elma','armut']))return '🍎';return morning?'🍽️':'🥘';}
  Widget calendar(ColorScheme cs){final first=DateTime(calendarMonth.year,calendarMonth.month);final days=DateTime(first.year,first.month+1,0).day;final offset=first.weekday-1;return Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:cs.surface,borderRadius:BorderRadius.circular(24)),child:Column(children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[IconButton(tooltip:'Önceki ay',onPressed:()=>setState(()=>calendarMonth=DateTime(first.year,first.month-1)),icon:const Icon(Icons.chevron_left)),Text('${months[first.month-1]} ${first.year}',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)),IconButton(tooltip:'Sonraki ay',onPressed:()=>setState(()=>calendarMonth=DateTime(first.year,first.month+1)),icon:const Icon(Icons.chevron_right))]),Row(children:[for(final d in shortDays)Expanded(child:Center(child:Text(d,style:TextStyle(color:cs.onSurfaceVariant))))]),const SizedBox(height:12),GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:((offset+days+6)~/7)*7,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:7,mainAxisSpacing:4,crossAxisSpacing:4,childAspectRatio:0.92),itemBuilder:(_,i){final n=i-offset+1;if(n<1||n>days)return const SizedBox();final d=DateTime(first.year,first.month,n);final active=keyOf(d)==keyOf(selected);return InkWell(borderRadius:BorderRadius.circular(12),onTap:()=>choose(d,goMenu:true),child:Container(decoration:BoxDecoration(color:active?cs.primary:cs.secondaryContainer,borderRadius:BorderRadius.circular(12)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text('$n',style:TextStyle(color:active?cs.onPrimary:cs.onSurface,fontWeight:FontWeight.bold)),if(data.containsKey(keyOf(d)))Icon(Icons.circle,size:6,color:active?cs.onPrimary:cs.primary)])));}),const SizedBox(height:12),const Text('Nokta: kayıtlı menü') ]));}
  Widget settings(ColorScheme cs)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    ListTile(title:const Text('Görünüm'),subtitle:const Text('Mevcut siyah ve sıcak bej palet'),trailing:DropdownButton<String>(value:widget.mode,items:const [DropdownMenuItem(value:'dark',child:Text('Koyu')),DropdownMenuItem(value:'light',child:Text('Açık')),DropdownMenuItem(value:'amoled',child:Text('AMOLED')),DropdownMenuItem(value:'system',child:Text('Sistem'))],onChanged:(v){if(v!=null)widget.onTheme(v); })),const Divider(),
    ListTile(leading:Icon(Icons.refresh,color:cs.primary),title:const Text('Menüyü yenile'),subtitle:Text(endpoint.isEmpty?'Canlı bağlantı kapalı':status.isEmpty?'Kepçe · Günlük menü':status),onTap:()=>refresh(manual:true)),
    SwitchListTile(title:const Text('Kepçe canlı menü'),subtitle:const Text('Yalnızca bugünün Ankara menüsü'),value:endpoint.isNotEmpty,onChanged:toggleKepce),
    ListTile(leading:Icon(Icons.open_in_new,color:cs.primary),title:const Text('Kaynak: kepce.org'),onTap:()=>openExternal(sourcePage)),
    ListTile(leading:Icon(Icons.file_download_outlined,color:cs.primary),title:const Text('Menü verisi ekle'),subtitle:const Text('JSON ile çevrimdışı güncelle'),onTap:importMenus),const Divider(),
    SwitchListTile(title:const Text('Kahvaltı bildirimi'),subtitle:Text(timeText(morningMinutes)),value:morningAlert,onChanged:(v){setState(()=>morningAlert=v);saveAlerts();}),ListTile(title:const Text('Kahvaltı saati'),trailing:Text(timeText(morningMinutes)),onTap:()=>pickTime(true)),
    SwitchListTile(title:const Text('Akşam yemeği bildirimi'),subtitle:Text(timeText(eveningMinutes)),value:eveningAlert,onChanged:(v){setState(()=>eveningAlert=v);saveAlerts();}),ListTile(title:const Text('Akşam saati'),trailing:Text(timeText(eveningMinutes)),onTap:()=>pickTime(false)),
    SwitchListTile(title:const Text('Favori yemek bildirimi'),subtitle:const Text('Kayıtlı menüde eşleşme varsa öğün saatinde'),value:favoriteAlert,onChanged:(v){setState(()=>favoriteAlert=v);saveAlerts();}),ListTile(leading:const Icon(Icons.favorite_outline),title:const Text('Favori ekle'),onTap:editFavorites),for(final f in favorites.toList()..sort())ListTile(title:Text(f),trailing:IconButton(tooltip:'Kaldır',onPressed:()=>toggleFavorite(f),icon:const Icon(Icons.close))),const Divider(),
    SwitchListTile(title:const Text('Açılışta sürüm kontrolü'),value:updateAlert,onChanged:(v){setState(()=>updateAlert=v);widget.prefs.setBool('updateAlert',v);}),ListTile(title:const Text('Güncellemeyi kontrol et'),onTap:()=>checkUpdate()),ListTile(title:const Text('GitHub sürümleri'),onTap:()=>openExternal(releasesPage)),const Divider(),
    const ListTile(leading:Icon(Icons.widgets_outlined),title:Text('Ana ekran widget’ı'),subtitle:Text('Android ana ekranına uzun bas → Widget’lar → YurtMenü. Kayıtlı menüyü gösterir.')),
    const ListTile(leading:Icon(Icons.location_on_outlined),title:Text('Ankara'),subtitle:Text('Tek şehir · Konum izni gerekmez')),const ListTile(leading:Icon(Icons.verified_user_outlined),title:Text('Gizlilik'),subtitle:Text('Reklam, üyelik, analitik yok. Favoriler cihazda saklanır.')),const ListTile(leading:Icon(Icons.info_outline),title:Text('Sürüm 0.2.1'),subtitle:Text('Bağımsız uygulama · Menü yurda göre değişebilir. Bildirim saatleri Android tarafından geciktirilebilir.'))]);
}

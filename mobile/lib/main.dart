import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/analysis/domain/analysis.dart';
import 'features/analysis/presentation/analysis_controller.dart';
import 'features/watchlist/watchlist.dart';

void main() => runApp(const ProviderScope(child: HustleApp()));
class HustleApp extends StatelessWidget {
  const HustleApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'Hustle', theme: ThemeData(
      brightness: Brightness.dark, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff31e981), brightness: Brightness.dark,
        surface: const Color(0xff111915)), scaffoldBackgroundColor: const Color(0xff080d0a)),
      useMaterial3: true, inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder())),
    home: const AppShell());
}
class AppShell extends StatefulWidget { const AppShell({super.key}); @override State<AppShell> createState() => _AppShellState(); }
class _AppShellState extends State<AppShell> {
  int index = 0;
  @override Widget build(BuildContext context) {
    final pages = [const HomeScreen(), const MarketsScreen(), const WatchlistScreen(), const ProfileScreen()];
    return Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: pages[index]))),
      bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (value) => setState(() => index = value), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Ana Sayfa'),
        NavigationDestination(icon: Icon(Icons.candlestick_chart_outlined), label: 'Piyasalar'),
        NavigationDestination(icon: Icon(Icons.star_outline), selectedIcon: Icon(Icons.star), label: 'Takip Listesi'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil')]));
  }
}
class HomeScreen extends ConsumerStatefulWidget { const HomeScreen({super.key}); @override ConsumerState<HomeScreen> createState() => _HomeScreenState(); }
class _HomeScreenState extends ConsumerState<HomeScreen> {
  final controller = TextEditingController(text: 'BTCUSDT'); String interval = '1h';
  @override void dispose() { controller.dispose(); super.dispose(); }
  void analyze() { final symbol = normalizeSymbol(controller.text); controller.text = symbol; if (symbol.isNotEmpty) ref.read(analysisProvider.notifier).analyze(symbol, interval); }
  @override Widget build(BuildContext context) {
    final result = ref.watch(analysisProvider);
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Row(children: [Logo(), SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('HUSTLE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)), Text('Akıllı piyasa sinyalleri')])]),
      const SizedBox(height: 24), const SectionTitle('Piyasa özeti'),
      const Card(child: Padding(padding: EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [MarketStat('Kripto', '7/24 Açık'), MarketStat('Kaynak', 'BINANCE'), MarketStat('Durum', 'Canlı')]))),
      const SizedBox(height: 20), TextField(key: const Key('symbolField'), controller: controller, textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(labelText: 'Varlık sembolü', hintText: 'Örn. BTCUSDT', prefixIcon: Icon(Icons.search))),
      const SizedBox(height: 12), Wrap(spacing: 8, children: ['15m','1h','4h','1d'].map((item) => ChoiceChip(label: Text(item), selected: interval == item, onSelected: (_) => setState(() => interval = item))).toList()),
      const SizedBox(height: 12), FilledButton.icon(key: const Key('analyzeButton'), onPressed: result.isLoading ? null : analyze, icon: const Icon(Icons.auto_graph), label: const Padding(padding: EdgeInsets.all(14), child: Text('Analiz et'))),
      const SizedBox(height: 14), Wrap(spacing: 8, children: ['BTCUSDT','ETHUSDT','SOLUSDT','BNBUSDT'].map((symbol) => ActionChip(label: Text(symbol), onPressed: () { controller.text = symbol; analyze(); })).toList()),
      const SizedBox(height: 22), result.when(
        loading: () => const Card(child: Padding(padding: EdgeInsets.all(28), child: Center(child: Column(children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Piyasa analiz ediliyor…')])))),
        error: (error, _) => ErrorCard(message: error.toString(), retry: analyze),
        data: (analysis) => analysis == null ? const EmptyCard() : SignalCard(analysis: analysis, refresh: analyze)),
    ]);
  }
}
class Logo extends StatelessWidget { const Logo({super.key}); @override Widget build(BuildContext context) => Container(width: 50, height: 50, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.trending_up, color: Colors.black, size: 32)); }
class SectionTitle extends StatelessWidget { const SectionTitle(this.text, {super.key}); final String text; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: Theme.of(context).textTheme.titleLarge)); }
class MarketStat extends StatelessWidget { const MarketStat(this.label,this.value,{super.key}); final String label,value; @override Widget build(BuildContext context) => Column(children:[Text(value, style: const TextStyle(color: Color(0xff31e981), fontWeight: FontWeight.bold)),Text(label, style: Theme.of(context).textTheme.bodySmall)]); }
class EmptyCard extends StatelessWidget { const EmptyCard({super.key}); @override Widget build(BuildContext context) => const Card(child: Padding(padding: EdgeInsets.all(24), child: Column(children:[Icon(Icons.query_stats,size:42),SizedBox(height:10),Text('Henüz analiz yok'),Text('Bir sembol seçip “Analiz et” düğmesine dokunun.', textAlign: TextAlign.center)]))); }
class ErrorCard extends StatelessWidget { const ErrorCard({required this.message,required this.retry,super.key}); final String message; final VoidCallback retry; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children:[const Icon(Icons.cloud_off,size:42,color:Colors.orange),const Text('Analiz alınamadı',style:TextStyle(fontWeight:FontWeight.bold)),Text(message,textAlign:TextAlign.center),TextButton.icon(onPressed:retry,icon:const Icon(Icons.refresh),label:const Text('Yeniden dene'))]))); }
class SignalCard extends StatelessWidget {
  const SignalCard({required this.analysis,required this.refresh,super.key}); final Analysis analysis; final VoidCallback refresh;
  String get action => switch(analysis.action){SignalAction.safeBuy=>'GÜVENLİ AL',SignalAction.takeProfit=>'KÂR AL',SignalAction.hold=>'BEKLE',SignalAction.unknown=>'BİLİNMİYOR'};
  Color color(BuildContext context) => switch(analysis.action){SignalAction.safeBuy=>const Color(0xff31e981),SignalAction.takeProfit=>Colors.orangeAccent,SignalAction.hold=>Colors.lightBlueAccent,SignalAction.unknown=>Colors.grey};
  @override Widget build(BuildContext context) => Card(key: const Key('signalCard'), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${analysis.symbol} • ${analysis.timeframe}'),Text('\$${analysis.price.toStringAsFixed(2)}',style:Theme.of(context).textTheme.headlineMedium)])),Chip(label:Text(action),backgroundColor:color(context).withValues(alpha:.18),labelStyle:TextStyle(color:color(context),fontWeight:FontWeight.bold))]),
    const Divider(),Text('Güven skoru: ${(analysis.confidence*100).toStringAsFixed(0)}%'),LinearProgressIndicator(value:analysis.confidence,color:color(context)),const SizedBox(height:16),const Text('Analiz nedenleri',style:TextStyle(fontWeight:FontWeight.bold)),
    ...analysis.reasons.map((reason)=>ListTile(contentPadding:EdgeInsets.zero,dense:true,leading:Icon(Icons.check_circle_outline,color:color(context)),title:Text(reason))),
    Text('Son güncelleme: ${analysis.signalTime?.toLocal().toString().split('.').first ?? 'Bilinmiyor'}',style:Theme.of(context).textTheme.bodySmall),Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:refresh,icon:const Icon(Icons.refresh),label:const Text('Yenile')))])));
}
class MarketsScreen extends StatelessWidget { const MarketsScreen({super.key}); @override Widget build(BuildContext context) => ListView(padding:const EdgeInsets.all(20),children:[const SectionTitle('Piyasalar'),const Text('Hızlı piyasa erişimi'),...['BTCUSDT','ETHUSDT','SOLUSDT','BNBUSDT'].map((s)=>Card(child:ListTile(leading:const Icon(Icons.currency_bitcoin),title:Text(s),subtitle:const Text('BINANCE • 7/24'),trailing:const Icon(Icons.chevron_right))))]); }
class WatchlistScreen extends ConsumerWidget { const WatchlistScreen({super.key}); @override Widget build(BuildContext context,WidgetRef ref){final items=ref.watch(watchlistProvider);final input=TextEditingController();return ListView(padding:const EdgeInsets.all(20),children:[const SectionTitle('Takip Listesi'),Row(children:[Expanded(child:TextField(controller:input,decoration:const InputDecoration(labelText:'Sembol ekle'))),const SizedBox(width:8),IconButton.filled(tooltip:'Takibe ekle',onPressed:()=>ref.read(watchlistProvider.notifier).add(input.text),icon:const Icon(Icons.add))]),if(items.isEmpty)const Padding(padding:EdgeInsets.all(32),child:Column(children:[Icon(Icons.star_border,size:48),Text('Takip listeniz boş'),Text('İzlemek istediğiniz sembolleri ekleyin.')])) else ...items.map((s)=>Card(child:ListTile(title:Text(s),leading:const Icon(Icons.star,color:Color(0xff31e981)),trailing:IconButton(tooltip:'Takipten kaldır',onPressed:()=>ref.read(watchlistProvider.notifier).remove(s),icon:const Icon(Icons.delete_outline)))))]);}}
class ProfileScreen extends StatelessWidget { const ProfileScreen({super.key}); @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(20),children:const [SectionTitle('Profil'),Card(child:ListTile(leading:CircleAvatar(child:Icon(Icons.person)),title:Text('Hustle kullanıcısı'),subtitle:Text('Veriler yalnızca bu cihazda saklanır.'))),Card(child:Padding(padding:EdgeInsets.all(18),child:Text('Hustle eğitim ve paper-trading amaçlıdır. Buradaki sinyaller yatırım tavsiyesi değildir.')))]);}

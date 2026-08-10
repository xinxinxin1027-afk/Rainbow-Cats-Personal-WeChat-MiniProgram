import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const pink = Color(0xffff99aa);
const bg = Color(0xfff6f6f6);

void main() => runApp(const RainbowCatsApp());

class RainbowCatsApp extends StatefulWidget {
  const RainbowCatsApp({super.key});
  @override State<RainbowCatsApp> createState() => _RainbowCatsAppState();
}

class _RainbowCatsAppState extends State<RainbowCatsApp> {
  final store = AppStore();
  @override void initState() { super.initState(); store.load(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (_, __) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rainbow Cats',
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: bg,
        primaryColor: pink,
        appBarTheme: const AppBarTheme(backgroundColor: pink, foregroundColor: Colors.black, elevation: 0, centerTitle: true),
        cardTheme: CardThemeData(color: Colors.white, elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
      ),
      home: Shell(store: store),
    ),
  );
}

class User { User(this.id, this.name, this.credit); String id, name; int credit;
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'credit':credit};
  factory User.fromJson(Map<String,dynamic> j)=>User(j['id'],j['name'],j['credit']??0); }
class Mission { Mission(this.id,this.owner,this.title,this.note,this.points,{this.done=false,this.star=false}); String id,owner,title,note; int points; bool done,star;
  Map<String,dynamic> toJson()=>{'id':id,'owner':owner,'title':title,'note':note,'points':points,'done':done,'star':star};
  factory Mission.fromJson(Map<String,dynamic> j)=>Mission(j['id'],j['owner'],j['title'],j['note']??'',j['points']??0,done:j['done']??false,star:j['star']??false); }
class Reward { Reward(this.id,this.owner,this.title,this.note,this.cost,{this.available=true}); String id,owner,title,note; int cost; bool available;
  Map<String,dynamic> toJson()=>{'id':id,'owner':owner,'title':title,'note':note,'cost':cost,'available':available};
  factory Reward.fromJson(Map<String,dynamic> j)=>Reward(j['id'],j['owner'],j['title'],j['note']??'',j['cost']??0,available:j['available']??true); }
class Item { Item(this.id,this.owner,this.title,this.note,this.cost,{this.used=false}); String id,owner,title,note; int cost; bool used;
  Map<String,dynamic> toJson()=>{'id':id,'owner':owner,'title':title,'note':note,'cost':cost,'used':used};
  factory Item.fromJson(Map<String,dynamic> j)=>Item(j['id'],j['owner'],j['title'],j['note']??'',j['cost']??0,used:j['used']??false); }

class AppStore extends ChangeNotifier {
  List<User> users=[User('a','卡比',100),User('b','瓦豆',100)];
  List<Mission> missions=[Mission('m1','a','背 30 个单词','完成后记得打卡',20),Mission('m2','b','一起散步','晚饭后 30 分钟',15)];
  List<Reward> rewards=[Reward('r1','a','奶茶券','兑换一杯喜欢的奶茶',30),Reward('r2','b','按摩券','20 分钟肩颈按摩',40)];
  List<Item> items=[]; String current='a'; bool ready=false;
  User get me=>users.firstWhere((u)=>u.id==current); User get other=>users.firstWhere((u)=>u.id!=current);
  Future<void> load() async { final p=await SharedPreferences.getInstance(); final raw=p.getString('rainbow.v1'); if(raw!=null){try{final j=jsonDecode(raw); current=j['current']??'a'; users=(j['users'] as List).map((e)=>User.fromJson(Map<String,dynamic>.from(e))).toList(); missions=(j['missions'] as List).map((e)=>Mission.fromJson(Map<String,dynamic>.from(e))).toList(); rewards=(j['rewards'] as List).map((e)=>Reward.fromJson(Map<String,dynamic>.from(e))).toList(); items=(j['items'] as List).map((e)=>Item.fromJson(Map<String,dynamic>.from(e))).toList();}catch(_){}} ready=true; notifyListeners(); }
  Future<void> save() async { final p=await SharedPreferences.getInstance(); await p.setString('rainbow.v1',jsonEncode({'current':current,'users':users.map((e)=>e.toJson()).toList(),'missions':missions.map((e)=>e.toJson()).toList(),'rewards':rewards.map((e)=>e.toJson()).toList(),'items':items.map((e)=>e.toJson()).toList()})); }
  void touch(){save();notifyListeners();}
  void switchUser(){current=current=='a'?'b':'a';touch();}
  void addMission(String t,String n,int p){missions.insert(0,Mission(DateTime.now().microsecondsSinceEpoch.toString(),current,t,n,p));touch();}
  String finish(Mission m){if(m.done)return '任务已经完成'; if(m.owner==current)return '只能完成对方发布的任务'; m.done=true; users.firstWhere((u)=>u.id==m.owner).credit+=m.points; touch(); return '任务完成 +${m.points}';}
  void removeMission(Mission m){missions.remove(m);touch();}
  void addReward(String t,String n,int c){rewards.insert(0,Reward(DateTime.now().microsecondsSinceEpoch.toString(),current,t,n,c));touch();}
  String buy(Reward r){if(!r.available)return '商品已兑换'; if(r.owner==current)return '不能购买自己发布的商品'; if(me.credit<r.cost)return '积分不足'; me.credit-=r.cost; r.available=false; items.insert(0,Item(DateTime.now().microsecondsSinceEpoch.toString(),current,r.title,r.note,r.cost));touch();return '兑换成功';}
  String use(Item i){if(i.used)return '已经使用过了'; i.used=true;touch();return '使用成功';}
}

class Shell extends StatefulWidget { const Shell({super.key,required this.store}); final AppStore store; @override State<Shell> createState()=>_ShellState(); }
class _ShellState extends State<Shell>{int index=0; @override Widget build(BuildContext c){final s=widget.store;if(!s.ready)return const Scaffold(body:Center(child:CircularProgressIndicator(color:pink))); final pages=[HomePage(s),MissionPage(s),MarketPage(s),AccountPage(s)]; return Scaffold(
  body:pages[index], bottomNavigationBar:BottomNavigationBar(currentIndex:index,onTap:(v)=>setState(()=>index=v),selectedItemColor:pink,unselectedItemColor:Colors.grey,type:BottomNavigationBarType.fixed,items:List.generate(4,(i){const labels=['首页','任务','商城','仓库']; const icons=['home','mission','market','account']; final path='assets/original/tab_${icons[i]}_${index==i?'selected':'normal'}.jpg'; return BottomNavigationBarItem(icon:Image.asset(path,width:26,height:26,errorBuilder:(_,__,___)=>Icon([Icons.home,Icons.check_circle,Icons.store,Icons.inventory_2][i])),label:labels[i]);})),
 );}}

PreferredSizeWidget top(AppStore s,String title)=>AppBar(title:Text(title),actions:[Padding(padding:const EdgeInsets.only(right:10),child:Center(child:InkWell(onTap:s.switchUser,borderRadius:BorderRadius.circular(22),child:Container(padding:const EdgeInsets.symmetric(horizontal:13,vertical:7),decoration:BoxDecoration(color:Colors.white.withOpacity(.82),borderRadius:BorderRadius.circular(22)),child:Text('${s.me.name} · ${s.me.credit}♥',style:const TextStyle(fontWeight:FontWeight.w600))))))]);
Widget section(String title,Widget child)=>Padding(padding:const EdgeInsets.fromLTRB(16,16,16,0),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:8),child]));
void toast(BuildContext c,String m)=>ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(m)));

class HomePage extends StatelessWidget{const HomePage(this.s,{super.key});final AppStore s;@override Widget build(BuildContext c)=>Scaffold(appBar:top(s,'卡比们的任务'),body:ListView(children:[
  Padding(padding:const EdgeInsets.all(16),child:ClipRRect(borderRadius:BorderRadius.circular(20),child:AspectRatio(aspectRatio:2.15,child:Image.asset('assets/original/home_0.jpg',fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(color:const Color(0xffffd7df),child:const Center(child:Text('Rainbow Cats',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold,color:pink)))))))),
  section('今日状态',Row(children:[Expanded(child:MiniStat(name:s.me.name,value:'${s.me.credit}',caption:'我的积分')),const SizedBox(width:12),Expanded(child:MiniStat(name:s.other.name,value:'${s.other.credit}',caption:'TA 的积分'))])),
  section('待完成任务',Column(children:s.missions.where((m)=>!m.done).take(3).map((m)=>MissionCard(s,m)).toList())),const SizedBox(height:24)]));}
class MiniStat extends StatelessWidget{const MiniStat({super.key,required this.name,required this.value,required this.caption});final String name,value,caption;@override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[Text(name),const SizedBox(height:8),Text('$value ♥',style:const TextStyle(color:pink,fontSize:24,fontWeight:FontWeight.bold)),Text(caption,style:const TextStyle(color:Colors.grey))]))));}

class MissionPage extends StatelessWidget{const MissionPage(this.s,{super.key});final AppStore s;@override Widget build(BuildContext c)=>Scaffold(appBar:top(s,'任务'),floatingActionButton:FloatingActionButton(backgroundColor:pink,onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>MissionEditor(s))),child:const Icon(Icons.add)),body:ListView(padding:const EdgeInsets.only(bottom:96),children:[section('未完成',Column(children:s.missions.where((m)=>!m.done).map((m)=>MissionCard(s,m)).toList())),section('已完成',Column(children:s.missions.where((m)=>m.done).map((m)=>MissionCard(s,m)).toList()))]));}
class MissionCard extends StatelessWidget{const MissionCard(this.s,this.m,{super.key});final AppStore s;final Mission m;@override Widget build(BuildContext c)=>Card(child:ListTile(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>MissionDetail(s,m))),contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:8),title:Text(m.title,style:TextStyle(fontWeight:FontWeight.bold,decoration:m.done?TextDecoration.lineThrough:null)),subtitle:Text('${s.users.firstWhere((u)=>u.id==m.owner).name} · ${m.note}',maxLines:2,overflow:TextOverflow.ellipsis),leading:IconButton(icon:Icon(m.star?Icons.star:Icons.star_border,color:pink),onPressed:(){m.star=!m.star;s.touch();}),trailing:Text('${m.points}♥',style:const TextStyle(color:pink,fontWeight:FontWeight.bold))));}
class MissionEditor extends StatefulWidget{const MissionEditor(this.s,{super.key});final AppStore s;@override State<MissionEditor>createState()=>_MissionEditorState();}
class _MissionEditorState extends State<MissionEditor>{final t=TextEditingController(),n=TextEditingController();double p=20;@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('发布任务')),body:ListView(padding:const EdgeInsets.all(16),children:[TextField(controller:t,decoration:const InputDecoration(labelText:'任务名称')),const SizedBox(height:12),TextField(controller:n,maxLines:4,decoration:const InputDecoration(labelText:'任务说明')),const SizedBox(height:18),Text('积分：${p.round()}♥'),Slider(value:p,min:5,max:100,divisions:19,activeColor:pink,onChanged:(v)=>setState(()=>p=v)),FilledButton(style:FilledButton.styleFrom(backgroundColor:pink),onPressed:(){if(t.text.trim().isEmpty)return;widget.s.addMission(t.text.trim(),n.text.trim(),p.round());Navigator.pop(c);},child:const Text('发布'))]));}
class MissionDetail extends StatelessWidget{const MissionDetail(this.s,this.m,{super.key});final AppStore s;final Mission m;@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('任务详情')),body:ListView(padding:const EdgeInsets.all(16),children:[DetailCard(title:m.title,note:m.note,points:m.points),const SizedBox(height:12),FilledButton(style:FilledButton.styleFrom(backgroundColor:pink),onPressed:m.done?null:()=>toast(c,s.finish(m)),child:Text(m.done?'已完成':'完成任务')),TextButton(onPressed:(){s.removeMission(m);Navigator.pop(c);},child:const Text('删除任务'))]));}

class MarketPage extends StatelessWidget{const MarketPage(this.s,{super.key});final AppStore s;@override Widget build(BuildContext c)=>Scaffold(appBar:top(s,'商城'),floatingActionButton:FloatingActionButton(backgroundColor:pink,onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>RewardEditor(s))),child:const Icon(Icons.add)),body:ListView(padding:const EdgeInsets.fromLTRB(16,16,16,96),children:s.rewards.map((r)=>Card(child:ListTile(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>RewardDetail(s,r))),contentPadding:const EdgeInsets.all(14),leading:CircleAvatar(backgroundColor:const Color(0xffffe5ea),child:Text('${r.cost}♥',style:const TextStyle(color:pink,fontWeight:FontWeight.bold)),title:Text(r.title,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${s.users.firstWhere((u)=>u.id==r.owner).name} · ${r.note}',maxLines:2),trailing:Icon(r.available?Icons.chevron_right:Icons.check,color:r.available?Colors.grey:pink)))).toList()));}
class RewardEditor extends StatefulWidget{const RewardEditor(this.s,{super.key});final AppStore s;@override State<RewardEditor>createState()=>_RewardEditorState();}
class _RewardEditorState extends State<RewardEditor>{final t=TextEditingController(),n=TextEditingController();double p=30;@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('上架商品')),body:ListView(padding:const EdgeInsets.all(16),children:[TextField(controller:t,decoration:const InputDecoration(labelText:'商品名称')),const SizedBox(height:12),TextField(controller:n,maxLines:4,decoration:const InputDecoration(labelText:'商品说明')),const SizedBox(height:18),Text('价格：${p.round()}♥'),Slider(value:p,min:5,max:200,divisions:39,activeColor:pink,onChanged:(v)=>setState(()=>p=v)),FilledButton(style:FilledButton.styleFrom(backgroundColor:pink),onPressed:(){if(t.text.trim().isEmpty)return;widget.s.addReward(t.text.trim(),n.text.trim(),p.round());Navigator.pop(c);},child:const Text('上架'))]));}
class RewardDetail extends StatelessWidget{const RewardDetail(this.s,this.r,{super.key});final AppStore s;final Reward r;@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('商品详情')),body:ListView(padding:const EdgeInsets.all(16),children:[DetailCard(title:r.title,note:r.note,points:r.cost),const SizedBox(height:12),FilledButton(style:FilledButton.styleFrom(backgroundColor:pink),onPressed:r.available?()=>toast(c,s.buy(r)):null,child:Text(r.available?'立即兑换':'已兑换'))]));}

class AccountPage extends StatelessWidget{const AccountPage(this.s,{super.key});final AppStore s;@override Widget build(BuildContext c)=>Scaffold(appBar:top(s,'仓库'),body:ListView(children:[section('我的账户',Card(child:ListTile(contentPadding:const EdgeInsets.all(18),leading:const CircleAvatar(radius:28,backgroundColor:Color(0xffffd7df),child:Icon(Icons.favorite,color:pink)),title:Text(s.me.name,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),subtitle:Text('当前积分 ${s.me.credit}♥\n点击右上角可切换身份')))),section('未使用',Column(children:s.items.where((i)=>i.owner==s.current&&!i.used).map((i)=>ItemCard(s,i)).toList())),section('使用记录',Column(children:s.items.where((i)=>i.owner==s.current&&i.used).map((i)=>ItemCard(s,i)).toList())),const SizedBox(height:24)]));}
class ItemCard extends StatelessWidget{const ItemCard(this.s,this.i,{super.key});final AppStore s;final Item i;@override Widget build(BuildContext c)=>Card(child:ListTile(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>ItemDetail(s,i))),leading:Icon(i.used?Icons.check_circle:Icons.redeem,color:pink),title:Text(i.title,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(i.note),trailing:const Icon(Icons.chevron_right))));}
class ItemDetail extends StatelessWidget{const ItemDetail(this.s,this.i,{super.key});final AppStore s;final Item i;@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('物品详情')),body:ListView(padding:const EdgeInsets.all(16),children:[DetailCard(title:i.title,note:i.note,points:i.cost),const SizedBox(height:12),FilledButton(style:FilledButton.styleFrom(backgroundColor:pink),onPressed:i.used?null:()=>toast(c,s.use(i)),child:Text(i.used?'已使用':'使用物品'))]));}
class DetailCard extends StatelessWidget{const DetailCard({super.key,required this.title,required this.note,required this.points});final String title,note;final int points;@override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:12),Text(note.isEmpty?'暂无说明':note,style:const TextStyle(height:1.6)),const SizedBox(height:18),Text('$points ♥',style:const TextStyle(color:pink,fontSize:24,fontWeight:FontWeight.bold))])));}

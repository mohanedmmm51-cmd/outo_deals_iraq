import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

void main()=>runApp(const App());

const yellow=Color(0xFFFFD400);
String money(int n)=>n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'),(m)=>'${m[1]},');

class Tire{
  final String size;final int wholesale;
  const Tire(this.size,this.wholesale);
  int get profit=>wholesale<150000?10000:wholesale<200000?12000:15000;
  int get commission=>wholesale<100000?3000:wholesale<150000?4000:5000;
  int get price=>wholesale+profit+commission;
}
const tires=[
Tire('500/12',67320),Tire('550/12',104040),Tire('550/13',87210),
Tire('165/65/13',73440),Tire('175/70/13',73440),Tire('175/70/14',68850),
Tire('185/65/14',76500),Tire('185/70/14',87210),Tire('195/70/14',88740),
Tire('195/14',126990),Tire('185/14',104040),Tire('205/75/14 خط',119340),
Tire('195/65/15',84150),Tire('195/65/15 كومفورس',91800),Tire('195/65/15 هلو',96390),
Tire('205/65/15',104040),Tire('205/70/15',99450),Tire('205/70/15 خط',114750),
Tire('215/75/15',114750),Tire('195/55/15',81090),Tire('195/60/15',81090),
Tire('185/65/15',81090),Tire('185/55/15',81090),Tire('195/15',128520),
Tire('195/55/16',91800),Tire('205/55/16 كومفورس',102510),Tire('205/55/16 هلو',111690),
Tire('205/55/16',99450),Tire('215/60/16',110160)
];

class Battery{
  final String brand,amp;final int wholesale;
  const Battery(this.brand,this.amp,this.wholesale);
  int get withOld=>wholesale+3000;
  int get withoutOld=>wholesale+10000+3000;
}
const batteries=[
Battery('انجيكو كوري','43 مربع',61200),Battery('انجيكو كوري','62',76500),
Battery('انجيكو كوري','70 عالي',84150),Battery('انجيكو كوري','74',87210),
Battery('انجيكو كوري','80 ناصي',107100),Battery('انجيكو كوري','88',107100),
Battery('انجيكو كوري','90',99450),Battery('انجيكو كوري','100 مستطيل',114750),
Battery('انجيكو كوري','150',175950),Battery('ماليزي','62',61200),
Battery('ماليزي','70 عالي',68850),Battery('ماليزي','74',76500),
Battery('ماليزي','80',81090),Battery('ماليزي','88',81090),
Battery('ماليزي','90',81090),Battery('ماليزي','100 مستطيل',84150),
Battery('ماليزي','100 مربع',111690),Battery('ماليزي','150',134640),
Battery('زكستور عراقي','62',44370),Battery('زكستور عراقي','70',58140),
Battery('زكستور عراقي','74',58140)
];

class Api{
  static const base='https://api.vehdb.com/v1';
  Future<dynamic> get(String path,String token)async{
    if(token.trim().isEmpty)throw Exception('أدخل API Token من زر المفتاح.');
    final c=HttpClient();
    try{
      final r=await c.getUrl(Uri.parse('$base$path'));
      r.headers.set(HttpHeaders.authorizationHeader,'Bearer ${token.trim()}');
      r.headers.set(HttpHeaders.acceptHeader,'application/json');
      final res=await r.close(),body=await res.transform(utf8.decoder).join();
      if(res.statusCode<200||res.statusCode>=300)throw Exception('VehDB HTTP ${res.statusCode}');
      return jsonDecode(body);
    }finally{c.close(force:true);}
  }
  List<String> strings(dynamic j){
    final d=j is Map?j['data']:null;if(d is! List)return[];
    return d.map<String?>((e){
      if(e is String)return e;
      if(e is Map)return '${e['make']??e['model']??e['name']??e['value']}';
      return null;
    }).whereType<String>().where((e)=>e!='null'&&e.isNotEmpty).toSet().toList();
  }
  Future<List<String>> makes(String t)=>get('/tire-sizes/makes',t).then(strings);
  Future<List<String>> models(String t,String m)=>get('/tire-sizes/models?make=${Uri.encodeQueryComponent(m)}',t).then(strings);
  Future<List<Car>> cars(String t,String m,String mo,int y)async{
    final j=await get('/cars?make=${Uri.encodeQueryComponent(m)}&model=${Uri.encodeQueryComponent(mo)}&year=$y',t);
    final d=j is Map?j['data']:null;if(d is! List)return[];
    return d.whereType<Map>().map((e)=>Car.from(e)).toList();
  }
  Future<List<String>> sizes(String t,String id)async{
    final j=await get('/cars/$id/tire-sizes',t),out=<String>{};
    final d=j is Map?j['data']:null;if(d is! List)return[];
    for(final e in d.whereType<Map>()){
      final o='${e['tire_size_oem']??''}'.trim();if(o.isNotEmpty)out.add(o);
      final a=e['alternate_tire_sizes'];
      if(a is String)for(final s in a.split(',')){if(s.trim().isNotEmpty)out.add(s.trim());}
      if(a is List)for(final s in a){if('$s'.trim().isNotEmpty)out.add('$s'.trim());}
    }
    return out.toList();
  }
}
class Car{
  final String id,make,model,trim;final int year;
  const Car(this.id,this.make,this.model,this.year,this.trim);
  factory Car.from(Map e)=>Car('${e['uuid']??''}','${e['make']??''}','${e['model']??''}',(e['year']as num?)?.toInt()??0,'${e['trim']??''}');
}

class App extends StatelessWidget{
  const App({super.key});
  Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'إطارات وبطاريات العراق',
    theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:yellow)),home:const Home());
}

class Home extends StatelessWidget{
  const Home({super.key});
  Widget build(BuildContext c)=>Scaffold(
    backgroundColor:const Color(0xfff5f5f5),
    bottomNavigationBar:BottomNavigationBar(currentIndex:0,type:BottomNavigationBarType.fixed,backgroundColor:Color(0xff111111),selectedItemColor:yellow,unselectedItemColor:Colors.white70,
      items:[BottomNavigationBarItem(icon:Icon(Icons.home),label:'الرئيسية'),BottomNavigationBarItem(icon:Icon(Icons.store),label:'المحلات'),BottomNavigationBarItem(icon:Icon(Icons.shopping_cart),label:'السلة'),BottomNavigationBarItem(icon:Icon(Icons.receipt_long),label:'طلباتي'),BottomNavigationBarItem(icon:Icon(Icons.person),label:'حسابي')]),
    body:SafeArea(child:Directionality(textDirection:TextDirection.rtl,child:ListView(children:[
      Container(padding:const EdgeInsets.fromLTRB(18,18,18,25),decoration:const BoxDecoration(color:Color(0xff101010),borderRadius:BorderRadius.vertical(bottom:Radius.circular(30))),child:const Column(children:[
        Row(children:[Icon(Icons.menu,color:Colors.white,size:30),Spacer(),Column(children:[Text('إطارات وبطاريات العراق',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold)),Text('الجودة .. بأقرب محل',style:TextStyle(color:Colors.white70))]),Spacer(),Icon(Icons.notifications_none,color:Colors.white,size:30)]),
        SizedBox(height:22),DecoratedBox(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.all(Radius.circular(16))),child:SizedBox(height:54,child:Row(children:[SizedBox(width:16),Icon(Icons.search,size:30),SizedBox(width:10),Text('شنو تحتاج؟ إطارات أو بطاريات...',style:TextStyle(color:Colors.grey,fontSize:16))])))
      ])),
      Padding(padding:const EdgeInsets.all(16),child:Column(children:[
        button(c,Icons.directions_car,'اختار سيارتك','اعرف قياس الإطار المناسب لسيارتك',yellow,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const CarsPage()))),
        const SizedBox(height:14),
        Row(children:[
          Expanded(child:cat(c,Icons.tire_repair,'الإطارات',()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const TiresPage())))),
          const SizedBox(width:12),
          Expanded(child:cat(c,Icons.battery_charging_full,'البطاريات',()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const BatteriesPage()))))
        ]),
        const SizedBox(height:14),button(c,Icons.location_on,'المحلات القريبة','اعثر على أقرب محل معتمد',Colors.white,()=>{})
      ]))
    ])))
  );
  static Widget button(BuildContext c,IconData i,String t,String s,Color col,VoidCallback f)=>InkWell(onTap:f,borderRadius:BorderRadius.circular(20),child:Container(width:double.infinity,padding:const EdgeInsets.all(19),decoration:BoxDecoration(color:col,borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.black12)),child:Row(children:[Icon(i,size:45,color:Colors.black),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t,style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold)),Text(s)])),const Icon(Icons.arrow_back_ios_new,size:18)])));
  static Widget cat(BuildContext c,IconData i,String t,VoidCallback f)=>InkWell(onTap:f,borderRadius:BorderRadius.circular(20),child:Container(height:140,decoration:BoxDecoration(color:const Color(0xff171717),borderRadius:BorderRadius.circular(20)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(i,color:yellow,size:52),const SizedBox(height:10),Text(t,style:const TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.bold))])));
}


class CarsPage extends StatefulWidget {
  const CarsPage({super.key});

  @override
  State<CarsPage> createState() => _CarsPageState();
}

class _CarsPageState extends State<CarsPage> {
  final Api api = Api();
  final TextEditingController token = TextEditingController();

  String? make;
  String? model;
  int? year;

  List<String> makes = [];
  List<String> models = [];
  List<Car> cars = [];

  bool busy = false;
  String? err;

  @override
  void dispose() {
    token.dispose();
    super.dispose();
  }

  void tokenDialog() {
    final controller = TextEditingController(text: token.text);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('VehDB API'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Token',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                token.text = controller.text.trim();
                Navigator.pop(context);
                loadMakes();
              },
              child: const Text('حفظ وتجربة'),
            ),
          ],
        );
      },
    );
  }

  Future<void> loadMakes() async {
    setState(() {
      busy = true;
      err = null;
    });

    try {
      final result = await api.makes(token.text);
      setState(() {
        makes = result;
      });
    } catch (e) {
      setState(() {
        err = '$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Future<void> loadModels(String value) async {
    setState(() {
      make = value;
      model = null;
      models = [];
      cars = [];
      busy = true;
      err = null;
    });

    try {
      final result = await api.models(token.text, value);
      setState(() {
        models = result;
      });
    } catch (e) {
      setState(() {
        err = '$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Future<void> searchCars() async {
    if (make == null || model == null || year == null) return;

    setState(() {
      busy = true;
      err = null;
      cars = [];
    });

    try {
      final result = await api.cars(
        token.text,
        make!,
        model!,
        year!,
      );

      setState(() {
        cars = result;
      });
    } catch (e) {
      setState(() {
        err = '$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  InputDecoration fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(
      30,
      (index) => 2026 - index,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختار سيارتك'),
        actions: [
          IconButton(
            onPressed: tokenDialog,
            icon: const Icon(Icons.key),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Icon(
              Icons.directions_car,
              size: 80,
              color: yellow,
            ),
            const SizedBox(height: 8),
            const Text(
              'اختار سيارتك حتى نطلع القياس المناسب',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: busy ? null : tokenDialog,
              icon: const Icon(Icons.key),
              label: Text(
                makes.isEmpty
                    ? 'إدخال API Token'
                    : 'تغيير API Token',
              ),
            ),
            if (makes.isNotEmpty) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: make,
                isExpanded: true,
                decoration: fieldDecoration('الشركة'),
                items: makes
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    loadModels(value);
                  }
                },
              ),
            ],
            if (models.isNotEmpty) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: model,
                isExpanded: true,
                decoration: fieldDecoration('الموديل'),
                items: models
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    model = value;
                    cars = [];
                  });
                },
              ),
            ],
            if (model != null) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: year,
                isExpanded: true,
                decoration: fieldDecoration('السنة'),
                items: years
                    .map(
                      (item) => DropdownMenuItem<int>(
                        value: item,
                        child: Text('$item'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    year = value;
                    cars = [];
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
            if (make != null && model != null && year != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: yellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: busy ? null : searchCars,
                child: const Text(
                  'بحث عن السيارة والفئة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            if (err != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text('خطأ: $err'),
                ),
              ),
            ...cars.map(
              (car) {
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.directions_car),
                    ),
                    title: Text(
                      car.trim.isEmpty
                          ? '${car.make} ${car.model}'
                          : car.trim,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${car.make} ${car.model} • ${car.year}',
                    ),
                    trailing: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                    ),
                    onTap: () async {
                      setState(() {
                        busy = true;
                        err = null;
                      });

                      try {
                        final sizes = await api.sizes(
                          token.text,
                          car.id,
                        );

                        if (!mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SizesPage(
                              car: car,
                              sizes: sizes,
                            ),
                          ),
                        );
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            err = '$e';
                          });
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            busy = false;
                          });
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SizesPage extends StatelessWidget {
  final Car car;
  final List<String> sizes;

  const SizesPage({
    super.key,
    required this.car,
    required this.sizes,
  });

  Tire? matchSize(String remoteSize) {
    final normalizedRemote =
        remoteSize.toUpperCase().replaceAll(RegExp(r'[^0-9]'), '');

    for (final tire in tires) {
      final normalizedLocal =
          tire.size.toUpperCase().replaceAll(RegExp(r'[^0-9]'), '');

      if (normalizedLocal == normalizedRemote ||
          normalizedRemote.contains(normalizedLocal) ||
          normalizedLocal.contains(normalizedRemote)) {
        return tire;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قياسات السيارة'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: yellow,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${car.make} ${car.model}',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      car.trim.isEmpty
                          ? '${car.year}'
                          : '${car.year} • ${car.trim}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'القياسات المناسبة',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (sizes.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'ما رجع VehDB قياسات لهذه السيارة.',
                  ),
                ),
              ),
            ...sizes.map((size) {
              final tire = matchSize(size);
              final subtitle = tire == null
                  ? 'لا يوجد سعر لهذا القياس حاليًا'
                  : 'سعر الزوج: ${money(tire.price)} د.ع';

              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.tire_repair,
                    size: 34,
                  ),
                  title: Text(
                    size,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(subtitle),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class TiresPage extends StatelessWidget {
  const TiresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإطارات'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tires.length,
          itemBuilder: (context, index) {
            final tire = tires[index];

            return Card(
              child: ListTile(
                leading: const Icon(Icons.tire_repair),
                title: Text(
                  tire.size,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'سعر الزوج: ${money(tire.price)} د.ع',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class BatteriesPage extends StatelessWidget {
  const BatteriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البطاريات'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: batteries.length,
          itemBuilder: (context, index) {
            final battery = batteries[index];

            return Card(
              child: ListTile(
                leading: const Icon(Icons.battery_charging_full),
                title: Text(
                  '${battery.brand} ${battery.amp}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'اختيار البطارية القديمة',
                ),
                trailing: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BatteryPage(
                        b: battery,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class BatteryPage extends StatefulWidget {
  final Battery b;

  const BatteryPage({
    super.key,
    required this.b,
  });

  @override
  State<BatteryPage> createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  bool old = true;

  @override
  Widget build(BuildContext context) {
    final price = old
        ? widget.b.withOld
        : widget.b.withoutOld;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل البطارية'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.battery_charging_full,
                      size: 80,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${widget.b.brand} ${widget.b.amp}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RadioListTile<bool>(
                      value: true,
                      groupValue: old,
                      title: const Text(
                        'أسلّم البطارية القديمة',
                      ),
                      onChanged: (_) {
                        setState(() {
                          old = true;
                        });
                      },
                    ),
                    RadioListTile<bool>(
                      value: false,
                      groupValue: old,
                      title: const Text(
                        'بدون البطارية القديمة',
                      ),
                      onChanged: (_) {
                        setState(() {
                          old = false;
                        });
                      },
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text('السعر النهائي'),
                    Text(
                      '${money(price)} د.ع',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

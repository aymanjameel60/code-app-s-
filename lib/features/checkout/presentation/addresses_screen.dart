import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../data/commerce_repository.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addressesProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = dark ? const Color(0xFF1D1D1D) : Colors.white;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _AddressHead(title: 'اختيار العنوان', onBack: () => context.canPop() ? context.pop() : context.go('/')),
          Expanded(
            child: state.when(
              loading: () => const SpikeLoading(),
              error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(addressesProvider)),
              data: (items) => RefreshIndicator(
                onRefresh: () async { ref.invalidate(addressesProvider); await ref.read(addressesProvider.future); },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(17, 10, 17, 24),
                  children: [
                    const Text('اختر عنوان التوصيل النشط أو عدّل أحد العناوين المحفوظة.', style: TextStyle(fontSize: 12, color: spikeMuted)),
                    const SizedBox(height: 14),
                    if (items.isEmpty)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 50), child: Text('لا يوجد عنوان محفوظ بعد. أضف عنوان التوصيل الأول.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: spikeMuted))),
                    for (final a in items) ...[
                      Container(
                        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), border: Border.all(color: a.isActive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).dividerColor)),
                        child: Row(children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                try {
                                  await ref.read(commerceRepositoryProvider).activateAddress(a.id);
                                  ref.invalidate(addressesProvider);
                                  if (context.mounted) { showSpikeToast(context, 'تم اختيار العنوان'); context.pop(a.id); }
                                } catch (e) { if (context.mounted) showSpikeToast(context, e.toString()); }
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 70),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(children: [
                                  const SizedBox(width: 28, child: Icon(LucideIcons.mapPin, size: 19)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('${a.label.isEmpty ? 'عنوان التوصيل' : a.label} - ${a.cityName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(a.addressLine, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: spikeMuted)),
                                  ])),
                                  SizedBox(width: 25, child: a.isActive ? const Icon(Icons.check, size: 18) : null),
                                ]),
                              ),
                            ),
                          ),
                          TextButton(onPressed: () => context.push('/address-form', extra: a), child: const Text('تعديل', style: TextStyle(fontSize: 12, decoration: TextDecoration.underline))),
                        ]),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.onSurface, foregroundColor: Theme.of(context).colorScheme.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: () => context.push('/address-form'),
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: const Text('إضافة عنوان جديد', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.address});
  final AddressModel? address;
  @override ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  late final TextEditingController name, phone, line, line2, landmark, maps;
  String? cityId;
  String label='المنزل';
  bool active=true,busy=false,locating=false;

  @override void initState(){
    super.initState();
    final a=widget.address,u=ref.read(currentUserProvider).valueOrNull;
    name=TextEditingController(text:a?.recipientName??'${u?['name']??''}');
    phone=TextEditingController(text:a?.phone??'${u?['phone']??''}');
    final parts=(a?.addressLine??'').split(' - ');
    line=TextEditingController(text:parts.isNotEmpty?parts[0]:'');
    line2=TextEditingController(text:parts.length>1?parts[1]:'');
    landmark=TextEditingController(text:parts.length>2?parts.sublist(2).join(' - '):'');
    maps=TextEditingController(text:a?.googleMapsUrl??'');
    cityId=a?.cityId;
    label=a?.label.isNotEmpty==true?a!.label:'المنزل';
    active=a?.isActive??true;
  }

  @override void dispose(){name.dispose();phone.dispose();line.dispose();line2.dispose();landmark.dispose();maps.dispose();super.dispose();}
  String get _typeKey=>label=='مكتب'?'office':label=='أخرى'?'other':'home';
  void _setType(String type)=>setState(()=>label=type=='office'?'مكتب':type=='other'?'أخرى':'المنزل');

  Future<void> _useCurrentLocation() async {
    if(locating)return;
    setState(()=>locating=true);
    try{
      var permission=await Geolocator.checkPermission();
      if(permission==LocationPermission.denied)permission=await Geolocator.requestPermission();
      if(permission==LocationPermission.denied||permission==LocationPermission.deniedForever){showSpikeToast(context,'اسمح للتطبيق باستخدام موقعك أو الصق رابط Google Maps يدويًا');return;}
      final pos=await Geolocator.getCurrentPosition(locationSettings:const LocationSettings(accuracy:LocationAccuracy.high,timeLimit:Duration(seconds:12)));
      maps.text='https://www.google.com/maps?q=${pos.latitude.toStringAsFixed(6)},${pos.longitude.toStringAsFixed(6)}';
      if(mounted)showSpikeToast(context,'تم تحديد موقعك الحالي');
    }catch(_){if(mounted)showSpikeToast(context,'تعذر تحديد موقعك الحالي');}finally{if(mounted)setState(()=>locating=false);}
  }

  Future<void> _delete() async {
    final a=widget.address;if(a==null||busy)return;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('حذف العنوان'),content:const Text('هل تريد حذف هذا العنوان؟'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),TextButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حذف'))]))??false;
    if(!ok)return;
    setState(()=>busy=true);
    try{await ref.read(commerceRepositoryProvider).deleteAddress(a.id);ref.invalidate(addressesProvider);if(mounted){showSpikeToast(context,'تم حذف العنوان');context.pop();}}catch(e){if(mounted)showSpikeToast(context,e.toString());}finally{if(mounted)setState(()=>busy=false);}
  }

  Future<void> save() async {
    if(busy)return;
    if(cityId==null||name.text.trim().isEmpty||phone.text.trim().isEmpty||line.text.trim().isEmpty){showSpikeToast(context,'أكمل العنوان والمدينة ورقم الجوال');return;}
    setState(()=>busy=true);
    final details=[line.text.trim(),line2.text.trim(),landmark.text.trim()].where((x)=>x.isNotEmpty).join(' - ');
    try{
      final repo=ref.read(commerceRepositoryProvider);
      if(widget.address==null){await repo.createAddress(cityId:cityId!,label:label,recipientName:name.text,phone:phone.text,addressLine:details,googleMapsUrl:maps.text,isActive:active);}else{await repo.updateAddress(widget.address!.id,cityId:cityId!,label:label,recipientName:name.text,phone:phone.text,addressLine:details,googleMapsUrl:maps.text,isActive:active);}
      ref.invalidate(addressesProvider);
      if(mounted){showSpikeToast(context,'تم حفظ العنوان');context.pop();}
    }catch(e){if(mounted)showSpikeToast(context,e.toString());}finally{if(mounted)setState(()=>busy=false);}
  }

  @override Widget build(BuildContext context){
    final cities=ref.watch(citiesProvider),dark=Theme.of(context).brightness==Brightness.dark,card=dark?const Color(0xFF1D1D1D):Colors.white;
    return Scaffold(body:SafeArea(child:Column(children:[
      _AddressHead(title:widget.address==null?'إضافة عنوان جديد':'تعديل العنوان',onBack:()=>context.canPop()?context.pop():context.go('/'),action:widget.address==null?null:_delete),
      Expanded(child:cities.when(loading:()=>const SpikeLoading(),error:(e,_)=>SpikeErrorState(message:e.toString(),onRetry:()=>ref.invalidate(citiesProvider)),data:(list)=>ListView(padding:const EdgeInsets.fromLTRB(17,0,17,20),children:[
        const Text('تفاصيل العنوان',style:TextStyle(fontSize:19,fontWeight:FontWeight.w700)),const SizedBox(height:12),
        _ReferenceField(controller:line,icon:LucideIcons.house,hint:'العنوان بالتفصيل *'),const SizedBox(height:12),
        _ReferenceField(controller:line2,icon:LucideIcons.building2,hint:'المنطقة / الحي (اختياري)'),const SizedBox(height:12),
        _ReferenceField(controller:landmark,icon:LucideIcons.landmark,hint:'معلم بارز (اختياري)'),const SizedBox(height:12),
        Container(height:54,padding:const EdgeInsets.symmetric(horizontal:14),decoration:BoxDecoration(color:card,border:Border.all(color:Theme.of(context).dividerColor),borderRadius:BorderRadius.circular(15)),child:Row(children:[const SizedBox(width:30,child:Icon(LucideIcons.map,size:19,color:spikeMuted)),const SizedBox(width:6),Expanded(child:DropdownButtonHideUnderline(child:DropdownButton<String>(value:cityId,isExpanded:true,hint:const Text('اختر مدينة التغطية *',style:TextStyle(fontSize:13,color:spikeMuted)),items:list.map((c)=>DropdownMenuItem(value:c.id,child:Text(c.name,style:const TextStyle(fontSize:13)))).toList(),onChanged:(v)=>setState(()=>cityId=v))))])),const SizedBox(height:12),
        _ReferenceField(controller:maps,icon:LucideIcons.mapPin,hint:'رابط Google Maps (اختياري)',keyboard:TextInputType.url,ltr:true),const SizedBox(height:10),
        SizedBox(height:44,child:OutlinedButton.icon(onPressed:locating?null:_useCurrentLocation,icon:locating?const SizedBox.square(dimension:16,child:CircularProgressIndicator(strokeWidth:2)):const Icon(LucideIcons.navigation,size:18),label:Text(locating?'جاري تحديد الموقع...':'استخدام موقعي الحالي'),style:OutlinedButton.styleFrom(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15))))),
        const SizedBox(height:7),const Text('لحساب أجور التوصيل بدقة أكبر يفضّل إضافة رابط Google Maps. إذا لم تضفه سيُحسب التوصيل تقديريًا على مسافة 10 كم.',style:TextStyle(fontSize:10,color:spikeMuted,height:1.45)),
        const SizedBox(height:20),const Text('تفاصيل الاتصال',style:TextStyle(fontSize:19,fontWeight:FontWeight.w700)),const SizedBox(height:12),
        _ReferenceField(controller:phone,icon:LucideIcons.phone,hint:'رقم الجوال *',keyboard:TextInputType.phone,ltr:true,height:64),
        const SizedBox(height:20),const Text('حفظ العنوان باسم',style:TextStyle(fontSize:19,fontWeight:FontWeight.w700)),const SizedBox(height:12),
        Row(children:[Expanded(child:_AddressType(type:'home',title:'المنزل',icon:LucideIcons.house,selected:_typeKey=='home',onTap:_setType)),const SizedBox(width:9),Expanded(child:_AddressType(type:'office',title:'مكتب',icon:LucideIcons.building2,selected:_typeKey=='office',onTap:_setType)),const SizedBox(width:9),Expanded(child:_AddressType(type:'other',title:'أخرى',icon:LucideIcons.mapPinned,selected:_typeKey=='other',onTap:_setType))]),
        const SizedBox(height:12),
        InkWell(onTap:()=>setState(()=>active=!active),borderRadius:BorderRadius.circular(17),child:Container(height:60,padding:const EdgeInsets.symmetric(horizontal:13),decoration:BoxDecoration(color:card,borderRadius:BorderRadius.circular(17)),child:Row(children:[Container(width:29,height:29,decoration:BoxDecoration(color:const Color(0xFFFFF6DF),borderRadius:BorderRadius.circular(10)),child:const Icon(Icons.check,size:17,color:Color(0xFFF0AD14))),const SizedBox(width:7),const Expanded(child:Text('تعيين كعنوان التوصيل الافتراضي',style:TextStyle(fontSize:12,fontWeight:FontWeight.w700))),Switch(value:active,onChanged:(v)=>setState(()=>active=v),activeThumbColor:const Color(0xFFF0AD14),activeTrackColor:const Color(0xFFF0AD14).withValues(alpha:.45))]))),
        const SizedBox(height:14),Row(children:[Expanded(child:SizedBox(height:48,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:const Color(0xFFF4B219),foregroundColor:Colors.black,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15))),onPressed:busy?null:save,child:busy?const SizedBox.square(dimension:20,child:CircularProgressIndicator(strokeWidth:2)):const Text('حفظ العنوان',style:TextStyle(fontWeight:FontWeight.w700))))),const SizedBox(width:12),Expanded(child:SizedBox(height:48,child:OutlinedButton(onPressed:()=>context.pop(),style:OutlinedButton.styleFrom(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15))),child:const Text('إلغاء'))))]),
      ])))
    ])));
  }
}

class _AddressHead extends StatelessWidget{
  const _AddressHead({required this.title,required this.onBack,this.action});final String title;final VoidCallback onBack;final VoidCallback? action;
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.fromLTRB(17,8,17,0),child:Column(children:[SizedBox(height:92,child:Stack(children:[Align(alignment:Alignment.centerRight,child:SizedBox(width:50,height:40,child:Material(color:Theme.of(context).brightness==Brightness.dark?spikeDarkPanel:const Color(0xFFE8E8E8),borderRadius:BorderRadius.circular(22),child:InkWell(onTap:onBack,borderRadius:BorderRadius.circular(22),child:const Icon(LucideIcons.arrowRight,size:23)))))])),SizedBox(height:60,child:Row(children:[Expanded(child:Align(alignment:Alignment.centerRight,child:Text(title,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w700)))),if(action!=null)IconButton(onPressed:action,icon:const Icon(LucideIcons.trash2,size:21))]))]));
}

class _ReferenceField extends StatelessWidget{
  const _ReferenceField({required this.controller,required this.icon,required this.hint,this.keyboard,this.ltr=false,this.height=54});final TextEditingController controller;final IconData icon;final String hint;final TextInputType? keyboard;final bool ltr;final double height;
  @override Widget build(BuildContext context)=>Container(height:height,padding:const EdgeInsets.symmetric(horizontal:14),decoration:BoxDecoration(color:Theme.of(context).brightness==Brightness.dark?const Color(0xFF1D1D1D):Colors.white,border:Border.all(color:Theme.of(context).dividerColor),borderRadius:BorderRadius.circular(15)),child:Row(children:[SizedBox(width:30,child:Icon(icon,size:19,color:spikeMuted)),const SizedBox(width:6),Expanded(child:TextField(controller:controller,keyboardType:keyboard,textDirection:ltr?TextDirection.ltr:TextDirection.rtl,textAlign:ltr?TextAlign.left:TextAlign.right,decoration:InputDecoration(hintText:hint,hintStyle:const TextStyle(fontSize:13,color:spikeMuted),border:InputBorder.none,enabledBorder:InputBorder.none,focusedBorder:InputBorder.none)))]));
}

class _AddressType extends StatelessWidget{
  const _AddressType({required this.type,required this.title,required this.icon,required this.selected,required this.onTap});final String type,title;final IconData icon;final bool selected;final ValueChanged<String> onTap;
  @override Widget build(BuildContext context)=>InkWell(onTap:()=>onTap(type),borderRadius:BorderRadius.circular(16),child:Container(height:83,decoration:BoxDecoration(color:selected?const Color(0xFFFFF9E8):(Theme.of(context).brightness==Brightness.dark?const Color(0xFF1D1D1D):Colors.white),borderRadius:BorderRadius.circular(16),border:Border.all(color:selected?const Color(0xFFF0AD14):Theme.of(context).dividerColor,width:selected?2:1)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,size:23,color:selected?const Color(0xFFEFAA0A):null),const SizedBox(height:7),Text(title,style:TextStyle(fontSize:12,color:selected?const Color(0xFFEFAA0A):null))])));
}

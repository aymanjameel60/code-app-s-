import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../data/commerce_repository.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final state=ref.watch(addressesProvider);
    return Scaffold(
      appBar: AppBar(backgroundColor:Colors.transparent,title:const Text('اختيار العنوان'),centerTitle:true),
      body: state.when(
        loading:()=>const SpikeLoading(),
        error:(e,_)=>SpikeErrorState(message:e.toString(),onRetry:()=>ref.invalidate(addressesProvider)),
        data:(items)=>ListView(padding:const EdgeInsets.all(17),children:[
          const Text('اختر عنوان التوصيل النشط أو عدّل أحد العناوين المحفوظة.',style:TextStyle(fontSize:12,color:Colors.black54)),
          const SizedBox(height:12),
          if(items.isEmpty) const SpikeEmptyState(message:'لا يوجد عنوان محفوظ بعد'),
          for(final a in items) Container(
            margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(12),
            decoration:BoxDecoration(color:spikePanel,borderRadius:BorderRadius.circular(20),border:a.isActive?Border.all(color:spikeRed,width:1.5):null),
            child:Row(children:[
              Icon(LucideIcons.mapPin,size:21,color:a.isActive?spikeRed:Colors.black87),const SizedBox(width:10),
              Expanded(child:InkWell(onTap:() async {await ref.read(commerceRepositoryProvider).activateAddress(a.id);ref.invalidate(addressesProvider);if(context.mounted){showSpikeToast(context,'تم اختيار العنوان');context.pop(a.id);}},child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${a.label}${a.cityName.isEmpty?'':' - ${a.cityName}'}',style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:3),Text(a.addressLine,style:const TextStyle(fontSize:11,color:Colors.black54)),if(a.isActive)const Padding(padding:EdgeInsets.only(top:4),child:Text('العنوان الافتراضي',style:TextStyle(fontSize:10,color:spikeRed,fontWeight:FontWeight.w700)))]))),
              IconButton(onPressed:()=>context.push('/address-form',extra:a),icon:const Icon(LucideIcons.pencil,size:18)),
              IconButton(onPressed:() async {try{await ref.read(commerceRepositoryProvider).deleteAddress(a.id);ref.invalidate(addressesProvider);}catch(e){if(context.mounted)showSpikeToast(context,e.toString());}},icon:const Icon(LucideIcons.trash2,size:18,color:spikeRed)),
            ]),
          ),
          const SizedBox(height:8),
          SizedBox(height:48,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:spikeRed),onPressed:()=>context.push('/address-form'),child:const Text('+ إضافة عنوان جديد'))),
        ]),
      ),
    );
  }
}

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key,this.address}); final AddressModel? address;
  @override ConsumerState<AddressFormScreen> createState()=>_AddressFormScreenState();
}
class _AddressFormScreenState extends ConsumerState<AddressFormScreen>{
  late final TextEditingController name,phone,line,maps; String? cityId; String label='المنزل'; bool active=true; bool busy=false;
  @override void initState(){super.initState();final a=widget.address;name=TextEditingController(text:a?.recipientName??'');phone=TextEditingController(text:a?.phone??'');line=TextEditingController(text:a?.addressLine??'');maps=TextEditingController(text:a?.googleMapsUrl??'');cityId=a?.cityId;label=a?.label.isNotEmpty==true?a!.label:'المنزل';active=a?.isActive??true;}
  @override void dispose(){name.dispose();phone.dispose();line.dispose();maps.dispose();super.dispose();}
  Future<void> save() async{
    if(busy)return;if(cityId==null||name.text.trim().isEmpty||phone.text.trim().isEmpty||line.text.trim().isEmpty||maps.text.trim().isEmpty){showSpikeToast(context,'أكمل جميع الحقول المطلوبة');return;}
    setState(()=>busy=true);try{final r=ref.read(commerceRepositoryProvider);if(widget.address==null){await r.createAddress(cityId:cityId!,label:label,recipientName:name.text,phone:phone.text,addressLine:line.text,googleMapsUrl:maps.text,isActive:active);}else{await r.updateAddress(widget.address!.id,cityId:cityId!,label:label,recipientName:name.text,phone:phone.text,addressLine:line.text,googleMapsUrl:maps.text,isActive:active);}ref.invalidate(addressesProvider);if(mounted)context.pop();}catch(e){if(mounted)showSpikeToast(context,e.toString());}finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context){final cities=ref.watch(citiesProvider);return Scaffold(appBar:AppBar(backgroundColor:Colors.transparent,title:Text(widget.address==null?'إضافة عنوان جديد':'تعديل العنوان'),centerTitle:true),body:cities.when(loading:()=>const SpikeLoading(),error:(e,_)=>SpikeErrorState(message:e.toString(),onRetry:()=>ref.invalidate(citiesProvider)),data:(list)=>ListView(padding:const EdgeInsets.all(17),children:[
    const Text('تفاصيل العنوان',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),const SizedBox(height:12),
    _field(name,'اسم المستلم *',LucideIcons.user),const SizedBox(height:10),
    _field(phone,'رقم الجوال *',LucideIcons.phone,keyboard:TextInputType.phone),const SizedBox(height:10),
    DropdownButtonFormField<String>(value:cityId,decoration:_dec('اختر مدينة التغطية *',LucideIcons.map),items:list.map((c)=>DropdownMenuItem(value:c.id,child:Text(c.name))).toList(),onChanged:(v)=>setState(()=>cityId=v)),const SizedBox(height:10),
    _field(line,'العنوان بالتفصيل *',LucideIcons.house),const SizedBox(height:10),
    _field(maps,'رابط Google Maps للموقع *',LucideIcons.mapPin,keyboard:TextInputType.url),const Padding(padding:EdgeInsets.only(top:6),child:Text('انسخ رابط موقعك من Google Maps والصقه هنا. النظام يحدد الإحداثيات تلقائياً.',style:TextStyle(fontSize:10,color:Colors.black54))),const SizedBox(height:16),
    const Text('حفظ العنوان باسم',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800)),const SizedBox(height:8),Wrap(spacing:8,children:['المنزل','مكتب','أخرى'].map((x)=>ChoiceChip(label:Text(x),selected:label==x,onSelected:(_)=>setState(()=>label=x))).toList()),
    SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('تعيين كعنوان التوصيل الافتراضي',style:TextStyle(fontWeight:FontWeight.w700)),value:active,onChanged:(v)=>setState(()=>active=v),activeColor:spikeRed),const SizedBox(height:10),
    SizedBox(height:48,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:spikeRed),onPressed:busy?null:save,child:busy?const SizedBox.square(dimension:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('حفظ العنوان')))
  ])));}
  InputDecoration _dec(String hint,IconData icon)=>InputDecoration(hintText:hint,filled:true,fillColor:spikeField,suffixIcon:Icon(icon,size:20),border:const OutlineInputBorder(borderSide:BorderSide.none,borderRadius:BorderRadius.all(Radius.circular(18))));
  Widget _field(TextEditingController c,String hint,IconData icon,{TextInputType? keyboard})=>TextField(controller:c,keyboardType:keyboard,decoration:_dec(hint,icon));
}

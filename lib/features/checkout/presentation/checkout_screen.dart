import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/media_url.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../cart/data/cart_repository.dart';
import '../data/commerce_repository.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override ConsumerState<CheckoutScreen> createState()=>_CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>{
  CartSnapshot? cart;
  List<AddressModel> addresses=[];
  List<PaymentMethodModel> methods=[];
  List<CurrencyModel> currencies=[];
  List<Map<String,dynamic>> wallets=[];
  List<Map<String,dynamic>> banners=[];
  AddressModel? address;
  CurrencyModel? currency;
  DeliveryQuote? quote;
  String paymentMode='transfer';
  bool loading=true,busy=false;

  PaymentMethodModel? get transferMethod=>methods.where((m)=>m.method!='wallet').cast<PaymentMethodModel?>().firstOrNull;

  @override void initState(){super.initState();_load();}

  Future<void> _load()async{
    if(mounted)setState(()=>loading=true);
    try{
      final commerce=ref.read(commerceRepositoryProvider);
      final preferred=ref.read(appSettingsProvider).currency;
      final result=await Future.wait([
        ref.read(cartRepositoryProvider).load(),
        commerce.addresses(),
        commerce.paymentMethods(),
        commerce.currencies(),
        ref.read(apiClientProvider).get('/electronic-wallets'),
        ref.read(apiClientProvider).get('/banners',query:{'placement':'checkout'}),
      ]);
      cart=result[0] as CartSnapshot;
      addresses=result[1] as List<AddressModel>;
      methods=result[2] as List<PaymentMethodModel>;
      currencies=result[3] as List<CurrencyModel>;
      final wd=result[4] as Map<String,dynamic>;
      final bd=result[5] as Map<String,dynamic>;
      wallets=(wd['wallets'] as List? ?? const []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).where((e)=>e['enabled']!=false).toList();
      banners=(bd['banners'] as List? ?? bd['banner_items'] as List? ?? const []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).where((e)=>e['enabled']!=false).toList();
      address=addresses.where((a)=>a.isActive).cast<AddressModel?>().firstOrNull??(addresses.isNotEmpty?addresses.first:null);
      currency=currencies.where((c)=>c.code==preferred).cast<CurrencyModel?>().firstOrNull??currencies.where((c)=>c.code==(cart?.currencyCode??'USD')).cast<CurrencyModel?>().firstOrNull??(currencies.isNotEmpty?currencies.first:null);
      if(currency!=null)cart=await ref.read(cartRepositoryProvider).updateMeta(currencyCode:currency!.code);
      if(address!=null&&cart!.items.isNotEmpty)quote=await commerce.quote(addressId:address!.id,cart:cart!);
    }catch(e){if(mounted)showSpikeToast(context,e.toString());}finally{if(mounted)setState(()=>loading=false);}
  }

  Future<void> _chooseAddress()async{
    await context.push('/addresses');if(!mounted)return;
    try{final list=await ref.read(commerceRepositoryProvider).addresses();final selected=list.where((a)=>a.isActive).cast<AddressModel?>().firstOrNull;if(selected==null||cart==null||cart!.items.isEmpty)return;quote=await ref.read(commerceRepositoryProvider).quote(addressId:selected.id,cart:cart!);if(mounted)setState(()=>address=selected);}catch(e){if(mounted)showSpikeToast(context,e.toString());}
  }

  Future<void> _placeOrder(String method)async{
    if(busy||cart==null||address==null||currency==null)return;
    setState(()=>busy=true);
    try{
      await ref.read(commerceRepositoryProvider).createOrder(cart:cart!,addressId:address!.id,paymentMethod:method,currencyCode:currency!.code);
      ref.invalidate(cartCountProvider);ref.invalidate(ordersProvider);
      if(mounted){showSpikeToast(context,'تم إنشاء الطلب بنجاح');context.go('/success?payment=${Uri.encodeComponent(method)}');}
    }catch(e){if(mounted)showSpikeToast(context,e.toString());}finally{if(mounted)setState(()=>busy=false);}
  }

  Future<void> _walletFlow(Map<String,dynamic> wallet)async{
    if(address==null){showSpikeToast(context,'اختر عنوان التوصيل');return;}
    final phone=TextEditingController();
    final phoneOk=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(ctx)=>_WalletSheet(title:'${wallet['name']??'المحفظة'}',message:'ادخل رقمك المرتبط بعملية الدفع',controller:phone,hint:'رقم الجوال',keyboard:TextInputType.phone));
    if(phoneOk!=true||!mounted)return;
    if(phone.text.trim().isEmpty){showSpikeToast(context,'أدخل رقم الجوال');return;}
    final otp=TextEditingController();
    final otpOk=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(ctx)=>_WalletSheet(title:'رمز التحقق',message:'أدخل رمز التحقق لإكمال الطلب',controller:otp,hint:'رمز التحقق',keyboard:TextInputType.number));
    if(otpOk!=true||!mounted)return;
    if(otp.text.trim().isEmpty){showSpikeToast(context,'أدخل رمز التحقق');return;}
    await _placeOrder('wallet');
  }

  void _openBanner(Map<String,dynamic> b){
    final type='${b['target_type']??''}',target='${b['target_id']??''}';
    if(target.isEmpty)return;
    if(type=='product')context.push('/product/$target');
    else if(type=='category')context.push('/products?category=${Uri.encodeComponent(target)}');
    else if(type=='collection')context.push('/products?collection=${Uri.encodeComponent(target)}');
  }

  @override Widget build(BuildContext context){
    if(loading)return const Scaffold(body:SpikeLoading());
    if(cart==null)return Scaffold(body:SpikeErrorState(onRetry:_load));
    if(cart!.items.isEmpty)return Scaffold(body:SafeArea(child:Column(children:[const _CheckoutHead(title:'تأكيد الطلب والدفع'),const Expanded(child:SpikeEmptyState(message:'السلة فارغة، أضف منتجات قبل إتمام الطلب')),Padding(padding:const EdgeInsets.all(17),child:SizedBox(width:double.infinity,height:46,child:FilledButton(onPressed:()=>context.go('/'),child:const Text('العودة للتسوق'))))])));

    final dark=Theme.of(context).brightness==Brightness.dark;
    final panel=dark?spikeDarkPanel:spikePanel;
    final white=dark?spikeDarkPanel:Colors.white;
    final rates=ref.watch(currencyRatesProvider).valueOrNull??const <String,double>{};
    final rate=rates[cart!.currencyCode.trim().toUpperCase()]??1;
    final yerOldRate=rates['YER_OLD']??530;
    final deliveryUsd=quote==null?0.0:quote!.shippingYerOld/yerOldRate;
    final grandUsd=cart!.subtotal+deliveryUsd;
    String money(double usd)=>formatMoney(usd,code:cart!.currencyCode,rate:rate);
    final transfer=paymentMode=='transfer';
    final banner=banners.firstOrNull;

    return Scaffold(body:SafeArea(child:Column(children:[
      const _CheckoutHead(title:'تأكيد الطلب والدفع'),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(17,0,17,24),children:[
        _Step(number:'1',title:'عنوان التوصيل',child:InkWell(onTap:_chooseAddress,borderRadius:BorderRadius.circular(16),child:Container(height:58,padding:const EdgeInsets.symmetric(horizontal:12),decoration:BoxDecoration(color:white,border:Border.all(color:const Color(0xFFE7E7E7)),borderRadius:BorderRadius.circular(16)),child:Row(children:[const Icon(LucideIcons.mapPin,size:20),const SizedBox(width:8),Expanded(child:Text(address==null?'اختر عنوان التوصيل':'${address!.label} - ${address!.cityName}',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700))),Text(address==null?'اختيار':'تغيير',style:const TextStyle(fontSize:12,decoration:TextDecoration.underline))])))),
        if(banner!=null)...[const SizedBox(height:12),_CheckoutBanner(data:banner,onTap:()=>_openBanner(banner))],
        const SizedBox(height:16),
        _Step(number:'2',title:'التوصيل',child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Container(constraints:const BoxConstraints(minHeight:39),padding:const EdgeInsets.symmetric(horizontal:16,vertical:10),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(22)),child:Row(children:[const Icon(LucideIcons.truck,size:18),const SizedBox(width:10),const Expanded(child:Text('مكتب التوصيل محدد لكل منتج من التاجر',style:TextStyle(fontSize:11))),if(quote!=null)Text(money(deliveryUsd),style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700))])),if(quote?.estimated==true)Padding(padding:const EdgeInsets.fromLTRB(12,7,12,0),child:Text('لم يتم تحديد موقع دقيق؛ تم حساب التوصيل تقديريًا على مسافة ${quote!.fallbackKm.toStringAsFixed(0)} كم.',style:const TextStyle(fontSize:10,color:spikeMuted,height:1.4)))])),
        const SizedBox(height:16),
        _Step(number:'3',title:'طريقة الدفع',child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Row(children:[Expanded(child:_PayChoice(label:'حوالة مالية',selected:transfer,onTap:()=>setState(()=>paymentMode='transfer'))),const SizedBox(width:12),Expanded(child:_PayChoice(label:'محفظة إلكترونية',selected:!transfer,onTap:()=>setState(()=>paymentMode='wallet')))]),
          if(transfer&&transferMethod!=null&&transferMethod!.instructions.trim().isNotEmpty)...[const SizedBox(height:12),Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:white,borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFE7E7E7))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('بيانات التحويل',style:TextStyle(fontSize:14,fontWeight:FontWeight.w700)),const SizedBox(height:8),Text(transferMethod!.instructions,style:const TextStyle(fontSize:10,height:1.55)),const SizedBox(height:10),const Text('بعد تأكيد الطلب سترفع سند الحوالة من قسم طلباتي.',style:TextStyle(fontSize:10,color:spikeMuted,height:1.5))]))],
          if(!transfer)...[const SizedBox(height:12),const Text('اختر المحفظة',style:TextStyle(fontSize:14,fontWeight:FontWeight.w700)),const SizedBox(height:10),if(wallets.isEmpty)Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(18)),child:const Text('لا توجد محافظ إلكترونية مفعلة حالياً.',style:TextStyle(fontSize:11)))else SizedBox(height:96,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:wallets.length,separatorBuilder:(_,__)=>const SizedBox(width:10),itemBuilder:(_,i){final w=wallets[i],logo=resolveMediaUrl('${w['logo_url']??''}');return InkWell(onTap:()=>_walletFlow(w),borderRadius:BorderRadius.circular(18),child:Container(width:108,padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:white,borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFE7E7E7))),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[if(logo!=null&&logo.isNotEmpty)ClipRRect(borderRadius:BorderRadius.circular(10),child:Image.network(logo,width:36,height:36,fit:BoxFit.contain,errorBuilder:(_,__,___)=>const Icon(LucideIcons.walletCards,size:25)))else const Icon(LucideIcons.walletCards,size:25),const SizedBox(height:6),Text('${w['name']??''}',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w700))])));} ))]
        ])),
        const SizedBox(height:16),
        Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:10),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(22)),child:Column(children:[_InvoiceLine(label:'المنتجات بعد الخصومات',value:money(cart!.subtotal)),_InvoiceLine(label:'رسوم مكتب التوصيل',value:quote==null?'تحسب عند التأكيد':money(deliveryUsd)),SizedBox(height:48,child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('الإجمالي مع التوصيل',style:TextStyle(fontSize:14,fontWeight:FontWeight.w700)),Text(money(grandUsd),style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800))]))])),
        const SizedBox(height:12),
        SizedBox(height:46,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:spikeRed,foregroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),onPressed:address==null||currency==null||busy?null:transfer?()=>_placeOrder('transfer'):()=>showSpikeToast(context,'اختر إحدى المحافظ الإلكترونية أولاً'),child:busy?const SizedBox.square(dimension:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Text(transfer?'تأكيد الطلب':'اختر المحفظة لإكمال الدفع',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700))))
      ]))
    ])));
  }
}

class _PayChoice extends StatelessWidget{const _PayChoice({required this.label,required this.selected,required this.onTap});final String label;final bool selected;final VoidCallback onTap;@override Widget build(BuildContext context)=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(16),child:Container(height:46,padding:const EdgeInsets.symmetric(horizontal:12),decoration:BoxDecoration(color:Theme.of(context).brightness==Brightness.dark?spikeDarkPanel:Colors.white,borderRadius:BorderRadius.circular(16),border:Border.all(color:selected?Theme.of(context).colorScheme.onSurface:const Color(0xFFE4E4E4),width:selected?1.5:1)),child:Row(children:[Icon(selected?Icons.radio_button_checked:Icons.radio_button_off,size:18),const SizedBox(width:7),Expanded(child:Text(label,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600))) ])));}
class _CheckoutBanner extends StatelessWidget{const _CheckoutBanner({required this.data,required this.onTap});final Map<String,dynamic> data;final VoidCallback onTap;@override Widget build(BuildContext context){final url=resolveMediaUrl('${data['image_url']??''}');if(url==null||url.isEmpty)return const SizedBox.shrink();return InkWell(onTap:onTap,borderRadius:BorderRadius.circular(23),child:ClipRRect(borderRadius:BorderRadius.circular(23),child:Image.network(url,height:105,width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox.shrink())));}}
class _WalletSheet extends StatelessWidget{const _WalletSheet({required this.title,required this.message,required this.controller,required this.hint,required this.keyboard});final String title,message,hint;final TextEditingController controller;final TextInputType keyboard;@override Widget build(BuildContext context)=>Padding(padding:EdgeInsets.only(bottom:MediaQuery.of(context).viewInsets.bottom),child:Container(padding:const EdgeInsets.fromLTRB(18,18,18,24),decoration:BoxDecoration(color:Theme.of(context).scaffoldBackgroundColor,borderRadius:const BorderRadius.vertical(top:Radius.circular(26))),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700)),const SizedBox(height:8),Text(message,style:const TextStyle(fontSize:11)),const SizedBox(height:14),SizedBox(height:54,child:TextField(controller:controller,keyboardType:keyboard,decoration:InputDecoration(hintText:hint,filled:true,fillColor:Theme.of(context).brightness==Brightness.dark?spikeDarkPanel:Colors.white,border:OutlineInputBorder(borderSide:BorderSide.none,borderRadius:BorderRadius.circular(15))))),const SizedBox(height:12),Row(children:[Expanded(child:OutlinedButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء'))),const SizedBox(width:10),Expanded(child:FilledButton(style:FilledButton.styleFrom(backgroundColor:Colors.black,foregroundColor:Colors.white),onPressed:()=>Navigator.pop(context,true),child:const Text('تأكيد')))])])));}
class _Step extends StatelessWidget{const _Step({required this.number,required this.title,required this.child});final String number,title;final Widget child;@override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[Container(width:28,height:28,alignment:Alignment.center,decoration:BoxDecoration(color:Theme.of(context).colorScheme.onSurface,shape:BoxShape.circle),child:Text(number,style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:Theme.of(context).colorScheme.surface))),const SizedBox(width:9),Text(title,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w700))]),const SizedBox(height:10),child]);}
class _CheckoutHead extends StatelessWidget{const _CheckoutHead({required this.title});final String title;@override Widget build(BuildContext context){final dark=Theme.of(context).brightness==Brightness.dark;return Padding(padding:const EdgeInsets.fromLTRB(17,8,17,0),child:Column(children:[SizedBox(height:92,child:Stack(children:[Align(alignment:Alignment.centerRight,child:SizedBox(width:50,height:40,child:Material(color:dark?spikeDarkPanel:const Color(0xFFE8E8E8),borderRadius:BorderRadius.circular(22),child:InkWell(borderRadius:BorderRadius.circular(22),onTap:()=>context.canPop()?context.pop():context.go('/cart'),child:const Icon(LucideIcons.arrowRight,size:23)))))])),SizedBox(height:60,child:Align(alignment:Alignment.centerRight,child:Text(title,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w700))))]));}}
class _InvoiceLine extends StatelessWidget{const _InvoiceLine({required this.label,required this.value});final String label,value;@override Widget build(BuildContext context)=>Container(height:36,alignment:Alignment.center,decoration:BoxDecoration(border:Border(bottom:BorderSide(color:Theme.of(context).dividerColor))),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(label,style:const TextStyle(fontSize:11)),Text(value,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700))]));}
extension _FirstOrNull<T> on Iterable<T>{T? get firstOrNull=>isEmpty?null:first;}

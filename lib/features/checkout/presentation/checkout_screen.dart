import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../cart/data/cart_repository.dart';
import '../data/commerce_repository.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  CartSnapshot? cart;
  List<AddressModel> addresses=[];
  List<PaymentMethodModel> methods=[];
  List<CurrencyModel> currencies=[];
  AddressModel? address;
  PaymentMethodModel? payment;
  CurrencyModel? currency;
  DeliveryQuote? quote;
  bool loading=true,busy=false;

  @override void initState(){super.initState();_load();}

  Future<void> _load() async {
    if(mounted)setState(()=>loading=true);
    try{
      final commerce=ref.read(commerceRepositoryProvider);
      final preferred=ref.read(appSettingsProvider).currency;
      final result=await Future.wait([ref.read(cartRepositoryProvider).load(),commerce.addresses(),commerce.paymentMethods(),commerce.currencies()]);
      cart=result[0] as CartSnapshot; addresses=result[1] as List<AddressModel>; methods=result[2] as List<PaymentMethodModel>; currencies=result[3] as List<CurrencyModel>;
      address=addresses.where((a)=>a.isActive).cast<AddressModel?>().firstOrNull ?? (addresses.isNotEmpty?addresses.first:null);
      payment=methods.isNotEmpty?methods.first:null;
      currency=currencies.where((c)=>c.code==preferred).cast<CurrencyModel?>().firstOrNull ?? currencies.where((c)=>c.code==(cart?.currencyCode??'USD')).cast<CurrencyModel?>().firstOrNull ?? (currencies.isNotEmpty?currencies.first:null);
      if(currency!=null)cart=await ref.read(cartRepositoryProvider).updateMeta(currencyCode:currency!.code);
      if(address!=null&&cart!.items.isNotEmpty)quote=await commerce.quote(addressId:address!.id,variantIds:cart!.items.map((e)=>e.variantId).toList());
    }catch(e){if(mounted)showSpikeToast(context,e.toString());}finally{if(mounted)setState(()=>loading=false);}
  }

  Future<void> _chooseAddress() async {
    await context.push('/addresses'); if(!mounted)return;
    try{final list=await ref.read(commerceRepositoryProvider).addresses();final selected=list.where((a)=>a.isActive).cast<AddressModel?>().firstOrNull;if(selected==null||cart==null||cart!.items.isEmpty)return;quote=await ref.read(commerceRepositoryProvider).quote(addressId:selected.id,variantIds:cart!.items.map((e)=>e.variantId).toList());if(mounted)setState(()=>address=selected);}catch(e){if(mounted)showSpikeToast(context,e.toString());}
  }

  Future<void> _submit() async {
    if(busy||cart==null||address==null||payment==null||currency==null)return;
    final selectedPayment=payment!.method;
    setState(()=>busy=true);
    try{
      await ref.read(commerceRepositoryProvider).createOrder(cart:cart!,addressId:address!.id,paymentMethod:selectedPayment,currencyCode:currency!.code);
      ref.invalidate(cartCountProvider);
      ref.invalidate(ordersProvider);
      if(mounted){showSpikeToast(context,'تم إنشاء الطلب بنجاح');context.go('/success?payment=${Uri.encodeComponent(selectedPayment)}');}
    }catch(e){if(mounted)showSpikeToast(context,e.toString());}finally{if(mounted)setState(()=>busy=false);}
  }

  @override Widget build(BuildContext context){
    if(loading)return const Scaffold(body:SpikeLoading());
    if(cart==null)return Scaffold(body:SpikeErrorState(onRetry:_load));
    if(cart!.items.isEmpty)return Scaffold(body:SafeArea(child:Column(children:[const _CheckoutHead(title:'تأكيد الطلب والدفع'),const Expanded(child:SpikeEmptyState(message:'السلة فارغة، أضف منتجات قبل إتمام الطلب')),Padding(padding:const EdgeInsets.all(17),child:SizedBox(width:double.infinity,height:39,child:FilledButton(onPressed:()=>context.go('/'),child:const Text('العودة للتسوق'))))])));

    final dark=Theme.of(context).brightness==Brightness.dark;
    final panel=dark?spikeDarkPanel:spikePanel;
    final white=dark?spikeDarkPanel:Colors.white;
    final rates=ref.watch(currencyRatesProvider).valueOrNull??const <String,double>{};
    final rate=rates[cart!.currencyCode.trim().toUpperCase()]??1;
    final yerOldRate=rates['YER_OLD']??530;
    final deliveryUsd=quote==null?0.0:quote!.shippingYerOld/yerOldRate;
    final grandUsd=cart!.subtotal+deliveryUsd;
    String money(double usd)=>formatMoney(usd,code:cart!.currencyCode,rate:rate);
    final ready=address!=null&&payment!=null&&currency!=null&&!busy;

    return Scaffold(body:SafeArea(child:Column(children:[
      const _CheckoutHead(title:'تأكيد الطلب والدفع'),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(17,0,17,24),children:[
        _Step(
          number:'1',
          title:'عنوان التوصيل',
          child:InkWell(onTap:_chooseAddress,borderRadius:BorderRadius.circular(16),child:Container(height:58,padding:const EdgeInsets.symmetric(horizontal:12),decoration:BoxDecoration(color:white,border:Border.all(color:const Color(0xFFE7E7E7)),borderRadius:BorderRadius.circular(16)),child:Row(children:[const Icon(LucideIcons.mapPin,size:20),const SizedBox(width:8),Expanded(child:Text(address==null?'اختر عنوان التوصيل':'${address!.label} - ${address!.cityName}',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700))),Text(address==null?'اختيار':'تغيير',style:const TextStyle(fontSize:12,decoration:TextDecoration.underline))]))),
        ),
        const SizedBox(height:16),
        _Step(
          number:'2',
          title:'التوصيل',
          child:Container(constraints:const BoxConstraints(minHeight:39),padding:const EdgeInsets.symmetric(horizontal:16,vertical:10),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(22)),child:Row(children:[const Icon(LucideIcons.truck,size:18),const SizedBox(width:10),const Expanded(child:Text('مكتب التوصيل محدد لكل منتج من التاجر',style:TextStyle(fontSize:11))),if(quote!=null)Text(money(deliveryUsd),style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700))])),
        ),
        const SizedBox(height:16),
        _Step(
          number:'3',
          title:'طريقة الدفع',
          child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            Wrap(spacing:18,runSpacing:8,children:[for(final method in methods)InkWell(onTap:()=>setState(()=>payment=method),child:Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(payment?.method==method.method?Icons.radio_button_checked:Icons.radio_button_off,size:18),const SizedBox(width:7),Text(method.label,style:const TextStyle(fontSize:12))])))]),
            if(payment!=null&&payment!.instructions.trim().isNotEmpty)...[
              const SizedBox(height:12),
              Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:white,borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFE7E7E7))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('بيانات التحويل',style:TextStyle(fontSize:14,fontWeight:FontWeight.w700)),const SizedBox(height:8),Text(payment!.instructions,style:const TextStyle(fontSize:10,height:1.55)),const SizedBox(height:10),const Text('بعد تأكيد الطلب سترفع سند الحوالة من قسم طلباتي.',style:TextStyle(fontSize:10,color:spikeMuted,height:1.5))])),
            ],
          ]),
        ),
        const SizedBox(height:16),
        Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:10),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(22)),child:Column(children:[_InvoiceLine(label:'المنتجات بعد الخصومات',value:money(cart!.subtotal)),_InvoiceLine(label:'رسوم مكتب التوصيل',value:quote==null?'تحسب عند التأكيد':money(deliveryUsd)),SizedBox(height:48,child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('الإجمالي مع التوصيل',style:TextStyle(fontSize:14,fontWeight:FontWeight.w700)),Text(money(grandUsd),style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800))]))])),
        const SizedBox(height:12),
        SizedBox(height:46,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:spikeRed,foregroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),onPressed:ready?_submit:null,child:busy?const SizedBox.square(dimension:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('تأكيد الطلب',style:TextStyle(fontSize:12,fontWeight:FontWeight.w700))))
      ]))
    ])));
  }
}

class _Step extends StatelessWidget{
  const _Step({required this.number,required this.title,required this.child});final String number,title;final Widget child;
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[Container(width:28,height:28,alignment:Alignment.center,decoration:BoxDecoration(color:Theme.of(context).colorScheme.onSurface,shape:BoxShape.circle),child:Text(number,style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:Theme.of(context).colorScheme.surface))),const SizedBox(width:9),Text(title,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w700))]),const SizedBox(height:10),child]);
}

class _CheckoutHead extends StatelessWidget{
  const _CheckoutHead({required this.title});final String title;
  @override Widget build(BuildContext context){final dark=Theme.of(context).brightness==Brightness.dark;return Padding(padding:const EdgeInsets.fromLTRB(17,8,17,0),child:Column(children:[SizedBox(height:92,child:Stack(children:[Align(alignment:Alignment.centerRight,child:SizedBox(width:50,height:40,child:Material(color:dark?spikeDarkPanel:const Color(0xFFE8E8E8),borderRadius:BorderRadius.circular(22),child:InkWell(borderRadius:BorderRadius.circular(22),onTap:()=>context.canPop()?context.pop():context.go('/cart'),child:const Icon(LucideIcons.arrowRight,size:23)))))])),SizedBox(height:60,child:Align(alignment:Alignment.centerRight,child:Text(title,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w700))))]));}
}

class _InvoiceLine extends StatelessWidget{
  const _InvoiceLine({required this.label,required this.value});final String label,value;
  @override Widget build(BuildContext context)=>Container(height:36,alignment:Alignment.center,decoration:BoxDecoration(border:Border(bottom:BorderSide(color:Theme.of(context).dividerColor))),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(label,style:const TextStyle(fontSize:11)),Text(value,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700))]));
}

extension _FirstOrNull<T> on Iterable<T>{T? get firstOrNull=>isEmpty?null:first;}

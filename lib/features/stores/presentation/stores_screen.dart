import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class StoresScreen extends ConsumerStatefulWidget {
  const StoresScreen({super.key});
  @override
  ConsumerState<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends ConsumerState<StoresScreen> {
  String _query='';
  String _sort='relevance';
  double _minRating=0;

  void _showSort(){
    showModalBottomSheet<void>(context:context,builder:(context)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(17,20,17,25),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Text('الترتيب حسب',style:TextStyle(fontSize:20,fontWeight:FontWeight.w700)),
      const SizedBox(height:18),
      for(final option in const [('relevance','الأكثر صلة'),('rating','الأعلى تقييماً'),('reviews','الأكثر مراجعات'),('name','الاسم أبجدياً')])
        SizedBox(height:48,child:ListTile(contentPadding:EdgeInsets.zero,title:Text(option.$2,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)),trailing:Radio<String>(value:option.$1,groupValue:_sort,onChanged:(v){if(v==null)return;setState(()=>_sort=v);Navigator.pop(context);}))
    ]))));
  }

  void _showFilter(){
    showModalBottomSheet<void>(context:context,builder:(context)=>StatefulBuilder(builder:(context,setLocal)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(17,20,17,25),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Text('فلترة المتاجر',style:TextStyle(fontSize:20,fontWeight:FontWeight.w700)),
      const SizedBox(height:18),
      const Text('التقييم',style:TextStyle(fontSize:11,fontWeight:FontWeight.w700)),
      const SizedBox(height:10),
      for(final r in const [0.0,4.0,4.5]) SizedBox(height:48,child:ListTile(contentPadding:EdgeInsets.zero,title:Text(r==0?'كل التقييمات':r==4?'4 نجوم فأعلى':'4.5 نجوم فأعلى',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)),trailing:Radio<double>(value:r,groupValue:_minRating,onChanged:(v){if(v==null)return;setLocal(()=>_minRating=v);setState(()=>_minRating=v);}))),
      const SizedBox(height:22),
      SizedBox(height:38,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:spikeRed),onPressed:()=>Navigator.pop(context),child:const Text('تطبيق الفلتر',style:TextStyle(fontSize:12,fontWeight:FontWeight.w700)))),
    ])))));
  }

  @override
  Widget build(BuildContext context){
    final storesState=ref.watch(storesProvider);
    final productsState=ref.watch(allProductsProvider);
    final dark=Theme.of(context).brightness==Brightness.dark;
    return Scaffold(
      appBar:AppBar(title:const Text('المتاجر',style:TextStyle(fontSize:21,fontWeight:FontWeight.w700)),centerTitle:true,actions:[Padding(padding:const EdgeInsetsDirectional.only(end:8),child:TextButton(onPressed:_showSort,child:const Text('ترتيب حسب',style:TextStyle(fontSize:12,fontWeight:FontWeight.w500))))]),
      body:Column(children:[
        Padding(padding:const EdgeInsets.symmetric(horizontal:17),child:Container(height:42,decoration:BoxDecoration(color:dark?spikeDarkPanel:spikeField,borderRadius:BorderRadius.circular(22)),child:TextField(onChanged:(v)=>setState(()=>_query=v.trim()),decoration:const InputDecoration(hintText:'البحث عن متجر',prefixIcon:Icon(Icons.search,size:20),border:InputBorder.none,contentPadding:EdgeInsets.symmetric(vertical:10))))),
        const SizedBox(height:15),
        Padding(padding:const EdgeInsets.symmetric(horizontal:17),child:Row(children:[
          SizedBox(width:38,height:38,child:IconButton.filledTonal(onPressed:_showFilter,icon:const Icon(Icons.tune,size:19))),
          const SizedBox(width:8),
          Expanded(child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
            for(final r in const [0.0,4.0,4.5]) Padding(padding:const EdgeInsetsDirectional.only(end:7),child:ChoiceChip(label:Text(r==0?'الكل':r==4?'4+':'4.5+',style:const TextStyle(fontSize:10)),selected:_minRating==r,onSelected:(_)=>setState(()=>_minRating=r),showCheckmark:false,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),side:BorderSide.none)),
          ]))),
        ])),
        const SizedBox(height:15),
        Expanded(child:storesState.when(
          loading:()=>const SpikeLoading(),
          error:(e,_)=>SpikeErrorState(message:e.toString(),onRetry:()=>ref.invalidate(storesProvider)),
          data:(stores){
            final allProducts=productsState.valueOrNull??const[];
            final q=_query.toLowerCase();
            final list=stores.where((s){final matches=q.isEmpty||s.name.toLowerCase().contains(q)||allProducts.any((p)=>p.storeId==s.id&&(p.categoryName??'').toLowerCase().contains(q));return matches&&s.rating>=_minRating;}).toList();
            if(_sort=='name')list.sort((a,b)=>a.name.compareTo(b.name));
            if(_sort=='rating')list.sort((a,b)=>b.rating.compareTo(a.rating));
            if(_sort=='reviews')list.sort((a,b)=>b.reviewCount.compareTo(a.reviewCount));
            if(list.isEmpty)return const SpikeEmptyState(message:'لا توجد متاجر مطابقة للفلتر');
            return RefreshIndicator(onRefresh:()async{ref.invalidate(storesProvider);ref.invalidate(allProductsProvider);await ref.read(storesProvider.future);},child:ListView.separated(padding:const EdgeInsets.fromLTRB(17,0,17,24),itemCount:list.length,separatorBuilder:(_,__)=>const SizedBox(height:14),itemBuilder:(context,i){
              final store=list[i];
              return InkWell(onTap:()=>context.push('/store/${store.id}'),borderRadius:BorderRadius.circular(24),child:Container(decoration:BoxDecoration(color:dark?spikeDarkPanel:spikePanel,borderRadius:BorderRadius.circular(24)),clipBehavior:Clip.antiAlias,child:Column(children:[
                SizedBox(height:150,width:double.infinity,child:store.bannerUrl==null?Container(color:dark?Colors.white10:Colors.black12):CachedNetworkImage(imageUrl:store.bannerUrl!,fit:BoxFit.cover,errorWidget:(_,__,___)=>Container(color:dark?Colors.white10:Colors.black12))),
                Container(minHeight:82,padding:const EdgeInsets.symmetric(horizontal:14,vertical:12),child:Row(children:[
                  Container(width:58,height:58,clipBehavior:Clip.antiAlias,decoration:BoxDecoration(color:Colors.white,shape:BoxShape.circle,border:Border.all(color:const Color(0xFFEEEEEE))),child:store.logoUrl==null?const Icon(Icons.storefront_outlined,size:22,color:Colors.black):CachedNetworkImage(imageUrl:store.logoUrl!,fit:BoxFit.contain,errorWidget:(_,__,___)=>const Icon(Icons.storefront_outlined,size:22,color:Colors.black))),
                  const SizedBox(width:11),
                  Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Text(store.name,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w700)),const SizedBox(height:3),Text(store.categoryName??'',style:const TextStyle(fontSize:9,color:spikeMuted))])),
                  Column(mainAxisAlignment:MainAxisAlignment.center,children:[Row(children:[const Icon(Icons.star_rounded,size:14,color:Color(0xFFF5B400)),const SizedBox(width:2),Text(store.reviewCount>0?store.rating.toStringAsFixed(1):'—',style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600)),if(store.reviewCount>0)Text(' (${store.reviewCount})',style:const TextStyle(fontSize:9,color:spikeMuted))]),const SizedBox(height:5),const Icon(Icons.arrow_back,size:20,color:spikeMuted)]),
                ])),
              ])));
            }));
          },
        )),
      ]),
    );
  }
}

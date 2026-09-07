import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../models/product.dart';
import '../../../widgets/product_card.dart';

class StoreDetailsScreen extends ConsumerStatefulWidget {
  const StoreDetailsScreen({super.key,required this.id});
  final String id;
  @override ConsumerState<StoreDetailsScreen> createState()=>_StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends ConsumerState<StoreDetailsScreen>{
  String _query='';
  String _sort='relevance';
  String _category='الكل';
  final Set<String> _favoriteBusy={};

  void _showSort(){
    showModalBottomSheet<void>(context:context,builder:(context)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(17,20,17,25),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Text('الترتيب حسب',style:TextStyle(fontSize:20,fontWeight:FontWeight.w700)),
      const SizedBox(height:18),
      for(final option in const [('relevance','الأكثر صلة'),('price-low','السعر: من الأقل للأعلى'),('price-high','السعر: من الأعلى للأقل'),('rating','الأعلى تقييماً')])
        SizedBox(height:48,child:ListTile(contentPadding:EdgeInsets.zero,title:Text(option.$2,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)),trailing:Radio<String>(value:option.$1,groupValue:_sort,onChanged:(v){if(v==null)return;setState(()=>_sort=v);Navigator.pop(context);}))
    ]))));
  }

  Future<void> _toggleFavorite(ProductModel p)async{
    if(_favoriteBusy.contains(p.id))return;
    setState(()=>_favoriteBusy.add(p.id));
    final ids=ref.read(wishlistIdsProvider).valueOrNull??<String>{};
    final active=ids.contains(p.id);
    try{if(active)await ref.read(engagementRepositoryProvider).removeWishlist(p.id);else await ref.read(engagementRepositoryProvider).addWishlist(p.id);ref.invalidate(wishlistIdsProvider);ref.invalidate(favoritesProvider);if(mounted)showSpikeToast(context,active?'تمت إزالة المنتج من المفضلة':'تمت إضافة المنتج إلى المفضلة');}catch(e){if(mounted)showSpikeToast(context,e.toString());}finally{if(mounted)setState(()=>_favoriteBusy.remove(p.id));}
  }

  Future<void> _add(ProductModel p)async{
    final v=p.cheapestVariant;if(v==null||!p.purchasable)return;
    try{await ref.read(cartRepositoryProvider).add(variantId:v.id);ref.invalidate(cartCountProvider);if(mounted)showSpikeToast(context,'تمت إضافة المنتج إلى السلة');}catch(e){if(mounted)showSpikeToast(context,e.toString());}
  }

  @override Widget build(BuildContext context){
    final stores=ref.watch(storesProvider);
    final products=ref.watch(allProductsProvider);
    final reviewsState=ref.watch(storeReviewsProvider(widget.id));
    final favorites=ref.watch(wishlistIdsProvider).valueOrNull??<String>{};
    final dark=Theme.of(context).brightness==Brightness.dark;
    return Scaffold(body:SafeArea(child:stores.when(
      loading:()=>const SpikeLoading(),
      error:(e,_)=>SpikeErrorState(message:e.toString(),onRetry:()=>ref.invalidate(storesProvider)),
      data:(storeList){
        final matching=storeList.where((s)=>s.id==widget.id);
        if(matching.isEmpty)return const SpikeEmptyState(message:'المتجر غير متاح حالياً');
        final store=matching.first;
        return products.when(
          loading:()=>const SpikeLoading(),
          error:(e,_)=>SpikeErrorState(message:e.toString(),onRetry:()=>ref.invalidate(allProductsProvider)),
          data:(all){
            final storeProducts=all.where((p)=>p.storeId==store.id).toList();
            final categories=<String>{for(final p in storeProducts)if((p.categoryName??'').trim().isNotEmpty)p.categoryName!.trim()}.toList()..sort();
            final q=_query.toLowerCase();
            final list=storeProducts.where((p){final mq=q.isEmpty||p.name.toLowerCase().contains(q)||(p.categoryName??'').toLowerCase().contains(q);final mc=_category=='الكل'||p.categoryName==_category;return mq&&mc;}).toList();
            if(_sort=='price-low')list.sort((a,b)=>a.price.compareTo(b.price));
            if(_sort=='price-high')list.sort((a,b)=>b.price.compareTo(a.price));
            if(_sort=='rating')list.sort((a,b)=>b.rating.compareTo(a.rating));
            final storeRating=reviewsState.valueOrNull;
            final rating=double.tryParse('${storeRating?['average']??store.rating}')??store.rating;
            final reviewsCount=int.tryParse('${storeRating?['count']??store.reviewCount}')??store.reviewCount;
            final reviews=(storeRating?['reviews'] as List? ?? const[]).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();

            return RefreshIndicator(onRefresh:()async{ref.invalidate(storesProvider);ref.invalidate(allProductsProvider);ref.invalidate(storeReviewsProvider(widget.id));ref.invalidate(wishlistIdsProvider);ref.invalidate(cartCountProvider);await ref.read(allProductsProvider.future);},child:CustomScrollView(slivers:[
              SliverToBoxAdapter(child:Column(children:[
                Padding(padding:const EdgeInsets.fromLTRB(17,8,17,12),child:Row(children:[
                  SizedBox(width:50,height:42,child:IconButton.filledTonal(onPressed:()=>context.pop(),icon:const Icon(Icons.arrow_forward,size:23))),
                  const SizedBox(width:9),
                  Expanded(child:Container(height:42,decoration:BoxDecoration(color:dark?spikeDarkPanel:spikeField,borderRadius:BorderRadius.circular(22)),child:TextField(onChanged:(v)=>setState(()=>_query=v.trim()),decoration:InputDecoration(hintText:'ابحث داخل ${store.name}',prefixIcon:const Icon(Icons.search,size:20),border:InputBorder.none,contentPadding:const EdgeInsets.symmetric(vertical:10))))),
                ])),
                Container(color:dark?spikeDarkPanel:Colors.white,child:Column(children:[
                  SizedBox(height:185,width:double.infinity,child:store.bannerUrl==null?Container(color:dark?Colors.white10:Colors.black12):CachedNetworkImage(imageUrl:store.bannerUrl!,fit:BoxFit.cover,errorWidget:(_,__,___)=>Container(color:dark?Colors.white10:Colors.black12))),
                  Transform.translate(offset:const Offset(0,-24),child:Padding(padding:const EdgeInsets.symmetric(horizontal:17),child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
                    Container(width:70,height:70,clipBehavior:Clip.antiAlias,decoration:BoxDecoration(color:Colors.white,shape:BoxShape.circle,border:Border.all(color:const Color(0xFFEEEEEE))),child:store.logoUrl==null?const Icon(Icons.storefront_outlined,color:Colors.black):CachedNetworkImage(imageUrl:store.logoUrl!,fit:BoxFit.contain,errorWidget:(_,__,___)=>const Icon(Icons.storefront_outlined,color:Colors.black))),
                    const SizedBox(width:12),
                    Expanded(child:Padding(padding:const EdgeInsets.only(bottom:4),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(store.name,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700)),const SizedBox(height:3),if((store.categoryName??'').isNotEmpty)Text(store.categoryName!,style:const TextStyle(fontSize:9,color:spikeMuted)),const Text('متجر موثوق على Spike',style:TextStyle(fontSize:9,color:spikeMuted))]))),
                    Container(margin:const EdgeInsets.only(bottom:4),padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),decoration:BoxDecoration(color:dark?Colors.white10:const Color(0xFFF1F1F1),borderRadius:BorderRadius.circular(18)),child:Row(children:[const Icon(Icons.star_rounded,size:14,color:Color(0xFFF5B400)),const SizedBox(width:2),Text(reviewsCount>0?rating.toStringAsFixed(1):'—',style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600)),if(reviewsCount>0)Text(' ($reviewsCount)',style:const TextStyle(fontSize:9,color:spikeMuted))])),
                  ]))),
                  Transform.translate(offset:const Offset(0,-12),child:Padding(padding:const EdgeInsets.symmetric(horizontal:17),child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[_stat('${storeProducts.length}','منتجات'),_stat('$reviewsCount','مراجعات'),_stat(reviewsCount>0?rating.toStringAsFixed(1):'—','التقييم')]))),
                ])),
                Padding(padding:const EdgeInsets.fromLTRB(17,14,17,0),child:Row(children:[
                  SizedBox(height:38,child:OutlinedButton.icon(onPressed:()=>setState(()=>_category=_category=='الكل'?(categories.isEmpty?'الكل':categories.first):'الكل'),icon:const Icon(Icons.sliders,size:17),label:const Text('فلتر',style:TextStyle(fontSize:11)),style:OutlinedButton.styleFrom(backgroundColor:dark?spikeDarkPanel:spikeField,side:BorderSide.none,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20))))),
                  const SizedBox(width:8),
                  SizedBox(height:38,child:OutlinedButton.icon(onPressed:_showSort,icon:const Icon(Icons.swap_vert,size:17),label:const Text('ترتيب',style:TextStyle(fontSize:11)),style:OutlinedButton.styleFrom(backgroundColor:dark?spikeDarkPanel:spikeField,side:BorderSide.none,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20))))),
                ])),
                if(categories.isNotEmpty)Padding(padding:const EdgeInsets.fromLTRB(17,8,17,0),child:SizedBox(height:35,child:ListView(scrollDirection:Axis.horizontal,children:[ChoiceChip(label:const Text('الكل',style:TextStyle(fontSize:10)),selected:_category=='الكل',onSelected:(_)=>setState(()=>_category='الكل'),showCheckmark:false),for(final category in categories)...[const SizedBox(width:7),ChoiceChip(label:Text(category,style:const TextStyle(fontSize:10)),selected:_category==category,onSelected:(_)=>setState(()=>_category=category),showCheckmark:false)]]))),
                if(reviews.isNotEmpty)Padding(padding:const EdgeInsets.fromLTRB(17,16,17,0),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('تقييمات العملاء',style:TextStyle(fontSize:16,fontWeight:FontWeight.w700)),Text('${reviews.length} تعليق',style:const TextStyle(fontSize:10,color:spikeMuted))]),const SizedBox(height:8),...reviews.take(3).map((r){final stars=int.tryParse('${r['rating']??0}')??0;final comment='${r['comment']??''}'.trim();return Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:dark?spikeDarkPanel:spikePanel,borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text('${r['name']??'عميل'}',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700))),Row(children:List.generate(5,(i)=>Icon(Icons.star_rounded,size:14,color:i<stars?const Color(0xFFF5B400):Theme.of(context).colorScheme.onSurface.withValues(alpha:.15))))]),if(comment.isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text(comment,style:const TextStyle(fontSize:11,height:1.45)))]));})])),
                Padding(padding:const EdgeInsets.fromLTRB(17,16,17,12),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('منتجات المتجر',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700)),Text('${list.length} منتج',style:const TextStyle(fontSize:10,color:spikeMuted))])),
              ])),
              if(list.isEmpty)const SliverToBoxAdapter(child:SpikeEmptyState(message:'لا توجد منتجات مطابقة'))else SliverPadding(padding:const EdgeInsets.fromLTRB(17,0,17,24),sliver:SliverGrid.builder(itemCount:list.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:11,mainAxisSpacing:11,mainAxisExtent:246),itemBuilder:(context,i){final p=list[i];return SpikeProductCard(product:p,isFavorite:favorites.contains(p.id),onTap:()=>context.push('/product/${p.id}'),onAdd:p.purchasable&&p.cheapestVariant!=null?()=>_add(p):null,onFavorite:_favoriteBusy.contains(p.id)?null:()=>_toggleFavorite(p));})),
            ]));
          },
        );
      },
    )));
  }

  Widget _stat(String value,String label)=>Column(children:[Text(value,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w700)),const SizedBox(height:2),Text(label,style:const TextStyle(fontSize:9,color:spikeMuted))]);
}

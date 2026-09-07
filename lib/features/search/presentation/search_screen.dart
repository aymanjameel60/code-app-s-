import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../models/product.dart';
import '../../../widgets/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key,this.initialQuery=''}); final String initialQuery;
  @override ConsumerState<SearchScreen> createState()=>_SearchScreenState();
}
class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller=TextEditingController(text:widget.initialQuery);
  final Set<String> _favoriteBusy={};
  String _query='',_sort='relevance',_category='الكل'; bool _offersOnly=false;
  @override void initState(){super.initState();_query=widget.initialQuery.trim();}
  @override void dispose(){_controller.dispose();super.dispose();}
  double _discount(ProductModel p){final o=p.originalPrice??0;return o>p.price&&o>0?(o-p.price)/o:0;}
  void _showSort(){showModalBottomSheet<void>(context:context,showDragHandle:true,builder:(sheetContext)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('الترتيب حسب',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),for(final o in const[('relevance','الأكثر صلة'),('price-low','السعر الأقل'),('price-high','السعر الأعلى'),('rating','الأعلى تقييماً'),('discount','الأعلى خصماً')])RadioListTile<String>(value:o.$1,groupValue:_sort,title:Text(o.$2),onChanged:(v){if(v!=null)setState(()=>_sort=v);Navigator.pop(sheetContext);})])));}

  Future<void> _toggleFavorite(ProductModel p) async {
    if(_favoriteBusy.contains(p.id))return;
    setState(()=>_favoriteBusy.add(p.id));
    final ids=ref.read(wishlistIdsProvider).valueOrNull??<String>{};
    final active=ids.contains(p.id);
    try{
      if(active)await ref.read(engagementRepositoryProvider).removeWishlist(p.id);else await ref.read(engagementRepositoryProvider).addWishlist(p.id);
      ref.invalidate(wishlistIdsProvider);ref.invalidate(favoritesProvider);
      if(mounted)showSpikeToast(context,active?'تمت إزالة المنتج من المفضلة':'تمت إضافة المنتج إلى المفضلة');
    }catch(e){if(mounted)showSpikeToast(context,e.toString());}
    finally{if(mounted)setState(()=>_favoriteBusy.remove(p.id));}
  }

  @override Widget build(BuildContext context){
    final state=ref.watch(allProductsProvider),categories=ref.watch(categoriesProvider).valueOrNull??const[];
    final favorites=ref.watch(wishlistIdsProvider).valueOrNull??<String>{};
    return Scaffold(body:SafeArea(child:Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(17,8,17,6),child:Row(children:[IconButton(onPressed:()=>context.pop(),icon:const Icon(LucideIcons.arrowRight)),Expanded(child:SizedBox(height:43,child:TextField(controller:_controller,autofocus:true,textInputAction:TextInputAction.search,onChanged:(v)=>setState(()=>_query=v.trim()),decoration:InputDecoration(hintText:'ابحث عن المنتجات ...',filled:true,fillColor:Theme.of(context).brightness==Brightness.dark?spikeDarkPanel:spikeField,prefixIcon:const Icon(LucideIcons.search,size:19),suffixIcon:_query.isEmpty?null:IconButton(icon:const Icon(LucideIcons.x,size:17),onPressed:(){_controller.clear();setState(()=>_query='');}),contentPadding:EdgeInsets.zero,border:const OutlineInputBorder(borderSide:BorderSide.none,borderRadius:BorderRadius.all(Radius.circular(22))))))),IconButton(onPressed:_showSort,icon:const Icon(LucideIcons.slidersHorizontal,size:20))])),
      SizedBox(height:42,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:17),children:[FilterChip(label:const Text('عروض'),selected:_offersOnly,onSelected:(v)=>setState(()=>_offersOnly=v)),const SizedBox(width:7),ChoiceChip(label:const Text('الكل'),selected:_category=='الكل',onSelected:(_)=>setState(()=>_category='الكل')),for(final c in categories)...[const SizedBox(width:7),ChoiceChip(label:Text(c.name),selected:_category==c.name,onSelected:(_)=>setState(()=>_category=c.name))]])),
      Expanded(child:state.when(loading:()=>const SpikeLoading(),error:(e,_)=>SpikeErrorState(message:e.toString(),onRetry:()=>ref.invalidate(allProductsProvider)),data:(products){
        final q=_query.toLowerCase();
        final list=products.where((p){final matches=q.isEmpty||p.name.toLowerCase().contains(q)||p.storeName.toLowerCase().contains(q)||(p.categoryName??'').toLowerCase().contains(q);return matches&&(_category=='الكل'||p.categoryName==_category)&&(!_offersOnly||_discount(p)>0);}).toList();
        if(_sort=='price-low')list.sort((a,b)=>a.price.compareTo(b.price));
        if(_sort=='price-high')list.sort((a,b)=>b.price.compareTo(a.price));
        if(_sort=='rating')list.sort((a,b)=>b.rating.compareTo(a.rating));
        if(_sort=='discount')list.sort((a,b)=>_discount(b).compareTo(_discount(a)));
        if(list.isEmpty)return SpikeEmptyState(message:_query.isEmpty?'ابدأ بكتابة اسم المنتج أو المتجر':'لا توجد نتائج لـ "$_query"');
        return Column(children:[Padding(padding:const EdgeInsets.fromLTRB(17,8,17,3),child:Align(alignment:Alignment.centerRight,child:Text('${list.length} نتيجة',style:const TextStyle(fontSize:11,color:spikeMuted,fontWeight:FontWeight.w600)))),Expanded(child:GridView.builder(padding:const EdgeInsets.fromLTRB(17,5,17,24),itemCount:list.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:11,mainAxisSpacing:11,mainAxisExtent:246),itemBuilder:(context,i){final p=list[i];return SpikeProductCard(product:p,isFavorite:favorites.contains(p.id),onTap:()=>context.push('/product/${p.id}'),onStore:p.storeId==null?null:()=>context.push('/store/${p.storeId}'),onAdd:p.purchasable&&p.cheapestVariant!=null?()async{try{await ref.read(cartRepositoryProvider).add(variantId:p.cheapestVariant!.id);if(context.mounted)showSpikeToast(context,'تمت إضافة المنتج إلى السلة');}catch(e){if(context.mounted)showSpikeToast(context,e.toString());}}:null,onFavorite:_favoriteBusy.contains(p.id)?null:()=>_toggleFavorite(p));}))]);
      }))
    ])));
  }
}

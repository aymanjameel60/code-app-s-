import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../widgets/product_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoritesProvider);
    return Scaffold(body: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(17,8,17,4), child: SizedBox(height:46, child: Stack(alignment:Alignment.center,children:[const Text('المفضلة',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),Align(alignment:Alignment.centerRight,child:IconButton(onPressed:()=>context.pop(),icon:const Icon(LucideIcons.arrowRight,size:22)))]))),
      Expanded(child: state.when(
        loading: () => const SpikeLoading(),
        error: (e, _) => SpikeErrorState(message:e.toString(),onRetry:()=>ref.invalidate(favoritesProvider)),
        data: (products) {
          if (products.isEmpty) {
            return Column(mainAxisAlignment:MainAxisAlignment.center,children:[Container(width:72,height:72,decoration:BoxDecoration(color:Theme.of(context).brightness==Brightness.dark?spikeDarkPanel:spikePanel,shape:BoxShape.circle),child:const Icon(LucideIcons.heart,size:30,color:spikeRed)),const SizedBox(height:14),const Text('المفضلة فارغة',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900)),const SizedBox(height:5),const Text('احفظ المنتجات التي تعجبك لتجدها هنا بسهولة',style:TextStyle(fontSize:11,color:spikeMuted)),const SizedBox(height:18),FilledButton(style:FilledButton.styleFrom(backgroundColor:Colors.black),onPressed:()=>context.go('/'),child:const Text('ابدأ التسوق'))]);
          }
          return RefreshIndicator(onRefresh:()async{ref.invalidate(wishlistIdsProvider);ref.invalidate(favoritesProvider);await ref.read(favoritesProvider.future);},child:GridView.builder(padding:const EdgeInsets.fromLTRB(17,10,17,24),itemCount:products.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:11,mainAxisSpacing:11,mainAxisExtent:246),itemBuilder:(context,i){
            final p=products[i];
            return SpikeProductCard(product:p,isFavorite:true,onTap:()=>context.push('/product/${p.id}'),onStore:p.storeId==null?null:()=>context.push('/store/${p.storeId}'),onFavorite:()async{try{await ref.read(engagementRepositoryProvider).removeWishlist(p.id);ref.invalidate(wishlistIdsProvider);ref.invalidate(favoritesProvider);if(context.mounted)showSpikeToast(context,'تمت إزالة المنتج من المفضلة');}catch(e){if(context.mounted)showSpikeToast(context,e.toString());}},onAdd:p.cheapestVariant==null?null:()async{try{await ref.read(cartRepositoryProvider).add(variantId:p.cheapestVariant!.id);ref.invalidate(cartCountProvider);if(context.mounted)showSpikeToast(context,'تمت إضافة المنتج إلى السلة');}catch(e){if(context.mounted)showSpikeToast(context,e.toString());}});
          }));
        },
      ))
    ])));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../models/product.dart';
import '../../../widgets/product_card.dart';

class FavoritesScreen extends ConsumerWidget{const FavoritesScreen({super.key});
@override Widget build(BuildContext context,WidgetRef ref){final state=ref.watch(favoritesProvider);return Scaffold(appBar:AppBar(backgroundColor:Colors.transparent,title:const Text('المفضلة'),centerTitle:true),body:state.when(loading:()=>const SpikeLoading(),error:(e,_)=>SpikeErrorState(message:e.toString(),onRetry:()=>ref.invalidate(favoritesProvider)),data:(products){if(products.isEmpty)return const SpikeEmptyState(message:'المفضلة فارغة');return GridView.builder(padding:const EdgeInsets.all(17),itemCount:products.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:11,mainAxisSpacing:11,mainAxisExtent:246),itemBuilder:(context,i){final p=products[i];return SpikeProductCard(product:p,onTap:()=>context.push('/product/${p.id}'),onFavorite:()async{await ref.read(engagementRepositoryProvider).removeWishlist(p.id);ref.invalidate(favoritesProvider);},onAdd:p.cheapestVariant==null?null:()async{try{await ref.read(cartRepositoryProvider).add(variantId:p.cheapestVariant!.id);if(context.mounted)showSpikeToast(context,'تمت إضافة المنتج إلى السلة');}catch(e){if(context.mounted)showSpikeToast(context,e.toString());}});});}));}}

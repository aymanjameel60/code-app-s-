import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  int get _index {
    if (location.startsWith('/profile')) return 0;
    if (location.startsWith('/offers')) return 1;
    if (location.startsWith('/cart')) return 3;
    return 2;
  }

  @override Widget build(BuildContext context, WidgetRef ref) {
    final scheme=Theme.of(context).colorScheme;
    final dark=Theme.of(context).brightness==Brightness.dark;
    final cartCount=ref.watch(cartCountProvider).valueOrNull??0;
    return Scaffold(
      body:child,
      bottomNavigationBar:SafeArea(top:false,child:Container(
        height:64,
        padding:const EdgeInsets.symmetric(horizontal:SpikeSpacing.sm,vertical:SpikeSpacing.xs),
        decoration:BoxDecoration(color:dark?spikeDarkPanel:Colors.white,border:Border(top:BorderSide(color:scheme.onSurface.withValues(alpha:.08)))),
        child:Row(children:[
          _item(context,0,LucideIcons.userRound,'/profile'),
          _item(context,1,LucideIcons.badgePercent,'/offers'),
          _item(context,2,LucideIcons.home,'/'),
          _item(context,3,LucideIcons.shoppingBag,'/cart',badge:cartCount),
        ]),
      )),
    );
  }

  Widget _item(BuildContext context,int index,IconData icon,String route,{int badge=0}){
    final selected=_index==index,scheme=Theme.of(context).colorScheme;
    return Expanded(child:InkWell(borderRadius:BorderRadius.circular(SpikeRadius.control),onTap:()=>context.go(route),child:Center(child:AnimatedContainer(
      duration:const Duration(milliseconds:160),
      width:46,height:42,alignment:Alignment.center,
      decoration:BoxDecoration(color:selected?scheme.onSurface.withValues(alpha:.08):Colors.transparent,borderRadius:BorderRadius.circular(SpikeRadius.control)),
      child:Stack(clipBehavior:Clip.none,alignment:Alignment.center,children:[
        Icon(icon,size:23,color:selected?scheme.onSurface:scheme.onSurface.withValues(alpha:.55)),
        if(badge>0)Positioned(left:-10,top:-9,child:Container(constraints:const BoxConstraints(minWidth:17,minHeight:17),padding:const EdgeInsets.symmetric(horizontal:SpikeSpacing.xs),alignment:Alignment.center,decoration:const BoxDecoration(color:spikeRed,shape:BoxShape.circle),child:Text(badge>99?'99+':'$badge',style:const TextStyle(color:Colors.white,fontSize:8,fontWeight:FontWeight.w900)))),
      ]),
    ))));
  }
}

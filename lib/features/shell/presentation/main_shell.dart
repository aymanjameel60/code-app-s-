import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MainShell extends StatelessWidget{
 const MainShell({super.key,required this.child,required this.location});final Widget child;final String location;
 int get _index{if(location.startsWith('/profile'))return 0;if(location.startsWith('/offers'))return 1;if(location.startsWith('/cart'))return 3;return 2;}
 @override Widget build(BuildContext context){final dark=Theme.of(context).brightness==Brightness.dark;return Scaffold(body:child,bottomNavigationBar:SafeArea(top:false,child:Container(height:62,decoration:BoxDecoration(color:dark?const Color(0xFF151515):Colors.white,border:const Border(top:BorderSide(color:Color(0x11000000)))),child:Row(children:[_item(context,0,LucideIcons.userRound,'/profile'),_item(context,1,LucideIcons.badgePercent,'/offers'),_item(context,2,LucideIcons.home,'/'),_item(context,3,LucideIcons.shoppingBag,'/cart')]))));}
 Widget _item(BuildContext context,int index,IconData icon,String route){final selected=_index==index;return Expanded(child:InkWell(onTap:()=>context.go(route),child:Center(child:AnimatedContainer(duration:const Duration(milliseconds:160),width:44,height:40,alignment:Alignment.center,decoration:BoxDecoration(color:selected?const Color(0xFFF1F1F1):Colors.transparent,borderRadius:BorderRadius.circular(15)),child:Icon(icon,size:23,color:selected?Colors.black:Theme.of(context).colorScheme.onSurface.withValues(alpha:.55))))));}
}

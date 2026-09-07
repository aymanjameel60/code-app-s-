import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class ProfileScreen extends ConsumerWidget{const ProfileScreen({super.key});
@override Widget build(BuildContext context,WidgetRef ref){final user=ref.watch(currentUserProvider);return SafeArea(child:user.when(loading:()=>const SpikeLoading(),error:(e,_)=>SpikeErrorState(message:e.toString(),onRetry:()=>ref.invalidate(currentUserProvider)),data:(u){if(u==null)return Padding(padding:const EdgeInsets.all(17),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Icon(LucideIcons.userRound,size:52),const SizedBox(height:14),const Text('سجّل الدخول للوصول إلى حسابك',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),const SizedBox(height:18),SizedBox(width:double.infinity,height:48,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:spikeRed),onPressed:()=>context.push('/login'),child:const Text('تسجيل الدخول'))),TextButton(onPressed:()=>context.push('/signup'),child:const Text('إنشاء حساب جديد'))]));return ListView(padding:const EdgeInsets.all(17),children:[
  InkWell(borderRadius:BorderRadius.circular(24),onTap:()=>context.push('/personal-data'),child:Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:spikePanel,borderRadius:BorderRadius.circular(24)),child:Row(children:[const CircleAvatar(radius:28,child:Icon(LucideIcons.userRound)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${u['name']??''}',style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800)),Text('${u['email']??''}',style:const TextStyle(fontSize:11,color:Colors.black54))])),const Icon(LucideIcons.pencil,size:17)]))),const SizedBox(height:12),
  _tile(LucideIcons.heart,'المفضلة',()=>context.push('/favorites')),
  _tile(LucideIcons.shoppingBag,'الطلبات',()=>context.push('/orders')),
  _tile(LucideIcons.mapPin,'العناوين',()=>context.push('/addresses')),
  _tile(LucideIcons.rotateCcw,'المرتجعات والاستردادات',()=>context.push('/returns-refunds')),
  _tile(LucideIcons.star,'التقييمات',()=>context.push('/reviews')),
  _tile(LucideIcons.bell,'الإشعارات',()=>context.push('/notifications')),
  _tile(LucideIcons.messageCircle,'خدمة العملاء',()=>context.push('/support')),
  _tile(LucideIcons.settings,'الإعدادات',()=>showSpikeToast(context,'الإعدادات في المرحلة التالية')),
  const SizedBox(height:12),TextButton(onPressed:()async{await ref.read(authRepositoryProvider).logout();ref.invalidate(currentUserProvider);if(context.mounted)context.go('/profile');},child:const Text('تسجيل الخروج',style:TextStyle(color:spikeRed,fontWeight:FontWeight.w800)))
]);}));}
Widget _tile(IconData icon,String text,VoidCallback onTap)=>Container(margin:const EdgeInsets.only(bottom:8),decoration:BoxDecoration(color:spikePanel,borderRadius:BorderRadius.circular(18)),child:ListTile(onTap:onTap,leading:Icon(icon,size:21),title:Text(text,style:const TextStyle(fontWeight:FontWeight.w700)),trailing:const Icon(Icons.arrow_back_ios_new,size:14)));
}

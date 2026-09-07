import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget{const NotificationsScreen({super.key});@override ConsumerState<NotificationsScreen> createState()=>_NotificationsScreenState();}
class _NotificationsScreenState extends ConsumerState<NotificationsScreen>{Map<String,dynamic>? data;bool loading=true;
@override void initState(){super.initState();_load();}
Future<void> _load()async{setState(()=>loading=true);try{data=await ref.read(engagementRepositoryProvider).notifications();}catch(e){if(mounted)showSpikeToast(context,e.toString());}finally{if(mounted)setState(()=>loading=false);}}
@override Widget build(BuildContext context){if(loading)return const Scaffold(body:SpikeLoading());final items=(data?['notifications'] as List? ?? const []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();return Scaffold(appBar:AppBar(backgroundColor:Colors.transparent,title:const Text('الإشعارات'),centerTitle:true,actions:[if(items.isNotEmpty)TextButton(onPressed:()async{await ref.read(engagementRepositoryProvider).readAllNotifications();await _load();},child:const Text('قراءة الكل'))]),body:items.isEmpty?const SpikeEmptyState(message:'لا توجد إشعارات'):ListView.builder(padding:const EdgeInsets.all(17),itemCount:items.length,itemBuilder:(context,i){final n=items[i],unread=n['read_at']==null;return Container(margin:const EdgeInsets.only(bottom:9),decoration:BoxDecoration(color:unread?spikePanel:Colors.white,borderRadius:BorderRadius.circular(18)),child:ListTile(onTap:()async{await ref.read(engagementRepositoryProvider).readNotification('${n['id']}');setState(()=>n['read_at']=DateTime.now().toIso8601String());},leading:Icon(unread?LucideIcons.bellRing:LucideIcons.bell,size:21,color:unread?spikeRed:Colors.black54),title:Text('${n['title']??''}',style:TextStyle(fontWeight:unread?FontWeight.w800:FontWeight.w600)),subtitle:Text('${n['body']??''}',style:const TextStyle(fontSize:11)),trailing:unread?const CircleAvatar(radius:4,backgroundColor:spikeRed):null));}));}}

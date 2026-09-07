import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _readOne(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(engagementRepositoryProvider).readNotification(id);
      ref.invalidate(notificationsDataProvider);
    } catch (e) {
      if (context.mounted) showSpikeToast(context, e.toString());
    }
  }

  Future<void> _readAll(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(engagementRepositoryProvider).readAllNotifications();
      ref.invalidate(notificationsDataProvider);
    } catch (e) {
      if (context.mounted) showSpikeToast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(notificationsDataProvider);
    return Scaffold(body: SafeArea(child: state.when(
      loading: () => const SpikeLoading(),
      error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(notificationsDataProvider)),
      data: (data) {
        final raw = data['notifications'];
        final items = (raw is List ? raw : const <dynamic>[]).whereType<Map>().map((e) => Map<String,dynamic>.from(e)).toList();
        final unread = items.where((n) => n['read_at'] == null).length;
        return Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(17,8,17,4), child: SizedBox(height:46, child: Stack(alignment:Alignment.center, children:[
            Column(mainAxisAlignment:MainAxisAlignment.center, children:[const Text('الإشعارات',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),if(unread>0)Text('$unread غير مقروءة',style:const TextStyle(fontSize:9,color:spikeRed,fontWeight:FontWeight.w700))]),
            Align(alignment:Alignment.centerRight,child:IconButton(onPressed:()=>context.pop(),icon:const Icon(LucideIcons.arrowRight,size:22))),
            if(items.isNotEmpty)Align(alignment:Alignment.centerLeft,child:TextButton(onPressed:unread==0?null:()=>_readAll(context,ref),child:const Text('قراءة الكل',style:TextStyle(fontSize:11))))
          ]))),
          Expanded(child: items.isEmpty
              ? const SpikeEmptyState(message:'لا توجد إشعارات حالياً')
              : RefreshIndicator(
                  onRefresh: () async { ref.invalidate(notificationsDataProvider); await ref.read(notificationsDataProvider.future); },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(17,10,17,24),
                    itemCount: items.length,
                    itemBuilder: (context,i) {
                      final n=items[i], isUnread=n['read_at']==null;
                      return InkWell(
                        onTap:isUnread?()=>_readOne(context,ref,'${n['id']}'):null,
                        borderRadius:BorderRadius.circular(18),
                        child:Container(
                          margin:const EdgeInsets.only(bottom:9),
                          padding:const EdgeInsets.symmetric(horizontal:13,vertical:10),
                          decoration:BoxDecoration(color:dark?spikeDarkPanel:(isUnread?const Color(0xFFFFF3F3):spikePanel),borderRadius:BorderRadius.circular(18)),
                          child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                            Container(width:40,height:40,decoration:BoxDecoration(color:isUnread?spikeRed:Colors.black12,shape:BoxShape.circle),child:Icon(isUnread?LucideIcons.bellRing:LucideIcons.bell,size:18,color:isUnread?Colors.white:spikeMuted)),
                            const SizedBox(width:11),
                            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                              Row(children:[Expanded(child:Text('${n['title']??''}',style:TextStyle(fontSize:13,fontWeight:isUnread?FontWeight.w900:FontWeight.w700))),if(isUnread)const CircleAvatar(radius:4,backgroundColor:spikeRed)]),
                              const SizedBox(height:4),
                              Text('${n['body']??''}',style:TextStyle(fontSize:11,height:1.5,color:dark?Colors.white70:spikeMuted)),
                            ])),
                          ]),
                        ),
                      );
                    },
                  ),
                )),
        ]);
      },
    )));
  }
}

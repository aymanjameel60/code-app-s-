import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.mode, this.afterLoginRoute = '/profile'});
  final String mode;
  final String afterLoginRoute;
  @override ConsumerState<AuthScreen> createState()=>_AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>{
  final _name=TextEditingController();
  final _phone=TextEditingController();
  final _password=TextEditingController();
  bool _busy=false;
  bool get signup=>widget.mode=='signup';

  @override void dispose(){_name.dispose();_phone.dispose();_password.dispose();super.dispose();}

  Future<void> _submit()async{
    if(_busy)return;
    if(_phone.text.trim().isEmpty||_password.text.isEmpty||(signup&&_name.text.trim().isEmpty)){showSpikeToast(context,'أكمل الحقول المطلوبة');return;}
    if(signup&&_password.text.length<8){showSpikeToast(context,'يجب أن لا تقل كلمة المرور عن 8 أحرف');return;}
    setState(()=>_busy=true);
    try{
      final repo=ref.read(authRepositoryProvider);
      if(signup){await repo.register(name:_name.text,phone:_phone.text,password:_password.text);}else{await repo.login(phone:_phone.text,password:_password.text);}
      try{await ref.read(cartRepositoryProvider).mergeGuestCart();}catch(_){ }
      ref.invalidate(currentUserProvider);ref.invalidate(cartCountProvider);
      if(mounted)context.go(widget.afterLoginRoute);
    }catch(e){if(mounted)showSpikeToast(context,e.toString());}finally{if(mounted)setState(()=>_busy=false);}
  }

  @override Widget build(BuildContext context){
    final dark=Theme.of(context).brightness==Brightness.dark;
    final muted=Theme.of(context).colorScheme.onSurface.withValues(alpha:.6);
    final field=dark?spikeDarkPanel:const Color(0xFFE7E7E7);
    return Scaffold(body:SafeArea(child:Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(17,8,17,0),child:Column(children:[
        SizedBox(height:92,child:Stack(children:[Align(alignment:Alignment.centerRight,child:SizedBox(width:50,height:40,child:Material(color:dark?spikeDarkPanel:const Color(0xFFE8E8E8),borderRadius:BorderRadius.circular(22),child:InkWell(borderRadius:BorderRadius.circular(22),onTap:()=>context.canPop()?context.pop():context.go('/profile'),child:const Icon(LucideIcons.arrowRight,size:23)))))])),
        SizedBox(height:60,child:Align(alignment:Alignment.centerRight,child:Text(signup?'تسجيل الحساب':'تسجيل الدخول',style:const TextStyle(fontSize:21,fontWeight:FontWeight.w700))))
      ])),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(17,0,17,24),children:[
        if(signup)...[_field(_name,'ادخل اسمك',LucideIcons.user,field),const SizedBox(height:12)],
        _field(_phone,'رقم الجوال',LucideIcons.phone,field,keyboard:TextInputType.phone),const SizedBox(height:12),
        _field(_password,'ادخل كلمة السر',LucideIcons.lockKeyhole,field,obscure:true),
        if(signup)Padding(padding:const EdgeInsets.fromLTRB(12,5,12,0),child:Text('* يجب أن لا تقل كلمة المرور عن 8 أحرف',style:TextStyle(fontSize:10,color:muted)))
        else Align(alignment:Alignment.center,child:TextButton(onPressed:()=>context.push('/password-reset'),child:const Text('هل نسيت كلمة المرور؟',style:TextStyle(fontSize:12)))),
        const SizedBox(height:12),
        SizedBox(height:46,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:spikeRed,foregroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),onPressed:_busy?null:_submit,child:_busy?const SizedBox.square(dimension:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Text(signup?'تسجيل الحساب':'تسجيل الدخول',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)))),
        TextButton(onPressed:()=>context.go('${signup?'/login':'/signup'}?next=${Uri.encodeComponent(widget.afterLoginRoute)}'),child:Text(signup?'تمتلك حساب؟ قم بتسجيل الدخول من هنا':'لا تملك حساباً؟ قم بإنشاء حساب من هنا',style:const TextStyle(fontSize:12)))
      ]))
    ])));
  }

  Widget _field(TextEditingController controller,String hint,IconData icon,Color fill,{bool obscure=false,TextInputType? keyboard})=>SizedBox(height:54,child:TextField(controller:controller,obscureText:obscure,keyboardType:keyboard,decoration:InputDecoration(hintText:hint,filled:true,fillColor:fill,border:OutlineInputBorder(borderSide:BorderSide.none,borderRadius:BorderRadius.circular(15)),enabledBorder:OutlineInputBorder(borderSide:BorderSide.none,borderRadius:BorderRadius.circular(15)),focusedBorder:OutlineInputBorder(borderSide:BorderSide.none,borderRadius:BorderRadius.circular(15)),contentPadding:const EdgeInsets.symmetric(horizontal:16),suffixIcon:Padding(padding:const EdgeInsetsDirectional.only(end:8),child:Icon(icon,size:20)),suffixIconConstraints:const BoxConstraints(minWidth:42))));
}

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../features/catalog/presentation/categories_screen.dart';
import '../features/catalog/presentation/product_details_screen.dart';
import '../features/catalog/presentation/products_screen.dart';
import '../features/favorites/presentation/favorites_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/offers/presentation/offers_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/shell/presentation/main_shell.dart';
import '../features/stores/presentation/store_details_screen.dart';
import '../features/stores/presentation/stores_screen.dart';

final appRouter=GoRouter(routes:[
  ShellRoute(builder:(context,state,child)=>MainShell(child:child,location:state.uri.path),routes:[
    GoRoute(path:'/',builder:(_,__)=>const HomeScreen()),
    GoRoute(path:'/offers',builder:(_,__)=>const OffersScreen()),
    GoRoute(path:'/cart',builder:(_,__)=>const CartScreen()),
    GoRoute(path:'/profile',builder:(_,__)=>const ProfileScreen()),
  ]),
  GoRoute(path:'/login',builder:(_,__)=>const AuthScreen(mode:'login')),
  GoRoute(path:'/signup',builder:(_,__)=>const AuthScreen(mode:'signup')),
  GoRoute(path:'/favorites',builder:(_,__)=>const FavoritesScreen()),
  GoRoute(path:'/categories',builder:(_,__)=>const CategoriesScreen()),
  GoRoute(path:'/stores',builder:(_,__)=>const StoresScreen()),
  GoRoute(path:'/store/:id',builder:(_,state)=>StoreDetailsScreen(id:state.pathParameters['id']!)),
  GoRoute(path:'/products',builder:(_,state)=>ProductsScreen(categoryId:state.uri.queryParameters['category'],collectionId:state.uri.queryParameters['collection'],title:state.uri.queryParameters['title']??'المنتجات')),
  GoRoute(path:'/product/:id',builder:(_,state)=>ProductDetailsScreen(id:state.pathParameters['id']!)),
  GoRoute(path:'/search',builder:(_,state)=>SearchScreen(initialQuery:state.uri.queryParameters['q']??'')),
],errorBuilder:(_,__)=>const Directionality(textDirection:TextDirection.rtl,child:Center(child:Text('الصفحة غير موجودة'))));

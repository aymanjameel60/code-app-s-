import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/widgets/async_state_widgets.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeDataProvider);
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('الفئات'), centerTitle: true),
      body: state.when(
        loading: () => const SpikeLoading(),
        error: (e, _) => SpikeErrorState(onRetry: () => ref.invalidate(homeDataProvider)),
        data: (data) => data.categories.isEmpty
            ? const SpikeEmptyState(message: 'لا توجد أقسام منشورة بعد')
            : GridView.builder(
                padding: const EdgeInsets.all(17),
                itemCount: data.categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 11, mainAxisSpacing: 13, childAspectRatio: .78),
                itemBuilder: (context, i) {
                  final category = data.categories[i];
                  return InkWell(
                    onTap: () => context.push('/products?category=${Uri.encodeComponent(category.id)}&title=${Uri.encodeComponent(category.name)}'),
                    borderRadius: BorderRadius.circular(21),
                    child: Column(children: [
                      Container(width: 81, height: 81, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21)), child: category.imageUrl == null ? const Icon(Icons.image_outlined, color: Colors.black26) : CachedNetworkImage(imageUrl: category.imageUrl!, fit: BoxFit.cover)),
                      const SizedBox(height: 7),
                      Text(category.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.2)),
                    ]),
                  );
                },
              ),
      ),
    );
  }
}

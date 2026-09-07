import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class StoresScreen extends ConsumerStatefulWidget {
  const StoresScreen({super.key});
  @override ConsumerState<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends ConsumerState<StoresScreen> {
  String _query = '';
  String _sort = 'newest';

  @override Widget build(BuildContext context) {
    final state = ref.watch(storesProvider);
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('المتاجر'), centerTitle: true),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17),
          child: TextField(
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: 'البحث عن متجر', filled: true, fillColor: spikeField, prefixIcon: const Icon(Icons.search),
              suffixIcon: PopupMenuButton<String>(initialValue: _sort, onSelected: (v) => setState(() => _sort = v), itemBuilder: (_) => const [PopupMenuItem(value: 'newest', child: Text('الأحدث')), PopupMenuItem(value: 'name', child: Text('الاسم أبجدياً'))]),
              border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(22))),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: state.when(
            loading: () => const SpikeLoading(),
            error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(storesProvider)),
            data: (stores) {
              final list = stores.where((s) => _query.isEmpty || s.name.toLowerCase().contains(_query.toLowerCase())).toList();
              if (_sort == 'name') list.sort((a, b) => a.name.compareTo(b.name));
              if (list.isEmpty) return const SpikeEmptyState(message: 'لا توجد متاجر مطابقة');
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(17, 0, 17, 20), itemCount: list.length, separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final store = list[i];
                  return InkWell(
                    onTap: () => context.push('/store/${store.id}'),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      height: 92, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: spikePanel, borderRadius: BorderRadius.circular(22)),
                      child: Row(children: [
                        Container(width: 68, height: 68, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: store.logoUrl == null ? const Icon(Icons.storefront_outlined) : CachedNetworkImage(imageUrl: store.logoUrl!, fit: BoxFit.contain)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(store.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                        const Icon(Icons.arrow_back),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_product_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MyProductsNotifier)
final myProductsProvider = MyProductsNotifierProvider._();

final class MyProductsNotifierProvider
    extends $AsyncNotifierProvider<MyProductsNotifier, List<ProductModel>> {
  MyProductsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myProductsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myProductsNotifierHash();

  @$internal
  @override
  MyProductsNotifier create() => MyProductsNotifier();
}

String _$myProductsNotifierHash() =>
    r'81b1e8fc8d64dec6a0e8368bd58070abe028b240';

abstract class _$MyProductsNotifier extends $AsyncNotifier<List<ProductModel>> {
  FutureOr<List<ProductModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ProductModel>>, List<ProductModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ProductModel>>, List<ProductModel>>,
              AsyncValue<List<ProductModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

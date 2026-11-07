import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/profile/catalog.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../bloc/catalog_picker_bloc.dart';

/// Abre el buscador de carreras del catálogo y devuelve la elegida.
Future<Degree?> showCatalogDegreePicker(BuildContext context) {
  return showModalBottomSheet<Degree>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => BlocProvider(
      create: (_) =>
          getIt<CatalogPickerBloc>()..add(const CatalogPickerEvent.started()),
      child: const _CatalogPickerView(),
    ),
  );
}

class _CatalogPickerView extends StatefulWidget {
  const _CatalogPickerView();

  @override
  State<_CatalogPickerView> createState() => _CatalogPickerViewState();
}

class _CatalogPickerViewState extends State<_CatalogPickerView> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<CatalogPickerBloc>().add(
          CatalogPickerEvent.queryChanged(value),
        );
      }
    });
  }

  void _resetSearch() {
    _debounce?.cancel();
    _search.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: BlocBuilder<CatalogPickerBloc, CatalogPickerState>(
        builder: (context, state) {
          final university = state.university;
          return Padding(
            padding: EdgeInsets.only(
              left: TokensSpacing.m,
              right: TokensSpacing.m,
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (university != null)
                      IconButton(
                        tooltip: l10n.commonBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () {
                          _resetSearch();
                          context.read<CatalogPickerBloc>().add(
                            const CatalogPickerEvent.universityCleared(),
                          );
                        },
                      ),
                    Expanded(
                      child: Text(
                        university == null
                            ? l10n.profileCatalogPickUniversity
                            : l10n.profileCatalogPickDegree,
                        style: context.textStyles.titleLarge,
                      ),
                    ),
                  ],
                ),
                if (university != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TokensSpacing.s),
                    child: Text(
                      university.name,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: TokensSpacing.s),
                AppSearchField(
                  label: university == null
                      ? l10n.profileCatalogSearchUniversity
                      : l10n.profileCatalogSearchDegree,
                  controller: _search,
                  onChanged: _onQuery,
                ),
                const SizedBox(height: TokensSpacing.s),
                Expanded(child: _results(context, state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _results(BuildContext context, CatalogPickerState state) {
    final l10n = context.localizations;
    final bloc = context.read<CatalogPickerBloc>();
    switch (state.status) {
      case CatalogPickerStatus.loading:
        return AppSkeletonGroup(
          child: ListView(
            children: [
              for (var i = 0; i < 6; i++)
                const Padding(
                  padding: EdgeInsets.only(bottom: TokensSpacing.s),
                  child: AppSkeleton(height: 56),
                ),
            ],
          ),
        );
      case CatalogPickerStatus.failure:
        return AppErrorView(
          error: state.error!,
          onRetry: () => bloc.add(CatalogPickerEvent.queryChanged(state.query)),
        );
      case CatalogPickerStatus.ready:
        final university = state.university;
        if (university == null) {
          if (state.universities.isEmpty) {
            return AppEmptyState(
              icon: Icons.account_balance_outlined,
              title: l10n.profileCatalogNoUniversities,
              message: l10n.profileCatalogNoResultsHint,
            );
          }
          return ListView.separated(
            itemCount: state.universities.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = state.universities[i];
              return AppFocusOutline(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_outlined),
                  title: Text(item.name),
                  subtitle: item.type == null && item.region == null
                      ? null
                      : Text([?item.type, ?item.region].join(' · ')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    _resetSearch();
                    bloc.add(CatalogPickerEvent.universitySelected(item));
                  },
                ),
              );
            },
          );
        }
        if (state.degrees.isEmpty) {
          return AppEmptyState(
            icon: Icons.school_outlined,
            title: l10n.profileCatalogNoDegrees,
            message: l10n.profileCatalogNoResultsHint,
          );
        }
        return ListView.separated(
          itemCount: state.degrees.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final degree = state.degrees[i];
            return AppFocusOutline(
              child: ListTile(
                leading: Icon(
                  Icons.school_outlined,
                  color: context.palette.study,
                ),
                title: Text(degree.name),
                subtitle: degree.centerName == null
                    ? null
                    : Text(degree.centerName!),
                onTap: () => Navigator.of(context).pop(
                  degree.universityName == null
                      ? degree.copyWith(
                          universityId: university.id,
                          universityName: university.name,
                        )
                      : degree,
                ),
              ),
            );
          },
        );
    }
  }
}

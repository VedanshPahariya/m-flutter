import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import 'seeker_jobs_screen.dart';
import 'seeker_repository.dart';

/// `m/seeker/saved_jobs`.
class SeekerSavedScreen extends StatelessWidget {
  const SeekerSavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved jobs')),
      body: AsyncView<List<Job>>(
        load: SeekerRepository(context.api).savedJobs,
        what: 'saved jobs',
        skeleton: const SkeletonList(),
        isEmpty: (l) => l.isEmpty,
        empty: (_) => const EmptyView(
          icon: Icons.bookmark_outline,
          title: 'No saved jobs',
          message: 'Tap the bookmark on a job to keep it here.',
        ),
        builder: (context, list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(indent: 16),
          itemBuilder: (context, i) => JobRow(job: list[i]),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/paged_list.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import 'seeker_repository.dart';

/// Job search over `m/jobs` (keyword) and `m/jobs/category/{slug}`.
class SeekerJobsScreen extends StatefulWidget {
  const SeekerJobsScreen({super.key});

  @override
  State<SeekerJobsScreen> createState() => _SeekerJobsScreenState();
}

class _SeekerJobsScreenState extends State<SeekerJobsScreen> {
  final _search = TextEditingController();
  String _keyword = '';
  String? _category;
  List<JobCategory> _categories = const [];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = SeekerRepository(context.api);
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(title: const Text('Find jobs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: SearchField(
              controller: _search,
              hint: 'Job title, skill or keyword',
              onSubmitted: (v) => setState(() => _keyword = v.trim()),
            ),
          ),
          if (_categories.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                children: [
                  for (final c in [null, ..._categories])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c?.name ?? 'All'),
                        selected: _category == c?.slug,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: _category == c?.slug ? k.base : k.ink,
                        ),
                        onSelected: (_) => setState(() => _category = c?.slug),
                      ),
                    ),
                ],
              ),
            ),
          const Divider(),
          Expanded(
            child: PagedListView<Job>(
              key: ValueKey('$_keyword|$_category'),
              what: 'jobs',
              fetch: (offset) async {
                final r = await repo.jobs(
                  offset: offset,
                  keyword: _keyword,
                  category: _category,
                );
                if (mounted && _categories.isEmpty && r.categories.isNotEmpty) {
                  setState(() => _categories = r.categories);
                }
                return r.page;
              },
              empty: (_) => EmptyView(
                icon: Icons.work_off_outlined,
                title: _keyword.isEmpty
                    ? 'No open jobs right now'
                    : 'No jobs match “$_keyword”',
                message: 'New openings are posted regularly. Check back soon.',
              ),
              itemBuilder: (context, job, _) => JobRow(job: job),
            ),
          ),
        ],
      ),
    );
  }
}

class JobRow extends StatelessWidget {
  const JobRow({super.key, required this.job, this.trailing});

  final Job job;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return ListTile(
      title: Text(
        job.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          job.company,
          job.city,
          job.jobType,
          if (job.salary.isNotEmpty) '₹${job.salary}',
        ].where((s) => s.isNotEmpty).join(' · '),
        style: TextStyle(color: k.ink3),
      ),
      trailing:
          trailing ??
          (job.postedAt.isEmpty
              ? null
              : Text(
                  formatAge(job.postedAt),
                  style: TextStyle(fontSize: 12, color: k.ink3),
                )),
      onTap: job.id.isEmpty
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
            ),
    );
  }
}

/// `m/jobs/detail/{id}` with apply and save actions.
class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final repo = SeekerRepository(context.api);
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job'),
        actions: [
          IconButton(
            tooltip: 'Save job',
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: () => runAction(
              context,
              () => repo.saveJob(job.id),
              successOf: (m) => m,
            ),
          ),
        ],
      ),
      body: AsyncView<Job>(
        load: () => repo.jobDetail(job.id),
        what: 'this job',
        skeleton: const SkeletonDetail(),
        builder: (context, j) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              j.title,
              style: context.text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [j.company, j.city].where((s) => s.isNotEmpty).join(' · '),
              style: TextStyle(color: k.ink3),
            ),
            const SizedBox(height: 16),
            CardGroup(
              margin: EdgeInsets.zero,
              children: [
                KeyValueRow('Job type', j.jobType),
                KeyValueRow('Salary', j.salary.isEmpty ? '' : '₹${j.salary}'),
                KeyValueRow('Experience', j.experience),
                KeyValueRow('Posted', formatDate(j.postedAt)),
              ],
            ),
            if (j.description.isNotEmpty) ...[
              const SectionLabel('Description'),
              Text(j.description),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: BusyButton(
            label: 'Apply now',
            icon: Icons.send,
            onPressed: () async {
              await runAction(
                context,
                () => repo.apply(job.id),
                successOf: (m) => m,
              );
            },
          ),
        ),
      ),
    );
  }
}

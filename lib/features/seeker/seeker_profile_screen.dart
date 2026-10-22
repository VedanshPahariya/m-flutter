import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/json.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/skeleton.dart';
import '../../shared/account_actions.dart';
import 'seeker_repository.dart';

class _ProfileData {
  const _ProfileData(this.dashboard, this.profile);

  final SeekerDashboard dashboard;
  final SeekerProfile profile;
}

/// Read-only profile from `m/seeker/dashboard` and `m/seeker/public_profile`.
/// Editing (profile, education, experience, resume upload) is not offered:
/// those POST endpoints were skipped in the inventory, so their fields are
/// unknown.
class SeekerProfileScreen extends StatelessWidget {
  const SeekerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = SeekerRepository(context.api);
    final k = context.kora;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: AsyncView<_ProfileData>(
        load: () async {
          final r = await Future.wait<Object>([
            repo.dashboard(),
            repo.profile(),
          ]);
          return _ProfileData(r[0] as SeekerDashboard, r[1] as SeekerProfile);
        },
        what: 'your profile',
        skeleton: const SkeletonDetail(),
        builder: (context, d) {
          final f = d.profile.fields;
          final s = d.dashboard.stats;
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Avatar(
                      initialsOf(str(f, const ['full_name'], 'J')),
                      size: 56,
                      highlighted: true,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            str(f, const ['full_name']),
                            style: context.text.titleLarge,
                          ),
                          Text(
                            str(f, const ['email']),
                            style: TextStyle(color: k.ink3),
                          ),
                          Text(
                            str(f, const ['mobile']),
                            style: TextStyle(color: k.ink3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile ${d.dashboard.completion}% complete',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ProgressBar(value: d.dashboard.completion / 100),
                        const SizedBox(height: 6),
                        Text(
                          'Complete your profile on the job portal website to stand out to employers.',
                          style: TextStyle(fontSize: 12, color: k.ink3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        value: '${intOf(s, const ['total'])}',
                        label: 'Applied',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatTile(
                        value: '${intOf(s, const ['shortlisted'])}',
                        label: 'Shortlisted',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatTile(
                        value: '${intOf(s, const ['interview'])}',
                        label: 'Interviews',
                      ),
                    ),
                  ],
                ),
              ),
              const SectionLabel('DETAILS'),
              CardGroup(
                children: [
                  KeyValueRow('Qualification', str(f, const ['qualification'])),
                  KeyValueRow(
                    'Experience',
                    '${str(f, const ['experience_years'], '0')} years',
                  ),
                  KeyValueRow(
                    'Current role',
                    [
                      str(f, const ['current_position']),
                      str(f, const ['current_company']),
                    ].where((x) => x.isNotEmpty).join(' at '),
                  ),
                  KeyValueRow(
                    'Location',
                    [
                      str(f, const ['city']),
                      str(f, const ['state']),
                    ].where((x) => x.isNotEmpty).join(', '),
                  ),
                  KeyValueRow(
                    'Preferred job',
                    str(f, const ['preferred_job_type']),
                  ),
                  KeyValueRow(
                    'Resume',
                    str(f, const ['resume_original_name'], 'Not uploaded'),
                  ),
                ],
              ),
              if (d.profile.education.isNotEmpty) ...[
                const SectionLabel('EDUCATION'),
                CardGroup(
                  children: [
                    for (final e in d.profile.education)
                      ListTile(
                        title: Text(
                          str(e, const [
                            'degree',
                            'qualification',
                            'title',
                          ], 'Education'),
                        ),
                        subtitle: Text(
                          [
                            str(e, const [
                              'institution',
                              'institute',
                              'school',
                            ]),
                            str(e, const ['year', 'end_year', 'passing_year']),
                          ].where((x) => x.isNotEmpty).join(' · '),
                        ),
                      ),
                  ],
                ),
              ],
              if (d.profile.experience.isNotEmpty) ...[
                const SectionLabel('EXPERIENCE'),
                CardGroup(
                  children: [
                    for (final e in d.profile.experience)
                      ListTile(
                        title: Text(
                          str(e, const [
                            'designation',
                            'position',
                            'title',
                          ], 'Experience'),
                        ),
                        subtitle: Text(
                          [
                            str(e, const ['company', 'company_name']),
                            str(e, const ['start_date', 'from_date']),
                          ].where((x) => x.isNotEmpty).join(' · '),
                        ),
                      ),
                  ],
                ),
              ],
              const SectionLabel('PREFERENCES'),
              const CardGroup(children: [ThemeSelector()]),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: k.danger,
                    side: BorderSide(color: k.danger),
                  ),
                  onPressed: () => confirmSignOut(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import '../../core/api/api_client.dart';
import '../../core/api/api_response.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/json.dart';
import '../../core/widgets/paged_list.dart';

/// A job posting. No populated job row was captured (every job list was
/// empty), so keys are read tolerantly. The company record shape is
/// verified from `m/jobs/company/{id}`.
class Job {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.city,
    required this.jobType,
    required this.salary,
    required this.postedAt,
    required this.description,
    required this.experience,
    required this.raw,
  });

  factory Job.fromJson(JsonMap j) {
    final min = str(j, const ['salary_min']);
    final max = str(j, const ['salary_max']);
    return Job(
      id: str(j, const ['id', 'job_id']),
      title: str(j, const ['title', 'job_title'], 'Job'),
      company: str(j, const ['company_name', 'company']),
      city: str(j, const ['city', 'location']),
      jobType: str(j, const ['job_type', 'employment_type']),
      salary: min.isEmpty && max.isEmpty
          ? str(j, const ['salary'])
          : [min, max].where((s) => s.isNotEmpty).join(' – '),
      postedAt: str(j, const ['posted_at', 'created_at']),
      description: str(j, const ['description', 'job_description']),
      experience: str(j, const [
        'experience',
        'experience_min',
        'experience_required',
      ]),
      raw: j,
    );
  }

  final String id;
  final String title;
  final String company;
  final String city;
  final String jobType;
  final String salary;
  final String postedAt;
  final String description;
  final String experience;
  final JsonMap raw;
}

class JobCategory {
  const JobCategory({required this.slug, required this.name});

  final String slug;
  final String name;
}

class JobSearchResult {
  const JobSearchResult({required this.page, required this.categories});

  final PageResult<Job> page;
  final List<JobCategory> categories;
}

class Application {
  const Application({
    required this.id,
    required this.jobTitle,
    required this.company,
    required this.status,
    required this.appliedAt,
  });

  factory Application.fromJson(JsonMap j) => Application(
    id: str(j, const ['id', 'application_id']),
    jobTitle: str(j, const ['job_title', 'title'], 'Job'),
    company: str(j, const ['company_name', 'company']),
    status: str(j, const ['status'], 'applied'),
    appliedAt: str(j, const ['applied_at', 'created_at']),
  );

  final String id;
  final String jobTitle;
  final String company;
  final String status;
  final String appliedAt;

  bool get canWithdraw => !const [
    'withdrawn',
    'rejected',
    'selected',
    'hired',
  ].contains(status.toLowerCase());
}

class Interview {
  const Interview({
    required this.jobTitle,
    required this.company,
    required this.when,
    required this.mode,
    required this.status,
  });

  factory Interview.fromJson(JsonMap j) => Interview(
    jobTitle: str(j, const ['job_title', 'title'], 'Interview'),
    company: str(j, const ['company_name', 'company']),
    when: str(j, const ['interview_date', 'scheduled_at', 'date']),
    mode: str(j, const ['interview_type', 'mode', 'location']),
    status: str(j, const ['status']),
  );

  final String jobTitle;
  final String company;
  final String when;
  final String mode;
  final String status;
}

class SeekerDashboard {
  const SeekerDashboard({
    required this.profile,
    required this.stats,
    required this.completion,
    required this.recent,
  });

  final JsonMap profile;
  final JsonMap stats;
  final int completion;
  final List<Application> recent;
}

class SeekerProfile {
  const SeekerProfile({
    required this.fields,
    required this.education,
    required this.experience,
    required this.portfolio,
  });

  final JsonMap fields;
  final List<JsonMap> education;
  final List<JsonMap> experience;
  final List<JsonMap> portfolio;
}

class SeekerRepository {
  const SeekerRepository(this._api);

  final ApiClient _api;
  static const pageSize = 10;

  /// Public job search. The seeker's token is sent but not required.
  Future<JobSearchResult> jobs({
    required int offset,
    String keyword = '',
    String? category,
  }) async {
    final json = await _api.get(
      category == null ? Endpoints.jobs : Endpoints.jobsByCategory(category),
      query: {
        'limit': pageSize,
        'offset': offset,
        if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      },
    );
    final data = dataMap(json);
    final items = asMapList(data['jobs']).map(Job.fromJson).toList();
    return JobSearchResult(
      page: PageResult(
        items: items,
        total: intOf(data, const [
          'total_jobs',
          'total',
        ], offset + items.length),
      ),
      categories: asMapList(data['categories'])
          .map(
            (c) => JobCategory(
              slug: str(c, const ['slug']),
              name: str(c, const ['name']),
            ),
          )
          .where((c) => c.slug.isNotEmpty)
          .toList(),
    );
  }

  Future<Job> jobDetail(String id) async {
    final data = dataMap(await _api.get(Endpoints.jobDetail(id)));
    final job = asMap(data['job']);
    return Job.fromJson(job.isNotEmpty ? job : data);
  }

  Future<String> apply(String jobId) async {
    final json = await _api.post(Endpoints.seekerApply(jobId));
    final m = messageOf(json);
    return m.isEmpty ? 'Application sent' : m;
  }

  Future<String> saveJob(String jobId) async {
    final json = await _api.post(Endpoints.seekerSaveJob(jobId));
    final m = messageOf(json);
    return m.isEmpty ? 'Job saved' : m;
  }

  Future<String> withdraw(String applicationId) async {
    final json = await _api.post(Endpoints.seekerWithdraw(applicationId));
    final m = messageOf(json);
    return m.isEmpty ? 'Application withdrawn' : m;
  }

  Future<(List<Application>, JsonMap)> applications() async {
    final data = dataMap(await _api.get(Endpoints.seekerApplications));
    return (
      asMapList(data['applications']).map(Application.fromJson).toList(),
      asMap(data['stats']),
    );
  }

  Future<(List<Interview>, List<Interview>)> interviews() async {
    final data = dataMap(await _api.get(Endpoints.seekerInterviews));
    return (
      asMapList(data['upcoming']).map(Interview.fromJson).toList(),
      asMapList(data['interviews']).map(Interview.fromJson).toList(),
    );
  }

  Future<List<Job>> savedJobs() async => dataList(
    await _api.get(Endpoints.seekerSavedJobs),
    'jobs',
  ).map(Job.fromJson).toList();

  Future<SeekerDashboard> dashboard() async {
    final data = dataMap(await _api.get(Endpoints.seekerDashboard));
    return SeekerDashboard(
      profile: asMap(data['seeker']),
      stats: asMap(data['stats']),
      completion: intOf(data, const ['profile_completion']),
      recent: asMapList(data['recent_applications'])
          .map(Application.fromJson)
          .toList(),
    );
  }

  Future<SeekerProfile> profile() async {
    final data = dataMap(await _api.get(Endpoints.seekerProfile));
    return SeekerProfile(
      fields: asMap(data['seeker']),
      education: asMapList(data['education']),
      experience: asMapList(data['experience']),
      portfolio: asMapList(data['portfolio']),
    );
  }
}

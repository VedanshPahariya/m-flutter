# Kora CRM Flutter app

Read `docs/PROJECT_CONTEXT.md` first: it has the full history, decisions, file
map, uncertainties and next steps for this project. API details are in
`docs/AUDIT.md`, `docs/API_VERIFICATION.md` and `docs/API_INVENTORY.md`.

Before committing, run:

```bash
dart format lib test
dart analyze
flutter test
```

Rules:

* The CodeIgniter 3 backend is out of scope. Never invent endpoints or fields.
* Add every new path to `lib/core/api/endpoints.dart` with its evidence tag.

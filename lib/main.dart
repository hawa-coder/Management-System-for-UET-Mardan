import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_state.dart';
import 'api_service.dart';

void main() => runApp(const DcmcsApp());

class DcmcsApp extends StatefulWidget {
  const DcmcsApp({super.key});
  @override
  State<DcmcsApp> createState() => _DcmcsAppState();
}

class _DcmcsAppState extends State<DcmcsApp> {
  final store = Store();
  bool onboardingComplete = false;

  @override
  void initState() {
    super.initState();
    store.initialize();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (_, child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DCMCS',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(seedColor: green, primary: green),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: green,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: store.initializing
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : !onboardingComplete
          ? Onboarding(onDone: () => setState(() => onboardingComplete = true))
          : store.signedIn
          ? Shell(store)
          : Login(store),
    ),
  );
}

class Onboarding extends StatefulWidget {
  const Onboarding({required this.onDone, super.key});
  final VoidCallback onDone;

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final controller = PageController();
  int page = 0;

  static const slides = [
    (
      Icons.assignment_turned_in_outlined,
      'Welcome to DCMS',
      'Easily submit and track your academic complaints with institutional transparency.',
    ),
    (
      Icons.verified_outlined,
      'Real-time Updates',
      'Get notified immediately when your complaint moves to the next administrative level.',
    ),
    (
      Icons.campaign_outlined,
      'Department Notices',
      'Stay updated with the latest announcements and directives from the Chairman.',
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: slides.length,
                onPageChanged: (value) => setState(() => page = value),
                itemBuilder: (_, index) {
                  final slide = slides[index];
                  return Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: index == 2
                                ? const Color(0xFFFFF7E8)
                                : const Color(0xFFE9EEF7),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: .08,
                                child: Image.asset('assets/images/logo.png'),
                              ),
                              Container(
                                padding: const EdgeInsets.all(28),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x220B1F3A),
                                      blurRadius: 30,
                                    ),
                                  ],
                                ),
                                child: Icon(slide.$1, size: 70, color: navy),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 46),
                      Text(
                        slide.$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        slide.$3,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF7B8496),
                          fontSize: 16,
                          height: 1.45,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: page == i ? 24 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: page == i ? navy : const Color(0xFFD9DDE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: navy,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (page == slides.length - 1) {
                    widget.onDone();
                  } else {
                    controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(page == slides.length - 1 ? 'Get Started' : 'Next'),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward, size: 19),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class Login extends StatefulWidget {
  const Login(this.store, {super.key});
  final Store store;
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final registrationNumber = TextEditingController();
  final mobileNumber = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  Role role = Role.student;
  int? semester;
  String? section;
  int? batchAdviserId;
  List<Map<String, dynamic>> advisers = const [];
  bool loadingAdvisers = false;
  bool hidePassword = true;
  bool createAccount = false;

  @override
  void initState() {
    super.initState();
    loadAdvisers();
  }

  Future<void> loadAdvisers() async {
    setState(() => loadingAdvisers = true);
    try {
      final result = await widget.store.api.fetchAdvisers();
      if (mounted) setState(() => advisers = result);
    } catch (_) {
      if (mounted) {
        setState(() => advisers = const []);
      }
    } finally {
      if (mounted) setState(() => loadingAdvisers = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    registrationNumber.dispose();
    mobileNumber.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    if (formKey.currentState?.validate() ?? false) {
      if (createAccount) {
        final created = await widget.store.register(
          name: name.text,
          email: email.text,
          registrationNumber: registrationNumber.text,
          semester: semester!,
          section: section!,
          mobileNumber: mobileNumber.text,
          batchAdviserId: batchAdviserId!,
          password: password.text,
        );
        if (created && mounted) {
          changeMode(false);
          password.clear();
          confirmPassword.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account submitted. You can sign in after your batch adviser approves it.',
              ),
            ),
          );
        }
      } else {
        await widget.store.login(email.text, password.text, role);
      }
    }
  }

  void changeMode(bool value) {
    setState(() {
      createAccount = value;
      role = Role.student;
      widget.store.authenticationError = null;
      formKey.currentState?.reset();
    });
  }

  String? validateEmail(String? value) {
    final input = value?.trim().toLowerCase() ?? '';
    if (input.isEmpty) return 'University email is required.';
    if (!RegExp(r'^[a-z0-9._%+-]+@uetmardan\.edu\.pk$').hasMatch(input)) {
      return 'Enter a valid @uetmardan.edu.pk email address.';
    }

    final localPart = input.split('@').first;
    final looksLikeStudent = RegExp(r'^\d').hasMatch(localPart);
    if (createAccount && !looksLikeStudent) {
      return 'Student email must begin with your registration digits.';
    }
    if (role == Role.student && !looksLikeStudent) {
      return 'Select the staff role assigned to this account.';
    }
    if (role != Role.student && looksLikeStudent) {
      return 'Student accounts cannot use a staff portal role.';
    }
    return null;
  }

  String? validatePassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return 'Password is required.';
    if (input.length < 8) return 'Use at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(input) ||
        !RegExp(r'[a-z]').hasMatch(input) ||
        !RegExp(r'[0-9]').hasMatch(input) ||
        !RegExp(r'[^A-Za-z0-9]').hasMatch(input)) {
      return 'Include uppercase, lowercase, number and symbol.';
    }
    return null;
  }

  String? requiredField(String? value, String label) =>
      (value?.trim().isEmpty ?? true) ? '$label is required.' : null;

  String? validateMobile(String? value) =>
      RegExp(r'^03\d{9}$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Enter a valid 11-digit mobile number.';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        if (MediaQuery.sizeOf(context).width > 1000)
          Expanded(
            child: Container(
              color: navy,
              padding: const EdgeInsets.all(60),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.account_balance_rounded, color: green, size: 64),
                  SizedBox(height: 30),
                  Text(
                    'A smarter way\nto be heard.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Submit, route and resolve department complaints with complete transparency.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 35),
                  Feature(Icons.track_changes, 'Real-time complaint tracking'),
                  Feature(
                    Icons.notifications_active_outlined,
                    'Role-based notifications',
                  ),
                  Feature(
                    Icons.verified_user_outlined,
                    'Secure university access',
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 135,
                          height: 135,
                        ),
                      ),
                      const SizedBox(height: 34),
                      const Center(
                        child: Text(
                          'Student Access',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            color: navy,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          createAccount
                              ? 'Create your student account'
                              : 'Sign in to track your complaints',
                          style: const TextStyle(color: Color(0xFF8B93A5)),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.login),
                            label: Text('Sign in'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.person_add_alt_1_outlined),
                            label: Text('Create account'),
                          ),
                        ],
                        selected: {createAccount},
                        onSelectionChanged: widget.store.authenticating
                            ? null
                            : (value) => changeMode(value.first),
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity(vertical: 2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (createAccount) ...[
                        TextFormField(
                          controller: name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              requiredField(value, 'Full name'),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: 'University email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: validateEmail,
                      ),
                      const SizedBox(height: 14),
                      if (createAccount) ...[
                        TextFormField(
                          controller: registrationNumber,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Registration number',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) =>
                              requiredField(value, 'Registration number'),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<int>(
                                isExpanded: true,
                                initialValue: semester,
                                decoration: const InputDecoration(
                                  labelText: 'Semester',
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                                items: List.generate(
                                  8,
                                  (index) => DropdownMenuItem(
                                    value: index + 1,
                                    child: Text('Semester ${index + 1}'),
                                  ),
                                ),
                                onChanged: (value) => setState(() {
                                  semester = value;
                                }),
                                validator: (value) =>
                                    value == null ? 'Select semester.' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: section,
                                decoration: const InputDecoration(
                                  labelText: 'Section',
                                ),
                                items:
                                    const ['A', 'B', 'C', 'D', 'AI', 'DS', 'CS']
                                        .map(
                                          (value) => DropdownMenuItem(
                                            value: value,
                                            child: Text(value),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) => setState(() {
                                  section = value;
                                }),
                                validator: (value) =>
                                    value == null ? 'Select section.' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          menuMaxHeight: 320,
                          initialValue: batchAdviserId,
                          decoration: const InputDecoration(
                            labelText: 'Choose batch adviser',
                            prefixIcon: Icon(Icons.supervisor_account_outlined),
                          ),
                          items: advisers.map((adviser) {
                            return DropdownMenuItem<int>(
                              value: adviser['id'] as int,
                              child: Text(
                                adviser['name']?.toString() ?? 'Batch adviser',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: loadingAdvisers
                              ? null
                              : (value) =>
                                    setState(() => batchAdviserId = value),
                          validator: (value) => value == null
                              ? 'Choose your batch adviser.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: mobileNumber,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          maxLength: 11,
                          decoration: const InputDecoration(
                            labelText: 'Mobile number',
                            hintText: '03XXXXXXXXX',
                            counterText: '',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: validateMobile,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: password,
                        obscureText: hidePassword,
                        textInputAction: createAccount
                            ? TextInputAction.next
                            : TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        autocorrect: false,
                        enableSuggestions: false,
                        onFieldSubmitted: createAccount
                            ? null
                            : (_) => submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: hidePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () =>
                                setState(() => hidePassword = !hidePassword),
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: validatePassword,
                      ),
                      if (createAccount) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: confirmPassword,
                          obscureText: hidePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => submit(),
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) => value != password.text
                              ? 'Passwords do not match.'
                              : null,
                        ),
                      ],
                      if (!createAccount)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => ForgotPasswordDialog(
                                widget.store.api,
                                initialEmail: email.text,
                              ),
                            ),
                            child: const Text('Forgot Password?'),
                          ),
                        ),
                      if (!createAccount) ...[
                        const SizedBox(height: 14),
                        DropdownButtonFormField<Role>(
                          initialValue: role,
                          decoration: const InputDecoration(
                            labelText: 'Portal role',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          items: Role.values
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r.label),
                                ),
                              )
                              .toList(),
                          onChanged: widget.store.authenticating
                              ? null
                              : (v) => setState(() => role = v!),
                        ),
                      ],
                      if (widget.store.authenticationError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 19,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.store.authenticationError!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: navy),
                        onPressed: widget.store.authenticating ? null : submit,
                        child: widget.store.authenticating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                createAccount ? 'Create Account' : 'Sign In',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: widget.store.authenticating
                              ? null
                              : () => changeMode(!createAccount),
                          child: Text(
                            createAccount
                                ? 'Already have an account? Sign in'
                                : "Don't have an account? Create one",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class Feature extends StatelessWidget {
  const Feature(this.icon, this.text, {super.key});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 17),
    child: Row(
      children: [
        Icon(icon, color: green),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class Shell extends StatelessWidget {
  const Shell(this.store, {super.key});
  final Store store;
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final pages = [
      Dashboard(store),
      Complaints(store),
      Notices(store),
      Profile(store),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.forum_rounded, color: green),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'DCMCS · ${store.role.label}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationsScreen(store)),
              ),
              icon: Badge(
                isLabelVisible: store.unreadNotificationCount > 0,
                label: Text('${store.unreadNotificationCount}'),
                child: const Icon(Icons.notifications_none),
              ),
              label: const Text('Notifications'),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              backgroundColor: Colors.white,
              selectedIndex: store.tab,
              onDestinationSelected: store.go,
              extended: MediaQuery.sizeOf(context).width >= 1180,
              minExtendedWidth: 220,
              labelType: MediaQuery.sizeOf(context).width >= 1180
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE8F5EE),
                  child: Text(
                    store.displayName.isEmpty
                        ? 'U'
                        : store.displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: Text('Complaints'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.campaign_outlined),
                  selectedIcon: Icon(Icons.campaign),
                  label: Text('Notices'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
          if (isDesktop) const VerticalDivider(width: 1),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: pages[store.tab],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: store.role == Role.student && store.tab == 1
          ? FloatingActionButton.extended(
              backgroundColor: store.studentApproved ? green : Colors.grey,
              foregroundColor: Colors.white,
              onPressed: store.studentApproved
                  ? () => showDialog(
                      context: context,
                      builder: (_) => NewComplaint(store),
                    )
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'You can submit complaints after your batch adviser approves your account.',
                        ),
                      ),
                    ),
              icon: const Icon(Icons.add),
              label: const Text('New complaint'),
            )
          : null,
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: store.tab,
              onDestinationSelected: store.go,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: 'Complaints',
                ),
                NavigationDestination(
                  icon: Icon(Icons.campaign_outlined),
                  selectedIcon: Icon(Icons.campaign),
                  label: 'Notices',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen(this.store, {super.key});
  final Store store;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      title: const Text('Notifications'),
      actions: [
        AnimatedBuilder(
          animation: store,
          builder: (context, child) => TextButton(
            onPressed: store.unreadNotificationCount == 0
                ? null
                : () async {
                    try {
                      await store.markAllNotificationsRead();
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not mark notifications as read. Please try again.',
                            ),
                          ),
                        );
                      }
                    }
                  },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white38,
            ),
            child: child!,
          ),
          child: const Text('Mark all read'),
        ),
      ],
    ),
    body: AnimatedBuilder(
      animation: store,
      builder: (context, child) {
        if (store.notifications.isEmpty) {
          return const Center(child: Text('No notifications yet'));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: store.notifications.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 78),
          itemBuilder: (context, index) {
            final notification = store.notifications[index];
            final (icon, color) = switch (notification.type) {
              NotificationType.complaint => (
                Icons.assignment_outlined,
                const Color(0xFF3867D6),
              ),
              NotificationType.notice => (
                Icons.campaign_outlined,
                const Color(0xFFE28A19),
              ),
              NotificationType.account => (Icons.security_outlined, green),
            };

            return Material(
              color: notification.isRead
                  ? Colors.transparent
                  : const Color(0xFFEFF5FF),
              child: InkWell(
                onTap: () => store.markNotificationRead(notification),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withValues(alpha: .12),
                        foregroundColor: color,
                        child: Icon(icon),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      color: navy,
                                      fontWeight: notification.isRead
                                          ? FontWeight.w600
                                          : FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF3867D6),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              notification.message,
                              style: const TextStyle(
                                color: Colors.black54,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              notification.time,
                              style: const TextStyle(
                                color: Colors.black38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class Dashboard extends StatelessWidget {
  const Dashboard(this.store, {super.key});
  final Store store;
  @override
  Widget build(BuildContext context) {
    final active = store.complaints
        .where(
          (c) => c.status != Status.resolved && c.status != Status.rejected,
        )
        .length;
    final resolved = store.complaints
        .where((c) => c.status == Status.resolved)
        .length;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [navy, Color(0xFF173E68)]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Good to see you',
                      style: TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      store.role == Role.student
                          ? store.displayName
                          : store.role.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      store.role == Role.student
                          ? 'BS Computer Science · 2023 · Section A'
                          : 'Computer Science Department',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const CircleAvatar(
                radius: 30,
                backgroundColor: green,
                child: Icon(Icons.person, color: Colors.white, size: 32),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (store.role == Role.student && !store.studentApproved) ...[
          Card(
            color: const Color(0xFFFFF4D6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.hourglass_top, color: Color(0xFF9A6700)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Waiting for batch adviser approval',
                          style: TextStyle(
                            color: Color(0xFF704D00),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${store.displayBatchAdviser} must approve your account. You can view the dashboard, notices, and profile, but you cannot submit a complaint yet.',
                          style: const TextStyle(color: Color(0xFF704D00)),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: store.checkApprovalStatus,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Check approval status'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          // Give the card contents enough vertical room on narrow phones and
          // when Android's font scaling is slightly larger than the default.
          childAspectRatio: 1.55,
          children: [
            Stat('Active', '$active', Icons.pending_actions, Colors.blue),
            Stat('Resolved', '$resolved', Icons.task_alt, Colors.green),
            const Stat('Notices', '2', Icons.campaign, Colors.orange),
            Stat(
              store.role == Role.student ? 'Adviser' : 'Approved students',
              store.role == Role.student
                  ? store.studentApproved
                        ? 'Approved'
                        : 'Waiting'
                  : '${store.approvedStudentsCount} / ${store.totalStudentsCount}',
              Icons.groups_outlined,
              Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (store.role == Role.adviser) ...[
          const SectionTitle('Student account approvals'),
          const SizedBox(height: 8),
          if (store.pendingStudents.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('No student accounts are waiting for approval.'),
              ),
            )
          else
            ...store.pendingStudents.map(
              (student) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name']?.toString() ?? 'Student',
                        style: const TextStyle(
                          color: navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${student['registration_number'] ?? ''} · Semester ${student['semester'] ?? ''} · Section ${student['section'] ?? ''}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        student['email']?.toString() ?? '',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await store.reviewStudent(
                                student['id'] as int,
                                'reject',
                              );
                            },
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () async {
                              await store.reviewStudent(
                                student['id'] as int,
                                'approve',
                              );
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
        ],
        if (store.role == Role.coordinator) ...[
          Row(
            children: [
              const Expanded(child: SectionTitle('Batch adviser approvals')),
              FilledButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AddAdviserDialog(store),
                ),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add adviser'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (store.adviserApprovals.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('No batch adviser accounts are available.'),
              ),
            )
          else
            ...store.adviserApprovals.map((adviser) {
              final status = adviser['account_status']?.toString() ?? 'pending';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              adviser['name']?.toString() ?? 'Batch adviser',
                              style: const TextStyle(
                                color: navy,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Chip(label: Text(status.toUpperCase())),
                        ],
                      ),
                      Text(
                        '${adviser['batch'] ?? ''} · Semester ${adviser['semester'] ?? ''} · Section ${adviser['section'] ?? ''}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        adviser['email']?.toString() ?? '',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status != 'rejected')
                            TextButton(
                              onPressed: () => store.reviewAdviser(
                                adviser['id'] as int,
                                'reject',
                              ),
                              child: const Text('Reject'),
                            ),
                          if (status != 'approved') ...[
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () => store.reviewAdviser(
                                adviser['id'] as int,
                                'approve',
                              ),
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 18),
        ],
        SectionTitle('Recent complaints', action: () => store.go(1)),
        const SizedBox(height: 8),
        ...store.complaints.take(3).map((c) => ComplaintCard(store, c)),
        const SizedBox(height: 18),
        const SectionTitle('Latest notice'),
        const NoticeCard(
          'Mid-term examination schedule',
          'The revised mid-term date sheet is available from the department office.',
          'All Students · Today',
        ),
      ],
    );
  }
}

class Stat extends StatelessWidget {
  const Stat(this.label, this.value, this.icon, this.color, {super.key});
  final String label, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {this.action, super.key});
  final String text;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: navy,
          ),
        ),
      ),
      if (action != null)
        TextButton(onPressed: action, child: const Text('View all')),
    ],
  );
}

class Complaints extends StatefulWidget {
  const Complaints(this.store, {super.key});
  final Store store;
  @override
  State<Complaints> createState() => _ComplaintsState();
}

class _ComplaintsState extends State<Complaints> {
  String filter = 'All';
  @override
  Widget build(BuildContext context) {
    final list = widget.store.complaints
        .where((c) => filter == 'All' || c.status.label == filter)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Complaints',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: navy,
          ),
        ),
        Text(
          widget.store.role == Role.student
              ? 'Track every request from submission to resolution.'
              : 'Review and act on complaints assigned to your role.',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                [
                      'All',
                      'Submitted',
                      'Under Review',
                      'Waiting for Office',
                      'Resolved',
                    ]
                    .map(
                      (x) => Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ChoiceChip(
                          label: Text(x),
                          selected: filter == x,
                          onSelected: (_) => setState(() => filter = x),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(50),
            child: Center(child: Text('No complaints found')),
          )
        else
          ...list.map((c) => ComplaintCard(widget.store, c)),
      ],
    );
  }
}

class ComplaintCard extends StatelessWidget {
  const ComplaintCard(this.store, this.c, {super.key});
  final Store store;
  final Complaint c;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 11),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Detail(store, c)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  c.id,
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
                const Spacer(),
                BadgeStatus(c.status),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              c.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: navy,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.category_outlined,
                  size: 15,
                  color: Colors.black45,
                ),
                const SizedBox(width: 5),
                Text(
                  c.category,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(width: 15),
                const Icon(
                  Icons.person_outline,
                  size: 15,
                  color: Colors.black45,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    c.handler,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class BadgeStatus extends StatelessWidget {
  const BadgeStatus(this.status, {super.key});
  final Status status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: status.color.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status.label,
      style: TextStyle(
        color: status.color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class Detail extends StatelessWidget {
  const Detail(this.store, this.c, {super.key});
  final Store store;
  final Complaint c;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      title: Text(c.id),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                c.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
            ),
            BadgeStatus(c.status),
          ],
        ),
        const SizedBox(height: 14),
        Text(c.details, style: const TextStyle(height: 1.5)),
        const SizedBox(height: 18),
        if (c.attachmentUrl != null) ...[
          OutlinedButton.icon(
            onPressed: () async {
              final opened = await launchUrl(
                Uri.parse(store.api.absoluteUrl(c.attachmentUrl!)),
                mode: LaunchMode.externalApplication,
              );
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unable to open attachment.')),
                );
              }
            },
            icon: Icon(
              c.attachmentName?.toLowerCase().endsWith('.pdf') ?? false
                  ? Icons.picture_as_pdf_outlined
                  : Icons.image_outlined,
            ),
            label: Text(c.attachmentName ?? 'Open attachment'),
          ),
          const SizedBox(height: 18),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 32,
              runSpacing: 15,
              children: [
                Info('Category', c.category),
                Info('Priority', c.priority),
                Info('Current handler', c.handler),
                Info(
                  'Student',
                  '${store.displayName} · ${store.displayRegistrationNumber}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const SectionTitle('Complaint timeline'),
        ...c.history.asMap().entries.map(
          (e) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (e.key < c.history.length - 1)
                    Container(
                      width: 2,
                      height: 35,
                      color: green.withValues(alpha: .25),
                    ),
                ],
              ),
              const SizedBox(width: 13),
              Text(
                e.value,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (store.role == Role.adviser ||
            store.role == Role.coordinator ||
            store.role == Role.chairman) ...[
          const SizedBox(height: 22),
          StaffComments(store, c),
        ],
        if (store.role == Role.office &&
            c.status == Status.resolved &&
            c.handler == Role.office.label) ...[
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => PublishResolutionDialog(store, c),
            ),
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('Publish resolution notice'),
          ),
        ],
        if (store.role != Role.student &&
            c.status != Status.rejected &&
            (c.status != Status.resolved ||
                (store.role == Role.chairman && c.handler == 'Closed'))) ...[
          const SizedBox(height: 20),
          const SectionTitle('Take action'),
          Wrap(spacing: 8, runSpacing: 8, children: actions(context)),
        ],
      ],
    ),
  );
  List<Widget> actions(BuildContext context) {
    final out = <Widget>[];
    void add(String text, String action) => out.add(
      FilledButton.tonal(
        onPressed: () async {
          try {
            await store.move(c, action);
            if (context.mounted) Navigator.pop(context);
          } on ApiException catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error.message)));
            }
          }
        },
        child: Text(text),
      ),
    );
    if (store.role == Role.chairman &&
        c.status == Status.resolved &&
        c.handler == 'Closed') {
      add('Send resolution to Department Staff', 'send_resolved_department');
      return out;
    }
    if (c.status != Status.review) {
      add('Accept', 'accept');
    }
    if (store.role == Role.adviser) {
      add('Forward to coordinator', 'forward_coordinator');
    }
    if (store.role == Role.coordinator) {
      add('Forward to chairman', 'forward_chairman');
    }
    if (store.role == Role.chairman) {
      add('Send to Department Staff', 'send_office');
      add('Send to dean', 'send_dean');
    }
    if (store.role == Role.office || store.role == Role.dean) {
      add('Return to chairman', 'return_chairman');
    }
    add('Resolve', 'resolve');
    add('Reject', 'reject');
    return out;
  }
}

class StaffComments extends StatefulWidget {
  const StaffComments(this.store, this.complaint, {super.key});
  final Store store;
  final Complaint complaint;
  @override
  State<StaffComments> createState() => _StaffCommentsState();
}

class _StaffCommentsState extends State<StaffComments> {
  final controller = TextEditingController();
  bool sending = false;
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionTitle('Staff comments & review'),
      const SizedBox(height: 8),
      if (widget.complaint.comments.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No staff comments yet.'),
          ),
        )
      else
        ...widget.complaint.comments.map(
          (comment) => Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.author,
                          style: const TextStyle(
                            color: navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        comment.role.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(comment.comment),
                ],
              ),
            ),
          ),
        ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        minLines: 2,
        maxLines: 4,
        maxLength: 2000,
        decoration: const InputDecoration(
          labelText: 'Add private staff comment',
          hintText: 'Write your review or instructions for the next handler...',
          prefixIcon: Icon(Icons.comment_outlined),
        ),
      ),
      if (error != null)
        Text(error!, style: const TextStyle(color: Colors.red)),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: sending
              ? null
              : () async {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  setState(() {
                    sending = true;
                    error = null;
                  });
                  try {
                    await widget.store.addComplaintComment(
                      widget.complaint,
                      text,
                    );
                    controller.clear();
                  } on ApiException catch (exception) {
                    error = exception.message;
                  } finally {
                    if (mounted) setState(() => sending = false);
                  }
                },
          icon: const Icon(Icons.send_outlined),
          label: Text(sending ? 'Posting...' : 'Post comment'),
        ),
      ),
    ],
  );
}

class PublishResolutionDialog extends StatefulWidget {
  const PublishResolutionDialog(this.store, this.complaint, {super.key});
  final Store store;
  final Complaint complaint;
  @override
  State<PublishResolutionDialog> createState() =>
      _PublishResolutionDialogState();
}

class _PublishResolutionDialogState extends State<PublishResolutionDialog> {
  late final TextEditingController title;
  final body = TextEditingController();
  bool publishing = false;
  String? error;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: 'Resolved: ${widget.complaint.title}');
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Publish resolution notice'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Notice title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: body,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Resolution details for students',
              hintText:
                  'Explain what was resolved and any action students should take.',
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: publishing ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: publishing
            ? null
            : () async {
                if (title.text.trim().isEmpty || body.text.trim().isEmpty) {
                  setState(
                    () => error = 'Title and resolution details are required.',
                  );
                  return;
                }
                setState(() {
                  publishing = true;
                  error = null;
                });
                try {
                  await widget.store.publishResolutionNotice(
                    widget.complaint,
                    title: title.text.trim(),
                    body: body.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Resolution published to the student notice board.',
                        ),
                      ),
                    );
                  }
                } on ApiException catch (exception) {
                  if (mounted) setState(() => error = exception.message);
                } finally {
                  if (mounted) setState(() => publishing = false);
                }
              },
        icon: const Icon(Icons.publish_outlined),
        label: Text(publishing ? 'Publishing...' : 'Publish'),
      ),
    ],
  );
}

class Info extends StatelessWidget {
  const Info(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 140,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black45, fontSize: 11),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class NewComplaint extends StatefulWidget {
  const NewComplaint(this.store, {super.key});
  final Store store;
  @override
  State<NewComplaint> createState() => _NewComplaintState();
}

class _NewComplaintState extends State<NewComplaint> {
  final title = TextEditingController(), details = TextEditingController();
  String category = 'Academic', priority = 'Medium';
  bool submitting = false;
  String? error;
  PlatformFile? attachment;

  Future<void> chooseAttachment() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (file == null || !mounted) return;
    if (await file.length() > 10 * 1024 * 1024) {
      setState(() => error = 'Attachment must not exceed 10 MB.');
      return;
    }
    setState(() {
      attachment = file;
      error = null;
    });
  }

  @override
  void dispose() {
    title.dispose();
    details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Submit a complaint'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 11),
            TextField(
              controller: details,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Describe the issue',
              ),
            ),
            const SizedBox(height: 11),
            DropdownButtonFormField(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                'Academic',
                'Attendance',
                'Lab',
                'Result',
                'Faculty',
                'Hostel',
                'Internet',
                'Classroom',
                'Examination',
                'Other',
              ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
              onChanged: (v) => category = v!,
            ),
            const SizedBox(height: 11),
            DropdownButtonFormField(
              initialValue: priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: [
                'Low',
                'Medium',
                'High',
              ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
              onChanged: (v) => priority = v!,
            ),
            const SizedBox(height: 11),
            OutlinedButton.icon(
              onPressed: submitting ? null : chooseAttachment,
              icon: const Icon(Icons.attach_file),
              label: Text(
                attachment == null
                    ? 'Attach image or PDF (optional)'
                    : attachment!.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (attachment != null)
              TextButton.icon(
                onPressed: submitting
                    ? null
                    : () => setState(() => attachment = null),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Remove attachment'),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: submitting
            ? null
            : () async {
                if (title.text.trim().isEmpty || details.text.trim().isEmpty) {
                  return;
                }
                setState(() {
                  submitting = true;
                  error = null;
                });
                try {
                  await widget.store.add(
                    Complaint(
                      id: '',
                      title: title.text.trim(),
                      details: details.text.trim(),
                      category: category,
                      priority: priority,
                      createdAt: DateTime.now(),
                    ),
                    attachmentBytes: attachment == null
                        ? null
                        : await attachment!.readAsBytes(),
                    attachmentName: attachment?.name,
                  );
                  if (context.mounted) Navigator.pop(context);
                } on ApiException catch (exception) {
                  if (mounted) setState(() => error = exception.message);
                } finally {
                  if (mounted) setState(() => submitting = false);
                }
              },
        child: submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Submit'),
      ),
    ],
  );
}

class Notices extends StatelessWidget {
  const Notices(this.store, {super.key});
  final Store store;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Notice board',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      const Text(
        'Official updates from the Computer Science Department.',
        style: TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 18),
      if (store.loadingData)
        const Center(child: CircularProgressIndicator())
      else if (store.notices.isEmpty)
        const Center(child: Text('No notices have been published.'))
      else
        ...store.notices.map(
          (notice) => NoticeCard(notice.title, notice.body, notice.meta),
        ),
    ],
  );
}

class NoticeCard extends StatelessWidget {
  const NoticeCard(this.title, this.body, this.meta, {super.key});
  final String title, body, meta;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2DD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign, color: Colors.orange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  body,
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 9),
                Text(
                  meta,
                  style: const TextStyle(
                    color: green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class Profile extends StatelessWidget {
  const Profile(this.store, {super.key});
  final Store store;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Profile',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      const SizedBox(height: 18),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: green,
                child: Icon(Icons.person, color: Colors.white, size: 45),
              ),
              const SizedBox(height: 12),
              Text(
                store.displayName,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
              Text(
                store.displayEmail,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 15),
              const Divider(),
              if (store.role == Role.student) ...[
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Registration number'),
                  trailing: Text(store.displayRegistrationNumber),
                ),
                ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: const Text('Batch & section'),
                  trailing: Text(
                    '${store.displayBatch} · ${store.displaySection}',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('Semester'),
                  trailing: Text(store.displaySemester),
                ),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Mobile number'),
                  trailing: Text(store.displayMobileNumber),
                ),
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('Batch adviser'),
                  trailing: Text(store.displayBatchAdviser),
                ),
              ],
              ListTile(
                leading: const Icon(Icons.password_outlined),
                title: const Text('Change password'),
                subtitle: const Text('Requires your current password'),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => ChangePasswordDialog(store.api),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Sign out',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: store.logout,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class AddAdviserDialog extends StatefulWidget {
  const AddAdviserDialog(this.store, {super.key});
  final Store store;
  @override
  State<AddAdviserDialog> createState() => _AddAdviserDialogState();
}

class _AddAdviserDialogState extends State<AddAdviserDialog> {
  final name = TextEditingController();
  final email = TextEditingController();
  final batch = TextEditingController();
  int semester = 1;
  String section = 'A';
  bool saving = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    batch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add batch adviser'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'University email'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: batch,
            decoration: const InputDecoration(
              labelText: 'Batch',
              hintText: 'Batch 09',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: semester,
                  decoration: const InputDecoration(labelText: 'Semester'),
                  items: List.generate(
                    8,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1}'),
                    ),
                  ),
                  onChanged: (value) => semester = value!,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: section,
                  decoration: const InputDecoration(labelText: 'Section'),
                  items: const ['A', 'B', 'C', 'D', 'AI', 'DS', 'CS']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => section = value!,
                ),
              ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: saving
            ? null
            : () async {
                if (name.text.trim().isEmpty ||
                    email.text.trim().isEmpty ||
                    batch.text.trim().isEmpty) {
                  setState(
                    () => error = 'Name, email, and batch are required.',
                  );
                  return;
                }
                setState(() {
                  saving = true;
                  error = null;
                });
                try {
                  await widget.store.addAdviser({
                    'name': name.text.trim(),
                    'email': email.text.trim().toLowerCase(),
                    'batch': batch.text.trim(),
                    'semester': semester,
                    'section': section,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Adviser added as pending. Approve the account when ready.',
                        ),
                      ),
                    );
                  }
                } on ApiException catch (exception) {
                  if (mounted) setState(() => error = exception.message);
                } finally {
                  if (mounted) setState(() => saving = false);
                }
              },
        child: Text(saving ? 'Adding...' : 'Add adviser'),
      ),
    ],
  );
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog(this.api, {super.key});
  final ApiService api;
  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final current = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool saving = false;
  String? error;

  @override
  void dispose() {
    current.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Change password'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: current,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Current password'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: confirm,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirm new password'),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: saving
            ? null
            : () async {
                if (password.text != confirm.text) {
                  setState(() => error = 'New passwords do not match.');
                  return;
                }
                setState(() {
                  saving = true;
                  error = null;
                });
                try {
                  final message = await widget.api.changePassword(
                    currentPassword: current.text,
                    password: password.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(message)));
                  }
                } on ApiException catch (exception) {
                  if (mounted) setState(() => error = exception.message);
                } finally {
                  if (mounted) setState(() => saving = false);
                }
              },
        child: Text(saving ? 'Saving...' : 'Change password'),
      ),
    ],
  );
}

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog(this.api, {this.initialEmail = '', super.key});
  final ApiService api;
  final String initialEmail;
  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  late final email = TextEditingController(text: widget.initialEmail);
  final code = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool codeSent = false, saving = false;
  String? error, info;

  @override
  void dispose() {
    email.dispose();
    code.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(codeSent ? 'Enter reset code' : 'Forgot password'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: email,
            enabled: !codeSent,
            decoration: const InputDecoration(labelText: 'University email'),
          ),
          if (codeSent) ...[
            const SizedBox(height: 10),
            TextField(
              controller: code,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Six-digit code'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
            ),
          ],
          if (info != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(info!, style: const TextStyle(color: green)),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: saving
            ? null
            : () async {
                setState(() {
                  saving = true;
                  error = null;
                });
                try {
                  if (!codeSent) {
                    final message = await widget.api.forgotPassword(email.text);
                    if (mounted) {
                      setState(() {
                        codeSent = true;
                        info = message;
                      });
                    }
                  } else {
                    if (password.text != confirm.text) {
                      throw const ApiException('New passwords do not match.');
                    }
                    final message = await widget.api.resetPassword(
                      email: email.text,
                      code: code.text,
                      password: password.text,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    }
                  }
                } on ApiException catch (exception) {
                  if (mounted) setState(() => error = exception.message);
                } finally {
                  if (mounted) setState(() => saving = false);
                }
              },
        child: Text(
          saving
              ? 'Please wait...'
              : codeSent
              ? 'Reset password'
              : 'Send code',
        ),
      ),
    ],
  );
}

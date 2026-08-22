import 'package:flutter/material.dart';

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
  final email = TextEditingController();
  final password = TextEditingController();
  Role role = Role.student;
  bool hidePassword = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    if (formKey.currentState?.validate() ?? false) {
      await widget.store.login(email.text, password.text, role);
    }
  }

  String? validateEmail(String? value) {
    final input = value?.trim().toLowerCase() ?? '';
    if (input.isEmpty) return 'University email is required.';
    if (!RegExp(r'^[a-z0-9._%+-]+@uetmardan\.edu\.pk$').hasMatch(input)) {
      return 'Enter a valid @uetmardan.edu.pk email address.';
    }

    final localPart = input.split('@').first;
    final looksLikeStudent = RegExp(r'^\d').hasMatch(localPart);
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
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            color: navy,
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Log in to track your complaints',
                          style: TextStyle(color: Color(0xFF8B93A5)),
                        ),
                      ),
                      const SizedBox(height: 28),
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
                      TextFormField(
                        controller: password,
                        obscureText: hidePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        autocorrect: false,
                        enableSuggestions: false,
                        onFieldSubmitted: (_) => submit(),
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password recovery will be available after mail service configuration.',
                                  ),
                                ),
                              ),
                          child: const Text('Forgot Password?'),
                        ),
                      ),
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
                            : const Text(
                                'Log In',
                                style: TextStyle(fontWeight: FontWeight.w700),
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
      body: pages[store.tab],
      floatingActionButton: store.role == Role.student && store.tab == 1
          ? FloatingActionButton.extended(
              backgroundColor: green,
              foregroundColor: Colors.white,
              onPressed: () => showDialog(
                context: context,
                builder: (_) => NewComplaint(store),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New complaint'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
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
        TextButton(
          onPressed: store.unreadNotificationCount == 0
              ? null
              : store.markAllNotificationsRead,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white38,
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
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.75,
          children: [
            Stat('Active', '$active', Icons.pending_actions, Colors.blue),
            Stat('Resolved', '$resolved', Icons.task_alt, Colors.green),
            const Stat('Notices', '2', Icons.campaign, Colors.orange),
            Stat(
              store.role == Role.student ? 'Adviser' : 'Students',
              store.role == Role.student ? 'Assigned' : '128',
              Icons.groups_outlined,
              Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 24),
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
        if (store.role != Role.student &&
            c.status != Status.resolved &&
            c.status != Status.rejected) ...[
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
    if (store.role == Role.adviser) {
      add('Forward to coordinator', 'forward_coordinator');
    }
    if (store.role == Role.coordinator) {
      add('Forward to chairman', 'forward_chairman');
    }
    if (store.role == Role.chairman) {
      add('Send to office', 'send_office');
      add('Send to dean', 'send_dean');
      add('Resolve', 'resolve');
      add('Reject', 'reject');
    }
    if (store.role == Role.office || store.role == Role.dean) {
      add('Return to chairman', 'return_chairman');
    }
    return out;
  }
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
                const ListTile(
                  leading: Icon(Icons.school_outlined),
                  title: Text('Batch adviser'),
                  trailing: Text('Dr. Ahmad'),
                ),
              ],
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

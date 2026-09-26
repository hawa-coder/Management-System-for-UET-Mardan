import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'app_state.dart';

const noticeCategories = [
  'Academic',
  'Examination',
  'Events',
  'Timetable',
  'FYP',
  'Department',
];
const noticePriorities = ['Normal', 'Important', 'Urgent'];

String noticeDate(DateTime? date) {
  if (date == null) return '—';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

Future<DateTime?> pickNoticeDate(BuildContext context, DateTime initial) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

Future<void> showNoticeComposer(
  BuildContext context,
  Store store, {
  DepartmentNotice? notice,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => NoticeComposer(store, notice: notice),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Notice saved. It will appear for the selected audience on its notice date.',
        ),
      ),
    );
  }
}

class NoticeComposer extends StatefulWidget {
  const NoticeComposer(this.store, {this.notice, super.key});
  final Store store;
  final DepartmentNotice? notice;
  @override
  State<NoticeComposer> createState() => _NoticeComposerState();
}

class _NoticeComposerState extends State<NoticeComposer> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final body = TextEditingController();
  final selections = <String, Set<String>>{};
  Map<String, dynamic>? options;
  String category = 'Department', priority = 'Normal';
  DateTime date = DateTime.now();
  DateTime? expiry;
  Uint8List? attachment;
  String? attachmentName;
  bool removeAttachment = false, saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    for (final field in [
      'departments',
      'batches',
      'semesters',
      'sections',
      'course_ids',
      'student_ids',
    ]) {
      selections[field] = (widget.notice?.data[field] as List? ?? [])
          .map((v) => v.toString())
          .toSet();
    }
    final notice = widget.notice;
    if (notice != null) {
      title.text = notice.title;
      body.text = notice.body;
      category = notice.category;
      priority = notice.priority;
      date = notice.date ?? date;
      expiry = notice.expiresAt;
      attachmentName = notice.attachmentName;
      for (final entry in {
        'department': 'departments',
        'batch': 'batches',
        'semester': 'semesters',
        'section': 'sections',
      }.entries) {
        if (notice.data[entry.key] != null &&
            selections[entry.value]!.isEmpty) {
          selections[entry.value]!.add(notice.data[entry.key].toString());
        }
      }
    }
    loadOptions();
  }

  Future<void> loadOptions() async {
    setState(() => error = null);
    try {
      final result = await widget.store.api.fetchNoticeOptions();
      if (mounted) setState(() => options = result);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is ApiException
              ? e.message
              : 'Unable to load audiences. Please retry.',
        );
      }
    }
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> chooseAttachment() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'png',
          'jpg',
          'jpeg',
          'doc',
          'docx',
          'txt',
          'odt',
        ],
      );
      if (file == null || !mounted) return;
      final size = await file.length();
      if (!mounted) return;
      if (size > 10 * 1024 * 1024) {
        setState(
          () => error = 'Choose a readable attachment no larger than 10 MB.',
        );
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        attachment = bytes;
        attachmentName = file.name;
        removeAttachment = false;
        error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              error = 'Unable to open the attachment. Please try another file.',
        );
      }
    }
  }

  Map<String, String> choices(String field) {
    if (field == 'semesters') {
      return {for (var i = 1; i <= 8; i++) '$i': 'Semester $i'};
    }
    if (field == 'course_ids') {
      return {
        for (final item in options?['courses'] as List? ?? [])
          '${item['id']}': '${item['code']} · ${item['name']}',
      };
    }
    if (field == 'student_ids') {
      return {
        for (final item in options?['students'] as List? ?? [])
          '${item['id']}':
              '${item['name']} · ${item['registration_number'] ?? item['id']}',
      };
    }
    final key = {
      'departments': 'department',
      'batches': 'batch',
      'sections': 'section',
    }[field];
    return {
      for (final value in options?[key] as List? ?? []) '$value': '$value',
    };
  }

  Widget audienceField(String field, String label) {
    final values = choices(field);
    // Keep existing targets visible when enrollment or profile data has changed.
    for (final selected in selections[field]!) {
      values.putIfAbsent(selected, () => selected);
    }
    final selectedLabels = selections[field]!
        .map((v) => values[v] ?? v)
        .join(', ');
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(14),
        ),
        onPressed: saving
            ? null
            : () async {
                final selected = await showDialog<Set<String>>(
                  context: context,
                  builder: (_) => AudienceSelectionDialog(
                    label: label,
                    choices: values,
                    selected: selections[field]!,
                  ),
                );
                if (selected != null && mounted) {
                  setState(() => selections[field] = selected);
                }
              },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedLabels.isEmpty
                        ? 'All permitted ${label.toLowerCase()}'
                        : selectedLabels,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
      ),
    );
  }

  Future<void> publish() async {
    if (!form.currentState!.validate()) return;
    if (expiry != null && !expiry!.isAfter(date)) {
      setState(() => error = 'Expiry must be after the notice date.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.store.publishNotice(
        {
          'title': title.text.trim(),
          'body': body.text.trim(),
          'audience': 'student',
          'category': category,
          'priority': priority,
          'notice_date': date.toUtc().toIso8601String(),
          'expires_at': expiry?.toUtc().toIso8601String(),
          'remove_attachment': removeAttachment,
          // Clear the legacy single-selection fields when editing an older notice.
          'department': null, 'batch': null, 'semester': null, 'section': null,
          for (final entry in selections.entries)
            entry.key:
                ['semesters', 'course_ids', 'student_ids'].contains(entry.key)
                ? entry.value.map(int.parse).toList()
                : entry.value.toList(),
        },
        id: widget.notice?.id,
        attachmentBytes: attachment,
        attachmentName: attachmentName,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          error = e is ApiException
              ? e.message
              : 'Unable to save the notice. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      title: Text(widget.notice == null ? 'Create Notice' : 'Edit Notice'),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Posted by ${widget.store.displayName} · ${widget.store.role.label}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: title,
                  enabled: !saving,
                  maxLength: 180,
                  decoration: const InputDecoration(labelText: 'Notice Title'),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Enter a notice title.'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: body,
                  enabled: !saving,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 10000,
                  decoration: const InputDecoration(
                    labelText: 'Notice Message',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Enter the notice message.'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Notice Category',
                  ),
                  items: noticeCategories
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: saving
                      ? null
                      : (v) => setState(() => category = v!),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: noticePriorities
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: saving
                      ? null
                      : (v) => setState(() => priority = v!),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          final result = await pickNoticeDate(context, date);
                          if (result != null && mounted) {
                            setState(() => date = result);
                          }
                        },
                  icon: const Icon(Icons.calendar_month),
                  label: Text('Date: ${noticeDate(date)}'),
                ),
                const Text(
                  'Choose a future date and time to schedule this notice.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          final result = await pickNoticeDate(
                            context,
                            expiry ?? date.add(const Duration(days: 7)),
                          );
                          if (result != null && mounted) {
                            setState(() => expiry = result);
                          }
                        },
                  icon: const Icon(Icons.event_busy),
                  label: Text(
                    expiry == null
                        ? 'Add expiry date (optional)'
                        : 'Expires: ${noticeDate(expiry)}',
                  ),
                ),
                if (expiry != null)
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => setState(() => expiry = null),
                    child: const Text('Remove expiry'),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: saving ? null : chooseAttachment,
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    attachmentName ??
                        'Attach PDF, image, or document (up to 10 MB)',
                  ),
                ),
                if (attachmentName != null)
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => setState(() {
                            attachment = null;
                            attachmentName = null;
                            removeAttachment = true;
                          }),
                    child: const Text('Remove attachment'),
                  ),
                const SizedBox(height: 22),
                const Text(
                  'Target audience',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 6),
                if (options != null) ...[
                  Text(
                    options!['scope_description']?.toString() ??
                        'Only your permitted students will receive this notice.',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('All Students'),
                        onPressed: saving
                            ? null
                            : () => setState(() {
                                for (final set in selections.values) {
                                  set.clear();
                                }
                              }),
                      ),
                      if (options!['faculty_restricted'] != true &&
                          widget.store.role != Role.adviser)
                        ActionChip(
                          label: const Text('Entire Department'),
                          onPressed: saving
                              ? null
                              : () => setState(() {
                                  for (final set in selections.values) {
                                    set.clear();
                                  }
                                  final department = widget
                                      .store
                                      .authenticatedUser?['department']
                                      ?.toString();
                                  if (department != null) {
                                    selections['departments']!.add(department);
                                  }
                                }),
                        ),
                    ],
                  ),
                  audienceField('departments', 'Department / Field'),
                  audienceField('batches', 'Batches'),
                  audienceField('semesters', 'Semesters'),
                  audienceField('sections', 'Sections'),
                  audienceField('course_ids', 'Courses / Classes'),
                  audienceField('student_ids', 'Specific Students'),
                  const SizedBox(height: 12),
                  const Text(
                    'Select multiple values in any group. A student must match every selected group. Leaving a group empty includes all students allowed by your role.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  if (options!['faculty_restricted'] == true &&
                      (options!['courses'] as List? ?? []).isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'No teaching assignments are available. Ask the department administrator to assign your courses and enrolled students.',
                        style: TextStyle(color: Colors.deepOrange),
                      ),
                    ),
                ] else if (error == null)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                  if (options == null)
                    TextButton(
                      onPressed: loadOptions,
                      child: const Text('Retry'),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed:
              saving ||
                  options == null ||
                  (options!['faculty_restricted'] == true &&
                      (options!['courses'] as List? ?? []).isEmpty)
              ? null
              : publish,
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  widget.notice != null
                      ? 'Save changes'
                      : date.isAfter(DateTime.now())
                      ? 'Schedule notice'
                      : 'Publish notice',
                ),
        ),
      ],
    ),
  );
}

class AudienceSelectionDialog extends StatefulWidget {
  const AudienceSelectionDialog({
    required this.label,
    required this.choices,
    required this.selected,
    super.key,
  });
  final String label;
  final Map<String, String> choices;
  final Set<String> selected;
  @override
  State<AudienceSelectionDialog> createState() =>
      _AudienceSelectionDialogState();
}

class _AudienceSelectionDialogState extends State<AudienceSelectionDialog> {
  late final selected = {...widget.selected};
  String search = '';
  @override
  Widget build(BuildContext context) {
    final choices = widget.choices.entries
        .where((e) => e.value.toLowerCase().contains(search.toLowerCase()))
        .toList();
    return AlertDialog(
      title: Text(widget.label),
      content: SizedBox(
        width: 520,
        height: 380,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => search = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: choices.isEmpty
                  ? const Center(child: Text('No matching options.'))
                  : ListView.builder(
                      itemCount: choices.length,
                      itemBuilder: (_, i) => CheckboxListTile(
                        title: Text(choices[i].value),
                        value: selected.contains(choices[i].key),
                        onChanged: (value) => setState(
                          () => value!
                              ? selected.add(choices[i].key)
                              : selected.remove(choices[i].key),
                        ),
                      ),
                    ),
            ),
            Text('${selected.length} selected · Empty means all permitted'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(selected.clear),
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, selected),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

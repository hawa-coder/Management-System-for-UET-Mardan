import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'app_state.dart';
import 'notice_composer.dart';

Color noticeColor(String priority) => switch (priority) {
  'Urgent' => const Color(0xFFC62828),
  'Important' => const Color(0xFF9A6700),
  _ => green,
};

Future<void> openNoticeDetails(
  BuildContext context,
  Store store,
  int id,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => NoticeDetails(store: store, id: id),
    ),
  );
}

class NoticeBoard extends StatefulWidget {
  const NoticeBoard(this.store, {super.key});
  final Store store;
  @override
  State<NoticeBoard> createState() => _NoticeBoardState();
}

class _NoticeBoardState extends State<NoticeBoard> {
  bool mine = false, loading = false;
  String search = '',
      filter = 'All Notices',
      readFilter = 'All',
      status = 'All';
  DateTimeRange? dates;
  String? error;

  Future<void> refresh() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (mine) {
        await widget.store.loadMyNotices();
      } else {
        await widget.store.refreshData();
        if (widget.store.dataError != null) {
          throw ApiException(widget.store.dataError!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is ApiException
              ? e.message
              : 'Unable to load notices. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final store = widget.store;
      final notices = (mine ? store.myNotices : store.notices).where((notice) {
        if (!mine && notice.status != 'Active') return false;
        if (mine && status != 'All' && notice.status != status) return false;
        if (filter != 'All Notices' &&
            notice.category != filter &&
            notice.priority != filter) {
          return false;
        }
        if (readFilter == 'Unread' && notice.isRead ||
            readFilter == 'Read' && !notice.isRead) {
          return false;
        }
        if (!'${notice.title} ${notice.body} ${notice.publisherName}'
            .toLowerCase()
            .contains(search.toLowerCase())) {
          return false;
        }
        if (dates != null &&
            (notice.date == null ||
                notice.date!.isBefore(dates!.start) ||
                !notice.date!.isBefore(
                  dates!.end.add(const Duration(days: 1)),
                ))) {
          return false;
        }
        return true;
      }).toList();
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              mine ? 'My Notices / Manage Notices' : 'Notice Board',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mine
                  ? 'Manage your published, scheduled, and expired announcements.'
                  : 'Announcements for your department, batch, semester, and classes.',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (store.canPublishNotices) ...[
                  FilledButton.icon(
                    onPressed: () => showNoticeComposer(context, store),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Create Notice'),
                  ),
                  OutlinedButton.icon(
                    onPressed: loading
                        ? null
                        : () async {
                            setState(() {
                              mine = !mine;
                              readFilter = 'All';
                              status = 'All';
                            });
                            if (mine) await refresh();
                          },
                    icon: Icon(
                      mine ? Icons.campaign_outlined : Icons.manage_history,
                    ),
                    label: Text(mine ? 'Notice Board' : 'My Notices'),
                  ),
                ],
                TextButton.icon(
                  onPressed: loading || store.loadingData ? null : refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
                if (!mine)
                  Chip(
                    avatar: const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 18,
                    ),
                    label: Text('${store.unreadNoticeCount} unread notices'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search notices',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => search = v),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  ['All Notices', ...noticeCategories, 'Important', 'Urgent']
                      .map(
                        (value) => ChoiceChip(
                          label: Text(value),
                          selected: filter == value,
                          onSelected: (_) => setState(() => filter = value),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (mine)
                  DropdownButton<String>(
                    value: status,
                    items: ['All', 'Active', 'Expired', 'Scheduled']
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(v == 'All' ? 'All statuses' : v),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => status = v!),
                  )
                else
                  DropdownButton<String>(
                    value: readFilter,
                    items: ['All', 'Unread', 'Read']
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(
                              v == 'All' ? 'Read and unread' : '$v notices',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => readFilter = v!),
                  ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    dates == null
                        ? 'Filter by date'
                        : '${noticeDate(dates!.start).split(',').first} – ${noticeDate(dates!.end).split(',').first}',
                  ),
                  onPressed: () async {
                    final value = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDateRange: dates,
                    );
                    if (value != null && mounted) setState(() => dates = value);
                  },
                ),
                if (dates != null)
                  TextButton(
                    onPressed: () => setState(() => dates = null),
                    child: const Text('Clear dates'),
                  ),
              ],
            ),
            if (loading || store.loadingData)
              const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
            if (error != null || store.dataError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  error ?? store.dataError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 12),
            if (notices.isEmpty && !loading && !store.loadingData)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No notices match this view.'),
                ),
              ),
            ...notices.map(
              (notice) =>
                  AnnouncementCard(store: store, notice: notice, manage: mine),
            ),
          ],
        ),
      );
    },
  );
}

class AnnouncementCard extends StatefulWidget {
  const AnnouncementCard({
    required this.store,
    required this.notice,
    this.manage = false,
    super.key,
  });
  final Store store;
  final DepartmentNotice notice;
  final bool manage;
  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  bool busy = false;

  Future<void> act(String action) async {
    final notice = widget.notice;
    if (action == 'Edit') {
      await showNoticeComposer(context, widget.store, notice: notice);
      return;
    }
    if (action == 'View') {
      await openNoticeDetails(context, widget.store, notice.id);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          action == 'Delete'
              ? 'Delete this notice?'
              : 'Re-publish this notice?',
        ),
        content: Text(
          action == 'Delete'
              ? '“${notice.title}” and its notifications will be removed.'
              : '“${notice.title}” will be published now with no expiry. Matching students will receive a new notification. You can set an expiry using Edit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      if (action == 'Delete') {
        await widget.store.deleteNotice(notice.id);
      } else {
        await widget.store.republishNotice(notice.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException
                  ? e.message
                  : 'Unable to complete the action. Please retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = widget.notice;
    final color = noticeColor(notice.priority);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withValues(
            alpha: notice.priority == 'Normal' ? .15 : .5,
          ),
        ),
      ),
      child: InkWell(
        onTap: busy ? null : () => act('View'),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 5)),
            color: notice.priority == 'Normal'
                ? null
                : color.withValues(alpha: .04),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    notice.priority == 'Urgent'
                        ? Icons.warning_amber_rounded
                        : Icons.campaign_outlined,
                    color: color,
                  ),
                  Text(
                    notice.priority,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '· ${notice.category}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if (!notice.isRead && !widget.manage)
                    const Chip(
                      label: Text('New Notice'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (widget.manage)
                    Chip(
                      label: Text(notice.status),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                notice.title,
                style: const TextStyle(
                  color: navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                notice.body,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.45),
              ),
              const SizedBox(height: 12),
              Text(
                'Posted by: ${notice.publisherName} · ${notice.publisherRole}',
                style: const TextStyle(
                  color: green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'For: ${notice.targetSummary}',
                style: const TextStyle(color: Colors.black54),
              ),
              Text(
                'Date: ${noticeDate(notice.date)}',
                style: const TextStyle(color: Colors.black54),
              ),
              if (widget.manage || notice.expiresAt != null)
                Text(
                  'Expiry: ${notice.expiresAt == null ? 'No expiry' : noticeDate(notice.expiresAt)}',
                  style: const TextStyle(color: Colors.black54),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: busy ? null : () => act('View'),
                    icon: Icon(
                      notice.attachmentName != null
                          ? Icons.attach_file
                          : Icons.open_in_new,
                    ),
                    label: Text(
                      notice.attachmentName != null
                          ? 'View notice & attachment'
                          : 'View notice',
                    ),
                  ),
                  if (widget.manage)
                    ...['Edit', 'Delete', 'Re-publish'].map(
                      (action) => TextButton(
                        onPressed: busy ? null : () => act(action),
                        child: Text(action),
                      ),
                    ),
                ],
              ),
              if (busy) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class NoticeDetails extends StatefulWidget {
  const NoticeDetails({required this.store, required this.id, super.key});
  final Store store;
  final int id;
  @override
  State<NoticeDetails> createState() => _NoticeDetailsState();
}

class _NoticeDetailsState extends State<NoticeDetails> {
  DepartmentNotice? notice;
  String? error;
  bool openingAttachment = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => error = null);
    try {
      final result = await widget.store.openNotice(widget.id);
      if (mounted) setState(() => notice = result);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is ApiException
              ? e.message
              : 'Unable to open this notice. Please retry.',
        );
      }
    }
  }

  Future<void> openAttachment() async {
    setState(() => openingAttachment = true);
    try {
      // Fetch a fresh signed link and recheck access each time the attachment is opened.
      final result = await widget.store.openNotice(widget.id);
      final path = result.data['attachment_url']?.toString();
      if (path == null) {
        throw const ApiException('This attachment is no longer available.');
      }
      final opened = await launchUrl(
        Uri.parse(widget.store.api.absoluteUrl(path)),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw const ApiException('Unable to open the attachment.');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException
                  ? e.message
                  : 'Unable to open the attachment. Please retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => openingAttachment = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      title: const Text('Notice'),
    ),
    body: error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error!),
                  TextButton(onPressed: load, child: const Text('Retry')),
                ],
              ),
            ),
          )
        : notice == null
        ? const Center(child: CircularProgressIndicator())
        : Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(notice!.priority),
                        labelStyle: TextStyle(
                          color: noticeColor(notice!.priority),
                        ),
                      ),
                      Chip(label: Text(notice!.category)),
                      Chip(label: Text(notice!.status)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    notice!.title,
                    style: const TextStyle(
                      fontSize: 26,
                      color: navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Posted by: ${notice!.publisherName}\nRole: ${notice!.publisherRole}\nFor: ${notice!.targetSummary}\nDate: ${noticeDate(notice!.date)}',
                    style: const TextStyle(color: Colors.black54, height: 1.6),
                  ),
                  if (notice!.expiresAt != null)
                    Text(
                      'Expires: ${noticeDate(notice!.expiresAt)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  const Divider(height: 32),
                  SelectableText(
                    notice!.body,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                  if (notice!.attachmentName != null) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: openingAttachment ? null : openAttachment,
                      icon: const Icon(Icons.attach_file),
                      label: Text(notice!.attachmentName!),
                    ),
                  ],
                ],
              ),
            ),
          ),
  );
}

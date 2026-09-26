import 'package:flutter/material.dart';

import 'api_service.dart';
import 'app_state.dart';

String complaintDateTime(DateTime value) {
  final date = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
}

class RoutingField extends StatelessWidget {
  const RoutingField(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(color: navy, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class ComplaintRoutingSummary extends StatelessWidget {
  const ComplaintRoutingSummary(
    this.complaint, {
    super.key,
    this.expanded = false,
  });
  final Complaint complaint;
  final bool expanded;
  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final fields = <Widget>[
      RoutingField('Student Registration No', c.registrationNumber),
      if (expanded)
        RoutingField(
          'Batch Adviser',
          c.routingLabel('batch_adviser', fallback: 'Not recorded'),
        ),
      RoutingField(
        'Received From',
        c.routingLabel(
          'received_from',
          fallback: '${c.registrationNumber} – Student',
        ),
      ),
      if (expanded || c.routing['originally_forwarded_by'] != null)
        RoutingField(
          'Originally Forwarded By',
          c.routingLabel('originally_forwarded_by'),
        ),
      RoutingField('Forwarded By', c.routingLabel('forwarded_by')),
      RoutingField('Forwarded To', c.routingLabel('forwarded_to')),
      if (expanded && c.routing['next_forwarded_to'] != null)
        RoutingField('Next Forwarded To', c.routingLabel('next_forwarded_to')),
      RoutingField('Currently With', c.currentlyWith),
      if (expanded) RoutingField('Status', c.status.label),
      RoutingField(
        'Date and Time',
        complaintDateTime(c.updatedAt ?? c.createdAt),
      ),
      if (expanded) RoutingField('Submitted', complaintDateTime(c.createdAt)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650
            ? 3
            : (constraints.maxWidth >= 400 ? 2 : 1);
        final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 2,
          children: fields
              .map((field) => SizedBox(width: width, child: field))
              .toList(),
        );
      },
    );
  }
}

class ComplaintRoutingHistory extends StatelessWidget {
  const ComplaintRoutingHistory(this.complaint, {super.key});
  final Complaint complaint;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final event in complaint.routingHistory)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 3, right: 12),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  color: green,
                  size: 19,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: green.withValues(alpha: .18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.action,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${event.type == 'submitted' ? 'Student' : 'Sent / acted by'}: ${event.actor?.label ?? 'Name not recorded'}',
                      ),
                      if (event.recipient != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${event.type == 'returned' ? 'Sent To' : 'Received by'}: ${event.recipient!.label}',
                        ),
                      ],
                      if (event.comment?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Comment: ${event.comment}',
                          style: const TextStyle(height: 1.4),
                        ),
                      ],
                      if (event.createdAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          complaintDateTime(event.createdAt!),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      if (complaint.routingHistory.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('No routing records are available for this complaint.'),
        ),
      RoutingField(
        complaint.handlerRole == 'closed'
            ? 'Complaint closed'
            : 'Currently Handling Complaint',
        complaint.currentlyWith,
      ),
    ],
  );
}

class ForwardComplaintDialog extends StatefulWidget {
  const ForwardComplaintDialog(
    this.store,
    this.complaint, {
    super.key,
    this.returning = false,
    this.resolution = false,
  });
  final Store store;
  final Complaint complaint;
  final bool returning, resolution;
  @override
  State<ForwardComplaintDialog> createState() => _ForwardComplaintDialogState();
}

class _ForwardComplaintDialogState extends State<ForwardComplaintDialog> {
  final comment = TextEditingController();
  final form = GlobalKey<FormState>();
  List<RoutingPerson> recipients = [];
  RoutingPerson? selected;
  bool loading = true, sending = false;
  String? error;
  String get title => widget.resolution
      ? 'Send Resolution'
      : (widget.returning ? 'Return Complaint' : 'Forward Complaint');

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await widget.store.api.complaintRecipients(
        widget.complaint.backendId!,
      );
      if (!mounted) return;
      setState(() {
        recipients = result.map(RoutingPerson.fromJson).toList();
        loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          error = e.message;
          loading = false;
        });
      }
    }
  }

  Future<void> submit() async {
    if (!form.currentState!.validate() || selected == null) return;
    setState(() {
      sending = true;
      error = null;
    });
    try {
      await widget.store.move(
        widget.complaint,
        widget.resolution
            ? 'send_resolved_department'
            : (widget.returning ? 'return' : 'forward'),
        recipientId: selected!.id,
        remarks: comment.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          error = e.message;
          sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !sending,
    child: AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RoutingField('Current Holder', widget.complaint.currentlyWith),
                if (loading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (recipients.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: widget.returning
                            ? 'Return To'
                            : 'Forward To',
                      ),
                      hint: const Text('Select Person'),
                      items: recipients
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                p.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: sending
                          ? null
                          : (id) => setState(
                              () => selected = recipients.firstWhere(
                                (p) => p.id == id,
                              ),
                            ),
                      validator: (id) => id == null ? 'Select a person.' : null,
                    ),
                    const SizedBox(height: 12),
                    RoutingField(
                      'Role',
                      selected?.roleLabel ??
                          'Select a person to display their role',
                    ),
                    TextFormField(
                      controller: comment,
                      enabled: !sending,
                      maxLines: 3,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: 'Comment',
                        hintText: 'Enter Comment',
                      ),
                    ),
                  ] else if (error == null)
                    const Text(
                      'No authorized recipients are currently available.',
                    ),
                ],
                if (error != null) ...[
                  Text(error!, style: const TextStyle(color: Colors.red)),
                  if (recipients.isEmpty)
                    TextButton(onPressed: load, child: const Text('Retry')),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: sending ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: sending || loading || recipients.isEmpty ? null : submit,
          child: Text(sending ? 'Sending…' : title),
        ),
      ],
    ),
  );
}

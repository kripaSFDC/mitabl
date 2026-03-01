import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/common_appbar.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/support_ticket_repository.dart';

class SettingsCookPage extends StatefulWidget {
  const SettingsCookPage({Key? key, this.routeArguments}) : super(key: key);

  final RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder:
          (_) => /*BlocProvider(
          create: (context) => CookProfileCubit(
              context.read<AuthenticationRepository>(), routeArguments),
          child:*/
              SettingsCookPage(routeArguments: routeArguments),
      // ));
    );
  }

  @override
  State<SettingsCookPage> createState() => _SettingsCookPageState();
}

class _SettingsCookPageState extends State<SettingsCookPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _ticketIdController;
  late final TextEditingController _replyController;

  bool _supportActionInFlight = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _subjectController = TextEditingController();
    _descriptionController = TextEditingController();
    _ticketIdController = TextEditingController();
    _replyController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _ticketIdController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitSupportTicket() async {
    final repository = context.read<SupportTicketRepository>();
    setState(() => _supportActionInFlight = true);

    try {
      final result = await repository.createSupportTicket(
        requesterEmail: _emailController.text.trim(),
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      final message =
          result['message']?.toString() ?? 'Support ticket created successfully.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to create ticket: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _supportActionInFlight = false);
      }
    }
  }

  Future<void> _loadSupportTicket() async {
    final ticketId = int.tryParse(_ticketIdController.text.trim());
    if (ticketId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid ticket id.')),
      );
      return;
    }

    final repository = context.read<SupportTicketRepository>();
    setState(() => _supportActionInFlight = true);

    try {
      final result = await repository.getSupportTicket(id: ticketId);
      final status = result['data']?['status']?.toString() ?? 'unknown';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket $ticketId status: $status')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load ticket: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _supportActionInFlight = false);
      }
    }
  }

  Future<void> _replyToSupportTicket() async {
    final ticketId = int.tryParse(_ticketIdController.text.trim());
    if (ticketId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid ticket id first.')),
      );
      return;
    }

    final repository = context.read<SupportTicketRepository>();
    setState(() => _supportActionInFlight = true);

    try {
      final result = await repository.replyToSupportTicket(
        id: ticketId,
        message: _replyController.text.trim(),
      );
      final message = result['message']?.toString() ?? 'Reply submitted.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to send reply: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _supportActionInFlight = false);
      }
    }
  }

  Future<void> _openSupportSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                TextField(
                  controller: _ticketIdController,
                  decoration: const InputDecoration(labelText: 'Ticket ID'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _replyController,
                  decoration: const InputDecoration(labelText: 'Reply message'),
                  maxLines: 2,
                ),
                SizedBox(height: config.AppConfig(context).appHeight(2)),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed:
                          _supportActionInFlight ? null : _submitSupportTicket,
                      child: const Text('Create Ticket'),
                    ),
                    ElevatedButton(
                      onPressed:
                          _supportActionInFlight ? null : _loadSupportTicket,
                      child: const Text('Get Ticket'),
                    ),
                    ElevatedButton(
                      onPressed:
                          _supportActionInFlight ? null : _replyToSupportTicket,
                      child: const Text('Reply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CommonAppBar(
          title: 'Settings',
          isFilter: false,
        ),
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.only(
            left: config.AppConfig(context).appWidth(3),
            right: config.AppConfig(context).appWidth(3),
          ),
          child: Column(
            children: [
              SizedBox(
                height: config.AppConfig(context).appHeight(3),
              ),
              ListTile(
                onTap: () {
                  if (widget.routeArguments!.id == 'foodie') {
                    navigatorKey.currentState!.pushNamed('/EditProfileFoodie');
                  } else {
                    navigatorKey.currentState!.pushNamed('/ProfileCook');
                  }
                },
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.zero,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/img/background.svg',
                            height: config.AppConfig(context).appHeight(4.5),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          widthFactor: 2,
                          child: SvgPicture.asset(
                            'assets/img/edit.svg',
                            height: config.AppConfig(context).appHeight(2),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: config.AppConfig(context).appWidth(4),
                    ),
                    Text(
                      'Edit profile',
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: config.AppConfig(context).appWidth(4.5),
                          fontWeight: FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward,
                  size: config.AppConfig(context).appWidth(6),
                  color: Theme.of(context).primaryColorDark,
                ),
              ),
              ListTile(
                onTap: () {
                  // navigatorKey.currentState!.pushNamed('/SettingsCook');
                },
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.zero,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/img/notification.svg',
                    ),
                    SizedBox(
                      width: config.AppConfig(context).appWidth(4),
                    ),
                    Text(
                      'Notification',
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: config.AppConfig(context).appWidth(4.5),
                          fontWeight: FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ),
                trailing: Container(
                  width: config.AppConfig(context).appWidth(18),
                  child: FlutterSwitch(
                    value: true,
                    activeText: '',
                    inactiveText: '',
                    valueFontSize: config.AppConfig(context).appWidth(4),
                    width: config.AppConfig(context).appWidth(13.8),
                    height: config.AppConfig(context).appHeight(3.8),
                    inactiveColor: Theme.of(context).primaryColorDark,
                    borderRadius: 30.0,
                    showOnOff: true,
                    onToggle: (val) {},
                  ),
                ),
              ),
              ListTile(
                onTap: () {
                  _openSupportSheet();
                },
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.zero,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/img/delete.svg',
                    ),
                    SizedBox(
                      width: config.AppConfig(context).appWidth(4),
                    ),
                    Text(
                      'Help & Support',
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: config.AppConfig(context).appWidth(4.5),
                          fontWeight: FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward,
                  size: config.AppConfig(context).appWidth(6),
                  color: Theme.of(context).primaryColorDark,
                ),
              ),
              ListTile(
                onTap: () {
                  // Delete account flow placeholder.
                },
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.zero,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/img/delete.svg',
                    ),
                    SizedBox(
                      width: config.AppConfig(context).appWidth(4),
                    ),
                    Text(
                      'Delete Account',
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: config.AppConfig(context).appWidth(4.5),
                          fontWeight: FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward,
                  size: config.AppConfig(context).appWidth(6),
                  color: Theme.of(context).primaryColorDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

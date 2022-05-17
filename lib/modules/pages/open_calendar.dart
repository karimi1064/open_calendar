import 'package:calendar_app/components/card_widget.dart';
import 'package:calendar_app/utils/app_colors.dart';
import 'package:calendar_app/utils/app_styles.dart';
import 'package:calendar_app/utils/snack_bar_utils.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/timezone.dart' as time_zone;

class OpenCalendar extends StatefulWidget {
  final bool isAlert;
  final bool isCalendar;

  const OpenCalendar(
      {Key? key,
      required this.isAlert,
      required this.isCalendar})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _OpenCalendarState();
  }
}

class _OpenCalendarState extends State<OpenCalendar> {
  final String appointmentDate = '';
  final String appointmentTime = '';
  late DeviceCalendarPlugin _deviceCalendarPlugin;
  late StateSetter setStateModalNewEvent;
  List<Calendar> _calendars = [];
  final List<Reminder> _reminders = [];
  Calendar _calendar = Calendar();
  bool isLoading = false;
  bool isAvailableUserLocation = false;
  bool isSwitchedAllDay = false;
  String _timezone = 'Etc/UTC';
  String calendarAlert = 'none'.tr();
  String calendarName = 'my_calendar'.tr();
  Event? _event;
  final titleTextEditingController = TextEditingController();
  final locationTextEditingController = TextEditingController();
  final urlTextEditingController = TextEditingController();
  final notesTextEditingController = TextEditingController();

  @override
  void dispose() {
    titleTextEditingController.dispose();
    locationTextEditingController.dispose();
    urlTextEditingController.dispose();
    notesTextEditingController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if (!widget.isAlert && !widget.isCalendar) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        _initCalendar();
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateModal) {
      if (!widget.isAlert && !widget.isCalendar) setStateModalNewEvent = setStateModal;
      return SlidingSheet(
        cornerRadius: 15,
        color: AppColors.indigoLight,
        snapSpec: const SnapSpec(
          snappings: [0.93, 0.99],
        ),
        builder: (BuildContext context, SheetState state) {
          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 35),
              child: widget.isAlert
                  ? _buildContentAlertBottomSheet()
                  : widget.isCalendar
                      ? _buildContentCalendarBottomSheet()
                      : _buildContentNewEventBottomSheet(
                          context, setStateModal),
            ),
          );
        },
        headerBuilder: (context, SheetState state) {
          return widget.isAlert
              ? _buildHeaderBottomSheet(context, 'new_event'.tr(), 'alert'.tr(),
                  isSaveButton: false)
              : widget.isCalendar
                  ? _buildHeaderBottomSheet(
                      context, 'new_event'.tr(), 'calendar'.tr(),
                      isSaveButton: false)
                  : _buildHeaderBottomSheet(
                      context,
                      'cancel'.tr(),
                      'new_event'.tr(),
                    );
        },
      );
    });
  }

  Widget _buildHeaderBottomSheet(
      BuildContext context, String backText, String headerText,
      {bool isSaveButton = true}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                backText,
                style: AppStyles.smallText16Style
                    .copyWith(color: AppColors.lightRed),
              )),
          Text(
            headerText,
            style: AppStyles.smallText18Style,
          ),
          isSaveButton
              ? InkWell(
                  onTap: _saveToCalendar,
                  child: Text(
                    'add'.tr(),
                    style: AppStyles.smallText18Style.copyWith(
                        color: titleTextEditingController.text.isNotEmpty
                            ? AppColors.lightRed
                            : AppColors.themeGrey),
                  ))
              : const SizedBox(width: 80),
        ],
      ),
    );
  }

  Future<void> _saveToCalendar() async {
    await _createEvent();

    var createEventResult =
        await _deviceCalendarPlugin.createOrUpdateEvent(_event);

    if (createEventResult?.isSuccess == true) {
      _showSnackBar('successfully_added'.tr(), isError: false);
      Navigator.of(context).pop();
    } else {
      _showSnackBar(createEventResult?.errors
              .map((err) => '[${err.errorCode}] ${err.errorMessage}')
              .join(' | ') ??
          'error'.tr());
      if (kDebugMode) {
        print(createEventResult?.errors
                .map((err) => '[${err.errorCode}] ${err.errorMessage}')
                .join(' | ') ??
            'error'.tr());
      }
    }
  }

  _showSnackBar(String s, {bool isError = true}) {
    SnackBarUtils.showBasicsFlash(
        context: context, message: s, isError: isError);
  }

  Future<void> _createEvent() async {
    if (_calendar.id == null) {
      _showSnackBar('error'.tr());
      return;
    }

    await getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    try {
      _timezone = await FlutterNativeTimezone.getLocalTimezone();
    } catch (e) {
      if (kDebugMode) {
        print('Could not get the local timezone');
      }
    }

    _event ??= Event(_calendar.id);
    if (kDebugMode) {
      print('calendar_event _timezone ------------------------- $_timezone');
    }
    var currentLocation = time_zone.timeZoneDatabase.locations[_timezone];
    if (currentLocation != null) {
      _event?.start = time_zone.TZDateTime.now(currentLocation);
      _event?.end = time_zone.TZDateTime.now(currentLocation)
          .add(const Duration(hours: 1));
    } else {
      var fallbackLocation = time_zone.timeZoneDatabase.locations['Etc/UTC'];
      _event?.start = time_zone.TZDateTime.now(fallbackLocation!);
      _event?.end = time_zone.TZDateTime.now(fallbackLocation!)
          .add(const Duration(hours: 1));
    }

    _event?.calendarId = _calendar.id;
    _event?.title = titleTextEditingController.text;
    _event?.availability = Availability.Busy;
    _event?.location = locationTextEditingController.text;
    _event?.description = notesTextEditingController.text;
    _event?.reminders = _reminders;

    if (kDebugMode) {
      print('DeviceCalendarPlugin calendar id is: ${_calendar.id}');
    }
  }

  Widget _buildContentNewEventBottomSheet(
      BuildContext context, StateSetter setStateModal) {
    return Column(
      children: [
        _buildCardWidgetForCalendar(
            Column(
              children: [
                _buildTextField(titleTextEditingController, 'title'.tr()),
                _buildDivider(),
                _buildTextField(locationTextEditingController, 'location'.tr(),
                    textInputType: TextInputType.streetAddress),
              ],
            ),
            margin: const EdgeInsets.only(bottom: 20, top: 10),
            padding: const EdgeInsets.fromLTRB(20, 0, 0, 0)),
        _buildCardWidgetForCalendar(
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _item('all_day'.tr()),
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: CupertinoSwitch(
                        activeColor: AppColors.green,
                        trackColor: AppColors.lightGrey,
                        // inactiveTrackColor: AppColors.lightGrey,
                        value: isSwitchedAllDay,
                        onChanged: (value) {
                          setStateModal(() => isSwitchedAllDay = value);
                        },
                      ),
                    ),
                  ],
                ),
                _buildDivider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isSwitchedAllDay) _item('starts'.tr()),
                    Row(
                      children: [
                        // CardWidget(
                        //     borderRadius: 10,
                        //     padding: const EdgeInsets.all(10),
                        //     margin: const EdgeInsets.symmetric(vertical: 4),
                        //     child: _item(appointmentDate),
                        //     color: AppColors.indigoLight),
                        if (!isSwitchedAllDay) const SizedBox(width: 5),
                        if (!isSwitchedAllDay)
                          CardWidget(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              borderRadius: 10,
                              padding: const EdgeInsets.all(10),
                              child: _item((_event?.start?.hour.toString() ??
                                      '9') +
                                  ':' +
                                  (_event?.start?.minute.toString() ?? '00')),
                              color: AppColors.indigoLight),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ],
                ),
                _buildDivider(),
                if (!isSwitchedAllDay)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _item('ends'.tr()),
                      Row(
                        children: [
                          // CardWidget(
                          //     borderRadius: 10,
                          //     padding: const EdgeInsets.all(10),
                          //     margin: const EdgeInsets.symmetric(vertical: 4),
                          //     child: _item(appointmentDate),
                          //     color: AppColors.indigoLight),
                          // const SizedBox(width: 5),
                          CardWidget(
                              borderRadius: 10,
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: _item(
                                  (_event?.end?.hour.toString() ?? '10') +
                                      ':' +
                                      (_event?.end?.minute.toString() ?? '00')),
                              color: AppColors.indigoLight),
                          const SizedBox(width: 20),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 10, 0, 0)),
        _buildCardWidgetForCalendar(
            InkWell(
              onTap: () => _buildCalendarModalBottomSheet(isCalendar: true),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _item('calendar'.tr()),
                  Row(
                    children: [
                      Text('•',
                          style: TextStyle(
                              color: Color(_calendar.color ?? 0),
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(width: 10),
                      Text(calendarName,
                          style: AppStyles.normalText16Style
                              .copyWith(color: AppColors.darkGrey)),
                      const SizedBox(width: 10),
                      Image.asset('assets/icons/arrow-forward.png', height: 20),
                    ],
                  ),
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10)),
        _buildCardWidgetForCalendar(
            InkWell(
              onTap: () => _buildCalendarModalBottomSheet(isAlert: true),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _item('alert'.tr()),
                  Row(
                    children: [
                      Text(calendarAlert,
                          style: AppStyles.normalText16Style
                              .copyWith(color: AppColors.darkGrey)),
                      const SizedBox(width: 10),
                      Image.asset('assets/icons/arrow-forward.png', height: 20),
                    ],
                  ),
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10)),
        _buildCardWidgetForCalendar(Column(
          children: [
            _buildTextField(urlTextEditingController, 'url'.tr(),
                textInputType: TextInputType.url),
            _buildDivider(),
            _buildTextField(notesTextEditingController, 'notes'.tr(),
                minLines: 5, textInputAction: TextInputAction.done),
          ],
        )),
      ],
    );
  }

  Future<void> _buildCalendarModalBottomSheet(
      {bool isAlert = false, bool isCalendar = false}) async {
    if (!isAlert && !isCalendar) await _initCalendar();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useRootNavigator: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            if (!isAlert && !isCalendar) setStateModalNewEvent = setStateModal;
            return _buildCalendarBottomSheet(
                setStateModal, isAlert, isCalendar);
          },
        );
      },
    );
  }

  Widget _buildCalendarBottomSheet(
      StateSetter setStateModal, bool isAlert, bool isCalendar) {
    return SlidingSheet(
      cornerRadius: 15,
      color: AppColors.indigoLight,
      snapSpec: const SnapSpec(
        snappings: [0.93, 0.94],
      ),
      builder: (BuildContext context, SheetState state) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 35),
            child: isAlert
                ? _buildContentAlertBottomSheet()
                : isCalendar
                ? _buildContentCalendarBottomSheet()
                : _buildContentNewEventBottomSheet(context, setStateModal),
          ),
        );
      },
      headerBuilder: (context, SheetState state) {
        return isAlert
            ? _buildHeaderBottomSheet(context, 'new_event'.tr(), 'alert'.tr(),
            isSaveButton: false)
            : isCalendar
            ? _buildHeaderBottomSheet(
            context, 'new_event'.tr(), 'calendar'.tr(),
            isSaveButton: false)
            : _buildHeaderBottomSheet(
          context,
          'cancel'.tr(),
          'new_event'.tr(),
        );
      },
    );
  }

  Widget _item(String text) {
    return Text(text,
        style: AppStyles.smallText16Style.copyWith(color: AppColors.grey));
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: AppColors.themeGrey);
  }

  Widget _buildTextField(
      TextEditingController textEditingController, String label,
      {TextInputAction textInputAction = TextInputAction.next,
      TextInputType textInputType = TextInputType.text,
      int minLines = 1}) {
    return TextField(
      cursorColor: AppColors.lightRed,
      keyboardType: textInputType,
      controller: textEditingController,
      style: AppStyles.smallText16Style.copyWith(color: AppColors.grey),
      decoration: InputDecoration(
          border: InputBorder.none,
          hintText: label,
          hintStyle:
              AppStyles.smallText16Style.copyWith(color: AppColors.lightGrey)),
      textInputAction: textInputAction,
      maxLines: 5,
      minLines: minLines,
      // onChanged: (value) {
      //   textEditingController.text = value;
      // },
    );
  }

  Widget _buildCardWidgetForCalendar(Widget child,
      {EdgeInsets margin = const EdgeInsets.symmetric(vertical: 15),
      EdgeInsets padding = const EdgeInsets.fromLTRB(20, 10, 0, 10)}) {
    return CardWidget(
        borderRadius: 10, margin: margin, padding: padding, child: child);
  }

  Widget _buildContentCalendarBottomSheet() {
    return Column(
      children: [
        _buildCardWidgetForCalendar(
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _calendars
                  .map((e) => _buildCalendarRow(e.name ?? '', e.color ?? 0))
                  .toList()),
          margin: const EdgeInsets.only(bottom: 20, top: 10),
        ),
        const SizedBox(height: 550),
      ],
    );
  }

  Widget _buildCalendarRow(String title, int color) {
    return Column(
      children: [
        InkWell(
          onTap: () => _setCalendarName(title, color),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              children: [
                Text('•',
                    style: TextStyle(
                        color: Color(color),
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
                const SizedBox(width: 10),
                _item(title),
              ],
            ),
          ),
        ),
        _buildDivider(),
      ],
    );
  }

  void _setCalendarName(String name, int color) {
    setStateModalNewEvent(() {
      _calendar.color = color;
      calendarName = name;
      _retrieveCalendar();
    });
    Navigator.of(context).pop();
  }

  void _retrieveCalendar() {
    _calendar = _calendars.firstWhere((element) => element.name == calendarName,
        orElse: () => Calendar());

    if (kDebugMode) {
      print(_calendar.toJson());
    }
  }

  Widget _buildContentAlertBottomSheet() {
    return Column(
      children: [
        _buildCardWidgetForCalendar(_buildAlertRow('none'.tr()),
            margin: const EdgeInsets.only(bottom: 20, top: 10),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10)),
        _buildCardWidgetForCalendar(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAlertRow('at_time_of_event'.tr(), 0),
              _buildDivider(),
              _buildAlertRow('5 ' + 'minutes_before'.tr(), 5),
              _buildDivider(),
              _buildAlertRow('10 ' + 'minutes_before'.tr(), 10),
              _buildDivider(),
              _buildAlertRow('15 ' + 'minutes_before'.tr(), 15),
              _buildDivider(),
              _buildAlertRow('30 ' + 'minutes_before'.tr(), 30),
              _buildDivider(),
              _buildAlertRow('1 ' + 'hour_before'.tr(), 60),
              _buildDivider(),
              _buildAlertRow('2 ' + 'hours_before'.tr(), 120),
              _buildDivider(),
              _buildAlertRow('1 ' + 'day_before'.tr(), 1440),
              _buildDivider(),
              _buildAlertRow('2 ' + 'days_before'.tr(), 2880),
              _buildDivider(),
              _buildAlertRow('1 ' + 'week_before'.tr(), 10080),
            ],
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildAlertRow(String title, [int? minutes]) {
    return InkWell(
      onTap: () => _setCalendarAlert(title, minutes),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        width: MediaQuery.of(context).size.width,
        child: _item(title),
      ),
    );
  }

  void _setCalendarAlert(String alert, [int? minutes]) {
    setStateModalNewEvent(() {
      _reminders.clear();
      if (minutes != null) _reminders.add(Reminder(minutes: minutes));
      calendarAlert = alert;
    });
    Navigator.of(context).pop();
  }

  Future<void> _initCalendar() async {
    await _initialEvent();
    titleTextEditingController.text = calendarName;
    locationTextEditingController.text = '';
    urlTextEditingController.text = _event?.url?.toString() ?? '';
    notesTextEditingController.text = '';
  }

  Future<void> _initialEvent() async {
    _deviceCalendarPlugin = DeviceCalendarPlugin();
    await _retrieveCalendars();
    _retrieveCalendar();
    _createCalendar();
  }

  void _createCalendar() async {
    if (_calendar.name != 'my_calendar'.tr() &&
        calendarName == 'my_calendar'.tr()) {
      var result = await _deviceCalendarPlugin.createCalendar(
        'my_calendar'.tr(),
        calendarColor: AppColors.logoBackground,
        localAccountName: '',
      );

      if (result.isSuccess) {
        await _retrieveCalendars();
        _retrieveCalendar();
      } else {
        _showSnackBar(result.errors
            .map((err) => '[${err.errorCode}] ${err.errorMessage}')
            .join(' | '));
      }
    }
  }

  Future<void> _retrieveCalendars() async {
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess &&
          (permissionsGranted.data == null ||
              permissionsGranted.data == false)) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess ||
            permissionsGranted.data == null ||
            permissionsGranted.data == false) {
          return;
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      _calendars = calendarsResult.data as List<Calendar>;
      _calendars =
          _calendars.where((element) => element.isReadOnly == false).toList();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }
}

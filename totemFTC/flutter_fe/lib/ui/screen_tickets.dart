import 'package:flutter/material.dart';
import 'package:flutter_fe/blocs/bloc_provider.dart';
import 'package:flutter_fe/blocs/crud_ticket.dart';
import 'package:flutter_fe/blocs/crud_user.dart';
import 'package:flutter_fe/blocs/crud_visit.dart';
import 'package:flutter_fe/blocs/session.dart';
import 'package:flutter_fe/ui/widgets/ui_selector_training.dart';
import 'package:flutter_fe/ui/widgets/ui_visit.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import 'screen_base.dart';
import 'widgets/ui_divider.dart';
import 'widgets/ui_ticket.dart';

// todo add radio selector for ticket
class ScreenTickets extends StatefulWidget {
  static const routeName = '/tickets';

  @override
  State createState() => ScreenTicketsState();
}

class ScreenTicketsState extends BlocProvider<ScreenTickets> {

  static final formatDateTime = DateFormat('yyyy-MM-dd HH:mm');

  late final Session session;
  late final SelectedVisitBloc visitBloc;

  @override
  void initState() {
    super.initState();
    session = Injector().get<Session>();
    CrudTicketBloc(provider: this).loadTickets();
    visitBloc = SelectedVisitBloc(provider: this);
    visitBloc.loadVisits(DateTime.now().subtract(Duration(days: 14)), 10);
  }

  @override
  Widget build(BuildContext context) {
    return UiScreen(body: Column(
        children: [
          BlocProvider.streamBuilder<List<CrudEntityTicket>, CrudTicketBloc>(builder: (ctx, data) => Column(children: [
            if (data.isNotEmpty) UiDivider('Абонементы'),
            for (var ticket in data)
              GestureDetector(
                onTap: () => visitBloc.selectTicket(session.user, ticket),
                child: UiTicket(ticket),
              )
          ])),
          BlocProvider.streamBuilder<List<CrudEntityVisit>, SelectedVisitBloc>(builder: (ctx, data) => Column(
            children: [
              UiDivider(_ticketName('Выберите абонемент', 'Посещения', visitBloc.selectedTicket)),
              for (var visit in data) UiVisit(visit),
            ],
          )),
        ]
    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddTraining(context, session, visitBloc),
        tooltip: 'Add',
        child: Icon(Icons.add),
      ),
    );
  }

  String _ticketName(String ifEmpty, String prefix, CrudEntityTicket? ticket) =>
      ticket != null ? '$prefix ${ticket.ticketType.name} / ${formatDateTime.format(ticket.buy)}' : ifEmpty;

  Future<void> _onAddTraining(BuildContext context, Session session, SelectedVisitBloc visitBloc) async {
    DateTime now = DateTime.now();
    var result = await UiSelectorTrainingDialog(title: _ticketName('Отметить посещение', 'Отметить абонемент', visitBloc.selectedTicket),
        dateRange: DateTimeRange(start: now.subtract(Duration(days: 7)), end: now),
        types: visitBloc.selectedTicket?.ticketType.trainingTypes
    ).selectTraining(context);
    log.finer("Dialog result: $result");
    if (result != null) {
      bool _past = result.time.isBefore(now);
      CrudEntityVisit visit = CrudEntityVisit(
          user: session.user,
          training: result,
          trainingId: result.id,
          markSchedule: _past ? false : true,
          markSelf: _past ? CrudEntityVisitMark.on : CrudEntityVisitMark.unmark,
          markMaster: CrudEntityVisitMark.unmark);
      visitBloc.markSelf(visit, CrudEntityVisitMark.on);
    }
  }
}

class SelectedVisitBloc extends CrudVisitBloc {
  CrudEntityTicket? selectedTicket;

  SelectedVisitBloc({List<CrudEntityVisit> state = const [], required BlocProvider provider, String? name}): super(provider: provider, state: state, name: name);

  Future<void> selectTicket(CrudEntityUser user, CrudEntityTicket ticket) async {
    ticket.visits ??= (await backend.requestJson('GET', '/api/visit/byTicket/${ticket.id}') as List)
        .map((item) {
      var crudEntityVisit = CrudEntityVisit.fromJson(item);
      crudEntityVisit.user = user;
      crudEntityVisit.ticket = ticket;
      return crudEntityVisit;
    }).toList();
    state = ticket.visits!;
    selectedTicket = ticket;
  }
}

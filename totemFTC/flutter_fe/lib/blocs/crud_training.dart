import 'dart:async';
import 'dart:collection';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_fe/blocs/crud_visit.dart';
import 'package:json_annotation/json_annotation.dart';

import '../misc/utils.dart';
import 'bloc_provider.dart';
import 'crud_api.dart';
import 'crud_user.dart';

part 'crud_training.g.dart';

class CrudTrainingBloc extends BlocBaseList<CrudEntityTraining> {

  CrudTrainingBloc({List<CrudEntityTraining> state = const [], required BlocProvider provider, String? name, bool master = false}): super(provider: provider, state: state, name: name);

  void loadTrainings(DateTime from, DateTime to) async {
    state = await cache('user_${dateTimeFormat.format(from)}_${dateTimeFormat.format(to)}', () async =>
        (await backend.requestJson('GET', '/api/userTraining/byDateInterval', params: {'from': dateTimeFormat.format(from), 'to': dateTimeFormat.format(to)}) as List)
            .map((item) => CrudEntityTraining.fromJson(item)).toList());
  }

  void loadMasterTrainings(DateTime from, DateTime to) async {
    state = await cache('trainer_${dateTimeFormat.format(from)}_${dateTimeFormat.format(to)}', () async =>
        (await backend.requestJson('GET', '/api/masterTraining/byDateInterval', params: {'from': dateTimeFormat.format(from), 'to': dateTimeFormat.format(to)}) as List)
            .map((item) => CrudEntityTraining.fromJson(item)..trainer = session.user).toList());
  }
}

class SelectedTrainingBloc extends BlocBaseState<CrudEntityTraining?> {
  SelectedTrainingBloc({CrudEntityTraining? state, required BlocProvider provider, String? name}): super(state: state, provider: provider, name: name);
}

// class CrudTrainingTypeBloc extends BlocBaseList<CrudEntityTrainingType> {}

class CrudTrainingTypeFilteredBloc extends BlocBaseList<CrudEntityTrainingType> {
  final CrudTrainingBloc visibleTrainingBloc;
  final SelectedTrainingBloc selectedTrainingBloc;
  List<CrudEntityTraining> _allTrainings = [];

  CrudTrainingTypeFilteredBloc({required this.visibleTrainingBloc, required this.selectedTrainingBloc, List<CrudEntityTrainingType> state = const [], required BlocProvider provider, String? name}): super(provider: provider, state: state, name: name);

  Future<void> loadTrainings({List<CrudEntityTrainingType>? types, DateTimeRange? dateRange, DateFilterInfo? dateFilter, TrainingFilter? trainingFilter}) async {
    if (dateRange == null && dateFilter == null) {
      throw Exception('Internal error. Range or filter must be specified');
    }
    dateRange ??= dateFilter?.range;

    Iterable<CrudEntityTraining> loaded = (await backend.requestJson('GET', '/api/userTraining/byDateInterval', params: {
      'from': dateTimeFormat.format(dateRange!.start), 'to': dateTimeFormat.format(dateRange!.end)}) as List)
        .map((item) => CrudEntityTraining.fromJson(item));
    if (dateFilter != null) {
      loaded = loaded.where((t) => dateFilter.filter(t.time));
    }
    if (trainingFilter != null) {
      loaded = loaded.where((t) => trainingFilter(t));
    }
    _allTrainings = loaded.toList();

    Set<CrudEntityTrainingType> trainingTypesSet = HashSet<CrudEntityTrainingType>();
    _allTrainings.forEach((training) => trainingTypesSet.add(training.trainingType));
    if (types != null) {
      trainingTypesSet.retainAll(types);
      _allTrainings = _allTrainings.where((t) => types.contains(t.trainingType)).toList();
    }
    var trainingTypes = List.of(trainingTypesSet, growable: false);
    trainingTypes.sort();
    state = trainingTypes;
    if (trainingTypes.isNotEmpty) onTrainingTypeChange(trainingTypes[0]);
  }

  Future<void> onTrainingTypeChange(CrudEntityTrainingType trainingType) async {
    var trainings = <CrudEntityTraining>[];
    _allTrainings.forEach((training) {
      if (trainingType == training.trainingType) {
        trainings.add(training);
      }
    });
    visibleTrainingBloc.state = trainings;
    selectedTrainingBloc.state = null;
    // selectedTrainingBloc.state = trainings.isNotEmpty ? trainings[0] : null;
  }
}

@JsonSerializable(explicitToJson: true)
class CrudEntityTraining implements Comparable<CrudEntityTraining> {
  int id;
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  DateTime time;
  CrudEntityUser? trainer;
  CrudEntityTrainingType trainingType;
  String? comment;
  /// Used for caching values
  @JsonKey(ignore: true)
  List<CrudEntityVisit>? visits;

  CrudEntityTraining({required this.id, required this.time, this.trainer, required this.trainingType, this.comment});

  factory CrudEntityTraining.fromJson(Map<String, dynamic> json) => _$CrudEntityTrainingFromJson(json);
  Map<String, dynamic> toJson() => _$CrudEntityTrainingToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrudEntityTraining &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  int compareTo(CrudEntityTraining other) {
    if (id == other.id) return 0;
    int result = compare(0, time, other.time);
    result = compare(result, trainingType, other.trainingType);
    result = compare(result, trainer, other.trainer);
    return compareId(result, id, other.id);
  }

  @override
  String toString() {
    return 'CrudEntityTraining{id: $id, time: $time}';
  }
}

@JsonSerializable()
class CrudEntityTrainingType implements Comparable<CrudEntityTrainingType> {
  String trainingType;
  String trainingName;

  CrudEntityTrainingType({required this.trainingType, required this.trainingName});

  factory CrudEntityTrainingType.fromJson(Map<String, dynamic> json) =>_$CrudEntityTrainingTypeFromJson(json);
  Map<String, dynamic> toJson() => _$CrudEntityTrainingTypeToJson(this);

  @override
  bool operator ==(Object other) {
    return other is CrudEntityTrainingType ? other.trainingType == trainingType : false;
  }

  @override
  int get hashCode => trainingType.hashCode;

  @override
  int compareTo(CrudEntityTrainingType other) {
    return trainingType.compareTo(other.trainingType);
  }
}

typedef TrainingFilter = bool Function(CrudEntityTraining training);

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_edit_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTimelineEditLogCollection on Isar {
  IsarCollection<TimelineEditLog> get timelineEditLogs => this.collection();
}

const TimelineEditLogSchema = CollectionSchema(
  name: r'TimelineEditLog',
  id: 8598609174756232900,
  properties: {
    r'end': PropertySchema(
      id: 0,
      name: r'end',
      type: IsarType.dateTime,
    ),
    r'placeName': PropertySchema(
      id: 1,
      name: r'placeName',
      type: IsarType.string,
    ),
    r'start': PropertySchema(
      id: 2,
      name: r'start',
      type: IsarType.dateTime,
    ),
    r'transport': PropertySchema(
      id: 3,
      name: r'transport',
      type: IsarType.string,
    ),
    r'transportText': PropertySchema(
      id: 4,
      name: r'transportText',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 5,
      name: r'type',
      type: IsarType.string,
    )
  },
  estimateSize: _timelineEditLogEstimateSize,
  serialize: _timelineEditLogSerialize,
  deserialize: _timelineEditLogDeserialize,
  deserializeProp: _timelineEditLogDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _timelineEditLogGetId,
  getLinks: _timelineEditLogGetLinks,
  attach: _timelineEditLogAttach,
  version: '3.1.0+1',
);

int _timelineEditLogEstimateSize(
  TimelineEditLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.placeName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.transport;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.transportText;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.type.length * 3;
  return bytesCount;
}

void _timelineEditLogSerialize(
  TimelineEditLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.end);
  writer.writeString(offsets[1], object.placeName);
  writer.writeDateTime(offsets[2], object.start);
  writer.writeString(offsets[3], object.transport);
  writer.writeString(offsets[4], object.transportText);
  writer.writeString(offsets[5], object.type);
}

TimelineEditLog _timelineEditLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TimelineEditLog();
  object.end = reader.readDateTime(offsets[0]);
  object.id = id;
  object.placeName = reader.readStringOrNull(offsets[1]);
  object.start = reader.readDateTime(offsets[2]);
  object.transport = reader.readStringOrNull(offsets[3]);
  object.transportText = reader.readStringOrNull(offsets[4]);
  object.type = reader.readString(offsets[5]);
  return object;
}

P _timelineEditLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _timelineEditLogGetId(TimelineEditLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _timelineEditLogGetLinks(TimelineEditLog object) {
  return [];
}

void _timelineEditLogAttach(
    IsarCollection<dynamic> col, Id id, TimelineEditLog object) {
  object.id = id;
}

extension TimelineEditLogQueryWhereSort
    on QueryBuilder<TimelineEditLog, TimelineEditLog, QWhere> {
  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TimelineEditLogQueryWhere
    on QueryBuilder<TimelineEditLog, TimelineEditLog, QWhereClause> {
  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TimelineEditLogQueryFilter
    on QueryBuilder<TimelineEditLog, TimelineEditLog, QFilterCondition> {
  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      endEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'end',
        value: value,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      endGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'end',
        value: value,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      endLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'end',
        value: value,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      endBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'end',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      placeNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'placeName',
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      placeNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'placeName',
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      placeNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'placeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      placeNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'placeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      placeNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'placeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      placeNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'placeName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      placeNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'placeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      placeNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'placeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      placeNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'placeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      placeNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'placeName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      placeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'placeName',
        value: '',
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      placeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'placeName',
        value: '',
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      startEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'start',
        value: value,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      startGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'start',
        value: value,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      startLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'start',
        value: value,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      startBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'start',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'transport',
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'transport',
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transport',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transport',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transport',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transport',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'transport',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'transport',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'transport',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'transport',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transport',
        value: '',
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'transport',
        value: '',
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportTextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'transportText',
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportTextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'transportText',
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportTextEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transportText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportTextGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transportText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportTextLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transportText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportTextBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transportText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'transportText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'transportText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'transportText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'transportText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transportText',
        value: '',
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      transportTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'transportText',
        value: '',
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension TimelineEditLogQueryObject
    on QueryBuilder<TimelineEditLog, TimelineEditLog, QFilterCondition> {}

extension TimelineEditLogQueryLinks
    on QueryBuilder<TimelineEditLog, TimelineEditLog, QFilterCondition> {}

extension TimelineEditLogQuerySortBy
    on QueryBuilder<TimelineEditLog, TimelineEditLog, QSortBy> {
  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy> sortByEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.asc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy> sortByEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.desc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy>
      sortByPlaceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'placeName', Sort.asc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy>
      sortByPlaceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'placeName', Sort.desc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy> sortByStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.asc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy>
      sortByStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.desc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy>
      sortByTransport() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transport', Sort.asc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy>
      sortByTransportDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transport', Sort.desc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy>
      sortByTransportText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transportText', Sort.asc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy>
      sortByTransportTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transportText', Sort.desc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension TimelineEditLogQuerySortThenBy
    on QueryBuilder<TimelineEditLog, TimelineEditLog, QSortThenBy> {
  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy> thenByEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.asc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy> thenByEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.desc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy>
      thenByPlaceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'placeName', Sort.asc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy>
      thenByPlaceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'placeName', Sort.desc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy> thenByStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.asc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy>
      thenByStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.desc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy>
      thenByTransport() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transport', Sort.asc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy>
      thenByTransportDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transport', Sort.desc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy>
      thenByTransportText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transportText', Sort.asc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy>
      thenByTransportTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transportText', Sort.desc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension TimelineEditLogQueryWhereDistinct
    on QueryBuilder<TimelineEditLog, TimelineEditLog, QDistinct> {
  QueryBuilder<TimelineEditLog, TimelineEditLog, QDistinct> distinctByEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'end');
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QDistinct> distinctByPlaceName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'placeName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QDistinct> distinctByStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'start');
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QDistinct> distinctByTransport(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transport', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QDistinct>
      distinctByTransportText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transportText',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimelineEditLog, TimelineEditLog, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension TimelineEditLogQueryProperty
    on QueryBuilder<TimelineEditLog, TimelineEditLog, QQueryProperty> {
  QueryBuilder<TimelineEditLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TimelineEditLog, DateTime, QQueryOperations> endProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'end');
    });
  }

  QueryBuilder<TimelineEditLog, String?, QQueryOperations> placeNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'placeName');
    });
  }

  QueryBuilder<TimelineEditLog, DateTime, QQueryOperations> startProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'start');
    });
  }

  QueryBuilder<TimelineEditLog, String?, QQueryOperations> transportProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transport');
    });
  }

  QueryBuilder<TimelineEditLog, String?, QQueryOperations>
      transportTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transportText');
    });
  }

  QueryBuilder<TimelineEditLog, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}

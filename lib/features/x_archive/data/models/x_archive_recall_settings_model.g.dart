// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'x_archive_recall_settings_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetXArchiveRecallSettingsModelCollection on Isar {
  IsarCollection<XArchiveRecallSettingsModel>
      get xArchiveRecallSettingsModels => this.collection();
}

const XArchiveRecallSettingsModelSchema = CollectionSchema(
  name: r'XArchiveRecallSettingsModel',
  id: 4903602105198109914,
  properties: {
    r'enabled': PropertySchema(
      id: 0,
      name: r'enabled',
      type: IsarType.bool,
    ),
    r'hour': PropertySchema(
      id: 1,
      name: r'hour',
      type: IsarType.long,
    ),
    r'minute': PropertySchema(
      id: 2,
      name: r'minute',
      type: IsarType.long,
    )
  },
  estimateSize: _xArchiveRecallSettingsModelEstimateSize,
  serialize: _xArchiveRecallSettingsModelSerialize,
  deserialize: _xArchiveRecallSettingsModelDeserialize,
  deserializeProp: _xArchiveRecallSettingsModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _xArchiveRecallSettingsModelGetId,
  getLinks: _xArchiveRecallSettingsModelGetLinks,
  attach: _xArchiveRecallSettingsModelAttach,
  version: '3.1.0+1',
);

int _xArchiveRecallSettingsModelEstimateSize(
  XArchiveRecallSettingsModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _xArchiveRecallSettingsModelSerialize(
  XArchiveRecallSettingsModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.enabled);
  writer.writeLong(offsets[1], object.hour);
  writer.writeLong(offsets[2], object.minute);
}

XArchiveRecallSettingsModel _xArchiveRecallSettingsModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = XArchiveRecallSettingsModel();
  object.enabled = reader.readBool(offsets[0]);
  object.hour = reader.readLong(offsets[1]);
  object.id = id;
  object.minute = reader.readLong(offsets[2]);
  return object;
}

P _xArchiveRecallSettingsModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _xArchiveRecallSettingsModelGetId(XArchiveRecallSettingsModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _xArchiveRecallSettingsModelGetLinks(
    XArchiveRecallSettingsModel object) {
  return [];
}

void _xArchiveRecallSettingsModelAttach(
    IsarCollection<dynamic> col, Id id, XArchiveRecallSettingsModel object) {
  object.id = id;
}

extension XArchiveRecallSettingsModelQueryWhereSort on QueryBuilder<
    XArchiveRecallSettingsModel, XArchiveRecallSettingsModel, QWhere> {
  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension XArchiveRecallSettingsModelQueryWhere on QueryBuilder<
    XArchiveRecallSettingsModel, XArchiveRecallSettingsModel, QWhereClause> {
  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterWhereClause> idBetween(
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

extension XArchiveRecallSettingsModelQueryFilter on QueryBuilder<
    XArchiveRecallSettingsModel,
    XArchiveRecallSettingsModel,
    QFilterCondition> {
  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterFilterCondition> enabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enabled',
        value: value,
      ));
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterFilterCondition> hourEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hour',
        value: value,
      ));
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterFilterCondition> hourGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hour',
        value: value,
      ));
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterFilterCondition> hourLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hour',
        value: value,
      ));
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterFilterCondition> hourBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hour',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterFilterCondition> minuteEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minute',
        value: value,
      ));
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterFilterCondition> minuteGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minute',
        value: value,
      ));
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterFilterCondition> minuteLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minute',
        value: value,
      ));
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterFilterCondition> minuteBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minute',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension XArchiveRecallSettingsModelQueryObject on QueryBuilder<
    XArchiveRecallSettingsModel,
    XArchiveRecallSettingsModel,
    QFilterCondition> {}

extension XArchiveRecallSettingsModelQueryLinks on QueryBuilder<
    XArchiveRecallSettingsModel,
    XArchiveRecallSettingsModel,
    QFilterCondition> {}

extension XArchiveRecallSettingsModelQuerySortBy on QueryBuilder<
    XArchiveRecallSettingsModel, XArchiveRecallSettingsModel, QSortBy> {
  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterSortBy> sortByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterSortBy> sortByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterSortBy> sortByHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hour', Sort.asc);
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterSortBy> sortByHourDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hour', Sort.desc);
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterSortBy> sortByMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minute', Sort.asc);
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterSortBy> sortByMinuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minute', Sort.desc);
    });
  }
}

extension XArchiveRecallSettingsModelQuerySortThenBy on QueryBuilder<
    XArchiveRecallSettingsModel, XArchiveRecallSettingsModel, QSortThenBy> {
  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterSortBy> thenByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterSortBy> thenByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterSortBy> thenByHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hour', Sort.asc);
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterSortBy> thenByHourDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hour', Sort.desc);
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterSortBy> thenByMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minute', Sort.asc);
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QAfterSortBy> thenByMinuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minute', Sort.desc);
    });
  }
}

extension XArchiveRecallSettingsModelQueryWhereDistinct on QueryBuilder<
    XArchiveRecallSettingsModel, XArchiveRecallSettingsModel, QDistinct> {
  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QDistinct> distinctByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enabled');
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QDistinct> distinctByHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hour');
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, XArchiveRecallSettingsModel,
      QDistinct> distinctByMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minute');
    });
  }
}

extension XArchiveRecallSettingsModelQueryProperty on QueryBuilder<
    XArchiveRecallSettingsModel, XArchiveRecallSettingsModel, QQueryProperty> {
  QueryBuilder<XArchiveRecallSettingsModel, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, bool, QQueryOperations>
      enabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enabled');
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, int, QQueryOperations>
      hourProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hour');
    });
  }

  QueryBuilder<XArchiveRecallSettingsModel, int, QQueryOperations>
      minuteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minute');
    });
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'x_archive_post_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetXArchivePostModelCollection on Isar {
  IsarCollection<XArchivePostModel> get xArchivePostModels => this.collection();
}

const XArchivePostModelSchema = CollectionSchema(
  name: r'XArchivePostModel',
  id: 7089278264064490253,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'hasVideo': PropertySchema(
      id: 1,
      name: r'hasVideo',
      type: IsarType.bool,
    ),
    r'imageFileNames': PropertySchema(
      id: 2,
      name: r'imageFileNames',
      type: IsarType.stringList,
    ),
    r'kind': PropertySchema(
      id: 3,
      name: r'kind',
      type: IsarType.string,
    ),
    r'replyToScreenName': PropertySchema(
      id: 4,
      name: r'replyToScreenName',
      type: IsarType.string,
    ),
    r'text': PropertySchema(
      id: 5,
      name: r'text',
      type: IsarType.string,
    ),
    r'tweetId': PropertySchema(
      id: 6,
      name: r'tweetId',
      type: IsarType.string,
    )
  },
  estimateSize: _xArchivePostModelEstimateSize,
  serialize: _xArchivePostModelSerialize,
  deserialize: _xArchivePostModelDeserialize,
  deserializeProp: _xArchivePostModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'tweetId': IndexSchema(
      id: 9183465975972251062,
      name: r'tweetId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'tweetId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _xArchivePostModelGetId,
  getLinks: _xArchivePostModelGetLinks,
  attach: _xArchivePostModelAttach,
  version: '3.1.0+1',
);

int _xArchivePostModelEstimateSize(
  XArchivePostModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.imageFileNames.length * 3;
  {
    for (var i = 0; i < object.imageFileNames.length; i++) {
      final value = object.imageFileNames[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.kind.length * 3;
  {
    final value = object.replyToScreenName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.text.length * 3;
  bytesCount += 3 + object.tweetId.length * 3;
  return bytesCount;
}

void _xArchivePostModelSerialize(
  XArchivePostModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeBool(offsets[1], object.hasVideo);
  writer.writeStringList(offsets[2], object.imageFileNames);
  writer.writeString(offsets[3], object.kind);
  writer.writeString(offsets[4], object.replyToScreenName);
  writer.writeString(offsets[5], object.text);
  writer.writeString(offsets[6], object.tweetId);
}

XArchivePostModel _xArchivePostModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = XArchivePostModel();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.hasVideo = reader.readBool(offsets[1]);
  object.id = id;
  object.imageFileNames = reader.readStringList(offsets[2]) ?? [];
  object.kind = reader.readString(offsets[3]);
  object.replyToScreenName = reader.readStringOrNull(offsets[4]);
  object.text = reader.readString(offsets[5]);
  object.tweetId = reader.readString(offsets[6]);
  return object;
}

P _xArchivePostModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readStringList(offset) ?? []) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _xArchivePostModelGetId(XArchivePostModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _xArchivePostModelGetLinks(
    XArchivePostModel object) {
  return [];
}

void _xArchivePostModelAttach(
    IsarCollection<dynamic> col, Id id, XArchivePostModel object) {
  object.id = id;
}

extension XArchivePostModelQueryWhereSort
    on QueryBuilder<XArchivePostModel, XArchivePostModel, QWhere> {
  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterWhere>
      anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension XArchivePostModelQueryWhere
    on QueryBuilder<XArchivePostModel, XArchivePostModel, QWhereClause> {
  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterWhereClause>
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

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterWhereClause>
      tweetIdEqualTo(String tweetId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'tweetId',
        value: [tweetId],
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterWhereClause>
      tweetIdNotEqualTo(String tweetId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tweetId',
              lower: [],
              upper: [tweetId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tweetId',
              lower: [tweetId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tweetId',
              lower: [tweetId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tweetId',
              lower: [],
              upper: [tweetId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterWhereClause>
      createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAt',
        value: [createdAt],
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterWhereClause>
      createdAtNotEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterWhereClause>
      createdAtGreaterThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [createdAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterWhereClause>
      createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [],
        upper: [createdAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterWhereClause>
      createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [lowerCreatedAt],
        includeLower: includeLower,
        upper: [upperCreatedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension XArchivePostModelQueryFilter
    on QueryBuilder<XArchivePostModel, XArchivePostModel, QFilterCondition> {
  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      hasVideoEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasVideo',
        value: value,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
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

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
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

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
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

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      imageFileNamesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageFileNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      imageFileNamesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imageFileNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      imageFileNamesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imageFileNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      imageFileNamesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imageFileNames',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      imageFileNamesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imageFileNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      imageFileNamesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imageFileNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      imageFileNamesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imageFileNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      imageFileNamesElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imageFileNames',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      imageFileNamesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageFileNames',
        value: '',
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      imageFileNamesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imageFileNames',
        value: '',
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      imageFileNamesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'imageFileNames',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      imageFileNamesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'imageFileNames',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      imageFileNamesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'imageFileNames',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      imageFileNamesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'imageFileNames',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      imageFileNamesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'imageFileNames',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      imageFileNamesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'imageFileNames',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      kindEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      kindGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      kindLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      kindBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kind',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      kindStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      kindEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      kindContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      kindMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kind',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      kindIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kind',
        value: '',
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      kindIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kind',
        value: '',
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      replyToScreenNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'replyToScreenName',
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      replyToScreenNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'replyToScreenName',
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      replyToScreenNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'replyToScreenName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      replyToScreenNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'replyToScreenName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      replyToScreenNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'replyToScreenName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      replyToScreenNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'replyToScreenName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      replyToScreenNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'replyToScreenName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      replyToScreenNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'replyToScreenName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      replyToScreenNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'replyToScreenName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      replyToScreenNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'replyToScreenName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      replyToScreenNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'replyToScreenName',
        value: '',
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      replyToScreenNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'replyToScreenName',
        value: '',
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      textEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'text',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      textStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      textEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'text',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      tweetIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tweetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      tweetIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tweetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      tweetIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tweetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      tweetIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tweetId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      tweetIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tweetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      tweetIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tweetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      tweetIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tweetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      tweetIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tweetId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      tweetIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tweetId',
        value: '',
      ));
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterFilterCondition>
      tweetIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tweetId',
        value: '',
      ));
    });
  }
}

extension XArchivePostModelQueryObject
    on QueryBuilder<XArchivePostModel, XArchivePostModel, QFilterCondition> {}

extension XArchivePostModelQueryLinks
    on QueryBuilder<XArchivePostModel, XArchivePostModel, QFilterCondition> {}

extension XArchivePostModelQuerySortBy
    on QueryBuilder<XArchivePostModel, XArchivePostModel, QSortBy> {
  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      sortByHasVideo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasVideo', Sort.asc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      sortByHasVideoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasVideo', Sort.desc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      sortByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      sortByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      sortByReplyToScreenName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToScreenName', Sort.asc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      sortByReplyToScreenNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToScreenName', Sort.desc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      sortByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      sortByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      sortByTweetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tweetId', Sort.asc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      sortByTweetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tweetId', Sort.desc);
    });
  }
}

extension XArchivePostModelQuerySortThenBy
    on QueryBuilder<XArchivePostModel, XArchivePostModel, QSortThenBy> {
  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      thenByHasVideo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasVideo', Sort.asc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      thenByHasVideoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasVideo', Sort.desc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      thenByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      thenByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      thenByReplyToScreenName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToScreenName', Sort.asc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      thenByReplyToScreenNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToScreenName', Sort.desc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      thenByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      thenByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      thenByTweetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tweetId', Sort.asc);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QAfterSortBy>
      thenByTweetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tweetId', Sort.desc);
    });
  }
}

extension XArchivePostModelQueryWhereDistinct
    on QueryBuilder<XArchivePostModel, XArchivePostModel, QDistinct> {
  QueryBuilder<XArchivePostModel, XArchivePostModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QDistinct>
      distinctByHasVideo() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasVideo');
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QDistinct>
      distinctByImageFileNames() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageFileNames');
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QDistinct> distinctByKind(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kind', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QDistinct>
      distinctByReplyToScreenName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'replyToScreenName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QDistinct> distinctByText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'text', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<XArchivePostModel, XArchivePostModel, QDistinct>
      distinctByTweetId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tweetId', caseSensitive: caseSensitive);
    });
  }
}

extension XArchivePostModelQueryProperty
    on QueryBuilder<XArchivePostModel, XArchivePostModel, QQueryProperty> {
  QueryBuilder<XArchivePostModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<XArchivePostModel, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<XArchivePostModel, bool, QQueryOperations> hasVideoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasVideo');
    });
  }

  QueryBuilder<XArchivePostModel, List<String>, QQueryOperations>
      imageFileNamesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageFileNames');
    });
  }

  QueryBuilder<XArchivePostModel, String, QQueryOperations> kindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kind');
    });
  }

  QueryBuilder<XArchivePostModel, String?, QQueryOperations>
      replyToScreenNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'replyToScreenName');
    });
  }

  QueryBuilder<XArchivePostModel, String, QQueryOperations> textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'text');
    });
  }

  QueryBuilder<XArchivePostModel, String, QQueryOperations> tweetIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tweetId');
    });
  }
}

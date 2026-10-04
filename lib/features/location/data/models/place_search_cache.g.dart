// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_search_cache.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPlaceSearchCacheCollection on Isar {
  IsarCollection<PlaceSearchCache> get placeSearchCaches => this.collection();
}

const PlaceSearchCacheSchema = CollectionSchema(
  name: r'PlaceSearchCache',
  id: 2008436867258523881,
  properties: {
    r'candidatesJson': PropertySchema(
      id: 0,
      name: r'candidatesJson',
      type: IsarType.string,
    ),
    r'fetchedAt': PropertySchema(
      id: 1,
      name: r'fetchedAt',
      type: IsarType.dateTime,
    ),
    r'key': PropertySchema(
      id: 2,
      name: r'key',
      type: IsarType.string,
    )
  },
  estimateSize: _placeSearchCacheEstimateSize,
  serialize: _placeSearchCacheSerialize,
  deserialize: _placeSearchCacheDeserialize,
  deserializeProp: _placeSearchCacheDeserializeProp,
  idName: r'id',
  indexes: {
    r'key': IndexSchema(
      id: -4906094122524121629,
      name: r'key',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'key',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _placeSearchCacheGetId,
  getLinks: _placeSearchCacheGetLinks,
  attach: _placeSearchCacheAttach,
  version: '3.1.0+1',
);

int _placeSearchCacheEstimateSize(
  PlaceSearchCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.candidatesJson.length * 3;
  bytesCount += 3 + object.key.length * 3;
  return bytesCount;
}

void _placeSearchCacheSerialize(
  PlaceSearchCache object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.candidatesJson);
  writer.writeDateTime(offsets[1], object.fetchedAt);
  writer.writeString(offsets[2], object.key);
}

PlaceSearchCache _placeSearchCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PlaceSearchCache();
  object.candidatesJson = reader.readString(offsets[0]);
  object.fetchedAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.key = reader.readString(offsets[2]);
  return object;
}

P _placeSearchCacheDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _placeSearchCacheGetId(PlaceSearchCache object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _placeSearchCacheGetLinks(PlaceSearchCache object) {
  return [];
}

void _placeSearchCacheAttach(
    IsarCollection<dynamic> col, Id id, PlaceSearchCache object) {
  object.id = id;
}

extension PlaceSearchCacheQueryWhereSort
    on QueryBuilder<PlaceSearchCache, PlaceSearchCache, QWhere> {
  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PlaceSearchCacheQueryWhere
    on QueryBuilder<PlaceSearchCache, PlaceSearchCache, QWhereClause> {
  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterWhereClause>
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

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterWhereClause> idBetween(
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

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterWhereClause>
      keyEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'key',
        value: [key],
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterWhereClause>
      keyNotEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [],
              upper: [key],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [key],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [key],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [],
              upper: [key],
              includeUpper: false,
            ));
      }
    });
  }
}

extension PlaceSearchCacheQueryFilter
    on QueryBuilder<PlaceSearchCache, PlaceSearchCache, QFilterCondition> {
  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      candidatesJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'candidatesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      candidatesJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'candidatesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      candidatesJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'candidatesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      candidatesJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'candidatesJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      candidatesJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'candidatesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      candidatesJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'candidatesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      candidatesJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'candidatesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      candidatesJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'candidatesJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      candidatesJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'candidatesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      candidatesJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'candidatesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      fetchedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fetchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      fetchedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fetchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      fetchedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fetchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      fetchedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fetchedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
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

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
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

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
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

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      keyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      keyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'key',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      keyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      keyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      keyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      keyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'key',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterFilterCondition>
      keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'key',
        value: '',
      ));
    });
  }
}

extension PlaceSearchCacheQueryObject
    on QueryBuilder<PlaceSearchCache, PlaceSearchCache, QFilterCondition> {}

extension PlaceSearchCacheQueryLinks
    on QueryBuilder<PlaceSearchCache, PlaceSearchCache, QFilterCondition> {}

extension PlaceSearchCacheQuerySortBy
    on QueryBuilder<PlaceSearchCache, PlaceSearchCache, QSortBy> {
  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterSortBy>
      sortByCandidatesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'candidatesJson', Sort.asc);
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterSortBy>
      sortByCandidatesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'candidatesJson', Sort.desc);
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterSortBy>
      sortByFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.asc);
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterSortBy>
      sortByFetchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.desc);
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterSortBy>
      sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }
}

extension PlaceSearchCacheQuerySortThenBy
    on QueryBuilder<PlaceSearchCache, PlaceSearchCache, QSortThenBy> {
  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterSortBy>
      thenByCandidatesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'candidatesJson', Sort.asc);
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterSortBy>
      thenByCandidatesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'candidatesJson', Sort.desc);
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterSortBy>
      thenByFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.asc);
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterSortBy>
      thenByFetchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.desc);
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QAfterSortBy>
      thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }
}

extension PlaceSearchCacheQueryWhereDistinct
    on QueryBuilder<PlaceSearchCache, PlaceSearchCache, QDistinct> {
  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QDistinct>
      distinctByCandidatesJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'candidatesJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QDistinct>
      distinctByFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fetchedAt');
    });
  }

  QueryBuilder<PlaceSearchCache, PlaceSearchCache, QDistinct> distinctByKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }
}

extension PlaceSearchCacheQueryProperty
    on QueryBuilder<PlaceSearchCache, PlaceSearchCache, QQueryProperty> {
  QueryBuilder<PlaceSearchCache, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PlaceSearchCache, String, QQueryOperations>
      candidatesJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'candidatesJson');
    });
  }

  QueryBuilder<PlaceSearchCache, DateTime, QQueryOperations>
      fetchedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fetchedAt');
    });
  }

  QueryBuilder<PlaceSearchCache, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }
}

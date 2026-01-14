// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teach_settings.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTeachSettingsCollection on Isar {
  IsarCollection<TeachSettings> get teachSettings => this.collection();
}

const TeachSettingsSchema = CollectionSchema(
  name: r'TeachSettings',
  id: 5665591798987172254,
  properties: {
    r'apiKey': PropertySchema(
      id: 0,
      name: r'apiKey',
      type: IsarType.string,
    ),
    r'cloudEndpoint': PropertySchema(
      id: 1,
      name: r'cloudEndpoint',
      type: IsarType.string,
    ),
    r'cloudModel': PropertySchema(
      id: 2,
      name: r'cloudModel',
      type: IsarType.string,
    ),
    r'cloudProvider': PropertySchema(
      id: 3,
      name: r'cloudProvider',
      type: IsarType.string,
    ),
    r'useLocalLLM': PropertySchema(
      id: 4,
      name: r'useLocalLLM',
      type: IsarType.bool,
    )
  },
  estimateSize: _teachSettingsEstimateSize,
  serialize: _teachSettingsSerialize,
  deserialize: _teachSettingsDeserialize,
  deserializeProp: _teachSettingsDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _teachSettingsGetId,
  getLinks: _teachSettingsGetLinks,
  attach: _teachSettingsAttach,
  version: '3.1.0+1',
);

int _teachSettingsEstimateSize(
  TeachSettings object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.apiKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.cloudEndpoint.length * 3;
  bytesCount += 3 + object.cloudModel.length * 3;
  bytesCount += 3 + object.cloudProvider.length * 3;
  return bytesCount;
}

void _teachSettingsSerialize(
  TeachSettings object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.apiKey);
  writer.writeString(offsets[1], object.cloudEndpoint);
  writer.writeString(offsets[2], object.cloudModel);
  writer.writeString(offsets[3], object.cloudProvider);
  writer.writeBool(offsets[4], object.useLocalLLM);
}

TeachSettings _teachSettingsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TeachSettings();
  object.apiKey = reader.readStringOrNull(offsets[0]);
  object.cloudEndpoint = reader.readString(offsets[1]);
  object.cloudModel = reader.readString(offsets[2]);
  object.cloudProvider = reader.readString(offsets[3]);
  object.id = id;
  object.useLocalLLM = reader.readBool(offsets[4]);
  return object;
}

P _teachSettingsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _teachSettingsGetId(TeachSettings object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _teachSettingsGetLinks(TeachSettings object) {
  return [];
}

void _teachSettingsAttach(
    IsarCollection<dynamic> col, Id id, TeachSettings object) {
  object.id = id;
}

extension TeachSettingsQueryWhereSort
    on QueryBuilder<TeachSettings, TeachSettings, QWhere> {
  QueryBuilder<TeachSettings, TeachSettings, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TeachSettingsQueryWhere
    on QueryBuilder<TeachSettings, TeachSettings, QWhereClause> {
  QueryBuilder<TeachSettings, TeachSettings, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<TeachSettings, TeachSettings, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterWhereClause> idBetween(
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

extension TeachSettingsQueryFilter
    on QueryBuilder<TeachSettings, TeachSettings, QFilterCondition> {
  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      apiKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'apiKey',
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      apiKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'apiKey',
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      apiKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      apiKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      apiKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      apiKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'apiKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      apiKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      apiKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      apiKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      apiKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'apiKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      apiKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'apiKey',
        value: '',
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      apiKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'apiKey',
        value: '',
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudEndpointEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cloudEndpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudEndpointGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cloudEndpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudEndpointLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cloudEndpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudEndpointBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cloudEndpoint',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudEndpointStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cloudEndpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudEndpointEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cloudEndpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudEndpointContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cloudEndpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudEndpointMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cloudEndpoint',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudEndpointIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cloudEndpoint',
        value: '',
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudEndpointIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cloudEndpoint',
        value: '',
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudModelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cloudModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudModelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cloudModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudModelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cloudModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudModelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cloudModel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudModelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cloudModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudModelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cloudModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudModelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cloudModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudModelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cloudModel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudModelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cloudModel',
        value: '',
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudModelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cloudModel',
        value: '',
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudProviderEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cloudProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudProviderGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cloudProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudProviderLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cloudProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudProviderBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cloudProvider',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudProviderStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cloudProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudProviderEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cloudProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudProviderContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cloudProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudProviderMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cloudProvider',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudProviderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cloudProvider',
        value: '',
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      cloudProviderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cloudProvider',
        value: '',
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
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

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition> idBetween(
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

  QueryBuilder<TeachSettings, TeachSettings, QAfterFilterCondition>
      useLocalLLMEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'useLocalLLM',
        value: value,
      ));
    });
  }
}

extension TeachSettingsQueryObject
    on QueryBuilder<TeachSettings, TeachSettings, QFilterCondition> {}

extension TeachSettingsQueryLinks
    on QueryBuilder<TeachSettings, TeachSettings, QFilterCondition> {}

extension TeachSettingsQuerySortBy
    on QueryBuilder<TeachSettings, TeachSettings, QSortBy> {
  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy> sortByApiKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.asc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy> sortByApiKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.desc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy>
      sortByCloudEndpoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudEndpoint', Sort.asc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy>
      sortByCloudEndpointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudEndpoint', Sort.desc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy> sortByCloudModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudModel', Sort.asc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy>
      sortByCloudModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudModel', Sort.desc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy>
      sortByCloudProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudProvider', Sort.asc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy>
      sortByCloudProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudProvider', Sort.desc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy> sortByUseLocalLLM() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useLocalLLM', Sort.asc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy>
      sortByUseLocalLLMDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useLocalLLM', Sort.desc);
    });
  }
}

extension TeachSettingsQuerySortThenBy
    on QueryBuilder<TeachSettings, TeachSettings, QSortThenBy> {
  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy> thenByApiKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.asc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy> thenByApiKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.desc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy>
      thenByCloudEndpoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudEndpoint', Sort.asc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy>
      thenByCloudEndpointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudEndpoint', Sort.desc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy> thenByCloudModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudModel', Sort.asc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy>
      thenByCloudModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudModel', Sort.desc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy>
      thenByCloudProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudProvider', Sort.asc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy>
      thenByCloudProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudProvider', Sort.desc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy> thenByUseLocalLLM() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useLocalLLM', Sort.asc);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QAfterSortBy>
      thenByUseLocalLLMDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useLocalLLM', Sort.desc);
    });
  }
}

extension TeachSettingsQueryWhereDistinct
    on QueryBuilder<TeachSettings, TeachSettings, QDistinct> {
  QueryBuilder<TeachSettings, TeachSettings, QDistinct> distinctByApiKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'apiKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QDistinct> distinctByCloudEndpoint(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cloudEndpoint',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QDistinct> distinctByCloudModel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cloudModel', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QDistinct> distinctByCloudProvider(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cloudProvider',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TeachSettings, TeachSettings, QDistinct>
      distinctByUseLocalLLM() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'useLocalLLM');
    });
  }
}

extension TeachSettingsQueryProperty
    on QueryBuilder<TeachSettings, TeachSettings, QQueryProperty> {
  QueryBuilder<TeachSettings, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TeachSettings, String?, QQueryOperations> apiKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'apiKey');
    });
  }

  QueryBuilder<TeachSettings, String, QQueryOperations>
      cloudEndpointProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cloudEndpoint');
    });
  }

  QueryBuilder<TeachSettings, String, QQueryOperations> cloudModelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cloudModel');
    });
  }

  QueryBuilder<TeachSettings, String, QQueryOperations>
      cloudProviderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cloudProvider');
    });
  }

  QueryBuilder<TeachSettings, bool, QQueryOperations> useLocalLLMProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'useLocalLLM');
    });
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetQuizCollection on Isar {
  IsarCollection<Quiz> get quizs => this.collection();
}

const QuizSchema = CollectionSchema(
  name: r'Quiz',
  id: 3912563531471134748,
  properties: {
    r'countdown': PropertySchema(
      id: 0,
      name: r'countdown',
      type: IsarType.bool,
    ),
    r'description': PropertySchema(
      id: 1,
      name: r'description',
      type: IsarType.string,
    ),
    r'immediateFeedback': PropertySchema(
      id: 2,
      name: r'immediateFeedback',
      type: IsarType.bool,
    ),
    r'timeLimitSeconds': PropertySchema(
      id: 3,
      name: r'timeLimitSeconds',
      type: IsarType.long,
    ),
    r'title': PropertySchema(
      id: 4,
      name: r'title',
      type: IsarType.string,
    ),
    r'topicId': PropertySchema(
      id: 5,
      name: r'topicId',
      type: IsarType.long,
    )
  },
  estimateSize: _quizEstimateSize,
  serialize: _quizSerialize,
  deserialize: _quizDeserialize,
  deserializeProp: _quizDeserializeProp,
  idName: r'id',
  indexes: {
    r'topicId': IndexSchema(
      id: 3718206658163357569,
      name: r'topicId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'topicId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'title': IndexSchema(
      id: -7636685945352118059,
      name: r'title',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'title',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _quizGetId,
  getLinks: _quizGetLinks,
  attach: _quizAttach,
  version: '3.1.0+1',
);

int _quizEstimateSize(
  Quiz object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _quizSerialize(
  Quiz object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.countdown);
  writer.writeString(offsets[1], object.description);
  writer.writeBool(offsets[2], object.immediateFeedback);
  writer.writeLong(offsets[3], object.timeLimitSeconds);
  writer.writeString(offsets[4], object.title);
  writer.writeLong(offsets[5], object.topicId);
}

Quiz _quizDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Quiz();
  object.countdown = reader.readBool(offsets[0]);
  object.description = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.immediateFeedback = reader.readBool(offsets[2]);
  object.timeLimitSeconds = reader.readLong(offsets[3]);
  object.title = reader.readString(offsets[4]);
  object.topicId = reader.readLong(offsets[5]);
  return object;
}

P _quizDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _quizGetId(Quiz object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _quizGetLinks(Quiz object) {
  return [];
}

void _quizAttach(IsarCollection<dynamic> col, Id id, Quiz object) {
  object.id = id;
}

extension QuizQueryWhereSort on QueryBuilder<Quiz, Quiz, QWhere> {
  QueryBuilder<Quiz, Quiz, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterWhere> anyTopicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'topicId'),
      );
    });
  }
}

extension QuizQueryWhere on QueryBuilder<Quiz, Quiz, QWhereClause> {
  QueryBuilder<Quiz, Quiz, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Quiz, Quiz, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterWhereClause> idBetween(
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

  QueryBuilder<Quiz, Quiz, QAfterWhereClause> topicIdEqualTo(int topicId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'topicId',
        value: [topicId],
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterWhereClause> topicIdNotEqualTo(int topicId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'topicId',
              lower: [],
              upper: [topicId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'topicId',
              lower: [topicId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'topicId',
              lower: [topicId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'topicId',
              lower: [],
              upper: [topicId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterWhereClause> topicIdGreaterThan(
    int topicId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'topicId',
        lower: [topicId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterWhereClause> topicIdLessThan(
    int topicId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'topicId',
        lower: [],
        upper: [topicId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterWhereClause> topicIdBetween(
    int lowerTopicId,
    int upperTopicId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'topicId',
        lower: [lowerTopicId],
        includeLower: includeLower,
        upper: [upperTopicId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterWhereClause> titleEqualTo(String title) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'title',
        value: [title],
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterWhereClause> titleNotEqualTo(String title) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ));
      }
    });
  }
}

extension QuizQueryFilter on QueryBuilder<Quiz, Quiz, QFilterCondition> {
  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> countdownEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'countdown',
        value: value,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> descriptionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> descriptionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> immediateFeedbackEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'immediateFeedback',
        value: value,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> timeLimitSecondsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeLimitSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> timeLimitSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timeLimitSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> timeLimitSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timeLimitSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> timeLimitSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timeLimitSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> titleContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> titleMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> topicIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topicId',
        value: value,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> topicIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'topicId',
        value: value,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> topicIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'topicId',
        value: value,
      ));
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterFilterCondition> topicIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'topicId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension QuizQueryObject on QueryBuilder<Quiz, Quiz, QFilterCondition> {}

extension QuizQueryLinks on QueryBuilder<Quiz, Quiz, QFilterCondition> {}

extension QuizQuerySortBy on QueryBuilder<Quiz, Quiz, QSortBy> {
  QueryBuilder<Quiz, Quiz, QAfterSortBy> sortByCountdown() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'countdown', Sort.asc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> sortByCountdownDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'countdown', Sort.desc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> sortByImmediateFeedback() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'immediateFeedback', Sort.asc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> sortByImmediateFeedbackDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'immediateFeedback', Sort.desc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> sortByTimeLimitSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeLimitSeconds', Sort.asc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> sortByTimeLimitSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeLimitSeconds', Sort.desc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> sortByTopicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.asc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> sortByTopicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.desc);
    });
  }
}

extension QuizQuerySortThenBy on QueryBuilder<Quiz, Quiz, QSortThenBy> {
  QueryBuilder<Quiz, Quiz, QAfterSortBy> thenByCountdown() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'countdown', Sort.asc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> thenByCountdownDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'countdown', Sort.desc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> thenByImmediateFeedback() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'immediateFeedback', Sort.asc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> thenByImmediateFeedbackDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'immediateFeedback', Sort.desc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> thenByTimeLimitSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeLimitSeconds', Sort.asc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> thenByTimeLimitSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeLimitSeconds', Sort.desc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> thenByTopicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.asc);
    });
  }

  QueryBuilder<Quiz, Quiz, QAfterSortBy> thenByTopicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.desc);
    });
  }
}

extension QuizQueryWhereDistinct on QueryBuilder<Quiz, Quiz, QDistinct> {
  QueryBuilder<Quiz, Quiz, QDistinct> distinctByCountdown() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'countdown');
    });
  }

  QueryBuilder<Quiz, Quiz, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Quiz, Quiz, QDistinct> distinctByImmediateFeedback() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'immediateFeedback');
    });
  }

  QueryBuilder<Quiz, Quiz, QDistinct> distinctByTimeLimitSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timeLimitSeconds');
    });
  }

  QueryBuilder<Quiz, Quiz, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Quiz, Quiz, QDistinct> distinctByTopicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topicId');
    });
  }
}

extension QuizQueryProperty on QueryBuilder<Quiz, Quiz, QQueryProperty> {
  QueryBuilder<Quiz, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Quiz, bool, QQueryOperations> countdownProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'countdown');
    });
  }

  QueryBuilder<Quiz, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<Quiz, bool, QQueryOperations> immediateFeedbackProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'immediateFeedback');
    });
  }

  QueryBuilder<Quiz, int, QQueryOperations> timeLimitSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeLimitSeconds');
    });
  }

  QueryBuilder<Quiz, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<Quiz, int, QQueryOperations> topicIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topicId');
    });
  }
}

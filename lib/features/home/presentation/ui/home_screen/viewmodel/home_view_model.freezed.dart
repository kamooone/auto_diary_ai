// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$HomeUiModel {
  List<String> get months => throw _privateConstructorUsedError;
  Map<String, List<DiaryItem>> get filteredItemsPerMonth =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $HomeUiModelCopyWith<HomeUiModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeUiModelCopyWith<$Res> {
  factory $HomeUiModelCopyWith(
          HomeUiModel value, $Res Function(HomeUiModel) then) =
      _$HomeUiModelCopyWithImpl<$Res, HomeUiModel>;
  @useResult
  $Res call(
      {List<String> months,
      Map<String, List<DiaryItem>> filteredItemsPerMonth});
}

/// @nodoc
class _$HomeUiModelCopyWithImpl<$Res, $Val extends HomeUiModel>
    implements $HomeUiModelCopyWith<$Res> {
  _$HomeUiModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? months = null,
    Object? filteredItemsPerMonth = null,
  }) {
    return _then(_value.copyWith(
      months: null == months
          ? _value.months
          : months // ignore: cast_nullable_to_non_nullable
              as List<String>,
      filteredItemsPerMonth: null == filteredItemsPerMonth
          ? _value.filteredItemsPerMonth
          : filteredItemsPerMonth // ignore: cast_nullable_to_non_nullable
              as Map<String, List<DiaryItem>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HomeUiModelImplCopyWith<$Res>
    implements $HomeUiModelCopyWith<$Res> {
  factory _$$HomeUiModelImplCopyWith(
          _$HomeUiModelImpl value, $Res Function(_$HomeUiModelImpl) then) =
      __$$HomeUiModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<String> months,
      Map<String, List<DiaryItem>> filteredItemsPerMonth});
}

/// @nodoc
class __$$HomeUiModelImplCopyWithImpl<$Res>
    extends _$HomeUiModelCopyWithImpl<$Res, _$HomeUiModelImpl>
    implements _$$HomeUiModelImplCopyWith<$Res> {
  __$$HomeUiModelImplCopyWithImpl(
      _$HomeUiModelImpl _value, $Res Function(_$HomeUiModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? months = null,
    Object? filteredItemsPerMonth = null,
  }) {
    return _then(_$HomeUiModelImpl(
      months: null == months
          ? _value._months
          : months // ignore: cast_nullable_to_non_nullable
              as List<String>,
      filteredItemsPerMonth: null == filteredItemsPerMonth
          ? _value._filteredItemsPerMonth
          : filteredItemsPerMonth // ignore: cast_nullable_to_non_nullable
              as Map<String, List<DiaryItem>>,
    ));
  }
}

/// @nodoc

class _$HomeUiModelImpl implements _HomeUiModel {
  const _$HomeUiModelImpl(
      {required final List<String> months,
      required final Map<String, List<DiaryItem>> filteredItemsPerMonth})
      : _months = months,
        _filteredItemsPerMonth = filteredItemsPerMonth;

  final List<String> _months;
  @override
  List<String> get months {
    if (_months is EqualUnmodifiableListView) return _months;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_months);
  }

  final Map<String, List<DiaryItem>> _filteredItemsPerMonth;
  @override
  Map<String, List<DiaryItem>> get filteredItemsPerMonth {
    if (_filteredItemsPerMonth is EqualUnmodifiableMapView)
      return _filteredItemsPerMonth;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_filteredItemsPerMonth);
  }

  @override
  String toString() {
    return 'HomeUiModel(months: $months, filteredItemsPerMonth: $filteredItemsPerMonth)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HomeUiModelImpl &&
            const DeepCollectionEquality().equals(other._months, _months) &&
            const DeepCollectionEquality()
                .equals(other._filteredItemsPerMonth, _filteredItemsPerMonth));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_months),
      const DeepCollectionEquality().hash(_filteredItemsPerMonth));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HomeUiModelImplCopyWith<_$HomeUiModelImpl> get copyWith =>
      __$$HomeUiModelImplCopyWithImpl<_$HomeUiModelImpl>(this, _$identity);
}

abstract class _HomeUiModel implements HomeUiModel {
  const factory _HomeUiModel(
          {required final List<String> months,
          required final Map<String, List<DiaryItem>> filteredItemsPerMonth}) =
      _$HomeUiModelImpl;

  @override
  List<String> get months;
  @override
  Map<String, List<DiaryItem>> get filteredItemsPerMonth;
  @override
  @JsonKey(ignore: true)
  _$$HomeUiModelImplCopyWith<_$HomeUiModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

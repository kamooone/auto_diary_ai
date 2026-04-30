// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeUiModel {

 List<String> get months; Map<String, List<DiaryItem>> get filteredItemsPerMonth;
/// Create a copy of HomeUiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeUiModelCopyWith<HomeUiModel> get copyWith => _$HomeUiModelCopyWithImpl<HomeUiModel>(this as HomeUiModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeUiModel&&const DeepCollectionEquality().equals(other.months, months)&&const DeepCollectionEquality().equals(other.filteredItemsPerMonth, filteredItemsPerMonth));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(months),const DeepCollectionEquality().hash(filteredItemsPerMonth));

@override
String toString() {
  return 'HomeUiModel(months: $months, filteredItemsPerMonth: $filteredItemsPerMonth)';
}


}

/// @nodoc
abstract mixin class $HomeUiModelCopyWith<$Res>  {
  factory $HomeUiModelCopyWith(HomeUiModel value, $Res Function(HomeUiModel) _then) = _$HomeUiModelCopyWithImpl;
@useResult
$Res call({
 List<String> months, Map<String, List<DiaryItem>> filteredItemsPerMonth
});




}
/// @nodoc
class _$HomeUiModelCopyWithImpl<$Res>
    implements $HomeUiModelCopyWith<$Res> {
  _$HomeUiModelCopyWithImpl(this._self, this._then);

  final HomeUiModel _self;
  final $Res Function(HomeUiModel) _then;

/// Create a copy of HomeUiModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? months = null,Object? filteredItemsPerMonth = null,}) {
  return _then(_self.copyWith(
months: null == months ? _self.months : months // ignore: cast_nullable_to_non_nullable
as List<String>,filteredItemsPerMonth: null == filteredItemsPerMonth ? _self.filteredItemsPerMonth : filteredItemsPerMonth // ignore: cast_nullable_to_non_nullable
as Map<String, List<DiaryItem>>,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeUiModel].
extension HomeUiModelPatterns on HomeUiModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeUiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeUiModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeUiModel value)  $default,){
final _that = this;
switch (_that) {
case _HomeUiModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeUiModel value)?  $default,){
final _that = this;
switch (_that) {
case _HomeUiModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> months,  Map<String, List<DiaryItem>> filteredItemsPerMonth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeUiModel() when $default != null:
return $default(_that.months,_that.filteredItemsPerMonth);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> months,  Map<String, List<DiaryItem>> filteredItemsPerMonth)  $default,) {final _that = this;
switch (_that) {
case _HomeUiModel():
return $default(_that.months,_that.filteredItemsPerMonth);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> months,  Map<String, List<DiaryItem>> filteredItemsPerMonth)?  $default,) {final _that = this;
switch (_that) {
case _HomeUiModel() when $default != null:
return $default(_that.months,_that.filteredItemsPerMonth);case _:
  return null;

}
}

}

/// @nodoc


class _HomeUiModel implements HomeUiModel {
  const _HomeUiModel({required final  List<String> months, required final  Map<String, List<DiaryItem>> filteredItemsPerMonth}): _months = months,_filteredItemsPerMonth = filteredItemsPerMonth;
  

 final  List<String> _months;
@override List<String> get months {
  if (_months is EqualUnmodifiableListView) return _months;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_months);
}

 final  Map<String, List<DiaryItem>> _filteredItemsPerMonth;
@override Map<String, List<DiaryItem>> get filteredItemsPerMonth {
  if (_filteredItemsPerMonth is EqualUnmodifiableMapView) return _filteredItemsPerMonth;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_filteredItemsPerMonth);
}


/// Create a copy of HomeUiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeUiModelCopyWith<_HomeUiModel> get copyWith => __$HomeUiModelCopyWithImpl<_HomeUiModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeUiModel&&const DeepCollectionEquality().equals(other._months, _months)&&const DeepCollectionEquality().equals(other._filteredItemsPerMonth, _filteredItemsPerMonth));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_months),const DeepCollectionEquality().hash(_filteredItemsPerMonth));

@override
String toString() {
  return 'HomeUiModel(months: $months, filteredItemsPerMonth: $filteredItemsPerMonth)';
}


}

/// @nodoc
abstract mixin class _$HomeUiModelCopyWith<$Res> implements $HomeUiModelCopyWith<$Res> {
  factory _$HomeUiModelCopyWith(_HomeUiModel value, $Res Function(_HomeUiModel) _then) = __$HomeUiModelCopyWithImpl;
@override @useResult
$Res call({
 List<String> months, Map<String, List<DiaryItem>> filteredItemsPerMonth
});




}
/// @nodoc
class __$HomeUiModelCopyWithImpl<$Res>
    implements _$HomeUiModelCopyWith<$Res> {
  __$HomeUiModelCopyWithImpl(this._self, this._then);

  final _HomeUiModel _self;
  final $Res Function(_HomeUiModel) _then;

/// Create a copy of HomeUiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? months = null,Object? filteredItemsPerMonth = null,}) {
  return _then(_HomeUiModel(
months: null == months ? _self._months : months // ignore: cast_nullable_to_non_nullable
as List<String>,filteredItemsPerMonth: null == filteredItemsPerMonth ? _self._filteredItemsPerMonth : filteredItemsPerMonth // ignore: cast_nullable_to_non_nullable
as Map<String, List<DiaryItem>>,
  ));
}


}

// dart format on

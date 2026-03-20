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
mixin _$HomeState {

 List<String> get months; Map<String, List<DiaryItem>> get filteredItemsPerMonth;
/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeStateCopyWith<HomeState> get copyWith => _$HomeStateCopyWithImpl<HomeState>(this as HomeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeState&&const DeepCollectionEquality().equals(other.months, months)&&const DeepCollectionEquality().equals(other.filteredItemsPerMonth, filteredItemsPerMonth));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(months),const DeepCollectionEquality().hash(filteredItemsPerMonth));

@override
String toString() {
  return 'HomeState(months: $months, filteredItemsPerMonth: $filteredItemsPerMonth)';
}


}

/// @nodoc
abstract mixin class $HomeStateCopyWith<$Res>  {
  factory $HomeStateCopyWith(HomeState value, $Res Function(HomeState) _then) = _$HomeStateCopyWithImpl;
@useResult
$Res call({
 List<String> months, Map<String, List<DiaryItem>> filteredItemsPerMonth
});




}
/// @nodoc
class _$HomeStateCopyWithImpl<$Res>
    implements $HomeStateCopyWith<$Res> {
  _$HomeStateCopyWithImpl(this._self, this._then);

  final HomeState _self;
  final $Res Function(HomeState) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? months = null,Object? filteredItemsPerMonth = null,}) {
  return _then(_self.copyWith(
months: null == months ? _self.months : months // ignore: cast_nullable_to_non_nullable
as List<String>,filteredItemsPerMonth: null == filteredItemsPerMonth ? _self.filteredItemsPerMonth : filteredItemsPerMonth // ignore: cast_nullable_to_non_nullable
as Map<String, List<DiaryItem>>,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeState].
extension HomeStatePatterns on HomeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeState value)  $default,){
final _that = this;
switch (_that) {
case _HomeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeState value)?  $default,){
final _that = this;
switch (_that) {
case _HomeState() when $default != null:
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
case _HomeState() when $default != null:
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
case _HomeState():
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
case _HomeState() when $default != null:
return $default(_that.months,_that.filteredItemsPerMonth);case _:
  return null;

}
}

}

/// @nodoc


class _HomeState implements HomeState {
  const _HomeState({required final  List<String> months, required final  Map<String, List<DiaryItem>> filteredItemsPerMonth}): _months = months,_filteredItemsPerMonth = filteredItemsPerMonth;
  

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


/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeStateCopyWith<_HomeState> get copyWith => __$HomeStateCopyWithImpl<_HomeState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeState&&const DeepCollectionEquality().equals(other._months, _months)&&const DeepCollectionEquality().equals(other._filteredItemsPerMonth, _filteredItemsPerMonth));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_months),const DeepCollectionEquality().hash(_filteredItemsPerMonth));

@override
String toString() {
  return 'HomeState(months: $months, filteredItemsPerMonth: $filteredItemsPerMonth)';
}


}

/// @nodoc
abstract mixin class _$HomeStateCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory _$HomeStateCopyWith(_HomeState value, $Res Function(_HomeState) _then) = __$HomeStateCopyWithImpl;
@override @useResult
$Res call({
 List<String> months, Map<String, List<DiaryItem>> filteredItemsPerMonth
});




}
/// @nodoc
class __$HomeStateCopyWithImpl<$Res>
    implements _$HomeStateCopyWith<$Res> {
  __$HomeStateCopyWithImpl(this._self, this._then);

  final _HomeState _self;
  final $Res Function(_HomeState) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? months = null,Object? filteredItemsPerMonth = null,}) {
  return _then(_HomeState(
months: null == months ? _self._months : months // ignore: cast_nullable_to_non_nullable
as List<String>,filteredItemsPerMonth: null == filteredItemsPerMonth ? _self._filteredItemsPerMonth : filteredItemsPerMonth // ignore: cast_nullable_to_non_nullable
as Map<String, List<DiaryItem>>,
  ));
}


}

// dart format on

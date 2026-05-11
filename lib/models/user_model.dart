import '../core/database/app_database.dart';

class UserModel {
  final int    localId;
  final int    id;
  final String email;
  final String firstName;
  final String lastName;
  final String avatar;
  final String movieTaste;
  final int    savedMoviesCount;

  const UserModel({
    required this.localId,
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatar,
    this.movieTaste       = '',
    this.savedMoviesCount = 0,
  });

  String get fullName => '$firstName $lastName'.trim();

  // From Reqres API
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    localId:    0,
    id:         json['id']         as int,
    email:      json['email']      as String? ?? '',
    firstName:  json['first_name'] as String? ?? '',
    lastName:   json['last_name']  as String? ?? '',
    avatar:     json['avatar']     as String? ?? '',
    movieTaste: json['job']        as String? ?? '',
  );

  // From Drift generated UsersTableData ← proper type, not dynamic
  factory UserModel.fromDb(UsersTableData db, {int savedMoviesCount = 0}) => UserModel(
    localId:          db.id,
    id:               db.serverId ?? db.id,
    email:            db.email,
    firstName:        db.firstName,
    lastName:         db.lastName,
    avatar:           db.avatarUrl,
    movieTaste:       db.movieTaste,
    savedMoviesCount: savedMoviesCount,
  );

  UserModel copyWith({int? savedMoviesCount}) => UserModel(
    localId:          localId,
    id:               id,
    email:            email,
    firstName:        firstName,
    lastName:         lastName,
    avatar:           avatar,
    movieTaste:       movieTaste,
    savedMoviesCount: savedMoviesCount ?? this.savedMoviesCount,
  );
}

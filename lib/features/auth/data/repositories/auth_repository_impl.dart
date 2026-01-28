import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/auth_response_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final ApiClient apiClient;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.apiClient,
  });

  @override
  Future<Either<Failure, AuthResponseEntity>> login({
    required String email,
    required String password,
  }) async {
    debugPrint('📡 [AuthRepository] login() appelé - email: $email');
    
    final isConnected = await networkInfo.isConnected;
    debugPrint('📡 [AuthRepository] Connexion réseau: $isConnected');
    
    if (isConnected) {
      try {
        debugPrint('📡 [AuthRepository] Appel remoteDataSource.login()...');
        final remoteAuth = await remoteDataSource.login(
          email: email,
          password: password,
        );
        debugPrint('📡 [AuthRepository] Réponse reçue - token: ${remoteAuth.token.substring(0, 10)}...');
        
        await localDataSource.cacheToken(remoteAuth.token);
        await localDataSource.cacheUser(remoteAuth.user);
        debugPrint('📡 [AuthRepository] Token et user mis en cache');
        
        apiClient.setToken(remoteAuth.token);
        debugPrint('📡 [AuthRepository] Token défini dans ApiClient');

        return Right(remoteAuth.toEntity());
      } on ServerException catch (e) {
        debugPrint('❌ [AuthRepository] ServerException: ${e.message}');
        return Left(ServerFailure(e.message));
      } on UnauthorizedException catch (e) {
        debugPrint('❌ [AuthRepository] UnauthorizedException: ${e.message}');
        return Left(UnauthorizedFailure(e.message));
      } on ForbiddenException catch (e) {
        debugPrint('❌ [AuthRepository] ForbiddenException: ${e.message} (code: ${e.errorCode})');
        return Left(ForbiddenFailure(e.message, errorCode: e.errorCode));
      } on ValidationException catch (e) {
        debugPrint('❌ [AuthRepository] ValidationException: ${e.errors}');
        return Left(ValidationFailure(e.errors));
      } catch (e, stackTrace) {
        debugPrint('💥 [AuthRepository] Exception inattendue: $e');
        debugPrint('💥 [AuthRepository] StackTrace: $stackTrace');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      debugPrint('❌ [AuthRepository] Pas de connexion réseau');
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, AuthResponseEntity>> register({
    required String name,
    required String pName,
    required String email,
    required String phone,
    required String password,
    required String licenseNumber,
    required String city,
    required String address,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteAuth = await remoteDataSource.register(
          name: name,
          pName: pName,
          email: email,
          phone: phone,
          password: password,
          licenseNumber: licenseNumber,
          city: city,
          address: address,
        );

        // NE PAS stocker le token après inscription
        // Le compte doit être approuvé par l'admin avant la connexion
        // await localDataSource.cacheToken(remoteAuth.token);
        // await localDataSource.cacheUser(remoteAuth.user);
        // apiClient.setToken(remoteAuth.token);

        return Right(remoteAuth.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on ValidationException catch (e) {
        return Left(ValidationFailure(e.errors));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getToken();
        if (token != null) {
          await remoteDataSource.logout(token);
        }
        await localDataSource.clearAuthData();
        apiClient.clearToken();
        return const Right(null);
      } catch (e) {
        // Even if logout fails on server, clear local data
        await localDataSource.clearAuthData();
        apiClient.clearToken();
        return const Right(null);
      }
    } else {
      // Offline logout - just clear local data
      await localDataSource.clearAuthData();
      apiClient.clearToken();
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    debugPrint('👤 [AuthRepository] getCurrentUser() appelé');
    try {
      final token = await localDataSource.getToken();
      debugPrint('👤 [AuthRepository] Token local: ${token != null ? "${token.substring(0, 10)}..." : "null"}');
      
      if (token != null) {
        apiClient.setToken(token);
      }

      final localUser = await localDataSource.getUser();
      debugPrint('👤 [AuthRepository] User local: ${localUser?.email ?? "null"}');
      
      if (localUser != null) {
        debugPrint('👤 [AuthRepository] Retour user depuis cache local');
        return Right(localUser.toEntity());
      }
      
      // If no local user but has token, try fetch from remote
      if (token != null) {
        debugPrint('👤 [AuthRepository] Pas de user local, tentative fetch remote...');
        if (await networkInfo.isConnected) {
          try {
            final remoteUser = await remoteDataSource.getCurrentUser(token);
            await localDataSource.cacheUser(remoteUser);
            debugPrint('👤 [AuthRepository] User récupéré du serveur: ${remoteUser.email}');
            return Right(remoteUser.toEntity());
          } catch (e) {
            debugPrint('❌ [AuthRepository] Échec fetch user remote: $e');
             return Left(ServerFailure('Failed to fetch user profile'));
          }
        }
      }

      debugPrint('👤 [AuthRepository] Pas d\'utilisateur connecté');
      return Left(CacheFailure('No user logged in'));
    } catch (e) {
      debugPrint('💥 [AuthRepository] Exception getCurrentUser: $e');
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkAuthStatus() async {
    try {
      final hasToken = await localDataSource.hasToken();
      
      if (!hasToken) {
        return const Right(false);
      }

      // Optional: Verify token validity with server if online
      if (await networkInfo.isConnected) {
         try {
           final token = await localDataSource.getToken();
           if(token != null){
              await remoteDataSource.getCurrentUser(token);
              return const Right(true);
           }
         } catch(e) {
           // Token invalid
           await localDataSource.clearAuthData();
           return const Right(false);
         }
      }

      return const Right(true);
    } catch (e) {
      return const Right(false);
    }
  }
}

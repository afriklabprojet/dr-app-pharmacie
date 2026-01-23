import 'package:dartz/dartz.dart';
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
    if (await networkInfo.isConnected) {
      try {
        final remoteAuth = await remoteDataSource.login(
          email: email,
          password: password,
        );
        
        await localDataSource.cacheToken(remoteAuth.token);
        await localDataSource.cacheUser(remoteAuth.user);
        
        apiClient.setToken(remoteAuth.token);

        return Right(remoteAuth.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on UnauthorizedException catch (e) {
        return Left(UnauthorizedFailure(e.message));
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

        await localDataSource.cacheToken(remoteAuth.token);
        await localDataSource.cacheUser(remoteAuth.user);
        
        apiClient.setToken(remoteAuth.token);

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
    try {
      final token = await localDataSource.getToken();
      if (token != null) {
        apiClient.setToken(token);
      }

      final localUser = await localDataSource.getUser();
      if (localUser != null) {
        return Right(localUser.toEntity());
      }
      
      // If no local user but has token, try fetch from remote
      if (token != null) {
        if (await networkInfo.isConnected) {
          try {
            final remoteUser = await remoteDataSource.getCurrentUser(token);
            await localDataSource.cacheUser(remoteUser);
            return Right(remoteUser.toEntity());
          } catch (e) {
             return Left(ServerFailure('Failed to fetch user profile'));
          }
        }
      }

      return Left(CacheFailure('No user logged in'));
    } catch (e) {
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

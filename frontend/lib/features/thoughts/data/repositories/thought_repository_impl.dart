import 'package:chronicle/features/thoughts/domain/models/thought.dart';
import 'package:chronicle/features/thoughts/domain/repositories/thought_repository.dart';
import 'package:chronicle/features/thoughts/data/datasources/thought_remote_datasource.dart';

class ThoughtRepositoryImpl implements ThoughtRepository {
  final ThoughtRemoteDatasource _datasource;

  ThoughtRepositoryImpl(this._datasource);

  @override
  Future<List<Thought>> getThoughts() => _datasource.getThoughts();

  @override
  Future<void> createThought(String content, String? tags) => _datasource.createThought(content, tags);

  @override
  Future<void> updateThought(String id, String content, String? tags) => _datasource.updateThought(id, content, tags);

  @override
  Future<void> deleteThought(String id) => _datasource.deleteThought(id);

  @override
  Future<void> toggleFavorite(String id, bool currentStatus) => _datasource.toggleFavorite(id, currentStatus);
}

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';

class CredentialManager {
  // Singleton pattern
  static final CredentialManager _instance = CredentialManager._internal();
  factory CredentialManager() => _instance;
  CredentialManager._internal();
  
  // This flag tracks if we need to recreate the database
  bool _needsDatabaseRecreation = false;

  // Check if database exists and is valid
  Future<bool> _checkDatabaseValidity() async {
    try {
      var databasesPath = await getDatabasesPath();
      String path = join(databasesPath, 'profile.db');
      bool exists = await databaseExists(path);
      
      if (!exists) {
        return false; // Database doesn't exist yet
      }
      
      // Try opening the database to check if it's valid
      Database db = await openDatabase(path, readOnly: true);
      await db.query('sqlite_master', limit: 1); // Simple query to test connection
      await db.close();
      return true;
    } catch (e) {
      print('Database validity check failed: $e');
      _needsDatabaseRecreation = true;
      return false;
    }
  }
  
  // Initialize database
  Future<Database> _initDatabase() async {
    // Initialize for desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'profile.db');
    
    // Check database validity before proceeding
    await _checkDatabaseValidity();
    
    // If we need to recreate the database (first run or after an error)
    if (_needsDatabaseRecreation) {
      try {
        // Delete existing database if it exists
        await deleteDatabase(path);
        _needsDatabaseRecreation = false;
      } catch (e) {
        print('Error during database recreation: $e');
      }
    }

    // Open the database and create table if needed
    return await openDatabase(path, version: 3,
      onCreate: (Database db, int version) async {
        await db.execute(
          '''CREATE TABLE if not exists Profile (
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          name TEXT, 
          student_ID TEXT NOT NULL, 
          password TEXT NOT NULL,
          error INTEGER NOT NULL DEFAULT 0)''');
          
        await db.execute(
          '''CREATE TABLE if not exists UserSettings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          credential_id INTEGER NOT NULL,
          is_selected INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (credential_id) REFERENCES Profile(id) ON DELETE CASCADE
          )''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // Add UserSettings table if upgrading from version 1
        if (oldVersion < 2) {
          await db.execute(
            '''CREATE TABLE if not exists UserSettings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            credential_id INTEGER NOT NULL,
            is_selected INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (credential_id) REFERENCES Profile(id) ON DELETE CASCADE
            )''');
        }
        
        // Add error column to Profile table if upgrading from version 2 or earlier
        if (oldVersion < 3) {
          try {
            // Check if the error column already exists to avoid errors
            var columnInfo = await db.rawQuery('PRAGMA table_info(Profile)');
            bool errorColumnExists = columnInfo.any((col) => col['name'] == 'error');
            
            if (!errorColumnExists) {
              await db.execute('ALTER TABLE Profile ADD COLUMN error INTEGER NOT NULL DEFAULT 0');
            }
          } catch (e) {
            print('Error adding error column: $e');
            // Only set recreation flag on specific errors that require recreation
            if (e.toString().contains('duplicate column')) {
              print('Column already exists, skipping...');
            } else {
              _needsDatabaseRecreation = true;
            }
          }
        }
      }
    );
  }

  // Save credentials to database
  Future<int> saveCredentials(String name, String studentId, String password, {bool hasError = false}) async {
    final db = await _initDatabase();
    
    int id = await db.transaction((txn) async {
      return await txn.rawInsert(
        '''
        INSERT INTO Profile(name, student_ID, password, error)
        VALUES(?, ?, ?, ?)
        ''',
        [name, studentId, password, hasError ? 1 : 0]
      );
    });
    
    // Create a backup after adding new credentials
    _autoBackup();
    
    return id;
  }

  // Get all credentials from database
  Future<List<Map<String, dynamic>>> getAllCredentials() async {
    final db = await _initDatabase();
    return await db.query('Profile');
  }

  // Get credential by student ID
  Future<Map<String, dynamic>?> getCredentialByStudentId(String studentId) async {
    final db = await _initDatabase();
    List<Map<String, dynamic>> results = await db.query(
      'Profile', 
      where: 'student_ID = ?', 
      whereArgs: [studentId]
    );
    
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // Check if credentials are valid for login
  Future<bool> validateCredentials(String studentId, String password) async {
    final db = await _initDatabase();
    List<Map<String, dynamic>> results = await db.query(
      'Profile', 
      where: 'student_ID = ? AND password = ?', 
      whereArgs: [studentId, password]
    );
    
    return results.isNotEmpty;
  }

  // Delete credential by ID
  Future<int> deleteCredential(int id) async {
    final db = await _initDatabase();
    
    int result = await db.delete(
      'Profile', 
      where: 'id = ?', 
      whereArgs: [id]
    );
    
    // Create a backup after deleting a credential
    _autoBackup();
    
    return result;
  }

  // Update credential
  Future<int> updateCredential(int id, String name, String studentId, String password, {bool? hasError}) async {
    final db = await _initDatabase();
    
    Map<String, dynamic> updateData = {
      'name': name,
      'student_ID': studentId,
      'password': password,
    };
    
    // Only include error field if it's explicitly provided
    if (hasError != null) {
      updateData['error'] = hasError ? 1 : 0;
    }
    
    return await db.update(
      'Profile',
      updateData,
      where: 'id = ?',
      whereArgs: [id]
    );
  }
  
  // Get or create a user setting
  Future<bool> getSettingStatus(int credentialId) async {
    final db = await _initDatabase();
    List<Map<String, dynamic>> results = await db.query(
      'UserSettings',
      where: 'credential_id = ?',
      whereArgs: [credentialId]
    );
    
    // If no setting exists, create one with default value (not selected)
    if (results.isEmpty) {
      await db.insert('UserSettings', {
        'credential_id': credentialId,
        'is_selected': 0
      });
      return false;
    }
    
    return results.first['is_selected'] == 1;
  }
  
  // Update error status for a credential
  Future<int> updateErrorStatus(int credentialId, bool hasError) async {
    final db = await _initDatabase();
    return await db.update(
      'Profile',
      {'error': hasError ? 1 : 0},
      where: 'id = ?',
      whereArgs: [credentialId]
    );
  }
  
  // Update user setting
  Future<int> updateSettingStatus(int credentialId, bool isSelected) async {
    final db = await _initDatabase();
    
    // Check if setting exists
    List<Map<String, dynamic>> results = await db.query(
      'UserSettings',
      where: 'credential_id = ?',
      whereArgs: [credentialId]
    );
    
    if (results.isEmpty) {
      // Create new setting
      return await db.insert('UserSettings', {
        'credential_id': credentialId,
        'is_selected': isSelected ? 1 : 0
      });
    } else {
      // Update existing setting
      return await db.update(
        'UserSettings',
        {'is_selected': isSelected ? 1 : 0},
        where: 'credential_id = ?',
        whereArgs: [credentialId]
      );
    }
  }
  
  // Get all credentials with their settings
  Future<List<Map<String, dynamic>>> getCredentialsWithSettings() async {
    final db = await _initDatabase();
    
    try {
      // Check if UserSettings table exists
      bool tableExists = false;
      var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='UserSettings'");
      tableExists = tables.isNotEmpty;
      
      if (!tableExists) {
        // Create the UserSettings table if it doesn't exist
        await db.execute(
          '''CREATE TABLE if not exists UserSettings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          credential_id INTEGER NOT NULL,
          is_selected INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (credential_id) REFERENCES Profile(id) ON DELETE CASCADE
          )''');
      }
      
      // Now we can safely query with the join
      return await db.rawQuery('''
        SELECT p.id, p.name, p.student_ID, p.password, p.error,
               COALESCE(us.is_selected, 0) as is_selected
        FROM Profile p
        LEFT JOIN UserSettings us ON p.id = us.credential_id
      ''');
    } catch (e) {
      // If there's an error, fall back to just returning the profiles without settings
      print('Error getting credentials with settings: $e');
      
      // Only recreate database for serious corruption errors
      if (e.toString().contains('no such table') || 
          e.toString().contains('database disk image is malformed')) {
        _needsDatabaseRecreation = true;
      }
      
      try {
        // Just return profiles without settings info
        var profiles = await db.query('Profile');
        return profiles.map((profile) => {
          ...profile,
          'is_selected': 0,
          'error': profile['error'] ?? 0
        }).toList();
      } catch (profileError) {
        // If we can't even query profiles, database is likely corrupted
        print('Error querying profiles: $profileError');
        _needsDatabaseRecreation = true;
        return [];
      }
    }
  }
  
  // Get only selected credentials for attendance marking
  Future<List<Map<String, dynamic>>> getSelectedCredentials() async {
    final db = await _initDatabase();
    
    try {
      // Check if UserSettings table exists
      bool tableExists = false;
      var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='UserSettings'");
      tableExists = tables.isNotEmpty;
      
      if (!tableExists) {
        return []; // No selected credentials if table doesn't exist
      }
      
      // Query only selected credentials that don't have errors
      return await db.rawQuery('''
        SELECT p.id, p.name, p.student_ID, p.password, p.error
        FROM Profile p
        JOIN UserSettings us ON p.id = us.credential_id
        WHERE us.is_selected = 1
      ''');
    } catch (e) {
      print('Error getting selected credentials: $e');
      return []; // Return empty list on error
    }
  }
  
  // Update profile error status and store error message in a separate table
  Future<void> updateProfileError(int id, int errorStatus, String errorMessage) async {
    final db = await _initDatabase();
    
    // Start a transaction to ensure both operations succeed or fail together
    await db.transaction((txn) async {
      // First update the error status in Profile table
      await txn.update(
        'Profile',
        {'error': errorStatus},
        where: 'id = ?',
        whereArgs: [id]
      );
      
      // Check if ErrorMessages table exists, create if not
      var tables = await txn.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='ErrorMessages'");
      if (tables.isEmpty) {
        await txn.execute('''
          CREATE TABLE ErrorMessages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER NOT NULL,
            error_message TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            FOREIGN KEY (profile_id) REFERENCES Profile(id) ON DELETE CASCADE
          )
        ''');
      }
      
      // Then add the error message to ErrorMessages table with current timestamp
      await txn.insert(
        'ErrorMessages',
        {
          'profile_id': id,
          'error_message': errorMessage,
          'timestamp': DateTime.now().toIso8601String()
        }
      );
    });
  }
  
  // Get error messages for a profile
  Future<List<Map<String, dynamic>>> getErrorMessages(int profileId) async {
    final db = await _initDatabase();
    
    // Check if table exists first
    var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='ErrorMessages'");
    if (tables.isEmpty) {
      return [];
    }
    
    return await db.query(
      'ErrorMessages',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'timestamp DESC'
    );
  }
  
  // Backup database to a file
  Future<String?> backupDatabase() async {
    try {
      var databasesPath = await getDatabasesPath();
      String dbPath = join(databasesPath, 'profile.db');
      
      if (!await databaseExists(dbPath)) {
        return null; // No database to backup
      }
      
      // Create backup with timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '_').replaceAll('.', '_');
      String backupPath = join(databasesPath, 'profile_backup_$timestamp.db');
      
      // Read original database as bytes
      File dbFile = File(dbPath);
      List<int> bytes = await dbFile.readAsBytes();
      
      // Write bytes to backup location
      File backupFile = File(backupPath);
      await backupFile.writeAsBytes(bytes);
      
      print('Database backed up to: $backupPath');
      return backupPath;
    } catch (e) {
      print('Error backing up database: $e');
      return null;
    }
  }
  
  // Restore database from most recent backup
  Future<bool> restoreFromBackup() async {
    try {
      var databasesPath = await getDatabasesPath();
      
      // Find all backup files
      Directory directory = Directory(databasesPath);
      List<FileSystemEntity> files = await directory.list().toList();
      List<File> backupFiles = files
          .whereType<File>()
          .where((file) => file.path.contains('profile_backup_'))
          .toList();
      
      if (backupFiles.isEmpty) {
        return false; // No backups found
      }
      
      // Sort by modification time, most recent first
      backupFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      // Use the most recent backup
      File mostRecentBackup = backupFiles.first;
      
      // Close any open database connections
      String dbPath = join(databasesPath, 'profile.db');
      await deleteDatabase(dbPath);
      
      // Copy backup to main database path
      List<int> bytes = await mostRecentBackup.readAsBytes();
      File dbFile = File(dbPath);
      await dbFile.writeAsBytes(bytes);
      
      print('Database restored from: ${mostRecentBackup.path}');
      return true;
    } catch (e) {
      print('Error restoring database from backup: $e');
      return false;
    }
  }
  
  // Automatically create a backup of the database
  Future<void> _autoBackup() async {
    try {
      // Only keep a maximum of 5 backups to prevent filling up storage
      var databasesPath = await getDatabasesPath();
      Directory directory = Directory(databasesPath);
      List<FileSystemEntity> files = await directory.list().toList();
      List<File> backupFiles = files
          .whereType<File>()
          .where((file) => file.path.contains('profile_backup_'))
          .toList();
      
      // Sort by modification time, oldest first
      backupFiles.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      
      // Delete oldest backups if we have more than 5
      while (backupFiles.length >= 5) {
        await backupFiles.first.delete();
        backupFiles.removeAt(0);
      }
      
      // Create a new backup
      await backupDatabase();
    } catch (e) {
      print('Auto backup failed: $e');
      // Do not throw - this is a background operation that should not affect the main flow
    }
  }
  
  // Check database integrity
  Future<Map<String, dynamic>> checkDatabaseIntegrity() async {
    try {
      final db = await _initDatabase();
      
      // Run PRAGMA integrity_check to ensure database is not corrupted
      List<Map<String, dynamic>> integrityResult = await db.rawQuery('PRAGMA integrity_check');
      bool isIntegrityOk = integrityResult.first.values.first == 'ok';
      
      // Check for all tables
      List<Map<String, dynamic>> tableList = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      List<String> tables = tableList.map((table) => table['name'].toString()).toList();
      
      // Check record counts
      Map<String, int> recordCounts = {};
      for (String table in tables) {
        if (table.startsWith('sqlite_') || table.startsWith('android_')) continue;
        List<Map<String, dynamic>> countResult = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
        recordCounts[table] = countResult.first['count'] as int;
      }
      
      return {
        'integrity_ok': isIntegrityOk,
        'tables': tables,
        'record_counts': recordCounts,
        'database_exists': true,
      };
    } catch (e) {
      print('Database integrity check failed: $e');
      return {
        'integrity_ok': false,
        'error': e.toString(),
        'database_exists': await databaseExists(join(await getDatabasesPath(), 'profile.db')),
      };
    }
  }
  
  // Force recreation of database (for admin use only)
  Future<bool> forceRecreateDatabase() async {
    try {
      // Backup first
      await backupDatabase();
      
      // Set flag to recreate
      _needsDatabaseRecreation = true;
      
      // Initialize will recreate the database
      await _initDatabase();
      
      return true;
    } catch (e) {
      print('Force database recreation failed: $e');
      return false;
    }
  }
}

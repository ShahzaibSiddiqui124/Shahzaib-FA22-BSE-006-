import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService().init();

  runApp(
    MaterialApp(
      scaffoldMessengerKey: NotificationService().scaffoldMessengerKey,
      home: ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: TaskManagerApp(),
      ),
    ),
  );
}


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<bool> _requestExactAlarmPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.scheduleExactAlarm.status;
      if (!status.isGranted) {
        final result = await Permission.scheduleExactAlarm.request();
        return result.isGranted;
      }
      return true;
    }
    return true;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      final hasPermission = await _requestExactAlarmPermission();

      if (!hasPermission) {
        _showPermissionError();
        return;
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel',
            'Task Notifications',
            channelDescription: 'Channel for task reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        _showPermissionError();
      } else {
        _showError(e.message ?? 'Unknown error occurred');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showPermissionError() {
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Please enable exact alarms in app settings'),
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Notification error: $message'),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}

class TaskManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.light(
          primary: Colors.deepPurple,
          secondary: Colors.amber,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.deepPurple,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.amber,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.deepPurpleAccent,
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: HomeScreen(),
    );
  }
}

class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;
  final bool isRepeated;
  final List<int> repeatDays;
  final TimeOfDay notificationTime;
  final List<Subtask> subtasks;

  Task({
    this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.isCompleted = false,
    this.isRepeated = false,
    this.repeatDays = const [],
    this.notificationTime = const TimeOfDay(hour: 9, minute: 0),
    this.subtasks = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'isRepeated': isRepeated ? 1 : 0,
      'repeatDays': repeatDays.join(','),
      'notificationTime': '${notificationTime.hour}:${notificationTime.minute}',
    };
  }

  static Task fromMap(Map<String, dynamic> map) {
    final timeParts = (map['notificationTime'] ?? '9:0').toString().split(':');
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.parse(map['dueDate']),
      isCompleted: map['isCompleted'] == 1,
      isRepeated: map['isRepeated'] == 1,
      repeatDays: (map['repeatDays']?.toString().split(',') ?? [])
          .map((e) => int.tryParse(e) ?? 0)
          .toList(),
      notificationTime: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
    );
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    bool? isRepeated,
    List<int>? repeatDays,
    TimeOfDay? notificationTime,
    List<Subtask>? subtasks,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isRepeated: isRepeated ?? this.isRepeated,
      repeatDays: repeatDays ?? this.repeatDays,
      notificationTime: notificationTime ?? this.notificationTime,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  double get progress {
    if (subtasks.isEmpty) return isCompleted ? 1.0 : 0.0;
    final completed = subtasks.where((s) => s.isCompleted).length;
    return completed / subtasks.length;
  }
}

class Subtask {
  final int? id;
  final String title;
  final bool isCompleted;
  final int taskId;

  Subtask({
    this.id,
    required this.title,
    this.isCompleted = false,
    required this.taskId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'taskId': taskId,
    };
  }

  static Subtask fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'],
      title: map['title'],
      isCompleted: map['isCompleted'] == 1,
      taskId: map['taskId'],
    );
  }

  Subtask copyWith({
    int? id,
    String? title,
    bool? isCompleted,
    int? taskId,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      taskId: taskId ?? this.taskId,
    );
  }
}

class TaskDatabase {
  static final TaskDatabase instance = TaskDatabase._init();
  static Database? _database;

  TaskDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        dueDate TEXT,
        isCompleted INTEGER,
        isRepeated INTEGER,
        repeatDays TEXT,
        notificationTime TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE subtasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        isCompleted INTEGER,
        taskId INTEGER,
        FOREIGN KEY(taskId) REFERENCES tasks(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<Task> createTask(Task task) async {
    final db = await instance.database;
    final id = await db.insert('tasks', task.toMap());
    for (var subtask in task.subtasks) {
      await db.insert('subtasks', subtask.copyWith(taskId: id).toMap());
    }
    return task.copyWith(id: id);
  }

  Future<List<Task>> readAllTasks() async {
    final db = await instance.database;
    final taskMaps = await db.query('tasks');
    final tasks = <Task>[];

    for (var taskMap in taskMaps) {
      final task = Task.fromMap(taskMap);
      final subtasks = await readSubtasksForTask(task.id!);
      tasks.add(task.copyWith(subtasks: subtasks));
    }

    return tasks;
  }

  Future<List<Task>> readTodayTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final allTasks = await readAllTasks();
    return allTasks.where((task) {
      if (task.isCompleted) return false;
      final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      return taskDate.isAfter(today.subtract(const Duration(days: 1))) &&
          taskDate.isBefore(tomorrow);
    }).toList();
  }

  Future<List<Task>> readCompletedTasks() async {
    final allTasks = await readAllTasks();
    return allTasks.where((task) => task.isCompleted).toList();
  }

  Future<List<Task>> readRepeatedTasks() async {
    final allTasks = await readAllTasks();
    return allTasks.where((task) => task.isRepeated).toList();
  }

  Future<List<Subtask>> readSubtasksForTask(int taskId) async {
    final db = await instance.database;
    final subtaskMaps = await db.query(
      'subtasks',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
    return subtaskMaps.map((map) => Subtask.fromMap(map)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    await db.delete('subtasks', where: 'taskId = ?', whereArgs: [task.id]);
    for (var subtask in task.subtasks) {
      await db.insert('subtasks', subtask.copyWith(taskId: task.id).toMap());
    }
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    await db.delete('subtasks', where: 'taskId = ?', whereArgs: [id]);
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late Future<List<Task>> _tasksFuture;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  void _refreshTasks() {
    setState(() {
      if (_selectedIndex == 0) {
        _tasksFuture = TaskDatabase.instance.readTodayTasks();
      } else if (_selectedIndex == 1) {
        _tasksFuture = TaskDatabase.instance.readCompletedTasks();
      } else {
        _tasksFuture = TaskDatabase.instance.readRepeatedTasks();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _refreshTasks();
      _scrollController.jumpTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(), style: TextStyle(fontSize: 22)),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(themeProvider.isDarkMode
                    ? Icons.light_mode
                    : Icons.dark_mode),
                onPressed: () {
                  themeProvider.setThemeMode(
                      themeProvider.isDarkMode
                          ? ThemeMode.light
                          : ThemeMode.dark
                  );
                },
              );
            },
          ),
          if (_selectedIndex == 0)
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () => _showCalendarView(),
            ),
          if (_selectedIndex == 2)
            IconButton(
              icon: Icon(Icons.notifications_active),
              onPressed: () => _showNotificationSettings(),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export_csv') {
                _exportTasksToCSV();
              } else if (value == 'export_pdf') {
                _exportTasksToPDF();
              } else if (value == 'clear_completed') {
                _clearCompletedTasks();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'export_csv',
                  child: ListTile(
                    leading: Icon(Icons.grid_on),
                    title: Text('Export to CSV'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'export_pdf',
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf),
                    title: Text('Export to PDF'),
                  ),
                ),
                if (_selectedIndex == 1)
                  const PopupMenuItem<String>(
                    value: 'clear_completed',
                    child: ListTile(
                      leading: Icon(Icons.delete_forever, color: Colors.red),
                      title: Text('Clear Completed Tasks'),
                    ),
                  ),
              ];
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          } else {
            return _buildTaskList(snapshot.data!);
          }
        },
      ),
      floatingActionButton: _selectedIndex != 1
          ? FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(),
        icon: Icon(Icons.add),
        label: Text('New Task'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      )
          : null,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 96, color: Colors.grey.withOpacity(0.3)),
          SizedBox(height: 24),
          Text(
            _getEmptyStateMessage(),
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    return AnimatedList(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      initialItemCount: tasks.length,
      itemBuilder: (context, index, animation) {
        final task = tasks[index];
        return SlideTransition(
          position: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ).drive(Tween<Offset>(
            begin: Offset(1, 0),
            end: Offset(0, 0),
          )),
          child: _buildTaskCard(task),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: Theme.of(context).colorScheme.secondary,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.today),
          label: 'Today',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.done_all),
          label: 'Completed',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.repeat),
          label: 'Repeated',
        ),
      ],
    );
  }


  Future<void> _undoTaskCompleted(Task task) async {
    final updatedTask = task.copyWith(isCompleted: false);
    await TaskDatabase.instance.updateTask(updatedTask);
    if (!updatedTask.isRepeated || (updatedTask.isRepeated && updatedTask.repeatDays.isNotEmpty)) {
      final notificationDate = DateTime(
        updatedTask.dueDate.year,
        updatedTask.dueDate.month,
        updatedTask.dueDate.day,
        updatedTask.notificationTime.hour,
        updatedTask.notificationTime.minute,
      );
      await NotificationService().scheduleNotification(
        id: updatedTask.id!,
        title: 'Task Reminder',
        body: updatedTask.title,
        scheduledDate: notificationDate,
      );
    }
    _refreshTasks();
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Today\'s Tasks';
      case 1:
        return 'Completed Tasks';
      case 2:
        return 'Repeated Tasks';
      default:
        return 'Task Manager';
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedIndex) {
      case 0:
        return 'No tasks for today!\nAdd a new task to get started.';
      case 1:
        return 'No completed tasks yet!\nComplete some tasks to see them here.';
      case 2:
        return 'No repeated tasks!\nAdd a repeated task to see them here.';
      default:
        return 'No tasks found!';
    }
  }

  Widget _buildTaskCard(Task task) {
    final isCompletedSection = _selectedIndex == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Slidable(
        key: ValueKey(task.id),
        startActionPane: isCompletedSection
            ? ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _undoTaskCompleted(task),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.undo,
              label: 'Undo',
            ),
          ],
        )
            : ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _markTaskCompleted(task),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: Icons.check,
              label: 'Complete',
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            if (!isCompletedSection)
              SlidableAction(
                onPressed: (_) => _showEditTaskDialog(task),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Edit',
              ),
            SlidableAction(
              onPressed: (_) => _deleteTask(task),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showTaskDetails(task),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (task.isRepeated)
                        Icon(Icons.repeat, color: Colors.amber),
                    ],
                  ),
                  if (task.description.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      task.description,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(task.dueDate),
                        style: TextStyle(color: Colors.grey),
                      ),
                      Spacer(),
                      if (task.subtasks.isNotEmpty)
                        Text(
                          '${(task.progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _getProgressColor(task.progress),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  if (task.subtasks.isNotEmpty) ...[
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: task.progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(task.progress),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.orange;
    return Colors.green;
  }

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate = DateTime.now();
    TimeOfDay? selectedTime = TimeOfDay.now();
    bool isRepeated = false;
    List<bool> repeatDays = List.filled(7, false);
    List<Subtask> subtasks = [];
    final subtaskController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState){
            return AlertDialog(
              title: Text('Add New Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.calendar_today),
                      title: Text('Due Date'),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate!)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate!,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.access_time),
                      title: Text('Notification Time'),
                      subtitle: Text(selectedTime!.format(context)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime!,
                        );
                        if (time != null) {
                          setState(() => selectedTime = time);
                        }
                      },
                    ),
                    SwitchListTile(
                      title: Text('Repeat Task'),
                      value: isRepeated,
                      onChanged: (value) => setState(() => isRepeated = value),
                    ),
                    if (isRepeated) ...[
                      SizedBox(height: 8),
                      Text('Repeat on:', style: TextStyle(color: Colors.grey)),
                      Wrap(
                        spacing: 8,
                        children: List.generate(7, (index) {
                          final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                          return FilterChip(
                            label: Text(dayNames[index]),
                            selected: repeatDays[index],
                            onSelected: (selected) {
                              setState(() => repeatDays[index] = selected);
                            },
                          );
                        }),
                      ),
                    ],
                    SizedBox(height: 16),
                    Text('Subtasks', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...subtasks.map((subtask) {
                      return ListTile(
                        leading: Checkbox(
                          value: subtask.isCompleted,
                          onChanged: (value) {
                            setState(() {
                              final index = subtasks.indexOf(subtask);
                              subtasks[index] = subtask.copyWith(isCompleted: value!);
                            });
                          },
                        ),
                        title: Text(subtask.title),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() => subtasks.remove(subtask));
                          },
                        ),
                      );
                    }).toList(),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subtaskController,
                            decoration: InputDecoration(
                              labelText: 'Add Subtask',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            if (subtaskController.text.isNotEmpty) {
                              setState(() {
                                subtasks.add(Subtask(
                                  title: subtaskController.text,
                                  taskId: 0, // Will be updated when task is created
                                ));
                                subtaskController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a title')),
                      );
                      return;
                    }

                    try {
                      final task = Task(
                        title: titleController.text,
                        description: descriptionController.text,
                        dueDate: selectedDate!,
                        isRepeated: isRepeated,
                        repeatDays: isRepeated
                            ? List.generate(7, (index) => index)
                            .where((index) => repeatDays[index])
                            .toList()
                            : [],
                        notificationTime: selectedTime!,
                        subtasks: subtasks,
                      );

                      final createdTask = await TaskDatabase.instance.createTask(task);

                      // Update subtasks with proper task ID
                      final updatedSubtasks = subtasks.map((s) => s.copyWith(taskId: createdTask.id!)).toList();
                      await TaskDatabase.instance.updateTask(createdTask.copyWith(subtasks: updatedSubtasks));

                      if (!isRepeated || (isRepeated && task.repeatDays.isNotEmpty)) {
                        final notificationDate = DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          selectedTime!.hour,
                          selectedTime!.minute,
                        );
                        await NotificationService().scheduleNotification(
                          id: createdTask.id!,
                          title: 'Task Reminder',
                          body: createdTask.title,
                          scheduledDate: notificationDate,
                        );
                      }

                      if (mounted) {
                        Navigator.pop(context);
                        _refreshTasks();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving task: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: Text('Add Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditTaskDialog(Task task) async {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    DateTime selectedDate = task.dueDate;
    TimeOfDay selectedTime = task.notificationTime;
    bool isRepeated = task.isRepeated;
    List<bool> repeatDays = List.generate(7, (index) => task.repeatDays.contains(index));
    List<Subtask> subtasks = List.from(task.subtasks);
    final subtaskController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.calendar_today),
                      title: Text('Due Date'),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.access_time),
                      title: Text('Notification Time'),
                      subtitle: Text(selectedTime.format(context)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setState(() => selectedTime = time);
                        }
                      },
                    ),
                    SwitchListTile(
                      title: Text('Repeat Task'),
                      value: isRepeated,
                      onChanged: (value) => setState(() => isRepeated = value),
                    ),
                    if (isRepeated) ...[
                      SizedBox(height: 8),
                      Text('Repeat on:', style: TextStyle(color: Colors.grey)),
                      Wrap(
                        spacing: 8,
                        children: List.generate(7, (index) {
                          final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                          return FilterChip(
                            label: Text(dayNames[index]),
                            selected: repeatDays[index],
                            onSelected: (selected) {
                              setState(() => repeatDays[index] = selected);
                            },
                          );
                        }),
                      ),
                    ],
                    SizedBox(height: 16),
                    Text('Subtasks', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...subtasks.map((subtask) {
                      return ListTile(
                        leading: Checkbox(
                          value: subtask.isCompleted,
                          onChanged: (value) {
                            setState(() {
                              final index = subtasks.indexOf(subtask);
                              subtasks[index] = subtask.copyWith(isCompleted: value!);
                            });
                          },
                        ),
                        title: Text(subtask.title),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() => subtasks.remove(subtask));
                          },
                        ),
                      );
                    }).toList(),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subtaskController,
                            decoration: InputDecoration(
                              labelText: 'Add Subtask',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            if (subtaskController.text.isNotEmpty) {
                              setState(() {
                                subtasks.add(Subtask(
                                  title: subtaskController.text,
                                  taskId: task.id!,
                                ));
                                subtaskController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a title')),
                      );
                      return;
                    }

                    final updatedTask = task.copyWith(
                      title: titleController.text,
                      description: descriptionController.text,
                      dueDate: selectedDate,
                      isRepeated: isRepeated,
                      repeatDays: isRepeated
                          ? List.generate(7, (index) => index)
                          .where((index) => repeatDays[index])
                          .toList()
                          : [],
                      notificationTime: selectedTime,
                      subtasks: subtasks,
                    );

                    await TaskDatabase.instance.updateTask(updatedTask);

                    // Cancel existing notification and schedule new one if needed
                    await NotificationService().cancelNotification(task.id!);

                    if (!isRepeated || (isRepeated && updatedTask.repeatDays.isNotEmpty)) {
                      final notificationDate = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      await NotificationService().scheduleNotification(
                        id: updatedTask.id!,
                        title: 'Task Reminder',
                        body: updatedTask.title,
                        scheduledDate: notificationDate,
                      );
                    }

                    Navigator.pop(context);
                    _refreshTasks();
                  },
                  child: Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showTaskDetails(Task task) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(task.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (task.description.isNotEmpty) ...[
                  Text(task.description, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Notification: ${task.notificationTime.format(context)}',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                if (task.isRepeated) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.repeat, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Repeats: ${_getRepeatDaysText(task.repeatDays)}',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
                if (task.subtasks.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text('Subtasks:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...task.subtasks.map((subtask) {
                    return ListTile(
                      leading: Checkbox(
                        value: subtask.isCompleted,
                        onChanged: null,
                      ),
                      title: Text(
                        subtask.title,
                        style: TextStyle(
                          decoration: subtask.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(task.progress),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${(task.progress * 100).toStringAsFixed(0)}% complete',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _getRepeatDaysText(List<int> repeatDays) {
    if (repeatDays.isEmpty) return 'Never';
    if (repeatDays.length == 7) return 'Daily';

    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return repeatDays.map((day) => dayNames[day]).join(', ');
  }

  Future<void> _markTaskCompleted(Task task) async {
    final updatedTask = task.copyWith(isCompleted: true);
    await TaskDatabase.instance.updateTask(updatedTask);
    await NotificationService().cancelNotification(task.id!);
    _refreshTasks();
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await TaskDatabase.instance.deleteTask(task.id!);
      await NotificationService().cancelNotification(task.id!);
      _refreshTasks();
    }
  }

  Future<void> _exportTasksToPDF() async {
    final tasks = await TaskDatabase.instance.readAllTasks();
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Task Manager Export',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              ...tasks.map((task) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(task.title,
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue)),
                    if (task.description.isNotEmpty)
                      pw.Text(task.description,
                          style: pw.TextStyle(fontSize: 14)),
                    pw.Text(
                        'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}',
                        style: pw.TextStyle(fontSize: 12)),
                    if (task.isRepeated)
                      pw.Text('Repeats: ${_getRepeatDaysText(task.repeatDays)}',
                          style: pw.TextStyle(fontSize: 12)),
                    if (task.subtasks.isNotEmpty) ...[
                      pw.Text('Subtasks:',
                          style: pw.TextStyle(
                              fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      ...task.subtasks.map((subtask) {
                        return pw.Row(
                          children: [
                            pw.Text('• ',
                                style: pw.TextStyle(fontSize: 14)),
                            pw.Text(subtask.title,
                                style: pw.TextStyle(
                                    fontSize: 14,
                                    decoration: subtask.isCompleted
                                        ? pw.TextDecoration.lineThrough
                                        : null)),
                          ],
                        );
                      }).toList(),
                      pw.Text(
                          'Progress: ${(task.progress * 100).toStringAsFixed(0)}%',
                          style: pw.TextStyle(fontSize: 12)),
                    ],
                    pw.Divider(),
                  ],
                );
              }).toList(),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/tasks_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf");
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF exported successfully'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => OpenFile.open(file.path),
        ),
      ),
    );
  }

  Future<void> _exportTasksToCSV() async {
    final tasks = await TaskDatabase.instance.readAllTasks();
    final csvData = [
      ['Title', 'Description', 'Due Date', 'Status', 'Repeat', 'Subtasks', 'Progress'],
      ...tasks.map((task) {
        return [
          task.title,
          task.description,
          DateFormat('MMM dd, yyyy').format(task.dueDate),
          task.isCompleted ? 'Completed' : 'Pending',
          task.isRepeated ? _getRepeatDaysText(task.repeatDays) : 'No',
          task.subtasks.map((s) => s.title).join('; '),
          '${(task.progress * 100).toStringAsFixed(0)}%',
        ];
      }).toList(),
    ];

    final csv = const ListToCsvConverter().convert(csvData);
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/tasks_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv");
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV exported successfully'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => OpenFile.open(file.path),
        ),
      ),
    );
  }

  Future<void> _clearCompletedTasks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Completed Tasks'),
        content: Text('Are you sure you want to delete all completed tasks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final completedTasks = await TaskDatabase.instance.readCompletedTasks();
      for (var task in completedTasks) {
        await TaskDatabase.instance.deleteTask(task.id!);
        await NotificationService().cancelNotification(task.id!);
      }
      _refreshTasks();
    }
  }

  Future<void> _showCalendarView() async {
    final tasks = await TaskDatabase.instance.readAllTasks();
    final events = tasks.map((task) {
      return CalendarEvent(
        date: task.dueDate,
        title: task.title,
        isCompleted: task.isCompleted,
      );
    }).toList();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Calendar View'),
        content: SizedBox(
          width: double.maxFinite,
          child: CalendarWidget(events: events),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotificationSettings() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notification Settings'),
        content: Text('Configure your notification preferences here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

class CalendarWidget extends StatelessWidget {
  final List<CalendarEvent> events;

  const CalendarWidget({Key? key, required this.events}) : super(key: key);

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.day == now.day && date.month == now.month && date.year == now.year;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    return Column(
      children: [
        _buildMonthHeader(currentMonth),
        _buildCalendarGrid(currentMonth),
      ],
    );
  }

  Widget _buildMonthHeader(DateTime month) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(month),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startingWeekday = firstDay.weekday;

    return Table(
      children: [
        TableRow(
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map((day) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                day,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ))
              .toList(),
        ),
        ...List.generate(6, (week) {
          return TableRow(
            children: List.generate(7, (day) {
              final dayNumber = week * 7 + day - startingWeekday + 1;
              final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
              final currentDate = isCurrentMonth
                  ? DateTime(month.year, month.month, dayNumber)
                  : null;

              final dayEvents = currentDate != null
                  ? events.where((e) {
                final eventDate = DateTime(e.date.year, e.date.month, e.date.day);
                return eventDate == currentDate;
              }).toList()
                  : [];

              return Container(
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Stack(
                  children: [
                    if (isCurrentMonth)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Text(
                          dayNumber.toString(),
                          style: TextStyle(
                            color: _isToday(currentDate) ? Colors.blue : null,
                            fontWeight: _isToday(currentDate) ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    if (dayEvents.isNotEmpty)
                      Positioned(
                        bottom: 2,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: dayEvents.any((e) => e.isCompleted)
                                    ? Colors.green
                                    : Colors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}

class CalendarEvent {
  final DateTime date;
  final String title;
  final bool isCompleted;

  CalendarEvent({
    required this.date,
    required this.title,
    required this.isCompleted,
  });
}
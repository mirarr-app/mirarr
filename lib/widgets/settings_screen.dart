import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/functions/themeprovider_class.dart';
import 'package:Mirarr/functions/supabase_provider.dart';
import 'package:Mirarr/services/supabase_sync_service.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:Mirarr/database/watch_history_database.dart';
import 'package:Mirarr/functions/get_base_url.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _supabaseUrlController = TextEditingController();
  final TextEditingController _supabaseAnonKeyController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSyncing = false;
  Map<String, dynamic>? _syncStatus;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final supabaseProvider = Provider.of<SupabaseProvider>(context, listen: false);
      _supabaseUrlController.text = supabaseProvider.supabaseUrl ?? '';
      _supabaseAnonKeyController.text = supabaseProvider.supabaseAnonKey ?? '';
      _loadSyncStatus();
    });
  }

  @override
  void dispose() {
    _supabaseUrlController.dispose();
    _supabaseAnonKeyController.dispose();
    super.dispose();
  }

  void _loadSyncStatus() async {
    final supabaseProvider = Provider.of<SupabaseProvider>(context, listen: false);
    if (supabaseProvider.isConfigured) {
      final syncService = SupabaseSyncService(supabaseProvider.client);
      final status = await syncService.getSyncStatus();
      setState(() {
        _syncStatus = status;
      });
    }
  }

  void _saveSupabaseConfig() async {
    if (_formKey.currentState!.validate()) {
      final supabaseProvider = Provider.of<SupabaseProvider>(context, listen: false);
      await supabaseProvider.setSupabaseConfig(
        _supabaseUrlController.text.trim().isEmpty ? null : _supabaseUrlController.text.trim(),
        _supabaseAnonKeyController.text.trim().isEmpty ? null : _supabaseAnonKeyController.text.trim(),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            supabaseProvider.isConfigured 
              ? 'Supabase configuration saved successfully!' 
              : 'Supabase configuration cleared',
          ),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
      
      // Reload sync status after configuration change
      _loadSyncStatus();
    }
  }

  void _clearSupabaseConfig() async {
    final supabaseProvider = Provider.of<SupabaseProvider>(context, listen: false);
    await supabaseProvider.clearSupabaseConfig();
    _supabaseUrlController.clear();
    _supabaseAnonKeyController.clear();
    
    setState(() {
      _syncStatus = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Supabase configuration cleared'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _syncWatchHistory() async {
    final supabaseProvider = Provider.of<SupabaseProvider>(context, listen: false);
    if (!supabaseProvider.isConfigured) return;

    setState(() {
      _isSyncing = true;
    });

    final syncService = SupabaseSyncService(supabaseProvider.client);
    final success = await syncService.syncWatchHistory();
    
    setState(() {
      _isSyncing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success 
            ? 'Watch history synced successfully!' 
            : 'Failed to sync watch history. Check your connection. Make sure you have configured Supabase correctly. Read the documentation for more information.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      _loadSyncStatus();
    }
  }

  void _uploadWatchHistory() async {
    final supabaseProvider = Provider.of<SupabaseProvider>(context, listen: false);
    if (!supabaseProvider.isConfigured) return;

    setState(() {
      _isSyncing = true;
    });

    final syncService = SupabaseSyncService(supabaseProvider.client);
    final success = await syncService.uploadWatchHistory();
    
    setState(() {
      _isSyncing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success 
            ? 'Watch history uploaded successfully!' 
            : 'Failed to sync watch history. Check your connection. Make sure you have configured Supabase correctly. Read the documentation for more information.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      _loadSyncStatus();
    }
  }

  void _downloadWatchHistory() async {
    final supabaseProvider = Provider.of<SupabaseProvider>(context, listen: false);
    if (!supabaseProvider.isConfigured) return;

    setState(() {
      _isSyncing = true;
    });

    final syncService = SupabaseSyncService(supabaseProvider.client);
    final success = await syncService.downloadWatchHistory();
    
    setState(() {
      _isSyncing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success 
            ? 'Watch history downloaded successfully!' 
            : 'Failed to sync watch history. Check your connection. Make sure you have configured Supabase correctly. Read the documentation for more information.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      _loadSyncStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Supabase Configuration Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Text(
                'Supabase Configuration',
                style: TextStyle(
                    color: Theme.of(context).primaryColor, fontSize: 20),
              ),
            ),
            const CustomDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Consumer<SupabaseProvider>(
                builder: (context, supabaseProvider, child) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configure your Supabase project to sync your watch history across devices. Configuration is saved locally.',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _supabaseUrlController,
                          decoration: InputDecoration(
                            labelText: 'Supabase URL',
                            hintText: 'https://your-project.supabase.co',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Theme.of(context).primaryColor),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final uri = Uri.tryParse(value);
                              if (uri == null) {
                                return 'Please enter a valid URL';
                              }
                              if (!value.contains('supabase.co')) {
                                return 'Please enter a valid Supabase URL';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _supabaseAnonKeyController,
                          decoration: InputDecoration(
                            labelText: 'Supabase Anon Key',
                            hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Theme.of(context).primaryColor),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          obscureText: true,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (value.length < 50) {
                                return 'Anon key seems too short';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Flexible(
                              child: ElevatedButton(
                                onPressed: _saveSupabaseConfig,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('Save Configuration'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _clearSupabaseConfig,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (supabaseProvider.isConfigured)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Supabase configured successfully',
                                  style: TextStyle(color: Colors.green, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        
                        // Sync Section
                        if (supabaseProvider.isConfigured) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Sync Watch History',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_syncStatus != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sync Status',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Local items: ${_syncStatus!['local_count']}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    'Remote items: ${_syncStatus!['remote_count']}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          // link to documentation
                  
                          const SizedBox(height: 8),
                          Row(
                            children: [
                               Flexible(
                                child: ElevatedButton.icon(
                                  onPressed: _isSyncing ? null : _syncWatchHistory,
                                  icon: _isSyncing 
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.sync),
                                  label: Text(_isSyncing ? 'Syncing...' : 'Sync All'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                                                            const SizedBox(width: 8),

                              Flexible(
                                child: ElevatedButton.icon(
                                  onPressed: _isSyncing ? null : _uploadWatchHistory,
                                  icon: const Icon(Icons.cloud_upload),
                                  label: const Text('Upload'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: ElevatedButton.icon(
                                  onPressed: _isSyncing ? null : _downloadWatchHistory,
                                  icon: const Icon(Icons.cloud_download),
                                  label: const Text('Download'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                      child: ListTile(
                        title:  Text('Documentation', style: TextStyle(color: Theme.of(context).primaryColor),),
                        onTap: () {
                          launchUrl(Uri.parse('https://github.com/mirarr-app/mirarr/blob/main/SUPABASE_SETUP.md'));
                        },
                        trailing:  Icon(Icons.arrow_forward_ios, color: Theme.of(context).primaryColor,),
                      ),
                    ),
                    
            // Import Data Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Text(
                'Import Data',
                style: TextStyle(
                    color: Theme.of(context).primaryColor, fontSize: 20),
              ),
            ),
            const CustomDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.import_contacts, color: Theme.of(context).primaryColor, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Import from Letterboxd',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Go to letterboxd.com/settings/data/\n2. Export your data and unzip the downloaded file.\n3. Tap below and select the "watched.csv" file.',
                        style: TextStyle(color: Colors.grey[400], height: 1.5, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _openLetterboxdSettings,
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('Open Letterboxd'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: ElevatedButton.icon(
                              onPressed: _importLetterboxdCsv,
                              icon: const Icon(Icons.file_upload),
                              label: const Text('Select watched.csv'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tv, color: Theme.of(context).primaryColor, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Import from TV Time',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Use the "TV Time Out by Refract" extension to export either of your movies or series JSON files.\n2. Tap below to select and import the JSON file.',
                        style: TextStyle(color: Colors.grey[400], height: 1.5, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _importTvTimeJson,
                        icon: const Icon(Icons.file_upload),
                        label: const Text('Select JSON File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Region Selection Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Text(
                'Select Region',
                style: TextStyle(
                    color: Theme.of(context).primaryColor, fontSize: 20),
              ),
            ),
            const CustomDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Consumer<RegionProvider>(
                builder: (context, regionProvider, child) {
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      fillColor: Theme.of(context).primaryColor,
                      labelText: 'Select Region',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)),
                      labelStyle:
                          TextStyle(color: Theme.of(context).primaryColor),
                      hintStyle: TextStyle(color: Theme.of(context).primaryColor),
                      focusColor: Theme.of(context).primaryColor,
                      hoverColor: Theme.of(context).primaryColor,
                    ),
                    value: regionProvider.currentRegion,
                    items: [
                      DropdownMenuItem<String>(
                        value: 'iran',
                        child: Text('Iran',
                            style:
                                TextStyle(color: Theme.of(context).primaryColor)),
                      ),
                      DropdownMenuItem<String>(
                        value: 'worldwide',
                        child: Text('Worldwide',
                            style:
                                TextStyle(color: Theme.of(context).primaryColor)),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        Provider.of<RegionProvider>(context, listen: false)
                            .setRegion(newValue);
                      }
                    },
                  );
                },
              ),
            ),
            
            // Theme Selection Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Text(
                'Select Theme',
                style: TextStyle(
                    color: Theme.of(context).primaryColor, fontSize: 20),
              ),
            ),
            const CustomDivider(),
            
            // Theme List
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ListTile(
                  title: const Text('Orange Theme',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  trailing: const Icon(Icons.circle, color: Colors.orange),
                  onTap: () {
                    Provider.of<ThemeProvider>(context, listen: false)
                        .setTheme(AppThemes.orangeTheme);
                  },
                ),
                ListTile(
                  title: const Text(
                    'Blue Theme',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  trailing: const Icon(Icons.circle, color: Colors.blue),
                  onTap: () {
                    Provider.of<ThemeProvider>(context, listen: false)
                        .setTheme(AppThemes.blueTheme);
                  },
                ),
                ListTile(
                  title: const Text(
                    'Red Theme',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  trailing: const Icon(Icons.circle, color: Colors.red),
                  onTap: () {
                    Provider.of<ThemeProvider>(context, listen: false)
                        .setTheme(AppThemes.redTheme);
                  },
                ),
                ListTile(
                  title: const Text('Yellow Theme',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  trailing: const Icon(Icons.circle, color: Colors.yellow),
                  onTap: () {
                    Provider.of<ThemeProvider>(context, listen: false)
                        .setTheme(AppThemes.yellowTheme);
                  },
                ),
                ListTile(
                  title: const Text('Grey Theme',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  trailing: const Icon(Icons.circle, color: Colors.grey),
                  onTap: () {
                    Provider.of<ThemeProvider>(context, listen: false)
                        .setTheme(AppThemes.greyTheme);
                  },
                ),
                ListTile(
                  title: const Text('Brown Theme',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  trailing: const Icon(Icons.circle, color: Colors.brown),
                  onTap: () {
                    Provider.of<ThemeProvider>(context, listen: false)
                        .setTheme(AppThemes.brownTheme);
                  },
                ),
                ListTile(
                  title: const Text('Green Theme',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  trailing: const Icon(Icons.circle, color: Colors.green),
                  onTap: () {
                    Provider.of<ThemeProvider>(context, listen: false)
                        .setTheme(AppThemes.greenTheme);
                  },
                ),
                ListTile(
                  title: const Text('Mono Theme',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )),
                  trailing: const Text(
                    'Mono',
                    style:
                        TextStyle(color: Colors.grey, fontFamily: 'RobotoMono'),
                  ),
                  onTap: () {
                    Provider.of<ThemeProvider>(context, listen: false)
                        .setTheme(AppThemes.monoFontTheme);
                  },
                ),
                ListTile(
                  title: const Text('Nothing',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  trailing: const Icon(Icons.circle, color: Colors.grey),
                  onTap: () {
                    Provider.of<ThemeProvider>(context, listen: false)
                        .setTheme(AppThemes.nothingFontTheme);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openLetterboxdSettings() async {
    final url = Uri.parse('https://letterboxd.com/settings/data/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Letterboxd settings URL')),
        );
      }
    }
  }

  List<List<String>> _parseCsv(String content) {
    final List<List<String>> rows = [];
    List<String> currentRow = [];
    StringBuffer currentField = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < content.length; i++) {
      final char = content[i];
      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < content.length && content[i + 1] == '"') {
            currentField.write('"');
            i++; // Skip next quote
          } else {
            inQuotes = false;
          }
        } else {
          currentField.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == ',') {
          currentRow.add(currentField.toString().trim());
          currentField.clear();
        } else if (char == '\n' || char == '\r') {
          currentRow.add(currentField.toString().trim());
          currentField.clear();
          if (currentRow.any((field) => field.isNotEmpty)) {
            rows.add(currentRow);
          }
          currentRow = [];
          if (char == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
            i++; // Skip \n
          }
        } else {
          currentField.write(char);
        }
      }
    }
    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString().trim());
      if (currentRow.any((field) => field.isNotEmpty)) {
        rows.add(currentRow);
      }
    }
    return rows;
  }

  void _importLetterboxdCsv() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String content = '';
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        final ioFile = File(file.path!);
        content = await ioFile.readAsString();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to read file content')),
          );
        }
        return;
      }

      final rows = _parseCsv(content);
      if (rows.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected CSV file is empty')),
          );
        }
        return;
      }

      final header = rows.first.map((e) => e.trim().toLowerCase()).toList();
      final dateIdx = header.indexOf('date');
      final nameIdx = header.indexOf('name');
      final yearIdx = header.indexOf('year');

      if (dateIdx == -1 || nameIdx == -1 || yearIdx == -1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid Letterboxd CSV. Missing columns: Date, Name, or Year.'),
            ),
          );
        }
        return;
      }

      final region = Provider.of<RegionProvider>(context, listen: false).currentRegion;
      final baseUrl = getBaseUrl(region);
      final apiKey = dotenv.env['TMDB_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('TMDB API Key is missing. Check setup.')),
          );
        }
        return;
      }

      if (mounted) {
        final importedCount = await showDialog<int>(
          context: context,
          barrierDismissible: false,
          builder: (context) => ImportProgressDialog(
            csvRows: rows,
            dateIdx: dateIdx,
            nameIdx: nameIdx,
            yearIdx: yearIdx,
            baseUrl: baseUrl,
            apiKey: apiKey,
          ),
        );

        if (importedCount != null && importedCount > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported $importedCount watched movies!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking or parsing CSV file: $e')),
        );
      }
    }
  }

  void _importTvTimeJson() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String content = '';
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        final ioFile = File(file.path!);
        content = await ioFile.readAsString();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to read file content')),
          );
        }
        return;
      }

      final dynamic decoded = json.decode(content);
      if (decoded is! List) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid JSON format. Expected a JSON array.')),
          );
        }
        return;
      }

      if (!mounted) return;
      final region = Provider.of<RegionProvider>(context, listen: false).currentRegion;
      final baseUrl = getBaseUrl(region);
      final apiKey = dotenv.env['TMDB_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('TMDB API Key is missing. Check setup.')),
          );
        }
        return;
      }

      if (mounted) {
        final importedCount = await showDialog<int>(
          context: context,
          barrierDismissible: false,
          builder: (context) => TvTimeImportProgressDialog(
            jsonList: decoded,
            baseUrl: baseUrl,
            apiKey: apiKey,
          ),
        );

        if (importedCount != null && importedCount > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported $importedCount items!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking or parsing JSON file: $e')),
        );
      }
    }
  }
}

class ImportProgressDialog extends StatefulWidget {
  final List<List<String>> csvRows;
  final int dateIdx;
  final int nameIdx;
  final int yearIdx;
  final String baseUrl;
  final String? apiKey;

  const ImportProgressDialog({
    Key? key,
    required this.csvRows,
    required this.dateIdx,
    required this.nameIdx,
    required this.yearIdx,
    required this.baseUrl,
    required this.apiKey,
  }) : super(key: key);

  @override
  _ImportProgressDialogState createState() => _ImportProgressDialogState();
}

class _ImportProgressDialogState extends State<ImportProgressDialog> {
  int _processedCount = 0;
  int _successCount = 0;
  int _failedCount = 0;
  bool _isCancelled = false;
  bool _isFinished = false;
  String _currentMovieName = '';
  final WatchHistoryDatabase _db = WatchHistoryDatabase();

  @override
  void initState() {
    super.initState();
    _startImport();
  }

  void _startImport() async {
    for (int i = 1; i < widget.csvRows.length; i++) {
      if (_isCancelled) break;

      final row = widget.csvRows[i];
      if (row.length <= widget.nameIdx || row.length <= widget.dateIdx || row.length <= widget.yearIdx) {
        if (mounted) {
          setState(() {
            _processedCount++;
            _failedCount++;
          });
        }
        continue;
      }

      final dateStr = row[widget.dateIdx].trim();
      final name = row[widget.nameIdx].trim();
      final yearStr = row[widget.yearIdx].trim();

      if (name.isEmpty) {
        if (mounted) {
          setState(() {
            _processedCount++;
            _failedCount++;
          });
        }
        continue;
      }

      if (mounted) {
        setState(() {
          _currentMovieName = name;
        });
      }

      final date = DateTime.tryParse(dateStr) ?? DateTime.now();

      try {
        int? tmdbId;
        String? title;
        String? posterPath;

        String searchUrl = '${widget.baseUrl}search/movie?api_key=${widget.apiKey}&query=${Uri.encodeComponent(name)}';
        if (yearStr.isNotEmpty) {
          searchUrl += '&primary_release_year=$yearStr';
        }

        var response = await http.get(Uri.parse(searchUrl));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> results = data['results'] ?? [];
          if (results.isNotEmpty) {
            final first = results.first;
            tmdbId = first['id'];
            title = first['title'];
            posterPath = first['poster_path'];
          }
        }

        if (tmdbId == null && yearStr.isNotEmpty) {
          final fallbackUrl = '${widget.baseUrl}search/movie?api_key=${widget.apiKey}&query=${Uri.encodeComponent(name)}';
          response = await http.get(Uri.parse(fallbackUrl));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final List<dynamic> results = data['results'] ?? [];
            if (results.isNotEmpty) {
              final first = results.first;
              tmdbId = first['id'];
              title = first['title'];
              posterPath = first['poster_path'];
            }
          }
        }

        if (tmdbId != null && title != null) {
          await _db.addMovieToHistory(
            tmdbId: tmdbId,
            title: title,
            posterPath: posterPath,
            watchedAt: date,
          );
          _successCount++;
        } else {
          _failedCount++;
        }
      } catch (e) {
        _failedCount++;
      }

      if (mounted) {
        setState(() {
          _processedCount++;
        });
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (mounted) {
      setState(() {
        _isFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.csvRows.length - 1;
    final progress = total > 0 ? _processedCount / total : 0.0;

    return WillPopScope(
      onWillPop: () async => _isFinished || _isCancelled,
      child: AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          _isFinished
              ? 'Import Completed'
              : _isCancelled
                  ? 'Import Cancelled'
                  : 'Importing movies...',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isFinished && !_isCancelled) ...[
              Text(
                'Processing: $_currentMovieName',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Total processed: $_processedCount / $total',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Successful: $_successCount',
              style: const TextStyle(color: Colors.green),
            ),
            Text(
              'Failed / Unmatched: $_failedCount',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          if (!_isFinished && !_isCancelled)
            TextButton(
              onPressed: () {
                setState(() {
                  _isCancelled = true;
                });
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
          if (_isFinished || _isCancelled)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_successCount);
              },
              child: Text(
                'Close',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}

class TvTimeImportProgressDialog extends StatefulWidget {
  final List<dynamic> jsonList;
  final String baseUrl;
  final String? apiKey;

  const TvTimeImportProgressDialog({
    Key? key,
    required this.jsonList,
    required this.baseUrl,
    required this.apiKey,
  }) : super(key: key);

  @override
  State<TvTimeImportProgressDialog> createState() => _TvTimeImportProgressDialogState();
}

class _TvTimeImportProgressDialogState extends State<TvTimeImportProgressDialog> {
  int _processedCount = 0;
  int _totalCount = 0;
  int _successCount = 0;
  int _failedCount = 0;
  bool _isCancelled = false;
  bool _isFinished = false;
  bool _isSeries = false;
  String _currentName = '';
  final WatchHistoryDatabase _db = WatchHistoryDatabase();
  
  // Cache show/movie lookups to avoid redundant API queries
  final Map<String, Map<String, dynamic>?> _tmdbCache = {};

  @override
  void initState() {
    super.initState();
    _startImport();
  }

  Future<Map<String, dynamic>?> _findMovieTmdb({
    required String title,
    int? tvdbId,
    String? imdbId,
    int? year,
    required String baseUrl,
    required String apiKey,
  }) async {
    if (imdbId != null && imdbId.isNotEmpty) {
      try {
        final findUrl = '${baseUrl}find/$imdbId?api_key=$apiKey&external_source=imdb_id';
        final response = await http.get(Uri.parse(findUrl));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> results = data['movie_results'] ?? [];
          if (results.isNotEmpty) {
            return results.first;
          }
        }
      } catch (_) {}
    }
    
    if (tvdbId != null) {
      try {
        final findUrl = '${baseUrl}find/$tvdbId?api_key=$apiKey&external_source=tvdb_id';
        final response = await http.get(Uri.parse(findUrl));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> results = data['movie_results'] ?? [];
          if (results.isNotEmpty) {
            return results.first;
          }
        }
      } catch (_) {}
    }

    // Fallback to search
    try {
      String searchUrl = '${baseUrl}search/movie?api_key=$apiKey&query=${Uri.encodeComponent(title)}';
      if (year != null) {
        searchUrl += '&primary_release_year=$year';
      }
      var response = await http.get(Uri.parse(searchUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        if (results.isNotEmpty) {
          return results.first;
        }
      }
      
      if (year != null) {
        // Try search without year
        final searchUrlNoYear = '${baseUrl}search/movie?api_key=$apiKey&query=${Uri.encodeComponent(title)}';
        response = await http.get(Uri.parse(searchUrlNoYear));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> results = data['results'] ?? [];
          if (results.isNotEmpty) {
            return results.first;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  Future<Map<String, dynamic>?> _findTvTmdb({
    required String title,
    int? tvdbId,
    String? imdbId,
    required String baseUrl,
    required String apiKey,
  }) async {
    if (tvdbId != null) {
      try {
        final findUrl = '${baseUrl}find/$tvdbId?api_key=$apiKey&external_source=tvdb_id';
        final response = await http.get(Uri.parse(findUrl));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> results = data['tv_results'] ?? [];
          if (results.isNotEmpty) {
            return results.first;
          }
        }
      } catch (_) {}
    }

    if (imdbId != null && imdbId.isNotEmpty) {
      try {
        final findUrl = '${baseUrl}find/$imdbId?api_key=$apiKey&external_source=imdb_id';
        final response = await http.get(Uri.parse(findUrl));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> results = data['tv_results'] ?? [];
          if (results.isNotEmpty) {
            return results.first;
          }
        }
      } catch (_) {}
    }

    // Fallback to search
    try {
      final searchUrl = '${baseUrl}search/tv?api_key=$apiKey&query=${Uri.encodeComponent(title)}';
      final response = await http.get(Uri.parse(searchUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        if (results.isNotEmpty) {
          return results.first;
        }
      }
    } catch (_) {}

    return null;
  }

  void _startImport() async {
    // Determine if movies or series JSON
    final isSeriesDetected = widget.jsonList.any((item) => item is Map && item.containsKey('seasons'));
    
    if (mounted) {
      setState(() {
        _isSeries = isSeriesDetected;
      });
    }

    if (isSeriesDetected) {
      // Parse series and flatten episodes
      final List<Map<String, dynamic>> watchedEpisodes = [];
      for (var seriesItem in widget.jsonList) {
        if (seriesItem is Map<String, dynamic>) {
          final seriesTitle = seriesItem['title'] as String? ?? 'Unknown Series';
          final idMap = seriesItem['id'] as Map<String, dynamic>?;
          final tvdbId = idMap?['tvdb'] as int?;
          final imdbId = idMap?['imdb'] as String?;
          final seriesCreatedAtStr = seriesItem['created_at'] as String?;
          
          final seasons = seriesItem['seasons'] as List<dynamic>?;
          if (seasons != null) {
            for (var season in seasons) {
              if (season is Map<String, dynamic>) {
                final seasonNumber = season['number'] as int? ?? 1;
                final episodes = season['episodes'] as List<dynamic>?;
                if (episodes != null) {
                  for (var episode in episodes) {
                    if (episode is Map<String, dynamic>) {
                      final isWatched = episode['is_watched'];
                      if (isWatched == true || isWatched == 'true') {
                        final episodeNumber = episode['number'] as int? ?? 1;
                        final episodeTitle = episode['name'] as String? ?? 'Episode $episodeNumber';
                        final watchedAtStr = episode['watched_at'] as String?;
                        
                        watchedEpisodes.add({
                          'seriesTitle': seriesTitle,
                          'tvdbId': tvdbId,
                          'imdbId': imdbId,
                          'seasonNumber': seasonNumber,
                          'episodeNumber': episodeNumber,
                          'episodeTitle': episodeTitle,
                          'watchedAt': watchedAtStr,
                          'seriesCreatedAt': seriesCreatedAtStr,
                        });
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      if (watchedEpisodes.isEmpty) {
        if (mounted) {
          setState(() {
            _isFinished = true;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _totalCount = watchedEpisodes.length;
        });
      }

      for (int i = 0; i < watchedEpisodes.length; i++) {
        if (_isCancelled) break;

        final episode = watchedEpisodes[i];
        final seriesTitle = episode['seriesTitle'] as String;
        final tvdbId = episode['tvdbId'] as int?;
        final imdbId = episode['imdbId'] as String?;
        final seasonNumber = episode['seasonNumber'] as int;
        final episodeNumber = episode['episodeNumber'] as int;
        final episodeTitle = episode['episodeTitle'] as String;
        final watchedAtStr = episode['watchedAt'] as String?;
        final seriesCreatedAtStr = episode['seriesCreatedAt'] as String?;

        if (mounted) {
          setState(() {
            _currentName = '$seriesTitle S${seasonNumber}E$episodeNumber';
          });
        }

        final date = (watchedAtStr != null && watchedAtStr.isNotEmpty)
            ? (DateTime.tryParse(watchedAtStr) ?? DateTime.now())
            : (seriesCreatedAtStr != null && seriesCreatedAtStr.isNotEmpty
                ? (DateTime.tryParse(seriesCreatedAtStr) ?? DateTime.now())
                : DateTime.now());

        try {
          final cacheKey = tvdbId != null ? 'tvdb_$tvdbId' : (imdbId != null ? 'imdb_$imdbId' : 'title_$seriesTitle');
          Map<String, dynamic>? tmdbData;

          if (_tmdbCache.containsKey(cacheKey)) {
            tmdbData = _tmdbCache[cacheKey];
          } else {
            tmdbData = await _findTvTmdb(
              title: seriesTitle,
              tvdbId: tvdbId,
              imdbId: imdbId,
              baseUrl: widget.baseUrl,
              apiKey: widget.apiKey ?? '',
            );
            _tmdbCache[cacheKey] = tmdbData;
          }

          if (tmdbData != null) {
            final tmdbId = tmdbData['id'] as int;
            final resolvedTitle = tmdbData['name'] as String? ?? seriesTitle;
            final posterPath = tmdbData['poster_path'] as String?;

            await _db.addShowToHistory(
              tmdbId: tmdbId,
              title: resolvedTitle,
              posterPath: posterPath,
              watchedAt: date,
              seasonNumber: seasonNumber,
              episodeNumber: episodeNumber,
              episodeTitle: episodeTitle,
            );
            _successCount++;
          } else {
            _failedCount++;
          }
        } catch (e) {
          _failedCount++;
        }

        if (mounted) {
          setState(() {
            _processedCount++;
          });
        }

        await Future.delayed(const Duration(milliseconds: 100));
      }
    } else {
      // Parse movies
      final List<Map<String, dynamic>> watchedMovies = [];
      for (var item in widget.jsonList) {
        if (item is Map<String, dynamic>) {
          final isWatched = item['is_watched'];
          if (isWatched == true || isWatched == 'true') {
            watchedMovies.add(item);
          }
        }
      }

      if (watchedMovies.isEmpty) {
        if (mounted) {
          setState(() {
            _isFinished = true;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _totalCount = watchedMovies.length;
        });
      }

      for (int i = 0; i < watchedMovies.length; i++) {
        if (_isCancelled) break;

        final movie = watchedMovies[i];
        final title = movie['title'] as String? ?? 'Unknown Movie';
        final idMap = movie['id'] as Map<String, dynamic>?;
        final tvdbId = idMap?['tvdb'] as int?;
        final imdbId = idMap?['imdb'] as String?;
        final year = movie['year'] as int?;
        final watchedAtStr = movie['watched_at'] as String?;
        final createdAtStr = movie['created_at'] as String?;

        if (mounted) {
          setState(() {
            _currentName = title;
          });
        }

        final date = (watchedAtStr != null && watchedAtStr.isNotEmpty)
            ? (DateTime.tryParse(watchedAtStr) ?? DateTime.now())
            : (createdAtStr != null && createdAtStr.isNotEmpty
                ? (DateTime.tryParse(createdAtStr) ?? DateTime.now())
                : DateTime.now());

        try {
          final cacheKey = imdbId != null ? 'imdb_$imdbId' : (tvdbId != null ? 'tvdb_$tvdbId' : 'title_$title');
          Map<String, dynamic>? tmdbData;

          if (_tmdbCache.containsKey(cacheKey)) {
            tmdbData = _tmdbCache[cacheKey];
          } else {
            tmdbData = await _findMovieTmdb(
              title: title,
              tvdbId: tvdbId,
              imdbId: imdbId,
              year: year,
              baseUrl: widget.baseUrl,
              apiKey: widget.apiKey ?? '',
            );
            _tmdbCache[cacheKey] = tmdbData;
          }

          if (tmdbData != null) {
            final tmdbId = tmdbData['id'] as int;
            final resolvedTitle = tmdbData['title'] as String? ?? title;
            final posterPath = tmdbData['poster_path'] as String?;

            await _db.addMovieToHistory(
              tmdbId: tmdbId,
              title: resolvedTitle,
              posterPath: posterPath,
              watchedAt: date,
            );
            _successCount++;
          } else {
            _failedCount++;
          }
        } catch (e) {
          _failedCount++;
        }

        if (mounted) {
          setState(() {
            _processedCount++;
          });
        }

        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    if (mounted) {
      setState(() {
        _isFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalCount > 0 ? _processedCount / _totalCount : 0.0;

    return PopScope(
      canPop: _isFinished || _isCancelled,
      child: AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          _isFinished
              ? 'Import Completed'
              : _isCancelled
                  ? 'Import Cancelled'
                  : (_isSeries ? 'Importing TV Time series...' : 'Importing TV Time movies...'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isFinished && !_isCancelled) ...[
              Text(
                'Processing: $_currentName',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Total processed: $_processedCount / $_totalCount',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Successful: $_successCount',
              style: const TextStyle(color: Colors.green),
            ),
            Text(
              'Failed / Unmatched: $_failedCount',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          if (!_isFinished && !_isCancelled)
            TextButton(
              onPressed: () {
                setState(() {
                  _isCancelled = true;
                });
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
          if (_isFinished || _isCancelled)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_successCount);
              },
              child: Text(
                'Close',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}

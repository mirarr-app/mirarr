import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/functions/themeprovider_class.dart';
import 'package:Mirarr/functions/supabase_provider.dart';
import 'package:Mirarr/services/supabase_sync_service.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
}

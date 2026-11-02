import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:major_project/providers/complaint_provider.dart';

class NewComplaintScreen extends StatefulWidget {
  final ImagePicker? imagePicker;

  const NewComplaintScreen({
    super.key,
    this.imagePicker,
  });

  @override
  State<NewComplaintScreen> createState() => _NewComplaintScreenState();
}

class _NewComplaintScreenState extends State<NewComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedPriority = 'Medium';
  bool _isAnonymous = false;
  final List<String> _attachedImagePaths = [];

  late final ImagePicker _picker;

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];

  @override
  void initState() {
    super.initState();
    _picker = widget.imagePicker ?? ImagePicker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ComplaintProvider>(context, listen: false);
      if (provider.categories.isEmpty) {
        provider.fetchCategories();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_attachedImagePaths.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 images allowed per complaint.')),
      );
      return;
    }

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _attachedImagePaths.add(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo (Camera)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    debugPrint('[NewComplaint] _submit called. Values: title="${_titleController.text}", cat="$_selectedCategoryId", loc="${_locationController.text}", desc="${_descriptionController.text}"');
    final isValid = _formKey.currentState!.validate();
    debugPrint('[NewComplaint] form validation returned: $isValid');
    if (!isValid) return;

    if (_selectedCategoryId == null) {
      debugPrint('[NewComplaint] category is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    final provider = Provider.of<ComplaintProvider>(context, listen: false);

    // Show modal progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Consumer<ComplaintProvider>(
        builder: (context, prov, _) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                prov.uploadProgress > 0 && prov.uploadProgress < 1.0
                    ? 'Uploading images: ${(prov.uploadProgress * 100).toInt()}%'
                    : 'Lodging complaint...',
              ),
            ],
          ),
        ),
      ),
    );

    final success = await provider.submitComplaint(
      title: _titleController.text,
      description: _descriptionController.text,
      categoryId: _selectedCategoryId!,
      location: _locationController.text,
      priority: _selectedPriority,
      isAnonymous: _isAnonymous,
      imagePaths: _attachedImagePaths,
    );

    if (!mounted) return;
    // Dismiss progress dialog
    Navigator.of(context, rootNavigator: true).pop();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint lodged successfully: ${provider.lastCreatedComplaint?.complaintId ?? ""}'),
          backgroundColor: Colors.teal,
        ),
      );
      Navigator.pop(context, true);
    } else {
      final errorMsg = provider.errorMessage ?? 'Failed to lodge complaint. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<ComplaintProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lodge a Complaint'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('complaint_title_field'),
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Complaint Title *',
                    hintText: 'e.g. Broken water tap in Block B',
                    prefixIcon: Icon(Icons.title_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    if (val.trim().length < 5) {
                      return 'Title must be at least 5 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category dropdown
                provider.isLoadingCategories
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        key: const Key('complaint_category_dropdown'),
                        initialValue: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          prefixIcon: Icon(Icons.category_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: provider.categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          setState(() {
                            _selectedCategoryId = val;
                          });
                        },
                      ),
                const SizedBox(height: 16),

                TextFormField(
                  key: const Key('complaint_location_field'),
                  controller: _locationController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Location / Venue *',
                    hintText: 'e.g. Hostel 3, 2nd Floor, Room 204',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter the location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  key: const Key('complaint_description_field'),
                  controller: _descriptionController,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'Detailed Description *',
                    hintText: 'Describe the issue clearly...',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 56),
                      child: Icon(Icons.description_outlined),
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    if (val.trim().length < 20) {
                      return 'Description must be at least 20 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Priority segmented selector
                Text(
                  'Urgency / Priority',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: _priorities.map((p) {
                    return ButtonSegment<String>(
                      value: p,
                      label: Text(p),
                    );
                  }).toList(),
                  selected: {_selectedPriority},
                  onSelectionChanged: (set) {
                    setState(() {
                      _selectedPriority = set.first;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Whistleblower switch
                SwitchListTile(
                  key: const Key('anonymous_switch'),
                  title: const Text(
                    'Submit Anonymously',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Enable whistleblower protection mode'),
                  value: _isAnonymous,
                  onChanged: (val) {
                    setState(() {
                      _isAnonymous = val;
                    });
                  },
                  secondary: Icon(
                    _isAnonymous ? Icons.security_rounded : Icons.person_outline,
                    color: _isAnonymous ? Colors.teal : null,
                  ),
                ),

                if (_isAnonymous) ...[
                  const SizedBox(height: 8),
                  Card(
                    color: Colors.teal.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_outlined, color: Colors.teal),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Whistleblower Protection: Your identity will be completely scrubbed from hostel/department authorities. Only system administrators can see ticket audit logs.',
                              style: TextStyle(fontSize: 13, color: Colors.teal),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Image attachments
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Evidence Photos (${_attachedImagePaths.length}/3)',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      key: const Key('add_image_button'),
                      onPressed: _attachedImagePaths.length >= 3 ? null : _showImagePickerSheet,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Add Photo'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_attachedImagePaths.isNotEmpty) ...[
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _attachedImagePaths.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (ctx, index) {
                        final path = _attachedImagePaths[index];
                        return Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(File(path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                key: Key('remove_image_$index'),
                                onTap: () {
                                  setState(() {
                                    _attachedImagePaths.removeAt(index);
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('submit_complaint_button'),
                  onPressed: provider.isSubmitting ? null : _submit,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    'Submit Grievance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

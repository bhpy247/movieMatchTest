import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../cubits/users_cubit.dart';

class AddUserPage extends StatefulWidget {
  final UsersCubit cubit; // passed via GoRouter extra
  const AddUserPage({super.key, required this.cubit});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCon    = TextEditingController();
  final _tasteCon   = TextEditingController();
  bool  _isLoading  = false;

  @override
  void dispose() {
    _nameCon.dispose();
    _tasteCon.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await widget.cubit.addUser(
      name:       _nameCon.text.trim(),
      movieTaste: _tasteCon.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User added!')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field
              TextFormField(
                controller: _nameCon,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Alex Johnson',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 2) return 'Name too short';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Movie Taste field
              TextFormField(
                controller: _tasteCon,
                decoration: const InputDecoration(
                  labelText: 'Movie Taste',
                  hintText: 'e.g. loves horror, no sad endings',
                  prefixIcon: Icon(Icons.movie_outlined),
                  helperText: 'A short note about what they like to watch',
                ),
                maxLines: 2,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Movie taste is required';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit button
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Add User'),
              ),

              // Offline hint
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Works offline — syncs when you reconnect',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
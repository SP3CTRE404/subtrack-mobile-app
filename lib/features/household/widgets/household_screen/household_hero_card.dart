import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/custom_toast.dart';
import '../../providers/household_provider.dart';
import 'edit_household_name_dialog.dart';

// Changed to ConsumerStatefulWidget to cache decoded image bytes
class HouseholdHeroCard extends ConsumerStatefulWidget {
  final String householdName;
  final String? imageUrl; // NEW
  final bool isAdmin;
  final String sharedSubs;
  final double totalValue;
  final String currencySymbol;
  final VoidCallback onInviteTap;

  const HouseholdHeroCard({
    super.key,
    required this.householdName,
    this.imageUrl, // NEW
    required this.isAdmin,
    required this.sharedSubs,
    required this.totalValue,
    required this.currencySymbol,
    required this.onInviteTap,
  });

  @override
  ConsumerState<HouseholdHeroCard> createState() => _HouseholdHeroCardState();
}

class _HouseholdHeroCardState extends ConsumerState<HouseholdHeroCard> {
  Uint8List? _decodedImageBytes;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(HouseholdHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _decodeImage();
    }
  }

  void _decodeImage() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      try {
        final base64String = widget.imageUrl!.split(',').last;
        _decodedImageBytes = base64Decode(base64String);
      } catch (e) {
        _decodedImageBytes = null;
      }
    } else {
      _decodedImageBytes = null;
    }
  }

  Future<String?> _cropImage(String path) async {
    final theme = Theme.of(context);
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 80,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Photo',
            toolbarColor: theme.colorScheme.surface,
            toolbarWidgetColor: theme.colorScheme.onSurface,
            activeControlsWidgetColor: AppColors.cobaltBlue,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: 'Edit Photo',
            aspectRatioPresets: [CropAspectRatioPreset.square],
            aspectRatioLockEnabled: true,
            resetButtonHidden: true,
            rotateButtonsHidden: false,
          ),
        ],
      );
      return croppedFile?.path;
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context: context,
          message: 'Error cropping image: $e',
          isError: true,
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.householdName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              height: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.isAdmin) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            color: AppColors.cobaltBlue,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => EditHouseholdNameDialog(
                                  currentName: widget.householdName,
                                  onSave: (newName) async {
                                    try {
                                      await ref.read(householdProvider.notifier).updateHouseholdName(newName);
                                      if (context.mounted) {
                                        CustomToast.show(context: context, message: 'Household name updated!', isError: false);
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        CustomToast.show(context: context, message: 'Failed to update name', isError: true);
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: widget.isAdmin ? () async {
                  final ImagePicker picker = ImagePicker();
                  try {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1000,
                      maxHeight: 1000,
                      imageQuality: 85,
                    );
                    
                    if (image != null && mounted) {
                      final croppedPath = await _cropImage(image.path);
                      if (croppedPath != null) {
                        final bytes = await File(croppedPath).readAsBytes();
                        final base64String = base64Encode(bytes);
                        final imgData = 'data:image/png;base64,$base64String';
                        
                        await ref.read(householdProvider.notifier).updateHouseholdImage(imgData);
                        
                        if (context.mounted) {
                          CustomToast.show(
                            context: context,
                            message: 'Image uploaded successfully!',
                            isError: false,
                          );
                        }
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      CustomToast.show(
                        context: context,
                        message: 'Failed to upload image: $e',
                        isError: true,
                      );
                    }
                  }
                } : null,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.cobaltBlue.withValues(alpha: 0.15),
                      backgroundImage: _decodedImageBytes != null ? MemoryImage(_decodedImageBytes!) : null,
                      child: _decodedImageBytes == null 
                          ? const Icon(Icons.groups_rounded, color: AppColors.cobaltBlue, size: 24)
                          : null, // Only show icon if no image
                    ),
                    if (widget.isAdmin)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.cobaltBlue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.cardTheme.color ?? theme.colorScheme.surface,
                              width: 2.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCol(context, widget.sharedSubs, 'Subscriptions'),
              Container(height: 32, width: 1, color: colorScheme.onSurface.withValues(alpha: 0.1)),
              _buildStatCol(context, formatCurrency(widget.totalValue, widget.currencySymbol), 'Yearly Value'),
            ],
          ),
          if (widget.isAdmin) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onInviteTap,
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Invite People'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cobaltBlue,
                  side: BorderSide(
                    color: AppColors.cobaltBlue.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCol(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.cobaltBlue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

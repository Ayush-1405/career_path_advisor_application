import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';
import '../../providers/social_feed_provider.dart';
import '../../providers/app_auth_provider.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/linkedin_post_card.dart';
import '../../models/post.dart';
import '../../utils/image_helper.dart';

class SocialFeedScreen extends ConsumerStatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen> {
  Timer? _pollingTimer;
  final TextEditingController _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Background fetch every 30 seconds to avoid micro-stutters
      ref.read(socialFeedProvider.notifier).fetchFeed(background: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _postController.dispose();
    super.dispose();
  }

  // ─── Text Only Post ────────────────────────────────────────────────
  void _showCreatePostDialog(BuildContext context, WidgetRef ref) {
    _postController.clear();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create a post',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.gray900,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: isDark ? Colors.white70 : AppTheme.gray600),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _postController,
                  maxLines: 6,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'What do you want to talk about?',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                    border: InputBorder.none,
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final text = _postController.text.trim();
                      if (text.isNotEmpty) {
                        ref.read(socialFeedProvider.notifier).createPost(text);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.userPrimaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Media Post (Image/Video + Text) ──────────────────────────────
  void _showMediaPostDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textController = TextEditingController();
    final List<XFile> selectedFiles = [];
    bool isVideo = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.75,
                maxChildSize: 0.95,
                builder: (_, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Share Media',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.gray900,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: isDark ? Colors.white70 : AppTheme.gray600),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Media type toggle
                        Row(
                          children: [
                            _MediaTypeChip(
                              label: 'Photo',
                              icon: Icons.image,
                              selected: !isVideo,
                              isDark: isDark,
                              onTap: () => setModalState(() => isVideo = false),
                            ),
                            const SizedBox(width: 8),
                            _MediaTypeChip(
                              label: 'Video',
                              icon: Icons.videocam,
                              selected: isVideo,
                              isDark: isDark,
                              onTap: () => setModalState(() => isVideo = true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Media picker area
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            if (isVideo) {
                              final video = await picker.pickVideo(source: ImageSource.gallery);
                              if (video != null) {
                                setModalState(() => selectedFiles
                                  ..clear()
                                  ..add(video));
                              }
                            } else {
                              final images = await picker.pickMultiImage();
                              if (images.isNotEmpty) {
                                setModalState(() => selectedFiles
                                  ..clear()
                                  ..addAll(images));
                              }
                            }
                          },
                          child: selectedFiles.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.userPrimaryBlue.withAlpha(80),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isVideo ? Icons.videocam_outlined : Icons.add_photo_alternate_outlined,
                                        size: 48,
                                        color: AppTheme.userPrimaryBlue,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        isVideo ? 'Tap to select a video' : 'Tap to select photos',
                                        style: TextStyle(
                                          color: AppTheme.userPrimaryBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isVideo ? 'MP4, MOV supported' : 'JPG, PNG supported • up to 9 photos',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white38 : Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : isVideo
                                  ? Container(
                                      width: double.infinity,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          const Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
                                          Positioned(
                                            bottom: 8,
                                            left: 8,
                                            child: Text(
                                              selectedFiles[0].name,
                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () => setModalState(() => selectedFiles.clear()),
                                              child: const CircleAvatar(
                                                radius: 14,
                                                backgroundColor: Colors.red,
                                                child: Icon(Icons.close, size: 16, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : SizedBox(
                                      height: 160,
                                      child: Stack(
                                        children: [
                                          ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: selectedFiles.length,
                                            itemBuilder: (_, i) {
                                              return Stack(
                                                children: [
                                                  Container(
                                                    width: 140,
                                                    margin: const EdgeInsets.only(right: 8),
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(12),
                                                      image: DecorationImage(
                                                        image: FileImage(File(selectedFiles[i].path)),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 4,
                                                    right: 12,
                                                    child: GestureDetector(
                                                      onTap: () => setModalState(() => selectedFiles.removeAt(i)),
                                                      child: const CircleAvatar(
                                                        radius: 12,
                                                        backgroundColor: Colors.red,
                                                        child: Icon(Icons.close, size: 14, color: Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                          if (selectedFiles.length < 9)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              bottom: 0,
                                              child: GestureDetector(
                                                onTap: () async {
                                                  final picker = ImagePicker();
                                                  final images = await picker.pickMultiImage();
                                                  if (images.isNotEmpty) {
                                                    setModalState(() {
                                                      selectedFiles.addAll(images);
                                                      if (selectedFiles.length > 9) {
                                                        selectedFiles.removeRange(9, selectedFiles.length);
                                                      }
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                  width: 48,
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Icon(Icons.add, color: AppTheme.userPrimaryBlue),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                        ),
                        const SizedBox(height: 16),

                        // Caption
                        TextField(
                          controller: textController,
                          maxLines: 4,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Write a caption...',
                            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.send_rounded, color: Colors.white),
                            label: const Text('Share Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            onPressed: () async {
                              final text = textController.text.trim();
                              Navigator.pop(ctx);

                              if (selectedFiles.isNotEmpty) {
                                // Show uploading snackbar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                        const SizedBox(width: 12),
                                        Text('Uploading ${isVideo ? 'video' : '${selectedFiles.length} photo${selectedFiles.length > 1 ? 's' : ''}'}...'),
                                      ],
                                    ),
                                    duration: const Duration(seconds: 10),
                                  ),
                                );
                                try {
                                  final apiService = ref.read(apiServiceProvider);
                                  final List<String> uploadedUrls = [];
                                  for (final file in selectedFiles) {
                                    final url = await apiService.uploadMediaFile(file.path, file.name);
                                    uploadedUrls.add(url);
                                  }
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  final content = text.isNotEmpty ? text : (isVideo ? 'Shared a video' : 'Shared ${uploadedUrls.length} photo${uploadedUrls.length > 1 ? 's' : ''}');
                                  await ref.read(socialFeedProvider.notifier).createPost(
                                    content,
                                    mediaUrls: uploadedUrls,
                                    mediaType: isVideo ? 'VIDEO' : 'IMAGE',
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              } else {
                                final content = text.isNotEmpty ? text : 'Post';
                                ref.read(socialFeedProvider.notifier).createPost(content);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.userPrimaryBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // ─── Event Post ───────────────────────────────────────────────────
  void _showEventPostDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    XFile? bannerImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              maxChildSize: 0.97,
              builder: (_, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Create Event',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.gray900,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: isDark ? Colors.white70 : AppTheme.gray600),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Event Banner
                      GestureDetector(
                        onTap: () async {
                          final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (picked != null) setModalState(() => bannerImage = picked);
                        },
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            image: bannerImage != null
                                ? DecorationImage(
                                    image: FileImage(File(bannerImage!.path)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: bannerImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.orange),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add Event Banner',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: GestureDetector(
                                      onTap: () => setModalState(() => bannerImage = null),
                                      child: const CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.red,
                                        child: Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Event Title
                      _FormField(
                        label: 'Event Title *',
                        controller: titleController,
                        hint: 'e.g. Career Networking Meetup',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Date & Time
                      Text(
                        'Date & Time',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppTheme.gray700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _DateTimeBtn(
                              icon: Icons.calendar_today_outlined,
                              label: DateFormat('EEE, MMM d, yyyy').format(selectedDate),
                              isDark: isDark,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                                  builder: (ctx, child) => Theme(
                                    data: Theme.of(ctx).copyWith(
                                      colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.userPrimaryBlue),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) setModalState(() => selectedDate = picked);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DateTimeBtn(
                              icon: Icons.access_time_outlined,
                              label: selectedTime.format(ctx),
                              isDark: isDark,
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: ctx,
                                  initialTime: selectedTime,
                                  builder: (ctx, child) => Theme(
                                    data: Theme.of(ctx).copyWith(
                                      colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.userPrimaryBlue),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) setModalState(() => selectedTime = picked);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Location
                      _FormField(
                        label: 'Location',
                        controller: locationController,
                        hint: 'e.g. Mumbai, Online (Zoom), etc.',
                        isDark: isDark,
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppTheme.gray700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descController,
                        maxLines: 5,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Tell people what this event is about...',
                          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                      const SizedBox(height: 24),

                       SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.event_available, color: Colors.white),
                          label: const Text('Create Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          onPressed: () async {
                            final title = titleController.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Please add an event title')),
                              );
                              return;
                            }
                            Navigator.pop(ctx);

                            final dateStr = DateFormat('EEE, MMM d yyyy').format(selectedDate);
                            final timeStr = selectedTime.format(context);
                            final location = locationController.text.trim();
                            final desc = descController.text.trim();
                            final content = '🗓 EVENT: $title\n📅 $dateStr at $timeStr'
                                '${location.isNotEmpty ? '\n📍 $location' : ''}'
                                '${desc.isNotEmpty ? '\n\n$desc' : ''}';

                            List<String> mediaUrls = [];
                            if (bannerImage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                      SizedBox(width: 12),
                                      Text('Uploading event banner...'),
                                    ],
                                  ),
                                  duration: Duration(seconds: 15),
                                ),
                              );
                              try {
                                final url = await ref.read(apiServiceProvider).uploadMediaFile(
                                  bannerImage!.path,
                                  bannerImage!.name,
                                );
                                mediaUrls = [url];
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              } catch (e) {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Banner upload failed: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }

                            await ref.read(socialFeedProvider.notifier).createPost(
                              content,
                              isAchievement: false,
                              mediaUrls: mediaUrls.isNotEmpty ? mediaUrls : null,
                              mediaType: mediaUrls.isNotEmpty ? 'IMAGE' : null,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ─── Article Post ─────────────────────────────────────────────────
  void _showArticlePostDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headlineController = TextEditingController();
    final bodyController = TextEditingController();
    XFile? coverImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              maxChildSize: 0.97,
              builder: (_, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Write Article',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.gray900,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: isDark ? Colors.white70 : AppTheme.gray600),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share your insights and expertise',
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : AppTheme.gray500),
                      ),
                      const SizedBox(height: 16),

                      // Cover Image
                      GestureDetector(
                        onTap: () async {
                          final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (picked != null) setModalState(() => coverImage = picked);
                        },
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFF0F0),
                            image: coverImage != null
                                ? DecorationImage(
                                    image: FileImage(File(coverImage!.path)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: coverImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.image_outlined, size: 36, color: Colors.redAccent),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Add Cover Image (optional)',
                                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ],
                                )
                              : Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: GestureDetector(
                                      onTap: () => setModalState(() => coverImage = null),
                                      child: const CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.red,
                                        child: Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Headline
                      TextField(
                        controller: headlineController,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.gray900,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Headline...',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      Divider(color: isDark ? Colors.white12 : Colors.black12),
                      const SizedBox(height: 8),

                      // Body
                      TextField(
                        controller: bodyController,
                        maxLines: 12,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: isDark ? Colors.white70 : AppTheme.gray700,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write your article here. Share your story, insights, or career tips...',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 24),

                       SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.article_outlined, color: Colors.white),
                          label: const Text('Publish Article', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          onPressed: () async {
                            final headline = headlineController.text.trim();
                            final body = bodyController.text.trim();
                            if (headline.isEmpty && body.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Please write something first')),
                              );
                              return;
                            }
                            Navigator.pop(ctx);

                            final content = '📰 ARTICLE'
                                '${headline.isNotEmpty ? '\n\n$headline' : ''}'
                                '${body.isNotEmpty ? '\n\n$body' : ''}';

                            List<String> mediaUrls = [];
                            if (coverImage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                      SizedBox(width: 12),
                                      Text('Uploading cover image...'),
                                    ],
                                  ),
                                  duration: Duration(seconds: 15),
                                ),
                              );
                              try {
                                final url = await ref.read(apiServiceProvider).uploadMediaFile(
                                  coverImage!.path,
                                  coverImage!.name,
                                );
                                mediaUrls = [url];
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              } catch (e) {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Cover image upload failed: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }

                            await ref.read(socialFeedProvider.notifier).createPost(
                              content,
                              isAchievement: false,
                              mediaUrls: mediaUrls.isNotEmpty ? mediaUrls : null,
                              mediaType: mediaUrls.isNotEmpty ? 'IMAGE' : null,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final feedState = ref.watch(socialFeedProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE9E5DF),
        appBar: AppBar(
          title: InkWell(
            onTap: () => context.push('/search'),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF3F8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 20,
                    color: isDark ? Colors.white38 : const Color(0xFF666666),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Search',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : const Color(0xFF666666),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppTheme.gray900,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(Icons.message_outlined),
              color: isDark ? Colors.white70 : AppTheme.gray600,
              onPressed: () => context.push('/chat'),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => ref.read(socialFeedProvider.notifier).fetchFeed(),
          child: CustomScrollView(
            slivers: [
              // Create Post Area
              SliverToBoxAdapter(
                child: Container(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: isDark
                                ? AppTheme.userPrimaryBlue.withAlpha(51)
                                : AppTheme.userPrimaryBlue.withAlpha(26),
                            backgroundImage: currentUser?.profilePictureUrl != null &&
                                    currentUser!.profilePictureUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(ImageHelper.getImageUrl(currentUser.profilePictureUrl)!)
                                : null,
                            child: currentUser?.profilePictureUrl == null ||
                                    currentUser!.profilePictureUrl!.isEmpty
                                ? Text(
                                    currentUser?.name.isNotEmpty == true
                                        ? currentUser!.name[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppTheme.userPrimaryBlue,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _showCreatePostDialog(context, ref),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: isDark ? Colors.white38 : AppTheme.gray400),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  'Start a post',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : AppTheme.gray600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _PostActionTab(
                            icon: Icons.image,
                            label: 'Media',
                            color: Colors.blue,
                            onTap: () => _showMediaPostDialog(context, ref),
                          ),
                          _PostActionTab(
                            icon: Icons.event,
                            label: 'Event',
                            color: Colors.orange,
                            onTap: () => _showEventPostDialog(context, ref),
                          ),
                          _PostActionTab(
                            icon: Icons.article,
                            label: 'Write article',
                            color: Colors.redAccent,
                            onTap: () => _showArticlePostDialog(context, ref),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Feed
              feedState.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No posts yet. Start the conversation!',
                          style: TextStyle(color: isDark ? Colors.white54 : AppTheme.gray500),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return LinkedInPostCard(
                          post: posts[index],
                          isDark: isDark,
                        );
                      },
                      childCount: posts.length,
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                error: (err, st) => SliverFillRemaining(
                  child: Center(child: Text('Failed to load feed: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ──────────────────────────────────────────────────────────

class _PostActionTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PostActionTab({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF666666),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _MediaTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.userPrimaryBlue
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.userPrimaryBlue : (isDark ? Colors.white24 : Colors.black12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : (isDark ? Colors.white70 : AppTheme.gray600)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? Colors.white : (isDark ? Colors.white70 : AppTheme.gray600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final IconData? prefixIcon;

  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.isDark,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppTheme.gray700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: isDark ? Colors.white38 : Colors.black38)
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _DateTimeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _DateTimeBtn({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.userPrimaryBlue),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.gray900,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/tv_provider.dart';
import '../models/tv_channel.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  String? _selectedCountryCode;
  String? _selectedCountryName;
  String _countrySearchQuery = '';
  String _channelSearchQuery = '';
  late final TextEditingController _countrySearchController;
  late final TextEditingController _channelSearchController;

  @override
  void initState() {
    super.initState();
    _countrySearchController = TextEditingController();
    _channelSearchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TvProvider>(context, listen: false).loadCountriesMetadata();
    });
  }

  @override
  void dispose() {
    _countrySearchController.dispose();
    _channelSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedCountryCode == null
          ? _buildCountriesList()
          : _buildChannelsList(),
    );
  }

  Widget _buildCountriesList() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'پخش زنده',
            style: GoogleFonts.vazirmatn(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'کشور مورد نظر خود را انتخاب کنید',
            style: GoogleFonts.vazirmatn(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 24),
          // Search bar for countries
          TextField(
            controller: _countrySearchController,
            onChanged: (value) {
              setState(() {
                _countrySearchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'جستجوی کشورها...',
              hintStyle: GoogleFonts.vazirmatn(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).iconTheme.color,
              ),
              suffixIcon: _countrySearchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        setState(() {
                          _countrySearchQuery = '';
                          _countrySearchController.clear();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Consumer<TvProvider>(
              builder: (context, tvProvider, child) {
                if (tvProvider.isLoadingCountries) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (tvProvider.countriesErrorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'خطا: ${tvProvider.countriesErrorMessage}',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لطفاً دوباره تلاش کنید',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: tvProvider.loadCountriesMetadata,
                          child: Text(
                            'تلاش مجدد',
                            style: GoogleFonts.vazirmatn(),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter countries based on search query
                final filteredCountries = <MapEntry<String, dynamic>>[];
                tvProvider.countriesMetadata.forEach((code, data) {
                  final countryData = data as Map<String, dynamic>;
                  final countryName = countryData['country'] as String;

                  if (_countrySearchQuery.isEmpty ||
                      countryName.contains(_countrySearchQuery) ||
                      countryName.toLowerCase().contains(
                        _countrySearchQuery.toLowerCase(),
                      ) ||
                      code.toLowerCase().contains(
                        _countrySearchQuery.toLowerCase(),
                      )) {
                    // Only include countries that have channels
                    if (countryData['hasChannels'] == true) {
                      filteredCountries.add(MapEntry(code, countryData));
                    }
                  }
                });

                if (filteredCountries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _countrySearchQuery.isEmpty
                              ? 'کشوری یافت نشد'
                              : 'کشوری با این نام یافت نشد',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildCountriesGrid(filteredCountries);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountriesGrid(List<MapEntry<String, dynamic>> countries) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = 150.0;
        final spacing = 20.0;
        final crossAxisCount =
            ((constraints.maxWidth + spacing) / (cardWidth + spacing))
                .floor()
                .toInt();

        final count = crossAxisCount.clamp(1, 6);

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            childAspectRatio: 1.2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: countries.length,
          itemBuilder: (context, index) {
            final country = countries[index];
            final code = country.key;
            final data = country.value as Map<String, dynamic>;
            final name = data['country'] as String;

            return _CountryCard(
              countryCode: code,
              countryName: name,
              onTap: () {
                setState(() {
                  _selectedCountryCode = code;
                  _selectedCountryName = name;
                  // Clear country search query when selecting a country
                  _countrySearchQuery = '';
                  _countrySearchController.clear();
                  // Clear channel search query when selecting a country
                  _channelSearchQuery = '';
                  _channelSearchController.clear();
                });
                // Load channels for the selected country
                Provider.of<TvProvider>(
                  context,
                  listen: false,
                ).loadChannelsByCountry(code);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChannelsList() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () {
                  setState(() {
                    _selectedCountryCode = null;
                    _selectedCountryName = null;
                    // Clear search queries when going back to countries list
                    _countrySearchQuery = '';
                    _channelSearchQuery = '';
                    _countrySearchController.clear();
                    _channelSearchController.clear();
                  });
                },
              ),
              const SizedBox(width: 12),
              Text(
                _selectedCountryName ?? '',
                style: GoogleFonts.vazirmatn(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  if (_selectedCountryCode != null) {
                    Provider.of<TvProvider>(
                      context,
                      listen: false,
                    ).loadChannelsByCountry(_selectedCountryCode!);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Search bar for channels
          TextField(
            controller: _channelSearchController,
            onChanged: (value) {
              setState(() {
                _channelSearchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'جستجوی کانال‌ها...',
              hintStyle: GoogleFonts.vazirmatn(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).iconTheme.color,
              ),
              suffixIcon: _channelSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        setState(() {
                          _channelSearchQuery = '';
                          _channelSearchController.clear();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Consumer<TvProvider>(
              builder: (context, tvProvider, child) {
                if (tvProvider.isLoadingChannels &&
                    tvProvider.channels.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (tvProvider.channelsErrorMessage != null &&
                    tvProvider.channels.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'خطا: ${tvProvider.channelsErrorMessage}',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لطفاً دوباره تلاش کنید',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => tvProvider.loadChannelsByCountry(
                            _selectedCountryCode!,
                          ),
                          child: Text(
                            'تلاش مجدد',
                            style: GoogleFonts.vazirmatn(),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (tvProvider.channels.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.live_tv_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'کانالی برای این کشور یافت نشد',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildChannelsGrid(tvProvider.channels);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsGrid(List<TvChannel> channels) {
    // Filter channels based on search query
    final filteredChannels = _channelSearchQuery.isEmpty
        ? channels
        : channels.where((channel) {
            return channel.name.contains(_channelSearchQuery) ||
                channel.name.toLowerCase().contains(
                  _channelSearchQuery.toLowerCase(),
                );
          }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = 200.0;
        final spacing = 20.0;
        final crossAxisCount =
            ((constraints.maxWidth + spacing) / (cardWidth + spacing))
                .floor()
                .toInt();

        final count = crossAxisCount.clamp(1, 5);

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            childAspectRatio: 0.68,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: filteredChannels.length,
          itemBuilder: (context, index) {
            final channel = filteredChannels[index];
            return _ChannelCard(channel: channel);
          },
        );
      },
    );
  }
}

// Video player screen
class _VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final Player player;
  final VideoController videoController;

  const _VideoPlayerScreen({
    required this.url,
    required this.title,
    required this.player,
    required this.videoController,
  });

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  @override
  void dispose() {
    widget.player.dispose();
    super.dispose();
  }

  void _showPlayerInstructionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'راهنمای پخش کننده ویدیو',
            style: GoogleFonts.vazirmatn(),
          ),
          content: SingleChildScrollView(
            child: Text(
              'برای نمایش آیکون تمام صفحه و نوار پیشرفت:\n\n'
              'روی صفحه ویدیو کلیک کنید\n\n'
              'سپس روی آیکون تمام صفحه کلیک کنید\n\n'
              'برای کنترل پیشرفت پخش:\n\n'
              'از نوار پیشرفت استفاده کنید',
              style: GoogleFonts.vazirmatn(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('بستن', style: GoogleFonts.vazirmatn()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showPlayerInstructionsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Video player
          Expanded(
            child: GestureDetector(
              onTap: _showPlayerInstructionsDialog,
              child: Video(
                controller: widget.videoController,
                controls: MaterialVideoControls,
              ),
            ),
          ),
          // Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  onPressed: () {
                    widget.player.seek(const Duration(seconds: -10));
                  },
                ),
                IconButton(
                  icon: StreamBuilder<bool>(
                    stream: widget.player.stream.playing,
                    builder: (context, snapshot) {
                      final playing = snapshot.data ?? false;
                      return Icon(playing ? Icons.pause : Icons.play_arrow);
                    },
                  ),
                  onPressed: () {
                    widget.player.playOrPause();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  onPressed: () {
                    widget.player.seek(const Duration(seconds: 10));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryCard extends StatelessWidget {
  final String countryCode;
  final String countryName;
  final VoidCallback onTap;

  const _CountryCard({
    required this.countryCode,
    required this.countryName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                // Try to load flag from assets
                image: _getFlagImage(countryCode),
                color: _getFlagImage(countryCode) == null
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
              ),
              child: _getFlagImage(countryCode) == null
                  ? Center(
                      child: Text(
                        countryCode,
                        style: GoogleFonts.vazirmatn(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              countryName,
              style: GoogleFonts.vazirmatn(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  DecorationImage? _getFlagImage(String countryCode) {
    try {
      // Handle special case for United Kingdom (GB)
      String flagCode = countryCode.toUpperCase();
      if (flagCode == 'UK') {
        flagCode = 'GB';
      }

      return DecorationImage(
        image: AssetImage('assets/CountryFlags/$flagCode.png'),
        fit: BoxFit.cover,
      );
    } catch (e) {
      // Return null if flag image is not found
      return null;
    }
  }
}

class _ChannelCard extends StatelessWidget {
  final TvChannel channel;

  const _ChannelCard({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel image/header
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Center(
              child: Icon(
                channel.hasYoutube ? Icons.play_circle_fill : Icons.live_tv,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.name,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Show channel type indicators
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (channel.hasIptv)
                      Chip(
                        label: Text(
                          'IPTV',
                          style: GoogleFonts.vazirmatn(fontSize: 12),
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                      ),
                    if (channel.hasYoutube)
                      Chip(
                        label: Text(
                          'YouTube',
                          style: GoogleFonts.vazirmatn(fontSize: 12),
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Play button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showPlaybackOptions(context, channel);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: Text('پخش', style: GoogleFonts.vazirmatn()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaybackOptions(BuildContext context, TvChannel channel) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.live_tv),
                title: Text('پخش با IPTV', style: GoogleFonts.vazirmatn()),
                enabled: channel.hasIptv,
                onTap: channel.hasIptv
                    ? () {
                        Navigator.pop(context);
                        _playIptv(context, channel);
                      }
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_fill),
                title: Text('پخش با YouTube', style: GoogleFonts.vazirmatn()),
                enabled: channel.hasYoutube,
                onTap: channel.hasYoutube
                    ? () {
                        Navigator.pop(context);
                        _playYoutube(context, channel);
                      }
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  void _playIptv(BuildContext context, TvChannel channel) {
    if (channel.iptvUrls.isNotEmpty) {
      _playMedia(context, channel.iptvUrls.first, channel.name);
    }
  }

  void _playYoutube(BuildContext context, TvChannel channel) {
    if (channel.youtubeUrls.isNotEmpty) {
      _launchUrlExternally(context, channel.youtubeUrls.first);
    }
  }

  void _playMedia(BuildContext context, String url, String title) {
    // Create player and controller
    final player = Player();
    final videoController = VideoController(player);

    // Open the media
    player.open(Media(url));

    // Open a new screen for video playback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => _VideoPlayerScreen(
              url: url,
              title: title,
              player: player,
              videoController: videoController,
            ),
          ),
        );
      }
    });
  }

  void _launchUrlExternally(BuildContext context, String url) async {
    // Convert YouTube embed URLs to regular watch URLs
    String convertedUrl = url;
    if (url.contains('youtube-nocookie.com/embed/') ||
        url.contains('youtube.com/embed/')) {
      final uri = Uri.parse(url);
      final videoId = uri.pathSegments.last;
      convertedUrl = 'https://www.youtube.com/watch?v=$videoId';
    }

    final Uri uri = Uri.parse(convertedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Handle the error appropriately
      debugPrint('Could not launch URL: $convertedUrl');
      // Show a snackbar to inform the user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('نمی‌توان لینک را باز کرد')),
        );
      }
    }
  }
}

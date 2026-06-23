import 'package:flutter/material.dart';

/// Maps the design's line-icon names (kit.jsx `Icon`) to the closest
/// Material outline glyphs, so screens can reference icons by the same
/// names used in the wireframe.
class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, this.size = 22, this.color});

  final String name;
  final double size;
  final Color? color;

  static const _map = <String, IconData>{
    'home': Icons.home_outlined,
    'wallet': Icons.account_balance_wallet_outlined,
    'person': Icons.person_outline,
    'camera': Icons.photo_camera_outlined,
    'bell': Icons.notifications_none,
    'plus': Icons.add,
    'arrow': Icons.arrow_forward,
    'check': Icons.check,
    'chevron': Icons.chevron_right,
    'back': Icons.arrow_back_ios_new,
    'close': Icons.close,
    'clock': Icons.access_time,
    'gift': Icons.card_giftcard,
    'image': Icons.image_outlined,
    'grid': Icons.grid_view,
    'edit': Icons.edit_outlined,
    'star': Icons.star_border,
    'trash': Icons.delete_outline,
    'refresh': Icons.refresh,
    'globe': Icons.language,
    'help': Icons.help_outline,
    'shield': Icons.shield_outlined,
    'logout': Icons.logout,
    'phone': Icons.call_outlined,
    'search': Icons.search,
    'bolt': Icons.bolt,
    'bank': Icons.account_balance,
    'truck': Icons.local_shipping_outlined,
    'info': Icons.info_outline,
    'wifi': Icons.wifi,
    'pin': Icons.location_on_outlined,
    'filter': Icons.filter_alt_outlined,
    'swap': Icons.swap_vert,
    'bookmark': Icons.bookmark_border,
    'map': Icons.map_outlined,
    'sort': Icons.swap_vert,
  };

  @override
  Widget build(BuildContext context) {
    return Icon(_map[name] ?? Icons.help_outline, size: size, color: color);
  }
}

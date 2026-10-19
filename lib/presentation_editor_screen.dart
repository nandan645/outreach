import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'api_service.dart';
import 'image_helper.dart';
import 'main.dart';
import 'slides/slides.dart';

Widget _buildHeyDocLogo({required double height}) {
  return Image.asset(
    'assets/presets/logo_presets/heydoc.png',
    height: height,
    fit: BoxFit.contain,
    alignment: Alignment.centerLeft,
    errorBuilder: (context, error, stackTrace) {
      return Text(
        'heyDoc',
        style: TextStyle(
          fontSize: height * 0.6,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F3952),
        ),
      );
    },
  );
}

List<dynamic> _extractSolutionMappingItems(dynamic rawData) {
  if (rawData == null) return [];
  if (rawData is List) return rawData;
  if (rawData is Map) {
    if (rawData['items'] is List) return rawData['items'] as List;
    if (rawData['solution'] is List) return rawData['solution'] as List;
    if (rawData['painPoints'] is List) return rawData['painPoints'] as List;
    if (rawData['pain_points'] is List) return rawData['pain_points'] as List;
    if (rawData['capabilities'] is List) return rawData['capabilities'] as List;
    if (rawData['features'] is List) return rawData['features'] as List;
    if (rawData['points'] is List) return rawData['points'] as List;
    if (rawData['list'] is List) return rawData['list'] as List;
    final fallbackList = rawData.values
        .where((v) => v is String || v is Map)
        .toList();
    if (fallbackList.isNotEmpty) return fallbackList;
  }
  return [];
}

String _formatSolutionMappingItemText(dynamic item) {
  if (item == null) return '';
  if (item is String) return item;
  if (item is Map) {
    final title = (item['title'] ?? item['heading'] ?? item['name'] ?? item['label'])?.toString().trim() ?? '';
    final desc = (item['description'] ?? item['detail'] ?? item['text'] ?? item['point'] ?? item['painPoint'] ?? item['solution'] ?? item['value'])?.toString().trim() ?? '';
    if (title.isNotEmpty && desc.isNotEmpty) {
      return '$title: $desc';
    } else if (title.isNotEmpty) {
      return title;
    } else if (desc.isNotEmpty) {
      return desc;
    } else {
      final validVals = item.values
          .where((v) => v != null && v is! List && v is! Map && v.toString().trim().isNotEmpty)
          .map((v) => v.toString().trim());
      if (validVals.isNotEmpty) return validVals.join(': ');
    }
  }
  return item.toString();
}

const Map<String, IconData> availableIconsMap = {
  // General & Status
  'check_circle': Icons.check_circle_outline,
  'check': Icons.check,
  'done_all': Icons.done_all,
  'verified': Icons.verified_outlined,
  'star': Icons.star_outline,
  'star_filled': Icons.star,
  'heart': Icons.favorite_border,
  'thumb_up': Icons.thumb_up_alt_outlined,
  'bookmark': Icons.bookmark_outline,
  'flag': Icons.flag_outlined,
  'tag': Icons.local_offer_outlined,
  'push_pin': Icons.push_pin_outlined,
  'help': Icons.help_outline,
  'info': Icons.info_outline,
  'warning': Icons.warning_amber_rounded,
  'error': Icons.error_outline,
  'cancel': Icons.cancel_outlined,
  'close': Icons.close,

  // Business, Growth & Finance
  'briefcase': Icons.work_outline,
  'building': Icons.business_outlined,
  'store': Icons.storefront,
  'money': Icons.payments_outlined,
  'savings': Icons.savings_outlined,
  'credit_card': Icons.credit_card,
  'dollar': Icons.attach_money,
  'trending_up': Icons.trending_up,
  'trending_down': Icons.trending_down,
  'analytics': Icons.insights,
  'bar_chart': Icons.bar_chart,
  'pie_chart': Icons.pie_chart_outline,
  'show_chart': Icons.show_chart,
  'target': Icons.track_changes,
  'trophy': Icons.emoji_events_outlined,
  'award': Icons.military_tech_outlined,
  'crown': Icons.workspace_premium_outlined,

  // Tech, AI & Data
  'rocket': Icons.rocket_launch_outlined,
  'ai_sparkles': Icons.auto_awesome,
  'brain_ai': Icons.psychology_outlined,
  'robot': Icons.smart_toy_outlined,
  'zap': Icons.bolt,
  'lightbulb': Icons.lightbulb_outline,
  'cpu': Icons.memory,
  'terminal': Icons.terminal,
  'code': Icons.code,
  'storage': Icons.dns_outlined,
  'database': Icons.storage,
  'cloud': Icons.cloud_outlined,
  'cloud_upload': Icons.cloud_upload_outlined,
  'cloud_download': Icons.cloud_download_outlined,
  'wifi': Icons.wifi,
  'shield': Icons.shield_outlined,
  'lock': Icons.lock_outline,
  'key': Icons.vpn_key_outlined,
  'settings': Icons.settings_outlined,
  'tune': Icons.tune,
  'hub': Icons.hub_outlined,
  'network': Icons.lan_outlined,

  // People & Communication
  'phone': Icons.phone_outlined,
  'email': Icons.email_outlined,
  'chat': Icons.chat_bubble_outline,
  'comment': Icons.comment_bank_outlined,
  'send': Icons.send_outlined,
  'share': Icons.share_outlined,
  'globe': Icons.public,
  'map_pin': Icons.location_on_outlined,
  'compass': Icons.explore_outlined,
  'user': Icons.person_outline,
  'users': Icons.people_outline,
  'group': Icons.groups_outlined,
  'badge': Icons.badge_outlined,
  'support': Icons.support_agent,

  // Process & Navigation
  'arrow_forward': Icons.arrow_forward,
  'arrow_back': Icons.arrow_back,
  'arrow_up': Icons.arrow_upward,
  'arrow_down': Icons.arrow_downward,
  'arrow_bidirectional': Icons.swap_horiz,
  'sync_alt': Icons.sync_alt,
  'compare_arrows': Icons.compare_arrows,
  'play': Icons.play_circle_fill,
  'pause': Icons.pause_circle_outline,
  'videocam': Icons.videocam_outlined,
  'image': Icons.image_outlined,
  'folder': Icons.folder_outlined,
  'document': Icons.article_outlined,
  'calendar': Icons.calendar_today_outlined,
  'clock': Icons.schedule,
  'timer': Icons.timer_outlined,
  'speed': Icons.speed,
  'refresh': Icons.refresh,
  'link': Icons.link,
};

class SlideData {
  String id;
  String slideType;
  String title;
  String subtitle;
  TextAlign textAlign;
  bool _isHidden;
  Map<String, dynamic> rawContent;

  bool get isHidden => _isHidden;
  set isHidden(bool value) {
    _isHidden = value;
    if (value) {
      rawContent['isHidden'] = true;
    } else {
      rawContent.remove('isHidden');
      rawContent.remove('hidden');
    }
  }

  SlideData({
    required this.id,
    this.slideType = 'standard',
    required this.title,
    this.subtitle = '',
    this.textAlign = TextAlign.left,
    this._isHidden = false,
    Map<String, dynamic>? rawContent,
  }) : rawContent = rawContent ?? {} {
    if (_isHidden) {
      this.rawContent['isHidden'] = true;
    }
  }

  IconData getIcon(String elementKey, IconData defaultIcon) {
    final iconsMap = rawContent['icons'] as Map<String, dynamic>?;
    if (iconsMap != null) {
      final val = iconsMap[elementKey]?.toString();
      if (val != null && availableIconsMap.containsKey(val)) {
        return availableIconsMap[val]!;
      }
      final baseKey = _extractBaseKey(elementKey);
      final baseVal = iconsMap[baseKey]?.toString();
      if (baseVal != null && availableIconsMap.containsKey(baseVal)) {
        return availableIconsMap[baseVal]!;
      }
    }
    return defaultIcon;
  }

  void setIcon(String elementKey, String iconName) {
    final iconsMap = Map<String, dynamic>.from(rawContent['icons'] as Map<String, dynamic>? ?? {});
    iconsMap[elementKey] = iconName;
    rawContent['icons'] = iconsMap;
  }

  double getFontSize(String elementKey, double defaultSize) {
    final formatting = rawContent['formatting'] as Map<String, dynamic>?;
    final elementFormat = formatting?[elementKey] as Map<String, dynamic>?;
    if (elementFormat != null && elementFormat['fontSize'] != null) {
      return (elementFormat['fontSize'] as num).toDouble();
    }
    final baseKey = _extractBaseKey(elementKey);
    final baseFormat = formatting?[baseKey] as Map<String, dynamic>?;
    if (baseFormat != null && baseFormat['fontSize'] != null) {
      return (baseFormat['fontSize'] as num).toDouble();
    }
    if (elementKey == 'title') {
      return (rawContent['titleFontSize'] as num?)?.toDouble() ?? defaultSize;
    }
    if (elementKey == 'subtitle') {
      return (rawContent['subtitleFontSize'] as num?)?.toDouble() ?? defaultSize;
    }
    return defaultSize;
  }

  FontWeight getFontWeight(String elementKey, FontWeight defaultWeight) {
    final formatting = rawContent['formatting'] as Map<String, dynamic>?;
    final elementFormat = formatting?[elementKey] as Map<String, dynamic>?;
    if (elementFormat != null && elementFormat['fontWeight'] != null) {
      final val = (elementFormat['fontWeight'] as num).toInt();
      return _intToFontWeight(val, defaultWeight);
    }
    final baseKey = _extractBaseKey(elementKey);
    final baseFormat = formatting?[baseKey] as Map<String, dynamic>?;
    if (baseFormat != null && baseFormat['fontWeight'] != null) {
      final val = (baseFormat['fontWeight'] as num).toInt();
      return _intToFontWeight(val, defaultWeight);
    }
    if (elementKey == 'title') return FontWeight.bold;
    return defaultWeight;
  }

  String _extractBaseKey(String key) {
    if (key.startsWith('card_') && key.contains('_bullet_')) return 'card_bullet';
    if (key.startsWith('card_') && key.contains('_outcome_title')) return 'card_outcome_title';
    if (key.startsWith('card_') && key.contains('_outcome_text')) return 'card_outcome_text';
    if (key.startsWith('card_') && key.contains('_outcome_icon')) return 'card_outcome_icon';
    if (key.startsWith('card_') && (key.contains('_subtitle') || key.contains('_sub'))) return 'card_subtitle';
    if (key.startsWith('card_title') || (key.startsWith('card_') && key.contains('_title'))) return 'card_title';
    if (key.startsWith('pilot_step_') && key.contains('_name')) return 'pilot_step_name';
    if (key.startsWith('pilot_step_') && key.contains('_desc')) return 'pilot_step_desc';
    if (key == 'pilot_label') return 'pilot_label';
    if (key == 'pilot_title') return 'pilot_title';
    if (key == 'pilot_subtitle') return 'pilot_subtitle';
    if (key.startsWith('metric_val')) return 'metric_val';
    if (key.startsWith('diagram_label')) return 'diagram_label';
    if (key.startsWith('body')) return 'body';
    if (key.startsWith('title')) return 'title';
    if (key.startsWith('subtitle')) return 'subtitle';
    if (key.startsWith('agent_') && key.contains('_title')) return 'agent_title';
    if (key.startsWith('agent_') && (key.contains('_sub') || key.contains('_subtitle'))) return 'agent_sub';
    if (key.startsWith('agent_') && key.contains('_item_')) return 'agent_item';
    if (key.startsWith('agent_') && key.contains('_icon_')) return 'agent_icon';
    if (key.startsWith('feat_') && key.contains('_title')) return 'feat_title';
    if (key.startsWith('feat_') && (key.contains('_desc') || key.contains('_description'))) return 'feat_desc';
    if (key.startsWith('feat_') && key.contains('_icon')) return 'feat_icon';
    if (key == 'bottom_title' || key == 'bottom_banner_title') return 'bottom_title';
    if (key == 'bottom_sub' || key == 'bottom_banner_sub') return 'bottom_sub';
    if (key.startsWith('ctx_') && key.contains('_title')) return 'ctx_title';
    if (key.startsWith('ctx_') && (key.contains('_desc') || key.contains('_description'))) return 'ctx_desc';
    if (key.startsWith('ctx_') && key.contains('_icon')) return 'ctx_icon';
    if (key.startsWith('act_') && key.contains('_title')) return 'act_title';
    if (key.startsWith('act_') && (key.contains('_desc') || key.contains('_description'))) return 'act_desc';
    if (key.startsWith('act_') && key.contains('_icon')) return 'act_icon';
    if (key.startsWith('wellness_step_') && key.contains('_icon')) return 'wellness_step_icon';
    if (key.startsWith('wellness_step_')) return 'wellness_step';
    if (key == 'wellness_title') return 'wellness_title';
    if (key == 'player_context_title') return 'player_context_title';
    if (key == 'next_best_action_title' || key == 'action_title') return 'next_best_action_title';
    if (key == 'player_experience_title' || key == 'exp_title') return 'player_experience_title';
    if (key.startsWith('card_icon')) return 'card_icon';
    if (key.startsWith('feature_icon')) return 'feature_icon';
    if (key.startsWith('list_icon')) return 'list_icon';
    if (key.startsWith('process_icon')) return 'process_icon';
    if (key.startsWith('eco_icon')) return 'eco_icon';
    if (key.startsWith('sol_icon')) return 'sol_icon';
    if (key.startsWith('arch_arrow_icon')) return 'arch_arrow_icon';
    if (key.startsWith('comp_arrow_icon')) return 'comp_arrow_icon';
    return key;
  }

  FontWeight _intToFontWeight(int val, FontWeight fallback) {
    switch (val) {
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      default:
        return fallback;
    }
  }

  void setFontSize(String elementKey, double size) {
    final formatting = Map<String, dynamic>.from(rawContent['formatting'] as Map<String, dynamic>? ?? {});
    final elementFormat = Map<String, dynamic>.from(formatting[elementKey] as Map<String, dynamic>? ?? {});
    elementFormat['fontSize'] = size;
    formatting[elementKey] = elementFormat;
    rawContent['formatting'] = formatting;

    if (elementKey == 'title') rawContent['titleFontSize'] = size;
    if (elementKey == 'subtitle') rawContent['subtitleFontSize'] = size;
  }

  void setFontWeight(String elementKey, FontWeight weight) {
    final formatting = Map<String, dynamic>.from(rawContent['formatting'] as Map<String, dynamic>? ?? {});
    final elementFormat = Map<String, dynamic>.from(formatting[elementKey] as Map<String, dynamic>? ?? {});
    int val = 400;
    if (weight == FontWeight.w500) val = 500;
    if (weight == FontWeight.w600) val = 600;
    if (weight == FontWeight.w700 || weight == FontWeight.bold) val = 700;
    if (weight == FontWeight.w800) val = 800;
    elementFormat['fontWeight'] = val;
    formatting[elementKey] = elementFormat;
    rawContent['formatting'] = formatting;
  }

  String getDefaultTextFromContent(String elementKey, [String fallback = '']) {
    if (elementKey == 'title') return title.isNotEmpty ? title : fallback;
    if (elementKey == 'subtitle') return subtitle.isNotEmpty ? subtitle : fallback;
    if (elementKey == 'bottom_title' || elementKey == 'bottom_banner_title') {
      final bb = rawContent['bottom_banner'] as Map?;
      if (bb != null && bb['title'] != null) return bb['title'].toString();
      if (rawContent['bottom_banner_title'] != null) return rawContent['bottom_banner_title'].toString();
    }
    if (elementKey == 'bottom_sub' || elementKey == 'bottom_banner_sub') {
      final bb = rawContent['bottom_banner'] as Map?;
      if (bb != null && bb['subtitle'] != null) return bb['subtitle'].toString();
      if (rawContent['bottom_banner_sub'] != null) return rawContent['bottom_banner_sub'].toString();
    }
    if (elementKey.startsWith('agent_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final agentIdx = (int.tryParse(parts[1]) ?? 1) - 1;
        final agentsList = rawContent['agents'] as List?;
        if (agentsList != null && agentIdx >= 0 && agentIdx < agentsList.length && agentsList[agentIdx] is Map) {
          final agentMap = agentsList[agentIdx] as Map;
          if (parts[2] == 'title') return agentMap['title']?.toString() ?? fallback;
          if (parts[2] == 'sub' || parts[2] == 'subtitle') return agentMap['subtitle']?.toString() ?? fallback;
          if (parts[2] == 'item' && parts.length >= 4) {
            final itemIdx = (int.tryParse(parts[3]) ?? 1) - 1;
            final itemsList = agentMap['items'] as List?;
            if (itemsList != null && itemIdx >= 0 && itemIdx < itemsList.length) {
              return itemsList[itemIdx]?.toString() ?? fallback;
            }
          }
        }
      }
    }
    if (elementKey.startsWith('feat_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final featIdx = (int.tryParse(parts[1]) ?? 1) - 1;
        final bb = rawContent['bottom_banner'] as Map?;
        final featuresList = bb?['features'] as List?;
        if (featuresList != null && featIdx >= 0 && featIdx < featuresList.length && featuresList[featIdx] is Map) {
          final featMap = featuresList[featIdx] as Map;
          if (parts[2] == 'title') return featMap['title']?.toString() ?? fallback;
          if (parts[2] == 'desc' || parts[2] == 'description') {
            return featMap['description']?.toString() ?? featMap['desc']?.toString() ?? fallback;
          }
        }
      }
    }
    if (elementKey.startsWith('banner_badge_')) {
      final parts = elementKey.split('_');
      final idx = parts.isNotEmpty ? (int.tryParse(parts.last) ?? 0) : 0;
      final badges = rawContent['badges'] as List?;
      if (badges != null && idx < badges.length) return badges[idx].toString();
    }

    if (elementKey.startsWith('top_title_')) {
      final parts = elementKey.split('_');
      final idx = parts.isNotEmpty ? (int.tryParse(parts.last) ?? 0) : 0;
      final topSteps = rawContent['top_steps'] as List?;
      if (topSteps != null && idx < topSteps.length && topSteps[idx] is Map) return topSteps[idx]['title']?.toString() ?? fallback;
    }
    if (elementKey.startsWith('top_desc_')) {
      final parts = elementKey.split('_');
      final idx = parts.isNotEmpty ? (int.tryParse(parts.last) ?? 0) : 0;
      final topSteps = rawContent['top_steps'] as List?;
      if (topSteps != null && idx < topSteps.length && topSteps[idx] is Map) return topSteps[idx]['description']?.toString() ?? fallback;
    }
    if (elementKey == 'mid_label') {
      final mL = rawContent['missing_layer'] as Map?;
      if (mL != null && mL['label'] != null) return mL['label'].toString();
    }
    if (elementKey.startsWith('mid_title_')) {
      final parts = elementKey.split('_');
      final idx = parts.isNotEmpty ? (int.tryParse(parts.last) ?? 0) : 0;
      final mL = rawContent['missing_layer'] as Map?;
      final steps = mL?['steps'] as List?;
      if (steps != null && idx < steps.length && steps[idx] is Map) return steps[idx]['title']?.toString() ?? fallback;
    }
    if (elementKey.startsWith('mid_desc_')) {
      final parts = elementKey.split('_');
      final idx = parts.isNotEmpty ? (int.tryParse(parts.last) ?? 0) : 0;
      final mL = rawContent['missing_layer'] as Map?;
      final steps = mL?['steps'] as List?;
      if (steps != null && idx < steps.length && steps[idx] is Map) return steps[idx]['description']?.toString() ?? fallback;
    }
    if (elementKey == 'right_mid_title') {
      final rg = (rawContent['missing_layer'] as Map?)?['right_goal'] as Map?;
      if (rg != null && rg['title'] != null) return rg['title'].toString();
    }
    if (elementKey == 'right_mid_desc') {
      final rg = (rawContent['missing_layer'] as Map?)?['right_goal'] as Map?;
      if (rg != null && rg['description'] != null) return rg['description'].toString();
    }
    if (elementKey == 'left_header_title') {
      if (rawContent['left_header_title'] != null) return rawContent['left_header_title'].toString();
    }
    if (elementKey == 'right_header_title') {
      if (rawContent['right_header_title'] != null) return rawContent['right_header_title'].toString();
    }
    if (elementKey.startsWith('exist_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final idx = (int.tryParse(parts[1]) ?? 1) - 1;
        final exList = rawContent['existing_ai_features'] as List?;
        if (exList != null && idx >= 0 && idx < exList.length && exList[idx] is Map) {
          final item = exList[idx] as Map;
          if (parts[2] == 'title') return item['title']?.toString() ?? fallback;
          if (parts[2] == 'sub') return item['sub']?.toString() ?? fallback;
          if (parts[2] == 'desc') return item['desc']?.toString() ?? fallback;
        }
      }
    }
    if (elementKey.startsWith('step_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final idx = (int.tryParse(parts[1]) ?? 1) - 1;
        final jSteps = rawContent['journey_steps'] as List?;
        if (jSteps != null && idx >= 0 && idx < jSteps.length && jSteps[idx] is Map) {
          final item = jSteps[idx] as Map;
          if (parts[2] == 'title') return item['title']?.toString() ?? fallback;
          if (parts[2] == 'desc') return item['desc']?.toString() ?? fallback;
        }
      }
    }
    if (elementKey == 'gap_title') {
      final g = rawContent['gap'] as Map?;
      if (g != null && g['title'] != null) return g['title'].toString();
    }
    if (elementKey == 'gap_text_1') {
      final g = rawContent['gap'] as Map?;
      if (g != null && g['line1'] != null) return g['line1'].toString();
    }
    if (elementKey == 'gap_text_2') {
      final g = rawContent['gap'] as Map?;
      if (g != null && g['line2'] != null) return g['line2'].toString();
    }
    if (elementKey == 'healthmem_title') {
      final hm = rawContent['healthmem'] as Map?;
      if (hm != null && hm['title'] != null) return hm['title'].toString();
    }
    if (elementKey == 'healthmem_sub') {
      final hm = rawContent['healthmem'] as Map?;
      if (hm != null && hm['subtitle'] != null) return hm['subtitle'].toString();
    }
    if (elementKey.startsWith('hm_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final idx = (int.tryParse(parts[1]) ?? 1) - 1;
        final items = (rawContent['healthmem'] as Map?)?['items'] as List?;
        if (items != null && idx >= 0 && idx < items.length && items[idx] is Map) {
          if (parts[2] == 'title') return items[idx]['title']?.toString() ?? fallback;
        }
      }
    }
    if (elementKey == 'result_header_title') {
      final res = rawContent['results'] as Map?;
      if (res != null && res['title'] != null) return res['title'].toString();
    }
    if (elementKey.startsWith('res_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final idx = (int.tryParse(parts[1]) ?? 1) - 1;
        final cards = (rawContent['results'] as Map?)?['cards'] as List?;
        if (cards != null && idx >= 0 && idx < cards.length && cards[idx] is Map) {
          final c = cards[idx] as Map;
          if (parts[2] == 'title') return c['title']?.toString() ?? fallback;
          if (parts[2] == 'desc') return c['description']?.toString() ?? fallback;
        }
      }
    }
    if (elementKey == 'left_sys_header') {
      if (rawContent['left_header_title'] != null) return rawContent['left_header_title'].toString();
    }
    if (elementKey == 'right_out_header') {
      if (rawContent['right_header_title'] != null) return rawContent['right_header_title'].toString();
    }
    if (elementKey == 'wellness_title') {
      final w = rawContent['wellnessgpt'] as Map?;
      if (w != null && w['title'] != null) return w['title'].toString();
    }
    if (elementKey.startsWith('sys_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final idx = (int.tryParse(parts[1]) ?? 1) - 1;
        final sys = rawContent['existing_systems'] as List?;
        if (sys != null && idx >= 0 && idx < sys.length && sys[idx] is Map) {
          final s = sys[idx] as Map;
          if (parts[2] == 'title') return s['title']?.toString() ?? fallback;
          if (parts[2] == 'desc') return s['desc']?.toString() ?? fallback;
        }
      }
    }
    if (elementKey.startsWith('cap_l')) {
      final idx = (int.tryParse(elementKey.replaceAll('cap_l', '').replaceAll('_title', '')) ?? 1) - 1;
      final lCaps = (rawContent['wellnessgpt'] as Map?)?['left_capabilities'] as List?;
      if (lCaps != null && idx >= 0 && idx < lCaps.length && lCaps[idx] is Map) {
        return lCaps[idx]['title']?.toString() ?? fallback;
      }
    }
    if (elementKey.startsWith('cap_r')) {
      final idx = (int.tryParse(elementKey.replaceAll('cap_r', '').replaceAll('_title', '')) ?? 1) - 1;
      final rCaps = (rawContent['wellnessgpt'] as Map?)?['right_capabilities'] as List?;
      if (rCaps != null && idx >= 0 && idx < rCaps.length && rCaps[idx] is Map) {
        return rCaps[idx]['title']?.toString() ?? fallback;
      }
    }
    if (elementKey.startsWith('ag_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final idx = (int.tryParse(parts[1]) ?? 1) - 1;
        final ags = (rawContent['wellnessgpt'] as Map?)?['agents'] as List?;
        if (ags != null && idx >= 0 && idx < ags.length && ags[idx] is Map) {
          return ags[idx]['title']?.toString() ?? fallback;
        }
      }
    }
    if (elementKey.startsWith('out_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final idx = (int.tryParse(parts[1]) ?? 1) - 1;
        final outs = rawContent['outcomes'] as List?;
        if (outs != null && idx >= 0 && idx < outs.length && outs[idx] is Map) {
          final o = outs[idx] as Map;
          if (parts[2] == 'title') return o['title']?.toString() ?? fallback;
          if (parts[2] == 'desc') return o['desc']?.toString() ?? fallback;
        }
      }
    }
    if (elementKey == 'user_data_header') {
      final ud = rawContent['user_data'] as Map?;
      if (ud != null && ud['title'] != null) return ud['title'].toString();
    }
    if (elementKey == 'company_agents_header') {
      final ca = rawContent['company_agents'] as Map?;
      if (ca != null && ca['title'] != null) return ca['title'].toString();
    }
    if (elementKey == 'actions_header') {
      final act = rawContent['actions'] as Map?;
      if (act != null && act['title'] != null) return act['title'].toString();
    }
    if (elementKey == 'brain_sub_label') {
      final b = rawContent['brain'] as Map?;
      if (b != null && b['title'] != null) return b['title'].toString();
    }
    if (elementKey.startsWith('ud_')) {
      final udItems = (rawContent['user_data'] as Map?)?['items'] as List?;
      if (udItems != null) {
        if (elementKey == 'ud_chat_title' && udItems.isNotEmpty && udItems[0] is Map) return udItems[0]['title']?.toString() ?? fallback;
        if (elementKey == 'ud_voice_title' && udItems.length > 1 && udItems[1] is Map) return udItems[1]['title']?.toString() ?? fallback;
        if (elementKey == 'ud_docs_title' && udItems.length > 2 && udItems[2] is Map) return udItems[2]['title']?.toString() ?? fallback;
        if (elementKey == 'ud_archive_title' && udItems.length > 3 && udItems[3] is Map) return udItems[3]['title']?.toString() ?? fallback;
      }
    }
    if (elementKey.startsWith('ca_')) {
      final caItems = (rawContent['company_agents'] as Map?)?['items'] as List?;
      if (caItems != null) {
        if (elementKey == 'ca_agent1_title' && caItems.isNotEmpty && caItems[0] is Map) return caItems[0]['title']?.toString() ?? fallback;
        if (elementKey == 'ca_agent2_title' && caItems.length > 1 && caItems[1] is Map) return caItems[1]['title']?.toString() ?? fallback;
        if (elementKey == 'ca_agent3_title' && caItems.length > 2 && caItems[2] is Map) return caItems[2]['title']?.toString() ?? fallback;
        if (elementKey == 'ca_agent4_title' && caItems.length > 3 && caItems[3] is Map) return caItems[3]['title']?.toString() ?? fallback;
        if (elementKey == 'ca_more_title' && caItems.length > 4 && caItems[4] is Map) return caItems[4]['title']?.toString() ?? fallback;
      }
    }
    if (elementKey.startsWith('act_')) {
      final actItems = (rawContent['actions'] as Map?)?['items'] as List?;
      if (actItems != null) {
        if (elementKey == 'act_remind_title' && actItems.isNotEmpty && actItems[0] is Map) return actItems[0]['title']?.toString() ?? fallback;
        if (elementKey == 'act_follow_title' && actItems.length > 1 && actItems[1] is Map) return actItems[1]['title']?.toString() ?? fallback;
        if (elementKey == 'act_care_title' && actItems.length > 2 && actItems[2] is Map) return actItems[2]['title']?.toString() ?? fallback;
        if (elementKey == 'act_escalate_title' && actItems.length > 3 && actItems[3] is Map) return actItems[3]['title']?.toString() ?? fallback;
      }
    }
    if (elementKey == 'bot_left_title') {
      final bl = rawContent['bottom_left'] as Map?;
      if (bl != null && bl['title'] != null) return bl['title'].toString();
    }
    if (elementKey == 'bot_left_desc') {
      final bl = rawContent['bottom_left'] as Map?;
      if (bl != null && bl['subtitle'] != null) return bl['subtitle'].toString();
    }
    if (elementKey == 'bot_right_title') {
      final br = rawContent['bottom_right'] as Map?;
      if (br != null && br['title'] != null) return br['title'].toString();
    }
    if (elementKey == 'bot_right_desc') {
      final br = rawContent['bottom_right'] as Map?;
      if (br != null && br['subtitle'] != null) return br['subtitle'].toString();
    }
    if (elementKey.startsWith('col_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final colIdx = (int.tryParse(parts[1]) ?? 1) - 1;
        final rawCols = rawContent['columns'] as List?;
        if (rawCols != null && colIdx >= 0 && colIdx < rawCols.length && rawCols[colIdx] is Map) {
          final colMap = rawCols[colIdx] as Map;
          if (parts[2] == 'title') return colMap['step_title']?.toString() ?? colMap['title']?.toString() ?? fallback;
          if (parts[2] == 'desc') return colMap['description']?.toString() ?? fallback;
          if (parts[2] == 'q' && parts.length >= 4 && parts[3] == 'label') {
            return colMap['question_label']?.toString() ?? fallback;
          }
          if (parts[2] == 'q' && parts.length >= 4) {
            final qIdx = (int.tryParse(parts[3]) ?? 1) - 1;
            final dynamic qData = colMap['questions'] ?? colMap['question'];
            final qList = qData is List ? qData : (qData != null ? [qData] : []);
            if (qIdx >= 0 && qIdx < qList.length) {
              return qList[qIdx]?.toString() ?? fallback;
            }
          }
        }
      }
    }
    if (elementKey == 'gap_banner_title') {
      final gapMap = rawContent['gap_banner'] as Map?;
      if (gapMap != null && gapMap['title'] != null) return gapMap['title'].toString();
    }
    if (elementKey == 'gap_banner_desc') {
      final gapMap = rawContent['gap_banner'] as Map?;
      if (gapMap != null && gapMap['description'] != null) return gapMap['description'].toString();
    }
    if (elementKey.startsWith('gap_issue_')) {
      final parts = elementKey.split('_');
      final issueIdx = (int.tryParse(parts.last) ?? 1) - 1;
      final gapMap = rawContent['gap_banner'] as Map?;
      final issueList = gapMap?['issues'] as List?;
      if (issueList != null && issueIdx >= 0 && issueIdx < issueList.length) {
        return issueList[issueIdx]?.toString() ?? fallback;
      }
    }
    if (elementKey == 'guided_journey_header') {
      final gj = rawContent['guided_journey'] as Map?;
      if (gj != null && gj['title'] != null) return gj['title'].toString();
    }
    if (elementKey.startsWith('gj_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final stepIdx = (int.tryParse(parts[1]) ?? 1) - 1;
        final steps = (rawContent['guided_journey'] as Map?)?['steps'] as List?;
        if (steps != null && stepIdx >= 0 && stepIdx < steps.length && steps[stepIdx] is Map) {
          final s = steps[stepIdx] as Map;
          if (parts[2] == 'title') return s['title']?.toString() ?? fallback;
          if (parts[2] == 'sub' || parts[2] == 'subtitle') return s['subtitle']?.toString() ?? fallback;
        }
      }
    }
    if (elementKey == 'bottom_banner_text') {
      final bb = rawContent['bottom_banner'] as Map?;
      if (bb != null && bb['title'] != null) return bb['title'].toString();
    }
    if (elementKey.startsWith('bottom_step_')) {
      final parts = elementKey.split('_');
      final stepIdx = (int.tryParse(parts.last) ?? 1) - 1;
      final steps = (rawContent['bottom_banner'] as Map?)?['flow_steps'] as List?;
      if (steps != null && stepIdx >= 0 && stepIdx < steps.length) {
        return steps[stepIdx]?.toString() ?? fallback;
      }
    }
    if (elementKey.startsWith('card_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final cardIdx = (int.tryParse(parts[1]) ?? 1) - 1;
        final relCards = rawContent['cards'] as List?;
        if (relCards != null && cardIdx >= 0 && cardIdx < relCards.length && relCards[cardIdx] is Map) {
          final c = relCards[cardIdx] as Map;
          if (parts[2] == 'title' && parts.length == 3) return c['title']?.toString() ?? fallback;
          if (parts[2] == 'subtitle' || parts[2] == 'sub') return c['subtitle']?.toString() ?? fallback;
          if (parts[2] == 'today' && parts.length >= 4 && parts[3] == 'text') return c['today_text']?.toString() ?? fallback;
          if (parts[2] == 'opp' && parts.length >= 4 && parts[3] == 'text') return c['opp_text']?.toString() ?? fallback;
          if (parts[2] == 'bullet' && parts.length >= 4) {
            final bIdx = (int.tryParse(parts[3]) ?? 1) - 1;
            final bullets = c['bullets'] as List?;
            if (bullets != null && bIdx >= 0 && bIdx < bullets.length) {
              return bullets[bIdx]?.toString() ?? fallback;
            }
          }
          if (parts[2] == 'outcome') {
            final rawKO = c['key_outcomes'] ?? c['key_outcome'] ?? c['outcome'] ?? c['outcomes'];
            if (parts.length >= 4 && parts[3] == 'title') {
              if (rawKO is Map) {
                return (rawKO['title'] ?? rawKO['label'] ?? rawKO['heading'] ?? rawKO['name'])?.toString() ?? 'KEY OUTCOMES';
              }
              return 'KEY OUTCOMES';
            }
            if (parts.length >= 4 && parts[3] == 'text') {
              if (rawKO is Map) {
                return (rawKO['outcomes_text'] ?? rawKO['outcomesText'] ?? rawKO['text'] ?? rawKO['value'] ?? rawKO['description'])?.toString() ?? fallback;
              } else if (rawKO is String) {
                return rawKO;
              } else if (rawKO is List) {
                return rawKO.map((e) => e is Map ? (e['text'] ?? e['value'] ?? e['title'] ?? e.toString()).toString() : e.toString()).join('  |  ');
              } else if (c['outcomes_text'] != null) {
                return c['outcomes_text'].toString();
              }
            }
          }
        }
      }
    }
    if (elementKey == 'player_context_title') {
      final m = rawContent['player_context'] as Map?;
      if (m != null) return m['title']?.toString() ?? fallback;
    }
    if (elementKey.startsWith('ctx_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final idx = (int.tryParse(parts[1]) ?? 1) - 1;
        final ctxItems = (rawContent['player_context'] as Map?)?['items'] as List?;
        if (ctxItems != null && idx >= 0 && idx < ctxItems.length && ctxItems[idx] is Map) {
          final item = ctxItems[idx] as Map;
          if (parts[2] == 'title') return item['title']?.toString() ?? fallback;
          if (parts[2] == 'desc' || parts[2] == 'description') return item['description']?.toString() ?? item['desc']?.toString() ?? fallback;
        }
      }
    }
    if (elementKey == 'wellness_title') {
      final m = rawContent['wellnessgpt'] as Map?;
      if (m != null) return m['title']?.toString() ?? fallback;
    }
    if (elementKey.startsWith('wellness_step_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final idx = (int.tryParse(parts[2]) ?? 1) - 1;
        final steps = (rawContent['wellnessgpt'] as Map?)?['steps'] as List?;
        if (steps != null && idx >= 0 && idx < steps.length) {
          return steps[idx].toString();
        }
      }
    }
    if (elementKey == 'next_best_action_title' || elementKey == 'action_title') {
      final m = rawContent['next_best_action'] as Map?;
      if (m != null) return m['title']?.toString() ?? fallback;
    }
    if (elementKey.startsWith('act_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final idx = (int.tryParse(parts[1]) ?? 1) - 1;
        final actItems = (rawContent['next_best_action'] as Map?)?['items'] as List?;
        if (actItems != null && idx >= 0 && idx < actItems.length && actItems[idx] is Map) {
          final item = actItems[idx] as Map;
          if (parts[2] == 'title') return item['title']?.toString() ?? fallback;
          if (parts[2] == 'desc' || parts[2] == 'description') return item['description']?.toString() ?? item['desc']?.toString() ?? fallback;
        }
      }
    }
    if (elementKey == 'player_experience_title' || elementKey == 'exp_title') {
      final m = rawContent['player_experience'] as Map?;
      if (m != null) return m['title']?.toString() ?? fallback;
    }
    if (elementKey.startsWith('pilot_')) {
      final pMap = rawContent['pilot_opportunity'] as Map?;
      if (pMap != null) {
        if (elementKey == 'pilot_label') return pMap['label']?.toString() ?? fallback;
        if (elementKey == 'pilot_title') return pMap['title']?.toString() ?? fallback;
        if (elementKey == 'pilot_subtitle') return pMap['subtitle']?.toString() ?? fallback;
        if (elementKey.startsWith('pilot_step_')) {
          final parts = elementKey.split('_');
          if (parts.length >= 4) {
            final sIdx = (int.tryParse(parts[2]) ?? 1) - 1;
            final steps = pMap['steps'] as List?;
            if (steps != null && sIdx >= 0 && sIdx < steps.length && steps[sIdx] is Map) {
              final step = steps[sIdx] as Map;
              if (parts[3] == 'name') return step['step_name']?.toString() ?? step['name']?.toString() ?? fallback;
              if (parts[3] == 'desc') return step['step_desc']?.toString() ?? step['desc']?.toString() ?? step['description']?.toString() ?? fallback;
            }
          }
        }
      }
    }
    if (elementKey.startsWith('bot_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final cardIdx = int.tryParse(parts[1]) ?? 0;
        final bCards = rawContent['bottom_cards'] as List?;
        if (bCards != null && cardIdx < bCards.length && bCards[cardIdx] is Map) {
          final card = bCards[cardIdx] as Map;
          if (parts[2] == 'title') return card['title']?.toString() ?? fallback;
          if (parts[2] == 'bullet' && parts.length >= 4) {
            final bulletIdx = int.tryParse(parts[3]) ?? 0;
            final bullets = card['bullets'] as List?;
            if (bullets != null && bulletIdx < bullets.length) return bullets[bulletIdx].toString();
          }
        }
      }
    }

    final metrics = rawContent['metrics'] as List?;
    final items = rawContent['items'] as List?;
    final stages = rawContent['stages'] as List?;
    final features = rawContent['features'] as List?;
    final cards = rawContent['cards'] as List?;
    final flow = rawContent['flow'] as List?;
    final caps = rawContent['capabilities'] as List?;
    final comp = rawContent['comparison'] as List?;

    int? getIndex(String key) {
      final parts = key.split('_');
      if (parts.isNotEmpty) {
        return int.tryParse(parts.last);
      }
      return null;
    }

    if (elementKey.startsWith('metric_val')) {
      final idx = getIndex(elementKey) ?? 0;
      if (metrics != null && idx < metrics.length && metrics[idx] is Map) {
        return metrics[idx]['value']?.toString() ?? fallback;
      }
    }

    if (elementKey.startsWith('card_title')) {
      if (elementKey == 'card_title_left') return (rawContent['left'] as Map?)?['label']?.toString() ?? fallback;
      if (elementKey == 'card_title_center') return (rawContent['center'] as Map?)?['label']?.toString() ?? fallback;
      if (elementKey == 'card_title_right') return (rawContent['right'] as Map?)?['label']?.toString() ?? fallback;
      if (elementKey == 'card_title_ingress') return (rawContent['architecture'] as Map?)?['ingress']?.toString() ?? 'API Gateway Ingest';
      if (elementKey == 'card_title_core') return (rawContent['architecture'] as Map?)?['core']?.toString() ?? 'Intelligent Intent Analysis Agentic Orchestration Engine';
      if (elementKey == 'card_title_pain') {
        final rawCS = rawContent['currentState'];
        if (rawCS is Map) {
          return rawCS['title']?.toString() ?? rawCS['header']?.toString() ?? 'Current State';
        }
        return 'Current State';
      }
      if (elementKey == 'card_title_solution') {
        final rawSol = rawContent['solution'];
        if (rawSol is Map) {
          return rawSol['title']?.toString() ?? rawSol['header']?.toString() ?? 'HeyDoc AI Solution';
        }
        return 'HeyDoc AI Solution';
      }
      if (elementKey == 'card_title_intro') return 'ORCHESTRATION CAPABILITIES';
      if (elementKey == 'card_title_agents') return 'ACTIVE AI AGENTS';
      if (elementKey == 'card_title_works') return 'IN-WORKS / ALPHA';

      final idx = getIndex(elementKey) ?? 0;
      if (metrics != null && idx < metrics.length && metrics[idx] is Map) return metrics[idx]['title']?.toString() ?? fallback;
      if (items != null && idx < items.length && items[idx] is Map) return items[idx]['title']?.toString() ?? fallback;
      if (stages != null && idx < stages.length && stages[idx] is Map) return stages[idx]['title']?.toString() ?? fallback;
      if (cards != null && idx < cards.length && cards[idx] is Map) return cards[idx]['title']?.toString() ?? fallback;
      if (features != null && idx < features.length && features[idx] is Map) return features[idx]['title']?.toString() ?? fallback;
      if (flow != null && idx < flow.length && flow[idx] is Map) return flow[idx]['stage']?.toString() ?? fallback;
      if (caps != null && idx < caps.length && caps[idx] is Map) return caps[idx]['title']?.toString() ?? fallback;
      if (comp != null && idx < comp.length && comp[idx] is Map) return comp[idx]['title']?.toString() ?? fallback;
    }

    if (elementKey.startsWith('body')) {
      if (elementKey == 'body_left') return (rawContent['left'] as Map?)?['description']?.toString() ?? fallback;
      if (elementKey == 'body_center') return (rawContent['center'] as Map?)?['description']?.toString() ?? fallback;
      if (elementKey == 'body_right') return (rawContent['right'] as Map?)?['description']?.toString() ?? fallback;
      if (elementKey == 'body_phone') return (rawContent['contact'] as Map?)?['phone']?.toString() ?? fallback;
      if (elementKey == 'body_email') return (rawContent['contact'] as Map?)?['email']?.toString() ?? fallback;

      if (elementKey.startsWith('body_agent_')) {
        final idx = getIndex(elementKey) ?? 0;
        final agents = (rawContent['architecture'] as Map?)?['agents'] as List?;
        if (agents != null && idx < agents.length) return agents[idx].toString();
      }
      if (elementKey.startsWith('body_pain_')) {
        final idx = getIndex(elementKey) ?? 0;
        final painItems = _extractSolutionMappingItems(rawContent['currentState']);
        if (idx < painItems.length) return _formatSolutionMappingItemText(painItems[idx]);
      }
      if (elementKey.startsWith('body_solution_')) {
        final idx = getIndex(elementKey) ?? 0;
        final solItems = _extractSolutionMappingItems(rawContent['solution']);
        if (idx < solItems.length) return _formatSolutionMappingItemText(solItems[idx]);
      }
      if (elementKey.startsWith('body_intro_')) {
        final idx = getIndex(elementKey) ?? 0;
        final list = rawContent['intro'] as List?;
        if (list != null && idx < list.length) return list[idx].toString();
      }
      if (elementKey.startsWith('body_agents_')) {
        final idx = getIndex(elementKey) ?? 0;
        final list = rawContent['agents'] as List?;
        if (list != null && idx < list.length) return list[idx].toString();
      }
      if (elementKey.startsWith('body_works_')) {
        final idx = getIndex(elementKey) ?? 0;
        final list = rawContent['inWorks'] as List?;
        if (list != null && idx < list.length) return list[idx].toString();
      }

      final idx = getIndex(elementKey) ?? 0;
      if (metrics != null && idx < metrics.length && metrics[idx] is Map) return metrics[idx]['description']?.toString() ?? fallback;
      if (items != null && idx < items.length && items[idx] is Map) return items[idx]['description']?.toString() ?? fallback;
      if (stages != null && idx < stages.length && stages[idx] is Map) return stages[idx]['description']?.toString() ?? fallback;
      if (cards != null && idx < cards.length && cards[idx] is Map) return cards[idx]['description']?.toString() ?? fallback;
      if (features != null && idx < features.length) {
        final item = features[idx];
        if (item is Map) return item['description']?.toString() ?? fallback;
        return item.toString();
      }
      if (flow != null && idx < flow.length && flow[idx] is Map) return flow[idx]['description']?.toString() ?? fallback;
      if (comp != null && idx < comp.length && comp[idx] is Map) return comp[idx]['description']?.toString() ?? fallback;
    }

    if (elementKey.startsWith('diagram_label')) {
      if (elementKey.startsWith('diagram_label_channel_')) {
        final idx = getIndex(elementKey) ?? 0;
        final list = (rawContent['architecture'] as Map?)?['userChannels'] as List?;
        if (list != null && idx < list.length) return list[idx].toString();
      }
      final parts = elementKey.split('_');
      if (parts.length >= 4) {
        final mainIdx = int.tryParse(parts[2]);
        final subIdx = int.tryParse(parts[3]);
        if (mainIdx != null && subIdx != null) {
          if (flow != null && mainIdx < flow.length && flow[mainIdx] is Map) {
            final agList = flow[mainIdx]['agents'] as List?;
            if (agList != null && subIdx < agList.length) return agList[subIdx].toString();
          }
          if (caps != null && mainIdx < caps.length && caps[mainIdx] is Map) {
            final agList = caps[mainIdx]['agents'] as List?;
            if (agList != null && subIdx < agList.length) return agList[subIdx].toString();
          }
        }
      }

      final idx = getIndex(elementKey) ?? 0;
      if (stages != null && idx < stages.length && stages[idx] is Map) return stages[idx]['label']?.toString() ?? fallback;
      final videos = rawContent['productVideos'] as List?;
      if (videos != null && idx < videos.length) return videos[idx].toString();
    }

    return fallback;
  }

  String getElementText(String elementKey, [String defaultText = '']) {
    final overrides = rawContent['text_overrides'] as Map<String, dynamic>?;
    if (overrides != null && overrides[elementKey] != null) {
      return overrides[elementKey].toString();
    }
    final textFromContent = getDefaultTextFromContent(elementKey, defaultText);
    if (textFromContent.isNotEmpty) {
      return textFromContent;
    }
    if (elementKey == 'title') return title;
    if (elementKey == 'subtitle') return subtitle;
    return defaultText;
  }

  void setElementText(String elementKey, String text) {
    bool handledDirectly = false;

    if (elementKey == 'title') {
      title = text;
      rawContent['title'] = text;
      handledDirectly = true;
    } else if (elementKey == 'subtitle') {
      subtitle = text;
      rawContent['subtitle'] = text;
      handledDirectly = true;
    } else if (elementKey == 'bottom_title' || elementKey == 'bottom_banner_title') {
      final bb = Map<String, dynamic>.from(rawContent['bottom_banner'] as Map? ?? {});
      bb['title'] = text;
      rawContent['bottom_banner'] = bb;
      rawContent['bottom_banner_title'] = text;
      handledDirectly = true;
    } else if (elementKey == 'bottom_sub' || elementKey == 'bottom_banner_sub') {
      final bb = Map<String, dynamic>.from(rawContent['bottom_banner'] as Map? ?? {});
      bb['subtitle'] = text;
      rawContent['bottom_banner'] = bb;
      rawContent['bottom_banner_sub'] = text;
      handledDirectly = true;
    } else if (elementKey.startsWith('agent_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final agentIdx = (int.tryParse(parts[1]) ?? 1) - 1;
        final rawAgents = List<dynamic>.from(rawContent['agents'] as List? ?? []);
        while (rawAgents.length <= agentIdx) {
          rawAgents.add({'title': '', 'subtitle': '', 'items': <dynamic>[]});
        }
        final agentMap = Map<String, dynamic>.from(rawAgents[agentIdx] is Map ? rawAgents[agentIdx] as Map : {});
        if (parts[2] == 'title') {
          agentMap['title'] = text;
          rawAgents[agentIdx] = agentMap;
          rawContent['agents'] = rawAgents;
          handledDirectly = true;
        } else if (parts[2] == 'sub' || parts[2] == 'subtitle') {
          agentMap['subtitle'] = text;
          rawAgents[agentIdx] = agentMap;
          rawContent['agents'] = rawAgents;
          handledDirectly = true;
        } else if (parts[2] == 'item' && parts.length >= 4) {
          final itemIdx = (int.tryParse(parts[3]) ?? 1) - 1;
          final rawItems = List<dynamic>.from(agentMap['items'] as List? ?? []);
          while (rawItems.length <= itemIdx) {
            rawItems.add('');
          }
          rawItems[itemIdx] = text;
          agentMap['items'] = rawItems;
          rawAgents[agentIdx] = agentMap;
          rawContent['agents'] = rawAgents;
          handledDirectly = true;
        }
      }
    } else if (elementKey.startsWith('feat_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final featIdx = (int.tryParse(parts[1]) ?? 1) - 1;
        final bb = Map<String, dynamic>.from(rawContent['bottom_banner'] as Map? ?? {});
        final rawFeatures = List<dynamic>.from(bb['features'] as List? ?? []);
        while (rawFeatures.length <= featIdx) {
          rawFeatures.add({'title': '', 'description': ''});
        }
        final featMap = Map<String, dynamic>.from(rawFeatures[featIdx] is Map ? rawFeatures[featIdx] as Map : {});
        if (parts[2] == 'title') {
          featMap['title'] = text;
          rawFeatures[featIdx] = featMap;
          bb['features'] = rawFeatures;
          rawContent['bottom_banner'] = bb;
          handledDirectly = true;
        } else if (parts[2] == 'desc' || parts[2] == 'description') {
          featMap['description'] = text;
          rawFeatures[featIdx] = featMap;
          bb['features'] = rawFeatures;
          rawContent['bottom_banner'] = bb;
          handledDirectly = true;
        }
      }
    } else if (elementKey == 'user_data_header') {
      final m = Map<String, dynamic>.from(rawContent['user_data'] as Map? ?? {});
      m['title'] = text;
      rawContent['user_data'] = m;
      handledDirectly = true;
    } else if (elementKey == 'company_agents_header') {
      final m = Map<String, dynamic>.from(rawContent['company_agents'] as Map? ?? {});
      m['title'] = text;
      rawContent['company_agents'] = m;
      handledDirectly = true;
    } else if (elementKey == 'actions_header') {
      final m = Map<String, dynamic>.from(rawContent['actions'] as Map? ?? {});
      m['title'] = text;
      rawContent['actions'] = m;
      handledDirectly = true;
    } else if (elementKey == 'brain_sub_label') {
      final m = Map<String, dynamic>.from(rawContent['brain'] as Map? ?? {});
      m['title'] = text;
      rawContent['brain'] = m;
      handledDirectly = true;
    } else if (elementKey.startsWith('banner_badge_')) {
      final parts = elementKey.split('_');
      final idx = parts.isNotEmpty ? (int.tryParse(parts.last) ?? 0) : 0;
      final badges = List<String>.from(rawContent['badges'] as List? ?? []);
      while (badges.length <= idx) {
        badges.add('');
      }
      badges[idx] = text;
      rawContent['badges'] = badges;
      handledDirectly = true;
    } else if (elementKey.startsWith('card_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final cardIdx = (int.tryParse(parts[1]) ?? 1) - 1;
        final rawCards = List<dynamic>.from(rawContent['cards'] as List? ?? []);
        if (cardIdx >= 0 && cardIdx < rawCards.length && rawCards[cardIdx] is Map) {
          final c = Map<String, dynamic>.from(rawCards[cardIdx] as Map);
          if (parts[2] == 'title' && parts.length == 3) {
            c['title'] = text;
            rawCards[cardIdx] = c;
            rawContent['cards'] = rawCards;
            handledDirectly = true;
          } else if (parts[2] == 'subtitle' || parts[2] == 'sub') {
            c['subtitle'] = text;
            rawCards[cardIdx] = c;
            rawContent['cards'] = rawCards;
            handledDirectly = true;
          } else if (parts[2] == 'today' && parts.length >= 4 && parts[3] == 'text') {
            c['today_text'] = text;
            rawCards[cardIdx] = c;
            rawContent['cards'] = rawCards;
            handledDirectly = true;
          } else if (parts[2] == 'opp' && parts.length >= 4 && parts[3] == 'text') {
            c['opp_text'] = text;
            rawCards[cardIdx] = c;
            rawContent['cards'] = rawCards;
            handledDirectly = true;
          } else if (parts[2] == 'bullet' && parts.length >= 4) {
            final bIdx = (int.tryParse(parts[3]) ?? 1) - 1;
            final bullets = List<dynamic>.from(c['bullets'] as List? ?? []);
            while (bullets.length <= bIdx) {
              bullets.add('');
            }
            bullets[bIdx] = text;
            c['bullets'] = bullets;
            rawCards[cardIdx] = c;
            rawContent['cards'] = rawCards;
            handledDirectly = true;
          } else if (parts[2] == 'outcome') {
            final rawKO = c['key_outcomes'] ?? c['key_outcome'] ?? c['outcome'] ?? c['outcomes'];
            if (parts.length >= 4 && parts[3] == 'title') {
              if (rawKO is Map) {
                final koMap = Map<String, dynamic>.from(rawKO);
                koMap['title'] = text;
                c['key_outcomes'] = koMap;
              } else {
                c['key_outcomes'] = {'title': text, 'outcomes_text': rawKO?.toString() ?? ''};
              }
              rawCards[cardIdx] = c;
              rawContent['cards'] = rawCards;
              handledDirectly = true;
            } else if (parts.length >= 4 && parts[3] == 'text') {
              if (rawKO is Map) {
                final koMap = Map<String, dynamic>.from(rawKO);
                koMap['outcomes_text'] = text;
                c['key_outcomes'] = koMap;
              } else if (c.containsKey('outcomes_text')) {
                c['outcomes_text'] = text;
              } else {
                c['key_outcomes'] = {'outcomes_text': text};
              }
              rawCards[cardIdx] = c;
              rawContent['cards'] = rawCards;
              handledDirectly = true;
            }
          }
        }
      }
    } else if (elementKey.startsWith('pilot_')) {
      final pMap = Map<String, dynamic>.from(rawContent['pilot_opportunity'] as Map? ?? {});
      if (elementKey == 'pilot_label') {
        pMap['label'] = text;
        rawContent['pilot_opportunity'] = pMap;
        handledDirectly = true;
      } else if (elementKey == 'pilot_title') {
        pMap['title'] = text;
        rawContent['pilot_opportunity'] = pMap;
        handledDirectly = true;
      } else if (elementKey == 'pilot_subtitle') {
        pMap['subtitle'] = text;
        rawContent['pilot_opportunity'] = pMap;
        handledDirectly = true;
      } else if (elementKey.startsWith('pilot_step_')) {
        final parts = elementKey.split('_');
        if (parts.length >= 4) {
          final sIdx = (int.tryParse(parts[2]) ?? 1) - 1;
          final steps = List<dynamic>.from(pMap['steps'] as List? ?? []);
          while (steps.length <= sIdx) {
            steps.add({'step_name': '', 'step_desc': ''});
          }
          final s = Map<String, dynamic>.from(steps[sIdx] is Map ? steps[sIdx] as Map : {});
          if (parts[3] == 'name') {
            s['step_name'] = text;
            steps[sIdx] = s;
            pMap['steps'] = steps;
            rawContent['pilot_opportunity'] = pMap;
            handledDirectly = true;
          } else if (parts[3] == 'desc') {
            s['step_desc'] = text;
            steps[sIdx] = s;
            pMap['steps'] = steps;
            rawContent['pilot_opportunity'] = pMap;
            handledDirectly = true;
          }
        }
      }
    } else if (elementKey == 'player_context_title') {
      final m = Map<String, dynamic>.from(rawContent['player_context'] as Map? ?? {});
      m['title'] = text;
      rawContent['player_context'] = m;
      handledDirectly = true;
    } else if (elementKey.startsWith('ctx_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final idx = (int.tryParse(parts[1]) ?? 1) - 1;
        final pCtx = Map<String, dynamic>.from(rawContent['player_context'] as Map? ?? {});
        final rawItems = List<dynamic>.from(pCtx['items'] as List? ?? []);
        while (rawItems.length <= idx) {
          rawItems.add({'title': '', 'description': ''});
        }
        final itemMap = Map<String, dynamic>.from(rawItems[idx] is Map ? rawItems[idx] as Map : {});
        if (parts[2] == 'title') {
          itemMap['title'] = text;
          rawItems[idx] = itemMap;
          pCtx['items'] = rawItems;
          rawContent['player_context'] = pCtx;
          handledDirectly = true;
        } else if (parts[2] == 'desc' || parts[2] == 'description') {
          itemMap['description'] = text;
          rawItems[idx] = itemMap;
          pCtx['items'] = rawItems;
          rawContent['player_context'] = pCtx;
          handledDirectly = true;
        }
      }
    } else if (elementKey == 'wellness_title') {
      final m = Map<String, dynamic>.from(rawContent['wellnessgpt'] as Map? ?? {});
      m['title'] = text;
      rawContent['wellnessgpt'] = m;
      handledDirectly = true;
    } else if (elementKey.startsWith('wellness_step_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final idx = (int.tryParse(parts[2]) ?? 1) - 1;
        final wGpt = Map<String, dynamic>.from(rawContent['wellnessgpt'] as Map? ?? {});
        final rawSteps = List<dynamic>.from(wGpt['steps'] as List? ?? []);
        while (rawSteps.length <= idx) {
          rawSteps.add('');
        }
        rawSteps[idx] = text;
        wGpt['steps'] = rawSteps;
        rawContent['wellnessgpt'] = wGpt;
        handledDirectly = true;
      }
    } else if (elementKey == 'next_best_action_title' || elementKey == 'action_title') {
      final m = Map<String, dynamic>.from(rawContent['next_best_action'] as Map? ?? {});
      m['title'] = text;
      rawContent['next_best_action'] = m;
      handledDirectly = true;
    } else if (elementKey.startsWith('act_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final idx = (int.tryParse(parts[1]) ?? 1) - 1;
        final nAct = Map<String, dynamic>.from(rawContent['next_best_action'] as Map? ?? {});
        final rawItems = List<dynamic>.from(nAct['items'] as List? ?? []);
        while (rawItems.length <= idx) {
          rawItems.add({'title': '', 'description': ''});
        }
        final itemMap = Map<String, dynamic>.from(rawItems[idx] is Map ? rawItems[idx] as Map : {});
        if (parts[2] == 'title') {
          itemMap['title'] = text;
          rawItems[idx] = itemMap;
          nAct['items'] = rawItems;
          rawContent['next_best_action'] = nAct;
          handledDirectly = true;
        } else if (parts[2] == 'desc' || parts[2] == 'description') {
          itemMap['description'] = text;
          rawItems[idx] = itemMap;
          nAct['items'] = rawItems;
          rawContent['next_best_action'] = nAct;
          handledDirectly = true;
        }
      }
    } else if (elementKey == 'player_experience_title' || elementKey == 'exp_title') {
      final m = Map<String, dynamic>.from(rawContent['player_experience'] as Map? ?? {});
      m['title'] = text;
      rawContent['player_experience'] = m;
      handledDirectly = true;
    }

    int? getIndex(String key) {
      final parts = key.split('_');
      if (parts.isNotEmpty) return int.tryParse(parts.last);
      return null;
    }

    // Directly update the underlying data structures inside rawContent so presentation.json stores direct edits
    if (elementKey == 'card_title_left') {
      final m = Map<String, dynamic>.from(rawContent['left'] as Map? ?? {});
      m['label'] = text;
      rawContent['left'] = m;
      handledDirectly = true;
    } else if (elementKey == 'body_left') {
      final m = Map<String, dynamic>.from(rawContent['left'] as Map? ?? {});
      m['description'] = text;
      rawContent['left'] = m;
      handledDirectly = true;
    } else if (elementKey == 'card_title_center') {
      final m = Map<String, dynamic>.from(rawContent['center'] as Map? ?? {});
      m['label'] = text;
      rawContent['center'] = m;
      handledDirectly = true;
    } else if (elementKey == 'body_center') {
      final m = Map<String, dynamic>.from(rawContent['center'] as Map? ?? {});
      m['description'] = text;
      rawContent['center'] = m;
      handledDirectly = true;
    } else if (elementKey == 'card_title_right') {
      final m = Map<String, dynamic>.from(rawContent['right'] as Map? ?? {});
      m['label'] = text;
      rawContent['right'] = m;
      handledDirectly = true;
    } else if (elementKey == 'body_right') {
      final m = Map<String, dynamic>.from(rawContent['right'] as Map? ?? {});
      m['description'] = text;
      rawContent['right'] = m;
      handledDirectly = true;
    } else if (elementKey == 'card_title_pain') {
      final m = Map<String, dynamic>.from(rawContent['currentState'] as Map? ?? {});
      m['title'] = text;
      rawContent['currentState'] = m;
      handledDirectly = true;
    } else if (elementKey == 'card_title_solution') {
      final m = Map<String, dynamic>.from(rawContent['solution'] as Map? ?? {});
      m['title'] = text;
      rawContent['solution'] = m;
      handledDirectly = true;
    } else if (elementKey == 'body_phone') {
      final m = Map<String, dynamic>.from(rawContent['contact'] as Map? ?? {});
      m['phone'] = text;
      rawContent['contact'] = m;
      handledDirectly = true;
    } else if (elementKey == 'body_email') {
      final m = Map<String, dynamic>.from(rawContent['contact'] as Map? ?? {});
      m['email'] = text;
      rawContent['contact'] = m;
      handledDirectly = true;
    } else if (elementKey.startsWith('col_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final colIdx = (int.tryParse(parts[1]) ?? 1) - 1;
        final rawCols = List<dynamic>.from(rawContent['columns'] as List? ?? []);
        if (colIdx >= 0 && colIdx < rawCols.length && rawCols[colIdx] is Map) {
          final colMap = Map<String, dynamic>.from(rawCols[colIdx] as Map);
          if (parts[2] == 'title') {
            colMap['step_title'] = text;
            rawCols[colIdx] = colMap;
            rawContent['columns'] = rawCols;
            handledDirectly = true;
          } else if (parts[2] == 'desc') {
            colMap['description'] = text;
            rawCols[colIdx] = colMap;
            rawContent['columns'] = rawCols;
            handledDirectly = true;
          } else if (parts[2] == 'q' && parts.length >= 4 && parts[3] == 'label') {
            colMap['question_label'] = text;
            rawCols[colIdx] = colMap;
            rawContent['columns'] = rawCols;
            handledDirectly = true;
          } else if (parts[2] == 'q' && parts.length >= 4) {
            final qIdx = (int.tryParse(parts[3]) ?? 1) - 1;
            final dynamic qData = colMap['questions'] ?? colMap['question'];
            final qList = List<dynamic>.from(qData is List ? qData : (qData != null ? [qData] : []));
            while (qList.length <= qIdx) {
              qList.add('');
            }
            qList[qIdx] = text;
            colMap['questions'] = qList;
            rawCols[colIdx] = colMap;
            rawContent['columns'] = rawCols;
            handledDirectly = true;
          }
        }
      }
    } else if (elementKey == 'gap_banner_title') {
      final gapMap = Map<String, dynamic>.from(rawContent['gap_banner'] as Map? ?? {});
      gapMap['title'] = text;
      rawContent['gap_banner'] = gapMap;
      handledDirectly = true;
    } else if (elementKey == 'gap_banner_desc') {
      final gapMap = Map<String, dynamic>.from(rawContent['gap_banner'] as Map? ?? {});
      gapMap['description'] = text;
      rawContent['gap_banner'] = gapMap;
      handledDirectly = true;
    } else if (elementKey.startsWith('gap_issue_')) {
      final parts = elementKey.split('_');
      final issueIdx = (int.tryParse(parts.last) ?? 1) - 1;
      final gapMap = Map<String, dynamic>.from(rawContent['gap_banner'] as Map? ?? {});
      final issueList = List<dynamic>.from(gapMap['issues'] as List? ?? []);
      while (issueList.length <= issueIdx) {
        issueList.add('');
      }
      issueList[issueIdx] = text;
      gapMap['issues'] = issueList;
      rawContent['gap_banner'] = gapMap;
      handledDirectly = true;
    } else if (elementKey == 'guided_journey_header') {
      final gj = Map<String, dynamic>.from(rawContent['guided_journey'] as Map? ?? {});
      gj['title'] = text;
      rawContent['guided_journey'] = gj;
      handledDirectly = true;
    } else if (elementKey.startsWith('gj_')) {
      final parts = elementKey.split('_');
      if (parts.length >= 3) {
        final stepIdx = (int.tryParse(parts[1]) ?? 1) - 1;
        final gj = Map<String, dynamic>.from(rawContent['guided_journey'] as Map? ?? {});
        final steps = List<dynamic>.from(gj['steps'] as List? ?? []);
        while (steps.length <= stepIdx) {
          steps.add({'step': '${steps.length + 1}', 'title': '', 'subtitle': ''});
        }
        final sMap = Map<String, dynamic>.from(steps[stepIdx] is Map ? steps[stepIdx] as Map : {});
        if (parts[2] == 'title') {
          sMap['title'] = text;
        } else if (parts[2] == 'sub' || parts[2] == 'subtitle') {
          sMap['subtitle'] = text;
        }
        steps[stepIdx] = sMap;
        gj['steps'] = steps;
        rawContent['guided_journey'] = gj;
        handledDirectly = true;
      }
    } else if (elementKey == 'bottom_banner_text') {
      final bb = Map<String, dynamic>.from(rawContent['bottom_banner'] as Map? ?? {});
      bb['title'] = text;
      rawContent['bottom_banner'] = bb;
      handledDirectly = true;
    } else if (elementKey.startsWith('bottom_step_')) {
      final parts = elementKey.split('_');
      final stepIdx = (int.tryParse(parts.last) ?? 1) - 1;
      final bb = Map<String, dynamic>.from(rawContent['bottom_banner'] as Map? ?? {});
      final steps = List<dynamic>.from(bb['flow_steps'] as List? ?? []);
      while (steps.length <= stepIdx) {
        steps.add('');
      }
      steps[stepIdx] = text;
      bb['flow_steps'] = steps;
      rawContent['bottom_banner'] = bb;
      handledDirectly = true;
    } else if (elementKey.startsWith('ud_')) {
      final idx = getIndex(elementKey);
      final ud = Map<String, dynamic>.from(rawContent['user_data'] as Map? ?? {});
      final items = List<dynamic>.from(ud['items'] as List? ?? []);
      if (idx != null && idx < items.length) {
        if (items[idx] is Map) {
          final m = Map<String, dynamic>.from(items[idx] as Map);
          m['title'] = text;
          items[idx] = m;
        } else {
          items[idx] = {'title': text};
        }
        ud['items'] = items;
        rawContent['user_data'] = ud;
        handledDirectly = true;
      }
    } else if (elementKey.startsWith('ca_')) {
      final idx = getIndex(elementKey);
      final ca = Map<String, dynamic>.from(rawContent['company_agents'] as Map? ?? {});
      final items = List<dynamic>.from(ca['items'] as List? ?? []);
      if (idx != null && idx < items.length) {
        if (items[idx] is Map) {
          final m = Map<String, dynamic>.from(items[idx] as Map);
          m['title'] = text;
          items[idx] = m;
        } else {
          items[idx] = {'title': text};
        }
        ca['items'] = items;
        rawContent['company_agents'] = ca;
        handledDirectly = true;
      }
    } else if (elementKey.startsWith('act_')) {
      final idx = getIndex(elementKey);
      final act = Map<String, dynamic>.from(rawContent['actions'] as Map? ?? {});
      final items = List<dynamic>.from(act['items'] as List? ?? []);
      if (idx != null && idx < items.length) {
        if (items[idx] is Map) {
          final m = Map<String, dynamic>.from(items[idx] as Map);
          m['title'] = text;
          items[idx] = m;
        } else {
          items[idx] = {'title': text};
        }
        act['items'] = items;
        rawContent['actions'] = act;
        handledDirectly = true;
      }
    } else if (elementKey.startsWith('metric_val_')) {
      final idx = getIndex(elementKey);
      final metrics = List<dynamic>.from(rawContent['metrics'] as List? ?? []);
      if (idx != null && idx < metrics.length && metrics[idx] is Map) {
        final m = Map<String, dynamic>.from(metrics[idx] as Map);
        m['value'] = text;
        metrics[idx] = m;
        rawContent['metrics'] = metrics;
        handledDirectly = true;
      }
    } else if (elementKey.startsWith('card_title_')) {
      final idx = getIndex(elementKey);
      if (idx != null) {
        if (rawContent['metrics'] is List) {
          final list = List<dynamic>.from(rawContent['metrics'] as List);
          if (idx < list.length && list[idx] is Map) {
            final m = Map<String, dynamic>.from(list[idx] as Map);
            m['title'] = text;
            list[idx] = m;
            rawContent['metrics'] = list;
            handledDirectly = true;
          }
        }
        if (rawContent['items'] is List) {
          final list = List<dynamic>.from(rawContent['items'] as List);
          if (idx < list.length && list[idx] is Map) {
            final m = Map<String, dynamic>.from(list[idx] as Map);
            m['title'] = text;
            list[idx] = m;
            rawContent['items'] = list;
            handledDirectly = true;
          }
        }
        if (rawContent['stages'] is List) {
          final list = List<dynamic>.from(rawContent['stages'] as List);
          if (idx < list.length && list[idx] is Map) {
            final m = Map<String, dynamic>.from(list[idx] as Map);
            m['title'] = text;
            list[idx] = m;
            rawContent['stages'] = list;
            handledDirectly = true;
          }
        }
        if (rawContent['cards'] is List) {
          final list = List<dynamic>.from(rawContent['cards'] as List);
          if (idx < list.length && list[idx] is Map) {
            final m = Map<String, dynamic>.from(list[idx] as Map);
            m['title'] = text;
            list[idx] = m;
            rawContent['cards'] = list;
            handledDirectly = true;
          }
        }
        if (rawContent['comparison'] is List) {
          final list = List<dynamic>.from(rawContent['comparison'] as List);
          if (idx < list.length && list[idx] is Map) {
            final m = Map<String, dynamic>.from(list[idx] as Map);
            m['title'] = text;
            list[idx] = m;
            rawContent['comparison'] = list;
            handledDirectly = true;
          }
        }
      }
    } else if (elementKey.startsWith('body_intro_')) {
      final idx = getIndex(elementKey);
      final list = List<dynamic>.from(rawContent['intro'] as List? ?? []);
      if (idx != null && idx < list.length) {
        list[idx] = text;
        rawContent['intro'] = list;
        handledDirectly = true;
      }
    } else if (elementKey.startsWith('body_agents_')) {
      final idx = getIndex(elementKey);
      final list = List<dynamic>.from(rawContent['agents'] as List? ?? []);
      if (idx != null && idx < list.length) {
        list[idx] = text;
        rawContent['agents'] = list;
        handledDirectly = true;
      }
    } else if (elementKey.startsWith('body_works_')) {
      final idx = getIndex(elementKey);
      final list = List<dynamic>.from(rawContent['inWorks'] as List? ?? []);
      if (idx != null && idx < list.length) {
        list[idx] = text;
        rawContent['inWorks'] = list;
        handledDirectly = true;
      }
    } else if (elementKey.startsWith('body_pain_')) {
      final idx = getIndex(elementKey);
      if (idx != null) {
        final rawCS = rawContent['currentState'];
        if (rawCS is Map) {
          final cs = Map<String, dynamic>.from(rawCS);
          final list = _extractSolutionMappingItems(cs);
          if (idx < list.length) {
            final mutableList = List<dynamic>.from(list);
            if (mutableList[idx] is Map) {
              final itemMap = Map<String, dynamic>.from(mutableList[idx] as Map);
              if (itemMap.containsKey('description')) {
                itemMap['description'] = text;
              } else if (itemMap.containsKey('title')) {
                itemMap['title'] = text;
              } else {
                itemMap['text'] = text;
              }
              mutableList[idx] = itemMap;
            } else {
              mutableList[idx] = text;
            }
            cs['items'] = mutableList;
            rawContent['currentState'] = cs;
            handledDirectly = true;
          }
        } else if (rawCS is List) {
          final list = List<dynamic>.from(rawCS);
          if (idx < list.length) {
            list[idx] = text;
            rawContent['currentState'] = list;
            handledDirectly = true;
          }
        }
      }
    } else if (elementKey.startsWith('body_solution_')) {
      final idx = getIndex(elementKey);
      if (idx != null) {
        final rawSol = rawContent['solution'];
        if (rawSol is Map) {
          final sol = Map<String, dynamic>.from(rawSol);
          final list = _extractSolutionMappingItems(sol);
          if (idx < list.length) {
            final mutableList = List<dynamic>.from(list);
            if (mutableList[idx] is Map) {
              final itemMap = Map<String, dynamic>.from(mutableList[idx] as Map);
              if (itemMap.containsKey('description')) {
                itemMap['description'] = text;
              } else if (itemMap.containsKey('title')) {
                itemMap['title'] = text;
              } else {
                itemMap['text'] = text;
              }
              mutableList[idx] = itemMap;
            } else {
              mutableList[idx] = text;
            }
            sol['items'] = mutableList;
            rawContent['solution'] = sol;
            handledDirectly = true;
          }
        } else if (rawSol is List) {
          final list = List<dynamic>.from(rawSol);
          if (idx < list.length) {
            list[idx] = text;
            rawContent['solution'] = list;
            handledDirectly = true;
          }
        }
      }
    } else if (elementKey.startsWith('body_')) {
      final idx = getIndex(elementKey);
      if (idx != null) {
        if (rawContent['metrics'] is List) {
          final list = List<dynamic>.from(rawContent['metrics'] as List);
          if (idx < list.length && list[idx] is Map) {
            final m = Map<String, dynamic>.from(list[idx] as Map);
            m['description'] = text;
            list[idx] = m;
            rawContent['metrics'] = list;
            handledDirectly = true;
          }
        }
        if (rawContent['items'] is List) {
          final list = List<dynamic>.from(rawContent['items'] as List);
          if (idx < list.length && list[idx] is Map) {
            final m = Map<String, dynamic>.from(list[idx] as Map);
            m['description'] = text;
            list[idx] = m;
            rawContent['items'] = list;
            handledDirectly = true;
          }
        }
        if (rawContent['stages'] is List) {
          final list = List<dynamic>.from(rawContent['stages'] as List);
          if (idx < list.length && list[idx] is Map) {
            final m = Map<String, dynamic>.from(list[idx] as Map);
            m['description'] = text;
            list[idx] = m;
            rawContent['stages'] = list;
            handledDirectly = true;
          }
        }
        if (rawContent['cards'] is List) {
          final list = List<dynamic>.from(rawContent['cards'] as List);
          if (idx < list.length && list[idx] is Map) {
            final m = Map<String, dynamic>.from(list[idx] as Map);
            m['description'] = text;
            list[idx] = m;
            rawContent['cards'] = list;
            handledDirectly = true;
          }
        }
        if (rawContent['features'] is List) {
          final list = List<dynamic>.from(rawContent['features'] as List);
          if (idx < list.length) {
            if (list[idx] is Map) {
              final m = Map<String, dynamic>.from(list[idx] as Map);
              m['description'] = text;
              list[idx] = m;
            } else {
              list[idx] = text;
            }
            rawContent['features'] = list;
            handledDirectly = true;
          }
        }
        if (rawContent['comparison'] is List) {
          final list = List<dynamic>.from(rawContent['comparison'] as List);
          if (idx < list.length && list[idx] is Map) {
            final m = Map<String, dynamic>.from(list[idx] as Map);
            m['description'] = text;
            list[idx] = m;
            rawContent['comparison'] = list;
            handledDirectly = true;
          }
        }
      }
    } else if (elementKey.startsWith('diagram_label_')) {
      final idx = getIndex(elementKey);
      if (idx != null) {
        if (rawContent['stages'] is List) {
          final list = List<dynamic>.from(rawContent['stages'] as List);
          if (idx < list.length && list[idx] is Map) {
            final m = Map<String, dynamic>.from(list[idx] as Map);
            m['label'] = text;
            list[idx] = m;
            rawContent['stages'] = list;
            handledDirectly = true;
          }
        }
        if (rawContent['productVideos'] is List) {
          final list = List<dynamic>.from(rawContent['productVideos'] as List);
          if (idx < list.length) {
            list[idx] = text;
            rawContent['productVideos'] = list;
            handledDirectly = true;
          }
        }
      }
    }

    final overrides = Map<String, dynamic>.from(rawContent['text_overrides'] as Map<String, dynamic>? ?? {});
    if (handledDirectly || elementKey == 'title' || elementKey == 'subtitle') {
      overrides.remove(elementKey);
    } else {
      overrides[elementKey] = text;
    }
    if (overrides.isEmpty) {
      rawContent.remove('text_overrides');
    } else {
      rawContent['text_overrides'] = overrides;
    }
  }

  bool hasImageOverride(String key) {
    final overrides = rawContent['image_overrides'] as Map<String, dynamic>?;
    return overrides != null && overrides.containsKey(key);
  }

  String getImagePath(String key, [String fallback = '']) {
    final overrides = rawContent['image_overrides'] as Map<String, dynamic>?;
    if (overrides != null && overrides.containsKey(key)) {
      final val = overrides[key].toString();
      return val == 'none' ? '' : val;
    }
    if (rawContent[key] != null && rawContent[key].toString().isNotEmpty) {
      final val = rawContent[key].toString();
      return val == 'none' ? '' : val;
    }
    // Fallback to legacy single-image keys only if key is generic or single-image layout
    if (!key.contains('_') || key == 'image_path' || key == 'hero_image' || key == 'mockup_image' || key == 'feature_image' || key == 'mobile_image') {
      if (rawContent['image_path'] != null && rawContent['image_path'].toString().isNotEmpty) {
        final val = rawContent['image_path'].toString();
        return val == 'none' ? '' : val;
      }
      if (rawContent['hero_image'] != null && rawContent['hero_image'].toString().isNotEmpty) {
        final val = rawContent['hero_image'].toString();
        return val == 'none' ? '' : val;
      }
      if (rawContent['imageUrl'] != null && rawContent['imageUrl'].toString().isNotEmpty) {
        final val = rawContent['imageUrl'].toString();
        return val == 'none' ? '' : val;
      }
    }
    return fallback;
  }

  void setImagePath(String key, String path) {
    final overrides = Map<String, dynamic>.from(rawContent['image_overrides'] as Map<String, dynamic>? ?? {});
    
    // Non-image state keys (like slot counts, layout settings, slot types, or slot order) should be stored directly in rawContent, not in image_overrides
    if (key.endsWith('_count') || key.endsWith('_layout') || key.endsWith('_mode') || key.endsWith('_type') || key.endsWith('_order')) {
      overrides.remove(key);
      if (overrides.isEmpty) {
        rawContent.remove('image_overrides');
      } else {
        rawContent['image_overrides'] = overrides;
      }
      if (path.isEmpty) {
        rawContent.remove(key);
      } else {
        rawContent[key] = path;
      }
      return;
    }

    final valToStore = path.isEmpty ? 'none' : path;
    overrides[key] = valToStore;
    rawContent[key] = valToStore;
    if (key == 'image_path' || key == 'hero_image' || key == 'mockup_image' || key == 'feature_image' || key == 'mobile_image') {
      rawContent['image_path'] = valToStore;
    }
    rawContent['image_overrides'] = overrides;
  }

  /// Completely flushes all data associated with a custom slide slot (image, type, order, card title/subtitle, font styles).
  void flushCustomSlot(int slotIndex) {
    // 1. Flush image overrides and rawContent image keys
    final imageOverrides = Map<String, dynamic>.from(rawContent['image_overrides'] as Map<String, dynamic>? ?? {});
    imageOverrides.remove('custom_image_$slotIndex');
    rawContent.remove('custom_image_$slotIndex');
    if (slotIndex == 0) {
      imageOverrides.remove('custom_image_0');
      imageOverrides.remove('custom_image');
      rawContent.remove('custom_image_0');
      rawContent.remove('custom_image');
    }
    if (imageOverrides.isEmpty) {
      rawContent.remove('image_overrides');
    } else {
      rawContent['image_overrides'] = imageOverrides;
    }

    // 2. Flush slot configurations
    rawContent.remove('custom_slot_${slotIndex}_type');
    rawContent.remove('custom_slot_${slotIndex}_order');

    // 3. Flush text card overrides
    final titleKey = 'card_${slotIndex + 1}_title';
    final subtitleKey = 'card_${slotIndex + 1}_subtitle';

    final textOverrides = Map<String, dynamic>.from(rawContent['text_overrides'] as Map<String, dynamic>? ?? {});
    textOverrides.remove(titleKey);
    textOverrides.remove(subtitleKey);
    if (textOverrides.isEmpty) {
      rawContent.remove('text_overrides');
    } else {
      rawContent['text_overrides'] = textOverrides;
    }

    // 4. Flush font size overrides
    final fontSizeOverrides = Map<String, dynamic>.from(rawContent['font_size_overrides'] as Map<String, dynamic>? ?? {});
    fontSizeOverrides.remove(titleKey);
    fontSizeOverrides.remove(subtitleKey);
    if (fontSizeOverrides.isEmpty) {
      rawContent.remove('font_size_overrides');
    } else {
      rawContent['font_size_overrides'] = fontSizeOverrides;
    }

    // 5. Flush font weight overrides
    final fontWeightOverrides = Map<String, dynamic>.from(rawContent['font_weight_overrides'] as Map<String, dynamic>? ?? {});
    fontWeightOverrides.remove(titleKey);
    fontWeightOverrides.remove(subtitleKey);
    if (fontWeightOverrides.isEmpty) {
      rawContent.remove('font_weight_overrides');
    } else {
      rawContent['font_weight_overrides'] = fontWeightOverrides;
    }
  }

  /// Copies all data from one custom slot to another.
  void copyCustomSlotData({required int fromIndex, required int toIndex}) {
    // 1. Copy image
    final fromImagePath = getImagePath(fromIndex == 0 ? 'custom_image' : 'custom_image_$fromIndex');
    if (fromImagePath.isNotEmpty) {
      setImagePath(toIndex == 0 ? 'custom_image' : 'custom_image_$toIndex', fromImagePath);
      if (toIndex == 0) {
        setImagePath('custom_image_0', fromImagePath);
      }
    } else {
      final overrides = Map<String, dynamic>.from(rawContent['image_overrides'] as Map<String, dynamic>? ?? {});
      overrides.remove('custom_image_$toIndex');
      rawContent.remove('custom_image_$toIndex');
      if (toIndex == 0) {
        overrides.remove('custom_image_0');
        overrides.remove('custom_image');
        rawContent.remove('custom_image_0');
        rawContent.remove('custom_image');
      }
      if (overrides.isEmpty) {
        rawContent.remove('image_overrides');
      } else {
        rawContent['image_overrides'] = overrides;
      }
    }

    // 2. Copy slot type & order
    final type = rawContent['custom_slot_${fromIndex}_type']?.toString();
    if (type != null && type.isNotEmpty) {
      rawContent['custom_slot_${toIndex}_type'] = type;
    } else {
      rawContent.remove('custom_slot_${toIndex}_type');
    }

    final order = rawContent['custom_slot_${fromIndex}_order']?.toString();
    if (order != null && order.isNotEmpty) {
      rawContent['custom_slot_${toIndex}_order'] = order;
    } else {
      rawContent.remove('custom_slot_${toIndex}_order');
    }

    // 3. Copy text overrides
    final fromTitleKey = 'card_${fromIndex + 1}_title';
    final fromSubKey = 'card_${fromIndex + 1}_subtitle';
    final toTitleKey = 'card_${toIndex + 1}_title';
    final toSubKey = 'card_${toIndex + 1}_subtitle';

    final textOverrides = Map<String, dynamic>.from(rawContent['text_overrides'] as Map<String, dynamic>? ?? {});
    if (textOverrides.containsKey(fromTitleKey)) {
      textOverrides[toTitleKey] = textOverrides[fromTitleKey];
    } else {
      textOverrides.remove(toTitleKey);
    }
    if (textOverrides.containsKey(fromSubKey)) {
      textOverrides[toSubKey] = textOverrides[fromSubKey];
    } else {
      textOverrides.remove(toSubKey);
    }
    if (textOverrides.isEmpty) {
      rawContent.remove('text_overrides');
    } else {
      rawContent['text_overrides'] = textOverrides;
    }

    // 4. Copy font size overrides
    final fontSizeOverrides = Map<String, dynamic>.from(rawContent['font_size_overrides'] as Map<String, dynamic>? ?? {});
    if (fontSizeOverrides.containsKey(fromTitleKey)) {
      fontSizeOverrides[toTitleKey] = fontSizeOverrides[fromTitleKey];
    } else {
      fontSizeOverrides.remove(toTitleKey);
    }
    if (fontSizeOverrides.containsKey(fromSubKey)) {
      fontSizeOverrides[toSubKey] = fontSizeOverrides[fromSubKey];
    } else {
      fontSizeOverrides.remove(toSubKey);
    }
    if (fontSizeOverrides.isEmpty) {
      rawContent.remove('font_size_overrides');
    } else {
      rawContent['font_size_overrides'] = fontSizeOverrides;
    }

    // 5. Copy font weight overrides
    final fontWeightOverrides = Map<String, dynamic>.from(rawContent['font_weight_overrides'] as Map<String, dynamic>? ?? {});
    if (fontWeightOverrides.containsKey(fromTitleKey)) {
      fontWeightOverrides[toTitleKey] = fontWeightOverrides[fromTitleKey];
    } else {
      fontWeightOverrides.remove(toTitleKey);
    }
    if (fontWeightOverrides.containsKey(fromSubKey)) {
      fontWeightOverrides[toSubKey] = fontWeightOverrides[fromSubKey];
    } else {
      fontWeightOverrides.remove(toSubKey);
    }
    if (fontWeightOverrides.isEmpty) {
      rawContent.remove('font_weight_overrides');
    } else {
      rawContent['font_weight_overrides'] = fontWeightOverrides;
    }
  }

  /// Deletes a custom slot at removeIndex, shifts following slots, flushes vacated tail slots, and decrements count.
  void deleteCustomSlot(int removeIndex) {
    int currentCount = 1;
    final rawCount = rawContent['custom_images_count'];
    if (rawCount is int) currentCount = rawCount.clamp(1, 6);
    if (rawCount is String) currentCount = (int.tryParse(rawCount) ?? 1).clamp(1, 6);

    if (currentCount <= 1) {
      flushCustomSlot(0);
      rawContent['custom_images_count'] = '1';
      return;
    }

    // Shift remaining slots forward
    for (int i = removeIndex; i < currentCount - 1; i++) {
      copyCustomSlotData(fromIndex: i + 1, toIndex: i);
    }

    // Flush vacated tail slots and any slots beyond the new count
    for (int s = currentCount - 1; s < 6; s++) {
      flushCustomSlot(s);
    }

    rawContent['custom_images_count'] = '${currentCount - 1}';
  }

  factory SlideData.fromJson(Map<String, dynamic> json, [Map<String, dynamic>? manifestSlideSettings]) {
    final content = Map<String, dynamic>.from(json['content'] as Map<String, dynamic>? ?? {});
    if (manifestSlideSettings != null) {
      manifestSlideSettings.forEach((k, v) {
        if (!content.containsKey(k) || content[k] == null || content[k].toString().isEmpty) {
          content[k] = v;
        }
      });
    }

    final slideTypeStr = json['slideType'] as String? ?? 'standard';
    final defaultAlign = (slideTypeStr == 'thank_you') ? 'center' : 'left';
    final alignStr = (content['textAlign'] ?? manifestSlideSettings?['textAlign']) as String? ?? defaultAlign;
    TextAlign align = TextAlign.left;
    if (alignStr == 'center') {
      align = TextAlign.center;
    } else if (alignStr == 'right') {
      align = TextAlign.right;
    }

    final isHidden = json['isHidden'] == true ||
        json['hidden'] == true ||
        content['isHidden'] == true ||
        manifestSlideSettings?['isHidden'] == true;

    content.remove('notes');

    final isCustom = slideTypeStr == 'custom_slide';
    final defaultTitle = isCustom ? 'Lorem Ipsum' : 'Untitled Slide';
    final defaultSubtitle = isCustom ? 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.' : '';

    final rawTitle = content['title'] as String?;
    final title = (rawTitle != null && rawTitle.trim().isNotEmpty) ? rawTitle : defaultTitle;
    final rawSubtitle = content['subtitle'] as String?;
    final subtitle = (rawSubtitle != null && rawSubtitle.trim().isNotEmpty) ? rawSubtitle : defaultSubtitle;

    return SlideData(
      id: json['id'] as String? ?? 'slide_000',
      slideType: slideTypeStr,
      title: title,
      subtitle: subtitle,
      textAlign: align,
      isHidden: isHidden,
      rawContent: content,
    );
  }

  Map<String, dynamic> toJson() {
    final updatedContent = Map<String, dynamic>.from(rawContent);
    updatedContent['title'] = title;
    updatedContent['subtitle'] = subtitle;
    updatedContent.remove('notes');
    updatedContent.remove('textAlign');

    return {
      'id': id,
      'slideType': slideType,
      'content': updatedContent,
    };
  }
}

/// Mouse Interactive Selectable Text Box Wrapper for Canvas Editing
class SelectableTextElement extends StatefulWidget {
  final String elementKey;
  final String label;
  final Widget child;
  final String? selectedElementKey;
  final Function(String key)? onSelectElement;

  const SelectableTextElement({
    super.key,
    required this.elementKey,
    required this.label,
    required this.child,
    this.selectedElementKey,
    this.onSelectElement,
  });

  @override
  State<SelectableTextElement> createState() => _SelectableTextElementState();
}

class _SelectableTextElementState extends State<SelectableTextElement> {
  bool _isHovered = false;

  String get baseKey {
    return _getBaseKey(widget.elementKey);
  }

  static String _getBaseKey(String key) {
    if (key.startsWith('card_') && key.contains('_bullet_')) return 'card_bullet';
    if (key.startsWith('card_') && key.contains('_outcome_title')) return 'card_outcome_title';
    if (key.startsWith('card_') && key.contains('_outcome_text')) return 'card_outcome_text';
    if (key.startsWith('card_') && (key.contains('_subtitle') || key.contains('_sub'))) return 'card_subtitle';
    if (key.startsWith('card_title') || (key.startsWith('card_') && key.contains('_title'))) return 'card_title';
    if (key.startsWith('pilot_step_') && key.contains('_name')) return 'pilot_step_name';
    if (key.startsWith('pilot_step_') && key.contains('_desc')) return 'pilot_step_desc';
    if (key == 'pilot_label') return 'pilot_label';
    if (key == 'pilot_title') return 'pilot_title';
    if (key == 'pilot_subtitle') return 'pilot_subtitle';
    if (key.startsWith('metric_val')) return 'metric_val';
    if (key.startsWith('diagram_label')) return 'diagram_label';
    if (key.startsWith('body')) return 'body';
    if (key.startsWith('title')) return 'title';
    if (key.startsWith('subtitle')) return 'subtitle';
    if (key.startsWith('agent_') && key.contains('_title')) return 'agent_title';
    if (key.startsWith('agent_') && (key.contains('_sub') || key.contains('_subtitle'))) return 'agent_sub';
    if (key.startsWith('agent_') && key.contains('_item_')) return 'agent_item';
    if (key.startsWith('feat_') && key.contains('_title')) return 'feat_title';
    if (key.startsWith('feat_') && (key.contains('_desc') || key.contains('_description'))) return 'feat_desc';
    if (key.startsWith('ctx_') && key.contains('_title')) return 'ctx_title';
    if (key.startsWith('ctx_') && (key.contains('_desc') || key.contains('_description'))) return 'ctx_desc';
    if (key.startsWith('act_') && key.contains('_title')) return 'act_title';
    if (key.startsWith('act_') && (key.contains('_desc') || key.contains('_description'))) return 'act_desc';
    if (key.startsWith('wellness_step_')) return 'wellness_step';
    if (key == 'wellness_title') return 'wellness_title';
    if (key == 'player_context_title') return 'player_context_title';
    if (key == 'next_best_action_title' || key == 'action_title') return 'next_best_action_title';
    if (key == 'player_experience_title' || key == 'exp_title') return 'player_experience_title';
    if (key == 'bottom_title' || key == 'bottom_banner_title') return 'bottom_title';
    if (key == 'bottom_sub' || key == 'bottom_banner_sub') return 'bottom_sub';
    return key;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onSelectElement == null) {
      return widget.child;
    }

    final isSelected = widget.selectedElementKey == widget.elementKey ||
        widget.selectedElementKey == baseKey;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final selKey = widget.selectedElementKey;
          if (selKey == baseKey) {
            // Clicked again while all items of this base type are selected -> switch to specific element
            widget.onSelectElement!(widget.elementKey);
          } else if (selKey != null && _getBaseKey(selKey) == baseKey) {
            // Already in specific element mode for this type -> switch to clicked specific element
            widget.onSelectElement!(widget.elementKey);
          } else {
            // First click on this element type -> select all items of this type
            widget.onSelectElement!(baseKey);
          }
        },
        onDoubleTap: () {
          // Double click directly selects specific element
          widget.onSelectElement!(widget.elementKey);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1877F2)
                  : (_isHovered
                      ? const Color(0xFF1877F2).withValues(alpha: 0.5)
                      : Colors.transparent),
              width: isSelected ? 2.0 : 1.0,
            ),
            color: isSelected
                ? const Color(0xFF1877F2).withValues(alpha: 0.08)
                : (_isHovered ? Colors.blue.withValues(alpha: 0.03) : Colors.transparent),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Mouse Interactive Selectable Icon Wrapper for Canvas Editing
class SelectableIconElement extends StatefulWidget {
  final String elementKey;
  final String label;
  final IconData icon;
  final double size;
  final Color color;
  final String? selectedElementKey;
  final Function(String key)? onSelectElement;

  const SelectableIconElement({
    super.key,
    required this.elementKey,
    required this.label,
    required this.icon,
    this.size = 18,
    required this.color,
    this.selectedElementKey,
    this.onSelectElement,
  });

  @override
  State<SelectableIconElement> createState() => _SelectableIconElementState();
}

class _SelectableIconElementState extends State<SelectableIconElement> {
  bool _isHovered = false;

  String get baseKey {
    return _getBaseKey(widget.elementKey);
  }

  static String _getBaseKey(String key) {
    if (key.startsWith('card_') && key.contains('_outcome_icon')) return 'card_outcome_icon';
    if (key.startsWith('card_icon')) return 'card_icon';
    if (key.startsWith('feature_icon')) return 'feature_icon';
    if (key.startsWith('list_icon')) return 'list_icon';
    if (key.startsWith('process_icon')) return 'process_icon';
    if (key.startsWith('eco_icon')) return 'eco_icon';
    if (key.startsWith('sol_icon')) return 'sol_icon';
    if (key.startsWith('arch_arrow_icon')) return 'arch_arrow_icon';
    if (key.startsWith('comp_arrow_icon')) return 'comp_arrow_icon';
    if (key.startsWith('agent_') && key.contains('_icon_')) return 'agent_icon';
    if (key.startsWith('feat_') && key.contains('_icon')) return 'feat_icon';
    if (key.startsWith('ctx_') && key.contains('_icon')) return 'ctx_icon';
    if (key.startsWith('act_') && key.contains('_icon')) return 'act_icon';
    if (key.startsWith('wellness_step_') && key.contains('_icon')) return 'wellness_step_icon';
    if (key.startsWith('icon')) return 'icon';
    return key;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onSelectElement == null) {
      return Icon(widget.icon, size: widget.size, color: widget.color);
    }

    final isSelected = widget.selectedElementKey == widget.elementKey ||
        widget.selectedElementKey == baseKey;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final selKey = widget.selectedElementKey;
          if (selKey == baseKey) {
            widget.onSelectElement!(widget.elementKey);
          } else if (selKey != null && _getBaseKey(selKey) == baseKey) {
            widget.onSelectElement!(widget.elementKey);
          } else {
            widget.onSelectElement!(baseKey);
          }
        },
        onDoubleTap: () {
          widget.onSelectElement!(widget.elementKey);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1877F2)
                  : (_isHovered
                      ? const Color(0xFF1877F2).withValues(alpha: 0.5)
                      : Colors.transparent),
              width: isSelected ? 1.8 : 1.0,
            ),
            color: isSelected
                ? const Color(0xFF1877F2).withValues(alpha: 0.12)
                : (_isHovered
                    ? const Color(0xFF1877F2).withValues(alpha: 0.05)
                    : Colors.transparent),
          ),
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

/// Unified Virtual 16:9 Slide Canvas (1920 x 1080 Fixed Proportional Space)
class VirtualSlideFrame extends StatelessWidget {
  final SlideData slide;
  final PresentationModel presentation;
  final Color accentColor;
  final int slideIndex;
  final int totalSlides;
  final String? selectedElementKey;
  final Function(String key)? onSelectElement;
  final VoidCallback? onDeselect;
  final Function(String imageKey, String path)? onImageChanged;

  const VirtualSlideFrame({
    super.key,
    required this.slide,
    required this.presentation,
    required this.accentColor,
    required this.slideIndex,
    required this.totalSlides,
    this.selectedElementKey,
    this.onSelectElement,
    this.onDeselect,
    this.onImageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? Colors.white : const Color(0xFF282828);

    return SizedBox(
      width: 1920,
      height: 1080,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (onDeselect != null) onDeselect!();
        },
        child: Container(
          color: cardBg,
          padding: const EdgeInsets.all(56),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Logo (HeyDoc x Company), Sector / Company badge, Slide Type, Slide Counter
            Row(
              children: [
                _buildHeyDocLogo(height: 38),

                if (presentation.logoPath.isNotEmpty || presentation.companyName.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '×',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  if (presentation.logoPath.isNotEmpty)
                    Container(
                      height: 38,
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: buildUniversalImage(
                        presentation.logoPath,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        presentationId: presentation.id,
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 24,
                          width: 6,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          presentation.companyName.toUpperCase(),
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Slide ${slideIndex + 1}',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Main Slide Layout Body
            Expanded(
              child: RenderSlideContent(
                slide: slide,
                accentColor: accentColor,
                isEditing: false,
                folderPath: presentation.folderPath,
                companyLogoPath: presentation.logoPath,
                companyName: presentation.companyName,
                selectedElementKey: selectedElementKey,
                onSelectElement: onSelectElement,
                onImageChanged: onImageChanged,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

/// Live Scaled Slide Thumbnail Widget for Left Sidebar
class SlideThumbnailWidget extends StatelessWidget {
  final SlideData slide;
  final PresentationModel presentation;
  final Color accentColor;
  final int slideIndex;
  final int totalSlides;
  final bool isSelected;

  const SlideThumbnailWidget({
    super.key,
    required this.slide,
    required this.presentation,
    required this.accentColor,
    required this.slideIndex,
    required this.totalSlides,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? Colors.white : const Color(0xFF282828);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF1877F2)
              : (isLight ? const Color(0xFFD1D5DB) : const Color(0xFF444444)),
          width: isSelected ? 2.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF1877F2).withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: isLight ? 0.05 : 0.2),
            blurRadius: isSelected ? 6 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: FittedBox(
            fit: BoxFit.contain,
            child: IgnorePointer(
              child: VirtualSlideFrame(
                slide: slide,
                presentation: presentation,
                accentColor: accentColor,
                slideIndex: slideIndex,
                totalSlides: totalSlides,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Typedef so legacy calls continue working without breaking changes
typedef ImageDropzoneWidget = ImagePickerWidget;

/// Helper to overlay dynamic text (e.g. caller ID name) onto dynamic preset assets
Widget buildDynamicPresetOverlay(String path, Widget baseImage, String? companyName) {
  if (!path.contains('Call Screen') && !path.contains('dynamic_presets')) {
    return baseImage;
  }
  final effectiveCompanyName = (companyName != null && companyName.trim().isNotEmpty)
      ? companyName.trim()
      : 'HeyDoc';
  final callerText = '$effectiveCompanyName AI Care';

  return Stack(
    children: [
      baseImage,
      Positioned.fill(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned(
                  top: constraints.maxHeight * 0.265,
                  left: constraints.maxWidth * 0.08,
                  right: constraints.maxWidth * 0.08,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        callerText,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (constraints.maxHeight * 0.038).clamp(10.0, 24.0),
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ],
  );
}

/// Upgraded Interactive Image Asset Picker Widget with Presets & Upload Popup Modal
class ImagePickerWidget extends StatefulWidget {
  final String label;
  final String formatHint;
  final double height;
  final bool isMobileFrame;
  final String? initialImagePath;
  final String? folderPath;
  final String? slideId;
  final String? imageKey;
  final String? companyName;
  final ValueChanged<String>? onImageSelected;

  const ImagePickerWidget({
    super.key,
    this.label = 'Select Image',
    this.formatHint = 'Presets or Upload Custom',
    this.height = 180,
    this.isMobileFrame = false,
    this.initialImagePath,
    this.folderPath,
    this.slideId,
    this.imageKey,
    this.companyName,
    this.onImageSelected,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  bool _isHovered = false;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _selectedImagePath = widget.initialImagePath;
  }

  @override
  void didUpdateWidget(covariant ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImagePath != oldWidget.initialImagePath || widget.initialImagePath != _selectedImagePath) {
      setState(() {
        _selectedImagePath = widget.initialImagePath;
      });
    }
  }

  void _openImageSelectionModal() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return ImageSelectionDialog(
          currentPath: _selectedImagePath,
          companyName: widget.companyName,
          initialTabIndex: (widget.imageKey ?? '').toLowerCase().contains('logo') ? 1 : null,
          onPresetSelected: (presetPath) {
            PaintingBinding.instance.imageCache.clear();
            PaintingBinding.instance.imageCache.clearLiveImages();
            setState(() {
              _selectedImagePath = presetPath;
            });
            if (widget.onImageSelected != null) {
              widget.onImageSelected!(presetPath);
            }
            Navigator.of(dialogContext).pop();
          },
          onCustomUpload: () async {
            Navigator.of(dialogContext).pop();
            await _pickImageFile();
          },
          onClearImage: () {
            _clearImage();
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  Future<void> _pickImageFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.image,
        dialogTitle: 'Select Custom Image File',
      );

      if (files.isNotEmpty) {
        final file = files.first;
        String finalPath = file.name;
        final bytes = await file.readAsBytes();

        if (bytes.isNotEmpty) {
          final presId = (widget.folderPath != null && widget.folderPath!.isNotEmpty)
              ? widget.folderPath!
              : 'global_assets';
          final ext = file.name.contains('.') ? file.name.split('.').last : 'png';
          final cleanSlideId = (widget.slideId != null && widget.slideId!.isNotEmpty)
              ? widget.slideId!.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
              : 'slide';
          final cleanKey = (widget.imageKey != null && widget.imageKey!.isNotEmpty)
              ? widget.imageKey!.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
              : 'image';
          final fileName = 'img_${cleanSlideId}_${cleanKey}_${DateTime.now().millisecondsSinceEpoch}.$ext';

          final uploadResult = await ApiService.uploadFile(
            presentationId: presId,
            filename: fileName,
            bytes: bytes,
          );

          if (uploadResult != null && uploadResult['relativePath'] != null) {
            finalPath = uploadResult['relativePath'] as String;
          }
        }

        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        setState(() {
          _selectedImagePath = finalPath;
        });
        if (widget.onImageSelected != null) {
          widget.onImageSelected!(finalPath);
        }
      }
    } catch (e) {
      debugPrint('Error picking image file: $e');
    }
  }

  Future<void> _clearImage() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    setState(() {
      _selectedImagePath = null;
    });
    if (widget.onImageSelected != null) {
      widget.onImageSelected!('');
    }
  }

  Widget _buildRenderedImage(String path) {
    final baseImage = buildUniversalImage(
      path,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      presentationId: widget.folderPath ?? '',
      fallback: const Icon(Icons.broken_image, size: 32, color: Colors.grey),
    );
    return buildDynamicPresetOverlay(path, baseImage, widget.companyName);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bool hasImage = _selectedImagePath != null && _selectedImagePath!.isNotEmpty;

    final borderColor = hasImage
        ? (_isHovered ? const Color(0xFF1877F2) : Colors.transparent)
        : (_isHovered
            ? const Color(0xFF1877F2)
            : (isLight ? const Color(0xFF1877F2).withValues(alpha: 0.35) : const Color(0xFF1877F2).withValues(alpha: 0.55)));

    final bgColor = hasImage
        ? (_isHovered ? const Color(0xFF1877F2).withValues(alpha: 0.05) : Colors.transparent)
        : (isLight
            ? (_isHovered ? const Color(0xFFEBF5FF) : const Color(0xFFF4F9FF))
            : (_isHovered ? const Color(0xFF24303F) : const Color(0xFF1B232D)));

    final textColor = isLight ? const Color(0xFF1F2937) : const Color(0xFFE0E0E0);
    final subtextColor = isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _openImageSelectionModal,
        child: Container(
          height: widget.height,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: hasImage ? 0 : 8,
            vertical: hasImage ? 0 : 6,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: _isHovered ? 2.0 : (hasImage ? 0.0 : 1.5),
            ),
            boxShadow: hasImage
                ? (_isHovered
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)]
                    : const <BoxShadow>[])
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: hasImage
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildRenderedImage(_selectedImagePath!),
                      ),
                    ),
                    if (_isHovered)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: _clearImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xB3000000),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: widget.height < 80 ? 22 : 28,
                      color: const Color(0xFF1877F2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select Image',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: widget.height < 80 ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.height >= 80) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Presets or Upload',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Image Selection Popup Modal Dialog (Vertical Navigation Tabs on Left Side)
class ImageSelectionDialog extends StatefulWidget {
  final String? currentPath;
  final String? companyName;
  final int? initialTabIndex;
  final ValueChanged<String> onPresetSelected;
  final VoidCallback onCustomUpload;
  final VoidCallback onClearImage;

  const ImageSelectionDialog({
    super.key,
    required this.currentPath,
    this.companyName,
    this.initialTabIndex,
    required this.onPresetSelected,
    required this.onCustomUpload,
    required this.onClearImage,
  });

  @override
  State<ImageSelectionDialog> createState() => _ImageSelectionDialogState();
}

class _ImageSelectionDialogState extends State<ImageSelectionDialog> {
  int _selectedTabIndex = 0; // 0: Metric Cards, 1: Logo Presets, etc.

  static const List<Map<String, String>> metricCardPresets = [
    {"name": "Metric Frame 1", "asset": "assets/presets/metric_cards/Frame 39725.png"},
    {"name": "Metric Frame 2", "asset": "assets/presets/metric_cards/Frame 39726.png"},
    {"name": "Metric Frame 3", "asset": "assets/presets/metric_cards/Frame 39727.png"},
    {"name": "Metric Frame 4", "asset": "assets/presets/metric_cards/Frame 39728.png"},
    {"name": "Metric Frame 5", "asset": "assets/presets/metric_cards/Frame 39729.png"},
    {"name": "Metric Frame 6", "asset": "assets/presets/metric_cards/Frame 39730.png"},
    {"name": "Metric Frame 7", "asset": "assets/presets/metric_cards/Frame 39734.png"},
    {"name": "Metric Frame 8", "asset": "assets/presets/metric_cards/Frame 39735.png"},
    {"name": "Metric Frame 9", "asset": "assets/presets/metric_cards/Frame 39736.png"},
    {"name": "Metric Frame 10", "asset": "assets/presets/metric_cards/Frame 39737.png"},
    {"name": "Metric Frame 11", "asset": "assets/presets/metric_cards/Frame 39738.png"},
    {"name": "Metric Frame 12", "asset": "assets/presets/metric_cards/Frame 39739.png"},
    {"name": "Metric Frame 13", "asset": "assets/presets/metric_cards/Frame 39740.png"},
    {"name": "Metric Frame 14", "asset": "assets/presets/metric_cards/Frame 39741.png"},
  ];

  static const List<Map<String, String>> logoPresets = [
    {"name": "Metropolis", "asset": "assets/presets/logo_presets/metropolis.png"},
    {"name": "Nano HealthSuite", "asset": "assets/presets/logo_presets/nano_healthsuite.png"},
    {"name": "YourDOST", "asset": "assets/presets/logo_presets/yourdost.png"},
    {"name": "Amaha", "asset": "assets/presets/logo_presets/amaha.png"},
    {"name": "Wellthy Care", "asset": "assets/presets/logo_presets/wellthy_care.png"},
    {"name": "MediBuddy", "asset": "assets/presets/logo_presets/medibuddy.png"},
    {"name": "GOQii", "asset": "assets/presets/logo_presets/goqii.png"},
    {"name": "Healthify", "asset": "assets/presets/logo_presets/healthify.png"},
    {"name": "Agilus Diagnostics", "asset": "assets/presets/logo_presets/agilus_diagnostics.png"},
    {"name": "Zyla Health", "asset": "assets/presets/logo_presets/zyla_health.png"},
    {"name": "Eka Care", "asset": "assets/presets/logo_presets/eka_care.png"},
    {"name": "BeatO", "asset": "assets/presets/logo_presets/beato.png"},
    {"name": "Thyrocare", "asset": "assets/presets/logo_presets/thyrocare.png"},
    {"name": "Sugar.fit", "asset": "assets/presets/logo_presets/sugarfit.png"},
    {"name": "Sunoh.ai", "asset": "assets/presets/logo_presets/sunoh_ai.png"},
    {"name": "LifeCell", "asset": "assets/presets/logo_presets/lifecell.png"},
    {"name": "MFine", "asset": "assets/presets/logo_presets/mfine.png"},
    {"name": "Lybrate", "asset": "assets/presets/logo_presets/lybrate.png"},
    {"name": "PharmEasy", "asset": "assets/presets/logo_presets/pharmeasy.png"},
    {"name": "Practo", "asset": "assets/presets/logo_presets/practo.png"},
    {"name": "Oncquest Laboratories", "asset": "assets/presets/logo_presets/oncquest_laboratories.png"},
    {"name": "Jivi AI", "asset": "assets/presets/logo_presets/jivi_ai.png"},
    {"name": "Niramai", "asset": "assets/presets/logo_presets/niramai.png"},
    {"name": "Docprime", "asset": "assets/presets/logo_presets/docprime.png"},
    {"name": "Lilac Insights", "asset": "assets/presets/logo_presets/lilac_insights.png"},
    {"name": "Dr Lal PathLabs", "asset": "assets/presets/logo_presets/dr_lal_pathlabs.png"},
    {"name": "HealthPlix", "asset": "assets/presets/logo_presets/healthplix.png"},
    {"name": "4baseCare", "asset": "assets/presets/logo_presets/4basecare.png"},
    {"name": "Manipal TRUtest", "asset": "assets/presets/logo_presets/manipal_trutest.png"},
    {"name": "Doceree", "asset": "assets/presets/logo_presets/doceree.png"},
    {"name": "Neuberg Diagnostics", "asset": "assets/presets/logo_presets/neuberg_diagnostics.png"},
    {"name": "Orange Health Labs", "asset": "assets/presets/logo_presets/orange_health_labs.png"},
    {"name": "Cloudnine", "asset": "assets/presets/logo_presets/cloudnine.png"},
    {"name": "iCALL", "asset": "assets/presets/logo_presets/icall.png"},
    {"name": "Innovaccer", "asset": "assets/presets/logo_presets/innovaccer.png"},
    {"name": "Portea Medical", "asset": "assets/presets/logo_presets/portea_medical.png"},
    {"name": "Lissun", "asset": "assets/presets/logo_presets/lissun.png"},
    {"name": "Cult.fit", "asset": "assets/presets/logo_presets/cultfit.png"},
    {"name": "Healthians", "asset": "assets/presets/logo_presets/healthians.png"},
    {"name": "Redcliffe Labs", "asset": "assets/presets/logo_presets/redcliffe_labs.png"},
    {"name": "Pristyn Care", "asset": "assets/presets/logo_presets/pristyn_care.png"},
    {"name": "Ultrahuman", "asset": "assets/presets/logo_presets/ultrahuman.png"},
    {"name": "Fitterfly", "asset": "assets/presets/logo_presets/fitterfly.png"},
    {"name": "PB Health", "asset": "assets/presets/logo_presets/pb_health.png"},
    {"name": "Connect and Heal", "asset": "assets/presets/logo_presets/connect_and_heal.png"},
    {"name": "MedGenome", "asset": "assets/presets/logo_presets/medgenome.png"},
    {"name": "Netmeds", "asset": "assets/presets/logo_presets/netmeds.png"},
    {"name": "HeyDoc", "asset": "assets/presets/logo_presets/heydoc.png"},
    {"name": "Machaxi", "asset": "assets/presets/logo_presets/machaxi.png"},
    {"name": "Narayana Health Insurance", "asset": "assets/presets/logo_presets/narayana_health_insurance.png"},
  ];

  static const List<Map<String, String>> comparisonEcosystemPresets = [
    {"name": "Comparison Frame 1", "asset": "assets/presets/comparison_ecosystem_presets/Frame 39731.png"},
    {"name": "Comparison Frame 2", "asset": "assets/presets/comparison_ecosystem_presets/Frame 39732.png"},
    {"name": "Comparison Frame 3", "asset": "assets/presets/comparison_ecosystem_presets/Frame 39733.png"},
  ];

  static const List<Map<String, String>> mobileMockupPresets = [
    {"name": "Chat Screen 1", "asset": "assets/presets/mobile_mockup/chat_screen_1.png"},
    {"name": "Chat Screen 2", "asset": "assets/presets/mobile_mockup/chat_screen_2.png"},
  ];

  static const List<Map<String, String>> multiFeatureShowcasePresets = [
    {"name": "Feature Frame 1", "asset": "assets/presets/multi_feature_showcase/Frame 1000013076.png"},
    {"name": "Feature Frame 2", "asset": "assets/presets/multi_feature_showcase/Frame 1000013077.png"},
    {"name": "Feature Frame 3", "asset": "assets/presets/multi_feature_showcase/Frame 1000013078.png"},
    {"name": "Feature Frame 4", "asset": "assets/presets/multi_feature_showcase/Frame 1000013079.png"},
    {"name": "Ecosystem Flow Diagram", "asset": "assets/presets/multi_feature_showcase/ecosystem_flow_preset.png"},
  ];

  static const List<Map<String, String>> dynamicPresets = [
    {"name": "Incoming Call Screen", "asset": "assets/presets/dynamic_presets/Call Screen.png"},
  ];

  static const List<Map<String, String>> architectureFlowPresets = [
    {"name": "Architecture Flow 1", "asset": "assets/presets/architecture_flow_presets/architecture_flow_01.png"},
    {"name": "Architecture Flow 2", "asset": "assets/presets/architecture_flow_presets/architecture_flow_02.png"},
    {"name": "Architecture Flow 3", "asset": "assets/presets/architecture_flow_presets/architecture_flow_04.png"},
  ];

  static const List<Map<String, String>> consumerExperiencePresets = [
    {"name": "Wellness GPT Chat (Fatigue)", "asset": "assets/presets/consumer_experience/wellness_gpt_chat_fatigue.png"},
    {"name": "Unified Agentic Memory Architecture", "asset": "assets/presets/consumer_experience/unified_agentic_memory.png"},
    {"name": "Multi-Agent Collaboration Panel", "asset": "assets/presets/consumer_experience/multi_agent_collaboration.png"},
    {"name": "Proactive Health Nudge (Lock Screen)", "asset": "assets/presets/consumer_experience/proactive_health_nudge.png"},
    {"name": "Diagnostic Lab Report Upload", "asset": "assets/presets/consumer_experience/lab_report_upload.png"},
    {"name": "Biomarker Summary & Risk Factors", "asset": "assets/presets/consumer_experience/biomarker_risk_summary.png"},
    {"name": "Diagnostic Contextual Conversation", "asset": "assets/presets/consumer_experience/diagnostic_agent_conversation.png"},
    {"name": "Insights To Action Care Options", "asset": "assets/presets/consumer_experience/insights_to_action_care.png"},
    {"name": "Insurance Coverage & Pre-Auth", "asset": "assets/presets/consumer_experience/insurance_coverage_preauth.png"},
    {"name": "Automated Insurance Verification", "asset": "assets/presets/consumer_experience/insurance_verification_flow.png"},
    {"name": "Guided Claims Tracker", "asset": "assets/presets/consumer_experience/guided_claims_tracker.png"},
    {"name": "Claim Approval Notification", "asset": "assets/presets/consumer_experience/claim_approved_notification.png"},
    {"name": "Care Scheduling & Booking UI", "asset": "assets/presets/consumer_experience/care_scheduling_booking.png"},
    {"name": "Visit Summary & Diagnosis Saved", "asset": "assets/presets/consumer_experience/visit_summary_diagnosis.png"},
    {"name": "Connected Care Orchestration", "asset": "assets/presets/consumer_experience/connected_care_orchestration.png"},
    {"name": "Post-Discharge AI Calling Agent", "asset": "assets/presets/consumer_experience/post_discharge_calling_agent.png"},
  ];

  static const List<Map<String, String>> platformShowcasePresets = [
    {"name": "Omnichannel Healthcare Hub (Orbit)", "asset": "assets/presets/platform_showcase/omnichannel_orbit_hub.png"},
    {"name": "Agent Orchestration Pipeline", "asset": "assets/presets/platform_showcase/agent_orchestration_pipeline.png"},
    {"name": "Interactions To Intelligence Matrix", "asset": "assets/presets/platform_showcase/interactions_to_intelligence_matrix.png"},
  ];

  static const List<Map<String, String>> enterpriseBrainPresets = [
    {"name": "Executive Intelligence Telemetry", "asset": "assets/presets/enterprise_brain/executive_intelligence_telemetry.png"},
    {"name": "Diagnostic Root Cause Investigation", "asset": "assets/presets/enterprise_brain/diagnostic_root_cause_investigation.png"},
    {"name": "Executive Decision Brief", "asset": "assets/presets/enterprise_brain/executive_decision_brief.png"},
    {"name": "Decision Execution Tracker", "asset": "assets/presets/enterprise_brain/decision_execution_tracker.png"},
  ];

  static const List<Map<String, String>> patientJourneyPresets = [
    {"name": "Step 1: Symptom Intake Chat", "asset": "assets/presets/patient_journey_steps/step_1_symptom_intake.png"},
    {"name": "Step 2: Structured Memory Capture", "asset": "assets/presets/patient_journey_steps/step_2_memory_capture.png"},
    {"name": "Step 3: Lab Test Booking", "asset": "assets/presets/patient_journey_steps/step_3_lab_test_booking.png"},
    {"name": "Step 4: Memory Recall & Actions", "asset": "assets/presets/patient_journey_steps/step_4_memory_recall_actions.png"},
    {"name": "Step 5: Follow-up Calling Agent", "asset": "assets/presets/patient_journey_steps/step_5_followup_calling_agent.png"},
    {"name": "Step 6: Patient Care Timeline", "asset": "assets/presets/patient_journey_steps/step_6_patient_care_timeline.png"},
  ];

  static const List<Map<String, String>> intelligenceDashboardPresets = [
    {"name": "Campaign & Daily Usage Analytics", "asset": "assets/presets/intelligence_dashboards/campaign_usage_analytics.png"},
    {"name": "Composable Intelligence Layer Stack", "asset": "assets/presets/intelligence_dashboards/composable_intelligence_stack.png"},
    {"name": "Profile Completeness & Timing Matrix", "asset": "assets/presets/intelligence_dashboards/profile_completeness_matrix.png"},
    {"name": "Agent Transition & Escalation Analysis", "asset": "assets/presets/intelligence_dashboards/agent_transition_analysis.png"},
    {"name": "GTM Product Tracks Comparative Matrix", "asset": "assets/presets/intelligence_dashboards/gtm_tracks_comparative_matrix.png"},
  ];

  static const List<Map<String, String>> modularUiMockupPresets = [
    {"name": "Care Timeline Window", "asset": "assets/presets/modular_ui_mockups/care_timeline_window.png"},
    {"name": "Structured Memory Window", "asset": "assets/presets/modular_ui_mockups/structured_memory_window.png"},
    {"name": "Cross-Channel Memory & Actions", "asset": "assets/presets/modular_ui_mockups/cross_channel_memory_actions.png"},
  ];

  static const List<Map<String, String>> coreCapabilitiesPresets = [
    {"name": "Agentic Orchestration Engine", "asset": "assets/presets/core_capabilities/agentic_orchestration_engine.png"},
    {"name": "Compound Consumer Growth", "asset": "assets/presets/core_capabilities/compound_consumer_growth.png"},
    {"name": "Enterprise Intelligence Layer", "asset": "assets/presets/core_capabilities/enterprise_intelligence_layer.png"},
    {"name": "HealthMem Temporal Memory", "asset": "assets/presets/core_capabilities/healthmem_temporal_memory.png"},
    {"name": "Immediate Resolution", "asset": "assets/presets/core_capabilities/immediate_resolution.png"},
    {"name": "Instant Strategic Querying", "asset": "assets/presets/core_capabilities/instant_strategic_querying.png"},
    {"name": "Enterprise Knowledge Graph", "asset": "assets/presets/core_capabilities/enterprise_knowledge_graph.png"},
    {"name": "Multimodal Synthesis", "asset": "assets/presets/core_capabilities/multimodal_synthesis.png"},
    {"name": "Predictive Outreach", "asset": "assets/presets/core_capabilities/predictive_outreach.png"},
    {"name": "Scalable Market Share", "asset": "assets/presets/core_capabilities/scalable_market_share.png"},
    {"name": "Specialized Healthcare Agents", "asset": "assets/presets/core_capabilities/specialized_healthcare_agents.png"},
    {"name": "Zero Friction Operations", "asset": "assets/presets/core_capabilities/zero_friction_operations.png"},
  ];

  final TextEditingController _logoSearchController = TextEditingController();

  @override
  void dispose() {
    _logoSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialTabIndex != null) {
      _selectedTabIndex = widget.initialTabIndex!;
    } else {
      final path = widget.currentPath ?? '';
      if (path.startsWith('assets/presets/logo_presets/')) {
        _selectedTabIndex = 1;
      } else if (path.startsWith('assets/presets/comparison_ecosystem_presets/')) {
        _selectedTabIndex = 2;
      } else if (path.startsWith('assets/presets/mobile_mockup/')) {
        _selectedTabIndex = 3;
      } else if (path.startsWith('assets/presets/multi_feature_showcase/')) {
        _selectedTabIndex = 4;
      } else if (path.startsWith('assets/presets/dynamic_presets/')) {
        _selectedTabIndex = 5;
      } else if (path.startsWith('assets/presets/architecture_flow_presets/')) {
        _selectedTabIndex = 6;
      } else if (path.startsWith('assets/presets/consumer_experience/')) {
        _selectedTabIndex = 7;
      } else if (path.startsWith('assets/presets/platform_showcase/')) {
        _selectedTabIndex = 8;
      } else if (path.startsWith('assets/presets/enterprise_brain/')) {
        _selectedTabIndex = 9;
      } else if (path.startsWith('assets/presets/patient_journey_steps/')) {
        _selectedTabIndex = 10;
      } else if (path.startsWith('assets/presets/intelligence_dashboards/')) {
        _selectedTabIndex = 11;
      } else if (path.startsWith('assets/presets/modular_ui_mockups/')) {
        _selectedTabIndex = 12;
      } else if (path.startsWith('assets/presets/core_capabilities/')) {
        _selectedTabIndex = 13;
      } else if (path.isNotEmpty &&
          !path.startsWith('assets/presets/metric_cards/')) {
        _selectedTabIndex = 14;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final dialogBg = isLight ? Colors.white : const Color(0xFF1E2630);
    final sidebarBg = isLight ? const Color(0xFFF3F4F6) : const Color(0xFF161E27);
    final borderColor = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333);
    final textColor = isLight ? const Color(0xFF111827) : Colors.white;
    final subtextColor = isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.84).clamp(920.0, 1280.0);
    final dialogHeight = (screenSize.height * 0.84).clamp(620.0, 860.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: dialogBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Image Asset',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose from universal presets or upload a custom image file',
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Body: Left Vertical Navigation Sidebar + Right Content Area
            Expanded(
              child: Row(
                children: [
                  // Left Side Vertical Navigation Tabs
                  Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: sidebarBg,
                      border: Border(right: BorderSide(color: borderColor)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            child: Text(
                              'CORE PRESETS',
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildNavTabItem(
                            index: 0,
                            icon: Icons.grid_view_rounded,
                            title: 'Metric Cards',
                            isLight: isLight,
                          ),
                          const SizedBox(height: 4),
                          _buildNavTabItem(
                            index: 1,
                            icon: Icons.bubble_chart_outlined,
                            title: 'Logo Presets',
                            isLight: isLight,
                          ),
                          const SizedBox(height: 4),
                          _buildNavTabItem(
                            index: 2,
                            icon: Icons.hub_outlined,
                            title: 'Ecosystem Cards',
                            isLight: isLight,
                          ),
                          const SizedBox(height: 4),
                          _buildNavTabItem(
                            index: 3,
                            icon: Icons.smartphone_outlined,
                            title: 'Mobile Mockups',
                            isLight: isLight,
                          ),
                          const SizedBox(height: 4),
                          _buildNavTabItem(
                            index: 4,
                            icon: Icons.view_quilt_outlined,
                            title: 'Feature Showcase',
                            isLight: isLight,
                          ),
                          const SizedBox(height: 4),
                          _buildNavTabItem(
                            index: 5,
                            icon: Icons.auto_awesome_outlined,
                            title: 'Dynamic Presets',
                            isLight: isLight,
                          ),
                          const SizedBox(height: 4),
                          _buildNavTabItem(
                            index: 6,
                            icon: Icons.account_tree_outlined,
                            title: 'Architecture Flow',
                            isLight: isLight,
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            child: Text(
                              'WEBSITE ASSETS',
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildNavTabItem(
                            index: 7,
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'Consumer Experience',
                            isLight: isLight,
                          ),
                          const SizedBox(height: 4),
                          _buildNavTabItem(
                            index: 8,
                            icon: Icons.space_dashboard_outlined,
                            title: 'Platform Showcase',
                            isLight: isLight,
                          ),
                          const SizedBox(height: 4),
                          _buildNavTabItem(
                            index: 9,
                            icon: Icons.psychology_outlined,
                            title: 'Enterprise Brain',
                            isLight: isLight,
                          ),
                          const SizedBox(height: 4),
                          _buildNavTabItem(
                            index: 10,
                            icon: Icons.timeline_rounded,
                            title: 'Patient Journey',
                            isLight: isLight,
                          ),
                          const SizedBox(height: 4),
                          _buildNavTabItem(
                            index: 11,
                            icon: Icons.analytics_outlined,
                            title: 'Intelligence Dashboards',
                            isLight: isLight,
                          ),
                          const SizedBox(height: 4),
                          _buildNavTabItem(
                            index: 12,
                            icon: Icons.dashboard_customize_outlined,
                            title: 'Modular UI Mockups',
                            isLight: isLight,
                          ),
                          const SizedBox(height: 4),
                          _buildNavTabItem(
                            index: 13,
                            icon: Icons.interests_outlined,
                            title: 'Core Capabilities',
                            isLight: isLight,
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            child: Text(
                              'CUSTOM UPLOAD',
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildNavTabItem(
                            index: 14,
                            icon: Icons.upload_file_outlined,
                            title: 'Manual Upload',
                            isLight: isLight,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // Right Side Content Panel
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: _buildTabContent(isLight, textColor, subtextColor),
                    ),
                  ),
                ],
              ),
            ),

            // Footer Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.currentPath != null && widget.currentPath!.isNotEmpty)
                    TextButton.icon(
                      onPressed: widget.onClearImage,
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                      label: const Text('Remove Selected Image', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333),
                      foregroundColor: textColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTabItem({
    required int index,
    required IconData icon,
    required String title,
    required bool isLight,
  }) {
    final isSelected = _selectedTabIndex == index;
    final activeBg = isSelected
        ? (isLight ? const Color(0xFF1877F2).withValues(alpha: 0.12) : const Color(0xFF1877F2).withValues(alpha: 0.25))
        : Colors.transparent;
    final activeColor = isSelected ? const Color(0xFF1877F2) : (isLight ? const Color(0xFF374151) : const Color(0xFFCCCCCC));

    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: activeBg,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF1877F2) : Colors.transparent,
              width: 3.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: activeColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: activeColor,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isLight, Color textColor, Color subtextColor) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildMetricCardsPresetView(isLight, textColor, subtextColor);
      case 1:
        return _buildStandardPresetView(
          isLight: isLight,
          textColor: textColor,
          subtextColor: subtextColor,
          title: 'Logo Presets',
          subtitle: 'Choose from 50 verified health-tech and provider logos',
          presets: logoPresets,
          crossAxisCount: 5,
          childAspectRatio: 16 / 11,
          searchController: _logoSearchController,
          searchPlaceholder: 'Search 50 healthcare logos by name...',
        );
      case 2:
        return _buildComparisonEcosystemPresetsView(isLight, textColor, subtextColor);
      case 3:
        return _buildMobileMockupPresetsView(isLight, textColor, subtextColor);
      case 4:
        return _buildMultiFeatureShowcasePresetsView(isLight, textColor, subtextColor);
      case 5:
        return _buildDynamicPresetsView(isLight, textColor, subtextColor);
      case 6:
        return _buildArchitectureFlowPresetsView(isLight, textColor, subtextColor);
      case 7:
        return _buildStandardPresetView(
          isLight: isLight,
          textColor: textColor,
          subtextColor: subtextColor,
          title: 'Consumer Experience Presets',
          subtitle: 'Patient & Consumer Care, Diagnostic, and Claims Flows',
          presets: consumerExperiencePresets,
          crossAxisCount: 4,
          childAspectRatio: 3 / 4,
        );
      case 8:
        return _buildStandardPresetView(
          isLight: isLight,
          textColor: textColor,
          subtextColor: subtextColor,
          title: 'Platform Showcase Presets',
          subtitle: 'Omnichannel Hub, Orchestration & Intelligence Matrix',
          presets: platformShowcasePresets,
          crossAxisCount: 3,
          childAspectRatio: 1.0,
        );
      case 9:
        return _buildStandardPresetView(
          isLight: isLight,
          textColor: textColor,
          subtextColor: subtextColor,
          title: 'Enterprise Brain Presets',
          subtitle: 'Executive Intelligence Telemetry, Decision Briefs & Root Cause',
          presets: enterpriseBrainPresets,
          crossAxisCount: 2,
          childAspectRatio: 16 / 10,
        );
      case 10:
        return _buildStandardPresetView(
          isLight: isLight,
          textColor: textColor,
          subtextColor: subtextColor,
          title: 'Patient Journey Steps',
          subtitle: 'Step-by-step Patient Consultation & Memory Care Milestones',
          presets: patientJourneyPresets,
          crossAxisCount: 2,
          childAspectRatio: 16 / 9,
        );
      case 11:
        return _buildStandardPresetView(
          isLight: isLight,
          textColor: textColor,
          subtextColor: subtextColor,
          title: 'Intelligence Dashboards',
          subtitle: 'Analytics, Stack Architecture, and GTM Tracks',
          presets: intelligenceDashboardPresets,
          crossAxisCount: 2,
          childAspectRatio: 16 / 10,
        );
      case 12:
        return _buildStandardPresetView(
          isLight: isLight,
          textColor: textColor,
          subtextColor: subtextColor,
          title: 'Modular UI Mockups',
          subtitle: 'Timeline Windows, Memory Layers & Cross-Channel Views',
          presets: modularUiMockupPresets,
          crossAxisCount: 2,
          childAspectRatio: 16 / 10,
        );
      case 13:
        return _buildStandardPresetView(
          isLight: isLight,
          textColor: textColor,
          subtextColor: subtextColor,
          title: 'Core Capabilities Presets',
          subtitle: 'Agentic Engines, Memory Systems, Growth & Knowledge Graphs',
          presets: coreCapabilitiesPresets,
          crossAxisCount: 4,
          childAspectRatio: 1.0,
        );
      case 14:
        return _buildManualUploadView(isLight, textColor, subtextColor);
      default:
        return _buildMetricCardsPresetView(isLight, textColor, subtextColor);
    }
  }

  Widget _buildMetricCardsPresetView(bool isLight, Color textColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Metric Cards Universal Presets',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${metricCardPresets.length} Universal Assets',
              style: TextStyle(
                color: subtextColor,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 16 / 10,
            ),
            itemCount: metricCardPresets.length,
            itemBuilder: (context, index) {
              final preset = metricCardPresets[index];
              final assetPath = preset['asset']!;
              final isSelected = widget.currentPath == assetPath;

              return InkWell(
                onTap: () => widget.onPresetSelected(assetPath),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF1B232D),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1877F2)
                          : (isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333)),
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1877F2).withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 28, color: Colors.grey),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1877F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildMobileMockupPresetsView(bool isLight, Color textColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mobile Mockup Presets',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${mobileMockupPresets.length} Universal Assets',
              style: TextStyle(
                color: subtextColor,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 9 / 18,
            ),
            itemCount: mobileMockupPresets.length,
            itemBuilder: (context, index) {
              final preset = mobileMockupPresets[index];
              final assetPath = preset['asset']!;
              final isSelected = widget.currentPath == assetPath;

              return InkWell(
                onTap: () => widget.onPresetSelected(assetPath),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF1B232D),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1877F2)
                          : (isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333)),
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1877F2).withValues(alpha: 0.35),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.broken_image,
                            size: 24,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 2,
                          right: 2,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: Color(0xFF1877F2),
                            child: Icon(Icons.check, size: 11, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMultiFeatureShowcasePresetsView(bool isLight, Color textColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Feature Showcase Presets',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${multiFeatureShowcasePresets.length} Universal Assets',
              style: TextStyle(
                color: subtextColor,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 16 / 10,
            ),
            itemCount: multiFeatureShowcasePresets.length,
            itemBuilder: (context, index) {
              final preset = multiFeatureShowcasePresets[index];
              final assetPath = preset['asset']!;
              final isSelected = widget.currentPath == assetPath;

              return InkWell(
                onTap: () => widget.onPresetSelected(assetPath),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF1B232D),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1877F2)
                          : (isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333)),
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1877F2).withValues(alpha: 0.35),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.broken_image,
                            size: 24,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 2,
                          right: 2,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: Color(0xFF1877F2),
                            child: Icon(Icons.check, size: 11, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicPresetsView(bool isLight, Color textColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dynamic Contextual Presets',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${dynamicPresets.length} Dynamic Assets',
              style: TextStyle(
                color: subtextColor,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'These presets dynamically overlay contextual text (e.g. caller ID) based on your company name.',
          style: TextStyle(
            color: subtextColor,
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 9 / 16,
            ),
            itemCount: dynamicPresets.length,
            itemBuilder: (context, index) {
              final preset = dynamicPresets[index];
              final assetPath = preset['asset']!;
              final isSelected = widget.currentPath == assetPath;

              final baseImage = Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 28, color: Colors.grey),
              );

              return InkWell(
                onTap: () => widget.onPresetSelected(assetPath),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF1B232D),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1877F2)
                          : (isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333)),
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1877F2).withValues(alpha: 0.35),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: buildDynamicPresetOverlay(assetPath, baseImage, widget.companyName),
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 2,
                          right: 2,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: Color(0xFF1877F2),
                            child: Icon(Icons.check, size: 11, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArchitectureFlowPresetsView(bool isLight, Color textColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Architecture Flow Presets',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${architectureFlowPresets.length} Presets Available',
              style: TextStyle(
                color: subtextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.0,
            ),
            itemCount: architectureFlowPresets.length,
            itemBuilder: (context, index) {
              final preset = architectureFlowPresets[index];
              final assetPath = preset['asset']!;
              final isSelected = widget.currentPath == assetPath;

              return InkWell(
                onTap: () => widget.onPresetSelected(assetPath),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF1B232D),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1877F2)
                          : (isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333)),
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1877F2).withValues(alpha: 0.35),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 28, color: Colors.grey),
                        ),
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 2,
                          right: 2,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: Color(0xFF1877F2),
                            child: Icon(Icons.check, size: 11, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonEcosystemPresetsView(bool isLight, Color textColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Comparison Ecosystem Presets',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '3 Preset Frames',
              style: TextStyle(
                color: subtextColor,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 16 / 9,
            ),
            itemCount: comparisonEcosystemPresets.length,
            itemBuilder: (context, index) {
              final preset = comparisonEcosystemPresets[index];
              final assetPath = preset['asset']!;
              final isSelected = widget.currentPath == assetPath;

              return InkWell(
                onTap: () => widget.onPresetSelected(assetPath),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF1B232D),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1877F2)
                          : (isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333)),
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1877F2).withValues(alpha: 0.35),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.broken_image,
                            size: 28,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 2,
                          right: 2,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: Color(0xFF1877F2),
                            child: Icon(Icons.check, size: 11, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStandardPresetView({
    required bool isLight,
    required Color textColor,
    required Color subtextColor,
    required String title,
    required String subtitle,
    required List<Map<String, String>> presets,
    required int crossAxisCount,
    required double childAspectRatio,
    TextEditingController? searchController,
    String? searchPlaceholder,
  }) {
    final query = (searchController?.text ?? '').trim().toLowerCase();
    final displayedPresets = query.isEmpty
        ? presets
        : presets.where((preset) {
            final name = (preset['name'] ?? '').toLowerCase();
            final asset = (preset['asset'] ?? '').toLowerCase();
            return name.contains(query) || asset.contains(query);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              searchController != null && searchController.text.trim().isNotEmpty
                  ? '${displayedPresets.length} of ${presets.length} Found'
                  : '${presets.length} Presets Available',
              style: TextStyle(
                color: subtextColor,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: subtextColor,
              fontSize: 11.5,
            ),
          ),
        ],
        if (searchController != null) ...[
          const SizedBox(height: 10),
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: isLight ? Colors.white : const Color(0xFF1B232D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isLight ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                width: 1,
              ),
            ),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontSize: 13,
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: searchPlaceholder ?? 'Search logos...',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: subtextColor.withValues(alpha: 0.7),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: subtextColor,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        color: subtextColor,
                        splashRadius: 16,
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: displayedPresets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 40,
                        color: subtextColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No logos found matching "$query"',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () {
                          searchController?.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh, size: 15),
                        label: const Text('Clear search', style: TextStyle(fontSize: 12.5)),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: displayedPresets.length,
                  itemBuilder: (context, index) {
                    final preset = displayedPresets[index];
                    final assetPath = preset['asset']!;
                    final presetName = preset['name'] ?? '';
                    final isSelected = widget.currentPath == assetPath;

                    return InkWell(
                      onTap: () => widget.onPresetSelected(assetPath),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF1B232D),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1877F2)
                                : (isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333)),
                            width: isSelected ? 2.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF1877F2).withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Center(
                                    child: Image.asset(
                                      assetPath,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.broken_image,
                                        size: 28,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Positioned(
                                      top: 2,
                                      right: 2,
                                      child: CircleAvatar(
                                        radius: 9,
                                        backgroundColor: Color(0xFF1877F2),
                                        child: Icon(Icons.check, size: 11, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (presetName.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                presetName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF1877F2)
                                      : (isLight ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildManualUploadView(bool isLight, Color textColor, Color subtextColor) {
    return Center(
      child: InkWell(
        onTap: widget.onCustomUpload,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF1B232D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLight ? const Color(0xFF1877F2).withValues(alpha: 0.35) : const Color(0xFF1877F2).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1877F2).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: Color(0xFF1877F2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload Custom Image from Computer',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Click anywhere in this area to browse and select an image file',
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom HSV Color Picker Widget (Matches Saturation/Value Box, Rainbow Hue Slider, Hex & RGB Inputs)
class CustomColorPickerWidget extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const CustomColorPickerWidget({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<CustomColorPickerWidget> createState() => _CustomColorPickerWidgetState();
}

class _CustomColorPickerWidgetState extends State<CustomColorPickerWidget> {
  late HSVColor _hsvColor;
  late TextEditingController _hexController;
  late TextEditingController _rController;
  late TextEditingController _gController;
  late TextEditingController _bController;

  bool _isUpdatingFromInputs = false;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
    final c = widget.initialColor;
    _hexController = TextEditingController(text: _colorToHex(c));
    _rController = TextEditingController(text: (c.r * 255).round().toString());
    _gController = TextEditingController(text: (c.g * 255).round().toString());
    _bController = TextEditingController(text: (c.b * 255).round().toString());
  }

  @override
  void didUpdateWidget(covariant CustomColorPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialColor != oldWidget.initialColor && !_isUpdatingFromInputs) {
      setState(() {
        _hsvColor = HSVColor.fromColor(widget.initialColor);
        _syncInputFields(widget.initialColor);
      });
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    _rController.dispose();
    _gController.dispose();
    _bController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#$r$g$b';
  }

  void _syncInputFields(Color c) {
    _hexController.text = _colorToHex(c);
    _rController.text = (c.r * 255).round().toString();
    _gController.text = (c.g * 255).round().toString();
    _bController.text = (c.b * 255).round().toString();
  }

  void _notifyColorChanged(Color newColor) {
    _isUpdatingFromInputs = true;
    _syncInputFields(newColor);
    widget.onColorChanged(newColor);
    _isUpdatingFromInputs = false;
  }

  void _onHexSubmitted(String val) {
    var hexStr = val.trim().replaceAll('#', '');
    if (hexStr.length == 6) {
      final intVal = int.tryParse('FF$hexStr', radix: 16);
      if (intVal != null) {
        final newColor = Color(intVal);
        setState(() {
          _hsvColor = HSVColor.fromColor(newColor);
        });
        _notifyColorChanged(newColor);
      }
    }
  }

  void _onRgbSubmitted() {
    final r = int.tryParse(_rController.text)?.clamp(0, 255) ?? (widget.initialColor.r * 255).round();
    final g = int.tryParse(_gController.text)?.clamp(0, 255) ?? (widget.initialColor.g * 255).round();
    final b = int.tryParse(_bController.text)?.clamp(0, 255) ?? (widget.initialColor.b * 255).round();
    final newColor = Color.fromARGB(255, r, g, b);
    setState(() {
      _hsvColor = HSVColor.fromColor(newColor);
    });
    _notifyColorChanged(newColor);
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _hsvColor.toColor();
    final pureHueColor = HSVColor.fromAHSV(1.0, _hsvColor.hue, 1.0, 1.0).toColor();
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? Colors.white : const Color(0xFF1E2630);
    final cardBorder = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333);
    final textColor = isLight ? const Color(0xFF111827) : Colors.white;
    final subtextColor = isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Saturation / Value 2D Box
        LayoutBuilder(
          builder: (context, constraints) {
            final boxWidth = constraints.maxWidth;
            const boxHeight = 140.0;

            final thumbX = (_hsvColor.saturation * boxWidth).clamp(0.0, boxWidth);
            final thumbY = ((1.0 - _hsvColor.value) * boxHeight).clamp(0.0, boxHeight);

            void updateSatVal(Offset localPos) {
              final sat = (localPos.dx / boxWidth).clamp(0.0, 1.0);
              final val = (1.0 - (localPos.dy / boxHeight)).clamp(0.0, 1.0);
              setState(() {
                _hsvColor = _hsvColor.withSaturation(sat).withValue(val);
              });
              _notifyColorChanged(_hsvColor.toColor());
            }

            return GestureDetector(
              onPanDown: (details) => updateSatVal(details.localPosition),
              onPanUpdate: (details) => updateSatVal(details.localPosition),
              child: Container(
                width: boxWidth,
                height: boxHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Stack(
                  children: [
                    // Base pure hue layer
                    Container(color: pureHueColor),
                    // White horizontal gradient (saturation)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                    // Black vertical gradient (value)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0x00000000), Color(0xFF000000)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Draggable Circular Thumb
                    Positioned(
                      left: thumbX - 14,
                      top: thumbY - 14,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentColor,
                          border: Border.all(color: Colors.white, width: 3.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // 2. Rainbow Hue Slider
        LayoutBuilder(
          builder: (context, constraints) {
            final sliderWidth = constraints.maxWidth;
            const sliderHeight = 16.0;
            final thumbX = ((_hsvColor.hue / 360.0) * sliderWidth).clamp(0.0, sliderWidth);

            void updateHue(Offset localPos) {
              final hue = (localPos.dx / sliderWidth).clamp(0.0, 1.0) * 360.0;
              setState(() {
                _hsvColor = _hsvColor.withHue(hue);
              });
              _notifyColorChanged(_hsvColor.toColor());
            }

            return GestureDetector(
              onPanDown: (details) => updateHue(details.localPosition),
              onPanUpdate: (details) => updateHue(details.localPosition),
              child: SizedBox(
                height: 28,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: sliderHeight,
                      width: sliderWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF0000),
                            Color(0xFFFFFF00),
                            Color(0xFF00FF00),
                            Color(0xFF00FFFF),
                            Color(0xFF0000FF),
                            Color(0xFFFF00FF),
                            Color(0xFFFF0000),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: (thumbX - 14).clamp(0.0, sliderWidth - 28.0),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pureHueColor,
                          border: Border.all(color: Colors.white, width: 3.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // 3. Hex & RGB Input Fields
        Row(
          children: [
            // Hex Input
            Expanded(
              flex: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hex', style: TextStyle(color: subtextColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 34,
                    child: TextField(
                      controller: _hexController,
                      onSubmitted: _onHexSubmitted,
                      onChanged: (v) {
                        if (v.replaceAll('#', '').length == 6) {
                          _onHexSubmitted(v);
                        }
                      },
                      style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        filled: true,
                        fillColor: cardBg,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFF1877F2)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // R Input
            Expanded(
              flex: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('R', style: TextStyle(color: subtextColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _rController,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _onRgbSubmitted(),
                    onChanged: (_) => _onRgbSubmitted(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      filled: true,
                      fillColor: cardBg,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1877F2)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // G Input
            Expanded(
              flex: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('G', style: TextStyle(color: subtextColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _gController,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _onRgbSubmitted(),
                    onChanged: (_) => _onRgbSubmitted(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      filled: true,
                      fillColor: cardBg,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1877F2)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // B Input
            Expanded(
              flex: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('B', style: TextStyle(color: subtextColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _bController,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _onRgbSubmitted(),
                    onChanged: (_) => _onRgbSubmitted(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      filled: true,
                      fillColor: cardBg,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1877F2)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PresentationEditorScreen extends StatefulWidget {
  final PresentationModel presentation;

  const PresentationEditorScreen({
    super.key,
    required this.presentation,
  });

  @override
  State<PresentationEditorScreen> createState() => _PresentationEditorScreenState();
}

class _PresentationEditorScreenState extends State<PresentationEditorScreen> {
  late List<SlideData> _slides;
  int _activeSlideIndex = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showRightSidebar = true;
  late Color _accentColor;
  String? _selectedTextElementKey;
  String _iconSearchQuery = '';
  Map<String, dynamic>? _sourceContext;
  int? _regeneratingSlideIndex;
  late String _effectiveLogoPath;

  double _getDefaultFontSize(String key) {
    if (key.startsWith('title')) return 36.0;
    if (key.startsWith('subtitle')) return 20.0;
    if (key.startsWith('metric_val')) return 36.0;
    if (key.startsWith('card_') && key.contains('_outcome_title')) return 12.0;
    if (key.startsWith('card_') && key.contains('_outcome_text')) return 14.5;
    if (key.startsWith('card_') && key.contains('_outcome_icon')) return 20.0;
    if (key.startsWith('card_') && key.contains('_bullet_')) return 15.0;
    if (key.startsWith('card_') && (key.contains('_subtitle') || key.contains('_sub'))) return 15.0;
    if (key.startsWith('card_title') || (key.startsWith('card_') && key.contains('_title'))) return 22.0;
    if (key.startsWith('pilot_step_') && key.contains('_name')) return 13.0;
    if (key.startsWith('pilot_step_') && key.contains('_desc')) return 13.0;
    if (key == 'pilot_label') return 13.0;
    if (key == 'pilot_title') return 19.0;
    if (key == 'pilot_subtitle') return 15.0;
    if (key.startsWith('diagram_label')) return 18.0;
    if (key.startsWith('agent_') && key.contains('_title')) return 24.0;
    if (key.startsWith('agent_') && (key.contains('_sub') || key.contains('_subtitle'))) return 16.0;
    if (key.startsWith('agent_') && key.contains('_item_')) return 16.0;
    if (key.startsWith('feat_') && key.contains('_title')) return 16.5;
    if (key.startsWith('feat_') && (key.contains('_desc') || key.contains('_description'))) return 14.0;
    if (key == 'bottom_title' || key == 'bottom_banner_title') return 20.0;
    if (key == 'bottom_sub' || key == 'bottom_banner_sub') return 15.0;
    if (key.startsWith('card_icon')) return 16.0;
    if (key.startsWith('feature_icon')) return 15.0;
    if (key.startsWith('list_icon')) return 13.0;
    if (key.startsWith('process_icon')) return 16.0;
    if (key.startsWith('eco_icon')) return 16.0;
    if (key.startsWith('sol_icon')) return 14.0;
    if (key.startsWith('agent_') && key.contains('_icon_')) return 20.0;
    if (key.startsWith('feat_') && key.contains('_icon')) return 24.0;
    if (key.contains('icon')) return 16.0;
    return 16.0;
  }

  FontWeight _getDefaultFontWeight(String key) {
    if (key.startsWith('title')) return FontWeight.bold;
    if (key.startsWith('metric_val')) return FontWeight.w800;
    if (key.startsWith('card_') && key.contains('_outcome_title')) return FontWeight.bold;
    if (key.startsWith('card_') && key.contains('_outcome_text')) return FontWeight.w600;
    if (key.startsWith('card_') && key.contains('_bullet_')) return FontWeight.normal;
    if (key.startsWith('card_') && (key.contains('_subtitle') || key.contains('_sub'))) return FontWeight.normal;
    if (key.startsWith('card_title') || (key.startsWith('card_') && key.contains('_title'))) return FontWeight.w600;
    if (key.startsWith('pilot_step_') && key.contains('_name')) return FontWeight.bold;
    if (key.startsWith('pilot_step_') && key.contains('_desc')) return FontWeight.normal;
    if (key == 'pilot_label') return FontWeight.bold;
    if (key == 'pilot_title') return FontWeight.bold;
    if (key == 'pilot_subtitle') return FontWeight.normal;
    if (key.startsWith('agent_') && key.contains('_title')) return FontWeight.w800;
    if (key.startsWith('agent_') && (key.contains('_sub') || key.contains('_subtitle'))) return FontWeight.w500;
    if (key.startsWith('agent_') && key.contains('_item_')) return FontWeight.w700;
    if (key.startsWith('feat_') && key.contains('_title')) return FontWeight.w800;
    if (key.startsWith('feat_') && (key.contains('_desc') || key.contains('_description'))) return FontWeight.w500;
    if (key == 'bottom_title' || key == 'bottom_banner_title') return FontWeight.w900;
    if (key == 'bottom_sub' || key == 'bottom_banner_sub') return FontWeight.w500;
    return FontWeight.normal;
  }

  Widget _buildFontWeightChip(SlideData activeSlide, String label, FontWeight weight) {
    if (_selectedTextElementKey == null) {
      return const SizedBox.shrink();
    }
    final targetKey = _selectedTextElementKey!;
    final currentWeight = activeSlide.getFontWeight(targetKey, _getDefaultFontWeight(targetKey));
    final isSelected = currentWeight == weight;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final activeColor = const Color(0xFF1877F2);

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : (isLight ? const Color(0xFF374151) : const Color(0xFFCCCCCC)),
          fontSize: 11,
          fontWeight: weight,
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF333333),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide(
        color: isSelected ? activeColor : (isLight ? const Color(0xFFE5E7EB) : const Color(0xFF444444)),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      onSelected: (_) {
        setState(() {
          activeSlide.setFontWeight(targetKey, weight);
        });
        _savePresentation();
      },
    );
  }

  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _selectedTextController;
  late TextEditingController _regenerationPromptController;
  late ScrollController _iconScrollController;
  Timer? _saveDebounceTimer;

  @override
  void initState() {
    super.initState();
    _accentColor = widget.presentation.accentColor;
    _effectiveLogoPath = widget.presentation.logoPath;
    _titleController = TextEditingController();
    _subtitleController = TextEditingController();
    _selectedTextController = TextEditingController();
    _regenerationPromptController = TextEditingController();
    _iconScrollController = ScrollController();
    HardwareKeyboard.instance.addHandler(_handleHardwareKeyEvent);
    _loadSlides();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKeyEvent);
    _saveDebounceTimer?.cancel();
    _titleController.dispose();
    _subtitleController.dispose();
    _selectedTextController.dispose();
    _regenerationPromptController.dispose();
    _iconScrollController.dispose();
    super.dispose();
  }

  bool _isTextContentKey(String key) {
    const settingsKeys = {
      'notes',
      'textAlign',
      'isHidden',
      'hidden',
      'formatting',
      'font_sizes',
      'font_weights',
      'titleFontSize',
      'subtitleFontSize',
      'font',
      'fontSize',
      'fontFamily',
      'icons',
      'image_overrides',
    };
    return !settingsKeys.contains(key);
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827))),
          ],
        ),
        content: SelectableText(message, style: const TextStyle(fontSize: 12.5, color: Color(0xFF4B5563), height: 1.4)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: const Size(60, 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  /// Load presentation slides from ApiService
  Future<void> _loadSlides() async {
    setState(() => _isLoading = true);
    final List<SlideData> loadedSlides = [];
    Map<String, dynamic>? sourceCtx;

    try {
      final presentations = await ApiService.getPresentations();
      Map<String, dynamic>? currentPres;
      for (final p in presentations) {
        if (p['id'] == widget.presentation.id || p['folderName'] == widget.presentation.id || p['folderPath'] == widget.presentation.folderPath) {
          currentPres = p;
          break;
        }
      }

      if (currentPres != null) {
        final manifestMap = Map<String, dynamic>.from(currentPres['manifest'] as Map? ?? {});
        final presMap = Map<String, dynamic>.from(currentPres['presentation'] as Map? ?? {});
        final manifestSlides = Map<String, dynamic>.from(manifestMap['slides'] as Map? ?? {});

        final themeMap = Map<String, dynamic>.from(manifestMap['theme'] as Map? ?? {});
        final String manifestLogo = themeMap['logo']?.toString() ??
            manifestMap['logo']?.toString() ??
            manifestMap['companyLogo']?.toString() ??
            '';
        if (manifestLogo.isNotEmpty) {
          _effectiveLogoPath = manifestLogo;
        }

        if (manifestMap['sourceContext'] is Map) {
          sourceCtx = Map<String, dynamic>.from(manifestMap['sourceContext'] as Map);
          sourceCtx.remove('font');
        }

        final slidesList = presMap['slides'] as List<dynamic>? ?? [];
        for (final s in slidesList) {
          if (s is Map<String, dynamic>) {
            final slideId = s['id']?.toString() ?? '';
            final settings = manifestSlides[slideId] as Map<String, dynamic>?;
            loadedSlides.add(SlideData.fromJson(s, settings));
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading slides: $e');
      if (mounted) {
        _showErrorDialog('Slide Loading Error', 'Failed to load presentation slides:\n\n$e');
      }
    }

    if (loadedSlides.isEmpty && mounted) {
      _showErrorDialog('Empty Presentation', 'No valid slides were found in this presentation.');
    }

    setState(() {
      _slides = loadedSlides;
      _sourceContext = sourceCtx;
      _activeSlideIndex = 0;
      _isLoading = false;
      _updateControllers();
    });
  }

  String _getDefaultRegenerationPrompt(int index) {
    if (index < 0 || index >= _slides.length) return '';
    final s = _slides[index];
    final typeName = s.slideType.replaceAll('_', ' ');
    final titleStr = s.title.isNotEmpty ? ' ("${s.title}")' : '';
    final companyStr = _sourceContext?['company']?.toString() ?? widget.presentation.companyName;
    return 'Regenerate Slide ${index + 1}$titleStr ($typeName). Focus on key insights, concise points, and compelling messaging for $companyStr.';
  }

  void _updateControllers() {
    if (_slides.isNotEmpty && _activeSlideIndex < _slides.length) {
      final currentSlide = _slides[_activeSlideIndex];
      _titleController.text = currentSlide.title;
      _subtitleController.text = currentSlide.subtitle;
      _regenerationPromptController.text = _getDefaultRegenerationPrompt(_activeSlideIndex);
    }
  }

  Future<Map<String, String>> _getGeminiConfig() async {
    try {
      final json = await ApiService.getSettings();
      final providers = json['aiProviders'] as Map<String, dynamic>?;
      final gemini = providers?['gemini'] as Map<String, dynamic>?;
      final key = gemini?['apiKey'] as String?;
      final model = gemini?['selectedModel'] as String? ?? 'gemini-3.6-flash';
      if (key != null && key.isNotEmpty) {
        return {'apiKey': key, 'selectedModel': model};
      }
    } catch (e) {
      debugPrint('Error getting saved Gemini config: $e');
    }
    return {};
  }

  String _getPromptFileNameForSector(String sector) {
    switch (sector) {
      case 'Digital Health & Fitness':
        return 'digital_health_and_fitness.md';
      case 'E-Pharmacies':
        return 'e-pharmacies.md';
      case 'Health Insurance':
        return 'health_insurance.md';
      case 'Hospital Care':
        return 'hospital_care.md';
      case 'Labs and Diagnostics':
      default:
        return 'labs_and_diagnostics.md';
    }
  }

  Future<String> _loadSectorPrompt(String sector) async {
    final fileName = _getPromptFileNameForSector(sector);
    try {
      return await rootBundle.loadString('assets/prompts/$fileName');
    } catch (_) {}
    return '';
  }

  String _getExistingSlidesSummary() {
    final buffer = StringBuffer();
    for (int i = 0; i < _slides.length; i++) {
      final s = _slides[i];
      buffer.writeln('Slide ${i + 1} (${s.slideType}): ${s.title} - ${s.subtitle}');
    }
    return buffer.toString();
  }

  Future<void> _regenerateSingleSlide(int index, {String? customPrompt}) async {
    if (index < 0 || index >= _slides.length) return;
    if (_regeneratingSlideIndex != null) return;

    final config = await _getGeminiConfig();
    final apiKey = config['apiKey'];
    final preferredModel = config['selectedModel'] ?? 'gemini-3.6-flash';

    if (apiKey == null || apiKey.isEmpty) {
      if (mounted) {
        _showErrorDialog(
          'Missing Gemini API Key',
          'No Gemini API Key found. Please configure your API Key in Account & Preferences.',
        );
      }
      return;
    }

    setState(() {
      _regeneratingSlideIndex = index;
    });

    try {
      final slideToRegen = _slides[index];
      final sector = _sourceContext?['sector']?.toString() ?? widget.presentation.sector;
      final company = _sourceContext?['company']?.toString() ?? widget.presentation.companyName;
      final font = _sourceContext?['font']?.toString() ?? 'Satoshi';
      final pdfText = _sourceContext?['pdfText']?.toString() ?? '';
      final cacheName = _sourceContext?['cacheName']?.toString() ?? '';

      final userPromptInstructions = (customPrompt != null && customPrompt.trim().isNotEmpty)
          ? customPrompt.trim()
          : _regenerationPromptController.text.trim();
      final effectiveInstructions = userPromptInstructions.isNotEmpty
          ? userPromptInstructions
          : _getDefaultRegenerationPrompt(index);

      final singleSlideRequestPrompt = 'REGENERATION REQUEST FOR SINGLE SLIDE\n'
          '==================================================\n'
          'Company Name: $company\n'
          'Sector: $sector\n'
          'Theme Color: ${_colorToHex(_accentColor)}\n'
          'Font: $font\n\n'
          'Target Slide Index: ${index + 1} (out of ${_slides.length} slides)\n'
          'Target Slide ID: "${slideToRegen.id}"\n'
          'Target Slide Type: "${slideToRegen.slideType}"\n'
          'Target Slide Current Title: "${slideToRegen.title}"\n\n'
          'SPECIFIC USER INSTRUCTIONS FOR THIS REGENERATION:\n'
          '$effectiveInstructions\n\n'
          'IMPORTANT INSTRUCTION:\n'
          'Respond strictly with a valid JSON object representing ONLY THIS SINGLE SLIDE.\n'
          'The JSON object must have keys: "id": "${slideToRegen.id}", "slideType": "${slideToRegen.slideType}", "content": { ... }.\n'
          'Do not wrap in markdown ```json formatting. Respond ONLY with the single slide JSON object.\n'
          '==================================================';

      final Map<String, dynamic> requestPayload = {};
      if (cacheName.isNotEmpty) {
        requestPayload['cachedContent'] = cacheName;
        requestPayload['contents'] = [
          {
            'parts': [
              {'text': singleSlideRequestPrompt}
            ]
          }
        ];
      } else {
        final sectorPrompt = await _loadSectorPrompt(sector);
        final fullPrompt = '$sectorPrompt\n\n'
            '==================================================\n'
            'METADATA FOR THIS PRESENTATION\n'
            '==================================================\n'
            'Company Name: $company\n'
            'Sector: $sector\n'
            'Theme Color: ${_colorToHex(_accentColor)}\n'
            'Font: $font\n\n'
            '==================================================\n'
            'SOURCE DOCUMENT / CONTEXT\n'
            '==================================================\n'
            '${pdfText.isNotEmpty ? pdfText : _getExistingSlidesSummary()}\n\n'
            '$singleSlideRequestPrompt';
        requestPayload['contents'] = [
          {
            'parts': [
              {'text': fullPrompt}
            ]
          }
        ];
      }

      String rawText = '';
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$preferredModel:generateContent?key=$apiKey');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      ).timeout(const Duration(seconds: 120));

      if (res.statusCode == 200) {
        final resJson = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final candidates = resJson['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final firstCand = candidates.first as Map;
          final contentObj = firstCand['content'] as Map?;
          final partsList = contentObj?['parts'] as List?;
          rawText = (partsList?.first as Map?)?['text']?.toString() ?? '';
        }
      } else {
        throw Exception('Gemini API error ($preferredModel HTTP ${res.statusCode}): ${utf8.decode(res.bodyBytes)}');
      }

      if (rawText.isEmpty) {
        throw Exception('No response content returned from $preferredModel.');
      }

      var cleanedJsonStr = rawText.trim();
      if (cleanedJsonStr.startsWith('```')) {
        final lines = cleanedJsonStr.split('\n');
        if (lines.first.startsWith('```')) lines.removeAt(0);
        if (lines.isNotEmpty && lines.last.startsWith('```')) lines.removeLast();
        cleanedJsonStr = lines.join('\n').trim();
      }

      dynamic parsedJson = jsonDecode(cleanedJsonStr);
      Map<String, dynamic> slideMap = {};

      if (parsedJson is Map<String, dynamic>) {
        if (parsedJson.containsKey('slides') && parsedJson['slides'] is List && (parsedJson['slides'] as List).isNotEmpty) {
          slideMap = Map<String, dynamic>.from((parsedJson['slides'] as List).first as Map);
        } else {
          slideMap = parsedJson;
        }
      }

      if (slideMap.isEmpty || !slideMap.containsKey('content')) {
        throw Exception('Invalid single slide response format received from $preferredModel.');
      }

      slideMap['id'] = slideToRegen.id;
      slideMap['slideType'] = slideToRegen.slideType;
      final newSlideData = SlideData.fromJson(slideMap);

      if (mounted) {
        setState(() {
          _slides[index] = newSlideData;
          _regeneratingSlideIndex = null;
          _updateControllers();
        });

        _savePresentation();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Slide ${index + 1} (${newSlideData.title}) regenerated successfully!'),
            backgroundColor: const Color(0xFF00A86B),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error regenerating slide: $e');
      if (mounted) {
        setState(() {
          _regeneratingSlideIndex = null;
        });
        _showErrorDialog(
          'Slide Regeneration Failed',
          'Failed to regenerate slide ${index + 1}:\n\n$e',
        );
      }
    }
  }

  String _colorToHex(Color color) {
    final argb = color.toARGB32();
    return '#${argb.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  /// Persist clean text to presentation.json and all settings/metadata to manifest.json via ApiService
  void _savePresentation() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      _performSave();
    });
  }

  Future<void> _performSave() async {
    if (widget.presentation.id.isEmpty && widget.presentation.folderPath.isEmpty) return;
    final presId = widget.presentation.id.isNotEmpty ? widget.presentation.id : widget.presentation.folderPath;

    if (mounted) setState(() => _isSaving = true);
    try {
      final Map<String, dynamic> manifestMap = {
        'id': presId,
        'company': widget.presentation.companyName,
        'sector': widget.presentation.sector,
        'theme': {
          'accent': _colorToHex(_accentColor),
          if (widget.presentation.logoPath.isNotEmpty) 'logo': widget.presentation.logoPath,
        },
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      if (_sourceContext != null) {
        _sourceContext!.remove('font');
        manifestMap['sourceContext'] = _sourceContext;
      }

      final Map<String, dynamic> updatedManifestSlidesMap = {};
      final List<Map<String, dynamic>> cleanPresentationSlides = [];

      for (var i = 0; i < _slides.length; i++) {
        final s = _slides[i];
        final newId = 'slide_${(i + 1).toString().padLeft(3, '0')}';
        s.id = newId;

        final Map<String, dynamic> textContent = {};
        final Map<String, dynamic> settingsContent = {};

        s.rawContent.forEach((key, val) {
          if (val != null && key != 'notes' && key != 'textAlign' && key != 'isHidden' && key != 'hidden') {
            if (_isTextContentKey(key)) {
              textContent[key] = val;
            } else {
              settingsContent[key] = val;
            }
          }
        });

        textContent['title'] = s.title;
        textContent['subtitle'] = s.subtitle;
        if (textContent['text_overrides'] is Map) {
          final overridesMap = Map<String, dynamic>.from(textContent['text_overrides'] as Map);
          overridesMap.remove('title');
          overridesMap.remove('subtitle');
          if (overridesMap.isEmpty) {
            textContent.remove('text_overrides');
            s.rawContent.remove('text_overrides');
          } else {
            textContent['text_overrides'] = overridesMap;
            s.rawContent['text_overrides'] = overridesMap;
          }
        }
        settingsContent['textAlign'] = s.textAlign.name;

        cleanPresentationSlides.add({
          'id': newId,
          'slideType': s.slideType,
          if (s.isHidden) 'isHidden': true,
          'content': textContent,
        });

        if (s.isHidden) {
          settingsContent['isHidden'] = true;
        }

        if (settingsContent.isNotEmpty) {
          updatedManifestSlidesMap[newId] = settingsContent;
        }
      }

      manifestMap['slides'] = updatedManifestSlidesMap;

      await ApiService.savePresentation(
        id: presId,
        manifest: manifestMap,
        presentation: {'slides': cleanPresentationSlides},
      );
    } catch (e) {
      debugPrint('Error saving presentation: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _syncSelectedTextController() {
    if (_selectedTextElementKey != null && _slides.isNotEmpty && _activeSlideIndex < _slides.length) {
      final activeSlide = _slides[_activeSlideIndex];
      final key = _selectedTextElementKey!;
      final bool isBaseKey = key == 'card_title' || key == 'card_subtitle' || key == 'card_bullet' || key == 'card_outcome_title' || key == 'card_outcome_text' || key == 'card_outcome_icon' || key == 'pilot_step_name' || key == 'pilot_step_desc' || key == 'body' || key == 'metric_val' || key == 'diagram_label' || key == 'card_num' || key == 'agent_title' || key == 'agent_sub' || key == 'agent_item' || key == 'agent_icon' || key == 'feat_title' || key == 'feat_desc' || key == 'feat_icon' || key == 'ctx_title' || key == 'ctx_desc' || key == 'ctx_icon' || key == 'act_title' || key == 'act_desc' || key == 'act_icon' || key == 'wellness_step' || key == 'wellness_step_icon';
      if (isBaseKey) {
        _selectedTextController.text = '';
      } else {
        final text = activeSlide.getElementText(key, '');
        _selectedTextController.text = text;
      }
    } else {
      _selectedTextController.text = '';
    }
  }

  void _onSelectedTextChanged(String val) {
    if (_selectedTextElementKey == null || _slides.isEmpty || _activeSlideIndex >= _slides.length) return;
    final activeSlide = _slides[_activeSlideIndex];
    setState(() {
      activeSlide.setElementText(_selectedTextElementKey!, val);
    });
    _savePresentation();
  }



  void _onTextAlignChanged(TextAlign align) {
    if (_slides.isNotEmpty && _activeSlideIndex < _slides.length) {
      setState(() {
        _slides[_activeSlideIndex].textAlign = align;
      });
      _savePresentation();
    }
  }



  final GlobalKey _pdfCaptureKey = GlobalKey();
  bool _isExportingPdf = false;
  SlideData? _exportingSlide;
  int _exportingSlideIndex = 0;

  Future<void> _exportPresentationToPdf() async {
    final exportableSlides = _slides.where((s) => !s.isHidden).toList();
    if (exportableSlides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No visible slides to export.')),
      );
      return;
    }

    if (_isExportingPdf) return;

    setState(() {
      _isExportingPdf = true;
    });

    int currentStep = 0;
    final totalSteps = exportableSlides.length;
    bool isCombining = false;
    StateSetter? dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setSt) {
            dialogSetState = setSt;
            final double? progress = isCombining
                ? null
                : (totalSteps > 0 ? (currentStep + 1) / totalSteps : 0.0);
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : const Color(0xFF252526),
              child: SizedBox(
                width: 320,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF00A86B), size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isCombining ? 'Combining PDF...' : 'Exporting PDF...',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).brightness == Brightness.light
                                        ? const Color(0xFF111827)
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isCombining
                                      ? 'Combining pages into final PDF...'
                                      : 'Slide ${(currentStep + 1).clamp(1, totalSteps)} of $totalSteps',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).brightness == Brightness.light
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFFAAAAAA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          color: const Color(0xFF00A86B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    final pdf = pw.Document();

    try {
      for (int i = 0; i < exportableSlides.length; i++) {
        if (!mounted) break;
        currentStep = i;
        if (dialogSetState != null) {
          dialogSetState!(() {});
        }

        setState(() {
          _exportingSlide = exportableSlides[i];
          _exportingSlideIndex = i;
        });

        await Future.delayed(const Duration(milliseconds: 200));
        await WidgetsBinding.instance.endOfFrame;

        final boundary = _pdfCaptureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 1.5);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final pngBytes = byteData.buffer.asUint8List();
            final pdfImage = pw.MemoryImage(pngBytes);

            pdf.addPage(
              pw.Page(
                pageFormat: const PdfPageFormat(
                  1920,
                  1080,
                  marginTop: 0,
                  marginBottom: 0,
                  marginLeft: 0,
                  marginRight: 0,
                ),
                build: (pw.Context context) {
                  return pw.FullPage(
                    ignoreMargins: true,
                    child: pw.Image(pdfImage, fit: pw.BoxFit.cover),
                  );
                },
              ),
            );
          }
        }
        await Future.delayed(const Duration(milliseconds: 50));
      }

      isCombining = true;
      if (dialogSetState != null) {
        dialogSetState!(() {});
      }
      await Future.delayed(const Duration(milliseconds: 1000));
      await WidgetsBinding.instance.endOfFrame;

      final bytes = await pdf.save();

      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: '${widget.presentation.companyName}_Presentation.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF Generated! Browser print/download dialog opened.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error exporting presentation to PDF: $e');
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
          _exportingSlide = null;
        });
      }
    }
  }



  void _selectSlide(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _activeSlideIndex = index;
      _selectedTextElementKey = null;
      _updateControllers();
    });
  }

  bool _handleHardwareKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (_slides.isEmpty) return false;

    // Do NOT navigate if user is currently typing in an editable text field
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && primaryFocus.context != null) {
      final isEditable = primaryFocus.context!.findAncestorWidgetOfExactType<EditableText>() != null;
      if (isEditable) return false;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.pageUp) {
      if (_activeSlideIndex > 0) {
        _selectSlide(_activeSlideIndex - 1);
        return true;
      }
    } else if (key == LogicalKeyboardKey.arrowRight ||
               key == LogicalKeyboardKey.arrowDown ||
               key == LogicalKeyboardKey.pageDown ||
               key == LogicalKeyboardKey.space) {
      if (_activeSlideIndex < _slides.length - 1) {
        _selectSlide(_activeSlideIndex + 1);
        return true;
      }
    } else if (key == LogicalKeyboardKey.home) {
      if (_activeSlideIndex != 0) {
        _selectSlide(0);
        return true;
      }
    } else if (key == LogicalKeyboardKey.end) {
      if (_activeSlideIndex != _slides.length - 1) {
        _selectSlide(_slides.length - 1);
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF1E1E1E),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Top Navigation Bar
                    _buildEditorTopBar(),

                    // Main Workspace Layout (Sidebar + Slide Canvas + Inspector Panel)
                    Expanded(
                      child: Row(
                        children: [
                          // Left Slide Navigator Sidebar
                          _buildSlidesSidebar(),

                          // Center Slide Canvas Area
                          Expanded(
                            child: _buildCanvasArea(),
                          ),

                          // Right Side Inspector Panel for Editing
                          if (_showRightSidebar) _buildRightInspectorSidebar(),
                        ],
                      ),
                    ),
                  ],
                ),

          // Offscreen RepaintBoundary for high-quality 16:9 PDF export
          if (_exportingSlide != null)
            Positioned(
              left: -9999,
              top: -9999,
              child: RepaintBoundary(
                key: _pdfCaptureKey,
                child: VirtualSlideFrame(
                  slide: _exportingSlide!,
                  presentation: widget.presentation.copyWith(logoPath: _effectiveLogoPath),
                  accentColor: _accentColor,
                  slideIndex: _exportingSlideIndex,
                  totalSlides: _slides.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Top Editor Navigation Bar
  Widget _buildEditorTopBar() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF252526),
        border: Border(
          bottom: BorderSide(
            color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button to return to Presentations list
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            color: isLight ? const Color(0xFF4B5563) : const Color(0xFFCCCCCC),
            tooltip: 'Back to Presentations',
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 8),

          // Presentation Title & Subtitle Breadcrumb
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.presentation.companyName,
                style: TextStyle(
                  color: isLight ? const Color(0xFF111827) : Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.presentation.sector.isNotEmpty)
                Text(
                  widget.presentation.sector,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF6B7280) : const Color(0xFF888888),
                    fontSize: 11,
                  ),
                ),
            ],
          ),

          const Spacer(),

          // Status indicator
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                  ),
                  SizedBox(width: 6),
                  Text('Saving...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),



          // Export PDF Action Button
          ElevatedButton.icon(
            onPressed: _isExportingPdf ? null : _exportPresentationToPdf,
            icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
            label: const Text('Export PDF', style: TextStyle(color: Colors.white, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A86B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
          const SizedBox(width: 10),



          // Toggle Right Inspector Sidebar Button
          IconButton(
            icon: Icon(
              _showRightSidebar ? Icons.view_sidebar : Icons.view_sidebar_outlined,
              size: 20,
            ),
            color: _showRightSidebar ? const Color(0xFF1877F2) : (isLight ? const Color(0xFF6B7280) : const Color(0xFFCCCCCC)),
            tooltip: _showRightSidebar ? 'Hide Inspector Panel' : 'Show Inspector Panel',
            onPressed: () {
              setState(() {
                _showRightSidebar = !_showRightSidebar;
              });
            },
          ),
        ],
      ),
    );
  }

  void _showSlideContextMenu(Offset globalPosition, int index) async {
    final slide = _slides[index];
    final RelativeRect position = RelativeRect.fromLTRB(
      globalPosition.dx,
      globalPosition.dy,
      globalPosition.dx + 1,
      globalPosition.dy + 1,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      elevation: 6,
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      menuPadding: const EdgeInsets.symmetric(vertical: 4),
      constraints: const BoxConstraints(minWidth: 165, maxWidth: 195),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'regenerate',
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: const [
              Icon(Icons.auto_awesome, size: 14, color: Color(0xFF1877F2)),
              SizedBox(width: 8),
              Text(
                'Generate slide again',
                style: TextStyle(fontSize: 12, color: Color(0xFF1F2937), fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'hide',
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(
                slide.isHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 14,
                color: const Color(0xFF374151),
              ),
              const SizedBox(width: 8),
              Text(
                slide.isHidden ? 'Unhide Slide' : 'Hide Slide',
                style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937), fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'duplicate',
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: const [
              Icon(Icons.copy_outlined, size: 14, color: Color(0xFF374151)),
              SizedBox(width: 8),
              Text(
                'Duplicate Slide',
                style: TextStyle(fontSize: 12, color: Color(0xFF1F2937), fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: const [
              Icon(Icons.delete_outline, size: 14, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text(
                'Delete Slide',
                style: TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ],
    );

    if (!mounted) return;

    if (selected == 'regenerate') {
      _openRegenerateSlideDialog(index);
    } else if (selected == 'hide') {
      setState(() {
        slide.isHidden = !slide.isHidden;
      });
      _performSave();
    } else if (selected == 'duplicate') {
      _duplicateSlide(index);
    } else if (selected == 'delete') {
      _deleteSlide(index);
    }
  }

  void _openRegenerateSlideDialog(int index) {
    final slide = _slides[index];
    final defaultPrompt = _getDefaultRegenerationPrompt(index);
    final promptController = TextEditingController(text: defaultPrompt);

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isGenerating = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isLight = Theme.of(context).brightness == Brightness.light;
            final cardBg = isLight ? Colors.white : const Color(0xFF282828);
            final cardBorder = isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.08);
            final textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
            final subtextColor = isLight ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 580,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isLight ? 0.12 : 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modal Header Strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: cardBorder, width: 1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF1877F2)),
                          const SizedBox(width: 10),
                          Text(
                            'Generate Slide ${index + 1} Again',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, size: 18, color: subtextColor),
                            onPressed: isGenerating ? null : () => Navigator.of(dialogContext).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Form Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Slide: Slide ${index + 1}${slide.title.isNotEmpty ? ' - "${slide.title}"' : ''}',
                              style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Edit the prompt below to guide AI on what content or layout changes to make for this slide.',
                              style: TextStyle(color: subtextColor, fontSize: 12),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'AI Generation Prompt *',
                              style: TextStyle(color: textColor, fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: promptController,
                              enabled: !isGenerating,
                              maxLines: 5,
                              minLines: 3,
                              style: TextStyle(color: textColor, fontSize: 13),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1E1E1E),
                                hintText: 'Enter prompt instructions for regenerating this slide...',
                                hintStyle: TextStyle(color: subtextColor, fontSize: 12.5),
                                contentPadding: const EdgeInsets.all(12),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(color: cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: Color(0xFF1877F2), width: 1.5),
                                ),
                              ),
                            ),

                            if (errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isLight ? const Color(0xFFFEF2F2) : const Color(0xFF2E1B1B),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFEF4444)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, size: 16, color: Color(0xFFEF4444)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        errorMessage!,
                                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            if (isGenerating) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isLight ? const Color(0xFFF0F9FF) : const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF1877F2).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1877F2)),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Regenerating slide content with Gemini AI...',
                                        style: TextStyle(color: Color(0xFF1877F2), fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            // Footer Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: isGenerating ? null : () => Navigator.of(dialogContext).pop(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    side: BorderSide(color: cardBorder),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(color: subtextColor, fontSize: 12.5, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: isGenerating
                                      ? null
                                      : () async {
                                          setDialogState(() {
                                            isGenerating = true;
                                            errorMessage = null;
                                          });
                                          try {
                                            await _regenerateSingleSlide(index, customPrompt: promptController.text.trim());
                                            if (dialogContext.mounted) {
                                              Navigator.of(dialogContext).pop();
                                            }
                                          } catch (e) {
                                            setDialogState(() {
                                              isGenerating = false;
                                              errorMessage = e.toString();
                                            });
                                          }
                                        },
                                  icon: isGenerating
                                      ? const SizedBox.shrink()
                                      : const Icon(Icons.auto_awesome, size: 15, color: Colors.white),
                                  label: Text(
                                    isGenerating ? 'Generating...' : 'Generate',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1877F2),
                                    disabledBackgroundColor: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _duplicateSlide(int index) {
    final originalSlide = _slides[index];
    final jsonMap = Map<String, dynamic>.from(originalSlide.toJson());
    jsonMap['id'] = 'slide_${DateTime.now().millisecondsSinceEpoch}';
    final duplicatedSlide = SlideData.fromJson(jsonMap);

    setState(() {
      _slides.insert(index + 1, duplicatedSlide);
    });
    _selectSlide(index + 1);
    _savePresentation();
  }

  void _deleteSlide(int index) async {
    if (_slides.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the only slide in the presentation.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: const Text(
          'Delete Slide',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        ),
        content: Text(
          'Are you sure you want to delete Slide ${index + 1}?',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF4B5563), height: 1.4),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(60, 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: const Size(60, 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      int newActiveIndex = _activeSlideIndex;
      if (index == _activeSlideIndex) {
        newActiveIndex = (index >= _slides.length - 1) ? _slides.length - 2 : index;
      } else if (index < _activeSlideIndex) {
        newActiveIndex = _activeSlideIndex - 1;
      }

      setState(() {
        _slides.removeAt(index);
      });
      _selectSlide(newActiveIndex);
      _savePresentation();
    }
  }

  /// Left Sidebar displaying thumbnails of all slides
  Widget _buildSlidesSidebar() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final sidebarBg = isLight ? const Color(0xFFFAFAFA) : const Color(0xFF252526);
    final borderColor = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333);
    final headerTextColor = isLight ? const Color(0xFF6B7280) : const Color(0xFFAAAAAA);

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Icon(Icons.slideshow, size: 16, color: headerTextColor),
                const SizedBox(width: 6),
                Text(
                  'SLIDES (${_slides.length})',
                  style: TextStyle(
                    color: headerTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: 'Add New Slide',
                  color: Colors.white,
                  elevation: 6,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                  surfaceTintColor: Colors.transparent,
                  menuPadding: const EdgeInsets.symmetric(vertical: 4),
                  constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                  icon: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1877F2).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.add, size: 16, color: Color(0xFF1877F2)),
                  ),
                  onSelected: (String slideType) {
                    final registeredSlide = SlideRegistry.get(slideType);
                    final newSlideId = 'slide_${DateTime.now().millisecondsSinceEpoch}';
                    final isCustom = slideType == 'custom_slide';
                    final newSlideMap = {
                      'id': newSlideId,
                      'slideType': slideType,
                      'content': {
                        'title': isCustom ? 'Lorem Ipsum' : registeredSlide.displayName,
                        'subtitle': isCustom ? 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.' : '',
                      },
                    };
                    final newSlideData = SlideData.fromJson(newSlideMap);
                    setState(() {
                      _slides.add(newSlideData);
                      _activeSlideIndex = _slides.length - 1;
                      _updateControllers();
                    });
                    _savePresentation();
                  },
                  itemBuilder: (BuildContext context) {
                    return SlideRegistry.all.map((s) {
                      return PopupMenuItem<String>(
                        value: s.type,
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          s.displayName,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937), fontWeight: FontWeight.w400),
                        ),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.all(12),
              itemCount: _slides.length,
              onReorderItem: (int oldIndex, int newIndex) {
                setState(() {
                  final activeSlide = (_slides.isNotEmpty && _activeSlideIndex < _slides.length)
                      ? _slides[_activeSlideIndex]
                      : null;
                  final item = _slides.removeAt(oldIndex);
                  _slides.insert(newIndex, item);
                  if (activeSlide != null) {
                    _activeSlideIndex = _slides.indexOf(activeSlide);
                  }
                });
                _savePresentation();
              },
              itemBuilder: (context, index) {
                final slide = _slides[index];
                final isSelected = index == _activeSlideIndex;
                final isRegenerating = _regeneratingSlideIndex == index;

                return ReorderableDelayedDragStartListener(
                  key: ValueKey(slide),
                  index: index,
                  child: GestureDetector(
                    onTap: () {
                      _selectSlide(index);
                    },
                    onSecondaryTapUp: (details) {
                      _showSlideContextMenu(details.globalPosition, index);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Drag handle
                          ReorderableDragStartListener(
                            index: index,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.grab,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  size: 16,
                                  color: isLight ? const Color(0xFF9CA3AF) : const Color(0xFF666666),
                                ),
                              ),
                            ),
                          ),
                          // Slide index badge
                          Container(
                            width: 18,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF1877F2)
                                    : (isLight ? const Color(0xFF6B7280) : const Color(0xFF888888)),
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          // Live Thumbnail box with Regeneration & Hidden Badge
                          Expanded(
                            child: Opacity(
                              opacity: slide.isHidden ? 0.5 : 1.0,
                              child: Stack(
                                children: [
                                  SlideThumbnailWidget(
                                    slide: slide,
                                    presentation: widget.presentation.copyWith(logoPath: _effectiveLogoPath),
                                    accentColor: _accentColor,
                                    slideIndex: index,
                                    totalSlides: _slides.length,
                                    isSelected: isSelected,
                                  ),
                                  // Static hidden indicator badge (only shown when slide is hidden)
                                  if (slide.isHidden)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.orangeAccent,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Icon(
                                          Icons.visibility_off,
                                          size: 12,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    if (isRegenerating)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.65),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Color(0xFF00A86B),
                                                ),
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                'Regenerating...',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Center Slide Canvas Editing Area
  Widget _buildCanvasArea() {
    if (_slides.isEmpty || _activeSlideIndex >= _slides.length) {
      return const Center(child: Text('No slide selected'));
    }

    final activeSlide = _slides[_activeSlideIndex];
    final isLight = Theme.of(context).brightness == Brightness.light;
    final canvasBg = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF181818);
    final cardBorder = isLight ? const Color(0xFFE5E7EB) : Colors.white.withValues(alpha: 0.08);

    return Container(
      color: canvasBg,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: cardBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FittedBox(
                fit: BoxFit.contain,
                child: VirtualSlideFrame(
                  slide: activeSlide,
                  presentation: widget.presentation.copyWith(logoPath: _effectiveLogoPath),
                  accentColor: _accentColor,
                  slideIndex: _activeSlideIndex,
                  totalSlides: _slides.length,
                  selectedElementKey: _selectedTextElementKey,
                  onSelectElement: (key) {
                    setState(() {
                      _selectedTextElementKey = key;
                      _showRightSidebar = true;
                    });
                    _syncSelectedTextController();
                  },
                  onDeselect: () {
                    setState(() {
                      _selectedTextElementKey = null;
                    });
                    _syncSelectedTextController();
                  },
                  onImageChanged: (imageKey, path) {
                    setState(() {
                      if (imageKey == 'custom_images_count') {
                        final newCount = int.tryParse(path) ?? 1;
                        if (_selectedTextElementKey != null && _selectedTextElementKey!.startsWith('card_')) {
                          final parts = _selectedTextElementKey!.split('_');
                          if (parts.length >= 2) {
                            final cardNum = int.tryParse(parts[1]);
                            if (cardNum != null && cardNum > newCount) {
                              _selectedTextElementKey = null;
                              _syncSelectedTextController();
                            }
                          }
                        }
                      }
                      activeSlide.setImagePath(imageKey, path);
                    });
                    _savePresentation();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Right Inspector Sidebar for Editing Slide Properties & Content
  Widget _buildRightInspectorSidebar() {
    if (_slides.isEmpty || _activeSlideIndex >= _slides.length) {
      return const SizedBox.shrink();
    }

    final activeSlide = _slides[_activeSlideIndex];
    final isLight = Theme.of(context).brightness == Brightness.light;

    final sidebarBg = isLight ? const Color(0xFFFAFAFA) : const Color(0xFF252526);
    final borderColor = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF333333);
    final cardBg = isLight ? Colors.white : const Color(0xFF1E1E1E);
    final cardBorder = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF3A3A3A);
    final textColor = isLight ? const Color(0xFF111827) : Colors.white;
    final hintColor = isLight ? const Color(0xFF9CA3AF) : const Color(0xFF555555);
    final subtextColor = isLight ? const Color(0xFF6B7280) : const Color(0xFFAAAAAA);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          left: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [


          // Scrollable Editor Properties Controls
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [


                  if (activeSlide.slideType == 'custom_slide') ...[
                    _buildSectionHeader('CUSTOM SLIDE IMAGES & LAYOUT'),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        final rawCount = activeSlide.rawContent['custom_images_count'];
                        int count = 1;
                        if (rawCount is int) count = rawCount.clamp(1, 6);
                        if (rawCount is String) count = (int.tryParse(rawCount) ?? 1).clamp(1, 6);
                        final mode = activeSlide.rawContent['custom_layout_mode']?.toString() ?? 'auto';

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Slots',
                                    style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '$count / 6',
                                    style: TextStyle(color: _accentColor, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: List.generate(6, (i) {
                                  final num = i + 1;
                                  final isCurrent = num == count;
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(right: i == 5 ? 0 : 4),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (num < count) {
                                              for (int s = num; s < 6; s++) {
                                                activeSlide.flushCustomSlot(s);
                                              }
                                              if (_selectedTextElementKey != null && _selectedTextElementKey!.startsWith('card_')) {
                                                final parts = _selectedTextElementKey!.split('_');
                                                if (parts.length >= 2) {
                                                  final cardNum = int.tryParse(parts[1]);
                                                  if (cardNum != null && cardNum > num) {
                                                    _selectedTextElementKey = null;
                                                    _syncSelectedTextController();
                                                  }
                                                }
                                              }
                                            }
                                            activeSlide.setImagePath('custom_images_count', '$num');
                                          });
                                          PaintingBinding.instance.imageCache.clear();
                                          PaintingBinding.instance.imageCache.clearLiveImages();
                                          _savePresentation();
                                        },
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isCurrent ? _accentColor : (isLight ? const Color(0xFFF3F4F6) : const Color(0xFF2C3847)),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: isCurrent ? _accentColor : cardBorder,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$num',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                              color: isCurrent ? Colors.white : textColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Layout Arrangement',
                                style: TextStyle(color: subtextColor, fontSize: 11.5),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  {'key': 'auto', 'label': 'Auto', 'icon': Icons.auto_awesome_mosaic_rounded},
                                  {'key': 'columns', 'label': 'Columns', 'icon': Icons.view_column_rounded},
                                  {'key': 'grid', 'label': 'Grid', 'icon': Icons.grid_view_rounded},
                                  {'key': 'hero', 'label': 'Hero Split', 'icon': Icons.splitscreen_rounded},
                                  {'key': 'rows', 'label': 'Rows', 'icon': Icons.table_rows_rounded},
                                ].map((opt) {
                                  final optKey = opt['key'] as String;
                                  final optLabel = opt['label'] as String;
                                  final optIcon = opt['icon'] as IconData;
                                  final isSelected = mode == optKey;

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        activeSlide.setImagePath('custom_layout_mode', optKey);
                                      });
                                      _savePresentation();
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isSelected ? _accentColor.withValues(alpha: isLight ? 0.15 : 0.25) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected ? _accentColor : cardBorder,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(optIcon, size: 13, color: isSelected ? _accentColor : subtextColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            optLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? _accentColor : textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Slot Content Types',
                                style: TextStyle(color: subtextColor, fontSize: 11.5),
                              ),
                              const SizedBox(height: 6),
                              Column(
                                children: List.generate(count, (i) {
                                  final slotKey = 'custom_slot_${i}_type';
                                  final currentType = activeSlide.rawContent[slotKey]?.toString() ?? 'image';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 48,
                                          child: Text(
                                            'Slot ${i + 1}',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: textColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              {'type': 'image', 'label': 'Image', 'icon': Icons.image_outlined},
                                              {'type': 'text', 'label': 'Text', 'icon': Icons.article_outlined},
                                              {'type': 'both', 'label': 'Both', 'icon': Icons.vertical_split_rounded},
                                            ].map((t) {
                                              final tType = t['type'] as String;
                                              final tLabel = t['label'] as String;
                                              final tIcon = t['icon'] as IconData;
                                              final isSel = currentType == tType;

                                              return Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                                  child: InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        activeSlide.setImagePath(slotKey, tType);
                                                      });
                                                      _savePresentation();
                                                    },
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: isSel
                                                            ? _accentColor.withValues(alpha: isLight ? 0.15 : 0.28)
                                                            : (isLight ? const Color(0xFFF3F4F6) : const Color(0xFF2C3847)),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(
                                                          color: isSel ? _accentColor : cardBorder,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            tIcon,
                                                            size: 11,
                                                            color: isSel ? _accentColor : subtextColor,
                                                          ),
                                                          const SizedBox(width: 3),
                                                          Text(
                                                            tLabel,
                                                            style: TextStyle(
                                                              fontSize: 10.5,
                                                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                                              color: isSel ? _accentColor : textColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                             }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 1. DYNAMIC SELECTED TEXT CONTENT EDITING SECTION
                  _buildSectionHeader('SELECTED TEXT CONTENT'),
                  const SizedBox(height: 10),

                  Builder(
                    builder: (context) {
                      final key = _selectedTextElementKey;
                      final bool isBaseKeyGroup = key == 'card_title' || key == 'card_subtitle' || key == 'card_bullet' || key == 'card_outcome_title' || key == 'card_outcome_text' || key == 'card_outcome_icon' || key == 'pilot_step_name' || key == 'pilot_step_desc' || key == 'body' || key == 'metric_val' || key == 'diagram_label' || key == 'agent_title' || key == 'agent_sub' || key == 'agent_item' || key == 'agent_icon' || key == 'feat_title' || key == 'feat_desc' || key == 'feat_icon' || key == 'ctx_title' || key == 'ctx_desc' || key == 'ctx_icon' || key == 'act_title' || key == 'act_desc' || key == 'act_icon' || key == 'wellness_step' || key == 'wellness_step_icon';
                      final bool isSelected = key != null;
                      final bool canEditContent = isSelected && !isBaseKeyGroup;

                      return Opacity(
                        opacity: canEditContent ? 1.0 : 0.4,
                        child: IgnorePointer(
                          ignoring: !canEditContent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBaseKeyGroup
                                    ? 'Mass Editing Formatting (Click item again to edit text)'
                                    : (key != null
                                        ? 'Edit Selected Text (${key.replaceAll('_', ' ').toUpperCase()})'
                                        : 'Edit Selected Text Content'),
                                style: TextStyle(color: subtextColor, fontSize: 11.5),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _selectedTextController,
                                onChanged: _onSelectedTextChanged,
                                maxLines: 4,
                                minLines: 2,
                                style: TextStyle(color: textColor, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: cardBg,
                                  hintText: isBaseKeyGroup
                                      ? 'All ${(key ?? '').replaceAll('_', ' ').toUpperCase()} items selected. Click again or double-click to edit specific text.'
                                      : (key != null
                                          ? 'Type to edit selected text...'
                                          : 'Click any text on canvas to edit...'),
                                  hintStyle: TextStyle(color: hintColor, fontSize: 12),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: cardBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: Color(0xFF1877F2)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // 2. TEXT FORMATTING & STYLING (FONT SIZE & WEIGHT)
                  _buildSectionHeader('TEXT FORMATTING & STYLING'),
                  const SizedBox(height: 8),

                  if (_selectedTextElementKey == null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.touch_app_outlined, size: 18, color: hintColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Single-click selects ALL items of a type for mass formatting. Click again or double-click to edit a specific item.',
                              style: TextStyle(color: hintColor, fontSize: 11.5, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Builder(
                      builder: (context) {
                        final key = _selectedTextElementKey!;
                        final bool isBaseKeyGroup = key == 'card_title' || key == 'card_subtitle' || key == 'card_bullet' || key == 'card_outcome_title' || key == 'card_outcome_text' || key == 'card_outcome_icon' || key == 'pilot_step_name' || key == 'pilot_step_desc' || key == 'body' || key == 'metric_val' || key == 'diagram_label' || key == 'agent_title' || key == 'agent_sub' || key == 'agent_item' || key == 'agent_icon' || key == 'feat_title' || key == 'feat_desc' || key == 'feat_icon' || key == 'ctx_title' || key == 'ctx_desc' || key == 'ctx_icon' || key == 'act_title' || key == 'act_desc' || key == 'act_icon' || key == 'wellness_step' || key == 'wellness_step_icon';
                        final badgeLabel = isBaseKeyGroup
                            ? 'SELECTED: ALL ${key.replaceAll('_', ' ').toUpperCase()} ITEMS (MASS FORMATTING)'
                            : 'SELECTED: ${key.replaceAll('_', ' ').toUpperCase()} (SPECIFIC ITEM)';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1877F2).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF1877F2).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 14, color: Color(0xFF1877F2)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  badgeLabel,
                                  style: const TextStyle(
                                    color: Color(0xFF1877F2),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InkWell(
                                onTap: () => setState(() => _selectedTextElementKey = null),
                                child: Icon(Icons.close, size: 14, color: subtextColor),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  Opacity(
                    opacity: _selectedTextElementKey != null ? 1.0 : 0.35,
                    child: IgnorePointer(
                      ignoring: _selectedTextElementKey == null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Font Size Control
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                (_selectedTextElementKey != null &&
                                        (_selectedTextElementKey!.contains('icon') ||
                                         _selectedTextElementKey!.startsWith('card_icon') ||
                                         _selectedTextElementKey!.startsWith('feature_icon') ||
                                         _selectedTextElementKey!.startsWith('list_icon') ||
                                         _selectedTextElementKey!.startsWith('process_icon') ||
                                         _selectedTextElementKey!.startsWith('eco_icon') ||
                                         _selectedTextElementKey!.startsWith('sol_icon')))
                                    ? 'Icon Size'
                                    : 'Font Size',
                                style: TextStyle(color: subtextColor, fontSize: 11.5),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                    onPressed: () {
                                      if (_selectedTextElementKey != null) {
                                        final key = _selectedTextElementKey!;
                                        final current = activeSlide.getFontSize(key, _getDefaultFontSize(key));
                                        if (current > 10) {
                                          setState(() {
                                            activeSlide.setFontSize(key, current - 2);
                                          });
                                          _savePresentation();
                                        }
                                      }
                                    },
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: cardBorder),
                                    ),
                                    child: Text(
                                      _selectedTextElementKey != null
                                          ? '${activeSlide.getFontSize(_selectedTextElementKey!, _getDefaultFontSize(_selectedTextElementKey!)).round()} px'
                                          : '-- px',
                                      style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                    onPressed: () {
                                      if (_selectedTextElementKey != null) {
                                        final key = _selectedTextElementKey!;
                                        final current = activeSlide.getFontSize(key, _getDefaultFontSize(key));
                                        if (current < 120) {
                                          setState(() {
                                            activeSlide.setFontSize(key, current + 2);
                                          });
                                          _savePresentation();
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Slider(
                            value: _selectedTextElementKey != null
                                ? activeSlide.getFontSize(_selectedTextElementKey!, _getDefaultFontSize(_selectedTextElementKey!)).clamp(10.0, 100.0)
                                : 30.0,
                            min: 10.0,
                            max: 100.0,
                            divisions: 90,
                            activeColor: const Color(0xFF1877F2),
                            onChanged: (val) {
                              if (_selectedTextElementKey != null) {
                                setState(() {
                                  activeSlide.setFontSize(_selectedTextElementKey!, val);
                                });
                                _savePresentation();
                              }
                            },
                          ),

                          const SizedBox(height: 12),

                          // Font Weight Chips
                          Text('Font Weight', style: TextStyle(color: subtextColor, fontSize: 11.5)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildFontWeightChip(activeSlide, 'Normal (400)', FontWeight.w400),
                              _buildFontWeightChip(activeSlide, 'Medium (500)', FontWeight.w500),
                              _buildFontWeightChip(activeSlide, 'SemiBold (600)', FontWeight.w600),
                              _buildFontWeightChip(activeSlide, 'Bold (700)', FontWeight.w700),
                              _buildFontWeightChip(activeSlide, 'ExtraBold (800)', FontWeight.w800),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Alignment Selector
                  Text('Text Alignment', style: TextStyle(color: subtextColor, fontSize: 11.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildAlignButton(
                        icon: Icons.format_align_left,
                        align: TextAlign.left,
                        currentAlign: activeSlide.textAlign,
                      ),
                      const SizedBox(width: 8),
                      _buildAlignButton(
                        icon: Icons.format_align_center,
                        align: TextAlign.center,
                        currentAlign: activeSlide.textAlign,
                      ),
                      const SizedBox(width: 8),
                      _buildAlignButton(
                        icon: Icons.format_align_right,
                        align: TextAlign.right,
                        currentAlign: activeSlide.textAlign,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 5. ACCENT THEME SECTION
                  _buildSectionHeader('ACCENT THEME'),
                  const SizedBox(height: 10),
                  CustomColorPickerWidget(
                    initialColor: _accentColor,
                    onColorChanged: (newColor) {
                      setState(() {
                        _accentColor = newColor;
                      });
                      _savePresentation();
                    },
                  ),

                  const SizedBox(height: 20),

                  // 6. ICON SELECTION SECTION
                  _buildSectionHeader('ICON SELECTION'),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final key = _selectedTextElementKey;
                      final bool isIconSelected = key != null &&
                          (key.contains('icon') || key.startsWith('card_icon') || key.startsWith('feature_icon') || key.startsWith('list_icon') || key.startsWith('process_icon') || key.startsWith('eco_icon') || key.startsWith('sol_icon'));

                      final filteredIcons = availableIconsMap.entries.where((entry) {
                        if (_iconSearchQuery.isEmpty) return true;
                        final q = _iconSearchQuery.toLowerCase();
                        return entry.key.toLowerCase().contains(q);
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isIconSelected
                                ? 'Selected: ${key.replaceAll('_', ' ').toUpperCase()}. Tap icon to swap:'
                                : 'Click any icon on canvas to select and change:',
                            style: TextStyle(color: subtextColor, fontSize: 11.5),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            onChanged: (val) {
                              setState(() {
                                _iconSearchQuery = val.trim();
                              });
                            },
                            style: TextStyle(color: textColor, fontSize: 12),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Search 90+ icons (e.g. phone, chart, ai)...',
                              hintStyle: TextStyle(color: hintColor, fontSize: 11.5),
                              prefixIcon: Icon(Icons.search, size: 14, color: hintColor),
                              filled: true,
                              fillColor: cardBg,
                              contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: Color(0xFF1877F2)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (filteredIcons.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No matching icons found',
                                style: TextStyle(color: hintColor, fontSize: 11.5, fontStyle: FontStyle.italic),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              height: 185,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF1B232D),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Scrollbar(
                                controller: _iconScrollController,
                                thumbVisibility: true,
                                interactive: true,
                                child: SingleChildScrollView(
                                  controller: _iconScrollController,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: filteredIcons.map((entry) {
                                      final iconName = entry.key;
                                      final iconData = entry.value;
                                      final isCurrentIcon = _selectedTextElementKey != null &&
                                          activeSlide.getIcon(_selectedTextElementKey!, Icons.star) == iconData;

                                      return InkWell(
                                        onTap: () {
                                          if (_selectedTextElementKey != null) {
                                            setState(() {
                                              activeSlide.setIcon(_selectedTextElementKey!, iconName);
                                            });
                                            _savePresentation();
                                          } else {
                                            // Mass fallback if nothing selected
                                            setState(() {
                                              activeSlide.setIcon('card_icon', iconName);
                                              activeSlide.setIcon('feature_icon', iconName);
                                              activeSlide.setIcon('list_icon', iconName);
                                              activeSlide.setIcon('process_icon', iconName);
                                              activeSlide.setIcon('eco_icon', iconName);
                                              activeSlide.setIcon('sol_icon', iconName);
                                            });
                                            _savePresentation();
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Tooltip(
                                          message: iconName.replaceAll('_', ' '),
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: isCurrentIcon ? const Color(0xFF1877F2).withValues(alpha: 0.2) : cardBg,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isCurrentIcon ? const Color(0xFF1877F2) : cardBorder,
                                                width: isCurrentIcon ? 1.8 : 1.0,
                                              ),
                                            ),
                                            child: Icon(
                                              iconData,
                                              size: 18,
                                              color: isCurrentIcon ? const Color(0xFF1877F2) : textColor,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),


                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Text(
      title,
      style: TextStyle(
        color: isLight ? const Color(0xFF6B7280) : const Color(0xFF888888),
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildAlignButton({
    required IconData icon,
    required TextAlign align,
    required TextAlign currentAlign,
  }) {
    final isSelected = align == currentAlign;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Expanded(
      child: InkWell(
        onTap: () => _onTextAlignChanged(align),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1877F2)
                : (isLight ? Colors.white : const Color(0xFF1E1E1E)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1877F2)
                  : (isLight ? const Color(0xFFE5E7EB) : const Color(0xFF3A3A3A)),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : (isLight ? const Color(0xFF4B5563) : const Color(0xFF888888)),
          ),
        ),
      ),
    );
  }
}

class HoverDynamicCountControls extends StatefulWidget {
  final int count;
  final int minCount;
  final int maxCount;
  final String addLabel;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final Widget child;
  final Color accentColor;

  const HoverDynamicCountControls({
    super.key,
    required this.count,
    this.minCount = 1,
    this.maxCount = 4,
    required this.addLabel,
    required this.onDecrement,
    required this.onIncrement,
    required this.child,
    required this.accentColor,
  });

  @override
  State<HoverDynamicCountControls> createState() => _HoverDynamicCountControlsState();
}

class _HoverDynamicCountControlsState extends State<HoverDynamicCountControls> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_isHovered)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF1E293B).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.count > widget.minCount)
                      InkWell(
                        onTap: widget.onDecrement,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.remove, size: 12, color: Colors.redAccent),
                        ),
                      ),
                    if (widget.count > widget.minCount && widget.count < widget.maxCount)
                      const SizedBox(width: 4),
                    if (widget.count < widget.maxCount)
                      InkWell(
                        onTap: widget.onIncrement,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: widget.accentColor.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 12, color: widget.accentColor),
                              const SizedBox(width: 2),
                              Text(
                                widget.addLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: widget.accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Comprehensive Renderer Dispatcher for all 15 Slide Types
class RenderSlideContent extends StatelessWidget {
  final SlideData slide;
  final Color accentColor;
  final bool isEditing;
  final String? folderPath;
  final String? companyLogoPath;
  final String? companyName;
  final TextEditingController? titleController;
  final TextEditingController? subtitleController;
  final Function(String)? onTitleChanged;
  final Function(String)? onSubtitleChanged;
  final String? selectedElementKey;
  final Function(String key)? onSelectElement;
  final Function(String imageKey, String path)? onImageChanged;

  const RenderSlideContent({
    super.key,
    required this.slide,
    required this.accentColor,
    this.isEditing = false,
    this.folderPath,
    this.companyLogoPath,
    this.companyName,
    this.titleController,
    this.subtitleController,
    this.onTitleChanged,
    this.onSubtitleChanged,
    this.selectedElementKey,
    this.onSelectElement,
    this.onImageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final renderContext = SlideRenderContext(
      slide: slide,
      accentColor: accentColor,
      isEditing: isEditing,
      folderPath: folderPath,
      companyLogoPath: companyLogoPath,
      companyName: companyName,
      titleController: titleController,
      subtitleController: subtitleController,
      onTitleChanged: onTitleChanged,
      onSubtitleChanged: onSubtitleChanged,
      selectedElementKey: selectedElementKey,
      onSelectElement: onSelectElement,
      onImageChanged: onImageChanged,
      buildTitleHeaderCallback: (ctx) => _buildTitleHeader(ctx),
    );

    return SlideRegistry.get(slide.slideType).build(renderContext);
  }

  Widget _buildTitleHeader(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final titleColor = isLight ? const Color(0xFF111827) : Colors.white;
    final subtitleColor = isLight ? const Color(0xFF4B5563) : const Color(0xFFB0B0B0);

    final titleFontSize = slide.getFontSize('title', 36.0);
    final titleFontWeight = slide.getFontWeight('title', FontWeight.bold);
    final subtitleFontSize = slide.getFontSize('subtitle', 20.0);
    final subtitleFontWeight = slide.getFontWeight('subtitle', FontWeight.normal);

    final crossAlign = slide.textAlign == TextAlign.center
        ? CrossAxisAlignment.center
        : (slide.textAlign == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start);

    if (isEditing && titleController != null && subtitleController != null) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: crossAlign,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: titleController,
                onChanged: onTitleChanged,
                textAlign: slide.textAlign,
                maxLines: 2,
                minLines: 1,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                decoration: const InputDecoration(
                  hintText: 'Enter Slide Title...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (slide.subtitle.isNotEmpty || subtitleController!.text.isNotEmpty) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: subtitleController,
                  onChanged: onSubtitleChanged,
                  textAlign: slide.textAlign,
                  maxLines: 2,
                  minLines: 1,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 13,
                    height: 1.25,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter Subtitle...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: crossAlign,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: SelectableTextElement(
              elementKey: 'title',
              label: 'Slide Title',
              selectedElementKey: selectedElementKey,
              onSelectElement: onSelectElement,
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  slide.getElementText('title', slide.title),
                  textAlign: slide.textAlign,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: titleFontSize,
                    fontWeight: titleFontWeight,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
          if (slide.subtitle.isNotEmpty || slide.getElementText('subtitle', '').isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SelectableTextElement(
                elementKey: 'subtitle',
                label: 'Subtitle',
                selectedElementKey: selectedElementKey,
                onSelectElement: onSelectElement,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    slide.getElementText('subtitle', slide.subtitle),
                    textAlign: slide.textAlign,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: subtitleFontSize,
                      fontWeight: subtitleFontWeight,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}



class HeroDiagramWidget extends StatelessWidget {
  final Map<String, dynamic>? rawContent;
  final String? companyLogoPath;
  final String? companyName;
  final String? folderPath;

  const HeroDiagramWidget({
    super.key,
    this.rawContent,
    this.companyLogoPath,
    this.companyName,
    this.folderPath,
  });

  @override
  Widget build(BuildContext context) {
    const double svgMinX = 66.0;
    const double svgMinY = 5.0;
    const double svgWidth = 1188.0;
    const double svgHeight = 380.0;

    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.center,
      child: Transform.scale(
        scale: 1.48,
        child: SizedBox(
          width: svgWidth,
          height: svgHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const CustomPaint(
                size: Size(svgWidth, svgHeight),
                painter: _HeroDiagramPainter(
                  animationValue: 0.5,
                  minX: svgMinX,
                  minY: svgMinY,
                ),
              ),
              ..._buildNodes(svgMinX, svgMinY),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNodes(double minX, double minY) {
    Widget pillGroup(double x, double y, double w, double h, String text, {double fontSize = 13, FontWeight fontWeight = FontWeight.w500}) {
      return Positioned(
        left: x - minX,
        top: y - minY,
        width: w,
        height: h,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(h / 2),
            border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF333D47),
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        ),
      );
    }

    Widget iconCircle(double cx, double cy, double r, String assetPath, double iconSize) {
      return Positioned(
        left: (cx - r) - minX,
        top: (cy - r) - minY,
        width: r * 2,
        height: r * 2,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE6E8EB), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Image.asset(
            assetPath,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, stack) => Icon(Icons.crop_square, size: iconSize * 0.7, color: Colors.grey),
          ),
        ),
      );
    }

    Widget imageNode(double x, double y, double w, double h, String assetPath) {
      return Positioned(
        left: x - minX,
        top: y - minY,
        width: w,
        height: h,
        child: Image.asset(
          assetPath,
          width: w,
          height: h,
          fit: BoxFit.contain,
          errorBuilder: (ctx, err, stack) => Icon(Icons.image, size: w * 0.5, color: Colors.grey),
        ),
      );
    }

    Widget companyLogoNode(double x, double y, double w, double h) {
      final logoPath = (companyLogoPath != null && companyLogoPath!.isNotEmpty)
          ? companyLogoPath!
          : 'assets/presets/logo_presets/heydoc.png';
      final cName = companyName ?? '';

      Widget childWidget = buildUniversalImage(
        logoPath,
        width: w,
        height: h,
        fit: BoxFit.contain,
        presentationId: folderPath ?? '',
        fallback: cName.isNotEmpty
            ? Text(
                cName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF4753DF),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              )
            : const SizedBox.shrink(),
      );

      return Positioned(
        left: x - minX,
        top: y - minY,
        width: w,
        height: h,
        child: Center(child: childWidget),
      );
    }

    return [
      // Column Headers
      Positioned(
        left: 380 - 100 - minX,
        top: 10 - minY,
        width: 200,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('COMPANY', style: TextStyle(color: Color(0xFF2F80FF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
            Text('AGENTS', style: TextStyle(color: Color(0xFF2F80FF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
          ],
        ),
      ),
      Positioned(
        left: 840 - 100 - minX,
        top: 10 - minY,
        width: 200,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('CONSUMER', style: TextStyle(color: Color(0xFF6F57FF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
            Text('AGENTS', style: TextStyle(color: Color(0xFF6F57FF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
          ],
        ),
      ),

      // Left Column 1: Labels
      pillGroup(70, 72, 130, 36, "Hospital chains"),
      pillGroup(70, 162, 130, 36, "Health insurance"),
      pillGroup(70, 252, 130, 36, "Preventive care"),
      pillGroup(70, 342, 130, 36, "Digital Health"),

      // Left Column 2: Hospitals
      iconCircle(245, 90, 22, 'assets/hero/hospital.png', 36),
      iconCircle(245, 180, 22, 'assets/hero/hospital.png', 36),
      iconCircle(245, 270, 22, 'assets/hero/hospital.png', 36),
      iconCircle(245, 360, 22, 'assets/hero/hospital.png', 36),

      // Left Column 3: Internal Agents
      imageNode(356, 66, 48, 48, 'assets/hero/internal-agent.png'),
      imageNode(356, 156, 48, 48, 'assets/hero/internal-agent.png'),
      imageNode(356, 246, 48, 48, 'assets/hero/internal-agent.png'),
      imageNode(356, 336, 48, 48, 'assets/hero/internal-agent.png'),

      // Center: Brain & Company Logo
      imageNode(570, 155, 140, 140, 'assets/hero/brain.png'),
      companyLogoNode(590, 300, 100, 60),
      Positioned(
        left: 640 - 100 - minX,
        top: 365 - minY,
        width: 200,
        child: const Text(
          'BRAIN',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF4753DF),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 6,
          ),
        ),
      ),

      // Right Column 1: External Agents
      imageNode(816, 66, 48, 48, 'assets/hero/external-agent.png'),
      imageNode(816, 201, 48, 48, 'assets/hero/external-agent.png'),
      imageNode(816, 336, 48, 48, 'assets/hero/external-agent.png'),

      // Right Column 2: Modalities
      iconCircle(960, 90, 20, 'assets/hero/text.png', 28),
      iconCircle(960, 225, 20, 'assets/hero/audio.png', 28),
      iconCircle(960, 360, 20, 'assets/hero/video.png', 28),

      // Right Column 3: Consumers/Users
      iconCircle(1080, 90, 22, 'assets/hero/consumer.png', 36),
      iconCircle(1080, 158, 22, 'assets/hero/consumer.png', 36),
      iconCircle(1080, 225, 22, 'assets/hero/consumer.png', 36),
      iconCircle(1080, 292, 22, 'assets/hero/consumer.png', 36),
      iconCircle(1080, 360, 22, 'assets/hero/consumer.png', 36),

      // Right Column 4: User Labels
      pillGroup(1140, 74, 110, 32, "User"),
      pillGroup(1140, 142, 110, 32, "उपयोगकर्ता"),
      pillGroup(1140, 209, 110, 32, "Utilisateur"),
      pillGroup(1140, 276, 110, 32, "مستخدم", fontSize: 15, fontWeight: FontWeight.w400),
      pillGroup(1140, 344, 110, 32, "ユーザー"),
    ];
  }
}

class _HeroDiagramPainter extends CustomPainter {
  final double animationValue;
  final double minX;
  final double minY;

  const _HeroDiagramPainter({required this.animationValue, required this.minX, required this.minY});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFA8A5B5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final blueDotPaint = Paint()
      ..color = const Color(0xFF60B3F7)
      ..style = PaintingStyle.fill;

    final cyanDotPaint = Paint()
      ..color = const Color(0xFF96F2E9)
      ..style = PaintingStyle.fill;

    final purpleDotPaint = Paint()
      ..color = const Color(0xFF9D8AE6)
      ..style = PaintingStyle.fill;

    double tx(double x) => x - minX;
    double ty(double y) => y - minY;

    final List<Path> hospPaths = [
      Path()..moveTo(tx(267), ty(90))..lineTo(tx(356), ty(90)),
      Path()..moveTo(tx(267), ty(180))..lineTo(tx(356), ty(180)),
      Path()..moveTo(tx(267), ty(270))..lineTo(tx(356), ty(270)),
      Path()..moveTo(tx(267), ty(360))..lineTo(tx(356), ty(360)),
    ];

    final List<Path> agentPaths = [
      Path()..moveTo(tx(404), ty(90))..lineTo(tx(480), ty(90))..quadraticBezierTo(tx(490), ty(90), tx(490), ty(100))..lineTo(tx(490), ty(215))..quadraticBezierTo(tx(490), ty(225), tx(500), ty(225))..lineTo(tx(570), ty(225)),
      Path()..moveTo(tx(404), ty(180))..lineTo(tx(480), ty(180))..quadraticBezierTo(tx(490), ty(180), tx(490), ty(190))..lineTo(tx(490), ty(215))..quadraticBezierTo(tx(490), ty(225), tx(500), ty(225))..lineTo(tx(570), ty(225)),
      Path()..moveTo(tx(404), ty(270))..lineTo(tx(480), ty(270))..quadraticBezierTo(tx(490), ty(270), tx(490), ty(260))..lineTo(tx(490), ty(235))..quadraticBezierTo(tx(490), ty(225), tx(500), ty(225))..lineTo(tx(570), ty(225)),
      Path()..moveTo(tx(404), ty(360))..lineTo(tx(480), ty(360))..quadraticBezierTo(tx(490), ty(360), tx(490), ty(350))..lineTo(tx(490), ty(235))..quadraticBezierTo(tx(490), ty(225), tx(500), ty(225))..lineTo(tx(570), ty(225)),
    ];

    final List<Path> brainPaths = [
      Path()..moveTo(tx(710), ty(225))..lineTo(tx(740), ty(225))..quadraticBezierTo(tx(750), ty(225), tx(750), ty(215))..lineTo(tx(750), ty(100))..quadraticBezierTo(tx(750), ty(90), tx(760), ty(90))..lineTo(tx(816), ty(90)),
      Path()..moveTo(tx(710), ty(225))..lineTo(tx(816), ty(225)),
      Path()..moveTo(tx(710), ty(225))..lineTo(tx(740), ty(225))..quadraticBezierTo(tx(750), ty(225), tx(750), ty(235))..lineTo(tx(750), ty(350))..quadraticBezierTo(tx(750), ty(360), tx(760), ty(360))..lineTo(tx(816), ty(360)),
    ];

    final List<Path> extPaths = [
      Path()..moveTo(tx(864), ty(90))..lineTo(tx(940), ty(90)),
      Path()..moveTo(tx(864), ty(225))..lineTo(tx(940), ty(225)),
      Path()..moveTo(tx(864), ty(360))..lineTo(tx(940), ty(360)),
    ];

    final List<Path> modPaths = [
      Path()..moveTo(tx(980), ty(90))..lineTo(tx(1025), ty(90)),
      Path()..moveTo(tx(980), ty(225))..lineTo(tx(1025), ty(225)),
      Path()..moveTo(tx(980), ty(360))..lineTo(tx(1025), ty(360)),
    ];

    final allPaths = [...hospPaths, ...agentPaths, ...brainPaths, ...extPaths, ...modPaths];
    for (final p in allPaths) {
      _drawDashedPath(canvas, p, linePaint, dashWidth: 6, dashSpace: 4);
    }

    final arrowPaint = Paint()
      ..color = const Color(0xFFA8A5B5)
      ..style = PaintingStyle.fill;

    for (final y in [90.0, 225.0, 360.0]) {
      final path = Path()
        ..moveTo(tx(1025), ty(y))
        ..lineTo(tx(1017), ty(y) - 3.5)
        ..lineTo(tx(1017), ty(y) + 3.5)
        ..close();
      canvas.drawPath(path, arrowPaint);
    }

    final hospSpeeds = [1.0, 0.85, 0.95, 0.78];
    for (int i = 0; i < hospPaths.length; i++) {
      final offset = (animationValue * hospSpeeds[i] + i * 0.25) % 1.0;
      _drawDotOnPath(canvas, hospPaths[i], offset, blueDotPaint, 4);
    }

    final agentSpeeds = [0.9, 0.75, 0.82, 0.7];
    for (int i = 0; i < agentPaths.length; i++) {
      final offset = (animationValue * agentSpeeds[i] + i * 0.2) % 1.0;
      _drawDotOnPath(canvas, agentPaths[i], offset, blueDotPaint, 4);
    }

    final brainSpeeds = [0.85, 0.95, 0.8];
    for (int i = 0; i < brainPaths.length; i++) {
      final offset = (animationValue * brainSpeeds[i] + i * 0.3) % 1.0;
      _drawDotOnPath(canvas, brainPaths[i], offset, cyanDotPaint, 4);
    }

    final extSpeeds = [1.1, 1.25, 1.0];
    for (int i = 0; i < extPaths.length; i++) {
      final offset = (animationValue * extSpeeds[i] + i * 0.33) % 1.0;
      _drawDotOnPath(canvas, extPaths[i], offset, purpleDotPaint, 4);
    }

    final modSpeeds = [1.3, 1.4, 1.2];
    for (int i = 0; i < modPaths.length; i++) {
      final offset = (animationValue * modSpeeds[i] + i * 0.33) % 1.0;
      _drawDotOnPath(canvas, modPaths[i], offset, purpleDotPaint, 4);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, {required double dashWidth, required double dashSpace}) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + dashWidth < metric.length) ? dashWidth : metric.length - distance;
        final Path extract = metric.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  void _drawDotOnPath(Canvas canvas, Path path, double progress, Paint paint, double radius) {
    for (final metric in path.computeMetrics()) {
      final tangent = metric.getTangentForOffset((progress * metric.length) % metric.length);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeroDiagramPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Exact macOS Console Mockup UI Widget for feature_list_with_mockup (Enlarged High-Visibility Replica of mac-mockup/index.html)
class MacOsMockupHtmlWidget extends StatelessWidget {
  final String? companyName;
  final String htmlFilePath;
  final Color accentColor;
  final Function(String path)? onSelectHtmlFile;

  const MacOsMockupHtmlWidget({
    super.key,
    this.companyName,
    required this.htmlFilePath,
    required this.accentColor,
    this.onSelectHtmlFile,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final String displayCompany = (companyName != null && companyName!.trim().isNotEmpty) ? companyName!.trim() : 'Pathkind Labs';

    final words = displayCompany.split(' ');
    final String firstPart = words.length > 1 ? '${words.sublist(0, words.length - 1).join(' ')} ' : displayCompany;
    final String lastPart = words.length > 1 ? words.last : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.18 : 0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // 1. macOS Window Title Bar (Traffic Lights + Centered Title + macOS Badge)
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
              child: Row(
                children: [
                  // Traffic Light buttons
                  Row(
                    children: [
                      Container(width: 15, height: 15, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Container(width: 15, height: 15, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Container(width: 15, height: 15, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
                    ],
                  ),

                  // Window Title
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.layers, size: 16, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          '$displayCompany â€” Care Assistant Console',
                          style: TextStyle(
                            color: isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // macOS label
                  const Text(
                    'macOS',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // 2. App Navigation Bar (Logo + Brand Title + Connected Status)
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF1E1E1E),
                border: Border(bottom: BorderSide(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF333333))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check, size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 18, color: isLight ? Colors.black : Colors.white),
                          children: [
                            TextSpan(text: firstPart, style: const TextStyle(fontWeight: FontWeight.w900)),
                            if (lastPart.isNotEmpty)
                              TextSpan(text: lastPart, style: TextStyle(fontWeight: FontWeight.w900, color: accentColor)),
                            const TextSpan(text: '  |  ', style: TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w300)),
                            const TextSpan(text: 'Care Assistant', style: TextStyle(color: Color(0xFF475569), fontSize: 15.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text(
                        'Connected',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Main Workspace Grid (Left Sidebar + Center Console + Right Sidebar)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ================= LEFT SIDEBAR =================
                  Container(
                    width: 220,
                    padding: const EdgeInsets.all(12),
                    color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF181818),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('VOICE AGENTS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.0)),
                          const SizedBox(height: 8),
                          _buildAgentCard('Symptom Triage Agent', 'Directs symptoms to packages', Icons.favorite, isLight),
                          _buildAgentCard('Lab Booking Agent', 'Books tests & recommendations', Icons.calendar_today, isLight),
                          _buildAgentCard('Track Sample Agent', 'Calculates phlebotomist ETA', Icons.local_shipping, isLight),
                          _buildAgentCard('Report Explainer Agent', 'Simplifies medical jargon', Icons.article, isLight),

                          const SizedBox(height: 14),
                          const Text('TEXT AGENTS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.0)),
                          const SizedBox(height: 8),
                          // Active Text Agent Card
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.chat_bubble, size: 16, color: accentColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Text Agent Orchestrator', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: accentColor)),
                                      const SizedBox(height: 2),
                                      const Text('Smart Multi-Agent Chat', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),
                          Text('WHY ${displayCompany.toUpperCase()}?', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.0)),
                          const SizedBox(height: 8),
                          _buildBenefitItem('One-Prick Home Collection', 'Trained, hygienic experts collect samples at doorstep.'),
                          _buildBenefitItem('Cold-Chain Sealed Bags', 'Transit in temperature-controlled bags (2-8Â°C).'),
                          _buildBenefitItem('Smart Pathology Reports', 'Verified by MD Pathologists in 12-24 hours.'),
                        ],
                      ),
                    ),
                  ),

                  // Vertical divider
                  Container(width: 1.5, color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF333333)),

                  // ================= CENTER CONSOLE =================
                  Expanded(
                    child: Container(
                      color: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF0F172A),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Console Top Sub-Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TEXT ORCHESTRATOR CONSOLE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 1.0)),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Demo: Returning User', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: const Text('Clear Context', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Chat Conversation & Package Cards
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Bot Greeting Message
                                  _buildChatBubbleContainer(
                                    sender: '',
                                    text: "Hello there! I'm from the $displayCompany team, and I'm really looking forward to helping you today, Devendra ji. How can I assist you?",
                                    isUser: false,
                                  ),
                                  const SizedBox(height: 10),

                                  // User Message
                                  _buildChatBubbleContainer(
                                    sender: 'You (Text)',
                                    text: "fever hai mujhe",
                                    isUser: true,
                                  ),
                                  const SizedBox(height: 10),

                                  // Orchestrator Response + Cards
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4, bottom: 4),
                                        child: Text('Orchestrator (symptom-triage)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: const Color(0xFFE5E7EB)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: const TextSpan(
                                                style: TextStyle(fontSize: 13.5, color: Color(0xFF1F2937), height: 1.45),
                                                children: [
                                                  TextSpan(text: 'Aap chinta mat kijiye, Devendra ji, hum isme poori madad karenge. Fever ke liye humara '),
                                                  TextSpan(text: 'Fever Package â‚¹500', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  TextSpan(text: ' ka hai. Dengue screening ke liye '),
                                                  TextSpan(text: 'Fever Package Advanced (â‚¹1100)', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  TextSpan(text: ' better rahega. Kya aapko body ache ya thand bhi lag rahi hai?'),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),

                                            // Package Cards Grid (Side-by-side 2 Columns)
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: _buildDetailedPackageCard(
                                                    title: 'Fever Package (includes Malaria & Typhoid Tests)',
                                                    badge: 'Package â€¢ Contains 45 tests',
                                                    eta: 'Report within 15 hours',
                                                    details: 'Includes CBC, Widal, Typhoid, Malaria, and Urine Routine',
                                                    price: 'â‚¹500',
                                                    originalPrice: 'â‚¹555',
                                                    discount: '10% off',
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: _buildDetailedPackageCard(
                                                    title: 'Fever Package Advanced (includes Dengue, Malaria & Typhoid)',
                                                    badge: 'Package â€¢ Contains 49 tests',
                                                    eta: 'Report within 15-16 hours',
                                                    details: 'Includes Dengue NS1 & IgM/IgG, Malaria, Typhoid',
                                                    price: 'â‚¹1100',
                                                    originalPrice: 'â‚¹1220',
                                                    discount: '10% off',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                          // Bottom Chat Input Bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text('Type a message to the Orchestrator...', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('Send', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Vertical divider
                  Container(width: 1.5, color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF333333)),

                  // ================= RIGHT SIDEBAR =================
                  Container(
                    width: 220,
                    padding: const EdgeInsets.all(12),
                    color: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF181818),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('USER PROFILE CONTEXT', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 1.0)),
                          const SizedBox(height: 10),

                          // Profile Card
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProfileRow('Name:', 'Devendra', true),
                                _buildProfileRow('Age/Gender:', '42 / Male', false),
                                _buildProfileRow('Location:', 'Dwarka Sector 7, New Delhi', false),

                                const SizedBox(height: 10),
                                const Text('Chronic Tags:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _buildTagPill('Prediabetic', const Color(0xFFFEE2E2), const Color(0xFFEF4444)),
                                    _buildTagPill('Hypertension', accentColor.withValues(alpha: 0.15), accentColor),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                Container(height: 1, color: const Color(0xFFF1F5F9)),
                                const SizedBox(height: 10),

                                const Text('Historical Tests:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Text('â€¢ HbA1c (6.8)', style: TextStyle(fontSize: 11, color: Color(0xFF334155))),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('â†‘ High', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text('â€¢ Lipid Profile', style: TextStyle(fontSize: 11, color: Color(0xFF334155))),
                                    const Spacer(),
                                    const Text('Normal', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),
                          // Context Sync Info Box
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.sync, size: 14, color: accentColor),
                                    const SizedBox(width: 6),
                                    Text('Context Sync', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: accentColor)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Patient records automatically synched with $displayCompany EHR system.',
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF334155), height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentCard(String title, String desc, IconData icon, bool isLight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 14, color: accentColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const SizedBox(height: 1),
                Text(desc, style: const TextStyle(fontSize: 10, color: Color(0xFF475569)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 1),
          Text(desc, style: const TextStyle(fontSize: 10, color: Color(0xFF475569), height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildChatBubbleContainer({required String sender, required String text, required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (sender.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 3),
              child: Text(sender, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? accentColor.withValues(alpha: 0.12) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isUser ? accentColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
              boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Text(
              text,
              style: TextStyle(fontSize: 13.5, fontWeight: isUser ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF1F2937)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedPackageCard({
    required String title,
    required String badge,
    required String eta,
    required String details,
    required String price,
    required String originalPrice,
    required String discount,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Purple package icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(7)),
            child: const Icon(Icons.inventory_2, size: 15, color: Color(0xFF7E22CE)),
          ),
          const SizedBox(height: 8),

          // Title
          Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.3)),
          const SizedBox(height: 5),

          // Badge
          Text(badge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
          Text(eta, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          const SizedBox(height: 8),

          // Details text
          Text(details, style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569), height: 1.3)),
          const SizedBox(height: 10),

          // Price & Booking
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(price, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      const SizedBox(width: 5),
                      Text(originalPrice, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                  Text('â†³ Extra 10% OFF With VIP', style: const TextStyle(fontSize: 9.5, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                ),
                child: const Text('BOOK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, bool isBold) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 11.5, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF0F172A)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagPill(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: textCol)),
    );
  }
}

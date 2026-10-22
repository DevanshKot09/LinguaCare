sealed class ContentBlock {
  const ContentBlock();

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'paragraph':
        return ParagraphBlock(text: json['text'] as String? ?? '');
      case 'heading':
        return HeadingBlock(text: json['text'] as String? ?? '');
      case 'bullets':
        return BulletsBlock(items: List<String>.from(json['items'] ?? []));
      case 'steps':
        return StepsBlock(items: List<String>.from(json['items'] ?? []));
      case 'callout':
        return CalloutBlock(text: json['text'] as String? ?? '');
      case 'myth_fact':
        return MythFactBlock(myth: json['myth'] as String? ?? '', fact: json['fact'] as String? ?? '');
      case 'barrier_fix':
        return BarrierFixBlock(barriers: (json['barriers'] as List? ?? []).map((b) => BarrierFixItem.fromJson(b)).toList());
      case 'role_tabs':
        return RoleTabsBlock(tabs: (json['tabs'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), v.toString())));
      case 'disclaimer':
        return DisclaimerBlock(text: json['text'] as String? ?? '');
      default:
        return ParagraphBlock(text: json['text'] as String? ?? '');
    }
  }
}

class ParagraphBlock extends ContentBlock {
  final String text;
  const ParagraphBlock({required this.text});
}

class HeadingBlock extends ContentBlock {
  final String text;
  const HeadingBlock({required this.text});
}

class BulletsBlock extends ContentBlock {
  final List<String> items;
  const BulletsBlock({required this.items});
}

class StepsBlock extends ContentBlock {
  final List<String> items;
  const StepsBlock({required this.items});
}

class CalloutBlock extends ContentBlock {
  final String text;
  const CalloutBlock({required this.text});
}

class MythFactBlock extends ContentBlock {
  final String myth;
  final String fact;
  const MythFactBlock({required this.myth, required this.fact});
}

class BarrierFixItem {
  final String barrier;
  final String fix;
  const BarrierFixItem({required this.barrier, required this.fix});

  factory BarrierFixItem.fromJson(Map<String, dynamic> json) {
    return BarrierFixItem(
      barrier: json['barrier'] as String? ?? '',
      fix: json['fix'] as String? ?? '',
    );
  }
}

class BarrierFixBlock extends ContentBlock {
  final List<BarrierFixItem> barriers;
  const BarrierFixBlock({required this.barriers});
}

class RoleTabsBlock extends ContentBlock {
  final Map<String, String> tabs;
  const RoleTabsBlock({required this.tabs});
}

class DisclaimerBlock extends ContentBlock {
  final String text;
  const DisclaimerBlock({required this.text});
}

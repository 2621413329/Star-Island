/// 今日日常补充说明（note）长度与展示相关常量。
const int momentNoteMaxLength = 500;

/// 每条日常最多照片数。
const int momentMaxPhotos = 6;

/// 列表卡片摘要默认展示字数（收起态软截断）。
const int momentNotePreviewMaxChars = 100;

/// 列表卡片摘要展开后展示全文（保留常量兼容旧引用）。
const int momentNotePreviewExpandedMaxChars = momentNoteMaxLength;

/// 本周小结收起态软截断上限。
const int weeklySummaryPreviewMaxChars = 160;

/// 嵌入对话模板时的日常摘录软截断上限。
const int companionNoteSnippetMaxChars = 48;

/// 小人对话单句软截断上限（避免气泡过长，不在句中硬切）。
const int companionSpeechLineMaxChars = 96;

/// 列表卡片摘要最多展示行数（兼容旧逻辑）。
const int momentNotePreviewMaxLines = 2;

/// 大卡日常带摘要最多展示行数。
const int momentNoteCardMaxLines = 3;

/// 岛屿角色缩放：备注丰富度参考长度（与 [momentNoteMaxLength] 对齐）。
const int momentNoteRichnessReferenceLength = momentNoteMaxLength;

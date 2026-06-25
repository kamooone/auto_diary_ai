class DiaryItem {
  final String date;
  final String aiMemo;
  final String thumbnailUrl;

  DiaryItem({
    required this.date,
    required this.aiMemo,
    required this.thumbnailUrl,
  });
}

// TODO:実データに差し替え
final List<DiaryItem> dummyDiaryItems = [
  // 2025-10
  DiaryItem(
    date: '2025-10-28',
    aiMemo: '友達とハイキングに行った。',
    thumbnailUrl: 'https://via.placeholder.com/150/FFB6C1',
  ),
  DiaryItem(
    date: '2025-10-29',
    aiMemo: '美術館で新しい展示を楽しんだ。',
    thumbnailUrl: 'https://via.placeholder.com/150/87CEFA',
  ),

  // 2025-11
  DiaryItem(
    date: '2025-11-01',
    aiMemo: '今日は公園に行ってピクニックを楽しみました。',
    thumbnailUrl: 'https://via.placeholder.com/150/FFD700',
  ),
  DiaryItem(
    date: '2025-11-02',
    aiMemo: '美味しいカフェで友達とランチしました。',
    thumbnailUrl: 'https://via.placeholder.com/150/ADFF2F',
  ),
  DiaryItem(
    date: '2025-11-03',
    aiMemo: '家で映画鑑賞、リラックスできた一日。',
    thumbnailUrl: 'https://via.placeholder.com/150/FF6347',
  ),

  // 2025-12
  DiaryItem(
    date: '2025-12-01',
    aiMemo: '冬の準備で大掃除をした。',
    thumbnailUrl: 'https://via.placeholder.com/150/40E0D0',
  ),
  DiaryItem(
    date: '2025-12-02',
    aiMemo: 'クリスマスツリーを飾った。',
    thumbnailUrl: 'https://via.placeholder.com/150/DA70D6',
  ),
];

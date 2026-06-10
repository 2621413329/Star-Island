import 'package:flutter/material.dart';

import '../core/theme/mood_theme.dart';
import '../data/models/growth_observation.dart';
import 'island_ui.dart';

class GrowthObservationReportCard extends StatelessWidget {
  const GrowthObservationReportCard({
    super.key,
    required this.observation,
    required this.palette,
  });

  final GrowthObservationReport observation;
  final MoodPalette palette;

  @override
  Widget build(BuildContext context) {
    final tierColor = riskTierColor(observation.riskTier);

    return IslandGlassCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '成长观察分析',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tierColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  observation.riskTierLabel,
                  style: TextStyle(
                    color: tierColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionTitle('① 风险点摘要'),
          const SizedBox(height: 6),
          ...observation.riskSummary.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('· ', style: TextStyle(color: palette.primary, fontWeight: FontWeight.w700)),
                  Expanded(
                    child: Text(s, style: const TextStyle(fontSize: 13, height: 1.45)),
                  ),
                ],
              ),
            ),
          ),
          if (observation.stressSources.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionTitle('② 压力来源'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: observation.stressSources.map((s) {
                final suffix = s.evidence.isNotEmpty ? ' · ${s.evidence}' : '';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: palette.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${s.label}$suffix',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          _sectionTitle('③ 情绪趋势'),
          const SizedBox(height: 6),
          Row(
            children: [
              _trendIcon(observation.emotionTrend.direction),
              const SizedBox(width: 6),
              Text(
                observation.emotionTrend.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _trendColor(observation.emotionTrend.direction),
                ),
              ),
            ],
          ),
          if (observation.emotionTrend.signals.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...observation.emotionTrend.signals.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  s,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8C7B6B), height: 1.4),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _sectionTitle('④ 教师建议'),
          const SizedBox(height: 6),
          Text(
            observation.teacherGuidance.urgencyLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: tierColor,
            ),
          ),
          if (observation.teacherGuidance.durationAssessment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '性质判断：${observation.teacherGuidance.durationAssessment}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF8C7B6B)),
            ),
          ],
          if (observation.teacherGuidance.rationale.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              observation.teacherGuidance.rationale,
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
          ],
          if (observation.teacherGuidance.suggestedActions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '建议方式：${observation.teacherGuidance.suggestedActions.join('、')}',
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
          if (observation.disclaimer.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              observation.disclaimer,
              style: TextStyle(
                fontSize: 11,
                color: palette.primary.withValues(alpha: 0.55),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8C7B6B)),
    );
  }

  Widget _trendIcon(String direction) {
    IconData icon;
    switch (direction) {
      case 'significantly_worsening':
      case 'worsening':
        icon = Icons.trending_down_rounded;
        break;
      case 'up':
        icon = Icons.trending_up_rounded;
        break;
      default:
        icon = Icons.trending_flat_rounded;
    }
    return Icon(icon, size: 18, color: _trendColor(direction));
  }

  Color _trendColor(String direction) {
    switch (direction) {
      case 'significantly_worsening':
        return const Color(0xFFD32F2F);
      case 'worsening':
        return const Color(0xFFFF9800);
      case 'up':
        return const Color(0xFF7CB342);
      default:
        return const Color(0xFF8C7B6B);
    }
  }
}

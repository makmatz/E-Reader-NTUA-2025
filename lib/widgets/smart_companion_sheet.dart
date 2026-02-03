import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/book.dart';
import '../theme/app_theme.dart';

class SmartCompanionButton extends StatelessWidget {
  const SmartCompanionButton({
    super.key,
    required this.book,
    required this.currentPage,
    required this.currentContent,
    required this.selectedText,
  });

  final Book book;
  final int currentPage;
  final String currentContent;
  final String selectedText;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _openSheet(context),
      tooltip: 'Smart Reading Companion',
      backgroundColor: AppColors.primaryText,
      foregroundColor: AppColors.background,
      child: const Icon(Icons.auto_awesome),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SmartCompanionSheet(
          book: book,
          currentPage: currentPage,
          currentContent: currentContent,
          selectedText: selectedText,
        );
      },
    );
  }
}

class SmartCompanionSheet extends StatefulWidget {
  const SmartCompanionSheet({
    super.key,
    required this.book,
    required this.currentPage,
    required this.currentContent,
    required this.selectedText,
  });

  final Book book;
  final int currentPage;
  final String currentContent;
  final String selectedText;

  @override
  State<SmartCompanionSheet> createState() => _SmartCompanionSheetState();
}

class _SmartCompanionSheetState extends State<SmartCompanionSheet> {
  final TextEditingController _questionController = TextEditingController();
  final List<_Message> _messages = [];
  String _activeTab = 'explain';
  String _targetLanguage = 'Spanish';
  bool _loading = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _addResponse(String content) async {
    setState(() {
      _messages.add(_Message(content: content, isUser: false));
      _loading = false;
    });
  }

  Future<void> _simulateResponse(String content) async {
    setState(() {
      _loading = true;
      _messages.add(_Message(content: content, isUser: true));
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
  }

  Future<void> _handleExplain() async {
    if (widget.selectedText.trim().isEmpty) {
      _showSnackBar('Select text in the reader first.');
      return;
    }
    await _simulateResponse('Explain: "${widget.selectedText}"');
    await _addResponse(
      'Explanation:\n\n"${widget.selectedText}" means...\n\n'
      'In this context, the author suggests... (mock response)',
    );
  }

  Future<void> _handleSummarizePage() async {
    await _simulateResponse('Summarize current page');
    await _addResponse(
      'Page ${widget.currentPage + 1} summary:\n'
      '${_summarizeText(widget.currentContent)}',
    );
  }

  Future<void> _handleSummarizeChapter() async {
    await _simulateResponse('Summarize current chapter');
    await _addResponse(
      'Chapter summary for ${widget.book.title}:\n'
      'So far, the story highlights... (mock response)',
    );
  }

  Future<void> _handleTranslate() async {
    if (widget.selectedText.trim().isEmpty) {
      _showSnackBar('Select text to translate.');
      return;
    }
    await _simulateResponse(
      'Translate to $_targetLanguage: "${widget.selectedText}"',
    );
    final translated = await _translateText(
      widget.selectedText,
      _targetLanguage,
    );
    await _addResponse(
      '$_targetLanguage translation:\n$translated',
    );
  }

  Future<String> _translateText(String text, String language) async {
    final lang = _languageCodes[language] ?? 'es';
    final uri = Uri.https(
      'api.mymemory.translated.net',
      '/get',
      {
        'q': text,
        'langpair': 'en|$lang',
      },
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return 'Translation failed (HTTP ${response.statusCode}).';
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final responseData = data['responseData'] as Map<String, dynamic>?;
      final translatedText = responseData?['translatedText'] as String?;
      return translatedText ?? 'Translation unavailable.';
    } catch (_) {
      return 'Translation failed. Check your connection.';
    }
  }

  Future<void> _handleQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      _showSnackBar('Ask a question first.');
      return;
    }
    _questionController.clear();
    await _simulateResponse(question);
    await _addResponse(
      'Answer:\nBased on the current page, it appears that... (mock response)',
    );
  }

  String _summarizeText(String text) {
    if (text.isEmpty) return 'No content to summarize.';
    final snippet = text.length > 200 ? text.substring(0, 200) : text;
    return '$snippet...';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppColors.primaryText;
    final secondaryText =
        isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.secondaryText;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: math.min(640, MediaQuery.of(context).size.height * 0.85),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Reading Companion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Explain, summarize, translate, or ask questions.',
              style: TextStyle(color: secondaryText),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildTabContent(primaryText, secondaryText)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(Color primaryText, Color secondaryText) {
    return Column(
      children: [
        if (widget.selectedText.isNotEmpty &&
            (_activeTab == 'explain' || _activeTab == 'translate'))
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.selectedText,
                    style: TextStyle(color: secondaryText, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              for (final message in _messages)
                Align(
                  alignment:
                      message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? AppColors.border.withValues(alpha: 0.2)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: message.isUser ? primaryText : secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              if (_loading)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Thinking...',
                        style: TextStyle(color: secondaryText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_activeTab == 'translate')
          DropdownButtonFormField<String>(
            value: _targetLanguage,
            items: _languages
                .map(
                  (lang) => DropdownMenuItem(
                    value: lang,
                    child: Text(lang),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _targetLanguage = value);
            },
          ),
        if (_activeTab == 'qa') ...[
          const SizedBox(height: 8),
          TextField(
            controller: _questionController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Ask a question about the story...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildBottomOptions(),
      ],
    );
  }

  Widget _buildBottomOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TabButton(
          label: 'Explain',
          selected: _activeTab == 'explain',
          onTap: () {
            setState(() => _activeTab = 'explain');
            _handleExplain();
          },
        ),
        _TabButton(
          label: 'Summary',
          selected: _activeTab == 'summary',
          onTap: () {
            setState(() => _activeTab = 'summary');
            _handleSummarizePage();
          },
        ),
        _TabButton(
          label: 'Translate',
          selected: _activeTab == 'translate',
          onTap: () {
            setState(() => _activeTab = 'translate');
            _handleTranslate();
          },
        ),
        _TabButton(
          label: 'Q&A',
          selected: _activeTab == 'qa',
          onTap: () {
            setState(() => _activeTab = 'qa');
            _handleQuestion();
          },
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.border.withValues(alpha: 0.2) : null,
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

class _Message {
  const _Message({required this.content, required this.isUser});

  final String content;
  final bool isUser;
}

const List<String> _languages = [
  'Spanish',
  'French',
  'German',
  'Italian',
  'Portuguese',
  'Chinese',
  'Japanese',
  'Korean',
];

const Map<String, String> _languageCodes = {
  'Spanish': 'es',
  'French': 'fr',
  'German': 'de',
  'Italian': 'it',
  'Portuguese': 'pt',
  'Chinese': 'zh',
  'Japanese': 'ja',
  'Korean': 'ko',
};

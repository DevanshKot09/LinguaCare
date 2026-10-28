import 'package:flutter/material.dart';

class SpecialistDirectoryScreen extends StatefulWidget {
  const SpecialistDirectoryScreen({super.key});

  @override
  State<SpecialistDirectoryScreen> createState() => _SpecialistDirectoryScreenState();
}

class SpecialistProfile {
  final String id;
  final String name;
  final String title;
  final String specialty;
  final String experience;
  final double rating;
  final int reviewsCount;
  final String certification;
  final String bio;
  final String emojiAvatar;
  final Color avatarColor;

  const SpecialistProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.specialty,
    required this.experience,
    required this.rating,
    required this.reviewsCount,
    required this.certification,
    required this.bio,
    required this.emojiAvatar,
    required this.avatarColor,
  });
}

class _SpecialistDirectoryScreenState extends State<SpecialistDirectoryScreen> {
  static const List<SpecialistProfile> _specialists = [
    SpecialistProfile(
      id: 'sp_1',
      name: 'Dr. Aris Thorne, Ph.D.',
      title: 'Senior Speech-Language Pathologist',
      specialty: 'Pediatric Speech & DLD',
      experience: '12+ years experience',
      rating: 4.95,
      reviewsCount: 38,
      certification: 'RCSLT & ASHA Certified',
      bio: 'Specializing in early childhood expressive language delay, developmental language disorder (DLD), and parent coaching.',
      emojiAvatar: '👩‍⚕️',
      avatarColor: Color(0xFF5B32E8),
    ),
    SpecialistProfile(
      id: 'sp_2',
      name: 'Michael Chen, M.S., CCC-SLP',
      title: 'Clinical Fluency Specialist',
      specialty: 'Stuttering & Social Fluency',
      experience: '9+ years experience',
      rating: 4.9,
      reviewsCount: 29,
      certification: 'ASHA Certified SLP',
      bio: 'Dedicated to empowering adolescents and young adults through evidence-based speech pacing, confidence conditioning, and stuttering management.',
      emojiAvatar: '👨‍⚕️',
      avatarColor: Color(0xFF00C4B4),
    ),
    SpecialistProfile(
      id: 'sp_3',
      name: 'Dr. Priya Ramanathan, SLP',
      title: 'Neurogenic Communication Specialist',
      specialty: 'Adult Neuro & Aphasia',
      experience: '15+ years experience',
      rating: 4.98,
      reviewsCount: 52,
      certification: 'RCI & ASHA Fellow',
      bio: 'Expert clinical support for adult speech recovery, stroke rehabilitation, voice modulation, and workplace communication accommodations.',
      emojiAvatar: '🩺',
      avatarColor: Color(0xFFFF9800),
    ),
    SpecialistProfile(
      id: 'sp_4',
      name: 'Elena Rostova, M.Ed., SLP',
      title: 'Educational Speech Therapist',
      specialty: 'Classroom Accommodations',
      experience: '8+ years experience',
      rating: 4.88,
      reviewsCount: 22,
      certification: 'State Licensed SLP',
      bio: 'Collaborating closely with teachers, parents, and schools to bridge speech therapy goals with classroom learning plans.',
      emojiAvatar: '👩‍🏫',
      avatarColor: Color(0xFFE91E63),
    ),
  ];

  String _selectedFilter = 'All';

  List<SpecialistProfile> get _filteredList {
    if (_selectedFilter == 'All') return _specialists;
    return _specialists.where((s) => s.specialty.toLowerCase().contains(_selectedFilter.toLowerCase())).toList();
  }

  void _openBookingSheet(SpecialistProfile spec) {
    int selectedDurationMonths = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: spec.avatarColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(spec.emojiAvatar, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            spec.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Quicksand'),
                          ),
                          Text(
                            spec.title,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                const Text(
                  'Select Support Plan Duration',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Quicksand'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [1, 2, 3].map((months) {
                    final isSel = selectedDurationMonths == months;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedDurationMonths = months),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF5B32E8).withValues(alpha: 0.1) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSel ? const Color(0xFF5B32E8) : Colors.grey.shade300,
                              width: isSel ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$months Month${months > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? const Color(0xFF5B32E8) : Colors.black87,
                                  fontFamily: 'Quicksand',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${months * 4} Sessions',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSel ? const Color(0xFF5B32E8) : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C4B4).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00C4B4).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF00897B), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedDurationMonths == 1
                              ? 'Includes 4 weekly telepractice sessions, goal alignment & written progress summaries.'
                              : selectedDurationMonths == 2
                                  ? 'Includes 8 weekly sessions, 2 family consults & school communication support.'
                                  : 'Comprehensive 12-week rehabilitation plan, milestone tracking & final evaluation report.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF00695C), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Support Plan Requested! 🎉', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Quicksand')),
                        content: Text(
                          'Your $selectedDurationMonths-month support plan request with ${spec.name} has been sent. The specialist team will reach out within 24 hours to schedule your kickoff consultation.',
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B32E8), Color(0xFF7952FC)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF4321BD),
                          offset: Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Confirm $selectedDurationMonths-Month Support Plan',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Quicksand',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FD),
      appBar: AppBar(
        title: const Text(
          'Specialist Directory',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Quicksand'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter categories horizontal bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  'All',
                  'Pediatric',
                  'Fluency',
                  'Adult',
                  'Accommodations',
                ].map((tag) {
                  final isSelected = _selectedFilter == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(tag),
                      selected: isSelected,
                      selectedColor: const Color(0xFF5B32E8),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Quicksand',
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedFilter = tag);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Specialists List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _filteredList.length,
                itemBuilder: (context, index) {
                  final spec = _filteredList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: spec.avatarColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(spec.emojiAvatar, style: const TextStyle(fontSize: 28)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            spec.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Quicksand',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF00C4B4)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      spec.title,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB300)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${spec.rating} (${spec.reviewsCount} reviews)',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '• ${spec.experience}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B32E8).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🎯 ${spec.specialty}  •  📜 ${spec.certification}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5B32E8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            spec.bio,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.35),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _openBookingSheet(spec),
                              icon: const Icon(Icons.calendar_month_rounded),
                              label: const Text('Book Support Plan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5B32E8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
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
        ),
      ),
    );
  }
}

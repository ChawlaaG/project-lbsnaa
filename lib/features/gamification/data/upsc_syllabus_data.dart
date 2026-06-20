import 'package:flutter/material.dart';

class UpscSubject {
  final String id;
  final String name;
  final IconData icon; // Using IconData for simplicity in this iteration
  final Color color;
  final List<String> topics;

  const UpscSubject({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.topics,
  });
}

class UpscSyllabusData {
  static const List<UpscSubject> subjects = [
    UpscSubject(
      id: 'history',
      name: 'History',
      icon: Icons.history_edu,
      color: Color(0xFFE57373), // Red 300
      topics: [
        'Ancient India: Indus Valley Civilization',
        'Ancient India: Vedic Period',
        'Ancient India: Buddhism & Jainism',
        'Ancient India: Mauryan Empire',
        'Ancient India: Gupta Period',
        'Medieval India: Delhi Sultanate',
        'Medieval India: Mughal Empire',
        'Medieval India: Bhakti & Sufi Movements',
        'Modern India: Advent of Europeans',
        'Modern India: 1857 Revolt',
        'Modern India: Social & Religious Reforms',
        'Modern India: Freedom Struggle (1885-1919)',
        'Modern India: Gandhian Era (1919-1947)',
        'Modern India: Growth of National Consciousness',
        'Modern India: Revolutionary Nationalism',
        'Modern India: Post-1857 Administrative Changes',
        'Art & Culture: Architecture, Sculpture, Painting',
        'Art & Culture: Music, Dance, Theatre',
      ],
    ),
    UpscSubject(
      id: 'geography',
      name: 'Geography',
      icon: Icons.public,
      color: Color(0xFF64B5F6), // Blue 300
      topics: [
        'Physical Geography: Geomorphology',
        'Physical Geography: Climatology',
        'Physical Geography: Oceanography',
        'Indian Geography: Physical Features',
        'Indian Geography: Drainage System',
        'Indian Geography: Climate & Monsoons',
        'Indian Geography: Soils & Vegetation',
        'Indian Geography: Agriculture & Resources',
        'World Geography: Continents & Major Features',
        'World Geography: Earth\'s Interior & Geomorphic Processes',
        'World Geography: Human Geography (Population & Urbanization)',
        'World Geography: Economic Geography',
      ],
    ),
    UpscSubject(
      id: 'polity',
      name: 'Polity',
      icon: Icons.account_balance,
      color: Color(0xFF81C784), // Green 300
      topics: [
        'Constitutional Framework: Preamble, FRs, DPSP',
        'Union Executive: President, VP, PM',
        'Union Legislature: Parliament',
        'State Government: Governor, CM, Legislature',
        'Judiciary: Supreme Court & High Courts',
        'Local Government: Panchayats & Municipalities',
        'Constitutional & Non-Constitutional Bodies',
        'Federalism & Centre-State Relations',
        'Amendments & Important Judgments',
        'Public Policy & Rights Issues',
        'Political Parties & Pressure Groups',
        'UT & Special Areas',
      ],
    ),
    UpscSubject(
      id: 'economy',
      name: 'Economy',
      icon: Icons.trending_up,
      color: Color(0xFFFFD54F), // Amber 300
      topics: [
        'National Income & Planning',
        'Inflation & Monetary Policy',
        'Banking System in India',
        'Fiscal Policy & Budgeting',
        'External Sector: BoP, Forex, Trade',
        'Agriculture & Food Security',
        'Industry & Infrastructure',
        'Poverty, Inequality & Employment',
        'Planning & Niti Aayog',
        'Sustainable Development Goals (SDGs)',
        'Digital India & Infrastructure',
        'Government Schemes (Social Sector)',
      ],
    ),
    UpscSubject(
      id: 'environment',
      name: 'Environment',
      icon: Icons.forest,
      color: Color(0xFFAED581), // Light Green 300
      topics: [
        'Ecology & Ecosystems',
        'Biodiversity & Conservation',
        'Climate Change & Global Warming',
        'Pollution & Waste Management',
        'Environmental Organizations & Acts',
        'International Conventions & Protocols',
      ],
    ),
    UpscSubject(
      id: 'science',
      name: 'Science & Tech',
      icon: Icons.biotech,
      color: Color(0xFF9575CD), // Deep Purple 300
      topics: [
        'Space Technology (ISRO, Missions)',
        'Defense Technology (Missiles, Aircraft)',
        'Biotechnology & Health',
        'Information Technology & AI',
        'Nanotechnology & Robotics',
        'Energy (Nuclear, Renewable)',
        'Intellectual Property Rights (IPR)',
        'General Science: Physics, Chemistry, Biology',
      ],
    ),
    UpscSubject(
      id: 'csat',
      name: 'CSAT (Paper II)',
      icon: Icons.calculate,
      color: Color(0xFFFF8A65), // Deep Orange 300
      topics: [
        'Reading Comprehension',
        'Interpersonal Skills & Communication',
        'Logical Reasoning & Analytical Ability',
        'Decision Making & Problem Solving',
        'General Mental Ability',
        'Basic Numeracy (Numbers, Orders)',
        'Data Interpretation (Charts, Graphs)',
        'Data Sufficiency',
      ],
    ),
    UpscSubject(
      id: 'maps',
      name: 'Strategic Maps',
      icon: Icons.map,
      color: Color(0xFFCE93D8), // Purple 200
      topics: [
        'India: Rivers & Tributaries (Mapping)',
        'India: Mountains & Passes',
        'India: National Parks & Sanctuaries',
        'World: Important Straits & Waterways',
        'World: Locations in News (Middle East, SE Asia)',
        'Mapping: Biodiversity Hotspots',
        'Mapping: Major Industrial Corridors',
      ],
    ),
    UpscSubject(
      id: 'current_affairs',
      name: 'Current Affairs',
      icon: Icons.newspaper,
      color: Color(0xFF4DB6AC), // Teal 300
      topics: [
        'Union Budget 2025-26: Key Allocations',
        'Economic Survey 2024-25: Major Findings',
        'Government Schemes: Samarth, PM-DevINE, etc.',
        'International Relations: India-Neighborhood',
        'International Relations: G20, BRICS, SCO',
        'Science & Tech in News',
        'Environment & Ecology: COP29 Highlights',
        'Awards, Sports & Personalities',
      ],
    ),
  ];
}

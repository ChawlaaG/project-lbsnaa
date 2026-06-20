# Roadmap V2: Project CADRE - The Unicorn Path

**Vision:** A One-Stop, Retention-Driven, Offline-Capable Digital Academy.
**Status:** MVP (Minimum Viable Product). Key Infrastructure is live (Map, Squads, Profile, News, Bulk Gen).
**Warning:** Current state is a "Functional Skeleton". It lacks the muscle (content) and nervous system (retention loops) to survive the market.

## Top 5 Missing Features (Ranked by Criticality)

### 1. The "Infinite Library" (Automated Content Pipeline)
| Feature Name | Why it's missing | Impact on Aspirant |
| :--- | :--- | :--- |
| **Content Engine v2** | Currently relies on manual "Bulk Gen" clicks or meager seeding. A serious aspirant answers 50-100 questions daily. Our current DB will be exhausted in <48 hours. | **High Churn.** "This app is empty." They uninstall and go back to Telegram/Books. |
| **Goal** | **10,000+ Questions.** Background Job / Server-Side Script to auto-populate topics weekly. | **Sticky.** "There is always something new to learn." |

### 2. The "Drill Sergeant" (Retention System)
| Feature Name | Why it's missing | Impact on Aspirant |
| :--- | :--- | :--- |
| **Push Notifications** | No `firebase_messaging` or local notification triggers implemented. We rely on the user *remembering* to open the app. | **Memory Hole.** "Out of sight, out of mind." Aspirants are distracted; we must pull them back. |
| **Goal** | **"0600 Hours Briefing."** Automated morning notification linking to the Daily News. "Missed Drill" nudges after 24h inactivity. | **Habit Forming.** The app becomes part of their daily discipline. |

### 3. The "CSAT Dojo" (Dedicated Aptitude Tools)
| Feature Name | Why it's missing | Impact on Aspirant |
| :--- | :--- | :--- |
| **Math Engine** | `PrelimsDashboard` has a "CSAT Gym" placeholder (UI Cards), but no specialized tools (Timer, Formula Sheet, Scratchpad). | **Feature Gap.** They will use a different app for math practice because generic MCQs aren't enough for timed drills. |
| **Goal** | **Stopwatch Mode.** A dedicated UI with a floating countdown, scratchpad overlay, and formula reference. | **Dependency.** "I need this app for my speed drills." |

### 4. The "Bunker Mode" (Offline Capability)
| Feature Name | Why it's missing | Impact on Aspirant |
| :--- | :--- | :--- |
| **Local Persistence** | While Firestore offers some caching, we have no explicit "Download for Offline" or robust `hive`/`sqflite` sync for core content. | **Frustration.** Commuting on the Delhi Metro or in a rural library with spotty net means the app is a brick. |
| **Goal** | **"Download Pack."** Button to save the next 100 Qs and Map Data locally. | **Reliability.** "It works everywhere." Essential for Tier-2/3 city users. |

### 5. The "War Room" (Analytics & Insights)
| Feature Name | Why it's missing | Impact on Aspirant |
| :--- | :--- | :--- |
| **Performance Analytics** | We track `xpPoints` and `level`, but give no strategic feedback (e.g., "Weak in Economy", "Strong in History"). | **Value Limit.** "It's just a game." They need to know *where* to improve to justify the time spent. |
| **Goal** | **Radar Chart.** Visual breakdown of strengths/weaknesses by subject. | **Strategic Value.** The app becomes their coach, not just a quiz machine. |

## Execution Strategy for V2
1.  **Immediate:** Build the **"Infinite Library"** (Script automation).
2.  **Short Term:** Implement **"Drill Sergeant"** (Notifications).
3.  **Mid Term:** Develop **"Bunker Mode"** (Offline Sync).
4.  **Long Term:** Deploy **"CSAT Dojo"** & **"War Room"**.

*Prepare for Phase 27.*

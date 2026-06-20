import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/gamification/models/quiz_entity.dart';

class SeedingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedHistoryRandomQuiz() async {
    final quizId = 'History_Random';
    final docRef = _firestore.collection('quizzes').doc(quizId);

    // Check if exists to avoid overwriting user progress if we were tracking it here (we aren't, but good practice)
    // Actually for seeding we might want to force update to ensure questions exist.
    
    final quizData = QuizEntity(
      id: quizId,
      title: 'History (Random Intercept)',
      questions: [
        QuestionEntity(
          questionText: 'Who among the following presided over the Surat Session of Indian National Congress in 1907?',
          options: [
            'Dadabhai Naoroji',
            'Gopal Krishna Gokhale',
            'Rash Behari Ghosh',
            'S.N. Banerjee'
          ],
          correctOptionIndex: 2,
          explanation: 'The Surat Session (1907) was presided over by Rash Behari Ghosh. It was here that the INC split into Moderates and Extremists.',
        ),
        QuestionEntity(
          questionText: 'The "Doctrine of Lapse" was a policy introduced by which Governor-General?',
          options: [
            'Lord Wellesley',
            'Lord Dalhousie',
            'Lord Canning',
            'Lord William Bentinck'
          ],
          correctOptionIndex: 1,
          explanation: 'Lord Dalhousie introduced the Doctrine of Lapse, which was used to annex states like Satara, Jhansi, and Nagpur.',
        ),
        QuestionEntity(
          questionText: 'Which Harappan site is known for its unique water management system?',
          options: [
            'Lothal',
            'Dholavira',
            'Kalibangan',
            'Rakhigarhi'
          ],
          correctOptionIndex: 1,
          explanation: 'Dholavira (Gujarat) is famous for its sophisticated water conservation system of channels and reservoirs.',
        ),
        QuestionEntity(
          questionText: 'The term "Mughal Zagir" refers to:',
          options: [
            'A piece of land given to a noble',
            'Revenue assignment for salary',
            'A religious grant',
            'Private land of the Emperor'
          ],
          correctOptionIndex: 1,
          explanation: 'Jagir system was a form of land tenancy system where collection of revenue was assigned to an official (Jagirdar) instead of salary.',
        ),
        QuestionEntity(
          questionText: 'Who founded the "Servants of India Society"?',
          options: [
            'Bal Gangadhar Tilak',
            'Gopal Krishna Gokhale',
            'Lala Lajpat Rai',
            'Annie Besant'
          ],
          correctOptionIndex: 1,
          explanation: 'Gopal Krishna Gokhale founded the Servants of India Society in 1905 to train Indians for public service.',
        ),
      ],
    );

    try {
      await docRef.set(quizData.toMap());
    } catch (e) {
      // print('❌ AMMO DROP FAILED: $e'); // Removed as per instruction
    }
  }
}

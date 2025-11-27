# Student Quiz App

Ứng dụng thi trắc nghiệm trực tuyến dành cho học sinh, được xây dựng bằng Flutter và Firebase.

## Tính năng chính

### Dành cho Học sinh
- **Dashboard**: Xem tổng quan số lượng bài thi khả dụng và lịch sử làm bài gần đây
- **Làm bài thi**: Danh sách các bài thi chưa hoàn thành với đầy đủ thông tin
- **Thi trực tuyến**: Giao diện làm bài với timer đếm ngược và thanh tiến trình
- **Nộp bài tự động**: Tự động nộp bài khi hết giờ hoặc hoàn thành tất cả câu hỏi
- **Lịch sử**: Xem lại điểm số và chi tiết các bài thi đã làm
- **Chi tiết kết quả**: Xem đáp án đã chọn và thời gian hoàn thành

## Cấu trúc thư mục

```
lib/
├── main.dart                          # Entry point của ứng dụng
├── models/                            # Data models
│   ├── quiz_model.dart               # Model Quiz và Question
│   └── submission_model.dart         # Model Submission
├── services/                          # Business logic layer
│   └── firebase_service.dart         # Tất cả các operations với Firebase
├── screens/                           # UI screens
│   ├── student/                      # Các màn hình dành cho học sinh
│   │   ├── student_panel.dart        # Navigation chính
│   │   ├── dashboard_page.dart       # Trang tổng quan
│   │   ├── quiz_list_page.dart       # Danh sách bài thi
│   │   ├── quiz_taking_page.dart     # Màn hình làm bài với timer
│   │   ├── submit_quiz_page.dart     # Trang thông tin nộp bài
│   │   ├── history_page.dart         # Lịch sử thi
│   │   └── result_detail_page.dart   # Chi tiết kết quả
│   └── auth/                         # Các màn hình xác thực
│       └── login_page.dart           # Đăng nhập (placeholder)
└── utils/                             # Helper utilities
    ├── constants.dart                # Constants toàn ứng dụng
    └── helpers.dart                  # Các hàm tiện ích

```

## Yêu cầu hệ thống

- Flutter SDK: >= 3.0.0
- Dart SDK: >= 3.0.0
- Firebase Project với Firestore enabled

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: latest
  cloud_firestore: latest
```

## Cấu trúc Firestore Database

### Collection: quiz
```
quiz/
├── {quizId}/
│   ├── title: string
│   ├── questionCount: number
│   ├── duration: number (phút)
│   ├── status: string ("available" | "archived")
│   └── questions/ (subcollection)
│       └── {questionId}/
│           ├── question: string
│           ├── options: array<string>
│           └── correctAnswer: string ("A" | "B" | "C" | "D")
```

### Collection: submissions
```
submissions/
└── {submissionId}/
    ├── studentId: string
    ├── quizId: string
    ├── quizTitle: string
    ├── score: number
    ├── totalQuestions: number
    ├── answers: map<string, string>
    ├── timestamp: timestamp
    └── timeSpent: number (giây)
```

## Firebase Indexes cần thiết

Tạo composite index cho collection `submissions`:
- Field: `studentId` (Ascending)
- Field: `timestamp` (Descending)

Hoặc click vào link được cung cấp trong error message khi chạy app lần đầu.


### Chạy ứng dụng

```bash
flutter run
```

## Hướng dẫn sử dụng

### Đối với Học sinh

1. **Đăng nhập**: Hiện tại app tự động đăng nhập với `studentId: 'student_001'`

2. **Xem Dashboard**: 
   - Số lượng bài thi khả dụng
   - 5 bài thi gần nhất đã hoàn thành

3. **Làm bài thi**:
   - Chọn tab "Làm bài thi"
   - Chọn bài thi từ danh sách
   - Click "Bắt đầu"
   - Trả lời các câu hỏi
   - Click "Nộp bài" hoặc đợi hết giờ

4. **Xem lịch sử**:
   - Chọn tab "Lịch sử"
   - Click vào icon mắt để xem chi tiết

### Đối với Giáo viên (Chưa implement)

Sẽ được thêm trong phiên bản tương lai:
- Tạo bài thi mới
- Quản lý câu hỏi
- Xem báo cáo kết quả học sinh

## Tính năng đang phát triển

- Authentication với Firebase Auth
- Teacher Panel
- Admin Panel
- Export kết quả ra Excel
- Thống kê chi tiết
- Phân loại bài thi theo môn học
- Hỗ trợ nhiều loại câu hỏi (hiện tại chỉ có trắc nghiệm)

## Mở rộng

### Thêm Authentication

1. Uncomment code trong `lib/screens/auth/login_page.dart`
2. Implement Firebase Authentication logic
3. Cập nhật `lib/main.dart`:
```dart
home: const LoginPage(), // Thay vì StudentPanel
```

### Thêm Teacher Panel

Tạo folder mới:
```
lib/screens/teacher/
├── teacher_panel.dart
├── create_quiz_page.dart
├── manage_quizzes_page.dart
└── view_results_page.dart
```

### Thêm Admin Panel

Tạo folder mới:
```
lib/screens/admin/
├── admin_panel.dart
├── manage_users_page.dart
└── system_settings_page.dart
```

## Troubleshooting

### Lỗi: Missing index

Nếu gặp lỗi về Firestore index:
1. Click vào link trong error message
2. Hoặc tạo index thủ công trong Firebase Console
3. Đợi vài phút để index được build

### Lỗi: Firebase not initialized

Kiểm tra:
1. File `google-services.json` (Android) hoặc `GoogleService-Info.plist` (iOS) đã được thêm đúng chưa
2. Gradle plugins đã được cấu hình đúng chưa
3. Chạy `flutter clean` và `flutter pub get`

### App bị crash khi chạy

1. Kiểm tra Firebase configuration
2. Xem logs: `flutter logs`
3. Đảm bảo Firestore đã được enable trong Firebase Console

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions or support, please contact: [your-email@example.com]

---

Phát triển bởi [Your Name] - 2024

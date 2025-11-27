# Student Quiz App

Ứng dụng thi trắc nghiệm trực tuyến dành cho học sinh, được xây dựng bằng Flutter và Firebase với hệ thống chống gian lận toàn diện và phân tích học tập chi tiết.

## ⭐ Tính năng nổi bật

### 🎓 Dành cho Học sinh

#### Làm bài thi
- **Dashboard**: Xem tổng quan số lượng bài thi khả dụng và lịch sử làm bài gần đây
- **Danh sách bài thi**: Hiển thị các bài thi chưa hoàn thành với đầy đủ thông tin (số câu hỏi, thời gian)
- **Thi trực tuyến**: Giao diện làm bài với timer đếm ngược, thanh tiến trình và hiển thị số câu đã làm
- **Nộp bài tự động**: Tự động nộp bài khi hết giờ hoặc khi hoàn thành tất cả câu hỏi

#### Lịch sử và Kết quả
- **Lịch sử thi**: Xem lại điểm số và thời gian hoàn thành các bài thi đã làm
- **Chi tiết kết quả**: Xem đáp án đã chọn, đáp án đúng và thời gian làm bài

#### 📊 Phân tích Học tập (Analytics)
- **Tổng quan hiệu suất**:
  - Tổng số bài thi đã hoàn thành
  - Điểm trung bình và tỷ lệ đúng trung bình
  - Thời gian trung bình mỗi bài thi

- **Phân loại kết quả**:
  - Xuất sắc (≥80%): Hiển thị số lượng và phần trăm
  - Khá (65-79%): Theo dõi bài thi đạt mức khá
  - Trung bình (50-64%): Xác định vùng cần cải thiện
  - Yếu (<50%): Cảnh báo các bài thi cần ôn tập lại

- **Phân tích xu hướng**:
  - Chỉ số tiến bộ: So sánh nửa đầu và nửa sau kết quả
  - Biểu đồ xu hướng 10 bài gần nhất
  - Hiển thị xu hướng tăng/giảm điểm số

- **Phân tích thời gian**:
  - Tổng thời gian học tập
  - Thời gian trung bình mỗi bài
  - Bài thi nhanh nhất và chậm nhất
  - Phân tích tốc độ làm bài

### 🔒 Hệ thống Chống Gian lận (Anti-Cheat)

#### Cross-Platform Anti-Cheat
Hệ thống chống gian lận hoạt động trên tất cả nền tảng (Web, Android, iOS) với các tính năng:

- **Phát hiện chuyển ứng dụng**: 
  - Theo dõi khi học sinh chuyển sang app khác (Mobile)
  - Phát hiện chuyển tab/cửa sổ (Web)
  - Ghi nhận thời gian vắng mặt

- **Chặn phím tắt nguy hiểm**:
  - Chặn chụp màn hình (Print Screen, Snipping Tool)
  - Vô hiệu hóa DevTools (F12, Ctrl+Shift+I)
  - Chặn Copy/Paste/Cut
  - Chặn View Source và Save Page

- **Phân tích hành vi**:
  - Theo dõi tốc độ trả lời câu hỏi
  - Phát hiện pattern nghi ngờ (trả lời quá nhanh/chậm)
  - Phân tích thời gian trên mỗi câu hỏi
  - Theo dõi chuyển động chuột

- **Hệ thống cảnh báo**:
  - Hiển thị số lần vi phạm trên AppBar
  - Mã màu theo mức độ nghiêm trọng (Vàng → Cam → Đỏ)
  - Tự động nộp bài sau 3 cảnh báo
  - Ghi log tất cả hoạt động nghi ngờ

#### 📹 Camera Proctoring (Chỉ trên Web)
- **Giám sát qua camera**:
  - Yêu cầu bật camera trước khi bắt đầu thi
  - Hiển thị preview camera bên cạnh bài thi
  - Ghi hình liên tục trong suốt bài thi
  - Chỉ báo REC màu đỏ khi đang quay

- **Nhận diện khuôn mặt (Face Detection)**:
  - Sử dụng TensorFlow.js và MediaPipe Face Detection
  - Phát hiện khi không có khuôn mặt trong khung hình
  - Cảnh báo khi phát hiện nhiều khuôn mặt
  - Tự động restart camera nếu bị ngắt kết nối
  - Hiển thị trạng thái face detection realtime

- **Xử lý vi phạm camera**:
  - Đếm số lần không phát hiện khuôn mặt
  - Đếm số lần phát hiện nhiều người
  - Tích hợp vào hệ thống cảnh báo chung
  - Ghi log chi tiết vào Firestore

#### 📱 Platform-Specific Features

**Web**:
- Tab visibility detection
- Keyboard shortcut blocking
- Clipboard blocking
- Right-click prevention
- Camera proctoring with face detection
- Screenshot prevention

**Mobile (Android/iOS)**:
- App lifecycle monitoring
- Fullscreen mode
- Hardware keyboard blocking (Android)
- Screenshot detection (Android)

**Desktop**:
- Keyboard monitoring
- Mouse behavior tracking

#### 🛡️ Báo cáo An toàn
Mỗi bài thi đều có báo cáo chống gian lận chi tiết:
- Tổng số cảnh báo
- Số lần chuyển ứng dụng/tab
- Số lần cố gắng chụp màn hình
- Số lần không có khuôn mặt (Web)
- Số lần nhiều khuôn mặt (Web)
- Phân tích timing patterns
- Cờ "flagged" cho bài thi nghi ngờ

## 📁 Cấu trúc thư mục

```
lib/
├── main.dart                               # Entry point
├── models/                                 # Data models
│   ├── quiz_model.dart                    # Model Quiz và Question
│   └── submission_model.dart              # Model Submission
├── services/                               # Business logic
│   ├── firebase_service.dart              # Firebase operations
│   ├── analytics_service.dart             # Tính toán analytics
│   ├── anti_cheat_service.dart            # Anti-cheat cơ bản (Mobile)
│   ├── web_anti_cheat_service.dart        # Anti-cheat cho Web
│   ├── web_anti_cheat_service_stub.dart   # Stub cho non-web
│   ├── cross_platform_anti_cheat_service.dart  # Anti-cheat đa nền tảng
│   └── camera_proctoring_service.dart     # Camera và face detection (Web)
├── screens/                                # UI screens
│   ├── student/
│   │   ├── student_panel.dart             # Navigation chính (5 tabs)
│   │   ├── dashboard_page.dart            # Trang tổng quan
│   │   ├── quiz_list_page.dart            # Danh sách bài thi
│   │   ├── quiz_taking_page.dart          # Làm bài với anti-cheat
│   │   ├── submit_quiz_page.dart          # Nộp bài
│   │   ├── history_page.dart              # Lịch sử thi
│   │   ├── result_detail_page.dart        # Chi tiết kết quả
│   │   └── analytics_page.dart            # Phân tích học tập
│   └── auth/
│       └── login_page.dart                # Đăng nhập
├── widgets/
│   └── camera_permission_dialog.dart      # Dialog xin quyền camera
└── utils/                                  # Helpers
    ├── constants.dart                     # Constants
    ├── helpers.dart                       # Hàm tiện ích
    └── platform_utils.dart                # Platform detection
```

## 🔧 Yêu cầu hệ thống

- Flutter SDK: >= 3.0.0
- Dart SDK: >= 3.0.0
- Firebase Project với Firestore enabled

### Cho Web (Camera Proctoring)
- Chrome/Edge/Firefox phiên bản mới nhất
- Camera và microphone (chỉ cần camera)
- HTTPS (required for getUserMedia API)

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: latest
  cloud_firestore: latest

# Web-specific (đã tích hợp trong Flutter)
# - dart:html (cho camera và DOM manipulation)
# - dart:js (cho TensorFlow.js integration)
```

### JavaScript Libraries (Web)
Thêm vào `web/index.html`:
```html
<!-- TensorFlow.js -->
<script src="https://cdn.jsdelivr.net/npm/@tensorflow/tfjs"></script>

<!-- Face Detection Model -->
<script src="https://cdn.jsdelivr.net/npm/@tensorflow-models/face-detection"></script>
```

## 🗄️ Cấu trúc Firestore Database

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
    ├── timeSpent: number (giây)
    └── antiCheat: object                  # 🆕 Dữ liệu chống gian lận
        ├── appSwitchCount: number         # Số lần chuyển app
        ├── tabSwitchCount: number         # Số lần chuyển tab (Web)
        ├── screenshotAttempts: number     # Số lần cố chụp màn hình
        ├── devToolsAttempts: number       # Số lần mở DevTools
        ├── copyPasteAttempts: number      # Số lần copy/paste
        ├── warningCount: number           # Tổng cảnh báo
        ├── noFaceWarnings: number         # 🆕 Không có mặt (Web)
        ├── multipleFaceWarnings: number   # 🆕 Nhiều người (Web)
        ├── wasFullscreen: boolean         # Có dùng fullscreen không
        ├── flagged: boolean               # Có nghi ngờ không
        ├── platform: string               # 🆕 Nền tảng (Web/Android/iOS)
        ├── patternAnalysis: object        # Phân tích pattern
        │   ├── averageTimePerQuestion: number
        │   ├── suspiciouslyFastAnswers: number
        │   ├── suspiciouslySlowAnswers: number
        │   └── consistency: string
        └── activityLog: array<object>     # Log chi tiết
            └── {
                  timestamp: timestamp,
                  type: string,
                  details: string,
                  severity: string
                }
```

### Collection: suspicious_activities (🆕)
```
suspicious_activities/
└── {activityId}/
    ├── submissionId: string
    ├── studentId: string
    ├── quizId: string
    ├── activityType: string
    │   # Types: "app_switch", "tab_switch", "screenshot_attempt",
    │   #         "print_screen", "devtools_attempt", "copy_attempt",
    │   #         "no_face_detected", "multiple_faces_detected", etc.
    ├── details: string
    ├── severity: string ("low" | "medium" | "high")
    └── timestamp: timestamp
```

## 🔐 Firebase Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Quiz collection - read only
    match /quiz/{quizId} {
      allow read: if true;
      allow write: if false; // Only admin can write
      
      match /questions/{questionId} {
        allow read: if true;
        allow write: if false;
      }
    }
    
    // Submissions - students can only read/write their own
    match /submissions/{submissionId} {
      allow read: if request.auth != null && 
                     resource.data.studentId == request.auth.uid;
      allow create: if request.auth != null && 
                       request.resource.data.studentId == request.auth.uid;
      allow update: if request.auth != null && 
                       resource.data.studentId == request.auth.uid;
    }
    
    // Suspicious activities - students can create, admins can read all
    match /suspicious_activities/{activityId} {
      allow read: if request.auth != null; // Admin only in production
      allow create: if request.auth != null;
    }
  }
}
```

## 📊 Firebase Indexes

Tạo các composite indexes sau:

1. **Submissions by student and time**:
   - Collection: `submissions`
   - Fields: `studentId` (Ascending) + `timestamp` (Descending)

2. **Suspicious activities by student**:
   - Collection: `suspicious_activities`
   - Fields: `studentId` (Ascending) + `timestamp` (Descending)

3. **Suspicious activities by submission**:
   - Collection: `suspicious_activities`
   - Fields: `submissionId` (Ascending) + `timestamp` (Descending)

Hoặc click vào link trong error message khi chạy app lần đầu.

## 🚀 Cài đặt và Chạy

### 1. Clone repository
```bash
git clone https://github.com/DuyNguyen25092004/CNPM_TAKING_EXAM_SYSTEM.git
cd student-quiz-app
```

### 2. Cài đặt dependencies
```bash
flutter pub get
```

### 3. Cấu hình Firebase

#### Cho Android:
1. Tải `google-services.json` từ Firebase Console
2. Đặt vào `android/app/`

#### Cho iOS:
1. Tải `GoogleService-Info.plist` từ Firebase Console
2. Đặt vào `ios/Runner/`

#### Cho Web:
1. Thêm Firebase config vào `web/index.html`
2. Thêm TensorFlow.js và Face Detection scripts (xem phần Dependencies)

### 4. Chạy ứng dụng

```bash
# Web (với camera proctoring)
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

## 📱 Hướng dẫn sử dụng

### Cho Học sinh

#### 1. Xem Dashboard
- Số lượng bài thi khả dụng
- 5 bài thi gần nhất đã hoàn thành
- Truy cập nhanh vào các tính năng

#### 2. Làm bài thi (với Camera Proctoring trên Web)
- Chọn tab "Làm bài thi"
- Chọn bài thi từ danh sách
- **Trên Web**: Cho phép truy cập camera khi được yêu cầu
  - Hệ thống sẽ load mô hình nhận diện khuôn mặt (5-15 giây)
  - Đợi đến khi thấy "Face Detection Ready"
  - Click "Bắt đầu thi"
- **Trên Mobile**: Bắt đầu thi trực tiếp (không cần camera)
- Làm bài trong thời gian cho phép
- Hệ thống sẽ giám sát:
  - Camera và khuôn mặt (Web)
  - Chuyển app/tab
  - Cố gắng chụp màn hình
  - Các hành vi gian lận khác
- Click "Nộp bài" hoặc đợi hết giờ

#### 3. Xem Analytics
- Chọn tab "Phân tích"
- Xem tổng quan hiệu suất
- Phân tích xu hướng học tập
- Xác định điểm mạnh/yếu

#### 4. Xem lịch sử
- Chọn tab "Lịch sử"
- Click vào icon mắt để xem chi tiết
- Xem cả báo cáo anti-cheat (nếu có vi phạm)

### 🎯 Best Practices khi thi

✅ **Nên**:
- Ngồi ở nơi có ánh sáng tốt (Web - camera)
- Đảm bảo khuôn mặt luôn trong khung hình (Web)
- Tập trung làm bài không chuyển tab/app
- Đọc kỹ câu hỏi trước khi trả lời

❌ **Không nên**:
- Chuyển tab/app trong khi làm bài
- Cố gắng chụp màn hình câu hỏi
- Để người khác vào camera (Web)
- Mở DevTools hoặc View Source (Web)
- Copy/paste nội dung câu hỏi

## 🔍 Troubleshooting

### Lỗi Camera (Web)

**"Không thể truy cập camera"**:
- Kiểm tra quyền camera trong browser settings
- Đảm bảo không có app nào đang dùng camera
- Thử restart browser
- Đảm bảo đang chạy trên HTTPS (localhost:// cũng OK)

**"Face Detection không load"**:
- Kiểm tra TensorFlow.js scripts trong `index.html`
- Xem console log để biết lỗi cụ thể
- Thử refresh trang
- Kiểm tra internet connection (cần download model)

**Camera bị đóng băng**:
- Click nút "Khởi động lại camera" trên UI
- Kiểm tra console log
- Thử đóng tất cả tabs khác đang dùng camera

**Nút "Bắt đầu thi" bị delay/không nhấn được ngay**:
- Đây là hành vi bình thường khi face detection vừa sẵn sàng
- Hệ thống cần 1-2 giây để verify camera và face detection hoạt động ổn định
- Nếu delay quá lâu (>5 giây), kiểm tra console log và thử restart camera

### Lỗi Firebase

**Missing index**:
1. Click vào link trong error message
2. Hoặc tạo index thủ công trong Firebase Console
3. Đợi vài phút để index được build

**Firebase not initialized**:
1. Kiểm tra config files đã được thêm đúng chưa
2. Chạy `flutter clean` và `flutter pub get`
3. Rebuild project

### Lỗi Anti-Cheat

**Quá nhiều cảnh báo giả (false positives)**:
- Điều chỉnh threshold trong code
- Kiểm tra platform detection
- Xem logs để biết nguyên nhân cụ thể

**Tab switch không được phát hiện (Web)**:
- Kiểm tra Page Visibility API có được hỗ trợ không
- Xem console logs
- Thử browser khác

## 🎨 Customization

### Thay đổi Threshold Anti-Cheat

Trong `quiz_taking_page.dart`:
```dart
// Số cảnh báo tối đa trước khi auto-submit
if (_warningCount >= 3) {  // Thay 3 thành số khác
  _showTooManyViolationsDialog();
}
```

### Thay đổi Màu sắc

Trong `utils/constants.dart`:
```dart
static const Color primaryColor = Colors.blue;  // Đổi màu chủ đạo
static const Color successColor = Colors.green;
static const Color warningColor = Colors.orange;
```

### Thêm Loại Câu Hỏi Mới

Hiện tại chỉ hỗ trợ trắc nghiệm 4 đáp án. Để thêm loại mới:
1. Cập nhật `Question` model
2. Thêm UI component mới trong `quiz_taking_page.dart`
3. Cập nhật logic chấm điểm trong `firebase_service.dart`

## 🚧 Tính năng đang phát triển

- [ ] Authentication với Firebase Auth
- [ ] Teacher Panel (tạo và quản lý bài thi)
- [ ] Admin Panel (quản lý hệ thống)
- [ ] Export báo cáo ra Excel/PDF
- [ ] Thống kê nâng cao với charts
- [ ] Phân loại bài thi theo môn học/chủ đề
- [ ] Video recording (lưu video thi) - Web
- [ ] Real-time monitoring dashboard cho giáo viên
- [ ] Machine learning để phát hiện gian lận nâng cao
- [ ] Hỗ trợ nhiều loại câu hỏi (tự luận, điền khuyết, ...)
- [ ] Mobile camera proctoring (Android/iOS)

## 📄 License

This project is licensed under the MIT License.

## 👥 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📧 Contact

For questions or support, please contact: [your-email@example.com]

---

**Phát triển bởi [Your Name] - 2024**

*"Công nghệ vì một nền giáo dục công bằng và minh bạch"*
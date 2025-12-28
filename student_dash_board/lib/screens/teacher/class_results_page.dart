// lib/screens/teacher/class_results_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class ClassResultsPage extends StatefulWidget {
  final String classId;

  const ClassResultsPage({Key? key, required this.classId}) : super(key: key);

  @override
  State<ClassResultsPage> createState() => _ClassResultsPageState();
}

class _ClassResultsPageState extends State<ClassResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedQuizFilter;
  String _sortBy = 'studentId';
  bool _sortAscending = false;
  bool _isExporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Hàm lấy tên học sinh từ classId và studentId
  Future<String> _getStudentName(String studentId) async {
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .doc(studentId)
          .get();

      if (studentDoc.exists) {
        return studentDoc.data()?['name'] ?? 'Không có tên';
      }
      return 'Không có tên';
    } catch (e) {
      return 'Không có tên';
    }
  }

  // Hàm xuất Excel
  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);

    try {
      // Lấy dữ liệu submissions
      final submissionsSnapshot = await FirebaseFirestore.instance
          .collection('submissions')
          .where('classId', isEqualTo: widget.classId)
          .get();

      if (submissionsSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('⚠️ Không có dữ liệu để xuất'),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      var submissions = submissionsSnapshot.docs;

      // Apply filters
      if (_searchQuery.isNotEmpty) {
        submissions = submissions.where((doc) {
          final data = doc.data();
          final studentId = (data['studentId'] ?? '').toString().toLowerCase();
          final studentName = (data['studentName'] ?? '')
              .toString()
              .toLowerCase();
          return studentId.contains(_searchQuery) ||
              studentName.contains(_searchQuery);
        }).toList();
      }

      if (_selectedQuizFilter != null) {
        submissions = submissions.where((doc) {
          final data = doc.data();
          return data['quizId'] == _selectedQuizFilter;
        }).toList();
      }

      // Sort
      submissions.sort((a, b) {
        final dataA = a.data();
        final dataB = b.data();

        int comparison = 0;

        if (_sortBy == 'score') {
          final scoreA = dataA['score'] ?? 0;
          final scoreB = dataB['score'] ?? 0;
          final totalA = dataA['totalQuestions'] ?? 1;
          final totalB = dataB['totalQuestions'] ?? 1;
          final percentA = (scoreA / totalA * 100);
          final percentB = (scoreB / totalB * 100);
          comparison = percentB.compareTo(percentA);
        } else if (_sortBy == 'suspicious') {
          final susA = dataA['suspiciousActionCount'] ?? 0;
          final susB = dataB['suspiciousActionCount'] ?? 0;
          comparison = susB.compareTo(susA);
        } else if (_sortBy == 'studentId') {
          // ← THÊM DÒNG NÀY
          final idA = dataA['studentId'] ?? ''; // ← THÊM DÒNG NÀY
          final idB = dataB['studentId'] ?? ''; // ← THÊM DÒNG NÀY
          comparison = idA.compareTo(idB); // ← THÊM DÒNG NÀY
        } else {
          final timeA = dataA['timestamp'] as Timestamp?;
          final timeB = dataB['timestamp'] as Timestamp?;
          if (timeA == null || timeB == null) return 0;
          comparison = timeB.compareTo(timeA);
        }

        return _sortAscending ? -comparison : comparison;
      });

      // Tạo Excel file
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Kết quả thi'];

      // Xóa sheet mặc định
      excel.delete('Sheet1');

      // Header style
      CellStyle headerStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Thêm headers
      List<String> headers = ['STT', 'Mã sinh viên', 'Họ và tên', 'Điểm số'];

      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Data style
      CellStyle dataStyle = CellStyle(
        fontSize: 11,
        verticalAlign: VerticalAlign.Center,
      );

      CellStyle warningStyle = CellStyle(
        fontSize: 11,
        verticalAlign: VerticalAlign.Center,
        // backgroundColorHex: ExcelColor.lightYellow,
      );

      // Thêm dữ liệu
      for (int i = 0; i < submissions.length; i++) {
        final data = submissions[i].data();
        final studentId = data['studentId'] ?? 'Unknown';
        final studentName =
            data['studentName'] ?? await _getStudentName(studentId);
        final score = data['score'] ?? 0;

        int rowIndex = i + 1;

        List<dynamic> rowData = [i + 1, studentId, studentName, score];

        for (int j = 0; j < rowData.length; j++) {
          var cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );

          if (rowData[j] is int) {
            cell.value = IntCellValue(rowData[j]);
          } else if (rowData[j] is double) {
            cell.value = DoubleCellValue(rowData[j]);
          } else {
            cell.value = TextCellValue(rowData[j].toString());
          }
        }
      }

      // Auto-fit columns
      for (int i = 0; i < headers.length; i++) {
        sheetObject.setColumnWidth(i, 18);
      }

      // Lấy tên lớp
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();
      final className = classDoc.data()?['name'] ?? 'Lop';

      // Tạo tên file
      final fileName = 'KetQua_${className}.xlsx';

      // Lưu file
      var fileBytes = excel.save(fileName: "$fileName");
      if (fileBytes == null) {
        throw Exception('Không thể tạo file Excel');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('✅ Đã xuất ${submissions.length} kết quả'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('❌ Lỗi: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _formatDateForExcel(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header & Filters
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.analytics_rounded,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Kết quả thi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Export button
                  ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportToExcel,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      _isExporting ? 'Đang xuất...' : 'Xuất Excel',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm mã học sinh hoặc tên...',
                  hintStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
              const SizedBox(height: 10),

              // Filters Row
              Row(
                children: [
                  // Quiz Filter
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('classes')
                          .doc(widget.classId)
                          .collection('quizzes')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final quizzes = snapshot.data!.docs;

                        return Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedQuizFilter,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              hint: Row(
                                children: [
                                  Icon(
                                    Icons.filter_list_rounded,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Lọc bài thi',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    'Tất cả',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                ...quizzes.map((quiz) {
                                  final data =
                                      quiz.data() as Map<String, dynamic>;
                                  return DropdownMenuItem(
                                    value: quiz.id,
                                    child: Text(
                                      data['title'] ?? 'Bài thi',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedQuizFilter = value);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Sort Options
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          dropdownColor: Colors.white,
                          items: const [
                            DropdownMenuItem(
                              value: 'time',
                              child: Text(
                                'Thời gian',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'score',
                              child: Text(
                                'Điểm số',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'suspicious',
                              child: Text(
                                'Vi phạm',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              // ← THÊM DÒNG NÀY
                              value: 'studentId', // ← THÊM DÒNG NÀY
                              child: Text(
                                // ← THÊM DÒNG NÀY
                                'Mã SV', // ← THÊM DÒNG NÀY
                                style: TextStyle(
                                  fontSize: 13,
                                ), // ← THÊM DÒNG NÀY
                              ), // ← THÊM DÒNG NÀY
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _sortBy = value ?? 'studentId');
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Sort Direction Toggle Button
                  Material(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() => _sortAscending = !_sortAscending);
                      },
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _sortAscending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: Colors.blue.shade700,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Results List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('submissions')
                .where('classId', isEqualTo: widget.classId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.orange.shade600,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 60,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Đã xảy ra lỗi tải dữ liệu',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState('Chưa có bài thi nào được nộp');
              }

              var submissions = snapshot.data!.docs;

              // Filter logic
              if (_searchQuery.isNotEmpty) {
                submissions = submissions.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final studentId = (data['studentId'] ?? '')
                      .toString()
                      .toLowerCase();
                  final studentName = (data['studentName'] ?? '')
                      .toString()
                      .toLowerCase();
                  return studentId.contains(_searchQuery) ||
                      studentName.contains(_searchQuery);
                }).toList();
              }

              if (_selectedQuizFilter != null) {
                submissions = submissions.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['quizId'] == _selectedQuizFilter;
                }).toList();
              }

              if (submissions.isEmpty) {
                return _buildEmptyState('Không tìm thấy kết quả phù hợp');
              }

              // Sort logic
              submissions.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;

                int comparison = 0;

                if (_sortBy == 'score') {
                  final scoreA = dataA['score'] ?? 0;
                  final scoreB = dataB['score'] ?? 0;
                  final totalA = dataA['totalQuestions'] ?? 1;
                  final totalB = dataB['totalQuestions'] ?? 1;
                  final percentA = (scoreA / totalA * 100);
                  final percentB = (scoreB / totalB * 100);
                  comparison = percentB.compareTo(percentA);
                } else if (_sortBy == 'suspicious') {
                  final susA = dataA['suspiciousActionCount'] ?? 0;
                  final susB = dataB['suspiciousActionCount'] ?? 0;
                  comparison = susB.compareTo(susA);
                } else if (_sortBy == 'studentId') {
                  final idA = dataA['studentId'] ?? '';
                  final idB = dataB['studentId'] ?? '';
                  comparison = idA.compareTo(idB);
                } else {
                  final timeA = dataA['timestamp'] as Timestamp?;
                  final timeB = dataB['timestamp'] as Timestamp?;
                  if (timeA == null || timeB == null) return 0;
                  comparison = timeB.compareTo(timeA);
                }

                return _sortAscending ? -comparison : comparison;
              });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  final doc = submissions[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final score = data['score'] ?? 0;
                  final total = data['totalQuestions'] ?? 1;
                  final percentage = (score / total * 100);
                  final scoreColor = _getScoreColor(percentage);
                  final studentId = data['studentId'] ?? 'Unknown';
                  final studentName = data['studentName'] as String?;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: (data['suspiciousActionCount'] ?? 0) > 0
                          ? Border.all(color: Colors.orange.shade300, width: 2)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () =>
                            _showSubmissionDetail(context, doc.id, data),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Score Circle
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      scoreColor.withOpacity(0.8),
                                      scoreColor,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: scoreColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${percentage.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '$score/$total',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: studentName != null
                                              ? Text(
                                                  studentName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                )
                                              : FutureBuilder<String>(
                                                  future: _getStudentName(
                                                    studentId,
                                                  ),
                                                  builder:
                                                      (context, nameSnapshot) {
                                                        return Text(
                                                          nameSnapshot.data ??
                                                              'Đang tải...',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                        );
                                                      },
                                                ),
                                        ),
                                        if ((data['suspiciousActionCount'] ??
                                                0) >
                                            0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.orange.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  size: 14,
                                                  color: Colors.orange.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${data['suspiciousActionCount']}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.orange.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'MSSV: $studentId',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data['quizTitle'] ?? 'Bài thi',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(data['timestamp']),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Action
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.visibility_rounded,
                                  color: Colors.blue.shade700,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green.shade600;
    if (percentage >= 50) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _showSubmissionDetail(
    BuildContext context,
    String submissionId,
    Map<String, dynamic> submission,
  ) async {
    final quizId = submission['quizId'] as String?;

    if (quizId == null) return;

    final questionsSnapshot = await FirebaseFirestore.instance
        .collection('quiz')
        .doc(quizId)
        .collection('questions')
        .get();

    if (!context.mounted) return;

    final studentAnswers = submission['answers'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (context) => _SubmissionDetailDialog(
        submission: submission,
        questions: questionsSnapshot.docs,
        studentAnswers: studentAnswers,
      ),
    );
  }
}

// Dialog chi tiết submission (giữ nguyên như code cũ)
class _SubmissionDetailDialog extends StatelessWidget {
  final Map<String, dynamic> submission;
  final List<QueryDocumentSnapshot> questions;
  final Map<String, dynamic> studentAnswers;

  const _SubmissionDetailDialog({
    required this.submission,
    required this.questions,
    required this.studentAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final score = submission['score'] ?? 0;
    final total = submission['totalQuestions'] ?? 1;
    final percentage = (score / total * 100);
    final timeSpent = submission['timeSpent'] ?? 0;
    final suspiciousCount = submission['suspiciousActionCount'] ?? 0;
    final cheatingDetected = submission['cheatingDetected'] ?? false;
    final autoSubmitted = submission['autoSubmitted'] ?? false;
    final studentName = submission['studentName'] ?? 'Không có tên';
    final studentId = submission['studentId'] ?? 'Unknown';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade500, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.95),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'MSSV: $studentId',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          submission['quizTitle'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Stats with Suspicious Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.check_circle_rounded,
                        '$score',
                        'Đúng',
                        Colors.green,
                      ),
                      _buildStatItem(
                        Icons.cancel_rounded,
                        '${total - score}',
                        'Sai',
                        Colors.red,
                      ),
                      _buildStatItem(
                        Icons.timer_rounded,
                        _formatTime(timeSpent),
                        'Thời gian',
                        Colors.blue,
                      ),
                      _buildStatItem(
                        Icons.grade_rounded,
                        '${percentage.toStringAsFixed(1)}%',
                        'Điểm số',
                        Colors.orange,
                      ),
                    ],
                  ),

                  if (suspiciousCount > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cheatingDetected
                            ? Colors.red.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cheatingDetected
                              ? Colors.red.shade300
                              : Colors.orange.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cheatingDetected
                                ? Icons.block_rounded
                                : Icons.warning_amber_rounded,
                            color: cheatingDetected
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  autoSubmitted
                                      ? 'Tự động nộp do vi phạm'
                                      : 'Có hành vi khả nghi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: cheatingDetected
                                        ? Colors.red.shade900
                                        : Colors.orange.shade900,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$suspiciousCount vi phạm được ghi nhận',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cheatingDetected
                                        ? Colors.red.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: cheatingDetected
                                  ? Colors.red.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$suspiciousCount',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: cheatingDetected
                                    ? Colors.red.shade900
                                    : Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Questions List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final questionDoc = questions[index];
                  final questionData =
                      questionDoc.data() as Map<String, dynamic>;
                  final questionId = questionDoc.id;
                  final correctAnswer = questionData['correctAnswer'] ?? '';
                  final studentAnswer = studentAnswers[questionId] ?? '';
                  final isCorrect = studentAnswer == correctAnswer;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCorrect
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isCorrect ? Colors.green : Colors.red)
                              .withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(14),
                              topRight: Radius.circular(14),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Câu ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCorrect
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  questionData['question'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: List.generate(4, (i) {
                              final letter = String.fromCharCode(65 + i);
                              final options = questionData['options'] as List;
                              final isCorrectOption = letter == correctAnswer;
                              final isStudentChoice = letter == studentAnswer;

                              Color bgColor = Colors.white;
                              Color borderColor = Colors.grey.shade200;
                              Color textColor = Colors.black87;
                              IconData? icon;

                              if (isCorrectOption) {
                                bgColor = Colors.green.shade50;
                                borderColor = Colors.green.shade400;
                                textColor = Colors.green.shade800;
                                icon = Icons.check_circle_rounded;
                              } else if (isStudentChoice && !isCorrect) {
                                bgColor = Colors.red.shade50;
                                borderColor = Colors.red.shade400;
                                textColor = Colors.red.shade800;
                                icon = Icons.cancel_rounded;
                              } else if (isStudentChoice) {
                                bgColor = Colors.green.shade50;
                                borderColor = Colors.green.shade400;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isCorrectOption
                                            ? Colors.green
                                            : (isStudentChoice
                                                  ? Colors.red
                                                  : Colors.grey.shade300),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          letter,
                                          style: TextStyle(
                                            color:
                                                isStudentChoice ||
                                                    isCorrectOption
                                                ? Colors.white
                                                : Colors.grey.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        options[i],
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (icon != null)
                                      Icon(icon, color: borderColor, size: 20),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
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

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}

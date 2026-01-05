// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // ✅ Cần import intl để hiển thị giờ

// --- THEME COLORS ---
const Color _primaryColor = Color(0xFF1E88E5);
const Color _backgroundColor = Color(0xFFF5F7FA);
const Color _otherBubbleColor = Colors.white;

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String chatTitle;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.chatTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser;

  // --- LOGIC GỬI TIN NHẮN (GIỮ NGUYÊN CỦA BẠN) ---
  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    try {
      // 1. Lưu tin nhắn
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
            'text': text,
            'senderId': currentUser!.uid,
            'createdAt':
                FieldValue.serverTimestamp(), // Dùng createdAt cho thống nhất
            'timestamp':
                FieldValue.serverTimestamp(), // Dùng thêm timestamp cho chắc
          });

      // 2. Cập nhật thông tin chat
      final chatDocRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.conversationId);

      Map<String, dynamic> chatData = {
        'lastMessage': text,
        'lastTime': FieldValue.serverTimestamp(),
        'userId': widget.conversationId,
        'isRead': false, // Đánh dấu chưa đọc để Admin biết
      };

      // ✅ Logic lấy tên thật của bạn
      if (currentUser!.uid == widget.conversationId) {
        String realName =
            currentUser!.displayName ?? currentUser!.email ?? 'Khách hàng';
        chatData['userName'] = realName;
      }

      await chatDocRef.set(chatData, SetOptions(merge: true));

      // Cuộn xuống
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    return Scaffold(
      backgroundColor: _backgroundColor, // Nền xám nhạt
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            // Avatar Admin giả lập
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.support_agent, size: 24, color: _primaryColor),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Thường trả lời ngay",
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. DANH SÁCH TIN NHẮN
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy(
                    'createdAt',
                    descending: true,
                  ) // Sắp xếp giảm dần (mới nhất ở dưới do reverse: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Đảo ngược để tin mới nhất nằm dưới cùng
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUser!.uid;
                    // Lấy thời gian (hỗ trợ cả trường hợp null khi mới gửi)
                    final timestamp = data['createdAt'] ?? data['timestamp'];

                    return _buildMessageBubble(data['text'], isMe, timestamp);
                  },
                );
              },
            ),
          ),

          // 2. KHUNG NHẬP LIỆU
          _buildInputArea(),
        ],
      ),
    );
  }

  // --- Widget Bong bóng tin nhắn ---
  Widget _buildMessageBubble(String message, bool isMe, dynamic timestamp) {
    // Format giờ
    String timeStr = "";
    if (timestamp != null && timestamp is Timestamp) {
      final dt = timestamp.toDate();
      timeStr = DateFormat('HH:mm').format(dt);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar nhỏ cho người đối diện (Admin)
            if (!isMe) ...[
              const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],

            // Nội dung bong bóng
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isMe ? _primaryColor : _otherBubbleColor,
                  // Bo góc bất đối xứng tạo hiệu ứng hội thoại
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: isMe
                        ? const Radius.circular(18)
                        : const Radius.circular(2),
                    bottomRight: isMe
                        ? const Radius.circular(2)
                        : const Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Hiển thị giờ
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Thanh nhập liệu ---
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Nút tiện ích (Ví dụ: Gửi ảnh)
            IconButton(
              icon: Icon(
                Icons.add_circle,
                color: _primaryColor.withOpacity(0.8),
              ),
              onPressed: () {}, // Chưa có chức năng
            ),

            // Ô nhập text
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _msgController,
                  textCapitalization:
                      TextCapitalization.sentences, // Viết hoa đầu câu
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 4, // Tự giãn dòng tối đa 4 dòng
                  decoration: const InputDecoration(
                    hintText: "Nhập tin nhắn...",
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Nút Gửi
            GestureDetector(
              onTap: _sendMessage,
              child: const CircleAvatar(
                backgroundColor: _primaryColor,
                radius: 22,
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 50,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            "Chưa có tin nhắn nào",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 5),
          const Text(
            "Hãy gửi lời chào tới chủ sân!",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

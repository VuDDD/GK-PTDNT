/// Các hàm kiểm tra dữ liệu đầu vào dùng chung cho Login và Product Form.
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$',
  );

  /// Kiểm tra email đăng nhập Admin.
  static String? validateEmail(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Vui lòng nhập email Admin';
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Email không đúng định dạng';
    }
    return null;
  }

  /// Kiểm tra mật khẩu đăng nhập Admin.
  static String? validatePassword(String? value) {
    final String raw = value ?? '';
    if (raw.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (raw.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  /// Kiểm tra tên sản phẩm: không được rỗng.
  static String? validateProductName(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Tên sản phẩm không được để trống';
    }
    if (trimmed.length < 2) {
      return 'Tên sản phẩm phải có ít nhất 2 ký tự';
    }
    return null;
  }

  /// Kiểm tra giá sản phẩm: phải là số hợp lệ và lớn hơn 0.
  static String? validatePrice(String? value) {
    final String cleaned = (value ?? '').trim().replaceAll(',', '');
    if (cleaned.isEmpty) {
      return 'Vui lòng nhập giá sản phẩm';
    }
    final double? parsed = double.tryParse(cleaned);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      return 'Giá sản phẩm phải là số hợp lệ';
    }
    if (parsed <= 0) {
      return 'Giá sản phẩm phải lớn hơn 0';
    }
    return null;
  }

  /// Kiểm tra số lượng sản phẩm: phải là số nguyên >= 0.
  static String? validateQuantity(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Vui lòng nhập số lượng sản phẩm';
    }
    final int? parsed = int.tryParse(trimmed);
    if (parsed == null) {
      return 'Số lượng phải là số nguyên hợp lệ';
    }
    if (parsed < 0) {
      return 'Số lượng phải lớn hơn hoặc bằng 0';
    }
    return null;
  }

  /// Parse chuỗi giá thành `double` sau khi đã validate.
  static double parsePrice(String value) {
    return double.parse(value.trim().replaceAll(',', ''));
  }

  /// Parse chuỗi số lượng thành `int` sau khi đã validate.
  static int parseQuantity(String value) {
    return int.parse(value.trim());
  }
}

